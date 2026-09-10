import XCTest
@testable import CulinaChef

final class IngredientCategorizerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "shopping_category_overrides")
        UserDefaults.standard.removeObject(forKey: "shopping_category_overrides_test_user_123")
        KeychainManager.deleteAll()
        try? KeychainManager.save(key: "user_id", value: "test_user_123")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "shopping_category_overrides")
        UserDefaults.standard.removeObject(forKey: "shopping_category_overrides_test_user_123")
        KeychainManager.deleteAll()
        super.tearDown()
    }

    func testSimilarNamesDoNotStealCategory() {
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Milch"), .dairy)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Milchreis"), .grains)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Orange"), .fruits)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Orangensaft"), .beverages)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Paprika"), .vegetables)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Paprikapulver"), .spices)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Preiselbeeren"), .fruits)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Reis"), .grains)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Eisbergsalat"), .vegetables)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Vanilleeis"), .frozen)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Eiernudeln"), .grains)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "2 Eier"), .dairy)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Kartoffelchips"), .snacks)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Kartoffeln"), .vegetables)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Schwein"), .meat)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Wein"), .beverages)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Hafermilch"), .dairy)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Kokosmilch"), .canned)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Tomatenmark"), .canned)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Hähnchenbrust"), .meat)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "TK-Spinat"), .frozen)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "1 Dose Tomaten"), .canned)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Erdnussbutter"), .snacks)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Olivenöl"), .spices)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Steak"), .meat)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Limette"), .fruits)
    }

    func testUserOverrideWinsAndPersists() {
        IngredientCategorizer.rememberOverride(name: "Milchreis", category: .snacks)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "Milchreis"), .snacks)
        XCTAssertEqual(ItemCategory.categorize(ingredient: "200g Milchreis"), .snacks)
    }
}
