import Foundation
import os

/// Production-safe logging.
///
/// - `debug` is compiled out of Release (no Unified Log entry).
/// - `info` / `warning` / `error` use private Unified Log privacy so Console/MDM
///   cannot read interpolated strings without a debug profile.
/// - `sensitive` is Debug-only.
enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.culinaai.culinachef"

    enum Category {
        case auth, network, ui, data, config, general
    }

    /// Debug-only. No-op in Release — never written to Unified Logging.
    static func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        print("[DEBUG][\(categoryName(category))] \(message)")
        #endif
    }

    static func info(_ message: String, category: Category = .general) {
        #if DEBUG
        print("[INFO][\(categoryName(category))] \(message)")
        #else
        osLogger(category).info("\(message, privacy: .private)")
        #endif
    }

    static func warning(_ message: String, category: Category = .general) {
        #if DEBUG
        print("[WARNING][\(categoryName(category))] \(message)")
        #else
        osLogger(category).warning("\(message, privacy: .private)")
        #endif
    }

    static func error(_ message: String, error: Error? = nil, category: Category = .general) {
        let fullMessage = error.map { "\(message): \($0.localizedDescription)" } ?? message
        #if DEBUG
        print("[ERROR][\(categoryName(category))] \(fullMessage)")
        #else
        osLogger(category).error("\(fullMessage, privacy: .private)")
        #endif
    }

    /// Never written in Release.
    static func sensitive(_ message: String, category: Category = .general) {
        #if DEBUG
        print("[SENSITIVE][\(categoryName(category))] \(message)")
        #endif
    }

    private static func osLogger(_ category: Category) -> os.Logger {
        os.Logger(subsystem: subsystem, category: categoryName(category).lowercased())
    }

    private static func categoryName(_ category: Category) -> String {
        switch category {
        case .auth: return "Auth"
        case .network: return "Network"
        case .ui: return "UI"
        case .data: return "Data"
        case .config: return "Config"
        case .general: return "General"
        }
    }
}
