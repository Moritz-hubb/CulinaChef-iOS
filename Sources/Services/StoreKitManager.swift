import Foundation
import StoreKit

// Helper function for timeout
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    let localizedDescription = "Operation timed out"
}

@MainActor
/// Verwaltet alle StoreKit-2-Operationen rund um das Monatsabo.
///
/// Verantwortlichkeiten:
/// - Laden der Produkt-Metadaten aus dem App Store.
/// - Kauf-Flow inkl. Verifikationsschritt.
/// - Wiederherstellung von Käufen und Prüfung der aktiven Entitlements.
final class StoreKitManager {
    /// Produkt-ID des monatlichen Abos im App Store.
    static let monthlyProductId = "com.moritzserrin.culinachef.unlimited.subscription"

    /// Zuletzt aus dem App Store geladene Produktbeschreibung.
    private(set) var product: Product?

    /// Lädt die Produktinformationen für das Monatsabo aus dem App Store.
    ///
    /// Fehler werden geloggt, aber bewusst nicht nach außen propagiert, damit die
    /// UI den Fehlerfluss kontrollieren kann.
    func loadProducts() async {
        // Use print() directly without string interpolation to avoid hangs
        print("[StoreKit] START loadProducts()")
        print("[StoreKit] Product ID:", Self.monthlyProductId)
        
        // Check if we're using StoreKit Configuration (Debug) or real App Store Connect (Release)
        #if DEBUG
        print("[StoreKit] Mode: DEBUG - Using StoreKit Configuration file if available")
        #else
        print("[StoreKit] Mode: RELEASE - Loading from App Store Connect")
        #endif
        
        do {
            print("[StoreKit] About to call Product.products()")
            
            // Add timeout to prevent hanging indefinitely
            let products = try await withTimeout(seconds: 10) {
                try await Product.products(for: [Self.monthlyProductId])
            }
            
            print("[StoreKit] Product.products() returned")
            print("[StoreKit] Product count:", products.count)
            
            if products.isEmpty {
                print("[StoreKit] ❌ CRITICAL: No products found!")
                print("[StoreKit] ========================================")
                print("[StoreKit] DIAGNOSTIC CHECKLIST:")
                print("[StoreKit] 1. Product ID: \(Self.monthlyProductId)")
                print("[StoreKit] 2. Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
                print("[StoreKit] 3. Build Mode: \(#if DEBUG "DEBUG" #else "RELEASE" #endif)")
                
                // Check if we're in TestFlight
                #if !DEBUG
                if Bundle.main.appStoreReceiptURL != nil {
                    print("[StoreKit] 4. App Store Receipt: EXISTS (TestFlight/App Store)")
                } else {
                    print("[StoreKit] 4. App Store Receipt: NOT FOUND")
                }
                #endif
                
                print("[StoreKit] ========================================")
                print("[StoreKit] COMMON FIXES:")
                print("[StoreKit] A. App Store Connect → Subscriptions:")
                print("[StoreKit]    - Subscription Status must be 'Ready to Submit' or 'Approved'")
                print("[StoreKit]    - NOT 'Waiting for Review' (won't work!)")
                print("[StoreKit] B. Subscription must be linked to your app:")
                print("[StoreKit]    - App Store Connect → Your App → Subscriptions")
                print("[StoreKit]    - Click 'Manage' next to your subscription group")
                print("[StoreKit]    - Ensure subscription is in the group")
                print("[StoreKit] C. App must be submitted at least once:")
                print("[StoreKit]    - Even if rejected, app must exist in App Store Connect")
                print("[StoreKit] D. TestFlight Sandbox Account:")
                print("[StoreKit]    - Settings → App Store → Sandbox Account")
                print("[StoreKit]    - Must be logged in with Sandbox Tester")
                print("[StoreKit] E. Product ID must match EXACTLY:")
                print("[StoreKit]    - No spaces, no typos")
                print("[StoreKit]    - Case-sensitive!")
                print("[StoreKit] ========================================")
            } else {
                print("[StoreKit] ✅ SUCCESS: Product found!")
                if let product = products.first {
                    print("[StoreKit] Product Details:")
                    print("[StoreKit]   - ID: \(product.id)")
                    print("[StoreKit]   - Display Name: '\(product.displayName)'")
                    print("[StoreKit]   - Description: '\(product.description)'")
                    print("[StoreKit]   - Price: \(product.displayPrice)")
                    
                    #if DEBUG
                    if product.displayName.isEmpty {
                        print("[StoreKit] ⚠️ NOTE: Empty display name = StoreKit Configuration file")
                    } else {
                        print("[StoreKit] ✅ NOTE: Has display name = App Store Connect")
                    }
                    #else
                    if product.displayName.isEmpty {
                        print("[StoreKit] ⚠️ WARNING: Empty display name in RELEASE build!")
                        print("[StoreKit] This suggests product metadata not loaded from App Store Connect")
                    } else {
                        print("[StoreKit] ✅ Product metadata loaded from App Store Connect")
                    }
                    #endif
                }
            }
            
            Logger.info("[StoreKit] Received \(products.count) product(s) from StoreKit", category: .data)
            
            // Log all returned products (should be 0 or 1)
            if products.isEmpty {
                Logger.error("[StoreKit] ⚠️ NO PRODUCTS RETURNED - Empty array from StoreKit", category: .data)
                Logger.error("[StoreKit] This means StoreKit could not find the product with ID: \(Self.monthlyProductId)", category: .data)
            } else {
                for (index, prod) in products.enumerated() {
                    Logger.info("[StoreKit] Product[\(index)]:", category: .data)
                    Logger.info("[StoreKit]   - ID: \(prod.id)", category: .data)
                    Logger.info("[StoreKit]   - Display Name: \(prod.displayName)", category: .data)
                    Logger.info("[StoreKit]   - Description: \(prod.description)", category: .data)
                    Logger.info("[StoreKit]   - Display Price: \(prod.displayPrice)", category: .data)
                    Logger.info("[StoreKit]   - Price: \(prod.price)", category: .data)
                    Logger.info("[StoreKit]   - Type: \(String(describing: prod.type))", category: .data)
                    if let subscription = prod.subscription {
                        Logger.info("[StoreKit]   - Subscription Period: \(subscription.subscriptionPeriod.debugDescription)", category: .data)
                        Logger.info("[StoreKit]   - Intro Offer: \(subscription.introductoryOffer != nil ? "Yes" : "No")", category: .data)
                    }
                }
            }
            
            self.product = products.first
            
            if let product = self.product {
                Logger.info("[StoreKit] ✅ Product successfully loaded and stored", category: .data)
                Logger.info("[StoreKit] Stored product ID: \(product.id)", category: .data)
                Logger.info("[StoreKit] Stored product name: \(product.displayName)", category: .data)
                Logger.info("[StoreKit] Stored product price: \(product.displayPrice)", category: .data)
                
                // Verify product ID matches
                if product.id != Self.monthlyProductId {
                    Logger.error("[StoreKit] ⚠️ WARNING: Product ID mismatch!", category: .data)
                    Logger.error("[StoreKit] Expected: \(Self.monthlyProductId)", category: .data)
                    Logger.error("[StoreKit] Got: \(product.id)", category: .data)
                }
            } else {
                let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
                Logger.error("[StoreKit] ❌ PRODUCT NOT FOUND - products.first is nil", category: .data)
                Logger.error("[StoreKit] Product ID searched: \(Self.monthlyProductId)", category: .data)
                Logger.error("[StoreKit] Bundle ID: \(bundleId)", category: .data)
                Logger.error("[StoreKit] Products array count: \(products.count)", category: .data)
                
                Logger.error("[StoreKit] Possible causes:", category: .data)
                Logger.error("[StoreKit] 1. Product ID mismatch in App Store Connect: \(Self.monthlyProductId)", category: .data)
                Logger.error("[StoreKit] 2. Bundle ID mismatch: Expected '\(bundleId)' in App Store Connect", category: .data)
                Logger.error("[StoreKit] 3. Subscription not created/configured in App Store Connect", category: .data)
                Logger.error("[StoreKit] 4. Subscription not linked to app in App Store Connect", category: .data)
                Logger.error("[StoreKit] 5. App not submitted/reviewed in App Store Connect yet", category: .data)
                Logger.error("[StoreKit] 6. StoreKit Configuration file not loaded in Xcode Scheme", category: .data)
                Logger.error("[StoreKit] 7. Network connectivity issue preventing StoreKit from reaching App Store", category: .data)
                Logger.error("[StoreKit] 8. Sandbox/TestFlight environment issue", category: .data)
                
                // Additional diagnostics
                Logger.error("[StoreKit] Diagnostic: Check Xcode Scheme → Run → Options → StoreKit Configuration", category: .data)
                Logger.error("[StoreKit] Diagnostic: Verify product exists in App Store Connect with exact ID: \(Self.monthlyProductId)", category: .data)
            }
        } catch {
            print("[StoreKit] ERROR occurred")
            print("[StoreKit] Error description:", error.localizedDescription)
            
            if error is TimeoutError {
                print("[StoreKit] TIMEOUT: Product.products() took longer than 10 seconds")
                print("[StoreKit] This usually means:")
                print("[StoreKit] 1. StoreKit Configuration not loaded in Xcode Scheme")
                print("[StoreKit] 2. Network connectivity issue")
                print("[StoreKit] 3. App Store services not available in Simulator")
            } else if let storeKitError = error as? StoreKitError {
                print("[StoreKit] StoreKitError type:", String(describing: storeKitError))
            }
            
            Logger.error("[StoreKit] Failed to load products", error: error, category: .data)
        }
        
        let isLoaded = self.product != nil
        print("[StoreKit] END loadProducts() - Product loaded:", isLoaded)
    }

    /// Startet den Kauf-Flow für das Monatsabo.
    ///
    /// - Returns: Verifizierte `Transaction` oder `nil`, wenn der Nutzer abbricht
    ///   oder der Kauf im Status `pending` bleibt.
    /// - Throws: `NSError`, falls die Transaktion nicht verifiziert werden konnte.
    func purchaseMonthly() async throws -> Transaction? {
        Logger.info("[StoreKit] ========== START purchaseMonthly() ==========", category: .data)
        Logger.info("[StoreKit] Current product state: \(product != nil ? "LOADED" : "NIL")", category: .data)
        
        if product == nil {
            Logger.info("[StoreKit] Product is nil, calling loadProducts() first...", category: .data)
            await loadProducts()
            Logger.info("[StoreKit] After loadProducts(), product state: \(product != nil ? "LOADED" : "NIL")", category: .data)
        }
        
        guard let product else {
            let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
            let errorMessage = "Produkt nicht gefunden. Product ID: \(Self.monthlyProductId), Bundle ID: \(bundleId)"
            Logger.error("[StoreKit] ❌ Cannot purchase - Product is nil", category: .data)
            Logger.error("[StoreKit] Product ID: \(Self.monthlyProductId)", category: .data)
            Logger.error("[StoreKit] Bundle ID: \(bundleId)", category: .data)
            Logger.error("[StoreKit] This means loadProducts() failed to load the product", category: .data)
            Logger.error("[StoreKit] Check the loadProducts() logs above for details", category: .data)
            throw NSError(domain: "StoreKit", code: -1, userInfo: [
                NSLocalizedDescriptionKey: errorMessage,
                "ProductID": Self.monthlyProductId,
                "BundleID": bundleId
            ])
        }
        
        Logger.info("[StoreKit] Product available for purchase:", category: .data)
        Logger.info("[StoreKit]   - ID: \(product.id)", category: .data)
        Logger.info("[StoreKit]   - Name: \(product.displayName)", category: .data)
        Logger.info("[StoreKit]   - Price: \(product.displayPrice)", category: .data)
        Logger.info("[StoreKit] Calling product.purchase()...", category: .data)
        
        let purchaseStartTime = Date()
        let result = try await product.purchase()
        let purchaseDuration = Date().timeIntervalSince(purchaseStartTime)
        
        Logger.info("[StoreKit] Purchase completed in \(String(format: "%.2f", purchaseDuration))s", category: .data)
        
        switch result {
        case .success(let verificationResult):
            Logger.info("[StoreKit] ✅ Purchase successful, verifying transaction...", category: .data)
            let transaction = try checkVerified(verificationResult)
            Logger.info("[StoreKit] Transaction verified:", category: .data)
            Logger.info("[StoreKit]   - Transaction ID: \(transaction.id)", category: .data)
            Logger.info("[StoreKit]   - Original Transaction ID: \(transaction.originalID)", category: .data)
            Logger.info("[StoreKit]   - Product ID: \(transaction.productID)", category: .data)
            Logger.info("[StoreKit]   - Purchase Date: \(transaction.purchaseDate)", category: .data)
            if let expirationDate = transaction.expirationDate {
                Logger.info("[StoreKit]   - Expiration Date: \(expirationDate)", category: .data)
            }
            await transaction.finish()
            Logger.info("[StoreKit] Transaction finished", category: .data)
            Logger.info("[StoreKit] ========== END purchaseMonthly() - SUCCESS ==========", category: .data)
            return transaction
        case .userCancelled:
            Logger.info("[StoreKit] ⚠️ Purchase cancelled by user", category: .data)
            Logger.info("[StoreKit] ========== END purchaseMonthly() - CANCELLED ==========", category: .data)
            return nil
        case .pending:
            Logger.info("[StoreKit] ⚠️ Purchase is pending (awaiting approval)", category: .data)
            Logger.info("[StoreKit] ========== END purchaseMonthly() - PENDING ==========", category: .data)
            return nil
        @unknown default:
            Logger.info("[StoreKit] ⚠️ Purchase returned unknown result case", category: .data)
            Logger.info("[StoreKit] ========== END purchaseMonthly() - UNKNOWN ==========", category: .data)
            return nil
        }
    }

    /// Stößt eine Wiederherstellung von Käufen im App Store an.
    func restore() async throws {
        Logger.info("[StoreKit] ========== START restore() ==========", category: .data)
        Logger.info("[StoreKit] Calling AppStore.sync()...", category: .data)
        
        let startTime = Date()
        do {
            try await AppStore.sync()
            let duration = Date().timeIntervalSince(startTime)
            Logger.info("[StoreKit] ✅ AppStore.sync() completed successfully in \(String(format: "%.2f", duration))s", category: .data)
            Logger.info("[StoreKit] ========== END restore() - SUCCESS ==========", category: .data)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            Logger.error("[StoreKit] ❌ AppStore.sync() failed after \(String(format: "%.2f", duration))s", category: .data)
            Logger.error("[StoreKit] Error: \(error.localizedDescription)", category: .data)
            if let nsError = error as NSError? {
                Logger.error("[StoreKit] Error domain: \(nsError.domain), code: \(nsError.code)", category: .data)
            }
            Logger.info("[StoreKit] ========== END restore() - ERROR ==========", category: .data)
            throw error
        }
    }

    /// Prüft, ob aktuell ein aktives Entitlement für das Monatsabo besteht.
    ///
    /// - Returns: `true`, wenn die Subscription nicht widerrufen und nicht abgelaufen ist.
    func hasActiveEntitlement() async -> Bool {
        Logger.debug("[StoreKit] Checking for active entitlements...", category: .data)
        var entitlementCount = 0
        var matchingEntitlementCount = 0
        
        for await ent in Transaction.currentEntitlements {
            entitlementCount += 1
            Logger.debug("[StoreKit] Found entitlement #\(entitlementCount)", category: .data)
            
            switch ent {
            case .verified(let transaction):
                Logger.debug("[StoreKit]   - Transaction ID: \(transaction.id)", category: .data)
                Logger.debug("[StoreKit]   - Product ID: \(transaction.productID)", category: .data)
                Logger.debug("[StoreKit]   - Original ID: \(transaction.originalID)", category: .data)
                Logger.debug("[StoreKit]   - Purchase Date: \(transaction.purchaseDate)", category: .data)
                if let expirationDate = transaction.expirationDate {
                    Logger.debug("[StoreKit]   - Expiration Date: \(expirationDate)", category: .data)
                    Logger.debug("[StoreKit]   - Is Expired: \(expirationDate < Date())", category: .data)
                } else {
                    Logger.debug("[StoreKit]   - Expiration Date: nil (non-expiring)", category: .data)
                }
                Logger.debug("[StoreKit]   - Revocation Date: \(transaction.revocationDate?.description ?? "nil")", category: .data)
                
                if transaction.productID == Self.monthlyProductId {
                    matchingEntitlementCount += 1
                    Logger.debug("[StoreKit]   ✅ MATCHES our product ID!", category: .data)
                    
                    let isRevoked = transaction.revocationDate != nil
                    let expirationDate = transaction.expirationDate ?? .distantFuture
                    let isExpired = expirationDate <= Date()
                    let isActive = !isRevoked && !isExpired
                    
                    Logger.debug("[StoreKit]   - Is Revoked: \(isRevoked)", category: .data)
                    Logger.debug("[StoreKit]   - Is Expired: \(isExpired)", category: .data)
                    Logger.debug("[StoreKit]   - Is Active: \(isActive)", category: .data)
                    
                    if isActive {
                        Logger.info("[StoreKit] ✅ Active entitlement found!", category: .data)
                        return true
                    } else {
                        Logger.info("[StoreKit] ⚠️ Matching entitlement found but not active (revoked: \(isRevoked), expired: \(isExpired))", category: .data)
                    }
                } else {
                    Logger.debug("[StoreKit]   - Product ID doesn't match (expected: \(Self.monthlyProductId))", category: .data)
                }
            case .unverified(_, let error):
                Logger.info("[StoreKit]   ⚠️ Unverified entitlement (error: \(error.localizedDescription))", category: .data)
            }
        }
        
        Logger.debug("[StoreKit] Total entitlements checked: \(entitlementCount)", category: .data)
        Logger.debug("[StoreKit] Matching entitlements: \(matchingEntitlementCount)", category: .data)
        Logger.debug("[StoreKit] No active entitlement found", category: .data)
        return false
    }
    
    /// Liefert detaillierte Informationen zur aktuellen Subscription, falls vorhanden.
    ///
    /// - Returns: Tuple mit Aktivitätsstatus, Auto-Renew-Flag und Ablaufdatum oder `nil`,
    ///   wenn keine passende Entitlement-Transaktion gefunden wurde.
    func getSubscriptionInfo() async -> (isActive: Bool, willRenew: Bool, expiresAt: Date?)? {
        for await ent in Transaction.currentEntitlements {
            if case .verified(let transaction) = ent, transaction.productID == Self.monthlyProductId {
                let now = Date()
                let expiresAt = transaction.expirationDate
                let isActive = transaction.revocationDate == nil && (expiresAt ?? .distantFuture) > now
                
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
        case .verified(let transaction):
            return transaction
        }
    }
}
