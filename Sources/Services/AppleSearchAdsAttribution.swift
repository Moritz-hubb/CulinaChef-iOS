import Foundation
import RevenueCat

/// Apple Search Ads (App Store ads), not in-app banners.
///
/// Uses AdServices via RevenueCat so install and subscription conversions can be
/// attributed to Search Ads campaigns. The AdServices token is single-use; we do
/// not redeem it ourselves against Apple's API.
enum AppleSearchAdsAttribution {
    /// Call once after `Purchases.configure`. Safe if RevenueCat is not configured.
    static func enable() {
        guard Purchases.isConfigured else {
            Logger.debug("[AppleSearchAds] Skip attribution — RevenueCat is not configured", category: .data)
            return
        }

        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
        Logger.info("[AppleSearchAds] AdServices attribution enabled", category: .data)
    }
}
