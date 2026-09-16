import Foundation

/// Password-reset links must be HTTPS Universal Links, never custom URL schemes.
enum PasswordResetLink {
    static let redirectURL = URL(string: "https://culinaai.com/reset-password")!
    static let codeVerifierKeychainKey = "password_reset_code_verifier"

    enum Parsed: Equatable {
        case pkce(code: String)
        case rejectedImplicit
        case rejectedCustomScheme
        case missingCredentials
        case notAResetLink
    }

    static func isAllowedHost(_ host: String?) -> Bool {
        host == "culinaai.com" || host == "www.culinaai.com"
    }

    static func isResetURL(_ url: URL) -> Bool {
        if url.scheme == "culinachef" {
            return url.host == "reset-password" || url.path.contains("reset-password")
        }
        guard url.scheme == "https", isAllowedHost(url.host) else { return false }
        return url.path.hasPrefix("/reset-password") || url.pathComponents.contains("reset-password")
    }

    static func parse(_ url: URL) -> Parsed {
        guard isResetURL(url) else { return .notAResetLink }

        if url.scheme == "culinachef" {
            return .rejectedCustomScheme
        }
        guard url.scheme == "https", isAllowedHost(url.host) else {
            return .rejectedCustomScheme
        }

        let items = queryAndFragmentItems(from: url)
        if let code = firstValue("code", in: items), !code.isEmpty {
            return .pkce(code: code)
        }
        let hasAccess = firstValue("access_token", in: items).map { !$0.isEmpty } ?? false
        let hasRefresh = firstValue("refresh_token", in: items).map { !$0.isEmpty } ?? false
        if hasAccess || hasRefresh {
            return .rejectedImplicit
        }
        return .missingCredentials
    }

    /// Host + path only. Never include query or fragment (tokens / PKCE codes).
    static func safeDescription(_ url: URL) -> String {
        let host = url.host ?? ""
        let path = url.path.isEmpty ? "/" : url.path
        let scheme = url.scheme ?? ""
        return "\(scheme)://\(host)\(path)"
    }

    private static func queryAndFragmentItems(from url: URL) -> [URLQueryItem] {
        var items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if let fragment = url.fragment, !fragment.isEmpty,
           let fragmentItems = URLComponents(string: "https://culinaai.com?\(fragment)")?.queryItems {
            items.append(contentsOf: fragmentItems)
        }
        return items
    }

    private static func firstValue(_ name: String, in items: [URLQueryItem]) -> String? {
        items.first(where: { $0.name == name })?.value
    }
}

/// Stores PKCE verifiers for in-flight password resets.
/// Resend for the same email replaces that email's verifier. A second email on the
/// same device keeps both (capped) so an earlier mail can still be exchanged.
enum PasswordResetPKCEStore {
    struct Entry: Codable, Equatable {
        var email: String
        var verifier: String
    }

    static let maxEntries = 3

    static func snapshot() -> [Entry] {
        load()
    }

    static func restore(_ entries: [Entry]) throws {
        if entries.isEmpty {
            clear()
            return
        }
        try KeychainManager.save(key: PasswordResetLink.codeVerifierKeychainKey, value: encode(entries))
    }

    static func upsert(verifier: String, email: String) throws {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var entries = load().filter { $0.email != normalized }
        entries.append(Entry(email: normalized, verifier: verifier))
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }
        try restore(entries)
    }

    static func verifiersNewestFirst() -> [String] {
        load().reversed().map(\.verifier).filter { !$0.isEmpty }
    }

    static func clear() {
        KeychainManager.delete(key: PasswordResetLink.codeVerifierKeychainKey)
    }

    private static func load() -> [Entry] {
        guard let raw = KeychainManager.get(key: PasswordResetLink.codeVerifierKeychainKey),
              !raw.isEmpty else {
            return []
        }
        if let data = raw.data(using: .utf8),
           let entries = try? JSONDecoder().decode([Entry].self, from: data) {
            return entries
        }
        return [Entry(email: "", verifier: raw)]
    }

    private static func encode(_ entries: [Entry]) -> String {
        let data = (try? JSONEncoder().encode(entries)) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}
