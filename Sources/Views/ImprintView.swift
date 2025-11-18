import SwiftUI

struct ImprintView: View {
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
                            Text(L.legalImprintTitle.localized)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        
                        Text(isGerman ? L.ui_angaben_gemäß_5_tmg.localized : "Information pursuant to § 5 German Telemedia Act (TMG)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
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
                    
                    ImprintSection(isGerman ? "Anbieter" : "Provider", icon: "building.2") {
                        VStack(alignment: .leading, spacing: 6) {
                            ImprintRow(label: isGerman ? "Unternehmen" : "Company", value: "CulinaAI")
                            ImprintRow(label: isGerman ? "Vertreten durch" : "Represented by", value: "Moritz Serrin")
                            ImprintRow(label: isGerman ? "Adresse" : "Address", value: "Sonnenblumenweg 8")
                            ImprintRow(label: "", value: "21244 Buchholz")
                            ImprintRow(label: "", value: isGerman ? "Deutschland" : "Germany")
                        }
                    }
                    
                    ImprintSection(isGerman ? "Kontakt" : "Contact", icon: "envelope") {
                        VStack(alignment: .leading, spacing: 6) {
                            ImprintRow(label: "E-Mail", value: "kontakt@culinaai.com")
                            ImprintRow(label: "Website", value: "www.culinaai.com")
                        }
                    }
                    
                    ImprintSection(isGerman ? "Vertretungsberechtigt" : "Authorized Representative", icon: "person.text.rectangle") {
                        VStack(alignment: .leading, spacing: 6) {
                            ImprintRow(label: isGerman ? "Geschäftsführer" : "Managing Director", value: "Moritz Serrin")
                        }
                    }
                    
                    ImprintSection(isGerman ? "Verantwortlich für den Inhalt" : "Responsible for Content", icon: "doc.text") {
                        Text(isGerman ? "Nach § 55 Abs. 2 RStV:" : "in accordance with § 55 (2) of the German Interstate Broadcasting Treaty (RStV):")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ImprintRow(label: isGerman ? "Name" : "Name", value: "Moritz Serrin")
                            ImprintRow(label: isGerman ? "Adresse" : "Address", value: "Sonnenblumenweg 8")
                            ImprintRow(label: "", value: "21244 Buchholz")
                            ImprintRow(label: "", value: isGerman ? "Deutschland" : "Germany")
                        }
                    }
                    
                    ImprintSection(isGerman ? "EU-Streitschlichtung" : "EU Online Dispute Resolution (ODR)", icon: "scale.3d") {
                        Text(isGerman ? L.ui_die_europäische_kommission_stellt.localized : "The European Commission provides a platform for online dispute resolution (ODR):")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                        
                        Link("https://consumer-redress.ec.europa.eu/dispute-resolution-bodies", 
                             destination: URL(string: "https://consumer-redress.ec.europa.eu/dispute-resolution-bodies")!)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .underline()
                            .padding(.vertical, 4)
                        
                        Text(isGerman ? "Unsere E-Mail-Adresse finden Sie oben im Impressum." : "Our e-mail address can be found above in this legal notice.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                    
                    ImprintSection(isGerman ? "Verbraucherstreitbeilegung" : "Consumer Dispute Resolution", icon: "person.2") {
                        InfoBox(
                            title: isGerman ? "Hinweis" : "Note",
                            content: isGerman ? "Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen." : "We are neither willing nor obliged to participate in dispute resolution proceedings before a consumer arbitration board."
                        )
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
                    .padding(.bottom, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L.legalImprintNavTitle.localized)
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
private struct ImprintSection<Content: View>: View {
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

private struct ImprintRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !label.isEmpty {
                Text(label + ":")
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 120, alignment: .leading)
            } else {
                Spacer()
                    .frame(width: 120)
            }
            // Check if value is an email address or URL
            if value.contains("@") && value.contains("."), let emailURL = URL(string: "mailto:\(value)") {
                Link(value, destination: emailURL)
                    .foregroundStyle(.blue)
                    .font(.subheadline)
            } else if value.hasPrefix("https://") || value.hasPrefix("http://"), let url = URL(string: value) {
                Link(value, destination: url)
                    .foregroundStyle(.blue)
                    .font(.subheadline)
            } else if value.hasPrefix("www."), let url = URL(string: "https://\(value)") {
                Link(value, destination: url)
                    .foregroundStyle(.blue)
                    .font(.subheadline)
            } else {
                Text(value)
                    .foregroundStyle(.white)
                    .font(.subheadline)
            }
            Spacer()
        }
    }
}

private struct InfoBox: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(4)
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
