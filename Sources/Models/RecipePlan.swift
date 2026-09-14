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
    var filter_tags: [String]?  // Auto-detected filter tags (vegan, vegetarian, etc.)
    var nutrition: NutritionInfo?
    var ingredients: [IngredientItem]
    var equipment: [String]?
    var steps: [RecipeStep]
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case title, servings, total_time_minutes, categories, filter_tags, nutrition, ingredients, equipment, steps, notes
    }

    init(title: String = "", servings: Int? = nil, total_time_minutes: Int? = nil, categories: [String]? = nil, filter_tags: [String]? = nil, nutrition: NutritionInfo? = nil, ingredients: [IngredientItem] = [], equipment: [String]? = nil, steps: [RecipeStep] = [], notes: String? = nil) {
        self.title = title
        self.servings = servings
        self.total_time_minutes = total_time_minutes
        self.categories = categories
        self.filter_tags = filter_tags
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
        self.filter_tags = try? c.decode([String].self, forKey: .filter_tags)
        self.nutrition = try? c.decode(NutritionInfo.self, forKey: .nutrition)
        self.ingredients = (try? c.decode([IngredientItem].self, forKey: .ingredients)) ?? []
        self.equipment = try? c.decode([String].self, forKey: .equipment)
        self.steps = (try? c.decode([RecipeStep].self, forKey: .steps)) ?? []
        self.notes = try? c.decode(String.self, forKey: .notes)
    }

    var ingredientLines: [String] {
        ingredients.map { item in
            var parts: [String] = []
            if let amount = item.amount {
                let amountStr = amount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(amount))
                    : String(format: "%.1f", amount)
                parts.append(amountStr)
            }
            if let unit = item.unit, !unit.isEmpty {
                parts.append(unit)
            }
            parts.append(item.name)
            return parts.joined(separator: " ")
        }
    }

    var instructionLines: [String] {
        steps.map { "⟦label:\($0.title)⟧ " + $0.description }
    }

    func reviseSourceSnapshot() -> BackendClient.ReviseSourceSnapshot {
        let cooking = total_time_minutes.map { "\($0) Min" }
        var nut: Nutrition?
        if let n = nutrition {
            nut = Nutrition(
                calories: n.calories,
                protein_g: n.protein_g,
                carbs_g: n.carbs_g,
                fat_g: n.fat_g
            )
        }
        return BackendClient.ReviseSourceSnapshot(
            title: title,
            ingredients: ingredientLines,
            instructions: instructionLines,
            nutrition: nut,
            language: nil,
            cooking_time: cooking,
            filter_tags: filter_tags,
            servings: servings,
            total_time_minutes: total_time_minutes,
            categories: categories
        )
    }

    static func fromRevisedRecipe(_ recipe: Recipe, previous: RecipePlan) -> RecipePlan {
        let ings = (recipe.ingredients ?? []).map { IngredientItem(name: $0) }
        let steps: [RecipeStep] = (recipe.instructions ?? []).enumerated().map { idx, text in
            Self.parseInstructionLine(text, fallbackIndex: idx + 1)
        }
        var minutes = previous.total_time_minutes
        if let cook = recipe.cooking_time {
            let digits = cook.split(whereSeparator: { !$0.isNumber }).first
            if let digits, let n = Int(digits) { minutes = n }
        }
        var filterTags = recipe.filter_tags
        if filterTags == nil, let tags = recipe.tags {
            let extracted = tags.compactMap { tag -> String? in
                guard tag.hasPrefix("_filter:") else { return nil }
                return String(tag.dropFirst("_filter:".count))
            }
            if !extracted.isEmpty { filterTags = extracted }
        }
        let visibleCats = recipe.tagsForDisplay.filter { $0.count > 2 && $0 != (recipe.language ?? "") }
        let nutritionInfo: NutritionInfo? = recipe.nutrition.map {
            NutritionInfo(
                calories: $0.calories,
                protein_g: $0.protein_g,
                fat_g: $0.fat_g,
                carbs_g: $0.carbs_g
            )
        }
        return RecipePlan(
            title: recipe.title.isEmpty ? previous.title : recipe.title,
            servings: previous.servings,
            total_time_minutes: minutes,
            categories: visibleCats.isEmpty ? previous.categories : visibleCats,
            filter_tags: filterTags ?? previous.filter_tags,
            nutrition: nutritionInfo ?? previous.nutrition,
            ingredients: ings.isEmpty ? previous.ingredients : ings,
            equipment: previous.equipment,
            steps: steps.isEmpty ? previous.steps : steps,
            notes: recipe.revision_note ?? previous.notes
        )
    }

    private static func parseInstructionLine(_ text: String, fallbackIndex: Int) -> RecipeStep {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = "⟦label:"
        if trimmed.hasPrefix(prefix), let end = trimmed.range(of: "⟧") {
            let titleStart = trimmed.index(trimmed.startIndex, offsetBy: prefix.count)
            let title = String(trimmed[titleStart..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let desc = String(trimmed[end.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return RecipeStep(
                title: title.isEmpty ? String(fallbackIndex) : title,
                description: desc.isEmpty ? trimmed : desc
            )
        }
        return RecipeStep(title: String(fallbackIndex), description: trimmed)
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