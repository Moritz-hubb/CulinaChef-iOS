import Foundation

/// Lokale Darstellung der Ernährungspräferenzen eines Nutzers.
///
/// Wird für In-Memory-State und Persistenz in `UserDefaults` verwendet.
struct DietaryPreferences: Codable, Equatable {
    var diets: Set<String> = []
    var allergies: [String] = []
    var dislikes: [String] = []
    var notes: String? = nil
}

extension DietaryPreferences {
    static let storageKey = "dietary_preferences"

    static func load() -> DietaryPreferences {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey),
           let obj = try? JSONDecoder().decode(DietaryPreferences.self, from: data) {
            return obj
        }
        return DietaryPreferences()
    }

    /// Persistiert die aktuellen Präferenzen in `UserDefaults`.
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
