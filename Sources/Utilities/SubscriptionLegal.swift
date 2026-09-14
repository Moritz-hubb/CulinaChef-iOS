import Foundation
import RevenueCat
import StoreKit
import SuperwallKit

extension Notification.Name {
    static let culinaPresentLegalTerms = Notification.Name("culinaPresentLegalTerms")
    static let culinaPresentLegalPrivacy = Notification.Name("culinaPresentLegalPrivacy")
}

/// Apple Guideline 3.1.2 + regional App Store pricing. Trial length matches StoreKit `P3D`.
enum SubscriptionLegal {
    static let trialDurationDays = 3
    static let termsURL = URL(string: "https://culinaai.com/terms")!
    static let privacyURL = URL(string: "https://culinaai.com/privacy")!

    struct Prices {
        var weekly: String?
        var monthly: String?
    }

    static func isGerman(_ language: String) -> Bool {
        language.lowercased().hasPrefix("de")
    }

    static func paywallFooter(language: String, prices: Prices) -> String {
        let weekly = prices.weekly ?? (isGerman(language) ? "dem im App Store angezeigten Wochenpreis" : "the weekly price shown in the App Store")
        let monthly = prices.monthly ?? (isGerman(language) ? "dem im App Store angezeigten Monatspreis" : "the monthly price shown in the App Store")
        if isGerman(language) {
            return "3 Tage kostenlos, danach automatisch \(weekly)/Woche oder \(monthly)/Monat (Storefront-Preis inkl. gesetzlicher Steuern, soweit von Apple ausgewiesen). Jederzeit in den Apple-ID-Einstellungen kündbar, spätestens 24 Stunden vor Periodenende. Zahlung nur über Apple. AGB und Datenschutzerklärung gelten. Käufe können wiederhergestellt werden."
        }
        return "3-day free trial, then auto-renews at \(weekly)/week or \(monthly)/month (App Store price for your region, including applicable taxes as displayed by Apple). Cancel anytime in Apple ID settings, at least 24 hours before the period ends. Payment is charged to your Apple ID. Terms and Privacy Policy apply. Restore purchases is available."
    }

    static func termsParagraphs(language: String, prices: Prices) -> [String] {
        let weekly = prices.weekly
        let monthly = prices.monthly
        let priceClauseDE: String = {
            switch (weekly, monthly) {
            case let (w?, m?):
                return "Aktuell zeigt der App Store für diese Storefront \(w) pro Woche und \(m) pro Monat. Maßgeblich ist stets der im Kaufbildschirm von StoreKit/Apple angezeigte Preis."
            case (let w?, nil):
                return "Aktuell zeigt der App Store für diese Storefront \(w) pro Woche. Maßgeblich ist stets der im Kaufbildschirm angezeigte Preis."
            case (nil, let m?):
                return "Aktuell zeigt der App Store für diese Storefront \(m) pro Monat. Maßgeblich ist stets der im Kaufbildschirm angezeigte Preis."
            default:
                return "Die konkreten Beträge legt Apple je Land und Währung fest und zeigt sie im Kaufdialog an."
            }
        }()
        let priceClauseEN: String = {
            switch (weekly, monthly) {
            case let (w?, m?):
                return "The App Store currently shows \(w) per week and \(m) per month for this storefront. The price displayed on the purchase screen at checkout is controlling."
            case (let w?, nil):
                return "The App Store currently shows \(w) per week for this storefront. The price displayed on the purchase screen is controlling."
            case (nil, let m?):
                return "The App Store currently shows \(m) per month for this storefront. The price displayed on the purchase screen is controlling."
            default:
                return "Apple sets the amounts per country and currency and displays them in the purchase sheet."
            }
        }()

        if isGerman(language) {
            return [
                "(1) Der Download der App ist kostenlos. Die KI-Funktionen (Chat, Rezeptgenerator, Analyse, Social-Import) erfordern das optionale Abonnement „CulinaAi Unlimited“ als Wochen- oder Monatsabo mit automatischer Verlängerung.",
                "(2) Die Preise variieren nach Region und Währung. \(priceClauseDE) Ausgewiesene Beträge enthalten die gesetzliche Umsatzsteuer, soweit Apple sie anzeigt.",
                "(3) Neue berechtigte Apple-IDs erhalten eine einmalige kostenlose Testphase von \(trialDurationDays) Tagen (Introductory Offer), sofern Apple sie für das Konto gewährt. Danach verlängert sich das Abo automatisch zum dann gültigen Store-Preis, bis es gekündigt wird.",
                "(4) Vertrag über das Abonnement, Abrechnung, Verlängerung, Kündigung und Rückerstattung erfolgen ausschließlich über Apple In-App Purchase. CulinaAI erhält und speichert keine Zahlungsdaten.",
                "(5) Die Kündigung muss in den Abonnementeinstellungen der Apple-ID erfolgen, mindestens 24 Stunden vor Ablauf der aktuellen Periode. Andernfalls verlängert Apple um dieselbe Laufzeit (Woche bzw. Monat) und belastet das Apple-Konto.",
                "(6) Bereits erworbene Abos können über „Käufe wiederherstellen“ derselben Apple-ID zugeordnet werden.",
                "(7) Preisänderungen gelten erst für die nächste Periode und nur nach Mitteilung durch Apple. Es gibt keine anteilige Erstattung bereits begonnener Perioden, soweit kein gesetzliches Widerrufs- oder Apple-Refund-Recht greift.",
            ]
        }
        return [
            "(1) Downloading the app is free. AI features (chat, recipe generator, analysis, social import) require the optional “CulinaAi Unlimited” auto-renewing weekly or monthly subscription.",
            "(2) Prices vary by region and currency. \(priceClauseEN) Displayed amounts include applicable VAT/sales tax where Apple shows it.",
            "(3) Eligible new Apple IDs receive a one-time \(trialDurationDays)-day free trial (introductory offer) when Apple grants it for that account. Afterwards the subscription auto-renews at the then-current store price until cancelled.",
            "(4) The subscription contract, billing, renewal, cancellation and refunds are handled solely through Apple In-App Purchase. CulinaAI does not receive or store payment details.",
            "(5) Cancel in Apple ID subscription settings at least 24 hours before the current period ends. Otherwise Apple renews for the same term (week or month) and charges the Apple ID.",
            "(6) Previous purchases can be restored with “Restore purchases” on the same Apple ID.",
            "(7) Price changes apply only to the next period after Apple notifies you. There is no pro-rata refund for a started period unless a statutory withdrawal right or Apple’s refund policy applies.",
        ]
    }

    static func summaryPriceLine(language: String, prices: Prices) -> String {
        let bits = [prices.weekly.map { isGerman(language) ? "\($0)/Woche" : "\($0)/week" },
                    prices.monthly.map { isGerman(language) ? "\($0)/Monat" : "\($0)/month" }]
            .compactMap { $0 }
        let store = bits.isEmpty
            ? (isGerman(language) ? "App-Store-Preis der Storefront" : "App Store price for your region")
            : bits.joined(separator: isGerman(language) ? " oder " : " or ")
        if isGerman(language) {
            return "3 Tage Test, danach \(store) (Apple In-App-Purchase)"
        }
        return "3-day trial, then \(store) (Apple In-App Purchase)"
    }

    static func presentsInAppLegal(from url: URL) -> LegalDestination? {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        let absolute = url.absoluteString.lowercased()
        if host.contains("culinaai.com") || url.scheme == "culinachef" {
            if path.contains("privacy") || absolute.contains("privacy") { return .privacy }
            if path.contains("terms") || path.contains("agb") || absolute.contains("terms") { return .terms }
        }
        return nil
    }

    enum LegalDestination {
        case terms
        case privacy
    }

    static func postOpenLegal(_ destination: LegalDestination) {
        switch destination {
        case .terms:
            NotificationCenter.default.post(name: .culinaPresentLegalTerms, object: nil)
        case .privacy:
            NotificationCenter.default.post(name: .culinaPresentLegalPrivacy, object: nil)
        }
    }
}

@MainActor
final class SubscriptionStorePricing: ObservableObject {
    static let shared = SubscriptionStorePricing()

    @Published private(set) var prices = SubscriptionLegal.Prices()

    func refresh() async {
        prices = await Monetization.shared.currentLocalizedSubscriptionPrices()
    }
}
