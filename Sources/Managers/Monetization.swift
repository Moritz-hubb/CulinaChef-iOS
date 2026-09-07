import Foundation
import SuperwallKit

/// Placement names must match campaigns in the Superwall dashboard.
enum SuperwallPlacements {
    static let campaignTrigger = "campaign_trigger"
    static let aiFeature = "ai_feature"
}

/// Starts Superwall + RevenueCat in the official order and keeps user IDs in sync.
@MainActor
final class Monetization {
    static let shared = Monetization()
    
    private let purchaseController = RCPurchaseController()
    private var didStart = false
    
    private init() {}
    
    /// Call once from `CulinaChefApp.init()` before creating `AppState`.
    /// Superwall is configured first (with this purchase controller), then RevenueCat, then status sync.
    func start() {
        guard !didStart else { return }
        didStart = true
        
        if Config.isSuperwallConfigured {
            Superwall.configure(
                apiKey: Config.superwallAPIKey,
                purchaseController: purchaseController
            )
            Logger.info("[Superwall] Configured with RevenueCat purchase controller", category: .data)
        } else {
            Logger.warning("[Superwall] Missing API key — paywalls disabled until SUPERWALL_API_KEY is set", category: .data)
        }
        
        let userId = KeychainManager.get(key: "user_id")
        RevenueCatManager.shared.configure(userId: userId)
        
        if Config.isSuperwallConfigured, RevenueCatManager.shared.isConfigured {
            purchaseController.syncSubscriptionStatus()
        }
        
        if let userId {
            Task { try? await identify(userId: userId) }
        }
    }
    
    func identify(userId: String) async throws {
        try await RevenueCatManager.shared.identify(userId: userId)
        if Config.isSuperwallConfigured {
            Superwall.shared.identify(userId: userId)
        }
    }
    
    func logOut() async {
        try? await RevenueCatManager.shared.logOut()
        if Config.isSuperwallConfigured {
            Superwall.shared.reset()
        }
    }
    
    func handleDeepLink(_ url: URL) {
        guard Config.isSuperwallConfigured else { return }
        Superwall.handleDeepLink(url)
    }
    
    /// Shows the Superwall campaign assigned to this placement (no-op if the user is already entitled).
    func register(placement: String, feature: (() -> Void)? = nil) {
        guard Config.isSuperwallConfigured else {
            feature?()
            return
        }
        if let feature {
            Superwall.shared.register(placement: placement, feature: feature)
        } else {
            Superwall.shared.register(placement: placement)
        }
    }
}
