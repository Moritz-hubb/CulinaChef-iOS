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
    
    /// Supabase URL loaded from Info.plist (configured via Build Settings or xcconfig)
    static let supabaseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let url = URL(string: urlString) else {
            Logger.error("SupabaseURL not configured in Info.plist. Using fallback URL.", category: .config)
            // Fallback to a placeholder URL - app will fail gracefully with network errors
            return URL(string: "https://placeholder.supabase.co")!
        }
        return url
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
    
    static var backendBaseURL: URL {
        switch currentEnvironment {
        case .development:
            // Development: Use production backend for local testing
            // Change to localhost if you want to test with local backend
            // #if targetEnvironment(simulator)
            // return URL(string: "http://127.0.0.1:8000")!
            // #else
            // return URL(string: "http://192.168.178.170:8000")!
            // #endif
                return URL(string: "https://culinachef-backend-production.up.railway.app")!
            
        case .staging:
            // Staging environment (optional - for testing before production)
            // Set the staging backend URL here when available
            return URL(string: "https://staging-api.culinaai.com")!
            
        case .production:
            // Production environment (live App Store version)
            return URL(string: "https://culinachef-backend-production.up.railway.app")!
        }
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

    // MARK: - Security / SSL Pinning (SPKI – Public Key Hash Pinning)
    
    /// Whether SSL public key pinning should be enforced.
    /// Uses SPKI (Subject Public Key Info) hashes instead of full certificate data,
    /// which survives certificate rotations when the server reuses the same key pair.
    /// If a pin mismatch occurs but system trust passes, the connection is still
    /// allowed (graceful degradation) to prevent the app from breaking on cert rotation.
    static var enableSSLPinning: Bool {
        currentEnvironment == .production
    }
    
    /// Whether Supabase traffic should be pinned.
    static var enableSupabasePinning: Bool {
        false
    }
    
    /// Base64-encoded SHA-256 hashes of the backend server's SPKI.
    /// Generate with: `./ios/scripts/download_ssl_certificates.sh`
    /// Include both the current and a backup hash for smoother key rotations.
    static let backendPublicKeyHashes: Set<String> = [
        "VYxe9LAwK2QozwAdcQXon+QWur/Wn6o01PdWoMq1jiw=",  // Current (as of 2026-04-08)
    ]
    
    /// Base64-encoded SHA-256 hashes of the Supabase server's SPKI.
    /// Only used when `enableSupabasePinning` is true.
    static let supabasePublicKeyHashes: Set<String> = []
    
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
        let raw: String
        if let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
           !key.isEmpty,
           !key.hasPrefix("$") {
            raw = key
        } else {
            #if DEBUG
            Logger.warning("RevenueCatAPIKey not configured in Info.plist. Using test key for development.", category: .config)
            raw = "test_nYAqGXmJwAhLGWnwCXWzRyQjWsk"
            #else
            Logger.error("RevenueCatAPIKey not configured in Info.plist. RevenueCat will not work in production!", category: .config)
            return ""
            #endif
        }
        
        #if DEBUG
        return raw
        #else
        if raw.hasPrefix("test_") {
            Logger.error(
                "RevenueCat Test Store API key (test_…) is not allowed in Release/TestFlight. Use the Apple public SDK key (appl_…) from RevenueCat → Apps → Apple.",
                category: .config
            )
            return ""
        }
        return raw
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
    
    // MARK: - API Timeouts
    
    /// Zeit zwischen Datenpaketen für typische API-Calls.
    static let apiTimeout: TimeInterval = 30.0
    /// Gesamtzeit pro URLSession-Task (muss ≥ längste Einzelanfrage sein, z. B. Social-Import).
    static let imageUploadTimeout: TimeInterval = 180.0
    /// `POST /ai/import-from-social-url` und Metadaten-Vorschau (KI + langsames Netz).
    static let socialImportAPITimeout: TimeInterval = 120.0
}
