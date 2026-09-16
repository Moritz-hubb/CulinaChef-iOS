import Foundation

enum Config {
    // MARK: - Environment Configuration
    
    /// Current environment - change this for different builds
    /// - development: Local development (localhost/simulator)
    /// - staging: Test environment (optional)
    /// - production: Live App Store version
    enum Environment {
        case development
        case staging
        case production
    }
    
    #if DEBUG
    static let currentEnvironment: Environment = .development
    #else
    static let currentEnvironment: Environment = .production
    #endif
    
    // MARK: - Supabase Configuration
    
    /// Parses `SupabaseURL` from an Info.plist dictionary. Returns nil instead of a fake host.
    static func resolvedSupabaseURL(from infoDictionary: [String: Any]?) -> URL? {
        guard let urlString = infoDictionary?["SupabaseURL"] as? String else { return nil }
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$") else { return nil }
        guard let url = URL(string: trimmed), url.scheme?.lowercased() == "https" else { return nil }
        let host = url.host?.lowercased() ?? ""
        if host == "placeholder.supabase.co" || host.hasSuffix(".placeholder.supabase.co") {
            return nil
        }
        return url
    }

    /// Supabase URL loaded from Info.plist (configured via Build Settings or xcconfig).
    /// Missing/invalid values must not silently talk to a placeholder host.
    static let supabaseURL: URL = {
        if let url = resolvedSupabaseURL(from: Bundle.main.infoDictionary) {
            return url
        }
        Logger.error("SupabaseURL not configured in Info.plist.", category: .config)
        #if DEBUG
        return URL(string: "https://invalid.invalid")!
        #else
        preconditionFailure("SupabaseURL must be a https URL in Info.plist (Secrets.xcconfig)")
        #endif
    }()
    
    /// Supabase Anon Key loaded from Info.plist (configured via Build Settings or xcconfig)
    /// 
    /// ⚠️ SECURITY NOTE: This is the public "anon" key from Supabase.
    /// It's designed to be public and is safe to expose in client apps.
    /// Row Level Security (RLS) policies protect your data on the server.
    /// DO NOT expose the "service_role" key!
    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
              !key.isEmpty,
              !key.hasPrefix("$") else {
            Logger.error("SupabaseAnonKey not configured in Info.plist. App may not function correctly.", category: .config)
            // Return empty string - authentication will fail gracefully
            return ""
        }
        return key
    }()
    
    // MARK: - Backend URL (Environment-based)

    static let productionBackendURL = URL(string: "https://culinachef-backend-production.up.railway.app")!
    static let developmentBackendURL = URL(string: "http://127.0.0.1:8000")!
    static let stagingBackendURL = URL(string: "https://staging-api.culinaai.com")!

    static var backendBaseURL: URL {
        backendBaseURL(for: currentEnvironment)
    }

    /// Development talks to localhost unless `CULINA_BACKEND_URL` is set. Production is never overridden.
    static func backendBaseURL(
        for environment: Environment,
        processEnv: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL {
        switch environment {
        case .development:
            if let override = resolvedBackendOverride(processEnv["CULINA_BACKEND_URL"]) {
                return override
            }
            return developmentBackendURL
        case .staging:
            return stagingBackendURL
        case .production:
            return productionBackendURL
        }
    }

    static func resolvedBackendOverride(_ raw: String?) -> URL? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$") else { return nil }
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else { return nil }
        guard scheme == "http" || scheme == "https" else { return nil }
        return url
    }
    
    // MARK: - Feature Flags
    
    /// Enable debug logging
    static var enableDebugLogging: Bool {
        currentEnvironment == .development
    }
    
    /// Enable Sentry error tracking
    static var enableSentry: Bool {
        currentEnvironment != .development
    }

    /// Check if we're in a development/testing environment where backend validation might not work
    /// (Development builds, TestFlight, or staging)
    /// In these environments, StoreKit should be trusted as the primary source
    static var shouldUseStoreKitAsPrimary: Bool {
        #if DEBUG
        return true // Always use StoreKit in DEBUG builds
        #else
        // In Release builds, check if we're in TestFlight or staging
        // TestFlight can be detected by checking for app store receipt
        if currentEnvironment == .staging {
            return true
        }
        // In production, only use StoreKit as fallback (backend validates with Apple)
        return false
        #endif
    }
    
    // MARK: - RevenueCat Configuration
    
    /// RevenueCat public SDK key from Info.plist (`Secrets.xcconfig`).
    /// Release/TestFlight must use an Apple key (`appl_`). A Test Store key (`test_`)
    /// makes RevenueCat call `fatalError` on configure and crashes the app on launch.
    static let revenueCatAPIKey: String = {
        let raw: String?
        if let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
           !key.isEmpty,
           !key.hasPrefix("$") {
            raw = key
        } else {
            raw = nil
        }
        #if DEBUG
        return sanitizedRevenueCatAPIKey(raw, allowTestStoreKey: true)
        #else
        return sanitizedRevenueCatAPIKey(raw, allowTestStoreKey: false)
        #endif
    }()
    
    /// Superwall public API key from Info.plist (`Secrets.xcconfig`).
    static let superwallAPIKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "SuperwallAPIKey") as? String,
           !key.isEmpty,
           !key.hasPrefix("$") {
            return key
        }
        Logger.warning("SuperwallAPIKey not configured in Info.plist. Superwall paywalls will not show.", category: .config)
        return ""
    }()
    
    static var isSuperwallConfigured: Bool {
        !superwallAPIKey.isEmpty
    }
    
    static var isRevenueCatConfigured: Bool {
        !revenueCatAPIKey.isEmpty
    }
    
    /// HTTPS Universal Link for Supabase password recovery (`redirect_to`).
    /// Allowlist this URL in the Supabase Auth redirect settings. Never use a custom scheme.
    static let passwordResetRedirectURL = URL(string: "https://culinaai.com/reset-password")!

    /// Release builds must never configure RevenueCat with a Test Store key (`test_`).
    static func sanitizedRevenueCatAPIKey(_ raw: String?, allowTestStoreKey: Bool) -> String {
        guard let raw, !raw.isEmpty, !raw.hasPrefix("$") else {
            if allowTestStoreKey {
                Logger.warning("RevenueCatAPIKey not configured in Info.plist.", category: .config)
            } else {
                Logger.error("RevenueCatAPIKey not configured in Info.plist. RevenueCat will not work in production!", category: .config)
            }
            return ""
        }
        if !allowTestStoreKey, raw.hasPrefix("test_") {
            Logger.error(
                "RevenueCat Test Store API key (test_…) is not allowed in Release/TestFlight. Use the Apple public SDK key (appl_…) from RevenueCat → Apps → Apple.",
                category: .config
            )
            return ""
        }
        return raw
    }

    static func isProductionPasswordResetRedirect(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
            && PasswordResetLink.isAllowedHost(url.host)
            && (url.path == "/reset-password" || url.path.hasPrefix("/reset-password/"))
    }

    // MARK: - API Timeouts
    
    /// Zeit zwischen Datenpaketen für typische API-Calls.
    static let apiTimeout: TimeInterval = 90.0
    /// Gesamtzeit pro URLSession-Task (muss ≥ längste Einzelanfrage sein, z. B. Social-Import).
    static let imageUploadTimeout: TimeInterval = 180.0
    /// `POST /ai/import-from-social-url` und Metadaten-Vorschau (KI + langsames Netz).
    static let socialImportAPITimeout: TimeInterval = 120.0
}
