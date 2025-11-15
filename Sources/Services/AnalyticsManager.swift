import Foundation
import StoreKit

/// Simple analytics manager for App Store Connect custom events
/// Only use for critical conversion events (onboarding, first recipe, subscription)
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    enum ConversionEvent: Int {
        case onboardingCompleted = 1
        case firstRecipeCreated = 2
        case subscriptionStarted = 3
    }
    
    /// Track a conversion event for App Store Connect
    /// - Note: Only use sparingly for critical events, max 64 unique values
    func trackConversion(_ event: ConversionEvent) {
        #if !DEBUG
        if #available(iOS 16.1, *) {
            Task {
                do {
                    try await SKAdNetwork.updatePostbackConversionValue(
                        event.rawValue,
                        coarseValue: .high
                    )
                    Logger.info("[Analytics] Tracked conversion: \(event)", category: .data)
                } catch {
                    Logger.error("[Analytics] Failed to track conversion", error: error, category: .data)
                }
            }
        } else {
            SKAdNetwork.updatePostbackConversionValue(event.rawValue)
        }
        #endif
    }
    
    /// Track subscription purchase for App Store Connect
    func trackSubscriptionPurchase() {
        trackConversion(.subscriptionStarted)
    }
}
