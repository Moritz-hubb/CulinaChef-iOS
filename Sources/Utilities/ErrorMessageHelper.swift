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

        if errorDescription.contains("subscription_required") ||
           errorDescription.contains("aktives abo ist erforderlich") {
            return L.error_aiChatRestricted.localized
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
           errorDescription.contains("could not be processed") ||
           errorDescription.contains("string_too_long") ||
           errorDescription.contains("string should have at most") ||
           errorDescription.contains("max_length") {
            return L.errorProcessingFailed.localized
        }
        
        // Backend errors (check for specific backend error messages)
        if errorDescription.contains("backend") && errorDescription.contains("error") {
            return L.errorProcessingFailed.localized
        }
        
        // Generic fallback
        return L.errorGenericUserFriendly.localized
    }

    /// Auth/UI copy: keep short human messages, drop JSON/HTML/stack dumps.
    static func sanitizedDisplayMessage(from error: Error, fallback: String) -> String {
        let mapped = userFriendlyMessage(from: error)
        if mapped != L.errorGenericUserFriendly.localized {
            return mapped
        }
        let text = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isSafeUserFacingMessage(text) else { return fallback }
        return text
    }

    static func isSafeUserFacingMessage(_ message: String) -> Bool {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...180).contains(text.count) else { return false }
        let lower = text.lowercased()
        if text.hasPrefix("{") || text.hasPrefix("[") { return false }
        if lower.contains("<html") || lower.contains("<!doctype") { return false }
        if lower.contains("traceback") || lower.contains("stack trace") { return false }
        if text.contains("\n") { return false }
        return true
    }
}

