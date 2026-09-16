import XCTest
@testable import CulinaChef

final class BackendClientTests: XCTestCase {
    
    var client: BackendClient!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        
        // Configure SecureURLSession to use MockURLProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        
        // Use mock URL session
        mockSession = URLSession.mock
        client = BackendClient(baseURL: URL(string: "https://api.test.com")!)
    }
    
    override func tearDown() {
        MockURLProtocol.reset()
        SecureURLSession.testConfiguration = nil
        client = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - Health Check Tests
    
    func testHealthSuccess() async throws {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 200)
        
        // Act & Assert
        try await client.health()
    }
    
    func testHealthFailure() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 500)
        
        // Act & Assert
        do {
            try await client.health()
            XCTFail("Should throw error for 500 status code")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    // MARK: - Subscription Status Tests
    
    func testSubscriptionStatusSuccess() async throws {
        // Arrange
        let mockData = MockSupabaseResponses.activeSubscriptionResponse()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        let status = try await client.subscriptionStatus(accessToken: "test_token")
        
        // Assert
        XCTAssertEqual(status.plan, "unlimited")
        XCTAssertTrue(status.is_active)
        XCTAssertTrue(status.auto_renew)
    }
    
    func testSubscriptionStatusUnauthorized() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 401)
        
        // Act & Assert
        do {
            _ = try await client.subscriptionStatus(accessToken: "invalid_token")
            XCTFail("Should throw error for 401")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkTimeout() async {
        // Arrange
        MockURLProtocol.mockError(MockSupabaseResponses.networkTimeoutError())
        
        // Act & Assert
        do {
            try await client.health()
            XCTFail("Should throw timeout error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testNoInternetConnection() async {
        MockURLProtocol.mockError(MockSupabaseResponses.noInternetConnectionError())
        
        do {
            try await client.health()
            XCTFail("Should throw network error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Wrong error type")
        }
    }

    func testIncrementAIUsageSwallowsServerErrorsBecauseCountsAreReadOnly() async throws {
        MockURLProtocol.mockResponse(
            statusCode: 500,
            data: #"{"detail":"temporary"}"#.data(using: .utf8)
        )
        let counts = try await client.incrementAIUsage(accessToken: "token")
        XCTAssertEqual(counts.daily, 0)
        XCTAssertEqual(counts.monthly, 0)
    }

    func testIncrementAIUsageStillThrowsSubscriptionRequired() async {
        let body = #"{"error_code":"SUBSCRIPTION_REQUIRED","detail":{"error_code":"SUBSCRIPTION_REQUIRED","message":"Aktives Abo ist erforderlich"}}"#
        MockURLProtocol.mockResponse(statusCode: 403, data: body.data(using: .utf8))
        do {
            _ = try await client.incrementAIUsage(accessToken: "token")
            XCTFail("Subscription denial must throw")
        } catch {
            XCTAssertTrue(BackendHTTPError.isSubscriptionRequired(error))
        }
    }

    func testImportRecipeFromSocialURLRejectsDisallowedHost() async {
        do {
            _ = try await client.importRecipeFromSocialURL(
                url: "https://127.0.0.1/internal",
                recipeLanguage: "de",
                dietaryContext: nil,
                recipeTweaks: nil,
                tweakText: nil,
                extraText: nil,
                accessToken: "token"
            )
            XCTFail("Loopback import URL must be rejected before the network call")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .badURL)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPreviewSocialMetadataRejectsArbitraryHosts() async {
        do {
            _ = try await client.previewSocialMetadata(
                url: "https://example.com/recipe",
                accessToken: "token"
            )
            XCTFail("Non-allowlisted host must be rejected")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .badURL)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
