import Foundation

/// Password-reset links must be HTTPS Universal Links, never custom URL schemes.
enum PasswordResetLink {
    static let redirectURL = URL(string: "https://culinaai.com/reset-password")!
    static let codeVerifierKeychainKey = "password_reset_code_verifier"

    enum Parsed: Equatable {
        case pkce(code: String)
        case implicit(accessToken: String, refreshToken: String)
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
        if let access = firstValue("access_token", in: items),
           let refresh = firstValue("refresh_token", in: items),
           !access.isEmpty,
           !refresh.isEmpty {
            return .implicit(accessToken: access, refreshToken: refresh)
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
