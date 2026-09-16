import SwiftUI
import AuthenticationServices

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
                    VStack(spacing: 8) {
                        Spacer().frame(height: focusedField == nil ? 40 : 20)
                        
                        // Penguin illustration - smaller when keyboard is visible
                        if let uiImage = UIImage(named: "penguin-auth") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: focusedField == nil ? 130 : 80, height: focusedField == nil ? 130 : 80)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: focusedField == nil ? 80 : 50))
                                .foregroundColor(.white)
                                .accessibilityHidden(true)
                        }
                        
                        if focusedField == nil {
                            Text(L.ui_willkommen_zurück.localized)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer().frame(height: focusedField == nil ? 16 : 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, focusedField == nil ? 20 : 10)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)
                    
                    // White card with form - takes remaining space
                    VStack(spacing: 0) {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 20) {
                                Spacer().frame(height: 1) // Top spacing
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
                                    .accessibilityHint(L.a11y_closeSignIn.localized)
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
                                .id("emailField")
                                
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
                                        .accessibilityLabel(showPassword ? L.a11y_hidePassword.localized : L.a11y_showPassword.localized)
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
                                .id("passwordField")
                        
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
                        .accessibilityHint(L.a11y_signInWithEmailHint.localized)
                        .disabled(app.loading || email.isEmpty || password.isEmpty)
                        .opacity((app.loading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                        .id("signInButton")
                        
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
                        .accessibilityHint(L.a11y_openPasswordReset.localized)
                        .padding(.top, 8)
                        
                        LocalizedAppleSignInButton(
                            buttonType: .signIn,
                            localizedText: L.loginWithApple.localized,
                            onRequest: { request in
                                let nonce = AppleSignInNonce.random()
                                self.appleNonce = nonce
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = AppleSignInNonce.sha256(nonce)
                            },
                            onCompletion: { result in
                                handleAppleAuthorization(result)
                            }
                        )
                        .disabled(app.loading)
                        .id("appleSignInButton")
                        }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 400) // Extra bottom padding for keyboard - ensures all content is accessible
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: focusedField) { _, newValue in
                            if let field = newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        switch field {
                                        case .email:
                                            proxy.scrollTo("emailField", anchor: .center)
                                        case .password:
                                            // When password field is focused, scroll to show sign in button
                                            proxy.scrollTo("signInButton", anchor: .bottom)
                                        }
                                    }
                                }
                            } else {
                                // When keyboard is dismissed, scroll to bottom to show all buttons
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo("signInButton", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        }
                        .background(Color.white)
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                        .ignoresSafeArea(edges: .bottom)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
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
            errorMessage = ErrorMessageHelper.sanitizedDisplayMessage(from: error, fallback: L.error_signInFailed.localized)
        }
    }
    
    private func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResult):
            if let credential = authResult.credential as? ASAuthorizationAppleIDCredential,
               let tokenData = credential.identityToken,
               let idToken = String(data: tokenData, encoding: .utf8) {
                let fullName = AppleSignInNonce.fullName(from: credential)
                let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
                Task { await handleAppleSignIn(idToken: idToken, fullName: fullName, appleUserId: credential.user, authorizationCode: authorizationCode) }
            } else {
                errorMessage = L.errorAppleTokenInvalid.localized
            }
        case .failure(let error):
            errorMessage = AppleSignInNonce.userMessage(for: error)
        }
    }

    private func handleAppleSignIn(idToken: String, fullName: String? = nil, appleUserId: String? = nil, authorizationCode: String? = nil) async {
        do {
            try await app.signInWithApple(idToken: idToken, nonce: appleNonce, fullName: fullName, appleUserId: appleUserId, authorizationCode: authorizationCode)
        } catch {
            await MainActor.run { self.errorMessage = ErrorMessageHelper.sanitizedDisplayMessage(from: error, fallback: L.error_signInFailed.localized) }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AppState())
}
