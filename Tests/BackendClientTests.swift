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
        // Arrange
        MockURLProtocol.mockError(MockSupabaseResponses.noInternetConnectionError())
        
        // Act & Assert
        do {
            try await client.health()
            XCTFail("Should throw network error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Wrong error type")
        }
    }
}
