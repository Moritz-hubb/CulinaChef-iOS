import XCTest
@testable import CulinaChef

@MainActor
final class RecipeManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

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
        try await manager.deleteRecipe(recipeId: "recipe-1", accessToken: "token", isOnline: false)

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)

        await manager.processOfflineQueue()

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)
    }

    func testProcessOfflineQueueWithoutTokenDoesNotCallAuthFlush() async throws {
        let manager = RecipeManager(userDefaults: defaults, enableNetworkMonitor: false)
        try await manager.deleteRecipe(recipeId: "recipe-2", accessToken: "token", isOnline: false)

        manager.accessTokenProvider = { "" }
        await manager.processOfflineQueue()

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)
    }
}
