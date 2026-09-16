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

    func testSignInWithApple422PreservesErrorCode() async {
        let errorData = MockSupabaseResponses.errorResponse(
            message: "Invalid JWT",
            errorCode: "bad_jwt"
        )
        MockURLProtocol.mockResponse(statusCode: 422, data: errorData)
        do {
            _ = try await client.signInWithApple(idToken: "token", nonce: "raw-nonce-value")
            XCTFail("Should throw")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 422)
            XCTAssertEqual(error.userInfo["error_code"] as? String, "bad_jwt")
            XCTAssertFalse(AuthenticationManager.isEmailAlreadyRegistered(error))
        }
    }

    func testSignInWithAppleLinkingRequiresNonce() async {
        do {
            _ = try await client.signInWithAppleLinkingExistingEmail(idToken: "token", nonce: nil)
            XCTFail("Should require nonce")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 401)
        }
    }

    func testSignInWithAppleLinkingPostsToAuthApple() async throws {
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try MockSupabaseResponses.successAuthResponseData())
        }

        let response = try await client.signInWithAppleLinkingExistingEmail(
            idToken: "apple-id-token",
            nonce: "raw-nonce-value"
        )
        XCTAssertFalse(response.access_token.isEmpty)
        let request = try XCTUnwrap(captured)
        XCTAssertTrue(request.url?.path.hasSuffix("/auth/apple") == true)
        let bodyData = request.httpBody ?? {
            guard let stream = request.httpBodyStream else { return Data() }
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            return data
        }()
        XCTAssertFalse(bodyData.isEmpty)
        let body = try JSONSerialization.jsonObject(with: bodyData) as? [String: String]
        XCTAssertEqual(body?["id_token"], "apple-id-token")
        XCTAssertEqual(body?["nonce"], "raw-nonce-value")
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

    func testResetPasswordForEmailUsesUniversalLinkAndPKCE() async throws {
        KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
        var captured: URLRequest?
        MockURLProtocol.requestHandler = { request in
            captured = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await client.resetPasswordForEmail(email: "user@example.com")

        let request = try XCTUnwrap(captured)
        let url = try XCTUnwrap(request.url)
        XCTAssertTrue(url.path.contains("/auth/v1/recover"))
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        XCTAssertEqual(
            comps?.queryItems?.first(where: { $0.name == "redirect_to" })?.value,
            "https://culinaai.com/reset-password"
        )
        XCTAssertFalse(url.absoluteString.contains("culinachef://"))

        let body = try JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: String]
        XCTAssertEqual(body?["email"], "user@example.com")
        XCTAssertEqual(body?["code_challenge_method"], "s256")
        XCTAssertFalse(body?["code_challenge"]?.isEmpty ?? true)
        XCTAssertNotNil(KeychainManager.get(key: PasswordResetLink.codeVerifierKeychainKey))
        KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
    }
    
    func testExchangePKCECodeRequiresStoredVerifier() async {
        KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
        do {
            _ = try await client.exchangePKCECode("auth-code")
            XCTFail("Should fail without verifier")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func testExchangePKCESuccessDeletesVerifier() async throws {
        try KeychainManager.save(key: PasswordResetLink.codeVerifierKeychainKey, value: "verifier")
        let mockData = try MockSupabaseResponses.successAuthResponseData()
        MockURLProtocol.mockResponse(statusCode: 200, data: mockData)

        _ = try await client.exchangePKCECode("auth-code")
        XCTAssertNil(KeychainManager.get(key: PasswordResetLink.codeVerifierKeychainKey))
    }

    func testExchangePKCEKeepsVerifierOnServerError() async {
        try? KeychainManager.save(key: PasswordResetLink.codeVerifierKeychainKey, value: "verifier")
        MockURLProtocol.mockResponse(statusCode: 503, data: Data("{\"message\":\"busy\"}".utf8))

        do {
            _ = try await client.exchangePKCECode("auth-code")
            XCTFail("Should fail on 503")
        } catch {
            XCTAssertEqual(KeychainManager.get(key: PasswordResetLink.codeVerifierKeychainKey), "verifier")
        }
        KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
    }

    func testExchangePKCEDeletesVerifierOnClientError() async {
        try? KeychainManager.save(key: PasswordResetLink.codeVerifierKeychainKey, value: "verifier")
        MockURLProtocol.mockResponse(statusCode: 400, data: Data("{\"message\":\"invalid\"}".utf8))

        do {
            _ = try await client.exchangePKCECode("auth-code")
            XCTFail("Should fail on 400")
        } catch {
            XCTAssertNil(KeychainManager.get(key: PasswordResetLink.codeVerifierKeychainKey))
        }
    }

    func testResendForSameEmailReplacesVerifierButKeepsOtherEmail() async throws {
        PasswordResetPKCEStore.clear()
        try PasswordResetPKCEStore.upsert(verifier: "old-a", email: "a@example.com")
        try PasswordResetPKCEStore.upsert(verifier: "b-verifier", email: "b@example.com")
        try PasswordResetPKCEStore.upsert(verifier: "new-a", email: "a@example.com")
        let verifiers = PasswordResetPKCEStore.verifiersNewestFirst()
        XCTAssertEqual(verifiers, ["new-a", "b-verifier"])
        PasswordResetPKCEStore.clear()
    }

    func testExchangePKCETriesPreviousVerifierAfterClientError() async throws {
        PasswordResetPKCEStore.clear()
        try PasswordResetPKCEStore.upsert(verifier: "older", email: "first@example.com")
        try PasswordResetPKCEStore.upsert(verifier: "newer", email: "second@example.com")

        var calls = 0
        MockURLProtocol.requestHandler = { request in
            calls += 1
            let status = calls == 1 ? 400 : 200
            let body = status == 200
                ? (try? MockSupabaseResponses.successAuthResponseData()) ?? Data()
                : Data("{\"message\":\"invalid\"}".utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, body)
        }

        _ = try await client.exchangePKCECode("auth-code")
        XCTAssertEqual(calls, 2)
        XCTAssertNil(KeychainManager.get(key: PasswordResetLink.codeVerifierKeychainKey))
    }

    func testFailedRecoverDoesNotWipeOtherEmailVerifier() async {
        PasswordResetPKCEStore.clear()
        try? PasswordResetPKCEStore.upsert(verifier: "keep-me", email: "keep@example.com")
        MockURLProtocol.mockResponse(statusCode: 500, data: Data("{\"message\":\"nope\"}".utf8))
        do {
            try await client.resetPasswordForEmail(email: "other@example.com")
            XCTFail("Should fail")
        } catch {
            XCTAssertEqual(PasswordResetPKCEStore.verifiersNewestFirst(), ["keep-me"])
        }
        PasswordResetPKCEStore.clear()
    }
}
