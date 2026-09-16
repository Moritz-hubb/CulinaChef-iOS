import XCTest
@testable import CulinaChef

final class StringValidationTests: XCTestCase {
    
    // MARK: - Email Validation Tests
    
    func testValidEmails() {
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.co.uk",
            "test123@test-domain.com",
            "a@b.co"
        ]
        
        for email in validEmails {
            XCTAssertTrue(email.isValidEmail, "\(email) should be valid")
        }
    }
    
    func testInvalidEmails() {
        let invalidEmails = [
            "",
            "notanemail",
            "@example.com",
            "test@",
            "test@@example.com",
            "test @example.com",
            "test@example",
            "test.example.com"
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(email.isValidEmail, "\(email) should be invalid")
        }
    }
    
    // MARK: - Password Validation Tests
    
    func testValidPasswords() {
        let validPasswords = [
            "123456",        // Minimum 6 chars
            "password",
            "Test1234",
            "veryLongPassword123",
            "!@#$%^&*()"
        ]
        
        for password in validPasswords {
            XCTAssertTrue(password.isValidPassword, "\(password) should be valid (min 6 chars)")
        }
    }
    
    func testInvalidPasswords() {
        let invalidPasswords = [
            "",
            "12345",        // Too short (5 chars)
            "abc",
            "a"
        ]
        
        for password in invalidPasswords {
            XCTAssertFalse(password.isValidPassword, "\(password) should be invalid (< 6 chars)")
        }
    }
    
    func testLoginAllowsLegacySixCharacterPasswords() {
        XCTAssertTrue("123456".isValidPassword)
        XCTAssertFalse("123456".isStrongPassword)
    }

    func testNewAccountPasswordMustBeStrong() {
        XCTAssertFalse("123456".isStrongPassword)
        XCTAssertTrue("Password1".isStrongPassword)
    }

    func testStrongPasswords() {
        let strongPasswords = [
            "Password1",      // 8+ chars, upper, lower, number
            "Test1234",
            "MySecureP4ss",
            "Abc123456"
        ]
        
        for password in strongPasswords {
            XCTAssertTrue(password.isStrongPassword, "\(password) should be strong")
        }
    }
    
    func testWeakPasswords() {
        let weakPasswords = [
            "password",       // No uppercase/number
            "PASSWORD",       // No lowercase/number
            "12345678",       // No letters
            "Pass1",          // Too short
            "password1",      // No uppercase
            "PASSWORD1"       // No lowercase
        ]
        
        for password in weakPasswords {
            XCTAssertFalse(password.isStrongPassword, "\(password) should be weak")
        }
    }
    
    // MARK: - Username Validation Tests
    
    func testValidUsernames() {
        let validUsernames = [
            "abc",           // Minimum 3 chars
            "user123",
            "test_user",
            "User_Name_123",
            "a".repeat(32)   // Max 32 chars
        ]
        
        for username in validUsernames {
            XCTAssertTrue(username.isValidUsername, "\(username) should be valid")
        }
    }
    
    func testInvalidUsernames() {
        let invalidUsernames = [
            "",
            "ab",            // Too short (2 chars)
            "user name",     // Contains space
            "user@name",     // Contains @
            "user.name",     // Contains .
            "user-name",     // Contains -
            "ü".repeat(3),   // Non-ASCII
            "a".repeat(33)   // Too long (33 chars)
        ]
        
        for username in invalidUsernames {
            XCTAssertFalse(username.isValidUsername, "\(username) should be invalid")
        }
    }
    
    // MARK: - Trimmed Tests
    
    func testTrimmedRemovesWhitespace() {
        XCTAssertEqual("  test  ".trimmed, "test")
        XCTAssertEqual("\ntest\n".trimmed, "test")
        XCTAssertEqual("\ttest\t".trimmed, "test")
        XCTAssertEqual("   ".trimmed, "")
    }
    
    func testTrimmedPreservesInternalWhitespace() {
        XCTAssertEqual("  hello world  ".trimmed, "hello world")
        XCTAssertEqual("test\nline".trimmed, "test\nline")
    }
    
    // MARK: - Blank Tests
    
    func testIsBlank() {
        XCTAssertTrue("".isBlank)
        XCTAssertTrue("   ".isBlank)
        XCTAssertTrue("\n".isBlank)
        XCTAssertTrue("\t".isBlank)
        XCTAssertTrue(" \n \t ".isBlank)
    }
    
    func testPostgRESTUUIDAcceptsCanonicalUUIDs() {
        XCTAssertTrue(PostgRESTUUID.isValid("550e8400-e29b-41d4-a716-446655440000"))
        XCTAssertTrue(PostgRESTUUID.isValid("AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"))
    }

    func testPostgRESTUUIDRejectsFilterInjection() {
        XCTAssertFalse(PostgRESTUUID.isValid("recipe-1"))
        XCTAssertFalse(PostgRESTUUID.isValid("550e8400-e29b-41d4-a716-446655440000,or(id.neq.null)"))
        XCTAssertFalse(PostgRESTUUID.isValid(""))
        XCTAssertFalse(PostgRESTUUID.isValid("not-a-uuid"))
    }

    func testPostgRESTFilterAcceptsUUIDAndSafeTokens() {
        XCTAssertTrue(PostgRESTFilter.isSafeEqValue("550e8400-e29b-41d4-a716-446655440000"))
        XCTAssertTrue(PostgRESTFilter.isSafeEqValue("test_user_123"))
        XCTAssertTrue(PostgRESTFilter.isSafeEqValue("menu_123"))
        XCTAssertTrue(PostgRESTFilter.isSafeEqValue("user123"))
    }

    func testPostgRESTFilterRejectsInjection() {
        XCTAssertFalse(PostgRESTFilter.isSafeEqValue(""))
        XCTAssertFalse(PostgRESTFilter.isSafeEqValue("id,or(id.neq.null)"))
        XCTAssertFalse(PostgRESTFilter.isSafeEqValue("abc)or(id.eq.1"))
        XCTAssertFalse(PostgRESTFilter.isSafeEqValue("a b"))
        XCTAssertFalse(PostgRESTFilter.isSafeEqValue(String(repeating: "a", count: 65)))
    }

    func testSocialImportURLAllowsKnownHttpsHosts() {
        XCTAssertTrue(SocialImportURL.isAllowed("https://www.tiktok.com/@chef/video/123"))
        XCTAssertTrue(SocialImportURL.isAllowed("https://youtu.be/abc123"))
        XCTAssertTrue(SocialImportURL.isAllowed("http://instagram.com/p/xyz"))
        XCTAssertTrue(SocialImportURL.isAllowed("https://vm.tiktok.com/ZMabc/"))
    }

    func testSocialImportURLRejectsUnsafeTargets() {
        XCTAssertFalse(SocialImportURL.isAllowed("file:///etc/passwd"))
        XCTAssertFalse(SocialImportURL.isAllowed("javascript:alert(1)"))
        XCTAssertFalse(SocialImportURL.isAllowed("https://127.0.0.1/ssrf"))
        XCTAssertFalse(SocialImportURL.isAllowed("http://192.168.0.1/recipe"))
        XCTAssertFalse(SocialImportURL.isAllowed("https://evil-tiktok.com/video/1"))
        XCTAssertFalse(SocialImportURL.isAllowed("https://example.com/recipe"))
        XCTAssertFalse(SocialImportURL.isAllowed("not a url"))
    }

    func testIsNotBlank() {
        XCTAssertFalse("test".isBlank)
        XCTAssertFalse("  test  ".isBlank)
        XCTAssertFalse(" a ".isBlank)
    }
    
    // MARK: - Validation Error Messages
    
    func testValidationErrorMessages() {
        let emailError = String.validationError(for: .email)
        XCTAssertFalse(emailError.isEmpty, "Email error message should not be empty")
        
        let passwordError = String.validationError(for: .password)
        XCTAssertFalse(passwordError.isEmpty, "Password error message should not be empty")
        
        let usernameError = String.validationError(for: .username)
        XCTAssertFalse(usernameError.isEmpty, "Username error message should not be empty")
        
        let requiredError = String.validationError(for: .required)
        XCTAssertFalse(requiredError.isEmpty, "Required error message should not be empty")
    }
}

// MARK: - String Helper Extension for Tests
private extension String {
    func `repeat`(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}
