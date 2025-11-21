import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var appleNonce: String?
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                // Top illustration section
                VStack(spacing: 8) {
                    Spacer().frame(height: 40)
                    
                    // Penguin illustration - smaller
                    if let uiImage = UIImage(named: "penguin-auth") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .accessibilityHidden(true)
                    }
                    
                    Text(L.ui_willkommen_zurück.localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer().frame(height: 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // White card with form
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        // Close button
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            .accessibilityLabel(L.cancel.localized)
                            .accessibilityHint("Schließt den Anmeldebildschirm")
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                        Text(L.auth_signInButton.localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.email.localized)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                                
                            TextField("", text: $email, prompt: Text(L.emailPlaceholder.localized).foregroundColor(.gray.opacity(0.5)))
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                                .accessibilityLabel(L.email.localized)
                                .accessibilityHint(L.emailPlaceholder.localized)
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(focusedField == .email ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.password.localized)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            HStack {
                                if showPassword {
                                    TextField("", text: $password, prompt: Text(L.passwordPlaceholderDots.localized).foregroundColor(.gray.opacity(0.5)))
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit { Task { await signIn() } }
                                        .accessibilityLabel(L.password.localized)
                                } else {
                                    SecureField("", text: $password, prompt: Text(L.passwordPlaceholderDots.localized).foregroundColor(.gray.opacity(0.5)))
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit { Task { await signIn() } }
                                        .accessibilityLabel(L.password.localized)
                                }
                                
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                                .accessibilityLabel(showPassword ? "Passwort verbergen" : "Passwort anzeigen")
                            }
                            .padding(12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(focusedField == .password ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                            )
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                Text(error)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Sign In Button
                        Button {
                            Task { await signIn() }
                        } label: {
                            HStack {
                                if app.loading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(L.loginButton.localized)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .accessibilityLabel(app.loading ? L.loading.localized : L.loginButton.localized)
                        .accessibilityHint("Meldet sich mit E-Mail und Passwort an")
                        .disabled(app.loading || email.isEmpty || password.isEmpty)
                        .opacity((app.loading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                        
                        // Divider with "Or"
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text(L.or.localized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)
                        
                        // Forgot Password Button
                        Button {
                            showForgotPassword = true
                        } label: {
                            Text(L.forgotPassword.localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .accessibilityLabel(L.forgotPassword.localized)
                        .accessibilityHint("Öffnet den Passwort-Reset-Bildschirm")
                        .padding(.top, 8)
                        
                        // Apple Sign In (original button - uses system language)
                        SignInWithAppleButton(.signIn, onRequest: { request in
                                // Prepare nonce for replay protection
                                let nonce = randomNonceString()
                                self.appleNonce = nonce
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            }, onCompletion: { result in
                                switch result {
                                case .success(let authResult):
                                    if let credential = authResult.credential as? ASAuthorizationAppleIDCredential,
                                       let tokenData = credential.identityToken,
                                       let idToken = String(data: tokenData, encoding: .utf8) {
                                        // Extract full name if available (only provided on first sign in)
                                        let fullName: String?
                                        if let givenName = credential.fullName?.givenName,
                                           let familyName = credential.fullName?.familyName {
                                            fullName = "\(givenName) \(familyName)"
                                        } else if let givenName = credential.fullName?.givenName {
                                            fullName = givenName
                                        } else {
                                            fullName = nil
                                        }
                                        Task { await handleAppleSignIn(idToken: idToken, fullName: fullName) }
                                    } else {
                                        self.errorMessage = L.errorAppleTokenInvalid.localized
                                    }
                                case .failure(let error):
                                    // Handle Apple Sign In errors with better messages
                                    let nsError = error as NSError
                                    let errorCode = nsError.code
                                    let errorDomain = nsError.domain
                                    
                                    // Check for simulator/device-specific errors
                                    if errorDomain == "AKAuthenticationError" || errorDomain.contains("AuthenticationServices") {
                                        #if targetEnvironment(simulator)
                                        self.errorMessage = "Sign in with Apple funktioniert nicht im Simulator. Bitte teste auf einem echten Gerät."
                                        #else
                                        // Real device errors
                                        if errorCode == -7022 || errorCode == -7071 {
                                            self.errorMessage = "Apple Sign In Fehler. Bitte versuche es erneut oder melde dich mit E-Mail an."
                                        } else {
                                            self.errorMessage = error.localizedDescription.isEmpty ? "Apple Sign In fehlgeschlagen. Bitte versuche es erneut." : error.localizedDescription
                                        }
                                        #endif
                                    } else {
                                        self.errorMessage = error.localizedDescription.isEmpty ? "Anmeldung fehlgeschlagen" : error.localizedDescription
                                    }
                                }
                            })
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 44)
                        .frame(maxWidth: 375) // Prevent constraint conflicts
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(app)
        }
        .id(localizationManager.currentLanguage) // Force re-render on language change
    }
    
    private func signIn() async {
        errorMessage = nil
        focusedField = nil
        
        // Validate input before sending to backend
        let trimmedEmail = email.trimmed
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = String.validationError(for: .required)
            return
        }
        
        guard trimmedEmail.isValidEmail else {
            errorMessage = String.validationError(for: .email)
            return
        }
        
        guard password.isValidPassword else {
            errorMessage = String.validationError(for: .password)
            return
        }
        
        do {
            try await app.signIn(email: trimmedEmail, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleAppleSignIn(idToken: String, fullName: String? = nil) async {
        do {
            try await app.signInWithApple(idToken: idToken, nonce: appleNonce, fullName: fullName)
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }
    
    // MARK: - Nonce utilities
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                Logger.error("Unable to generate nonce. SecRandomCopyBytes failed with status: \(status)", category: .auth)
                // Fallback: Use timestamp-based nonce as last resort
                return String(format: "%08x%08x", UInt32(Date().timeIntervalSince1970), arc4random())
            }
            for random in randoms {
                if remainingLength == 0 { break }
                result.append(charset[Int(random % UInt8(charset.count))])
                remainingLength -= 1
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    SignInView()
        .environmentObject(AppState())
}
