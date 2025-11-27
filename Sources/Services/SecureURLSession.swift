import Foundation
import Security

/// Shared URLSession with REQUIRED SSL pinning for critical hosts (Supabase, Backend).
///
/// - Pins certificates by comparing the server leaf certificate data with `.cer` files
///   in the app bundle.
/// - SSL pinning is REQUIRED in production builds - missing certificates will cause a fatal error.
/// - In debug builds, missing certificates will log a warning but allow the build to continue.
final class SecureURLSession: NSObject, URLSessionDelegate {
    /// Global Singleton-Instanz, die in der gesamten App für Netzwerkzugriffe verwendet wird.
    static let shared = SecureURLSession()
    
    /// Für Tests: Erlaubt das Injizieren einer benutzerdefinierten `URLSessionConfiguration`.
    ///
    /// Wenn dieser Wert gesetzt ist, wird keine SSL-Pinning-Validierung durchgeführt,
    /// damit Integrationstests einfach gegen Mock-Server laufen können.
    static var testConfiguration: URLSessionConfiguration?

    /// Pinned Zertifikate, gruppiert nach Hostname.
    /// Der Key ist der Host (z.B. `xyz.supabase.co`), der Wert eine Liste der erlaubten Zertifikatdaten.
    private let pinnedCertificates: [String: [Data]] // host -> [certData]

    /// Lazily created URLSession so that we can safely use `self` as delegate
    /// ohne rekursiv die Singleton-Instanz erneut zu initialisieren.
    private lazy var session: URLSession = {
        let config: URLSessionConfiguration
        let delegate: URLSessionDelegate?
        
        if let testConfig = SecureURLSession.testConfiguration {
            config = testConfig
            delegate = nil  // Disable SSL pinning in tests
        } else {
            config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = Config.apiTimeout
            config.timeoutIntervalForResource = Config.imageUploadTimeout
            config.waitsForConnectivity = true
            delegate = self
        }
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }()

    private override init() {
        // Prepare pinned certs - REQUIRED in production
        var pins: [String: [Data]] = [:]
        
        // Supabase certificate - REQUIRED
        guard let supabaseHost = Config.supabaseURL.host else {
            #if DEBUG
            Logger.error("Supabase host not configured", category: .config)
            #else
            fatalError("SSL Pinning: Supabase host not configured - this is a build configuration error")
            #endif
            super.init()
            self.pinnedCertificates = [:]
            return
        }
        
        guard let supabaseCert = SecureURLSession.loadCertificate(named: "supabase") else {
            #if DEBUG
            Logger.error("Supabase SSL certificate not found in bundle - SSL pinning disabled", category: .config)
            #else
            fatalError("SSL Pinning: Supabase certificate (supabase.cer) not found in bundle - required for production builds")
            #endif
            super.init()
            self.pinnedCertificates = [:]
            return
        }
        pins[supabaseHost] = [supabaseCert]
        
        // Backend certificate - REQUIRED
        let backendHost = Config.backendBaseURL.host
        if let backendCert = SecureURLSession.loadCertificate(named: "backend") {
            if let host = backendHost {
                pins[host] = [backendCert]
                Logger.info("SSL Pinning: Backend certificate loaded for host: \(host)", category: .config)
            }
        } else {
            Logger.error("Backend SSL certificate not found in bundle - SSL pinning disabled for backend", category: .config)
            Logger.error("Backend host: \(backendHost ?? "nil")", category: .config)
            #if !DEBUG
            fatalError("SSL Pinning: Backend certificate (backend.cer) not found in bundle - required for production builds")
            #endif
        }
        
        self.pinnedCertificates = pins
        super.init()
    }

    /// Convenience wrapper so call sites don't need to access the underlying URLSession.
    ///
    /// - Parameter request: Vollständig vorbereiteter `URLRequest`.
    /// - Returns: Antwortdaten und `URLResponse` des Servers.
    /// - Throws: Fehler aus `URLSession.data(for:)`, z.B. `URLError`.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }

    // MARK: - URLSessionDelegate (SSL pinning)

    /// Validiert TLS-Verbindungen und führt SSL-Pinning durch.
    ///
    /// Für gepinnte Hosts (Supabase, Backend) wird das Zertifikat validiert.
    /// Wenn kein Pin für einen Host konfiguriert ist, wird die Standard-Systemvalidierung verwendet.
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // If we have no pins for this host, let the system handle it
        guard let pinnedForHost = pinnedCertificates[host], !pinnedForHost.isEmpty else {
            Logger.info("No SSL pinning for host: \(host) - using system validation", category: .network)
            completionHandler(.performDefaultHandling, nil)
            return
        }

        #if DEBUG
        Logger.debug("Validating SSL pinning for host: \(host)", category: .network)
        #endif

        // Evaluate the server trust using the system's default policy first
        var error: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)
        guard isTrusted else {
            #if DEBUG
            Logger.error("SSL trust evaluation failed for \(host): \(error?.localizedDescription ?? "unknown error")", category: .network)
            #endif
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Compare the server leaf certificate with our pinned certs
        guard let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            #if DEBUG
            Logger.error("Could not get server certificate for \(host)", category: .network)
            #endif
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let serverCertData = SecCertificateCopyData(serverCert) as Data

        if pinnedForHost.contains(serverCertData) {
            #if DEBUG
            Logger.debug("SSL pinning successful for \(host)", category: .network)
            #endif
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Certificate mismatch – fail the connection for this host
            #if DEBUG
            Logger.error("SSL pinning failed for \(host): Certificate mismatch", category: .network)
            // In DEBUG builds, allow connection to proceed for testing
            Logger.warning("DEBUG: Allowing connection despite certificate mismatch", category: .network)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            #else
            completionHandler(.cancelAuthenticationChallenge, nil)
            #endif
        }
    }

    // MARK: - Helpers

    /// Lädt eine `.cer`-Datei aus dem Bundle und gibt deren Daten zurück.
    ///
    /// - Parameter name: Dateiname ohne Erweiterung.
    /// - Returns: Binärdaten des Zertifikats oder `nil`, falls nicht gefunden.
    private static func loadCertificate(named name: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "cer") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}
