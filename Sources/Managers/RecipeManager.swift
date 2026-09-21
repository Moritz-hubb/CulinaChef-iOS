import Foundation
import Network

/// Manager for all recipe operations including offline deletion queue
/// Extracted from AppState to improve maintainability and separation of concerns
@MainActor
final class RecipeManager {
    
    // MARK: - Network Monitoring
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var isNetworkAvailable = false
    
    // MARK: - Offline Queue
    
    private struct RecipeDeletion: Codable {
        let recipeId: String
        let timestamp: Date
    }
    
    private static let legacyQueueKey = "offline_recipe_deletion_queue"
    private let defaults: UserDefaults
    /// Live token for the network-monitor flush. Without a token the queue must stay intact.
    var accessTokenProvider: (() -> String?)?
    /// Current user for queue isolation. Defaults to Keychain `user_id`.
    var userIdProvider: (() -> String?)?
    
    init(userDefaults: UserDefaults = .standard, enableNetworkMonitor: Bool = true) {
        self.defaults = userDefaults
        if enableNetworkMonitor {
            setupNetworkMonitoring()
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkAvailable = (path.status == .satisfied)
                if path.status == .satisfied {
                    await self?.processOfflineQueue()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Recipe Deletion
    
    /// Delete a recipe, queuing for offline processing if network unavailable
    func deleteRecipe(recipeId: String, accessToken: String?, isOnline: Bool) async throws {
        guard PostgRESTUUID.isValid(recipeId) else {
            throw URLError(.badURL)
        }
        guard let token = accessToken else {
            throw URLError(.userAuthenticationRequired)
        }
        guard let userId = resolvedUserId(), !userId.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        
        if isOnline && isNetworkAvailable {
            // Try immediate deletion
            do {
                try await deleteRecipeFromSupabase(recipeId: recipeId, accessToken: token)
            } catch {
                // Network error - queue for later
                addToOfflineQueue(recipeId: recipeId, userId: userId)
                throw error
            }
        } else {
            // Offline - queue immediately
            addToOfflineQueue(recipeId: recipeId, userId: userId)
        }
    }
    
    private struct DeletedRecipeRow: Decodable {
        let id: String
        let image_url: String?
    }
    
    private func deleteRecipeFromSupabase(recipeId: String, accessToken: String) async throws {
        guard PostgRESTUUID.isValid(recipeId) else {
            throw URLError(.badURL)
        }
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(recipeId)")])
        
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        var imageURL: String?
        if !data.isEmpty,
           let rows = try? JSONDecoder().decode([DeletedRecipeRow].self, from: data) {
            imageURL = rows.first?.image_url
        }
        if let imageURL {
            await deleteRecipePhotoFromStorage(imageURL: imageURL, accessToken: accessToken)
        }
    }

    private func deleteRecipePhotoFromStorage(imageURL: String, accessToken: String) async {
        guard let filename = RecipeImageURL.storageObjectName(from: imageURL) else { return }
        var deleteURL = Config.supabaseURL
        deleteURL.append(path: "/storage/v1/object/recipe-photo/\(filename)")
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await SecureURLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                Logger.error(
                    "Recipe photo storage delete failed (status: \(http.statusCode))",
                    category: .network
                )
            }
        } catch {
            Logger.error("Recipe photo storage delete failed", error: error, category: .network)
        }
    }
    
    // MARK: - Offline Queue Management
    
    private func resolvedUserId() -> String? {
        if let userIdProvider {
            return userIdProvider()
        }
        return KeychainManager.get(key: "user_id")
    }
    
    private func queueKey(for userId: String) -> String {
        "\(Self.legacyQueueKey)_\(userId)"
    }
    
    private func addToOfflineQueue(recipeId: String, userId: String) {
        migrateLegacyQueueIfNeeded(into: userId)
        var queue = loadOfflineQueue(for: userId)
        if !queue.contains(where: { $0.recipeId == recipeId }) {
            queue.append(RecipeDeletion(recipeId: recipeId, timestamp: Date()))
            saveOfflineQueue(queue, for: userId)
        }
    }
    
    private func loadOfflineQueue(for userId: String) -> [RecipeDeletion] {
        guard let data = defaults.data(forKey: queueKey(for: userId)),
              let queue = try? JSONDecoder().decode([RecipeDeletion].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveOfflineQueue(_ queue: [RecipeDeletion], for userId: String) {
        let key = queueKey(for: userId)
        if queue.isEmpty {
            defaults.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(queue) {
            defaults.set(data, forKey: key)
        }
    }
    
    /// One-time: move the pre-isolation queue onto the first logged-in user, then drop it.
    private func migrateLegacyQueueIfNeeded(into userId: String) {
        guard let data = defaults.data(forKey: Self.legacyQueueKey) else { return }
        defaults.removeObject(forKey: Self.legacyQueueKey)
        guard let legacy = try? JSONDecoder().decode([RecipeDeletion].self, from: data), !legacy.isEmpty else {
            return
        }
        var queue = loadOfflineQueue(for: userId)
        let existing = Set(queue.map(\.recipeId))
        for item in legacy where !existing.contains(item.recipeId) {
            queue.append(item)
        }
        saveOfflineQueue(queue, for: userId)
    }
    
    /// Network-monitor entry point. Must not DELETE or dequeue without an access token.
    func processOfflineQueue() async {
        guard let token = accessTokenProvider?(), !token.isEmpty else {
            Logger.debug("Skipping offline deletion flush — no access token", category: .data)
            return
        }
        await processOfflineQueueWithAuth(accessToken: token)
    }
    
    /// Process offline queue with access token (called by AppState when network returns)
    func processOfflineQueueWithAuth(accessToken: String) async {
        guard let userId = resolvedUserId(), !userId.isEmpty else { return }
        migrateLegacyQueueIfNeeded(into: userId)
        var queue = loadOfflineQueue(for: userId)
        guard !queue.isEmpty else { return }
        
        var successfulIndices: [Int] = []
        
        for (index, deletion) in queue.enumerated() {
            guard PostgRESTUUID.isValid(deletion.recipeId) else {
                successfulIndices.append(index)
                continue
            }
            do {
                try await deleteRecipeFromSupabase(recipeId: deletion.recipeId, accessToken: accessToken)
                successfulIndices.append(index)
            } catch {
                Logger.error("Failed to process offline deletion for recipe \(deletion.recipeId)", error: error, category: .data)
            }
        }
        
        for index in successfulIndices.reversed() {
            queue.remove(at: index)
        }
        
        saveOfflineQueue(queue, for: userId)
    }
    
    func getPendingDeletionCount() -> Int {
        guard let userId = resolvedUserId(), !userId.isEmpty else { return 0 }
        migrateLegacyQueueIfNeeded(into: userId)
        return loadOfflineQueue(for: userId).count
    }
    
    func clearOfflineQueue(for userId: String) {
        defaults.removeObject(forKey: queueKey(for: userId))
        defaults.removeObject(forKey: Self.legacyQueueKey)
    }
}
