import Foundation
import StoreKit

@MainActor
/// Verwaltet alle StoreKit-2-Operationen rund um das Monatsabo.
///
/// Verantwortlichkeiten:
/// - Laden der Produkt-Metadaten aus dem App Store.
/// - Kauf-Flow inkl. Verifikationsschritt.
/// - Wiederherstellung von Käufen und Prüfung der aktiven Entitlements.
final class StoreKitManager {
    /// Produkt-ID des monatlichen Abos im App Store.
    static let monthlyProductId = "com.moritzserrin.culinachef.unlimited.monthly"

    /// Zuletzt aus dem App Store geladene Produktbeschreibung.
    private(set) var product: Product?

    /// Lädt die Produktinformationen für das Monatsabo aus dem App Store.
    ///
    /// Fehler werden geloggt, aber bewusst nicht nach außen propagiert, damit die
    /// UI den Fehlerfluss kontrollieren kann.
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.monthlyProductId])
            self.product = products.first
        } catch {
            Logger.error("[StoreKit] Failed to load products", error: error, category: .data)
        }
    }

    /// Startet den Kauf-Flow für das Monatsabo.
    ///
    /// - Returns: Verifizierte `Transaction` oder `nil`, wenn der Nutzer abbricht
    ///   oder der Kauf im Status `pending` bleibt.
    /// - Throws: `NSError`, falls die Transaktion nicht verifiziert werden konnte.
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

    /// Stößt eine Wiederherstellung von Käufen im App Store an.
    func restore() async throws {
        try await AppStore.sync()
    }

    /// Prüft, ob aktuell ein aktives Entitlement für das Monatsabo besteht.
    ///
    /// - Returns: `true`, wenn die Subscription nicht widerrufen und nicht abgelaufen ist.
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
    
    /// Liefert detaillierte Informationen zur aktuellen Subscription, falls vorhanden.
    ///
    /// - Returns: Tuple mit Aktivitätsstatus, Auto-Renew-Flag und Ablaufdatum oder `nil`,
    ///   wenn keine passende Entitlement-Transaktion gefunden wurde.
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

    /// Hilfsfunktion zur Sicherstellung, dass eine StoreKit-Transaktion verifiziert ist.
    ///
    /// - Parameter result: Von StoreKit geliefertes `VerificationResult`.
    /// - Returns: Verifizierte Payload.
    /// - Throws: `NSError`, wenn die Verifikation fehlschlägt.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "Kauf konnte nicht verifiziert werden"])
        case .verified(let t):
            return t
        }
    }
}