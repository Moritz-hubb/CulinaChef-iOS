import Foundation

// MARK: - Shopping List Models

struct ShoppingListItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let quantity: String?
    let category: ItemCategory
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
    
    static func categorize(ingredient: String) -> ItemCategory {
        let lower = ingredient.lowercased()
        
        // Try multilingual extended categorization first
        let extended = ItemCategory.categorizeMultilingual(ingredient: ingredient)
        if extended != ItemCategory.other {
            return extended
        }
        
        // Fleisch & Geflügel (DE, EN, ES, FR, IT)
        if lower.contains("fleisch") || lower.contains("hähnchen") || lower.contains("hühnchen") || 
           lower.contains("rind") || lower.contains("schwein") || lower.contains("lamm") ||
           lower.contains("pute") || lower.contains("ente") || lower.contains("wurst") ||
           lower.contains("schinken") || lower.contains("speck") || lower.contains("hackfleisch") ||
           lower.contains("steak") || lower.contains("schnitzel") || lower.contains("kotelett") ||
           lower.contains("bratwurst") || lower.contains("salami") || lower.contains("mortadella") ||
           lower.contains("prosciutto") || lower.contains("chorizo") || lower.contains("bacon") ||
           // English
           lower.contains("meat") || lower.contains("chicken") || lower.contains("beef") ||
           lower.contains("pork") || lower.contains("lamb") || lower.contains("turkey") ||
           lower.contains("duck") || lower.contains("sausage") || lower.contains("ham") ||
           lower.contains("ground beef") || lower.contains("minced meat") ||
           // Spanish
           lower.contains("carne") || lower.contains("pollo") || lower.contains("res") ||
           lower.contains("cerdo") || lower.contains("cordero") || lower.contains("pavo") ||
           lower.contains("pato") || lower.contains("jamón") || lower.contains("tocino") ||
           // French
           lower.contains("viande") || lower.contains("poulet") || lower.contains("boeuf") ||
           lower.contains("porc") || lower.contains("agneau") || lower.contains("dinde") ||
           lower.contains("canard") || lower.contains("jambon") || lower.contains("saucisse") ||
           // Italian
           lower.contains("carne") || lower.contains("pollo") || lower.contains("manzo") ||
           lower.contains("maiale") || lower.contains("agnello") || lower.contains("tacchino") ||
           lower.contains("anatra") || lower.contains("salsiccia") {
            return .meat
        }
        
        // Fisch & Meeresfrüchte (DE, EN, ES, FR, IT)
        if lower.contains("fisch") || lower.contains("lachs") || lower.contains("thunfisch") ||
           lower.contains("garnele") || lower.contains("krabbe") || lower.contains("muschel") ||
           lower.contains("tintenfisch") || lower.contains("shrimp") || lower.contains("forelle") ||
           lower.contains("kabeljau") || lower.contains("hering") || lower.contains("makrele") ||
           lower.contains("sardine") || lower.contains("sardelle") || lower.contains("seelachs") ||
           lower.contains("dorade") || lower.contains("scholle") || lower.contains("zander") ||
           lower.contains("hummer") || lower.contains("languste") || lower.contains("austern") ||
           lower.contains("jakobsmuschel") || lower.contains("calamari") || lower.contains("oktopus") ||
           // English
           lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("shrimp") || lower.contains("prawn") || lower.contains("crab") ||
           lower.contains("mussel") || lower.contains("clam") || lower.contains("oyster") ||
           lower.contains("lobster") || lower.contains("squid") || lower.contains("octopus") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") ||
           lower.contains("mackerel") || lower.contains("sardine") || lower.contains("anchovy") ||
           lower.contains("sea bass") || lower.contains("scallop") ||
           // Spanish
           lower.contains("pescado") || lower.contains("salmón") || lower.contains("atún") ||
           lower.contains("camarón") || lower.contains("gamba") || lower.contains("cangrejo") ||
           lower.contains("mejillón") || lower.contains("almeja") || lower.contains("langosta") ||
           lower.contains("calamar") || lower.contains("pulpo") || lower.contains("merluza") ||
           // French
           lower.contains("poisson") || lower.contains("saumon") || lower.contains("thon") ||
           lower.contains("crevette") || lower.contains("crabe") || lower.contains("moule") ||
           lower.contains("homard") || lower.contains("calamar") || lower.contains("poulpe") ||
           lower.contains("cabillaud") || lower.contains("truite") || lower.contains("maquereau") ||
           // Italian
           lower.contains("pesce") || lower.contains("salmone") || lower.contains("tonno") ||
           lower.contains("gamberetto") || lower.contains("gambero") || lower.contains("granchio") ||
           lower.contains("cozza") || lower.contains("vongola") || lower.contains("aragosta") ||
           lower.contains("calamaro") || lower.contains("polpo") || lower.contains("merluzzo") {
            return .fish
        }
        
        // Gemüse (DE, EN, ES, FR, IT)
        if lower.contains("tomate") || lower.contains("gurke") || lower.contains("paprika") ||
           lower.contains("zwiebel") || lower.contains("knoblauch") || lower.contains("karotte") ||
           lower.contains("möhre") || lower.contains("kartoffel") || lower.contains("salat") ||
           lower.contains("kohl") || lower.contains("brokkoli") || lower.contains("blumenkohl") ||
           lower.contains("zucchini") || lower.contains("aubergine") || lower.contains("spinat") ||
           lower.contains("lauch") || lower.contains("sellerie") || lower.contains("pilz") ||
           lower.contains("champignon") || lower.contains("erbsen") || lower.contains("bohne") ||
           lower.contains("linsen") || lower.contains("kürbis") || lower.contains("mais") ||
           lower.contains("spargel") || lower.contains("radieschen") || lower.contains("rucola") ||
           lower.contains("ingwer") || lower.contains("chili") || lower.contains("peperoni") ||
           lower.contains("porree") || lower.contains("fenchel") || lower.contains("rote bete") ||
           lower.contains("rotkohl") || lower.contains("weißkohl") || lower.contains("wirsing") ||
           lower.contains("pak choi") || lower.contains("chinakohl") || lower.contains("rosenkohl") ||
           lower.contains("artischocke") || lower.contains("okra") || lower.contains("pastinake") ||
           // English
           lower.contains("tomato") || lower.contains("cucumber") || lower.contains("pepper") ||
           lower.contains("bell pepper") || lower.contains("onion") || lower.contains("garlic") ||
           lower.contains("carrot") || lower.contains("potato") || lower.contains("lettuce") ||
           lower.contains("cabbage") || lower.contains("broccoli") || lower.contains("cauliflower") ||
           lower.contains("zucchini") || lower.contains("eggplant") || lower.contains("aubergine") ||
           lower.contains("spinach") || lower.contains("leek") || lower.contains("celery") ||
           lower.contains("mushroom") || lower.contains("peas") || lower.contains("beans") ||
           lower.contains("lentils") || lower.contains("pumpkin") || lower.contains("corn") ||
           lower.contains("asparagus") || lower.contains("radish") || lower.contains("arugula") ||
           lower.contains("rocket") || lower.contains("ginger") || lower.contains("kale") ||
           lower.contains("brussels sprouts") || lower.contains("artichoke") || lower.contains("beetroot") ||
           // Spanish
           lower.contains("tomate") || lower.contains("pepino") || lower.contains("pimiento") ||
           lower.contains("cebolla") || lower.contains("ajo") || lower.contains("zanahoria") ||
           lower.contains("patata") || lower.contains("lechuga") || lower.contains("col") ||
           lower.contains("brócoli") || lower.contains("coliflor") || lower.contains("calabacín") ||
           lower.contains("berenjena") || lower.contains("espinaca") || lower.contains("puerro") ||
           lower.contains("apio") || lower.contains("champiñón") || lower.contains("guisantes") ||
           lower.contains("judías") || lower.contains("lentejas") || lower.contains("calabaza") ||
           lower.contains("maíz") || lower.contains("espárrago") || lower.contains("rábano") ||
           lower.contains("rúcula") || lower.contains("jengibre") ||
           // French
           lower.contains("tomate") || lower.contains("concombre") || lower.contains("poivron") ||
           lower.contains("oignon") || lower.contains("ail") || lower.contains("carotte") ||
           lower.contains("pomme de terre") || lower.contains("laitue") || lower.contains("chou") ||
           lower.contains("brocoli") || lower.contains("chou-fleur") || lower.contains("courgette") ||
           lower.contains("aubergine") || lower.contains("épinard") || lower.contains("poireau") ||
           lower.contains("céleri") || lower.contains("champignon") || lower.contains("petits pois") ||
           lower.contains("haricots") || lower.contains("lentilles") || lower.contains("citrouille") ||
           lower.contains("maïs") || lower.contains("asperge") || lower.contains("radis") ||
           lower.contains("roquette") || lower.contains("gingembre") ||
           // Italian
           lower.contains("pomodoro") || lower.contains("cetriolo") || lower.contains("peperone") ||
           lower.contains("cipolla") || lower.contains("aglio") || lower.contains("carota") ||
           lower.contains("patata") || lower.contains("lattuga") || lower.contains("cavolo") ||
           lower.contains("broccoli") || lower.contains("cavolfiore") || lower.contains("zucchina") ||
           lower.contains("melanzana") || lower.contains("spinaci") || lower.contains("porro") ||
           lower.contains("sedano") || lower.contains("fungo") || lower.contains("piselli") ||
           lower.contains("fagioli") || lower.contains("lenticchie") || lower.contains("zucca") ||
           lower.contains("mais") || lower.contains("asparagi") || lower.contains("ravanello") ||
           lower.contains("rucola") || lower.contains("zenzero") {
            return .vegetables
        }
        
        // Obst
        if lower.contains("apfel") || lower.contains("äpfel") || lower.contains("birne") || lower.contains("banane") ||
           lower.contains("orange") || lower.contains("zitrone") || lower.contains("limette") ||
           lower.contains("beere") || lower.contains("erdbeere") || lower.contains("himbeere") ||
           lower.contains("blaubeere") || lower.contains("heidelbeere") || lower.contains("kirsche") || 
           lower.contains("pfirsich") || lower.contains("aprikose") || lower.contains("pflaume") || 
           lower.contains("traube") || lower.contains("weintraube") || lower.contains("melone") || 
           lower.contains("wassermelone") || lower.contains("ananas") || lower.contains("mango") ||
           lower.contains("kiwi") || lower.contains("avocado") || lower.contains("grapefruit") ||
           lower.contains("mandarine") || lower.contains("clementine") || lower.contains("nektarine") ||
           lower.contains("papaya") || lower.contains("maracuja") || lower.contains("passionsfrucht") ||
           lower.contains("litschi") || lower.contains("feige") || lower.contains("granatapfel") ||
           lower.contains("brombeere") || lower.contains("johannisbeere") || lower.contains("stachelbeere") ||
           lower.contains("holunderbeere") || lower.contains("dattel") || lower.contains("rosine") ||
           lower.contains("cranberry") || lower.contains("preiselbeere") {
            return .fruits
        }
        
        // Milchprodukte
        if lower.contains("milch") || lower.contains("käse") || lower.contains("butter") ||
           lower.contains("sahne") || lower.contains("joghurt") || lower.contains("quark") ||
           lower.contains("ei") || lower.contains("eier") || lower.contains("mascarpone") ||
           lower.contains("mozzarella") || lower.contains("parmesan") || lower.contains("creme") ||
           lower.contains("frischkäse") || lower.contains("gouda") {
            return .dairy
        }
        
        // Brot & Backwaren
        if lower.contains("brot") || lower.contains("brötchen") || lower.contains("toast") ||
           lower.contains("mehl") || lower.contains("teig") || lower.contains("hefe") ||
           lower.contains("backpulver") || lower.contains("croissant") || lower.contains("bagel") {
            return .bakery
        }
        
        // Getreide & Nudeln
        if lower.contains("nudel") || lower.contains("pasta") || lower.contains("reis") ||
           lower.contains("spaghetti") || lower.contains("penne") || lower.contains("couscous") ||
           lower.contains("quinoa") || lower.contains("bulgur") || lower.contains("hafer") ||
           lower.contains("müsli") || lower.contains("cornflakes") || lower.contains("risotto") {
            return .grains
        }
        
        // Konserven & Gläser
        if lower.contains("dose") || lower.contains("konserve") || lower.contains("tomatenpüree") ||
           lower.contains("passata") || lower.contains("tomatensauce") || lower.contains("glas") ||
           lower.contains("marmelade") || lower.contains("honig") {
            return .canned
        }
        
        // Gewürze & Kräuter
        if lower.contains("salz") || lower.contains("pfeffer") || lower.contains("gewürz") ||
           lower.contains("paprika") && lower.contains("edel") || lower.contains("curry") ||
           lower.contains("muskat") || lower.contains("zimt") || lower.contains("kreuzkümmel") ||
           lower.contains("oregano") || lower.contains("basilikum") || lower.contains("thymian") ||
           lower.contains("rosmarin") || lower.contains("petersilie") || lower.contains("koriander") ||
           lower.contains("dill") || lower.contains("schnittlauch") || lower.contains("minze") ||
           lower.contains("essig") || lower.contains("öl") || lower.contains("olivenöl") ||
           lower.contains("senf") || lower.contains("ketchup") || lower.contains("mayonnaise") ||
           lower.contains("sojasoße") || lower.contains("sojasauce") {
            return .spices
        }
        
        // Getränke
        if lower.contains("wasser") || lower.contains("saft") || lower.contains("tee") ||
           lower.contains("kaffee") || lower.contains("cola") || lower.contains("limonade") ||
           lower.contains("wein") || lower.contains("bier") {
            return .beverages
        }
        
        // Tiefkühlprodukte
        if lower.contains("tiefkühl") || lower.contains("tk") || lower.contains("gefroren") ||
           lower.contains("eis") && (lower.contains("vanille") || lower.contains("schokolade")) {
            return .frozen
        }
        
        // Snacks & Süßigkeiten
        if lower.contains("chips") || lower.contains("schokolade") || lower.contains("keks") ||
           lower.contains("zucker") || lower.contains("süßigkeit") || lower.contains("bonbon") ||
           lower.contains("nuss") || lower.contains("mandel") || lower.contains("erdnuss") {
            return .snacks
        }
        
        return .other
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
