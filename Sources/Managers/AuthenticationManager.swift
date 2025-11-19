import Foundation

/// Manager for all authentication operations (sign in, sign up, sign out, Apple Sign-In)
/// Extracted from AppState to improve maintainability and separation of concerns
@MainActor
final class AuthenticationManager {
    
    // MARK: - Dependencies
    
    private let auth: SupabaseAuthClient
    private let preferencesClient: UserPreferencesClient
    
    init(auth: SupabaseAuthClient, preferencesClient: UserPreferencesClient) {
        self.auth = auth
        self.preferencesClient = preferencesClient
    }
    
    // MARK: - Sign In
    
    struct SignInResult {
        let accessToken: String
        let refreshToken: String
        let userId: String
        let email: String
    }
    
    func signIn(email: String, password: String) async throws -> SignInResult {
        let response = try await auth.signIn(email: email, password: password)
        
        try KeychainManager.save(key: "access_token", value: response.access_token)
        try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
        try KeychainManager.save(key: "user_id", value: response.user.id)
        try KeychainManager.save(key: "user_email", value: response.user.email)
        
        // Load onboarding status from backend
        await loadOnboardingStatusFromBackend(userId: response.user.id, accessToken: response.access_token)
        
        return SignInResult(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            userId: response.user.id,
            email: response.user.email
        )
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, username: String) async throws -> SignInResult {
        // Require non-empty username at app level
        let uname = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uname.isEmpty else {
            throw NSError(domain: "SignUp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bitte Benutzernamen angeben"])
        }
        
        let response = try await auth.signUp(email: email, password: password, username: uname)
        
        try KeychainManager.save(key: "access_token", value: response.access_token)
        try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
        try KeychainManager.save(key: "user_id", value: response.user.id)
        try KeychainManager.save(key: "user_email", value: response.user.email)
        
        // Create/Upsert profile with unique username
        // If profile saving fails, log it but don't fail the entire signup
        // The account is already created, so we can retry profile creation later
        do {
            try await upsertProfile(userId: response.user.id, username: uname, accessToken: response.access_token)
        } catch {
            #if DEBUG
            print("[AuthenticationManager] Warning: Profile could not be saved during signup: \(error.localizedDescription)")
            print("[AuthenticationManager] User account was created successfully. Profile can be created/updated later.")
            #endif
            // Don't throw - account is created, profile can be fixed later
            // The user can still use the app, and profile will be created on next login or profile update
        }
        
        return SignInResult(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            userId: response.user.id,
            email: response.user.email
        )
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple(idToken: String, nonce: String?) async throws -> SignInResult {
        let response = try await auth.signInWithApple(idToken: idToken, nonce: nonce)
        
        try KeychainManager.save(key: "access_token", value: response.access_token)
        try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
        try KeychainManager.save(key: "user_id", value: response.user.id)
        try KeychainManager.save(key: "user_email", value: response.user.email)
        
        // Load onboarding status from backend
        await loadOnboardingStatusFromBackend(userId: response.user.id, accessToken: response.access_token)
        
        return SignInResult(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            userId: response.user.id,
            email: response.user.email
        )
    }
    
    // MARK: - Reset Password
    
    /// Sendet eine Passwort-Reset-E-Mail an die angegebene E-Mail-Adresse.
    ///
    /// - Parameter email: E-Mail-Adresse des Nutzers.
    /// - Throws: Fehler aus `SupabaseAuthClient`.
    func resetPassword(email: String) async throws {
        try await auth.resetPasswordForEmail(email: email)
    }
    
    /// Aktualisiert das Passwort mit einem Reset-Token.
    ///
    /// - Parameters:
    ///   - accessToken: Access-Token aus dem Passwort-Reset-Link.
    ///   - refreshToken: Refresh-Token aus dem Passwort-Reset-Link.
    ///   - newPassword: Neues Passwort.
    /// - Returns: `SignInResult` mit neuen Tokens.
    /// - Throws: Fehler aus `SupabaseAuthClient`.
    func updatePassword(accessToken: String, refreshToken: String, newPassword: String) async throws -> SignInResult {
        let response = try await auth.updatePassword(accessToken: accessToken, refreshToken: refreshToken, newPassword: newPassword)
        
        try KeychainManager.save(key: "access_token", value: response.access_token)
        try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
        try KeychainManager.save(key: "user_id", value: response.user.id)
        try KeychainManager.save(key: "user_email", value: response.user.email)
        
        return SignInResult(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            userId: response.user.id,
            email: response.user.email
        )
    }
    
    // MARK: - Sign Out
    
    func signOut(accessToken: String?) async {
        if let token = accessToken {
            try? await auth.signOut(accessToken: token)
        }
        
        // Preserve user id for consent cleanup before wiping Keychain
        let userIdForConsent = KeychainManager.get(key: "user_id")
        
        KeychainManager.deleteAll()
        
        // Remove only the OpenAI consent for the previous user to prevent cache bleeding
        if let uid = userIdForConsent {
            let key = "openai_consent_granted_\(uid)"
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // MARK: - Profile Management
    
    struct ProfileRow: Codable {
        let user_id: String
        let username: String
        let full_name: String?
        let email: String?
    }
    
    func fetchProfile(accessToken: String?, userId: String?) async throws -> ProfileRow? {
        guard let token = accessToken, let uid = userId else { return nil }
        
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/profiles")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(uid)"),
            URLQueryItem(name: "select", value: "user_id,username,full_name,email"),
            URLQueryItem(name: "limit", value: "1")
        ])
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
        
        let rows = try JSONDecoder().decode([ProfileRow].self, from: data)
        return rows.first
    }
    
    func saveProfile(fullName: String?, email: String?, accessToken: String?, userId: String?, userEmail: String?) async throws {
        guard let token = accessToken, let uid = userId else {
            throw NSError(domain: "Profiles", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        
        // Keep existing username (required) or fallback to email prefix
        let current = try await fetchProfile(accessToken: token, userId: uid)
        let uname = current?.username ?? (userEmail?.split(separator: "@").first.map(String.init) ?? "user")
        try await upsertProfile(userId: uid, username: uname, accessToken: token, fullName: fullName?.nilIfBlank(), email: email?.nilIfBlank())
    }
    
    private func upsertProfile(userId: String, username: String, accessToken: String, fullName: String? = nil, email: String? = nil) async throws {
        struct Row: Encodable {
            let user_id: String
            let username: String
            let full_name: String?
            let email: String?
        }
        
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/profiles")
        url.append(queryItems: [URLQueryItem(name: "on_conflict", value: "user_id")])
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode([Row(user_id: userId, username: username, full_name: fullName, email: email)])
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "Profiles", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profil konnte nicht gespeichert werden: Ungültige Server-Antwort"])
        }
        
        // Accept 200 (OK), 201 (Created), and 204 (No Content) as success
        // Also accept 409 (Conflict) if profile already exists (upsert should handle this)
        let successCodes = [200, 201, 204]
        let acceptableCodes = successCodes + [409] // 409 might occur if profile exists but upsert didn't work as expected
        
        if !successCodes.contains(http.statusCode) {
            #if DEBUG
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("[AuthenticationManager] Profile upsert response: Status \(http.statusCode)")
            print("[AuthenticationManager] Response body: \(responseBody)")
            #endif
            
            if acceptableCodes.contains(http.statusCode) {
                // 409 Conflict might mean profile already exists - this is actually OK for upsert
                #if DEBUG
                print("[AuthenticationManager] Profile upsert returned \(http.statusCode) - treating as success (profile may already exist)")
                #endif
                return
            }
            
            // Try to decode error message from response
            let errorMessage: String
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorData["message"] ?? errorData["error"] {
                errorMessage = "Profil konnte nicht gespeichert werden: \(message)"
            } else {
                errorMessage = "Profil konnte nicht gespeichert werden (Status: \(http.statusCode))"
            }
            
            throw NSError(domain: "Profiles", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        #if DEBUG
        print("[AuthenticationManager] Profile successfully saved/updated (Status: \(http.statusCode))")
        #endif
    }
    
    // MARK: - Onboarding Status
    
    private func loadOnboardingStatusFromBackend(userId: String, accessToken: String) async {
        do {
            // Fetch user preferences from backend
            if let preferences = try await preferencesClient.fetchPreferences(userId: userId, accessToken: accessToken) {
                // User has preferences in backend - set local flag based on backend value
                let key = "onboarding_completed_\(userId)"
                UserDefaults.standard.set(preferences.onboardingCompleted, forKey: key)
                Logger.debug("Loaded onboarding status from backend: \(preferences.onboardingCompleted)", category: .auth)
            } else {
                // No preferences in backend - user hasn't completed onboarding
                let key = "onboarding_completed_\(userId)"
                UserDefaults.standard.set(false, forKey: key)
                Logger.debug("No preferences found in backend - onboarding not completed", category: .auth)
            }
        } catch {
            // If fetch fails, default to false (show onboarding)
            let key = "onboarding_completed_\(userId)"
            UserDefaults.standard.set(false, forKey: key)
            Logger.error("Failed to load onboarding status from backend, defaulting to false", error: error, category: .auth)
        }
    }
}

// MARK: - String Extension Helper

private extension String {
    func nilIfBlank() -> String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
