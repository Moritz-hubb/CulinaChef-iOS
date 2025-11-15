import XCTest
@testable import CulinaChef

/// Unit tests for ShoppingListManager
/// Tests item management, persistence, user isolation, and categorization
@MainActor
final class ShoppingListManagerTests: XCTestCase {
    
    var manager: ShoppingListManager!
    
    override func setUp() {
        super.setUp()
        
        // Clean state
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Set up test user
        try? KeychainManager.save(key: "user_id", value: "test_user_123")
        
        manager = ShoppingListManager()
    }
    
    override func tearDown() {
        KeychainManager.deleteAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        manager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialStateIsEmpty() {
        XCTAssertEqual(manager.shoppingList.items.count, 0, "Initial shopping list should be empty")
        XCTAssertEqual(manager.categoriesVersion, 0, "Categories version should be 0 when empty")
    }
    
    func testInitializationWithoutUser() {
        // Arrange - No user logged in
        KeychainManager.deleteAll()
        
        // Act
        let freshManager = ShoppingListManager()
        
        // Assert - Should initialize with empty list
        XCTAssertEqual(freshManager.shoppingList.items.count, 0)
    }
    
    // MARK: - Add Item Tests
    
    func testAddSingleItem() {
        // Act
        manager.addItem(name: "Tomatoes", quantity: "500g", category: .vegetables)
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 1)
        XCTAssertEqual(manager.shoppingList.items[0].name, "Tomatoes")
        XCTAssertEqual(manager.shoppingList.items[0].quantity, "500g")
        XCTAssertEqual(manager.shoppingList.items[0].category, .vegetables)
        XCTAssertFalse(manager.shoppingList.items[0].isCompleted)
    }
    
    func testAddMultipleItems() {
        // Arrange
        let items = [
            ShoppingListItem(name: "Milk", quantity: "1L", category: .dairy),
            ShoppingListItem(name: "Bread", quantity: "2", category: .bakery),
            ShoppingListItem(name: "Apples", quantity: "1kg", category: .fruits)
        ]
        
        // Act
        manager.addItems(items)
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 3)
        XCTAssertEqual(manager.shoppingList.items[0].name, "Milk")
        XCTAssertEqual(manager.shoppingList.items[1].name, "Bread")
        XCTAssertEqual(manager.shoppingList.items[2].name, "Apples")
    }
    
    func testAddItemWithoutQuantity() {
        // Act
        manager.addItem(name: "Salt", quantity: nil, category: .spices)
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 1)
        XCTAssertNil(manager.shoppingList.items[0].quantity)
    }
    
    func testCategoriesVersionUpdatesWhenItemsAdded() {
        let initialVersion = manager.categoriesVersion
        
        manager.addItem(name: "Test Item", quantity: "1", category: .other)
        
        XCTAssertEqual(manager.categoriesVersion, initialVersion + 1)
    }
    
    // MARK: - Delete Item Tests
    
    func testDeleteSingleItem() {
        // Arrange
        manager.addItem(name: "Item 1", quantity: "1", category: .other)
        manager.addItem(name: "Item 2", quantity: "2", category: .other)
        
        let itemToDelete = manager.shoppingList.items[0]
        
        // Act
        manager.deleteItem(item: itemToDelete)
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 1)
        XCTAssertEqual(manager.shoppingList.items[0].name, "Item 2")
    }
    
    func testDeleteItemsAtOffsets() {
        // Arrange
        manager.addItem(name: "Vegetables 1", quantity: "1", category: .vegetables)
        manager.addItem(name: "Vegetables 2", quantity: "2", category: .vegetables)
        manager.addItem(name: "Vegetables 3", quantity: "3", category: .vegetables)
        
        // Act - Delete first item (offset 0)
        manager.deleteItems(at: IndexSet(integer: 0), in: .vegetables)
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 2)
        XCTAssertEqual(manager.shoppingList.items[0].name, "Vegetables 2")
    }
    
    // MARK: - Toggle Completion Tests
    
    func testToggleItemCompletion() {
        // Arrange
        manager.addItem(name: "Test Item", quantity: "1", category: .other)
        let item = manager.shoppingList.items[0]
        
        XCTAssertFalse(item.isCompleted)
        
        // Act - Toggle on
        manager.toggleItemCompletion(item: item)
        
        // Assert
        XCTAssertTrue(manager.shoppingList.items[0].isCompleted)
        
        // Act - Toggle off
        manager.toggleItemCompletion(item: manager.shoppingList.items[0])
        
        // Assert
        XCTAssertFalse(manager.shoppingList.items[0].isCompleted)
    }
    
    func testToggleNonExistentItem() {
        // Arrange
        let fakeItem = ShoppingListItem(id: "fake_id", name: "Fake", quantity: nil, category: .other)
        
        // Act - Should not crash
        manager.toggleItemCompletion(item: fakeItem)
        
        // Assert - List unchanged
        XCTAssertEqual(manager.shoppingList.items.count, 0)
    }
    
    // MARK: - Clear Tests
    
    func testClearCompleted() {
        // Arrange
        manager.addItem(name: "Item 1", quantity: "1", category: .other)
        manager.addItem(name: "Item 2", quantity: "2", category: .other)
        manager.addItem(name: "Item 3", quantity: "3", category: .other)
        
        // Mark first and third as completed
        manager.toggleItemCompletion(item: manager.shoppingList.items[0])
        manager.toggleItemCompletion(item: manager.shoppingList.items[2])
        
        // Act
        manager.clearCompleted()
        
        // Assert - Only uncompleted item remains
        XCTAssertEqual(manager.shoppingList.items.count, 1)
        XCTAssertEqual(manager.shoppingList.items[0].name, "Item 2")
    }
    
    func testClearAll() {
        // Arrange
        manager.addItem(name: "Item 1", quantity: "1", category: .other)
        manager.addItem(name: "Item 2", quantity: "2", category: .other)
        
        XCTAssertEqual(manager.shoppingList.items.count, 2)
        
        // Act
        manager.clearAll()
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 0)
    }
    
    func testClearShoppingList() {
        // Arrange
        manager.addItem(name: "Test", quantity: "1", category: .other)
        manager.saveShoppingList()
        
        // Act
        manager.clearShoppingList()
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 0)
        
        // Verify UserDefaults also cleared
        let userId = KeychainManager.get(key: "user_id")!
        let key = "shopping_list_\(userId)"
        XCTAssertNil(UserDefaults.standard.data(forKey: key))
    }
    
    // MARK: - Persistence Tests
    
    func testSaveAndLoadShoppingList() {
        // Arrange
        manager.addItem(name: "Persistent Item", quantity: "100g", category: .vegetables)
        manager.saveShoppingList()
        
        // Act - Create new manager to load from storage
        let newManager = ShoppingListManager()
        
        // Assert
        XCTAssertEqual(newManager.shoppingList.items.count, 1)
        XCTAssertEqual(newManager.shoppingList.items[0].name, "Persistent Item")
        XCTAssertEqual(newManager.shoppingList.items[0].quantity, "100g")
        XCTAssertEqual(newManager.shoppingList.items[0].category, .vegetables)
    }
    
    func testMultipleItemsPersistence() {
        // Arrange
        manager.addItem(name: "Item 1", quantity: "1", category: .meat)
        manager.addItem(name: "Item 2", quantity: "2", category: .dairy)
        manager.addItem(name: "Item 3", quantity: "3", category: .bakery)
        manager.saveShoppingList()
        
        // Act
        let newManager = ShoppingListManager()
        
        // Assert
        XCTAssertEqual(newManager.shoppingList.items.count, 3)
        XCTAssertEqual(newManager.shoppingList.items.map { $0.name }, ["Item 1", "Item 2", "Item 3"])
    }
    
    func testCompletionStatePersists() {
        // Arrange
        manager.addItem(name: "Test", quantity: "1", category: .other)
        manager.toggleItemCompletion(item: manager.shoppingList.items[0])
        manager.saveShoppingList()
        
        // Act
        let newManager = ShoppingListManager()
        
        // Assert
        XCTAssertTrue(newManager.shoppingList.items[0].isCompleted)
    }
    
    // MARK: - User Isolation Tests
    
    func testUserIsolation() {
        // Arrange - User 1 adds items
        try? KeychainManager.save(key: "user_id", value: "user_1")
        let manager1 = ShoppingListManager()
        manager1.addItem(name: "User 1 Item", quantity: "1", category: .other)
        manager1.saveShoppingList()
        
        // Act - User 2 logs in
        try? KeychainManager.save(key: "user_id", value: "user_2")
        let manager2 = ShoppingListManager()
        
        // Assert - User 2 should not see User 1's items
        XCTAssertEqual(manager2.shoppingList.items.count, 0, "User 2 should have empty list")
        
        // User 2 adds item
        manager2.addItem(name: "User 2 Item", quantity: "2", category: .other)
        manager2.saveShoppingList()
        
        // Switch back to User 1
        try? KeychainManager.save(key: "user_id", value: "user_1")
        let manager1Again = ShoppingListManager()
        
        // Assert - User 1 should still see their own items
        XCTAssertEqual(manager1Again.shoppingList.items.count, 1)
        XCTAssertEqual(manager1Again.shoppingList.items[0].name, "User 1 Item")
    }
    
    // MARK: - Grouping & Sorting Tests
    
    func testItemsGroupedByCategory() {
        // Arrange
        manager.addItem(name: "Tomato", quantity: "1", category: .vegetables)
        manager.addItem(name: "Milk", quantity: "1L", category: .dairy)
        manager.addItem(name: "Chicken", quantity: "500g", category: .meat)
        manager.addItem(name: "Onion", quantity: "2", category: .vegetables)
        
        // Act
        let grouped = manager.itemsGroupedByCategory()
        
        // Assert
        XCTAssertEqual(grouped[.vegetables]?.count, 2)
        XCTAssertEqual(grouped[.dairy]?.count, 1)
        XCTAssertEqual(grouped[.meat]?.count, 1)
        XCTAssertNil(grouped[.fish])
    }
    
    func testSortedCategories() {
        // Arrange
        manager.addItem(name: "Item 1", quantity: "1", category: .spices)
        manager.addItem(name: "Item 2", quantity: "2", category: .dairy)
        manager.addItem(name: "Item 3", quantity: "3", category: .vegetables)
        
        // Act
        let sorted = manager.sortedCategories()
        
        // Assert - Should only include categories with items
        XCTAssertEqual(sorted.count, 3)
        XCTAssertTrue(sorted.contains(.spices))
        XCTAssertTrue(sorted.contains(.dairy))
        XCTAssertTrue(sorted.contains(.vegetables))
        XCTAssertFalse(sorted.contains(.meat))
    }
    
    func testSortedCategoriesEmpty() {
        // Act
        let sorted = manager.sortedCategories()
        
        // Assert
        XCTAssertEqual(sorted.count, 0)
    }
    
    // MARK: - Edge Cases
    
    func testAddItemsEmptyArray() {
        // Act
        manager.addItems([])
        
        // Assert
        XCTAssertEqual(manager.shoppingList.items.count, 0)
    }
    
    func testLastUpdatedTimestamp() {
        let beforeAdd = Date()
        
        manager.addItem(name: "Test", quantity: "1", category: .other)
        
        let afterAdd = manager.shoppingList.lastUpdated
        
        XCTAssertGreaterThanOrEqual(afterAdd, beforeAdd)
    }
    
    func testSaveWithoutUser() {
        // Arrange - Remove user
        KeychainManager.deleteAll()
        
        // Act - Should not crash
        manager.addItem(name: "Test", quantity: "1", category: .other)
        manager.saveShoppingList()
        
        // Assert - Item added but not persisted
        XCTAssertEqual(manager.shoppingList.items.count, 1)
    }
    
    func testLoadCorruptedData() {
        // Arrange - Save corrupted data
        let userId = KeychainManager.get(key: "user_id")!
        let key = "shopping_list_\(userId)"
        UserDefaults.standard.set("corrupted data".data(using: .utf8), forKey: key)
        
        // Act - Should not crash, should fallback to empty list
        let newManager = ShoppingListManager()
        
        // Assert
        XCTAssertEqual(newManager.shoppingList.items.count, 0)
    }
}
