import Foundation

/// Invisible AI marker: the next step can be done during this step's waiting time.
enum ParallelNextStepMarker {
    static let token = "⟦parallel_next⟧"

    static func allowsNextStep(in text: String) -> Bool {
        text.contains(token)
    }

    static func stripping(from text: String) -> String {
        text
            .replacingOccurrences(of: token, with: "")
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

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

    /// Surface forms. Matching uses `normalize`, so diacritics do not need duplicates.
    private static let unitLiterals: [String] = [
        "esslöffel", "teelöffel", "essloeffel", "teeloeffel", "messerspitze",
        "kilogramm", "milliliter", "kilogram", "tablespoon", "tablespoons", "teaspoon", "teaspoons",
        "packung", "package", "packages", "ounce", "ounces", "pound", "pounds",
        "stück", "stueck", "stücke", "pieces", "piece", "tassen", "tasse", "becher",
        "prisen", "prise", "dosen", "dose", "gläser", "glaeser", "glas", "bund",
        "zehen", "zehe", "cloves", "clove", "scheiben", "scheibe", "slices", "slice",
        "handvoll", "spritzer", "zweige", "zweig", "knollen", "knolle",
        "liter", "litre", "liters", "tbsp", "tsp", "cups", "cup", "pinch", "pinches",
        "bunch", "cans", "can", "pkt", "stk", "pkg",
        "kg", "mg", "ml", "dl", "cl", "el", "tl", "oz", "lb", "st", "g", "l"
    ]

    private static let knownUnits: Set<String> = Set(unitLiterals.map(normalize))

    private static let adjectiveLiterals: [String] = [
        "große", "großer", "großes", "grosser", "grosse", "grosses",
        "kleine", "kleiner", "kleines", "frische", "frischer", "frisches", "frischen",
        "feine", "feiner", "feines", "fein", "getrocknete", "getrockneter", "getrocknetes",
        "gehackte", "gehackter", "gehacktes", "geriebene", "geriebener", "geriebenes",
        "gemahlene", "gemahlener", "gemahlenes", "gestrichen", "gestrichene", "gestrichener", "gestrichenes",
        "reife", "reifer", "reifes", "junge", "junger", "junges", "optional"
    ]

    private static let adjectives: Set<String> = Set(adjectiveLiterals.map(normalize))

    private static let skipTokens: Set<String> = [
        "der", "die", "das", "den", "dem", "des", "ein", "eine", "einer", "einem", "einen",
        "vom", "von", "am", "beim", "zum", "zur", "im", "ins", "aufs",
        "the", "a", "an"
    ]

    private static let stopTokens: Set<String> = [
        "und", "oder", "mit", "ohne", "in", "auf", "für", "fur", "bis", "sowie", "dann", "danach",
        "anschliessend", "anschließend", "hinzu", "hinzugeben", "dazugeben", "zugeben", "geben",
        "add", "to", "into", "and", "with", "until", "then", "or",
        "schneiden", "würfeln", "wurfeln", "hacken", "erhitzen", "anbraten", "braten",
        "kochen", "backen", "rühren", "ruhren", "verrühren", "verruhren", "mischen", "vermischen",
        "unterrühren", "unterruhren", "verquirlen", "auspressen", "waschen", "schälen", "schalen",
        "hinzufügen", "hinzufugen", "bestreuen", "würzen", "wurzen", "abschmecken",
        "servieren", "anrichten", "garen", "dünsten", "dunsten", "köcheln", "kocheln",
        "gießen", "giessen", "ablöschen", "abloschen", "reduzieren", "kneten", "ausrollen",
        "einfetten", "belegen", "füllen", "fullen", "verteilen", "marinieren", "ruhen", "warten",
        "lassen", "stellen", "legen", "wenden", "grillen", "dazugeben"
    ]

    private static let prepFragments: [String] = [
        "schneid", "wurf", "hack", "brat", "koch", "back", "ruhr", "misch", "geb", "wasch",
        "schal", "heiz", "dunst", "wurz", "streu", "giess", "pul", "knet", "form", "roll",
        "wend", "grill", "dampf", "schmor", "losch", "reduz", "montier", "stell", "full",
        "reib", "seih", "mix", "blend", "chop", "dice", "fry", "bake", "boil", "stir",
        "pour", "heat", "season", "slice", "peel", "whisk", "fold", "simmer", "roast",
        "saute", "saut", "purier", "kochel", "abschmeck", "marin", "quell", "druck"
    ]

    private static let platingFragments: [String] = [
        "servier", "anricht", "garnier", "auftisch", "geniess", "serve", "plating", "garnish",
        "enjoy", "warten", "ruhen", "warte"
    ]

    /// Remainder after an ingredient stem that still means that ingredient ("Zitronensaft", "Lachsfilet").
    private static let compoundSuffixes: Set<String> = [
        "filet", "wurfel", "scheibe", "scheiben", "stuck", "stucke", "pulver", "saft", "schale",
        "blatt", "blatter", "grun", "zehe", "zehen", "stange", "stangen", "streifen", "spalten",
        "spalte", "ringe", "ring", "brust", "schenkel", "keule", "lende", "hack"
    ]

    private static let oilBases: Set<String> = [
        "oliven", "sonnenblumen", "raps", "sesam", "erdnuss", "walnuss", "kuerbis", "kurbis",
        "truffel", "chili", "leindotter", "distel", "trauben", "brat"
    ]

    private static let prepTails: Set<String> = [
        "gehackt", "gewuerfelt", "gewurfelt", "gerieben", "gemahlen", "geschnitten",
        "in scheiben", "in streifen", "in wurfeln", "nach geschmack", "n. b.", "n.b.", "nb",
        "optional", "frisch", "fein"
    ]

    private static let numberPattern = #"[½¼¾⅓⅔]|\d+\s*[/\-–]\s*\d+(?:[.,]\d+)?|\d+[.,]\d+|\d+"#

    private static let unitPattern: String = {
        let parts = unitLiterals
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
        return "(?<![\\p{L}])(?:" + parts.joined(separator: "|") + ")(?![\\p{L}])"
    }()

    private static let adjectivePattern: String = {
        adjectiveLiterals
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
    }()

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

        let plain = plainStepText(scaled)
        let platingOnly = isOnlyPlatingOrWaiting(plain)

        for hit in extractMarkedQuantities(from: scaled) {
            let hint = hit.nameHint.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolved = resolveName(hint, catalog: catalog.map(\.name))
            let name = resolved ?? (platingOnly ? "" : parseIngredientName(hint))
            guard !name.isEmpty else { continue }
            let key = normalize(name)
            guard !claimedNames.contains(key) else { continue }
            claimedNames.insert(key)
            results.append(StepIngredientDisplay(name: name, quantity: hit.quantity))
        }

        for item in matchingCatalog(catalog, in: plain) {
            let key = normalize(item.name)
            guard !claimedNames.contains(key) else { continue }
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

    /// Finds marked amounts: `200 g⟦ingredient_qty:⟧ Mehl`, `2⟦ingredient_qty:⟧ Eier`, `2 Eier⟦ingredient_qty:⟧`.
    /// A word is treated as the unit only when it is a known unit. Otherwise it is the ingredient name.
    private static func extractMarkedQuantities(from text: String) -> [MarkedHit] {
        let working = normalizeKnownUnitMarkerPlacement(in: text)
        let pattern = "(?i)(\(numberPattern))\\s*(\\p{L}+)?\\s*\(NSRegularExpression.escapedPattern(for: marker))"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = working as NSString
        let matches = re.matches(in: working, range: NSRange(location: 0, length: ns.length))

        var hits: [MarkedHit] = []
        for match in matches {
            guard let numR = Range(match.range(at: 1), in: working) else { continue }
            let num = String(working[numR])
            let word: String? = {
                guard match.range(at: 2).location != NSNotFound, match.range(at: 2).length > 0,
                      let wordR = Range(match.range(at: 2), in: working) else { return nil }
                return String(working[wordR])
            }()
            let afterIdx = working.index(working.startIndex, offsetBy: match.range.upperBound)
            let after = String(working[afterIdx...])

            if let word, knownUnits.contains(normalize(word)) {
                hits.append(MarkedHit(quantity: "\(num) \(word)", nameHint: nameTokens(from: after)))
            } else if let word {
                hits.append(MarkedHit(quantity: num, nameHint: nameTokens(from: word + " " + after)))
            } else {
                hits.append(MarkedHit(quantity: num, nameHint: nameTokens(from: after)))
            }
        }
        return hits
    }

    /// Old marker placement `200⟦ingredient_qty:⟧ g` becomes `200 g⟦ingredient_qty:⟧` only when the word is a real unit.
    private static func normalizeKnownUnitMarkerPlacement(in text: String) -> String {
        let pattern = "(?i)(\(numberPattern))\\s*\(NSRegularExpression.escapedPattern(for: marker))\\s*(\\p{L}+)"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        var working = text
        let ns = working as NSString
        let matches = re.matches(in: working, range: NSRange(location: 0, length: ns.length)).reversed()
        for match in matches {
            guard let numR = Range(match.range(at: 1), in: working),
                  let wordR = Range(match.range(at: 2), in: working),
                  let fullR = Range(match.range, in: working) else { continue }
            let word = String(working[wordR])
            guard knownUnits.contains(normalize(word)) else { continue }
            working.replaceSubrange(fullR, with: "\(working[numR]) \(word)\(marker)")
        }
        return working
    }

    private static func nameTokens(from text: String) -> String {
        let parts = text.split { !$0.isLetter && $0 != "-" }
        var tokens: [String] = []
        for part in parts {
            let token = String(part)
            let key = normalize(token)
            if key.isEmpty { continue }
            if skipTokens.contains(key) || adjectives.contains(key) || knownUnits.contains(key) { continue }
            if stopTokens.contains(key) { break }
            tokens.append(token)
            if tokens.count >= 3 { break }
        }
        return tokens.joined(separator: " ")
    }

    private static func resolveName(_ hint: String, catalog: [String]) -> String? {
        let hintWords = words(in: hint)
        guard !hintWords.isEmpty else { return nil }
        var best: (name: String, score: Int)?
        for name in catalog {
            let tokens = significantTokens(name)
            guard !tokens.isEmpty else { continue }
            var score = 0
            for token in tokens {
                let tokenKey = normalize(token)
                let matched = hintWords.contains { word in
                    matchesToken(word, token: token, loose: true)
                }
                guard matched else { continue }
                let exact = hintWords.contains { normalize($0) == tokenKey }
                score += exact ? 2 : 1
            }
            // Prefer a catalog entry whose head noun is actually in the hint.
            let head = tokens.last!
            let headHit = hintWords.contains(where: { matchesToken($0, token: head, loose: true) })
            guard headHit, score > 0 else { continue }
            if best == nil || score > best!.score || (score == best!.score && name.count > best!.name.count) {
                best = (name, score)
            }
        }
        return best?.name
    }

    /// Serving / plating / waiting with no prep verb. Finished dishes marked there are not ingredients.
    /// Real recipe ingredients named in the same sentence are still listed by the catalog pass.
    private static func isOnlyPlatingOrWaiting(_ text: String) -> Bool {
        let tokens = words(in: text).map(normalize)
        if tokens.contains(where: { word in prepFragments.contains(where: { word.contains($0) }) }) {
            return false
        }
        return tokens.contains(where: { word in platingFragments.contains(where: { word.contains($0) }) })
    }

    // MARK: - Catalog matching

    private static func matchingCatalog(
        _ catalog: [(name: String, quantity: String?)],
        in text: String
    ) -> [(name: String, quantity: String?)] {
        let hay = words(in: text)
        struct Candidate {
            let item: (name: String, quantity: String?)
            let tokens: [String]
            let head: String
            let full: Bool
        }
        var matched: [Candidate] = []
        for item in catalog {
            let tokens = significantTokens(item.name)
            guard !tokens.isEmpty else { continue }
            let joiner = isJoiner(item.name)
            let heads = joiner ? tokens : [tokens.last!]
            let mentioned = heads.contains { head in
                hay.contains(where: { matchesToken($0, token: head, loose: false) })
            }
            guard mentioned else { continue }
            let full = tokens.allSatisfy { token in
                hay.contains(where: { matchesToken($0, token: token, loose: false) })
            }
            let headKey = joiner ? "join:\(normalize(item.name))" : normalize(tokens.last!)
            matched.append(Candidate(item: item, tokens: tokens, head: headKey, full: full))
        }

        var kept: [Candidate] = []
        for group in Dictionary(grouping: matched, by: \.head).values {
            let fullOnes = group.filter(\.full)
            if !fullOnes.isEmpty {
                kept.append(contentsOf: fullOnes)
            } else if let minCount = group.map({ $0.tokens.count }).min() {
                kept.append(contentsOf: group.filter { $0.tokens.count == minCount })
            }
        }

        let fullSets = kept.filter(\.full).map { Set($0.tokens.map(normalize)) }
        let keptItems = kept.filter { candidate in
            let mine = Set(candidate.tokens.map(normalize))
            let dominated = fullSets.contains { other in other.count > mine.count && mine.isSubset(of: other) }
            return !dominated
        }.map(\.item)
        let order = Dictionary(catalog.enumerated().map { ($0.element.name, $0.offset) }, uniquingKeysWith: { first, _ in first })
        return keptItems.sorted { (order[$0.name] ?? 0) < (order[$1.name] ?? 0) }
    }

    private static func isJoiner(_ name: String) -> Bool {
        let n = normalize(name)
        return n.contains(" und ") || n.contains(" oder ") || n.contains(" & ")
    }

    private static func matchesToken(_ word: String, token: String, loose: Bool) -> Bool {
        let w = normalize(word)
        let t = normalize(token)
        guard w.count >= 2, t.count >= 2 else { return false }
        if w == t { return true }
        if samePlural(w, t) { return true }
        if isCompound(w, of: t) { return true }
        if loose, oilMatch(w, stem: t) { return true }
        return false
    }

    private static func samePlural(_ a: String, _ b: String) -> Bool {
        if a == "ei" && (b == "eier" || b == "eiern") { return true }
        if b == "ei" && (a == "eier" || a == "eiern") { return true }
        guard a.count >= 4, b.count >= 4 else { return false }
        return a + "n" == b || b + "n" == a
    }

    private static func isCompound(_ word: String, of token: String) -> Bool {
        guard token.count >= 4, word.count > token.count, word.hasPrefix(token) else { return false }
        var rest = String(word.dropFirst(token.count))
        if rest.hasPrefix("en") { rest.removeFirst(2) }
        else if rest.hasPrefix("er") { rest.removeFirst(2) }
        else if rest.hasPrefix("n") || rest.hasPrefix("s") { rest.removeFirst(1) }
        return compoundSuffixes.contains(rest)
    }

    private static func oilMatch(_ word: String, stem: String) -> Bool {
        guard stem == "ol", word.hasSuffix("ol"), word.count > stem.count else { return false }
        return oilBases.contains(String(word.dropLast(2)))
    }

    private static func significantTokens(_ name: String) -> [String] {
        words(in: name).filter { word in
            let key = normalize(word)
            return key.count >= 2 && !skipTokens.contains(key) && !knownUnits.contains(key) && !adjectives.contains(key) && !stopTokens.contains(key)
        }
    }

    private static func words(in text: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: #"\p{L}+"#) else { return [] }
        let ns = text as NSString
        return re.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }

    private static func plainStepText(_ text: String) -> String {
        ParallelNextStepMarker.stripping(from: text)
            .replacingOccurrences(of: marker, with: "")
            .replacingOccurrences(of: #"⟦label:.*?⟧"#, with: "", options: .regularExpression)
    }

    // MARK: - Matching helpers

    private static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    // MARK: - Parse / scale (aligned with RecipeDetailView)

    static func parseIngredientName(_ ingredient: String) -> String {
        var cleaned = ingredient.replacingOccurrences(of: marker, with: "")
        cleaned = cleaned.replacingOccurrences(of: #"\([^)]*\)"#, with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\[[^\]]*\]"#, with: " ", options: .regularExpression)
        for _ in 0..<3 {
            let next = stripLeadingQuantity(from: cleaned)
            if next == cleaned { break }
            cleaned = next
        }
        cleaned = stripVonQuantity(from: cleaned)
        cleaned = stripGluedSingleLetterUnit(from: cleaned)
        cleaned = stripTrailingGluedUnit(from: cleaned)
        cleaned = stripLeadingAdjectives(from: cleaned)
        cleaned = stripPrepTails(from: cleaned)
        return collapseSpaces(cleaned)
    }

    static func parseIngredientQuantity(_ ingredient: String) -> String? {
        let trimmed = ingredient.replacingOccurrences(of: marker, with: "").trimmingCharacters(in: .whitespaces)
        guard let parts = leadingQuantityParts(in: trimmed) else { return nil }
        if let unit = parts.unit, !unit.isEmpty {
            return "\(parts.number) \(unit)"
        }
        return parts.number
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

    /// Scales marked ingredient amounts inside instruction text.
    static func scaleIngredientQuantities(in text: String, baseServings: Int, currentServings: Int) -> String {
        guard baseServings > 0, baseServings != currentServings else { return text }
        let scale = Double(currentServings) / Double(baseServings)
        var result = normalizeKnownUnitMarkerPlacement(in: text)

        let pattern = "(?i)(\(numberPattern))\\s*(\\p{L}+)?\\s*\(NSRegularExpression.escapedPattern(for: marker))"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
        let ns = result as NSString
        for match in regex.matches(in: result, range: NSRange(location: 0, length: ns.length)).reversed() {
            guard let numR = Range(match.range(at: 1), in: result),
                  let fullR = Range(match.range, in: result) else { continue }
            let numStr = String(result[numR])
            let scaled = scaleNumberToken(numStr, by: scale)
            let word: String? = {
                guard match.range(at: 2).location != NSNotFound, match.range(at: 2).length > 0,
                      let wordR = Range(match.range(at: 2), in: result) else { return nil }
                return String(result[wordR])
            }()
            if let word {
                result.replaceSubrange(fullR, with: "\(scaled) \(word)\(marker)")
            } else {
                result.replaceSubrange(fullR, with: "\(scaled)\(marker)")
            }
        }
        return result
    }

    private static func scaleNumberToken(_ token: String, by scale: Double) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespaces)
        if trimmed.count == 1, let ch = trimmed.first, let value = fractionChars[ch] {
            return formatScaledQuantity(value * scale, original: trimmed)
        }
        if trimmed.contains("/"), !trimmed.contains("-"), !trimmed.contains("–") {
            let parts = trimmed.replacingOccurrences(of: " ", with: "").split(separator: "/")
            if parts.count == 2, let n = Double(parts[0]), let d = Double(parts[1]), d != 0 {
                return formatScaledQuantity(n / d * scale, original: trimmed)
            }
        }
        let rangeParts = trimmed.split(whereSeparator: { $0 == "-" || $0 == "–" })
        if rangeParts.count == 2, let a = parseNumber(String(rangeParts[0])), let b = parseNumber(String(rangeParts[1])) {
            let sep = trimmed.contains("–") ? "–" : "-"
            return formatScaledQuantity(a * scale, original: String(rangeParts[0])) + sep + formatScaledQuantity(b * scale, original: String(rangeParts[1]))
        }
        if let value = parseNumber(trimmed) {
            return formatScaledQuantity(value * scale, original: trimmed)
        }
        return token
    }

    private static let fractionChars: [Character: Double] = [
        "½": 0.5, "¼": 0.25, "¾": 0.75, "⅓": 1.0 / 3.0, "⅔": 2.0 / 3.0
    ]

    private static func parseNumber(_ numStr: String) -> Double? {
        let s = numStr.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
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

    // MARK: - Quantity stripping

    private struct QuantityParts {
        let number: String
        let unit: String?
        let consumed: String
    }

    private static func leadingQuantityParts(in text: String) -> QuantityParts? {
        let pattern = "(?i)^\\s*(?:(?:ca\\.?|circa|etwa|approx\\.?|ungefähr|ungefaehr)\\s+)?(\(numberPattern))(?:\\s+(?:\(adjectivePattern))){0,3}(?:\\s*(\(unitPattern)))?"
        guard let re = try? NSRegularExpression(pattern: pattern),
              let match = re.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)),
              match.range.length > 0,
              let numR = Range(match.range(at: 1), in: text),
              let fullR = Range(match.range, in: text) else { return nil }
        let unit: String? = {
            guard match.range(at: 2).location != NSNotFound, match.range(at: 2).length > 0,
                  let unitR = Range(match.range(at: 2), in: text) else { return nil }
            return String(text[unitR])
        }()
        return QuantityParts(number: String(text[numR]), unit: unit, consumed: String(text[fullR]))
    }

    private static func stripLeadingQuantity(from text: String) -> String {
        guard let parts = leadingQuantityParts(in: text) else { return text }
        var rest = text
        if let range = rest.range(of: parts.consumed) {
            rest.removeSubrange(range)
        }
        return rest
    }

    /// `Knoblauchzehen` keeps the food and drops the glued counting word.
    private static func stripTrailingGluedUnit(from text: String) -> String {
        var parts = text.split(separator: " ").map(String.init)
        guard let last = parts.last else { return text }
        let lastKey = normalize(last)
        let units = unitLiterals.map(normalize).filter { $0.count >= 4 }.sorted { $0.count > $1.count }
        for unit in units {
            guard lastKey.count >= unit.count + 4, lastKey.hasSuffix(unit) else { continue }
            let trimmed = String(last.dropLast(unit.count))
            guard normalize(trimmed).count >= 4 else { continue }
            parts[parts.count - 1] = trimmed
            break
        }
        return parts.joined(separator: " ")
    }

    /// `200gMehl` leaves a glued `g`/`l` after the number is removed. `Gurke` and `Lachs` do not.
    private static func stripGluedSingleLetterUnit(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let re = try? NSRegularExpression(pattern: #"^[gGlL](?=[A-ZÄÖÜ])"#) else { return text }
        let range = NSRange(location: 0, length: (trimmed as NSString).length)
        return re.stringByReplacingMatches(in: trimmed, range: range, withTemplate: "")
    }

    private static func stripVonQuantity(from text: String) -> String {
        let pattern = "(?i)\\bvon\\s+(?:\(numberPattern))(?:\\s+(?:\(adjectivePattern))){0,3}(?:\\s*(?:\(unitPattern)))?"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return re.stringByReplacingMatches(in: text, range: range, withTemplate: "von")
    }

    private static func stripLeadingAdjectives(from text: String) -> String {
        var parts = text.split(separator: " ").map(String.init)
        while parts.count > 1 {
            let key = normalize(parts[0].trimmingCharacters(in: .punctuationCharacters))
            if adjectives.contains(key) {
                parts.removeFirst()
            } else {
                break
            }
        }
        return parts.joined(separator: " ")
    }

    private static func stripPrepTails(from text: String) -> String {
        let segments = text.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
        guard segments.count > 1 else { return text }
        let kept = segments.filter { segment in
            !prepTails.contains(normalize(segment))
        }
        let chosen = kept.isEmpty ? [segments[0]] : kept
        return chosen.joined(separator: " ")
    }

    private static func collapseSpaces(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ",.;:-"))
    }
}
