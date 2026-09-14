import Foundation

@MainActor
final class MealPlanStore {
    func fetchPlans(accessToken: String, userId: String) async throws -> [SavedMealPlan] {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/meal_plans")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "id,user_id,title,meal_count,nutrition_mode,nutrition_targets,dietary_context,created_at"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([SavedMealPlan].self, from: data)
    }

    func fetchItems(accessToken: String, planId: String) async throws -> [SavedMealPlanItem] {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/meal_plan_items")
        url.append(queryItems: [
            URLQueryItem(name: "meal_plan_id", value: "eq.\(planId)"),
            URLQueryItem(name: "select", value: "id,meal_plan_id,recipe_id,slot,sort_order,nutrition_target"),
            URLQueryItem(name: "order", value: "sort_order.asc")
        ])
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([SavedMealPlanItem].self, from: data)
    }

    func saveGeneratedPlan(
        _ plan: GeneratedMealPlan,
        recipes: [Recipe],
        nutritionMode: String,
        nutritionTargets: MealPlanNutritionTargets,
        dietaryContext: String?,
        accessToken: String,
        userId: String
    ) async throws -> SavedMealPlan {
        guard recipes.count == plan.meals.count else {
            throw URLError(.cannotParseResponse)
        }

        var savedRecipes: [Recipe] = []
        for recipe in recipes {
            savedRecipes.append(try await insertRecipe(recipe, accessToken: accessToken, userId: userId))
        }

        let created = try await insertPlan(
            title: String(plan.title.prefix(200)),
            mealCount: plan.meal_count,
            nutritionMode: nutritionMode,
            nutritionTargets: nutritionTargets,
            dietaryContext: dietaryContext,
            accessToken: accessToken,
            userId: userId
        )

        for (idx, meal) in plan.meals.enumerated() {
            try await insertItem(
                planId: created.id,
                recipeId: savedRecipes[idx].id,
                slot: String(meal.slot.prefix(40)),
                sortOrder: idx,
                nutritionTarget: meal.nutrition_target,
                accessToken: accessToken
            )
        }
        return created
    }

    func deletePlan(id: String, accessToken: String) async throws {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/meal_plans")
        url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(id)")])
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (_, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func insertRecipe(_ recipe: Recipe, accessToken: String, userId: String) async throws -> Recipe {
        let nutritionDict: [String: Any] = [
            "calories": recipe.nutrition?.calories ?? 0,
            "protein_g": recipe.nutrition?.protein_g ?? 0,
            "carbs_g": recipe.nutrition?.carbs_g ?? 0,
            "fat_g": recipe.nutrition?.fat_g ?? 0
        ]
        var body: [String: Any] = [
            "user_id": userId,
            "title": String(recipe.title.prefix(200)),
            "ingredients": recipe.ingredients ?? [],
            "instructions": recipe.instructions ?? [],
            "nutrition": nutritionDict,
            "is_public": false
        ]
        if let cook = recipe.cooking_time, !cook.isEmpty {
            body["cooking_time"] = cook
        }
        if let tags = recipe.tags, !tags.isEmpty {
            body["tags"] = tags
        }
        if let filter = recipe.filter_tags, !filter.isEmpty {
            body["filter_tags"] = filter
        }
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let rows = try JSONDecoder().decode([Recipe].self, from: data)
        guard let first = rows.first else { throw URLError(.cannotParseResponse) }
        return first
    }

    private func insertPlan(
        title: String,
        mealCount: Int,
        nutritionMode: String,
        nutritionTargets: MealPlanNutritionTargets,
        dietaryContext: String?,
        accessToken: String,
        userId: String
    ) async throws -> SavedMealPlan {
        struct Row: Encodable {
            let user_id: String
            let title: String
            let meal_count: Int
            let nutrition_mode: String
            let nutrition_targets: MealPlanNutritionTargets
            let dietary_context: String?
        }
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/meal_plans")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode([
            Row(
                user_id: userId,
                title: title,
                meal_count: mealCount,
                nutrition_mode: nutritionMode,
                nutrition_targets: nutritionTargets,
                dietary_context: dietaryContext
            )
        ])
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let rows = try JSONDecoder().decode([SavedMealPlan].self, from: data)
        guard let first = rows.first else { throw URLError(.cannotParseResponse) }
        return first
    }

    private func insertItem(
        planId: String,
        recipeId: String,
        slot: String,
        sortOrder: Int,
        nutritionTarget: MealPlanNutritionTargets?,
        accessToken: String
    ) async throws {
        struct Row: Encodable {
            let meal_plan_id: String
            let recipe_id: String
            let slot: String
            let sort_order: Int
            let nutrition_target: MealPlanNutritionTargets?
        }
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/meal_plan_items")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode([
            Row(
                meal_plan_id: planId,
                recipe_id: recipeId,
                slot: slot,
                sort_order: sortOrder,
                nutrition_target: nutritionTarget
            )
        ])
        let (_, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
