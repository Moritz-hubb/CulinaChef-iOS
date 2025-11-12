import Foundation
import os.log

/// Production-safe logging utility
/// Uses os.log in production, print() in debug
enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.culinaai.culinachef"
    
    // Category-based loggers
    private static let auth = OSLog(subsystem: subsystem, category: "auth")
    private static let network = OSLog(subsystem: subsystem, category: "network")
    private static let ui = OSLog(subsystem: subsystem, category: "ui")
    private static let data = OSLog(subsystem: subsystem, category: "data")
    private static let general = OSLog(subsystem: subsystem, category: "general")
    
    enum Category {
        case auth, network, ui, data, general
        
        var log: OSLog {
            switch self {
            case .auth: return Logger.auth
            case .network: return Logger.network
            case .ui: return Logger.ui
            case .data: return Logger.data
            case .general: return Logger.general
            }
        }
    }
    
    /// Log debug message (only visible in Debug builds)
    static func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        print("[DEBUG][\(categoryName(category))] \(message)")
        #else
        os_log(.debug, log: category.log, "%{public}@", message)
        #endif
    }
    
    /// Log info message
    static func info(_ message: String, category: Category = .general) {
        #if DEBUG
        print("[INFO][\(categoryName(category))] \(message)")
        #else
        os_log(.info, log: category.log, "%{public}@", message)
        #endif
    }
    
    /// Log error message (always logged)
    static func error(_ message: String, error: Error? = nil, category: Category = .general) {
        let fullMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        
        #if DEBUG
        print("[ERROR][\(categoryName(category))] \(fullMessage)")
        #else
        os_log(.error, log: category.log, "%{public}@", fullMessage)
        #endif
    }
    
    /// Log sensitive data (never logged in production)
    static func sensitive(_ message: String, category: Category = .general) {
        #if DEBUG
        print("[SENSITIVE][\(categoryName(category))] \(message)")
        #endif
        // Intentionally not logged in production
    }
    
    private static func categoryName(_ category: Category) -> String {
        switch category {
        case .auth: return "Auth"
        case .network: return "Network"
        case .ui: return "UI"
        case .data: return "Data"
        case .general: return "General"
        }
    }
}

// MARK: - Usage Examples
/*
 // Debug info (removed in production)
 Logger.debug("User tapped generate button")
 
 // Important info (kept in production)
 Logger.info("Session refreshed successfully", category: .auth)
 
 // Errors (always logged + sent to Sentry)
 Logger.error("Failed to load preferences", error: error, category: .data)
 
 // Sensitive data (NEVER in production)
 Logger.sensitive("Access token: \(token)", category: .auth)
 */
