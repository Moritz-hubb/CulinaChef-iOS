import Foundation

/// Manager for all menu-related operations (CRUD, suggestions, course mappings)
/// Extracted from AppState to improve maintainability and separation of concerns
@MainActor
final class MenuManager {
    
    // MARK: - Menu Suggestions (Local Storage)
    
    struct MenuSuggestion: Identifiable, Codable, Equatable {
        let id: UUID
        let name: String
        let description: String?
        let course: String?
        var status: String? // nil|"generating"|"failed"
        var progress: Double? // 0.0 ... 1.0 while generating
        
        init(id: UUID = UUID(), name: String, description: String? = nil, course: String? = nil, status: String? = nil, progress: Double? = nil) {
            self.id = id
            self.name = name
            self.description = description
            self.course = course
            self.status = status
            self.progress = progress
        }
    }
    
    // MARK: - Supabase Menu Operations
    
    /// Fetch all menus for a user from Supabase
    func fetchMenus(accessToken: String, userId: String) async throws -> [Menu] {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/menus")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Menu].self, from: data)
    }
    
    /// Create a new menu in Supabase
    func createMenu(title: String, accessToken: String, userId: String) async throws -> Menu {
        struct Row: Encodable {
            let user_id: String
            let title: String
        }
        
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/menus")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode([Row(user_id: userId, title: title)])
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Menu].self, from: data).first!
    }
    
    /// Add a recipe to a menu
    func addRecipeToMenu(menuId: String, recipeId: String, accessToken: String) async throws {
        struct Row: Encodable {
            let menu_id: String
            let recipe_id: String
        }
        
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipe_menus")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode([Row(menu_id: menuId, recipe_id: recipeId)])
        
        let (_, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    /// Remove a recipe from a menu
    func removeRecipeFromMenu(menuId: String, recipeId: String, accessToken: String) async throws {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipe_menus")
        url.append(queryItems: [
            URLQueryItem(name: "menu_id", value: "eq.\(menuId)"),
            URLQueryItem(name: "recipe_id", value: "eq.\(recipeId)")
        ])
        
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (_, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    /// Fetch recipe IDs associated with a menu
    func fetchMenuRecipeIds(menuId: String, accessToken: String) async throws -> [String] {
        struct Row: Decodable {
            let recipe_id: String
        }
        
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipe_menus")
        url.append(queryItems: [
            URLQueryItem(name: "menu_id", value: "eq.\(menuId)"),
            URLQueryItem(name: "select", value: "recipe_id")
        ])
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return rows.map { $0.recipe_id }
    }
    
    /// Delete a menu from Supabase
    func deleteMenu(menuId: String, accessToken: String) async throws {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/menus")
        url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(menuId)")])
        
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
        
        // Clean up local placeholders
        removeAllMenuSuggestions(menuId: menuId)
    }
    
    // MARK: - Menu Suggestions (Local Storage)
    
    private func suggestionsKey(for menuId: String) -> String {
        "menu_suggestions_\(menuId)"
    }
    
    func getMenuSuggestions(menuId: String) -> [MenuSuggestion] {
        let key = suggestionsKey(for: menuId)
        if let data = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([MenuSuggestion].self, from: data) {
            return arr
        }
        return []
    }
    
    func addMenuSuggestions(_ suggestions: [MenuSuggestion], to menuId: String) {
        var existing = getMenuSuggestions(menuId: menuId)
        existing.append(contentsOf: suggestions)
        saveMenuSuggestions(existing, to: menuId)
    }
    
    func removeMenuSuggestion(named name: String, from menuId: String) {
        var existing = getMenuSuggestions(menuId: menuId)
        if let idx = existing.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            existing.remove(at: idx)
            saveMenuSuggestions(existing, to: menuId)
        }
    }
    
    func removeAllMenuSuggestions(menuId: String) {
        let key = suggestionsKey(for: menuId)
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func setMenuSuggestionStatus(menuId: String, name: String, status: String?) {
        var existing = getMenuSuggestions(menuId: menuId)
        if let idx = existing.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            existing[idx].status = status
            saveMenuSuggestions(existing, to: menuId)
        }
    }
    
    func setMenuSuggestionProgress(menuId: String, name: String, progress: Double?) {
        var existing = getMenuSuggestions(menuId: menuId)
        if let idx = existing.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            existing[idx].progress = progress
            saveMenuSuggestions(existing, to: menuId)
        }
    }
    
    private func saveMenuSuggestions(_ list: [MenuSuggestion], to menuId: String) {
        let key = suggestionsKey(for: menuId)
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Menu Course Mapping (Local Storage)
    
    private func courseMapKey(for menuId: String) -> String {
        "menu_courses_\(menuId)"
    }
    
    func getMenuCourseMap(menuId: String) -> [String: String] {
        let key = courseMapKey(for: menuId)
        if let data = UserDefaults.standard.data(forKey: key),
           let obj = try? JSONDecoder().decode([String: String].self, from: data) {
            return obj
        }
        return [:]
    }
    
    func setMenuCourse(menuId: String, recipeId: String, course: String) {
        var map = getMenuCourseMap(menuId: menuId)
        map[recipeId] = course
        let key = courseMapKey(for: menuId)
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func removeMenuCourse(menuId: String, recipeId: String) {
        var map = getMenuCourseMap(menuId: menuId)
        map.removeValue(forKey: recipeId)
        let key = courseMapKey(for: menuId)
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    // MARK: - Course Guesser (Heuristic)
    
    /// Heuristic to guess the course type from name and description
    func guessCourse(name: String, description: String?) -> String {
        let text = (name + " " + (description ?? "")).lowercased()
        
        let starters = ["vorspeise", "starter", "antipasti", "antipasto", "bruschetta", "salat", "suppe", "gazpacho", "carpaccio"]
        let intermediate = ["zwischengang", "zwischen-gang", "zwischen gang"]
        let amuse = ["amuse-bouche", "amuse bouche", "gruß aus der küche", "gruss aus der kueche"]
        let mains = ["hauptspeise", "hauptgericht", "hauptgang", "main", "pasta", "steak", "curry", "burger", "auflauf", "pfanne"]
        let desserts = ["nachspeise", "dessert", "kuchen", "tiramisu", "pudding", "mousse", "eis", "brownie", "keks", "cookie"]
        let cheese = ["käsegang", "kaesegang", "käse", "kaese", "käseplatte", "kaeseplatte"]
        let sides = ["beilage", "beilagen", "brot", "reis", "kartoffel", "kartoffeln", "pommes", "gemüse", "gemuese"]
        let aperitif = ["aperitif", "aperitivo"]
        let digestif = ["digestif"]
        let drinks = ["getränk", "getraenk", "drink", "cocktail", "mocktail", "saft", "smoothie", "limonade"]
        
        if amuse.contains(where: { text.contains($0) }) { return "Amuse-Bouche" }
        if starters.contains(where: { text.contains($0) }) { return "Vorspeise" }
        if intermediate.contains(where: { text.contains($0) }) { return "Zwischengang" }
        if mains.contains(where: { text.contains($0) }) { return "Hauptspeise" }
        if cheese.contains(where: { text.contains($0) }) { return "Käsegang" }
        if desserts.contains(where: { text.contains($0) }) { return "Nachspeise" }
        if aperitif.contains(where: { text.contains($0) }) { return "Aperitif" }
        if digestif.contains(where: { text.contains($0) }) { return "Digestif" }
        if drinks.contains(where: { text.contains($0) }) { return "Getränk" }
        if sides.contains(where: { text.contains($0) }) { return "Beilage" }
        
        return "Hauptspeise" // Default
    }
}
