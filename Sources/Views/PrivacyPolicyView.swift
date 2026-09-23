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
                                Label(localized("Stand: 14.09.2026", "Date: 14.09.2026", "Date: September 14, 2026"), systemImage: "calendar")
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
                                    title: localized("Keine In-App-Werbung:", "Pas de publicité in-app:", "No in-app ads:"),
                                    text: localized(
                                        "Wir zeigen keine Banner, Interstitials oder Tracker von Werbenetzwerken in der App. Kampagnen können über Apple Search Ads im App Store geschaltet werden.",
                                        "Nous n'affichons pas de bannières, d'interstitiels ni de trackers de réseaux publicitaires dans l'app. Des campagnes peuvent être diffusées via Apple Search Ads dans l'App Store.",
                                        "We do not show banners, interstitials, or ad-network trackers in the app. Campaigns may run via Apple Search Ads in the App Store."
                                    )
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
                                DataCategory(
                                    title: localized("Apple Search Ads", "Apple Search Ads", "Apple Search Ads"),
                                    description: localized(
                                        "Ob die App über eine Apple-Search-Ads-Kampagne im App Store installiert wurde (Kampagnen-Attribution, ohne geräteübergreifendes Tracking).",
                                        "Si l'app a été installée via une campagne Apple Search Ads dans l'App Store (attribution de campagne, sans suivi inter-apps).",
                                        "Whether the app was installed from an Apple Search Ads campaign in the App Store (campaign attribution, without cross-app tracking)."
                                    )
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
                                    title: localized("Datenportabilität (Art. 20 DSGVO)", "Droit à la portabilité (art. 20 RGPD)", "Data portability (Art. 20 GDPR)", spanish: "Portabilidad (art. 20 RGPD)", italian: "Portabilità (art. 20 GDPR)"),
                                    description: localized(
                                        "Unter Einstellungen können Sie eine JSON-Datei laden. Sie enthält E-Mail, Name, Benutzername, Allergien, Ernährungsweise, Geschmack, Abneigungen, Notizen und Rezepte.",
                                        "Dans Réglages, vous pouvez télécharger un fichier JSON : e-mail, nom, nom d'utilisateur, allergies, régime, goûts, aversions, notes et recettes.",
                                        "In Settings you can download a JSON file with your email, name, username, allergies, diet, taste, dislikes, notes, and recipes.",
                                        spanish: "En Ajustes puede descargar un JSON con correo, nombre, usuario, alergias, dieta, sabor, aversiones, notas y recetas.",
                                        italian: "In Impostazioni potete scaricare un JSON con email, nome, nome utente, allergie, dieta, gusti, avversioni, note e ricette."
                                    )
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
                                "Konto, Profil, E-Mail, Rezepte, Fotos und Ernährungsdaten werden gelöscht, sobald Sie das Konto in der App löschen. Der Chat bleibt nur im Arbeitsspeicher und wird nicht auf dem Server gespeichert. Absturzberichte bei Sentry enthalten keine E-Mail und keine Nutzer-ID und werden nach 30 Tagen gelöscht. Datenbank-Sicherungen liegen 7 Tage und werden nicht genutzt, um ein gelöschtes Konto zurückzuholen. Vom Löschvorgang bleibt 3 Jahre nur ein Hash der Nutzer-ID, der Zeitpunkt und dass Sie die Löschung ausgelöst haben.",
                                "Le compte, le profil, l'e-mail, les recettes, les photos et les données alimentaires sont supprimés dès que vous supprimez le compte dans l'app. Le chat reste uniquement en mémoire et n'est pas enregistré sur le serveur. Les rapports Sentry ne contiennent ni e-mail ni identifiant et sont supprimés après 30 jours. Les sauvegardes de la base durent 7 jours et ne servent pas à rétablir un compte supprimé. De la suppression, il ne reste pendant 3 ans qu'un hash de l'identifiant, l'heure, et le fait que vous l'avez demandée.",
                                "Your account, profile, email, recipes, photos, and dietary data are deleted as soon as you delete the account in the app. Chat stays in memory only and is not stored on the server. Sentry crash reports contain no email and no user id and are deleted after 30 days. Database backups are kept for 7 days and are not used to bring a deleted account back. For 3 years, the only deletion record is a hash of the user id, the time, and that you requested deletion.",
                                spanish: "La cuenta, el perfil, el correo, las recetas, las fotos y los datos alimentarios se eliminan en cuanto elimina la cuenta en la app. El chat solo está en memoria y no se guarda en el servidor. Los informes de Sentry no incluyen correo ni id de usuario y se borran a los 30 días. Las copias de la base duran 7 días y no se usan para recuperar una cuenta eliminada. De la eliminación solo queda, durante 3 años, un hash del id, la hora y que usted la pidió.",
                                italian: "Account, profilo, email, ricette, foto e dati alimentari vengono eliminati appena eliminate l'account nell'app. La chat resta solo in memoria e non è salvata sul server. I report Sentry non contengono email né id utente e vengono eliminati dopo 30 giorni. I backup del database durano 7 giorni e non servono a ripristinare un account eliminato. Della cancellazione resta, per 3 anni, solo un hash dell'id, l'ora e il fatto che l'avete richiesta."
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
                        
                        PrivacySection(localized("9. Werbung und Tracking", "9. Publicité et suivi", "9. Advertising and Tracking", spanish: "9. Publicidad y seguimiento", italian: "9. Pubblicità e tracciamento"), icon: "hand.raised") {
                            Text(localized(
                                "Wir können Apple Search Ads nutzen, also Werbung im App Store. Dafür wird Apples AdServices-Attribution verwendet, um zu messen, welche Kampagne zu einer Installation oder einem Abo geführt hat. Es gibt keinen App-Tracking-Transparency-Dialog, weil wir keine Daten mit anderen Unternehmen für geräteübergreifendes Tracking teilen und keine Werbe-IDs (IDFA) auslesen. In der App selbst verzichten wir auf:",
                                "Nous pouvons utiliser Apple Search Ads, c'est-à-dire de la publicité dans l'App Store. L'attribution AdServices d'Apple mesure quelle campagne a mené à une installation ou un abonnement. Il n'y a pas de demande App Tracking Transparency, car nous ne partageons pas de données avec d'autres entreprises pour un suivi inter-apps et nous ne lisons pas d'identifiants publicitaires (IDFA). Dans l'app elle-même, nous n'utilisons pas:",
                                "We may use Apple Search Ads, which is advertising in the App Store. Apple's AdServices attribution measures which campaign led to an install or subscription. There is no App Tracking Transparency prompt, because we do not share data with other companies for cross-app tracking and we do not read advertising identifiers (IDFA). Inside the app we do not use:",
                                spanish: "Podemos usar Apple Search Ads, es decir, anuncios en el App Store. La atribución AdServices de Apple mide qué campaña llevó a una instalación o suscripción. No hay aviso de App Tracking Transparency porque no compartimos datos con otras empresas para seguimiento entre apps ni leemos identificadores publicitarios (IDFA). Dentro de la app no usamos:",
                                italian: "Possiamo usare Apple Search Ads, cioè pubblicità nell'App Store. L'attribuzione AdServices di Apple misura quale campagna ha portato a un'installazione o a un abbonamento. Non c'è la richiesta App Tracking Transparency perché non condividiamo dati con altre aziende per il tracciamento tra app e non leggiamo identificatori pubblicitari (IDFA). Nell'app non usiamo:"
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
                                        "In-App-Werbung, Werbenetzwerke (z. B. AdMob) oder Profilbildung",
                                        "Publicité in-app, réseaux publicitaires (p. ex. AdMob) ou profilage d'utilisateurs",
                                        "In-app advertising, ad networks (e.g. AdMob), or user profiling",
                                        spanish: "Publicidad in-app, redes publicitarias (p. ej. AdMob) o perfilado de usuarios",
                                        italian: "Pubblicità in-app, reti pubblicitarie (es. AdMob) o profilazione utenti"
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
                                        "Alle gespeicherten Rezepte und Menüs",
                                        "Toutes les recettes et menus sauvegardés",
                                        "All saved recipes and menus",
                                        spanish: "Todas las recetas y menús guardados",
                                        italian: "Tutte le ricette e i menu salvati"
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
                                        "Bewertungen, Favoriten und Meldungen",
                                        "Évaluations, favoris et signalements",
                                        "Ratings, favorites, and reports",
                                        spanish: "Valoraciones, favoritos e informes",
                                        italian: "Valutazioni, preferiti e segnalazioni"
                                    )
                                )
                                DataCategory(
                                    title: "",
                                    description: localized(
                                        "Rezeptfotos und lokal gespeicherte Daten (z. B. Einkaufsliste)",
                                        "Photos de recettes et données locales (p. ex. liste de courses)",
                                        "Recipe photos and locally stored data (e.g. shopping list)",
                                        spanish: "Fotos de recetas y datos locales (p. ej. lista de la compra)",
                                        italian: "Foto delle ricette e dati locali (p. es. lista della spesa)"
                                    )
                                )
                            }
                            .padding(.bottom, 12)
                            
                            ImportantNote(text: localized(
                                "Wichtig: Apple-Abonnements müssen separat in der Apple-ID-Verwaltung gekündigt werden. Es bleibt 3 Jahre nur ein Hash der Nutzer-ID. Eine Sicherung kann das Konto noch bis zu 7 Tage enthalten und wird nicht zur Wiederherstellung eines gelöschten Kontos verwendet. Die Löschung ist endgültig.",
                                "Important : les abonnements Apple doivent être annulés séparément dans les réglages de l'identifiant Apple. Pendant 3 ans, il ne reste qu'un hash de l'identifiant. Une sauvegarde peut encore contenir le compte jusqu'à 7 jours et n'est pas utilisée pour le rétablir. La suppression est définitive.",
                                "Important: Cancel Apple subscriptions separately in your Apple ID settings. For 3 years only a hash of the user id remains. A backup may still contain the account for up to 7 days and is not used to restore it. Deletion is permanent.",
                                spanish: "Importante: cancele las suscripciones de Apple por separado en los ajustes del Apple ID. Durante 3 años solo queda un hash del id. Una copia puede contener la cuenta hasta 7 días y no se usa para restaurarla. La eliminación es definitiva.",
                                italian: "Importante: annullate gli abbonamenti Apple separatamente nelle impostazioni dell'ID Apple. Per 3 anni resta solo un hash dell'id. Un backup può contenere l'account fino a 7 giorni e non viene usato per ripristinarlo. La cancellazione è definitiva."
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
