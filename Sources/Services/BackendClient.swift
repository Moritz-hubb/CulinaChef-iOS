import CryptoKit
import Foundation

/// Shares one in-flight AI POST per request body, and reuses its idempotency key
/// if that call timed out, so a retry does not start a second billed generation.
private final class AIIdempotencyGate: @unchecked Sendable {
    static let shared = AIIdempotencyGate()

    private let lock = NSLock()
    private var tasks: [String: (key: String, task: Task<(Data, HTTPURLResponse), Error>)] = [:]
    private var retryAfterTimeout: [String: (key: String, until: Date)] = [:]

    func fingerprint(path: String, body: Data?) -> String {
        var hasher = SHA256()
        hasher.update(data: Data(path.utf8))
        hasher.update(data: [0])
        hasher.update(data: body ?? Data())
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func run(
        fingerprint: String,
        work: @escaping (String) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        let task: Task<(Data, HTTPURLResponse), Error>
        let key: String
        let created: Bool
        lock.lock()
        if let existing = tasks[fingerprint] {
            task = existing.task
            key = existing.key
            created = false
        } else {
            if let saved = retryAfterTimeout[fingerprint], saved.until > Date() {
                key = saved.key
            } else {
                key = UUID().uuidString.lowercased()
            }
            task = Task {
                try await work(key)
            }
            tasks[fingerprint] = (key, task)
            created = true
        }
        lock.unlock()

        do {
            let value = try await task.value
            if created { finish(fingerprint: fingerprint, reuseKey: nil) }
            return value
        } catch {
            if created {
                let reuse = (error as? URLError)?.code == .timedOut || error is AIRequestStillRunning
                finish(fingerprint: fingerprint, reuseKey: reuse ? key : nil)
            }
            throw error
        }
    }

    private func finish(fingerprint: String, reuseKey: String?) {
        lock.lock()
        tasks.removeValue(forKey: fingerprint)
        if let reuseKey {
            retryAfterTimeout[fingerprint] = (reuseKey, Date().addingTimeInterval(10 * 60))
        } else {
            retryAfterTimeout.removeValue(forKey: fingerprint)
        }
        lock.unlock()
    }
}

private struct AIRequestStillRunning: Error {}

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
    /// Same-module entry so the OpenAI client uses the same idempotency gate.
    func send(
        path: String,
        method: String = "GET",
        token: String?,
        jsonBody: Data? = nil,
        timeoutInterval: TimeInterval? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        try await request(
            path: path,
            method: method,
            token: token,
            jsonBody: jsonBody,
            timeoutInterval: timeoutInterval
        )
    }

    private func request(
        path: String,
        method: String = "GET",
        token: String?,
        jsonBody: Data? = nil,
        timeoutInterval: TimeInterval? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        if method == "POST", path.hasPrefix("/ai/") {
            let fingerprint = AIIdempotencyGate.shared.fingerprint(path: path, body: jsonBody)
            return try await AIIdempotencyGate.shared.run(fingerprint: fingerprint) { key in
                try await self.perform(
                    path: path,
                    method: method,
                    token: token,
                    jsonBody: jsonBody,
                    timeoutInterval: timeoutInterval,
                    idempotencyKey: key
                )
            }
        }
        return try await perform(
            path: path,
            method: method,
            token: token,
            jsonBody: jsonBody,
            timeoutInterval: timeoutInterval,
            idempotencyKey: nil
        )
    }

    private func perform(
        path: String,
        method: String,
        token: String?,
        jsonBody: Data?,
        timeoutInterval: TimeInterval?,
        idempotencyKey: String?
    ) async throws -> (Data, HTTPURLResponse) {
        var url = baseURL
        url.append(path: path)
        #if DEBUG
        Logger.debug("[BackendClient] Request: \(method) \(url.absoluteString)", category: .network)
        #endif
        var req = URLRequest(url: url)
        if let t = timeoutInterval, t > 0 {
            req.timeoutInterval = t
        }
        req.httpMethod = method
        if let token = token { req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let idempotencyKey {
            req.addValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }
        if let body = jsonBody {
            req.httpBody = body
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        // Prefer in-app language so AI replies match the selected UI language
        let appLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "de"
        req.addValue(appLanguage, forHTTPHeaderField: "Accept-Language")
        var waits = 0
        do {
            while true {
                let (data, resp) = try await SecureURLSession.shared.data(for: req)
                #if DEBUG
                if let http = resp as? HTTPURLResponse {
                    Logger.debug("[BackendClient] Response: \(http.statusCode) for \(url.absoluteString)", category: .network)
                }
                #endif
                guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                if http.statusCode == 409, idempotencyKey != nil, waits < 8 {
                    waits += 1
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    continue
                }
                if http.statusCode == 409, idempotencyKey != nil {
                    throw AIRequestStillRunning()
                }
                if !(200...299).contains(http.statusCode) {
                    #if DEBUG
                    let preview = String(data: data.prefix(900), encoding: .utf8) ?? ""
                    Logger.error(
                        "[BackendClient] HTTP \(http.statusCode) \(method) \(url.path) body preview: \(preview)",
                        category: .network
                    )
                    #endif
                    throw BackendHTTPError.make(statusCode: http.statusCode, data: data)
                }
                return (data, http)
            }
        } catch {
            Logger.error("[BackendClient] Request failed: \(method) \(url.path)", error: error, category: .network)
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

    /// Lädt ein Rezeptfoto hoch. Das Backend prüft den Inhalt und speichert ein neues JPEG.
    func uploadRecipePhoto(jpegData: Data, accessToken: String) async throws -> String {
        var url = baseURL
        url.append(path: "/recipe-photos")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 60
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        req.httpBody = jpegData
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(http.statusCode) else {
            throw BackendHTTPError.make(statusCode: http.statusCode, data: data)
        }
        struct Response: Decodable { let image_url: String }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard RecipeImageURL.isAllowed(decoded.image_url) else {
            throw URLError(.badServerResponse)
        }
        return decoded.image_url
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

        let body = Body(
            ingredients: Array(ingredients.prefix(AIInputLimit.ingredientList)).map { AIInputLimit.clamp($0, to: AIInputLimit.ingredient) },
            language: deviceLanguage
        )
        let data = try JSONEncoder().encode(body)
        let (respData, _) = try await request(path: "/ai/generate_recipe", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(Recipe.self, from: respData)
    }

    struct ReviseSourceSnapshot: Encodable {
        let title: String
        let ingredients: [String]
        let instructions: [String]
        let nutrition: Nutrition?
        let language: String?
        let cooking_time: String?
        let filter_tags: [String]?
        let servings: Int?
        let total_time_minutes: Int?
        let categories: [String]?
    }

    /// Lässt das Backend ein Rezept KI-gestützt überarbeiten.
    ///
    /// Gespeichert: `sourceRecipeId` — Ergebnis wird als neue Kopie angelegt.
    /// Ungespeichert: `sourceRecipe` + `persist: false` — nur die überarbeitete Variante, ohne Speichern.
    func reviseRecipe(
        sourceRecipeId: String? = nil,
        sourceRecipe: ReviseSourceSnapshot? = nil,
        persist: Bool? = nil,
        goals: [String],
        freeText: String?,
        language: String?,
        accessToken: String
    ) async throws -> Recipe {
        struct Body: Encodable {
            let source_recipe_id: String?
            let source_recipe: ReviseSourceSnapshot?
            let persist: Bool?
            let goals: [String]
            let free_text: String?
            let language: String?

            enum CodingKeys: String, CodingKey {
                case source_recipe_id, source_recipe, persist, goals, free_text, language
            }

            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encodeIfPresent(source_recipe_id, forKey: .source_recipe_id)
                try c.encodeIfPresent(source_recipe, forKey: .source_recipe)
                try c.encodeIfPresent(persist, forKey: .persist)
                try c.encode(goals, forKey: .goals)
                try c.encodeIfPresent(free_text, forKey: .free_text)
                try c.encodeIfPresent(language, forKey: .language)
            }
        }
        let body = Body(
            source_recipe_id: sourceRecipeId,
            source_recipe: sourceRecipe,
            persist: persist,
            goals: goals,
            free_text: freeText.map { AIInputLimit.clamp($0, to: AIInputLimit.freeText) },
            language: language
        )
        let data = try JSONEncoder().encode(body)
        let (respData, _) = try await request(path: "/ai/revise_recipe", method: "POST", token: accessToken, jsonBody: data)
        return try JSONDecoder().decode(Recipe.self, from: respData)
    }

    /// Reads current daily/monthly AI usage. Does **not** increment counters.
    /// Server-side counting and subscription checks happen on the real `/ai/*` routes.
    /// Transient failures return `(0, 0)` so a downed status endpoint cannot block those routes.
    /// Auth and subscription denials still throw.
    func incrementAIUsage(accessToken: String, originalTransactionId: String? = nil) async throws -> (daily: Int, monthly: Int) {
        struct Body: Encodable { let original_transaction_id: String? }
        let body = Body(original_transaction_id: originalTransactionId)
        let jsonBody = try JSONEncoder().encode(body)

        do {
            let (data, _) = try await request(path: "/ai/usage/increment", method: "POST", token: accessToken, jsonBody: jsonBody)
            let c = try JSONDecoder().decode(AIUsageIncrementCounts.self, from: data)
            return (c.daily_count, c.monthly_count)
        } catch {
            if BackendHTTPError.isSubscriptionRequired(error) { throw error }
            let ns = error as NSError
            if ns.domain == "Backend", (500...599).contains(ns.code) {
                Logger.error("[BackendClient] AI usage fetch failed (\(ns.code)), continuing", category: .network)
                return (0, 0)
            }
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotFindHost, .cannotConnectToHost, .timedOut, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed:
                    Logger.info("[BackendClient] Backend unreachable for AI usage, continuing", category: .network)
                    return (0, 0)
                default:
                    break
                }
            }
            throw error
        }
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

    // MARK: - Social import (URL → Metadaten + KI → gespeichertes Rezept)

    /// Importiert ein Rezept aus einem Social-Media-Link (Backend).
    /// - Parameter recipeLanguage: App-Sprache (`de`/`en`/…) — Rezeptausgabe der KI, unabhängig von der Sprache der Metadaten.
    func importRecipeFromSocialURL(
        url: String,
        recipeLanguage: String,
        dietaryContext: String?,
        recipeTweaks: [String]?,
        tweakText: String?,
        extraText: String?,
        accessToken: String
    ) async throws -> Recipe {
        struct Body: Encodable {
            let url: String
            let extra_text: String?
            let language: String?
            let dietary_context: String?
            let recipe_tweaks: [String]?
            let tweak_text: String?
        }
        let lang: String = {
            switch recipeLanguage.lowercased() {
            case "de", "en", "es", "fr", "it": return recipeLanguage.lowercased()
            default: return "de"
            }
        }()
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SocialImportURL.isAllowed(trimmedURL) else {
            throw URLError(.badURL)
        }
        let trimmedTweakText = tweakText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExtra = extraText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cappedExtra = trimmedExtra.map { AIInputLimit.clamp($0, to: AIInputLimit.socialExtra) }
        let body = Body(
            url: trimmedURL,
            extra_text: (cappedExtra?.isEmpty == true) ? nil : cappedExtra,
            language: lang,
            dietary_context: dietaryContext.map { AIInputLimit.clamp($0, to: AIInputLimit.dietaryContext) },
            recipe_tweaks: recipeTweaks?.isEmpty == true ? nil : recipeTweaks,
            tweak_text: (trimmedTweakText?.isEmpty == true) ? nil : trimmedTweakText.map { AIInputLimit.clamp($0, to: AIInputLimit.freeText) }
        )
        #if DEBUG
        Logger.debug(
            "[SocialImport] importRecipeFromSocialURL start url=\(trimmedURL.prefix(160)) lang=\(lang)",
            category: .network
        )
        #endif
        let data = try JSONEncoder().encode(body)
        let (respData, httpResponse) = try await request(
            path: "/ai/import-from-social-url",
            method: "POST",
            token: accessToken,
            jsonBody: data,
            timeoutInterval: Config.socialImportAPITimeout
        )
        #if DEBUG
        Logger.debug(
            "[SocialImport] import HTTP status=\(httpResponse.statusCode) bytes=\(respData.count)",
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
            Logger.error(
                "[SocialImport] import decode FAILED status=\(httpResponse.statusCode) bytes=\(respData.count)",
                category: .network
            )
            #if DEBUG
            Logger.error(
                "[SocialImport] import decode detail: \(String(describing: error))",
                category: .network
            )
            if let decodingError = error as? DecodingError {
                Logger.error(
                    "[SocialImport] import DecodingError: \(culinachefDecodingErrorDescription(decodingError))",
                    category: .network
                )
            }
            let bodyPrefix = String(data: respData.prefix(2500), encoding: .utf8) ?? ""
            Logger.error(
                "[SocialImport] import response body prefix: \(bodyPrefix.prefix(1200))",
                category: .network
            )
            #endif
            throw error
        }
    }

    /// Lädt nur Metadaten (Titel/Beschreibung/Creator) für einen Social-Link – ohne KI.
    func previewSocialMetadata(url: String, accessToken: String) async throws -> SocialMetadataPreview {
        struct Body: Encodable {
            let url: String
        }
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SocialImportURL.isAllowed(trimmedURL) else {
            throw URLError(.badURL)
        }
        #if DEBUG
        Logger.debug("[SocialImport] previewSocialMetadata start url=\(trimmedURL.prefix(160))", category: .network)
        #endif
        let data = try JSONEncoder().encode(Body(url: trimmedURL))
        let (respData, _) = try await request(
            path: "/ai/preview-social-metadata",
            method: "POST",
            token: accessToken,
            jsonBody: data,
            timeoutInterval: Config.socialImportAPITimeout
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
