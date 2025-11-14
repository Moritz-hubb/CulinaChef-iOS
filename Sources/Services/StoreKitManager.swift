import Foundation
import StoreKit

@MainActor
final class StoreKitManager {
    static let monthlyProductId = "com.moritzserrin.culinachef.unlimited.monthly"

    private(set) var product: Product?

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.monthlyProductId])
            self.product = products.first
        } catch {
            print("[StoreKit] Failed to load products: \\(error)")
        }
    }

    func purchaseMonthly() async throws -> Transaction? {
        if product == nil { await loadProducts() }
        guard let product else { throw NSError(domain: "StoreKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Produkt nicht gefunden"]) }
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func restore() async throws {
        try await AppStore.sync()
    }

    func hasActiveEntitlement() async -> Bool {
        for await ent in Transaction.currentEntitlements {
            if case .verified(let t) = ent, t.productID == Self.monthlyProductId {
                if t.revocationDate == nil, (t.expirationDate ?? .distantFuture) > Date() {
                    return true
                }
            }
        }
        return false
    }
    
    func getSubscriptionInfo() async -> (isActive: Bool, willRenew: Bool, expiresAt: Date?)? {
        for await ent in Transaction.currentEntitlements {
            if case .verified(let t) = ent, t.productID == Self.monthlyProductId {
                let now = Date()
                let expiresAt = t.expirationDate
                let isActive = t.revocationDate == nil && (expiresAt ?? .distantFuture) > now
                
                // Check if subscription will auto-renew
                // In StoreKit 2, if there's no explicit cancellation, it will renew
                // We need to check the subscription status from Product.SubscriptionInfo
                var willRenew = true
                
                if let product = self.product {
                    if let status = try? await product.subscription?.status.first {
                        // Check if user cancelled but subscription is still active
                        // renewalInfo is a VerificationResult, need to unwrap it
                        if case .verified(let renewalInfo) = status.renewalInfo {
                            willRenew = status.state != .revoked && renewalInfo.willAutoRenew
                        }
                    }
                }
                
                return (isActive: isActive, willRenew: willRenew, expiresAt: expiresAt)
            }
        }
        return nil
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "Kauf konnte nicht verifiziert werden"])
        case .verified(let t):
            return t
        }
    }
}