import Foundation
import Security

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let user: User
    
    struct User: Codable {
        let id: String
        let email: String
    }
}

struct AuthError: Codable {
    let message: String
}

final class SupabaseAuthClient {
    private let baseURL: URL
    private let apiKey: String
    
    init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Sign Up
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
    
    // MARK: - Change Password
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
enum KeychainManager {
    private static let service = "com.moritzserrin.culinachef"
    
    static func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
    
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
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
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
    static func save(key: String, date: Date) throws {
        let timestamp = date.timeIntervalSince1970
        try save(key: key, value: String(timestamp))
    }
    
    static func getDate(key: String) -> Date? {
        guard let value = get(key: key),
              let timestamp = Double(value) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Bool Storage
    static func save(key: String, bool: Bool) throws {
        try save(key: key, value: bool ? "true" : "false")
    }
    
    static func getBool(key: String) -> Bool? {
        guard let value = get(key: key) else {
            return nil
        }
        return value == "true"
    }
}
