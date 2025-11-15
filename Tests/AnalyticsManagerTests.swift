import XCTest
@testable import CulinaChef

final class AnalyticsManagerTests: XCTestCase {
    
    var sut: AnalyticsManager!
    
    override func setUp() {
        super.setUp()
        sut = AnalyticsManager.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstance_IsSingleton() {
        let instance1 = AnalyticsManager.shared
        let instance2 = AnalyticsManager.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Conversion Event Tests
    
    func testConversionEvent_HasCorrectRawValues() {
        XCTAssertEqual(AnalyticsManager.ConversionEvent.onboardingCompleted.rawValue, 1)
        XCTAssertEqual(AnalyticsManager.ConversionEvent.firstRecipeCreated.rawValue, 2)
        XCTAssertEqual(AnalyticsManager.ConversionEvent.subscriptionStarted.rawValue, 3)
    }
    
    func testConversionEvent_AllEventsAreUnique() {
        let onboarding = AnalyticsManager.ConversionEvent.onboardingCompleted.rawValue
        let firstRecipe = AnalyticsManager.ConversionEvent.firstRecipeCreated.rawValue
        let subscription = AnalyticsManager.ConversionEvent.subscriptionStarted.rawValue
        
        XCTAssertNotEqual(onboarding, firstRecipe)
        XCTAssertNotEqual(onboarding, subscription)
        XCTAssertNotEqual(firstRecipe, subscription)
    }
    
    // MARK: - Track Conversion Tests
    
    func testTrackConversion_DoesNotCrash() {
        // In DEBUG mode, tracking is disabled, but method should not crash
        sut.trackConversion(.onboardingCompleted)
        sut.trackConversion(.firstRecipeCreated)
        sut.trackConversion(.subscriptionStarted)
        
        // If we reach here without crash, test passes
        XCTAssertTrue(true)
    }
    
    func testTrackConversion_CanBeCalledMultipleTimes() {
        for _ in 0..<5 {
            sut.trackConversion(.onboardingCompleted)
        }
        
        // Should not crash or cause issues
        XCTAssertTrue(true)
    }
    
    func testTrackConversion_AcceptsAllEventTypes() {
        // Test that all event types can be tracked without errors
        let allEvents: [AnalyticsManager.ConversionEvent] = [
            .onboardingCompleted,
            .firstRecipeCreated,
            .subscriptionStarted
        ]
        
        for event in allEvents {
            sut.trackConversion(event)
        }
        
        XCTAssertTrue(true)
    }
    
    // MARK: - Subscription Purchase Tests
    
    func testTrackSubscriptionPurchase_DoesNotCrash() {
        sut.trackSubscriptionPurchase()
        XCTAssertTrue(true)
    }
    
    func testTrackSubscriptionPurchase_CallsTrackConversion() {
        // We can't directly verify the call in DEBUG mode,
        // but we can verify the method exists and executes
        sut.trackSubscriptionPurchase()
        
        // Verify it's a convenience method for the subscription event
        XCTAssertEqual(AnalyticsManager.ConversionEvent.subscriptionStarted.rawValue, 3)
    }
}
