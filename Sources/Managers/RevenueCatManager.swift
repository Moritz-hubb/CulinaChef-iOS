import Foundation
import RevenueCat
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// RevenueCat subscription operations: configure, identify, offerings, purchases.
@MainActor
final class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var isLoading = false
    @Published var error: Error?
    
    /// Must match the entitlement identifier in the RevenueCat dashboard.
    static let unlimitedEntitlementID = "CulinaAi Unlimited"
    
    private(set) var isConfigured = false
    
    private override init() {
        super.init()
    }
    
    func configure(userId: String? = nil) {
        guard !isConfigured else {
            Logger.debug("[RevenueCat] Already configured", category: .data)
            return
        }
        
        let apiKey = Config.revenueCatAPIKey
        guard !apiKey.isEmpty else {
            Logger.error("[RevenueCat] Missing API key — skip configure", category: .data)
            return
        }
        
        let appUserID = userId ?? KeychainManager.get(key: "user_id")
        Logger.info("[RevenueCat] Configuring SDK", category: .data)
        
        Purchases.logLevel = Config.currentEnvironment == .development ? .debug : .info
        
        var builder = Configuration.Builder(withAPIKey: apiKey)
        if let appUserID, !appUserID.isEmpty {
            builder = builder.with(appUserID: appUserID)
        }
        Purchases.configure(with: builder.build())
        Purchases.shared.delegate = self
        isConfigured = true
        
        Task {
            await loadCustomerInfo()
            await loadOfferings()
        }
    }
    
    func identify(userId: String) async throws {
        guard isConfigured, Purchases.isConfigured else { return }
        Logger.info("[RevenueCat] Identifying user", category: .data)
        let result = try await Purchases.shared.logIn(userId)
        customerInfo = result.customerInfo
    }
    
    func logOut() async throws {
        guard isConfigured, Purchases.isConfigured else { return }
        Logger.info("[RevenueCat] Logging out user", category: .data)
        customerInfo = try await Purchases.shared.logOut()
    }
    
    func loadCustomerInfo() async {
        guard isConfigured, Purchases.isConfigured else { return }
        isLoading = true
        error = nil
        do {
            let info = try await Purchases.shared.customerInfo()
            customerInfo = info
            isLoading = false
            Logger.info(
                "[RevenueCat] Customer info loaded — subscribed: \(info.entitlements[Self.unlimitedEntitlementID]?.isActive == true)",
                category: .data
            )
        } catch {
            self.error = error
            isLoading = false
            Logger.error("[RevenueCat] Failed to load customer info", error: error, category: .data)
        }
    }
    
    var isSubscribed: Bool {
        customerInfo?.entitlements[Self.unlimitedEntitlementID]?.isActive == true
    }
    
    var expirationDate: Date? {
        customerInfo?.entitlements[Self.unlimitedEntitlementID]?.expirationDate
    }
    
    var periodEnd: Date? { expirationDate }
    
    var willRenew: Bool {
        customerInfo?.entitlements[Self.unlimitedEntitlementID]?.willRenew == true
    }
    
    var activeProductIdentifier: String? {
        customerInfo?.entitlements[Self.unlimitedEntitlementID]?.productIdentifier
    }
    
    func loadOfferings() async {
        guard isConfigured, Purchases.isConfigured else { return }
        do {
            offerings = try await Purchases.shared.offerings()
            Logger.info(
                "[RevenueCat] Offerings loaded — packages: \(offerings?.current?.availablePackages.count ?? 0)",
                category: .data
            )
        } catch {
            self.error = error
            Logger.error("[RevenueCat] Failed to load offerings", error: error, category: .data)
        }
    }
    
    var availablePackages: [Package] {
        offerings?.current?.availablePackages ?? []
    }
    
    var monthlyPackage: Package? {
        availablePackages.first { $0.packageType == .monthly }
            ?? availablePackages.first { $0.storeProduct.subscriptionPeriod?.unit == .month }
    }
    
    var yearlyPackage: Package? {
        availablePackages.first { $0.packageType == .annual }
            ?? availablePackages.first { $0.storeProduct.subscriptionPeriod?.unit == .year }
    }
    
    func purchase(package: Package) async throws -> (StoreTransaction?, CustomerInfo) {
        Logger.info("[RevenueCat] Starting purchase for package: \(package.identifier)", category: .data)
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled {
            throw RevenueCatError.userCancelled
        }
        customerInfo = result.customerInfo
        Logger.info("[RevenueCat] Purchase successful", category: .data)
        return (result.transaction, result.customerInfo)
    }
    
    func restorePurchases() async throws {
        Logger.info("[RevenueCat] Restoring purchases", category: .data)
        customerInfo = try await Purchases.shared.restorePurchases()
        Logger.info("[RevenueCat] Restore finished — subscribed: \(isSubscribed)", category: .data)
    }
    
    var canShowCustomerCenter: Bool {
        customerInfo != nil
    }
    
    func showCustomerCenter() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            Logger.info(
                "[RevenueCat] Customer info updated — subscribed: \(customerInfo.entitlements[Self.unlimitedEntitlementID]?.isActive == true)",
                category: .data
            )
        }
    }
}

enum RevenueCatError: LocalizedError, Equatable {
    case userCancelled
    case noOfferingsAvailable
    case packageNotFound
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .noOfferingsAvailable:
            return "No subscription packages available"
        case .packageNotFound:
            return "Subscription package not found"
        case .configurationError:
            return "RevenueCat configuration error"
        }
    }
}
