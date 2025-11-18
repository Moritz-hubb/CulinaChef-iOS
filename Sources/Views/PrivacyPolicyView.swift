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
                            InfoRow(label: isGerman ? "Adresse" : "Address", value: isGerman ? "Sonnenblumenweg 8, 21244 Buchholz, Deutschland" : "Sonnenblumenweg 8, 21244 Buchholz, Germany")
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
                    
                    PrivacySection(isGerman ? "3. Erhobene Daten" : "3. Data Collected", icon: "list.bullet.rectangle") {
                        SubSection(isGerman ? "3.1 Benutzerkonto" : "3.1 User Account") {
                            Text(isGerman ? L.ui_erforderlich_bei_registrierung.localized : "Required for registration:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint(isGerman ? "Benutzername (3–32 Zeichen)" : "Username (3–32 characters)")
                            BulletPoint(isGerman ? "E-Mail-Adresse" : "E-mail address")
                            BulletPoint(isGerman ? "Passwort (mind. 6 Zeichen, bcrypt)" : "Password (min. 6 characters, bcrypt)")
                            BulletPoint("Optional: Sign in with Apple")
                            
                            LegalBox(
                                title: isGerman ? "Zweck" : "Purpose",
                                content: isGerman ? "Kontoerstellung und Authentifizierung" : "Account creation and authentication"
                            )
                            LegalBox(
                                title: isGerman ? "Rechtsgrundlage" : "Legal basis",
                                content: isGerman ? "Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)" : "Art. 6 (1)(b) GDPR (contract performance)"
                            )
                        }
                        
                        SubSection(isGerman ? "3.2 Rezeptverwaltung" : "3.2 Recipe Management") {
                            Text(isGerman ? "Gespeicherte Daten:" : "Stored data:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint(isGerman ? "Rezepttitel, Zutaten, Anleitung" : "Recipe title, ingredients, instructions")
                            BulletPoint(isGerman ? "Nährwerte, Kochzeit, Tags" : "Nutritional values, cooking time, tags")
                            BulletPoint(isGerman ? "Favoriten, Menüplanung" : "Favorites, menu planning")
                            BulletPoint(isGerman ? "Bewertungen (1–5 Sterne)" : "Ratings (1–5 stars)")
                            
                            LegalBox(
                                title: isGerman ? "Zweck" : "Purpose",
                                content: isGerman ? "Hauptfunktion der App – Rezeptverwaltung" : "Main app function – recipe management"
                            )
                            LegalBox(
                                title: isGerman ? "Speicherung" : "Storage",
                                content: isGerman ? "Bis zur Löschung durch den Nutzer" : "Until deletion by the user"
                            )
                        }
                        
                        SubSection(isGerman ? "3.3 Ernährungspräferenzen" : "3.3 Dietary Preferences") {
                            BulletPoint(isGerman ? "Allergien (z.B. Nüsse, Gluten)" : "Allergies (e.g., nuts, gluten)")
                            BulletPoint(isGerman ? "Ernährungsweisen (vegan, vegetarisch)" : "Dietary preferences (vegan, vegetarian)")
                            BulletPoint(isGerman ? "Geschmacksvorlieben / Abneigungen" : "Taste preferences / aversions")
                            BulletPoint(isGerman ? "Notizen (Freitext)" : "Notes (free text)")
                            
                            LegalBox(
                                title: isGerman ? "Zweck" : "Purpose",
                                content: isGerman ? "Personalisierte Rezeptvorschläge und Filterung" : "Personalized recipe suggestions and filtering"
                            )
                        }
                        
                        SubSection(isGerman ? "3.4 Künstliche Intelligenz (OpenAI)" : "3.4 Artificial Intelligence (OpenAI)") {
                            Text(isGerman ? L.ui_wir_nutzen_openai_gpt4omini.localized : "We use OpenAI GPT-4o-mini for:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint(isGerman ? "Automatische Rezepterstellung" : "Automatic recipe creation")
                            BulletPoint(isGerman ? "Beantwortung von Kochfragen" : "Answering cooking questions")
                            
                            Text(isGerman ? L.ui_übermittelte_daten.localized : "Data transmitted:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            BulletPoint(isGerman ? "Zutatenlisten" : "Ingredient lists")
                            BulletPoint(isGerman ? "Chat-Nachrichten" : "Chat messages")
                            BulletPoint(isGerman ? "Ernährungspräferenzen (Kontext)" : "Dietary preferences (context)")
                            BulletPoint(isGerman ? "KEINE personenbezogenen Daten" : "NO personal data")
                            
                            ThirdPartyBox(
                                title: isGerman ? "Drittanbieter: OpenAI L.L.C." : "Third-party provider: OpenAI L.L.C.",
                                items: isGerman ? [
                                    "Empfänger: OpenAI L.L.C., USA",
                                    "Rechtsgrundlage: Art. 49 Abs. 1 lit. a DSGVO (Einwilligung)",
                                    "Speicherdauer: Maximal 30 Tage bei OpenAI"
                                ] : [
                                    "Recipient: OpenAI L.L.C., USA",
                                    "Legal basis: Art. 49 (1)(a) GDPR (consent)",
                                    "Storage period: Maximum 30 days at OpenAI"
                                ]
                            )
                            
                            DisclaimerBox(
                                text: isGerman ? "Wichtig: KI-generierte Inhalte sind automatisiert erstellt. Es besteht keine Haftung für Richtigkeit, Vollständigkeit oder gesundheitliche Verträglichkeit." : "Important: AI-generated content is automatically created. There is no liability for accuracy, completeness, or health compatibility."
                            )
                            
                            // KI-Disclaimer: Fehler und Gesundheit
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(isGerman ? "Wichtiger Hinweis zu KI-generierten Rezepten" : "Important Notice Regarding AI-Generated Recipes")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(.white)
                                        
                                        Text(isGerman ? 
                                            "KI-Systeme können Fehler machen. Bitte überprüfen Sie alle KI-generierten Rezepte sorgfältig, bevor Sie sie zubereiten. Insbesondere bei Allergien, Unverträglichkeiten oder speziellen Ernährungsanforderungen sollten Sie die Zutatenliste und Anweisungen doppelt prüfen." :
                                            "AI systems can make errors. Please carefully review all AI-generated recipes before preparing them. Especially if you have allergies, intolerances, or special dietary requirements, you should double-check the ingredient list and instructions.")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.9))
                                            .lineSpacing(4)
                                        
                                        Text(isGerman ?
                                            "Wir übernehmen keine Haftung für gesundheitliche Folgen, die durch die Verwendung von KI-generierten Rezepten entstehen. Die Verantwortung für die Überprüfung der Rezepte und die Entscheidung, ob ein Rezept für Ihre individuellen Bedürfnisse geeignet ist, liegt allein bei Ihnen." :
                                            "We assume no liability for health consequences arising from the use of AI-generated recipes. The responsibility for reviewing recipes and deciding whether a recipe is suitable for your individual needs lies solely with you.")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.9))
                                            .lineSpacing(4)
                                    }
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
                            )
                            .padding(.top, 8)
                        }
                        
                        SubSection(isGerman ? "3.5 Zahlungsabwicklung (Apple)" : "3.5 Payment Processing (Apple)") {
                            Text(isGerman ? "Abonnement: 5,99 €/Monat via Apple In-App-Purchase" : "Subscription: € 5.99 per month via Apple In-App Purchase")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text(isGerman ? "Verarbeitet durch Apple:" : "Processed by Apple:")
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            BulletPoint(isGerman ? "Apple-ID" : "Apple ID")
                            BulletPoint(isGerman ? "Zahlungsinformationen" : "Payment information")
                            BulletPoint(isGerman ? "Kaufhistorie" : "Purchase history")
                            
                            LegalBox(
                                title: isGerman ? "Hinweis" : "Note",
                                content: isGerman ? "Wir erhalten keine Zahlungsdaten, ausschließlich Transaktionsbestätigungen von Apple. Weitere Informationen finden Sie in der Apple Datenschutzrichtlinie." : "We do not receive or store payment data — only transaction confirmations from Apple. For details, please refer to Apple's Privacy Policy."
                            )
                        }
                        
                        SubSection(isGerman ? "3.6 Fehlererfassung und Crash Reporting (Sentry)" : "3.6 Error Tracking and Crash Reporting (Sentry)") {
                            Text(isGerman ? "Zur Verbesserung der App-Stabilität nutzen wir Sentry von Functional Software, Inc." : "We use Sentry by Functional Software, Inc. to improve app stability.")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text(isGerman ? "Übermittelte Daten bei Crashes oder Fehlern:" : "Data transmitted during crashes or errors:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            BulletPoint(isGerman ? "Geräteinformationen (Modell, iOS-Version)" : "Device information (model, iOS version)")
                            BulletPoint(isGerman ? "App-Version und Build-Nummer" : "App version and build number")
                            BulletPoint(isGerman ? "Stack Traces (technische Fehlerprotokolle)" : "Stack traces (technical error logs)")
                            BulletPoint(isGerman ? "Zeitstempel des Fehlers" : "Error timestamps")
                            BulletPoint(isGerman ? "User-Aktionen vor dem Fehler (Breadcrumbs)" : "User actions before the error (breadcrumbs)")
                            BulletPoint(isGerman ? "KEINE personenbezogenen Daten (Namen, E-Mails, etc.)" : "No personal data (names, e-mails, etc.)")
                            
                            ThirdPartyBox(
                                title: isGerman ? "Drittanbieter: Functional Software, Inc. (Sentry)" : "Third-party provider: Functional Software, Inc. (Sentry)",
                                items: isGerman ? [
                                    "Empfänger: Functional Software, Inc., USA",
                                    "Rechtsgrundlage: Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse)",
                                    "Speicherdauer: 30 Tage bei Sentry",
                                    "Zweck: Erkennung und Behebung von technischen Fehlern zur Verbesserung der App-Stabilität"
                                ] : [
                                    "Recipient: Functional Software, Inc., USA",
                                    "Legal basis: Art. 6 (1)(f) GDPR – Legitimate interest",
                                    "Storage period: 30 days at Sentry",
                                    "Purpose: Detection and resolution of technical errors to improve app stability"
                                ]
                            )
                            
                            if isGerman {
                                Link("Weitere Informationen: https://sentry.io/privacy/", destination: URL(string: "https://sentry.io/privacy")!)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .underline()
                                    .padding(.top, 4)
                            } else {
                                Link("For more information, see: https://sentry.io/privacy/", destination: URL(string: "https://sentry.io/privacy")!)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .underline()
                                    .padding(.top, 4)
                            }
                        }
                        
                        SubSection(isGerman ? "3.7 Lokale Speicherung" : "3.7 Local Storage") {
                            Text(isGerman ? "UserDefaults (nicht sensibel):" : "UserDefaults (non-sensitive):")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            BulletPoint(isGerman ? "App-Sprache, Dark Mode" : "App language, dark mode setting")
                            BulletPoint(isGerman ? "Onboarding-Status" : "Onboarding status")
                            BulletPoint(isGerman ? "Menüvorschläge (Cache)" : "Menu suggestions (cache)")
                            
                            Text(isGerman ? "Keychain (verschlüsselt):" : "Keychain (encrypted):")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                            BulletPoint("Access & Refresh Token")
                            BulletPoint(isGerman ? "User-ID, E-Mail" : "User ID, e-mail")
                            
                            LegalBox(
                                title: isGerman ? "Löschung" : "Deletion",
                                content: isGerman ? "Automatisch bei App-Deinstallation durch iOS" : "Automatically performed by iOS when the app is uninstalled."
                            )
                        }
                    }
                    
                    PrivacySection(isGerman ? "4. Datenübermittlung in Drittländer" : "4. Data Transfers to Third Countries", icon: "globe") {
                        Text(isGerman ? "Folgende Drittanbieter verarbeiten Daten außerhalb der EU:" : "The following service providers may process data outside the European Union:")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 12) {
                            DataProcessorCard(
                                name: "Supabase Inc.",
                                purpose: isGerman ? "Datenbank und Authentifizierung" : "Database and authentication",
                                location: "EU/USA",
                                legal: isGerman ? "Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)" : "Art. 6 (1)(b) GDPR"
                            )
                            
                            DataProcessorCard(
                                name: "OpenAI L.L.C.",
                                purpose: isGerman ? "KI-gestützte Rezeptgenerierung" : "AI-based recipe generation",
                                location: "USA",
                                legal: isGerman ? "Art. 49 Abs. 1 lit. a DSGVO (Einwilligung)" : "Art. 49 (1)(a) GDPR"
                            )
                            
                            DataProcessorCard(
                                name: "Apple Inc.",
                                purpose: isGerman ? "In-App-Käufe und Abonnements" : "In-app purchases and subscriptions",
                                location: "USA",
                                legal: isGerman ? "Angemessenheitsbeschluss der EU-Kommission" : "EU Adequacy Decision"
                            )
                            
                            DataProcessorCard(
                                name: "Functional Software, Inc. (Sentry)",
                                purpose: isGerman ? "Fehlererfassung und Crash Reporting" : "Error tracking and crash reporting",
                                location: "USA/EU",
                                legal: isGerman ? "Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse)" : "Art. 6 (1)(f) GDPR"
                            )
                        }
                        
                        SecurityNote(text: isGerman ? "Alle Datenübertragungen erfolgen verschlüsselt via HTTPS/TLS." : "All data transmissions are encrypted via HTTPS/TLS.")
                    }
                    
                    PrivacySection(isGerman ? "5. Technische und organisatorische Maßnahmen" : "5. Technical and Organizational Measures", icon: "lock.shield") {
                        Text(L.ui_zum_schutz_ihrer_daten.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 10) {
                            SecurityMeasure(
                                title: isGerman ? "Verschlüsselung" : "Encryption",
                                description: isGerman ? "TLS/HTTPS für alle Datenübertragungen" : "TLS/HTTPS for all data transmissions"
                            )
                            SecurityMeasure(
                                title: isGerman ? "Passwort-Schutz" : "Password Protection",
                                description: isGerman ? "bcrypt-Hashing mit Salt" : "bcrypt hashing with salt"
                            )
                            SecurityMeasure(
                                title: isGerman ? "Zugriffsschutz" : "Access Protection",
                                description: isGerman ? "Row Level Security (RLS) in Datenbank" : "Row Level Security (RLS) in database"
                            )
                            SecurityMeasure(
                                title: isGerman ? "Token-Sicherheit" : "Token Security",
                                description: isGerman ? "Sichere Speicherung in iOS Keychain" : "Secure storage in iOS Keychain"
                            )
                            SecurityMeasure(
                                title: "Audit-Logs",
                                description: isGerman ? "Protokollierung sicherheitsrelevanter Vorgänge" : "Logging of security-relevant processes"
                            )
                            SecurityMeasure(
                                title: isGerman ? "Datensparsamkeit" : "Data Minimization",
                                description: isGerman ? "Kein Tracking, keine Werbung, kein Profiling" : "No tracking, no advertising, no profiling"
                            )
                            SecurityMeasure(
                                title: isGerman ? "Backup-Strategie" : "Backup Strategy",
                                description: isGerman ? "Regelmäßige Sicherungen (30-Tage-Aufbewahrung)" : "Regular backups (30-day retention)"
                            )
                        }
                    }
                    
                    PrivacySection(isGerman ? "6. Ihre Rechte nach DSGVO" : "6. Your Rights under GDPR", icon: "hand.raised") {
                        Text(L.ui_sie_haben_folgende_rechte.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 10) {
                            RightCard(
                                icon: "doc.text.magnifyingglass",
                                title: isGerman ? "Auskunft (Art. 15)" : "Right of Access (Art. 15)",
                                description: isGerman ? "Übersicht über alle gespeicherten Daten" : "Overview of all stored data"
                            )
                            RightCard(
                                icon: "pencil",
                                title: isGerman ? "Berichtigung (Art. 16)" : "Rectification (Art. 16)",
                                description: isGerman ? "Korrektur falscher oder unvollständiger Daten" : "Correction of incorrect or incomplete data"
                            )
                            RightCard(
                                icon: "trash",
                                title: isGerman ? "Löschung (Art. 17)" : "Erasure (Art. 17)",
                                description: isGerman ? "Vollständige Löschung Ihres Kontos in der App" : "Complete deletion of your account in the app"
                            )
                            RightCard(
                                icon: "arrow.down.doc",
                                title: isGerman ? "Datenportabilität (Art. 20)" : "Data Portability (Art. 20)",
                                description: isGerman ? "Export Ihrer Daten im JSON-Format" : "Export of your data in JSON format"
                            )
                            RightCard(
                                icon: "hand.raised.slash",
                                title: isGerman ? "Widerspruch (Art. 21)" : "Objection (Art. 21)",
                                description: isGerman ? "Widerspruch gegen Datenverarbeitung" : "Objection to data processing"
                            )
                            RightCard(
                                icon: "exclamationmark.shield",
                                title: isGerman ? "Beschwerde (Art. 77)" : "Complaint (Art. 77)",
                                description: isGerman ? "Beschwerde bei Aufsichtsbehörde" : "Complaint to supervisory authority"
                            )
                        }
                        
                        ContactBox(
                            title: isGerman ? "Ausübung Ihrer Rechte" : "Exercising Your Rights",
                            email: "datenschutz@culinaai.com",
                            note: isGerman ? "Zur Ausübung Ihrer Rechte kontaktieren Sie uns bitte per E-Mail. Wir werden Ihre Anfrage unverzüglich bearbeiten." : "To exercise your rights, please contact us by e-mail. We will process your request immediately."
                        )
                    }
                    
                    PrivacySection(isGerman ? "7. Speicherdauer" : "7. Storage Period", icon: "clock") {
                        Text(L.ui_übersicht_über_die_aufbewahrungsfri.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 1) {
                            StorageRow(
                                type: isGerman ? "Benutzerkonto" : "User Account",
                                duration: isGerman ? "Bis zur Löschung" : "Until deletion",
                                method: isGerman ? "Manuell durch Nutzer" : "Manual by user"
                            )
                            StorageRow(
                                type: isGerman ? "Rezepte & Favoriten" : "Recipes & Favorites",
                                duration: isGerman ? "Bis zur Löschung" : "Until deletion",
                                method: isGerman ? "Mit Konto" : "With account"
                            )
                            StorageRow(
                                type: isGerman ? "Ernährungspräferenzen" : "Dietary Preferences",
                                duration: isGerman ? "Bis zur Löschung" : "Until deletion",
                                method: isGerman ? "Mit Konto" : "With account"
                            )
                            StorageRow(
                                type: isGerman ? "Chat-Nachrichten" : "Chat Messages",
                                duration: isGerman ? "Sitzungsdauer" : "Session duration",
                                method: isGerman ? "Nach App-Schließen" : "After app closes"
                            )
                            StorageRow(
                                type: isGerman ? "API-Protokolle" : "API Logs",
                                duration: isGerman ? "30 Tage" : "30 days",
                                method: isGerman ? "Technische Logs" : "Technical logs"
                            )
                            StorageRow(
                                type: isGerman ? "Audit-Protokolle" : "Audit Logs",
                                duration: isGerman ? "3 Jahre" : "3 years",
                                method: isGerman ? "Gesetzliche Pflicht" : "Legal requirement"
                            )
                        }
                        .background(.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        Text(L.ui_hinweis_chatnachrichten_werden_nur.localized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                    
                    PrivacySection(isGerman ? "8. Minderjährigenschutz" : "8. Protection of Minors", icon: "person.2") {
                        LegalBox(
                            title: isGerman ? "Altersanforderung" : "Age Requirement",
                            content: isGerman ? "Die Nutzung der App ist Personen ab 16 Jahren gestattet. Personen unter 16 Jahren benötigen die Einwilligung eines Erziehungsberechtigten gemäß Art. 8 DSGVO." : "Use of the app is permitted for persons aged 16 years or older. Persons under 16 years of age require the consent of a parent or guardian in accordance with Art. 8 GDPR."
                        )
                    }
                    
                    PrivacySection(isGerman ? "9. Keine Werbung oder Tracking" : "9. No Advertising or Tracking", icon: "eye.slash") {
                        Text(L.ui_wir_verzichten_vollständig_auf.localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 8) {
                            NoTrackingRow(item: isGerman ? "Cookies oder ähnliche Tracking-Technologien" : "Cookies or similar tracking technologies")
                            NoTrackingRow(item: isGerman ? "Google Analytics oder vergleichbare Analysedienste" : "Google Analytics or comparable analytics services")
                            NoTrackingRow(item: isGerman ? "Werbung, Werbenetzwerke oder Profilbildung" : "Advertising, ad networks, or profiling")
                            NoTrackingRow(item: isGerman ? "Social-Media-Plugins oder externe Tracker" : "Social media plugins or external trackers")
                        }
                        
                        HighlightBox(text: isGerman ? "Ihre persönlichen Daten werden niemals an Dritte verkauft oder für Werbezwecke verwendet." : "Your personal data will never be sold to third parties or used for advertising purposes.")
                    }
                    
                    PrivacySection(isGerman ? "10. Kontolöschung" : "10. Account Deletion", icon: "person.crop.circle.badge.minus") {
                        Text(L.ui_sie_können_ihr_konto.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        
                        InstructionBox(
                            title: isGerman ? "Löschung durchführen" : "Perform Deletion",
                            steps: isGerman ? [
                                "Öffnen Sie die Einstellungen in der App",
                                "Wählen Sie 'Konto löschen'",
                                "Bestätigen Sie die Löschung"
                            ] : [
                                "Open the settings in the app",
                                "Select 'Delete Account'",
                                "Confirm the deletion"
                            ]
                        )
                        
                        Text(isGerman ? L.ui_folgende_daten_werden_gelöscht.localized : "The following data will be deleted:")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DeletionItem(isGerman ? "Benutzerkonto und Authentifizierungsdaten" : "User account and authentication data")
                            DeletionItem(isGerman ? "Alle gespeicherten Rezepte, Menüs und Favoriten" : "All stored recipes, menus, and favorites")
                            DeletionItem(isGerman ? "Ernährungspräferenzen und persönliche Einstellungen" : "Dietary preferences and personal settings")
                            DeletionItem(isGerman ? "Bewertungen und Notizen" : "Ratings and notes")
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.1))
                        .cornerRadius(10)
                        
                        ImportantNote(
                            title: isGerman ? "Wichtiger Hinweis" : "Important Notice",
                            items: isGerman ? [
                                "Apple-Abonnements müssen separat in der Apple-ID-Verwaltung gekündigt werden.",
                                "Audit-Protokolle der Löschung werden aus rechtlichen Gründen 3 Jahre aufbewahrt (Art. 6 Abs. 1 lit. c DSGVO).",
                                "Die Löschung ist endgültig und kann nicht rückgängig gemacht werden."
                            ] : [
                                "Apple subscriptions must be cancelled separately in Apple ID management.",
                                "Audit logs of the deletion are retained for 3 years for legal reasons (Art. 6 (1)(c) GDPR).",
                                "The deletion is permanent and cannot be undone."
                            ]
                        )
                    }
                    
                    PrivacySection(isGerman ? "11. Änderungen dieser Datenschutzerklärung" : "11. Changes to this Privacy Policy", icon: "arrow.triangle.2.circlepath") {
                        LegalBox(
                            title: isGerman ? "Aktualisierungen" : "Updates",
                            content: isGerman ? "Wir behalten uns vor, diese Datenschutzerklärung bei rechtlichen oder technischen Änderungen anzupassen. Die jeweils aktuelle Version finden Sie in der App sowie unter https://culinaai.com/datenschutz. Bei wesentlichen Änderungen werden Sie innerhalb der App informiert." : "We reserve the right to adapt this Privacy Policy in the event of legal or technical changes. You can find the current version in the app as well as at https://culinaai.com/datenschutz. You will be informed within the app of any material changes."
                        )
                    }
                    
                    PrivacySection(isGerman ? "12. Kontakt" : "12. Contact", icon: "envelope") {
                        ContactInfoBox(
                            contacts: [
                                (label: isGerman ? "Datenschutzanfragen" : "Privacy Inquiries", email: "datenschutz@culinaai.com"),
                                (label: isGerman ? "Technischer Support" : "Technical Support", email: "support@culinaai.com"),
                                (label: isGerman ? "Allgemeine Anfragen" : "General Inquiries", email: "kontakt@culinaai.com")
                            ]
                        )
                    }
                    
                    PrivacySection(isGerman ? "13. Anwendbares Recht und Gerichtsstand" : "13. Applicable Law and Jurisdiction", icon: "building.columns") {
                        LegalBox(
                            title: isGerman ? "Rechtliche Grundlage" : "Legal Basis",
                            content: isGerman ? "Für diese Datenschutzerklärung und die Datenverarbeitung gilt ausschließlich deutsches Recht. Gerichtsstand ist Deutschland." : "German law applies exclusively to this Privacy Policy and data processing. The place of jurisdiction is Germany."
                        )
                        
                        Text(isGerman ? L.ui_maßgebliche_rechtsgrundlagen.localized : "Relevant Legal Frameworks:")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            LegalReference("DSGVO", isGerman ? "Datenschutz-Grundverordnung" : "General Data Protection Regulation (GDPR)")
                            LegalReference("BDSG", isGerman ? "Bundesdatenschutzgesetz" : "Federal Data Protection Act")
                            LegalReference("TMG", isGerman ? "Telemediengesetz" : "Telemedia Act")
                            LegalReference("UWG", isGerman ? "Gesetz gegen den unlauteren Wettbewerb" : "Act Against Unfair Competition")
                            LegalReference("BGB", isGerman ? "Bürgerliches Gesetzbuch" : "German Civil Code")
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
            // Check if value is an email address
            if value.contains("@") && value.contains("."), let emailURL = URL(string: "mailto:\(value)") {
                Link(value, destination: emailURL)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            } else {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
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
            // Parse content and make URLs clickable
            if let httpsRange = content.range(of: "https://") {
                let beforeURL = String(content[..<httpsRange.lowerBound])
                let urlStart = httpsRange.lowerBound
                // Find the end of the URL (space or end of string)
                let remaining = content[urlStart...]
                let urlEnd = remaining.firstIndex(where: { $0 == " " || $0 == "." || $0 == "," }) ?? remaining.endIndex
                let urlString = String(content[urlStart..<urlEnd])
                let afterURL = String(content[urlEnd...])
                
                VStack(alignment: .leading, spacing: 4) {
                    if !beforeURL.isEmpty {
                        Text(beforeURL)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    if let url = URL(string: urlString) {
                        Link(urlString, destination: url)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .underline()
                    } else {
                        Text(urlString)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    if !afterURL.isEmpty {
                        Text(afterURL)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            } else {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(3)
            }
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
            
            if let emailURL = URL(string: "mailto:\(email)") {
                Link(destination: emailURL) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.white)
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.white)
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
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
                    if let emailURL = URL(string: "mailto:\(contact.email)") {
                        Link(destination: emailURL) {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                Text(contact.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope")
                                .font(.caption)
                                .foregroundStyle(.white)
                            Text(contact.email)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
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
