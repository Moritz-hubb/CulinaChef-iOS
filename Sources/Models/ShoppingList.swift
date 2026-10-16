import Foundation

// MARK: - Shopping List Models

struct ShoppingListItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    var quantity: String?
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

// MARK: - Stacking equal items

enum ShoppingListQuantity {
    enum CombineOutcome: Equatable {
        /// Same item. `nil` means both rows had no quantity.
        case merged(String?)
        case keepSeparate
    }

    static func normalizedName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    static func combine(_ existing: String?, _ incoming: String?) -> CombineOutcome {
        let left = cleaned(existing)
        let right = cleaned(incoming)

        switch (left, right) {
        case (nil, nil):
            return .merged(nil)
        case (nil, _), (_, nil):
            return .keepSeparate
        case let (left?, right?):
            switch (parse(left), parse(right)) {
            case let (leftAmount?, rightAmount?) where leftAmount.kind == rightAmount.kind:
                return .merged(format(leftAmount.adding(rightAmount)))
            case (nil, nil) where left.caseInsensitiveCompare(right) == .orderedSame:
                return .merged(left)
            default:
                return .keepSeparate
            }
        }
    }

    // MARK: Parsing

    private struct Amount: Equatable {
        enum Kind: Equatable {
            case mass
            case volume
            case other(String)
        }

        var base: Double
        var kind: Kind
        /// Unit as written, used when the unit is not converted to g/kg or ml/l.
        var unitToken: String

        func adding(_ other: Amount) -> Amount {
            var sum = self
            sum.base += other.base
            if unitToken.isEmpty {
                sum.unitToken = other.unitToken
            }
            return sum
        }
    }

    private static func cleaned(_ quantity: String?) -> String? {
        guard let quantity else { return nil }
        let trimmed = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func parse(_ quantity: String) -> Amount? {
        guard let regex = quantityExpression,
              let match = regex.firstMatch(in: quantity, range: NSRange(quantity.startIndex..., in: quantity)),
              let numberRange = Range(match.range(at: 1), in: quantity),
              let value = parseNumber(String(quantity[numberRange])) else {
            return nil
        }

        let unitToken: String
        if match.range(at: 2).location != NSNotFound, let unitRange = Range(match.range(at: 2), in: quantity) {
            unitToken = String(quantity[unitRange])
        } else {
            unitToken = ""
        }

        let (kind, factor) = classify(unitToken)
        return Amount(base: value * factor, kind: kind, unitToken: unitToken)
    }

    private static let quantityExpression = try? NSRegularExpression(
        pattern: #"^\s*(\d+\s*/\s*\d+|\d+(?:[.,]\d+)?)\s*(\S+)?\s*$"#
    )

    private static func parseNumber(_ raw: String) -> Double? {
        let compact = raw.replacingOccurrences(of: " ", with: "")
        if compact.contains("/") {
            let parts = compact.split(separator: "/")
            guard parts.count == 2,
                  let numerator = Double(parts[0].replacingOccurrences(of: ",", with: ".")),
                  let denominator = Double(parts[1].replacingOccurrences(of: ",", with: ".")),
                  denominator != 0 else {
                return nil
            }
            return numerator / denominator
        }
        return Double(compact.replacingOccurrences(of: ",", with: "."))
    }

    /// Mass is stored in grams, volume in milliliters.
    private static func classify(_ unitToken: String) -> (Amount.Kind, Double) {
        let key = fold(unitToken)
        if key.isEmpty {
            return (.other(""), 1)
        }
        if let grams = massToGrams[key] {
            return (.mass, grams)
        }
        if let milliliters = volumeToMilliliters[key] {
            return (.volume, milliliters)
        }
        return (.other(countAliases[key] ?? key), 1)
    }

    private static func fold(_ raw: String) -> String {
        raw.lowercased()
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    private static let massToGrams: [String: Double] = [
        "mg": 0.001,
        "g": 1, "gramm": 1, "gram": 1, "grams": 1,
        "kg": 1000, "kilo": 1000, "kilogramm": 1000, "kilogram": 1000, "kilograms": 1000
    ]

    private static let volumeToMilliliters: [String: Double] = [
        "ml": 1, "milliliter": 1, "millilitre": 1, "milliliters": 1, "millilitres": 1,
        "cl": 10,
        "dl": 100,
        "l": 1000, "lt": 1000, "liter": 1000, "litre": 1000, "liters": 1000, "litres": 1000
    ]

    private static let countAliases: [String: String] = [
        "stueck": "stueck", "stuecke": "stueck", "stk": "stueck", "st": "stueck",
        "piece": "stueck", "pieces": "stueck", "pcs": "stueck", "pc": "stueck",
        "tl": "tl", "tsp": "tl", "teeloeffel": "tl", "teaspoon": "tl", "teaspoons": "tl",
        "el": "el", "tbsp": "el", "essloeffel": "el", "tablespoon": "el", "tablespoons": "el",
        "prise": "prise", "prisen": "prise", "pinch": "prise", "pinches": "prise",
        "bund": "bund", "buendel": "bund", "bunch": "bund", "bunches": "bund",
        "dose": "dose", "dosen": "dose", "can": "dose", "cans": "dose",
        "tasse": "tasse", "tassen": "tasse", "cup": "tasse", "cups": "tasse",
        "becher": "becher",
        "packung": "packung", "packungen": "packung", "package": "packung", "packages": "packung", "pkg": "packung",
        "paket": "paket", "pakete": "paket",
        "glas": "glas", "glaeser": "glas",
        "scheibe": "scheibe", "scheiben": "scheibe",
        "zehe": "zehe", "zehen": "zehe"
    ]

    // MARK: Formatting

    private static func format(_ amount: Amount) -> String {
        switch amount.kind {
        case .mass:
            return formatMass(grams: amount.base)
        case .volume:
            return formatVolume(milliliters: amount.base)
        case .other:
            let number = formatAmount(amount.base)
            let token = amount.unitToken.trimmingCharacters(in: .whitespacesAndNewlines)
            return token.isEmpty ? number : "\(number) \(token)"
        }
    }

    private static func formatMass(grams: Double) -> String {
        let grams = snap(grams)
        if grams >= 1000 {
            return formatAmount(grams / 1000) + "kg"
        }
        if grams >= 1 {
            return formatAmount(grams) + "g"
        }
        if grams > 0 {
            return formatAmount(grams * 1000) + "mg"
        }
        return "0g"
    }

    private static func formatVolume(milliliters: Double) -> String {
        let milliliters = snap(milliliters)
        if milliliters >= 1000 {
            return formatAmount(milliliters / 1000) + "l"
        }
        return formatAmount(milliliters) + "ml"
    }

    private static func snap(_ value: Double) -> Double {
        (value * 1_000_000).rounded() / 1_000_000
    }

    private static func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let snapped = snap(value)
        return formatter.string(from: NSNumber(value: snapped)) ?? String(snapped)
    }
}
