import XCTest
@testable import CulinaChef

final class KeychainManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean up keychain before each test
        KeychainManager.deleteAll()
    }
    
    override func tearDown() {
        // Clean up keychain after each test
        KeychainManager.deleteAll()
        super.tearDown()
    }
    
    // MARK: - Save & Get Tests
    
    func testSaveAndGetToken() throws {
        // Given
        let testToken = "test_access_token_12345"
        let key = "access_token"
        
        // When
        try KeychainManager.save(key: key, value: testToken)
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertNotNil(retrieved, "Token should be retrieved from Keychain")
        XCTAssertEqual(retrieved, testToken, "Retrieved token should match saved token")
    }
    
    func testSaveAndGetMultipleValues() throws {
        // Given
        let accessToken = "access_token_abc"
        let refreshToken = "refresh_token_xyz"
        let userId = "user_id_123"
        
        // When
        try KeychainManager.save(key: "access_token", value: accessToken)
        try KeychainManager.save(key: "refresh_token", value: refreshToken)
        try KeychainManager.save(key: "user_id", value: userId)
        
        // Then
        XCTAssertEqual(KeychainManager.get(key: "access_token"), accessToken)
        XCTAssertEqual(KeychainManager.get(key: "refresh_token"), refreshToken)
        XCTAssertEqual(KeychainManager.get(key: "user_id"), userId)
    }
    
    func testSaveOverwritesExistingValue() throws {
        // Given
        let key = "access_token"
        let oldValue = "old_token"
        let newValue = "new_token"
        
        // When
        try KeychainManager.save(key: key, value: oldValue)
        try KeychainManager.save(key: key, value: newValue)
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertEqual(retrieved, newValue, "New value should overwrite old value")
    }
    
    // MARK: - Delete Tests
    
    func testDeleteSingleKey() throws {
        // Given
        let key = "access_token"
        let value = "test_token"
        try KeychainManager.save(key: key, value: value)
        
        // When
        KeychainManager.delete(key: key)
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertNil(retrieved, "Token should be deleted from Keychain")
    }
    
    func testDeleteAll() throws {
        // Given
        try KeychainManager.save(key: "access_token", value: "token1")
        try KeychainManager.save(key: "refresh_token", value: "token2")
        try KeychainManager.save(key: "user_id", value: "user123")
        try KeychainManager.save(key: "user_email", value: "test@example.com")
        
        // When
        KeychainManager.deleteAll()
        
        // Then
        XCTAssertNil(KeychainManager.get(key: "access_token"))
        XCTAssertNil(KeychainManager.get(key: "refresh_token"))
        XCTAssertNil(KeychainManager.get(key: "user_id"))
        XCTAssertNil(KeychainManager.get(key: "user_email"))
    }
    
    // MARK: - Edge Cases
    
    func testGetNonExistentKey() {
        // When
        let retrieved = KeychainManager.get(key: "non_existent_key")
        
        // Then
        XCTAssertNil(retrieved, "Non-existent key should return nil")
    }
    
    func testSaveEmptyString() throws {
        // Given
        let key = "empty_value"
        let emptyValue = ""
        
        // When
        try KeychainManager.save(key: key, value: emptyValue)
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertNotNil(retrieved, "Empty string should be saved")
        XCTAssertEqual(retrieved, emptyValue, "Retrieved value should be empty string")
    }
    
    func testSaveLongToken() throws {
        // Given
        let key = "long_token"
        let longToken = String(repeating: "a", count: 10000)
        
        // When
        try KeychainManager.save(key: key, value: longToken)
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertEqual(retrieved, longToken, "Long tokens should be saved correctly")
    }
    
    func testSaveSpecialCharacters() throws {
        // Given
        let key = "special_token"
        let specialToken = "token_with_!@#$%^&*()_+-={}[]|:;<>?,./~`"
        
        // When
        try KeychainManager.save(key: key, value: specialToken)
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertEqual(retrieved, specialToken, "Special characters should be preserved")
    }
    
    // MARK: - Security Tests
    
    func testMultipleDeletesAreIdempotent() throws {
        // Given
        let key = "test_token"
        try KeychainManager.save(key: key, value: "value")
        
        // When
        KeychainManager.delete(key: key)
        KeychainManager.delete(key: key) // Delete again
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertNil(retrieved, "Multiple deletes should not cause issues")
    }
    
    func testKeychainPersistsAcrossInstances() throws {
        // Given
        let key = "persistent_token"
        let value = "persistent_value"
        try KeychainManager.save(key: key, value: value)
        
        // When - Simulate app restart by just reading again
        let retrieved = KeychainManager.get(key: key)
        
        // Then
        XCTAssertEqual(retrieved, value, "Keychain should persist values")
    }
}
