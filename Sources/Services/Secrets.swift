import Foundation

enum Secrets {
    static func openAIAPIKey() -> String? {
        // Prefer Info.plist key (build-time substitution), fallback to runtime env var
        if let key = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String, !key.isEmpty, !key.hasPrefix("$") {
            return key
        }
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
}
