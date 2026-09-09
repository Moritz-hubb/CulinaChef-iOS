import Foundation

/// Defines all features in the app that can be gated behind subscriptions
enum Feature {
    // AI-powered features (require unlimited subscription)
    case aiChat
    case aiRecipeGenerator
    case aiRecipeAnalysis
    
    // Free features (available to all users)
    case manualRecipes
    case shoppingList
    case communityLibrary
    case recipeManagement
}

extension AppState {
    /// Check if the current user has access to a specific feature.
    /// AI access is based on RevenueCat entitlement `CulinaAi Unlimited` (`isSubscribed`).
    /// The backend still re-checks RevenueCat/DB; this only avoids sending the request.
    func hasAccess(to feature: Feature) -> Bool {
        switch feature {
        case .aiChat, .aiRecipeGenerator, .aiRecipeAnalysis:
            return isSubscribed
        case .manualRecipes, .shoppingList, .communityLibrary, .recipeManagement:
            return true
        }
    }
    
    /// Refreshes RevenueCat customer info, then allows the AI call or presents the Superwall paywall.
    @discardableResult
    func ensureAIAccess(for feature: Feature) async -> Bool {
        await refreshSubscriptionStatusFromStoreKit()
        if hasAccess(to: feature) {
            return true
        }
        presentAIPaywall()
        return false
    }
    
    func presentAIPaywall() {
        Monetization.shared.register(placement: SuperwallPlacements.campaignTrigger)
    }
    
    /// If the backend returned 403 SUBSCRIPTION_REQUIRED, show the paywall and return true.
    @discardableResult
    func handleAISubscriptionDenied(_ error: Error) -> Bool {
        guard BackendHTTPError.isSubscriptionRequired(error) else { return false }
        presentAIPaywall()
        return true
    }
    
    /// Get a user-friendly description of why access is restricted
    func accessRestrictionReason(for feature: Feature) -> String {
        switch feature {
        case .aiChat:
            return L.error_aiChatRestricted.localized
        case .aiRecipeGenerator:
            return L.error_aiRecipeRestricted.localized
        case .aiRecipeAnalysis:
            return L.error_aiAnalysisRestricted.localized
        default:
            return ""
        }
    }
}
