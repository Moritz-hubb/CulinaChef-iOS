import XCTest
@testable import CulinaChef

/// Unit tests for UserPreferencesClient
/// Tests fetch/upsert preferences, dietary data sync, and error handling
final class UserPreferencesClientTests: XCTestCase {
    
    var client: UserPreferencesClient!
    
    override func setUp() {
        super.setUp()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        
        let testURL = URL(string: "https://test.supabase.co")!
        client = UserPreferencesClient(baseURL: testURL, apiKey: "test_key")
        
        MockURLProtocol.reset()
    }
    
    override func tearDown() {
        SecureURLSession.testConfiguration = nil
        MockURLProtocol.reset()
        client = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Preferences Tests
    
    func testFetchPreferencesSuccess() async throws {
        let mockResponse = """
        [{
            "user_id": "user123",
            "allergies": ["nuts", "dairy"],
            "dietary_types": ["vegan", "glutenfrei"],
            "taste_preferences": {
                "spicy_level": 3.5,
                "sweet": true,
                "sour": false,
                "bitter": null,
                "umami": true
            },
            "dislikes": ["mushrooms"],
            "notes": "Test notes",
            "onboarding_completed": true,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-15T10:00:00Z"
        }]
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockResponse.data(using: .utf8))
        
        let prefs = try await client.fetchPreferences(userId: "user123", accessToken: "token")
        
        XCTAssertNotNil(prefs)
        XCTAssertEqual(prefs?.userId, "user123")
        XCTAssertEqual(prefs?.allergies, ["nuts", "dairy"])
        XCTAssertEqual(prefs?.dietaryTypes, ["vegan", "glutenfrei"])
        XCTAssertEqual(prefs?.dislikes, ["mushrooms"])
        XCTAssertEqual(prefs?.notes, "Test notes")
        XCTAssertTrue(prefs?.onboardingCompleted ?? false)
        XCTAssertEqual(prefs?.tastePreferences.spicyLevel, 3.5)
        XCTAssertEqual(prefs?.tastePreferences.sweet, true)
    }
    
    func testFetchPreferencesNotFound() async throws {
        MockURLProtocol.mockResponse(statusCode: 200, data: "[]".data(using: .utf8))
        
        let prefs = try await client.fetchPreferences(userId: "nonexistent", accessToken: "token")
        
        XCTAssertNil(prefs)
    }
    
    func testFetchPreferences404() async throws {
        MockURLProtocol.mockResponse(statusCode: 404)
        
        let prefs = try await client.fetchPreferences(userId: "user123", accessToken: "token")
        
        XCTAssertNil(prefs)
    }
    
    func testFetchPreferencesUnauthorized() async {
        MockURLProtocol.mockResponse(statusCode: 401)
        
        do {
            _ = try await client.fetchPreferences(userId: "user123", accessToken: "invalid")
            XCTFail("Should throw error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "UserPreferencesClient")
            XCTAssertEqual(error.code, 401)
        }
    }
    
    func testFetchPreferencesNetworkError() async {
        MockURLProtocol.mockError(URLError(.notConnectedToInternet))
        
        do {
            _ = try await client.fetchPreferences(userId: "user123", accessToken: "token")
            XCTFail("Should throw network error")
        } catch {
            // Expected
        }
    }
    
    // MARK: - Upsert Preferences Tests
    
    func testUpsertPreferencesSuccess() async throws {
        let mockResponse = """
        [{
            "user_id": "user123",
            "allergies": ["lactose"],
            "dietary_types": ["vegetarian"]
        }]
        """
        MockURLProtocol.mockResponse(statusCode: 201, data: mockResponse.data(using: .utf8))
        
        let tastePrefs: [String: Any] = [
            "spicy_level": 2.0,
            "sweet": true,
            "sour": false
        ]
        
        try await client.upsertPreferences(
            userId: "user123",
            allergies: ["lactose"],
            dietaryTypes: ["vegetarian"],
            tastePreferences: tastePrefs,
            dislikes: ["olives"],
            notes: "New user",
            onboardingCompleted: true,
            accessToken: "token"
        )
        
        // No error = success
    }
    
    func testUpsertPreferencesUpdate() async throws {
        MockURLProtocol.mockResponse(statusCode: 200, data: Data())
        
        try await client.upsertPreferences(
            userId: "user123",
            allergies: ["updated"],
            dietaryTypes: ["vegan"],
            tastePreferences: [:],
            dislikes: [],
            notes: nil,
            onboardingCompleted: true,
            accessToken: "token"
        )
    }
    
    func testUpsertPreferencesUnauthorized() async {
        MockURLProtocol.mockResponse(statusCode: 401)
        
        do {
            try await client.upsertPreferences(
                userId: "user123",
                allergies: [],
                dietaryTypes: [],
                tastePreferences: [:],
                dislikes: [],
                notes: nil,
                onboardingCompleted: false,
                accessToken: "invalid"
            )
            XCTFail("Should throw error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "UserPreferencesClient")
            XCTAssertEqual(error.code, 401)
        }
    }
    
    func testUpsertPreferencesServerError() async {
        MockURLProtocol.mockResponse(statusCode: 500)
        
        do {
            try await client.upsertPreferences(
                userId: "user123",
                allergies: [],
                dietaryTypes: [],
                tastePreferences: [:],
                dislikes: [],
                notes: nil,
                onboardingCompleted: false,
                accessToken: "token"
            )
            XCTFail("Should throw error")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 500)
        }
    }
    
    // MARK: - Update Preferences Tests
    
    func testUpdatePreferencesSuccess() async throws {
        MockURLProtocol.mockResponse(statusCode: 200)
        
        try await client.updatePreferences(
            userId: "user123",
            allergies: ["gluten"],
            dietaryTypes: ["vegan"],
            tastePreferences: ["spicy_level": 4.0],
            dislikes: ["onions"],
            notes: "Updated",
            accessToken: "token"
        )
    }
    
    func testUpdatePreferences204() async throws {
        MockURLProtocol.mockResponse(statusCode: 204)
        
        try await client.updatePreferences(
            userId: "user123",
            allergies: [],
            dietaryTypes: [],
            tastePreferences: [:],
            dislikes: [],
            notes: nil,
            accessToken: "token"
        )
    }
    
    // MARK: - Edge Cases
    
    func testFetchPreferencesWithNullOptionals() async throws {
        let mockResponse = """
        [{
            "user_id": "user123",
            "allergies": [],
            "dietary_types": [],
            "taste_preferences": {
                "spicy_level": 0.0,
                "sweet": null,
                "sour": null,
                "bitter": null,
                "umami": null
            },
            "dislikes": [],
            "notes": null,
            "onboarding_completed": false,
            "created_at": null,
            "updated_at": null
        }]
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockResponse.data(using: .utf8))
        
        let prefs = try await client.fetchPreferences(userId: "user123", accessToken: "token")
        
        XCTAssertNotNil(prefs)
        XCTAssertNil(prefs?.notes)
        XCTAssertNil(prefs?.tastePreferences.sweet)
    }
    
    func testUpsertPreferencesEmptyArrays() async throws {
        MockURLProtocol.mockResponse(statusCode: 201)
        
        try await client.upsertPreferences(
            userId: "user123",
            allergies: [],
            dietaryTypes: [],
            tastePreferences: [:],
            dislikes: [],
            notes: nil,
            onboardingCompleted: false,
            accessToken: "token"
        )
    }
}
