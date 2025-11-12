import SwiftUI

struct PrivacyPolicyView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @Environment(\.dismiss) var dismiss
    
    // Language detection - use German content for DE, English for all others
    private var isGerman: Bool {
        localizationManager.currentLanguage == "de"
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
                        
                        Text(L.legalPrivacySubtitle.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        HStack(spacing: 16) {
                            Label(L.legalEffectiveDate.localized, systemImage: "calendar")
                            Label(L.legalVersion.localized, systemImage: "doc.text")
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
                    
                    PrivacySection(isGerman ? "1. Verantwortlicher" : "1. Data Controller", icon: "person.text.rectangle") {
                        VStack(alignment: .leading, spacing: 6) {
                            InfoRow(label: isGerman ? "Unternehmen" : "Company", value: "CulinaAI")
                            InfoRow(label: isGerman ? "Vertreten durch" : "Represented by", value: "Moritz Serrin")
                            InfoRow(label: isGerman ? "Adresse" : "Address", value: isGerman ? "21244 Buchholz, Deutschland" : "21244 Buchholz, Germany")
                            InfoRow(label: "E-Mail", value: "kontakt@culinaai.com")
                            InfoRow(label: isGerman ? "Datenschutz" : "Data Protection Contact", value: "datenschutz@culinaai.com")
                        }
                    }
                    
                    PrivacySection(isGerman ? "2. Allgemeines" : "2. General Information", icon: "info.circle") {
                        Text(isGerman ? L.ui_der_schutz_ihrer_personenbezogenen.localized : "Protecting your personal data is important to us. This Privacy Policy explains the type, scope, and purpose of processing personal data within our iOS app CulinaChef (CulinaAI).")
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                        
                        Text(isGerman ? L.ui_grundsätze_der_datenverarbeitung.localized : "Principles of data processing:")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                        
                        VStack(spacing: 8) {
                            PrincipleRow(title: isGerman ? "Datenminimierung" : "Data minimization", description: isGerman ? "Nur notwendige Daten werden erfasst" : "Only the data necessary for operation are collected")
                            PrincipleRow(title: isGerman ? "Transparenz" : "Transparency", description: isGerman ? "Klare Kommunikation über Datennutzung" : "We clearly communicate how your data are used")
                            PrincipleRow(title: isGerman ? "Sicherheit" : "Security", description: isGerman ? "TLS-Verschlüsselung und sichere Speicherung" : "TLS encryption and secure storage")
                            PrincipleRow(title: isGerman ? "Keine Werbung" : "No advertising", description: isGerman ? "Kein Tracking oder Profilbildung" : "No tracking or profiling")
                        }
                    }
                    
                    PrivacySection("3. Erhobene Daten", icon: "list.bullet.rectangle") {
                        SubSection("3.1 Benutzerkonto") {
                            Text(L.ui_erforderlich_bei_registrierung.localized)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint("Benutzername (3–32 Zeichen)")
                            BulletPoint("E-Mail-Adresse")
                            BulletPoint("Passwort (mind. 6 Zeichen, bcrypt)")
                            BulletPoint("Optional: Sign in with Apple")
                            
                            LegalBox(title: "Zweck", content: "Kontoerstellung und Authentifizierung")
                            LegalBox(title: "Rechtsgrundlage", content: "Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)")
                        }
                        
                        SubSection("3.2 Rezeptverwaltung") {
                            Text("Gespeicherte Daten:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint("Rezepttitel, Zutaten, Anleitung")
                            BulletPoint("Nährwerte, Kochzeit, Tags")
                            BulletPoint("Favoriten, Menüplanung")
                            BulletPoint("Bewertungen (1–5 Sterne)")
                            
                            LegalBox(title: "Zweck", content: "Hauptfunktion der App – Rezeptverwaltung")
                            LegalBox(title: "Speicherung", content: "Bis zur Löschung durch den Nutzer")
                        }
                        
                        SubSection("3.3 Ernährungspräferenzen") {
                            BulletPoint("Allergien (z.B. Nüsse, Gluten)")
                            BulletPoint("Ernährungsweisen (vegan, vegetarisch)")
                            BulletPoint("Geschmacksvorlieben / Abneigungen")
                            BulletPoint("Notizen (Freitext)")
                            
                            LegalBox(title: "Zweck", content: "Personalisierte Rezeptvorschläge und Filterung")
                        }
                        
                        SubSection("3.4 Künstliche Intelligenz (OpenAI)") {
                            Text(L.ui_wir_nutzen_openai_gpt4omini.localized)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint("Automatische Rezepterstellung")
                            BulletPoint("Beantwortung von Kochfragen")
                            
                            Text(L.ui_übermittelte_daten.localized)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            BulletPoint("Zutatenlisten")
                            BulletPoint("Chat-Nachrichten")
                            BulletPoint("Ernährungspräferenzen (Kontext)")
                            BulletPoint("KEINE personenbezogenen Daten")
                            
                            ThirdPartyBox(
                                title: "Drittanbieter: OpenAI L.L.C.",
                                items: [
                                    "Empfänger: OpenAI L.L.C., USA",
                                    "Rechtsgrundlage: Art. 49 Abs. 1 lit. a DSGVO (Einwilligung)",
                                    "Speicherdauer: Maximal 30 Tage bei OpenAI"
                                ]
                            )
                            
                            DisclaimerBox(text: "Wichtig: KI-generierte Inhalte sind automatisiert erstellt. Es besteht keine Haftung für Richtigkeit, Vollständigkeit oder gesundheitliche Verträglichkeit.")
                        }
                        
                        SubSection("3.5 Zahlungsabwicklung (Apple)") {
                            Text("Abonnement: 6,99 €/Monat via Apple In-App-Purchase")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("Verarbeitet durch Apple:")
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            BulletPoint("Apple-ID")
                            BulletPoint("Zahlungsinformationen")
                            BulletPoint("Kaufhistorie")
                            
                            LegalBox(title: "Hinweis", content: "Wir erhalten keine Zahlungsdaten, ausschließlich Transaktionsbestätigungen von Apple. Weitere Informationen finden Sie in der Apple Datenschutzrichtlinie.")
                        }
                        
                        SubSection("3.6 Lokale Speicherung") {
                            Text("UserDefaults (nicht sensibel):")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint("App-Sprache, Dark Mode")
                            BulletPoint("Onboarding-Status")
                            BulletPoint("Menüvorschläge (Cache)")
                            
                            Text(L.ui_keychain_verschlüsselt.localized)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            BulletPoint("Access & Refresh Token")
                            BulletPoint("User-ID, E-Mail")
                            
                            LegalBox(title: "Löschung", content: "Automatisch bei App-Deinstallation durch iOS")
                        }
                    }
                    
                    PrivacySection("4. Datenübermittlung in Drittländer", icon: "globe") {
                        Text(L.ui_folgende_drittanbieter_verarbeiten_.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 12) {
                            DataProcessorCard(
                                name: "Supabase Inc.",
                                purpose: "Datenbank und Authentifizierung",
                                location: "EU/USA",
                                legal: "Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)"
                            )
                            
                            DataProcessorCard(
                                name: "OpenAI L.L.C.",
                                purpose: "KI-gestützte Rezeptgenerierung",
                                location: "USA",
                                legal: "Art. 49 Abs. 1 lit. a DSGVO (Einwilligung)"
                            )
                            
                            DataProcessorCard(
                                name: "Apple Inc.",
                                purpose: "In-App-Käufe und Abonnements",
                                location: "USA",
                                legal: "Angemessenheitsbeschluss der EU-Kommission"
                            )
                        }
                        
                        SecurityNote(text: "Alle Datenübertragungen erfolgen verschlüsselt via HTTPS/TLS.")
                    }
                    
                    PrivacySection("5. Technische und organisatorische Maßnahmen", icon: "lock.shield") {
                        Text(L.ui_zum_schutz_ihrer_daten.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 10) {
                            SecurityMeasure(title: "Verschlüsselung", description: "TLS/HTTPS für alle Datenübertragungen")
                            SecurityMeasure(title: "Passwort-Schutz", description: "bcrypt-Hashing mit Salt")
                            SecurityMeasure(title: "Zugriffsschutz", description: "Row Level Security (RLS) in Datenbank")
                            SecurityMeasure(title: "Token-Sicherheit", description: "Sichere Speicherung in iOS Keychain")
                            SecurityMeasure(title: "Audit-Logs", description: "Protokollierung sicherheitsrelevanter Vorgänge")
                            SecurityMeasure(title: "Datensparsamkeit", description: "Kein Tracking, keine Werbung, kein Profiling")
                            SecurityMeasure(title: "Backup-Strategie", description: "Regelmäßige Sicherungen (30-Tage-Aufbewahrung)")
                        }
                    }
                    
                    PrivacySection("6. Ihre Rechte nach DSGVO", icon: "hand.raised") {
                        Text(L.ui_sie_haben_folgende_rechte.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 10) {
                            RightCard(icon: "doc.text.magnifyingglass", title: "Auskunft (Art. 15)", description: "Übersicht über alle gespeicherten Daten")
                            RightCard(icon: "pencil", title: "Berichtigung (Art. 16)", description: "Korrektur falscher oder unvollständiger Daten")
                            RightCard(icon: "trash", title: "Löschung (Art. 17)", description: "Vollständige Löschung Ihres Kontos in der App")
                            RightCard(icon: "arrow.down.doc", title: "Datenportabilität (Art. 20)", description: "Export Ihrer Daten im JSON-Format")
                            RightCard(icon: "hand.raised.slash", title: "Widerspruch (Art. 21)", description: "Widerspruch gegen Datenverarbeitung")
                            RightCard(icon: "exclamationmark.shield", title: "Beschwerde (Art. 77)", description: "Beschwerde bei Aufsichtsbehörde")
                        }
                        
                        ContactBox(
                            title: "Ausübung Ihrer Rechte",
                            email: "datenschutz@culinaai.com",
                            note: "Zur Ausübung Ihrer Rechte kontaktieren Sie uns bitte per E-Mail. Wir werden Ihre Anfrage unverzüglich bearbeiten."
                        )
                    }
                    
                    PrivacySection("7. Speicherdauer", icon: "clock") {
                        Text(L.ui_übersicht_über_die_aufbewahrungsfri.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 1) {
                            StorageRow(type: "Benutzerkonto", duration: "Bis zur Löschung", method: "Manuell durch Nutzer")
                            StorageRow(type: "Rezepte & Favoriten", duration: "Bis zur Löschung", method: "Mit Konto")
                            StorageRow(type: "Ernährungspräferenzen", duration: "Bis zur Löschung", method: "Mit Konto")
                            StorageRow(type: "Chat-Nachrichten", duration: "Sitzungsdauer", method: "Nach App-Schließen")
                            StorageRow(type: "API-Protokolle", duration: "30 Tage", method: "Technische Logs")
                            StorageRow(type: "Audit-Protokolle", duration: "3 Jahre", method: "Gesetzliche Pflicht")
                        }
                        .background(.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        Text(L.ui_hinweis_chatnachrichten_werden_nur.localized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                    
                    PrivacySection("8. Minderjährigenschutz", icon: "person.2") {
                        LegalBox(
                            title: "Altersanforderung",
                            content: "Die Nutzung der App ist Personen ab 16 Jahren gestattet. Personen unter 16 Jahren benötigen die Einwilligung eines Erziehungsberechtigten gemäß Art. 8 DSGVO."
                        )
                    }
                    
                    PrivacySection("9. Keine Werbung oder Tracking", icon: "eye.slash") {
                        Text(L.ui_wir_verzichten_vollständig_auf.localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 8) {
                            NoTrackingRow(item: "Cookies oder ähnliche Tracking-Technologien")
                            NoTrackingRow(item: "Google Analytics oder vergleichbare Analysedienste")
                            NoTrackingRow(item: "Werbung, Werbenetzwerke oder Profilbildung")
                            NoTrackingRow(item: "Social-Media-Plugins oder externe Tracker")
                        }
                        
                        HighlightBox(text: "Ihre persönlichen Daten werden niemals an Dritte verkauft oder für Werbezwecke verwendet.")
                    }
                    
                    PrivacySection("10. Kontolöschung", icon: "person.crop.circle.badge.minus") {
                        Text(L.ui_sie_können_ihr_konto.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        InstructionBox(
                            title: "Löschung durchführen",
                            steps: [
                                "Öffnen Sie die Einstellungen in der App",
                                "Wählen Sie 'Konto löschen'",
                                "Bestätigen Sie die Löschung"
                            ]
                        )
                        
                        Text(L.ui_folgende_daten_werden_gelöscht.localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DeletionItem("Benutzerkonto und Authentifizierungsdaten")
                            DeletionItem("Alle gespeicherten Rezepte, Menüs und Favoriten")
                            DeletionItem("Ernährungspräferenzen und persönliche Einstellungen")
                            DeletionItem("Bewertungen und Notizen")
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.1))
                        .cornerRadius(10)
                        
                        ImportantNote(
                            title: "Wichtiger Hinweis",
                            items: [
                                "Apple-Abonnements müssen separat in der Apple-ID-Verwaltung gekündigt werden.",
                                "Audit-Protokolle der Löschung werden aus rechtlichen Gründen 3 Jahre aufbewahrt (Art. 6 Abs. 1 lit. c DSGVO).",
                                "Die Löschung ist endgültig und kann nicht rückgängig gemacht werden."
                            ]
                        )
                    }
                    
                    PrivacySection("11. Änderungen dieser Datenschutzerklärung", icon: "arrow.triangle.2.circlepath") {
                        LegalBox(
                            title: "Aktualisierungen",
                            content: "Wir behalten uns vor, diese Datenschutzerklärung bei rechtlichen oder technischen Änderungen anzupassen. Die jeweils aktuelle Version finden Sie in der App sowie unter https://culinaai.com/datenschutz. Bei wesentlichen Änderungen werden Sie innerhalb der App informiert."
                        )
                    }
                    
                    PrivacySection("12. Kontakt", icon: "envelope") {
                        ContactInfoBox(
                            contacts: [
                                (label: "Datenschutzanfragen", email: "datenschutz@culinaai.com"),
                                (label: "Technischer Support", email: "support@culinaai.com"),
                                (label: "Allgemeine Anfragen", email: "kontakt@culinaai.com")
                            ]
                        )
                    }
                    
                    PrivacySection("13. Anwendbares Recht und Gerichtsstand", icon: "building.columns") {
                        LegalBox(
                            title: "Rechtliche Grundlage",
                            content: "Für diese Datenschutzerklärung und die Datenverarbeitung gilt ausschließlich deutsches Recht. Gerichtsstand ist Deutschland."
                        )
                        
                        Text(L.ui_maßgebliche_rechtsgrundlagen.localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            LegalReference("DSGVO", "Datenschutz-Grundverordnung")
                            LegalReference("BDSG", "Bundesdatenschutzgesetz")
                            LegalReference("TMG", "Telemediengesetz")
                            LegalReference("UWG", "Gesetz gegen den unlauteren Wettbewerb")
                            LegalReference("BGB", "Bürgerliches Gesetzbuch")
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Divider().background(.white.opacity(0.3))
                        .padding(.vertical, 8)
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text(L.legalFooterDate.localized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(L.legalVersion.localized)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
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

private struct SubSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            content
        }
        .padding(.top, 8)
    }
}

private struct BulletPoint: View {
    let text: String
    init(_ text: String) { self.text = text }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .foregroundStyle(.white)
            Spacer()
        }
        .font(.subheadline)
    }
}

private struct InfoBox: View {
    let text: String
    init(_ text: String) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.2))
            .cornerRadius(8)
    }
}

private struct WarningBox: View {
    let text: String
    init(_ text: String) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.2))
            .cornerRadius(8)
    }
}

private struct ThirdPartyRow: View {
    let name: String
    let purpose: String
    let country: String
    let basis: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text("Zweck: \(purpose)")
                .foregroundStyle(.white.opacity(0.8))
            Text("Sitz: \(country)")
                .foregroundStyle(.white.opacity(0.8))
            Text("Grundlage: \(basis)")
                .foregroundStyle(.white.opacity(0.8))
        }
        .font(.caption)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(8)
    }
}

private struct RightRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(icon)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(desc)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}

private struct StorageRow: View {
    let type: String
    let duration: String
    let method: String
    
    var body: some View {
        HStack {
            Text(type)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(duration)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(method)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.1))
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 130, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct PrincipleRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct LegalBox: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            Text(content)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .cornerRadius(10)
    }
}

private struct ThirdPartyBox: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .foregroundStyle(.white.opacity(0.7))
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .cornerRadius(10)
    }
}

private struct DisclaimerBox: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .cornerRadius(10)
    }
}

private struct DataProcessorCard: View {
    let name: String
    let purpose: String
    let location: String
    let legal: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRowSmall(label: "Zweck", value: purpose)
                InfoRowSmall(label: "Standort", value: location)
                InfoRowSmall(label: "Rechtsgrundlage", value: legal)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct InfoRowSmall: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct SecurityNote: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.white)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .cornerRadius(10)
    }
}

private struct SecurityMeasure: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.fill")
                .font(.body)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct RightCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct ContactBox: View {
    let title: String
    let email: String
    let note: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(.white)
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            
            Text(note)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .cornerRadius(10)
    }
}

private struct NoTrackingRow: View {
    let item: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white)
            Text(item)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(8)
    }
}

private struct HighlightBox: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.2))
        .cornerRadius(10)
    }
}

private struct InstructionBox: View {
    let title: String
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 20)
                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct DeletionItem: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "minus.circle.fill")
                .font(.body)
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct ImportantNote: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text(item)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineSpacing(3)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .cornerRadius(10)
    }
}

private struct ContactInfoBox: View {
    let contacts: [(label: String, email: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(contacts, id: \.label) { contact in
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.label)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 6) {
                        Image(systemName: "envelope")
                            .font(.caption)
                            .foregroundStyle(.white)
                        Text(contact.email)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                
                if contact.label != contacts.last?.label {
                    Divider()
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct LegalReference: View {
    let abbreviation: String
    let fullName: String
    
    init(_ abbreviation: String, _ fullName: String) {
        self.abbreviation = abbreviation
        self.fullName = fullName
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(abbreviation)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 70, alignment: .leading)
            Text(fullName)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
    }
}
