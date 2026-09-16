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
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "Backend")
            XCTAssertEqual(error.code, 500)
            XCTAssertFalse(error.localizedDescription.contains("{"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
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
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "Backend")
            XCTAssertEqual(error.code, 401)
        } catch {
            XCTFail("Unexpected error type: \(error)")
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

    func testHTTPErrorDoesNotExposeRawHTMLOrJSONBodies() {
        let html = Data("<html><body>Internal Server Error</body></html>".utf8)
        let htmlError = BackendHTTPError.make(statusCode: 500, data: html) as NSError
        XCTAssertFalse(htmlError.localizedDescription.lowercased().contains("<html"))
        XCTAssertFalse(htmlError.localizedDescription.contains("Internal Server Error"))

        let json = Data(#"{"trace":"secret","stack":"boom"}"#.utf8)
        let jsonError = BackendHTTPError.make(statusCode: 502, data: json) as NSError
        XCTAssertFalse(jsonError.localizedDescription.contains("secret"))
        XCTAssertFalse(jsonError.localizedDescription.contains("trace"))

        let detail = Data(#"{"detail":"Recipe import failed"}"#.utf8)
        let detailError = BackendHTTPError.make(statusCode: 400, data: detail) as NSError
        XCTAssertEqual(detailError.localizedDescription, "Recipe import failed")
    }

    func testSafeUserFacingMessageRejectsDumps() {
        XCTAssertTrue(ErrorMessageHelper.isSafeUserFacingMessage("Invalid password"))
        XCTAssertFalse(ErrorMessageHelper.isSafeUserFacingMessage(#"{"error":"nope"}"#))
        XCTAssertFalse(ErrorMessageHelper.isSafeUserFacingMessage("<html>fail</html>"))
        XCTAssertFalse(ErrorMessageHelper.isSafeUserFacingMessage(String(repeating: "x", count: 400)))
    }

    func testSanitizedDisplayMessageHidesHtmlAndKeepsShortCopy() {
        let html = NSError(
            domain: "Backend",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "<html>nope</html>"]
        )
        XCTAssertEqual(
            ErrorMessageHelper.sanitizedDisplayMessage(from: html, fallback: "safe"),
            "safe"
        )
        let short = NSError(
            domain: "Backend",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: "Invalid password"]
        )
        let displayed = ErrorMessageHelper.sanitizedDisplayMessage(from: short, fallback: "safe")
        XCTAssertFalse(displayed.contains("<html"))
        XCTAssertFalse(displayed.isEmpty)
    }
}
