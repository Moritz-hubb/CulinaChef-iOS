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
                                isGerman ? "Ihre Zutaten und Anfragen werden an OpenAI (USA) gesendet" : "Your ingredients and requests are sent to OpenAI (USA)",
                                isGerman ? "OpenAI generiert personalisierte Rezepte basierend auf Ihren Eingaben" : "OpenAI generates personalized recipes based on your inputs",
                                isGerman ? "Speicherdauer bei OpenAI: maximal 30 Tage" : "Storage duration at OpenAI: maximum 30 days"
                            ]
                        )
                        
                        InfoSection(
                            title: isGerman ? "Was wird NICHT übermittelt?" : "What is NOT transmitted?",
                            items: [
                                isGerman ? "Keine personenbezogenen Daten (Name, E-Mail, etc.)" : "No personal data (name, email, etc.)",
                                isGerman ? "Keine Zahlungsinformationen" : "No payment information",
                                isGerman ? "Kein Tracking oder Profiling" : "No tracking or profiling"
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
                    
                    Button {
                        onDecline()
                        dismiss()
                    } label: {
                        Text(isGerman ? "Ablehnen" : "Decline")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
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

// MARK: - Storage for consent status
enum OpenAIConsentManager {
    private static let consentKeyPrefix = "openai_consent_granted_"
    
    // Generate user-specific key to prevent cache bleeding
    private static func consentKey(for userId: String) -> String {
        return "\(consentKeyPrefix)\(userId)"
    }
    
    static var hasConsent: Bool {
        get {
            // Get consent for current user only
            guard let userId = KeychainManager.get(key: "user_id") else {
                return false // No user logged in = no consent
            }
            return UserDefaults.standard.bool(forKey: consentKey(for: userId))
        }
        set {
            // Set consent for current user only
            guard let userId = KeychainManager.get(key: "user_id") else {
                print("[OpenAIConsent] Cannot save consent: no user_id")
                return
            }
            UserDefaults.standard.set(newValue, forKey: consentKey(for: userId))
            print("[OpenAIConsent] Consent set to \(newValue) for user \(userId)")
        }
    }
    
    static func resetConsent() {
        guard let userId = KeychainManager.get(key: "user_id") else {
            print("[OpenAIConsent] Cannot reset consent: no user_id")
            return
        }
        UserDefaults.standard.removeObject(forKey: consentKey(for: userId))
        print("[OpenAIConsent] Reset consent for user \(userId)")
    }
}

#Preview {
    OpenAIConsentDialog(
        onAccept: { print("Accepted") },
        onDecline: { print("Declined") }
    )
}
