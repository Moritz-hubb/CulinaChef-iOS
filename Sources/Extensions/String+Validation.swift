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

// MARK: - Localized Error Messages
extension String {
    static func validationError(for field: ValidationField) -> String {
        switch field {
        case .email:
            return NSLocalizedString("validation.email.invalid", value: "Bitte geben Sie eine gültige E-Mail-Adresse ein", comment: "Invalid email error")
        case .password:
            return NSLocalizedString("validation.password.too_short", value: "Passwort muss mindestens 6 Zeichen lang sein", comment: "Password too short error")
        case .passwordStrong:
            return NSLocalizedString("validation.password.weak", value: "Passwort muss mind. 8 Zeichen, 1 Großbuchstaben, 1 Kleinbuchstaben und 1 Zahl enthalten", comment: "Weak password error")
        case .username:
            return NSLocalizedString("validation.username.invalid", value: "Benutzername muss 3-32 Zeichen lang sein und darf nur Buchstaben, Zahlen und _ enthalten", comment: "Invalid username error")
        case .required:
            return NSLocalizedString("validation.field.required", value: "Dieses Feld ist erforderlich", comment: "Required field error")
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
