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
    }
}

/// Fehlerobjekt, das Supabase bei fehlgeschlagenen Auth-Operationen zurückliefert.
struct AuthError: Codable {
    let message: String
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
            // When email already registered or policy error
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(domain: "SupabaseAuth", code: http.statusCode, 
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? "Registrierung fehlgeschlagen (\(http.statusCode))"])
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
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(domain: "SupabaseAuth", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? "Anmeldung fehlgeschlagen"])
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
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(
                domain: "SupabaseAuth",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: error?.message ?? "Apple Sign-In fehlgeschlagen"]
            )
        }
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
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? "Token-Refresh fehlgeschlagen"])
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
        var url = baseURL
        url.append(path: "/auth/v1/recover")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        // Supabase requires redirectTo URL for password reset
        // For iOS apps, we can use a deep link or a custom URL scheme
        let redirectTo = "culinachef://reset-password"
        let body = ["email": email, "redirect_to": redirectTo]
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Supabase returns 200 on success (even if email doesn't exist, for security)
        if http.statusCode == 200 {
            return
        } else {
            let error = try? JSONDecoder().decode(AuthError.self, from: data)
            throw NSError(domain: "SupabaseAuth", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? "Passwort-Reset-E-Mail konnte nicht gesendet werden"])
        }
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
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? "Passwort-Update fehlgeschlagen"])
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
                let email: String
            }
            let user = try JSONDecoder().decode(UserResponse.self, from: data)
            return AuthResponse.User(id: user.id, email: user.email)
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
                         userInfo: [NSLocalizedDescriptionKey: error?.message ?? "Passwortänderung fehlgeschlagen"])
        }
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
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly  // ✅ Explizit: Nur wenn entsperrt, nur auf diesem Gerät
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
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
        delete(key: "access_token")
        delete(key: "refresh_token")
        delete(key: "user_id")
        delete(key: "user_email")
        // Subscription keys
        delete(key: "subscription_last_payment")
        delete(key: "subscription_period_end")
        delete(key: "subscription_autorenew")
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
