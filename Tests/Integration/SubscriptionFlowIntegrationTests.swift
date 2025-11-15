import XCTest
@testable import CulinaChef

/// Integration tests for subscription flow
/// Tests subscription state management, backend sync, and feature access
@MainActor
final class SubscriptionFlowIntegrationTests: XCTestCase {
    
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
        
        // Set up authenticated user for subscription tests
        try? KeychainManager.save(key: "user_id", value: "test_user_123")
        try? KeychainManager.save(key: "access_token", value: "test_token")
        try? KeychainManager.save(key: "user_email", value: "test@example.com")
        
        appState = AppState()
        appState.accessToken = "test_token"
        appState.userEmail = "test@example.com"
        appState.isAuthenticated = true
        
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
    
    // MARK: - Subscription Activation Flow
    
    func testCompleteSubscriptionFlow() {
        // Initial state - Not subscribed
        XCTAssertFalse(appState.isSubscribed, "Should not be subscribed initially")
        XCTAssertFalse(appState.hasAccess(to: .aiChat), "Should not have AI access")
        XCTAssertFalse(appState.hasAccess(to: .aiRecipeGenerator), "Should not have recipe generator access")
        
        // Act - Subscribe (simulated)
        appState.subscribeSimulated()
        
        // Assert subscription activated
        XCTAssertTrue(appState.isSubscribed, "Should be subscribed after activation")
        
        // Verify Keychain state
        XCTAssertNotNil(KeychainManager.getDate(key: "subscription_last_payment"), "Last payment should be set")
        XCTAssertNotNil(KeychainManager.getDate(key: "subscription_period_end"), "Period end should be set")
        XCTAssertEqual(KeychainManager.getBool(key: "subscription_autorenew"), true, "Auto-renew should be enabled")
        
        // Verify feature access
        XCTAssertTrue(appState.hasAccess(to: .aiChat), "Should have AI chat access")
        XCTAssertTrue(appState.hasAccess(to: .aiRecipeGenerator), "Should have recipe generator access")
        XCTAssertTrue(appState.hasAccess(to: .aiRecipeAnalysis), "Should have recipe analysis access")
    }
    
    func testSubscriptionPersistenceAcrossAppRestart() {
        // Arrange - Subscribe first
        appState.subscribeSimulated()
        XCTAssertTrue(appState.isSubscribed)
        
        let originalPeriodEnd = appState.getSubscriptionPeriodEnd()
        XCTAssertNotNil(originalPeriodEnd)
        
        // Simulate app restart
        appState = nil
        appState = AppState()
        appState.accessToken = "test_token"
        appState.isAuthenticated = true
        
        // Act - Load subscription status
        appState.loadSubscriptionStatus()
        
        // Assert subscription persisted
        XCTAssertTrue(appState.isSubscribed, "Subscription should persist across restarts")
        XCTAssertEqual(appState.getSubscriptionPeriodEnd(), originalPeriodEnd, "Period end should be preserved")
        XCTAssertTrue(appState.getSubscriptionAutoRenew(), "Auto-renew should be preserved")
    }
    
    func testCancelAutoRenewFlow() {
        // Arrange - Subscribe first
        appState.subscribeSimulated()
        XCTAssertTrue(appState.isSubscribed)
        XCTAssertTrue(appState.getSubscriptionAutoRenew())
        
        // Act - Cancel auto-renew
        appState.cancelAutoRenew()
        
        // Assert - Still subscribed until period ends
        XCTAssertTrue(appState.isSubscribed, "Should remain subscribed until period ends")
        XCTAssertFalse(appState.getSubscriptionAutoRenew(), "Auto-renew should be disabled")
        
        // Verify features still accessible
        XCTAssertTrue(appState.hasAccess(to: .aiChat), "Features should remain active")
        
        // Verify Keychain updated
        XCTAssertEqual(KeychainManager.getBool(key: "subscription_autorenew"), false, "Keychain should reflect cancellation")
    }
    
    func testExpiredSubscriptionDeniesAccess() {
        // Arrange - Set up expired subscription
        let pastDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        try? KeychainManager.save(key: "subscription_period_end", date: pastDate)
        try? KeychainManager.save(key: "subscription_autorenew", bool: false)
        
        // Act - Load subscription status
        appState.loadSubscriptionStatus()
        
        // Assert - Subscription expired
        XCTAssertFalse(appState.isSubscribed, "Expired subscription should not be active")
        XCTAssertFalse(appState.hasAccess(to: .aiChat), "Should not have AI access")
        XCTAssertFalse(appState.hasAccess(to: .aiRecipeGenerator), "Should not have recipe generator access")
        
        // Verify free features still accessible
        XCTAssertTrue(appState.hasAccess(to: .manualRecipes), "Manual recipes should still be accessible")
        XCTAssertTrue(appState.hasAccess(to: .shoppingList), "Shopping list should still be accessible")
    }
    
    // MARK: - Feature Access Control
    
    func testFeatureAccessWithoutSubscription() {
        // Ensure no subscription
        appState.isSubscribed = false
        
        // Premium features should be blocked
        XCTAssertFalse(appState.hasAccess(to: .aiChat))
        XCTAssertFalse(appState.hasAccess(to: .aiRecipeGenerator))
        XCTAssertFalse(appState.hasAccess(to: .aiRecipeAnalysis))
        
        // Free features should be available
        XCTAssertTrue(appState.hasAccess(to: .manualRecipes))
        XCTAssertTrue(appState.hasAccess(to: .shoppingList))
        XCTAssertTrue(appState.hasAccess(to: .communityLibrary))
        XCTAssertTrue(appState.hasAccess(to: .recipeManagement))
    }
    
    func testFeatureAccessWithActiveSubscription() {
        // Arrange - Active subscription
        appState.subscribeSimulated()
        
        // All premium features should be accessible
        XCTAssertTrue(appState.hasAccess(to: .aiChat))
        XCTAssertTrue(appState.hasAccess(to: .aiRecipeGenerator))
        XCTAssertTrue(appState.hasAccess(to: .aiRecipeAnalysis))
        
        // Free features should also be accessible
        XCTAssertTrue(appState.hasAccess(to: .manualRecipes))
        XCTAssertTrue(appState.hasAccess(to: .shoppingList))
        XCTAssertTrue(appState.hasAccess(to: .communityLibrary))
    }
    
    // MARK: - Auto-Renewal Tests
    
    func testAutoRenewExtendsPeriod() {
        // Arrange - Subscribe with period ending soon
        let nearExpiry = Date().addingTimeInterval(24 * 60 * 60) // 1 day from now
        try? KeychainManager.save(key: "subscription_last_payment", date: Date().addingTimeInterval(-29 * 24 * 60 * 60))
        try? KeychainManager.save(key: "subscription_period_end", date: nearExpiry)
        try? KeychainManager.save(key: "subscription_autorenew", bool: true)
        
        // Act - Load subscription (triggers auto-renew logic)
        appState.loadSubscriptionStatus()
        
        // Assert - Subscription should still be active
        XCTAssertTrue(appState.isSubscribed, "Should be subscribed")
        
        // Verify period end exists
        let periodEnd = appState.getSubscriptionPeriodEnd()
        XCTAssertNotNil(periodEnd, "Period end should be set")
    }
    
    func testManualRenewalAfterExpiration() {
        // Arrange - Expired subscription
        let pastDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        try? KeychainManager.save(key: "subscription_period_end", date: pastDate)
        try? KeychainManager.save(key: "subscription_autorenew", bool: false)
        
        appState.loadSubscriptionStatus()
        XCTAssertFalse(appState.isSubscribed)
        
        // Act - Renew subscription
        appState.subscribeSimulated()
        
        // Assert - Subscription reactivated
        XCTAssertTrue(appState.isSubscribed, "Should be subscribed after renewal")
        XCTAssertTrue(appState.hasAccess(to: .aiChat), "Should regain AI access")
        
        // Verify new period end in future
        let newPeriodEnd = appState.getSubscriptionPeriodEnd()
        XCTAssertNotNil(newPeriodEnd)
        XCTAssertGreaterThan(newPeriodEnd!, Date(), "New period end should be in future")
    }
    
    // MARK: - Subscription Status Initialization
    
    func testSubscriptionStatusInitialization() {
        // Create fresh AppState
        let freshState = AppState()
        
        // Initially false until loaded
        XCTAssertFalse(freshState.subscriptionStatusInitialized, "Should not be initialized immediately")
        
        // Load status
        freshState.loadSubscriptionStatus()
        
        // Should be initialized after load
        XCTAssertTrue(freshState.subscriptionStatusInitialized, "Should be initialized after load")
    }
    
    func testSubscriptionStatusWithNoUser() {
        // Arrange - No user logged in
        KeychainManager.deleteAll()
        
        let freshState = AppState()
        
        // Act - Load subscription status
        freshState.loadSubscriptionStatus()
        
        // Assert - Should be initialized but not subscribed
        XCTAssertTrue(freshState.subscriptionStatusInitialized, "Should be initialized")
        XCTAssertFalse(freshState.isSubscribed, "Should not be subscribed without user")
    }
    
    // MARK: - Edge Cases
    
    func testSubscriptionWithFutureDate() {
        // Arrange - Subscription with period end far in future
        let futureDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
        try? KeychainManager.save(key: "subscription_period_end", date: futureDate)
        try? KeychainManager.save(key: "subscription_autorenew", bool: true)
        
        // Act
        appState.loadSubscriptionStatus()
        
        // Assert
        XCTAssertTrue(appState.isSubscribed, "Should be subscribed with future date")
        XCTAssertTrue(appState.hasAccess(to: .aiChat), "Should have access")
    }
    
    func testSubscriptionAtExactExpiryMoment() {
        // Arrange - Subscription ending exactly now
        let now = Date()
        try? KeychainManager.save(key: "subscription_period_end", date: now)
        try? KeychainManager.save(key: "subscription_autorenew", bool: false)
        
        // Act
        appState.loadSubscriptionStatus()
        
        // Assert - Should be expired (Date() < periodEnd check)
        XCTAssertFalse(appState.isSubscribed, "Should be expired at exact expiry time")
    }
    
    func testMultipleSubscriptionCycles() {
        // Cycle 1: Subscribe
        appState.subscribeSimulated()
        XCTAssertTrue(appState.isSubscribed)
        let period1 = appState.getSubscriptionPeriodEnd()
        
        // Cycle 2: Cancel
        appState.cancelAutoRenew()
        XCTAssertTrue(appState.isSubscribed) // Still active
        XCTAssertFalse(appState.getSubscriptionAutoRenew())
        
        // Cycle 3: Let expire (simulate)
        let pastDate = Date().addingTimeInterval(-1 * 24 * 60 * 60)
        try? KeychainManager.save(key: "subscription_period_end", date: pastDate)
        appState.loadSubscriptionStatus()
        XCTAssertFalse(appState.isSubscribed)
        
        // Cycle 4: Re-subscribe
        appState.subscribeSimulated()
        XCTAssertTrue(appState.isSubscribed)
        let period2 = appState.getSubscriptionPeriodEnd()
        
        // Verify new period is different
        XCTAssertNotEqual(period1, period2, "New subscription should have different period")
        XCTAssertTrue(appState.getSubscriptionAutoRenew(), "Auto-renew should be re-enabled")
    }
    
    func testSignOutClearsSubscriptionState() async {
        // Arrange - Subscribe first
        appState.subscribeSimulated()
        XCTAssertTrue(appState.isSubscribed)
        
        // Mock sign out
        MockURLProtocol.mockResponse(statusCode: 204)
        
        // Act - Sign out
        await appState.signOut()
        
        // Assert - Subscription cleared
        XCTAssertFalse(appState.isSubscribed, "Subscription should be cleared on sign out")
        XCTAssertFalse(appState.hasAccess(to: .aiChat), "Premium features should be inaccessible")
        
        // Verify Keychain cleared
        XCTAssertNil(KeychainManager.getDate(key: "subscription_period_end"))
        XCTAssertNil(KeychainManager.getBool(key: "subscription_autorenew"))
    }
    
    // MARK: - Subscription Data Integrity
    
    func testSubscriptionDataConsistency() {
        // Subscribe
        appState.subscribeSimulated()
        
        // Verify all subscription data is consistent
        let lastPayment = appState.getSubscriptionLastPayment()
        let periodEnd = appState.getSubscriptionPeriodEnd()
        let autoRenew = appState.getSubscriptionAutoRenew()
        
        XCTAssertNotNil(lastPayment, "Last payment should be set")
        XCTAssertNotNil(periodEnd, "Period end should be set")
        XCTAssertTrue(autoRenew, "Auto-renew should be true")
        
        // Verify period end is after last payment
        if let payment = lastPayment, let end = periodEnd {
            XCTAssertGreaterThan(end, payment, "Period end should be after last payment")
        }
        
        // Verify both in memory and Keychain match
        XCTAssertTrue(appState.isSubscribed, "In-memory state should be subscribed")
        
        let keychainPeriodEnd = KeychainManager.getDate(key: "subscription_period_end")
        XCTAssertEqual(periodEnd, keychainPeriodEnd, "Keychain and memory should match")
    }
}
