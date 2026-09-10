import Foundation

// MARK: - Shopping List Models

struct ShoppingListItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let quantity: String?
    var category: ItemCategory
    var isCompleted: Bool
    
    init(id: String = UUID().uuidString, name: String, quantity: String?, category: ItemCategory, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.category = category
        self.isCompleted = isCompleted
    }
}

enum ItemCategory: String, Codable, CaseIterable {
    case meat = "meat"
    case fish = "fish"
    case vegetables = "vegetables"
    case fruits = "fruits"
    case dairy = "dairy"
    case bakery = "bakery"
    case grains = "grains"
    case canned = "canned"
    case spices = "spices"
    case beverages = "beverages"
    case frozen = "frozen"
    case snacks = "snacks"
    case other = "other"
    
    var localizedName: String {
        switch self {
        case .meat: return L.category_meatPoultry.localized
        case .fish: return L.category_fishSeafood.localized
        case .vegetables: return L.category_vegetables.localized
        case .fruits: return L.category_fruits.localized
        case .dairy: return L.category_dairy.localized
        case .bakery: return L.category_bakery.localized
        case .grains: return L.category_grains.localized
        case .canned: return L.category_canned.localized
        case .spices: return L.category_spices.localized
        case .beverages: return L.category_beverages.localized
        case .frozen: return L.category_frozen.localized
        case .snacks: return L.category_snacks.localized
        case .other: return L.category_other.localized
        }
    }
    
    var systemImage: String {
        switch self {
        case .meat: return "fork.knife"
        case .fish: return "fish"
        case .vegetables: return "leaf.fill"
        case .fruits: return "apple.logo"
        case .dairy: return "cup.and.saucer.fill"
        case .bakery: return "birthday.cake.fill"
        case .grains: return "circle.grid.2x2.fill"
        case .canned: return "archivebox.fill"
        case .spices: return "sparkles"
        case .beverages: return "mug.fill"
        case .frozen: return "snowflake"
        case .snacks: return "gift.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    static func categorize(ingredient: String) -> ItemCategory {
        IngredientCategorizer.categorize(ingredient)
    }
}

struct ShoppingList: Codable {
    var items: [ShoppingListItem]
    var lastUpdated: Date
    
    init(items: [ShoppingListItem] = [], lastUpdated: Date = Date()) {
        self.items = items
        self.lastUpdated = lastUpdated
    }
}
