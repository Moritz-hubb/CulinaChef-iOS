import Foundation

/// Antwort von `POST /ai/preview-social-metadata` (nur Metadaten, keine KI).
/// Wird optional als `metadata_snapshot` beim Import mitgeschickt (gleiche Daten, kein zweiter Fetch).
struct SocialMetadataPreview: Codable {
    let url: String
    let platform: String
    let title: String?
    let description: String?
    let author_name: String?
    let raw_snippet: String?
}

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
        print("🌐 [DEBUG] Backend Request: \(method) \(url.absoluteString)") // Direct print for visibility
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
            #if DEBUG
            let preview = String(data: data.prefix(900), encoding: .utf8) ?? ""
            Logger.error(
                "[BackendClient] HTTP \(http.statusCode) \(method) \(url.path) body preview: \(preview)",
                category: .network
            )
            #endif
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
            Logger.error("[BackendClient] Request failed: \(method) \(url.absoluteString) - \(error.localizedDescription)", category: .network)
            if let urlError = error as? URLError {
                Logger.error("[BackendClient] URLError code: \(urlError.code.rawValue) (\(urlError.code)), description: \(urlError.localizedDescription)", category: .network)
            } else if let nsError = error as NSError? {
                Logger.error("[BackendClient] NSError domain: \(nsError.domain), code: \(nsError.code)", category: .network)
            }
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

    /// Lässt das Backend ein bestehendes Rezept KI-gestützt überarbeiten und als **neue** Kopie speichern.
    ///
    /// - Parameters:
    ///   - sourceRecipeId: UUID des Ausgangsrezepts (eigenes oder öffentliches Community-Rezept).
    ///   - goals: Kurze Ziele (z. B. vegan, glutenfrei); leer erlaubt nur mit `freeText`.
    ///   - freeText: Optionaler Freitext (max. 500 Zeichen serverseitig).
    ///   - language: Ausgabesprache (`de`, `en`, …); nil = Gerät/App-Logik.
    func reviseRecipe(
        sourceRecipeId: String,
        goals: [String],
        freeText: String?,
        language: String?,
        accessToken: String
    ) async throws -> Recipe {
        struct Body: Encodable {
            let source_recipe_id: String
            let goals: [String]
            let free_text: String?
            let language: String?
        }
        let body = Body(
            source_recipe_id: sourceRecipeId,
            goals: goals,
            free_text: freeText,
            language: language
        )
        let data = try JSONEncoder().encode(body)
        let (respData, _) = try await request(path: "/ai/revise_recipe", method: "POST", token: accessToken, jsonBody: data)
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
        let c = try JSONDecoder().decode(AIUsageIncrementCounts.self, from: data)
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
    
    /// DTO für Bewertungsstatistiken eines einzelnen Rezepts (für Batch-Requests).
    struct RecipeRatingStats: Decodable {
        let recipe_id: String
        let average_rating: Double?
        let total_ratings: Int
    }
    
    /// DTO für Batch-Ratings-Response.
    struct BatchRatingsResponse: Decodable {
        let ratings: [RecipeRatingStats]
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
    
    /// Lädt Bewertungsstatistiken für mehrere Rezepte auf einmal (Batch-Request).
    /// Optimiert für Performance beim Laden von Rezeptlisten.
    ///
    /// - Parameters:
    ///   - recipeIds: Liste der Rezept-IDs (max 100).
    ///   - accessToken: Supabase-Access-Token.
    /// - Returns: Bewertungsstatistiken für alle angeforderten Rezepte.
    func getBatchRatings(recipeIds: [String], accessToken: String) async throws -> BatchRatingsResponse {
        struct Body: Encodable {
            let recipe_ids: [String]
        }
        let data = try JSONEncoder().encode(Body(recipe_ids: recipeIds))
        let (respData, _) = try await request(path: "/recipes/ratings/batch", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(BatchRatingsResponse.self, from: respData)
    }

    // MARK: - Social import (URL → Metadaten + KI → gespeichertes Rezept)

    /// Importiert ein Rezept aus einem Social-Media-Link (Backend).
    func importRecipeFromSocialURL(
        url: String,
        extraText: String?,
        dietaryContext: String?,
        accessToken: String,
        prefetchedTitle: String? = nil,
        prefetchedDescription: String? = nil,
        prefetchedAuthor: String? = nil,
        metadataSnapshot: SocialMetadataPreview? = nil
    ) async throws -> Recipe {
        struct MetadataSnapshotPayload: Encodable {
            let url: String
            let platform: String
            let title: String?
            let description: String?
            let author_name: String?
            let raw_snippet: String?
        }
        struct Body: Encodable {
            let url: String
            let extra_text: String?
            let language: String?
            let dietary_context: String?
            let prefetched_title: String?
            let prefetched_description: String?
            let prefetched_author: String?
            let metadata_snapshot: MetadataSnapshotPayload?
        }
        let langCode: String = {
            let lang = Locale.current.language.languageCode?.identifier ?? "de"
            switch lang {
            case "de", "en", "es", "fr", "it": return lang
            default: return "de"
            }
        }()
        let snapshotPayload: MetadataSnapshotPayload? = metadataSnapshot.map {
            MetadataSnapshotPayload(
                url: $0.url,
                platform: $0.platform,
                title: $0.title,
                description: $0.description,
                author_name: $0.author_name,
                raw_snippet: $0.raw_snippet
            )
        }
        let body = Body(
            url: url,
            extra_text: extraText,
            language: langCode,
            dietary_context: dietaryContext,
            prefetched_title: prefetchedTitle,
            prefetched_description: prefetchedDescription,
            prefetched_author: prefetchedAuthor,
            metadata_snapshot: snapshotPayload
        )
        #if DEBUG
        Logger.debug(
            "[SocialImport] importRecipeFromSocialURL start url=\(url.prefix(160)) extra=\(extraText != nil) metadata_snapshot=\(metadataSnapshot != nil)",
            category: .network
        )
        #endif
        let data = try JSONEncoder().encode(body)
        let (respData, httpResponse) = try await request(
            path: "/ai/import-from-social-url",
            method: "POST",
            token: accessToken,
            jsonBody: data
        )
        #if DEBUG
        Logger.debug(
            "[SocialImport] import HTTP status=\(httpResponse.statusCode) bytes=\(respData.count) snapshot_sent=\(metadataSnapshot != nil)",
            category: .network
        )
        #endif
        struct Resp: Decodable {
            let recipe: Recipe
        }
        do {
            let recipe = try JSONDecoder().decode(Resp.self, from: respData).recipe
            #if DEBUG
            Logger.debug("[SocialImport] importRecipeFromSocialURL ok recipeId=\(recipe.id)", category: .network)
            #endif
            return recipe
        } catch {
            let bodyPrefix = String(data: respData.prefix(2500), encoding: .utf8) ?? ""
            Logger.error(
                "[SocialImport] import decode FAILED status=\(httpResponse.statusCode) bytes=\(respData.count) describing=\(String(describing: error))",
                category: .network
            )
            if let decodingError = error as? DecodingError {
                Logger.error(
                    "[SocialImport] import DecodingError: \(culinachefDecodingErrorDescription(decodingError))",
                    category: .network
                )
            }
            Logger.error(
                "[SocialImport] import response body prefix: \(bodyPrefix.prefix(1200))",
                category: .network
            )
            throw error
        }
    }

    /// Lädt nur Metadaten (Titel/Beschreibung/Creator) für einen Social-Link – ohne KI.
    func previewSocialMetadata(url: String, accessToken: String) async throws -> SocialMetadataPreview {
        struct Body: Encodable {
            let url: String
        }
        #if DEBUG
        Logger.debug("[SocialImport] previewSocialMetadata start url=\(url.prefix(160))", category: .network)
        #endif
        let data = try JSONEncoder().encode(Body(url: url))
        let (respData, _) = try await request(
            path: "/ai/preview-social-metadata",
            method: "POST",
            token: accessToken,
            jsonBody: data
        )
        let decoded = try JSONDecoder().decode(SocialMetadataPreview.self, from: respData)
        #if DEBUG
        Logger.debug(
            "[SocialImport] previewSocialMetadata ok platform=\(decoded.platform) title_len=\(decoded.title?.count ?? 0) desc_len=\(decoded.description?.count ?? 0) author=\(decoded.author_name ?? "nil")",
            category: .network
        )
        #endif
        return decoded
    }
}

/// Antwort von `POST /ai/usage/increment` — tolerant gegen fehlende Keys oder Zahl-Typen im JSON.
private struct AIUsageIncrementCounts: Decodable {
    let daily_count: Int
    let monthly_count: Int

    enum CodingKeys: String, CodingKey {
        case daily_count
        case monthly_count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        daily_count = Self.decodeIntLenient(container, key: .daily_count)
        monthly_count = Self.decodeIntLenient(container, key: .monthly_count)
    }

    private static func decodeIntLenient(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int {
        if let v = try? container.decode(Int.self, forKey: key) { return v }
        if let v = try? container.decode(Double.self, forKey: key) { return Int(v.rounded()) }
        if let s = try? container.decode(String.self, forKey: key) {
            if let i = Int(s) { return i }
            if let d = Double(s) { return Int(d.rounded()) }
        }
        return 0
    }
}

/// Hilfsausgabe für Social-Import-Decode-Fehler (Konsole / Gerätelog).
private func culinachefDecodingErrorDescription(_ error: DecodingError) -> String {
    switch error {
    case let .keyNotFound(key, context):
        return "keyNotFound(key=\(key.stringValue), \(context.debugDescription)"
    case let .typeMismatch(type, context):
        return "typeMismatch(type=\(String(describing: type)), \(context.debugDescription)"
    case let .valueNotFound(type, context):
        return "valueNotFound(type=\(String(describing: type)), \(context.debugDescription)"
    case let .dataCorrupted(context):
        return "dataCorrupted(\(context.debugDescription)"
    @unknown default:
        return String(describing: error)
    }
}
