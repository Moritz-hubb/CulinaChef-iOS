import Foundation

/// Parses FastAPI error bodies and maps subscription denials to a stable NSError.
enum BackendHTTPError {
    static let subscriptionDomain = "CulinaChef.Subscription"
    static let subscriptionRequiredCode = 403
    static let errorCodeKey = "error_code"

    static func isSubscriptionRequired(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == subscriptionDomain && ns.code == subscriptionRequiredCode {
            return true
        }
        if ns.code == 403 {
            let text = ns.localizedDescription.lowercased()
            if text.contains("subscription_required") || text.contains("aktives abo") {
                return true
            }
        }
        return ns.localizedDescription.lowercased().contains("subscription_required")
    }

    static func make(statusCode: Int, data: Data) -> Error {
        if let code = extractErrorCode(from: data), code == "SUBSCRIPTION_REQUIRED" {
            let message = extractMessage(from: data) ?? L.error_aiChatRestricted.localized
            return NSError(
                domain: subscriptionDomain,
                code: subscriptionRequiredCode,
                userInfo: [
                    NSLocalizedDescriptionKey: message,
                    errorCodeKey: code
                ]
            )
        }
        if let message = extractMessage(from: data), !message.isEmpty {
            return NSError(domain: "Backend", code: statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
            return NSError(domain: "Backend", code: statusCode, userInfo: [NSLocalizedDescriptionKey: raw])
        }
        return URLError(.badServerResponse)
    }

    private static func extractErrorCode(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let detail = obj["detail"] as? [String: Any], let code = detail["error_code"] as? String {
            return code
        }
        return obj["error_code"] as? String
    }

    private static func extractMessage(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let detail = obj["detail"] as? String, !detail.isEmpty {
            return detail
        }
        if let detail = obj["detail"] as? [String: Any] {
            if let message = detail["message"] as? String, !message.isEmpty {
                return message
            }
        }
        if let error = obj["error"] as? [String: Any], let message = error["message"] as? String, !message.isEmpty {
            return message
        }
        return nil
    }
}
