import Foundation

/// Superwall must never receive auth secrets. Only scheme://host/path is forwarded.
enum SuperwallDeepLink {
    /// `nil` means do not call Superwall (reset links, or a URL that cannot be stripped safely).
    static func urlToForward(_ url: URL) -> URL? {
        guard !PasswordResetLink.isResetURL(url) else { return nil }
        return strippedQueryAndFragment(url)
    }

    static func strippedQueryAndFragment(_ url: URL) -> URL? {
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        if !url.path.isEmpty {
            components.path = url.path
        }
        guard let sanitized = components.url else { return nil }
        if let query = sanitized.query, !query.isEmpty { return nil }
        if let fragment = sanitized.fragment, !fragment.isEmpty { return nil }
        return sanitized
    }
}
