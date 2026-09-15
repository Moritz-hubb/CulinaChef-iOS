import XCTest
@testable import CulinaChef

final class OpenAIConsentManagerTests: XCTestCase {
    private let userA = "user-a-consent-tests"
    private let userB = "user-b-consent-tests"

    override func setUp() {
        super.setUp()
        KeychainManager.deleteAll()
        OpenAIConsentManager.resetConsent(for: userA)
        OpenAIConsentManager.resetConsent(for: userB)
    }

    override func tearDown() {
        OpenAIConsentManager.resetConsent(for: userA)
        OpenAIConsentManager.resetConsent(for: userB)
        KeychainManager.deleteAll()
        super.tearDown()
    }

    func testHasConsentIsFalseWithoutUserId() {
        XCTAssertFalse(OpenAIConsentManager.hasConsent)
        OpenAIConsentManager.hasConsent = true
        XCTAssertFalse(OpenAIConsentManager.hasConsent)
    }

    func testConsentIsScopedToCurrentUser() throws {
        try KeychainManager.save(key: "user_id", value: userA)
        OpenAIConsentManager.hasConsent = true
        XCTAssertTrue(OpenAIConsentManager.hasConsent)

        try KeychainManager.save(key: "user_id", value: userB)
        XCTAssertFalse(OpenAIConsentManager.hasConsent)

        OpenAIConsentManager.hasConsent = true
        XCTAssertTrue(OpenAIConsentManager.hasConsent(for: userB))
        XCTAssertTrue(OpenAIConsentManager.hasConsent(for: userA))
    }

    func testResetConsentClearsCurrentUserOnly() throws {
        try KeychainManager.save(key: "user_id", value: userA)
        OpenAIConsentManager.hasConsent = true
        OpenAIConsentManager.setConsent(true, for: userB)

        OpenAIConsentManager.resetConsent()
        XCTAssertFalse(OpenAIConsentManager.hasConsent)
        XCTAssertTrue(OpenAIConsentManager.hasConsent(for: userB))
    }

    func testResetConsentForUserIdDoesNotRequireKeychain() {
        OpenAIConsentManager.setConsent(true, for: userA)
        XCTAssertTrue(OpenAIConsentManager.hasConsent(for: userA))

        OpenAIConsentManager.resetConsent(for: userA)
        XCTAssertFalse(OpenAIConsentManager.hasConsent(for: userA))
    }

    func testSettingConsentPostsNotification() throws {
        try KeychainManager.save(key: "user_id", value: userA)
        let expectation = expectation(forNotification: OpenAIConsentManager.consentChangedNotification, object: nil) { note in
            (note.userInfo?["hasConsent"] as? Bool) == true
        }
        OpenAIConsentManager.hasConsent = true
        wait(for: [expectation], timeout: 1.0)
    }
}
