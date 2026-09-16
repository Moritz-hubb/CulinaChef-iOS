import XCTest
@testable import CulinaChef

@MainActor
final class AppStateTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

        MockURLProtocol.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config

        appState = AppState()
    }
    
    override func tearDown() async throws {
        AppleAccountDeletionAuth.requestAuthorizationCodeOverride = nil
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

    func testSignOutClearsDietaryPreferencesAndRecipeCaches() async throws {
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)
        try await appState.signIn(email: "test@example.com", password: "password123")
        let userId = try XCTUnwrap(KeychainManager.get(key: "user_id"))

        appState.dietary.allergies = ["peanuts"]
        appState.dietary.diets = ["vegan"]
        appState.saveCachedRecipesToDisk(recipes: [], menus: [])
        XCTAssertNotNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey(for: userId)))
        XCTAssertNotNil(UserDefaults.standard.object(forKey: "recipes_cache_timestamp_\(userId)"))

        MockURLProtocol.mockResponse(statusCode: 204)
        await appState.signOut()

        XCTAssertTrue(appState.dietary.allergies.isEmpty)
        XCTAssertTrue(appState.dietary.diets.isEmpty)
        XCTAssertTrue(appState.cachedRecipes.isEmpty)
        XCTAssertTrue(appState.cachedMenus.isEmpty)
        XCTAssertNil(appState.recipesCacheTimestamp)
        XCTAssertNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey))
        XCTAssertNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey(for: userId)))
        XCTAssertNil(UserDefaults.standard.object(forKey: "cached_recipes_\(userId)"))
        XCTAssertNil(UserDefaults.standard.object(forKey: "cached_menus_\(userId)"))
        XCTAssertNil(UserDefaults.standard.object(forKey: "recipes_cache_timestamp_\(userId)"))
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

    func testSilentRefreshAuthFailureSignsOutEvenIfTokenPresent() async throws {
        let jwt = Self.makeJWT(expFromNow: 3600)
        try KeychainManager.save(key: "access_token", value: jwt)
        try KeychainManager.save(key: "refresh_token", value: "stale_refresh")
        try KeychainManager.save(key: "user_email", value: "test@example.com")
        appState.accessToken = jwt
        appState.userEmail = "test@example.com"
        appState.isAuthenticated = true

        MockURLProtocol.mockResponse(statusCode: 401, data: MockSupabaseResponses.tokenExpiredError())
        await appState.refreshSessionIfNeeded(silent: true)

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.accessToken)
        XCTAssertNil(KeychainManager.get(key: "access_token"))
    }

    func testSilentRefreshNetworkErrorKeepsUnexpiredAccessToken() async throws {
        let jwt = Self.makeJWT(expFromNow: 3600)
        try KeychainManager.save(key: "access_token", value: jwt)
        try KeychainManager.save(key: "refresh_token", value: "refresh")
        try KeychainManager.save(key: "user_email", value: "test@example.com")
        appState.accessToken = jwt
        appState.userEmail = "test@example.com"
        appState.isAuthenticated = true

        MockURLProtocol.mockError(URLError(.notConnectedToInternet))
        await appState.refreshSessionIfNeeded(silent: true)

        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertEqual(appState.accessToken, jwt)
    }

    func testAccessTokenAndEmailAloneDoNotAuthenticate() async throws {
        try KeychainManager.save(key: "access_token", value: Self.makeJWT(expFromNow: 3600))
        try KeychainManager.save(key: "user_email", value: "test@example.com")

        await appState.checkSession()

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.accessToken)
        XCTAssertNil(KeychainManager.get(key: "access_token"))
    }

    func testExpiredAccessTokenIsNotTreatedAsAuthenticatedOnFailedRefresh() async throws {
        let jwt = Self.makeJWT(expFromNow: -3600)
        try KeychainManager.save(key: "access_token", value: jwt)
        try KeychainManager.save(key: "refresh_token", value: "stale_refresh")
        try KeychainManager.save(key: "user_email", value: "test@example.com")

        MockURLProtocol.mockResponse(statusCode: 401, data: MockSupabaseResponses.tokenExpiredError())
        await appState.checkSession()

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertFalse(SessionAccessToken.isUnexpired(jwt))
        XCTAssertNil(appState.accessToken)
    }

    func testSessionAccessTokenExpiryParsing() {
        XCTAssertTrue(SessionAccessToken.isUnexpired(Self.makeJWT(expFromNow: 3600)))
        XCTAssertFalse(SessionAccessToken.isUnexpired(Self.makeJWT(expFromNow: -3600)))
        XCTAssertFalse(SessionAccessToken.isUnexpired("not-a-jwt"))
        XCTAssertFalse(SessionAccessToken.isUnexpired("a.b.c"))
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

    // MARK: - Account deletion (SEC-002)

    func testDeleteAccountSignsOutImmediatelyAndClearsTokens() async throws {
        try KeychainManager.save(key: "access_token", value: "live_access_token")
        try KeychainManager.save(key: "refresh_token", value: "live_refresh_token")
        try KeychainManager.save(key: "user_id", value: "user_123")
        try KeychainManager.save(key: "user_email", value: "test@example.com")
        try KeychainManager.save(key: "auth_provider", value: "email")
        appState.accessToken = "live_access_token"
        appState.userEmail = "test@example.com"
        appState.isAuthenticated = true

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            if path.contains("/account/delete") {
                let data = Data(#"{"status":"deleted"}"#.utf8)
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
            if path.contains("/logout") {
                let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
                return (response, nil)
            }
            throw URLError(.badURL)
        }

        try await appState.deleteAccountAndData()

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.accessToken)
        XCTAssertNil(appState.userEmail)
        XCTAssertNil(KeychainManager.get(key: "access_token"))
        XCTAssertNil(KeychainManager.get(key: "refresh_token"))
        XCTAssertNil(KeychainManager.get(key: "user_id"))
        XCTAssertTrue(appState.showAccountDeletedAlert)
    }

    func testDeleteAccountFailureLeavesSessionIntact() async {
        try? KeychainManager.save(key: "access_token", value: "live_access_token")
        try? KeychainManager.save(key: "refresh_token", value: "live_refresh_token")
        try? KeychainManager.save(key: "user_id", value: "user_123")
        try? KeychainManager.save(key: "auth_provider", value: "email")
        appState.accessToken = "live_access_token"
        appState.isAuthenticated = true

        MockURLProtocol.mockResponse(statusCode: 500, data: Data(#"{"detail":"fail"}"#.utf8))

        do {
            try await appState.deleteAccountAndData()
            XCTFail("Deletion should fail")
        } catch {
            XCTAssertTrue(appState.isAuthenticated)
            XCTAssertEqual(appState.accessToken, "live_access_token")
            XCTAssertEqual(KeychainManager.get(key: "access_token"), "live_access_token")
            XCTAssertFalse(appState.showAccountDeletedAlert)
        }
    }

    func testAppleAccountWithoutAuthorizationCodeDoesNotDelete() async {
        try? KeychainManager.save(key: "access_token", value: "live_access_token")
        try? KeychainManager.save(key: "refresh_token", value: "live_refresh_token")
        try? KeychainManager.save(key: "user_id", value: "user_123")
        try? KeychainManager.save(key: "auth_provider", value: "apple")
        try? KeychainManager.save(key: "apple_user_id", value: "apple.user.1")
        appState.accessToken = "live_access_token"
        appState.isAuthenticated = true
        AppleAccountDeletionAuth.requestAuthorizationCodeOverride = { nil }

        var deleteCalled = false
        MockURLProtocol.requestHandler = { request in
            if request.url?.path.contains("/account/delete") == true {
                deleteCalled = true
            }
            throw URLError(.badServerResponse)
        }

        do {
            try await appState.deleteAccountAndData()
            XCTFail("Apple deletion without authorization code must fail closed")
        } catch {
            XCTAssertFalse(deleteCalled)
            XCTAssertTrue(appState.isAuthenticated)
            XCTAssertEqual(appState.accessToken, "live_access_token")
            XCTAssertEqual(KeychainManager.get(key: "access_token"), "live_access_token")
            XCTAssertFalse(appState.showAccountDeletedAlert)
        }
    }

    func testAppleAccountWithAuthorizationCodeSendsCodeThenSignsOut() async throws {
        try KeychainManager.save(key: "access_token", value: "live_access_token")
        try KeychainManager.save(key: "refresh_token", value: "live_refresh_token")
        try KeychainManager.save(key: "user_id", value: "user_123")
        try KeychainManager.save(key: "auth_provider", value: "apple")
        appState.accessToken = "live_access_token"
        appState.isAuthenticated = true
        AppleAccountDeletionAuth.requestAuthorizationCodeOverride = { "apple-auth-code" }

        var sentBody: Data?
        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            if path.contains("/account/delete") {
                sentBody = request.httpBody ?? Self.bodyFromStream(request)
                let data = Data(#"{"status":"deleted"}"#.utf8)
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
            if path.contains("/logout") {
                let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
                return (response, nil)
            }
            throw URLError(.badURL)
        }

        try await appState.deleteAccountAndData()

        let body = try XCTUnwrap(sentBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(json?["apple_authorization_code"], "apple-auth-code")
        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(KeychainManager.get(key: "access_token"))
        XCTAssertTrue(appState.showAccountDeletedAlert)
    }

    func testIsAppleAccountDetection() {
        XCTAssertTrue(AccountDeletionAppleRequirement.isAppleAccount(provider: "apple", email: nil, appleUserId: nil))
        XCTAssertTrue(AccountDeletionAppleRequirement.isAppleAccount(provider: "email", email: "x@privaterelay.appleid.com", appleUserId: nil))
        XCTAssertTrue(AccountDeletionAppleRequirement.isAppleAccount(provider: nil, email: nil, appleUserId: "001234"))
        XCTAssertFalse(AccountDeletionAppleRequirement.isAppleAccount(provider: "email", email: "user@example.com", appleUserId: nil))
        XCTAssertFalse(AccountDeletionAppleRequirement.isAppleAccount(provider: nil, email: nil, appleUserId: ""))
    }

    func testRequireAuthorizationCodeFailClosed() throws {
        XCTAssertThrowsError(try AccountDeletionAppleRequirement.requireAuthorizationCode(nil))
        XCTAssertThrowsError(try AccountDeletionAppleRequirement.requireAuthorizationCode("  "))
        XCTAssertEqual(try AccountDeletionAppleRequirement.requireAuthorizationCode(" code "), "code")
    }

    func testAppBundleContainsPrivacyManifestWithRequiredReasonAPIs() throws {
        let bundle = Bundle(for: AppState.self)
        let url = try XCTUnwrap(bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, false)
        let apis = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let types = Set(apis.compactMap { $0["NSPrivacyAccessedAPIType"] as? String })
        XCTAssertTrue(types.contains("NSPrivacyAccessedAPICategoryUserDefaults"))
        XCTAssertTrue(types.contains("NSPrivacyAccessedAPICategoryFileTimestamp"))
        let collected = try XCTUnwrap(plist["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
        let collectedTypes = Set(collected.compactMap { $0["NSPrivacyCollectedDataType"] as? String })
        XCTAssertTrue(collectedTypes.contains("NSPrivacyCollectedDataTypeHealth"))
        XCTAssertTrue(collectedTypes.contains("NSPrivacyCollectedDataTypeName"))
        XCTAssertTrue(collectedTypes.contains("NSPrivacyCollectedDataTypeEmailAddress"))
    }

    func testDietarySystemPromptSurvivesOutOfRangeSpicyLevel() throws {
        var prefs = TastePreferencesManager.TastePreferences()
        prefs.spicyLevel = 99
        try TastePreferencesManager.save(prefs)
        let prompt = appState.dietarySystemPrompt()
        XCTAssertTrue(prompt.contains("Sehr Scharf"))

        prefs.spicyLevel = -8
        try TastePreferencesManager.save(prefs)
        let mild = appState.dietarySystemPrompt()
        XCTAssertTrue(mild.contains("Mild"))

        prefs.spicyLevel = .nan
        try TastePreferencesManager.save(prefs)
        let fallback = appState.dietarySystemPrompt()
        XCTAssertTrue(fallback.contains("Scharf"))
    }

    private static func makeJWT(expFromNow: TimeInterval) -> String {
        func base64URL(_ string: String) -> String {
            Data(string.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        let header = base64URL("{\"alg\":\"none\",\"typ\":\"JWT\"}")
        let exp = Int(Date().addingTimeInterval(expFromNow).timeIntervalSince1970)
        let payload = base64URL("{\"sub\":\"user_123\",\"exp\":\(exp)}")
        return "\(header).\(payload).sig"
    }

    private static func bodyFromStream(_ request: URLRequest) -> Data? {
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: 4096)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
