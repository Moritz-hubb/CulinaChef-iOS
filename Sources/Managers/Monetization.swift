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
    /// Weeks per average month. `Decimal(string:)` is non-optional for this literal.
    static let weeksPerMonth = Decimal(string: "4.345")! // swiftlint:disable:this force_unwrapping
    
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
    ///
    /// Placement params must go through `register` so Superwall Parameter variables
    /// (`{{ monthlySavingsPercentage }}`) receive a value. `getPaywall` does not reliably
    /// bind Parameter state in SuperwallKit 4.x.
    func register(placement: String, feature: (() -> Void)? = nil) {
        guard Config.isSuperwallConfigured else {
            feature?()
            return
        }
        Task {
            let context = await preparePaywallContext()
            Superwall.shared.setUserAttributes(context.userAttributes)
            if !context.productIdsBySuperwallName.isEmpty {
                Superwall.shared.overrideProductsByName = context.productIdsBySuperwallName
            }
            
            Logger.info(
                "[PaywallDebug] register placement=\(placement) params=\(Self.debugDescribe(context.params)) userAttributes[savings]=\(String(describing: Superwall.shared.userAttributes[Self.monthlySavingsPercentageKey])) overrides=\(context.productIdsBySuperwallName)",
                category: .data
            )
            
            let handler = PaywallPresentationHandler()
            handler.onPresent { info in
                Logger.info(
                    "[PaywallDebug] presented name=\(info.name) id=\(info.identifier) products=\(info.productIds) savingsParamStill=\(String(describing: Superwall.shared.userAttributes[Self.monthlySavingsPercentageKey]))",
                    category: .data
                )
            }
            handler.onSkip { reason in
                Logger.info("[PaywallDebug] skipped: \(reason)", category: .data)
            }
            handler.onError { error in
                Logger.error("[PaywallDebug] presentation error", error: error, category: .data)
            }
            
            if let feature {
                Superwall.shared.register(placement: placement, params: context.params, handler: handler, feature: feature)
            } else {
                Superwall.shared.register(placement: placement, params: context.params, handler: handler)
            }
        }
    }
    
    // MARK: - Paywall parameters
    
    private struct PaywallContext {
        var params: [String: Any]
        var userAttributes: [String: Any?]
        var productIdsBySuperwallName: [String: String]
    }
    
    private func preparePaywallContext() async -> PaywallContext {
        await waitUntilSuperwallConfigured()
        await applyStorefrontLocale()
        await waitUntilOfferingsLoaded()
        
        let storeProducts = await loadLocalizedStoreProducts()
        var params: [String: Any] = [:]
        var attributes: [String: Any?] = [:]
        
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
        
        if let weekly = storeProducts.weekly, let monthly = storeProducts.monthly {
            if let percentage = PaywallPriceMath.roundedSavingsPercentage(
                weeklyPrice: weekly.price,
                monthlyPrice: monthly.price
            ) {
                // Superwall Parameter variables bind from placement params.
                // Pass a JSON number (editor type: number) and the same digits as text
                // so `{{ monthlySavingsPercentage }}` and `{{ params.monthlySavingsPercentage }}` both fill.
                let number = NSNumber(value: percentage)
                let text = String(percentage)
                params[Self.monthlySavingsPercentageKey] = number
                attributes[Self.monthlySavingsPercentageKey] = number
                attributes["\(Self.monthlySavingsPercentageKey)Text"] = text
                Logger.info(
                    "[PaywallDebug] savings=\(percentage)% weeklyPrice=\(weekly.price) (\(weekly.localizedPrice)) monthlyPrice=\(monthly.price) (\(monthly.localizedPrice)) currency=\(monthly.currencyCode ?? "?")",
                    category: .data
                )
            } else {
                Logger.warning(
                    "[PaywallDebug] savings math returned nil weeklyPrice=\(weekly.price) monthlyPrice=\(monthly.price)",
                    category: .data
                )
            }
        } else {
            Logger.warning(
                "[PaywallDebug] savings skipped — weekly=\(storeProducts.weekly?.localizedPrice ?? "nil") monthly=\(storeProducts.monthly?.localizedPrice ?? "nil")",
                category: .data
            )
        }
        
        return PaywallContext(
            params: params,
            userAttributes: attributes,
            productIdsBySuperwallName: storeProducts.appleIdsBySuperwallName
        )
    }
    
    private static func debugDescribe(_ params: [String: Any]) -> String {
        params
            .keys
            .sorted()
            .map { key in
                "\(key)=\(String(describing: params[key] ?? "nil"))"
            }
            .joined(separator: ", ")
    }
    
    private func waitUntilSuperwallConfigured() async {
        let deadline = Date().addingTimeInterval(5)
        while Superwall.shared.configurationStatus == .pending, Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        Logger.info(
            "[PaywallDebug] Superwall configurationStatus=\(String(describing: Superwall.shared.configurationStatus))",
            category: .data
        )
    }
    
    private func waitUntilOfferingsLoaded() async {
        if RevenueCatManager.shared.availablePackages.isEmpty, RevenueCatManager.shared.error == nil {
            await RevenueCatManager.shared.loadOfferings()
        }
        let offering = RevenueCatManager.shared.paywallOffering
        if RevenueCatManager.shared.availablePackages.isEmpty {
            Logger.warning(
                "[PaywallDebug] RevenueCat offerings have no products. Savings will use StoreKit IDs only. Fix: RevenueCat → Offering \(RevenueCatManager.trialPlansOfferingID) → add weekly + monthly packages. Simulator also needs Scheme → Run → Options → StoreKit Configuration = Configs/StoreKit.storekit and an App Store account (or the .storekit file).",
                category: .data
            )
        }
        Logger.info(
            "[PaywallDebug] RC offering=\(offering?.identifier ?? "nil") packages=\(RevenueCatManager.shared.availablePackages.count)",
            category: .data
        )
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
        var appleProductId: String
    }
    
    private struct LoadedStoreProducts {
        var weekly: LocalizedProduct?
        var monthly: LocalizedProduct?
        var appleIdsBySuperwallName: [String: String]
    }
    
    /// Prefer RevenueCat packages from `TrialPlansCulinaAi`, then StoreKit 2 for the same Apple IDs.
    private func loadLocalizedStoreProducts() async -> LoadedStoreProducts {
        let packages = allRevenueCatPackages()
        for package in packages {
            let period = package.storeProduct.subscriptionPeriod.map { period in
                "\(period.value)-\(String(describing: period.unit))"
            } ?? "none"
            Logger.info(
                "[PaywallDebug] RC package id=\(package.identifier) type=\(String(describing: package.packageType)) product=\(package.storeProduct.productIdentifier) period=\(period) price=\(package.storeProduct.localizedPriceString) currency=\(package.storeProduct.currencyCode ?? "?")",
                category: .data
            )
        }
        
        var identifiers = Set(packages.map(\.storeProduct.productIdentifier))
        identifiers.insert(AppleSubscriptionProductIDs.monthly)
        identifiers.insert(SuperwallProductNames.weeklyPlanTrial)
        identifiers.insert(SuperwallProductNames.monthlyPlanTrial)
        
        let rcProductsById: [String: RevenueCat.StoreProduct]
        if packages.isEmpty {
            let fetched = await RevenueCatManager.shared.storeProducts(for: Array(identifiers))
            rcProductsById = Dictionary(uniqueKeysWithValues: fetched.map { ($0.productIdentifier, $0) })
            for product in fetched {
                Logger.info(
                    "[PaywallDebug] RC product-by-id \(product.productIdentifier) price=\(product.localizedPriceString) period=\(String(describing: product.subscriptionPeriod?.unit))",
                    category: .data
                )
            }
        } else {
            rcProductsById = [:]
        }
        
        if await Storefront.current == nil {
            Logger.warning(
                "[PaywallDebug] Storefront.current is nil (ASDError 509 / no App Store account). Simulator: enable StoreKit Configuration on the CulinaChef scheme. Device: sign in with a sandbox Apple ID.",
                category: .data
            )
        }
        
        var sk2ById: [String: StoreKit.Product] = [:]
        do {
            let products = try await StoreKit.Product.products(for: identifiers)
            for product in products {
                sk2ById[product.id] = product
            }
            Logger.info(
                "[PaywallDebug] SK2 requested=\(identifiers.sorted()) loaded=\(sk2ById.keys.sorted())",
                category: .data
            )
            if sk2ById.isEmpty {
                Logger.warning(
                    "[PaywallDebug] StoreKit returned 0 products. Superwall cannot purchase until App Store Connect IDs match and StoreKit Configuration is selected in the Run scheme (simulator) or a sandbox account is signed in (device).",
                    category: .data
                )
            }
        } catch {
            Logger.error("[PaywallDebug] SK2 Product.products failed", error: error, category: .data)
        }
        
        func fromSK2(_ product: StoreKit.Product) -> LocalizedProduct {
            LocalizedProduct(
                price: product.price,
                localizedPrice: product.displayPrice,
                currencyCode: product.priceFormatStyle.currencyCode,
                locale: product.priceFormatStyle.locale,
                appleProductId: product.id
            )
        }
        
        func fromRC(_ package: Package) -> LocalizedProduct? {
            let store = package.storeProduct
            guard store.price > 0 else { return nil }
            return LocalizedProduct(
                price: store.price,
                localizedPrice: store.localizedPriceString,
                currencyCode: store.currencyCode,
                locale: store.priceFormatter?.locale ?? Locale.current,
                appleProductId: store.productIdentifier
            )
        }
        
        func looksWeekly(_ package: Package) -> Bool {
            if package.packageType == .weekly { return true }
            if package.storeProduct.subscriptionPeriod?.unit == .week { return true }
            let token = "\(package.identifier) \(package.storeProduct.productIdentifier)".lowercased()
            return token.contains("week")
        }
        
        func looksMonthly(_ package: Package) -> Bool {
            if package.packageType == .monthly { return true }
            if package.storeProduct.subscriptionPeriod?.unit == .month { return true }
            let token = "\(package.identifier) \(package.storeProduct.productIdentifier)".lowercased()
            return token.contains("month") && !token.contains("week")
        }
        
        var weekly = packages.first(where: looksWeekly).flatMap(fromRC)
        var monthly = packages.first(where: looksMonthly).flatMap(fromRC)
        
        func fromRCProduct(_ store: RevenueCat.StoreProduct) -> LocalizedProduct? {
            guard store.price > 0 else { return nil }
            return LocalizedProduct(
                price: store.price,
                localizedPrice: store.localizedPriceString,
                currencyCode: store.currencyCode,
                locale: store.priceFormatter?.locale ?? Locale.current,
                appleProductId: store.productIdentifier
            )
        }
        
        for store in rcProductsById.values {
            if store.subscriptionPeriod?.unit == .week || store.productIdentifier.lowercased().contains("week") {
                if weekly == nil { weekly = fromRCProduct(store) }
            }
            if store.subscriptionPeriod?.unit == .month || store.productIdentifier.lowercased().contains("month") {
                if monthly == nil { monthly = fromRCProduct(store) }
            }
            if store.productIdentifier == AppleSubscriptionProductIDs.monthly, monthly == nil {
                monthly = fromRCProduct(store)
            }
        }
        
        if let sk2Week = sk2ById.values.first(where: { $0.subscription?.subscriptionPeriod.unit == .week }) {
            weekly = fromSK2(sk2Week)
        }
        if let namedWeek = sk2ById[SuperwallProductNames.weeklyPlanTrial] {
            weekly = fromSK2(namedWeek)
        }
        
        if let sk2Month = sk2ById.values.first(where: { $0.subscription?.subscriptionPeriod.unit == .month }) {
            monthly = fromSK2(sk2Month)
        }
        if let appleMonth = sk2ById[AppleSubscriptionProductIDs.monthly] {
            monthly = fromSK2(appleMonth)
        }
        if let namedMonth = sk2ById[SuperwallProductNames.monthlyPlanTrial] {
            monthly = fromSK2(namedMonth)
        }
        
        var ids: [String: String] = [:]
        if let weekly {
            ids[SuperwallProductNames.weeklyPlanTrial] = weekly.appleProductId
        }
        if let monthly {
            ids[SuperwallProductNames.monthlyPlanTrial] = monthly.appleProductId
        }
        
        Logger.info(
            "[PaywallDebug] resolved weekly=\(weekly?.localizedPrice ?? "nil") (\(weekly?.appleProductId ?? "no-id")) monthly=\(monthly?.localizedPrice ?? "nil") (\(monthly?.appleProductId ?? "no-id"))",
            category: .data
        )
        
        return LoadedStoreProducts(weekly: weekly, monthly: monthly, appleIdsBySuperwallName: ids)
    }
    
    private func allRevenueCatPackages() -> [Package] {
        RevenueCatManager.shared.availablePackages
    }
}
