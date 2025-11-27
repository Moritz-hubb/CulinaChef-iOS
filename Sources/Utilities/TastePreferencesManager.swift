import Foundation

/// Manager for securely storing and retrieving taste preferences in Keychain
/// Replaces unencrypted UserDefaults storage for privacy and security
enum TastePreferencesManager {
    private static let keychainKey = "taste_preferences_secure"
    
    /// Taste preferences data structure
    struct TastePreferences: Codable {
        var spicyLevel: Double = 2.0
        var sweet: Bool = false
        var sour: Bool = false
        var bitter: Bool = false
        var umami: Bool = false
    }
    
    /// Save taste preferences to Keychain (secure storage)
    static func save(_ preferences: TastePreferences) throws {
        Logger.debug("[TastePreferencesManager] save() called - spicyLevel: \(preferences.spicyLevel), sweet: \(preferences.sweet), sour: \(preferences.sour), bitter: \(preferences.bitter), umami: \(preferences.umami)", category: .data)
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        let jsonString = String(data: data, encoding: .utf8) ?? "{}"
        Logger.debug("[TastePreferencesManager] Encoded to JSON: \(jsonString)", category: .data)
        try KeychainManager.save(key: keychainKey, value: jsonString)
        Logger.debug("[TastePreferencesManager] Successfully saved to Keychain", category: .data)
    }
    
    /// Load taste preferences from Keychain (or migrate from UserDefaults if needed)
    static func load() -> TastePreferences {
        Logger.debug("[TastePreferencesManager] load() called", category: .data)
        
        // Try to load from Keychain first
        if let jsonString = KeychainManager.get(key: keychainKey),
           let data = jsonString.data(using: .utf8),
           let preferences = try? JSONDecoder().decode(TastePreferences.self, from: data) {
            Logger.debug("[TastePreferencesManager] Loaded from Keychain - spicyLevel: \(preferences.spicyLevel), sweet: \(preferences.sweet), sour: \(preferences.sour), bitter: \(preferences.bitter), umami: \(preferences.umami)", category: .data)
            return preferences
        } else {
            Logger.debug("[TastePreferencesManager] No data found in Keychain", category: .data)
        }
        
        // Fallback: Try to migrate from old UserDefaults storage
        if let legacyData = UserDefaults.standard.data(forKey: "taste_preferences"),
           let dict = try? JSONSerialization.jsonObject(with: legacyData) as? [String: Any] {
            Logger.debug("[TastePreferencesManager] Found legacy data in UserDefaults, migrating...", category: .data)
            var preferences = TastePreferences()
            preferences.spicyLevel = dict["spicy_level"] as? Double ?? 2.0
            preferences.sweet = dict["sweet"] as? Bool ?? false
            preferences.sour = dict["sour"] as? Bool ?? false
            preferences.bitter = dict["bitter"] as? Bool ?? false
            preferences.umami = dict["umami"] as? Bool ?? false
            
            // Save to Keychain for future use
            try? save(preferences)
            
            // Remove from UserDefaults for security
            UserDefaults.standard.removeObject(forKey: "taste_preferences")
            
            Logger.info("Migrated taste preferences from UserDefaults to Keychain", category: .data)
            return preferences
        }
        
        // Return default preferences if nothing found
        Logger.debug("[TastePreferencesManager] No preferences found, returning defaults - spicyLevel: 2.0, all tastes: false", category: .data)
        return TastePreferences()
    }
    
    /// Convert TastePreferences to dictionary format (for backward compatibility with existing code)
    static func toDictionary(_ preferences: TastePreferences) -> [String: Any] {
        return [
            "spicy_level": preferences.spicyLevel,
            "sweet": preferences.sweet,
            "sour": preferences.sour,
            "bitter": preferences.bitter,
            "umami": preferences.umami
        ]
    }
    
    /// Create TastePreferences from dictionary format (for backward compatibility)
    static func fromDictionary(_ dict: [String: Any]) -> TastePreferences {
        var preferences = TastePreferences()
        preferences.spicyLevel = dict["spicy_level"] as? Double ?? 2.0
        preferences.sweet = dict["sweet"] as? Bool ?? false
        preferences.sour = dict["sour"] as? Bool ?? false
        preferences.bitter = dict["bitter"] as? Bool ?? false
        preferences.umami = dict["umami"] as? Bool ?? false
        return preferences
    }
    
    /// Delete taste preferences from Keychain
    static func delete() {
        KeychainManager.delete(key: keychainKey)
        UserDefaults.standard.removeObject(forKey: "taste_preferences")
    }
}
