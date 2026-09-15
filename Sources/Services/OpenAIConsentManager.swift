import Foundation

/// Per-user OpenAI/GDPR consent stored in UserDefaults, keyed by Keychain `user_id`.
enum OpenAIConsentManager {
    static let consentChangedNotification = Notification.Name("OpenAIConsentChanged")

    private static let consentKeyPrefix = "openai_consent_granted_"

    static func storageKey(for userId: String) -> String {
        "\(consentKeyPrefix)\(userId)"
    }

    static var hasConsent: Bool {
        get { hasConsent(for: KeychainManager.get(key: "user_id")) }
        set { setConsent(newValue, for: KeychainManager.get(key: "user_id")) }
    }

    static func hasConsent(for userId: String?) -> Bool {
        guard let userId, !userId.isEmpty else { return false }
        return UserDefaults.standard.bool(forKey: storageKey(for: userId))
    }

    static func setConsent(_ granted: Bool, for userId: String?) {
        guard let userId, !userId.isEmpty else {
            Logger.debug("[OpenAIConsent] Cannot save consent: no user_id", category: .auth)
            return
        }
        UserDefaults.standard.set(granted, forKey: storageKey(for: userId))
        Logger.sensitive("[OpenAIConsent] Consent set to \(granted) for user \(userId)", category: .auth)
        postChange(granted)
    }

    /// Resets consent for the currently logged-in user (Keychain `user_id`).
    static func resetConsent() {
        resetConsent(for: KeychainManager.get(key: "user_id"))
    }

    /// Resets consent for a known user id (logout/delete, before Keychain wipe).
    static func resetConsent(for userId: String?) {
        guard let userId, !userId.isEmpty else {
            Logger.debug("[OpenAIConsent] Cannot reset consent: no user_id", category: .auth)
            return
        }
        UserDefaults.standard.removeObject(forKey: storageKey(for: userId))
        Logger.sensitive("[OpenAIConsent] Reset consent for user \(userId)", category: .auth)
        postChange(false)
    }

    private static func postChange(_ hasConsent: Bool) {
        NotificationCenter.default.post(
            name: consentChangedNotification,
            object: nil,
            userInfo: ["hasConsent": hasConsent]
        )
    }
}
