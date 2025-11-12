import Foundation

/// RatingsClient now uses FastAPI Backend instead of direct Supabase calls
final class RatingsClient {
    let backendClient: BackendClient
    
    init(backendClient: BackendClient) {
        self.backendClient = backendClient
    }

    /// Fetch average rating for a recipe from Backend API
    func fetchAverageRating(recipeId: String, accessToken: String) async throws -> Double? {
        let response = try await backendClient.getRecipeRatings(recipeId: recipeId, accessToken: accessToken)
        return response.total_ratings > 0 ? response.average_rating : nil
    }

    /// Rate a recipe via Backend API (automatically handles insert/update)
    func upsertRating(recipeId: String, rating: Int, accessToken: String, userId: String) async throws {
        _ = try await backendClient.rateRecipe(recipeId: recipeId, rating: rating, accessToken: accessToken)
    }
    
    /// Delete user's rating for a recipe
    func deleteRating(recipeId: String, accessToken: String) async throws {
        try await backendClient.deleteRating(recipeId: recipeId, accessToken: accessToken)
    }
}
