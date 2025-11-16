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
    
    private let queueKey = "offline_recipe_deletion_queue"
    
    init() {
        setupNetworkMonitoring()
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
        guard let token = accessToken else {
            throw URLError(.userAuthenticationRequired)
        }
        
        if isOnline && isNetworkAvailable {
            // Try immediate deletion
            do {
                try await deleteRecipeFromSupabase(recipeId: recipeId, accessToken: token)
            } catch {
                // Network error - queue for later
                addToOfflineQueue(recipeId: recipeId)
                throw error
            }
        } else {
            // Offline - queue immediately
            addToOfflineQueue(recipeId: recipeId)
        }
    }
    
    private func deleteRecipeFromSupabase(recipeId: String, accessToken: String) async throws {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(recipeId)")])
        
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        let (_, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Offline Queue Management
    
    private func addToOfflineQueue(recipeId: String) {
        var queue = loadOfflineQueue()
        // Avoid duplicates
        if !queue.contains(where: { $0.recipeId == recipeId }) {
            queue.append(RecipeDeletion(recipeId: recipeId, timestamp: Date()))
            saveOfflineQueue(queue)
        }
    }
    
    private func loadOfflineQueue() -> [RecipeDeletion] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([RecipeDeletion].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveOfflineQueue(_ queue: [RecipeDeletion]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
    
    private func processOfflineQueue() async {
        var queue = loadOfflineQueue()
        guard !queue.isEmpty else { return }
        
        // Try to get access token from AppState (via callback or similar)
        // For now, we'll assume the caller provides it via a method parameter
        // This is a design consideration for later integration
        
        var processedIndices: [Int] = []
        
        for (index, deletion) in queue.enumerated() {
            // Skip processing if we don't have auth
            // This will be handled during integration with AppState
            processedIndices.append(index)
        }
        
        // Remove processed items
        for index in processedIndices.reversed() {
            queue.remove(at: index)
        }
        
        saveOfflineQueue(queue)
    }
    
    /// Process offline queue with access token (called by AppState when network returns)
    func processOfflineQueueWithAuth(accessToken: String) async {
        var queue = loadOfflineQueue()
        guard !queue.isEmpty else { return }
        
        var successfulIndices: [Int] = []
        
        for (index, deletion) in queue.enumerated() {
            do {
                try await deleteRecipeFromSupabase(recipeId: deletion.recipeId, accessToken: accessToken)
                successfulIndices.append(index)
            } catch {
                // Keep in queue, will retry later
                Logger.error("Failed to process offline deletion for recipe \(deletion.recipeId)", error: error, category: .data)
            }
        }
        
        // Remove successful deletions from queue
        for index in successfulIndices.reversed() {
            queue.remove(at: index)
        }
        
        saveOfflineQueue(queue)
    }
    
    func getPendingDeletionCount() -> Int {
        return loadOfflineQueue().count
    }
}
