import StoreKit
import SuperwallKit
import RevenueCat

enum PurchasingError: LocalizedError {
    case sk2ProductNotFound
    
    var errorDescription: String? {
        switch self {
        case .sk2ProductNotFound:
            return "Superwall did not pass a StoreKit 2 product. Superwall must use StoreKit 2."
        }
    }
}

/// Superwall `PurchaseController` that routes paywall purchases through RevenueCat.
/// Superwall shows the paywall; RevenueCat remains the source of truth for entitlements.
final class RCPurchaseController: PurchaseController {
    
    func syncSubscriptionStatus() {
        guard Purchases.isConfigured else {
            Logger.error("[Superwall] RevenueCat must be configured before syncing subscription status", category: .data)
            return
        }
        
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                let entitlements = Set(customerInfo.entitlements.activeInCurrentEnvironment.keys.map {
                    Entitlement(id: $0)
                })
                await MainActor.run {
                    if entitlements.isEmpty {
                        Superwall.shared.subscriptionStatus = .inactive
                    } else {
                        Superwall.shared.subscriptionStatus = .active(entitlements)
                    }
                }
            }
        }
    }
    
    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            guard let sk2Product = product.sk2Product else {
                throw PurchasingError.sk2ProductNotFound
            }
            let storeProduct = RevenueCat.StoreProduct(sk2Product: sk2Product)
            let revenueCatResult = try await Purchases.shared.purchase(product: storeProduct)
            if revenueCatResult.userCancelled {
                return .cancelled
            }
            return .purchased
        } catch let error as ErrorCode where error == .paymentPendingError {
            return .pending
        } catch {
            return .failed(error)
        }
    }
    
    func restorePurchases() async -> RestorationResult {
        do {
            _ = try await Purchases.shared.restorePurchases()
            return .restored
        } catch {
            return .failed(error)
        }
    }
}
