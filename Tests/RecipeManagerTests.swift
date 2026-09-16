import XCTest
@testable import CulinaChef

@MainActor
final class RecipeManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private let validRecipeID = "550e8400-e29b-41d4-a716-446655440000"

    override func setUp() {
        super.setUp()
        suiteName = "recipe-manager-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testProcessOfflineQueueWithoutTokenDoesNotDropQueuedDeletions() async throws {
        let manager = RecipeManager(userDefaults: defaults, enableNetworkMonitor: false)
        try await manager.deleteRecipe(recipeId: validRecipeID, accessToken: "token", isOnline: false)

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)

        await manager.processOfflineQueue()

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)
    }

    func testProcessOfflineQueueWithoutTokenDoesNotCallAuthFlush() async throws {
        let manager = RecipeManager(userDefaults: defaults, enableNetworkMonitor: false)
        try await manager.deleteRecipe(recipeId: validRecipeID, accessToken: "token", isOnline: false)

        manager.accessTokenProvider = { "" }
        await manager.processOfflineQueue()

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)
    }

    func testDeleteRecipeRejectsNonUUIDAndDoesNotQueue() async {
        let manager = RecipeManager(userDefaults: defaults, enableNetworkMonitor: false)
        do {
            try await manager.deleteRecipe(
                recipeId: "550e8400-e29b-41d4-a716-446655440000,or(id.neq.null)",
                accessToken: "token",
                isOnline: false
            )
            XCTFail("Non-UUID recipe ids must be rejected")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }
        XCTAssertEqual(manager.getPendingDeletionCount(), 0)
    }
}
