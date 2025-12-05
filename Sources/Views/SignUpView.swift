import SwiftUI
import AuthenticationServices
import CryptoKit
import Security

struct SignUpView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage: String?
    @State private var acceptedTerms = false
    @State private var confirmedAge = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @FocusState private var focusedField: Field?
    @State private var showAccountExistsError = false
    var onNavigateToSignIn: (() -> Void)?
    
    enum Field: Hashable {
        case username, email, password, confirmPassword
    }
    
    var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    var passwordStrengthColor: Color {
        if password.isEmpty { return .gray }
        if password.count < 6 { return .red }
        if password.count < 8 { return Color(red: 0.95, green: 0.5, blue: 0.3) }
        return .green
    }
    
    @Environment(\.dismiss) var dismiss
    
    @State private var appleNonce: String? = nil
    
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
                VStack(spacing: 6) {
                    Spacer().frame(height: 30)
                    
                    // Penguin illustration - smaller
                    if let uiImage = UIImage(named: "penguin-auth") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                            .accessibilityHidden(true)
                    }
                    
                    Text(L.letsGetStarted.localized)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer().frame(height: 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
                
                // White card with form
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
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
                            }
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                            Text(L.ui_registrieren.localized)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Username Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L.username.localized)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                            TextField("", text: $username, prompt: Text(L.usernamePlaceholder.localized).foregroundColor(.gray.opacity(0.5)))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .email }
                                .accessibilityLabel(L.username.localized)
                                .accessibilityHint(L.usernamePlaceholder.localized)
                                .padding(10)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .username ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                                )
                            if !usernameWarning.isEmpty {
                                Text(usernameWarning)
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L.email.localized)
                                .font(.system(size: 12, weight: .semibold))
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
                                .padding(10)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .email ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L.password.localized)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            HStack {
                                if showPassword {
                                    TextField("", text: $password, prompt: Text(L.minCharacters.localized).foregroundColor(.gray.opacity(0.5)))
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .confirmPassword }
                                        .accessibilityLabel(L.password.localized)
                                } else {
                                    SecureField("", text: $password, prompt: Text(L.minCharacters.localized).foregroundColor(.gray.opacity(0.5)))
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.next)
                                        .onSubmit { focusedField = .confirmPassword }
                                        .accessibilityLabel(L.password.localized)
                                }
                                
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .accessibilityLabel(showPassword ? "Passwort verbergen" : "Passwort anzeigen")
                            }
                            .padding(10)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .password ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                            )
                            
                            // Password strength indicator
                            if !password.isEmpty {
                                HStack(spacing: 3) {
                                    ForEach(0..<3) { index in
                                        Rectangle()
                                            .fill(index < strengthBars ? passwordStrengthColor : Color.gray.opacity(0.2))
                                            .frame(height: 3)
                                            .cornerRadius(1.5)
                                    }
                                }
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L.ui_passwort_bestätigen.localized)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("", text: $confirmPassword, prompt: Text(L.ui_wiederholen.localized).foregroundColor(.gray.opacity(0.5)))
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .submitLabel(.go)
                                        .onSubmit { Task { await signUp() } }
                                        .accessibilityLabel(L.ui_passwort_bestätigen.localized)
                                } else {
                                    SecureField("", text: $confirmPassword, prompt: Text(L.ui_wiederholen.localized).foregroundColor(.gray.opacity(0.5)))
                                        .textContentType(.newPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .submitLabel(.go)
                                        .onSubmit { Task { await signUp() } }
                                        .accessibilityLabel(L.ui_passwort_bestätigen.localized)
                                }
                                
                                Button { showConfirmPassword.toggle() } label: {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                                .accessibilityLabel(showConfirmPassword ? "Passwort verbergen" : "Passwort anzeigen")
                                
                                if passwordsMatch {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16))
                                        .accessibilityLabel("Passwörter stimmen überein")
                                }
                            }
                            .padding(10)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .confirmPassword ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                            )
                        }
                        
                        // Terms & Privacy Acceptance
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Button(action: { acceptedTerms.toggle() }) {
                                    Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 20))
                                        .foregroundStyle(acceptedTerms ? Color(red: 0.95, green: 0.5, blue: 0.3) : .gray)
                                }
                                .accessibilityLabel(acceptedTerms ? "Nutzungsbedingungen akzeptiert" : "Nutzungsbedingungen akzeptieren")
                                
                                HStack(spacing: 0) {
                                    Text(L.ui_ich_akzeptiere_die.localized)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                    Button(action: { showTerms = true }) {
                                        Text(L.termsOfServiceShort.localized)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                                            .underline()
                                    }
                                    .accessibilityLabel(L.termsOfServiceShort.localized)
                                    .accessibilityHint("Öffnet die Nutzungsbedingungen")
                                    Text(L.ui_und_die.localized)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                    Button(action: { showPrivacy = true }) {
                                        Text(L.ui_datenschutzerklärung_2997.localized)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                                            .underline()
                                    }
                                    .accessibilityLabel(L.ui_datenschutzerklärung_2997.localized)
                                    .accessibilityHint("Öffnet die Datenschutzerklärung")
                                }
                            }
                            
                            // Age Confirmation
                            HStack(alignment: .top, spacing: 10) {
                                Button(action: { confirmedAge.toggle() }) {
                                    Image(systemName: confirmedAge ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 20))
                                        .foregroundStyle(confirmedAge ? Color(red: 0.95, green: 0.5, blue: 0.3) : .gray)
                                }
                                .accessibilityLabel(confirmedAge ? "Altersbestätigung akzeptiert" : "Altersbestätigung akzeptieren")
                                
                                Text(L.ui_ich_bestätige_dass_ich.localized)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        
                        // Error Message
                        if showAccountExistsError {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 5) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 11))
                                    Text(L.errorAccountExists.localized)
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(.red)
                                
                                Button(action: {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onNavigateToSignIn?()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Text(L.errorAccountExistsLoginLink.localized)
                                            .font(.system(size: 11, weight: .semibold))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                                }
                                .accessibilityLabel(L.errorAccountExistsLoginLink.localized)
                                .accessibilityHint("Wechselt zum Anmeldebildschirm")
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                        } else if let error = errorMessage {
                            HStack(spacing: 5) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11))
                                Text(error)
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.red)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        // Sign Up Button
                        Button {
                            Task { await signUp() }
                        } label: {
                            HStack {
                                if app.loading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(L.signUpButton.localized)
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(color: Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel(app.loading ? L.loading.localized : L.signUpButton.localized)
                        .accessibilityHint("Registriert ein neues Konto")
                        .disabled(app.loading || !isFormValid)
                        .opacity((app.loading || !isFormValid) ? 0.6 : 1)
                        
                        // Divider with "Or"
                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 2)
                        
                        // Apple Sign In (original button - uses system language)
                        // NOTE: Apple Sign In remembers if the Apple ID was used before.
                        // After first use, Apple will always show Sign In dialog, even with .signUp.
                        // Our app logic handles this by checking if profile exists after authentication.
                        SignInWithAppleButton(.signUp, onRequest: { request in
                                // Validate that user has accepted terms and privacy
                                guard self.acceptedTerms && self.confirmedAge else {
                                    DispatchQueue.main.async {
                                        self.errorMessage = L.acceptTermsAndPrivacy.localized
                                        self.showAccountExistsError = false
                                    }
                                    return
                                }
                                
                                // Clear any previous error messages
                                DispatchQueue.main.async {
                                    self.errorMessage = nil
                                    self.showAccountExistsError = false
                                }
                                
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
                                        self.errorMessage = "Apple Anmelde-Token ungültig"
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
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                    .background(Color.white)
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
    
    private var strengthBars: Int {
        if password.isEmpty { return 0 }
        if password.count < 6 { return 1 }
        if password.count < 8 { return 2 }
        return 3
    }
    
    private var isFormValid: Bool {
        let uname = username.trimmed
        let trimmedEmail = email.trimmed
        return !uname.isEmpty && uname.isValidUsername &&
        !trimmedEmail.isEmpty && trimmedEmail.isValidEmail &&
        password.isValidPassword && passwordsMatch &&
        acceptedTerms && confirmedAge
    }
    
    private func signUp() async {
        errorMessage = nil
        showAccountExistsError = false
        focusedField = nil
        
        // Validate input before sending to backend
        let uname = username.trimmed
        let trimmedEmail = email.trimmed
        
        guard !uname.isEmpty else {
            errorMessage = String.validationError(for: .required)
            return
        }
        
        guard uname.isValidUsername else {
            errorMessage = String.validationError(for: .username)
            return
        }
        
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
        
        guard passwordsMatch else {
            errorMessage = NSLocalizedString("validation.password.mismatch", value: "Passwörter stimmen nicht überein", comment: "Password mismatch error")
            return
        }
        
        guard acceptedTerms && confirmedAge else {
            errorMessage = NSLocalizedString("validation.terms.required", value: "Bitte akzeptieren Sie die Nutzungsbedingungen", comment: "Terms required error")
            return
        }
        
        do {
            try await app.signUp(
                email: trimmedEmail,
                password: password,
                username: uname
            )
        } catch {
            // Check if it's a 422 error (account already exists) or if error message indicates email exists
            let errorDescription = error.localizedDescription.lowercased()
            let errorCode = (error as NSError).code
            
            // Check for 422 status code or error messages indicating email already exists
            if errorCode == 422 || 
               errorDescription.contains("422") ||
               errorDescription.contains("email") && (errorDescription.contains("already") || 
                                                       errorDescription.contains("exist") || 
                                                       errorDescription.contains("registered") ||
                                                       errorDescription.contains("duplicate") ||
                                                       errorDescription.contains("taken")) {
                showAccountExistsError = true
                errorMessage = nil
            } else {
                showAccountExistsError = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleAppleSignIn(idToken: String, fullName: String? = nil) async {
        do {
            try await app.signInWithApple(idToken: idToken, nonce: appleNonce, fullName: fullName, isSignUp: true)
        } catch {
            let errorDescription = error.localizedDescription.lowercased()
            let errorCode = (error as NSError).code
            let errorDomain = (error as NSError).domain
            
            // Check if it's a 422 error (account already exists)
            // This happens when user tries to sign up but account already exists
            // IMPORTANT: After Apple Sign In is used once (even if it fails), Apple will
            // always show the Sign In dialog, not Sign Up. This is expected Apple behavior.
            // Our app detects this and shows the appropriate error message.
            if errorCode == 422 || 
               errorDomain == "SupabaseAuth" ||
               errorDescription.contains("422") ||
               errorDescription.contains("bereits") ||
               errorDescription.contains("existiert") ||
               (errorDescription.contains("account") && errorDescription.contains("bereits")) {
                await MainActor.run {
                    self.showAccountExistsError = true
                    self.errorMessage = nil
                }
            } else {
                await MainActor.run {
                    self.showAccountExistsError = false
                    self.errorMessage = error.localizedDescription
                }
            }
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
    private var usernameWarning: String {
        let uname = username.trimmed
        if uname.isEmpty { return "" }
        if uname.count < 3 { return "Mindestens 3 Zeichen" }
        if !uname.isValidUsername { return "Nur Buchstaben, Zahlen und _ erlaubt" }
        return ""
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

#Preview {
    SignUpView()
        .environmentObject(AppState())
}
