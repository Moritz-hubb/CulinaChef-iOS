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
    /// Check if the current user has access to a specific feature
    /// - Parameter feature: The feature to check access for
    /// - Returns: True if user has access, false otherwise
    /// 
    /// DEVELOPMENT MODE: All features are enabled. Before launch, restore subscription check.
    /// DEV MODE: Always returns true - all features available without subscription
    func hasAccess(to feature: Feature) -> Bool {
        // DEV MODE: All features available, no subscription checks
        return true
        
        // Original code commented out for DEV MODE:
        /*
        // DEVELOPMENT: All features enabled
        return true
        
        // PRODUCTION (uncomment before launch):
        // switch feature {
        // // AI features require active subscription
        // case .aiChat, .aiRecipeGenerator, .aiRecipeAnalysis:
        //     return isSubscribed
        //     
        // // Free features are always available
        // case .manualRecipes, .shoppingList, .communityLibrary, .recipeManagement:
        //     return true
        // }
        */
    }
    
    /// Get a user-friendly description of why access is restricted
    /// - Parameter feature: The feature that is restricted
    /// - Returns: Localized description string
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
