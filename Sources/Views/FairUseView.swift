import SwiftUI

struct FairUseView: View {
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
    
    private func localized(_ german: String, _ french: String, _ spanish: String, _ italian: String, _ english: String) -> String {
        if isGerman { return german }
        if isFrench { return french }
        if isSpanish { return spanish }
        if isItalian { return italian }
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
                            Text(localized("Fair Use Policy", "Politique d'utilisation équitable", "Política de uso justo", "Politica di utilizzo equo", "Fair Use Policy"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text(localized(
                                "Nutzungsgrenzen und Missbrauchsschutz",
                                "Limites d'utilisation et protection contre les abus",
                                "Límites de uso y protección contra abusos",
                                "Limiti di utilizzo e protezione contro gli abusi",
                                "Usage Limits and Abuse Protection"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            
                            HStack(spacing: 16) {
                                Label(localized("Stand: 11.11.2025", "Date: 11.11.2025", "Fecha: 11.11.2025", "Data: 11.11.2025", "Date: November 11, 2025"), systemImage: "calendar")
                                Label(localized("Version: 1.0", "Version: 1.0", "Versión: 1.0", "Versione: 1.0", "Version: 1.0"), systemImage: "doc.text")
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
                        
                        // Section 1: Zweck
                        FairUseSection(localized("1. Zweck dieser Richtlinie", "1. Objectif de cette politique", "1. Propósito de esta política", "1. Scopo di questa politica", "1. Purpose of this Policy"), icon: "target") {
                            Text(localized(
                                "Diese Fair Use Policy erläutert die Nutzungsgrenzen für KI-gestützte Funktionen in der CulinaChef (CulinaAI) App. Auch wenn das 'Unlimited'-Abonnement unbegrenzte Funktionen bietet, gelten angemessene technische Limits zum Schutz vor Missbrauch und zur Sicherstellung der Verfügbarkeit für alle Nutzer.",
                                "Cette politique d'utilisation équitable explique les limites d'utilisation des fonctions basées sur l'IA dans l'application CulinaChef (CulinaAI). Même si l'abonnement 'Unlimited' offre des fonctionnalités illimitées, des limites techniques raisonnables s'appliquent pour protéger contre les abus et assurer la disponibilité pour tous les utilisateurs.",
                                "Esta política de uso justo explica los límites de uso para las funciones basadas en IA en la aplicación CulinaChef (CulinaAI). Aunque la suscripción 'Unlimited' ofrece funcionalidades ilimitadas, se aplican límites técnicos razonables para proteger contra el abuso y garantizar la disponibilidad para todos los usuarios.",
                                "Questa politica di utilizzo equo spiega i limiti di utilizzo per le funzioni basate sull'IA nell'app CulinaChef (CulinaAI). Anche se l'abbonamento 'Unlimited' offre funzionalità illimitate, si applicano limiti tecnici ragionevoli per proteggere contro gli abusi e garantire la disponibilità per tutti gli utenti.",
                                "This Fair Use Policy explains the usage limits for AI-powered functions in the CulinaChef (CulinaAI) app. Even though the 'Unlimited' subscription offers unlimited features, reasonable technical limits apply to protect against abuse and ensure availability for all users."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                        }
                        
                        // Section 2: Geltungsbereich
                        FairUseSection(localized("2. Geltungsbereich", "2. Champ d'application", "2. Alcance", "2. Ambito di applicazione", "2. Scope"), icon: "scope") {
                            Text(localized(
                                "Diese Richtlinie gilt für:",
                                "Cette politique s'applique à :",
                                "Esta política se aplica a:",
                                "Questa politica si applica a:",
                                "This policy applies to:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                FairUseBullet(text: localized(
                                    "KI-gestützte Rezeptgenerierung",
                                    "Génération de recettes basée sur l'IA",
                                    "Generación de recetas basada en IA",
                                    "Generazione di ricette basata sull'IA",
                                    "AI-powered recipe generation"
                                ))
                                FairUseBullet(text: localized(
                                    "KI-Chat (Culina Assistant)",
                                    "Chat IA (Assistant Culina)",
                                    "Chat de IA (Asistente Culina)",
                                    "Chat IA (Assistente Culina)",
                                    "AI Chat (Culina Assistant)"
                                ))
                                FairUseBullet(text: localized(
                                    "KI-Rezeptanalyse und Anpassungen",
                                    "Analyse et adaptation de recettes par IA",
                                    "Análisis y adaptación de recetas por IA",
                                    "Analisi e adattamento delle ricette tramite IA",
                                    "AI recipe analysis and adjustments"
                                ))
                                FairUseBullet(text: localized(
                                    "Automatische Nährwertberechnungen",
                                    "Calculs nutritionnels automatiques",
                                    "Cálculos nutricionales automáticos",
                                    "Calcoli nutrizionali automatici",
                                    "Automatic nutritional calculations"
                                ))
                            }
                        }
                        
                        // Section 3: Nutzungsgrenzen
                        FairUseSection(localized("3. Nutzungsgrenzen", "3. Limites d'utilisation", "3. Límites de uso", "3. Limiti di utilizzo", "3. Usage Limits"), icon: "chart.bar") {
                            Text(localized(
                                "Zum Schutz der Systemstabilität und fairen Nutzung gelten folgende technische Limits:",
                                "Pour protéger la stabilité du système et une utilisation équitable, les limites techniques suivantes s'appliquent :",
                                "Para proteger la estabilidad del sistema y un uso justo, se aplican los siguientes límites técnicos:",
                                "Per proteggere la stabilità del sistema e un utilizzo equo, si applicano i seguenti limiti tecnici:",
                                "To protect system stability and fair usage, the following technical limits apply:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 12)
                            
                            // Daily Limit Box
                            LimitBox(
                                title: localized("Tägliches Limit", "Limite quotidienne", "Límite diario", "Limite giornaliero", "Daily Limit"),
                                limit: localized("100 Anfragen pro Tag", "100 demandes par jour", "100 solicitudes por día", "100 richieste al giorno", "100 requests per day"),
                                description: localized("(00:00 - 23:59 Uhr UTC)", "(00:00 - 23:59 UTC)", "(00:00 - 23:59 UTC)", "(00:00 - 23:59 UTC)", "(00:00 - 23:59 UTC)"),
                                subtitle: localized("Maximale Anzahl KI-Anfragen pro Tag", "Nombre maximum de demandes IA par jour", "Número máximo de solicitudes de IA por día", "Numero massimo di richieste IA al giorno", "Maximum number of AI requests per day")
                            )
                            
                            // Monthly Limit Box
                            LimitBox(
                                title: localized("Monatliches Limit", "Limite mensuelle", "Límite mensual", "Limite mensile", "Monthly Limit"),
                                limit: localized("1.000 Anfragen pro Monat", "1 000 demandes par mois", "1.000 solicitudes por mes", "1.000 richieste al mese", "1,000 requests per month"),
                                description: "",
                                subtitle: localized("Maximale Anzahl KI-Anfragen pro Kalendermonat", "Nombre maximum de demandes IA par mois calendaire", "Número máximo de solicitudes de IA por mes calendario", "Numero massimo di richieste IA per mese calendario", "Maximum number of AI requests per calendar month")
                            )
                            
                            ImportantNote(text: localized(
                                "Hinweis: Diese Limits gelten pro Benutzerkonto. Ein Zurücksetzen erfolgt automatisch täglich bzw. monatlich.",
                                "Remarque : Ces limites s'appliquent par compte utilisateur. Une réinitialisation se produit automatiquement quotidiennement ou mensuellement.",
                                "Nota: Estos límites se aplican por cuenta de usuario. El reinicio se produce automáticamente diariamente o mensualmente.",
                                "Nota: Questi limiti si applicano per account utente. Il ripristino avviene automaticamente quotidianamente o mensilmente.",
                                "Note: These limits apply per user account. Reset occurs automatically daily or monthly."
                            ))
                        }
                        
                        // Section 4: Was zählt als Anfrage?
                        FairUseSection(localized("4. Was zählt als Anfrage?", "4. Qu'est-ce qui compte comme demande ?", "4. ¿Qué cuenta como solicitud?", "4. Cosa conta come richiesta?", "4. What Counts as a Request?"), icon: "questionmark.circle") {
                            Text(localized("Als Anfrage gilt:", "Compte comme demande :", "Cuenta como solicitud:", "Conta come richiesta:", "Counts as a request:"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                FairUseBullet(text: localized(
                                    "Jede KI-Rezeptgenerierung",
                                    "Chaque génération de recette IA",
                                    "Cada generación de receta por IA",
                                    "Ogni generazione di ricetta tramite IA",
                                    "Each AI recipe generation"
                                ))
                                FairUseBullet(text: localized(
                                    "Jede Chat-Nachricht an Culina Assistant",
                                    "Chaque message de chat à l'Assistant Culina",
                                    "Cada mensaje de chat al Asistente Culina",
                                    "Ogni messaggio di chat all'Assistente Culina",
                                    "Each chat message to Culina Assistant"
                                ))
                                FairUseBullet(text: localized(
                                    "Jede Rezeptanpassung oder -analyse",
                                    "Chaque adaptation ou analyse de recette",
                                    "Cada adaptación o análisis de receta",
                                    "Ogni adattamento o analisi della ricetta",
                                    "Each recipe adjustment or analysis"
                                ))
                            }
                            .padding(.bottom, 12)
                            
                            Text(localized("Nicht als Anfrage zählt:", "Ne compte pas comme demande :", "No cuenta como solicitud:", "Non conta come richiesta:", "Does not count as a request:"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                FairUseBullet(text: localized(
                                    "Manuelle Rezepterstellung",
                                    "Création manuelle de recettes",
                                    "Creación manual de recetas",
                                    "Creazione manuale di ricette",
                                    "Manual recipe creation"
                                ))
                                FairUseBullet(text: localized(
                                    "Speichern und Verwalten von Rezepten",
                                    "Enregistrement et gestion des recettes",
                                    "Guardar y gestionar recetas",
                                    "Salvataggio e gestione delle ricette",
                                    "Saving and managing recipes"
                                ))
                                FairUseBullet(text: localized(
                                    "Nutzung der Community-Bibliothek",
                                    "Utilisation de la bibliothèque communautaire",
                                    "Uso de la biblioteca de la comunidad",
                                    "Utilizzo della biblioteca della comunità",
                                    "Using the community library"
                                ))
                                FairUseBullet(text: localized(
                                    "Einkaufsliste und Menüplanung",
                                    "Liste de courses et planification de menus",
                                    "Lista de compras y planificación de menús",
                                    "Lista della spesa e pianificazione del menu",
                                    "Shopping list and menu planning"
                                ))
                            }
                        }
                        
                        // Section 5: Typische Nutzung
                        FairUseSection(localized("5. Typische Nutzung", "5. Utilisation typique", "5. Uso típico", "5. Utilizzo tipico", "5. Typical Usage"), icon: "chart.line.uptrend.xyaxis") {
                            Text(localized(
                                "Die festgelegten Limits sind großzügig bemessen und decken die typische Nutzung ab:",
                                "Les limites fixées sont généreuses et couvrent l'utilisation typique :",
                                "Los límites establecidos son generosos y cubren el uso típico:",
                                "I limiti stabiliti sono generosi e coprono l'utilizzo tipico:",
                                "The established limits are generous and cover typical usage:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            Text(localized("Beispiel: Durchschnittliche Nutzung", "Exemple : Utilisation moyenne", "Ejemplo: Uso promedio", "Esempio: Utilizzo medio", "Example: Average Usage"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                FairUseBullet(text: localized(
                                    "3-5 Rezeptgenerierungen pro Tag = 15-25 Anfragen/Tag",
                                    "3-5 générations de recettes par jour = 15-25 demandes/jour",
                                    "3-5 generaciones de recetas por día = 15-25 solicitudes/día",
                                    "3-5 generazioni di ricette al giorno = 15-25 richieste/giorno",
                                    "3-5 recipe generations per day = 15-25 requests/day"
                                ))
                                FairUseBullet(text: localized(
                                    "10-15 Chat-Nachrichten = 10-15 Anfragen/Tag",
                                    "10-15 messages de chat = 10-15 demandes/jour",
                                    "10-15 mensajes de chat = 10-15 solicitudes/día",
                                    "10-15 messaggi di chat = 10-15 richieste/giorno",
                                    "10-15 chat messages = 10-15 requests/day"
                                ))
                                FairUseBullet(text: localized(
                                    "Gesamt: ~20-40 Anfragen/Tag",
                                    "Total : ~20-40 demandes/jour",
                                    "Total: ~20-40 solicitudes/día",
                                    "Totale: ~20-40 richieste/giorno",
                                    "Total: ~20-40 requests/day"
                                ), isBold: true)
                            }
                            
                            Text(localized(
                                "Die meisten Nutzer bleiben deutlich unter 50 Anfragen pro Tag und 500 Anfragen pro Monat.",
                                "La plupart des utilisateurs restent bien en dessous de 50 demandes par jour et 500 demandes par mois.",
                                "La mayoría de los usuarios se mantienen muy por debajo de 50 solicitudes por día y 500 solicitudes por mes.",
                                "La maggior parte degli utenti rimane ben al di sotto di 50 richieste al giorno e 500 richieste al mese.",
                                "Most users stay well below 50 requests per day and 500 requests per month."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.top, 8)
                        }
                        
                        // Section 6: Was passiert bei Überschreitung?
                        FairUseSection(localized("6. Was passiert bei Überschreitung?", "6. Que se passe-t-il en cas de dépassement ?", "6. ¿Qué sucede si se excede?", "6. Cosa succede in caso di superamento?", "6. What Happens When Limits Are Exceeded?"), icon: "exclamationmark.triangle") {
                            Text(localized(
                                "Bei Erreichen eines Limits:",
                                "Lorsqu'une limite est atteinte :",
                                "Cuando se alcanza un límite:",
                                "Quando viene raggiunto un limite:",
                                "When a limit is reached:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                NumberedBullet(number: "1", text: localized(
                                    "KI-Funktionen werden temporär deaktiviert",
                                    "Les fonctions IA sont temporairement désactivées",
                                    "Las funciones de IA se desactivan temporalmente",
                                    "Le funzioni IA vengono temporaneamente disattivate",
                                    "AI functions are temporarily disabled"
                                ))
                                NumberedBullet(number: "2", text: localized(
                                    "Sie erhalten eine Benachrichtigung in der App",
                                    "Vous recevez une notification dans l'application",
                                    "Recibirá una notificación en la aplicación",
                                    "Riceverai una notifica nell'app",
                                    "You receive a notification in the app"
                                ))
                                NumberedBullet(number: "3", text: localized(
                                    "Alle anderen Funktionen bleiben verfügbar",
                                    "Toutes les autres fonctions restent disponibles",
                                    "Todas las demás funciones permanecen disponibles",
                                    "Tutte le altre funzioni rimangono disponibili",
                                    "All other functions remain available"
                                ))
                                NumberedBullet(number: "4", text: localized(
                                    "Nach Zurücksetzung (täglich/monatlich) steht die volle Funktionalität wieder zur Verfügung",
                                    "Après réinitialisation (quotidienne/mensuelle), la fonctionnalité complète est à nouveau disponible",
                                    "Después del reinicio (diario/mensual), la funcionalidad completa está disponible nuevamente",
                                    "Dopo il ripristino (giornaliero/mensile), la funzionalità completa è nuovamente disponibile",
                                    "After reset (daily/monthly), full functionality is available again"
                                ))
                            }
                            
                            ImportantNote(text: localized(
                                "Wichtig: Ihr Abonnement bleibt aktiv und alle nicht-KI-Funktionen sind weiterhin unbegrenzt nutzbar.",
                                "Important : Votre abonnement reste actif et toutes les fonctions non-IA restent utilisables sans limite.",
                                "Importante: Su suscripción permanece activa y todas las funciones que no son de IA siguen siendo utilizables sin límite.",
                                "Importante: Il tuo abbonamento rimane attivo e tutte le funzioni non-IA rimangono utilizzabili senza limiti.",
                                "Important: Your subscription remains active and all non-AI functions remain unlimited."
                            ))
                        }
                        
                        // Section 7: Missbrauchsschutz
                        FairUseSection(localized("7. Missbrauchsschutz", "7. Protection contre les abus", "7. Protección contra abusos", "7. Protezione contro gli abusi", "7. Abuse Protection"), icon: "shield.checkered") {
                            Text(localized(
                                "Diese Limits dienen dem Schutz vor:",
                                "Ces limites servent à protéger contre :",
                                "Estos límites sirven para proteger contra:",
                                "Questi limiti servono a proteggere contro:",
                                "These limits serve to protect against:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                FairUseBullet(text: localized(
                                    "Automatisierten Anfragen (Bots)",
                                    "Demandes automatisées (bots)",
                                    "Solicitudes automatizadas (bots)",
                                    "Richieste automatizzate (bot)",
                                    "Automated requests (bots)"
                                ))
                                FairUseBullet(text: localized(
                                    "Missbräuchlicher kommerzieller Nutzung",
                                    "Utilisation commerciale abusive",
                                    "Uso comercial abusivo",
                                    "Utilizzo commerciale abusivo",
                                    "Abusive commercial use"
                                ))
                                FairUseBullet(text: localized(
                                    "Überlastung der KI-Infrastruktur",
                                    "Surcharge de l'infrastructure IA",
                                    "Sobrecarga de la infraestructura de IA",
                                    "Sovraccarico dell'infrastruttura IA",
                                    "Overloading of AI infrastructure"
                                ))
                                FairUseBullet(text: localized(
                                    "Unfairer Ressourcennutzung",
                                    "Utilisation injuste des ressources",
                                    "Uso injusto de recursos",
                                    "Utilizzo ingiusto delle risorse",
                                    "Unfair resource usage"
                                ))
                            }
                            
                            WarningNote(text: localized(
                                "Rechtlicher Hinweis: Bei wiederholtem Missbrauch oder dem Versuch, diese Limits zu umgehen, behält sich der Anbieter vor, das Konto zu sperren oder den Zugang zu einschränken (gemäß AGB § 8).",
                                "Avis juridique : En cas d'abus répété ou de tentative de contournement de ces limites, le fournisseur se réserve le droit de bloquer le compte ou de restreindre l'accès (conformément aux CGU § 8).",
                                "Aviso legal: En caso de abuso repetido o intento de eludir estos límites, el proveedor se reserva el derecho de bloquear la cuenta o restringir el acceso (según T&C § 8).",
                                "Avviso legale: In caso di abuso ripetuto o tentativo di aggirare questi limiti, il fornitore si riserva il diritto di bloccare l'account o limitare l'accesso (secondo T&C § 8).",
                                "Legal Notice: In case of repeated abuse or attempts to circumvent these limits, the provider reserves the right to block the account or restrict access (according to T&C § 8)."
                            ))
                        }
                        
                        // Section 8: Technische Umsetzung
                        FairUseSection(localized("8. Technische Umsetzung", "8. Mise en œuvre technique", "8. Implementación técnica", "8. Implementazione tecnica", "8. Technical Implementation"), icon: "gearshape.2") {
                            VStack(alignment: .leading, spacing: 8) {
                                FairUseBullet(
                                    title: localized("Zählmethode:", "Méthode de comptage:", "Método de conteo:", "Metodo di conteggio:", "Counting method:"),
                                    text: localized("Server-seitig über API-Gateway", "Côté serveur via passerelle API", "Del lado del servidor a través de la puerta de enlace API", "Lato server tramite gateway API", "Server-side via API gateway")
                                )
                                FairUseBullet(
                                    title: localized("Zurücksetzung (täglich):", "Réinitialisation (quotidienne):", "Reinicio (diario):", "Ripristino (giornaliero):", "Reset (daily):"),
                                    text: localized("Automatisch um 00:00 Uhr (UTC)", "Automatiquement à 00h00 (UTC)", "Automáticamente a las 00:00 (UTC)", "Automaticamente alle 00:00 (UTC)", "Automatically at 00:00 (UTC)")
                                )
                                FairUseBullet(
                                    title: localized("Zurücksetzung (monatlich):", "Réinitialisation (mensuelle):", "Reinicio (mensual):", "Ripristino (mensile):", "Reset (monthly):"),
                                    text: localized("Automatisch am 1. des Monats", "Automatiquement le 1er du mois", "Automáticamente el día 1 del mes", "Automaticamente il giorno 1 del mese", "Automatically on the 1st of the month")
                                )
                                FairUseBullet(
                                    title: localized("Transparenz:", "Transparence:", "Transparencia:", "Trasparenza:", "Transparency:"),
                                    text: localized("Aktueller Verbrauch in den App-Einstellungen einsehbar", "Consommation actuelle visible dans les paramètres de l'application", "Consumo actual visible en la configuración de la aplicación", "Consumo attuale visibile nelle impostazioni dell'app", "Current usage visible in app settings")
                                )
                            }
                        }
                        
                        // Section 9: Anpassung der Limits
                        FairUseSection(localized("9. Anpassung der Limits", "9. Ajustement des limites", "9. Ajuste de límites", "9. Adeguamento dei limiti", "9. Adjustment of Limits"), icon: "arrow.triangle.2.circlepath") {
                            Text(localized(
                                "Der Anbieter behält sich vor, die Nutzungsgrenzen anzupassen:",
                                "Le fournisseur se réserve le droit d'ajuster les limites d'utilisation :",
                                "El proveedor se reserva el derecho de ajustar los límites de uso:",
                                "Il fornitore si riserva il diritto di adeguare i limiti di utilizzo:",
                                "The provider reserves the right to adjust usage limits:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                FairUseBullet(text: localized(
                                    "Bei signifikanten Änderungen der KI-Kosten",
                                    "En cas de modifications significatives des coûts IA",
                                    "En caso de cambios significativos en los costos de IA",
                                    "In caso di modifiche significative dei costi IA",
                                    "In case of significant changes in AI costs"
                                ))
                                FairUseBullet(text: localized(
                                    "Bei technischen Weiterentwicklungen",
                                    "En cas d'évolutions techniques",
                                    "En caso de avances técnicos",
                                    "In caso di evoluzioni tecniche",
                                    "In case of technical developments"
                                ))
                                FairUseBullet(text: localized(
                                    "Zur Optimierung der Nutzererfahrung",
                                    "Pour optimiser l'expérience utilisateur",
                                    "Para optimizar la experiencia del usuario",
                                    "Per ottimizzare l'esperienza utente",
                                    "To optimize user experience"
                                ))
                            }
                            
                            ImportantNote(text: localized(
                                "Information: Nutzer werden über wesentliche Änderungen mindestens 30 Tage im Voraus informiert.",
                                "Information : Les utilisateurs seront informés des modifications importantes au moins 30 jours à l'avance.",
                                "Información: Los usuarios serán informados de cambios importantes con al menos 30 días de anticipación.",
                                "Informazione: Gli utenti saranno informati di modifiche importanti con almeno 30 giorni di anticipo.",
                                "Information: Users will be informed of significant changes at least 30 days in advance."
                            ))
                        }
                        
                        // Section 10: Höhere Limits beantragen
                        FairUseSection(localized("10. Höhere Limits beantragen", "10. Demander des limites plus élevées", "10. Solicitar límites más altos", "10. Richiedere limiti più elevati", "10. Request Higher Limits"), icon: "arrow.up.circle") {
                            Text(localized(
                                "Benötigen Sie mehr KI-Anfragen für Ihre Nutzung?",
                                "Avez-vous besoin de plus de demandes IA pour votre utilisation ?",
                                "¿Necesita más solicitudes de IA para su uso?",
                                "Hai bisogno di più richieste IA per il tuo utilizzo?",
                                "Do you need more AI requests for your usage?"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                            
                            Text(localized(
                                "In begründeten Ausnahmefällen können Sie höhere Nutzungsgrenzen beantragen:",
                                "Dans des cas exceptionnels justifiés, vous pouvez demander des limites d'utilisation plus élevées :",
                                "En casos excepcionales justificados, puede solicitar límites de uso más altos:",
                                "In casi eccezionali giustificati, puoi richiedere limiti di utilizzo più elevati:",
                                "In justified exceptional cases, you can request higher usage limits:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            Text(localized("So geht's:", "Voici comment :", "Así es como:", "Ecco come:", "Here's how:"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                NumberedBullet(number: "1", text: localized(
                                    "Senden Sie eine E-Mail an support@culinaai.com",
                                    "Envoyez un e-mail à support@culinaai.com",
                                    "Envíe un correo electrónico a support@culinaai.com",
                                    "Invia un'email a support@culinaai.com",
                                    "Send an email to support@culinaai.com"
                                ))
                                NumberedBullet(number: "2", text: localized(
                                    "Beschreiben Sie Ihren Anwendungsfall und geschätzten Bedarf",
                                    "Décrivez votre cas d'utilisation et vos besoins estimés",
                                    "Describa su caso de uso y necesidades estimadas",
                                    "Descrivi il tuo caso d'uso e le tue esigenze stimate",
                                    "Describe your use case and estimated needs"
                                ))
                                NumberedBullet(number: "3", text: localized(
                                    "Unser Support-Team prüft Ihre Anfrage individuell",
                                    "Notre équipe de support examine votre demande individuellement",
                                    "Nuestro equipo de soporte revisa su solicitud individualmente",
                                    "Il nostro team di supporto esamina la tua richiesta individualmente",
                                    "Our support team reviews your request individually"
                                ))
                                NumberedBullet(number: "4", text: localized(
                                    "Bei Genehmigung werden Ihre Limits angepasst",
                                    "En cas d'approbation, vos limites seront ajustées",
                                    "Si se aprueba, se ajustarán sus límites",
                                    "In caso di approvazione, i tuoi limiti saranno adeguati",
                                    "If approved, your limits will be adjusted"
                                ))
                            }
                            
                            ContactBox(
                                contact: "support@culinaai.com",
                                subject: localized("Anfrage: Höhere KI-Nutzungsgrenzen", "Demande : Limites d'utilisation IA plus élevées", "Solicitud: Límites de uso de IA más altos", "Richiesta: Limiti di utilizzo IA più elevati", "Request: Higher AI Usage Limits"),
                                contactLabel: localized("Kontakt:", "Contact:", "Contacto:", "Contatto:", "Contact:"),
                                subjectLabel: localized("Betreff:", "Objet:", "Asunto:", "Oggetto:", "Subject:")
                            )
                            
                            ImportantNote(text: localized(
                                "Hinweis: Die Freischaltung höherer Limits erfolgt nach Ermessen des Anbieters und ist nicht garantiert. Missbrauch führt zur sofortigen Sperrung.",
                                "Remarque : L'activation de limites plus élevées se fait à la discrétion du fournisseur et n'est pas garantie. L'abus entraîne un blocage immédiat.",
                                "Nota: La activación de límites más altos se realiza a discreción del proveedor y no está garantizada. El abuso resulta en bloqueo inmediato.",
                                "Nota: L'attivazione di limiti più elevati avviene a discrezione del fornitore e non è garantita. L'abuso comporta il blocco immediato.",
                                "Note: Activation of higher limits is at the provider's discretion and not guaranteed. Abuse results in immediate blocking."
                            ))
                        }
                        
                        // Section 11: Rechtliche Grundlage
                        FairUseSection(localized("11. Rechtliche Grundlage", "11. Base juridique", "11. Base legal", "11. Base legale", "11. Legal Basis"), icon: "scale.3d") {
                            Text(localized(
                                "Diese Fair Use Policy ist Bestandteil der Allgemeinen Geschäftsbedingungen (AGB) und ergänzt § 2 (Vertragsgegenstand) sowie § 5 (Abonnement).",
                                "Cette politique d'utilisation équitable fait partie des conditions générales (CGU) et complète le § 2 (Objet du contrat) ainsi que le § 5 (Abonnement).",
                                "Esta política de uso justo es parte de los términos y condiciones (T&C) y complementa el § 2 (Objeto del contrato) y el § 5 (Suscripción).",
                                "Questa politica di utilizzo equo fa parte dei termini e condizioni (T&C) e integra il § 2 (Oggetto del contratto) e il § 5 (Abbonamento).",
                                "This Fair Use Policy is part of the Terms and Conditions (T&C) and supplements § 2 (Subject Matter) and § 5 (Subscription)."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                            .padding(.bottom, 8)
                            
                            ImportantNote(text: localized(
                                "Rechtsgrundlage: Die Festlegung angemessener Nutzungsgrenzen erfolgt nach Treu und Glauben (§ 242 BGB) und dient der Aufrechterhaltung eines fairen und stabilen Dienstes für alle Nutzer.",
                                "Base juridique : L'établissement de limites d'utilisation raisonnables se fait selon la bonne foi (§ 242 BGB) et sert à maintenir un service équitable et stable pour tous les utilisateurs.",
                                "Base legal: El establecimiento de límites de uso razonables se realiza de buena fe (§ 242 BGB) y sirve para mantener un servicio justo y estable para todos los usuarios.",
                                "Base legale: L'istituzione di limiti di utilizzo ragionevoli avviene secondo la buona fede (§ 242 BGB) e serve a mantenere un servizio equo e stabile per tutti gli utenti.",
                                "Legal basis: The establishment of reasonable usage limits is done in good faith (§ 242 BGB) and serves to maintain a fair and stable service for all users."
                            ))
                        }
                        
                        // Section 12: Kontakt bei Fragen
                        FairUseSection(localized("12. Kontakt bei Fragen", "12. Contact pour questions", "12. Contacto para preguntas", "12. Contatto per domande", "12. Contact for Questions"), icon: "envelope.badge") {
                            Text(localized(
                                "Bei Fragen zu dieser Richtlinie oder Ihrem Nutzungsverhalten wenden Sie sich bitte an:",
                                "Pour toute question concernant cette politique ou votre comportement d'utilisation, veuillez nous contacter :",
                                "Para preguntas sobre esta política o su comportamiento de uso, contáctenos:",
                                "Per domande su questa politica o il tuo comportamento di utilizzo, contattaci:",
                                "For questions about this policy or your usage behavior, please contact us:"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                            
                            ContactBox(
                                contact: "support@culinaai.com",
                                subject: localized("Fair Use Policy Anfrage", "Demande de politique d'utilisation équitable", "Solicitud de política de uso justo", "Richiesta di politica di utilizzo equo", "Fair Use Policy Request"),
                                contactLabel: localized("Kontakt:", "Contact:", "Contacto:", "Contatto:", "Contact:"),
                                subjectLabel: localized("Betreff:", "Objet:", "Asunto:", "Oggetto:", "Subject:")
                            )
                        }
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text(localized("Stand: 11. November 2025 | Version 1.0", "Date: 11 novembre 2025 | Version 1.0", "Fecha: 11 de noviembre de 2025 | Versión 1.0", "Data: 11 novembre 2025 | Versione 1.0", "Date: November 11, 2025 | Version 1.0"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text(localized(
                                "Bei Fragen kontaktieren Sie uns: support@culinaai.com",
                                "Pour toute question, contactez-nous : support@culinaai.com",
                                "Para preguntas, contáctenos: support@culinaai.com",
                                "Per domande, contattaci: support@culinaai.com",
                                "For questions, contact us: support@culinaai.com"
                            ))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Fair Use Policy")
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
private struct FairUseSection<Content: View>: View {
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

private struct FairUseBullet: View {
    let title: String?
    let text: String
    let isBold: Bool
    
    init(title: String? = nil, text: String, isBold: Bool = false) {
        self.title = title
        self.text = text
        self.isBold = isBold
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 2) {
                if let title = title {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Text(text)
                    .font(isBold ? .subheadline.weight(.bold) : .subheadline)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}

private struct NumberedBullet: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, alignment: .leading)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct LimitBox: View {
    let title: String
    let limit: String
    let description: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(limit)
                .font(.title3.bold())
                .foregroundStyle(.white)
            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
        )
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
                .foregroundStyle(.orange)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
        )
    }
}

private struct ContactBox: View {
    let contact: String
    let subject: String
    let contactLabel: String
    let subjectLabel: String
    
    init(contact: String, subject: String, contactLabel: String = "Kontakt:", subjectLabel: String = "Betreff:") {
        self.contact = contact
        self.subject = subject
        self.contactLabel = contactLabel
        self.subjectLabel = subjectLabel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(contactLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                if let emailURL = URL(string: "mailto:\(contact)") {
                    Link(contact, destination: emailURL)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                } else {
                    Text(contact)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            HStack {
                Text(subjectLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subject)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .background(.white.opacity(0.1))
        .cornerRadius(10)
    }
}
