import Foundation

/// Shared `URLSession` with app-wide timeouts. Tests can inject a mock configuration.
final class SecureURLSession {
    static let shared = SecureURLSession()

    /// Für Tests: Erlaubt das Injizieren einer benutzerdefinierten `URLSessionConfiguration`.
    static var testConfiguration: URLSessionConfiguration?

    private lazy var session: URLSession = {
        if let testConfig = SecureURLSession.testConfiguration {
            return URLSession(configuration: testConfig)
        }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Config.apiTimeout
        config.timeoutIntervalForResource = Config.imageUploadTimeout
        config.waitsForConnectivity = false
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        return URLSession(configuration: config)
    }()

    private init() {}

    /// Convenience wrapper so call sites don't need to access the underlying URLSession.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
