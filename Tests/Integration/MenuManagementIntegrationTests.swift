import XCTest
@testable import CulinaChef

/// Integration tests for menu management workflows
/// Tests menu creation, recipe assignment, course management, and shopping list generation
@MainActor
final class MenuManagementIntegrationTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        
        // Configure MockURLProtocol for SecureURLSession
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        
        // Clean state
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Set up authenticated user
        try? KeychainManager.save(key: "user_id", value: "test_user_123")
        try? KeychainManager.save(key: "access_token", value: "test_token")
        try? KeychainManager.save(key: "user_email", value: "test@example.com")
        
        appState = AppState()
        appState.accessToken = "test_token"
        appState.userEmail = "test@example.com"
        appState.isAuthenticated = true
        
        MockURLProtocol.reset()
    }
    
    override func tearDown() {
        SecureURLSession.testConfiguration = nil
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        MockURLProtocol.reset()
        appState = nil
        super.tearDown()
    }
    
    // MARK: - Menu Lifecycle Tests
    
    func testCreateMenuFlow() async throws {
        // Arrange - Mock successful menu creation
        let mockMenuJSON = """
        [{
            "id": "menu_123",
            "user_id": "test_user_123",
            "title": "Wochenplan",
            "created_at": "2024-01-15T10:00:00Z"
        }]
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockMenuJSON.data(using: .utf8)
        )
        
        // Act - Create menu
        let menu = try await appState.createMenu(
            title: "Wochenplan",
            accessToken: "test_token",
            userId: "test_user_123"
        )
        
        // Assert menu created
        XCTAssertEqual(menu.id, "menu_123", "Menu ID should match")
        XCTAssertEqual(menu.title, "Wochenplan", "Menu title should match")
        XCTAssertEqual(menu.user_id, "test_user_123", "User ID should match")
        
        // Verify lastCreatedMenu published
        XCTAssertEqual(appState.lastCreatedMenu?.id, "menu_123", "Should broadcast created menu")
    }
    
    func testFetchMenusFlow() async throws {
        // Arrange - Mock menus response
        let mockMenusJSON = """
        [
            {
                "id": "menu_1",
                "user_id": "test_user_123",
                "title": "Woche 1",
                "created_at": "2024-01-15T10:00:00Z"
            },
            {
                "id": "menu_2",
                "user_id": "test_user_123",
                "title": "Woche 2",
                "created_at": "2024-01-14T10:00:00Z"
            }
        ]
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockMenusJSON.data(using: .utf8)
        )
        
        // Act
        let menus = try await appState.fetchMenus(
            accessToken: "test_token",
            userId: "test_user_123"
        )
        
        // Assert
        XCTAssertEqual(menus.count, 2, "Should fetch 2 menus")
        XCTAssertEqual(menus[0].title, "Woche 1")
        XCTAssertEqual(menus[1].title, "Woche 2")
    }
    
    func testDeleteMenuFlow() async throws {
        // Arrange - Mock delete response
        MockURLProtocol.mockResponse(statusCode: 204)
        
        // Act - Should not throw
        try await appState.deleteMenu(
            menuId: "menu_123",
            accessToken: "test_token"
        )
        
        // Assert - No error thrown = success
        // In real scenario, would verify menu is removed from local state
    }
    
    // MARK: - Recipe-to-Menu Assignment Tests
    
    func testAddRecipeToMenuFlow() async throws {
        // Arrange - Mock successful assignment
        MockURLProtocol.mockResponse(statusCode: 200)
        
        // Act - Should not throw
        try await appState.addRecipeToMenu(
            menuId: "menu_123",
            recipeId: "recipe_456",
            accessToken: "test_token"
        )
        
        // Assert - No error = success
    }
    
    func testRemoveRecipeFromMenuFlow() async throws {
        // Arrange - Mock successful removal
        MockURLProtocol.mockResponse(statusCode: 204)
        
        // Act
        try await appState.removeRecipeFromMenu(
            menuId: "menu_123",
            recipeId: "recipe_456",
            accessToken: "test_token"
        )
        
        // Assert - No error = success
    }
    
    func testFetchMenuRecipeIdsFlow() async throws {
        // Arrange - Mock recipe IDs response
        let mockRecipeIdsJSON = """
        [
            {"recipe_id": "recipe_1"},
            {"recipe_id": "recipe_2"},
            {"recipe_id": "recipe_3"}
        ]
        """
        MockURLProtocol.mockResponse(
            statusCode: 200,
            data: mockRecipeIdsJSON.data(using: .utf8)
        )
        
        // Act
        let recipeIds = try await appState.fetchMenuRecipeIds(
            menuId: "menu_123",
            accessToken: "test_token"
        )
        
        // Assert
        XCTAssertEqual(recipeIds.count, 3, "Should fetch 3 recipe IDs")
        XCTAssertEqual(recipeIds, ["recipe_1", "recipe_2", "recipe_3"])
    }
    
    // MARK: - Course Management Tests
    
    func testCourseGuessing() {
        // Test starter detection
        let starter = appState.guessCourse(name: "Tomatensuppe", description: nil)
        XCTAssertEqual(starter, "Vorspeise", "Should detect starter")
        
        // Test main course detection
        let main = appState.guessCourse(name: "Spaghetti Carbonara", description: nil)
        XCTAssertEqual(main, "Hauptspeise", "Should detect main course")
        
        // Test dessert detection
        let dessert = appState.guessCourse(name: "Tiramisu", description: nil)
        XCTAssertEqual(dessert, "Nachspeise", "Should detect dessert")
        
        // Test default to main
        let unknown = appState.guessCourse(name: "Unbekanntes Gericht", description: nil)
        XCTAssertEqual(unknown, "Hauptspeise", "Should default to main course")
    }
    
    func testSetMenuCourse() {
        let menuId = "menu_123"
        let recipeId = "recipe_456"
        
        // Act - Set course
        appState.setMenuCourse(menuId: menuId, recipeId: recipeId, course: "Vorspeise")
        
        // Assert - Course saved
        let courseMap = appState.getMenuCourseMap(menuId: menuId)
        XCTAssertEqual(courseMap[recipeId], "Vorspeise", "Course should be saved")
    }
    
    func testRemoveMenuCourse() {
        let menuId = "menu_123"
        let recipeId = "recipe_456"
        
        // Arrange - Set course first
        appState.setMenuCourse(menuId: menuId, recipeId: recipeId, course: "Hauptspeise")
        XCTAssertNotNil(appState.getMenuCourseMap(menuId: menuId)[recipeId])
        
        // Act - Remove course
        appState.removeMenuCourse(menuId: menuId, recipeId: recipeId)
        
        // Assert - Course removed
        let courseMap = appState.getMenuCourseMap(menuId: menuId)
        XCTAssertNil(courseMap[recipeId], "Course should be removed")
    }
    
    func testPersistentCourseMapping() {
        let menuId = "menu_123"
        
        // Set multiple courses
        appState.setMenuCourse(menuId: menuId, recipeId: "recipe_1", course: "Vorspeise")
        appState.setMenuCourse(menuId: menuId, recipeId: "recipe_2", course: "Hauptspeise")
        appState.setMenuCourse(menuId: menuId, recipeId: "recipe_3", course: "Nachspeise")
        
        // Simulate app restart
        appState = nil
        appState = AppState()
        
        // Verify courses persisted
        let courseMap = appState.getMenuCourseMap(menuId: menuId)
        XCTAssertEqual(courseMap.count, 3, "All courses should persist")
        XCTAssertEqual(courseMap["recipe_1"], "Vorspeise")
        XCTAssertEqual(courseMap["recipe_2"], "Hauptspeise")
        XCTAssertEqual(courseMap["recipe_3"], "Nachspeise")
    }
    
    // MARK: - Menu Suggestions Tests
    
    func testAddMenuSuggestions() {
        let menuId = "menu_123"
        let suggestions = [
            AppState.MenuSuggestion(name: "Pasta Carbonara", course: "Hauptspeise"),
            AppState.MenuSuggestion(name: "Tiramisu", course: "Nachspeise")
        ]
        
        // Act
        appState.addMenuSuggestions(suggestions, to: menuId)
        
        // Assert
        let saved = appState.getMenuSuggestions(menuId: menuId)
        XCTAssertEqual(saved.count, 2, "Should save 2 suggestions")
        XCTAssertEqual(saved[0].name, "Pasta Carbonara")
        XCTAssertEqual(saved[1].name, "Tiramisu")
    }
    
    func testRemoveMenuSuggestion() {
        let menuId = "menu_123"
        let suggestions = [
            AppState.MenuSuggestion(name: "Pasta", course: "Hauptspeise"),
            AppState.MenuSuggestion(name: "Salat", course: "Vorspeise")
        ]
        
        appState.addMenuSuggestions(suggestions, to: menuId)
        XCTAssertEqual(appState.getMenuSuggestions(menuId: menuId).count, 2)
        
        // Act - Remove one suggestion
        appState.removeMenuSuggestion(named: "Pasta", from: menuId)
        
        // Assert
        let remaining = appState.getMenuSuggestions(menuId: menuId)
        XCTAssertEqual(remaining.count, 1, "Should have 1 suggestion left")
        XCTAssertEqual(remaining[0].name, "Salat")
    }
    
    func testRemoveAllMenuSuggestions() {
        let menuId = "menu_123"
        let suggestions = [
            AppState.MenuSuggestion(name: "Dish 1"),
            AppState.MenuSuggestion(name: "Dish 2")
        ]
        
        appState.addMenuSuggestions(suggestions, to: menuId)
        XCTAssertEqual(appState.getMenuSuggestions(menuId: menuId).count, 2)
        
        // Act
        appState.removeAllMenuSuggestions(menuId: menuId)
        
        // Assert
        XCTAssertEqual(appState.getMenuSuggestions(menuId: menuId).count, 0, "All suggestions should be removed")
    }
    
    func testSetMenuSuggestionStatus() {
        let menuId = "menu_123"
        let suggestion = AppState.MenuSuggestion(name: "Test Dish", status: nil, progress: nil)
        
        appState.addMenuSuggestions([suggestion], to: menuId)
        
        // Act - Set status
        appState.setMenuSuggestionStatus(menuId: menuId, name: "Test Dish", status: "generating")
        
        // Assert
        let updated = appState.getMenuSuggestions(menuId: menuId)[0]
        XCTAssertEqual(updated.status, "generating", "Status should be updated")
    }
    
    func testSetMenuSuggestionProgress() {
        let menuId = "menu_123"
        let suggestion = AppState.MenuSuggestion(name: "Test Dish")
        
        appState.addMenuSuggestions([suggestion], to: menuId)
        
        // Act - Set progress
        appState.setMenuSuggestionProgress(menuId: menuId, name: "Test Dish", progress: 0.5)
        
        // Assert
        let updated = appState.getMenuSuggestions(menuId: menuId)[0]
        XCTAssertEqual(updated.progress, 0.5, "Progress should be updated")
    }
    
    // MARK: - Complete Menu Workflow Tests
    
    func testCompleteMenuCreationWorkflow() async throws {
        // Step 1: Create menu
        let mockMenuJSON = """
        [{
            "id": "menu_workflow_123",
            "user_id": "test_user_123",
            "title": "Dinner Party",
            "created_at": "2024-01-15T18:00:00Z"
        }]
        """
        MockURLProtocol.mockResponse(statusCode: 200, data: mockMenuJSON.data(using: .utf8))
        
        let menu = try await appState.createMenu(
            title: "Dinner Party",
            accessToken: "test_token",
            userId: "test_user_123"
        )
        
        XCTAssertEqual(menu.title, "Dinner Party")
        let menuId = menu.id
        
        // Step 2: Add suggestions
        let suggestions = [
            AppState.MenuSuggestion(name: "Carpaccio", course: "Vorspeise"),
            AppState.MenuSuggestion(name: "Ossobuco", course: "Hauptspeise"),
            AppState.MenuSuggestion(name: "Panna Cotta", course: "Nachspeise")
        ]
        appState.addMenuSuggestions(suggestions, to: menuId)
        
        XCTAssertEqual(appState.getMenuSuggestions(menuId: menuId).count, 3)
        
        // Step 3: Add recipes to menu
        MockURLProtocol.mockResponse(statusCode: 200)
        try await appState.addRecipeToMenu(menuId: menuId, recipeId: "recipe_1", accessToken: "test_token")
        try await appState.addRecipeToMenu(menuId: menuId, recipeId: "recipe_2", accessToken: "test_token")
        
        // Step 4: Set courses
        appState.setMenuCourse(menuId: menuId, recipeId: "recipe_1", course: "Vorspeise")
        appState.setMenuCourse(menuId: menuId, recipeId: "recipe_2", course: "Hauptspeise")
        
        let courseMap = appState.getMenuCourseMap(menuId: menuId)
        XCTAssertEqual(courseMap.count, 2)
        XCTAssertEqual(courseMap["recipe_1"], "Vorspeise")
        
        // Step 5: Remove suggestion after recipe created
        appState.removeMenuSuggestion(named: "Carpaccio", from: menuId)
        XCTAssertEqual(appState.getMenuSuggestions(menuId: menuId).count, 2)
    }
    
    func testMenuWithPendingTargetRecipe() async throws {
        // Simulate user creating recipe with target menu
        appState.pendingTargetMenuId = "target_menu_123"
        appState.pendingSuggestionNameToRemove = "Suggested Dish"
        
        // Add suggestion first
        let suggestion = AppState.MenuSuggestion(name: "Suggested Dish", course: "Hauptspeise")
        appState.addMenuSuggestions([suggestion], to: "target_menu_123")
        
        XCTAssertEqual(appState.getMenuSuggestions(menuId: "target_menu_123").count, 1)
        
        // Verify pending state
        XCTAssertEqual(appState.pendingTargetMenuId, "target_menu_123")
        XCTAssertEqual(appState.pendingSuggestionNameToRemove, "Suggested Dish")
        
        // After recipe created (simulated), remove suggestion
        if let menuId = appState.pendingTargetMenuId,
           let suggestionName = appState.pendingSuggestionNameToRemove {
            appState.removeMenuSuggestion(named: suggestionName, from: menuId)
            appState.pendingTargetMenuId = nil
            appState.pendingSuggestionNameToRemove = nil
        }
        
        XCTAssertEqual(appState.getMenuSuggestions(menuId: "target_menu_123").count, 0)
        XCTAssertNil(appState.pendingTargetMenuId)
    }
    
    // MARK: - Error Handling Tests
    
    func testCreateMenuWithNetworkError() async throws {
        // Arrange - Mock network error
        MockURLProtocol.mockError(URLError(.notConnectedToInternet))
        
        // Act & Assert - Should throw
        do {
            _ = try await appState.createMenu(
                title: "Test Menu",
                accessToken: "test_token",
                userId: "test_user_123"
            )
            XCTFail("Should throw network error")
        } catch {
            // Expected error
        }
    }
    
    func testFetchMenusWithUnauthorized() async throws {
        // Arrange - Mock 401 unauthorized
        MockURLProtocol.mockResponse(statusCode: 401)
        
        // Act & Assert
        do {
            _ = try await appState.fetchMenus(accessToken: "invalid_token", userId: "test_user_123")
            XCTFail("Should throw error for unauthorized")
        } catch {
            // Expected error
        }
    }
    
    // MARK: - Multi-Menu Tests
    
    func testManageMultipleMenus() {
        // Create suggestions for multiple menus
        appState.addMenuSuggestions([
            AppState.MenuSuggestion(name: "Dish A")
        ], to: "menu_1")
        
        appState.addMenuSuggestions([
            AppState.MenuSuggestion(name: "Dish B")
        ], to: "menu_2")
        
        // Set courses for multiple menus
        appState.setMenuCourse(menuId: "menu_1", recipeId: "recipe_1", course: "Vorspeise")
        appState.setMenuCourse(menuId: "menu_2", recipeId: "recipe_2", course: "Hauptspeise")
        
        // Assert independence
        let menu1Suggestions = appState.getMenuSuggestions(menuId: "menu_1")
        let menu2Suggestions = appState.getMenuSuggestions(menuId: "menu_2")
        
        XCTAssertEqual(menu1Suggestions.count, 1)
        XCTAssertEqual(menu2Suggestions.count, 1)
        XCTAssertNotEqual(menu1Suggestions[0].name, menu2Suggestions[0].name)
        
        let menu1Courses = appState.getMenuCourseMap(menuId: "menu_1")
        let menu2Courses = appState.getMenuCourseMap(menuId: "menu_2")
        
        XCTAssertEqual(menu1Courses["recipe_1"], "Vorspeise")
        XCTAssertEqual(menu2Courses["recipe_2"], "Hauptspeise")
        XCTAssertNil(menu1Courses["recipe_2"])
        XCTAssertNil(menu2Courses["recipe_1"])
    }
}
