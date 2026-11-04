import XCTest
@testable import CulinaChef

final class StepIngredientExtractorTests: XCTestCase {
    private let marker = "⟦ingredient_qty:⟧"

    private func names(in instruction: String, ingredients: [String], servings: Int = 4) -> [String] {
        StepIngredientExtractor.ingredients(
            in: instruction,
            recipeIngredients: ingredients,
            servings: servings
        ).map(\.name)
    }

    private func items(in instruction: String, ingredients: [String], servings: Int = 4) -> [StepIngredientDisplay] {
        StepIngredientExtractor.ingredients(
            in: instruction,
            recipeIngredients: ingredients,
            servings: servings
        )
    }

    func testParseKeepsIngredientInitialsThatLookLikeUnits() {
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("200 g Mehl"), "Mehl")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("2 EL Olivenöl"), "Olivenöl")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("1 Gurke"), "Gurke")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("2 große Zwiebeln"), "Zwiebeln")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("1 Glas Milch"), "Milch")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("1 Liter Milch"), "Milch")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("2 Limetten"), "Limetten")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("1 Lauch"), "Lauch")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("500 g Lachs"), "Lachs")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("2 Lammkoteletts"), "Lammkoteletts")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("1 Bund Petersilie"), "Petersilie")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("1 Dose Tomaten"), "Tomaten")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("3 Knoblauchzehen"), "Knoblauch")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("4 Eier"), "Eier")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("1 TL Salz"), "Salz")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("Mehl (Type 405)"), "Mehl")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("Tomaten, gehackt"), "Tomaten")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("200gMehl"), "Mehl")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientName("Saft von 1 Zitrone"), "Saft von Zitrone")
    }

    func testParseQuantityDoesNotSwallowTheIngredient() {
        XCTAssertEqual(StepIngredientExtractor.parseIngredientQuantity("1 Gurke"), "1")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientQuantity("2 große Zwiebeln"), "2")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientQuantity("1 Glas Milch"), "1 Glas")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientQuantity("200 g Mehl"), "200 g")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientQuantity("1 kleine Dose Tomaten"), "1 Dose")
        XCTAssertEqual(StepIngredientExtractor.parseIngredientQuantity("1 gestrichener TL Salz"), "1 TL")
    }

    func testMarkedFlourStillShows() {
        let found = items(
            in: "Füge 200 g\(marker) Mehl hinzu und verknete den Teig.",
            ingredients: ["200 g Mehl", "1 TL Salz"]
        )
        XCTAssertEqual(found.map(\.name), ["Mehl"])
        XCTAssertEqual(found.first?.quantity, "200 g")
    }

    func testCountableEggsWithoutARealUnitStillShow() {
        let catalog = ["4 Eier", "200 g Mehl"]
        XCTAssertEqual(
            names(in: "2\(marker) Eier verquirlen.", ingredients: catalog),
            ["Eier"]
        )
        XCTAssertEqual(
            names(in: "2 Eier\(marker) verquirlen.", ingredients: catalog),
            ["Eier"]
        )
        XCTAssertEqual(
            names(in: "2 Stück\(marker) Eier aufschlagen.", ingredients: catalog),
            ["Eier"]
        )
    }

    func testArticleBetweenMarkerAndNameIsSkipped() {
        let found = items(
            in: "200 g\(marker) der Sahne hinzufügen.",
            ingredients: ["200 g Sahne"]
        )
        XCTAssertEqual(found.map(\.name), ["Sahne"])
        XCTAssertEqual(found.first?.quantity, "200 g")
    }

    func testUnmarkedIngredientsMatchDespiteAdjectivesAndUnits() {
        let catalog = [
            "2 große Zwiebeln",
            "1 Gurke",
            "1 Glas Milch",
            "2 Limetten",
            "1 Bund Petersilie",
            "1 Dose Tomaten",
            "3 Knoblauchzehen"
        ]
        XCTAssertEqual(names(in: "Die Zwiebeln würfeln.", ingredients: catalog), ["Zwiebeln"])
        XCTAssertEqual(names(in: "Die Gurke in Scheiben schneiden.", ingredients: catalog), ["Gurke"])
        XCTAssertEqual(names(in: "Die Milch dazugeben.", ingredients: catalog), ["Milch"])
        XCTAssertEqual(names(in: "Die Limetten auspressen.", ingredients: catalog), ["Limetten"])
        XCTAssertEqual(names(in: "Petersilie hacken.", ingredients: catalog), ["Petersilie"])
        XCTAssertEqual(names(in: "Tomaten einrühren.", ingredients: catalog), ["Tomaten"])
        XCTAssertEqual(names(in: "Knoblauch fein hacken.", ingredients: catalog), ["Knoblauch"])
    }

    func testSingularAndPluralMatch() {
        XCTAssertEqual(
            names(in: "Die Zwiebel würfeln.", ingredients: ["2 Zwiebeln"]),
            ["Zwiebeln"]
        )
        XCTAssertEqual(
            names(in: "Die Tomate schneiden.", ingredients: ["4 Tomaten"]),
            ["Tomaten"]
        )
        XCTAssertEqual(
            names(in: "Das Ei verquirlen.", ingredients: ["4 Eier"]),
            ["Eier"]
        )
    }

    func testWorktopDoesNotHideIngredients() {
        XCTAssertEqual(
            names(
                in: "Die Zwiebeln auf der Arbeitsplatte würfeln.",
                ingredients: ["2 große Zwiebeln", "1 TL Salz"]
            ),
            ["Zwiebeln"]
        )
    }

    func testGarnishStillShowsAndFinishedComponentsDoNot() {
        XCTAssertEqual(
            names(
                in: "Mit Petersilie bestreuen und servieren.",
                ingredients: ["1 Bund Petersilie", "2 EL Öl"]
            ),
            ["Petersilie"]
        )
        let plated = names(
            in: "8\(marker) Kartoffelpuffer mit 200 g\(marker) Dip anrichten und sofort servieren.",
            ingredients: ["500 g Kartoffeln", "1 Bund Petersilie"]
        )
        XCTAssertFalse(plated.contains("Kartoffelpuffer"))
        XCTAssertFalse(plated.contains("Dip"))
        XCTAssertTrue(plated.isEmpty)
    }

    func testSimilarWordsDoNotStealIngredients() {
        let catalog = ["200 g Reis", "4 Eier", "2 Tomaten", "1 EL Tomatenmark"]
        XCTAssertTrue(names(in: "Beim Preis nicht sparen und nichts aufreißen.", ingredients: catalog).isEmpty)
        XCTAssertEqual(names(in: "Den Teig kneten.", ingredients: catalog), [])
        XCTAssertEqual(
            names(in: "Das Tomatenmark einrühren.", ingredients: catalog),
            ["Tomatenmark"]
        )
        XCTAssertFalse(
            names(in: "Ein Ei in die Pfanne schlagen.", ingredients: catalog).contains("Teig")
        )
    }

    func testSeveralIngredientsInOneStep() {
        XCTAssertEqual(
            names(
                in: "Zwiebeln und Knoblauch anbraten, dann Tomaten dazugeben.",
                ingredients: ["2 Zwiebeln", "3 Knoblauchzehen", "1 Dose Tomaten", "1 TL Salz"]
            ),
            ["Zwiebeln", "Knoblauch", "Tomaten"]
        )
    }

    func testMarkedQuantityScalesAndUnmarkedUsesRecipeQuantity() {
        let scaled = items(
            in: "200 g\(marker) Mehl hinzufügen.",
            ingredients: ["200 g Mehl"],
            servings: 8
        )
        XCTAssertEqual(scaled.first?.quantity, "400 g")

        let unmarked = items(
            in: "Das Mehl hinzufügen.",
            ingredients: ["200 g Mehl"],
            servings: 8
        )
        XCTAssertEqual(unmarked.first?.name, "Mehl")
        XCTAssertEqual(unmarked.first?.quantity, "400g")
    }

    func testDuplicateMentionIsListedOnce() {
        XCTAssertEqual(
            names(
                in: "200 g\(marker) Mehl und noch etwas Mehl einkneten.",
                ingredients: ["400 g Mehl"]
            ),
            ["Mehl"]
        )
    }

    func testLemonJuiceMatchesTheFruit() {
        XCTAssertEqual(
            names(in: "Den Zitronensaft dazugeben.", ingredients: ["1 Zitrone"]),
            ["Zitrone"]
        )
    }

    func testRedOnionsDoNotReplacePlainOnionsWhenOnlyThoseAreNamed() {
        XCTAssertEqual(
            names(
                in: "Die Zwiebeln würfeln.",
                ingredients: ["2 Zwiebeln", "1 rote Zwiebeln"]
            ),
            ["Zwiebeln"]
        )
        XCTAssertEqual(
            names(
                in: "Die roten Zwiebeln in Ringe schneiden.",
                ingredients: ["2 Zwiebeln", "1 rote Zwiebeln"]
            ),
            ["rote Zwiebeln"]
        )
    }
}
