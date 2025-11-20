import SwiftUI
import AuthenticationServices
import CryptoKit

/// A localized Apple Sign In button that triggers the authorization flow
struct LocalizedAppleSignInButton: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    let buttonType: ASAuthorizationAppleIDButton.ButtonType
    let buttonStyle: ASAuthorizationAppleIDButton.Style
    let localizedText: String
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    @State private var authorizationController: ASAuthorizationController?
    
    init(
        buttonType: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        buttonStyle: ASAuthorizationAppleIDButton.Style = .black,
        localizedText: String,
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
    ) {
        self.buttonType = buttonType
        self.buttonStyle = buttonStyle
        self.localizedText = localizedText
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        Button(action: {
            performAppleSignIn()
        }) {
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
        .frame(maxWidth: 375) // Prevent constraint conflicts
    }
    
    private func performAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        onRequest(request)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AuthorizationDelegate(onCompletion: onCompletion)
        controller.presentationContextProvider = PresentationContextProvider()
        controller.performRequests()
        
        // Keep a reference to prevent deallocation
        self.authorizationController = controller
    }
}

// MARK: - Authorization Delegate
private class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    init(onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onCompletion = onCompletion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion(.failure(error))
    }
}

// MARK: - Presentation Context Provider
private class PresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Use modern API for iOS 13+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        // Fallback: create a new window (shouldn't happen in normal usage)
        return UIWindow()
    }
}

