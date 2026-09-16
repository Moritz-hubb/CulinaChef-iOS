import Foundation
import SwiftUI

/// Character caps for AI-bound text. Must stay in sync with `backend/app/ai_input_limits.py`.
enum AIInputLimit {
    static let chatMessage = 2500
    static let recipeGoal = 500
    static let freeText = 500
    static let imagePrompt = 500
    static let dietaryContext = 1000
    static let ingredient = 100
    static let ingredientList = 20
    static let cookingTime = 40
    static let socialURL = 2048
    static let socialExtra = 4000
    static let mealPlanNotes = 500
    static let preferenceItem = 80
    static let nutritionNumber = 6

    static func clamp(_ text: String, to max: Int) -> String {
        String(text.prefix(max))
    }
}

extension Binding where Value == String {
    func limited(to max: Int) -> Binding<String> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = String($0.prefix(max)) }
        )
    }
}

extension String {
    /// Validate if string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Validate if string is a valid password (min 6 chars)
    var isValidPassword: Bool {
        return self.count >= 6
    }
    
    /// Validate if string is a valid password with strong requirements
    var isStrongPassword: Bool {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
        let passwordRegex = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$"#
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: self)
    }
    
    /// Validate if string is a valid username (3-32 chars, alphanumeric + underscore)
    var isValidUsername: Bool {
        guard self.count >= 3 && self.count <= 32 else { return false }
        let usernameRegex = #"^[a-zA-Z0-9_]+$"#
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: self)
    }
    
    /// Remove leading and trailing whitespace
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is empty after trimming
    var isBlank: Bool {
        return self.trimmed.isEmpty
    }
    
    /// Validate if input is safe (no SQL injection/XSS patterns)
    var isSafeInput: Bool {
        let dangerousPatterns = [
            "<script", "</script", "javascript:",
            "DROP TABLE", "DELETE FROM", "INSERT INTO",
            "--", "/*", "*/", "xp_", "sp_",
            "<iframe", "onerror=", "onclick="
        ]
        let lowercased = self.lowercased()
        return !dangerousPatterns.contains { lowercased.contains($0.lowercased()) }
    }
    
    /// Validate if string is a valid recipe title (3-100 chars)
    var isValidRecipeTitle: Bool {
        let trimmed = self.trimmed
        return trimmed.count >= 3 && trimmed.count <= 100
    }
    
    /// Validate if string is a valid ingredient (1-200 chars)
    var isValidIngredient: Bool {
        let trimmed = self.trimmed
        return !trimmed.isEmpty && trimmed.count <= 200 && trimmed.isSafeInput
    }
    
    /// Validate if string is a valid instruction (5-2000 chars)
    var isValidInstruction: Bool {
        let trimmed = self.trimmed
        return trimmed.count >= 5 && trimmed.count <= 2000 && trimmed.isSafeInput
    }
    
    /// Validate if string is a valid menu title (2-100 chars)
    var isValidMenuTitle: Bool {
        let trimmed = self.trimmed
        return trimmed.count >= 2 && trimmed.count <= 100 && trimmed.isSafeInput
    }
    
    /// Validate if string is a valid tag (2-50 chars, alphanumeric + spaces + hyphens)
    var isValidTag: Bool {
        let trimmed = self.trimmed
        guard trimmed.count >= 2 && trimmed.count <= 50 else { return false }
        let tagRegex = #"^[a-zA-Z0-9äöüÄÖÜß\s-]+$"#
        let tagPredicate = NSPredicate(format: "SELF MATCHES %@", tagRegex)
        return tagPredicate.evaluate(with: trimmed)
    }
    
    /// Validate if string is a valid note/comment (0-1000 chars)
    var isValidNote: Bool {
        return self.trimmed.count <= 1000
    }
    
    /// Validate if string contains only numbers (for portions, cooking time, etc.)
    var isNumeric: Bool {
        return !self.isEmpty && self.allSatisfy { $0.isNumber }
    }
    
    /// Validate if string is a valid difficulty level
    var isValidDifficulty: Bool {
        let validDifficulties = ["Einfach", "Mittel", "Schwer", "Easy", "Medium", "Hard"]
        return validDifficulties.contains(self)
    }
}

/// Canonical UUID for PostgREST `eq.<id>` filters. Rejects operators, commas, and empty strings.
enum PostgRESTUUID {
    static func isValid(_ raw: String) -> Bool {
        UUID(uuidString: raw) != nil
    }
}

/// Values interpolated into PostgREST `eq.<value>` query items.
/// UUIDs are preferred; non-UUID tokens are allowed only if they cannot introduce extra filters.
enum PostgRESTFilter {
    static func isSafeEqValue(_ raw: String) -> Bool {
        if PostgRESTUUID.isValid(raw) { return true }
        guard (1...64).contains(raw.count) else { return false }
        return raw.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "_" || scalar == "-"
        }
    }

    static func requireEqValue(_ raw: String) throws {
        guard isSafeEqValue(raw) else { throw URLError(.badURL) }
    }
}

/// Client-side allowlist matching backend `social_import._ALLOWED_HOST_SUFFIXES`.
enum SocialImportURL {
    static let allowedHostSuffixes: [String] = [
        "youtube.com",
        "youtu.be",
        "tiktok.com",
        "instagram.com",
        "facebook.com",
        "fb.watch",
        "pinterest.com",
        "pin.it",
        "reddit.com",
        "snapchat.com",
        "vimeo.com",
        "twitch.tv",
        "threads.net",
        "twitter.com",
        "x.com",
        "dailymotion.com",
        "dai.ly"
    ]

    static func isAllowed(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else { return false }
        guard scheme == "https" || scheme == "http" else { return false }
        guard let host = url.host?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) else {
            return false
        }
        if host.contains(":") { return false }
        if isIPv4Literal(host) { return false }
        return allowedHostSuffixes.contains { suffix in
            host == suffix || host.hasSuffix("." + suffix)
        }
    }

    fileprivate static func isIPv4Literal(_ host: String) -> Bool {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let n = Int(part), (0...255).contains(n) else { return false }
            return true
        }
    }
}

/// Recipe photos are stored on Supabase / GCS. Arbitrary hosts must not be fetched.
enum RecipeImageURL {
    static let allowedHostSuffixes = [
        "supabase.co",
        "supabase.in",
        "storage.googleapis.com"
    ]

    static func isAllowed(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https" else { return false }
        guard let host = url.host?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) else {
            return false
        }
        if host.contains(":") { return false }
        if SocialImportURL.isIPv4Literal(host) { return false }
        return allowedHostSuffixes.contains { suffix in
            host == suffix || host.hasSuffix("." + suffix)
        }
    }

    static func isAllowed(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return false }
        return isAllowed(url)
    }
}

enum SocialImportPendingStore {
    static let suiteName = "group.com.moritzserrin.culinachef.share"
    static let urlKey = "pending_social_import_url"

    static func save(_ url: String, defaults: UserDefaults? = UserDefaults(suiteName: suiteName)) {
        defaults?.set(url, forKey: urlKey)
        defaults?.synchronize()
    }

    @discardableResult
    static func consume(defaults: UserDefaults? = UserDefaults(suiteName: suiteName)) -> String? {
        guard let defaults else { return nil }
        let value = defaults.string(forKey: urlKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.removeObject(forKey: urlKey)
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}

enum SocialImportLink {
    struct Payload: Equatable {
        let url: String
        let extra: String?
    }

    /// Custom scheme ignores query `url` (any app can open it). Share Extension writes the App Group first.
    static func payload(from incoming: URL, pendingAppGroupURL: String?) -> Payload? {
        if incoming.scheme == "culinachef", incoming.host == "import" {
            guard let pending = pendingAppGroupURL, SocialImportURL.isAllowed(pending) else { return nil }
            return Payload(url: pending, extra: nil)
        }
        let host = incoming.host?.lowercased()
        let isUniversal = incoming.scheme?.lowercased() == "https"
            && (host == "culinaai.com" || host == "www.culinaai.com")
            && incoming.path.contains("import")
        guard isUniversal else { return nil }
        let items = URLComponents(url: incoming, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let raw = items.first(where: { $0.name == "url" })?.value else { return nil }
        let decoded = raw.removingPercentEncoding ?? raw
        guard SocialImportURL.isAllowed(decoded) else { return nil }
        let extra = items.first(where: { $0.name == "extra" })?.value.map { $0.removingPercentEncoding ?? $0 }
        return Payload(url: decoded, extra: extra)
    }
}

enum SentryPrivacy {
    static func sanitizedURL(_ raw: String) -> String {
        guard let url = URL(string: raw), let host = url.host, !host.isEmpty else { return "" }
        let scheme = url.scheme ?? "https"
        let path = url.path
        return "\(scheme)://\(host)\(path)"
    }

    static func isSensitiveBreadcrumb(message: String?, dataDescription: String?) -> Bool {
        let combined = ((message ?? "") + " " + (dataDescription ?? "")).lowercased()
        let sensitive = ["user_id", "token", "email", "password", "consent", "auth", "apikey", "key"]
        return sensitive.contains { combined.contains($0) }
    }
}

// MARK: - Localized Error Messages
extension String {
    static func validationError(for field: ValidationField) -> String {
        switch field {
        case .email:
            return L.validation_emailInvalid.localized
        case .password:
            return L.validation_passwordTooShort.localized
        case .passwordStrong:
            return L.validation_passwordWeak.localized
        case .username:
            return L.validation_usernameInvalid.localized
        case .required:
            return L.validation_fieldRequired.localized
        }
    }
    
    enum ValidationField {
        case email
        case password
        case passwordStrong
        case username
        case required
    }
}
