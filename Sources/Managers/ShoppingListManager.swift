import Foundation
import WidgetKit

// MARK: - Shopping List Manager
// Manages shopping list persistence with user isolation to prevent cache bleeding

@MainActor
class ShoppingListManager: ObservableObject {
    @Published var shoppingList: ShoppingList
    
    private let userDefaults = UserDefaults.standard
    private let appGroupID = "group.com.moritzserrin.culinachef"
    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
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
            Logger.debug("[ShoppingListManager] No user_id found, using empty list", category: .data)
            shoppingList = ShoppingList()
            return
        }
        
        let key = storageKey(for: userId)
        
        // First, try to load from App Group (may have been updated by widget)
        if let appGroupDefaults = appGroupDefaults,
           let appGroupData = appGroupDefaults.data(forKey: "shopping_list"),
           let appGroupJson = try? JSONSerialization.jsonObject(with: appGroupData) as? [String: Any],
           let appGroupItems = appGroupJson["items"] as? [[String: Any]] {
            // Convert App Group format to ShoppingList format
            let items = appGroupItems.compactMap { dict -> ShoppingListItem? in
                guard let id = dict["id"] as? String,
                      let name = dict["name"] as? String,
                      let categoryString = dict["category"] as? String,
                      let category = ItemCategory(rawValue: categoryString),
                      let isCompleted = dict["isCompleted"] as? Bool else {
                    return nil
                }
                let quantity = dict["quantity"] as? String
                return ShoppingListItem(
                    id: id,
                    name: name,
                    quantity: quantity?.isEmpty == false ? quantity : nil,
                    category: category,
                    isCompleted: isCompleted
                )
            }
            
            // If App Group has newer data, use it and sync back to main UserDefaults
            if let appGroupLastUpdated = appGroupJson["lastUpdated"] as? TimeInterval {
                let appGroupDate = Date(timeIntervalSince1970: appGroupLastUpdated)
                var appGroupList = ShoppingList()
                appGroupList.items = items
                appGroupList.lastUpdated = appGroupDate
                
                // Check if App Group data is newer than main UserDefaults
                var shouldUseAppGroup = true
                if let mainData = userDefaults.data(forKey: key),
                   let mainList = try? JSONDecoder().decode(ShoppingList.self, from: mainData),
                   mainList.lastUpdated > appGroupDate {
                    shouldUseAppGroup = false
                }
                
                if shouldUseAppGroup {
                    shoppingList = appGroupList
                    // Sync back to main UserDefaults
                    if let encoded = try? JSONEncoder().encode(appGroupList) {
                        userDefaults.set(encoded, forKey: key)
                    }
                    Logger.debug("[ShoppingListManager] Loaded shopping list from App Group (widget update) with \(items.count) items", category: .data)
                    return
                }
            }
        }
        
        // Fallback to main UserDefaults
        guard let data = userDefaults.data(forKey: key) else {
            Logger.sensitive("[ShoppingListManager] No saved shopping list for user \(userId)", category: .data)
            shoppingList = ShoppingList()
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(ShoppingList.self, from: data)
            shoppingList = decoded
            Logger.sensitive("[ShoppingListManager] Loaded shopping list with \(decoded.items.count) items for user \(userId)", category: .data)
        } catch {
            Logger.error("[ShoppingListManager] Error decoding shopping list", error: error, category: .data)
            shoppingList = ShoppingList()
        }
    }
    
    // Save shopping list for current user
    func saveShoppingList() {
        guard let userId = KeychainManager.get(key: "user_id") else {
            Logger.debug("[ShoppingListManager] Cannot save: no user_id", category: .data)
            return
        }
        
        let key = storageKey(for: userId)
        shoppingList.lastUpdated = Date()
        
        do {
            let data = try JSONEncoder().encode(shoppingList)
            // Save to standard UserDefaults
            userDefaults.set(data, forKey: key)
            
            // Also save to App Group for widget access (convert to widget-compatible format)
            if let appGroupDefaults = appGroupDefaults {
                // Convert ShoppingList to widget-compatible format (using Dictionary for compatibility)
                let widgetItems: [[String: Any]] = shoppingList.items.map { item in
                    [
                        "id": item.id,
                        "name": item.name,
                        "quantity": item.quantity ?? "",
                        "category": item.category.rawValue,  // Convert enum to string
                        "isCompleted": item.isCompleted
                    ]
                }
                let widgetData: [String: Any] = [
                    "items": widgetItems,
                    "lastUpdated": shoppingList.lastUpdated.timeIntervalSince1970
                ]
                
                // Save as JSON data
                if let jsonData = try? JSONSerialization.data(withJSONObject: widgetData) {
                    appGroupDefaults.set(jsonData, forKey: "shopping_list")
                    let syncResult = appGroupDefaults.synchronize()
                    Logger.debug("[ShoppingListManager] saveShoppingList() App Group sync result: \(syncResult), items: \(shoppingList.items.count)", category: .data)
                    
                    // Verify data was saved
                    if let savedData = appGroupDefaults.data(forKey: "shopping_list") {
                        Logger.debug("[ShoppingListManager] saveShoppingList() VERIFIED: Data saved to App Group (\(savedData.count) bytes)", category: .data)
                    } else {
                        Logger.error("[ShoppingListManager] saveShoppingList() ERROR: Data not found after saving!", category: .data)
                    }
                } else {
                    Logger.error("[ShoppingListManager] saveShoppingList() ERROR: Failed to encode widget data", category: .data)
                }
                
                // Reload widget timeline
                WidgetCenter.shared.reloadTimelines(ofKind: "CulinaChefShoppingListWidget")
                Logger.debug("[ShoppingListManager] saveShoppingList() Widget timeline reload requested", category: .data)
            }
            
            Logger.sensitive("[ShoppingListManager] Saved shopping list with \(shoppingList.items.count) items for user \(userId)", category: .data)
        } catch {
            Logger.error("[ShoppingListManager] Error encoding shopping list", error: error, category: .data)
        }
    }
    
    // Clear shopping list when user logs out
    func clearShoppingList() {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        let key = storageKey(for: userId)
        userDefaults.removeObject(forKey: key)
        shoppingList = ShoppingList()
        Logger.sensitive("[ShoppingListManager] Cleared shopping list for user \(userId)", category: .data)
    }
    
    // MARK: - Item Management
    
    func addItem(name: String, quantity: String?, category: ItemCategory) {
        let item = ShoppingListItem(name: name, quantity: quantity, category: category)
        var updatedList = shoppingList
        updatedList.items.append(item)
        shoppingList = updatedList
        saveShoppingList()
        // Notify views that the shopping list changed
        NotificationCenter.default.post(name: NSNotification.Name("ShoppingListDidChange"), object: nil)
    }
    
    func addItems(_ items: [ShoppingListItem]) {
        var updatedList = shoppingList
        updatedList.items.append(contentsOf: items)
        shoppingList = updatedList
        saveShoppingList()
        // Notify views that the shopping list changed
        NotificationCenter.default.post(name: NSNotification.Name("ShoppingListDidChange"), object: nil)
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
        let categories = ItemCategory.allCases.filter { grouped[$0] != nil }
        // Return categories in a consistent order, with new categories appearing at the end
        return categories.sorted { cat1, cat2 in
            let index1 = ItemCategory.allCases.firstIndex(of: cat1) ?? Int.max
            let index2 = ItemCategory.allCases.firstIndex(of: cat2) ?? Int.max
            return index1 < index2
        }
    }
}
