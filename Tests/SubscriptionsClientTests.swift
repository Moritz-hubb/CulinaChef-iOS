import XCTest
@testable import CulinaChef

/// Unit tests for SubscriptionsClient
/// Tests Supabase subscription CRUD operations, error handling, and network failures
final class SubscriptionsClientTests: XCTestCase {
    
    var client: SubscriptionsClient!
    var testBaseURL: URL!
    
    override func setUp() {
        super.setUp()
        
        // Configure MockURLProtocol for SecureURLSession
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        
        testBaseURL = URL(string: "https://test.supabase.co")!
        client = SubscriptionsClient(baseURL: testBaseURL, apiKey: "test_api_key")
        
        MockURLProtocol.reset()
    }
    
    override func tearDown() {
        SecureURLSession.testConfiguration = nil
        MockURLProtocol.reset()
        client = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Subscription Tests
    
    func testFetchSubscriptionSuccess() async throws {
        // Arrange
        let mockResponse = """
        [{
            "user_id": "user_123",
            "plan": "unlimited",
            "status": "active",
            "auto_renew": true,
            "cancel_at_period_end": false,
            "last_payment_at": "2024-01-15T10:00:00Z",
            "current_period_end": "2024-02-15T10:00:00Z",
            "price_cents": 599,
            "currency": "EUR"
        }]
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockResponse.data(using: .utf8)
        )
        
        // Act
        let subscription = try await client.fetchSubscription(
            userId: "user_123",
            accessToken: "test_token"
        )
        
        // Assert
        XCTAssertNotNil(subscription)
        XCTAssertEqual(subscription?.userId, "user_123")
        XCTAssertEqual(subscription?.plan, "unlimited")
        XCTAssertEqual(subscription?.status, "active")
        XCTAssertTrue(subscription?.autoRenew ?? false)
        XCTAssertFalse(subscription?.cancelAtPeriodEnd ?? true)
        XCTAssertEqual(subscription?.priceCents, 599)
        XCTAssertEqual(subscription?.currency, "EUR")
        XCTAssertNotNil(subscription?.lastPaymentAt)
        XCTAssertNotNil(subscription?.currentPeriodEnd)
    }
    
    func testFetchSubscriptionNotFound() async throws {
        // Arrange - Empty array response
        let mockResponse = "[]"
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockResponse.data(using: .utf8)
        )
        
        // Act
        let subscription = try await client.fetchSubscription(
            userId: "nonexistent_user",
            accessToken: "test_token"
        )
        
        // Assert
        XCTAssertNil(subscription)
    }
    
    func testFetchSubscription404() async throws {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 404)
        
        // Act
        let subscription = try await client.fetchSubscription(
            userId: "user_123",
            accessToken: "test_token"
        )
        
        // Assert
        XCTAssertNil(subscription)
    }
    
    func testFetchSubscriptionUnauthorized() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 401)
        
        // Act & Assert
        do {
            _ = try await client.fetchSubscription(
                userId: "user_123",
                accessToken: "invalid_token"
            )
            XCTFail("Should throw error for 401")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "SubscriptionsClient")
            XCTAssertEqual(error.code, 401)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testFetchSubscriptionNetworkError() async {
        // Arrange
        MockURLProtocol.mockError(URLError(.notConnectedToInternet))
        
        // Act & Assert
        do {
            _ = try await client.fetchSubscription(
                userId: "user_123",
                accessToken: "test_token"
            )
            XCTFail("Should throw network error")
        } catch {
            // Expected error
        }
    }
    
    func testFetchSubscriptionInvalidJSON() async {
        // Arrange
        let invalidJSON = "{ invalid json"
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: invalidJSON.data(using: .utf8)
        )
        
        // Act & Assert
        do {
            _ = try await client.fetchSubscription(
                userId: "user_123",
                accessToken: "test_token"
            )
            XCTFail("Should throw decoding error")
        } catch {
            // Expected decoding error
        }
    }
    
    // MARK: - Upsert Subscription Tests
    
    func testUpsertSubscriptionSuccess() async throws {
        // Arrange
        let mockResponse = """
        [{
            "user_id": "user_123",
            "plan": "unlimited",
            "status": "active"
        }]
        """
        MockURLProtocol.mockResponse(
            statusCode: 201,
            data: mockResponse.data(using: .utf8)
        )
        
        let lastPayment = Date()
        let periodEnd = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Act - Should not throw
        try await client.upsertSubscription(
            userId: "user_123",
            plan: "unlimited",
            status: "active",
            autoRenew: true,
            cancelAtPeriodEnd: false,
            lastPaymentAt: lastPayment,
            currentPeriodEnd: periodEnd,
            priceCents: 599,
            currency: "EUR",
            accessToken: "test_token"
        )
        
        // Assert - No error thrown = success
    }
    
    func testUpsertSubscriptionUpdate() async throws {
        // Arrange - Simulate updating existing subscription
        MockURLProtocol.mockResponse(statusCode: 200)
        
        let lastPayment = Date()
        let periodEnd = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Act
        try await client.upsertSubscription(
            userId: "user_123",
            plan: "unlimited",
            status: "in_grace",
            autoRenew: false,
            cancelAtPeriodEnd: true,
            lastPaymentAt: lastPayment,
            currentPeriodEnd: periodEnd,
            priceCents: 599,
            currency: "EUR",
            accessToken: "test_token"
        )
        
        // Assert - No error = success
    }
    
    func testUpsertSubscriptionUnauthorized() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 401)
        
        let lastPayment = Date()
        let periodEnd = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Act & Assert
        do {
            try await client.upsertSubscription(
                userId: "user_123",
                plan: "unlimited",
                status: "active",
                autoRenew: true,
                cancelAtPeriodEnd: false,
                lastPaymentAt: lastPayment,
                currentPeriodEnd: periodEnd,
                priceCents: 599,
                currency: "EUR",
                accessToken: "invalid_token"
            )
            XCTFail("Should throw error for 401")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "SubscriptionsClient")
            XCTAssertEqual(error.code, 401)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUpsertSubscriptionServerError() async {
        // Arrange
        let errorResponse = """
        {"error": "Internal server error"}
        """
        MockURLProtocol.mockResponse(
            statusCode: 500,
            data: errorResponse.data(using: .utf8)
        )
        
        let lastPayment = Date()
        let periodEnd = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Act & Assert
        do {
            try await client.upsertSubscription(
                userId: "user_123",
                plan: "unlimited",
                status: "active",
                autoRenew: true,
                cancelAtPeriodEnd: false,
                lastPaymentAt: lastPayment,
                currentPeriodEnd: periodEnd,
                priceCents: 599,
                currency: "EUR",
                accessToken: "test_token"
            )
            XCTFail("Should throw error for 500")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "SubscriptionsClient")
            XCTAssertEqual(error.code, 500)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testUpsertSubscriptionNetworkError() async {
        // Arrange
        MockURLProtocol.mockError(URLError(.timedOut))
        
        let lastPayment = Date()
        let periodEnd = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Act & Assert
        do {
            try await client.upsertSubscription(
                userId: "user_123",
                plan: "unlimited",
                status: "active",
                autoRenew: true,
                cancelAtPeriodEnd: false,
                lastPaymentAt: lastPayment,
                currentPeriodEnd: periodEnd,
                priceCents: 599,
                currency: "EUR",
                accessToken: "test_token"
            )
            XCTFail("Should throw network error")
        } catch {
            // Expected error
        }
    }
    
    // MARK: - Date Encoding/Decoding Tests
    
    func testDateEncodingDecoding() async throws {
        // Arrange - Mock response with specific dates
        let mockResponse = """
        [{
            "user_id": "user_123",
            "plan": "unlimited",
            "status": "active",
            "auto_renew": true,
            "cancel_at_period_end": false,
            "last_payment_at": "2024-01-15T10:30:00Z",
            "current_period_end": "2024-02-15T10:30:00Z",
            "price_cents": 599,
            "currency": "EUR"
        }]
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockResponse.data(using: .utf8)
        )
        
        // Act
        let subscription = try await client.fetchSubscription(
            userId: "user_123",
            accessToken: "test_token"
        )
        
        // Assert dates parsed correctly
        XCTAssertNotNil(subscription?.lastPaymentAt)
        XCTAssertNotNil(subscription?.currentPeriodEnd)
        
        if let lastPayment = subscription?.lastPaymentAt,
           let periodEnd = subscription?.currentPeriodEnd {
            XCTAssertLessThan(lastPayment, periodEnd, "Last payment should be before period end")
        }
    }
    
    // MARK: - Edge Cases
    
    func testFetchSubscriptionEmptyResponse() async throws {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 200, data: Data())
        
        // Act & Assert
        do {
            _ = try await client.fetchSubscription(
                userId: "user_123",
                accessToken: "test_token"
            )
            XCTFail("Should throw decoding error for empty data")
        } catch {
            // Expected error
        }
    }
    
    func testUpsertSubscriptionWithOptionalNilValues() async throws {
        // Arrange - Response with nil optional values
        MockURLProtocol.mockResponse(statusCode: 201)
        
        let lastPayment = Date()
        let periodEnd = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Act - Should handle nil price/currency gracefully
        try await client.upsertSubscription(
            userId: "user_123",
            plan: "free",
            status: "active",
            autoRenew: false,
            cancelAtPeriodEnd: false,
            lastPaymentAt: lastPayment,
            currentPeriodEnd: periodEnd,
            priceCents: 0,
            currency: "",
            accessToken: "test_token"
        )
        
        // Assert - No error
    }
    
    func testFetchSubscriptionWithNullDates() async throws {
        // Arrange - Response with null dates
        let mockResponse = """
        [{
            "user_id": "user_123",
            "plan": "trial",
            "status": "active",
            "auto_renew": false,
            "cancel_at_period_end": false,
            "last_payment_at": null,
            "current_period_end": null,
            "price_cents": null,
            "currency": null
        }]
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockResponse.data(using: .utf8)
        )
        
        // Act
        let subscription = try await client.fetchSubscription(
            userId: "user_123",
            accessToken: "test_token"
        )
        
        // Assert
        XCTAssertNotNil(subscription)
        XCTAssertNil(subscription?.lastPaymentAt)
        XCTAssertNil(subscription?.currentPeriodEnd)
        XCTAssertNil(subscription?.priceCents)
        XCTAssertNil(subscription?.currency)
    }
}
