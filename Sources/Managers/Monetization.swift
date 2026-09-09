import Foundation
import RevenueCat
import StoreKit
import SuperwallKit
#if canImport(UIKit)
import UIKit
#endif

/// Placement names must match campaigns in the Superwall dashboard.
enum SuperwallPlacements {
    static let campaignTrigger = "campaign_trigger"
    static let aiFeature = "ai_feature"
}

/// Product names assigned in the Superwall paywall editor (`{{ products.<name>.price }}`).
enum SuperwallProductNames {
    static let weeklyPlanTrial = "weeklyPlanTrial"
    static let monthlyPlanTrial = "monthlyPlanTrial"
}

/// Apple product identifiers. Superwall editor names are not StoreKit IDs.
enum AppleSubscriptionProductIDs {
    static let monthly = "com.moritzserrin.culinachef.unlimited.subscription"
}

/// Savings / weekly-equivalent math for Superwall Parameter variables.
enum PaywallPriceMath {
    static let weeksPerMonth = Decimal(string: "4.345")!
    
    /// `savingsPercentage = (1 - monthlyPrice / (weeklyPrice * 4.345)) * 100`, rounded to an integer.
    static func roundedSavingsPercentage(weeklyPrice: Decimal, monthlyPrice: Decimal) -> Int? {
        guard weeklyPrice > 0, monthlyPrice > 0 else { return nil }
        
        let weeklyMonthlyEquivalent = weeklyPrice * weeksPerMonth
        guard weeklyMonthlyEquivalent > 0 else { return nil }
        
        var savings = (Decimal(1) - (monthlyPrice / weeklyMonthlyEquivalent)) * Decimal(100)
        guard savings > 0 else { return nil }
        
        var rounded = Decimal()
        NSDecimalRound(&rounded, &savings, 0, .plain)
        let value = NSDecimalNumber(decimal: rounded).intValue
        guard value > 0 else { return nil }
        return value
    }
    
    /// `monthlyWeeklyPrice = monthlyPrice / 4.345`, 2 fraction digits, store currency.
    static func formattedMonthlyWeeklyPrice(
        monthlyPrice: Decimal,
        currencyCode: String?,
        locale: Locale
    ) -> String? {
        guard monthlyPrice > 0 else { return nil }
        
        var perWeek = monthlyPrice / weeksPerMonth
        var rounded = Decimal()
        NSDecimalRound(&rounded, &perWeek, 2, .plain)
        guard rounded > 0 else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        if let currencyCode {
            formatter.currencyCode = currencyCode
        }
        return formatter.string(from: rounded as NSDecimalNumber)
    }
    
    static func localeIdentifier(forStorefrontCountryCode code: String) -> String {
        switch code.uppercased() {
        case "DEU": return "de_DE"
        case "AUT": return "de_AT"
        case "CHE": return "de_CH"
        case "USA": return "en_US"
        case "GBR": return "en_GB"
        case "FRA": return "fr_FR"
        case "ESP": return "es_ES"
        case "ITA": return "it_IT"
        default:
            return Locale.identifier(fromComponents: [
                NSLocale.Key.countryCode.rawValue: code
            ])
        }
    }
}

/// Starts Superwall + RevenueCat in the official order and keeps user IDs in sync.
@MainActor
final class Monetization {
    static let shared = Monetization()
    
    /// Superwall Parameter variable (number). Editor: `{{ monthlySavingsPercentage }}` or `{{ params.monthlySavingsPercentage }}`.
    static let monthlySavingsPercentageKey = "monthlySavingsPercentage"
    /// Superwall Parameter variable (text). Editor: `{{ monthlyWeeklyPrice }}` or `{{ params.monthlyWeeklyPrice }}`.
    static let monthlyWeeklyPriceKey = "monthlyWeeklyPrice"
    
    private let purchaseController = RCPurchaseController()
    private var didStart = false
    
    private init() {}
    
    /// Call once from `CulinaChefApp.init()` before creating `AppState`.
    func start() {
        guard !didStart else { return }
        didStart = true
        
        if Config.isSuperwallConfigured {
            let options = SuperwallOptions()
            options.paywalls.shouldPreload = true
            #if DEBUG
            options.logging.level = .debug
            options.logging.scopes = [.all]
            #endif
            Superwall.configure(
                apiKey: Config.superwallAPIKey,
                purchaseController: purchaseController,
                options: options
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
        Task {
            let context = await preparePaywallContext()
            Superwall.shared.setUserAttributes(context.userAttributes)
            
            do {
                let paywall = try await Superwall.shared.getPaywall(
                    forPlacement: placement,
                    params: context.params,
                    paywallOverrides: context.overrides,
                    delegate: self
                )
            Logger.info(
                "[Superwall] Presenting paywall name=\(paywall.info.name) id=\(paywall.info.identifier) placement=\(placement)",
                category: .data
            )
                present(paywall)
            } catch let reason as PaywallSkippedReason {
                Logger.info("[Superwall] Paywall skipped: \(reason)", category: .data)
                feature?()
            } catch {
                Logger.error("[Superwall] getPaywall failed — falling back to register", error: error, category: .data)
                if let feature {
                    Superwall.shared.register(placement: placement, params: context.params, feature: feature)
                } else {
                    Superwall.shared.register(placement: placement, params: context.params)
                }
            }
        }
    }
    
    // MARK: - Presentation
    
    private func present(_ paywall: PaywallViewController) {
        #if canImport(UIKit)
        paywall.modalPresentationStyle = .fullScreen
        guard let host = topViewController() else {
            Logger.error("[Superwall] No view controller available to present paywall", category: .data)
            return
        }
        if host === paywall || host.presentedViewController === paywall { return }
        host.present(paywall, animated: true)
        #endif
    }
    
    #if canImport(UIKit)
    private func topViewController() -> UIViewController? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        let window = windows.first(where: \.isKeyWindow) ?? windows.first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
    #endif
    
    // MARK: - Paywall parameters
    
    private struct PaywallContext {
        var params: [String: Any]
        var userAttributes: [String: Any?]
        var overrides: PaywallOverrides?
    }
    
    private func preparePaywallContext() async -> PaywallContext {
        await waitUntilSuperwallConfigured()
        await applyStorefrontLocale()
        
        if RevenueCatManager.shared.offerings == nil {
            await RevenueCatManager.shared.loadOfferings()
        }
        
        let storeProducts = await loadLocalizedStoreProducts()
        var params: [String: Any] = [:]
        var attributes: [String: Any?] = [
            Self.monthlySavingsPercentageKey: nil,
            Self.monthlyWeeklyPriceKey: nil
        ]
        
        if let monthly = storeProducts.monthly {
            let weeklyEquivalent = PaywallPriceMath.formattedMonthlyWeeklyPrice(
                monthlyPrice: monthly.price,
                currencyCode: monthly.currencyCode,
                locale: monthly.locale
            )
            if let weeklyEquivalent {
                params[Self.monthlyWeeklyPriceKey] = weeklyEquivalent
                attributes[Self.monthlyWeeklyPriceKey] = weeklyEquivalent
            }
            params["monthlyPlanTrialPrice"] = monthly.localizedPrice
        }
        
        if let weekly = storeProducts.weekly {
            params["weeklyPlanTrialPrice"] = weekly.localizedPrice
        }
        
        if let weekly = storeProducts.weekly, let monthly = storeProducts.monthly,
           let percentage = PaywallPriceMath.roundedSavingsPercentage(
            weeklyPrice: weekly.price,
            monthlyPrice: monthly.price
           ) {
            // Superwall Parameter "number" expects a JSON number (NSNumber), not a Swift Int box.
            let number = NSNumber(value: percentage)
            params[Self.monthlySavingsPercentageKey] = number
            attributes[Self.monthlySavingsPercentageKey] = number
            Logger.info(
                "[Superwall] monthlySavingsPercentage=\(percentage) weekly=\(weekly.localizedPrice) monthly=\(monthly.localizedPrice) currency=\(monthly.currencyCode ?? "?")",
                category: .data
            )
        } else {
            Logger.warning(
                "[Superwall] monthlySavingsPercentage skipped — weekly=\(storeProducts.weekly != nil) monthly=\(storeProducts.monthly != nil)",
                category: .data
            )
        }
        
        var overrides: PaywallOverrides?
        if !storeProducts.bySuperwallName.isEmpty {
            overrides = PaywallOverrides(
                productsByName: storeProducts.bySuperwallName,
                presentationStyleOverride: .fullscreen
            )
        }
        
        return PaywallContext(params: params, userAttributes: attributes, overrides: overrides)
    }
    
    private func waitUntilSuperwallConfigured() async {
        let deadline = Date().addingTimeInterval(5)
        while Superwall.shared.configurationStatus == .pending, Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func applyStorefrontLocale() async {
        guard let storefront = await Storefront.current else { return }
        let identifier = PaywallPriceMath.localeIdentifier(forStorefrontCountryCode: storefront.countryCode)
        Superwall.shared.localeIdentifier = identifier
        Logger.info("[Superwall] Storefront \(storefront.countryCode) → locale \(identifier)", category: .data)
    }
    
    private struct LocalizedProduct {
        var price: Decimal
        var localizedPrice: String
        var currencyCode: String?
        var locale: Locale
        var superwallProduct: SuperwallKit.StoreProduct
    }
    
    private struct LoadedStoreProducts {
        var weekly: LocalizedProduct?
        var monthly: LocalizedProduct?
        var bySuperwallName: [String: SuperwallKit.StoreProduct]
    }
    
    /// StoreKit 2 first (App Store storefront), then RevenueCat. Superwall custom/dashboard USD is not used.
    private func loadLocalizedStoreProducts() async -> LoadedStoreProducts {
        let packages = allRevenueCatPackages()
        var identifiers = Set(packages.map(\.storeProduct.productIdentifier))
        identifiers.insert(AppleSubscriptionProductIDs.monthly)
        identifiers.insert(SuperwallProductNames.weeklyPlanTrial)
        identifiers.insert(SuperwallProductNames.monthlyPlanTrial)
        
        var sk2ById: [String: StoreKit.Product] = [:]
        if let products = try? await StoreKit.Product.products(for: identifiers) {
            for product in products {
                sk2ById[product.id] = product
            }
        }
        
        func localized(from product: StoreKit.Product) -> LocalizedProduct {
            LocalizedProduct(
                price: product.price,
                localizedPrice: product.displayPrice,
                currencyCode: product.priceFormatStyle.currencyCode,
                locale: product.priceFormatStyle.locale,
                superwallProduct: SuperwallKit.StoreProduct(sk2Product: product)
            )
        }
        
        func sk2Weekly() -> StoreKit.Product? {
            if let named = sk2ById[SuperwallProductNames.weeklyPlanTrial] { return named }
            return sk2ById.values.first { $0.subscription?.subscriptionPeriod.unit == .week }
        }
        
        func sk2Monthly() -> StoreKit.Product? {
            if let named = sk2ById[SuperwallProductNames.monthlyPlanTrial] { return named }
            if let apple = sk2ById[AppleSubscriptionProductIDs.monthly] { return apple }
            return sk2ById.values.first { $0.subscription?.subscriptionPeriod.unit == .month }
        }
        
        var weekly = sk2Weekly().map(localized(from:))
        var monthly = sk2Monthly().map(localized(from:))
        
        if weekly == nil || monthly == nil {
            for package in packages {
                let store = package.storeProduct
                guard let unit = store.subscriptionPeriod?.unit else { continue }
                let wrapped: SuperwallKit.StoreProduct
                if let sk2 = store.sk2Product {
                    wrapped = SuperwallKit.StoreProduct(sk2Product: sk2)
                } else {
                    continue
                }
                let localized = LocalizedProduct(
                    price: store.price,
                    localizedPrice: store.localizedPriceString,
                    currencyCode: store.currencyCode,
                    locale: store.priceFormatter?.locale ?? Locale.current,
                    superwallProduct: wrapped
                )
                if unit == .week, weekly == nil { weekly = localized }
                if unit == .month, monthly == nil { monthly = localized }
            }
        }
        
        var byName: [String: SuperwallKit.StoreProduct] = [:]
        if let weekly {
            byName[SuperwallProductNames.weeklyPlanTrial] = weekly.superwallProduct
        }
        if let monthly {
            byName[SuperwallProductNames.monthlyPlanTrial] = monthly.superwallProduct
        }
        
        Logger.info(
            "[Superwall] Store products loaded: \(sk2ById.keys.sorted().joined(separator: ", ")) weekly=\(weekly?.localizedPrice ?? "nil") monthly=\(monthly?.localizedPrice ?? "nil")",
            category: .data
        )
        
        return LoadedStoreProducts(weekly: weekly, monthly: monthly, bySuperwallName: byName)
    }
    
    private func allRevenueCatPackages() -> [Package] {
        RevenueCatManager.shared.availablePackages
    }
}

extension Monetization: PaywallViewControllerDelegate {
    func paywall(
        _ paywall: PaywallViewController,
        didFinishWith result: PaywallResult,
        shouldDismiss: Bool
    ) {
        if shouldDismiss {
            paywall.dismiss(animated: true)
        }
    }
    
    func paywall(
        _ paywall: PaywallViewController,
        loadingStateDidChange loadingState: PaywallLoadingState
    ) {}
}
