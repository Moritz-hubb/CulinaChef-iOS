import Foundation
import Security
import CryptoKit

/// URLSession with Subject Public Key Info (SPKI) pinning for critical hosts.
///
/// Uses **public key hash pinning** instead of full certificate pinning.
/// Public key hashes survive certificate rotations as long as the server
/// reuses the same key pair (common with Let's Encrypt renewals).
///
/// **Graceful degradation:** When a pin mismatch occurs but system trust
/// validation passes (i.e. the certificate is valid, just rotated),
/// the connection is allowed with a warning logged. This prevents the app
/// from breaking when managed hosting platforms (Railway, Supabase) rotate
/// certificates outside of our control.
final class SecureURLSession: NSObject, URLSessionDelegate {

    static let shared = SecureURLSession()

    /// Für Tests: Erlaubt das Injizieren einer benutzerdefinierten `URLSessionConfiguration`.
    /// Wenn gesetzt, wird keine SSL-Pinning-Validierung durchgeführt.
    static var testConfiguration: URLSessionConfiguration?

    /// Pinned SPKI SHA-256 hashes, grouped by hostname.
    /// Key = host (e.g. `culinachef-backend-production.up.railway.app`),
    /// Value = set of base64-encoded SHA-256 hashes of the server's SPKI.
    private let pinnedKeyHashes: [String: Set<String>]

    private lazy var session: URLSession = {
        let config: URLSessionConfiguration
        let delegate: URLSessionDelegate?

        if let testConfig = SecureURLSession.testConfiguration {
            config = testConfig
            delegate = nil
        } else {
            config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = Config.apiTimeout
            config.timeoutIntervalForResource = Config.imageUploadTimeout
            config.waitsForConnectivity = false
            config.allowsCellularAccess = true
            config.allowsConstrainedNetworkAccess = true
            config.allowsExpensiveNetworkAccess = true
            delegate = self
        }
        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }()

    // MARK: - ASN.1 Headers for SPKI encoding

    // Prepended to raw public key data to form proper SubjectPublicKeyInfo
    // before hashing, matching the output of `openssl x509 -pubkey`.

    private static let rsa2048ASN1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]

    private static let rsa4096ASN1Header: [UInt8] = [
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00
    ]

    private static let ecDsaSecp256r1ASN1Header: [UInt8] = [
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
        0x42, 0x00
    ]

    private static let ecDsaSecp384r1ASN1Header: [UInt8] = [
        0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00
    ]

    // MARK: - Initialization

    private override init() {
        if !Config.enableSSLPinning {
            self.pinnedKeyHashes = [:]
            super.init()
            Logger.info("SSL Pinning disabled by config", category: .config)
            return
        }

        var pins: [String: Set<String>] = [:]

        if let host = Config.backendBaseURL.host {
            let hashes = Config.backendPublicKeyHashes
            if !hashes.isEmpty {
                pins[host] = hashes
                Logger.info("SSL Pinning: \(hashes.count) public key pin(s) for backend host: \(host)", category: .config)
            } else {
                Logger.warning("SSL Pinning: No public key hashes configured for backend host: \(host)", category: .config)
            }
        }

        if Config.enableSupabasePinning, let host = Config.supabaseURL.host {
            let hashes = Config.supabasePublicKeyHashes
            if !hashes.isEmpty {
                pins[host] = hashes
                Logger.info("SSL Pinning: \(hashes.count) public key pin(s) for Supabase host: \(host)", category: .config)
            }
        }

        self.pinnedKeyHashes = pins
        super.init()
    }

    /// Convenience wrapper so call sites don't need to access the underlying URLSession.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }

    // MARK: - URLSessionDelegate (SSL Pinning)

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        guard let expectedHashes = pinnedKeyHashes[host], !expectedHashes.isEmpty else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Step 1: System trust validation (baseline – blocks expired / untrusted certs)
        var error: CFError?
        let systemTrusted = SecTrustEvaluateWithError(serverTrust, &error)

        guard systemTrusted else {
            Logger.error("SSL: System trust evaluation failed for \(host): \(error?.localizedDescription ?? "unknown")", category: .network)
            #if DEBUG
            Logger.warning("DEBUG: Allowing connection despite trust evaluation failure", category: .network)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            #else
            completionHandler(.cancelAuthenticationChallenge, nil)
            #endif
            return
        }

        // Step 2: SPKI hash comparison
        let serverHash = Self.publicKeyHash(from: serverTrust)

        if let hash = serverHash, expectedHashes.contains(hash) {
            Logger.info("SSL Pinning: Public key pin matched for \(host)", category: .network)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }

        // Step 3: Pin mismatch, but system-trusted → graceful degradation.
        // The certificate is valid per system CA trust (not a MITM attack),
        // but the public key has rotated. Allow connection and log a warning
        // so we can update the pinned hashes in the next release.
        Logger.error(
            "SSL Pinning: Public key mismatch for \(host). " +
            "Server SPKI hash: \(serverHash ?? "unavailable"). " +
            "Connection allowed via system trust (graceful degradation). " +
            "Update Config.backendPublicKeyHashes with the new hash.",
            category: .network
        )

        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }

    // MARK: - SPKI Hashing

    /// Extracts the base64-encoded SHA-256 hash of the leaf certificate's
    /// Subject Public Key Info (SPKI).
    private static func publicKeyHash(from trust: SecTrust) -> String? {
        let cert: SecCertificate?
        if #available(iOS 15.0, *) {
            cert = (SecTrustCopyCertificateChain(trust) as? [SecCertificate])?.first
        } else {
            cert = SecTrustGetCertificateAtIndex(trust, 0)
        }

        guard let leafCert = cert,
              let publicKey = SecCertificateCopyKey(leafCert),
              let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        let header = asn1Header(for: publicKey)
        var spkiData = Data(header)
        spkiData.append(keyData)

        let hash = SHA256.hash(data: spkiData)
        return Data(hash).base64EncodedString()
    }

    /// Returns the appropriate ASN.1 header based on key type and size.
    private static func asn1Header(for key: SecKey) -> [UInt8] {
        guard let attributes = SecKeyCopyAttributes(key) as? [String: Any],
              let keyType = attributes[kSecAttrKeyType as String] as? String,
              let keySize = attributes[kSecAttrKeySizeInBits as String] as? Int else {
            return rsa2048ASN1Header
        }

        if keyType == (kSecAttrKeyTypeRSA as String) {
            return keySize > 2048 ? rsa4096ASN1Header : rsa2048ASN1Header
        } else if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) {
            return keySize > 256 ? ecDsaSecp384r1ASN1Header : ecDsaSecp256r1ASN1Header
        }

        return rsa2048ASN1Header
    }
}
