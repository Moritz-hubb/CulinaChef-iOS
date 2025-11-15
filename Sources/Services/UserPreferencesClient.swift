import Foundation

/// Vollständiger Preferences-Datensatz eines Nutzers aus der Tabelle `user_preferences`.
struct UserPreferences: Codable {
    let userId: String
    let allergies: [String]
    let dietaryTypes: [String]
    let tastePreferences: TastePreferences
    let dislikes: [String]
    let notes: String?
    let onboardingCompleted: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case allergies
        case dietaryTypes = "dietary_types"
        case tastePreferences = "taste_preferences"
        case dislikes
        case notes
        case onboardingCompleted = "onboarding_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Sub-Datensatz für Geschmackspräferenzen des Nutzers.
    struct TastePreferences: Codable {
        let spicyLevel: Double
        let sweet: Bool?
        let sour: Bool?
        let bitter: Bool?
        let umami: Bool?
        
        enum CodingKeys: String, CodingKey {
            case spicyLevel = "spicy_level"
            case sweet
            case sour
            case bitter
            case umami
        }
    }
}

// UserPreferencesRequest removed - we use direct dictionary encoding instead

/// Client für CRUD-Operationen auf der Supabase-Tabelle `user_preferences`.
final class UserPreferencesClient {
    private let baseURL: URL
    private let apiKey: String
    
    init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Fetch User Preferences
    /// Lädt die gespeicherten Preferences eines Nutzers aus Supabase.
    ///
    /// - Parameters:
    ///   - userId: Supabase-User-ID.
    ///   - accessToken: Access-Token für den REST-Call.
    /// - Returns: Preferences-Datensatz oder `nil`, wenn noch keine Zeile existiert.
    /// - Throws: `NSError` bei HTTP-Fehlern oder `URLError` bei Transportfehlern.
    func fetchPreferences(userId: String, accessToken: String) async throws -> UserPreferences? {
        Logger.sensitive("[UserPreferencesClient] Fetching preferences for user: \(userId)", category: .data)
        var url = baseURL
        url.append(path: "/rest/v1/user_preferences")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*")
        ])
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 200 {
            let preferences = try JSONDecoder().decode([UserPreferences].self, from: data)
            if preferences.isEmpty {
                // No preferences found in DB - return nil to trigger fallback
                return nil
            }
            return preferences.first
        } else if http.statusCode == 404 {
            return nil
        } else {
            // Log the error for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                Logger.error("[UserPreferencesClient] Fetch error (\(http.statusCode)): \(errorString)", category: .data)
            }
            throw NSError(domain: "UserPreferencesClient", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Preferences konnten nicht geladen werden"])
        }
    }
    
    // MARK: - Upsert User Preferences
    /// Legt einen Preferences-Datensatz an oder aktualisiert ihn per Upsert.
    ///
    /// - Parameters:
    ///   - userId: Supabase-User-ID.
    ///   - allergies: Liste von Allergenen.
    ///   - dietaryTypes: Ernährungsformen (vegan, vegetarisch, ...).
    ///   - tastePreferences: Wörterbuch für Geschmackspräferenzen (wird als JSON gespeichert).
    ///   - dislikes: Liste von Zutaten, die vermieden werden sollen.
    ///   - notes: Freitext-Notizen.
    ///   - onboardingCompleted: Flag, ob der Onboarding-Flow abgeschlossen ist.
    ///   - accessToken: Access-Token für den REST-Call.
    /// - Throws: `NSError` mit Fehlermessage der REST-API oder `URLError` bei Transportfehlern.
    func upsertPreferences(
        userId: String,
        allergies: [String],
        dietaryTypes: [String],
        tastePreferences: [String: Any],
        dislikes: [String],
        notes: String?,
        onboardingCompleted: Bool,
        accessToken: String
    ) async throws {
        var url = baseURL
        url.append(path: "/rest/v1/user_preferences")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer") // Upsert behavior
        
        let body: [String: Any] = [
            "user_id": userId,
            "allergies": allergies,
            "dietary_types": Array(dietaryTypes),
            "taste_preferences": tastePreferences,
            "dislikes": dislikes,
            "notes": notes ?? "",
            "onboarding_completed": onboardingCompleted
        ]
        
        // Debug logging
        Logger.sensitive("[UserPreferencesClient] Upserting preferences for user: \(userId)", category: .data)
        Logger.sensitive("[UserPreferencesClient] Dietary types: \(dietaryTypes)", category: .data)
        Logger.sensitive("[UserPreferencesClient] Allergies: \(allergies)", category: .data)
        
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Debug logging
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.debug("[UserPreferences] Status: \(http.statusCode)", category: .data)
            Logger.debug("[UserPreferences] Response: \(responseString)", category: .data)
        }
        
        if http.statusCode != 200 && http.statusCode != 201 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
            throw NSError(domain: "UserPreferencesClient", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Preferences konnten nicht gespeichert werden: \(errorMessage)"])
        }
    }
    
    // MARK: - Update Preferences
    /// Aktualisiert bestehende Preferences via `PATCH`, ohne Zeilen anzulegen.
    ///
    /// - Parameters:
    ///   - userId: Supabase-User-ID.
    ///   - allergies: Aktualisierte Liste der Allergene.
    ///   - dietaryTypes: Aktualisierte Ernährungsformen.
    ///   - tastePreferences: Aktualisierte Geschmackspräferenzen.
    ///   - dislikes: Aktualisierte Dislikes-Liste.
    ///   - notes: Aktualisierte Notizen.
    ///   - accessToken: Access-Token für den REST-Call.
    /// - Throws: `NSError` bei HTTP-Fehlern oder `URLError` bei Transportfehlern.
    func updatePreferences(
        userId: String,
        allergies: [String],
        dietaryTypes: [String],
        tastePreferences: [String: Any],
        dislikes: [String],
        notes: String?,
        accessToken: String
    ) async throws {
        var url = baseURL
        url.append(path: "/rest/v1/user_preferences")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ])
        
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "allergies": allergies,
            "dietary_types": Array(dietaryTypes),
            "taste_preferences": tastePreferences,
            "dislikes": dislikes,
            "notes": notes ?? "",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await SecureURLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode != 200 && http.statusCode != 204 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
            throw NSError(domain: "UserPreferencesClient", code: http.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Preferences konnten nicht aktualisiert werden: \(errorMessage)"])
        }
    }
}
