import Foundation
import Security

/// Shared URLSession with optional SSL pinning for critical hosts (Supabase, Backend).
///
/// - Pins certificates by comparing the server leaf certificate data with `.cer` files
///   in the app bundle.
/// - If no pin is configured for a host, falls back to default system trust evaluation.
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
        // Prepare pinned certs (if present in bundle)
        var pins: [String: [Data]] = [:]

        if let supabaseHost = Config.supabaseURL.host,
           let cert = SecureURLSession.loadCertificate(named: "supabase") {
            pins[supabaseHost] = [cert]
        }

        if let backendHost = Config.backendBaseURL.host,
           let cert = SecureURLSession.loadCertificate(named: "backend") {
            pins[backendHost] = [cert]
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

    /// Validiert TLS-Verbindungen und führt optional SSL-Pinning durch.
    ///
    /// Wenn für den Host kein Pin konfiguriert ist, wird die Standard-Systemvalidierung verwendet.
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
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate the server trust using the system's default policy first
        var error: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)
        guard isTrusted else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Compare the server leaf certificate with our pinned certs
        guard let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let serverCertData = SecCertificateCopyData(serverCert) as Data

        if pinnedForHost.contains(serverCertData) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Certificate mismatch – fail the connection for this host
            completionHandler(.cancelAuthenticationChallenge, nil)
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
