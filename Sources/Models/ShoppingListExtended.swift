import Foundation

/// Token-based grocery categorizer.
/// Avoids naive substring hits ("milch" in Milchreis, "ei" in Speiseeis, "reis" in Preiselbeere)
/// by scoring whole tokens and German compounds, then applying form transformers (Saft, TK, Dose).
enum IngredientCategorizer {
    private static let overridesKey = "shopping_category_overrides"

    // MARK: - Public

    static func categorize(_ ingredient: String) -> ItemCategory {
        let prepared = prepare(ingredient)
        guard !prepared.normalized.isEmpty else { return .other }

        if let override = override(for: prepared) {
            return override
        }

        if let frozen = frozenHint(prepared.rawLower) {
            return frozen
        }

        if let phrase = matchPhrases(in: prepared.normalized, compact: prepared.compact) {
            return phrase
        }

        if let form = formDrivenCategory(prepared) {
            return form
        }

        return scoreKeywords(prepared)
    }

    static func rememberOverride(name: String, category: ItemCategory) {
        let prepared = prepare(name)
        guard !prepared.normalized.isEmpty else { return }
        var map = loadOverrides()
        map[prepared.normalized] = category.rawValue
        map[prepared.compact] = category.rawValue
        UserDefaults.standard.set(map, forKey: storageKey())
    }

    // MARK: - Preparation

    struct Prepared {
        let rawLower: String
        let normalized: String
        let compact: String
        let tokens: [String]
    }

    static func prepare(_ raw: String) -> Prepared {
        var text = raw.lowercased()
        text = text.replacingOccurrences(of: "⟦ingredient_qty:⟧", with: "")
        text = fold(text)

        let quantity = try? NSRegularExpression(
            pattern: #"^\s*\d+(?:[.,]\d+)?(?:\s*\/\s*\d+(?:[.,]\d+)?)?"#,
            options: .caseInsensitive
        )
        if let quantity {
            let range = NSRange(text.startIndex..., in: text)
            text = quantity.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: " ")
        }

        let allowed = CharacterSet.letters.union(.whitespaces)
        text = String(text.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " })
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let stop: Set<String> = [
            "und", "or", "of", "de", "di", "du", "da", "del", "des", "la", "le", "el",
            "the", "a", "an", "der", "die", "das", "den", "dem", "ein", "eine", "einen",
            "einem", "einer", "mit", "fur", "von", "vom", "aus", "optional", "ca", "etwa",
            "approx", "about", "frisch", "frische", "frischer", "fresh", "bio", "organic",
            "grosse", "grosser", "kleine", "kleiner", "mini", "n", "g", "kg",
            "mg", "ml", "l", "el", "tl", "tbsp", "tsp", "cup", "cups", "stk", "stuck",
            "stueck", "packung", "paket", "prise", "bund", "zehe", "scheibe", "etwas"
        ]

        let tokens = text.split(separator: " ").map(String.init).filter { token in
            token.count > 1 && !stop.contains(token) && !units.contains(token)
        }

        let compact = tokens.joined()
        return Prepared(rawLower: raw.lowercased(), normalized: tokens.joined(separator: " "), compact: compact, tokens: tokens)
    }

    private static let units: Set<String> = [
        "g", "kg", "mg", "ml", "l", "dl", "cl", "el", "tl", "essloffel", "teeloffel",
        "tasse", "tassen", "becher", "stuck", "stueck", "prise", "prisen", "bund",
        "dose", "dosen", "glas", "glaser", "packung", "paket", "cup", "cups", "tbsp",
        "tsp", "oz", "lb", "piece", "pieces", "can", "cans", "jar", "bunch"
    ]

    // MARK: - Overrides

    private static func storageKey() -> String {
        if let userId = KeychainManager.get(key: "user_id"), !userId.isEmpty {
            return "\(overridesKey)_\(userId)"
        }
        return overridesKey
    }

    static func clearOverrides() {
        UserDefaults.standard.removeObject(forKey: storageKey())
        UserDefaults.standard.removeObject(forKey: overridesKey)
    }

    private static func loadOverrides() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: storageKey()) as? [String: String] ?? [:]
    }

    private static func override(for prepared: Prepared) -> ItemCategory? {
        let map = loadOverrides()
        if let raw = map[prepared.normalized], let category = ItemCategory(rawValue: raw) {
            return category
        }
        if let raw = map[prepared.compact], let category = ItemCategory(rawValue: raw) {
            return category
        }
        return nil
    }

    // MARK: - Frozen / form hints

    private static func frozenHint(_ rawLower: String) -> ItemCategory? {
        let frozenMarkers = ["tiefkuhl", "tiefkühl", " tk", "tk-", "tk ", "gefroren", "frozen", "congelado", "surgele", "surgelato"]
        let folded = rawLower.folding(options: .diacriticInsensitive, locale: Locale(identifier: "de_DE"))
        if frozenMarkers.contains(where: { folded.contains($0) || rawLower.contains($0) }) {
            return .frozen
        }
        if rawLower.hasPrefix("tk ") || folded.hasPrefix("tk ") {
            return .frozen
        }
        return nil
    }

    private static func formDrivenCategory(_ prepared: Prepared) -> ItemCategory? {
        let beverageTokens: Set<String> = ["saft", "juice", "nektar", "schorle", "smoothie", "limonade"]
        if prepared.tokens.contains(where: { token in
            beverageTokens.contains(token) || token.hasSuffix("saft") || token.hasSuffix("juice") || token.hasSuffix("schorle")
        }) {
            return .beverages
        }

        let cannedNeedles = ["konserve", "eingelegt", "passata", "tomatenmark", "tomato paste", "tomato puree"]
        let blob = prepared.normalized + " " + prepared.compact
        if cannedNeedles.contains(where: { blob.contains($0) }) {
            return .canned
        }

        let raw = " \(fold(prepared.rawLower)) "
        if raw.range(of: #"\b(dose|dosen|konserve|canned|cans?)\b"#, options: .regularExpression) != nil {
            return .canned
        }

        return nil
    }

    // MARK: - High-confidence phrases (longest first)

    private static func matchPhrases(in normalized: String, compact: String) -> ItemCategory? {
        let haystack = " \(normalized) \(compact) "
        for (phrase, category) in phraseRules {
            let foldedPhrase = fold(phrase)
            if haystack.contains(" \(foldedPhrase) ") {
                return category
            }
            let compactPhrase = foldedPhrase.replacingOccurrences(of: " ", with: "")
            if compactPhrase.count >= 6, compact.contains(compactPhrase) {
                return category
            }
        }
        return nil
    }

    /// Explicit compounds that substring matching historically got wrong.
    private static let phraseRules: [(String, ItemCategory)] = [
        ("milchreis", .grains),
        ("rice pudding", .grains),
        ("kokosmilch", .canned),
        ("coconut milk", .canned),
        ("lait de coco", .canned),
        ("latte di cocco", .canned),
        ("hafermilch", .dairy),
        ("sojamilch", .dairy),
        ("mandelmilch", .dairy),
        ("reismilch", .dairy),
        ("dinkelmilch", .dairy),
        ("cashewmilch", .dairy),
        ("oat milk", .dairy),
        ("soy milk", .dairy),
        ("almond milk", .dairy),
        ("rice milk", .dairy),
        ("eisbergsalat", .vegetables),
        ("iceberg", .vegetables),
        ("fruchtsalat", .fruits),
        ("obstsalat", .fruits),
        ("kartoffelchips", .snacks),
        ("potato chips", .snacks),
        ("pommes", .frozen),
        ("pommes frites", .frozen),
        ("french fries", .frozen),
        ("paprikapulver", .spices),
        ("chili flakes", .spices),
        ("chiliflocken", .spices),
        ("edelpaprika", .spices),
        ("edelsuss", .spices),
        ("edelsuss paprika", .spices),
        ("tomatenmark", .canned),
        ("tomatenpuree", .canned),
        ("tomatensauce", .canned),
        ("tomatensosse", .canned),
        ("apfelmus", .canned),
        ("apfelmark", .canned),
        ("erdnussbutter", .snacks),
        ("peanut butter", .snacks),
        ("haselnusscreme", .snacks),
        ("nutella", .snacks),
        ("vanilleeis", .frozen),
        ("schokoeis", .frozen),
        ("speiseeis", .frozen),
        ("ice cream", .frozen),
        ("eierlikor", .beverages),
        ("eiernudeln", .grains),
        ("eierspatzle", .grains),
        ("eierspatzle", .grains),
        ("bohnenkaffee", .beverages),
        ("kaffeebohnen", .beverages),
        ("espresso", .beverages),
        ("pfefferminztee", .beverages),
        ("krautermix", .spices),
        ("huhnchenbruehe", .spices),
        ("hahnchenbruehe", .spices),
        ("gemusebruehe", .spices),
        ("rinderbruehe", .spices),
        ("bruhwurfel", .spices),
        ("bouillon", .spices),
        ("backpulver", .bakery),
        ("natron", .bakery),
        ("vanillezucker", .spices),
        ("puderzucker", .snacks),
        ("paniermehl", .bakery),
        ("semmelbrose", .bakery),
        ("breadcrumbs", .bakery),
        ("preiselbeere", .fruits),
        ("preiselbeeren", .fruits),
        ("cranberry", .fruits),
        ("mayo", .spices),
        ("mayonnaise", .spices),
        ("senf", .spices),
        ("ketchup", .spices),
        ("sojasosse", .spices),
        ("sojasauce", .spices),
        ("soy sauce", .spices),
        ("worcester", .spices),
        ("olivenol", .spices),
        ("olive oil", .spices),
        ("sonnenblumenol", .spices),
        ("rapsöl", .spices),
        ("rapsol", .spices),
        ("sesamol", .spices),
        ("walnussol", .spices),
        ("kokosol", .spices),
        ("coconut oil", .spices),
        ("essig", .spices),
        ("balsamico", .spices),
        ("apfelessig", .spices),
        ("wein", .beverages),
        ("weisswein", .beverages),
        ("rotwein", .beverages),
        ("kochwein", .beverages),
        ("bier", .beverages),
        ("mineralwasser", .beverages),
        ("sprudel", .beverages),
        ("cola", .beverages),
        ("fanta", .beverages),
        ("sprite", .beverages),
        ("orangensaft", .beverages),
        ("apfelsaft", .beverages),
        ("multivitaminsaft", .beverages),
        ("traubensaft", .beverages),
        ("tomatensaft", .beverages),
        ("ananas saft", .beverages),
        ("orange juice", .beverages),
        ("apple juice", .beverages),
        ("sahneersatz", .dairy),
        ("kochsahne", .dairy),
        ("schlagsahne", .dairy),
        ("sauerrahm", .dairy),
        ("schmand", .dairy),
        ("creme fraiche", .dairy),
        ("frischkase", .dairy),
        ("streichkase", .dairy),
        ("hahnchenbrust", .meat),
        ("huhnchenbrust", .meat),
        ("putebrust", .meat),
        ("rinderhack", .meat),
        ("schweinehack", .meat),
        ("hackfleisch", .meat),
        ("ground beef", .meat),
        ("thunfisch dose", .canned),
        ("canned tuna", .canned),
        ("kichererbsen", .vegetables),
        ("kidneybohnen", .vegetables),
        ("weisse bohnen", .vegetables),
        ("lauchzwiebel", .vegetables),
        ("fruhlingszwiebel", .vegetables),
        ("zwiebelpulver", .spices),
        ("knoblauchpulver", .spices),
        ("knoblauchgranulat", .spices),
        ("ingwerpulver", .spices),
        ("zimt", .spices),
        ("vanilleextrakt", .spices),
        ("vanillepaste", .spices),
        ("backkakao", .snacks),
        ("kakao", .snacks),
        ("schokolade", .snacks),
        ("kuvertüre", .snacks),
        ("kuverture", .snacks),
        ("geriebene schokolade", .snacks),
        ("kokosraspeln", .snacks),
        ("kokosflocken", .snacks),
        ("rosinen", .fruits),
        ("sultanas", .fruits),
        ("datteln", .fruits),
        ("feigen getrocknet", .fruits),
        ("getrocknete aprikosen", .fruits)
    ].sorted { $0.0.count > $1.0.count }

    // MARK: - Keyword scoring

    private static func scoreKeywords(_ prepared: Prepared) -> ItemCategory {
        var best: (ItemCategory, Int)?

        func consider(_ category: ItemCategory, _ score: Int) {
            guard score > 0 else { return }
            if best == nil || score > best!.1 {
                best = (category, score)
            } else if score == best!.1, categoryPriority(category) < categoryPriority(best!.0) {
                best = (category, score)
            }
        }

        for (keyword, category) in lexicon {
            let key = fold(keyword)
            guard key.count >= 2 else { continue }

            if prepared.tokens.contains(key) {
                consider(category, 120 + key.count * 3)
                continue
            }

            if key.contains(" ") {
                if prepared.normalized.contains(key) {
                    consider(category, 110 + key.count * 3)
                }
                continue
            }

            if key.count <= 3 { continue }

            for token in prepared.tokens {
                guard let remainder = compoundRemainder(token: token, stem: key) else { continue }
                if remainder.isEmpty || ignoreAffixes.contains(remainder) || formSuffixes.contains(remainder) {
                    consider(category, scoreRemainder(remainder, stemLength: key.count))
                } else if let transformed = transformerCategory(remainder) {
                    consider(transformed, 130 + remainder.count * 2)
                }
            }

            if key.count >= 7, prepared.compact.contains(key) {
                consider(category, 55 + key.count)
            }
        }

        guard let best, best.1 >= 40 else { return .other }
        return best.0
    }

    /// Lower number wins ties — prefer more specific aisles over generic pantry hits.
    private static func categoryPriority(_ category: ItemCategory) -> Int {
        switch category {
        case .frozen: return 0
        case .beverages: return 1
        case .canned: return 2
        case .meat, .fish: return 3
        case .dairy: return 4
        case .bakery, .grains: return 5
        case .snacks: return 6
        case .spices: return 7
        case .vegetables, .fruits: return 8
        case .other: return 9
        }
    }

    private static func fold(_ value: String) -> String {
        var text = value.lowercased()
        text = text.replacingOccurrences(of: "ß", with: "ss")
        text = text.replacingOccurrences(of: "ä", with: "a")
        text = text.replacingOccurrences(of: "ö", with: "o")
        text = text.replacingOccurrences(of: "ü", with: "u")
        return text.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
    }

    private static func compoundRemainder(token: String, stem: String) -> String? {
        if token.hasPrefix(stem), token.count > stem.count {
            return stripLinking(String(token.dropFirst(stem.count)))
        }
        if token.hasSuffix(stem), token.count > stem.count {
            return stripLinking(String(token.dropLast(stem.count)))
        }
        return nil
    }

    private static func stripLinking(_ value: String) -> String {
        var remainder = value
        if remainder.hasPrefix("-") { remainder.removeFirst() }
        let linkers = ["en", "er", "es", "n", "s", "e"]
        for linker in linkers where remainder.hasPrefix(linker) && remainder.count > linker.count {
            let stripped = String(remainder.dropFirst(linker.count))
            if transformerCategory(stripped) != nil || formSuffixes.contains(stripped) || ignoreAffixes.contains(stripped) {
                return stripped
            }
        }
        return remainder
    }

    private static func scoreRemainder(_ remainder: String, stemLength: Int) -> Int {
        if remainder.isEmpty { return 120 + stemLength * 3 }
        if ignoreAffixes.contains(remainder) { return 110 + stemLength * 3 }
        if formSuffixes.contains(remainder) { return 100 + stemLength * 3 }
        if transformerCategory(remainder) != nil {
            return 0
        }
        if remainder.count <= 4 { return 70 + stemLength }
        return 0
    }

    private static func transformerCategory(_ remainder: String) -> ItemCategory? {
        switch remainder {
        case "saft", "saefte", "nektar", "schorle", "juice", "smoothie", "limo", "limonade", "tee", "tea", "wasser":
            return .beverages
        case "mark", "puree", "passata", "paste", "marmelade", "konfiture", "jam", "mus", "kompott":
            return .canned
        case "pulver", "gewurz", "granulat":
            return .spices
        case "chips", "sticks", "riegel", "butter":
            return .snacks
        case "ol", "oil":
            return .spices
        case "bruehe", "fond", "bouillon", "stock":
            return .spices
        case "wurst", "wurstchen", "salami":
            return .meat
        case "reis":
            return .grains
        default:
            return nil
        }
    }

    private static let ignoreAffixes: Set<String> = [
        "bio", "frisch", "frische", "tk", "light", "mini", "baby", "jung", "junge",
        "alt", "alte", "gross", "grosse", "klein", "kleine", "rot", "rote", "roter",
        "gelb", "gelbe", "grun", "grune", "weiss", "weisse", "schwarz", "getrocknet",
        "getrocknete", "gerieben", "gemahlen", "gehackt", "geschnitten"
    ]

    private static let formSuffixes: Set<String> = [
        "brust", "brustfilet", "filet", "filets", "keule", "keulen", "schlegel",
        "schnitzel", "steak", "steaks", "hack", "hackfleisch", "wurfel", "scheibe",
        "scheiben", "stucke", "ringe", "streifen", "schote", "schoten", "zehe", "zehen",
        "knolle", "bund", "kopf", "kopfe", "beere", "beeren", "kerne", "samen",
        "stuck", "stucke", "ecken", "spalten", "viertel", "halbe", "ganz", "ganze",
        "filetstreifen", "geschnetzeltes", "gulasch", "braten", "kotelett", "minze"
    ]

    // MARK: - Lexicon (stems only; short words are whole-token)

    private static let lexicon: [(String, ItemCategory)] = {
        var items: [(String, ItemCategory)] = []

        func add(_ words: [String], _ category: ItemCategory) {
            for word in words {
                let folded = fold(word)
                if folded.count >= 2 {
                    items.append((folded, category))
                }
            }
        }

        add([
            "fleisch", "hahnchen", "haehnchen", "huhnchen", "huehnchen", "huhn", "geflugel", "chicken", "pollo", "poulet",
            "rind", "rinder", "rindfleisch", "beef", "boeuf", "manzo",
            "schwein", "schweine", "pork", "cerdo", "porc", "maiale",
            "lamm", "lammfleisch", "lamb", "cordero", "agneau", "agnello",
            "pute", "puten", "truthahn", "turkey", "pavo", "dinde", "tacchino",
            "ente", "enten", "duck", "pato", "canard", "anatra",
            "wurst", "wurstchen", "bratwurst", "sausage", "salchicha", "saucisse", "salsiccia",
            "schinken", "ham", "jamon", "jambon", "prosciutto",
            "speck", "bacon", "tocino", "pancetta",
            "hackfleisch", "hack", "mince",
            "steak", "schnitzel", "kotelett", "chop", "chuleta",
            "salami", "mortadella", "chorizo", "leberwurst", "teewurst", "mettwurst",
            "fleischwurst", "jagdwurst", "bierschinken", "cervelat", "pepperoni",
            "rippchen", "spare ribs", "ribs", "burger", "frikadelle", "bulette",
            "geschnetzeltes", "gulasch", "braten", "roastbeef", "pastrami", "bresaola",
            "kalb", "kalbfleisch", "veal", "wild", "hirsch", "rehwild", "wildschwein",
            "kaninchen", "hase", "nuggets", "wings", "spareribs"
        ], .meat)

        add([
            "fisch", "fish", "pescado", "poisson", "pesce",
            "lachs", "salmon", "salmon", "saumon", "salmone",
            "thunfisch", "tuna", "atun", "thon", "tonno",
            "garnele", "garnelen", "shrimp", "prawn", "gamba", "camaron", "crevette", "gamberetto",
            "krabbe", "krabben", "crab", "cangrejo", "crabe", "granchio",
            "muschel", "muscheln", "mussel", "clam", "mejillon", "moule", "cozza", "vongola",
            "tintenfisch", "squid", "calamari", "calamar", "calamaro",
            "oktopus", "octopus", "pulpo", "poulpe", "polpo",
            "forelle", "trout", "trucha", "truite", "trota",
            "kabeljau", "cod", "bacalao", "cabillaud", "merluzzo",
            "hering", "herring", "arenque", "hareng", "aringa",
            "makrele", "mackerel", "caballa", "maquereau", "sgombro",
            "sardine", "sardinen", "sardina",
            "sardelle", "anchovy", "anchoa", "anchois", "acciuga",
            "seelachs", "pollock", "alaska seelachs",
            "dorade", "goldbrasse", "orata",
            "scholle", "zander", "hecht", "hummer", "lobster", "languste",
            "auster", "austern", "oyster", "jakobsmuschel", "scallop",
            "meeresfruchte", "seafood", "fischfilet", "pangasius", "tilapia",
            "rotbarsch", "kaviar", "lachsforelle", "wolfsbarsch", "seezunge"
        ], .fish)

        add([
            "tomate", "tomaten", "tomato", "pomodoro", "rispentomaten", "romatomaten", "cherry tomaten",
            "gurke", "gurken", "cucumber", "pepino", "concombre", "cetriolo", "snackgurke",
            "paprika", "gemusepaprika", "bell pepper", "pimiento", "poivron", "peperone",
            "zwiebel", "zwiebeln", "onion", "cebolla", "oignon", "cipolla", "rotschalotte", "schalotte",
            "knoblauch", "garlic", "aglio", "ajo",
            "karotte", "karotten", "mohre", "mohren", "carrot", "zanahoria", "carotte", "carota",
            "kartoffel", "kartoffeln", "potato", "patata", "pomme de terre", "festkochend",
            "salat", "lettuce", "lechuga", "laitue", "lattuga", "kopfsalat", "rucola", "arugula", "rocket",
            "kohl", "kohlrabi", "cabbage", "wirsing", "rotkohl", "weisskohl", "spitzkohl", "grunkohl",
            "brokkoli", "broccoli", "blumenkohl", "cauliflower", "romanesco",
            "zucchini", "courgette", "aubergine", "eggplant", "melanzana", "berenjena",
            "spinat", "spinach", "mangold", "pak choi", "pakchoi", "chinakohl",
            "lauch", "porree", "leek", "sellerie", "stangensellerie", "celery", "knollensellerie",
            "pilz", "pilze", "champignon", "champignons", "mushroom", "pfifferling", "krauterseitling", "shiitake",
            "erbse", "erbsen", "peas", "zuckerschote", "zuckerschoten",
            "bohne", "bohnen", "beans", "stangenbohne", "bohnensalat",
            "linse", "linsen", "lentils", "kichererbse", "kichererbsen", "falafel",
            "kurbis", "pumpkin", "butternut", "hokkaido",
            "mais", "corn", "zuckermais", "maiskolben",
            "spargel", "asparagus", "radieschen", "radish", "rettich",
            "ingwer", "ginger", "chili", "chilischote", "peperoni", "peperoncino", "jalapeno",
            "fenchel", "fennel", "rote bete", "rotebete", "beetroot", "rande",
            "rosenkohl", "brussels", "artischocke", "artichoke", "okra", "pastinake", "parsnip",
            "olive", "oliven", "olives",
            "susskartoffel", "batate", "yam",
            "rhabarber", "topinambur", "almglocken",
            "petersilienwurzel", "gelbe rube"
        ], .vegetables)

        add([
            "apfel", "apfel", "apple", "manzana", "pomme", "mela", "boskop", "elstar", "granny smith",
            "birne", "pear", "pera", "poire",
            "banane", "banana", "platano",
            "orange", "oranges", "naranja", "arancia", "blutorange",
            "zitrone", "lemon", "limon", "citron", "limone", "limette", "lime", "limetten",
            "erdbeere", "erdbeeren", "strawberry", "fraise", "fragola", "fresa",
            "himbeere", "himbeeren", "raspberry", "framboise", "lampone",
            "blaubeere", "heidelbeere", "blueberry", "mirtillo",
            "kirsche", "kirschen", "cherry", "ciliegia", "cerise",
            "pfirsich", "peach", "pesca", "peche",
            "aprikose", "aprikosen", "apricot", "marille",
            "pflaume", "pflaumen", "plum", "zwetschge",
            "traube", "trauben", "weintraube", "grape", "uva",
            "melone", "honigmelone", "wassermelone", "watermelon", "cantaloupe",
            "ananas", "pineapple", "mango", "kiwi", "papaya", "maracuja", "passionsfrucht",
            "mandarine", "clementine", "tangerine", "grapefruit", "pomelo",
            "brombeere", "johannisbeere", "stachelbeere", "holunderbeere",
            "dattel", "datteln", "feige", "feigen", "granatapfel", "litschi",
            "cranberry", "preiselbeere", "preiselbeeren", "rosine", "rosinen",
            "nashi", "kaki", "sharon", "physalis", "mirabelle",
            "avocado", "aguacate", "avocat"
        ], .fruits)

        add([
            "milch", "milk", "leche", "lait", "latte", "vollmilch", "fettarme milch", "magermilch",
            "kase", "cheese", "queso", "fromage", "formaggio",
            "butter", "butter", "mantequilla", "beurre", "burro",
            "sahne", "cream", "schlagsahne", "kochsahne", "sahneersatz",
            "joghurt", "yogurt", "yoghurt", "yaourt",
            "quark", "skyr", "kefir", "buttermilch",
            "ei", "eier", "egg", "eggs", "huevo", "oeuf", "uovo",
            "mascarpone", "ricotta", "feta", "mozzarella", "parmesan", "parmigiano",
            "gouda", "cheddar", "emmentaler", "camembert", "brie", "gorgonzola", "pecorino",
            "halloumi", "manchego", "blue cheese", "roquefort", "cottage", "hirtenkase",
            "frischkase", "streichkase", "schmelzkase", "raclette", "fondue",
            "schmand", "sauerrahm", "creme fraiche", "creme fraiche",
            "kondensmilch", "kaffeesahne"
        ], .dairy)

        add([
            "nudel", "nudeln", "pasta", "noodle", "noodles", "fideos", "pates",
            "reis", "rice", "arroz", "riz", "riso", "basmati", "jasminreis", "risotto", "risi",
            "spaghetti", "penne", "fusilli", "tagliatelle", "linguine", "farfalle", "macaroni",
            "lasagne", "lasagneplatten", "gnocchi", "spatzle", "spatzle", "spatzle",
            "couscous", "quinoa", "bulgur", "polenta", "grie", "griess", "gries",
            "hafer", "haferflocken", "oat", "oats", "avena", "porridge",
            "musli", "muesli", "cereal", "cornflakes", "vollkorn",
            "dinkel", "gerste", "hirse", "amaranth", "buchweizen", "wildreis",
            "weizen", "roggen", "maisgrie", "semola"
        ], .grains)

        add([
            "brot", "bread", "pan", "pain", "pane", "vollkornbrot", "toastbrot",
            "brotchen", "roll", "semmel", "laugensemmel", "bagel", "pretzel", "brezel",
            "toast", "baguette", "ciabatta", "focaccia", "croissant", "pain au chocolat",
            "mehl", "flour", "harina", "farine", "farina", "weizenmehl", "dinkelmehl", "roggenmehl",
            "hefe", "yeast", "levadura", "levure", "lievito",
            "backpulver", "baking powder", "natron", "baking soda",
            "teig", "blatterteig", "hefeteig", "murbeteig", "pizzateig",
            "tortilla", "wrap", "wraps", "pita", "naan", "fladenbrot"
        ], .bakery)

        add([
            "salz", "salt", "sel", "sale", "meersalz", "speisesalz",
            "pfeffer", "pepper", "poivre", "pepe", "pimienta", "schwarzer pfeffer",
            "curry", "kurkuma", "turmeric", "curcuma",
            "zimt", "cinnamon", "canela", "cannelle", "cannella",
            "oregano", "basilikum", "basil", "albahaca", "basilic", "basilico",
            "thymian", "thyme", "tomillo", "thym", "timo",
            "rosmarin", "rosemary", "romero", "romarin", "rosmarino",
            "petersilie", "parsley", "perejil", "persil", "prezzemolo",
            "koriander", "cilantro", "coriander", "coriandre", "coriandolo",
            "dill", "schnittlauch", "chive", "minze", "mint", "menta",
            "muskat", "nutmeg", "kardamom", "nelke", "nelken", "anise", "anis",
            "fenchelsamen", "kummel", "kreuzkummel", "cumin", "koriandersamen",
            "paprikapulver", "chili flakes", "cayenne", "garam masala", "harissa",
            "ol", "oil", "olive oil", "olivenol", "raps", "sonnenblumenol",
            "essig", "vinegar", "vinaigre", "aceto", "balsamico",
            "senf", "mustard", "ketchup", "mayonnaise", "sojasosse", "sojasauce",
            "sojasauce", "worcestersosse", "tabasco", "pesto", "tahini", "humus", "hummus",
            "hefeextrakt", "gemusebruehe", "bruhwurfel", "fond", "vanille", "vanillin"
        ], .spices)

        add([
            "wasser", "water", "agua", "eau", "acqua", "sprudel", "mineralwasser",
            "saft", "juice", "zumo", "jus", "succo",
            "tee", "tea", "te", "the", "kamillentee", "gruner tee", "schwarztee",
            "kaffee", "coffee", "cafe", "caffe", "espresso", "cappuccino",
            "cola", "limonade", "limo", "soda", "tonic", "bitter lemon",
            "wein", "wine", "vino", "vin", "prosecco", "sekt", "champagner",
            "bier", "beer", "cerveza", "biere", "birra",
            "smoothie", "shake", "milkshake", "kakao getrank",
            " bulion" 
        ], .beverages)

        add([
            "tiefkuhl", "frozen", "congelado", "surgele", "gelato", "eiscreme",
            "speiseeis", "ice cream", "helado", "glace",
            "pizza tk", "fish fingers", "fischstabchen", "kroketten", "spinach tk"
        ], .frozen)

        add([
            "konserve", "canned", "conserva", "passata", "tomatenmark",
            "eingelegt", "cornichon", "gewurzgurke", "sauerkraut", "kimchi",
            "oliven eingelegt", "capers", "kapern", "ajvar", "pesto rosso",
            "honig", "honey", "marmelade", "konfiture", "jam"
        ], .canned)

        add([
            "chips", "crisps", "nachos", "popcorn",
            "schokolade", "chocolate", "chocolat", "cioccolato", "praline",
            "keks", "kekse", "cookie", "cookies", "biscuit", "biscotto", "galleta",
            "zucker", "sugar", "azucar", "sucre", "zucchero", "brauner zucker",
            "nuss", "nusse", "nut", "nuts", "walnuss", "haselnuss", "cashew", "cashews",
            "mandel", "mandeln", "almond", "almendra", "amande", "mandorla",
            "erdnuss", "peanut", "arachide", "pistazie", "pistazien", "macadamia",
            "bonbon", "candy", "gummi", "gummibar", "lakritz", "riegel",
            "ahornsirup", "agavendicksaft", "sirup"
        ], .snacks)

        return items.sorted { $0.0.count > $1.0.count }
    }()
}

extension ItemCategory {
    static func categorizeMultilingual(ingredient: String) -> ItemCategory {
        IngredientCategorizer.categorize(ingredient)
    }
}
