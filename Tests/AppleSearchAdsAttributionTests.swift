import XCTest
@testable import CulinaChef

final class AppleSearchAdsAttributionTests: XCTestCase {

    func testEnable_DoesNotCrashWhenRevenueCatIsNotConfigured() {
        AppleSearchAdsAttribution.enable()
        XCTAssertTrue(true)
    }

    func testEnable_CanBeCalledMoreThanOnce() {
        AppleSearchAdsAttribution.enable()
        AppleSearchAdsAttribution.enable()
        XCTAssertTrue(true)
    }
}
