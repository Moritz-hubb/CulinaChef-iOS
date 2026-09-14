import XCTest
@testable import CulinaChef

final class SubscriptionLegalTests: XCTestCase {
    func testGermanCopyUsesStoreKitPricesAndThreeDayTrial() {
        let prices = SubscriptionLegal.Prices(weekly: "2,99 €", monthly: "9,99 €")
        let paragraphs = SubscriptionLegal.termsParagraphs(language: "de", prices: prices)
        let joined = paragraphs.joined(separator: " ")
        XCTAssertFalse(joined.contains("5,99"))
        XCTAssertTrue(joined.contains("2,99"))
        XCTAssertTrue(joined.contains("9,99"))
        XCTAssertTrue(joined.contains("3 Tagen") || joined.contains("3 Tage"))
        XCTAssertTrue(joined.contains("StoreKit") || joined.contains("Kaufbildschirm"))
    }

    func testEnglishCopyUsesStoreKitPricesAndThreeDayTrial() {
        let prices = SubscriptionLegal.Prices(weekly: "$4.99", monthly: "$14.99")
        let paragraphs = SubscriptionLegal.termsParagraphs(language: "en", prices: prices)
        let joined = paragraphs.joined(separator: " ")
        XCTAssertFalse(joined.contains("5.99"))
        XCTAssertTrue(joined.contains("$4.99"))
        XCTAssertTrue(joined.contains("3-day") || joined.contains("3-day"))
        XCTAssertEqual(SubscriptionLegal.trialDurationDays, 3)
    }

    func testPaywallFooterFallsBackWithoutHardcodedEuroAmount() {
        let footer = SubscriptionLegal.paywallFooter(language: "de", prices: SubscriptionLegal.Prices())
        XCTAssertFalse(footer.contains("5,99"))
        XCTAssertTrue(footer.contains("3 Tage"))
    }

    func testTermsURLOpensInAppLegal() {
        XCTAssertEqual(
            SubscriptionLegal.presentsInAppLegal(from: URL(string: "https://culinaai.com/terms")!),
            .terms
        )
        XCTAssertEqual(
            SubscriptionLegal.presentsInAppLegal(from: URL(string: "https://www.culinaai.com/privacy")!),
            .privacy
        )
    }
}
