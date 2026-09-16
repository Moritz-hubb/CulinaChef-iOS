import XCTest
@testable import CulinaChef

final class PasswordResetLinkTests: XCTestCase {
    func testParsesPKCECodeFromUniversalLink() {
        let url = URL(string: "https://culinaai.com/reset-password?code=abc123")!
        XCTAssertEqual(PasswordResetLink.parse(url), .pkce(code: "abc123"))
    }

    func testRejectsImplicitTokensFromHTTPSFragment() {
        let url = URL(string: "https://www.culinaai.com/reset-password#access_token=tok&refresh_token=ref&type=recovery")!
        XCTAssertEqual(PasswordResetLink.parse(url), .rejectedImplicit)
    }

    func testRejectsImplicitTokensFromQuery() {
        let url = URL(string: "https://culinaai.com/reset-password?access_token=tok&refresh_token=ref")!
        XCTAssertEqual(PasswordResetLink.parse(url), .rejectedImplicit)
    }

    func testPrefersPKCECodeWhenTokensAreAlsoPresent() {
        let url = URL(string: "https://culinaai.com/reset-password?code=abc123#access_token=tok&refresh_token=ref")!
        XCTAssertEqual(PasswordResetLink.parse(url), .pkce(code: "abc123"))
    }

    func testRejectsCustomSchemeEvenWithTokens() {
        let url = URL(string: "culinachef://reset-password#access_token=stolen&refresh_token=also")!
        XCTAssertEqual(PasswordResetLink.parse(url), .rejectedCustomScheme)
    }

    func testRejectsForeignHost() {
        let url = URL(string: "https://evil.example/reset-password?code=abc")!
        XCTAssertEqual(PasswordResetLink.parse(url), .notAResetLink)
    }

    func testSafeDescriptionStripsQueryAndFragment() {
        let url = URL(string: "https://culinaai.com/reset-password?code=secret#access_token=tok")!
        XCTAssertEqual(PasswordResetLink.safeDescription(url), "https://culinaai.com/reset-password")
        XCTAssertFalse(PasswordResetLink.safeDescription(url).contains("secret"))
        XCTAssertFalse(PasswordResetLink.safeDescription(url).contains("tok"))
    }

    func testPKCEStoreCapsEntriesAndReplacesSameEmail() throws {
        PasswordResetPKCEStore.clear()
        try PasswordResetPKCEStore.upsert(verifier: "v1", email: "a@x.com")
        try PasswordResetPKCEStore.upsert(verifier: "v2", email: "b@x.com")
        try PasswordResetPKCEStore.upsert(verifier: "v3", email: "c@x.com")
        try PasswordResetPKCEStore.upsert(verifier: "v4", email: "d@x.com")
        XCTAssertEqual(PasswordResetPKCEStore.verifiersNewestFirst().count, 3)
        XCTAssertEqual(PasswordResetPKCEStore.verifiersNewestFirst().first, "v4")
        try PasswordResetPKCEStore.upsert(verifier: "v4b", email: "d@x.com")
        XCTAssertEqual(PasswordResetPKCEStore.verifiersNewestFirst().first, "v4b")
        PasswordResetPKCEStore.clear()
    }

    func testPKCEChallengeIsS256Base64URL() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        XCTAssertEqual(
            PKCE.codeChallenge(for: verifier),
            "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        )
    }

    func testProductionPasswordResetRedirectIsHTTPSUniversalLink() {
        XCTAssertTrue(Config.isProductionPasswordResetRedirect(Config.passwordResetRedirectURL))
        XCTAssertFalse(Config.isProductionPasswordResetRedirect(URL(string: "culinachef://reset-password")!))
        XCTAssertFalse(Config.isProductionPasswordResetRedirect(URL(string: "http://culinaai.com/reset-password")!))
    }

    func testReleaseRejectsRevenueCatTestStoreKey() {
        XCTAssertEqual(Config.sanitizedRevenueCatAPIKey("test_abc", allowTestStoreKey: false), "")
        XCTAssertEqual(Config.sanitizedRevenueCatAPIKey("appl_live", allowTestStoreKey: false), "appl_live")
        XCTAssertEqual(Config.sanitizedRevenueCatAPIKey("$REVENUECAT_API_KEY", allowTestStoreKey: false), "")
        XCTAssertEqual(Config.sanitizedRevenueCatAPIKey(nil, allowTestStoreKey: false), "")
    }

    func testDebugMayKeepConfiguredRevenueCatKeyIncludingTestStore() {
        XCTAssertEqual(Config.sanitizedRevenueCatAPIKey("test_abc", allowTestStoreKey: true), "test_abc")
        XCTAssertEqual(Config.sanitizedRevenueCatAPIKey("appl_live", allowTestStoreKey: true), "appl_live")
    }

    func testSupabaseURLRejectsMissingUnsubstitutedAndPlaceholder() {
        XCTAssertNil(Config.resolvedSupabaseURL(from: [:]))
        XCTAssertNil(Config.resolvedSupabaseURL(from: ["SupabaseURL": "$(SUPABASE_URL)"]))
        XCTAssertNil(Config.resolvedSupabaseURL(from: ["SupabaseURL": ""]))
        XCTAssertNil(Config.resolvedSupabaseURL(from: ["SupabaseURL": "http://project.supabase.co"]))
        XCTAssertNil(Config.resolvedSupabaseURL(from: ["SupabaseURL": "https://placeholder.supabase.co"]))
        XCTAssertEqual(
            Config.resolvedSupabaseURL(from: ["SupabaseURL": "https://abcdefgh.supabase.co"])?.absoluteString,
            "https://abcdefgh.supabase.co"
        )
    }

    func testDevelopmentBackendDoesNotUseProductionHost() {
        let development = Config.backendBaseURL(for: .development, processEnv: [:])
        XCTAssertEqual(development, Config.developmentBackendURL)
        XCTAssertNotEqual(development.host, Config.productionBackendURL.host)
        XCTAssertEqual(
            Config.backendBaseURL(for: .production, processEnv: ["CULINA_BACKEND_URL": "http://127.0.0.1:9"]),
            Config.productionBackendURL
        )
        XCTAssertEqual(
            Config.backendBaseURL(
                for: .development,
                processEnv: ["CULINA_BACKEND_URL": "https://staging-api.culinaai.com"]
            ).absoluteString,
            "https://staging-api.culinaai.com"
        )
        XCTAssertNil(Config.resolvedBackendOverride("$(CULINA_BACKEND_URL)"))
        XCTAssertNil(Config.resolvedBackendOverride("ftp://example.com"))
    }
}
