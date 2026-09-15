import XCTest
@testable import CulinaChef

final class PasswordResetLinkTests: XCTestCase {
    func testParsesPKCECodeFromUniversalLink() {
        let url = URL(string: "https://culinaai.com/reset-password?code=abc123")!
        XCTAssertEqual(PasswordResetLink.parse(url), .pkce(code: "abc123"))
    }

    func testParsesImplicitTokensFromHTTPSFragmentOnly() {
        let url = URL(string: "https://www.culinaai.com/reset-password#access_token=tok&refresh_token=ref&type=recovery")!
        XCTAssertEqual(
            PasswordResetLink.parse(url),
            .implicit(accessToken: "tok", refreshToken: "ref")
        )
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

    func testPKCEChallengeIsS256Base64URL() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        XCTAssertEqual(
            PKCE.codeChallenge(for: verifier),
            "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        )
    }
}
