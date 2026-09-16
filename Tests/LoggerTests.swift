import XCTest
@testable import CulinaChef

final class LoggerTests: XCTestCase {
    func testPublicAPIDoesNotTrap() {
        Logger.debug("debug", category: .auth)
        Logger.info("info", category: .network)
        Logger.warning("warning", category: .ui)
        Logger.error("error", category: .data)
        Logger.sensitive("secret", category: .auth)
    }

    func testPasswordResetSafeDescriptionNeverIncludesQuery() {
        let url = URL(string: "https://culinaai.com/reset-password?code=secret#access_token=tok")!
        let logged = PasswordResetLink.safeDescription(url)
        XCTAssertFalse(logged.contains("secret"))
        XCTAssertFalse(logged.contains("tok"))
        XCTAssertFalse(logged.contains("access_token"))
    }
}
