import SwiftUI
import AuthenticationServices
import CryptoKit
import Security
import UIKit

/// Nonce, SHA-256 and user-facing error mapping for Sign in with Apple.
enum AppleSignInNonce {
    static func random(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                Logger.error("Unable to generate nonce. SecRandomCopyBytes failed with status: \(status)", category: .auth)
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

    static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Returns `nil` when the user cancelled so the UI stays quiet.
    static func userMessage(for error: Error) -> String? {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            return nil
        }
        let nsError = error as NSError
        if nsError.code == 1001 {
            return nil
        }
        if nsError.domain == "AKAuthenticationError" || nsError.domain.contains("AuthenticationServices") {
            #if targetEnvironment(simulator)
            return L.error_appleSignInSimulator.localized
            #else
            if nsError.code == -7022 || nsError.code == -7071 {
                return L.error_appleSignInUseEmail.localized
            }
            return error.localizedDescription.isEmpty
                ? L.errorAppleSignInFailed.localized
                : ErrorMessageHelper.sanitizedAuthDisplayMessage(from: error, fallback: L.errorAppleSignInFailed.localized)
            #endif
        }
        return error.localizedDescription.isEmpty
            ? L.error_signInFailed.localized
            : ErrorMessageHelper.sanitizedAuthDisplayMessage(from: error, fallback: L.error_signInFailed.localized)
    }

    static func fullName(from credential: ASAuthorizationAppleIDCredential) -> String? {
        if let givenName = credential.fullName?.givenName,
           let familyName = credential.fullName?.familyName {
            return "\(givenName) \(familyName)"
        }
        return credential.fullName?.givenName
    }
}

/// Owns the authorization controller so delegates are not deallocated mid-flow.
final class AppleSignInController: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onRequest: (ASAuthorizationAppleIDRequest) -> Void = { _ in }
    var onCompletion: (Result<ASAuthorization, Error>, String?) -> Void = { _, _ in }
    var presentationWindow: UIWindow?
    private var authorizationController: ASAuthorizationController?

    func performRequest() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        onRequest(request)
        // Hosted Supabase hashes the nonce as hex and compares that to the ID token.
        // Native Apple writes a different encoding into the nonce claim, and the cloud
        // dashboard has no switch to skip that check. Leaving the nonce unset makes both
        // sides empty, so Auth skips the comparison. Signature, expiry, issuer, and
        // audience are still verified. Callers that set request.nonce themselves (account
        // deletion) keep that value.
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        authorizationController = controller
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        DispatchQueue.main.async {
            self.onCompletion(.success(authorization), nil)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.onCompletion(.failure(error), nil)
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let presentationWindow, !presentationWindow.isHidden {
            return presentationWindow
        }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        if let key = windows.first(where: { $0.isKeyWindow && !$0.isHidden }) {
            return key
        }
        if let visible = windows.first(where: { !$0.isHidden && $0.alpha > 0 }) {
            return visible
        }
        return windows.first ?? ASPresentationAnchor()
    }
}

private struct WindowProbe: UIViewRepresentable {
    var onResolve: (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            onResolve(uiView.window)
        }
    }
}

/// Custom Apple Sign In button. The system `SignInWithAppleButton` often swallows taps inside a `ScrollView` / `fullScreenCover`.
struct LocalizedAppleSignInButton: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var session = AppleSignInController()

    let buttonType: ASAuthorizationAppleIDButton.ButtonType
    let buttonStyle: ASAuthorizationAppleIDButton.Style
    let localizedText: String
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>, String?) -> Void
    let shouldPerformRequest: (() -> Bool)?

    init(
        buttonType: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        buttonStyle: ASAuthorizationAppleIDButton.Style = .black,
        localizedText: String,
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>, String?) -> Void,
        shouldPerformRequest: (() -> Bool)? = nil
    ) {
        self.buttonType = buttonType
        self.buttonStyle = buttonStyle
        self.localizedText = localizedText
        self.onRequest = onRequest
        self.onCompletion = onCompletion
        self.shouldPerformRequest = shouldPerformRequest
    }

    var body: some View {
        Button {
            performAppleSignIn()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .font(.system(size: 16, weight: .semibold))
                Text(localizedText)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(buttonStyle == .black ? .white : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(buttonStyle == .black ? Color.black : Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(buttonStyle == .black ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 375)
        .background(WindowProbe { session.presentationWindow = $0 })
        .accessibilityLabel(localizedText)
        .id("\(localizationManager.currentLanguage)-\(buttonType.rawValue)")
    }

    private func performAppleSignIn() {
        if let shouldPerform = shouldPerformRequest, !shouldPerform() {
            return
        }
        session.onRequest = onRequest
        session.onCompletion = onCompletion
        session.performRequest()
    }
}

@MainActor
enum AppleAccountDeletionAuth {
    private static var session: AppleSignInController?
    /// Test seam so unit tests can fail-closed without presenting Sign in with Apple.
    static var requestAuthorizationCodeOverride: (() async -> String?)?

    static func requestAuthorizationCode() async -> String? {
        if let requestAuthorizationCodeOverride {
            return await requestAuthorizationCodeOverride()
        }
        return await performLiveRequest()
    }

    private static func performLiveRequest() async -> String? {
        await withCheckedContinuation { continuation in
            let controller = AppleSignInController()
            session = controller
            let nonce = AppleSignInNonce.random()
            controller.onRequest = { request in
                request.requestedScopes = []
                request.nonce = AppleSignInNonce.sha256(nonce)
            }
            controller.onCompletion = { result, _ in
                session = nil
                switch result {
                case .success(let authorization):
                    let credential = authorization.credential as? ASAuthorizationAppleIDCredential
                    let code = credential.flatMap(\.authorizationCode).flatMap { String(data: $0, encoding: .utf8) }
                    continuation.resume(returning: code)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
            controller.performRequest()
        }
    }
}

enum AccountDeletionAppleRequirement {
    static func isAppleAccount(provider: String?, email: String?, appleUserId: String?) -> Bool {
        if provider == "apple" { return true }
        if let appleUserId, !appleUserId.isEmpty { return true }
        if let email, email.lowercased().contains("privaterelay.appleid.com") { return true }
        return false
    }

    static func requireAuthorizationCode(_ code: String?) throws -> String {
        let trimmed = code?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            throw NSError(
                domain: "Account",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: L.accountDeletionFailed.localized]
            )
        }
        return trimmed
    }
}
