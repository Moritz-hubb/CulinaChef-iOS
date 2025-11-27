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
    
    // MARK: - API Timeouts
    
    static let apiTimeout: TimeInterval = 30.0
    static let imageUploadTimeout: TimeInterval = 60.0
}
