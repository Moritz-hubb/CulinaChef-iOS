import Foundation

// MARK: - Shopping List Manager
// Manages shopping list persistence with user isolation to prevent cache bleeding

@MainActor
class ShoppingListManager: ObservableObject {
    @Published var shoppingList: ShoppingList
    
    private let userDefaults = UserDefaults.standard
    
    // Computed property that changes when items change, forcing UI updates
    var categoriesVersion: Int {
        shoppingList.items.count
    }
    
    init() {
        self.shoppingList = ShoppingList()
        loadShoppingList()
    }
    
    // Generate user-specific key to prevent cache bleeding between accounts
    private func storageKey(for userId: String) -> String {
        return "shopping_list_\(userId)"
    }
    
    // Load shopping list for current user
    func loadShoppingList() {
        guard let userId = KeychainManager.get(key: "user_id") else {
            print("[ShoppingListManager] No user_id found, using empty list")
            shoppingList = ShoppingList()
            return
        }
        
        let key = storageKey(for: userId)
        
        guard let data = userDefaults.data(forKey: key) else {
            print("[ShoppingListManager] No saved shopping list for user \(userId)")
            shoppingList = ShoppingList()
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(ShoppingList.self, from: data)
            shoppingList = decoded
            print("[ShoppingListManager] Loaded shopping list with \(decoded.items.count) items for user \(userId)")
        } catch {
            print("[ShoppingListManager] Error decoding shopping list: \(error)")
            shoppingList = ShoppingList()
        }
    }
    
    // Save shopping list for current user
    func saveShoppingList() {
        guard let userId = KeychainManager.get(key: "user_id") else {
            print("[ShoppingListManager] Cannot save: no user_id")
            return
        }
        
        let key = storageKey(for: userId)
        shoppingList.lastUpdated = Date()
        
        do {
            let data = try JSONEncoder().encode(shoppingList)
            userDefaults.set(data, forKey: key)
            print("[ShoppingListManager] Saved shopping list with \(shoppingList.items.count) items for user \(userId)")
        } catch {
            print("[ShoppingListManager] Error encoding shopping list: \(error)")
        }
    }
    
    // Clear shopping list when user logs out
    func clearShoppingList() {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        let key = storageKey(for: userId)
        userDefaults.removeObject(forKey: key)
        shoppingList = ShoppingList()
        print("[ShoppingListManager] Cleared shopping list for user \(userId)")
    }
    
    // MARK: - Item Management
    
    func addItem(name: String, quantity: String?, category: ItemCategory) {
        let item = ShoppingListItem(name: name, quantity: quantity, category: category)
        var updatedList = shoppingList
        updatedList.items.append(item)
        shoppingList = updatedList
        saveShoppingList()
    }
    
    func addItems(_ items: [ShoppingListItem]) {
        var updatedList = shoppingList
        updatedList.items.append(contentsOf: items)
        shoppingList = updatedList
        saveShoppingList()
    }
    
    func toggleItemCompletion(item: ShoppingListItem) {
        if let index = shoppingList.items.firstIndex(where: { $0.id == item.id }) {
            var updatedList = shoppingList
            updatedList.items[index].isCompleted.toggle()
            shoppingList = updatedList
            saveShoppingList()
        }
    }
    
    func deleteItem(item: ShoppingListItem) {
        var updatedList = shoppingList
        updatedList.items.removeAll { $0.id == item.id }
        shoppingList = updatedList
        saveShoppingList()
    }
    
    func deleteItems(at offsets: IndexSet, in category: ItemCategory) {
        let categoryItems = itemsGroupedByCategory()[category] ?? []
        let idsToRemove = offsets.map { categoryItems[$0].id }
        var updatedList = shoppingList
        updatedList.items.removeAll { idsToRemove.contains($0.id) }
        shoppingList = updatedList
        saveShoppingList()
    }
    
    func clearCompleted() {
        var updatedList = shoppingList
        updatedList.items.removeAll { $0.isCompleted }
        shoppingList = updatedList
        saveShoppingList()
    }
    
    func clearAll() {
        var updatedList = shoppingList
        updatedList.items.removeAll()
        shoppingList = updatedList
        saveShoppingList()
    }
    
    // MARK: - Helpers
    
    func itemsGroupedByCategory() -> [ItemCategory: [ShoppingListItem]] {
        Dictionary(grouping: shoppingList.items) { $0.category }
    }
    
    func sortedCategories() -> [ItemCategory] {
        let grouped = itemsGroupedByCategory()
        return ItemCategory.allCases.filter { grouped[$0] != nil }
    }
}
