import Foundation

struct NutritionInfo: Codable {
    var calories: Int?
    var protein_g: Double?
    var fat_g: Double?
    var carbs_g: Double?
    var fiber_g: Double?
    var sugar_g: Double?
    var salt_g: Double?
}

struct IngredientItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var amount: Double?
    var unit: String?

    enum CodingKeys: String, CodingKey { case name, amount, unit }
    init(id: UUID = UUID(), name: String, amount: Double? = nil, unit: String? = nil) {
        self.id = id; self.name = name; self.amount = amount; self.unit = unit
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try c.decode(String.self, forKey: .name)
        self.amount = try? c.decode(Double.self, forKey: .amount)
        self.unit = try? c.decode(String.self, forKey: .unit)
    }
}

struct RecipeStep: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var duration_minutes: Int?

    enum CodingKeys: String, CodingKey { case title, description, duration_minutes }
    init(id: UUID = UUID(), title: String, description: String, duration_minutes: Int? = nil) {
        self.id = id; self.title = title; self.description = description; self.duration_minutes = duration_minutes
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = (try? c.decode(String.self, forKey: .title)) ?? ""
        self.description = (try? c.decode(String.self, forKey: .description)) ?? ""
        self.duration_minutes = try? c.decode(Int.self, forKey: .duration_minutes)
    }
}

struct RecipePlan: Codable {
    var title: String
    var servings: Int?
    var total_time_minutes: Int?
    var categories: [String]?
    var nutrition: NutritionInfo?
    var ingredients: [IngredientItem]
    var equipment: [String]?
    var steps: [RecipeStep]
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case title, servings, total_time_minutes, categories, nutrition, ingredients, equipment, steps, notes
    }

    init(title: String = "", servings: Int? = nil, total_time_minutes: Int? = nil, categories: [String]? = nil, nutrition: NutritionInfo? = nil, ingredients: [IngredientItem] = [], equipment: [String]? = nil, steps: [RecipeStep] = [], notes: String? = nil) {
        self.title = title
        self.servings = servings
        self.total_time_minutes = total_time_minutes
        self.categories = categories
        self.nutrition = nutrition
        self.ingredients = ingredients
        self.equipment = equipment
        self.steps = steps
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.title = (try? c.decode(String.self, forKey: .title)) ?? ""
        self.servings = try? c.decode(Int.self, forKey: .servings)
        self.total_time_minutes = try? c.decode(Int.self, forKey: .total_time_minutes)
        self.categories = try? c.decode([String].self, forKey: .categories)
        self.nutrition = try? c.decode(NutritionInfo.self, forKey: .nutrition)
        self.ingredients = (try? c.decode([IngredientItem].self, forKey: .ingredients)) ?? []
        self.equipment = try? c.decode([String].self, forKey: .equipment)
        self.steps = (try? c.decode([RecipeStep].self, forKey: .steps)) ?? []
        self.notes = try? c.decode(String.self, forKey: .notes)
    }
}

struct NutritionConstraint: Codable {
    var calories_min: Int?
    var calories_max: Int?
    var protein_min_g: Int?
    var protein_max_g: Int?
    var fat_min_g: Int?
    var fat_max_g: Int?
    var carbs_min_g: Int?
    var carbs_max_g: Int?
}