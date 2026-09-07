import Foundation

/// One ingredient used in a cooking step (name + optional quantity for the current portion count).
struct StepIngredientDisplay: Identifiable, Hashable {
    let name: String
    let quantity: String?

    var id: String { "\(name.lowercased())|\(quantity ?? "")" }
}

/// Extracts per-step ingredients from instruction text so they can be shown
/// next to the step (and scale with servings like the main ingredient list).
enum StepIngredientExtractor {
    private static let marker = "⟦ingredient_qty:⟧"

    /// Units commonly used for ingredient amounts (DE/EN).
    private static let knownUnits: Set<String> = [
        "g", "kg", "mg", "ml", "l", "dl", "cl",
        "tl", "el", "esslöffel", "teelöffel", "essloeffel", "teeloeffel",
        "tasse", "tassen", "becher", "stück", "stueck", "st", "st.",
        "prise", "prisen", "bund", "dose", "dosen", "paket", "packung",
        "glas", "gläser", "glaeser",
        "cup", "cups", "tbsp", "tsp", "oz", "lb", "pound", "pounds",
        "ounce", "ounces", "piece", "pieces", "pinch", "bunch", "can", "cans", "package"
    ]

    // MARK: - Public API

    /// From free-text recipe instructions (`Recipe.ingredients` are `"200 g Mehl"` strings).
    static func ingredients(
        in instruction: String,
        recipeIngredients: [String],
        servings: Int,
        baseServings: Int = 4
    ) -> [StepIngredientDisplay] {
        let scaled = scaleIngredientQuantities(
            in: instruction,
            baseServings: baseServings,
            currentServings: servings
        )

        var results: [StepIngredientDisplay] = []
        var claimedNames = Set<String>()

        let catalog: [(name: String, quantity: String?)] = recipeIngredients.map { raw in
            let cleaned = raw.replacingOccurrences(of: marker, with: "")
            let name = parseIngredientName(cleaned)
            let qty = parseIngredientQuantity(cleaned).map { scaleQuantity($0, servings: servings, baseServings: baseServings) }
            return (name, qty)
        }.filter { !$0.name.isEmpty }
        .sorted { $0.name.count > $1.name.count }

        // 1) Explicit amounts marked in the step text
        for hit in extractMarkedQuantities(from: scaled) {
            let resolvedName = resolveName(afterMarkerText: hit.nameHint, catalog: catalog.map(\.name))
                ?? hit.nameHint.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !resolvedName.isEmpty else { continue }
            let key = normalize(resolvedName)
            guard !claimedNames.contains(key) else { continue }
            claimedNames.insert(key)
            results.append(StepIngredientDisplay(name: resolvedName, quantity: hit.quantity))
        }

        // 2) Recipe ingredients mentioned by name but without a marked amount — only when
        // the cook still has to handle them (not serving/plating recaps of finished food).
        guard !isNonActionableStep(scaled) else { return results }

        let plain = scaled
            .replacingOccurrences(of: marker, with: "")
            .replacingOccurrences(of: #"⟦label:.*?⟧"#, with: "", options: .regularExpression)

        for item in catalog {
            let key = normalize(item.name)
            guard !claimedNames.contains(key) else { continue }
            guard containsWord(item.name, in: plain) else { continue }
            claimedNames.insert(key)
            results.append(StepIngredientDisplay(name: item.name, quantity: item.quantity))
        }

        return results
    }

    /// From structured `RecipePlan` (generation / preview flow).
    static func ingredients(
        in stepDescription: String,
        planIngredients: [IngredientItem],
        currentServings: Int,
        baseServings: Int?
    ) -> [StepIngredientDisplay] {
        let base = max(baseServings ?? 4, 1)
        let asStrings: [String] = planIngredients.map { item in
            var parts: [String] = []
            if let amount = item.amount {
                let amountStr = amount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(amount))
                    : String(format: "%.1f", amount)
                parts.append(amountStr)
            }
            if let unit = item.unit, !unit.isEmpty {
                parts.append(unit)
            }
            parts.append(item.name)
            return parts.joined(separator: " ")
        }
        return ingredients(
            in: stepDescription,
            recipeIngredients: asStrings,
            servings: currentServings,
            baseServings: base
        )
    }

    // MARK: - Marked quantity extraction

    private struct MarkedHit {
        let quantity: String
        let nameHint: String
    }

    /// Finds `200 g⟦ingredient_qty:⟧ Mehl …` (and old `200⟦ingredient_qty:⟧ g Mehl`) after scaling.
    private static func extractMarkedQuantities(from text: String) -> [MarkedHit] {
        var working = text

        // Normalize old marker placement: number ⟦marker⟧ unit → number unit ⟦marker⟧
        let normalizePattern = #"(?i)(\d+(?:\/\d+|[\.,]\d+)?)\s*⟦ingredient_qty:⟧\s*(\p{L}+)"#
        if let re = try? NSRegularExpression(pattern: normalizePattern) {
            let ns = working as NSString
            let matches = re.matches(in: working, range: NSRange(location: 0, length: ns.length)).reversed()
            for m in matches {
                guard let numR = Range(m.range(at: 1), in: working),
                      let unitR = Range(m.range(at: 2), in: working),
                      let fullR = Range(m.range, in: working) else { continue }
                let replacement = "\(working[numR]) \(working[unitR])\(marker)"
                working.replaceSubrange(fullR, with: replacement)
            }
        }

        let pattern = #"(?i)(\d+(?:\/\d+|[\.,]\d+)?)\s*(\p{L}+)\s*⟦ingredient_qty:⟧\s*"#
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = working as NSString
        let matches = re.matches(in: working, range: NSRange(location: 0, length: ns.length))

        var hits: [MarkedHit] = []
        for m in matches {
            guard let numR = Range(m.range(at: 1), in: working),
                  let unitR = Range(m.range(at: 2), in: working) else { continue }
            let num = String(working[numR])
            let unit = String(working[unitR])
            let qty = "\(num) \(unit)".trimmingCharacters(in: .whitespaces)

            let afterIdx = working.index(working.startIndex, offsetBy: m.range.upperBound)
            let after = String(working[afterIdx...])
            let hint = firstNameTokens(from: after)
            hits.append(MarkedHit(quantity: qty, nameHint: hint))
        }
        return hits
    }

    private static func firstNameTokens(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // Stop words / verbs that typically follow the ingredient name in DE/EN recipes
        let stop: Set<String> = [
            "hinzu", "hinzugeben", "dazugeben", "zugeben", "und", "mit", "in", "auf", "für", "fur",
            "bis", "oder", "sowie", "zum", "zur", "im", "am", "vom", "der", "die", "das", "den", "dem",
            "add", "to", "into", "and", "with", "until", "then", "or", "the", "a", "an"
        ]

        var tokens: [String] = []
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace || ",.;:!?\n".contains($0) })
        for part in parts.prefix(4) {
            let t = String(part)
            let lower = t.lowercased()
            if stop.contains(lower) { break }
            if t.rangeOfCharacter(from: .decimalDigits) != nil { break }
            if t.contains(marker) { break }
            // Skip bare units accidentally captured as "name"
            if knownUnits.contains(lower) { continue }
            tokens.append(t)
            // Single solid compound (Mehl, Olivenöl) is usually enough
            if tokens.count >= 2 { break }
        }
        return tokens.joined(separator: " ")
    }

    private static func resolveName(afterMarkerText hint: String, catalog: [String]) -> String? {
        let hintNorm = normalize(hint)
        guard !hintNorm.isEmpty else { return nil }
        // Prefer catalog names that start with / equal the hint, longest first
        if let exact = catalog.first(where: { normalize($0) == hintNorm }) {
            return exact
        }
        if let prefix = catalog.first(where: { normalize($0).hasPrefix(hintNorm) || hintNorm.hasPrefix(normalize($0)) }) {
            return prefix
        }
        return hint.isEmpty ? nil : hint
    }

    /// Serving / plating / waiting: names like "Dip" or "Kartoffelpuffer" are recaps, not a shopping checklist.
    private static func isNonActionableStep(_ text: String) -> Bool {
        let t = normalize(text)
        let hints = [
            "servier", "anricht", "garnier", "anrichten", "auftischen", "genieß", "geniess",
            "teller", "platte", "anbieten",
            "serve", "serving", "plated", "plating", "garnish", "enjoy", "plate up"
        ]
        return hints.contains { t.contains($0) }
    }

    // MARK: - Matching helpers

    private static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func containsWord(_ name: String, in text: String) -> Bool {
        let n = normalize(name)
        let t = normalize(text)
        guard n.count >= 2 else { return false }
        // Prefer word-boundary-ish match; also allow substring for German compounds
        if let re = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: n))\\b") {
            let range = NSRange(location: 0, length: t.utf16.count)
            if re.firstMatch(in: t, range: range) != nil { return true }
        }
        return t.contains(n)
    }

    // MARK: - Parse / scale (aligned with RecipeDetailView)

    static func parseIngredientName(_ ingredient: String) -> String {
        var cleaned = ingredient.replacingOccurrences(of: marker, with: "")
        let pattern = #"^[\d\/.,\s-]+(?:g|kg|ml|l|tl|el|teelöffel|esslöffel|tasse|tassen|stück|prise|prisen)?\s*"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: cleaned.utf16.count)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    static func parseIngredientQuantity(_ ingredient: String) -> String? {
        let trimmed = ingredient.replacingOccurrences(of: marker, with: "").trimmingCharacters(in: .whitespaces)
        let patterns = [
            #"^([\d\/.,\s-]+\s*(?:g|kg|mg|ml|l|dl|cl|tl|el|esslöffel|teelöffel|essloeffel|teeloeffel|tasse|tassen|becher|stück|stueck|st\.|prise|prisen|bund|dose|dosen|paket|packung|glas|gläser))"#,
            #"^([\d\/.,\s-]+\s*(?:cup|cups|tbsp|tsp|oz|lb|pound|pounds|ounce|ounces|piece|pieces|pinch|bunch|can|cans|package))"#,
            #"^([\d\/.,]+)\s+"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
               let range = Range(match.range(at: 1), in: trimmed) {
                let qty = String(trimmed[range]).trimmingCharacters(in: .whitespaces)
                if !qty.isEmpty { return qty }
            }
        }
        return nil
    }

    static func scaleQuantity(_ quantity: String, servings: Int, baseServings: Int = 4) -> String {
        guard baseServings > 0 else { return quantity }
        let scale = Double(servings) / Double(baseServings)
        let pattern = #"([\d\/.,]+)\s*(.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: quantity, range: NSRange(location: 0, length: quantity.utf16.count)),
              let numberRange = Range(match.range(at: 1), in: quantity) else {
            return quantity
        }
        let numberStr = String(quantity[numberRange]).replacingOccurrences(of: ",", with: ".")
        let unit = match.range(at: 2).location != NSNotFound
            ? String(quantity[Range(match.range(at: 2), in: quantity)!])
            : ""

        if numberStr.contains("/") {
            let parts = numberStr.split(separator: "/")
            if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den != 0 {
                return formatNumber(num / den * scale) + unit
            }
        }
        if let number = Double(numberStr) {
            return formatNumber(number * scale) + unit
        }
        return quantity
    }

    private static func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else if value < 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }

    /// Scales marked (and detectable) ingredient amounts inside instruction text.
    static func scaleIngredientQuantities(in text: String, baseServings: Int, currentServings: Int) -> String {
        guard baseServings > 0, baseServings != currentServings else { return text }
        let scale = Double(currentServings) / Double(baseServings)
        var result = text

        let normalizePattern = #"(?i)(\d+(?:\/\d+|[\.,]\d+)?)\s*⟦ingredient_qty:⟧\s*(\p{L}+)"#
        if let normalizeRegex = try? NSRegularExpression(pattern: normalizePattern) {
            let ns = result as NSString
            for m in normalizeRegex.matches(in: result, range: NSRange(location: 0, length: ns.length)).reversed() {
                guard let numR = Range(m.range(at: 1), in: result),
                      let unitR = Range(m.range(at: 2), in: result),
                      let fullR = Range(m.range, in: result) else { continue }
                result.replaceSubrange(fullR, with: "\(result[numR]) \(result[unitR])\(marker)")
            }
        }

        let labeledPattern = #"(?i)(\b\d+\/\d+|\b\d+[\.,]\d+|\b\d+)\s*(\p{L}+)\s*⟦ingredient_qty:⟧"#
        if let labeledRegex = try? NSRegularExpression(pattern: labeledPattern) {
            let ns = result as NSString
            for m in labeledRegex.matches(in: result, range: NSRange(location: 0, length: ns.length)).reversed() {
                guard let numR = Range(m.range(at: 1), in: result),
                      let unitR = Range(m.range(at: 2), in: result),
                      let fullR = Range(m.range, in: result) else { continue }
                let numStr = String(result[numR])
                let unitStr = String(result[unitR])
                guard let value = parseNumber(numStr) else { continue }
                let scaled = formatScaledQuantity(value * scale, original: numStr)
                result.replaceSubrange(fullR, with: "\(scaled) \(unitStr)\(marker)")
            }
        }

        return result
    }

    private static func parseNumber(_ numStr: String) -> Double? {
        let s = numStr.replacingOccurrences(of: ",", with: ".")
        if s.contains("/") {
            let parts = s.split(separator: "/")
            if parts.count == 2, let n = Double(parts[0]), let d = Double(parts[1]), d != 0 {
                return n / d
            }
            return nil
        }
        return Double(s)
    }

    private static func formatScaledQuantity(_ value: Double, original: String) -> String {
        if original.contains("/") || value < 10, value.truncatingRemainder(dividingBy: 1) != 0 {
            return String(format: "%.1f", value)
        }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return value < 10 ? String(format: "%.1f", value) : String(format: "%.0f", value)
    }
}
