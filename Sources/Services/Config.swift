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
    
    static let supabaseURL = URL(string: "https://ywduddopwudltshxiqyp.supabase.co")!
    
    // ⚠️ SECURITY NOTE: This is the public "anon" key from Supabase.
    // It's designed to be public and is safe to expose in client apps.
    // Row Level Security (RLS) policies protect your data on the server.
    // DO NOT expose the "service_role" key!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3ZHVkZG9wd3VkbHRzaHhpcXlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2Nzk5MTEsImV4cCI6MjA3NzI1NTkxMX0.DvGlgWnMp42dBO7mF43nQTNT4AvmAqBc9ElBmOO5U6c"
    
    // MARK: - Backend URL (Environment-based)
    
    static var backendBaseURL: URL {
        switch currentEnvironment {
        case .development:
            // Development: Localhost for simulator, LAN IP for device
            // HTTP is only allowed in DEBUG builds
            #if DEBUG
                #if targetEnvironment(simulator)
                return URL(string: "http://127.0.0.1:8000")!
                #else
                return URL(string: "http://192.168.178.170:8000")!
                #endif
            #else
                // Fallback to HTTPS in Release builds even for development environment
                return URL(string: "https://culinachef-backend-production.up.railway.app")!
            #endif
            
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
    
    // MARK: - API Timeouts
    
    static let apiTimeout: TimeInterval = 30.0
    static let imageUploadTimeout: TimeInterval = 60.0
}
