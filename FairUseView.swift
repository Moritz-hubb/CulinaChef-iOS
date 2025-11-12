import SwiftUI

struct FairUseView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) var dismiss
    
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
                            
                            Text("Nutzungsgrenzen und Missbrauchsschutz")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            HStack(spacing: 16) {
                                Label("Stand: 11.11.2025", systemImage: "calendar")
                                Label("Version 1.0", systemImage: "doc.text")
                            }
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.bottom, 8)
                        
                        Divider().background(.white.opacity(0.3))
                        
                        FairUseSection("1. Zweck dieser Richtlinie", icon: "info.circle") {
                            Text("Diese Fair Use Policy erläutert die Nutzungsgrenzen für KI-gestützte Funktionen in der CulinaChef (CulinaAI) App. Auch wenn das 'Unlimited'-Abonnement unbegrenzte Funktionen bietet, gelten angemessene technische Limits zum Schutz vor Missbrauch und zur Sicherstellung der Verfügbarkeit für alle Nutzer.")
                                .lineSpacing(4)
                                .foregroundStyle(.white)
                        }
                        
                        FairUseSection("2. Geltungsbereich", icon: "scope") {
                            Text("Diese Richtlinie gilt für:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 8) {
                                FairUseBullet("KI-gestützte Rezeptgenerierung")
                                FairUseBullet("KI-Chat (Kulina Assistant)")
                                FairUseBullet("KI-Rezeptanalyse und Anpassungen")
                                FairUseBullet("Automatische Nährwertberechnungen")
                            }
                        }
                        
                        FairUseSection("3. Nutzungsgrenzen", icon: "chart.bar") {
                            Text("Zum Schutz der Systemstabilität und fairen Nutzung gelten folgende technische Limits:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 12)
                            
                            VStack(spacing: 16) {
                                LimitCard(
                                    title: "Tägliches Limit",
                                    limit: "100 Anfragen",
                                    description: "Maximale Anzahl KI-Anfragen pro Tag (00:00 - 23:59 Uhr)",
                                    color: .blue
                                )
                                
                                LimitCard(
                                    title: "Monatliches Limit",
                                    limit: "1.000 Anfragen",
                                    description: "Maximale Anzahl KI-Anfragen pro Kalendermonat",
                                    color: .purple
                                )
                            }
                            
                            InfoNote(text: "Diese Limits gelten pro Benutzerkonto. Ein Zurücksetzen erfolgt automatisch täglich bzw. monatlich.")
                        }
                        
                        FairUseSection("4. Was zählt als Anfrage?", icon: "questionmark.circle") {
                            Text("Als Anfrage gilt:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 6) {
                                FairUseBullet("Jede KI-Rezeptgenerierung")
                                FairUseBullet("Jede Chat-Nachricht an Kulina")
                                FairUseBullet("Jede Rezeptanpassung oder -analyse")
                            }
                            .padding(.bottom, 8)
                            
                            Text("Nicht als Anfrage zählt:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 6) {
                                FairUseBullet("Manuelle Rezepterstellung")
                                FairUseBullet("Speichern und Verwalten von Rezepten")
                                FairUseBullet("Nutzung der Community-Bibliothek")
                                FairUseBullet("Einkaufsliste und Menüplanung")
                            }
                        }
                        
                        FairUseSection("5. Typische Nutzung", icon: "person.fill.checkmark") {
                            Text("Die festgelegten Limits sind großzügig bemessen und decken die typische Nutzung ab:")
                                .foregroundStyle(.white)
                                .padding(.bottom, 12)
                            
                            UsageExample(
                                title: "Beispiel: Durchschnittliche Nutzung",
                                items: [
                                    "3-5 Rezeptgenerierungen pro Tag = 15-25 Anfragen/Tag",
                                    "10-15 Chat-Nachrichten = 10-15 Anfragen/Tag",
                                    "Gesamt: ~20-40 Anfragen/Tag"
                                ]
                            )
                            
                            SuccessNote(text: "Die meisten Nutzer bleiben deutlich unter 50 Anfragen pro Tag und 500 Anfragen pro Monat.")
                        }
                        
                        FairUseSection("6. Was passiert bei Überschreitung?", icon: "exclamationmark.triangle") {
                            Text("Bei Erreichen eines Limits:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 12) {
                                WarningStep(number: "1", text: "KI-Funktionen werden temporär deaktiviert")
                                WarningStep(number: "2", text: "Sie erhalten eine Benachrichtigung in der App")
                                WarningStep(number: "3", text: "Alle anderen Funktionen bleiben verfügbar")
                                WarningStep(number: "4", text: "Nach Zurücksetzung (täglich/monatlich) steht die volle Funktionalität wieder zur Verfügung")
                            }
                            
                            ImportantNote(text: "Ihr Abonnement bleibt aktiv und alle nicht-KI-Funktionen sind weiterhin unbegrenzt nutzbar.")
                        }
                        
                        FairUseSection("7. Missbrauchsschutz", icon: "shield.fill") {
                            Text("Diese Limits dienen dem Schutz vor:")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 4)
                            
                            VStack(spacing: 8) {
                                FairUseBullet("Automatisierten Anfragen (Bots)")
                                FairUseBullet("Missbräuchlicher kommerzieller Nutzung")
                                FairUseBullet("Überlastung der KI-Infrastruktur")
                                FairUseBullet("Unfairer Ressourcennutzung")
                            }
                            
                            LegalNote(text: "Bei wiederholtem Missbrauch oder dem Versuch, diese Limits zu umgehen, behält sich der Anbieter vor, das Konto zu sperren oder den Zugang zu einschränken (gemäß AGB § 8).")
                        }
                        
                        FairUseSection("8. Technische Umsetzung", icon: "gearshape.2") {
                            VStack(alignment: .leading, spacing: 8) {
                                TechDetail(label: "Zählmethode", value: "Server-seitig über API-Gateway")
                                TechDetail(label: "Zurücksetzung (täglich)", value: "Automatisch um 00:00 Uhr (UTC)")
                                TechDetail(label: "Zurücksetzung (monatlich)", value: "Automatisch am 1. des Monats")
                                TechDetail(label: "Transparenz", value: "Aktueller Verbrauch in den App-Einstellungen einsehbar")
                            }
                        }
                        
                        FairUseSection("9. Anpassung der Limits", icon: "slider.horizontal.3") {
                            Text("Der Anbieter behält sich vor, die Nutzungsgrenzen anzupassen:")
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 6) {
                                FairUseBullet("Bei signifikanten Änderungen der KI-Kosten")
                                FairUseBullet("Bei technischen Weiterentwicklungen")
                                FairUseBullet("Zur Optimierung der Nutzererfahrung")
                            }
                            
                            InfoNote(text: "Nutzer werden über wesentliche Änderungen mindestens 30 Tage im Voraus informiert.")
                        }
                        
                        FairUseSection("10. Höhere Limits beantragen", icon: "arrow.up.circle") {
                            Text("Benötigen Sie mehr KI-Anfragen für Ihre Nutzung?")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            Text("In begründeten Ausnahmefällen können Sie höhere Nutzungsgrenzen beantragen:")
                                .foregroundStyle(.white)
                                .padding(.bottom, 12)
                            
                            VStack(spacing: 12) {
                                RequestStep(number: "1", text: "Senden Sie eine E-Mail an support@culinaai.com")
                                RequestStep(number: "2", text: "Beschreiben Sie Ihren Anwendungsfall und geschätzten Bedarf")
                                RequestStep(number: "3", text: "Unser Support-Team prüft Ihre Anfrage individuell")
                                RequestStep(number: "4", text: "Bei Genehmigung werden Ihre Limits angepasst")
                            }
                            
                            ContactCard(
                                email: "support@culinaai.com",
                                subject: "Anfrage: Höhere KI-Nutzungsgrenzen"
                            )
                            
                            InfoNote(text: "Die Freischaltung höherer Limits erfolgt nach Ermessen des Anbieters und ist nicht garantiert. Missbrauch führt zur sofortigen Sperrung.")
                        }
                        
                        FairUseSection("11. Rechtliche Grundlage", icon: "building.columns") {
                            Text("Diese Fair Use Policy ist Bestandteil der Allgemeinen Geschäftsbedingungen (AGB) und ergänzt § 2 (Vertragsgegenstand) sowie § 5 (Abonnement).")
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            LegalBox(
                                title: "Rechtsgrundlage",
                                content: "Die Festlegung angemessener Nutzungsgrenzen erfolgt nach Treu und Glauben (§ 242 BGB) und dient der Aufrechterhaltung eines fairen und stabilen Dienstes für alle Nutzer."
                            )
                        }
                        
                        FairUseSection("12. Kontakt bei Fragen", icon: "envelope") {
                            Text("Bei Fragen zu dieser Richtlinie oder Ihrem Nutzungsverhalten wenden Sie sich bitte an:")
                                .foregroundStyle(.white)
                                .padding(.bottom, 8)
                            
                            ContactCard(
                                email: "support@culinaai.com",
                                subject: "Fair Use Policy Anfrage"
                            )
                        }
                        
                        Divider().background(.white.opacity(0.3))
                            .padding(.vertical, 8)
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("Stand: 11. November 2025")
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
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
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
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            
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
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                Text(email)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
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
