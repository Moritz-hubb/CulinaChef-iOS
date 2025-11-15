import Foundation

/// Backend-proxied OpenAI client
/// All OpenAI API calls go through the backend to keep API keys secure.
final class BackendOpenAIClient {
    let backend: BackendClient
    let accessTokenProvider: () -> String?
    
    init(backend: BackendClient, accessTokenProvider: @escaping () -> String?) {
        self.backend = backend
        self.accessTokenProvider = accessTokenProvider
    }
    
    // MARK: - Chat Completion
    
    /// Chat completion with optional vision support
    func chatReply(
        messages: [ChatMessage],
        maxHistory: Int = 8,
        model: String = "gpt-4o-mini"
    ) async throws -> String {
        guard let token = accessTokenProvider() else {
            throw NSError(domain: "BackendOpenAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        
        // Trim messages to maxHistory
        let trimmed = Array(messages.suffix(maxHistory))
        
        struct RequestMessage: Encodable {
            let role: String
            let content: String
            let image_data_base64: String?
        }
        
        struct Request: Encodable {
            let messages: [RequestMessage]
            let max_tokens: Int
            let temperature: Double
            let model: String
        }
        
        let requestMessages = trimmed.map { msg in
            RequestMessage(
                role: msg.role.rawValue,
                content: msg.text,
                image_data_base64: msg.imageDataBase64
            )
        }
        
        let request = Request(
            messages: requestMessages,
            max_tokens: 500,
            temperature: 0.7,
            model: model
        )
        
        let jsonBody = try JSONEncoder().encode(request)
        
        var url = backend.baseURL
        url.append(path: "/ai/chat")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = jsonBody
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        if !(200...299).contains(http.statusCode) {
            struct ServerError: Decodable { let detail: String? }
            if let err = try? JSONDecoder().decode(ServerError.self, from: data),
               let msg = err.detail, !msg.isEmpty {
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.badServerResponse)
        }
        
        struct Response: Decodable {
            let reply: String
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.reply
    }
    
    // MARK: - Image Analysis
    
    /// Analyze image with OpenAI Vision
    func analyzeImage(
        _ imageData: Data,
        userPrompt: String,
        model: String = "gpt-4o-mini"
    ) async throws -> String {
        guard let token = accessTokenProvider() else {
            throw NSError(domain: "BackendOpenAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        
        struct Request: Encodable {
            let image_data_base64: String
            let prompt: String
            let model: String
        }
        
        let request = Request(
            image_data_base64: imageData.base64EncodedString(),
            prompt: userPrompt,
            model: model
        )
        
        let jsonBody = try JSONEncoder().encode(request)
        
        var url = backend.baseURL
        url.append(path: "/ai/analyze-image")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = jsonBody
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        if !(200...299).contains(http.statusCode) {
            struct ServerError: Decodable { let detail: String? }
            if let err = try? JSONDecoder().decode(ServerError.self, from: data),
               let msg = err.detail, !msg.isEmpty {
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.badServerResponse)
        }
        
        struct Response: Decodable {
            let analysis: String
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.analysis
    }
    
    // MARK: - Recipe Plan Generation
    
    /// Generate structured recipe plan
    func generateRecipePlan(
        goal: String,
        timeMinutesMin: Int?,
        timeMinutesMax: Int?,
        nutrition: NutritionConstraint,
        categories: [String],
        servings: Int?,
        dietaryContext: String? = nil
    ) async throws -> RecipePlan {
        guard let token = accessTokenProvider() else {
            throw NSError(domain: "BackendOpenAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        
        // Build request dictionary
        var requestDict: [String: Any] = [
            "goal": goal,
            "categories": categories,
            "model": "gpt-4o-mini"
        ]
        
        if let min = timeMinutesMin { requestDict["time_minutes_min"] = min }
        if let max = timeMinutesMax { requestDict["time_minutes_max"] = max }
        if let s = servings { requestDict["servings"] = s }
        if let ctx = dietaryContext { requestDict["dietary_context"] = ctx }
        
        requestDict["nutrition_constraints"] = [
            "calories_min": nutrition.calories_min,
            "calories_max": nutrition.calories_max,
            "protein_min_g": nutrition.protein_min_g,
            "protein_max_g": nutrition.protein_max_g,
            "fat_min_g": nutrition.fat_min_g,
            "fat_max_g": nutrition.fat_max_g,
            "carbs_min_g": nutrition.carbs_min_g,
            "carbs_max_g": nutrition.carbs_max_g
        ]
        
        let jsonBody = try JSONSerialization.data(withJSONObject: requestDict)
        
        var url = backend.baseURL
        url.append(path: "/ai/generate-recipe-plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = jsonBody
        
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        if !(200...299).contains(http.statusCode) {
            struct ServerError: Decodable { let detail: String? }
            if let err = try? JSONDecoder().decode(ServerError.self, from: data),
               let msg = err.detail, !msg.isEmpty {
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(RecipePlan.self, from: data)
    }
}
