import Foundation

// Extended multilingual categorization
extension ItemCategory {
    static func categorizeMultilingual(ingredient: String) -> ItemCategory {
        let lower = ingredient.lowercased()
        
        // Fleisch & Geflügel/Meat & Poultry - Multilingual
        let meat = ["fleisch", "hähnchen", "hühnchen", "chicken", "pollo", "poulet", "pollo",
                    "rind", "beef", "res", "boeuf", "manzo",
                    "schwein", "pork", "cerdo", "porc", "maiale",
                    "lamm", "lamb", "cordero", "agneau", "agnello",
                    "pute", "turkey", "pavo", "dinde", "tacchino",
                    "ente", "duck", "pato", "canard", "anatra",
                    "wurst", "sausage", "salchicha", "saucisse", "salsiccia",
                    "schinken", "ham", "jamón", "jambon", "prosciutto",
                    "speck", "bacon", "tocino", "bacon", "pancetta",
                    "hackfleisch", "ground beef", "minced meat", "carne picada", "viande hachée",
                    "steak", "schnitzel", "kotelett", "chop", "chuleta", "côtelette",
                    "bratwurst", "salami", "mortadella", "chorizo", "pancetta"]
        
        for item in meat {
            if lower.contains(item) { return .meat }
        }
        
        // Fisch & Meeresfrüchte/Fish & Seafood - Multilingual
        let fish = ["fisch", "fish", "pescado", "poisson", "pesce",
                    "lachs", "salmon", "salmón", "saumon", "salmone",
                    "thunfisch", "tuna", "atún", "thon", "tonno",
                    "garnele", "shrimp", "prawn", "gamba", "camarón", "crevette", "gamberetto",
                    "krabbe", "crab", "cangrejo", "crabe", "granchio",
                    "muschel", "mussel", "clam", "mejillón", "almeja", "moule", "cozza", "vongola",
                    "tintenfisch", "squid", "calamari", "calamar", "calamar", "calamaro",
                    "oktopus", "octopus", "pulpo", "poulpe", "polpo",
                    "forelle", "trout", "trucha", "truite", "trota",
                    "kabeljau", "cod", "bacalao", "cabillaud", "merluzzo",
                    "hering", "herring", "arenque", "hareng", "aringa",
                    "makrele", "mackerel", "caballa", "maquereau", "sgombro",
                    "sardine", "sardine", "sardina", "sardine", "sardina",
                    "sardelle", "anchovy", "anchoa", "anchois", "acciuga",
                    "seelachs", "pollock", "abadejo", "lieu", "merluzzo",
                    "dorade", "sea bream", "dorada", "daurade", "orata",
                    "scholle", "plaice", "platija", "plie", "passera",
                    "zander", "pike-perch", "lucioperca", "sandre", "lucioperca",
                    "hummer", "lobster", "langosta", "homard", "aragosta",
                    "languste", "crayfish", "cigala", "langouste", "scampo",
                    "austern", "oyster", "ostra", "huître", "ostrica",
                    "jakobsmuschel", "scallop", "vieira", "coquille", "capasanta"]
        
        for item in fish {
            if lower.contains(item) { return .fish }
        }
        
        // Gemüse/Vegetables - Multilingual
        let vegetables = ["tomate", "tomato", "tomate", "tomate", "pomodoro",
                          "gurke", "cucumber", "pepino", "concombre", "cetriolo",
                          "paprika", "bell pepper", "pepper", "pimiento", "poivron", "peperone",
                          "zwiebel", "onion", "cebolla", "oignon", "cipolla",
                          "knoblauch", "garlic", "ajo", "ail", "aglio",
                          "karotte", "möhre", "carrot", "zanahoria", "carotte", "carota",
                          "kartoffel", "potato", "patata", "pomme de terre", "patata",
                          "salat", "lettuce", "lechuga", "laitue", "lattuga",
                          "kohl", "cabbage", "col", "chou", "cavolo",
                          "brokkoli", "broccoli", "brócoli", "brocoli", "broccoli",
                          "blumenkohl", "cauliflower", "coliflor", "chou-fleur", "cavolfiore",
                          "zucchini", "zucchini", "calabacín", "courgette", "zucchina",
                          "aubergine", "eggplant", "berenjena", "aubergine", "melanzana",
                          "spinat", "spinach", "espinaca", "épinard", "spinaci",
                          "lauch", "porree", "leek", "puerro", "poireau", "porro",
                          "sellerie", "celery", "apio", "céleri", "sedano",
                          "pilz", "champignon", "mushroom", "champiñón", "champignon", "fungo",
                          "erbsen", "peas", "guisantes", "petits pois", "piselli",
                          "bohne", "beans", "judías", "haricots", "fagioli",
                          "linsen", "lentils", "lentejas", "lentilles", "lenticchie",
                          "kürbis", "pumpkin", "calabaza", "citrouille", "zucca",
                          "mais", "corn", "maíz", "maïs", "mais",
                          "spargel", "asparagus", "espárrago", "asperge", "asparagi",
                          "radieschen", "radish", "rábano", "radis", "ravanello",
                          "rucola", "arugula", "rocket", "rúcula", "roquette", "rucola",
                          "ingwer", "ginger", "jengibre", "gingembre", "zenzero",
                          "chili", "chili", "chile", "piment", "peperoncino",
                          "peperoni", "pepperoni", "peperoncino",
                          "fenchel", "fennel", "hinojo", "fenouil", "finocchio",
                          "rote bete", "beetroot", "remolacha", "betterave", "barbabietola",
                          "rotkohl", "red cabbage", "col roja", "chou rouge", "cavolo rosso",
                          "weißkohl", "white cabbage", "col blanca", "chou blanc", "cavolo bianco",
                          "wirsing", "savoy cabbage", "col rizada", "chou frisé", "verza",
                          "rosenkohl", "brussels sprouts", "coles de bruselas", "choux de bruxelles", "cavoletti",
                          "artischocke", "artichoke", "alcachofa", "artichaut", "carciofo",
                          "pastinake", "parsnip", "chirivía", "panais", "pastinaca"]
        
        for item in vegetables {
            if lower.contains(item) { return .vegetables }
        }
        
        // Obst/Fruits - Erweitert (DE, EN, ES, FR, IT)
        let fruits = ["apfel", "äpfel", "apple", "manzana", "pomme", "mela",
                      "birne", "pear", "pera", "poire", "pera",
                      "banane", "banana", "plátano", "banane", "banana",
                      "orange", "orange", "naranja", "orange", "arancia",
                      "zitrone", "lemon", "limón", "citron", "limone",
                      "erdbeere", "strawberry", "fresa", "fraise", "fragola",
                      "himbeere", "raspberry", "frambuesa", "framboise", "lampone",
                      "blaubeere", "heidelbeere", "blueberry", "arándano", "myrtille", "mirtillo",
                      "kirsche", "cherry", "cereza", "cerise", "ciliegia",
                      "pfirsich", "peach", "melocotón", "pêche", "pesca",
                      "traube", "grape", "uva", "raisin", "uva",
                      "melone", "melon", "melón", "melon", "melone",
                      "ananas", "pineapple", "piña", "ananas", "ananas",
                      "mango", "mango", "mango", "mangue", "mango",
                      "kiwi", "kiwi", "kiwi", "kiwi", "kiwi",
                      "avocado", "avocado", "aguacate", "avocat", "avocado",
                      "mandarine", "tangerine", "mandarina", "mandarine", "mandarino",
                      "grapefruit", "grapefruit", "pomelo", "pamplemousse", "pompelmo",
                      "brombeere", "blackberry", "mora", "mûre", "mora",
                      "johannisbeere", "currant", "grosella", "groseille", "ribes",
                      "cranberry", "cranberry", "arándano rojo", "canneberge", "mirtillo rosso"]
        
        for fruit in fruits {
            if lower.contains(fruit) { return .fruits }
        }
        
        // Milchprodukte/Dairy - Erweitert
        let dairy = ["milch", "milk", "leche", "lait", "latte",
                     "käse", "cheese", "queso", "fromage", "formaggio",
                     "butter", "butter", "mantequilla", "beurre", "burro",
                     "sahne", "cream", "nata", "crème", "panna",
                     "joghurt", "yogurt", "yogur", "yaourt", "yogurt",
                     "quark", "curd", "requesón", "fromage blanc", "quark",
                     "ei", "eier", "egg", "huevo", "oeuf", "uovo",
                     "mascarpone", "ricotta", "feta", "mozzarella", "parmesan",
                     "gouda", "cheddar", "emmentaler", "camembert", "brie"]
        
        for item in dairy {
            if lower.contains(item) { return .dairy }
        }
        
        // Getreide & Nudeln/Grains & Pasta - Erweitert
        let grains = ["nudel", "pasta", "noodle", "fideos", "pâtes", "pasta",
                      "reis", "rice", "arroz", "riz", "riso",
                      "spaghetti", "penne", "fusilli", "tagliatelle", "linguine",
                      "couscous", "quinoa", "bulgur", "hafer", "oat", "avena", "avoine",
                      "müsli", "cereal", "cornflakes", "risotto",
                      "vollkorn", "whole grain", "integral", "complet", "integrale"]
        
        for item in grains {
            if lower.contains(item) { return .grains }
        }
        
        // Brot & Backwaren/Bakery - Erweitert
        let bakery = ["brot", "bread", "pan", "pain", "pane",
                      "brötchen", "roll", "panecillo", "petit pain", "panino",
                      "toast", "baguette", "croissant", "bagel", "pretzel",
                      "mehl", "flour", "harina", "farine", "farina",
                      "hefe", "yeast", "levadura", "levure", "lievito",
                      "backpulver", "baking powder", "levadura en polvo", "levure", "lievito"]
        
        for item in bakery {
            if lower.contains(item) { return .bakery }
        }
        
        // Gewürze & Kräuter/Spices & Herbs - Erweitert
        let spices = ["salz", "salt", "sal", "sel", "sale",
                      "pfeffer", "pepper", "pimienta", "poivre", "pepe",
                      "curry", "kurkuma", "turmeric", "cúrcuma", "curcuma",
                      "zimt", "cinnamon", "canela", "cannelle", "cannella",
                      "oregano", "basilikum", "basil", "albahaca", "basilic", "basilico",
                      "thymian", "thyme", "tomillo", "thym", "timo",
                      "rosmarin", "rosemary", "romero", "romarin", "rosmarino",
                      "petersilie", "parsley", "perejil", "persil", "prezzemolo",
                      "koriander", "cilantro", "coriander", "cilantro", "coriandre", "coriandolo",
                      "dill", "dill", "eneldo", "aneth", "aneto",
                      "schnittlauch", "chive", "cebollino", "ciboulette", "erba cipollina",
                      "minze", "mint", "menta", "menthe", "menta",
                      "muskat", "nutmeg", "nuez moscada", "muscade", "noce moscata",
                      "öl", "oil", "aceite", "huile", "olio",
                      "olivenöl", "olive oil", "aceite de oliva", "huile d'olive", "olio d'oliva",
                      "essig", "vinegar", "vinagre", "vinaigre", "aceto",
                      "senf", "mustard", "mostaza", "moutarde", "senape",
                      "ketchup", "mayonnaise", "mayo", "sojasoße", "soy sauce", "salsa de soja"]
        
        for item in spices {
            if lower.contains(item) { return .spices }
        }
        
        // Getränke/Beverages - Erweitert
        let beverages = ["wasser", "water", "agua", "eau", "acqua",
                         "saft", "juice", "zumo", "jus", "succo",
                         "tee", "tea", "té", "thé", "tè",
                         "kaffee", "coffee", "café", "café", "caffè",
                         "cola", "limo", "soda", "refresco", "soda",
                         "wein", "wine", "vino", "vin", "vino",
                         "bier", "beer", "cerveza", "bière", "birra",
                         "smoothie", "shake", "milkshake"]
        
        for item in beverages {
            if lower.contains(item) { return .beverages }
        }
        
        // Tiefkühl/Frozen - Erweitert
        let frozen = ["tiefkühl", "tk", "frozen", "congelado", "surgelé", "surgelato",
                      "gefroren", "eis", "ice cream", "helado", "glace", "gelato"]
        
        for item in frozen {
            if lower.contains(item) { return .frozen }
        }
        
        // Konserven/Canned - Erweitert
        let canned = ["dose", "can", "lata", "boîte", "scatola",
                      "konserve", "canned", "conserva", "conserve", "conserva",
                      "glas", "jar", "tarro", "bocal", "barattolo",
                      "passata", "püree", "purée", "puré", "salsa"]
        
        for item in canned {
            if lower.contains(item) { return .canned }
        }
        
        // Snacks - Erweitert
        let snacks = ["chips", "crisps", "patatas fritas", "chips",
                      "schokolade", "chocolate", "chocolate", "chocolat", "cioccolato",
                      "keks", "cookie", "galleta", "biscuit", "biscotto",
                      "zucker", "sugar", "azúcar", "sucre", "zucchero",
                      "nuss", "nut", "nuez", "noix", "noce",
                      "mandel", "almond", "almendra", "amande", "mandorla",
                      "erdnuss", "peanut", "cacahuete", "cacahuète", "arachide",
                      "popcorn", "bonbon", "candy", "caramelo", "bonbon", "caramella"]
        
        for item in snacks {
            if lower.contains(item) { return .snacks }
        }
        
        return .other
    }
}
