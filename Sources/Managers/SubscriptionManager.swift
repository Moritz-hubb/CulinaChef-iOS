import Foundation
import StoreKit

/// Manager for all subscription operations (StoreKit, polling, status management)
/// Extracted from AppState to improve maintainability and separation of concerns
@MainActor
final class SubscriptionManager {
    
    // MARK: - Dependencies
    
    private let backend: BackendClient
    private let subscriptionsClient: SubscriptionsClient
    private let storeKit: StoreKitManager
    
    // MARK: - Polling Timers
    
    private var subscriptionTimer: Timer?
    private var aggressiveTimer: Timer?
    private var aggressiveUntil: Date?
    
    // MARK: - KeyPrefix Constants (for migration)
    
    private static let subscriptionKeyPrefix = "subscription_is_active_"
    private static let subscriptionLastPaymentKeyPrefix = "subscription_last_payment_"
    private static let subscriptionPeriodEndKeyPrefix = "subscription_period_end_"
    private static let subscriptionAutoRenewKeyPrefix = "subscription_autorenew_"
    
    init(backend: BackendClient, subscriptionsClient: SubscriptionsClient, storeKit: StoreKitManager) {
        self.backend = backend
        self.subscriptionsClient = subscriptionsClient
        self.storeKit = storeKit
    }
    
    // MARK: - Data Migration
    
    /// Migrate subscription data from UserDefaults to Keychain (one-time)
    func migrateSubscriptionDataToKeychain() {
        // Check if migration already happened
        let migrationKey = "subscription_migrated_to_keychain_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            Logger.debug("Subscription migration already completed", category: .data)
            return
        }
        
        // Only migrate if we have a user ID
        guard let userId = KeychainManager.get(key: "user_id") else {
            Logger.debug("No user ID found, skipping migration", category: .data)
            return
        }
        
        Logger.info("Starting subscription data migration to Keychain", category: .data)
        
        let d = UserDefaults.standard
        var migrated = false
        
        // Migrate last payment date
        if let lastPayment = d.object(forKey: key(Self.subscriptionLastPaymentKeyPrefix, for: userId)) as? Date {
            do {
                try KeychainManager.save(key: "subscription_last_payment", date: lastPayment)
                Logger.debug("Migrated last payment date", category: .data)
                migrated = true
            } catch {
                Logger.error("Failed to migrate last payment date", error: error, category: .data)
            }
        }
        
        // Migrate period end date
        if let periodEnd = d.object(forKey: key(Self.subscriptionPeriodEndKeyPrefix, for: userId)) as? Date {
            do {
                try KeychainManager.save(key: "subscription_period_end", date: periodEnd)
                Logger.debug("Migrated period end date", category: .data)
                migrated = true
            } catch {
                Logger.error("Failed to migrate period end date", error: error, category: .data)
            }
        }
        
        // Migrate auto-renew flag
        let autoRenew = d.bool(forKey: key(Self.subscriptionAutoRenewKeyPrefix, for: userId))
        do {
            try KeychainManager.save(key: "subscription_autorenew", bool: autoRenew)
            Logger.debug("Migrated auto-renew flag: \(autoRenew)", category: .data)
            migrated = true
        } catch {
            Logger.error("Failed to migrate auto-renew flag", error: error, category: .data)
        }
        
        // Mark migration as complete
        if migrated {
            d.set(true, forKey: migrationKey)
            Logger.info("Subscription data migration completed successfully", category: .data)
        }
    }
    
    private func key(_ prefix: String, for userId: String) -> String {
        "\(prefix)\(userId)"
    }
    
    // MARK: - Subscription Status
    
    struct SubscriptionStatus {
        let isSubscribed: Bool
        let periodEnd: Date?
        let lastPayment: Date?
        let autoRenew: Bool
    }
    
    func loadSubscriptionStatus(accessToken: String?) async -> SubscriptionStatus {
        guard let userId = KeychainManager.get(key: "user_id") else {
            return SubscriptionStatus(isSubscribed: false, periodEnd: nil, lastPayment: nil, autoRenew: false)
        }
        
        // Try backend first if authenticated
        if let token = accessToken {
            // Backend DTO
            if let dto = try? await backend.subscriptionStatus(accessToken: token) {
                let iso = ISO8601DateFormatter()
                let lastPayment = dto.last_payment_at.flatMap { iso.date(from: $0) }
                let periodEnd = dto.current_period_end.flatMap { iso.date(from: $0) }
                
                // Store in Keychain (secure)
                if let lp = lastPayment { try? KeychainManager.save(key: "subscription_last_payment", date: lp) }
                if let pe = periodEnd { try? KeychainManager.save(key: "subscription_period_end", date: pe) }
                try? KeychainManager.save(key: "subscription_autorenew", bool: dto.auto_renew)
                
                return SubscriptionStatus(isSubscribed: dto.is_active, periodEnd: periodEnd, lastPayment: lastPayment, autoRenew: dto.auto_renew)
            }
            
            // Fallback: direct Supabase (legacy)
            if let remote = try? await subscriptionsClient.fetchSubscription(userId: userId, accessToken: token) {
                // Store in Keychain (secure)
                if let lp = remote.lastPaymentAt { try? KeychainManager.save(key: "subscription_last_payment", date: lp) }
                if let pe = remote.currentPeriodEnd { try? KeychainManager.save(key: "subscription_period_end", date: pe) }
                try? KeychainManager.save(key: "subscription_autorenew", bool: remote.autoRenew)
                
                let isActive = remote.currentPeriodEnd.map { Date() < $0 } ?? false
                return SubscriptionStatus(isSubscribed: isActive, periodEnd: remote.currentPeriodEnd, lastPayment: remote.lastPaymentAt, autoRenew: remote.autoRenew)
            }
        }
        
        // Local fallback
        return loadSubscriptionStatusLocal()
    }
    
    private func loadSubscriptionStatusLocal() -> SubscriptionStatus {
        guard KeychainManager.get(key: "user_id") != nil else {
            return SubscriptionStatus(isSubscribed: false, periodEnd: nil, lastPayment: nil, autoRenew: false)
        }
        
        extendIfAutoRenewNeeded()
        
        let periodEnd = getSubscriptionPeriodEnd()
        let lastPayment = getSubscriptionLastPayment()
        let autoRenew = getSubscriptionAutoRenew()
        let isSubscribed = periodEnd.map { Date() < $0 } ?? false
        
        return SubscriptionStatus(isSubscribed: isSubscribed, periodEnd: periodEnd, lastPayment: lastPayment, autoRenew: autoRenew)
    }
    
    func getSubscriptionPeriodEnd() -> Date? {
        guard KeychainManager.get(key: "user_id") != nil else { return nil }
        return KeychainManager.getDate(key: "subscription_period_end")
    }
    
    func getSubscriptionLastPayment() -> Date? {
        guard KeychainManager.get(key: "user_id") != nil else { return nil }
        return KeychainManager.getDate(key: "subscription_last_payment")
    }
    
    func getSubscriptionAutoRenew() -> Bool {
        guard KeychainManager.get(key: "user_id") != nil else { return false }
        return KeychainManager.getBool(key: "subscription_autorenew") ?? false
    }
    
    private func addOneMonth(to date: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date.addingTimeInterval(30*24*60*60)
    }
    
    private func extendIfAutoRenewNeeded() {
        guard KeychainManager.get(key: "user_id") != nil else { return }
        var periodEnd = getSubscriptionPeriodEnd()
        let auto = getSubscriptionAutoRenew()
        guard auto, var end = periodEnd else { return }
        let now = Date()
        // Extend in month steps until next period end is in the future
        while now >= end {
            let newLastPayment = end
            let newEnd = addOneMonth(to: end)
            try? KeychainManager.save(key: "subscription_last_payment", date: newLastPayment)
            try? KeychainManager.save(key: "subscription_period_end", date: newEnd)
            end = newEnd
        }
    }
    
    // MARK: - StoreKit Operations
    
    func refreshSubscriptionStatusFromStoreKit() async -> Bool {
        guard KeychainManager.get(key: "user_id") != nil else { return false }
        
        // Get detailed subscription info from StoreKit
        if let info = await storeKit.getSubscriptionInfo() {
            // Store in Keychain (secure)
            try? KeychainManager.save(key: "subscription_autorenew", bool: info.willRenew)
            if let expiresAt = info.expiresAt {
                try? KeychainManager.save(key: "subscription_period_end", date: expiresAt)
            }
            return info.isActive
        } else {
            // No active entitlement found
            return false
        }
    }
    
    func purchaseStoreKit(accessToken: String?, userId: String?) async throws -> Bool {
        guard let uid = userId else {
            throw NSError(domain: "Subscription", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        
        let txn = try await storeKit.purchaseMonthly()
        
        // IMPORTANT: Only proceed if transaction exists (user completed purchase)
        guard let _ = txn else {
            // User cancelled or pending
            Logger.info("Purchase cancelled or pending", category: .data)
            return false
        }
        
        // SUCCESS: User completed purchase
        Logger.info("Purchase successful", category: .data)
        
        // Refresh from StoreKit entitlements
        let isActive = await refreshSubscriptionStatusFromStoreKit()
        
        // Read normalized values
        let now = getSubscriptionLastPayment() ?? Date()
        let periodEnd = getSubscriptionPeriodEnd() ?? addOneMonth(to: now)
        let autoRenew = getSubscriptionAutoRenew()
        
        // Sync to Supabase if authenticated
        if let token = accessToken {
            Task {
                let params = SubscriptionUpsertParams(
                    userId: uid,
                    plan: "unlimited",
                    status: "active",
                    autoRenew: autoRenew,
                    cancelAtPeriodEnd: !autoRenew,
                    lastPaymentAt: now,
                    currentPeriodEnd: periodEnd,
                    priceCents: 599,
                    currency: "EUR"
                )
                try? await subscriptionsClient.upsertSubscription(params: params, accessToken: token)
            }
        }
        
        return isActive
    }
    
    func restorePurchases() async throws -> Bool {
        try await storeKit.restore()
        return await storeKit.hasActiveEntitlement()
    }
    
    func getOriginalTransactionId() async -> String? {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == StoreKitManager.monthlyProductId {
                return String(transaction.originalID)
            }
        }
        return nil
    }
    
    // MARK: - Simulated Subscription (Legacy/Testing)
    
    func subscribeSimulated(accessToken: String?) {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        let now = Date()
        let periodEnd = addOneMonth(to: now)
        
        // Store in Keychain (secure)
        try? KeychainManager.save(key: "subscription_last_payment", date: now)
        try? KeychainManager.save(key: "subscription_period_end", date: periodEnd)
        try? KeychainManager.save(key: "subscription_autorenew", bool: true)
        
        // Push to Supabase
        if let token = accessToken {
            Task {
                let params = SubscriptionUpsertParams(
                    userId: userId,
                    plan: "unlimited",
                    status: "active",
                    autoRenew: true,
                    cancelAtPeriodEnd: false,
                    lastPaymentAt: now,
                    currentPeriodEnd: periodEnd,
                    priceCents: 599,
                    currency: "EUR"
                )
                try? await subscriptionsClient.upsertSubscription(params: params, accessToken: token)
            }
        }
    }
    
    func cancelAutoRenew(accessToken: String?) {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        
        // Store in Keychain (secure)
        try? KeychainManager.save(key: "subscription_autorenew", bool: false)
        
        if let token = accessToken {
            let periodEnd = getSubscriptionPeriodEnd()
            let now = Date()
            let status = (periodEnd != nil && now < periodEnd!) ? "in_grace" : "expired"
            Task {
                let params = SubscriptionUpsertParams(
                    userId: userId,
                    plan: "unlimited",
                    status: status,
                    autoRenew: false,
                    cancelAtPeriodEnd: true,
                    lastPaymentAt: getSubscriptionLastPayment() ?? now,
                    currentPeriodEnd: periodEnd ?? now,
                    priceCents: 599,
                    currency: "EUR"
                )
                try? await subscriptionsClient.upsertSubscription(params: params, accessToken: token)
            }
        }
    }
    
    // MARK: - Account Management
    
    func openManageSubscriptions() async {
        #if canImport(UIKit)
        if #available(iOS 15.0, *) {
            guard let scene = await UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            try? await AppStore.showManageSubscriptions(in: scene)
        } else {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await UIApplication.shared.open(url)
            }
        }
        #endif
    }
    
    func deleteAccountAndData(accessToken: String?, userId: String?, userEmail: String?) async throws {
        guard let token = accessToken, let uid = userId else {
            throw NSError(domain: "Account", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        
        // Log deletion for audit/GDPR compliance
        do {
            struct AuditLog: Encodable {
                let user_id: String
                let email: String?
                let deleted_by: String
                let reason: String
            }
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/account_deletions")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.addValue("return=minimal", forHTTPHeaderField: "Prefer")
            let log = AuditLog(user_id: uid, email: userEmail, deleted_by: "user_request", reason: "user_initiated")
            req.httpBody = try JSONEncoder().encode([log])
            _ = try? await SecureURLSession.shared.data(for: req)
        } catch {
            Logger.error("[AccountDeletion] Audit log failed", error: error, category: .data)
        }
        
        // Call backend to delete all data + auth user
        var url = Config.backendBaseURL
        url.append(path: "/account/delete")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Subscription Polling
    
    func startSubscriptionPolling(isAuthenticated: Bool, loadStatusCallback: @escaping () -> Void) {
        stopSubscriptionPolling()
        guard isAuthenticated else { return }
        // Immediate refresh on start
        loadStatusCallback()
        subscriptionTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { _ in
            loadStatusCallback()
        }
    }
    
    func stopSubscriptionPolling() {
        subscriptionTimer?.invalidate()
        subscriptionTimer = nil
        aggressiveTimer?.invalidate()
        aggressiveTimer = nil
        aggressiveUntil = nil
    }
    
    func startAggressiveSubscriptionPolling(durationSeconds: TimeInterval, intervalSeconds: TimeInterval, loadStatusCallback: @escaping () -> Void) {
        aggressiveTimer?.invalidate()
        aggressiveTimer = nil
        aggressiveUntil = Date().addingTimeInterval(durationSeconds)
        aggressiveTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self = self else { return }
                loadStatusCallback()
                if let until = self.aggressiveUntil, Date() >= until {
                    t.invalidate()
                    self.aggressiveTimer = nil
                    self.aggressiveUntil = nil
                }
            }
        }
    }
}
