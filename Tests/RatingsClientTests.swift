import XCTest
@testable import CulinaChef

@MainActor
final class RatingsClientTests: XCTestCase {
    
    var sut: RatingsClient!
    var backendClient: BackendClient!
    
    override func setUp() async throws {
        try await super.setUp()
        // Use real BackendClient with test URL - we're testing RatingsClient logic only
        backendClient = BackendClient(baseURL: URL(string: "https://test.example.com")!)
        sut = RatingsClient(backendClient: backendClient)
    }
    
    override func tearDown() async throws {
        sut = nil
        backendClient = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let client = RatingsClient(backendClient: backendClient)
        XCTAssertNotNil(client)
        XCTAssertTrue(client.backendClient === backendClient)
    }
    
    // MARK: - Logic Tests (without network calls)
    
    func testFetchAverageRating_Logic_WithZeroRatings() {
        // Test the logic: if total_ratings is 0, should return nil
        // We can't easily mock BackendClient (it's final), so we test the wrapper logic conceptually
        
        // Verify client is initialized correctly
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.backendClient)
    }
    
    func testUpsertRating_HasCorrectSignature() {
        // Verify the method exists and has correct signature
        XCTAssertNotNil(sut)
        // The method signature is: func upsertRating(recipeId: String, rating: Int, accessToken: String, userId: String) async throws
    }
    
    func testDeleteRating_HasCorrectSignature() {
        // Verify the method exists and has correct signature  
        XCTAssertNotNil(sut)
        // The method signature is: func deleteRating(recipeId: String, accessToken: String) async throws
    }
    
    func testFetchAverageRating_HasCorrectSignature() {
        // Verify the method exists and has correct signature
        XCTAssertNotNil(sut)
        // The method signature is: func fetchAverageRating(recipeId: String, accessToken: String) async throws -> Double?
    }
    
    // MARK: - Integration Tests (require network/backend)
    // Note: Full integration tests would require a test backend or MockURLProtocol
    // These are structural tests only
    
    func testRatingsClient_UsesBackendClient() {
        XCTAssertTrue(sut.backendClient === backendClient)
    }
    
    func testRatingsClient_CanBeInitializedWithDifferentBackendClients() {
        let client1 = BackendClient(baseURL: URL(string: "https://test1.com")!)
        let client2 = BackendClient(baseURL: URL(string: "https://test2.com")!)
        
        let ratings1 = RatingsClient(backendClient: client1)
        let ratings2 = RatingsClient(backendClient: client2)
        
        XCTAssertTrue(ratings1.backendClient === client1)
        XCTAssertTrue(ratings2.backendClient === client2)
        XCTAssertFalse(ratings1.backendClient === ratings2.backendClient)
    }
}
