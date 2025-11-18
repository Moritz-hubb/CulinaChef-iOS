import SwiftUI

struct TermsOfServiceView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @Environment(\.dismiss) var dismiss
    @State private var showFairUsePolicy = false
    @State private var showPrivacy = false
    
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
                        Text(L.legalTermsTitle.localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text(L.legalTermsSubtitle.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        HStack(spacing: 16) {
                            Label(L.legalEffectiveDate.localized, systemImage: "calendar")
                            Label(L.legalVersion.localized, systemImage: "doc.text")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        
                        Text(L.legalContractLanguageNotice.localized)
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
                    
                    TermsSection(isGerman ? "1. Geltungsbereich und Vertragsparteien" : "1. Scope and Contracting Parties", icon: "doc.text") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Diese Allgemeinen Geschäftsbedingungen (nachfolgend 'AGB') gelten für die Nutzung der mobilen Applikation 'CulinaChef (CulinaAI)' (nachfolgend 'App') durch Verbraucher im Sinne des § 13 BGB." : "These Terms and Conditions (hereinafter referred to as 'T&C') apply to the use of the mobile application 'CulinaChef (CulinaAI)' (hereinafter 'App') by consumers within the meaning of Section 13 of the German Civil Code (BGB).")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Anbieter und Vertragspartner des Nutzers ist:" : "Provider and Contractual Partner:")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ContactInfo(label: isGerman ? "Unternehmen" : "Company", value: "CulinaAI")
                            ContactInfo(label: isGerman ? "Vertreten durch" : "Represented by", value: "Moritz Serrin")
                            ContactInfo(label: isGerman ? "Adresse" : "Address", value: "Sonnenblumenweg 8, 21244 Buchholz, " + (isGerman ? "Deutschland" : "Germany"))
                            ContactInfo(label: "E-Mail", value: "kontakt@culinaai.com")
                            ContactInfo(label: "Support", value: "support@culinaai.com")
                            ContactInfo(label: "Website", value: "https://culinaai.com")
                        }
                        .padding(12)
                        .background(.white.opacity(0.1))
                        .cornerRadius(10)
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Abweichende, entgegenstehende oder ergänzende Bedingungen des Nutzers werden nicht Vertragsbestandteil, es sei denn, der Anbieter stimmt ihrer Geltung ausdrücklich schriftlich zu." : "Any deviating, conflicting, or supplementary terms and conditions of the user shall not become part of the contract unless the provider expressly agrees to them in writing.")
                    }
                    
                    TermsSection(isGerman ? "2. Vertragsgegenstand und Leistungsbeschreibung" : "2. Subject Matter and Description of Services", icon: "app.badge") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Die App CulinaChef (CulinaAI) ist eine digitale Rezept- und Ernährungs-App, die es Nutzern ermöglicht," : "The CulinaChef (CulinaAI) app is a digital recipe and nutrition app that allows users to:")
                        
                        VStack(alignment: .leading, spacing: 6) {
                            TermsBullet(isGerman ? "eigene Rezepte zu speichern," : "store their own recipes,")
                            TermsBullet(isGerman ? "Ernährungspräferenzen zu verwalten," : "manage dietary preferences,")
                            TermsBullet(isGerman ? "KI-gestützte Rezeptvorschläge zu erhalten (OpenAI GPT-4o-mini)," : "receive AI-based recipe suggestions (OpenAI GPT-4o-mini),")
                            TermsBullet(isGerman ? "Menüs zu planen," : "plan menus, and")
                            TermsBullet(isGerman ? "und über ein optionales Abonnement ('Unlimited') zusätzliche Premium-Funktionen zu nutzen." : "and access additional premium features through an optional subscription ('Unlimited').")
                        }
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Die App steht ausschließlich auf iOS-Geräten (iPhone) über den Apple App Store zur Verfügung." : "The app is available exclusively for iOS devices (iPhone) via the Apple App Store.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Die Nutzung setzt eine vorherige Registrierung oder Anmeldung ('Sign in with Apple') voraus." : "Use of the app requires prior registration or login ('Sign in with Apple').")
                        
                        TermsParagraph(number: "(4)", text: isGerman ? "Der Anbieter behält sich vor, den Funktionsumfang der App im Rahmen technischer oder rechtlicher Weiterentwicklungen anzupassen, soweit dies dem Nutzer zumutbar ist." : "The provider reserves the right to modify the app's functionality within reasonable limits for technical or legal reasons, provided such changes are reasonable for the user.")
                    }
                    
                    TermsSection(isGerman ? "3. Vertragsabschluss" : "3. Conclusion of Contract", icon: "signature") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Der Nutzungsvertrag kommt mit Herunterladen der App und Registrierung eines Nutzerkontos zustande." : "The user agreement is concluded when the app is downloaded and a user account is registered.")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Das Abonnement ('Unlimited') wird ausschließlich über den Apple App Store (In-App-Purchase) abgeschlossen. Der Vertrag über das Abonnement kommt direkt zwischen dem Nutzer und Apple Inc. zustande." : "The Unlimited subscription can only be purchased via the Apple App Store (In-App Purchase). The subscription contract is concluded directly between the user and Apple Inc.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Die Abrechnung, Verlängerung und Kündigung des Abonnements erfolgen ausschließlich über das Apple-Benutzerkonto des Nutzers." : "Billing, renewal, and cancellation of the subscription are handled exclusively via the user's Apple account.")
                    }
                    
                    TermsSection(isGerman ? "4. Registrierung, Konto und Zugangsdaten" : "4. Registration, Account, and Access Data", icon: "person.badge.key") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Zur Nutzung der App ist ein Nutzerkonto erforderlich. Hierfür werden folgende Angaben benötigt:" : "A user account is required to use the app. The following information is needed:")
                        
                        VStack(alignment: .leading, spacing: 6) {
                            TermsBullet(isGerman ? "Benutzername" : "Username")
                            TermsBullet(isGerman ? "E-Mail-Adresse" : "E-mail address")
                            TermsBullet(isGerman ? "Passwort" : "Password")
                        }
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Der Nutzer ist verpflichtet, seine Zugangsdaten geheim zu halten und nicht an Dritte weiterzugeben." : "Users must keep their login credentials confidential and not disclose them to third parties.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Mehrfachkonten, falsche Angaben oder Missbrauch führen zur Sperrung des Kontos." : "Multiple accounts, false information, or misuse may lead to account suspension.")
                        
                        ImportantNote(text: isGerman ? "Die Nutzung ist nur Personen ab 16 Jahren gestattet (§ 8 DSGVO)." : "Use of the app is permitted only for persons aged 16 years or older (Art. 8 GDPR).")
                    }
                    
                    TermsSection(isGerman ? "5. Abonnement, Preise und Zahlungsbedingungen" : "5. Subscription, Prices, and Payment Terms", icon: "creditcard") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Der Basis-Download der App ist kostenlos. Der Zugang zu erweiterten Funktionen erfordert ein monatliches Abonnement ('Unlimited') zum Preis von 5,99 € (inkl. MwSt.)." : "Downloading the app is free of charge. Access to extended features requires a monthly subscription ('Unlimited') at a price of €5.99 (incl. VAT).")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Das Abonnement wird über Apple In-App-Purchase abgeschlossen, abgerechnet und verwaltet. Der Anbieter erhält keine Zahlungsdaten; diese verbleiben bei Apple." : "The subscription is concluded, billed, and managed through Apple In-App Purchase. The provider does not receive or store any payment data; such data remains with Apple.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Das Abonnement verlängert sich automatisch um jeweils einen Monat, wenn es nicht mindestens 24 Stunden vor Ablauf der aktuellen Laufzeit im Apple-Account des Nutzers gekündigt wird." : "The subscription automatically renews for one month unless it is cancelled at least 24 hours before the end of the current term in the user's Apple account.")
                        
                        TermsParagraph(number: "(4)", text: isGerman ? "Eine anteilige Rückerstattung bereits gezahlter Gebühren ist ausgeschlossen, soweit kein gesetzliches Widerrufsrecht besteht." : "Partial refunds of fees already paid are excluded unless a statutory right of withdrawal applies.")
                        
                        TermsParagraph(number: "(5)", text: isGerman ? "Preisänderungen können vom Anbieter vorgenommen werden, gelten jedoch erst ab der nächsten Abonnement-Periode und nur nach vorheriger Information durch Apple." : "The provider may change prices; however, such changes only take effect for the next subscription period and only after prior notification by Apple.")
                    }
                    
                    TermsSection(isGerman ? "6. Widerrufsrecht" : "6. Right of Withdrawal", icon: "arrow.uturn.backward") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Verbraucher haben bei digitalen Inhalten grundsätzlich ein gesetzliches Widerrufsrecht (§ 356 Abs. 5 BGB)." : "Consumers generally have a statutory right of withdrawal for digital content (Section 356(5) BGB).")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Das Widerrufsrecht erlischt jedoch, wenn der Nutzer ausdrücklich zugestimmt hat, dass die Ausführung des Vertrages vor Ablauf der Widerrufsfrist beginnt, und bestätigt, dass er sein Widerrufsrecht dadurch verliert." : "The right of withdrawal expires once the user has expressly consented to the immediate execution of the contract and acknowledged that they thereby lose their right of withdrawal.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Die Widerrufsabwicklung erfolgt ausschließlich über den Apple App Store nach den dort geltenden Richtlinien." : "Withdrawal handling is carried out exclusively via the Apple App Store in accordance with Apple's applicable policies.")
                    }
                    
                    TermsSection(isGerman ? "7. Nutzungsrechte" : "7. Usage Rights", icon: "key") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Der Anbieter räumt dem Nutzer ein einfaches, nicht übertragbares, widerrufliches Nutzungsrecht an der App und deren Inhalten ein." : "The provider grants the user a simple, non-transferable, and revocable right to use the app and its contents.")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Der Nutzer darf die App ausschließlich zu privaten, nicht-kommerziellen Zwecken verwenden." : "The app may only be used for private, non-commercial purposes.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Eine Weitergabe, Vervielfältigung oder öffentliche Zugänglichmachung der Inhalte, insbesondere KI-generierter Rezepte, ist ohne ausdrückliche Zustimmung untersagt." : "Sharing, reproducing, or publicly making available any content — particularly AI-generated recipes — without explicit consent is prohibited.")
                        
                        TermsParagraph(number: "(4)", text: isGerman ? "Bei Verstößen gegen diese Lizenzbedingungen kann das Konto gesperrt oder gelöscht werden." : "Violations of these license terms may result in suspension or deletion of the account.")
                    }
                    
                    TermsSection(isGerman ? "8. Pflichten und Verantwortlichkeiten der Nutzer" : "8. User Obligations and Responsibilities", icon: "checkmark.shield") {
                        Text(isGerman ? L.ui_der_nutzer_verpflichtet_sich.localized : "The user agrees:")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ObligationRow(text: isGerman ? "keine rechtswidrigen, beleidigenden oder diskriminierenden Inhalte zu erstellen oder zu teilen," : "not to create or share unlawful, offensive, or discriminatory content,")
                            ObligationRow(text: isGerman ? "keine Urheberrechte oder Markenrechte Dritter zu verletzen," : "not to infringe third-party copyrights or trademarks,")
                            ObligationRow(text: isGerman ? "keine falschen oder gesundheitsgefährdenden Angaben in Rezepten zu verbreiten," : "not to spread false or health-endangering information in recipes,")
                            ObligationRow(text: isGerman ? "die App nicht missbrauchlich oder automatisiert zu verwenden (z. B. Scraping, Bots)," : "not to misuse or automate the app's functions (e.g., scraping, bots),")
                            ObligationRow(text: isGerman ? "keine sicherheitsrelevanten Funktionen zu umgehen." : "not to bypass security-related features.")
                        }
                        
                        WarningNote(text: isGerman ? "Bei Verstößen kann der Anbieter den Nutzer sperren, Daten löschen oder den Vertrag außerordentlich kündigen." : "In case of violations, the provider may suspend the user, delete data, or terminate the contract without notice.")
                    }
                    
                    TermsSection(isGerman ? "9. KI-Inhalte (OpenAI)" : "9. AI-Generated Content (OpenAI)", icon: "sparkles") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Die App nutzt künstliche Intelligenz (OpenAI GPT-4o-mini) zur Erstellung oder Anpassung von Rezepten und Textvorschlägen." : "The app uses artificial intelligence (OpenAI GPT-4o-mini) to create or adapt recipes and text suggestions.")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Diese Inhalte werden automatisiert generiert und können fehlerhaft, unvollständig oder ungeeignet sein. Der Anbieter übernimmt keine Gewähr für Richtigkeit, Vollständigkeit oder gesundheitliche Eignung der KI-generierten Inhalte." : "Such content is automatically generated and may be inaccurate, incomplete, or unsuitable. The provider assumes no liability for the accuracy, completeness, or health suitability of AI-generated content.")
                        
                        DisclaimerNote(text: isGerman ? "Nutzer sollten Rezepte, Zutaten und Ernährungsempfehlungen stets kritisch prüfen, insbesondere bei Allergien, Unverträglichkeiten oder diätischen Anforderungen." : "Users should always review recipes, ingredients, and nutritional advice critically—especially in cases of allergies, intolerances, or dietary requirements.")
                        
                        // Wichtiger Disclaimer-Box
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
                    
                    TermsSection(isGerman ? "9a. Fair Use Policy für KI-Funktionen" : "9a. Fair Use Policy for AI Functions", icon: "shield.checkered") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Die Nutzung der KI-basierten Funktionen im Rahmen des Premium-Abonnements ('Unlimited') unterliegt der Fair Use Policy des Anbieters. Diese ist integraler Bestandteil dieser AGB und in der App einsehbar." : "Use of AI-based functions within the premium subscription ('Unlimited') is subject to the provider's Fair Use Policy, which forms an integral part of these T&C and is available in the app.")
                        
                        Button(action: { showFairUsePolicy = true }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square")
                                Text(L.legalFairUseLink.localized)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.blue)
                            .padding(.vertical, 8)
                        }
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Zweck der Fair Use Policy ist die Vermeidung von Missbrauch und die Sicherstellung eines fairen und gleichmäßigen Zugangs zu den KI-Diensten für alle Nutzer gemäß § 242 BGB (Treu und Glauben)." : "The purpose of the Fair Use Policy is to prevent abuse and to ensure fair and balanced access to AI services for all users, in accordance with Section 242 BGB (principle of good faith).")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Der Anbieter behält sich vor, bei übermäßiger, missbräuchlicher oder automatisierter Nutzung der KI-Funktionen zeitweise Einschränkungen vorzunehmen oder den Zugang zu sperren." : "The provider reserves the right to temporarily restrict or suspend access in cases of excessive, abusive, or automated use.")
                        
                        TermsParagraph(number: "(4)", text: isGerman ? "Nutzer mit berechtigtem Bedarf an erweiterten Nutzungsgrenzen können unter support@culinaai.com eine Anfrage stellen. Die Bewilligung erfolgt im Ermessen des Anbieters." : "Users with legitimate needs for extended usage limits may request an exception by contacting support@culinaai.com. Approval is at the provider's discretion.")
                        
                        TermsParagraph(number: "(5)", text: isGerman ? "Die Fair Use Policy kann vom Anbieter angepasst werden, um technischen und wirtschaftlichen Entwicklungen Rechnung zu tragen. Nutzer werden über wesentliche Änderungen in der App informiert." : "The Fair Use Policy may be adapted to reflect technical or economic developments. Users will be informed of significant changes via the app.")
                        
                        ImportantNote(text: isGerman ? "Die Fair Use Policy dient dem Schutz der Servicequalität für alle Nutzer und ist nicht als Beschränkung der beworbenen 'Unlimited'-Funktion zu verstehen, sondern als Schutzmaßnahme gegen Missbrauch." : "The Fair Use Policy is designed to protect service quality for all users and does not constitute a limitation of the advertised 'Unlimited' feature but a safeguard against misuse.")
                    }
                    
                    TermsSection(isGerman ? "10. Haftung" : "10. Liability", icon: "exclamationmark.shield") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Der Anbieter haftet unbeschränkt für Schäden aus Vorsatz und grober Fahrlässigkeit sowie bei Verletzung von Leben, Körper oder Gesundheit." : "The provider is fully liable for damages arising from intent and gross negligence, as well as for injury to life, body, or health.")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Bei leichter Fahrlässigkeit haftet der Anbieter nur bei Verletzung einer wesentlichen Vertragspflicht (Kardinalpflicht), deren Erfüllung die ordnungsgemäße Durchführung des Vertrags überhaupt erst ermöglicht." : "In cases of slight negligence, the provider is only liable for breaches of essential contractual obligations ('cardinal obligations'), the fulfillment of which is necessary for proper contract performance.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "In diesen Fällen ist die Haftung auf den vorhersehbaren, typischerweise eintretenden Schaden begrenzt." : "In such cases, liability is limited to the foreseeable, typical damage.")
                        
                        TermsParagraph(number: "(4)", text: isGerman ? "Eine Haftung für gesundheitliche Beeinträchtigungen aufgrund von Rezeptvorschlägen oder Ernährungshinweisen ist ausgeschlossen, soweit keine grobe Fahrlässigkeit oder Vorsatz vorliegt." : "Liability for health impairments resulting from recipe suggestions or nutritional advice is excluded unless caused by gross negligence or intent.")
                        
                        TermsParagraph(number: "(5)", text: isGerman ? "Die Haftung nach dem Produkthaftungsgesetz bleibt unberührt." : "Liability under the German Product Liability Act remains unaffected.")
                    }
                    
                    TermsSection(isGerman ? "11. Datenschutz" : "11. Data Protection", icon: "lock.shield") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Die Verarbeitung personenbezogener Daten ist in unserer separaten Datenschutzerklärung geregelt, die in der App verfügbar ist." : "Processing of personal data is governed by our separate Privacy Policy, available in the app.")
                        
                        Button(action: { showPrivacy = true }) {
                            Text(isGerman ? "Datenschutzerklärung in der App öffnen" : "Open Privacy Policy in App")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .underline()
                        }
                        .padding(.vertical, 4)
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Die Datenschutzerklärung ist nicht Bestandteil dieser AGB, gilt jedoch unabhängig und bindend." : "The Privacy Policy is not part of these T&C but applies independently and bindingly.")
                    }
                    
                    TermsSection(isGerman ? "12. Laufzeit, Kündigung und Account-Löschung" : "12. Term, Termination, and Account Deletion", icon: "person.crop.circle.badge.xmark") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Das Vertragsverhältnis besteht auf unbestimmte Zeit und kann vom Nutzer jederzeit durch Löschung des Accounts in der App beendet werden." : "The contractual relationship is indefinite and may be terminated by the user at any time by deleting the account within the app.")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Bei Kündigung oder Account-Löschung werden alle gespeicherten Inhalte (Rezepte, Präferenzen, Menüs etc.) dauerhaft gelöscht." : "Upon termination or deletion, all stored data (recipes, preferences, menus, etc.) will be permanently deleted.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Das Apple-Abonnement muss separat im Apple-Benutzerkonto gekündigt werden." : "The Apple subscription must be cancelled separately in the user's Apple account.")
                        
                        TermsParagraph(number: "(4)", text: isGerman ? "Der Anbieter kann das Konto fristlos kündigen, wenn der Nutzer gegen diese AGB verstößt oder die App missbrauchlich verwendet." : "The provider may terminate the account without notice in the event of a breach of these T&C or misuse of the app.")
                    }
                    
                    TermsSection(isGerman ? "13. Änderungen der AGB" : "13. Amendments to the T&C", icon: "arrow.triangle.2.circlepath") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Der Anbieter kann diese AGB ändern, wenn sachliche Gründe vorliegen (z. B. Gesetzesänderungen, Funktionsanpassungen)." : "The provider may amend these T&C for valid reasons (e.g., legal changes, functional adjustments).")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Nutzer werden über Änderungen in der App oder per E-Mail informiert. Widerspricht der Nutzer nicht innerhalb von 30 Tagen nach Mitteilung, gelten die Änderungen als akzeptiert." : "Users will be notified of changes via the app or email. If the user does not object within 30 days, the amendments shall be deemed accepted.")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Bei wesentlichen Änderungen, die den Vertragsinhalt betreffen, wird eine ausdrückliche Zustimmung eingeholt." : "For material changes affecting the substance of the contract, explicit consent will be obtained.")
                    }
                    
                    TermsSection(isGerman ? "14. Schlussbestimmungen" : "14. Final Provisions", icon: "building.columns") {
                        TermsParagraph(number: "(1)", text: isGerman ? "Es gilt ausschließlich deutsches Recht unter Ausschluss des UN-Kaufrechts." : "German law shall apply exclusively, excluding the UN Convention on Contracts for the International Sale of Goods (CISG).")
                        
                        TermsParagraph(number: "(2)", text: isGerman ? "Sofern der Nutzer keinen allgemeinen Gerichtsstand in Deutschland hat, ist Gerichtsstand der Sitz des Anbieters (Buchholz, Deutschland)." : "If the user has no general place of jurisdiction in Germany, the place of jurisdiction shall be the provider's registered office (Buchholz, Germany).")
                        
                        TermsParagraph(number: "(3)", text: isGerman ? "Sollten einzelne Bestimmungen dieser AGB unwirksam sein, bleibt die Wirksamkeit der übrigen Bestimmungen unberührt. An ihre Stelle tritt eine Regelung, die dem wirtschaftlichen Zweck der unwirksamen Bestimmung am nächsten kommt." : "Should individual provisions of these T&C be invalid, the remaining provisions shall remain effective. The invalid provision shall be replaced by a valid one that best reflects the intended economic purpose.")
                        
                        TermsParagraph(number: "(4)", text: isGerman ? "Die Vertragssprache ist Deutsch." : "The contract language is German.")
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Summary Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundStyle(.white)
                            Text(isGerman ? L.ui_zusammenfassung.localized : "Summary")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            SummaryRow(label: isGerman ? "App-Name" : "App Name", value: "CulinaChef (CulinaAI)")
                            SummaryRow(label: isGerman ? "Anbieter" : "Provider", value: "CulinaAI – Moritz Serrin")
                            SummaryRow(label: isGerman ? "Preis" : "Price", value: isGerman ? "5,99 €/Monat (Apple In-App-Purchase)" : "€5.99/month (Apple In-App Purchase)")
                            SummaryRow(label: isGerman ? "Kündigung" : "Cancellation", value: isGerman ? "Jederzeit über Apple-Einstellungen" : "Anytime via Apple settings")
                            SummaryRow(label: isGerman ? "Datenschutz" : "Privacy", value: isGerman ? "Keine Werbung, kein Tracking" : "No ads, no tracking")
                            SummaryRow(label: isGerman ? "Mindestalter" : "Minimum Age", value: isGerman ? "16 Jahre" : "16 years")
                            SummaryRow(label: isGerman ? "Haftung" : "Liability", value: isGerman ? "KI-Rezepte nur zur Information" : "AI recipes for informational purposes only")
                        }
                    }
                    .padding(16)
                    .background(.white.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text(L.legalFooterDate.localized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
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
            .navigationTitle(L.legalTermsNavTitle.localized)
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
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showFairUsePolicy) {
            FairUseView()
        }
    }
}

// MARK: - Helper Views
private struct TermsSection<Content: View>: View {
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

private struct TermsParagraph: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 32, alignment: .leading)
            // Check if text contains an email address
            if let emailRange = text.range(of: #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#, options: .regularExpression) {
                let beforeEmail = String(text[..<emailRange.lowerBound])
                let email = String(text[emailRange])
                let afterEmail = String(text[emailRange.upperBound...])
                
                VStack(alignment: .leading, spacing: 0) {
                    if !beforeEmail.isEmpty {
                        Text(beforeEmail)
                            .font(.subheadline)
                            .lineSpacing(5)
                            .foregroundStyle(.white)
                    }
                    if let emailURL = URL(string: "mailto:\(email)") {
                        Link(email, destination: emailURL)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    } else {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    if !afterEmail.isEmpty {
                        Text(afterEmail)
                            .font(.subheadline)
                            .lineSpacing(5)
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text(text)
                    .font(.subheadline)
                    .lineSpacing(5)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct TermsBullet: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
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
            // Check if value is an email address or URL
            if value.contains("@") && value.contains("."), let emailURL = URL(string: "mailto:\(value)") {
                Link(value, destination: emailURL)
                    .font(.caption)
                    .foregroundStyle(.blue)
            } else if value.hasPrefix("https://") || value.hasPrefix("http://"), let url = URL(string: value) {
                Link(value, destination: url)
                    .font(.caption)
                    .foregroundStyle(.blue)
            } else if value.hasPrefix("www."), let url = URL(string: "https://\(value)") {
                Link(value, destination: url)
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

private struct WarningNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
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

private struct DisclaimerNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.white)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .lineSpacing(4)
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

private struct ObligationRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}
