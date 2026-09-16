import XCTest
@testable import CulinaChef

final class DietaryPreferencesTests: XCTestCase {
    private let userA = "user-a"
    private let userB = "user-b"

    override func setUp() {
        super.setUp()
        KeychainManager.deleteAll()
        DietaryPreferences.removeAll(for: userA)
        DietaryPreferences.removeAll(for: userB)
        UserDefaults.standard.removeObject(forKey: DietaryPreferences.storageKey)
        UserDefaults.standard.removeObject(forKey: DietaryPreferences.storageKey(for: userA))
        UserDefaults.standard.removeObject(forKey: DietaryPreferences.storageKey(for: userB))
    }

    override func tearDown() {
        DietaryPreferences.removeAll(for: userA)
        DietaryPreferences.removeAll(for: userB)
        UserDefaults.standard.removeObject(forKey: DietaryPreferences.storageKey)
        KeychainManager.deleteAll()
        super.tearDown()
    }

    func testSaveStoresInKeychainNotUserDefaults() throws {
        try KeychainManager.save(key: "user_id", value: userA)
        var prefs = DietaryPreferences(diets: ["vegan"], allergies: ["nuts"], dislikes: [], notes: nil)
        prefs.save()

        XCTAssertNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey))
        XCTAssertNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey(for: userA)))
        XCTAssertNotNil(KeychainManager.get(key: DietaryPreferences.storageKey(for: userA)))

        let loaded = DietaryPreferences.load()
        XCTAssertEqual(loaded.allergies, ["nuts"])
        XCTAssertTrue(loaded.diets.contains("vegan"))
    }

    func testLoadWithoutUserDoesNotExposeLeftoverHealthData() {
        let leftover = DietaryPreferences(diets: [], allergies: ["shellfish"], dislikes: [], notes: nil)
        leftover.save(userId: "nobody")
        if let data = try? JSONEncoder().encode(leftover) {
            UserDefaults.standard.set(data, forKey: DietaryPreferences.storageKey)
        }

        let loaded = DietaryPreferences.load(userId: nil)
        XCTAssertTrue(loaded.allergies.isEmpty)
        XCTAssertNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey))
    }

    func testAccountsDoNotShareDietaryPreferences() throws {
        try KeychainManager.save(key: "user_id", value: userA)
        DietaryPreferences(diets: ["keto"], allergies: ["peanuts"], dislikes: [], notes: nil).save()

        KeychainManager.delete(key: "user_id")
        try KeychainManager.save(key: "user_id", value: userB)
        let loadedB = DietaryPreferences.load()
        XCTAssertTrue(loadedB.allergies.isEmpty)
        XCTAssertTrue(loadedB.diets.isEmpty)

        KeychainManager.delete(key: "user_id")
        try KeychainManager.save(key: "user_id", value: userA)
        let loadedA = DietaryPreferences.load()
        XCTAssertEqual(loadedA.allergies, ["peanuts"])
    }

    func testLegacyUserDefaultsMigratesToKeychainAndClearsDefaults() throws {
        let legacy = DietaryPreferences(diets: ["vegetarian"], allergies: ["gluten"], dislikes: [], notes: nil)
        UserDefaults.standard.set(try JSONEncoder().encode(legacy), forKey: DietaryPreferences.storageKey)
        try KeychainManager.save(key: "user_id", value: userA)

        let loaded = DietaryPreferences.load()
        XCTAssertEqual(loaded.allergies, ["gluten"])
        XCTAssertNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey))
        XCTAssertNil(UserDefaults.standard.data(forKey: DietaryPreferences.storageKey(for: userA)))
        XCTAssertNotNil(KeychainManager.get(key: DietaryPreferences.storageKey(for: userA)))
    }

    func testDeleteAllRemovesCurrentUserDietaryPreferences() throws {
        try KeychainManager.save(key: "user_id", value: userA)
        DietaryPreferences(diets: ["vegan"], allergies: ["eggs"], dislikes: [], notes: nil).save()
        XCTAssertNotNil(KeychainManager.get(key: DietaryPreferences.storageKey(for: userA)))

        KeychainManager.deleteAll()
        XCTAssertNil(KeychainManager.get(key: DietaryPreferences.storageKey(for: userA)))
    }
}
