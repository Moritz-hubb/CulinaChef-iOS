import XCTest
@testable import CulinaChef

@MainActor
final class LikedRecipesManagerTests: XCTestCase {
    
    var manager: LikedRecipesManager!
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        manager = LikedRecipesManager()
    }
    
    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        manager = nil
        super.tearDown()
    }
    
    func testInitialStateEmpty() {
        XCTAssertEqual(manager.likedRecipeIds.count, 0)
    }
    
    func testLikeRecipe() {
        manager.like(recipeId: "recipe_1")
        
        XCTAssertTrue(manager.isLiked(recipeId: "recipe_1"))
        XCTAssertEqual(manager.likedRecipeIds.count, 1)
    }
    
    func testUnlikeRecipe() {
        manager.like(recipeId: "recipe_1")
        XCTAssertTrue(manager.isLiked(recipeId: "recipe_1"))
        
        manager.unlike(recipeId: "recipe_1")
        
        XCTAssertFalse(manager.isLiked(recipeId: "recipe_1"))
        XCTAssertEqual(manager.likedRecipeIds.count, 0)
    }
    
    func testToggleLike() {
        manager.toggleLike(recipeId: "recipe_1")
        XCTAssertTrue(manager.isLiked(recipeId: "recipe_1"))
        
        manager.toggleLike(recipeId: "recipe_1")
        XCTAssertFalse(manager.isLiked(recipeId: "recipe_1"))
    }
    
    func testMultipleLikes() {
        manager.like(recipeId: "recipe_1")
        manager.like(recipeId: "recipe_2")
        manager.like(recipeId: "recipe_3")
        
        XCTAssertEqual(manager.likedRecipeIds.count, 3)
        XCTAssertTrue(manager.isLiked(recipeId: "recipe_1"))
        XCTAssertTrue(manager.isLiked(recipeId: "recipe_2"))
        XCTAssertTrue(manager.isLiked(recipeId: "recipe_3"))
    }
    
    func testPersistence() {
        manager.like(recipeId: "recipe_persist")
        
        let newManager = LikedRecipesManager()
        
        XCTAssertTrue(newManager.isLiked(recipeId: "recipe_persist"))
    }
    
    func testClearAll() {
        manager.like(recipeId: "recipe_1")
        manager.like(recipeId: "recipe_2")
        
        manager.clearAll()
        
        XCTAssertEqual(manager.likedRecipeIds.count, 0)
        XCTAssertFalse(manager.isLiked(recipeId: "recipe_1"))
    }
    
    func testDuplicateLike() {
        manager.like(recipeId: "recipe_1")
        manager.like(recipeId: "recipe_1")
        
        XCTAssertEqual(manager.likedRecipeIds.count, 1)
    }
    
    func testUnlikeNonExistent() {
        manager.unlike(recipeId: "nonexistent")
        
        XCTAssertEqual(manager.likedRecipeIds.count, 0)
    }
}
