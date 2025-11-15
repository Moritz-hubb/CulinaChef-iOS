import Foundation

final class BackendClient {
    let baseURL: URL
    init(baseURL: URL) { self.baseURL = baseURL }

    private func request(path: String, method: String = "GET", token: String?, jsonBody: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        var url = baseURL
        url.append(path: path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = token { req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body = jsonBody {
            req.httpBody = body
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        // Add Accept-Language header for backend language detection
        let preferredLanguages = Locale.preferredLanguages.prefix(3).joined(separator: ", ")
        req.addValue(preferredLanguages, forHTTPHeaderField: "Accept-Language")
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if !(200...299).contains(http.statusCode) {
            struct ServerError: Decodable { let detail: String? }
            if let err = try? JSONDecoder().decode(ServerError.self, from: data), let msg = err.detail, !msg.isEmpty {
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            if let msg = String(data: data, encoding: .utf8), !msg.isEmpty {
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }

    func health() async throws {
        _ = try await request(path: "/health", token: nil)
    }

    func listRecipes(accessToken: String) async throws -> [Recipe] {
        let (data, _) = try await request(path: "/recipes", token: accessToken)
        return try JSONDecoder().decode([Recipe].self, from: data)
    }

    func generateRecipe(ingredients: [String], accessToken: String) async throws -> Recipe {
        struct Body: Encodable { 
            let ingredients: [String]
            let language: String?
        }
        
        // Detect device language
        let deviceLanguage: String? = {
            let langCode = Locale.current.language.languageCode?.identifier ?? "de"
            // Map to supported languages (de, en, es, fr, it)
            switch langCode {
            case "de": return "de"
            case "en": return "en"
            case "es": return "es"
            case "fr": return "fr"
            case "it": return "it"
            default: return "de"  // Default to German
            }
        }()
        
        let body = Body(ingredients: ingredients, language: deviceLanguage)
        let data = try JSONEncoder().encode(body)
        let (respData, _) = try await request(path: "/ai/generate_recipe", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(Recipe.self, from: respData)
    }

    func toggleFavorite(recipeId: String, accessToken: String) async throws -> FavoriteResponse {
        struct Body: Encodable { let recipe_id: String }
        let data = try JSONEncoder().encode(Body(recipe_id: recipeId))
        let (respData, _) = try await request(path: "/favorites/toggle", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(FavoriteResponse.self, from: respData)
    }

    // Rate limiting: increment and check server-side counters
    // If originalTransactionId is provided, uses transaction-based limiting (prevents multi-account abuse)
    // If nil, uses user-based limiting (free tier)
    func incrementAIUsage(accessToken: String, originalTransactionId: String? = nil) async throws -> (daily: Int, monthly: Int) {
        struct Body: Encodable { let original_transaction_id: String? }
        let body = Body(original_transaction_id: originalTransactionId)
        let jsonBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await request(path: "/ai/usage/increment", method: "POST", token: accessToken, jsonBody: jsonBody)
        struct Counts: Decodable { let daily_count: Int; let monthly_count: Int }
        let c = try JSONDecoder().decode(Counts.self, from: data)
        return (c.daily_count, c.monthly_count)
    }

    // Subscription status from backend
    struct SubscriptionStatusDTO: Decodable {
        let user_id: String
        let plan: String
        let status: String
        let auto_renew: Bool
        let cancel_at_period_end: Bool
        let last_payment_at: String?
        let current_period_end: String?
        let price_cents: Int?
        let currency: String?
        let is_active: Bool
    }

    func subscriptionStatus(accessToken: String) async throws -> SubscriptionStatusDTO {
        let (data, _) = try await request(path: "/subscription/status", token: accessToken)
        return try JSONDecoder().decode(SubscriptionStatusDTO.self, from: data)
    }
    
    // MARK: - Ratings
    
    struct RatingResponse: Decodable {
        let id: String
        let recipe_id: String
        let user_id: String
        let rating: Int
        let created_at: String
    }
    
    struct RecipeRatingsResponse: Decodable {
        let recipe_id: String
        let average_rating: Double
        let total_ratings: Int
        let user_rating: Int?
        let ratings: [RatingResponse]
    }
    
    func rateRecipe(recipeId: String, rating: Int, accessToken: String) async throws -> RatingResponse {
        struct Body: Encodable { let recipe_id: String; let rating: Int }
        let data = try JSONEncoder().encode(Body(recipe_id: recipeId, rating: rating))
        let (respData, _) = try await request(path: "/recipes/\(recipeId)/rate", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(RatingResponse.self, from: respData)
    }
    
    func getRecipeRatings(recipeId: String, accessToken: String) async throws -> RecipeRatingsResponse {
        let (data, _) = try await request(path: "/recipes/\(recipeId)/ratings", token: accessToken)
        return try JSONDecoder().decode(RecipeRatingsResponse.self, from: data)
    }
    
    func deleteRating(recipeId: String, accessToken: String) async throws {
        _ = try await request(path: "/recipes/\(recipeId)/rating", method: "DELETE", token: accessToken)
    }
}
