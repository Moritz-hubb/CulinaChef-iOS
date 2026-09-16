import Foundation

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

    private static func isIPv4Literal(_ host: String) -> Bool {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let n = Int(part), (0...255).contains(n) else { return false }
            return true
        }
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
