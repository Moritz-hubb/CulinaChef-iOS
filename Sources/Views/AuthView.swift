import SwiftUI

struct AuthView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showImprint = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.5, blue: 0.3),
                        Color(red: 0.85, green: 0.4, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Welcome Screen
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Penguin illustration
                    if let uiImage = UIImage(named: "penguin-auth") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: showSignUp || showSignIn ? 120 : 240, 
                                   height: showSignUp || showSignIn ? 120 : 240)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSignUp || showSignIn)
                    } else {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: showSignUp || showSignIn ? 80 : 160))
                            .foregroundColor(.white)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSignUp || showSignIn)
                    }
                    
                    Spacer().frame(height: 40)
                    
                    // Title
                    Text(L.auth_letsGetStarted.localized)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Sign Up Button
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showSignUp = true
                            showSignIn = false
                        }
                    } label: {
                        Text(L.signUp.localized)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2))
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 32)
                    
                    // Sign In link
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showSignIn = true
                            showSignUp = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(L.auth_alreadyHaveAccount.localized)
                                .foregroundColor(.white.opacity(0.9))
                            Text(L.auth_signInButton.localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 15))
                    }
                    .padding(.top, 20)
                    
                    // Legal links
                    HStack(spacing: 12) {
                        Button(action: { showTerms = true }) {
                            Text(L.auth_termsOfService.localized)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .underline()
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Button(action: { showPrivacy = true }) {
                            Text(L.auth_privacyPolicy.localized)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .underline()
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Button(action: { showImprint = true }) {
                            Text(L.auth_imprint.localized)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .underline()
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 50)
                }
                .opacity(showSignUp || showSignIn ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: showSignUp || showSignIn)
            }
            .fullScreenCover(isPresented: $showSignUp, onDismiss: {
                showSignUp = false
            }) {
                SignUpView()
            }
            .fullScreenCover(isPresented: $showSignIn, onDismiss: {
                showSignIn = false
            }) {
                SignInView()
            }
            .sheet(isPresented: $showTerms) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showImprint) {
                ImprintView()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Legal Placeholder View
private struct LegalPlaceholderView: View {
    let title: String
    let text: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(text)
                        .font(.body)
                        .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.done.localized) { dismiss() }
                }
            }
        }
    }
}
