import SwiftUI

struct ImprintView: View {
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
                            Text(localized("Impressum", "Mentions légales", "Aviso legal", "Note legali", "Legal Notice (Impressum)"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text(localized(
                                "Angaben gemäß § 5 TMG",
                                "Informations selon § 5 TMG",
                                "Información según § 5 TMG",
                                "Informazioni secondo § 5 TMG",
                                "Information pursuant to § 5 German Telemedia Act (TMG)"
                            ))
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
                        
                        // Anbieter Section
                        ImprintSection(localized("Anbieter", "Fournisseur", "Proveedor", "Fornitore", "Provider"), icon: "building.2") {
                            VStack(alignment: .leading, spacing: 4) {
                                ContactInfo(label: localized("Unternehmen:", "Entreprise:", "Empresa:", "Azienda:", "Company:"), value: "CulinaAI")
                                ContactInfo(label: localized("Vertreten durch:", "Représentée par:", "Representado por:", "Rappresentato da:", "Represented by:"), value: "Moritz Serrin")
                                ContactInfo(label: localized("Adresse:", "Adresse:", "Dirección:", "Indirizzo:", "Address:"), value: "Sonnenblumenweg 8\n21244 Buchholz\n" + localized("Deutschland", "Allemagne", "Alemania", "Germania", "Germany"))
                            }
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Kontakt Section
                        ImprintSection(localized("Kontakt", "Contact", "Contacto", "Contatto", "Contact"), icon: "envelope") {
                            VStack(alignment: .leading, spacing: 4) {
                                ContactInfo(label: "E-Mail:", value: "kontakt@culinaai.com")
                                ContactInfo(label: localized("Website:", "Site web:", "Sitio web:", "Sito web:", "Website:"), value: "www.culinaai.com")
                            }
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Vertretungsberechtigt Section
                        ImprintSection(localized("Vertretungsberechtigt", "Représentant autorisé", "Representante autorizado", "Rappresentante autorizzato", "Authorized Representative"), icon: "person.badge.shield.checkmark") {
                            VStack(alignment: .leading, spacing: 4) {
                                ContactInfo(label: localized("Geschäftsführer:", "Directeur général:", "Director general:", "Direttore generale:", "Managing Director:"), value: "Moritz Serrin")
                            }
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Verantwortlich für den Inhalt Section
                        ImprintSection(localized("Verantwortlich für den Inhalt", "Responsable du contenu", "Responsable del contenido", "Responsabile del contenuto", "Responsible for Content"), icon: "doc.text") {
                            Text(localized(
                                "Nach § 55 Abs. 2 RStV:",
                                "Selon § 55 Abs. 2 RStV:",
                                "Según § 55 Abs. 2 RStV:",
                                "Secondo § 55 Abs. 2 RStV:",
                                "in accordance with § 55 (2) of the German Interstate Broadcasting Treaty (RStV):"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ContactInfo(label: localized("Name:", "Nom:", "Nombre:", "Nome:", "Name:"), value: "Moritz Serrin")
                                ContactInfo(label: localized("Adresse:", "Adresse:", "Dirección:", "Indirizzo:", "Address:"), value: "Sonnenblumenweg 8\n21244 Buchholz\n" + localized("Deutschland", "Allemagne", "Alemania", "Germania", "Germany"))
                            }
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // EU-Streitschlichtung
                        InfoBox(
                            title: localized("EU-Streitschlichtung", "Règlement des litiges UE", "Resolución de litigios de la UE", "Risoluzione delle controversie UE", "EU Online Dispute Resolution (ODR)"),
                            icon: "globe.europe.africa"
                        ) {
                            Text(localized(
                                "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit:",
                                "La Commission européenne fournit une plateforme de règlement en ligne des litiges (OS):",
                                "La Comisión Europea proporciona una plataforma de resolución de litigios en línea (OS):",
                                "La Commissione europea fornisce una piattaforma per la risoluzione online delle controversie (OS):",
                                "The European Commission provides a platform for online dispute resolution (ODR):"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                            .padding(.bottom, 8)
                            
                            if let url = URL(string: "https://consumer-redress.ec.europa.eu/dispute-resolution-bodies") {
                                Link("https://consumer-redress.ec.europa.eu/dispute-resolution-bodies", destination: url)
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .underline()
                            }
                            
                            Text(localized(
                                "Unsere E-Mail-Adresse finden Sie oben im Impressum.",
                                "Notre adresse e-mail se trouve ci-dessus dans les mentions légales.",
                                "Nuestra dirección de correo electrónico se encuentra arriba en el aviso legal.",
                                "Il nostro indirizzo email si trova sopra nelle note legali.",
                                "Our e-mail address can be found above in this legal notice."
                            ))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, 8)
                        }
                        
                        // Verbraucherstreitbeilegung
                        InfoBox(
                            title: localized("Verbraucherstreitbeilegung", "Règlement des litiges consommateurs", "Resolución de litigios de consumidores", "Risoluzione delle controversie dei consumatori", "Consumer Dispute Resolution"),
                            icon: "scale.3d"
                        ) {
                            Text(localized(
                                "Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.",
                                "Nous ne sommes pas disposés ou obligés de participer à des procédures de règlement des litiges devant un organisme de médiation des consommateurs.",
                                "No estamos dispuestos ni obligados a participar en procedimientos de resolución de litigios ante un organismo de resolución de disputas de consumidores.",
                                "Non siamo disposti né obbligati a partecipare a procedure di risoluzione delle controversie davanti a un organismo di risoluzione delle controversie dei consumatori.",
                                "We are neither willing nor obliged to participate in dispute resolution proceedings before a consumer arbitration board."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(5)
                        }
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text(localized("Stand: 04. November 2025 | Version 1.0", "Date: 04 novembre 2025 | Version 1.0", "Fecha: 04 de noviembre de 2025 | Versión 1.0", "Data: 04 novembre 2025 | Versione 1.0", "Date: November 4, 2025 | Version 1.0"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
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
                    .accessibilityLabel(L.done.localized)
                    .accessibilityHint(L.legalCloseHint.localized)
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

private struct ContactInfo: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 110, alignment: .leading)
            if value.contains("@") && value.contains("."), let emailURL = URL(string: "mailto:\(value)") {
                Link(value, destination: emailURL)
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

private struct InfoBox<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.3), lineWidth: 1.5)
        )
    }
}
