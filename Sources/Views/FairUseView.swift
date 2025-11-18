import SwiftUI

struct FairUseView: View {
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
                            Text("Fair Use Policy")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text(isGerman ? "Nutzungsgrenzen und Missbrauchsschutz" : "Usage Limits and Abuse Protection")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            HStack(spacing: 16) {
                                Label(isGerman ? "Stand: 11.11.2025" : "Effective Date: Nov 11, 2025", systemImage: "calendar")
                                Label("Version 1.0", systemImage: "doc.text")
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
                        
                        FairUseSection(isGerman ? "1. Zweck dieser Richtlinie" : "1. Purpose of This Policy", icon: "info.circle") {
                            Text(isGerman ? "Diese Fair Use Policy erläutert die Nutzungsgrenzen für KI-gestützte Funktionen in der CulinaChef (CulinaAI) App. Auch wenn das 'Unlimited'-Abonnement unbegrenzte Funktionen bietet, gelten angemessene technische Limits zum Schutz vor Missbrauch und zur Sicherstellung der Verfügbarkeit für alle Nutzer." : "This Fair Use Policy defines reasonable usage limits for AI-powered features within the CulinaChef (CulinaAI) app. While the Unlimited subscription provides unrestricted access in principle, technical limits are applied to prevent misuse and to ensure stable availability for all users.")
                                .lineSpacing(4)
                                .foregroundStyle(.white)
                        }
                        
                        FairUseSection(isGerman ? "2. Geltungsbereich" : "2. Scope of Application", icon: "scope") {
                            Text(isGerman ? "Diese Richtlinie gilt für:" : "This policy applies to the following AI-powered features:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 8) {
                                FairUseBullet(isGerman ? "KI-gestützte Rezeptgenerierung" : "AI-based recipe generation")
                                FairUseBullet(isGerman ? "KI-Chat (Culina Assistant)" : "AI chat (Culina Assistant)")
                                FairUseBullet(isGerman ? "KI-Rezeptanalyse und Anpassungen" : "AI recipe analysis and customization")
                                FairUseBullet(isGerman ? "Automatische Nährwertberechnungen" : "Automatic nutritional calculations")
                            }
                        }
                        
                        FairUseSection(isGerman ? "3. Nutzungsgrenzen" : "3. Usage Limits", icon: "chart.bar") {
                            Text(isGerman ? "Zum Schutz der Systemstabilität und fairen Nutzung gelten folgende technische Limits:" : "To protect system stability and fairness, the following technical limits apply:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 12)
                            
                            VStack(spacing: 16) {
                                LimitCard(
                                    title: isGerman ? "Tägliches Limit" : "Daily Limit",
                                    limit: isGerman ? "100 Anfragen" : "100 requests",
                                    description: isGerman ? "Maximale Anzahl KI-Anfragen pro Tag (00:00 - 23:59 Uhr)" : "Maximum number of AI interactions per day (00:00–23:59 UTC)",
                                    color: .blue
                                )
                                
                                LimitCard(
                                    title: isGerman ? "Monatliches Limit" : "Monthly Limit",
                                    limit: isGerman ? "1.000 Anfragen" : "1,000 requests",
                                    description: isGerman ? "Maximale Anzahl KI-Anfragen pro Kalendermonat" : "Maximum number of AI interactions per month",
                                    color: .purple
                                )
                            }
                            
                            InfoNote(text: isGerman ? "Diese Limits gelten pro Benutzerkonto. Ein Zurücksetzen erfolgt automatisch täglich bzw. monatlich." : "Limits apply per user account. Reset occurs automatically on a daily and monthly basis.")
                        }
                        
                        FairUseSection(isGerman ? "4. Was zählt als Anfrage?" : "4. What Counts as a Request?", icon: "questionmark.circle") {
                            Text(isGerman ? "Als Anfrage gilt:" : "Counts as a request:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 6) {
                                FairUseBullet(isGerman ? "Jede KI-Rezeptgenerierung" : "Each AI recipe generation")
                                FairUseBullet(isGerman ? "Jede Chat-Nachricht an Culina" : "Each chat message sent to Culina Assistant")
                                FairUseBullet(isGerman ? "Jede Rezeptanpassung oder -analyse" : "Each recipe adjustment or analysis")
                            }
                            .padding(.bottom, 8)
                            
                            Text(isGerman ? "Nicht als Anfrage zählt:" : "Does not count as a request:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 6) {
                                FairUseBullet(isGerman ? "Manuelle Rezepterstellung" : "Manual recipe creation")
                                FairUseBullet(isGerman ? "Speichern und Verwalten von Rezepten" : "Saving and managing recipes")
                                FairUseBullet(isGerman ? "Nutzung der Community-Bibliothek" : "Using the community recipe library")
                                FairUseBullet(isGerman ? "Einkaufsliste und Menüplanung" : "Shopping list or meal planning functions")
                            }
                        }
                        
                        FairUseSection(isGerman ? "5. Typische Nutzung" : "5. Typical Usage", icon: "person.fill.checkmark") {
                            Text(isGerman ? "Die festgelegten Limits sind großzügig bemessen und decken die typische Nutzung ab:" : "The defined limits are generous and cover typical usage patterns.")
                                .foregroundStyle(.white)
                                .padding(.bottom, 12)
                            
                            UsageExample(
                                title: isGerman ? "Beispiel: Durchschnittliche Nutzung" : "Example – Average User Activity",
                                items: isGerman ? [
                                    "3-5 Rezeptgenerierungen pro Tag = 15-25 Anfragen/Tag",
                                    "10-15 Chat-Nachrichten = 10-15 Anfragen/Tag",
                                    "Gesamt: ~20-40 Anfragen/Tag"
                                ] : [
                                    "3–5 recipe generations per day = ~15–25 requests/day",
                                    "10–15 chat messages = ~10–15 requests/day",
                                    "Total: ~20–40 requests/day"
                                ]
                            )
                            
                            SuccessNote(text: isGerman ? "Die meisten Nutzer bleiben deutlich unter 50 Anfragen pro Tag und 500 Anfragen pro Monat." : "Most users stay well below 50 requests per day and 500 per month.")
                        }
                        
                        FairUseSection(isGerman ? "6. Was passiert bei Überschreitung?" : "6. What Happens If a Limit Is Reached?", icon: "exclamationmark.triangle") {
                            Text(isGerman ? "Bei Erreichen eines Limits:" : "If a user reaches a limit:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 12) {
                                WarningStep(number: "1", text: isGerman ? "KI-Funktionen werden temporär deaktiviert" : "AI features will be temporarily disabled")
                                WarningStep(number: "2", text: isGerman ? "Sie erhalten eine Benachrichtigung in der App" : "A notification will appear in the app")
                                WarningStep(number: "3", text: isGerman ? "Alle anderen Funktionen bleiben verfügbar" : "All non-AI functions remain fully accessible")
                                WarningStep(number: "4", text: isGerman ? "Nach Zurücksetzung (täglich/monatlich) steht die volle Funktionalität wieder zur Verfügung" : "Full AI functionality is automatically restored after reset")
                            }
                            
                            ImportantNote(text: isGerman ? "Ihr Abonnement bleibt aktiv und alle nicht-KI-Funktionen sind weiterhin unbegrenzt nutzbar." : "Your subscription remains active, and all non-AI features continue to be available without restriction.")
                        }
                        
                        FairUseSection(isGerman ? "7. Missbrauchsschutz" : "7. Abuse Protection", icon: "shield.fill") {
                            Text(isGerman ? "Diese Limits dienen dem Schutz vor:" : "These limits protect against:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 8) {
                                FairUseBullet(isGerman ? "Automatisierten Anfragen (Bots)" : "Automated requests (bots)")
                                FairUseBullet(isGerman ? "Missbräuchlicher kommerzieller Nutzung" : "Misuse for commercial or external purposes")
                                FairUseBullet(isGerman ? "Überlastung der KI-Infrastruktur" : "Overloading of AI infrastructure")
                                FairUseBullet(isGerman ? "Unfairer Ressourcennutzung" : "Unfair resource consumption")
                            }
                            
                            LegalNote(text: isGerman ? "Bei wiederholtem Missbrauch oder dem Versuch, diese Limits zu umgehen, behält sich der Anbieter vor, das Konto zu sperren oder den Zugang zu einschränken (gemäß AGB § 8)." : "In cases of repeated abuse or attempts to bypass these limits, the provider reserves the right to suspend or restrict the account (in accordance with §8 of the Terms of Service).")
                        }
                        
                        FairUseSection(isGerman ? "8. Technische Umsetzung" : "8. Technical Implementation", icon: "gearshape.2") {
                            VStack(alignment: .leading, spacing: 8) {
                                TechDetail(label: isGerman ? "Zählmethode" : "Counting method", value: isGerman ? "Server-seitig über API-Gateway" : "Server-side via API gateway")
                                TechDetail(label: isGerman ? "Zurücksetzung (täglich)" : "Daily reset", value: isGerman ? "Automatisch um 00:00 Uhr (UTC)" : "Automatically at 00:00 UTC")
                                TechDetail(label: isGerman ? "Zurücksetzung (monatlich)" : "Monthly reset", value: isGerman ? "Automatisch am 1. des Monats" : "Automatically on the 1st of each month")
                                TechDetail(label: isGerman ? "Transparenz" : "Transparency", value: isGerman ? "Aktueller Verbrauch in den App-Einstellungen einsehbar" : "Current usage statistics visible in app settings")
                            }
                        }
                        
                        FairUseSection(isGerman ? "9. Anpassung der Limits" : "9. Adjustment of Limits", icon: "slider.horizontal.3") {
                            Text(isGerman ? "Der Anbieter behält sich vor, die Nutzungsgrenzen anzupassen:" : "The provider reserves the right to adjust usage limits:")
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 6) {
                                FairUseBullet(isGerman ? "Bei signifikanten Änderungen der KI-Kosten" : "In case of significant changes to AI infrastructure costs")
                                FairUseBullet(isGerman ? "Bei technischen Weiterentwicklungen" : "Due to technical developments")
                                FairUseBullet(isGerman ? "Zur Optimierung der Nutzererfahrung" : "To improve user experience")
                            }
                            
                            InfoNote(text: isGerman ? "Nutzer werden über wesentliche Änderungen mindestens 30 Tage im Voraus informiert." : "Users will be informed of substantial changes at least 30 days in advance.")
                        }
                        
                        FairUseSection(isGerman ? "10. Höhere Limits beantragen" : "10. Requesting Higher Limits", icon: "arrow.up.circle") {
                            Text(isGerman ? "Benötigen Sie mehr KI-Anfragen für Ihre Nutzung?" : "Need more AI requests for your use case?")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            Text(isGerman ? "In begründeten Ausnahmefällen können Sie höhere Nutzungsgrenzen beantragen:" : "In justified individual cases, users may request higher usage limits:")
                                .foregroundStyle(.white)
                                .padding(.bottom, 12)
                            
                            VStack(spacing: 12) {
                                RequestStep(number: "1", text: isGerman ? "Senden Sie eine E-Mail an support@culinaai.com" : "Send an e-mail to support@culinaai.com")
                                RequestStep(number: "2", text: isGerman ? "Beschreiben Sie Ihren Anwendungsfall und geschätzten Bedarf" : "Include your use case and estimated request volume")
                                RequestStep(number: "3", text: isGerman ? "Unser Support-Team prüft Ihre Anfrage individuell" : "Our support team will review your request individually")
                                RequestStep(number: "4", text: isGerman ? "Bei Genehmigung werden Ihre Limits angepasst" : "If approved, your limits will be adjusted accordingly")
                            }
                            
                            ContactCard(
                                email: "support@culinaai.com",
                                subject: isGerman ? "Anfrage: Höhere KI-Nutzungsgrenzen" : "Request: Higher AI Usage Limits"
                            )
                            
                            InfoNote(text: isGerman ? "Die Freischaltung höherer Limits erfolgt nach Ermessen des Anbieters und ist nicht garantiert. Missbrauch führt zur sofortigen Sperrung." : "Approval of higher limits is at the provider's sole discretion and not guaranteed. Detected misuse will result in immediate suspension of access.")
                        }
                        
                        FairUseSection(isGerman ? "11. Rechtliche Grundlage" : "11. Legal Basis", icon: "building.columns") {
                            Text(isGerman ? "Diese Fair Use Policy ist Bestandteil der Allgemeinen Geschäftsbedingungen (AGB) und ergänzt § 2 (Vertragsgegenstand) sowie § 5 (Abonnement)." : "This Fair Use Policy is part of the Terms of Service and supplements §2 (Subject Matter) and §5 (Subscription).")
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            LegalBox(
                                title: isGerman ? "Rechtsgrundlage" : "Legal Basis",
                                content: isGerman ? "Die Festlegung angemessener Nutzungsgrenzen erfolgt nach Treu und Glauben (§ 242 BGB) und dient der Aufrechterhaltung eines fairen und stabilen Dienstes für alle Nutzer." : "The establishment of reasonable usage limits is based on the principle of good faith (§ 242 BGB) and serves to maintain a fair and stable service for all users."
                            )
                        }
                        
                        FairUseSection(isGerman ? "12. Kontakt bei Fragen" : "12. Contact for Questions", icon: "envelope") {
                            Text(isGerman ? "Bei Fragen zu dieser Richtlinie oder Ihrem Nutzungsverhalten wenden Sie sich bitte an:" : "If you have questions about this policy or your usage, please contact:")
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            ContactCard(
                                email: "support@culinaai.com",
                                subject: isGerman ? "Fair Use Policy Anfrage" : "Fair Use Policy Inquiry"
                            )
                        }
                        
                        Divider().background(.white.opacity(0.3))
                            .padding(.vertical, 8)
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text(isGerman ? "Stand: 11. November 2025" : "Effective Date: November 11, 2025")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("Version 1.0")
                                .font(.caption2)
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
                    Button(isGerman ? "Fertig" : "Done") {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            
            content
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
}

private struct FairUseBullet: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.white)
                .frame(width: 12, alignment: .leading)
            Text(text)
                .foregroundStyle(.white)
            Spacer()
        }
        .font(.subheadline)
    }
}

private struct LimitCard: View {
    let title: String
    let limit: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            Text(limit)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
    }
}

private struct InfoNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(8)
    }
}

private struct SuccessNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.2))
        .cornerRadius(8)
    }
}

private struct ImportantNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(8)
    }
}

private struct LegalNote: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.red)
            Text(text)
                .font(.caption)
                .lineSpacing(3)
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.2))
        .cornerRadius(10)
    }
}

private struct UsageExample: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct WarningStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.orange.opacity(0.3))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
}

private struct RequestStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.3))
                .clipShape(Circle())
            
            // Check if text contains an email address
            if let emailRange = text.range(of: #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#, options: .regularExpression) {
                let beforeEmail = String(text[..<emailRange.lowerBound])
                let email = String(text[emailRange])
                let afterEmail = String(text[emailRange.upperBound...])
                
                VStack(alignment: .leading, spacing: 0) {
                    if !beforeEmail.isEmpty {
                        Text(beforeEmail)
                            .font(.subheadline)
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
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
    }
}

private struct TechDetail: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 160, alignment: .leading)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct LegalBox: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            Text(content)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct ContactCard: View {
    let email: String
    let subject: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                Link(destination: emailURL) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                        Text(email)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                    Text(email)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
            }
            Text("Betreff: \(subject)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}
