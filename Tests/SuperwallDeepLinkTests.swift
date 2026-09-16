import XCTest
@testable import CulinaChef

final class SuperwallDeepLinkTests: XCTestCase {
    func testNeverForwardsHTTPSResetLinkWithPKCECode() {
        let url = URL(string: "https://culinaai.com/reset-password?code=abc123")!
        XCTAssertNil(SuperwallDeepLink.urlToForward(url))
    }

    func testNeverForwardsResetLinkWithFragmentTokens() {
        let url = URL(string: "https://www.culinaai.com/reset-password#access_token=tok&refresh_token=ref")!
        XCTAssertNil(SuperwallDeepLink.urlToForward(url))
    }

    func testNeverForwardsCustomSchemeResetLink() {
        let url = URL(string: "culinachef://reset-password#access_token=stolen&refresh_token=also")!
        XCTAssertNil(SuperwallDeepLink.urlToForward(url))
    }

    func testStripsQueryAndFragmentFromCampaignLinks() {
        let url = URL(string: "https://culinaai.com/recipe/abc?utm=secret#fragment")!
        let forwarded = SuperwallDeepLink.urlToForward(url)
        XCTAssertEqual(forwarded?.absoluteString, "https://culinaai.com/recipe/abc")
        XCTAssertNil(forwarded?.query)
        XCTAssertNil(forwarded?.fragment)
        XCTAssertFalse(forwarded?.absoluteString.contains("secret") ?? true)
    }

    func testStripsImportQueryFromCustomScheme() {
        let url = URL(string: "culinachef://import?url=https://tiktok.com/secret")!
        let forwarded = SuperwallDeepLink.urlToForward(url)
        XCTAssertEqual(forwarded?.absoluteString, "culinachef://import")
        XCTAssertFalse(forwarded?.absoluteString.contains("tiktok") ?? true)
    }
}
