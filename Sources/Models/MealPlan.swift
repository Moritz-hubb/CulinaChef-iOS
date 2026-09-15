import Foundation

struct MealPlanNutritionTargets: Codable, Equatable {
    var calories: Int?
    var protein_g: Int?
    var fat_g: Int?
    var carbs_g: Int?
    var calories_min: Int?
    var calories_max: Int?
    var protein_min_g: Int?
    var protein_max_g: Int?
    var fat_min_g: Int?
    var fat_max_g: Int?
    var carbs_min_g: Int?
    var carbs_max_g: Int?
}

struct GeneratedMealPlanMeal: Codable, Identifiable {
    var id: String { slot + goal }
    var slot: String
    var goal: String
    var nutrition_target: MealPlanNutritionTargets?
    var recipe: RecipePlan
}

struct GeneratedMealPlan: Codable {
    var title: String
    var meal_count: Int
    var nutrition_mode: String
    var meals: [GeneratedMealPlanMeal]
}

struct SavedMealPlan: Identifiable, Codable, Equatable {
    let id: String
    let user_id: String
    let title: String
    let meal_count: Int
    let nutrition_mode: String
    let nutrition_targets: MealPlanNutritionTargets?
    let dietary_context: String?
    let created_at: String?
}

struct SavedMealPlanItem: Identifiable, Codable, Equatable {
    let id: String
    let meal_plan_id: String
    let recipe_id: String
    let slot: String
    let sort_order: Int
    let nutrition_target: MealPlanNutritionTargets?
}

struct MealPlanMealPreference: Codable, Equatable {
    var slot: String
    var override_diets: Bool
    var categories: [String]
    var spicy_level: Int?
}

enum MealPlanSlot {
    static let selectable: [String] = [
        "breakfast",
        "brunch",
        "lunch",
        "dinner",
        "morning_snack",
        "afternoon_snack",
        "evening_snack",
        "snack",
        "protein_snack",
        "dessert",
        "bedtime",
        "pre_workout",
        "intra_workout",
        "post_workout"
    ]

    static let defaultSelection: [String] = ["breakfast", "lunch", "dinner"]

    static func localizedTitle(_ slot: String) -> String {
        switch slot {
        case "breakfast": return L.mealplan_slot_breakfast.localized
        case "brunch": return L.mealplan_slot_brunch.localized
        case "lunch": return L.mealplan_slot_lunch.localized
        case "dinner": return L.mealplan_slot_dinner.localized
        case "morning_snack": return L.mealplan_slot_morningSnack.localized
        case "afternoon_snack": return L.mealplan_slot_afternoonSnack.localized
        case "evening_snack": return L.mealplan_slot_eveningSnack.localized
        case "snack": return L.mealplan_slot_snack.localized
        case "protein_snack": return L.mealplan_slot_proteinSnack.localized
        case "dessert": return L.mealplan_slot_dessert.localized
        case "bedtime": return L.mealplan_slot_bedtime.localized
        case "pre_workout": return L.mealplan_slot_preWorkout.localized
        case "intra_workout": return L.mealplan_slot_intraWorkout.localized
        case "post_workout": return L.mealplan_slot_postWorkout.localized
        default: return slot
        }
    }
}

extension RecipePlan {
    func asPersistedRecipe(userId: String, languageCode: String, extraTags: [String] = []) -> Recipe {
        let ingredientNames: [String] = ingredients.map { item in
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
        let instructionTexts = steps.map { "⟦label:\($0.title)⟧ " + $0.description }
        let cookStr = total_time_minutes.map { "\($0) Min" }
        var tags: [String] = categories?.map { $0.capitalized } ?? []
        if let filterTags = filter_tags, !filterTags.isEmpty {
            tags.append(contentsOf: filterTags.map { "_filter:\($0.lowercased())" })
        }
        tags.append("_mealplan")
        tags.append(contentsOf: extraTags)
        let lang = languageCode.lowercased()
        if !tags.contains(lang) {
            tags.append(lang)
        }
        return Recipe(
            id: UUID().uuidString,
            user_id: userId,
            title: title,
            ingredients: ingredientNames,
            instructions: instructionTexts,
            nutrition: Nutrition(
                calories: nutrition?.calories,
                protein_g: nutrition?.protein_g,
                carbs_g: nutrition?.carbs_g,
                fat_g: nutrition?.fat_g
            ),
            created_at: nil,
            user_email: nil,
            is_public: false,
            image_url: nil,
            cooking_time: cookStr,
            difficulty: nil,
            tags: tags,
            filter_tags: filter_tags,
            rating: nil,
            language: lang
        )
    }
}
