import SwiftUI

/// Signup gate shown after email and password. The confirm action stays disabled until a code is entered.
struct EmailVerificationSlide: View {
    let email: String
    let isLoading: Bool
    let errorMessage: String?
    let statusMessage: String?
    var onBack: (() -> Void)? = nil
    let onConfirm: (String) -> Void
    let onResend: () -> Void

    @State private var code = ""
    @State private var resendAvailableAt = Date().addingTimeInterval(30)
    @FocusState private var codeFocused: Bool

    private var digits: String { code.filter(\.isNumber) }
    private var canConfirm: Bool { (6...10).contains(digits.count) && !isLoading }

    var body: some View {
        VStack(spacing: 16) {
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel(L.onboarding_zurück.localized)
                    Spacer()
                }
            }

            Text(L.verifyEmailTitle.localized)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(L.verifyEmailBody.localized(replacing: ["email": email]))
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            TextField(
                "",
                text: $code,
                prompt: Text(L.verifyEmailCodePlaceholder.localized).foregroundColor(.gray.opacity(0.5))
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($codeFocused)
            .padding(12)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .foregroundColor(.black)
            .onChange(of: code) { _, newValue in
                let filtered = String(newValue.filter(\.isNumber).prefix(10))
                if filtered != newValue { code = filtered }
            }

            if let errorMessage, !errorMessage.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(errorMessage)
                        .font(.system(size: 11))
                }
                .foregroundColor(.red)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            } else if let statusMessage, !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                onConfirm(digits)
            } label: {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(L.verifyEmailButton.localized)
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
            }
            .disabled(!canConfirm)
            .opacity(canConfirm ? 1 : 0.6)

            Button(action: resend) {
                Text(L.verifyEmailResend.localized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(canResend ? Color(red: 0.95, green: 0.5, blue: 0.3) : .gray)
            }
            .disabled(!canResend || isLoading)
        }
        .onAppear { codeFocused = true }
    }

    private var canResend: Bool { Date() >= resendAvailableAt }

    private func resend() {
        guard canResend, !isLoading else { return }
        resendAvailableAt = Date().addingTimeInterval(30)
        onResend()
    }
}
