import Foundation

/// Manager für lokal gespeicherte Likes (nicht in der Datenbank)
/// Speichert nur die Recipe-IDs in UserDefaults
@MainActor
final class LikedRecipesManager: ObservableObject {
    @Published private(set) var likedRecipeIds: Set<String> = []
    
    private let storageKey = "liked_recipe_ids"
    
    init() {
        load()
    }
    
    /// Lädt die gelikten Rezept-IDs aus UserDefaults
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            likedRecipeIds = decoded
        }
    }
    
    /// Speichert die gelikten Rezept-IDs in UserDefaults
    private func save() {
        if let encoded = try? JSONEncoder().encode(likedRecipeIds) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    /// Prüft, ob ein Rezept geliked ist
    func isLiked(recipeId: String) -> Bool {
        likedRecipeIds.contains(recipeId)
    }
    
    /// Toggle Like für ein Rezept
    func toggleLike(recipeId: String) {
        if likedRecipeIds.contains(recipeId) {
            likedRecipeIds.remove(recipeId)
        } else {
            likedRecipeIds.insert(recipeId)
        }
        save()
    }
    
    /// Like ein Rezept
    func like(recipeId: String) {
        guard !likedRecipeIds.contains(recipeId) else { return }
        likedRecipeIds.insert(recipeId)
        save()
    }
    
    /// Unlike ein Rezept
    func unlike(recipeId: String) {
        guard likedRecipeIds.contains(recipeId) else { return }
        likedRecipeIds.remove(recipeId)
        save()
    }
    
    /// Entfernt alle Likes (z.B. beim Logout)
    func clearAll() {
        likedRecipeIds.removeAll()
        save()
    }
}
