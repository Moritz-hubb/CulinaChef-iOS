import SwiftUI

struct PrivacyPolicyView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) var dismiss
    
    private var isGerman: Bool {
        localizationManager.currentLanguage == "de"
    }
    
    private var isFrench: Bool {
        localizationManager.currentLanguage == "fr"
    }
    
    private func localized(_ german: String, _ french: String, _ english: String) -> String {
        if isGerman { return german }
        if isFrench { return french }
        return english
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L.legalPrivacyTitle.localized)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text(localized(
                                "für die App \"CulinaChef (CulinaAI)\"",
                                "pour l'application \"CulinaChef (CulinaAI)\"",
                                "for the app \"CulinaChef (CulinaAI)\""
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            
                            HStack(spacing: 16) {
                                Label(localized("Stand: 04.11.2025", "Date: 04.11.2025", "Date: November 4, 2025"), systemImage: "calendar")
                                Label(localized("Version: 1.0", "Version: 1.0", "Version: 1.0"), systemImage: "doc.text")
                            }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.bottom, 8)
                        
                        Divider().background(.white.opacity(0.3))
                        
                        // Language Notice
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                            Text(L.legalLanguageNotice.localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.25))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.4), lineWidth: 1.5)
                        )
                        
                        PrivacySection(localized("1. Verantwortlicher", "1. Responsable", "1. Data Controller"), icon: "person.badge.shield.checkmark") {
                            VStack(alignment: .leading, spacing: 4) {
                                ContactInfo(label: localized("Unternehmen", "Entreprise", "Company"), value: "CulinaAI")
                                ContactInfo(label: localized("Vertreten durch", "Représentée par", "Represented by"), value: "Moritz Serrin")
                                ContactInfo(label: localized("Adresse", "Adresse", "Address"), value: "Sonnenblumenweg 8, 21244 Buchholz, " + localized("Deutschland", "Allemagne", "Germany"))
                                ContactInfo(label: "E-Mail", value: "kontakt@culinaai.com")
                                ContactInfo(label: localized("Datenschutz", "Protection des données", "Data Protection"), value: "support@culinaai.com")
                            }
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        PrivacySection(localized("2. Allgemeines", "2. Généralités", "2. General Information"), icon: "info.circle") {
                            Text(localized(
                                "Der Schutz Ihrer personenbezogenen Daten ist uns wichtig. Wir verarbeiten personenbezogene Daten im Einklang mit der DSGVO, dem BDSG und anderen anwendbaren Bestimmungen.",
                                "La protection de vos données personnelles est importante. Nous traitons les données conformément au RGPD, au BDSG et autres réglementations applicables.",
                                "The protection of your personal data is important to us. We process personal data in accordance with the GDPR, BDSG, and other applicable regulations."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                            .padding(.bottom, 8)
                            
                            Text(localized("Grundsätze der Datenverarbeitung:", "Principes de traitement:", "Data Processing Principles:"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.top, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                PrivacyBullet(
                                    title: localized("Minimierung:", "Minimisation:", "Minimization:"),
                                    text: localized("Wir erheben nur die Daten, die für die Funktionalität der App notwendig sind.", "Nous collectons uniquement les données nécessaires au fonctionnement de l'application.", "We only collect data necessary for the app's functionality.")
                                )
                                PrivacyBullet(
                                    title: localized("Transparenz:", "Transparence:", "Transparency:"),
                                    text: localized("Klare Kommunikation über die Verwendung Ihrer Daten.", "Communication claire sur l'utilisation de vos données.", "Clear communication about how your data is used.")
                                )
                                PrivacyBullet(
                                    title: localized("Sicherheit:", "Sécurité:", "Security:"),
                                    text: localized("TLS-Verschlüsselung und sichere Speicherung.", "Chiffrement TLS et stockage sécurisé.", "TLS encryption and secure storage.")
                                )
                                PrivacyBullet(
                                    title: localized("Keine Werbung:", "Pas de publicité:", "No Advertising:"),
                                    text: localized("Wir zeigen keine Werbung und verwenden kein Tracking.", "Nous n'affichons pas de publicité et n'utilisons pas de suivi.", "We do not show ads or use tracking.")
                                )
                            }
                        }
                        
                        PrivacySection(localized("3. Erhobene Daten", "3. Données collectées", "3. Data Collected"), icon: "tray.full") {
                            Text(localized(
                                "Wir erheben und verarbeiten folgende Kategorien von Daten:",
                                "Nous collectons et traitons les catégories de données suivantes :",
                                "We collect and process the following categories of data:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                DataCategory(
                                    title: localized("Kontodaten", "Données de compte", "Account Data"),
                                    description: localized("Benutzername, E-Mail-Adresse (über 'Sign in with Apple'), Passwort-Hash", "Nom d'utilisateur, adresse e-mail (via 'Sign in with Apple'), hash du mot de passe", "Username, email address (via 'Sign in with Apple'), password hash")
                                )
                                DataCategory(
                                    title: localized("Rezeptdaten", "Données de recettes", "Recipe Data"),
                                    description: localized("Von Ihnen erstellte oder gespeicherte Rezepte, Zutaten, Anweisungen", "Recettes créées ou enregistrées, ingrédients, instructions", "Recipes you create or save, ingredients, instructions")
                                )
                                DataCategory(
                                    title: localized("Präferenzen", "Préférences", "Preferences"),
                                    description: localized("Allergien, Unverträglichkeiten, Ernährungspräferenzen, Menüpläne", "Allergies, intolérances, préférences alimentaires, plans de menus", "Allergies, intolerances, dietary preferences, menu plans")
                                )
                                DataCategory(
                                    title: localized("Nutzungsdaten", "Données d'utilisation", "Usage Data"),
                                    description: localized("App-Version, Gerätetyp, Betriebssystem-Version (anonymisiert)", "Version de l'app, type d'appareil, version du système d'exploitation (anonymisé)", "App version, device type, operating system version (anonymized)")
                                )
                            }
                        }
                        
                        PrivacySection(localized("4. Datenübermittlung in Drittländer", "4. Transfert vers des pays tiers", "4. Data Transfer to Third Countries"), icon: "globe") {
                            Text(localized(
                                "Ihre Daten werden in der EU/EWR gespeichert. Für die KI-Funktionen nutzen wir OpenAI (USA), wobei die übermittelten Daten (Rezeptanfragen) gemäß OpenAI's Datenschutzrichtlinie verarbeitet werden. OpenAI hat sich verpflichtet, die EU-Standards einzuhalten.",
                                "Vos données sont stockées dans l'UE/EEE. Pour les fonctions IA, nous utilisons OpenAI (États-Unis), les données transmises étant traitées selon la politique de confidentialité d'OpenAI. OpenAI s'est engagé à respecter les normes de l'UE.",
                                "Your data is stored in the EU/EEA. For AI functions, we use OpenAI (USA), with transmitted data (recipe requests) processed according to OpenAI's privacy policy. OpenAI has committed to comply with EU standards."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                        }
                        
                        PrivacySection(localized("5. Technische und organisatorische Maßnahmen", "5. Mesures techniques et organisationnelles", "5. Technical and Organizational Measures"), icon: "lock.shield") {
                            VStack(alignment: .leading, spacing: 8) {
                                PrivacyBullet(
                                    title: localized("Verschlüsselung:", "Chiffrement:", "Encryption:"),
                                    text: localized("TLS-Verschlüsselung für alle Datenübertragungen", "Chiffrement TLS pour toutes les transmissions", "TLS encryption for all data transmissions")
                                )
                                PrivacyBullet(
                                    title: localized("Sichere Speicherung:", "Stockage sécurisé:", "Secure Storage:"),
                                    text: localized("Daten werden auf sicheren Servern gespeichert", "Données stockées sur des serveurs sécurisés", "Data stored on secure servers")
                                )
                                PrivacyBullet(
                                    title: localized("Zugriffskontrolle:", "Contrôle d'accès:", "Access Control:"),
                                    text: localized("Nur autorisierte Personen haben Zugriff", "Seules les personnes autorisées ont accès", "Only authorized personnel have access")
                                )
                            }
                        }
                        
                        PrivacySection(localized("6. Ihre Rechte nach DSGVO", "6. Vos droits selon le RGPD", "6. Your Rights under GDPR"), icon: "checkmark.shield") {
                            VStack(alignment: .leading, spacing: 12) {
                                RightRow(
                                    title: localized("Auskunftsrecht (Art. 15 DSGVO)", "Droit d'accès (art. 15 RGPD)", "Right of Access (Art. 15 GDPR)"),
                                    description: localized("Sie können Auskunft über Ihre gespeicherten Daten verlangen.", "Vous pouvez demander des informations sur vos données stockées.", "You can request information about your stored data.")
                                )
                                RightRow(
                                    title: localized("Berichtigungsrecht (Art. 16 DSGVO)", "Droit de rectification (art. 16 RGPD)", "Right to Rectification (Art. 16 GDPR)"),
                                    description: localized("Sie können die Korrektur falscher Daten verlangen.", "Vous pouvez demander la correction de données incorrectes.", "You can request correction of incorrect data.")
                                )
                                RightRow(
                                    title: localized("Löschungsrecht (Art. 17 DSGVO)", "Droit à l'effacement (art. 17 RGPD)", "Right to Erasure (Art. 17 GDPR)"),
                                    description: localized("Sie können die Löschung Ihrer Daten verlangen.", "Vous pouvez demander la suppression de vos données.", "You can request deletion of your data.")
                                )
                                RightRow(
                                    title: localized("Widerspruchsrecht (Art. 21 DSGVO)", "Droit d'opposition (art. 21 RGPD)", "Right to Object (Art. 21 GDPR)"),
                                    description: localized("Sie können der Verarbeitung Ihrer Daten widersprechen.", "Vous pouvez vous opposer au traitement de vos données.", "You can object to the processing of your data.")
                                )
                            }
                            
                            ImportantNote(text: localized(
                                "Um Ihre Rechte auszuüben, kontaktieren Sie uns bitte unter: kontakt@culinaai.com",
                                "Pour exercer vos droits, contactez-nous à : kontakt@culinaai.com",
                                "To exercise your rights, please contact us at: kontakt@culinaai.com"
                            ))
                        }
                        
                        PrivacySection(localized("7. Speicherdauer", "7. Durée de conservation", "7. Storage Duration"), icon: "clock") {
                            Text(localized(
                                "Wir speichern Ihre Daten nur so lange, wie es für die Erfüllung der Vertragszwecke erforderlich ist oder gesetzliche Aufbewahrungspflichten bestehen. Nach Löschung Ihres Kontos werden alle Daten innerhalb von 30 Tagen gelöscht, sofern keine gesetzlichen Aufbewahrungspflichten entgegenstehen.",
                                "Nous conservons vos données uniquement aussi longtemps que nécessaire pour les fins contractuelles ou les obligations légales. Après suppression de votre compte, toutes les données sont supprimées dans les 30 jours, sauf obligations légales de conservation.",
                                "We store your data only as long as necessary for contract fulfillment or legal retention obligations. After account deletion, all data will be deleted within 30 days, unless legal retention obligations apply."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                        }
                        
                        PrivacySection(localized("8. Minderjährigenschutz", "8. Protection des mineurs", "8. Protection of Minors"), icon: "person.2") {
                            Text(localized(
                                "Die App ist nur für Personen ab 16 Jahren bestimmt (§ 8 DSGVO). Personen unter 16 Jahren dürfen die App nicht nutzen. Wir erheben keine Daten von Minderjährigen.",
                                "L'application est destinée uniquement aux personnes de 16 ans et plus (§ 8 RGPD). Les personnes de moins de 16 ans ne peuvent pas utiliser l'application. Nous ne collectons pas de données de mineurs.",
                                "The app is intended only for persons aged 16 years or older (Art. 8 GDPR). Persons under 16 may not use the app. We do not collect data from minors."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                        }
                        
                        PrivacySection(localized("9. Keine Werbung oder Tracking", "9. Pas de publicité ou de suivi", "9. No Advertising or Tracking"), icon: "hand.raised") {
                            Text(localized(
                                "Wir zeigen keine Werbung in der App und verwenden keine Tracking-Technologien. Wir verkaufen keine Daten an Dritte.",
                                "Nous n'affichons pas de publicité dans l'application et n'utilisons pas de technologies de suivi. Nous ne vendons pas de données à des tiers.",
                                "We do not show advertising in the app and do not use tracking technologies. We do not sell data to third parties."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L.legalPrivacyNavTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.done.localized) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Helper Views
private struct PrivacySection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(_ title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white.opacity(0.2)))
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            
            content
                .font(.subheadline)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct ContactInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 110, alignment: .leading)
            if value.contains("@") && value.contains("."), let emailURL = URL(string: "mailto:\(value)") {
                Link(value, destination: emailURL)
                    .font(.caption)
                    .foregroundStyle(.blue)
            } else {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}

private struct PrivacyBullet: View {
    let title: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct DataCategory: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct RightRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct ImportantNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.white)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
    }
}
