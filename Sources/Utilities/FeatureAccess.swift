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
    }
    
    /// Get a user-friendly description of why access is restricted
    /// - Parameter feature: The feature that is restricted
    /// - Returns: Localized description string
    func accessRestrictionReason(for feature: Feature) -> String {
        switch feature {
        case .aiChat:
            return NSLocalizedString("ai_chat_restricted", comment: "AI Chat requires Unlimited subscription")
        case .aiRecipeGenerator:
            return NSLocalizedString("ai_recipe_restricted", comment: "AI Recipe Generation requires Unlimited subscription")
        case .aiRecipeAnalysis:
            return NSLocalizedString("ai_analysis_restricted", comment: "AI Recipe Analysis requires Unlimited subscription")
        default:
            return ""
        }
    }
}
