import XCTest
@testable import CulinaChef

@MainActor
final class LocalizationManagerTests: XCTestCase {
    
    var sut: LocalizationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = LocalizationManager.shared
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstance_IsSingleton() {
        let instance1 = LocalizationManager.shared
        let instance2 = LocalizationManager.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Available Languages Tests
    
    func testAvailableLanguages_ContainsExpectedLanguages() {
        XCTAssertEqual(sut.availableLanguages.count, 5)
        XCTAssertEqual(sut.availableLanguages["de"], "Deutsch")
        XCTAssertEqual(sut.availableLanguages["en"], "English")
        XCTAssertEqual(sut.availableLanguages["fr"], "Français")
        XCTAssertEqual(sut.availableLanguages["it"], "Italiano")
        XCTAssertEqual(sut.availableLanguages["es"], "Español")
    }
    
    func testAvailableLanguages_AllLanguagesHaveNames() {
        for (code, name) in sut.availableLanguages {
            XCTAssertFalse(code.isEmpty)
            XCTAssertFalse(name.isEmpty)
        }
    }
    
    // MARK: - Current Language Tests
    
    func testCurrentLanguage_IsValid() {
        let currentLang = sut.currentLanguage
        XCTAssertTrue(sut.availableLanguages.keys.contains(currentLang))
    }
    
    func testCurrentLanguage_CanBeChanged() {
        let originalLanguage = sut.currentLanguage
        
        // Change to a different language
        let newLanguage = originalLanguage == "de" ? "en" : "de"
        sut.currentLanguage = newLanguage
        
        XCTAssertEqual(sut.currentLanguage, newLanguage)
        
        // Reset to original
        sut.currentLanguage = originalLanguage
    }
    
    func testCurrentLanguage_SavesToUserDefaults() {
        let testLanguage = "en"
        sut.currentLanguage = testLanguage
        
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language")
        XCTAssertEqual(savedLanguage, testLanguage)
    }
    
    // MARK: - String Localization Tests
    
    func testStringForKey_ReturnsKeyWhenNotFound() {
        let nonExistentKey = "test.nonexistent.key.12345"
        let result = sut.string(forKey: nonExistentKey)
        
        // Should return the key itself as fallback
        XCTAssertEqual(result, nonExistentKey)
    }
    
    func testStringForKey_DoesNotCrash() {
        // Test various key patterns
        _ = sut.string(forKey: "common.done")
        _ = sut.string(forKey: "recipes.title")
        _ = sut.string(forKey: "settings.dietary")
        _ = sut.string(forKey: "nonexistent.key")
        
        // If we reach here without crash, test passes
        XCTAssertTrue(true)
    }
    
    // MARK: - String Extension Tests
    
    func testLocalizedExtension_DoesNotCrash() {
        let key = "common.done"
        let localized = key.localized
        
        XCTAssertNotNil(localized)
        XCTAssertFalse(localized.isEmpty)
    }
    
    func testLocalizedExtension_UsesLocalizationManager() {
        let key = "test.key"
        let result = key.localized
        
        // Should return either translated string or key itself
        XCTAssertFalse(result.isEmpty)
    }
    
    // MARK: - Notification Tests
    
    func testLanguageChange_PostsNotification() {
        let expectation = XCTestExpectation(description: "Language changed notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .languageChanged,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Change language
        let newLanguage = sut.currentLanguage == "de" ? "en" : "de"
        sut.currentLanguage = newLanguage
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - L Keys Tests (Sample)
    
    func testLKeys_CommonKeys_Exist() {
        // Test that common L keys are defined
        XCTAssertFalse(L.done.isEmpty)
        XCTAssertFalse(L.cancel.isEmpty)
        XCTAssertFalse(L.save.isEmpty)
        XCTAssertFalse(L.delete.isEmpty)
    }
    
    func testLKeys_AuthKeys_Exist() {
        XCTAssertFalse(L.signIn.isEmpty)
        XCTAssertFalse(L.signUp.isEmpty)
        XCTAssertFalse(L.email.isEmpty)
        XCTAssertFalse(L.password.isEmpty)
    }
    
    func testLKeys_RecipeKeys_Exist() {
        XCTAssertFalse(L.recipes.isEmpty)
        XCTAssertFalse(L.ingredients.isEmpty)
        XCTAssertFalse(L.instructions.isEmpty)
    }
    
    func testLKeys_SettingsKeys_Exist() {
        XCTAssertFalse(L.settings.isEmpty)
        XCTAssertFalse(L.dietary.isEmpty)
        XCTAssertFalse(L.subscription.isEmpty)
    }
}
