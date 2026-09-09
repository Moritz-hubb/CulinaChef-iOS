import XCTest
@testable import CulinaChef

final class PaywallPriceMathTests: XCTestCase {
    func testSavingsPercentage_germanExamplePrices() {
        let weekly = Decimal(string: "2.99")!
        let monthly = Decimal(string: "9.99")!
        XCTAssertEqual(PaywallPriceMath.roundedSavingsPercentage(weeklyPrice: weekly, monthlyPrice: monthly), 23)
    }
    
    func testSavingsPercentage_usExamplePrices() {
        let weekly = Decimal(string: "4.99")!
        let monthly = Decimal(string: "14.99")!
        XCTAssertEqual(PaywallPriceMath.roundedSavingsPercentage(weeklyPrice: weekly, monthlyPrice: monthly), 31)
    }
    
    func testSavingsPercentage_omitsWhenWeeklyMissing() {
        XCTAssertNil(PaywallPriceMath.roundedSavingsPercentage(weeklyPrice: 0, monthlyPrice: 9.99))
    }
    
    func testMonthlyWeeklyPrice_formatsEuro() {
        let formatted = PaywallPriceMath.formattedMonthlyWeeklyPrice(
            monthlyPrice: Decimal(string: "9.99")!,
            currencyCode: "EUR",
            locale: Locale(identifier: "de_DE")
        )
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted?.contains("2,30") == true || formatted?.contains("2.30") == true)
    }
    
    func testStorefrontLocale_germany() {
        XCTAssertEqual(PaywallPriceMath.localeIdentifier(forStorefrontCountryCode: "DEU"), "de_DE")
        XCTAssertEqual(PaywallPriceMath.localeIdentifier(forStorefrontCountryCode: "USA"), "en_US")
    }
}
