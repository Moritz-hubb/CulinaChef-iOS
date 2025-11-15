import XCTest
@testable import CulinaChef

final class SupabaseAuthClientTests: XCTestCase {
    
    var client: SupabaseAuthClient!
    let mockBaseURL = URL(string: "https://mock.supabase.co")!
    let mockAPIKey = "mock_anon_key_12345"
    
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        
        // Configure SecureURLSession to use MockURLProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        
        client = SupabaseAuthClient(baseURL: mockBaseURL, apiKey: mockAPIKey)
    }
    
    override func tearDown() {
        MockURLProtocol.reset()
        SecureURLSession.testConfiguration = nil
        client = nil
        super.tearDown()
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async throws {
        // Arrange
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        let response = try await client.signUp(
            email: "test@example.com",
            password: "password123",
            username: "testuser"
        )
        
        // Assert
        XCTAssertEqual(response.user.email, "test@example.com")
        XCTAssertFalse(response.access_token.isEmpty)
        XCTAssertFalse(response.refresh_token.isEmpty)
    }
    
    func testSignUpWithEmailAlreadyRegistered() async {
        // Arrange
        let errorData = MockSupabaseResponses.emailAlreadyRegisteredError()
        MockURLProtocol.mockResponse(statusCode: 400, data: errorData)
        
        // Act & Assert
        do {
            _ = try await client.signUp(
                email: "existing@example.com",
                password: "password123",
                username: "testuser"
            )
            XCTFail("Should throw error for existing email")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 400)
            XCTAssertTrue(error.localizedDescription.contains("already registered"))
        }
    }
    
    func testSignUpWithWeakPassword() async {
        // Arrange
        let errorData = MockSupabaseResponses.weakPasswordError()
        MockURLProtocol.mockResponse(statusCode: 422, data: errorData)
        
        // Act & Assert
        do {
            _ = try await client.signUp(
                email: "test@example.com",
                password: "123",
                username: "testuser"
            )
            XCTFail("Should throw error for weak password")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 422)
        }
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async throws {
        // Arrange
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        let response = try await client.signIn(
            email: "test@example.com",
            password: "password123"
        )
        
        // Assert
        XCTAssertEqual(response.user.email, "test@example.com")
        XCTAssertFalse(response.access_token.isEmpty)
        XCTAssertFalse(response.refresh_token.isEmpty)
    }
    
    func testSignInWithInvalidCredentials() async {
        // Arrange
        let errorData = MockSupabaseResponses.invalidPasswordError()
        MockURLProtocol.mockResponse(statusCode: 401, data: errorData)
        
        // Act & Assert
        do {
            _ = try await client.signIn(
                email: "test@example.com",
                password: "wrongpassword"
            )
            XCTFail("Should throw error for invalid credentials")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 401)
        }
    }
    
    func testSignInWithNonExistentUser() async {
        // Arrange
        let errorData = MockSupabaseResponses.userNotFoundError()
        MockURLProtocol.mockResponse(statusCode: 400, data: errorData)
        
        // Act & Assert
        do {
            _ = try await client.signIn(
                email: "nonexistent@example.com",
                password: "password123"
            )
            XCTFail("Should throw error for non-existent user")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 400)
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshSessionSuccess() async throws {
        // Arrange
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        let response = try await client.refreshSession(refreshToken: "mock_refresh_token")
        
        // Assert
        XCTAssertFalse(response.access_token.isEmpty)
        XCTAssertFalse(response.refresh_token.isEmpty)
    }
    
    func testRefreshSessionWithExpiredToken() async {
        // Arrange
        let errorData = MockSupabaseResponses.tokenExpiredError()
        MockURLProtocol.mockResponse(statusCode: 401, data: errorData)
        
        // Act & Assert
        do {
            _ = try await client.refreshSession(refreshToken: "expired_token")
            XCTFail("Should throw error for expired refresh token")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 401)
        }
    }
    
    func testRefreshSessionWithInvalidToken() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 403, data: Data())
        
        // Act & Assert
        do {
            _ = try await client.refreshSession(refreshToken: "invalid_token")
            XCTFail("Should throw error for invalid token")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 403)
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() async throws {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 204)
        
        // Act & Assert
        try await client.signOut(accessToken: "mock_access_token")
    }
    
    func testSignOutWithInvalidToken() async {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 401)
        
        // Act & Assert
        do {
            try await client.signOut(accessToken: "invalid_token")
            XCTFail("Should throw error for invalid token")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    // MARK: - Change Password Tests
    
    func testChangePasswordSuccess() async throws {
        // Arrange
        MockURLProtocol.mockResponse(statusCode: 200, data: Data())
        
        // Act & Assert
        try await client.changePassword(
            accessToken: "mock_access_token",
            newPassword: "newpassword123"
        )
    }
    
    func testChangePasswordWithWeakPassword() async {
        // Arrange
        let errorData = MockSupabaseResponses.weakPasswordError()
        MockURLProtocol.mockResponse(statusCode: 422, data: errorData)
        
        // Act & Assert
        do {
            try await client.changePassword(
                accessToken: "mock_access_token",
                newPassword: "123"
            )
            XCTFail("Should throw error for weak password")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 422)
        }
    }
    
    // MARK: - Apple Sign In Tests
    
    func testSignInWithAppleSuccess() async throws {
        // Arrange
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        let response = try await client.signInWithApple(
            idToken: "mock_apple_id_token",
            nonce: "mock_nonce"
        )
        
        // Assert
        XCTAssertFalse(response.access_token.isEmpty)
        XCTAssertFalse(response.refresh_token.isEmpty)
    }
    
    func testSignInWithAppleInvalidToken() async {
        // Arrange
        let errorData = MockSupabaseResponses.errorResponse(message: "Invalid Apple ID token")
        MockURLProtocol.mockResponse(statusCode: 400, data: errorData)
        
        // Act & Assert
        do {
            _ = try await client.signInWithApple(
                idToken: "invalid_token",
                nonce: nil
            )
            XCTFail("Should throw error for invalid Apple token")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 400)
        }
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkTimeoutError() async {
        // Arrange
        MockURLProtocol.mockError(MockSupabaseResponses.networkTimeoutError())
        
        // Act & Assert
        do {
            _ = try await client.signIn(email: "test@example.com", password: "password")
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
            _ = try await client.signIn(email: "test@example.com", password: "password")
            XCTFail("Should throw network error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    // MARK: - Rate Limiting Tests
    
    func testRateLimitExceeded() async {
        // Arrange
        let errorData = MockSupabaseResponses.rateLimitError()
        MockURLProtocol.mockResponse(statusCode: 429, data: errorData)
        
        // Act & Assert
        do {
            _ = try await client.signIn(email: "test@example.com", password: "password")
            XCTFail("Should throw rate limit error")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 429)
            XCTAssertTrue(error.localizedDescription.contains("Rate limit"))
        }
    }
}
