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
    let shouldPerformRequest: (() -> Bool)?
    
    @State private var authorizationController: ASAuthorizationController?
    @State private var authorizationDelegate: AuthorizationDelegate?
    @State private var presentationProvider: PresentationContextProvider?
    
    init(
        buttonType: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        buttonStyle: ASAuthorizationAppleIDButton.Style = .black,
        localizedText: String,
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void,
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
        .frame(maxWidth: 375) // Prevent constraint conflicts
    }
    
    private func performAppleSignIn() {
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.performAppleSignIn()
            }
            return
        }
        
        // Check if request should be performed (validation)
        if let shouldPerform = shouldPerformRequest, !shouldPerform() {
            // Validation failed, don't perform request
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        onRequest(request)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        let completionHandler = onCompletion
        let delegate = AuthorizationDelegate(onCompletion: { result in
            // Call the completion handler
            // Note: References are automatically managed by @State and will be cleared when view is recreated
            completionHandler(result)
        })
        let presentationProvider = PresentationContextProvider()
        
        controller.delegate = delegate
        controller.presentationContextProvider = presentationProvider
        
        // Keep references to prevent deallocation
        self.authorizationController = controller
        self.authorizationDelegate = delegate
        self.presentationProvider = presentationProvider
        
        controller.performRequests()
    }
}

// MARK: - Authorization Delegate
private class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    init(onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onCompletion = onCompletion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Ensure callback is on main thread
        DispatchQueue.main.async {
            self.onCompletion(.success(authorization))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Ensure callback is on main thread
        DispatchQueue.main.async {
            self.onCompletion(.failure(error))
        }
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


