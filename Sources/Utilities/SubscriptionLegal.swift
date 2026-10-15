import Combine
import Foundation

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
            return "CulinaAi Premium, wöchentlich oder monatlich. Wenn Apple eine 3-tägige Testphase gewährt, danach automatisch \(weekly)/Woche oder \(monthly)/Monat (Storefront-Preis inkl. gesetzlicher Steuern, soweit von Apple ausgewiesen). Kündigung in den Apple-ID-Einstellungen, spätestens 24 Stunden vor Periodenende. Zahlung nur über Apple. Käufe können wiederhergestellt werden. KI-Kontingent: 100 Einheiten/Tag, 1.000/Kalendermonat, 10 Bilder/Tag, max. 3 Bilder/Anfrage. Social-Import: 2 Einheiten. KI-Essensplan: 1 Einheit plus 1 je Gericht. Standardmäßig höchstens 3 gleichzeitige KI-Anfragen pro Konto. Manuelle Rezepte und die Einkaufsliste bleiben nutzbar. AGB und Datenschutz gelten."
        }
        return "CulinaAi Premium, weekly or monthly. If Apple grants a 3-day trial, it then auto-renews at \(weekly)/week or \(monthly)/month (App Store price for your region, including applicable taxes as displayed by Apple). Cancel in Apple ID settings at least 24 hours before the period ends. Payment is charged to your Apple ID. Restore purchases is available. AI allowance: 100 units/day, 1,000 per calendar month, 10 images/day, max 3 images/request. Social import: 2 units. AI meal plan: 1 unit plus 1 per meal. Up to 3 simultaneous AI requests per account by default. Manual recipes and the shopping list stay available. Terms and Privacy Policy apply."
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
                "(1) Der Download der App ist kostenlos. KI-Chat, Rezeptgenerator, Bildanalyse, KI-Essensplanung und Social-Import erfordern das optionale Abonnement „CulinaAi Premium“ als Wochen- oder Monatsabo mit automatischer Verlängerung. Das Abo ist kein unbegrenztes KI-Kontingent.",
                "(2) Die Preise variieren nach Region und Währung. \(priceClauseDE) Ausgewiesene Beträge enthalten die gesetzliche Umsatzsteuer, soweit Apple sie anzeigt.",
                "(3) Neue berechtigte Apple-IDs erhalten eine einmalige kostenlose Testphase von \(trialDurationDays) Tagen (Introductory Offer), sofern Apple sie für das Konto gewährt. Danach verlängert sich das Abo automatisch zum dann gültigen Store-Preis, bis es gekündigt wird.",
                "(4) Vertrag über das Abonnement, Abrechnung, Verlängerung, Kündigung und Rückerstattung erfolgen ausschließlich über Apple In-App Purchase. CulinaAI erhält und speichert keine Zahlungsdaten.",
                "(5) Die Kündigung muss in den Abonnementeinstellungen der Apple-ID erfolgen, mindestens 24 Stunden vor Ablauf der aktuellen Periode. Andernfalls verlängert Apple um dieselbe Laufzeit (Woche bzw. Monat) und belastet das Apple-Konto.",
                "(6) Bereits erworbene Abos können über „Käufe wiederherstellen“ derselben Apple-ID zugeordnet werden.",
                "(7) Preisänderungen gelten erst für die nächste Periode und nur nach Mitteilung durch Apple. Es gibt keine anteilige Erstattung bereits begonnener Perioden, soweit kein gesetzliches Widerrufs- oder Apple-Refund-Recht greift.",
                "(8) Premium umfasst 100 KI-Einheiten pro Tag und 1.000 pro Kalendermonat, 10 analysierte Bilder pro Tag und höchstens 3 Bilder pro Anfrage. Ein Social-Import verbraucht 2 Einheiten. Eine KI-Essensplanung verbraucht 1 Einheit plus 1 Einheit je erzeugtem Gericht. Standardmäßig sind höchstens 3 KI-Anfragen desselben Kontos gleichzeitig in Bearbeitung (insgesamt standardmäßig 20 in der gesamten App). Ist ein Kontingent aufgebraucht oder eine vorübergehende Auslastungssperre aktiv, sind weitere KI-Anfragen bis zum Reset bzw. bis Kapazität frei ist nicht möglich. Manuelles Anlegen und Bearbeiten von Rezepten, die Einkaufsliste und die Rezeptverwaltung bleiben ohne KI-Kontingent nutzbar. Automatisierter Missbrauch kann zusätzlich beschränkt werden. Ob und wann ein gesetzliches Widerrufsrecht besteht, prüft die rechtliche Freigabe; Apple-Erstattungen folgen Apples Verfahren.",
            ]
        }
        return [
            "(1) Downloading the app is free. AI chat, recipe generation, image analysis, AI meal planning, and social import require the optional “CulinaAi Premium” auto-renewing weekly or monthly subscription. Premium is not an unlimited AI allowance.",
            "(2) Prices vary by region and currency. \(priceClauseEN) Displayed amounts include applicable VAT/sales tax where Apple shows it.",
            "(3) Eligible new Apple IDs receive a one-time \(trialDurationDays)-day free trial (introductory offer) when Apple grants it for that account. Afterwards the subscription auto-renews at the then-current store price until cancelled.",
            "(4) The subscription contract, billing, renewal, cancellation and refunds are handled solely through Apple In-App Purchase. CulinaAI does not receive or store payment details.",
            "(5) Cancel in Apple ID subscription settings at least 24 hours before the current period ends. Otherwise Apple renews for the same term (week or month) and charges the Apple ID.",
            "(6) Previous purchases can be restored with “Restore purchases” on the same Apple ID.",
            "(7) Price changes apply only to the next period after Apple notifies you. There is no pro-rata refund for a started period unless a statutory withdrawal right or Apple’s refund policy applies.",
            "(8) Premium includes 100 AI units per day and 1,000 per calendar month, 10 analyzed images per day, and at most 3 images per request. A social import uses 2 units. An AI meal plan uses 1 unit plus 1 unit per generated meal. By default at most 3 AI requests for the same account run at once (20 across the service by default). When a quota is used up, or a temporary capacity limit applies, further AI requests wait until reset or free capacity. Creating and editing recipes manually, the shopping list, and recipe management stay available without AI quota. Automated abuse can be restricted separately. Whether a statutory withdrawal right applies is subject to legal review; Apple refunds follow Apple’s process.",
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
            return "CulinaAi Premium, 3 Tage Test nur wenn Apple sie gewährt, danach \(store) (Apple In-App-Purchase)"
        }
        return "CulinaAi Premium, 3-day trial only when Apple grants it, then \(store) (Apple In-App Purchase)"
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
