import XCTest
@testable import CulinaChef

final class OpenAIClientTests: XCTestCase {
    
    var client: OpenAIClient!
    
    override func setUp() {
        super.setUp()
        client = OpenAIClient(apiKey: "test_api_key_123", session: .mock)
        MockURLProtocol.reset()
    }
    
    override func tearDown() {
        MockURLProtocol.reset()
        client = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitWithValidAPIKey() {
        let client = OpenAIClient(apiKey: "valid_key", session: .mock)
        XCTAssertNotNil(client)
    }
    
    func testInitWithEmptyAPIKey() {
        let client = OpenAIClient(apiKey: "", session: .mock)
        XCTAssertNil(client)
    }
    
    func testInitWithNilAPIKey() {
        let client = OpenAIClient(apiKey: nil, session: .mock)
        XCTAssertNil(client)
    }
    
    // MARK: - Chat Reply Tests
    
    func testChatReplySuccess() async throws {
        // Arrange
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "Das ist eine Testantwort von der KI."
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockResponse.data(using: .utf8),
            headers: ["Content-Type": "application/json"]
        )
        
        let messages = [
            ChatMessage(role: .user, text: "Wie koche ich Pasta?")
        ]
        
        // Act
        let reply = try await client.chatReply(messages: messages)
        
        // Assert
        XCTAssertFalse(reply.isEmpty)
        XCTAssertEqual(reply, "Das ist eine Testantwort von der KI.")
    }
    
    func testChatReplyWithEmptyResponse() async throws {
        // Arrange
        let mockResponse = """
        {
            "choices": []
        }
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockResponse.data(using: .utf8)
        )
        
        let messages = [ChatMessage(role: .user, text: "Test")]
        
        // Act
        let reply = try await client.chatReply(messages: messages)
        
        // Assert
        XCTAssertTrue(reply.isEmpty)
    }
    
    func testChatReplyWithMultipleMessages() async throws {
        // Arrange
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "Hier ist eine detaillierte Antwort."
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockResponse.data(using: .utf8))
        
        let messages = [
            ChatMessage(role: .system, text: "Du bist ein Koch-Assistent."),
            ChatMessage(role: .user, text: "Wie koche ich Pasta?"),
            ChatMessage(role: .assistant, text: "Pasta kochen..."),
            ChatMessage(role: .user, text: "Und wie lange?")
        ]
        
        // Act
        let reply = try await client.chatReply(messages: messages)
        
        // Assert
        XCTAssertFalse(reply.isEmpty)
    }
    
    // MARK: - Recipe Generation Tests
    
    func testGenerateRecipePlanSuccess() async throws {
        // Arrange
        let mockRecipeJSON = """
        {
            "title": "Spaghetti Carbonara",
            "servings": 4,
            "total_time_minutes": 30,
            "categories": ["Pasta", "Italian"],
            "nutrition": {
                "calories": 450,
                "protein_g": 18,
                "fat_g": 22,
                "carbs_g": 48,
                "fiber_g": 3,
                "sugar_g": 2,
                "salt_g": 1.5
            },
            "ingredients": [
                {"name": "Spaghetti", "amount": 400, "unit": "g"},
                {"name": "Eier", "amount": 4, "unit": "Stück"},
                {"name": "Parmesan", "amount": 100, "unit": "g"}
            ],
            "equipment": ["Topf", "Pfanne", "Reibe"],
            "steps": [
                {
                    "title": "Pasta kochen",
                    "description": "Wasser zum Kochen bringen und Pasta 8-10 Min al dente kochen.",
                    "duration_minutes": 10
                },
                {
                    "title": "Sauce vorbereiten",
                    "description": "Eier mit Parmesan verrühren.",
                    "duration_minutes": 5
                }
            ],
            "notes": "Traditionelles italienisches Rezept"
        }
        """
        
        let mockOpenAIResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "\(mockRecipeJSON.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: ""))"
                    }
                }
            ]
        }
        """
        
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockOpenAIResponse.data(using: .utf8)
        )
        
        // Act
        let recipe = try await client.generateRecipePlan(
            goal: "Spaghetti Carbonara",
            timeMinutesMin: nil,
            timeMinutesMax: 30,
            nutrition: NutritionConstraint(
                calories_min: nil,
                calories_max: 500,
                protein_min_g: nil,
                protein_max_g: nil,
                fat_min_g: nil,
                fat_max_g: nil,
                carbs_min_g: nil,
                carbs_max_g: nil
            ),
            categories: ["Pasta"],
            servings: 4
        )
        
        // Assert
        XCTAssertEqual(recipe.title, "Spaghetti Carbonara")
        XCTAssertEqual(recipe.servings, 4)
        XCTAssertEqual(recipe.total_time_minutes, 30)
        XCTAssertEqual(recipe.ingredients.count, 3)
        XCTAssertEqual(recipe.steps.count, 2)
        XCTAssertEqual(recipe.nutrition?.calories, 450)
    }
    
    func testGenerateRecipePlanWithNonRecipeRequest() async {
        // Arrange
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "NO_RECIPE_REQUEST"
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockResponse.data(using: .utf8))
        
        // Act & Assert
        do {
            _ = try await client.generateRecipePlan(
                goal: "Was ist 2+2?",
                timeMinutesMin: nil,
                timeMinutesMax: nil,
                nutrition: NutritionConstraint(
                    calories_min: nil, calories_max: nil,
                    protein_min_g: nil, protein_max_g: nil,
                    fat_min_g: nil, fat_max_g: nil,
                    carbs_min_g: nil, carbs_max_g: nil
                ),
                categories: [],
                servings: 4
            )
            XCTFail("Should throw notARecipeRequest error")
        } catch OpenAIClient.RecipeError.notARecipeRequest {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testGenerateRecipePlanWithImpossibleRecipe() async {
        // Arrange
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "IMPOSSIBLE_RECIPE: Ein halales Schweinefleischgericht ist nicht möglich, da Schweinefleisch im Islam als haram gilt."
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockResponse.data(using: .utf8))
        
        // Act & Assert
        do {
            _ = try await client.generateRecipePlan(
                goal: "Halales Schweinebraten",
                timeMinutesMin: nil,
                timeMinutesMax: nil,
                nutrition: NutritionConstraint(
                    calories_min: nil, calories_max: nil,
                    protein_min_g: nil, protein_max_g: nil,
                    fat_min_g: nil, fat_max_g: nil,
                    carbs_min_g: nil, carbs_max_g: nil
                ),
                categories: [],
                servings: 4
            )
            XCTFail("Should throw impossibleRecipe error")
        } catch OpenAIClient.RecipeError.impossibleRecipe(let explanation) {
            XCTAssertTrue(explanation.contains("haram"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Network Error Tests
    
    func testChatReplyWithNetworkTimeout() async {
        // Arrange
        MockURLProtocol.mockError(URLError(.timedOut))
        
        let messages = [ChatMessage(role: .user, text: "Test")]
        
        // Act & Assert
        do {
            _ = try await client.chatReply(messages: messages)
            XCTFail("Should throw timeout error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testChatReplyWithNoInternetConnection() async {
        // Arrange
        MockURLProtocol.mockError(URLError(.notConnectedToInternet))
        
        let messages = [ChatMessage(role: .user, text: "Test")]
        
        // Act & Assert
        do {
            _ = try await client.chatReply(messages: messages)
            XCTFail("Should throw network error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testChatReplyWithUnauthorized() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 401)
        
        let messages = [ChatMessage(role: .user, text: "Test")]
        
        // Act & Assert
        do {
            _ = try await client.chatReply(messages: messages)
            XCTFail("Should throw error for 401")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testChatReplyWithRateLimit() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 429)
        
        let messages = [ChatMessage(role: .user, text: "Test")]
        
        // Act & Assert
        do {
            _ = try await client.chatReply(messages: messages)
            XCTFail("Should throw error for rate limit")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    // MARK: - Image Analysis Tests
    
    func testAnalyzeImageSuccess() async throws {
        // Arrange
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "Auf dem Bild sind folgende Zutaten: 200g Tomaten, 1 Zwiebel, 3 Knoblauchzehen."
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockResponse.data(using: .utf8))
        
        let testImage = UIImage(systemName: "photo")!
        let imageData = testImage.pngData()!
        
        // Act
        let result = try await client.analyzeImage(imageData, userPrompt: "Was siehst du auf dem Bild?")
        
        // Assert
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("Tomaten"))
    }
    
    // MARK: - Message Trimming Tests
    
    func testChatReplyTrimsToMaxHistory() async throws {
        // Arrange
        let mockResponse = """
        {
            "choices": [
                {
                    "message": {
                        "content": "Antwort"
                    }
                }
            ]
        }
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockResponse.data(using: .utf8))
        
        // Create 20 messages (should trim to last 8)
        var messages: [ChatMessage] = []
        for i in 1...20 {
            messages.append(ChatMessage(role: .user, text: "Message \(i)"))
        }
        
        // Act
        let reply = try await client.chatReply(messages: messages, maxHistory: 8)
        
        // Assert
        XCTAssertFalse(reply.isEmpty)
        // Note: Can't directly verify trimming without inspecting request,
        // but this tests that the function handles large message arrays
    }
}
