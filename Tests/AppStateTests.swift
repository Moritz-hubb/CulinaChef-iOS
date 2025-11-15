import XCTest
@testable import CulinaChef

@MainActor
final class AppStateTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        // Clean Keychain before each test
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Create fresh AppState
        appState = AppState()
        
        // Configure Mock URLProtocol
        MockURLProtocol.reset()
        
        // Configure SecureURLSession to use MockURLProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
    }
    
    override func tearDown() async throws {
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        MockURLProtocol.reset()
        SecureURLSession.testConfiguration = nil
        appState = nil
        try await super.tearDown()
    }
    
    // MARK: - Authentication State Tests
    
    func testInitialStateIsUnauthenticated() {
        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.accessToken)
        XCTAssertNil(appState.userEmail)
    }
    
    func testSignInUpdatesAuthenticationState() async throws {
        // Arrange
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        try await appState.signIn(email: "test@example.com", password: "password123")
        
        // Assert
        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertNotNil(appState.accessToken)
        XCTAssertEqual(appState.userEmail, "test@example.com")
        
        // Verify Keychain storage
        XCTAssertNotNil(KeychainManager.get(key: "access_token"))
        XCTAssertNotNil(KeychainManager.get(key: "refresh_token"))
        XCTAssertNotNil(KeychainManager.get(key: "user_email"))
    }
    
    func testSignInWithInvalidCredentials() async {
        // Arrange
        let errorData = MockSupabaseResponses.invalidPasswordError()
        MockURLProtocol.mockResponse(statusCode: 401, data: errorData)
        
        // Act & Assert
        do {
            try await appState.signIn(email: "test@example.com", password: "wrongpassword")
            XCTFail("Should throw error for invalid credentials")
        } catch {
            XCTAssertFalse(appState.isAuthenticated)
            XCTAssertNil(appState.accessToken)
        }
    }
    
    func testSignUpUpdatesAuthenticationState() async throws {
        // Arrange
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        try await appState.signUp(
            email: "newuser@example.com",
            password: "password123",
            username: "newuser"
        )
        
        // Assert
        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertNotNil(appState.accessToken)
        XCTAssertEqual(appState.userEmail, "test@example.com")
    }
    
    func testSignOutClearsAuthenticationState() async throws {
        // Arrange - First sign in
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        try await appState.signIn(email: "test@example.com", password: "password123")
        
        XCTAssertTrue(appState.isAuthenticated)
        
        // Configure mock for sign out
        MockURLProtocol.mockResponse(statusCode: 204)
        
        // Act
        await appState.signOut()
        
        // Assert
        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.accessToken)
        XCTAssertNil(appState.userEmail)
        
        // Verify Keychain is cleared
        XCTAssertNil(KeychainManager.get(key: "access_token"))
        XCTAssertNil(KeychainManager.get(key: "refresh_token"))
        XCTAssertNil(KeychainManager.get(key: "user_email"))
    }
    
    // MARK: - Subscription State Tests
    
    func testInitialSubscriptionState() {
        XCTAssertFalse(appState.isSubscribed)
    }
    
    func testSubscribeSimulatedSetsActiveState() {
        // Arrange - Need user_id in Keychain for subscribeSimulated to work
        try? KeychainManager.save(key: "user_id", value: "test_user_123")
        
        // Act
        appState.subscribeSimulated()
        
        // Assert
        XCTAssertTrue(appState.isSubscribed)
        
        // Verify Keychain storage
        XCTAssertNotNil(KeychainManager.getDate(key: "subscription_last_payment"))
        XCTAssertNotNil(KeychainManager.getDate(key: "subscription_period_end"))
        XCTAssertEqual(KeychainManager.getBool(key: "subscription_autorenew"), true)
    }
    
    func testCancelAutoRenewDisablesRenewal() {
        // Arrange - Need user_id in Keychain
        try? KeychainManager.save(key: "user_id", value: "test_user_123")
        
        // Arrange - First subscribe
        appState.subscribeSimulated()
        XCTAssertTrue(appState.isSubscribed)
        XCTAssertEqual(KeychainManager.getBool(key: "subscription_autorenew"), true)
        
        // Act
        appState.cancelAutoRenew()
        
        // Assert
        XCTAssertEqual(KeychainManager.getBool(key: "subscription_autorenew"), false)
        // Should still be subscribed until period ends
        XCTAssertTrue(appState.isSubscribed)
    }
    
    func testLoadSubscriptionStatusWithExpiredSubscription() {
        // Arrange - Set expired subscription in Keychain
        let pastDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        try? KeychainManager.save(key: "subscription_period_end", date: pastDate)
        try? KeychainManager.save(key: "subscription_autorenew", bool: false)
        
        // Act
        appState.loadSubscriptionStatus()
        
        // Assert
        XCTAssertFalse(appState.isSubscribed)
    }
    
    func testLoadSubscriptionStatusWithActiveSubscription() {
        // Arrange - Set user_id and active subscription in Keychain
        try? KeychainManager.save(key: "user_id", value: "test_user_123")
        let futureDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
        try? KeychainManager.save(key: "subscription_period_end", date: futureDate)
        
        // Act
        appState.loadSubscriptionStatus()
        
        // Assert
        XCTAssertTrue(appState.isSubscribed)
    }
    
    // MARK: - Dietary Preferences Tests
    
    func testInitialDietaryPreferences() {
        XCTAssertTrue(appState.dietary.diets.isEmpty)
        XCTAssertTrue(appState.dietary.allergies.isEmpty)
        XCTAssertTrue(appState.dietary.dislikes.isEmpty)
    }
    
    func testUpdateDietaryPreferences() {
        // Act
        appState.dietary.diets.insert("vegan")
        appState.dietary.allergies.append("nuts")
        appState.dietary.dislikes.append("mushrooms")
        
        // Assert
        XCTAssertTrue(appState.dietary.diets.contains("vegan"))
        XCTAssertTrue(appState.dietary.allergies.contains("nuts"))
        XCTAssertTrue(appState.dietary.dislikes.contains("mushrooms"))
    }
    
    func testDietarySystemPrompt() {
        // Arrange
        appState.dietary.diets.insert("vegan")
        appState.dietary.allergies.append("gluten")
        
        // Act
        let prompt = appState.dietarySystemPrompt()
        
        // Assert
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("vegan"))
        XCTAssertTrue(prompt.contains("gluten"))
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateDuringSignIn() async throws {
        // Arrange
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        XCTAssertFalse(appState.loading)
        
        // Act - Start async task but don't await immediately
        let task = Task {
            try await appState.signIn(email: "test@example.com", password: "password")
        }
        
        // Loading state is set synchronously before async call
        // After the call completes, loading should be false
        try await task.value
        
        // Assert
        XCTAssertFalse(appState.loading) // Should be false after completion
    }
    
    // MARK: - Error State Tests
    
    func testErrorStateOnFailedSignIn() async {
        // Arrange
        let errorData = MockSupabaseResponses.invalidPasswordError()
        MockURLProtocol.mockResponse(statusCode: 401, data: errorData)
        
        // Act
        do {
            try await appState.signIn(email: "test@example.com", password: "wrong")
            XCTFail("Should throw error")
        } catch {
            // Error is thrown, not stored in appState.error in current implementation
            XCTAssertFalse(appState.isAuthenticated)
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshSessionWithValidToken() async throws {
        // Arrange - Save refresh token
        try KeychainManager.save(key: "refresh_token", value: "mock_refresh_token")
        
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        
        // Act
        await appState.refreshSessionIfNeeded()
        
        // Assert
        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertNotNil(appState.accessToken)
    }
    
    func testRefreshSessionWithExpiredToken() async {
        // Arrange - Save refresh token
        try? KeychainManager.save(key: "refresh_token", value: "expired_token")
        
        let errorData = MockSupabaseResponses.tokenExpiredError()
        MockURLProtocol.mockResponse(statusCode: 401, data: errorData)
        
        // Act
        await appState.refreshSessionIfNeeded()
        
        // Assert - Should sign out on failed refresh
        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.accessToken)
    }
    
    // MARK: - Language Tests
    
    func testCurrentLanguageCode() {
        let langCode = appState.currentLanguageCode()
        XCTAssertFalse(langCode.isEmpty)
        XCTAssertTrue(["de", "en", "es", "fr", "it"].contains(langCode))
    }
    
    func testRecipeLanguageTag() {
        let tag = appState.recipeLanguageTag()
        XCTAssertFalse(tag.isEmpty)
        XCTAssertTrue(["DE", "EN", "ES", "FR", "IT"].contains(tag))
    }
    
    // MARK: - Menu Management Tests
    
    func testLastCreatedMenuBroadcast() {
        // Arrange
        let mockMenu = Menu(
            id: "menu_123",
            user_id: "user_123",
            title: "Test Menu",
            created_at: nil
        )
        
        // Act
        appState.lastCreatedMenu = mockMenu
        
        // Assert
        XCTAssertEqual(appState.lastCreatedMenu?.id, "menu_123")
        XCTAssertEqual(appState.lastCreatedMenu?.title, "Test Menu")
    }
}
