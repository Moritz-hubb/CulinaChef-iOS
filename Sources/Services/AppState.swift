import Foundation
import Network
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

struct DietaryPreferences: Codable {
    var diets: Set<String> = []
    var allergies: [String] = []
    var dislikes: [String] = []
    var notes: String? = nil
}

extension DietaryPreferences {
    static let storageKey = "dietary_preferences"
    static func load() -> DietaryPreferences {
        let d = UserDefaults.standard
        if let data = d.data(forKey: storageKey),
           let obj = try? JSONDecoder().decode(DietaryPreferences.self, from: data) {
            return obj
        }
        return DietaryPreferences()
    }
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var loading: Bool = false
    @Published var error: String?
    @Published var accessToken: String?
    @Published var userEmail: String?

    // Subscription state (simulated, prepared for StoreKit)
    @Published var isSubscribed: Bool = false
    private static let subscriptionKeyPrefix = "subscription_active_" // legacy
    private static let subscriptionLastPaymentKeyPrefix = "subscription_last_payment_"
    private static let subscriptionPeriodEndKeyPrefix = "subscription_period_end_"
    private static let subscriptionAutoRenewKeyPrefix = "subscription_autorenew_"

    // Tab selection for programmatic navigation
    @Published var selectedTab: Int = 0
    
    // Recipe goal from chat navigation
    @Published var pendingRecipeGoal: String? = nil
    @Published var pendingRecipeDescription: String? = nil
    
    // Hidden intent summary from last user recipe query (e.g. "vegan, glutenfrei")
    @Published var intentSummary: String? = nil

    // Broadcast last created menu so views can update immediately
    @Published var lastCreatedMenu: Menu? = nil
    // Broadcast last created recipe and its menu (if any) so lists update immediately
    @Published var lastCreatedRecipe: Recipe? = nil
    @Published var lastCreatedRecipeMenuId: String? = nil

    // When creating a recipe from a suggestion, automatically assign to this menu (if set)
    @Published var pendingTargetMenuId: String? = nil
    // If set, remove this suggestion name from the menu's placeholders after saving
    @Published var pendingSuggestionNameToRemove: String? = nil
    // After creating a menu, highlight/select it in Meine Rezepte
    @Published var pendingSelectMenuId: String? = nil

    // User dietary preferences (persisted)
    // Start with empty, will be loaded from Supabase (or UserDefaults as fallback)
    @Published var dietary: DietaryPreferences = DietaryPreferences() {
        didSet { dietary.save() }
    }
    
    // Recipe selected for community upload (for upload sheet)
    @Published var selectedRecipeForUpload: Recipe? = nil
    
    // Deep link recipe navigation
    @Published var deepLinkRecipe: Recipe? = nil

    private(set) var backend: BackendClient!
    private(set) var openAI: OpenAIClient?
    private(set) var recipeAI: OpenAIClient?
    private(set) var auth: SupabaseAuthClient!
    private(set) var preferencesClient: UserPreferencesClient!
    private(set) var subscriptionsClient: SubscriptionsClient!
    private(set) var storeKit: StoreKitManager!
    
    // Shopping list manager (shared across views)
    private(set) var shoppingListManager: ShoppingListManager!
    
    // Liked recipes manager (local storage, no DB)
    private(set) var likedRecipesManager: LikedRecipesManager!

    // Offline delete queue
    private let deleteQueueKey = "delete_queue_recipe_ids"
    private var deleteQueue: [String] {
        get { (UserDefaults.standard.stringArray(forKey: deleteQueueKey) ?? []) }
        set { UserDefaults.standard.set(newValue, forKey: deleteQueueKey) }
    }
    private var pathMonitor: NWPathMonitor?

    // Subscription polling
    private var subscriptionTimer: Timer?
    private var aggressiveTimer: Timer?
    private var aggressiveUntil: Date?

    init() {
        backend = BackendClient(baseURL: Config.backendBaseURL)
        openAI = OpenAIClient(apiKey: Secrets.openAIAPIKey())
        recipeAI = OpenAIClient(apiKey: Secrets.openAIAPIKey())
        auth = SupabaseAuthClient(baseURL: Config.supabaseURL, apiKey: Config.supabaseAnonKey)
        preferencesClient = UserPreferencesClient(baseURL: Config.supabaseURL, apiKey: Config.supabaseAnonKey)
        subscriptionsClient = SubscriptionsClient(baseURL: Config.supabaseURL, apiKey: Config.supabaseAnonKey)
        storeKit = StoreKitManager()
        shoppingListManager = ShoppingListManager()
        likedRecipesManager = LikedRecipesManager()
        
        // Prime StoreKit
        Task { [weak self] in
            guard let self else { return }
            await self.storeKit.loadProducts()
            await self.refreshSubscriptionFromEntitlements()
            // Listen for transaction updates
            for await result in Transaction.updates {
                if case .verified(let transaction) = result, transaction.productID == StoreKitManager.monthlyProductId {
                    await self.refreshSubscriptionFromEntitlements()
                }
            }
        }
        
        // Network reachability monitor for flushing offline queue
        let monitor = NWPathMonitor()
        self.pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied {
                Task { await self.flushDeletionQueue() }
            }
        }
        let queue = DispatchQueue(label: "net.monitor")
        monitor.start(queue: queue)
        
        // Migrate old UserDefaults subscription data to Keychain (one-time)
        migrateSubscriptionDataToKeychain()
        
        // Check for existing session
        checkSession()
        // Load subscription status for current user (if any)
        loadSubscriptionStatus()
        // Start polling in foreground
        startSubscriptionPolling()
        // Load preferences from Supabase on startup (takes priority over UserDefaults)
        // MUST run after checkSession() has set accessToken
        Task { [weak self] in
            guard let self else { return }
            // Small delay to ensure checkSession() has completed
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec
            do {
                try await self.loadPreferencesFromSupabase()
            } catch {
                // Fallback to UserDefaults if Supabase load fails (e.g., offline)
                print("[AppState] Failed to load preferences from Supabase: \(error.localizedDescription). Using local cache.")
                await MainActor.run {
                    self.dietary = DietaryPreferences.load()
                }
            }
        }
        // Observe app lifecycle for resume/suspend refresh
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        #endif
        // Try to flush any queued deletions on startup
        Task { await flushDeletionQueue() }
    }

    deinit {
        // Inline cleanup to avoid calling actor-isolated methods from nonisolated deinit
        subscriptionTimer?.invalidate(); subscriptionTimer = nil
        aggressiveTimer?.invalidate(); aggressiveTimer = nil
        aggressiveUntil = nil
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(self)
        #endif
    }
    
    private func checkSession() {
        if let token = KeychainManager.get(key: "access_token"),
           let email = KeychainManager.get(key: "user_email") {
            self.accessToken = token
            self.userEmail = email
            self.isAuthenticated = true
            
            // Try to refresh token immediately on startup to ensure session is valid
            Task { [weak self] in
                await self?.refreshSessionIfNeeded()
            }
        }
    }
    
    // MARK: - Token Refresh
    func refreshSessionIfNeeded() async {
        guard let refreshToken = KeychainManager.get(key: "refresh_token") else {
            Logger.info("No refresh token found, logging out", category: .auth)
            await signOut()
            return
        }
        
        do {
            Logger.info("Refreshing session with refresh token", category: .auth)
            let response = try await auth.refreshSession(refreshToken: refreshToken)
            
            // Update stored tokens
            try KeychainManager.save(key: "access_token", value: response.access_token)
            try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
            try KeychainManager.save(key: "user_id", value: response.user.id)
            try KeychainManager.save(key: "user_email", value: response.user.email)
            
            await MainActor.run {
                self.accessToken = response.access_token
                self.userEmail = response.user.email
                self.isAuthenticated = true
                Logger.info("Session refreshed successfully", category: .auth)
            }
        } catch {
            Logger.error("Token refresh failed", error: error, category: .auth)
            // Token refresh failed - user needs to log in again
            await signOut()
        }
    }

    func refreshOpenAI() {
        openAI = OpenAIClient(apiKey: Secrets.openAIAPIKey())
    }

    func refreshRecipeAI() {
        recipeAI = OpenAIClient(apiKey: Secrets.openAIAPIKey())
    }

    func dietarySystemPrompt() -> String {
        var strictParts: [String] = []  // Allergien & Ernährungsweisen - IMMER beachten
        var preferencesParts: [String] = []  // Geschmack - nur als Vorschlag
        
        // STRIKTE Anforderungen (Allergien & Ernährungsweisen)
        if !dietary.diets.isEmpty {
            strictParts.append("Ernährungsweisen: " + dietary.diets.sorted().joined(separator: ", "))
        }
        if !dietary.allergies.isEmpty {
            strictParts.append("Allergien/Unverträglichkeiten (IMMER vermeiden): " + dietary.allergies.joined(separator: ", "))
        }
        if !dietary.dislikes.isEmpty {
            strictParts.append("Bitte meiden: " + dietary.dislikes.joined(separator: ", "))
        }
        
        // OPTIONALE Geschmackspräferenzen
        if let data = UserDefaults.standard.data(forKey: "taste_preferences"),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let spicyLevel = dict["spicy_level"] as? Double ?? 2
            let spicyLabels = ["Mild", "Normal", "Scharf", "Sehr Scharf"]
            preferencesParts.append("Schärfe-Präferenz: " + spicyLabels[Int(spicyLevel)])
            
            var tastes: [String] = []
            if dict["sweet"] as? Bool == true { tastes.append("süß") }
            if dict["sour"] as? Bool == true { tastes.append("sauer") }
            if dict["bitter"] as? Bool == true { tastes.append("bitter") }
            if dict["umami"] as? Bool == true { tastes.append("umami") }
            if !tastes.isEmpty {
                preferencesParts.append("Bevorzugte Geschmacksrichtungen: " + tastes.joined(separator: ", "))
            }
        }
        
        if let notes = dietary.notes, !notes.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            strictParts.append("Hinweise: " + notes)
        }
        
        var result: [String] = []
        if !strictParts.isEmpty {
            result.append("STRIKTE Anforderungen (IMMER beachten): " + strictParts.joined(separator: " | "))
        }
        if !preferencesParts.isEmpty {
            result.append("Geschmackspräferenzen (nur wenn sinnvoll anwenden, NICHT zwingend in jedes Rezept einbauen): " + preferencesParts.joined(separator: " | "))
        }
        
        if result.isEmpty { return "" }
        return result.joined(separator: "\n")
    }

    func languageSystemPrompt() -> String {
        let code = currentLanguageCode()
        switch code {
        case "en": return "Respond exclusively in English."
        case "es": return "Responde exclusivamente en español."
        case "fr": return "Réponds exclusivement en français."
        case "it": return "Rispondi esclusivamente in italiano."
        default: return "Antworte ausschließlich auf Deutsch."
        }
    }

    /// Returns the current app language code used for AI responses (e.g. "de", "en").
    func currentLanguageCode() -> String {
        (UserDefaults.standard.string(forKey: "app_language") ?? "de").lowercased()
    }

    /// Returns a short tag that encodes the recipe language, to be attached to recipe tags.
    /// Example outputs: "DE", "EN", "ES", "FR", "IT".
    func recipeLanguageTag() -> String {
        switch currentLanguageCode() {
        case "en": return "EN"
        case "es": return "ES"
        case "fr": return "FR"
        case "it": return "IT"
        default: return "DE"
        }
    }

    func systemContext() -> String {
        let diet = dietarySystemPrompt()
        let lang = languageSystemPrompt()
        return [diet, lang].filter { !$0.isEmpty }.joined(separator: "\n")
    }

    // Hidden user-intent context, not shown in UI, appended to generation prompts
    func hiddenIntentContext() -> String {
        guard let s = intentSummary?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return "" }
        return "⟦intent: " + s + "⟧"
    }
    
    func chatSystemContext() -> String {
        let base = systemContext()
        let chatPrompt = """
DOMAIN: Küche/Kochen. Behandle ALLE Anfragen, die plausibel damit zusammenhängen, als relevant. Dazu zählen u. a.:
- Kochen, Backen, Grillen, Zubereitung, Techniken, Garzeiten/Temperaturen
- Zutaten, Ersatzprodukte, Einkauf/Bezugsquellen (online/offline), Lagerung, Haltbarkeit, Hygiene
- Küchenwerkzeuge/-geräte, Töpfe/Pfannen/Ofen/Grill, Messmethoden
- Speiseplanung, Menüs, Diäten/Ernährung, Nährwerte/Allergene, Portionierung
- Beziehe stets den bisherigen Gesprächskontext mit ein, um Folgefragen korrekt einzuordnen.

Nur wenn eine Anfrage EINDUTIG fachfremd ist (z. B. Wetter, Politik, Programmierung, Finanzen, Reisen, Sport, Film/Serie etc.), antworte GENAU mit:
"Ich kann dir damit leider nicht helfen. Ich kann dir aber gerne deine Fragen übers Kochen beantworten."
und schreibe sonst nichts weiter.

WICHTIG: Wenn nach Rezepten oder Rezeptideen gefragt wird, gib NUR kurze Rezeptvorschläge (Name + 1-2 Sätze Beschreibung).
Gib KEINE kompletten Rezepte mit Zutaten und Anleitungen.

Formatiere Rezeptvorschläge so:
🍴 **[Rezeptname]** ⟦course: [Vorspeise|Zwischengang|Hauptspeise|Nachspeise|Beilage|Getränk|Amuse-Bouche|Aperitif|Digestif|Käsegang]⟧
[Kurze Beschreibung]

Regel: Füge IMMER das unsichtbare Kurs-Label in der Form "⟦course: …⟧" hinzu (nach dem Titel oder am Ende der Zeile). Das UI zeigt diesen Tag nicht an, nutzt ihn aber zur Kategorisierung.

KLASSIFIZIERUNG (für das UI):
- Wenn du ein zusammenhängendes Menü mit Gängen (z. B. Vorspeise/Hauptspeise/Nachspeise) vorschlägst, schreibe GANZ AM ENDE (neue Zeile) GENAU EINEN Marker: "⟦kind: menu⟧".
- Wenn es nur lose Rezeptideen sind, schreibe stattdessen: "⟦kind: ideas⟧".
- Schreibe keinen weiteren Text nach diesem Marker.

Beispiel:
🍴 **Cremige Tomaten-Pasta mit Basilikum** ⟦course: Hauptspeise⟧
Eine schnelle, cremige Pasta mit frischen Tomaten, Knoblauch und Basilikum. Perfekt für einen gemütlichen Abend.
⟦kind: ideas⟧
"""
        return [base, chatPrompt].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    func signIn(email: String, password: String) async throws {
        loading = true
        defer { loading = false }
        
        let response = try await auth.signIn(email: email, password: password)
        
        try KeychainManager.save(key: "access_token", value: response.access_token)
        try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
        try KeychainManager.save(key: "user_id", value: response.user.id)
        try KeychainManager.save(key: "user_email", value: response.user.email)
        
        // Load onboarding status from backend
        await loadOnboardingStatusFromBackend(userId: response.user.id, accessToken: response.access_token)
        
        await MainActor.run {
            self.accessToken = response.access_token
            self.userEmail = response.user.email
            self.isAuthenticated = true
            self.loadSubscriptionStatus()
        }
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        loading = true
        defer { loading = false }
        
        // Require non-empty username at app level
        let uname = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uname.isEmpty else {
            throw NSError(domain: "SignUp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bitte Benutzernamen angeben"])
        }
        
        let response = try await auth.signUp(email: email, password: password, username: uname)
        
        try KeychainManager.save(key: "access_token", value: response.access_token)
        try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
        try KeychainManager.save(key: "user_id", value: response.user.id)
        try KeychainManager.save(key: "user_email", value: response.user.email)
        
        // Create/Upsert profile with unique username
        try await upsertProfile(userId: response.user.id, username: uname, accessToken: response.access_token)
        
        await MainActor.run {
            self.accessToken = response.access_token
            self.userEmail = response.user.email
            self.isAuthenticated = true
            self.loadSubscriptionStatus()
        }
    }

    private func upsertProfile(userId: String, username: String, accessToken: String, fullName: String? = nil, email: String? = nil) async throws {
        struct Row: Encodable { let user_id: String; let username: String; let full_name: String?; let email: String? }
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/profiles")
        url.append(queryItems: [URLQueryItem(name: "on_conflict", value: "user_id")])
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.addValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode([Row(user_id: userId, username: username, full_name: fullName, email: email)])
        let (_, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "Profiles", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Profil konnte nicht gespeichert werden"])
        }
    }

    // Public API for settings sheet: load & save profile
    struct ProfileRow: Codable { let user_id: String; let username: String; let full_name: String?; let email: String? }

    func fetchProfile() async throws -> ProfileRow? {
        guard let token = accessToken, let userId = KeychainManager.get(key: "user_id") else { return nil }
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/profiles")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "user_id,username,full_name,email"),
            URLQueryItem(name: "limit", value: "1")
        ])
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
        let rows = try JSONDecoder().decode([ProfileRow].self, from: data)
        return rows.first
    }

    func saveProfile(fullName: String?, email: String?) async throws {
        guard let token = accessToken, let userId = KeychainManager.get(key: "user_id") else {
            throw NSError(domain: "Profiles", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        // Keep existing username (required) or fallback to email prefix
        let current = try await fetchProfile()
        let uname = current?.username ?? (userEmail?.split(separator: "@").first.map(String.init) ?? "user")
        try await upsertProfile(userId: userId, username: uname, accessToken: token, fullName: fullName?.nilIfBlank(), email: email?.nilIfBlank())
    }
    
    func signInWithApple(idToken: String, nonce: String?) async throws {
        loading = true
        defer { loading = false }
        let response = try await auth.signInWithApple(idToken: idToken, nonce: nonce)
        try KeychainManager.save(key: "access_token", value: response.access_token)
        try KeychainManager.save(key: "refresh_token", value: response.refresh_token)
        try KeychainManager.save(key: "user_id", value: response.user.id)
        try KeychainManager.save(key: "user_email", value: response.user.email)
        
        // Load onboarding status from backend
        await loadOnboardingStatusFromBackend(userId: response.user.id, accessToken: response.access_token)
        
        await MainActor.run {
            self.accessToken = response.access_token
            self.userEmail = response.user.email
            self.isAuthenticated = true
            self.loadSubscriptionStatus()
        }
    }
    
    // MARK: - Onboarding Status
    private func loadOnboardingStatusFromBackend(userId: String, accessToken: String) async {
        do {
            // Fetch user preferences from backend
            if let preferences = try await preferencesClient.fetchPreferences(userId: userId, accessToken: accessToken) {
                // User has preferences in backend - set local flag based on backend value
                let key = "onboarding_completed_\(userId)"
                UserDefaults.standard.set(preferences.onboardingCompleted, forKey: key)
                Logger.debug("Loaded onboarding status from backend: \(preferences.onboardingCompleted)", category: .auth)
            } else {
                // No preferences in backend - user hasn't completed onboarding
                let key = "onboarding_completed_\(userId)"
                UserDefaults.standard.set(false, forKey: key)
                Logger.debug("No preferences found in backend - onboarding not completed", category: .auth)
            }
        } catch {
            // If fetch fails, default to false (show onboarding)
            let key = "onboarding_completed_\(userId)"
            UserDefaults.standard.set(false, forKey: key)
            Logger.error("Failed to load onboarding status from backend, defaulting to false", error: error, category: .auth)
        }
    }
    
    // MARK: - Subscription Data Migration (UserDefaults → Keychain)
    private func migrateSubscriptionDataToKeychain() {
        // Check if migration already happened
        let migrationKey = "subscription_migrated_to_keychain_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            Logger.debug("Subscription migration already completed", category: .data)
            return
        }
        
        // Only migrate if we have a user ID
        guard let userId = KeychainManager.get(key: "user_id") else {
            Logger.debug("No user ID found, skipping migration", category: .data)
            return
        }
        
        Logger.info("Starting subscription data migration to Keychain", category: .data)
        
        let d = UserDefaults.standard
        var migrated = false
        
        // Migrate last payment date
        if let lastPayment = d.object(forKey: key(Self.subscriptionLastPaymentKeyPrefix, for: userId)) as? Date {
            do {
                try KeychainManager.save(key: "subscription_last_payment", date: lastPayment)
                Logger.debug("Migrated last payment date", category: .data)
                migrated = true
            } catch {
                Logger.error("Failed to migrate last payment date", error: error, category: .data)
            }
        }
        
        // Migrate period end date
        if let periodEnd = d.object(forKey: key(Self.subscriptionPeriodEndKeyPrefix, for: userId)) as? Date {
            do {
                try KeychainManager.save(key: "subscription_period_end", date: periodEnd)
                Logger.debug("Migrated period end date", category: .data)
                migrated = true
            } catch {
                Logger.error("Failed to migrate period end date", error: error, category: .data)
            }
        }
        
        // Migrate auto-renew flag
        let autoRenew = d.bool(forKey: key(Self.subscriptionAutoRenewKeyPrefix, for: userId))
        do {
            try KeychainManager.save(key: "subscription_autorenew", bool: autoRenew)
            Logger.debug("Migrated auto-renew flag: \(autoRenew)", category: .data)
            migrated = true
        } catch {
            Logger.error("Failed to migrate auto-renew flag", error: error, category: .data)
        }
        
        // Mark migration as complete
        if migrated {
            d.set(true, forKey: migrationKey)
            Logger.info("Subscription data migration completed successfully", category: .data)
            
            // Optional: Clean up old UserDefaults keys (uncomment when confident)
            // d.removeObject(forKey: key(Self.subscriptionLastPaymentKeyPrefix, for: userId))
            // d.removeObject(forKey: key(Self.subscriptionPeriodEndKeyPrefix, for: userId))
            // d.removeObject(forKey: key(Self.subscriptionAutoRenewKeyPrefix, for: userId))
            // d.removeObject(forKey: key(Self.subscriptionKeyPrefix, for: userId))
        }
    }
    
    func signOut() async {
        if let token = accessToken {
            try? await auth.signOut(accessToken: token)
        }
        
        KeychainManager.deleteAll()
        
        await MainActor.run {
            self.accessToken = nil
            self.userEmail = nil
            self.isAuthenticated = false
            self.isSubscribed = false
        }
        stopSubscriptionPolling()
    }
    
    // MARK: - User Preferences
    func savePreferencesToSupabase(
        allergies: [String],
        dietaryTypes: Set<String>,
        tastePreferences: [String: Any],
        dislikes: [String],
        notes: String?,
        onboardingCompleted: Bool
    ) async throws {
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = accessToken else {
            throw NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
        }
        
        try await preferencesClient.upsertPreferences(
            userId: userId,
            allergies: allergies,
            dietaryTypes: Array(dietaryTypes),
            tastePreferences: tastePreferences,
            dislikes: dislikes,
            notes: notes,
            onboardingCompleted: onboardingCompleted,
            accessToken: token
        )
    }
    
    // MARK: - Subscription (simulation; prepare for StoreKit)
    private func key(_ prefix: String, for userId: String) -> String { "\(prefix)\(userId)" }
    
    private func addOneMonth(to date: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date.addingTimeInterval(30*24*60*60)
    }
    
    func subscribeSimulated() {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        let now = Date()
        let periodEnd = addOneMonth(to: now)
        
        // Store in Keychain (secure)
        try? KeychainManager.save(key: "subscription_last_payment", date: now)
        try? KeychainManager.save(key: "subscription_period_end", date: periodEnd)
        try? KeychainManager.save(key: "subscription_autorenew", bool: true)
        
        self.isSubscribed = true
        // Push to Supabase
        if let token = self.accessToken {
            Task {
                try? await self.subscriptionsClient.upsertSubscription(
                    userId: userId,
                    plan: "unlimited",
                    status: "active",
                    autoRenew: true,
                    cancelAtPeriodEnd: false,
                    lastPaymentAt: now,
                    currentPeriodEnd: periodEnd,
                    priceCents: 599,
                    currency: "EUR",
                    accessToken: token
                )
                // Immediately refresh from backend and start aggressive polling for 5 min
                await MainActor.run {
                    self.loadSubscriptionStatus()
                    self.startAggressiveSubscriptionPolling(durationSeconds: 5 * 60, intervalSeconds: 30)
                }
            }
        }
    }
    
    func cancelAutoRenew() {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        
        // Store in Keychain (secure)
        try? KeychainManager.save(key: "subscription_autorenew", bool: false)
        
        // Do not change period end; features remain until end of cycle
        loadSubscriptionStatus()
        if let token = self.accessToken {
            let periodEnd = getSubscriptionPeriodEnd()
            let now = Date()
            let status = (periodEnd != nil && now < periodEnd!) ? "in_grace" : "expired"
            Task {
                try? await self.subscriptionsClient.upsertSubscription(
                    userId: userId,
                    plan: "unlimited",
                    status: status,
                    autoRenew: false,
                    cancelAtPeriodEnd: true,
                    lastPaymentAt: self.getSubscriptionLastPayment() ?? now,
                    currentPeriodEnd: periodEnd ?? now,
                    priceCents: 599,
                    currency: "EUR",
                    accessToken: token
                )
            }
        }
    }

    // MARK: - Account deletion & subscription management
    func openManageSubscriptions() async {
        #if canImport(UIKit)
        if #available(iOS 15.0, *) {
            guard let scene = await UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            try? await AppStore.showManageSubscriptions(in: scene)
        } else {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await UIApplication.shared.open(url)
            }
        }
        #endif
    }

    func deleteAccountAndData() async {
        // Best-effort: cancel auto-renew in our DB and open Apple subscription management
        // cancelAutoRenew()
        // await openManageSubscriptions()

        guard let token = self.accessToken, let userId = KeychainManager.get(key: "user_id") else {
            await signOut()
            return
        }
        let email = self.userEmail

        // Log deletion for audit/GDPR compliance (write BEFORE deleting data)
        do {
            struct AuditLog: Encodable {
                let user_id: String
                let email: String?
                let deleted_by: String
                let reason: String
            }
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/account_deletions")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.addValue("return=minimal", forHTTPHeaderField: "Prefer")
            let log = AuditLog(user_id: userId, email: email, deleted_by: "user_request", reason: "user_initiated")
            req.httpBody = try JSONEncoder().encode([log])
            _ = try? await SecureURLSession.shared.data(for: req)
        } catch {
            print("[AccountDeletion] Audit log failed: \(error)")
        }

        // Call backend to delete all data + auth user
        do {
            var url = Config.backendBaseURL
            url.append(path: "/account/delete")
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
        } catch {
            print("[AccountDeletion] Backend deletion failed: \(error)")
            // Note: signOut will be called by UI after user dismisses alert
        }
    }
    
    func getSubscriptionPeriodEnd() -> Date? {
        guard KeychainManager.get(key: "user_id") != nil else { return nil }
        return KeychainManager.getDate(key: "subscription_period_end")
    }
    
    func getSubscriptionLastPayment() -> Date? {
        guard KeychainManager.get(key: "user_id") != nil else { return nil }
        return KeychainManager.getDate(key: "subscription_last_payment")
    }
    
    func getSubscriptionAutoRenew() -> Bool {
        guard KeychainManager.get(key: "user_id") != nil else { return false }
        return KeychainManager.getBool(key: "subscription_autorenew") ?? false
    }
    
    func refreshSubscriptionStatusFromStoreKit() async {
        guard KeychainManager.get(key: "user_id") != nil else { return }
        
        // Get detailed subscription info from StoreKit
        if let info = await storeKit.getSubscriptionInfo() {
            await MainActor.run {
                // Store in Keychain (secure)
                try? KeychainManager.save(key: "subscription_autorenew", bool: info.willRenew)
                if let expiresAt = info.expiresAt {
                    try? KeychainManager.save(key: "subscription_period_end", date: expiresAt)
                }
                self.isSubscribed = info.isActive
            }
        } else {
            // No active entitlement found
            await MainActor.run {
                self.isSubscribed = false
            }
        }
    }
    
    private func extendIfAutoRenewNeeded() {
        guard KeychainManager.get(key: "user_id") != nil else { return }
        var periodEnd = getSubscriptionPeriodEnd()
        let auto = getSubscriptionAutoRenew()
        guard auto, var end = periodEnd else { return }
        let now = Date()
        // Extend in month steps until next period end is in the future
        while now >= end {
            let newLastPayment = end
            let newEnd = addOneMonth(to: end)
            try? KeychainManager.save(key: "subscription_last_payment", date: newLastPayment)
            try? KeychainManager.save(key: "subscription_period_end", date: newEnd)
            end = newEnd
        }
    }
    
    func loadSubscriptionStatus() {
        guard let userId = KeychainManager.get(key: "user_id") else {
            self.isSubscribed = false
            return
        }
        // Try backend first if authenticated
        if let token = self.accessToken {
            Task {
                if let dto = try? await self.backend.subscriptionStatus(accessToken: token) {
                    // Parse dates
                    let iso = ISO8601DateFormatter()
                    let lastPayment = dto.last_payment_at.flatMap { iso.date(from: $0) }
                    let periodEnd = dto.current_period_end.flatMap { iso.date(from: $0) }
                    await MainActor.run {
                        // Store in Keychain (secure)
                        if let lp = lastPayment { try? KeychainManager.save(key: "subscription_last_payment", date: lp) }
                        if let pe = periodEnd { try? KeychainManager.save(key: "subscription_period_end", date: pe) }
                        try? KeychainManager.save(key: "subscription_autorenew", bool: dto.auto_renew)
                        self.isSubscribed = dto.is_active
                    }
                    return
                }
                // Fallback: direct Supabase (legacy)
                if let remote = try? await self.subscriptionsClient.fetchSubscription(userId: userId, accessToken: token) {
                    await MainActor.run {
                        // Store in Keychain (secure)
                        if let lp = remote.lastPaymentAt { try? KeychainManager.save(key: "subscription_last_payment", date: lp) }
                        if let pe = remote.currentPeriodEnd { try? KeychainManager.save(key: "subscription_period_end", date: pe) }
                        try? KeychainManager.save(key: "subscription_autorenew", bool: remote.autoRenew)
                        self.isSubscribed = (remote.currentPeriodEnd.map { Date() < $0 } ?? false)
                    }
                    return
                }
                // Otherwise local
                await MainActor.run { self.loadSubscriptionStatusLocal() }
            }
            return
        }
        // Not authenticated: local only
        loadSubscriptionStatusLocal()
    }
    
    private func loadSubscriptionStatusLocal() {
        guard KeychainManager.get(key: "user_id") != nil else {
            self.isSubscribed = false
            return
        }
        extendIfAutoRenewNeeded()
        if let periodEnd = getSubscriptionPeriodEnd() {
            self.isSubscribed = Date() < periodEnd
        } else {
            self.isSubscribed = false
        }
    }
    
    // Backward compatibility: keep existing API
    func setSubscriptionActive(_ active: Bool) {
        if active { subscribeSimulated() } else { cancelAutoRenew() }
    }

    // MARK: - StoreKit purchase/restore
    func purchaseStoreKit() async {
        do {
            guard let userId = KeychainManager.get(key: "user_id") else { return }
            let txn = try await storeKit.purchaseMonthly()
            if txn != nil {
                // Update local + backend
                let now = Date(); let periodEnd = addOneMonth(to: now)
                
                // Store in Keychain (secure)
                try? KeychainManager.save(key: "subscription_last_payment", date: now)
                try? KeychainManager.save(key: "subscription_period_end", date: periodEnd)
                try? KeychainManager.save(key: "subscription_autorenew", bool: true)
                
                self.isSubscribed = true
                if let token = self.accessToken {
                    Task {
                        try? await self.subscriptionsClient.upsertSubscription(
                            userId: userId,
                            plan: "unlimited",
                            status: "active",
                            autoRenew: true,
                            cancelAtPeriodEnd: false,
                            lastPaymentAt: now,
                            currentPeriodEnd: periodEnd,
                            priceCents: 599,
                            currency: "EUR",
                            accessToken: token
                        )
                    }
                }
                // Aggressive refresh
                await MainActor.run {
                    self.loadSubscriptionStatus()
                    self.startAggressiveSubscriptionPolling(durationSeconds: 5 * 60, intervalSeconds: 30)
                }
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }

    func restorePurchases() async {
        do {
            try await storeKit.restore()
            await refreshSubscriptionFromEntitlements()
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }

    private func refreshSubscriptionFromEntitlements() async {
        let active = await storeKit.hasActiveEntitlement()
        await MainActor.run {
            self.isSubscribed = active
            if active { self.loadSubscriptionStatus() }
        }
    }

    // MARK: - Subscription polling helpers
    private func startSubscriptionPolling() {
        stopSubscriptionPolling()
        guard isAuthenticated else { return }
        // Immediate refresh on start
        loadSubscriptionStatus()
        subscriptionTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            self?.loadSubscriptionStatus()
        }
    }

    private func stopSubscriptionPolling() {
        subscriptionTimer?.invalidate(); subscriptionTimer = nil
        aggressiveTimer?.invalidate(); aggressiveTimer = nil
        aggressiveUntil = nil
    }

    private func startAggressiveSubscriptionPolling(durationSeconds: TimeInterval, intervalSeconds: TimeInterval) {
        aggressiveTimer?.invalidate(); aggressiveTimer = nil
        aggressiveUntil = Date().addingTimeInterval(durationSeconds)
        aggressiveTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] t in
            guard let self = self else { return }
            self.loadSubscriptionStatus()
            if let until = self.aggressiveUntil, Date() >= until {
                t.invalidate(); self.aggressiveTimer = nil; self.aggressiveUntil = nil
            }
        }
    }

    #if canImport(UIKit)
    @objc private func onDidBecomeActive() {
        startSubscriptionPolling()
    }

    @objc private func onWillResignActive() {
        stopSubscriptionPolling()
    }
    #endif
    
    func loadPreferencesFromSupabase() async throws {
            print("[AppState] loadPreferencesFromSupabase called")
            print("[AppState] accessToken available: \(accessToken != nil)")
            print("[AppState] userId available: \(KeychainManager.get(key: "user_id") != nil)" )
            
            guard let userId = KeychainManager.get(key: "user_id"),
                  let token = accessToken else {
            // Not logged in - try loading from UserDefaults as fallback
            print("[AppState] No userId or accessToken - loading from UserDefaults")
            await MainActor.run {
                self.dietary = DietaryPreferences.load()
            }
            return
        }
        
        if let prefs = try await preferencesClient.fetchPreferences(userId: userId, accessToken: token) {
            // Successfully loaded from Supabase - use these preferences
            print("[AppState] Successfully loaded preferences from Supabase")
            print("[AppState] Dietary types: \(prefs.dietaryTypes)")
            print("[AppState] Allergies: \(prefs.allergies)")
            await MainActor.run {
                var dietary = self.dietary
                dietary.allergies = prefs.allergies
                dietary.diets = Set(prefs.dietaryTypes)
                dietary.dislikes = prefs.dislikes
                dietary.notes = prefs.notes
                self.dietary = dietary
                
                // Save taste preferences to UserDefaults (as backup)
                let tasteDict: [String: Any] = [
                    "spicy_level": prefs.tastePreferences.spicyLevel,
                    "sweet": prefs.tastePreferences.sweet ?? false,
                    "sour": prefs.tastePreferences.sour ?? false,
                    "bitter": prefs.tastePreferences.bitter ?? false,
                    "umami": prefs.tastePreferences.umami ?? false
                ]
                if let data = try? JSONSerialization.data(withJSONObject: tasteDict) {
                    UserDefaults.standard.set(data, forKey: "taste_preferences")
                }
                
                // Mark onboarding as completed for this user
                let key = "onboarding_completed_\(userId)"
                UserDefaults.standard.set(prefs.onboardingCompleted, forKey: key)
            }
        } else {
            // No preferences in Supabase yet - try UserDefaults as fallback
            print("[AppState] No preferences in Supabase, loading from UserDefaults")
            await MainActor.run {
                let loaded = DietaryPreferences.load()
                print("[AppState] Loaded from UserDefaults - diets: \(loaded.diets)")
                self.dietary = loaded
            }
        }
    }
    
    // MARK: - Menus (Supabase)
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
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode([Menu].self, from: data)
    }
    
    func createMenu(title: String, accessToken: String, userId: String) async throws -> Menu {
        struct Row: Encodable { let user_id: String; let title: String }
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
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode([Menu].self, from: data).first!
    }
    
    func addRecipeToMenu(menuId: String, recipeId: String, accessToken: String) async throws {
        struct Row: Encodable { let menu_id: String; let recipe_id: String }
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
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
    }
    
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
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
    }
    
    func fetchMenuRecipeIds(menuId: String, accessToken: String) async throws -> [String] {
        struct Row: Decodable { let recipe_id: String }
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
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return rows.map { $0.recipe_id }
    }

    // MARK: - Delete a menu
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
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        // cleanup local placeholders
        removeAllMenuSuggestions(menuId: menuId)
    }

    // MARK: - Auto-generate recipes for a menu
    func autoGenerateRecipesForMenu(menu: Menu, suggestions: [MenuSuggestion]) async {
        guard let token = self.accessToken, let userId = KeychainManager.get(key: "user_id") else { return }
        
        // Enforce OpenAI DSGVO consent for any automatic generation
        guard OpenAIConsentManager.hasConsent else {
            print("[AutoGen] OpenAI consent not granted; skipping auto-generation")
            return
        }
        
        var ai = (self.recipeAI ?? self.openAI)
        if ai == nil { refreshRecipeAI(); ai = (self.recipeAI ?? self.openAI) }
        guard let model = ai else { return }
        let dietaryCtx = [systemContext(), hiddenIntentContext()].filter { !$0.isEmpty }.joined(separator: "\n")
        for s in suggestions {
            // mark as generating in local placeholders
            setMenuSuggestionStatus(menuId: menu.id, name: s.name, status: "generating")
            setMenuSuggestionProgress(menuId: menu.id, name: s.name, progress: 0.05)
            do {
                // Generate plan with dietary context; leave other settings empty
                // Combine name with description for better context
                let recipeGoal = (s.description?.isEmpty ?? true) ? s.name : "\(s.name): \(s.description!)"
                let plan = try await model.generateRecipePlan(
                    goal: recipeGoal,
                    timeMinutesMin: nil,
                    timeMinutesMax: nil,
                    nutrition: NutritionConstraint(
                        calories_min: nil, calories_max: nil,
                        protein_min_g: nil, protein_max_g: nil,
                        fat_min_g: nil, fat_max_g: nil,
                        carbs_min_g: nil, carbs_max_g: nil
                    ),
                    categories: [],
                    servings: 4,
                    dietaryContext: dietaryCtx
)
                // Update progress mid-way
                setMenuSuggestionProgress(menuId: menu.id, name: s.name, progress: 0.6)
                // Save to Supabase
                if let created = try await saveRecipePlan(plan, token: token, userId: userId) {
                    setMenuSuggestionProgress(menuId: menu.id, name: s.name, progress: 0.85)
                    // Link to menu
                    try? await addRecipeToMenu(menuId: menu.id, recipeId: created.id, accessToken: token)
                    // Assign course mapping based on suggestion or heuristic
                    let course = s.course ?? guessCourse(name: s.name, description: s.description)
                    setMenuCourse(menuId: menu.id, recipeId: created.id, course: course)
                    setMenuSuggestionProgress(menuId: menu.id, name: s.name, progress: 1.0)
                    // Remove placeholder
                    removeMenuSuggestion(named: s.name, from: menu.id)
                    // Broadcast new recipe
                    await MainActor.run {
                        self.lastCreatedRecipe = created
                        self.lastCreatedRecipeMenuId = menu.id
                        self.pendingSelectMenuId = menu.id
                    }
                } else {
                    setMenuSuggestionStatus(menuId: menu.id, name: s.name, status: "failed")
                    setMenuSuggestionProgress(menuId: menu.id, name: s.name, progress: nil)
                }
            } catch {
                print("[AutoGen] Failed for \(s.name): \(error)")
                setMenuSuggestionStatus(menuId: menu.id, name: s.name, status: "failed")
                setMenuSuggestionProgress(menuId: menu.id, name: s.name, progress: nil)
                continue
            }
        }
    }

    private struct SaveRecipeRow: Encodable {
        let user_id: String
        let title: String
        let ingredients: [String]
        let instructions: [String]
        let nutrition: Nutrition
        let is_public: Bool
        let cooking_time: String?
        let tags: [String]?
    }

    private func saveRecipePlan(_ plan: RecipePlan, token: String, userId: String) async throws -> Recipe? {
        // Build typed payload to keep the compiler fast and payload clean
        // DEBUG: Log what we got from AI
        print("[saveRecipePlan] Received \(plan.ingredients.count) ingredients from AI:")
        
        let ingredientNames: [String] = plan.ingredients.map { item in
            var parts: [String] = []
            if let amount = item.amount {
                // Format amount: remove trailing zeros for whole numbers
                let amountStr = amount.truncatingRemainder(dividingBy: 1) == 0 
                    ? String(Int(amount)) 
                    : String(format: "%.1f", amount)
                parts.append(amountStr)
            }
            if let unit = item.unit, !unit.isEmpty {
                parts.append(unit)
            }
            parts.append(item.name)
            return parts.joined(separator: " ")
        }
        let instructionTexts: [String] = plan.steps.map { "⟦label:\($0.title)⟧ " + $0.description }
        let cookingTime: String? = plan.total_time_minutes.map { "\($0) Min" }

        // Build tags from AI categories and ALWAYS include a language tag for the recipe.
        var tagsArray: [String] = []
        if let categories = plan.categories, !categories.isEmpty {
            tagsArray.append(contentsOf: categories)
        }
        let langTag = recipeLanguageTag()
        if !tagsArray.contains(langTag) {
            tagsArray.append(langTag)
        }
        let tags: [String]? = tagsArray.isEmpty ? nil : tagsArray

        let nut = Nutrition(
            calories: plan.nutrition?.calories ?? 0,
            protein_g: plan.nutrition?.protein_g ?? 0,
            carbs_g: plan.nutrition?.carbs_g ?? 0,
            fat_g: plan.nutrition?.fat_g ?? 0
        )
        let row = SaveRecipeRow(
            user_id: userId,
            title: plan.title.isEmpty ? "Rezept" : plan.title,
            ingredients: ingredientNames,
            instructions: instructionTexts,
            nutrition: nut,
            is_public: false,
            cooking_time: cookingTime,
            tags: tags
        )
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        let enc = JSONEncoder()
        request.httpBody = try enc.encode(row)
        let (respData, response) = try await SecureURLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        if let list = try? JSONDecoder().decode([Recipe].self, from: respData), let first = list.first {
            return first
        }
        return nil
    }
    
    // MARK: - Deletes with offline queue
    func deleteRecipeOrQueue(recipeId: String) async {
        if let token = self.accessToken {
            do {
                var url = Config.supabaseURL
                url.append(path: "/rest/v1/recipes")
                url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(recipeId)")])
                var req = URLRequest(url: url)
                req.httpMethod = "DELETE"
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
                req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                req.addValue("return=minimal", forHTTPHeaderField: "Prefer")
                req.timeoutInterval = 15
                let (_, resp) = try await SecureURLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return
            } catch let err as URLError {
                // Network issue -> queue
                switch err.code {
                case .notConnectedToInternet, .cannotConnectToHost, .timedOut, .networkConnectionLost, .dnsLookupFailed:
                    enqueueDeletion(recipeId)
                    return
                default:
                    enqueueDeletion(recipeId)
                    return
                }
            } catch {
                enqueueDeletion(recipeId)
                return
            }
        } else {
            enqueueDeletion(recipeId)
        }
    }
    
    private func enqueueDeletion(_ recipeId: String) {
        var q = deleteQueue
        if !q.contains(recipeId) { q.append(recipeId) }
        deleteQueue = q
    }
    
    func flushDeletionQueue() async {
        guard let token = self.accessToken else { return }
        var q = deleteQueue
        guard !q.isEmpty else { return }
        var kept: [String] = []
        for id in q {
            do {
                var url = Config.supabaseURL
                url.append(path: "/rest/v1/recipes")
                url.append(queryItems: [URLQueryItem(name: "id", value: "eq.\(id)")])
                var req = URLRequest(url: url)
                req.httpMethod = "DELETE"
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
                req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                req.addValue("return=minimal", forHTTPHeaderField: "Prefer")
                req.timeoutInterval = 15
                let (_, resp) = try await SecureURLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    kept.append(id)
                    continue
                }
            } catch {
                kept.append(id)
            }
        }
        deleteQueue = kept
    }

    // MARK: - Local Menu Suggestions (placeholders)
    struct MenuSuggestion: Identifiable, Codable, Equatable {
        let id: UUID
        let name: String
        let description: String?
        let course: String?
        var status: String? // nil|"generating"|"failed"
        var progress: Double? // 0.0 ... 1.0 while generating
        init(id: UUID = UUID(), name: String, description: String? = nil, course: String? = nil, status: String? = nil, progress: Double? = nil) {
            self.id = id; self.name = name; self.description = description; self.course = course; self.status = status; self.progress = progress
        }
    }

    private func suggestionsKey(for menuId: String) -> String { "menu_suggestions_\(menuId)" }

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

    // MARK: - Menu course mapping (recipe_id -> course)
    private func courseMapKey(for menuId: String) -> String { "menu_courses_\(menuId)" }

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
        if let data = try? JSONEncoder().encode(map) { UserDefaults.standard.set(data, forKey: key) }
    }

    func removeMenuCourse(menuId: String, recipeId: String) {
        var map = getMenuCourseMap(menuId: menuId)
        map.removeValue(forKey: recipeId)
        let key = courseMapKey(for: menuId)
        if let data = try? JSONEncoder().encode(map) { UserDefaults.standard.set(data, forKey: key) }
    }

    // Heuristic course guesser
    func guessCourse(name: String, description: String?) -> String {
        let text = (name + " " + (description ?? "")).lowercased()
        let starters = ["vorspeise", "starter", "antipasti", "antipasto", "bruschetta", "salat", "suppe", "gazpacho", "carpaccio"]
        let intermediate = ["zwischengang", "zwischen-gang", "zwischen gang"]
        let amuse = ["amuse-bouche", "amuse bouche", "gruß aus der küche", "gruss aus der kueche", "gruss aus der küche", "gruss aus der küche"]
        let mains = ["hauptspeise", "hauptgericht", "hauptgang", "main", "pasta", "steak", "curry", "burger", "auflauf", "pfanne", "pfannengericht"]
        let desserts = ["nachspeise", "dessert", "kuchen", "tiramisu", "pudding", "mousse", "eis", "brownie", "keks", "cookie"]
        let cheese = ["käsegang", "kaesegang", "käse", "kaese", "käseplatte", "kaeseplatte"]
        let sides = ["beilage", "beilagen", "brot", "reis", "kartoffel", "kartoffeln", "pommes", "gemüse", "gemuese"]
        let aperitif = ["aperitif", "aperitivo"]
        let digestif = ["digestif"]
        let drinks = ["getränk", "getraenk", "drink", "cocktail", "mocktail", "saft", "smoothie", "limonade", "tee", "kaffee", "wein", "bier"]
        if amuse.contains(where: { text.contains($0) }) { return "Amuse-Bouche" }
        if starters.contains(where: { text.contains($0) }) { return "Vorspeise" }
        if intermediate.contains(where: { text.contains($0) }) { return "Zwischengang" }
        if cheese.contains(where: { text.contains($0) }) { return "Käsegang" }
        if desserts.contains(where: { text.contains($0) }) { return "Nachspeise" }
        if aperitif.contains(where: { text.contains($0) }) { return "Aperitif" }
        if digestif.contains(where: { text.contains($0) }) { return "Digestif" }
        if drinks.contains(where: { text.contains($0) }) { return "Getränk" }
        if sides.contains(where: { text.contains($0) }) { return "Beilage" }
        if mains.contains(where: { text.contains($0) }) { return "Hauptspeise" }
        return "Hauptspeise"
    }
    
    // Quick keyword-based intent summary from free text
    func summarizeIntent(from text: String) -> String {
        let t = text.lowercased()
        var tags: [String] = []
        func has(_ subs: [String]) -> Bool { subs.contains { t.contains($0) } }
        if has(["vegan"]) { tags.append("vegan") }
        if has(["vegetarisch","vegetarian"]) { tags.append("vegetarisch") }
        if has(["glutenfrei","gluten-free"]) { tags.append("glutenfrei") }
        if has(["laktosefrei","lactose-free"]) { tags.append("laktosefrei") }
        if has(["low carb","low-carb","kohlenhydratarm"]) { tags.append("low-carb") }
        if has(["high protein","eiweißreich","eiweissreich","proteinreich"]) { tags.append("high-protein") }
        if has(["scharf","spicy","pikant"]) { tags.append("scharf") }
        if has(["schnell","quick","30 min","30min","wenig zeit"]) { tags.append("schnell") }
        if has(["budget","günstig","guenstig","billig","preiswert"]) { tags.append("budget") }
        return tags.joined(separator: ", ")
    }

    // MARK: - Ratings (Backend API)
    func fetchAverageRating(recipeId: String, accessToken: String) async throws -> Double? {
        let response = try await backend.getRecipeRatings(recipeId: recipeId, accessToken: accessToken)
        return response.total_ratings > 0 ? response.average_rating : nil
    }

    // Fetch average and count in one call
    func fetchRatingStats(recipeId: String, accessToken: String) async throws -> (average: Double?, count: Int) {
        let response = try await backend.getRecipeRatings(recipeId: recipeId, accessToken: accessToken)
        let avg = response.total_ratings > 0 ? response.average_rating : nil
        return (avg, response.total_ratings)
    }
    
    func upsertRating(recipeId: String, rating: Int, accessToken: String, userId: String) async throws {
        _ = try await backend.rateRecipe(recipeId: recipeId, rating: rating, accessToken: accessToken)
    }
}

private extension String {
    func nilIfBlank() -> String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
