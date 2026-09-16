import Foundation
import Security

/// Antwortobjekt für erfolgreiche Supabase-Auth-Operationen.
///
/// Dieses Modell entspricht der Supabase-Response und wird direkt aus dem
/// JSON der Auth-Endpunkte decodiert.
struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let user: User
    
    struct User: Codable {
        let id: String
        let email: String

        enum CodingKeys: String, CodingKey {
            case id, email
        }

        init(id: String, email: String) {
            self.id = id
            self.email = email
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        }
    }
}

/// Fehlerobjekt, das Supabase bei fehlgeschlagenen Auth-Operationen zurückliefert.
struct AuthError: Decodable {
    let message: String
    let errorCode: String?

    enum CodingKeys: String, CodingKey {
        case message, msg, error, error_code, code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var messageValue = try container.decodeIfPresent(String.self, forKey: .message)
        if messageValue == nil {
            messageValue = try container.decodeIfPresent(String.self, forKey: .msg)
        }
        if messageValue == nil {
            messageValue = try container.decodeIfPresent(String.self, forKey: .error)
        }
        message = messageValue ?? ""
        if let explicit = try container.decodeIfPresent(String.self, forKey: .error_code), !explicit.isEmpty {
            errorCode = explicit
        } else if let code = try container.decodeIfPresent(String.self, forKey: .code),
                  !code.isEmpty,
                  Int(code) == nil {
            errorCode = code
        } else {
            errorCode = nil
        }
    }
}

private struct RecoverRequestBody: Encodable {
    let email: String
    let code_challenge: String
    let code_challenge_method: String
}

private struct PKCETokenRequest: Encodable {
    let auth_code: String
    let code_verifier: String
}

/// Client für alle Authentifizierungs-Flows gegen Supabase (E-Mail, Passwort, Apple, Refresh).
///
/// Verantwortlichkeiten:
/// - Kapselt HTTP-Aufrufe an `/auth/v1/*`.
/// - Mappt HTTP-Statuscodes auf typisierte Fehler (`NSError` mit lokalisierten Messages).
/// - Enthält keine UI-Logik, sondern nur Transport- und Fehlermapping.
final class SupabaseAuthClient {
    private let baseURL: URL
    private let apiKey: String
    
    /// Erstellt einen neuen Auth-Client für die angegebene Supabase-Instanz.
    ///
    /// - Parameters:
    ///   - baseURL: Basis-URL der Supabase-Instanz (z.B. `https://xyz.supabase.co`).
    ///   - apiKey: Service- oder anonymisierter API-Key für Auth-Endpunkte.
    init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Sign Up
    /// Registriert einen neuen Nutzer bei Supabase.
    ///
    /// - Parameters:
    ///   - email: E-Mail-Adresse des Nutzers.
    ///   - password: Passwort für das Konto.
    ///   - username: Anzeigename, der zusätzlich in den User-Metadaten gespeichert wird.
    /// - Returns: `AuthResponse` mit Access- und Refresh-Token sowie User-Daten.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func signUp(email: String, password: String, username: String) async throws -> AuthResponse {
        var url = baseURL
        url.append(path: "/auth/v1/signup")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            // store username in auth user metadata, too
            "data": ["username": username]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 200 {
            do {
                return try JSONDecoder().decode(AuthResponse.self, from: data)
            } catch {
                throw NSError(domain: "SupabaseAuth", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Response konnte nicht verarbeitet werden: \(error.localizedDescription)"])
            }
        } else {
            throw Self.authError(statusCode: http.statusCode, data: data, fallback: L.error_registrationFailed.localized(replacing: ["code": String(http.statusCode)]))
        }
    }
    
    // MARK: - Sign In
    /// Meldet einen bestehenden Nutzer mit E-Mail und Passwort an.
    ///
    /// - Parameters:
    ///   - email: Registrierte E-Mail-Adresse.
    ///   - password: Passwort.
    /// - Returns: `AuthResponse` mit Access- und Refresh-Token.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func signIn(email: String, password: String) async throws -> AuthResponse {
        var url = baseURL
        url.append(path: "/auth/v1/token")
        url.append(queryItems: [URLQueryItem(name: "grant_type", value: "password")])
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body = ["email": email, "password": password]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } else {
            throw Self.authError(statusCode: http.statusCode, data: data, fallback: L.error_signInFailed.localized)
        }
    }
    
    // MARK: - Sign in with Apple (Id Token Exchange)
    /// Führt den Supabase-Login mit einem Apple ID-Token durch.
    ///
    /// - Parameters:
    ///   - idToken: Vom Apple-SDK geliefertes ID-Token.
    ///   - nonce: Optionaler, vom Client gesetzter Nonce-Wert zur Replay-Protection.
    /// - Returns: `AuthResponse` mit Access- und Refresh-Token.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func signInWithApple(idToken: String, nonce: String?) async throws -> AuthResponse {
        var url = baseURL
        url.append(path: "/auth/v1/token")
        url.append(queryItems: [URLQueryItem(name: "grant_type", value: "id_token")])
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        var body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken
        ]
        if let nonce { body["nonce"] = nonce }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } else {
            throw Self.authError(statusCode: http.statusCode, data: data, fallback: L.errorAppleSignInFailed.localized)
        }
    }

    /// After a verified "email already registered" error, the backend links the Apple identity and signs in.
    func signInWithAppleLinkingExistingEmail(idToken: String, nonce: String?) async throws -> AuthResponse {
        guard let nonce, nonce.count >= 8 else {
            throw NSError(
                domain: "SupabaseAuth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: L.errorAppleSignInFailed.localized]
            )
        }
        var url = Config.backendBaseURL
        url.append(path: "/auth/apple")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["id_token": idToken, "nonce": nonce]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await SecureURLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        }
        let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["detail"] as? String
        throw NSError(
            domain: "SupabaseAuth",
            code: http.statusCode,
            userInfo: [NSLocalizedDescriptionKey: detail ?? L.error_appleSignInUseEmail.localized]
        )
    }
    
    // MARK: - Token Refresh
    /// Erneuert eine bestehende Supabase-Session über das Refresh-Token.
    ///
    /// - Parameter refreshToken: Gültiges Refresh-Token.
    /// - Returns: Neue `AuthResponse` mit aktualisierten Tokens.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func refreshSession(refreshToken: String) async throws -> AuthResponse {
        var url = baseURL
        url.append(path: "/auth/v1/token")
        url.append(queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")])
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body = ["refresh_token": refreshToken]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } else {
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(domain: "SupabaseAuth", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? L.error_tokenRefreshFailed.localized])
        }
    }
    
    // MARK: - Sign Out
    /// Meldet den Nutzer bei Supabase ab und invalidiert das Access-Token.
    ///
    /// - Parameter accessToken: Aktuelles Access-Token des Nutzers.
    /// - Throws: `URLError` bei Transportfehlern oder wenn Supabase keinen 204-Status zurückgibt.
    func signOut(accessToken: String) async throws {
        var url = baseURL
        url.append(path: "/auth/v1/logout")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let (_, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Reset Password
    /// Sendet eine Passwort-Reset-E-Mail an die angegebene E-Mail-Adresse.
    ///
    /// - Parameter email: E-Mail-Adresse des Nutzers, für die das Passwort zurückgesetzt werden soll.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func resetPasswordForEmail(email: String) async throws {
        let verifier = PKCE.generateCodeVerifier()
        try KeychainManager.save(key: PasswordResetLink.codeVerifierKeychainKey, value: verifier)

        var url = baseURL
        url.append(path: "/auth/v1/recover")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "redirect_to", value: Config.passwordResetRedirectURL.absoluteString)
        ]
        guard let recoverURL = components?.url else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: recoverURL)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")

        let body = RecoverRequestBody(
            email: email,
            code_challenge: PKCE.codeChallenge(for: verifier),
            code_challenge_method: "s256"
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await SecureURLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Supabase returns 200 on success (even if email doesn't exist, for security)
        if http.statusCode == 200 {
            return
        } else {
            KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(domain: "SupabaseAuth", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? L.error_passwordResetEmailFailed.localized])
        }
    }

    /// Exchanges a one-time PKCE `code` from the Universal Link for a recovery session.
    func exchangePKCECode(_ code: String) async throws -> AuthResponse {
        guard let verifier = KeychainManager.get(key: PasswordResetLink.codeVerifierKeychainKey),
              !verifier.isEmpty else {
            throw NSError(
                domain: "SupabaseAuth",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: L.resetPasswordError.localized]
            )
        }

        var url = baseURL
        url.append(path: "/auth/v1/token")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "pkce")]
        guard let tokenURL = components?.url else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONEncoder().encode(PKCETokenRequest(auth_code: code, code_verifier: verifier))

        let (data, response) = try await SecureURLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if http.statusCode == 200 {
            do {
                let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
                KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
                return decoded
            } catch {
                throw NSError(
                    domain: "SupabaseAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: L.resetPasswordError.localized]
                )
            }
        }
        if (400...499).contains(http.statusCode) {
            KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
        }
        let error = try? JSONDecoder().decode(AuthError.self, from: data)
        throw NSError(domain: "SupabaseAuth", code: http.statusCode,
                     userInfo: [NSLocalizedDescriptionKey: error?.message ?? L.error_passwordResetEmailFailed.localized])
    }
    
    // MARK: - Update Password (from reset token)
    /// Aktualisiert das Passwort eines Nutzers mit einem Reset-Token.
    /// Nach dem Klick auf den Reset-Link ist der User bereits authentifiziert.
    ///
    /// - Parameters:
    ///   - accessToken: Access-Token aus dem Passwort-Reset-Link.
    ///   - refreshToken: Refresh-Token aus dem Passwort-Reset-Link.
    ///   - newPassword: Neues Passwort.
    /// - Returns: `AuthResponse` mit aktualisierten Tokens.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func updatePassword(accessToken: String, refreshToken: String, newPassword: String) async throws -> AuthResponse {
        var url = baseURL
        url.append(path: "/auth/v1/user")
        
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body = ["password": newPassword]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 200 {
            // After password update, refresh the session to get new tokens
            // The user is already authenticated, so we can refresh
            return try await refreshSession(refreshToken: refreshToken)
        } else {
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(domain: "SupabaseAuth", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? L.error_passwordUpdateFailed.localized])
        }
    }
    
    // MARK: - Get User (Check Session)
    /// Ruft die aktuellen User-Daten ab, um zu prüfen, ob eine gültige Session existiert.
    ///
    /// - Parameter accessToken: Optionales Access-Token. Wenn nicht angegeben, wird versucht, es aus dem Keychain zu lesen.
    /// - Returns: User-Daten, falls eine gültige Session existiert.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func getUser(accessToken: String?) async throws -> AuthResponse.User? {
        guard let token = accessToken else {
            return nil
        }
        
        var url = baseURL
        url.append(path: "/auth/v1/user")
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 200 {
            // Supabase returns user data directly
            struct UserResponse: Codable {
                let id: String
                let email: String?
            }
            let user = try JSONDecoder().decode(UserResponse.self, from: data)
            return AuthResponse.User(id: user.id, email: user.email ?? "")
        } else {
            return nil
        }
    }
    
    // MARK: - Change Password
    /// Ändert das Passwort des aktuell angemeldeten Nutzers.
    ///
    /// - Parameters:
    ///   - accessToken: Gültiges Access-Token des Nutzers.
    ///   - newPassword: Neues Passwort.
    /// - Throws: `NSError` mit Supabase-Fehlermessage oder `URLError` bei Transportfehlern.
    func changePassword(accessToken: String, newPassword: String) async throws {
        var url = baseURL
        url.append(path: "/auth/v1/user")
        
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let body = ["password": newPassword]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 200 {
            return
        } else {
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(domain: "SupabaseAuth", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? L.error_passwordChangeFailed.localized])
        }
    }

    static func authError(statusCode: Int, data: Data, fallback: String) -> NSError {
        let decoded = try? JSONDecoder().decode(AuthError.self, from: data)
        let message = (decoded?.message.isEmpty == false) ? decoded!.message : fallback
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: message]
        if let errorCode = decoded?.errorCode, !errorCode.isEmpty {
            userInfo["error_code"] = errorCode
        }
        return NSError(domain: "SupabaseAuth", code: statusCode, userInfo: userInfo)
    }
}

// MARK: - Keychain Storage

/// Kleiner Helper für die gesicherte Ablage von Tokens & Metadaten im iOS-Keychain.
///
/// Achtung: Die API ist bewusst minimal: Strings werden unverändert gespeichert,
/// höherwertige Typen (Date/Bool) werden manuell auf Strings abgebildet.
enum KeychainManager {
    private static let service = "com.moritzserrin.culinachef"
    
    /// Speichert einen String-Wert im Keychain (überschreibt ggf. bestehende Einträge).
    ///
    /// - Parameters:
    ///   - key: Logischer Schlüssel (z.B. "access_token").
    ///   - value: Zu speichernder Wert.
    /// - Throws: `NSError` mit `NSOSStatusErrorDomain`, falls die Operation fehlschlägt.
    static func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // First, try to update existing item
        let updateQuery: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        var status = SecItemUpdate(baseQuery as CFDictionary, updateQuery as CFDictionary)
        
        // If update failed because item doesn't exist, add it
        if status == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        
        // If update failed for other reason, try delete and add
        if status != errSecSuccess && status != errSecItemNotFound {
            // Delete existing item (ignore errors)
            SecItemDelete(baseQuery as CFDictionary)
            // Try to add
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        
        guard status == errSecSuccess else {
            Logger.error("[KeychainManager] Failed to save key '\(key)': OSStatus \(status)", category: .data)
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [
                NSLocalizedDescriptionKey: "Keychain save failed with OSStatus \(status)"
            ])
        }
    }
    
    /// Liest einen String-Wert aus dem Keychain.
    ///
    /// - Parameter key: Logischer Schlüssel.
    /// - Returns: Gefundener Wert oder `nil`, falls kein Eintrag existiert.
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Entfernt einen Eintrag aus dem Keychain (idempotent).
    ///
    /// - Parameter key: Logischer Schlüssel des zu löschenden Eintrags.
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Löscht alle von der App gespeicherten Auth-bezogenen Keychain-Einträge.
    static func deleteAll() {
        let userId = get(key: "user_id")
        delete(key: "access_token")
        delete(key: "refresh_token")
        delete(key: "user_id")
        delete(key: "user_email")
        // Subscription keys
        delete(key: "subscription_last_payment")
        delete(key: "subscription_period_end")
        delete(key: "subscription_autorenew")
        delete(key: "taste_preferences_secure")
        delete(key: "auth_provider")
        delete(key: "apple_user_id")
        delete(key: PasswordResetLink.codeVerifierKeychainKey)
        if let userId, !userId.isEmpty {
            delete(key: DietaryPreferences.storageKey(for: userId))
            delete(key: TastePreferencesManager.storageKey(for: userId))
        }
    }
    
    // MARK: - Date Storage
    /// Speichert ein Datum als Unix-Timestamp im Keychain.
    static func save(key: String, date: Date) throws {
        let timestamp = date.timeIntervalSince1970
        try save(key: key, value: String(timestamp))
    }
    
    /// Liest ein Datum aus einem zuvor gespeicherten Unix-Timestamp.
    static func getDate(key: String) -> Date? {
        guard let value = get(key: key),
              let timestamp = Double(value) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Bool Storage
    /// Speichert einen Bool als "true"/"false" im Keychain.
    static func save(key: String, bool: Bool) throws {
        try save(key: key, value: bool ? "true" : "false")
    }
    
    /// Liest einen Bool aus dem Keychain, der als "true"/"false" gespeichert wurde.
    static func getBool(key: String) -> Bool? {
        guard let value = get(key: key) else {
            return nil
        }
        return value == "true"
    }
}
