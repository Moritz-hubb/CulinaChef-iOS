import Foundation

/// Paginated personal-recipe loader. PostgREST silently truncates unbounded `select=*`.
enum RecipeLibraryFetch {
    static let pageSize = 500

    static func loadAll(userId: String, token: String, timeout: TimeInterval = 15) async throws -> [Recipe] {
        try PostgRESTFilter.requireEqValue(userId)
        var collected: [Recipe] = []
        var seen = Set<String>()
        var offset = 0
        while offset < 50_000 {
            let page = try await loadPage(userId: userId, token: token, offset: offset, timeout: timeout)
            if page.isEmpty {
                break
            }
            for recipe in page where seen.insert(recipe.id).inserted {
                collected.append(recipe)
            }
            if page.count < pageSize {
                break
            }
            offset += page.count
        }
        return collected
    }

    private static func loadPage(userId: String, token: String, offset: Int, timeout: TimeInterval) async throws -> [Recipe] {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "offset", value: String(offset))
        ])
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(offset)-\(offset + pageSize - 1)", forHTTPHeaderField: "Range")
        request.timeoutInterval = timeout
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([Recipe].self, from: data)
    }
}
