import XCTest
@testable import CulinaChef

/// Integration tests for the complete authentication flow
/// Tests the interaction between AppState, SupabaseAuthClient, and KeychainManager
@MainActor
final class AuthFlowIntegrationTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        
        // Configure MockURLProtocol for SecureURLSession
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        
        // Clean state
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        appState = AppState()
        MockURLProtocol.reset()
    }
    
    override func tearDown() {
        SecureURLSession.testConfiguration = nil
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        MockURLProtocol.reset()
        appState = nil
        super.tearDown()
    }
    
    // MARK: - Complete Auth Flow Tests
    
    func testCompleteSignUpAndSignInFlow() async throws {
        // Arrange - Mock sign up response
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act - Sign Up
        try await appState.signUp(
            email: "newuser@example.com",
            password: "SecurePass123!",
            username: "newuser"
        )
        
        // Assert Sign Up State
        XCTAssertTrue(appState.isAuthenticated, "User should be authenticated after sign up")
        XCTAssertNotNil(appState.accessToken, "Access token should be set")
        XCTAssertEqual(appState.userEmail, "test@example.com") // From mock response
        
        // Verify Keychain Integration
        XCTAssertNotNil(KeychainManager.get(key: "access_token"), "Access token should be in Keychain")
        XCTAssertNotNil(KeychainManager.get(key: "refresh_token"), "Refresh token should be in Keychain")
        XCTAssertNotNil(KeychainManager.get(key: "user_email"), "Email should be in Keychain")
        XCTAssertNotNil(KeychainManager.get(key: "user_id"), "User ID should be in Keychain")
        
        // Act - Sign Out
        MockURLProtocol.mockResponse(statusCode: 204)
        await appState.signOut()
        
        // Assert Sign Out State
        XCTAssertFalse(appState.isAuthenticated, "User should not be authenticated after sign out")
        XCTAssertNil(appState.accessToken, "Access token should be nil")
        XCTAssertNil(appState.userEmail, "Email should be nil")
        
        // Verify Keychain Cleanup
        XCTAssertNil(KeychainManager.get(key: "access_token"), "Access token should be removed")
        XCTAssertNil(KeychainManager.get(key: "refresh_token"), "Refresh token should be removed")
        XCTAssertNil(KeychainManager.get(key: "user_email"), "Email should be removed")
        
        // Act - Sign In Again
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        try await appState.signIn(email: "test@example.com", password: "password123")
        
        // Assert Sign In State
        XCTAssertTrue(appState.isAuthenticated, "User should be authenticated after sign in")
        XCTAssertNotNil(appState.accessToken, "Access token should be restored")
    }
    
    func testSessionPersistenceAcrossAppLaunches() async throws {
        // Simulate first app launch - User signs in
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        try await appState.signIn(email: "user@example.com", password: "password")
        
        let firstAccessToken = appState.accessToken
        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertNotNil(firstAccessToken)
        
        // Simulate app restart - Create new AppState instance
        appState = nil
        
        // New AppState should restore session from Keychain
        appState = AppState()
        
        // Give checkSession() time to run
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Assert session restored
        XCTAssertTrue(appState.isAuthenticated, "Session should be restored from Keychain")
        XCTAssertNotNil(appState.accessToken, "Access token should be restored")
        XCTAssertEqual(appState.userEmail, "test@example.com", "Email should be restored")
    }
    
    func testTokenRefreshIntegration() async throws {
        // Arrange - Save expired access token and valid refresh token
        try KeychainManager.save(key: "access_token", value: "expired_token")
        try KeychainManager.save(key: "refresh_token", value: "valid_refresh_token")
        try KeychainManager.save(key: "user_email", value: "test@example.com")
        try KeychainManager.save(key: "user_id", value: "user123")
        
        // Create AppState with expired token
        appState = AppState()
        
        // Mock refresh token response
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act - Trigger token refresh
        await appState.refreshSessionIfNeeded()
        
        // Assert token refreshed
        XCTAssertTrue(appState.isAuthenticated, "Should remain authenticated after refresh")
        XCTAssertNotNil(appState.accessToken, "New access token should be set")
        XCTAssertNotEqual(appState.accessToken, "expired_token", "Token should be updated")
        
        // Verify new token in Keychain
        let newToken = KeychainManager.get(key: "access_token")
        XCTAssertNotNil(newToken, "New token should be stored in Keychain")
        XCTAssertNotEqual(newToken, "expired_token", "Keychain token should be updated")
    }
    
    func testAuthFailureHandling() async throws {
        // Arrange - Mock invalid credentials error
        let errorData = MockSupabaseResponses.invalidPasswordError()
        MockURLProtocol.mockResponse(statusCode: 401, data: errorData)
        
        // Act & Assert - Sign in should fail
        do {
            try await appState.signIn(email: "user@example.com", password: "wrongpassword")
            XCTFail("Sign in should throw error for invalid credentials")
        } catch {
            // Expected error
            XCTAssertFalse(appState.isAuthenticated, "Should not be authenticated")
            XCTAssertNil(appState.accessToken, "Access token should be nil")
            
            // Verify Keychain remains clean
            XCTAssertNil(KeychainManager.get(key: "access_token"), "No token should be stored")
        }
    }
    
    func testMultipleSignInAttempts() async throws {
        // First attempt - Success
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        try await appState.signIn(email: "user1@example.com", password: "pass1")
        XCTAssertTrue(appState.isAuthenticated)
        let firstToken = appState.accessToken
        
        // Sign out
        MockURLProtocol.mockResponse(statusCode: 204)
        await appState.signOut()
        XCTAssertFalse(appState.isAuthenticated)
        
        // Second attempt - Different user
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        try await appState.signIn(email: "user2@example.com", password: "pass2")
        
        XCTAssertTrue(appState.isAuthenticated, "Second user should be authenticated")
        XCTAssertNotEqual(appState.accessToken, firstToken, "Token should be different")
        
        // Verify Keychain has new credentials
        let newToken = KeychainManager.get(key: "access_token")
        XCTAssertNotNil(newToken, "New token should be in Keychain")
    }
    
    func testSignOutClearsAllUserData() async throws {
        // Arrange - Sign in and set up user data
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        try await appState.signIn(email: "user@example.com", password: "password")
        
        // Set up subscription data
        try KeychainManager.save(key: "subscription_period_end", date: Date().addingTimeInterval(86400))
        try KeychainManager.save(key: "subscription_autorenew", bool: true)
        appState.isSubscribed = true
        
        // Set up dietary preferences
        appState.dietary.diets.insert("vegan")
        appState.dietary.allergies.append("nuts")
        
        // Act - Sign out
        MockURLProtocol.mockResponse(statusCode: 204)
        await appState.signOut()
        
        // Assert all auth data cleared
        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.accessToken)
        XCTAssertNil(appState.userEmail)
        XCTAssertFalse(appState.isSubscribed, "Subscription should be cleared")
        
        // Verify Keychain cleared
        XCTAssertNil(KeychainManager.get(key: "access_token"))
        XCTAssertNil(KeychainManager.get(key: "refresh_token"))
        XCTAssertNil(KeychainManager.get(key: "user_id"))
        XCTAssertNil(KeychainManager.get(key: "user_email"))
        XCTAssertNil(KeychainManager.getDate(key: "subscription_period_end"))
        XCTAssertNil(KeychainManager.getBool(key: "subscription_autorenew"))
    }
    
    func testConcurrentAuthOperations() async throws {
        // Test that concurrent auth operations don't corrupt state
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Launch multiple sign-in attempts concurrently
        async let result1 = (try? await appState.signIn(email: "user@example.com", password: "pass"))
        async let result2 = (try? await appState.signIn(email: "user@example.com", password: "pass"))
        
        let _ = await (result1, result2)
        
        // Assert final state is consistent
        XCTAssertTrue(appState.isAuthenticated, "Should be authenticated")
        XCTAssertNotNil(appState.accessToken, "Should have valid token")
        
        // Verify Keychain state is not corrupted
        XCTAssertNotNil(KeychainManager.get(key: "access_token"))
        XCTAssertNotNil(KeychainManager.get(key: "user_email"))
    }
    
    // MARK: - Error Recovery Tests
    
    func testNetworkErrorRecovery() async throws {
        // First attempt - Network error
        MockURLProtocol.mockError(URLError(.notConnectedToInternet))
        
        do {
            try await appState.signIn(email: "user@example.com", password: "password")
            XCTFail("Should throw network error")
        } catch {
            XCTAssertFalse(appState.isAuthenticated, "Should not be authenticated after network error")
        }
        
        // Second attempt - Success after network recovery
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        try await appState.signIn(email: "user@example.com", password: "password")
        
        XCTAssertTrue(appState.isAuthenticated, "Should be authenticated after network recovery")
        XCTAssertNotNil(appState.accessToken, "Should have access token")
    }
    
    func testExpiredTokenAutoRefresh() async throws {
        // Arrange - Set up authenticated state with old token
        try KeychainManager.save(key: "access_token", value: "old_token")
        try KeychainManager.save(key: "refresh_token", value: "refresh_token")
        try KeychainManager.save(key: "user_email", value: "user@example.com")
        try KeychainManager.save(key: "user_id", value: "user123")
        
        appState = AppState()
        
        // Mock token expired error on first request
        let errorData = MockSupabaseResponses.tokenExpiredError()
        MockURLProtocol.mockResponse(statusCode: 401, data: errorData)
        
        // Wait for initial refresh attempt
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        // Mock successful refresh
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        await appState.refreshSessionIfNeeded()
        
        // Assert token refreshed automatically
        XCTAssertTrue(appState.isAuthenticated, "Should remain authenticated")
        XCTAssertNotNil(appState.accessToken, "Should have new token")
    }
}
