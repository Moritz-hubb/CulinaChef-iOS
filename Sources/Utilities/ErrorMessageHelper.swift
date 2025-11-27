import Foundation

/// Helper für nutzerfreundliche Error-Messages
///
/// Konvertiert technische Error-Messages in lokalisierte, nutzerfreundliche Texte
enum ErrorMessageHelper {
    /// Konvertiert einen Error in eine nutzerfreundliche, lokalisierte Message
    static func userFriendlyMessage(from error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        return userFriendlyMessage(from: errorDescription)
    }
    
    /// Konvertiert einen Error-String in eine nutzerfreundliche, lokalisierte Message
    static func userFriendlyMessage(from errorString: String) -> String {
        let errorDescription = errorString.lowercased()
        
        // Network errors
        if errorDescription.contains("cannotfindhost") || 
           errorDescription.contains("cannotconnecttohost") ||
           errorDescription.contains("network") ||
           errorDescription.contains("internet") ||
           errorDescription.contains("connection") {
            return L.errorNetworkConnection.localized
        }
        
        // Server errors
        if errorDescription.contains("server") ||
           errorDescription.contains("unavailable") ||
           errorDescription.contains("timeout") {
            return L.errorServerUnavailable.localized
        }
        
        // Authentication errors
        if errorDescription.contains("unauthorized") ||
           errorDescription.contains("not logged in") ||
           errorDescription.contains("token") ||
           errorDescription.contains("authentication") {
            return L.errorNotLoggedIn.localized
        }
        
        // StoreKit/Purchase errors
        if errorDescription.contains("purchase") || 
           errorDescription.contains("storekit") ||
           errorDescription.contains("payment") {
            return L.errorPurchaseFailed.localized
        }
        
        // Rate limit errors
        if errorDescription.contains("rate limit") || 
           errorDescription.contains("limit exceeded") ||
           errorDescription.contains("too many requests") {
            return L.errorRateLimitExceeded.localized
        }
        
        // Upload errors
        if errorDescription.contains("upload") || 
           errorDescription.contains("failed") {
            return L.errorUploadFailed.localized
        }
        
        // Save errors
        if errorDescription.contains("save") {
            return L.errorSaveFailed.localized
        }
        
        // API Client errors
        if errorDescription.contains("api") ||
           errorDescription.contains("client") ||
           errorDescription.contains("configured") {
            return L.errorApiClientNotConfigured.localized
        }
        
        // Backend AI processing errors
        if errorDescription.contains("ki-antwort konnte nicht") ||
           errorDescription.contains("openai fehler") ||
           errorDescription.contains("verarbeitet werden") ||
           errorDescription.contains("could not be processed") {
            return L.errorProcessingFailed.localized
        }
        
        // Backend errors (check for specific backend error messages)
        if errorDescription.contains("backend") && errorDescription.contains("error") {
            return L.errorProcessingFailed.localized
        }
        
        // Generic fallback
        return L.errorGenericUserFriendly.localized
    }
}

