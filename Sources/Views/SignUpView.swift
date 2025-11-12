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
                    } else {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
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
                        
                        // Terms & Privacy Acceptance
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
                            
                            // Age Confirmation
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
                        
                        // Error Message
                        if let error = errorMessage {
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
                        
                        // Apple Sign In (official button)
                        SignInWithAppleButton(.signUp, onRequest: { request in
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
                                    Task { await handleAppleSignIn(idToken: idToken) }
                                } else {
                                    self.errorMessage = "Apple Anmelde-Token ungültig"
                                }
                            case .failure(let error):
                                self.errorMessage = error.localizedDescription
                            }
                        })
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 44)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .frame(maxHeight: .infinity)
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
        let uname = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !uname.isEmpty && isValidUsername(uname) &&
        !email.isEmpty && email.contains("@") &&
        password.count >= 6 && passwordsMatch &&
        acceptedTerms && confirmedAge
    }
    
    private func signUp() async {
        guard isFormValid else {
            errorMessage = "Bitte fülle alle Felder korrekt aus"
            return
        }
        
        errorMessage = nil
        focusedField = nil
        
        do {
            let uname = username.trimmingCharacters(in: .whitespacesAndNewlines)
            try await app.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                username: uname
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleAppleSignIn(idToken: String) async {
        do {
            try await app.signInWithApple(idToken: idToken, nonce: appleNonce)
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
            if status != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed") }
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
        let uname = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if uname.isEmpty { return "" }
        if uname.count < 3 { return "Mindestens 3 Zeichen" }
        if !isValidUsername(uname) { return "Nur Buchstaben, Zahlen und _ erlaubt" }
        return ""
    }
    
    private func isValidUsername(_ u: String) -> Bool {
        let pattern = "^[A-Za-z0-9_]{3,32}$"
        return u.range(of: pattern, options: .regularExpression) != nil
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
