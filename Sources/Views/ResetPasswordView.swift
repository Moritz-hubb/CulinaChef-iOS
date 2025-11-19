import SwiftUI

struct ResetPasswordView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject var app: AppState
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case newPassword, confirmPassword
    }
    
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
                    
                    // Icon
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text(L.resetPasswordNewPasswordTitle.localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer().frame(height: 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // White card with form
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        if showSuccess {
                            // Success message
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.green)
                                
                                Text(L.resetPasswordSuccess.localized)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text(L.loginButton.localized)
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 40)
                        } else {
                            // Form
                            Text(L.resetPasswordNewPasswordSubtitle.localized)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // New Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L.resetPasswordNewPassword.localized)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    if showPassword {
                                        TextField("", text: $newPassword, prompt: Text(L.passwordPlaceholderDots.localized).foregroundColor(.gray.opacity(0.5)))
                                            .textContentType(.newPassword)
                                            .focused($focusedField, equals: .newPassword)
                                            .submitLabel(.next)
                                            .onSubmit { focusedField = .confirmPassword }
                                            .accessibilityLabel(L.resetPasswordNewPassword.localized)
                                    } else {
                                        SecureField("", text: $newPassword, prompt: Text(L.passwordPlaceholderDots.localized).foregroundColor(.gray.opacity(0.5)))
                                            .textContentType(.newPassword)
                                            .focused($focusedField, equals: .newPassword)
                                            .submitLabel(.next)
                                            .onSubmit { focusedField = .confirmPassword }
                                            .accessibilityLabel(L.resetPasswordNewPassword.localized)
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
                                        .stroke(focusedField == .newPassword ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
                                )
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L.resetPasswordConfirmPassword.localized)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("", text: $confirmPassword, prompt: Text(L.passwordPlaceholderDots.localized).foregroundColor(.gray.opacity(0.5)))
                                            .textContentType(.newPassword)
                                            .focused($focusedField, equals: .confirmPassword)
                                            .submitLabel(.go)
                                            .onSubmit { Task { await updatePassword() } }
                                            .accessibilityLabel(L.resetPasswordConfirmPassword.localized)
                                    } else {
                                        SecureField("", text: $confirmPassword, prompt: Text(L.passwordPlaceholderDots.localized).foregroundColor(.gray.opacity(0.5)))
                                            .textContentType(.newPassword)
                                            .focused($focusedField, equals: .confirmPassword)
                                            .submitLabel(.go)
                                            .onSubmit { Task { await updatePassword() } }
                                            .accessibilityLabel(L.resetPasswordConfirmPassword.localized)
                                    }
                                    
                                    Button { showConfirmPassword.toggle() } label: {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                    .accessibilityLabel(showConfirmPassword ? "Passwort verbergen" : "Passwort anzeigen")
                                }
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(focusedField == .confirmPassword ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
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
                            
                            // Update Button
                            Button {
                                Task { await updatePassword() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(L.resetPasswordUpdateButton.localized)
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
                            .accessibilityLabel(isLoading ? L.loading.localized : L.resetPasswordUpdateButton.localized)
                            .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty)
                            .opacity((isLoading || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1)
                        }
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
        .id(localizationManager.currentLanguage) // Force re-render on language change
    }
    
    private func updatePassword() async {
        errorMessage = nil
        focusedField = nil
        
        // Validate passwords match
        guard newPassword == confirmPassword else {
            errorMessage = L.resetPasswordPasswordsDoNotMatch.localized
            return
        }
        
        // Validate password length
        guard newPassword.count >= 6 else {
            errorMessage = L.resetPasswordTooShort.localized
            return
        }
        
        guard let accessToken = app.passwordResetToken,
              let refreshToken = app.passwordResetRefreshToken else {
            errorMessage = L.resetPasswordError.localized
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await app.updatePassword(accessToken: accessToken, refreshToken: refreshToken, newPassword: newPassword)
            await MainActor.run {
                showSuccess = true
                // Auto-dismiss after 2 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        app.showPasswordReset = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = L.resetPasswordError.localized
            }
        }
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(AppState())
}

