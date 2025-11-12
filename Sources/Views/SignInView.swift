import SwiftUI

struct SignInView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
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
                    } else {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
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
                                } else {
                                    SecureField("", text: $password, prompt: Text(L.passwordPlaceholderDots.localized).foregroundColor(.gray.opacity(0.5)))
                                        .textContentType(.password)
                                        .focused($focusedField, equals: .password)
                                        .submitLabel(.go)
                                        .onSubmit { Task { await signIn() } }
                                }
                                
                                Button { showPassword.toggle() } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
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
                        
                        // Apple Sign In
                        Button {
                            // TODO: Implement Apple Sign In
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 16, weight: .medium))
                                Text(L.loginWithApple.localized)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
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
    }
    
    private func signIn() async {
        errorMessage = nil
        focusedField = nil
        
        do {
            try await app.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), 
                                password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AppState())
}
