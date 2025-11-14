import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    let id: String
    let user_id: String
    let title: String
    let ingredients: [String]
    let instructions: [String]
    let nutrition: Nutrition
    let created_at: String?
    var is_favorite: Bool?
    var user_email: String? // For community recipes
    var is_public: Bool? // Flag if recipe is shared publicly
    var image_url: String? // Photo URL
    var cooking_time: String? // e.g. "30 Min"
    var difficulty: String? // "Einfach", "Mittel", "Schwer"
    var tags: [String]? // ["Vegan", "Schnell", etc.]
    var rating: Int? // 1-5 stars
    var language: String? // Recipe language ("de", "en", "es", "fr", "it")
}

struct Nutrition: Codable, Equatable {
    let calories: Int?
    let protein_g: Double?
    let carbs_g: Double?
    let fat_g: Double?
}

struct FavoriteResponse: Codable {
    let recipe_id: String
    let favorited: Bool
}
