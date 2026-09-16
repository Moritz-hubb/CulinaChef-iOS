import Foundation
import WidgetKit

// MARK: - Shopping List Manager
// Manages shopping list persistence with user isolation to prevent cache bleeding

@MainActor
class ShoppingListManager: ObservableObject {
    @Published var shoppingList: ShoppingList

    static let appGroupListKey = "shopping_list"
    static let appGroupOwnerKey = "ownerUserId"

    private let userDefaults: UserDefaults
    private let appGroupDefaults: UserDefaults?

    var categoriesVersion: Int {
        shoppingList.items.count
    }

    init(
        userDefaults: UserDefaults = .standard,
        appGroupDefaults: UserDefaults? = UserDefaults(suiteName: "group.com.moritzserrin.culinachef")
    ) {
        self.userDefaults = userDefaults
        self.appGroupDefaults = appGroupDefaults
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

        if let appGroupDefaults = appGroupDefaults,
           let appGroupData = appGroupDefaults.data(forKey: Self.appGroupListKey),
           let appGroupJson = try? JSONSerialization.jsonObject(with: appGroupData) as? [String: Any],
           let ownerId = appGroupJson[Self.appGroupOwnerKey] as? String,
           ownerId == userId,
           let appGroupItems = appGroupJson["items"] as? [[String: Any]] {
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

            if let appGroupLastUpdated = appGroupJson["lastUpdated"] as? TimeInterval {
                let appGroupDate = Date(timeIntervalSince1970: appGroupLastUpdated)
                var appGroupList = ShoppingList()
                appGroupList.items = items
                appGroupList.lastUpdated = appGroupDate

                var shouldUseAppGroup = true
                if let mainData = userDefaults.data(forKey: key),
                   let mainList = try? JSONDecoder().decode(ShoppingList.self, from: mainData),
                   mainList.lastUpdated > appGroupDate {
                    shouldUseAppGroup = false
                }

                if shouldUseAppGroup {
                    shoppingList = appGroupList
                    if let encoded = try? JSONEncoder().encode(appGroupList) {
                        userDefaults.set(encoded, forKey: key)
                    }
                    Logger.debug("[ShoppingListManager] Loaded shopping list from App Group (widget update) with \(items.count) items", category: .data)
                    return
                }
            }
        }

        // Fallback to main UserDefaults
        if let data = userDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(ShoppingList.self, from: data) {
            shoppingList = decoded
            Logger.sensitive("[ShoppingListManager] Loaded shopping list with \(decoded.items.count) items for user \(userId)", category: .data)
        } else {
            Logger.sensitive("[ShoppingListManager] No saved shopping list for user \(userId)", category: .data)
            shoppingList = ShoppingList()
        }
        writeAppGroupSnapshot(userId: userId)
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
            writeAppGroupSnapshot(userId: userId)
            WidgetCenter.shared.reloadTimelines(ofKind: "CulinaChefShoppingListWidget")
            Logger.sensitive("[ShoppingListManager] Saved shopping list with \(shoppingList.items.count) items for user \(userId)", category: .data)
        } catch {
            Logger.error("[ShoppingListManager] Error encoding shopping list", error: error, category: .data)
        }
    }

    private func writeAppGroupSnapshot(userId: String) {
        guard let appGroupDefaults else { return }
        let widgetItems: [[String: Any]] = shoppingList.items.map { item in
            [
                "id": item.id,
                "name": item.name,
                "quantity": item.quantity ?? "",
                "category": item.category.rawValue,
                "isCompleted": item.isCompleted
            ]
        }
        let widgetData: [String: Any] = [
            "items": widgetItems,
            "lastUpdated": shoppingList.lastUpdated.timeIntervalSince1970,
            Self.appGroupOwnerKey: userId
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: widgetData) {
            appGroupDefaults.set(jsonData, forKey: Self.appGroupListKey)
        }
    }
    
    // Clear shopping list when user logs out
    func clearShoppingList(for userId: String? = nil) {
        let resolvedUserId = userId ?? KeychainManager.get(key: "user_id")
        if let resolvedUserId, !resolvedUserId.isEmpty {
            userDefaults.removeObject(forKey: storageKey(for: resolvedUserId))
            Logger.sensitive("[ShoppingListManager] Cleared shopping list for user \(resolvedUserId)", category: .data)
        }
        appGroupDefaults?.removeObject(forKey: Self.appGroupListKey)
        shoppingList = ShoppingList()
        WidgetCenter.shared.reloadAllTimelines()
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
    
    func updateItemCategory(item: ShoppingListItem, to category: ItemCategory) {
        guard item.category != category else { return }
        guard let index = shoppingList.items.firstIndex(where: { $0.id == item.id }) else { return }
        var updatedList = shoppingList
        updatedList.items[index].category = category
        shoppingList = updatedList
        IngredientCategorizer.rememberOverride(name: item.name, category: category)
        saveShoppingList()
        NotificationCenter.default.post(name: NSNotification.Name("ShoppingListDidChange"), object: nil)
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
