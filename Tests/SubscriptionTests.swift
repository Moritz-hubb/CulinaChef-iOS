import XCTest
@testable import CulinaChef

final class SubscriptionTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        appState = AppState()
        // Clean up any previous test data
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
    
    override func tearDown() {
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        appState = nil
        super.tearDown()
    }
    
    // MARK: - Feature Access Tests
    
    func testAIFeaturesRequireSubscription() {
        // Given
        appState.isSubscribed = false
        
        // Then
        XCTAssertFalse(appState.hasAccess(to: .aiChat), "AI Chat should require subscription")
        XCTAssertFalse(appState.hasAccess(to: .aiRecipeGenerator), "AI Recipe Generator should require subscription")
        XCTAssertFalse(appState.hasAccess(to: .aiRecipeAnalysis), "AI Recipe Analysis should require subscription")
    }
    
    func testAIFeaturesAccessibleWithSubscription() {
        // Given
        appState.isSubscribed = true
        
        // Then
        XCTAssertTrue(appState.hasAccess(to: .aiChat), "AI Chat should be accessible with subscription")
        XCTAssertTrue(appState.hasAccess(to: .aiRecipeGenerator), "AI Recipe Generator should be accessible")
        XCTAssertTrue(appState.hasAccess(to: .aiRecipeAnalysis), "AI Recipe Analysis should be accessible")
    }
    
    func testFreeFeaturesAlwaysAccessible() {
        // Given - No subscription
        appState.isSubscribed = false
        
        // Then
        XCTAssertTrue(appState.hasAccess(to: .manualRecipes), "Manual recipes should always be accessible")
        XCTAssertTrue(appState.hasAccess(to: .shoppingList), "Shopping list should always be accessible")
        XCTAssertTrue(appState.hasAccess(to: .communityLibrary), "Community library should always be accessible")
        XCTAssertTrue(appState.hasAccess(to: .recipeManagement), "Recipe management should always be accessible")
    }
    
    // MARK: - Subscription Period Tests
    
    func testGetSubscriptionPeriodEndWhenNotSet() {
        // Given - No user logged in
        
        // When
        let periodEnd = appState.getSubscriptionPeriodEnd()
        
        // Then
        XCTAssertNil(periodEnd, "Period end should be nil when not set")
    }
    
    func testGetSubscriptionAutoRenewWhenNotSet() {
        // Given - No user logged in
        
        // When
        let autoRenew = appState.getSubscriptionAutoRenew()
        
        // Then
        XCTAssertFalse(autoRenew, "Auto renew should be false when not set")
    }
    
    // MARK: - Dietary Preferences Tests
    
    func testDietarySystemPromptEmpty() {
        // Given - No dietary restrictions
        appState.dietary = DietaryPreferences(diets: [], allergies: [], dislikes: [], notes: nil)
        
        // When
        let prompt = appState.dietarySystemPrompt()
        
        // Then
        XCTAssertTrue(prompt.isEmpty, "Prompt should be empty when no dietary preferences")
    }
    
    func testDietarySystemPromptWithDiets() {
        // Given
        appState.dietary = DietaryPreferences(diets: ["vegan", "glutenfrei"], allergies: [], dislikes: [], notes: nil)
        
        // When
        let prompt = appState.dietarySystemPrompt()
        
        // Then
        XCTAssertFalse(prompt.isEmpty, "Prompt should not be empty")
        XCTAssertTrue(prompt.contains("vegan"), "Prompt should contain vegan")
        XCTAssertTrue(prompt.contains("glutenfrei"), "Prompt should contain glutenfrei")
    }
    
    func testDietarySystemPromptWithAllergies() {
        // Given
        appState.dietary = DietaryPreferences(diets: [], allergies: ["Nüsse", "Milch"], dislikes: [], notes: nil)
        
        // When
        let prompt = appState.dietarySystemPrompt()
        
        // Then
        XCTAssertTrue(prompt.contains("Allergien"), "Prompt should contain allergies keyword")
        XCTAssertTrue(prompt.contains("Nüsse"), "Prompt should contain nuts")
        XCTAssertTrue(prompt.contains("Milch"), "Prompt should contain milk")
    }
    
    // MARK: - Intent Summarization Tests
    
    func testSummarizeIntentVegan() {
        // When
        let summary = appState.summarizeIntent(from: "Ich möchte ein veganes Rezept")
        
        // Then
        XCTAssertTrue(summary.contains("vegan"), "Summary should detect vegan intent")
    }
    
    func testSummarizeIntentMultipleTags() {
        // When
        let summary = appState.summarizeIntent(from: "Ich brauche etwas glutenfreies, low-carb und schnelles")
        
        // Then
        XCTAssertTrue(summary.contains("glutenfrei"), "Summary should detect gluten-free")
        XCTAssertTrue(summary.contains("low-carb"), "Summary should detect low-carb")
        XCTAssertTrue(summary.contains("schnell"), "Summary should detect quick")
    }
    
    func testSummarizeIntentNoTags() {
        // When
        let summary = appState.summarizeIntent(from: "Ich möchte Pasta kochen")
        
        // Then
        XCTAssertTrue(summary.isEmpty, "Summary should be empty when no dietary keywords")
    }
    
    // MARK: - Language Tests
    
    func testLanguageSystemPromptGerman() {
        // Given
        UserDefaults.standard.set("de", forKey: "app_language")
        
        // When
        let prompt = appState.languageSystemPrompt()
        
        // Then
        XCTAssertTrue(prompt.contains("Deutsch") || prompt.contains("German"), "Should request German language")
    }
    
    func testLanguageSystemPromptEnglish() {
        // Given
        UserDefaults.standard.set("en", forKey: "app_language")
        
        // When
        let prompt = appState.languageSystemPrompt()
        
        // Then
        XCTAssertTrue(prompt.contains("English"), "Should request English language")
    }
    
    // MARK: - Course Guessing Tests
    
    func testGuessCourseStarter() {
        let starterNames = [
            "Tomatensuppe",
            "Salat mit Dressing",
            "Bruschetta"
        ]
        
        for name in starterNames {
            let course = appState.guessCourse(name: name, description: nil)
            XCTAssertEqual(course, "Vorspeise", "\(name) should be categorized as Vorspeise")
        }
    }
    
    func testGuessCourseMain() {
        let mainDishNames = [
            "Spaghetti Carbonara",
            "Steak mit Pommes",
            "Curry mit Reis"
        ]
        
        for name in mainDishNames {
            let course = appState.guessCourse(name: name, description: nil)
            XCTAssertEqual(course, "Hauptspeise", "\(name) should be categorized as Hauptspeise")
        }
    }
    
    func testGuessCourseDessert() {
        let dessertNames = [
            "Tiramisu",
            "Schokoladenkuchen",
            "Eis mit Sahne"
        ]
        
        for name in dessertNames {
            let course = appState.guessCourse(name: name, description: nil)
            XCTAssertEqual(course, "Nachspeise", "\(name) should be categorized as Nachspeise")
        }
    }
    
    func testGuessCourseDefaultsToMain() {
        let course = appState.guessCourse(name: "Unbekanntes Gericht", description: nil)
        XCTAssertEqual(course, "Hauptspeise", "Unknown dishes should default to Hauptspeise")
    }
}
