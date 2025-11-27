import Foundation

/// Backend-proxied OpenAI client.
///
/// Alle OpenAI-Aufrufe werden über das Backend geleitet, damit API-Keys niemals
/// direkt auf dem Gerät liegen. Der Client kennt nur das Supabase-Access-Token
/// und delegiert das eigentliche Prompting an den Server.
final class BackendOpenAIClient {
    /// HTTP-Client für generische Backend-Endpunkte.
    let backend: BackendClient
    /// Liefert das aktuelle Access-Token des Nutzers (z.B. aus AppState).
    let accessTokenProvider: () -> String?
    
    /// Erstellt einen neuen BackendOpenAIClient.
    ///
    /// - Parameters:
    ///   - backend: Bereits konfigurierter BackendClient.
    ///   - accessTokenProvider: Closure, die das aktuelle Access-Token liefert.
    init(backend: BackendClient, accessTokenProvider: @escaping () -> String?) {
        self.backend = backend
        self.accessTokenProvider = accessTokenProvider
    }
    
    // MARK: - Chat Completion
    
    /// Chat completion with optional vision support.
    ///
    /// - Parameters:
    ///   - messages: Voller Nachrichtenverlauf (wird intern auf `maxHistory` gekürzt).
    ///   - maxHistory: Maximale Anzahl an Nachrichten, die an das Backend geschickt werden.
    ///   - model: OpenAI-Modellkennung, die das Backend erwartet.
    /// - Returns: Textuelle Antwort der AI.
    /// - Throws: `NSError` bei Backend-Fehlern oder `URLError` bei Transportfehlern.
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
            // Try to decode error response - handle both simple string and nested object structures
            struct ServerErrorDetail: Decodable {
                let error_code: String?
                let message: String?
            }
            struct ServerError: Decodable {
                let detail: String?
                let error: ServerErrorDetail?
            }
            
            // First try to decode as nested structure
            if let err = try? JSONDecoder().decode(ServerError.self, from: data) {
                if let nestedError = err.error, let msg = nestedError.message, !msg.isEmpty {
                    Logger.error("[BackendOpenAI] Chat error: \(msg)", category: .network)
                    throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }
                if let msg = err.detail, !msg.isEmpty {
                    Logger.error("[BackendOpenAI] Chat error: \(msg)", category: .network)
                    throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }
            }
            
            // Fallback: try to decode as simple string detail
            struct SimpleServerError: Decodable { let detail: String? }
            if let err = try? JSONDecoder().decode(SimpleServerError.self, from: data),
               let msg = err.detail, !msg.isEmpty {
                Logger.error("[BackendOpenAI] Chat error: \(msg)", category: .network)
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            
            // Last resort: try to read as plain text
            if let msg = String(data: data, encoding: .utf8), !msg.isEmpty {
                Logger.error("[BackendOpenAI] Chat error (plain text): \(msg)", category: .network)
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            
            Logger.error("[BackendOpenAI] Chat failed with status \(http.statusCode), no error message available", category: .network)
            throw URLError(.badServerResponse)
        }
        
        struct Response: Decodable {
            let reply: String
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.reply
    }
    
    // MARK: - Image Analysis
    
    /// Analyze image with OpenAI Vision.
    ///
    /// - Parameters:
    ///   - imageData: Binärdaten eines Bildes (JPEG/PNG), die Base64-kodiert werden.
    ///   - userPrompt: Zusätzlicher Prompt-Kontext vom Nutzer.
    ///   - model: Modellkennung für Vision.
    /// - Returns: Textuelles Analyse-Ergebnis.
    /// - Throws: `NSError` bei Backend-Fehlern oder `URLError` bei Transportfehlern.
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
    
    // MARK: - Menu Naming Helper
    
    /// Generate a short, catchy menu name for a set of course titles.
    /// Uses the same backend `/ai/chat` proxy as normal chat.
    func generateMenuName(occasion: String?, courseTitles: [String]) async throws -> String {
        // Build a very small conversation using the existing chat endpoint
        var descriptionParts: [String] = []
        if let occ = occasion, !occ.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            descriptionParts.append("Anlass: \(occ)")
        }
        if !courseTitles.isEmpty {
            descriptionParts.append("Gänge: " + courseTitles.joined(separator: ", "))
        }
        let userText = descriptionParts.isEmpty ? "Erfinde einen kreativen Namen für ein Menü." : descriptionParts.joined(separator: " | ")
        
        let system = ChatMessage(
            role: .system,
            text: "Du bist ein kreativer Menü-Namensgenerator. Erfinde einen kurzen, schönen Titel (max. 6 Worte) für ein Menü. Gib NUR den Titel ohne Anführungszeichen zurück."
        )
        let user = ChatMessage(role: .user, text: userText)
        let reply = try await chatReply(messages: [system, user], maxHistory: 4)
        return reply.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Recipe Plan Generation
    
    /// Generate structured recipe plan.
    ///
    /// - Parameters:
    ///   - goal: Zielbeschreibung (z.B. „Abnehmen“, „Muskelaufbau“).
    ///   - timeMinutesMin: Minimale Zubereitungszeit.
    ///   - timeMinutesMax: Maximale Zubereitungszeit.
    ///   - nutrition: Nährwertgrenzen für den Plan.
    ///   - categories: Rezeptkategorien (z.B. Frühstück, Snack).
    ///   - servings: Anzahl Portionen.
    ///   - dietaryContext: Optionaler Freitext-Kontext zu Ernährungspräferenzen.
    /// - Returns: Strukturiertes `RecipePlan`-Objekt.
    /// - Throws: `NSError` bei Backend-Fehlern oder `URLError` bei Transportfehlern.
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
            // Try to decode error response - handle both simple string and nested object structures
            struct ServerErrorDetail: Decodable {
                let error_code: String?
                let message: String?
            }
            struct ServerError: Decodable {
                let detail: String?
                let error: ServerErrorDetail?
            }
            
            // First try to decode as nested structure
            if let err = try? JSONDecoder().decode(ServerError.self, from: data) {
                if let nestedError = err.error, let msg = nestedError.message, !msg.isEmpty {
                    Logger.error("[BackendOpenAI] Recipe generation error: \(msg)", category: .network)
                    throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }
                if let msg = err.detail, !msg.isEmpty {
                    Logger.error("[BackendOpenAI] Recipe generation error: \(msg)", category: .network)
                    throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }
            }
            
            // Fallback: try to decode as simple string detail
            struct SimpleServerError: Decodable { let detail: String? }
            if let err = try? JSONDecoder().decode(SimpleServerError.self, from: data),
               let msg = err.detail, !msg.isEmpty {
                Logger.error("[BackendOpenAI] Recipe generation error: \(msg)", category: .network)
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            
            // Last resort: try to read as plain text
            if let msg = String(data: data, encoding: .utf8), !msg.isEmpty {
                Logger.error("[BackendOpenAI] Recipe generation error (plain text): \(msg)", category: .network)
                throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            
            Logger.error("[BackendOpenAI] Recipe generation failed with status \(http.statusCode), no error message available", category: .network)
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(RecipePlan.self, from: data)
    }
}
