import SwiftUI

struct OpenAIConsentDialog: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var showPrivacy = false
    
    private var isGerman: Bool {
        localizationManager.currentLanguage == "de"
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismiss on background tap
                }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                    
                    Text(isGerman ? "KI-Funktionen nutzen" : "Use AI Features")
                        .font(.title2.bold())
                    
                    Text(isGerman ? "Einwilligung zur Datenverarbeitung" : "Consent for Data Processing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            title: isGerman ? "Was passiert mit Ihren Daten?" : "What happens with your data?",
                            items: [
                                isGerman ? "Anfragen können personenbezogene Daten sein: Chattexte, Rezeptinhalte, Bilder, Ernährungs- und Allergieangaben sowie Import-Metadaten" : "Requests can be personal data: chat text, recipe content, images, diet and allergy details, and import metadata",
                                isGerman ? "Diese Inhalte werden zur KI-Antwort an OpenAI gesendet. Das Standardziel von OpenAI liegt in den USA. Ein Vertrag über Standardvertragsklauseln oder das Data Privacy Framework wird hier nicht behauptet" : "This content is sent to OpenAI to produce the AI reply. OpenAI’s default location is the USA. This dialog does not claim that standard contractual clauses or the Data Privacy Framework are in place",
                                isGerman ? "Zahlungsdaten der Apple-ID werden nicht an OpenAI gesendet" : "Apple ID payment details are not sent to OpenAI"
                            ]
                        )
                        
                        InfoSection(
                            title: isGerman ? "Widerruf und Speicherdauer" : "Withdrawal and retention",
                            items: [
                                isGerman ? "Die Einwilligung kannst du in den Einstellungen widerrufen. Danach starten keine neuen KI-Anfragen" : "You can withdraw consent in Settings. New AI requests then do not start",
                                isGerman ? "Bereits gesendete Anfragen bleiben davon unberührt" : "Requests already sent are not undone",
                                isGerman ? "Wie lange OpenAI Inhalte speichert, steht nur fest, wenn es im OpenAI-Konto des Anbieters nachgesehen wurde. Diese Angabe ist noch offen" : "How long OpenAI keeps content is known only after checking the provider’s OpenAI account. That figure is still open"
                            ]
                        )
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isGerman ? "Rechtsgrundlage" : "Legal Basis")
                                .font(.footnote.bold())
                            
                            Text(isGerman ? 
                                "Ihre Einwilligung gemäß Art. 49 Abs. 1 lit. a DSGVO für die Datenübermittlung in ein Drittland (USA)." :
                                "Your consent according to Art. 49 para. 1 lit. a GDPR for data transfer to a third country (USA).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isGerman ? "Widerruf" : "Withdrawal")
                                .font(.footnote.bold())
                            
                            Text(isGerman ?
                                "Sie können Ihre Einwilligung jederzeit in den App-Einstellungen widerrufen. Dies hat keine Auswirkung auf bereits durchgeführte Verarbeitungen." :
                                "You can withdraw your consent at any time in the app settings. This does not affect processing that has already taken place.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Privacy link
                        Button {
                            showPrivacy = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text(isGerman ? "Vollständige Datenschutzerklärung" : "Full Privacy Policy")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .font(.footnote)
                            .foregroundColor(.blue)
                        }
                        .accessibilityLabel(L.a11y_fullPrivacyPolicy.localized)
                        .accessibilityHint(L.a11y_openFullPrivacy.localized)
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        onAccept()
                        dismiss()
                    } label: {
                        Text(isGerman ? "Zustimmen und fortfahren" : "Accept and Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel(L.a11y_acceptAndContinue.localized)
                    .accessibilityHint(L.a11y_acceptConsentHint.localized)
                    
                    Button {
                        onDecline()
                        dismiss()
                    } label: {
                        Text(isGerman ? "Ablehnen" : "Decline")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel(L.a11y_decline.localized)
                    .accessibilityHint(L.a11y_declineConsentHint.localized)
                    
                    Text(isGerman ?
                        "Ohne Zustimmung können KI-Funktionen nicht genutzt werden." :
                        "AI features cannot be used without consent.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(24)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(maxWidth: 500, maxHeight: 700)
            .padding(.horizontal, 40)
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
}

private struct InfoSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.bold())
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    OpenAIConsentDialog(
        onAccept: { Logger.debug("[OpenAIConsentDialog] Accepted", category: .ui) },
        onDecline: { Logger.debug("[OpenAIConsentDialog] Declined", category: .ui) }
    )
}
