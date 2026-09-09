import SwiftUI
import AuthenticationServices
import CryptoKit
import Security

struct SignUpView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
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
    @State private var step = 0
    var onNavigateToSignIn: (() -> Void)?
    
    enum Field: Hashable {
        case email, password, confirmPassword
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
        GeometryReader { geometry in
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
                .ignoresSafeArea(.keyboard)
                
                VStack(spacing: 0) {
                    // Top illustration section - reduces when keyboard is visible
                    VStack(spacing: 6) {
                        Spacer().frame(height: focusedField == nil ? 30 : 15)
                        
                        // Penguin illustration - smaller when keyboard is visible
                        if let uiImage = UIImage(named: "penguin-auth") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: focusedField == nil ? 110 : 70, height: focusedField == nil ? 110 : 70)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: focusedField == nil ? 70 : 45))
                                .foregroundColor(.white)
                                .accessibilityHidden(true)
                        }
                        
                        if focusedField == nil {
                            Text(L.letsGetStarted.localized)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer().frame(height: focusedField == nil ? 12 : 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, focusedField == nil ? 16 : 8)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)
                    
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 16) {
                                signupHeaderBar
                                
                                Text(L.ui_registrieren.localized)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                
                                if step == 0 {
                                    emailSlide
                                } else {
                                    passwordSlide
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 400)
                            .animation(.easeInOut(duration: 0.25), value: step)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                    .background(Color.white)
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    .ignoresSafeArea(edges: .bottom)
                    .frame(maxHeight: .infinity)

                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    private var signupHeaderBar: some View {
        HStack {
            if step == 1 {
                Button {
                    errorMessage = nil
                    showAccountExistsError = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        step = 0
                    }
                    focusedField = .email
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(L.onboarding_zurück.localized)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .accessibilityLabel(L.cancel.localized)
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }
    
    private var emailSlide: some View {
        VStack(spacing: 16) {
            emailField
            termsSection
            errorBanner
            primaryButton(title: L.next.localized, disabled: email.trimmed.isEmpty, loading: false) {
                goToPasswordSlide()
            }
            orDivider
            appleSignInButton
        }
        .padding(.horizontal, 20)
    }
    
    private var passwordSlide: some View {
        VStack(spacing: 16) {
            Text(email.trimmed)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            passwordField
            confirmPasswordField
            termsSection
            errorBanner
            primaryButton(
                title: L.signUpButton.localized,
                disabled: app.loading || !isFormValid,
                loading: app.loading
            ) {
                Task { await signUp() }
            }
            orDivider
            appleSignInButton
        }
        .padding(.horizontal, 20)
    }
    
    private var emailField: some View {
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
                .onSubmit { goToPasswordSlide() }
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .foregroundColor(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(focusedField == .email ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                )
        }
    }
    
    private var passwordField: some View {
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
                } else {
                    SecureField("", text: $password, prompt: Text(L.minCharacters.localized).foregroundColor(.gray.opacity(0.5)))
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                }
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .accessibilityLabel(showPassword ? L.a11y_hidePassword.localized : L.a11y_showPassword.localized)
            }
            .padding(10)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .foregroundColor(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focusedField == .password ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
            )
            if !password.isEmpty {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Rectangle()
                            .fill(index < strengthBars ? passwordStrengthColor : Color.gray.opacity(0.2))
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
            }
        }
    }
    
    private var confirmPasswordField: some View {
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
                } else {
                    SecureField("", text: $confirmPassword, prompt: Text(L.ui_wiederholen.localized).foregroundColor(.gray.opacity(0.5)))
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit { Task { await signUp() } }
                }
                Button { showConfirmPassword.toggle() } label: {
                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .accessibilityLabel(showConfirmPassword ? L.a11y_hidePassword.localized : L.a11y_showPassword.localized)
                if passwordsMatch {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
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
    }
    
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: { acceptedTerms.toggle() }) {
                    Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundStyle(acceptedTerms ? Color(red: 0.95, green: 0.5, blue: 0.3) : .gray)
                }
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
                    Text(L.ui_und_die.localized)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Button(action: { showPrivacy = true }) {
                        Text(L.ui_datenschutzerklärung_2997.localized)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                            .underline()
                    }
                }
            }
            HStack(alignment: .top, spacing: 10) {
                Button(action: { confirmedAge.toggle() }) {
                    Image(systemName: confirmedAge ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundStyle(confirmedAge ? Color(red: 0.95, green: 0.5, blue: 0.3) : .gray)
                }
                Text(L.ui_ich_bestätige_dass_ich.localized)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var errorBanner: some View {
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
    }
    
    private var orDivider: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
            Text(L.or.localized).font(.system(size: 11, weight: .medium)).foregroundColor(.gray)
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
        }
        .padding(.vertical, 2)
    }
    
    private func primaryButton(title: String, disabled: Bool, loading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if loading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.system(size: 15, weight: .semibold))
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
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }
    
    private var appleSignInButton: some View {
        SignInWithAppleButton(.signUp, onRequest: { request in
            guard self.acceptedTerms && self.confirmedAge else {
                DispatchQueue.main.async {
                    self.errorMessage = L.acceptTermsAndPrivacy.localized
                    self.showAccountExistsError = false
                }
                return
            }
            DispatchQueue.main.async {
                self.errorMessage = nil
                self.showAccountExistsError = false
            }
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
                let nsError = error as NSError
                let errorCode = nsError.code
                let errorDomain = nsError.domain
                if errorDomain == "AKAuthenticationError" || errorDomain.contains("AuthenticationServices") {
                    #if targetEnvironment(simulator)
                    self.errorMessage = L.error_appleSignInSimulator.localized
                    #else
                    if errorCode == -7022 || errorCode == -7071 {
                        self.errorMessage = L.error_appleSignInUseEmail.localized
                    } else {
                        self.errorMessage = error.localizedDescription.isEmpty ? L.errorAppleSignInFailed.localized : error.localizedDescription
                    }
                    #endif
                } else {
                    self.errorMessage = error.localizedDescription.isEmpty ? L.error_signInFailed.localized : error.localizedDescription
                }
            }
        })
        .signInWithAppleButtonStyle(.black)
        .frame(height: 44)
        .frame(maxWidth: 375)
        .cornerRadius(8)
    }
    
    private func goToPasswordSlide() {
        let trimmed = email.trimmed
        guard !trimmed.isEmpty else {
            errorMessage = String.validationError(for: .required)
            showAccountExistsError = false
            return
        }
        guard trimmed.isValidEmail else {
            errorMessage = String.validationError(for: .email)
            showAccountExistsError = false
            return
        }
        errorMessage = nil
        showAccountExistsError = false
        withAnimation(.easeInOut(duration: 0.25)) {
            step = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            focusedField = .password
        }
    }
    
    private var strengthBars: Int {
        if password.isEmpty { return 0 }
        if password.count < 6 { return 1 }
        if password.count < 8 { return 2 }
        return 3
    }
    
    private var isFormValid: Bool {
        let trimmedEmail = email.trimmed
        return !trimmedEmail.isEmpty && trimmedEmail.isValidEmail &&
        password.isValidPassword && passwordsMatch &&
        acceptedTerms && confirmedAge
    }
    
    private func signUp() async {
        errorMessage = nil
        showAccountExistsError = false
        focusedField = nil
        
        // Validate input before sending to backend
        let trimmedEmail = email.trimmed
        let derivedUsername = generateUsername(fromEmail: trimmedEmail)
        
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
            errorMessage = L.settings_passwordsDoNotMatch.localized
            return
        }
        
        guard acceptedTerms && confirmedAge else {
            errorMessage = L.acceptTermsAndPrivacy.localized
            return
        }
        
        do {
            try await app.signUp(
                email: trimmedEmail,
                password: password,
                username: derivedUsername
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
    /// Generates a stable, valid username from an email address.
    /// Keeps signup minimal (name is collected in onboarding).
    private func generateUsername(fromEmail email: String) -> String {
        let localPart = email.split(separator: "@").first.map(String.init) ?? "user"
        // Allow only letters, numbers and underscore (same rule as `isValidUsername`)
        let cleaned = localPart
            .lowercased()
            .map { ch -> Character in
                if ch.isLetter || ch.isNumber || ch == "_" { return ch }
                return "_"
            }
        
        var base = String(cleaned)
        // Trim underscores and ensure minimum length
        base = base.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        if base.count < 3 { base = (base + "_user").prefix(12).description }
        
        // Hard cap to keep things tidy
        base = String(base.prefix(20))
        
        // Final safety fallback
        if base.isEmpty { base = "user" }
        return base
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
