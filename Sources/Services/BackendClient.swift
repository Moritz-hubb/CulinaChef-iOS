import Foundation

/// Client für alle HTTP-Aufrufe an das CulinaAI-Backend.
///
/// - Hinweis: Diese Klasse ist bewusst schlank gehalten und enthält keine
///   Business-Logik oder Caching. Sie kapselt nur Transport, Fehlerbehandlung
///   und grundlegende Header (z.B. Sprache).
final class BackendClient {
    /// Basis-URL des Backends (z.B. `https://api.culinachef.app`).
    let baseURL: URL

    /// Initialisiert einen neuen Backend-Client.
    ///
    /// - Parameter baseURL: Root-URL des Backends ohne abschließenden Slash.
    init(baseURL: URL) { self.baseURL = baseURL }

    /// Führt einen HTTP-Request gegen das Backend aus.
    ///
    /// - Parameters:
    ///   - path: Relativer Pfad beginnend mit `/` (z.B. `/recipes`).
    ///   - method: HTTP-Methode, standardmäßig `GET`.
    ///   - token: Optionales Bearer-Token für authentifizierte Requests.
    ///   - jsonBody: Optionaler JSON-codierter Request-Body.
    /// - Returns: Antwortdaten und zugehörige `HTTPURLResponse`.
    /// - Throws: `URLError` bei Transport-/Statusfehlern oder `NSError` mit
    ///   Backend-Fehlermeldung im `NSLocalizedDescriptionKey`.
    private func request(path: String, method: String = "GET", token: String?, jsonBody: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        var url = baseURL
        url.append(path: path)
        #if DEBUG
        Logger.debug("[BackendClient] Request: \(method) \(url.absoluteString)", category: .network)
        #endif
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = token { req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body = jsonBody {
            req.httpBody = body
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        // Add Accept-Language header for backend language detection
        let preferredLanguages = Locale.preferredLanguages.prefix(3).joined(separator: ", ")
        req.addValue(preferredLanguages, forHTTPHeaderField: "Accept-Language")
        do {
            let (data, resp) = try await SecureURLSession.shared.data(for: req)
            #if DEBUG
            if let http = resp as? HTTPURLResponse {
                Logger.debug("[BackendClient] Response: \(http.statusCode) for \(url.absoluteString)", category: .network)
            }
            #endif
            guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if !(200...299).contains(http.statusCode) {
                struct ServerError: Decodable { let detail: String? }
                if let err = try? JSONDecoder().decode(ServerError.self, from: data), let msg = err.detail, !msg.isEmpty {
                    throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }
                if let msg = String(data: data, encoding: .utf8), !msg.isEmpty {
                    throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
                }
                throw URLError(.badServerResponse)
            }
            return (data, http)
        } catch {
            #if DEBUG
            Logger.error("[BackendClient] Request failed: \(method) \(url.absoluteString) - \(error.localizedDescription)", category: .network)
            #endif
            throw error
        }
    }

    /// Health-Check-Endpunkt des Backends.
    ///
    /// - Throws: Fehler aus dem zugrunde liegenden `request`-Aufruf.
    func health() async throws {
        _ = try await request(path: "/health", token: nil)
    }

    /// Liefert alle Rezepte des aktuellen Nutzers.
    ///
    /// - Parameter accessToken: Supabase-Access-Token.
    /// - Returns: Liste der Rezepte.
    func listRecipes(accessToken: String) async throws -> [Recipe] {
        let (data, _) = try await request(path: "/recipes", token: accessToken)
        return try JSONDecoder().decode([Recipe].self, from: data)
    }

    /// Lässt das Backend per AI ein Rezept aus den angegebenen Zutaten generieren.
    ///
    /// - Parameters:
    ///   - ingredients: Zutatenliste, die an die AI übergeben wird.
    ///   - accessToken: Supabase-Access-Token.
    /// - Returns: Das generierte `Recipe` vom Backend.
    func generateRecipe(ingredients: [String], accessToken: String) async throws -> Recipe {
        struct Body: Encodable {
            let ingredients: [String]
            let language: String?
        }

        // Detect device language
        let deviceLanguage: String? = {
            let langCode = Locale.current.language.languageCode?.identifier ?? "de"
            // Map to supported languages (de, en, es, fr, it)
            switch langCode {
            case "de": return "de"
            case "en": return "en"
            case "es": return "es"
            case "fr": return "fr"
            case "it": return "it"
            default: return "de"  // Default to German
            }
        }()

        let body = Body(ingredients: ingredients, language: deviceLanguage)
        let data = try JSONEncoder().encode(body)
        let (respData, _) = try await request(path: "/ai/generate_recipe", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(Recipe.self, from: respData)
    }

    /// Markiert ein Rezept als Favorit bzw. hebt die Markierung auf.
    ///
    /// - Parameters:
    ///   - recipeId: ID des Rezepts.
    ///   - accessToken: Supabase-Access-Token.
    /// - Returns: Serverantwort mit dem neuen Favoritenstatus.
    func toggleFavorite(recipeId: String, accessToken: String) async throws -> FavoriteResponse {
        struct Body: Encodable { let recipe_id: String }
        let data = try JSONEncoder().encode(Body(recipe_id: recipeId))
        let (respData, _) = try await request(path: "/favorites/toggle", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(FavoriteResponse.self, from: respData)
    }

    // Rate limiting: increment and check server-side counters
    // If originalTransactionId is provided, uses transaction-based limiting (prevents multi-account abuse)
    // If nil, uses user-based limiting (free tier)
    /// Erhöht die AI-Nutzung für den aktuellen Nutzer und liefert die Zählerstände zurück.
    ///
    /// - Parameters:
    ///   - accessToken: Supabase-Access-Token.
    ///   - originalTransactionId: Optionaler StoreKit-Original-Transaction-Identifier
    ///     zur besseren Betrugserkennung.
    /// - Returns: Aktuelle tägliche und monatliche AI-Usage-Zähler.
    func incrementAIUsage(accessToken: String, originalTransactionId: String? = nil) async throws -> (daily: Int, monthly: Int) {
        struct Body: Encodable { let original_transaction_id: String? }
        let body = Body(original_transaction_id: originalTransactionId)
        let jsonBody = try JSONEncoder().encode(body)

        let (data, _) = try await request(path: "/ai/usage/increment", method: "POST", token: accessToken, jsonBody: jsonBody)
        struct Counts: Decodable { let daily_count: Int; let monthly_count: Int }
        let c = try JSONDecoder().decode(Counts.self, from: data)
        return (c.daily_count, c.monthly_count)
    }

    /// DTO für den vom Backend gemeldeten Abo-Status.
    struct SubscriptionStatusDTO: Decodable {
        let user_id: String
        let plan: String
        let status: String
        let auto_renew: Bool
        let cancel_at_period_end: Bool
        let last_payment_at: String?
        let current_period_end: String?
        let price_cents: Int?
        let currency: String?
        let is_active: Bool
    }

    /// Liefert den Subscription-Status des Nutzers aus dem Backend.
    ///
    /// - Parameter accessToken: Supabase-Access-Token.
    /// - Returns: Aktueller Abo-Status laut Backend.
    func subscriptionStatus(accessToken: String) async throws -> SubscriptionStatusDTO {
        let (data, _) = try await request(path: "/subscription/status", token: accessToken)
        return try JSONDecoder().decode(SubscriptionStatusDTO.self, from: data)
    }

    // MARK: - Ratings

    /// DTO für eine einzelne Bewertung.
    struct RatingResponse: Decodable {
        let id: String
        let recipe_id: String
        let user_id: String
        let rating: Int
        let created_at: String
    }

    /// DTO für die aggregierten Bewertungen eines Rezepts.
    struct RecipeRatingsResponse: Decodable {
        let recipe_id: String
        let average_rating: Double
        let total_ratings: Int
        let user_rating: Int?
        let ratings: [RatingResponse]
    }

    /// Sendet eine Bewertung für ein Rezept an das Backend.
    ///
    /// - Parameters:
    ///   - recipeId: ID des bewerteten Rezepts.
    ///   - rating: Bewertungswert (z.B. 1–5).
    ///   - accessToken: Supabase-Access-Token.
    /// - Returns: Persistierte Bewertung vom Backend.
    func rateRecipe(recipeId: String, rating: Int, accessToken: String) async throws -> RatingResponse {
        struct Body: Encodable { let recipe_id: String; let rating: Int }
        let data = try JSONEncoder().encode(Body(recipe_id: recipeId, rating: rating))
        let (respData, _) = try await request(path: "/recipes/\(recipeId)/rate", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(RatingResponse.self, from: respData)
    }

    /// Lädt alle Ratings für ein bestimmtes Rezept.
    ///
    /// - Parameters:
    ///   - recipeId: ID des Rezepts.
    ///   - accessToken: Supabase-Access-Token.
    /// - Returns: Aggregierte Bewertungsinformationen.
    func getRecipeRatings(recipeId: String, accessToken: String) async throws -> RecipeRatingsResponse {
        let (data, _) = try await request(path: "/recipes/\(recipeId)/ratings", token: accessToken)
        return try JSONDecoder().decode(RecipeRatingsResponse.self, from: data)
    }

    /// Löscht die Bewertung des aktuellen Nutzers für ein Rezept.
    ///
    /// - Parameters:
    ///   - recipeId: ID des Rezepts.
    ///   - accessToken: Supabase-Access-Token.
    func deleteRating(recipeId: String, accessToken: String) async throws {
        _ = try await request(path: "/recipes/\(recipeId)/rating", method: "DELETE", token: accessToken)
    }
}
