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
        let manager = makeManager(userId: "user-a")
        try await manager.deleteRecipe(recipeId: validRecipeID, accessToken: "token", isOnline: false)

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)

        await manager.processOfflineQueue()

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)
    }

    func testProcessOfflineQueueWithoutTokenDoesNotCallAuthFlush() async throws {
        let manager = makeManager(userId: "user-a")
        try await manager.deleteRecipe(recipeId: validRecipeID, accessToken: "token", isOnline: false)

        manager.accessTokenProvider = { "" }
        await manager.processOfflineQueue()

        XCTAssertEqual(manager.getPendingDeletionCount(), 1)
    }

    func testDeleteRecipeRejectsNonUUIDAndDoesNotQueue() async {
        let manager = makeManager(userId: "user-a")
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

    func testDeleteRecipeWithoutUserIdDoesNotUseGlobalQueue() async {
        let manager = RecipeManager(userDefaults: defaults, enableNetworkMonitor: false)
        manager.userIdProvider = { nil }
        do {
            try await manager.deleteRecipe(recipeId: validRecipeID, accessToken: "token", isOnline: false)
            XCTFail("Queueing without a user id must fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .userAuthenticationRequired)
        }
        XCTAssertEqual(manager.getPendingDeletionCount(), 0)
        XCTAssertNil(defaults.data(forKey: "offline_recipe_deletion_queue"))
    }

    func testOfflineQueueIsIsolatedPerUser() async throws {
        let userA = makeManager(userId: "user-a")
        try await userA.deleteRecipe(recipeId: validRecipeID, accessToken: "token-a", isOnline: false)
        XCTAssertEqual(userA.getPendingDeletionCount(), 1)

        let userB = makeManager(userId: "user-b")
        XCTAssertEqual(userB.getPendingDeletionCount(), 0)
        XCTAssertEqual(userA.getPendingDeletionCount(), 1)
    }

    func testClearOfflineQueueRemovesOnlyThatUser() async throws {
        let userA = makeManager(userId: "user-a")
        let userB = makeManager(userId: "user-b")
        try await userA.deleteRecipe(recipeId: validRecipeID, accessToken: "token-a", isOnline: false)
        try await userB.deleteRecipe(
            recipeId: "550e8400-e29b-41d4-a716-446655440001",
            accessToken: "token-b",
            isOnline: false
        )

        userA.clearOfflineQueue(for: "user-a")
        XCTAssertEqual(userA.getPendingDeletionCount(), 0)
        XCTAssertEqual(userB.getPendingDeletionCount(), 1)
    }

    func testLegacyQueueMigratesToCurrentUserOnlyOnce() throws {
        struct LegacyItem: Encodable {
            let recipeId: String
            let timestamp: Date
        }
        defaults.set(
            try JSONEncoder().encode([LegacyItem(recipeId: validRecipeID, timestamp: Date())]),
            forKey: "offline_recipe_deletion_queue"
        )

        let userA = makeManager(userId: "user-a")
        XCTAssertEqual(userA.getPendingDeletionCount(), 1)
        XCTAssertNil(defaults.data(forKey: "offline_recipe_deletion_queue"))

        let userB = makeManager(userId: "user-b")
        XCTAssertEqual(userB.getPendingDeletionCount(), 0)
        XCTAssertEqual(userA.getPendingDeletionCount(), 1)
    }

    private func makeManager(userId: String) -> RecipeManager {
        let manager = RecipeManager(userDefaults: defaults, enableNetworkMonitor: false)
        manager.userIdProvider = { userId }
        return manager
    }
}

@MainActor
final class MenuManagerFilterTests: XCTestCase {
    func testRenameMenuRejectsPostgRESTInjection() async {
        let manager = MenuManager()
        do {
            _ = try await manager.renameMenu(
                menuId: "abc,or(id.neq.null)",
                newTitle: "Dinner",
                accessToken: "token"
            )
            XCTFail("Injected menu id must be rejected")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }
    }

    func testDeleteMenuAllowsExistingTestTokens() async {
        MockURLProtocol.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        defer { SecureURLSession.testConfiguration = nil }

        MockURLProtocol.mockResponse(statusCode: 204)
        let manager = MenuManager()
        try? await manager.deleteMenu(menuId: "menu_123", accessToken: "token")
    }

    func testCreateMenuEmptyRepresentationThrowsInsteadOfCrashing() async {
        MockURLProtocol.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        defer { SecureURLSession.testConfiguration = nil }

        MockURLProtocol.mockResponse(statusCode: 201, data: Data("[]".utf8))
        let manager = MenuManager()
        do {
            _ = try await manager.createMenu(title: "Dinner", accessToken: "token", userId: "user_1")
            XCTFail("Empty representation must throw")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cannotParseResponse)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testCreateMenuReturnsFirstRow() async throws {
        MockURLProtocol.reset()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        SecureURLSession.testConfiguration = config
        defer { SecureURLSession.testConfiguration = nil }

        let menu = Menu(id: "menu_1", user_id: "user_1", title: "Dinner", created_at: nil)
        let data = try JSONEncoder().encode([menu])
        MockURLProtocol.mockResponse(statusCode: 201, data: data)
        let manager = MenuManager()
        let created = try await manager.createMenu(title: "Dinner", accessToken: "token", userId: "user_1")
        XCTAssertEqual(created.id, "menu_1")
        XCTAssertEqual(created.title, "Dinner")
    }
}
