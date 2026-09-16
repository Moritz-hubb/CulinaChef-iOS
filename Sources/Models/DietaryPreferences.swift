import Foundation

/// Lokale Darstellung der Ernährungspräferenzen eines Nutzers.
/// Persistenz: Keychain (Gesundheitsdaten), migriert aus UserDefaults.
struct DietaryPreferences: Codable, Equatable {
    var diets: Set<String> = []
    var allergies: [String] = []
    var dislikes: [String] = []
    var notes: String? = nil
}

extension DietaryPreferences {
    /// Pre-user-scoping key. Must not be used for new writes.
    static let storageKey = "dietary_preferences"

    static func storageKey(for userId: String) -> String {
        "\(storageKey)_\(userId)"
    }

    static func load(userId: String? = KeychainManager.get(key: "user_id")) -> DietaryPreferences {
        let defaults = UserDefaults.standard
        guard let userId, !userId.isEmpty else {
            defaults.removeObject(forKey: storageKey)
            return DietaryPreferences()
        }

        if let stored = decodeFromKeychain(userId: userId) {
            clearUserDefaults(userId: userId)
            return stored
        }

        if let data = defaults.data(forKey: storageKey(for: userId)),
           let obj = try? JSONDecoder().decode(DietaryPreferences.self, from: data) {
            try? persistToKeychain(obj, userId: userId)
            clearUserDefaults(userId: userId)
            return obj
        }

        if let data = defaults.data(forKey: storageKey),
           let obj = try? JSONDecoder().decode(DietaryPreferences.self, from: data) {
            try? persistToKeychain(obj, userId: userId)
            clearUserDefaults(userId: userId)
            return obj
        }

        return DietaryPreferences()
    }

    func save(userId: String? = KeychainManager.get(key: "user_id")) {
        guard let userId, !userId.isEmpty else { return }
        try? Self.persistToKeychain(self, userId: userId)
        Self.clearUserDefaults(userId: userId)
    }

    static func removeAll(for userId: String?) {
        clearUserDefaults(userId: userId)
        if let userId, !userId.isEmpty {
            KeychainManager.delete(key: storageKey(for: userId))
        }
    }

    private static func persistToKeychain(_ prefs: DietaryPreferences, userId: String) throws {
        let data = try JSONEncoder().encode(prefs)
        guard let json = String(data: data, encoding: .utf8) else { return }
        try KeychainManager.save(key: storageKey(for: userId), value: json)
    }

    private static func decodeFromKeychain(userId: String) -> DietaryPreferences? {
        guard let json = KeychainManager.get(key: storageKey(for: userId)),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(DietaryPreferences.self, from: data)
    }

    private static func clearUserDefaults(userId: String?) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: "allergies")
        defaults.removeObject(forKey: "dietary_types")
        if let userId, !userId.isEmpty {
            defaults.removeObject(forKey: storageKey(for: userId))
        }
    }
}
