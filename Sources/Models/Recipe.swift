import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    let id: String
    let user_id: String
    let title: String
    let ingredients: [String]? // Optional for preview recipes
    let instructions: [String]? // Optional for preview recipes
    let nutrition: Nutrition? // Optional for preview recipes
    let created_at: String?
    var is_favorite: Bool?
    var user_email: String? // For community recipes
    var is_public: Bool? // Flag if recipe is shared publicly
    var image_url: String? // Photo URL
    var cooking_time: String? // e.g. "30 Min"
    var difficulty: String? // "Einfach", "Mittel", "Schwer"
    var tags: [String]? // ["Vegan", "Schnell", etc.]
    var filter_tags: [String]? // Hidden filter tags from AI (vegan, vegetarian, gluten-free, etc.)
    var rating: Int? // 1-5 stars
    var language: String? // Recipe language ("de", "en", "es", "fr", "it")
    
    // Check if this is a preview (missing full data)
    var isPreview: Bool {
        return ingredients == nil || instructions == nil || nutrition == nil
    }
    
    // Explicit CodingKeys enum (required when using custom decoder)
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case title
        case ingredients
        case instructions
        case nutrition
        case created_at
        case is_favorite
        case user_email
        case is_public
        case image_url
        case cooking_time
        case difficulty
        case tags
        case filter_tags
        case rating
        case language
    }
    
    // Normal initializer (required since we have custom decoder)
    init(
        id: String,
        user_id: String,
        title: String,
        ingredients: [String]? = nil,
        instructions: [String]? = nil,
        nutrition: Nutrition? = nil,
        created_at: String? = nil,
        is_favorite: Bool? = nil,
        user_email: String? = nil,
        is_public: Bool? = nil,
        image_url: String? = nil,
        cooking_time: String? = nil,
        difficulty: String? = nil,
        tags: [String]? = nil,
        filter_tags: [String]? = nil,
        rating: Int? = nil,
        language: String? = nil
    ) {
        self.id = id
        self.user_id = user_id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.nutrition = nutrition
        self.created_at = created_at
        self.is_favorite = is_favorite
        self.user_email = user_email
        self.is_public = is_public
        self.image_url = image_url
        self.cooking_time = cooking_time
        self.difficulty = difficulty
        self.tags = tags
        self.filter_tags = filter_tags
        self.rating = rating
        self.language = language
    }
    
    // Custom decoder to handle missing fields gracefully (for preview recipes)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user_id = try container.decode(String.self, forKey: .user_id)
        title = try container.decode(String.self, forKey: .title)
        
        // Decode optional fields - use nil if missing (for preview recipes)
        ingredients = try? container.decode([String].self, forKey: .ingredients)
        instructions = try? container.decode([String].self, forKey: .instructions)
        nutrition = try? container.decode(Nutrition.self, forKey: .nutrition)
        
        created_at = try? container.decode(String.self, forKey: .created_at)
        is_favorite = try? container.decode(Bool.self, forKey: .is_favorite)
        user_email = try? container.decode(String.self, forKey: .user_email)
        is_public = try? container.decode(Bool.self, forKey: .is_public)
        image_url = try? container.decode(String.self, forKey: .image_url)
        cooking_time = try? container.decode(String.self, forKey: .cooking_time)
        difficulty = try? container.decode(String.self, forKey: .difficulty)
        tags = try? container.decode([String].self, forKey: .tags)
        filter_tags = try? container.decode([String].self, forKey: .filter_tags)
        rating = try? container.decode(Int.self, forKey: .rating)
        language = try? container.decode(String.self, forKey: .language)
    }
    
    // Custom encoder (standard implementation, but explicit for clarity)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(ingredients, forKey: .ingredients)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(nutrition, forKey: .nutrition)
        try container.encodeIfPresent(created_at, forKey: .created_at)
        try container.encodeIfPresent(is_favorite, forKey: .is_favorite)
        try container.encodeIfPresent(user_email, forKey: .user_email)
        try container.encodeIfPresent(is_public, forKey: .is_public)
        try container.encodeIfPresent(image_url, forKey: .image_url)
        try container.encodeIfPresent(cooking_time, forKey: .cooking_time)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(filter_tags, forKey: .filter_tags)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(language, forKey: .language)
    }
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
