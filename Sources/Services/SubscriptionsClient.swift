import Foundation

/// Datenmodell einer Subscription-Zeile aus der Supabase-Tabelle `subscriptions`.
struct SubscriptionRow: Codable {
    let userId: String
    let plan: String
    let status: String
    let autoRenew: Bool
    let cancelAtPeriodEnd: Bool
    let lastPaymentAt: Date?
    let currentPeriodEnd: Date?
    let priceCents: Int?
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case plan
        case status
        case autoRenew = "auto_renew"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case lastPaymentAt = "last_payment_at"
        case currentPeriodEnd = "current_period_end"
        case priceCents = "price_cents"
        case currency
    }
}

/// Parameter für Subscription-Upsert.
struct SubscriptionUpsertParams {
    let userId: String
    let plan: String
    let status: String
    let autoRenew: Bool
    let cancelAtPeriodEnd: Bool
    let lastPaymentAt: Date
    let currentPeriodEnd: Date
    let priceCents: Int
    let currency: String
}

/// Client für lesende und schreibende Zugriffe auf die `subscriptions`-Tabelle via Supabase REST.
final class SubscriptionsClient {
    private let baseURL: URL
    private let apiKey: String

    /// Initialisiert einen neuen Client für Subscription-Zugriffe.
    ///
    /// - Parameters:
    ///   - baseURL: Supabase-Basis-URL.
    ///   - apiKey: API-Key für den REST-Zugriff.
    init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    /// Lädt die Subscription-Zeile für einen bestimmten Nutzer.
    ///
    /// - Parameters:
    ///   - userId: Supabase-User-ID.
    ///   - accessToken: Access-Token des Nutzers.
    /// - Returns: Gefundene Subscription oder `nil`, falls keine vorhanden ist.
    /// - Throws: `NSError` bei HTTP-Fehlern ungleich 200/404 oder `URLError` bei Transportfehlern.
    func fetchSubscription(userId: String, accessToken: String) async throws -> SubscriptionRow? {
        var url = baseURL
        url.append(path: "/rest/v1/subscriptions")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*")
        ])
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 200 {
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            let rows = try dec.decode([SubscriptionRow].self, from: data)
            return rows.first
        } else if http.statusCode == 404 {
            return nil
        } else {
            throw NSError(domain: "SubscriptionsClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Subscription fetch failed"])
        }
    }

    /// Legt eine Subscription an oder aktualisiert eine bestehende Zeile per Upsert.
    ///
    /// - Parameters:
    ///   - params: Parameter für den Upsert.
    ///   - accessToken: Access-Token des Nutzers.
    /// - Throws: `NSError` mit Fehlermessage aus der REST-API oder `URLError` bei Transportfehlern.
    func upsertSubscription(params: SubscriptionUpsertParams, accessToken: String) async throws {
        var url = baseURL
        url.append(path: "/rest/v1/subscriptions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(apiKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")

        let enc = ISO8601DateFormatter()
        let body: [[String: Any]] = [[
            "user_id": params.userId,
            "plan": params.plan,
            "status": params.status,
            "auto_renew": params.autoRenew,
            "cancel_at_period_end": params.cancelAtPeriodEnd,
            "last_payment_at": enc.string(from: params.lastPaymentAt),
            "current_period_end": enc.string(from: params.currentPeriodEnd),
            "price_cents": params.priceCents,
            "currency": params.currency
        ]]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            throw NSError(domain: "SubscriptionsClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Subscription upsert failed: \(msg)"])
        }
    }
}
