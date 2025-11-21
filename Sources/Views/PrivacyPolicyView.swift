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
    
    private var isSpanish: Bool {
        localizationManager.currentLanguage == "es"
    }
    
    private var isItalian: Bool {
        localizationManager.currentLanguage == "it"
    }
    
    private func localized(_ german: String, _ french: String, _ english: String, spanish: String? = nil, italian: String? = nil) -> String {
        if isGerman { return german }
        if isFrench { return french }
        if isSpanish { return spanish ?? english }
        if isItalian { return italian ?? english }
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
                                "für die App \"CulinaAI\"",
                                "pour l'application \"CulinaAI\"",
                                "for the app \"CulinaAI\""
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
                        
                        PrivacySection(localized("9. Keine Werbung oder Tracking", "9. Pas de publicité ou de suivi", "9. No Advertising or Tracking", spanish: "9. Sin publicidad ni seguimiento", italian: "9. Nessuna pubblicità o tracciamento"), icon: "hand.raised") {
                            Text(localized(
                                "Wir verzichten vollständig auf:",
                                "Nous nous abstenons complètement d'utiliser:",
                                "We strictly refrain from using:",
                                spanish: "Nos abstenemos completamente de usar:",
                                italian: "Ci asteniamo completamente dall'usare:"
                            ))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                PrivacyBullet(
                                    title: "",
                                    text: localized(
                                        "Cookies oder ähnliche Tracking-Technologien",
                                        "Cookies ou technologies de suivi similaires",
                                        "Cookies or similar tracking technologies",
                                        spanish: "Cookies o tecnologías de seguimiento similares",
                                        italian: "Cookie o tecnologie di tracciamento simili"
                                    )
                                )
                                PrivacyBullet(
                                    title: "",
                                    text: localized(
                                        "Google Analytics oder vergleichbare Analysedienste",
                                        "Google Analytics ou outils d'analyse comparables",
                                        "Google Analytics or comparable analytics tools",
                                        spanish: "Google Analytics o herramientas de análisis comparables",
                                        italian: "Google Analytics o strumenti di analisi comparabili"
                                    )
                                )
                                PrivacyBullet(
                                    title: "",
                                    text: localized(
                                        "Werbung, Werbenetzwerke oder Profilbildung",
                                        "Publicité, réseaux publicitaires ou profilage d'utilisateurs",
                                        "Advertising, ad networks, or user profiling",
                                        spanish: "Publicidad, redes publicitarias o perfilado de usuarios",
                                        italian: "Pubblicità, reti pubblicitarie o profilazione utenti"
                                    )
                                )
                                PrivacyBullet(
                                    title: "",
                                    text: localized(
                                        "Social-Media-Plugins oder externe Tracker",
                                        "Plugins de réseaux sociaux ou trackers externes",
                                        "Social media plugins or external trackers",
                                        spanish: "Plugins de redes sociales o rastreadores externos",
                                        italian: "Plugin di social media o tracker esterni"
                                    )
                                )
                            }
                            
                            ImportantNote(text: localized(
                                "Ihre persönlichen Daten werden niemals an Dritte verkauft oder für Werbezwecke verwendet.",
                                "Vos données personnelles ne seront jamais vendues ou utilisées à des fins publicitaires.",
                                "Your personal data will never be sold or used for advertising purposes.",
                                spanish: "Sus datos personales nunca se venderán ni se usarán con fines publicitarios.",
                                italian: "I vostri dati personali non saranno mai venduti o utilizzati a fini pubblicitari."
                            ))
                        }
                        
                        PrivacySection(localized("10. Kontolöschung", "10. Suppression du compte", "10. Account Deletion", spanish: "10. Eliminación de cuenta", italian: "10. Cancellazione account"), icon: "trash") {
                            Text(localized(
                                "Sie können Ihr Konto jederzeit in den Einstellungen vollständig löschen.",
                                "Vous pouvez supprimer votre compte à tout moment dans les paramètres.",
                                "You can delete your account at any time in the settings.",
                                spanish: "Puede eliminar su cuenta en cualquier momento siguiendo estos pasos:",
                                italian: "Potete eliminare il vostro account in qualsiasi momento seguendo questi passaggi:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 12)
                            
                            Text(localized("Löschung durchführen:", "Procédure de suppression:", "To delete your account:", spanish: "Para eliminar su cuenta:", italian: "Per eliminare il vostro account:"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                PrivacyBullet(
                                    title: "1.",
                                    text: localized(
                                        "Öffnen Sie die Einstellungen in der App",
                                        "Ouvrez les paramètres dans l'application",
                                        "Open Settings in the app",
                                        spanish: "Abra Configuración en la app",
                                        italian: "Aprite Impostazioni nell'app"
                                    )
                                )
                                PrivacyBullet(
                                    title: "2.",
                                    text: localized(
                                        "Wählen Sie 'Konto löschen'",
                                        "Sélectionnez 'Supprimer le compte'",
                                        "Select 'Delete Account'",
                                        spanish: "Seleccione 'Eliminar cuenta'",
                                        italian: "Selezionate 'Elimina account'"
                                    )
                                )
                                PrivacyBullet(
                                    title: "3.",
                                    text: localized(
                                        "Bestätigen Sie die Löschung",
                                        "Confirmez la suppression",
                                        "Confirm the deletion",
                                        spanish: "Confirme la eliminación",
                                        italian: "Confermate la cancellazione"
                                    )
                                )
                            }
                            .padding(.bottom, 12)
                            
                            Text(localized("Folgende Daten werden gelöscht:", "Données supprimées:", "Deleted data include:", spanish: "Los datos eliminados incluyen:", italian: "I dati eliminati includono:"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                DataCategory(
                                    title: "",
                                    description: localized(
                                        "Benutzerkonto und Authentifizierungsdaten",
                                        "Compte utilisateur et données d'authentification",
                                        "User account and authentication data",
                                        spanish: "Cuenta de usuario y datos de autenticación",
                                        italian: "Account utente e dati di autenticazione"
                                    )
                                )
                                DataCategory(
                                    title: "",
                                    description: localized(
                                        "Alle gespeicherten Rezepte, Menüs und Favoriten",
                                        "Toutes les recettes, menus et favoris sauvegardés",
                                        "All saved recipes, menus, and favorites",
                                        spanish: "Todas las recetas, menús y favoritos guardados",
                                        italian: "Tutte le ricette, menu e preferiti salvati"
                                    )
                                )
                                DataCategory(
                                    title: "",
                                    description: localized(
                                        "Ernährungspräferenzen und persönliche Einstellungen",
                                        "Préférences alimentaires et paramètres personnels",
                                        "Dietary preferences and personal settings",
                                        spanish: "Preferencias alimentarias y configuraciones personales",
                                        italian: "Preferenze alimentari e impostazioni personali"
                                    )
                                )
                                DataCategory(
                                    title: "",
                                    description: localized(
                                        "Bewertungen und Notizen",
                                        "Évaluations et notes",
                                        "Ratings and notes",
                                        spanish: "Valoraciones y notas",
                                        italian: "Valutazioni e note"
                                    )
                                )
                            }
                            .padding(.bottom, 12)
                            
                            ImportantNote(text: localized(
                                "Wichtig: Apple-Abonnements müssen separat in der Apple-ID-Verwaltung gekündigt werden. Audit-Protokolle der Löschung werden aus rechtlichen Gründen 3 Jahre aufbewahrt. Die Löschung ist endgültig und kann nicht rückgängig gemacht werden.",
                                "Important: Les abonnements Apple doivent être annulés séparément dans les paramètres de votre compte Apple ID. Les journaux d'audit liés à la suppression sont conservés pendant trois ans. La suppression est permanente et irréversible.",
                                "Important: Apple subscriptions must be cancelled separately in your Apple ID account settings. Audit logs related to the deletion process are retained for three years. Deletion is permanent and irreversible.",
                                spanish: "Importante: Las suscripciones de Apple deben cancelarse por separado en la configuración de su cuenta de Apple ID. Los registros de auditoría relacionados con el proceso de eliminación se conservan durante tres años. La eliminación es permanente e irreversible.",
                                italian: "Importante: Gli abbonamenti Apple devono essere annullati separatamente nelle impostazioni del vostro account Apple ID. I log di audit relativi al processo di cancellazione sono conservati per tre anni. La cancellazione è permanente e irreversibile."
                            ))
                        }
                        
                        PrivacySection(localized("11. Änderungen dieser Datenschutzerklärung", "11. Modifications de cette politique", "11. Changes to This Privacy Policy", spanish: "11. Cambios en esta política de privacidad", italian: "11. Modifiche all'informativa sulla privacy"), icon: "doc.badge.gearshape") {
                            ImportantNote(text: localized(
                                "Wir behalten uns vor, diese Datenschutzerklärung bei rechtlichen oder technischen Änderungen anzupassen. Die jeweils aktuelle Version finden Sie in der App sowie unter https://culinaai.com/datenschutz. Bei wesentlichen Änderungen werden Sie innerhalb der App informiert.",
                                "Nous nous réservons le droit de modifier cette Politique de Confidentialité en cas de changements légaux ou techniques. La version la plus récente est toujours disponible dans l'app et sur https://culinaai.com/datenschutz. Les utilisateurs seront informés de tout changement important dans l'app.",
                                "We reserve the right to amend this Privacy Policy in case of legal or technical changes. The latest version is always available in the app and at https://culinaai.com/datenschutz. Users will be informed of any significant changes within the app.",
                                spanish: "Nos reservamos el derecho de modificar esta Política de Privacidad en caso de cambios legales o técnicos. La versión más reciente está siempre disponible en la app y en https://culinaai.com/datenschutz. Los usuarios serán informados de cualquier cambio significativo dentro de la app.",
                                italian: "Ci riserviamo il diritto di modificare questa Informativa sulla Privacy in caso di modifiche legali o tecniche. La versione più recente è sempre disponibile nell'app e su https://culinaai.com/datenschutz. Gli utenti saranno informati di eventuali modifiche significative nell'app."
                            ))
                        }
                        
                        PrivacySection(localized("12. Kontakt", "12. Contact", "12. Contact", spanish: "12. Contacto", italian: "12. Contatti"), icon: "envelope") {
                            VStack(alignment: .leading, spacing: 12) {
                                ContactInfo(label: localized("Datenschutzanfragen", "Demandes de protection des données", "Data protection inquiries", spanish: "Consultas de protección de datos", italian: "Richieste di protezione dati"), value: "datenschutz@culinaai.com")
                                ContactInfo(label: localized("Technischer Support", "Support technique", "Technical support", spanish: "Soporte técnico", italian: "Supporto tecnico"), value: "support@culinaai.com")
                                ContactInfo(label: localized("Allgemeine Anfragen", "Demandes générales", "General inquiries", spanish: "Consultas generales", italian: "Richieste generali"), value: "kontakt@culinaai.com")
                            }
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        PrivacySection(localized("13. Anwendbares Recht und Gerichtsstand", "13. Droit applicable et juridiction", "13. Applicable Law and Jurisdiction", spanish: "13. Ley aplicable y jurisdicción", italian: "13. Legge applicabile e foro competente"), icon: "scale.3d") {
                            ImportantNote(text: localized(
                                "Für diese Datenschutzerklärung und die Datenverarbeitung gilt ausschließlich deutsches Recht. Gerichtsstand ist Deutschland.",
                                "Cette Politique de Confidentialité et toutes les activités de traitement de données connexes sont régies exclusivement par le droit allemand. Lieu de juridiction: Allemagne.",
                                "This Privacy Policy and all related data processing activities are governed exclusively by German law. Place of jurisdiction: Germany.",
                                spanish: "Esta Política de Privacidad y todas las actividades de procesamiento de datos relacionadas se rigen exclusivamente por la ley alemana. Lugar de jurisdicción: Alemania.",
                                italian: "Questa Informativa sulla Privacy e tutte le attività di trattamento dei dati correlate sono disciplinate esclusivamente dalla legge tedesca. Foro competente: Germania."
                            ))
                            
                            Text(localized("Maßgebliche Rechtsgrundlagen:", "Cadre juridique applicable:", "Applicable legal framework:", spanish: "Marco legal aplicable:", italian: "Quadro giuridico applicabile:"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                PrivacyBullet(
                                    title: localized("DSGVO:", "RGPD:", "GDPR:", spanish: "RGPD:", italian: "GDPR:"),
                                    text: localized(
                                        "Datenschutz-Grundverordnung",
                                        "Règlement Général sur la Protection des Données",
                                        "General Data Protection Regulation",
                                        spanish: "Reglamento General de Protección de Datos",
                                        italian: "Regolamento Generale sulla Protezione dei Dati"
                                    )
                                )
                                PrivacyBullet(
                                    title: localized("BDSG:", "BDSG:", "BDSG:", spanish: "BDSG:", italian: "BDSG:"),
                                    text: localized(
                                        "Bundesdatenschutzgesetz",
                                        "Loi fédérale allemande sur la protection des données",
                                        "Federal Data Protection Act",
                                        spanish: "Ley Federal Alemana de Protección de Datos",
                                        italian: "Legge federale tedesca sulla protezione dei dati"
                                    )
                                )
                                PrivacyBullet(
                                    title: localized("TMG:", "TMG:", "TMG:", spanish: "TMG:", italian: "TMG:"),
                                    text: localized(
                                        "Telemediengesetz",
                                        "Loi sur les télécommunications",
                                        "Telemedia Act",
                                        spanish: "Ley de Telemedios",
                                        italian: "Legge sui servizi di media telematici"
                                    )
                                )
                                PrivacyBullet(
                                    title: localized("UWG:", "UWG:", "UWG:", spanish: "UWG:", italian: "UWG:"),
                                    text: localized(
                                        "Gesetz gegen den unlauteren Wettbewerb",
                                        "Loi contre la concurrence déloyale",
                                        "Act Against Unfair Competition",
                                        spanish: "Ley contra la Competencia Desleal",
                                        italian: "Legge contro la concorrenza sleale"
                                    )
                                )
                                PrivacyBullet(
                                    title: localized("BGB:", "BGB:", "BGB:", spanish: "BGB:", italian: "BGB:"),
                                    text: localized(
                                        "Bürgerliches Gesetzbuch",
                                        "Code civil allemand",
                                        "German Civil Code",
                                        spanish: "Código Civil Alemán",
                                        italian: "Codice civile tedesco"
                                    )
                                )
                            }
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
                    .accessibilityLabel(L.done.localized)
                    .accessibilityHint(L.legalCloseHint.localized)
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
