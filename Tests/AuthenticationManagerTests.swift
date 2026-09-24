import XCTest
@testable import CulinaChef

@MainActor
final class AuthenticationManagerTests: XCTestCase {
    var manager: AuthenticationManager!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        KeychainManager.deleteAll()

        let auth = SupabaseAuthClient(baseURL: URL(string: "https://mock.supabase.co")!, apiKey: "anon")
        let prefs = UserPreferencesClient(baseURL: URL(string: "https://mock.supabase.co")!, apiKey: "anon")
        manager = AuthenticationManager(auth: auth, preferencesClient: prefs)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        SecureURLSession.testConfiguration = nil
        KeychainManager.deleteAll()
        manager = nil
        super.tearDown()
    }

    func test422WithoutEmailExistsMessageIsNotTreatedAsRegistered() {
        let error = NSError(
            domain: "SupabaseAuth",
            code: 422,
            userInfo: [NSLocalizedDescriptionKey: "Invalid JWT"]
        )
        XCTAssertFalse(AuthenticationManager.isEmailAlreadyRegistered(error))
    }

    func testRateLimit422IsNotTreatedAsRegistered() {
        let error = NSError(
            domain: "SupabaseAuth",
            code: 422,
            userInfo: [NSLocalizedDescriptionKey: "Validation failed"]
        )
        XCTAssertFalse(AuthenticationManager.isEmailAlreadyRegistered(error))
    }

    func testIdentityAlreadyExistsErrorCodeIsTreatedAsRegistered() {
        let error = NSError(
            domain: "SupabaseAuth",
            code: 400,
            userInfo: [
                NSLocalizedDescriptionKey: "anything",
                "error_code": "identity_already_exists"
            ]
        )
        XCTAssertTrue(AuthenticationManager.isEmailAlreadyRegistered(error))
    }

    func testAlreadyBeenRegisteredMessageIsTreatedAsRegistered() {
        let error = NSError(
            domain: "SupabaseAuth",
            code: 422,
            userInfo: [NSLocalizedDescriptionKey: "A user with this email address has already been registered"]
        )
        XCTAssertTrue(AuthenticationManager.isEmailAlreadyRegistered(error))
    }

    func testGenericExistsSubstringDoesNotTriggerLinking() {
        let error = NSError(
            domain: "SupabaseAuth",
            code: 422,
            userInfo: [NSLocalizedDescriptionKey: "Resource exists in another project"]
        )
        XCTAssertFalse(AuthenticationManager.isEmailAlreadyRegistered(error))
    }

    func testInvalidAppleToken422DoesNotCallAuthApple() async {
        var paths: [String] = []
        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            paths.append(path)
            let body = MockSupabaseResponses.errorResponse(message: "Invalid JWT")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 422,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }

        do {
            _ = try await manager.signInWithApple(idToken: "invalid-token", nonce: "raw-nonce-value")
            XCTFail("Should fail for an invalid Apple token")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 422)
        }

        XCTAssertFalse(paths.contains { $0.contains("/auth/apple") })
        XCTAssertTrue(paths.contains { $0.contains("/auth/v1/token") })
    }

    func testEmailAlreadyRegisteredDoesNotCallAuthAppleOrSignIn() async {
        var paths: [String] = []
        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            paths.append(path)
            if path.contains("/auth/v1/token") {
                let body = MockSupabaseResponses.appleEmailAlreadyRegisteredError()
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 422,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, body)
            }
            if path.contains("/auth/apple") {
                let body = try MockSupabaseResponses.successAuthResponseData()
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, body)
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("[]".utf8))
        }

        do {
            _ = try await manager.signInWithApple(idToken: "apple-id-token", nonce: "raw-nonce-value")
            XCTFail("Should not sign in by silently linking Apple to an existing email account")
        } catch {
            XCTAssertTrue(AuthenticationManager.isEmailAlreadyRegistered(error))
        }

        XCTAssertFalse(paths.contains { $0.contains("/auth/apple") })
        XCTAssertTrue(paths.contains { $0.contains("/auth/v1/token") })
        XCTAssertNil(KeychainManager.get(key: "access_token"))
        XCTAssertNil(KeychainManager.get(key: "user_id"))
        XCTAssertNil(KeychainManager.get(key: "auth_provider"))
    }

    func testChangePasswordPersistsSignInSessionAndUsesNewAccessToken() async throws {
        try KeychainManager.save(key: "access_token", value: "stale_access_token")
        try KeychainManager.save(key: "refresh_token", value: "stale_refresh_token")

        var putAuthorization: String?
        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            if path.contains("/auth/v1/token") {
                let body = try JSONEncoder().encode(
                    MockSupabaseResponses.successAuthResponse(
                        accessToken: "fresh_access_token",
                        refreshToken: "fresh_refresh_token",
                        userId: "user_test_123",
                        email: "test@example.com"
                    )
                )
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, body)
            }
            if request.httpMethod == "PUT", path.contains("/auth/v1/user") {
                putAuthorization = request.value(forHTTPHeaderField: "Authorization")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data())
            }
            throw URLError(.badURL)
        }

        let result = try await manager.changePassword(
            email: "test@example.com",
            currentPassword: "old-pass-123",
            newPassword: "new-pass-123"
        )

        XCTAssertEqual(result.accessToken, "fresh_access_token")
        XCTAssertEqual(KeychainManager.get(key: "access_token"), "fresh_access_token")
        XCTAssertEqual(KeychainManager.get(key: "refresh_token"), "fresh_refresh_token")
        XCTAssertEqual(putAuthorization, "Bearer fresh_access_token")
        XCTAssertNotEqual(putAuthorization, "Bearer stale_access_token")
    }

    func testSignOutRetriesServerLogoutThenAlwaysClearsKeychain() async throws {
        try KeychainManager.save(key: "access_token", value: "tok")
        try KeychainManager.save(key: "user_id", value: "user_1")
        var logoutAttempts = 0
        MockURLProtocol.requestHandler = { request in
            if request.url?.path.contains("/logout") == true {
                logoutAttempts += 1
                if logoutAttempts == 1 {
                    throw URLError(.timedOut)
                }
                let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
                return (response, nil)
            }
            throw URLError(.badURL)
        }

        await manager.signOut(accessToken: "tok")

        XCTAssertEqual(logoutAttempts, 2)
        XCTAssertNil(KeychainManager.get(key: "access_token"))
        XCTAssertNil(KeychainManager.get(key: "user_id"))
    }

    func testSignOutClearsKeychainWhenServerLogoutKeepsFailing() async throws {
        try KeychainManager.save(key: "access_token", value: "tok")
        MockURLProtocol.mockError(URLError(.notConnectedToInternet))

        await manager.signOut(accessToken: "tok")

        XCTAssertNil(KeychainManager.get(key: "access_token"))
    }

    func testGeneric422IsNotTreatedAsExistingAccountOnSignup() {
        let error = NSError(
            domain: "SupabaseAuth",
            code: 422,
            userInfo: [NSLocalizedDescriptionKey: "Nonces mismatch"]
        )
        XCTAssertFalse(AuthenticationManager.isEmailAlreadyRegistered(error))
        let authCopy = ErrorMessageHelper.sanitizedAuthDisplayMessage(
            from: error,
            fallback: "fallback"
        )
        XCTAssertEqual(authCopy, "Nonces mismatch")
        let genericCopy = ErrorMessageHelper.sanitizedDisplayMessage(
            from: NSError(domain: "SupabaseAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID token"]),
            fallback: "fallback"
        )
        XCTAssertEqual(genericCopy, L.errorNotLoggedIn.localized)
        let authTokenCopy = ErrorMessageHelper.sanitizedAuthDisplayMessage(
            from: NSError(domain: "SupabaseAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID token"]),
            fallback: "fallback"
        )
        XCTAssertEqual(authTokenCopy, "Invalid Apple ID token")
        let rateLimited = ErrorMessageHelper.sanitizedAuthDisplayMessage(
            from: NSError(
                domain: "SupabaseAuth",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "email rate limit exceeded"]
            ),
            fallback: "fallback"
        )
        XCTAssertEqual(rateLimited, L.errorAuthRateLimited.localized)
        XCTAssertNotEqual(rateLimited, L.errorRateLimitExceeded.localized)
    }
}
