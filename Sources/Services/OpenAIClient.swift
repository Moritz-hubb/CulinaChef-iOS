import Foundation

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable { case system, user, assistant }
    let id: UUID
    var role: Role
    var text: String
    var imageDataBase64: String? // optional inline image for vision prompts

    init(id: UUID = UUID(), role: Role, text: String, imageDataBase64: String? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.imageDataBase64 = imageDataBase64
    }
}

final class OpenAIClient {
    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://api.openai.com/v1")!

    init?(apiKey: String?, session: URLSession = URLSession(configuration: .default)) {
        guard let key = apiKey, !key.isEmpty else { return nil }
        self.apiKey = key
        self.session = session
    }

    // MARK: - Public

    func chatReply(messages: [ChatMessage], maxHistory: Int = 8, model: String = "gpt-4o-mini") async throws -> String {
        // keep last N messages to control cost
        let trimmed = Array(messages.suffix(maxHistory))
        let requestBody = try buildChatCompletionsBody(from: trimmed, model: model)
        let req = try makeJSONRequest(path: "/chat/completions", body: requestBody)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        struct Choice: Decodable { let message: AssistantMessage }
        struct AssistantMessage: Decodable { let content: String }
        struct Response: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    func analyzeImage(_ imageData: Data, userPrompt: String, model: String = "gpt-4o-mini") async throws -> String {
        // Build a single-turn vision prompt asking for ingredient breakdown and measurements
        let b64 = imageData.base64EncodedString()
        let combinedPrompt = "\(userPrompt)\n\nAnalysiere die Hauptzutaten auf dem Bild. Gib eine strukturierte Liste zurück mit: Name, geschätzte Menge (Gramm/Stück), ggf. Dicke/Größe. Antworte kurz und präzise."
        let content: [[String: Any]] = [
            ["type": "text", "text": combinedPrompt],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]]
        ]
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": content]
            ]
        ]
        let req = try makeJSONRequest(path: "/chat/completions", jsonBody: body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        struct Choice: Decodable { let message: AssistantMsg }
        struct AssistantMsg: Decodable { let content: String }
        struct Response: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    // Custom error for non-recipe requests
    enum RecipeError: LocalizedError {
        case notARecipeRequest
        case impossibleRecipe(explanation: String)
        
        var errorDescription: String? {
            switch self {
            case .notARecipeRequest:
                return "NO_RECIPE_REQUEST"
            case .impossibleRecipe(let explanation):
                return "IMPOSSIBLE_RECIPE: \(explanation)"
            }
        }
    }
    
    // Structured recipe generation
    func generateRecipePlan(goal: String, timeMinutesMin: Int?, timeMinutesMax: Int?, nutrition: NutritionConstraint, categories: [String], servings: Int?, dietaryContext: String? = nil) async throws -> RecipePlan {
        let model = "gpt-4o-mini"
        // System prompt with strict JSON contract
        let schema = """
        You are a culinary expert assistant that ONLY helps with cooking recipes.
        
        IMPORTANT: Follow these rules in order:
        
        1) If the request is NOT about recipes/cooking/food (e.g., math, general questions, unrelated tasks), return ONLY: NO_RECIPE_REQUEST
        
        2) If it IS a recipe request, check if the combination is logically IMPOSSIBLE (e.g., "halal pork", "vegan steak with real beef", "kosher shellfish").
           - FIRST try to find creative alternatives (e.g., vegan burger → use plant-based patty; vegetarian steak → portobello mushroom or seitan)
           - ONLY if it's 100% impossible and no reasonable alternative exists, return: IMPOSSIBLE_RECIPE: [2-3 sentences in German explaining why it's impossible]
           Example: "IMPOSSIBLE_RECIPE: Ein halales Spanferkel ist nicht möglich, da Schweinefleisch im Islam als haram (verboten) gilt. Halal bedeutet, dass das Fleisch von erlaubten Tieren stammen muss, wie Rind, Lamm oder Geflügel."
        
        3) If the request is valid or can be adapted with alternatives, return ONLY JSON (no markdown) matching this Swift-like schema:
        {
          "title": string,
          "servings": number | null,
          "total_time_minutes": number | null,
          "categories": [string],
          "nutrition": {
            "calories": number | null,        // per serving, not total
            "protein_g": number | null,       // per serving
            "fat_g": number | null,           // per serving
            "carbs_g": number | null,         // per serving
            "fiber_g": number | null,         // per serving
            "sugar_g": number | null,         // per serving
            "salt_g": number | null           // per serving
          },
          "ingredients": [ { "name": string, "amount": number | null, "unit": string | null } ],
          "equipment": [string],
          "steps": [ { "title": string, "description": string, "duration_minutes": number | null } ],
          "notes": string | null
        }
        Quantify all amounts with grams/ml/Stück where applicable. Be precise and detailed.
        Nutrition values MUST be per serving and internally consistent with the listed ingredients. REQUIRED: Do not output null for calories, protein_g, fat_g, carbs_g when ingredients are present. Provide numeric values only (no ranges/units), kcal as whole numbers, macros to 0 decimals. Validate that kcal ≈ protein_g*4 + carbs_g*4 + fat_g*9 within ±10%. If uncertain, compute using standard nutritional averages and choose a single best estimate.
        For each step, write a highly detailed instruction including:
        - exact action with verbs and sequencing (1-2 sentences)
        - exact quantities (metric), equipment (pan/pot size), and preparation state
        - heat/temperature (e.g., "mittlere Hitze (6/10)", "Backofen 200°C Umluft")
        - precise timing (start/end or ranges) AND sensory cues (Farbe, Geruch, Textur, Geräusch)
        - doneness checks (z.B. Kerntemperatur medium-rare 54–57°C; Pasta al dente Bissfestigkeit)
        - parallelization hints using "In der Zwischenzeit, …" where appropriate
        Keep steps atomic; avoid combining multiple unrelated actions in one Schritt.
        """
        let user: [String: Any] = [
            "goal": goal,
            "time_minutes_min": timeMinutesMin as Any,
            "time_minutes_max": timeMinutesMax as Any,
            "servings": servings as Any,
            "categories": categories,
            "nutrition_constraints": [
                "calories_min": nutrition.calories_min as Any,
                "calories_max": nutrition.calories_max as Any,
                "protein_min_g": nutrition.protein_min_g as Any,
                "protein_max_g": nutrition.protein_max_g as Any,
                "fat_min_g": nutrition.fat_min_g as Any,
                "fat_max_g": nutrition.fat_max_g as Any,
                "carbs_min_g": nutrition.carbs_min_g as Any,
                "carbs_max_g": nutrition.carbs_max_g as Any
            ]
        ]
        // Build chat payload
        var messages: [[String: Any]] = [["role": "system", "content": schema]]
        if let ctx = dietaryContext, !ctx.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(["role": "system", "content": ctx])
        }
        messages.append(["role": "user", "content": try jsonString(user)])
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.1,
            "response_format": ["type": "json_object"],
            "messages": messages
        ]
        let req = try makeJSONRequest(path: "/chat/completions", jsonBody: body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        struct Choice: Decodable { let message: AssistantMsg }
        struct AssistantMsg: Decodable { let content: String }
        struct Response: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let content = decoded.choices.first?.message.content ?? "{}"
        
        // Check if AI returned the rejection keywords
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedContent.contains("NO_RECIPE_REQUEST") {
            throw RecipeError.notARecipeRequest
        }
        
        // Check for impossible recipe with explanation
        if trimmedContent.hasPrefix("IMPOSSIBLE_RECIPE:") {
            let explanation = trimmedContent.replacingOccurrences(of: "IMPOSSIBLE_RECIPE:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            throw RecipeError.impossibleRecipe(explanation: explanation)
        }
        
        // Parse JSON from content (strip fences or extra text if any)
        let cleaned = Self.extractJSONObjectString(from: content) ?? content
        let jsonData = Data(cleaned.utf8)
        return try JSONDecoder().decode(RecipePlan.self, from: jsonData)
    }

    // MARK: - Helpers

    private func buildChatCompletionsBody(from messages: [ChatMessage], model: String) throws -> URLRequestBody {
        var converted: [[String: Any]] = []
        for m in messages {
            if let b64 = m.imageDataBase64 {
                let content: [[String: Any]] = [
                    ["type": "text", "text": m.text],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]]
                ]
                converted.append(["role": m.role.rawValue, "content": content])
            } else {
                converted.append(["role": m.role.rawValue, "content": m.text])
            }
        }
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.4,
            "messages": converted
        ]
        return URLRequestBody.json(body)
    }

    private enum URLRequestBody {
        case json([String: Any])
        case data(Data)
    }

    private func jsonString(_ dict: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func extractJSONObjectString(from text: String) -> String? {
        // Remove markdown fences
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            // drop first fence line
            if let range = t.range(of: "\n") { t = String(t[range.upperBound...]) }
            // drop trailing fence
            if let r = t.range(of: "```", options: .backwards) { t = String(t[..<r.lowerBound]) }
        }
        // Find first '{' and last '}' to extract JSON object
        guard let first = t.firstIndex(of: "{"), let last = t.lastIndex(of: "}") else { return nil }
        let substr = t[first...last]
        return String(substr)
    }

    // Generate a short, catchy German menu name based on occasion and course titles
    func generateMenuName(occasion: String?, courseTitles: [String]) async throws -> String {
        let model = "gpt-4o-mini"
        let sys = """
        Du bist ein kreativer Küchenberater. Erzeuge einen KURZEN deutschen Menü-Namen (max. 5 Wörter),
        ohne Anführungszeichen oder Satzzeichen am Ende. Beispiel: "Weihnachtsmenü Rustikal" oder "Sommerliches Grill-Menü".
        Antworte NUR mit dem Namen, nichts weiter.
        """
        var user: [String: Any] = ["courses": courseTitles]
        if let occ = occasion, !occ.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            user["occasion"] = occ
        }
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.6,
            "messages": [
                ["role": "system", "content": sys],
                ["role": "user", "content": try jsonString(user)]
            ]
        ]
        let req = try makeJSONRequest(path: "/chat/completions", jsonBody: body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        struct Choice: Decodable { let message: AssistantMsg }
        struct AssistantMsg: Decodable { let content: String }
        struct Response: Decodable { let choices: [Choice] }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let raw = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "KI-Menü"
        // Strip quotes if any
        return raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func makeJSONRequest(path: String, body: URLRequestBody) throws -> URLRequest {
        var url = baseURL
        url.append(path: path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        switch body {
        case .json(let dict):
            req.httpBody = try JSONSerialization.data(withJSONObject: dict)
        case .data(let data):
            req.httpBody = data
        }
        return req
    }

    private func makeJSONRequest(path: String, jsonBody: [String: Any]) throws -> URLRequest {
        try makeJSONRequest(path: path, body: .json(jsonBody))
    }
}