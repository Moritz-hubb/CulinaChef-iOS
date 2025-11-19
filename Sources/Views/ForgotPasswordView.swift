import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var isResending = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var showResendSuccess = false
    @State private var pollingTask: Task<Void, Never>?
    @FocusState private var isEmailFocused: Bool
    
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
                    
                    // Penguin illustration
                    if let uiImage = UIImage(named: "penguin-auth") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 130)
                    } else {
                        Image(systemName: "key.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                    
                    Text(L.resetPasswordTitle.localized)
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
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                        
                        if showSuccess {
                            // Success message
                            VStack(spacing: 20) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.green)
                                
                                Text(showResendSuccess ? L.resetPasswordResendEmailSuccess.localized : L.resetPasswordEmailSent.localized)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text(L.resetPasswordCheckEmail.localized)
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                // Info about localhost links
                                Text(L.resetPasswordLinkClicked.localized)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                
                                // Resend Email Button
                                Button {
                                    Task { await resendEmail() }
                                } label: {
                                    HStack {
                                        if isResending {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text(L.resetPasswordResendEmail.localized)
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
                                .accessibilityLabel(isResending ? L.loading.localized : L.resetPasswordResendEmail.localized)
                                .disabled(isResending || email.isEmpty)
                                .opacity((isResending || email.isEmpty) ? 0.6 : 1)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                
                                // Manual check button (fallback if polling doesn't work)
                                Button {
                                    Task { await checkPasswordResetStatus() }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(L.resetPasswordCheckStatus.localized)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                }
                                .accessibilityLabel(L.resetPasswordCheckStatus.localized)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }
                            .padding(.vertical, 40)
                        } else {
                            // Form
                            Text(L.resetPasswordSubtitle.localized)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
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
                                    .focused($isEmailFocused)
                                    .submitLabel(.send)
                                    .onSubmit { Task { await resetPassword() } }
                                    .accessibilityLabel(L.email.localized)
                                    .accessibilityHint(L.emailPlaceholder.localized)
                                    .padding(12)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isEmailFocused ? Color(red: 0.95, green: 0.5, blue: 0.3) : Color.clear, lineWidth: 2)
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
                            
                            // Send Button
                            Button {
                                Task { await resetPassword() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(L.resetPasswordButton.localized)
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
                            .accessibilityLabel(isLoading ? L.loading.localized : L.resetPasswordButton.localized)
                            .disabled(isLoading || email.isEmpty)
                            .opacity((isLoading || email.isEmpty) ? 0.6 : 1)
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
        .onDisappear {
            // Stop polling when view disappears
            pollingTask?.cancel()
            pollingTask = nil
        }
    }
    
    private func resetPassword() async {
        errorMessage = nil
        isEmailFocused = false
        
        // Validate email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = L.resetPasswordInvalidEmail.localized
            return
        }
        
        guard trimmedEmail.isValidEmail else {
            errorMessage = L.resetPasswordInvalidEmail.localized
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await app.resetPassword(email: trimmedEmail)
            await MainActor.run {
                showSuccess = true
                showResendSuccess = false
                // Start polling for password reset link click
                startPollingForPasswordReset()
            }
        } catch {
            await MainActor.run {
                errorMessage = L.resetPasswordError.localized
            }
        }
    }
    
    private func startPollingForPasswordReset() {
        // Stop any existing polling
        pollingTask?.cancel()
        
        // Store the email before starting polling
        let emailToCheck = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let initialTokens = (KeychainManager.get(key: "access_token"), KeychainManager.get(key: "refresh_token"))
        
        // Start new polling task
        pollingTask = Task {
            var pollCount = 0
            let maxPolls = 60 // Poll for 5 minutes (60 * 5 seconds)
            
            while !Task.isCancelled && pollCount < maxPolls {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                if Task.isCancelled {
                    break
                }
                
                // Check if user clicked the link by checking for new or changed tokens in Keychain
                // When user clicks the reset link, Supabase authenticates them and tokens are stored
                let currentAccessToken = KeychainManager.get(key: "access_token")
                let currentRefreshToken = KeychainManager.get(key: "refresh_token")
                let userEmail = KeychainManager.get(key: "user_email")
                
                // Check if tokens exist and match the email, and are different from initial tokens
                if let accessToken = currentAccessToken,
                   let refreshToken = currentRefreshToken,
                   let email = userEmail,
                   email.lowercased() == emailToCheck.lowercased(),
                   // Tokens changed (user clicked the link) OR tokens didn't exist before
                   (currentAccessToken != initialTokens.0 || currentRefreshToken != initialTokens.1 || initialTokens.0 == nil) {
                    
                    // Verify the token is valid and is a password reset token
                    // by checking if we can get user info
                    do {
                        if let _ = try await app.getUser(accessToken: accessToken) {
                            // User is authenticated via password reset link
                            await MainActor.run {
                                app.passwordResetToken = accessToken
                                app.passwordResetRefreshToken = refreshToken
                                app.showPasswordReset = true
                                // Stop polling
                                pollingTask?.cancel()
                                pollingTask = nil
                            }
                            return
                        }
                    } catch {
                        // Token might not be valid yet, continue polling
                    }
                }
                
                pollCount += 1
            }
            
            // Stop polling after max attempts
            await MainActor.run {
                pollingTask = nil
            }
        }
    }
    
    private func resendEmail() async {
        errorMessage = nil
        
        // Validate email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = L.resetPasswordInvalidEmail.localized
            return
        }
        
        guard trimmedEmail.isValidEmail else {
            errorMessage = L.resetPasswordInvalidEmail.localized
            return
        }
        
        isResending = true
        defer { isResending = false }
        
        do {
            try await app.resetPassword(email: trimmedEmail)
            await MainActor.run {
                showResendSuccess = true
                // Restart polling for password reset link click
                startPollingForPasswordReset()
                // Reset the resend success message after 3 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        showResendSuccess = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = L.resetPasswordError.localized
            }
        }
    }
    
    private func checkPasswordResetStatus() async {
        let emailToCheck = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Logger.debug("[ForgotPasswordView] Checking password reset status for: \(emailToCheck)", category: .auth)
        
        // Check if user clicked the link by checking for tokens in Keychain
        let accessToken = KeychainManager.get(key: "access_token")
        let refreshToken = KeychainManager.get(key: "refresh_token")
        let userEmail = KeychainManager.get(key: "user_email")
        
        Logger.debug("[ForgotPasswordView] Keychain check - accessToken: \(accessToken != nil), refreshToken: \(refreshToken != nil), userEmail: \(userEmail ?? "nil")", category: .auth)
        
        if let token = accessToken,
           let refresh = refreshToken,
           let email = userEmail,
           email.lowercased() == emailToCheck.lowercased() {
            
            Logger.debug("[ForgotPasswordView] Tokens found, verifying with Supabase...", category: .auth)
            
            // Verify the token is valid
            do {
                if let user = try await app.getUser(accessToken: token) {
                    Logger.debug("[ForgotPasswordView] Token verified, user authenticated: \(user.email)", category: .auth)
                    // User is authenticated via password reset link
                    await MainActor.run {
                        app.passwordResetToken = token
                        app.passwordResetRefreshToken = refresh
                        app.showPasswordReset = true
                        Logger.debug("[ForgotPasswordView] Navigating to password reset view", category: .auth)
                    }
                    return
                } else {
                    Logger.debug("[ForgotPasswordView] getUser returned nil", category: .auth)
                }
            } catch {
                Logger.error("[ForgotPasswordView] Error verifying token: \(error.localizedDescription)", category: .auth)
                await MainActor.run {
                    errorMessage = L.resetPasswordError.localized
                }
                return
            }
        } else {
            Logger.debug("[ForgotPasswordView] Tokens not found or email mismatch", category: .auth)
            Logger.debug("[ForgotPasswordView] Expected email: \(emailToCheck), Found email: \(userEmail ?? "nil")", category: .auth)
        }
        
        // If we get here, the link hasn't been clicked yet or tokens aren't in Keychain
        // This can happen if the link redirects to localhost instead of opening the app
        await MainActor.run {
            if accessToken == nil || refreshToken == nil {
                errorMessage = L.resetPasswordLinkClicked.localized
            } else if let email = userEmail, email.lowercased() != emailToCheck.lowercased() {
                errorMessage = L.resetPasswordInvalidEmail.localized
            } else {
                errorMessage = L.resetPasswordCheckEmail.localized
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AppState())
}

