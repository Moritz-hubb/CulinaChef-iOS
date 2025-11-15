import Foundation
@testable import CulinaChef

/// Mock Supabase Auth responses for testing
enum MockSupabaseResponses {
    
    // MARK: - Success Responses
    
    static func successAuthResponse(
        accessToken: String = "mock_access_token_abc123",
        refreshToken: String = "mock_refresh_token_xyz789",
        userId: String = "user_test_123",
        email: String = "test@example.com"
    ) -> AuthResponse {
        return AuthResponse(
            access_token: accessToken,
            refresh_token: refreshToken,
            user: AuthResponse.User(id: userId, email: email)
        )
    }
    
    static func successAuthResponseData() throws -> Data {
        let response = successAuthResponse()
        return try JSONEncoder().encode(response)
    }
    
    // MARK: - Error Responses
    
    static func errorResponse(message: String = "Invalid credentials") -> Data {
        let json = ["message": message]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    static func invalidEmailError() -> Data {
        errorResponse(message: "Invalid email format")
    }
    
    static func userNotFoundError() -> Data {
        errorResponse(message: "User not found")
    }
    
    static func invalidPasswordError() -> Data {
        errorResponse(message: "Invalid password")
    }
    
    static func tokenExpiredError() -> Data {
        errorResponse(message: "Token has expired")
    }
    
    static func rateLimitError() -> Data {
        errorResponse(message: "Rate limit exceeded. Please try again later.")
    }
    
    static func emailAlreadyRegisteredError() -> Data {
        errorResponse(message: "Email already registered")
    }
    
    static func weakPasswordError() -> Data {
        errorResponse(message: "Password is too weak. Must be at least 6 characters.")
    }
    
    // MARK: - Row Level Security Errors
    
    static func rlsPolicyViolation() -> Data {
        errorResponse(message: "Row level security policy violation")
    }
    
    static func insufficientPermissions() -> Data {
        errorResponse(message: "Insufficient permissions to access this resource")
    }
    
    // MARK: - Network/Server Errors
    
    static func networkTimeoutError() -> URLError {
        URLError(.timedOut)
    }
    
    static func noInternetConnectionError() -> URLError {
        URLError(.notConnectedToInternet)
    }
    
    static func badServerResponseError() -> URLError {
        URLError(.badServerResponse)
    }
    
    static func dnsLookupFailedError() -> URLError {
        URLError(.cannotFindHost)
    }
    
    // MARK: - Database Responses
    
    static func emptyArrayResponse() -> Data {
        let json: [[String: Any]] = []
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    static func singleRecipeResponse(
        id: String = "recipe_123",
        title: String = "Test Recipe",
        ingredients: [String] = ["100g Flour", "2 Eggs"],
        instructions: [String] = ["Mix", "Bake"]
    ) -> Data {
        let json: [String: Any] = [
            "id": id,
            "title": title,
            "ingredients": ingredients,
            "instructions": instructions,
            "nutrition": [
                "calories": 350,
                "protein_g": 12,
                "carbs_g": 45,
                "fat_g": 8
            ],
            "is_public": false,
            "cooking_time": "30 Min",
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        return try! JSONSerialization.data(withJSONObject: [json])
    }
    
    // MARK: - Subscription Responses
    
    static func activeSubscriptionResponse() -> Data {
        let json: [String: Any] = [
            "user_id": "user_123",
            "plan": "unlimited",
            "status": "active",
            "auto_renew": true,
            "cancel_at_period_end": false,
            "last_payment_at": ISO8601DateFormatter().string(from: Date()),
            "current_period_end": ISO8601DateFormatter().string(from: Date().addingTimeInterval(30*24*60*60)),
            "price_cents": 599,
            "currency": "EUR",
            "is_active": true
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    static func expiredSubscriptionResponse() -> Data {
        let json: [String: Any] = [
            "user_id": "user_123",
            "plan": "unlimited",
            "status": "expired",
            "auto_renew": false,
            "cancel_at_period_end": true,
            "last_payment_at": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-60*24*60*60)),
            "current_period_end": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-30*24*60*60)),
            "price_cents": 599,
            "currency": "EUR",
            "is_active": false
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
