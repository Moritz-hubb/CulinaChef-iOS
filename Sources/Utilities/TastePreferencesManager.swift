import Foundation

/// Manager for securely storing and retrieving taste preferences in Keychain.
/// Keys are scoped per user so account switches cannot reuse another profile's tastes.
enum TastePreferencesManager {
    static let legacyKeychainKey = "taste_preferences_secure"

    /// Taste preferences data structure
    struct TastePreferences: Codable, Equatable {
        var spicyLevel: Double = 2.0
        var sweet: Bool = false
        var sour: Bool = false
        var bitter: Bool = false
        var umami: Bool = false
    }

    static func storageKey(for userId: String) -> String {
        "\(legacyKeychainKey)_\(userId)"
    }

    static func clampedSpicyIndex(_ level: Double) -> Int {
        let labels = 4
        guard level.isFinite else { return 2 }
        let index = Int(level.rounded(.towardZero))
        return min(max(index, 0), labels - 1)
    }

    /// Save taste preferences to Keychain (secure storage)
    static func save(_ preferences: TastePreferences, userId: String? = KeychainManager.get(key: "user_id")) throws {
        guard let userId, !userId.isEmpty else {
            Logger.debug("[TastePreferencesManager] save skipped — no user_id", category: .data)
            return
        }
        Logger.debug("[TastePreferencesManager] save() called", category: .data)
        let encoder = JSONEncoder()
        let data = try encoder.encode(sanitized(preferences))
        let jsonString = String(data: data, encoding: .utf8) ?? "{}"
        try KeychainManager.save(key: storageKey(for: userId), value: jsonString)
        KeychainManager.delete(key: legacyKeychainKey)
        Logger.debug("[TastePreferencesManager] Successfully saved to Keychain", category: .data)
    }

    /// Load taste preferences from Keychain (or migrate from UserDefaults if needed)
    static func load(userId: String? = KeychainManager.get(key: "user_id")) -> TastePreferences {
        Logger.debug("[TastePreferencesManager] load() called", category: .data)
        guard let userId, !userId.isEmpty else {
            return TastePreferences()
        }

        if let stored = decode(fromKey: storageKey(for: userId)) {
            return stored
        }

        if let legacy = decode(fromKey: legacyKeychainKey) {
            try? save(legacy, userId: userId)
            KeychainManager.delete(key: legacyKeychainKey)
            return legacy
        }

        if let legacyData = UserDefaults.standard.data(forKey: "taste_preferences"),
           let dict = try? JSONSerialization.jsonObject(with: legacyData) as? [String: Any] {
            Logger.debug("[TastePreferencesManager] Found legacy data in UserDefaults, migrating...", category: .data)
            let preferences = fromDictionary(dict)
            try? save(preferences, userId: userId)
            UserDefaults.standard.removeObject(forKey: "taste_preferences")
            Logger.info("Migrated taste preferences from UserDefaults to Keychain", category: .data)
            return preferences
        }

        Logger.debug("[TastePreferencesManager] No preferences found, returning defaults", category: .data)
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

    static func delete() {
        delete(for: KeychainManager.get(key: "user_id"))
    }

    static func delete(for userId: String?) {
        if let userId, !userId.isEmpty {
            KeychainManager.delete(key: storageKey(for: userId))
        }
        KeychainManager.delete(key: legacyKeychainKey)
        UserDefaults.standard.removeObject(forKey: "taste_preferences")
    }

    private static func decode(fromKey key: String) -> TastePreferences? {
        guard let jsonString = KeychainManager.get(key: key),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(TastePreferences.self, from: data)
    }

    private static func sanitized(_ preferences: TastePreferences) -> TastePreferences {
        var copy = preferences
        copy.spicyLevel = Double(clampedSpicyIndex(preferences.spicyLevel))
        return copy
    }
}
