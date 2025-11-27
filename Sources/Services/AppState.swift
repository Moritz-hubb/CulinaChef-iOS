import Foundation
import Network
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

/// Lokale Darstellung der Ernährungspräferenzen eines Nutzers.
///
/// Dieses Modell ist bewusst schlank und wird sowohl für das In-Memory-State-Management
/// als auch für die Persistenz in `UserDefaults` verwendet.
struct DietaryPreferences: Codable, Equatable {
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

    /// Persistiert die aktuellen Präferenzen in `UserDefaults`.
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

/// Zentrale App-weite Statusverwaltung für Auth, Subscriptions, AI-Kontext, Menüs und Präferenzen.
///
/// - Diese Klasse ist `@MainActor`, d.h. alle veröffentlichten Properties und die
///   meisten Methoden sind hauptthread-isoliert und somit sicher für den Einsatz
///   mit SwiftUI-Views.
/// - Externe Services (Backend, Supabase, StoreKit) werden über klar getrennte
///   Clients gekapselt, um Netzwerklogik vom View-Layer fernzuhalten.
@MainActor
final class AppState: ObservableObject {
    /// Gibt an, ob aktuell ein Nutzer angemeldet ist (basierend auf Tokens im Keychain).
    @Published var isAuthenticated: Bool = false
    /// Globaler Loading-Flag für Auth-/Subscription-Aktionen.
    @Published var loading: Bool = false
    /// Heuristischer Jailbreak-Status des aktuellen Geräts.
    @Published var isJailbroken: Bool = JailbreakDetector.isJailbroken
    /// Letzte global angezeigte Fehlermeldung (z.B. aus StoreKit oder Backend).
    @Published var error: String?
    /// Aktuelles Supabase-Access-Token (gespiegelt aus dem Keychain).
    @Published var accessToken: String?
    /// E-Mail-Adresse des angemeldeten Nutzers.
    @Published var userEmail: String?

    // Subscription state (simulated, prepared for StoreKit)
    /// Ob die App aktuell davon ausgeht, dass der Nutzer ein aktives Abo hat.
    @Published var isSubscribed: Bool = false
    /// Becomes true once we have loaded the initial subscription status
    /// (from StoreKit, backend, Supabase, or local cache).
    /// Used to avoid briefly showing the paywall before we know the real state.
    @Published var subscriptionStatusInitialized: Bool = false

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
    // Start by loading from UserDefaults immediately, then sync from Supabase
    @Published var dietary: DietaryPreferences = DietaryPreferences.load() {
        didSet { dietary.save() }
    }
    
    // Recipe selected for community upload (for upload sheet)
    @Published var selectedRecipeForUpload: Recipe? = nil
    
    // Password reset state
    @Published var showPasswordReset: Bool = false
    @Published var showSettings: Bool = false
    @Published var showLanguageSettings: Bool = false
    @Published var passwordResetToken: String? = nil
    @Published var passwordResetRefreshToken: String? = nil
    
    // Deep link recipe navigation
    @Published var deepLinkRecipe: Recipe? = nil
    
    // Initial data loading state
    @Published var isInitialDataLoaded: Bool = false
    
    // OpenAI Consent Status (reactive)
    @Published var openAIConsentGranted: Bool = false {
        didSet {
            // Sync with OpenAIConsentManager (only if different to avoid loops)
            if OpenAIConsentManager.hasConsent != openAIConsentGranted {
                OpenAIConsentManager.hasConsent = openAIConsentGranted
            }
        }
    }

    private(set) var backend: BackendClient!
    private(set) var openAI: BackendOpenAIClient?
    private(set) var recipeAI: BackendOpenAIClient?
    private(set) var auth: SupabaseAuthClient!
    private(set) var preferencesClient: UserPreferencesClient!
    private(set) var subscriptionsClient: SubscriptionsClient!
    private(set) var storeKit: StoreKitManager!
    
    // Shopping list manager (shared across views)
    private(set) var shoppingListManager: ShoppingListManager!
    
    // Liked recipes manager (local storage, no DB)
    private(set) var likedRecipesManager: LikedRecipesManager!
    
    // MARK: - Feature Managers (Extracted from God Object)
    private(set) var authManager: AuthenticationManager!
    private(set) var subscriptionManager: SubscriptionManager!
    private(set) var menuManager: MenuManager!
    private(set) var recipeManager: RecipeManager!

    // Legacy network monitor (kept for RecipeManager integration)
    private var pathMonitor: NWPathMonitor?

    // Subscription polling (managed by SubscriptionManager)

    /// Initialisiert den globalen App-Status und startet notwendige Hintergrund-Tasks.
    ///
    /// - Richtet alle Service-Clients ein (Backend, Supabase, StoreKit).
    /// - Lädt StoreKit-Produkte und initialen Subscription-Status.
    /// - Startet Netzwerk-Monitoring für Offline-Löschwarteschlange.
    /// - Führt einmalige Migration von Abo-Daten aus `UserDefaults` in den Keychain durch.
    /// - Prüft bestehende Sessions und lädt ggf. Nutzerpräferenzen aus Supabase.
    init() {
        let backendURL = Config.backendBaseURL
        // Always log in DEBUG to ensure we see it
        Logger.info("[AppState] Initializing BackendClient with URL: \(backendURL.absoluteString)", category: .config)
        print("🔍 [DEBUG] Backend URL: \(backendURL.absoluteString)") // Direct print for visibility
        backend = BackendClient(baseURL: backendURL)
        // OpenAI now proxied through backend for security
        openAI = BackendOpenAIClient(backend: backend, accessTokenProvider: { [weak self] in self?.accessToken })
        recipeAI = BackendOpenAIClient(backend: backend, accessTokenProvider: { [weak self] in self?.accessToken })
        auth = SupabaseAuthClient(baseURL: Config.supabaseURL, apiKey: Config.supabaseAnonKey)
        preferencesClient = UserPreferencesClient(baseURL: Config.supabaseURL, apiKey: Config.supabaseAnonKey)
        subscriptionsClient = SubscriptionsClient(baseURL: Config.supabaseURL, apiKey: Config.supabaseAnonKey, backendBaseURL: Config.backendBaseURL)
        storeKit = StoreKitManager()
        shoppingListManager = ShoppingListManager()
        likedRecipesManager = LikedRecipesManager()
        
        // Initialize feature managers
        authManager = AuthenticationManager(auth: auth, preferencesClient: preferencesClient)
        subscriptionManager = SubscriptionManager(backend: backend, subscriptionsClient: subscriptionsClient, storeKit: storeKit)
        menuManager = MenuManager()
        recipeManager = RecipeManager()
        
        // Prime StoreKit - delay to ensure app is fully initialized
        Task { @MainActor [weak self] in
            guard let self else {
                #if DEBUG
                Logger.debug("[AppState] StoreKit Task: self is nil, returning", category: .data)
                #endif
                return
            }
            // Delay to ensure StoreKit and app are fully ready
            #if DEBUG
            Logger.debug("[AppState] StoreKit Task: Starting, will wait 0.5s...", category: .data)
            #endif
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            #if DEBUG
            Logger.debug("[AppState] StoreKit Task: Delay complete, calling loadProducts()...", category: .data)
            #endif
            Logger.info("[AppState] Initializing StoreKit on app startup...", category: .data)
            Logger.info("[AppState] Calling storeKit.loadProducts()...", category: .data)
            await self.storeKit.loadProducts()
            #if DEBUG
            Logger.debug("[AppState] StoreKit Task: loadProducts() completed", category: .data)
            #endif
            Logger.info("[AppState] Calling refreshSubscriptionFromEntitlements()...", category: .data)
            await self.refreshSubscriptionFromEntitlements()
            Logger.info("[AppState] Starting Transaction.updates listener...", category: .data)
            // Listen for transaction updates
            for await result in Transaction.updates {
                Logger.info("[AppState] Received Transaction.update", category: .data)
                if case .verified(let transaction) = result, transaction.productID == StoreKitManager.monthlyProductId {
                    Logger.info("[AppState] ✅ Verified transaction for our product received", category: .data)
                    Logger.info("[AppState] Transaction ID: \(transaction.id)", category: .data)
                    // Always refresh local and backend subscription status when a new
                    // verified transaction for our product appears, then finish it
                    await self.refreshSubscriptionFromEntitlements()
                    await transaction.finish()
                    Logger.info("[AppState] Transaction finished", category: .data)
                } else {
                    Logger.debug("[AppState] Transaction update not for our product or unverified", category: .data)
                }
            }
        }
        
        // Network reachability monitor for flushing offline queue
        let monitor = NWPathMonitor()
        self.pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status == .satisfied {
                Task { @MainActor in
                    if let token = self.accessToken {
                        await self.recipeManager.processOfflineQueueWithAuth(accessToken: token)
                    }
                }
            }
        }
        let queue = DispatchQueue(label: "net.monitor")
        monitor.start(queue: queue)
        
        // Migrate old UserDefaults subscription data to Keychain (one-time)
        subscriptionManager.migrateSubscriptionDataToKeychain()
        
        // Check for existing session
        checkSession()
        // Load subscription status directly from StoreKit (Apple) first, not from database
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Small delay to ensure StoreKit is ready
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await self.refreshSubscriptionStatusFromStoreKit()
        }
        // Start polling in foreground
        self.startSubscriptionPolling()
        // Load OpenAI consent status
        openAIConsentGranted = OpenAIConsentManager.hasConsent
        
        // Listen for consent changes
        NotificationCenter.default.addObserver(
            forName: OpenAIConsentManager.consentChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newValue = notification.userInfo?["hasConsent"] as? Bool {
                self?.openAIConsentGranted = newValue
            } else {
                self?.openAIConsentGranted = OpenAIConsentManager.hasConsent
            }
        }
        
        // Load preferences from Supabase on startup (takes priority over UserDefaults)
        // MUST run after checkSession() has set accessToken
        // First load from UserDefaults immediately so views have data, then sync from Supabase
        Task { [weak self] in
            guard let self else { return }
            // Small delay to ensure checkSession() has completed
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 sec to ensure session is ready
            do {
                try await self.loadPreferencesFromSupabase()
                Logger.info("[AppState] Successfully loaded preferences from Supabase on startup", category: .data)
            } catch {
                // Fallback to UserDefaults if Supabase load fails (e.g., offline)
                Logger.info("Failed to load preferences from Supabase, using local cache", category: .data)
                await MainActor.run {
                    // Ensure we have the latest from UserDefaults
                    let loaded = DietaryPreferences.load()
                    if !loaded.diets.isEmpty || !loaded.allergies.isEmpty || !loaded.dislikes.isEmpty {
                        self.dietary = loaded
                        Logger.info("[AppState] Loaded preferences from UserDefaults - diets: \(loaded.diets), allergies: \(loaded.allergies.count)", category: .data)
                    }
                    // Ensure taste preferences are loaded from Keychain
                    _ = TastePreferencesManager.load()
                }
            }
        }
        // Observe app lifecycle for resume/suspend refresh
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(self, selector: #selector(AppState.onDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppState.onWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        #endif
        // Try to flush any queued deletions on startup
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let token = self.accessToken {
                await self.recipeManager.processOfflineQueueWithAuth(accessToken: token)
            }
        }
        
        // Load initial data after a short delay to ensure everything is initialized
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Small delay to ensure all initialization is complete
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await self.loadInitialData()
        }
    }

    deinit {
        #if canImport(UIKit)
        NotificationCenter.default.removeObserver(self as Any)
        #endif
    }
    
    private func checkSession() {
        if let token = KeychainManager.get(key: "access_token"),
           let email = KeychainManager.get(key: "user_email") {
            self.accessToken = token
            self.userEmail = email
            self.isAuthenticated = true
            
            // Try to refresh token in background to ensure session is valid
            // Don't log out immediately if refresh fails - let user continue with existing token
            Task { [weak self] in
                await self?.refreshSessionIfNeeded(silent: true)
            }
        }
    }
    
    // MARK: - Initial Data Loading
    /// Lädt alle initialen Daten im Hintergrund (Subscription, Preferences, Menüs, etc.)
    /// Diese Funktion wird beim App-Start aufgerufen und setzt `isInitialDataLoaded` auf `true`, wenn fertig.
    func loadInitialData() async {
        guard isAuthenticated else {
            // If not authenticated, mark as loaded immediately
            await MainActor.run {
                self.isInitialDataLoaded = true
            }
            return
        }
        
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = accessToken else {
            await MainActor.run {
                self.isInitialDataLoaded = true
            }
            return
        }
        
        // CRITICAL: Load onboarding status FIRST before showing the main view
        // This ensures onboarding is ready to show immediately if needed
        Logger.info("[AppState] Loading onboarding status from backend...", category: .data)
        await authManager.loadOnboardingStatusFromBackend(userId: userId, accessToken: token)
        
        // CRITICAL: Load subscription status directly from StoreKit (Apple) first
        // This ensures we get the most up-to-date status from Apple, not from database
        Logger.info("[AppState] Loading subscription status from StoreKit (Apple)...", category: .data)
        await refreshSubscriptionStatusFromStoreKit()
        
        // Wait for subscription status to be initialized
        var subscriptionReady = false
        var attempts = 0
        while !subscriptionReady && attempts < 10 {
            await MainActor.run {
                subscriptionReady = self.subscriptionStatusInitialized
            }
            if !subscriptionReady {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                attempts += 1
            }
        }
        
        // Load menus in parallel (they're loaded lazily in RecipesView, but we can preload)
        // This is optional - menus will be loaded when RecipesView appears anyway
        // But preloading gives a smoother experience
        
        // Mark as loaded after a minimum time to ensure smooth transition
        // This prevents the loading screen from flashing too quickly
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds minimum
        
        await MainActor.run {
            self.isInitialDataLoaded = true
        }
    }
    
    // MARK: - Token Refresh
    /// Versucht, eine bestehende Supabase-Session mit dem gespeicherten Refresh-Token zu erneuern.
    ///
    /// - Parameter silent: Wenn `true`, wird der User nicht ausgeloggt, wenn der Refresh fehlschlägt (z.B. beim App-Start).
    ///                     Der User kann weiterhin mit dem vorhandenen Token arbeiten, bis dieser abläuft.
    /// - Wenn kein Refresh-Token vorhanden ist oder die Erneuerung scheitert und `silent == false`, wird der Nutzer ausgeloggt.
    func refreshSessionIfNeeded(silent: Bool = false) async {
        guard let refreshToken = KeychainManager.get(key: "refresh_token") else {
            if !silent {
                Logger.info("No refresh token found, logging out", category: .auth)
                await self.signOut()
            } else {
                Logger.info("No refresh token found, but silent mode - keeping existing session", category: .auth)
            }
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
            
            if !silent {
                // Token refresh failed - user needs to log in again
                await self.signOut()
            } else {
                // Silent mode: Keep user logged in with existing token
                // Token will be refreshed on next API call or when it expires
                Logger.info("Token refresh failed in silent mode - keeping existing session", category: .auth)
            }
        }
    }

    func refreshOpenAI() {
        // Recreate backend-proxied OpenAI client (uses current access token via provider)
        openAI = BackendOpenAIClient(backend: backend, accessTokenProvider: { [weak self] in self?.accessToken })
    }
    
    func refreshRecipeAI() {
        // Separate instance so we can tune settings independently later if needed
        recipeAI = BackendOpenAIClient(backend: backend, accessTokenProvider: { [weak self] in self?.accessToken })
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
        let prefs = TastePreferencesManager.load()
        let spicyLevel = prefs.spicyLevel
        let spicyLabels = ["Mild", "Normal", "Scharf", "Sehr Scharf"]
        preferencesParts.append("Schärfe-Präferenz: " + spicyLabels[Int(spicyLevel)])
        
        var tastes: [String] = []
        if prefs.sweet { tastes.append("süß") }
        if prefs.sour { tastes.append("sauer") }
        if prefs.bitter { tastes.append("bitter") }
        if prefs.umami { tastes.append("umami") }
        
        if !tastes.isEmpty {
            preferencesParts.append("Geschmackspräferenzen: " + tastes.joined(separator: ", "))
        }
        
        // Legacy code path (for backward compatibility)
        if false { // Disabled - using Keychain now
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

ANZAHL DER REZEPT-IDEEN:
- STANDARD: Gib immer 5 Rezept-Ideen, wenn der User keine spezifische Anzahl angibt
- MAXIMUM: Wenn der User explizit nach mehr fragt (z. B. "10 Rezepte", "mehr Ideen", "gib mir 8"), kannst du bis zu MAXIMAL 10 Rezept-Ideen geben
- NIEMALS mehr als 10 Rezept-Ideen, auch wenn der User nach mehr fragt (z. B. "100 Rezept-Ideen" → MAXIMAL 10)
- NIEMALS weniger als 5 Rezept-Ideen, es sei denn der User fragt explizit nach weniger

KRITISCHE LIMITS (NIEMALS ÜBERSCHREITEN):
- MAXIMAL 10 Rezept-Ideen pro Antwort
- MAXIMAL 12 Gänge für Menüs, auch wenn der User nach mehr fragt (z. B. "20-Gänge-Menü" → MAXIMAL 12 Gänge)
- Diese Limits sind HART und dürfen NIEMALS überschritten werden, unabhängig von der User-Anfrage.

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

    /// Führt den E-Mail/Passwort-Login über Supabase aus und aktualisiert Tokens & State.
    ///
    /// - Parameters:
    ///   - email: E-Mail-Adresse.
    ///   - password: Passwort.
    /// - Throws: Fehler aus `SupabaseAuthClient` oder Keychain-Speicherung.
    func signIn(email: String, password: String) async throws {
        loading = true
        defer { loading = false }
        
        let result = try await authManager.signIn(email: email, password: password)
        
        await MainActor.run {
            self.accessToken = result.accessToken
            self.userEmail = result.email
            self.isAuthenticated = true
            self.isInitialDataLoaded = false // Reset to show loading screen
        }
        
        // Load subscription status directly from StoreKit (Apple) first
        await refreshSubscriptionStatusFromStoreKit()
        
        // Load initial data after sign in
        await loadInitialData()
    }
    
    /// Registriert einen neuen Nutzer und legt ein Profil mit eindeutigem Benutzernamen an.
    ///
    /// - Parameters:
    ///   - email: E-Mail-Adresse.
    ///   - password: Passwort.
    ///   - username: Gewünschter Benutzername (muss nicht leer sein).
    /// - Throws: Validierungsfehler oder Fehler aus `SupabaseAuthClient`/Profil-Upsert.
    func signUp(email: String, password: String, username: String) async throws {
        loading = true
        defer { loading = false }
        
        let result = try await authManager.signUp(email: email, password: password, username: username)
        
        await MainActor.run {
            self.accessToken = result.accessToken
            self.userEmail = result.email
            self.isAuthenticated = true
            self.isInitialDataLoaded = false // Reset to show loading screen
        }
        
        // Load subscription status directly from StoreKit (Apple) first
        await refreshSubscriptionStatusFromStoreKit()
        
        // Load initial data after sign up
        await loadInitialData()
    }

    // moved to AuthenticationManager.upsertProfile(userId:username:accessToken:)

    // Public API for settings sheet: load & save profile
    typealias ProfileRow = AuthenticationManager.ProfileRow

    func fetchProfile() async throws -> ProfileRow? {
        return try await authManager.fetchProfile(accessToken: accessToken, userId: KeychainManager.get(key: "user_id"))
    }

    func saveProfile(fullName: String?, email: String?) async throws {
        try await authManager.saveProfile(fullName: fullName, email: email, accessToken: accessToken, userId: KeychainManager.get(key: "user_id"), userEmail: userEmail)
    }
    
    /// Sendet eine Passwort-Reset-E-Mail an die angegebene E-Mail-Adresse.
    ///
    /// - Parameter email: E-Mail-Adresse des Nutzers.
    /// - Throws: Fehler aus `AuthenticationManager`.
    func resetPassword(email: String) async throws {
        try await authManager.resetPassword(email: email)
    }
    
    /// Prüft, ob eine gültige Session für den angegebenen Access-Token existiert.
    ///
    /// - Parameter accessToken: Access-Token zum Prüfen.
    /// - Returns: User-Daten, falls eine gültige Session existiert.
    /// - Throws: Fehler aus `SupabaseAuthClient`.
    func getUser(accessToken: String) async throws -> AuthResponse.User? {
        return try await auth.getUser(accessToken: accessToken)
    }
    
    /// Aktualisiert das Passwort mit einem Reset-Token.
    ///
    /// - Parameters:
    ///   - accessToken: Access-Token aus dem Passwort-Reset-Link.
    ///   - refreshToken: Refresh-Token aus dem Passwort-Reset-Link.
    ///   - newPassword: Neues Passwort.
    /// - Throws: Fehler aus `AuthenticationManager`.
    func updatePassword(accessToken: String, refreshToken: String, newPassword: String) async throws {
        loading = true
        defer { loading = false }
        
        let result = try await authManager.updatePassword(accessToken: accessToken, refreshToken: refreshToken, newPassword: newPassword)
        
        await MainActor.run {
            self.accessToken = result.accessToken
            self.userEmail = result.email
            self.isAuthenticated = true
            self.isInitialDataLoaded = false // Reset to show loading screen
            self.showPasswordReset = false
            self.passwordResetToken = nil
            self.passwordResetRefreshToken = nil
        }
        
        // Load subscription status directly from StoreKit (Apple) first
        await refreshSubscriptionStatusFromStoreKit()
        
        // Load initial data after password update
        await loadInitialData()
    }
    
    /// Führt den Login via „Sign in with Apple" durch und aktualisiert Tokens & State.
    ///
    /// - Parameters:
    ///   - idToken: Vom Apple-SDK geliefertes Token.
    ///   - nonce: Optionaler Nonce zur Absicherung gegen Replay-Angriffe.
    ///   - fullName: Optionaler vollständiger Name vom Apple Credential (nur beim ersten Sign In verfügbar).
    ///   - isSignUp: Wenn true, wird geprüft ob Account bereits existiert und Fehler geworfen.
    /// - Throws: Fehler aus `SupabaseAuthClient` oder Keychain-Speicherung.
    func signInWithApple(idToken: String, nonce: String?, fullName: String? = nil, isSignUp: Bool = false) async throws {
        loading = true
        defer { loading = false }
        
        let result = try await authManager.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName, isSignUp: isSignUp)
        
        await MainActor.run {
            self.accessToken = result.accessToken
            self.userEmail = result.email
            self.isAuthenticated = true
            self.isInitialDataLoaded = false // Reset to show loading screen
            
            // CRITICAL: Reload shopping list for new user to prevent cache bleeding
            self.shoppingListManager.loadShoppingList()
        }
        
        // Load subscription status directly from StoreKit (Apple) first
        await refreshSubscriptionStatusFromStoreKit()
        
        // Load initial data after sign in with Apple
        await loadInitialData()
    }
    
    // moved to AuthenticationManager.loadOnboardingStatusFromBackend(userId:accessToken:)
    
    // moved to SubscriptionManager.migrateSubscriptionDataToKeychain()
    
    /// Meldet den Nutzer ab, löscht Tokens und leert sicherheitskritische Caches.
    ///
    /// - Hinweis: Shopping- und Subscription-Daten werden lokal zurückgesetzt;
    ///   Server-seitige Session-Invalidierung erfolgt über Supabase.
    func signOut() async {
        await authManager.signOut(accessToken: accessToken)
        await MainActor.run {
            self.accessToken = nil
            self.userEmail = nil
            self.isAuthenticated = false
            self.isSubscribed = false
            
            // CRITICAL: Clear shopping list to prevent cache bleeding
            self.shoppingListManager.clearShoppingList()
        }
        stopSubscriptionPolling()
    }
    
    // MARK: - User Preferences
    /// Speichert die vom Nutzer konfigurierten Präferenzen in der Supabase-Tabelle `user_preferences`.
    ///
    /// - Throws: Fehler aus `UserPreferencesClient` oder `NSError` bei fehlender Authentifizierung.
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
    // moved to SubscriptionManager.addOneMonth(to:) and SubscriptionManager.key(_:for:)
    
    func subscribeSimulated() {
        subscriptionManager.subscribeSimulated(accessToken: self.accessToken)
        self.isSubscribed = true
        // Immediately refresh from backend and start aggressive polling for 5 min
        self.loadSubscriptionStatus()
        self.startAggressiveSubscriptionPolling(durationSeconds: 5 * 60, intervalSeconds: 30)
    }
    
    func cancelAutoRenew() {
        subscriptionManager.cancelAutoRenew(accessToken: self.accessToken)
        loadSubscriptionStatus()
    }

    // MARK: - Account deletion & subscription management
    func openManageSubscriptions() async {
        await subscriptionManager.openManageSubscriptions()
    }

    func deleteAccountAndData() async {
        do {
            try await subscriptionManager.deleteAccountAndData(accessToken: self.accessToken, userId: KeychainManager.get(key: "user_id"), userEmail: self.userEmail)
        } catch {
            Logger.error("[AccountDeletion] Backend deletion failed", error: error, category: .data)
        }
    }
    
    func getSubscriptionPeriodEnd() -> Date? {
        subscriptionManager.getSubscriptionPeriodEnd()
    }
    
    func getSubscriptionLastPayment() -> Date? {
        subscriptionManager.getSubscriptionLastPayment()
    }
    
    func getSubscriptionAutoRenew() -> Bool {
        subscriptionManager.getSubscriptionAutoRenew()
    }
    
    /// Lädt den Subscription-Status direkt von StoreKit (Apple), nicht aus der Datenbank.
    /// Dies ist die bevorzugte Methode beim App-Start, um den aktuellsten Status zu erhalten.
    func refreshSubscriptionStatusFromStoreKit() async {
        Logger.info("[AppState] Refreshing subscription status from StoreKit (Apple)...", category: .data)
        let active = await subscriptionManager.refreshSubscriptionStatusFromStoreKit()
        await MainActor.run {
            self.isSubscribed = active
            self.subscriptionStatusInitialized = true
            Logger.info("[AppState] Subscription status from StoreKit: \(active ? "active" : "inactive")", category: .data)
        }
    }
    
    // moved to SubscriptionManager.extendIfAutoRenewNeeded()
    
    func loadSubscriptionStatus() {
        Task { [weak self] in
            guard let self else { return }
            let status = await self.subscriptionManager.loadSubscriptionStatus(accessToken: self.accessToken)
            await MainActor.run {
                self.isSubscribed = status.isSubscribed
                self.subscriptionStatusInitialized = true
            }
        }
    }
    
    private func loadSubscriptionStatusLocal() {
        Task { [weak self] in
            guard let self else { return }
            let status = await self.subscriptionManager.loadSubscriptionStatus(accessToken: nil as String?)
            await MainActor.run {
                self.isSubscribed = status.isSubscribed
                self.subscriptionStatusInitialized = true
            }
        }
    }
    
    // Backward compatibility: keep existing API
    func setSubscriptionActive(_ active: Bool) {
        if active { subscribeSimulated() } else { cancelAutoRenew() }
    }

    // MARK: - StoreKit purchase/restore
    /// Startet den StoreKit-Kauf-Flow für das Monatsabo und synchronisiert Status mit Supabase.
    ///
    /// - Hinweis: Bei Abbruch oder pending-Status wird kein Fehler gesetzt.
    func purchaseStoreKit() async {
        Logger.info("[AppState] ========== START purchaseStoreKit() ==========", category: .data)
        Logger.info("[AppState] Has access token: \(self.accessToken != nil)", category: .data)
        Logger.info("[AppState] User ID: \(KeychainManager.get(key: "user_id") ?? "nil")", category: .data)
        
        await MainActor.run { self.error = nil }
        do {
            Logger.info("[AppState] Calling subscriptionManager.purchaseStoreKit()...", category: .data)
            let isActive = try await subscriptionManager.purchaseStoreKit(accessToken: self.accessToken, userId: KeychainManager.get(key: "user_id"))
            Logger.info("[AppState] Purchase completed, isActive: \(isActive)", category: .data)
            
            await MainActor.run {
                Logger.info("[AppState] Updating app state...", category: .data)
                self.isSubscribed = isActive
                Logger.info("[AppState] isSubscribed set to: \(isActive)", category: .data)
                self.loadSubscriptionStatus()
                Logger.info("[AppState] Starting aggressive subscription polling...", category: .data)
                self.startAggressiveSubscriptionPolling(durationSeconds: 5 * 60, intervalSeconds: 30)
                
                // Track positive action for App Store review (subscription purchase)
                if isActive {
                    AppStoreReviewManager.recordPositiveAction()
                    AppStoreReviewManager.requestReviewIfAppropriate()
                }
            }
            Logger.info("[AppState] ========== END purchaseStoreKit() - SUCCESS ==========", category: .data)
        } catch {
            Logger.error("[AppState] ❌ Purchase failed", error: error, category: .data)
            Logger.error("[AppState] Error: \(error.localizedDescription)", category: .data)
            if let nsError = error as NSError? {
                Logger.error("[AppState] Error domain: \(nsError.domain), code: \(nsError.code)", category: .data)
            }
            await MainActor.run { 
                self.error = error.localizedDescription
                Logger.info("[AppState] Error message set in app state: \(error.localizedDescription)", category: .data)
            }
            Logger.info("[AppState] ========== END purchaseStoreKit() - ERROR ==========", category: .data)
        }
    }

    /// Stellt Käufe über StoreKit wieder her und aktualisiert Subscription-Entitlements.
    func restorePurchases() async {
        do {
            let active = try await subscriptionManager.restorePurchases()
            await MainActor.run {
                self.isSubscribed = active
                self.subscriptionStatusInitialized = true
                if active { self.loadSubscriptionStatus() }
            }
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
        }
    }

    private func refreshSubscriptionFromEntitlements() async {
        let active = try? await subscriptionManager.restorePurchases()
        await MainActor.run {
            self.isSubscribed = active ?? false
            self.subscriptionStatusInitialized = true
            if self.isSubscribed { self.loadSubscriptionStatus() }
        }
    }
    
    /// Returns the original transaction ID of the current subscription (if any).
    /// This is used for transaction-based rate limiting to prevent multi-account abuse.
    /// - Returns: originalTransactionId as String, or nil if no active subscription
    func getOriginalTransactionId() async -> String? {
        await subscriptionManager.getOriginalTransactionId()
    }

    // MARK: - Subscription polling helpers
    private func startSubscriptionPolling() {
        subscriptionManager.startSubscriptionPolling(isAuthenticated: isAuthenticated) { [weak self] in
            self?.loadSubscriptionStatus()
        }
    }

    private func stopSubscriptionPolling() {
        subscriptionManager.stopSubscriptionPolling()
    }

    private func startAggressiveSubscriptionPolling(durationSeconds: TimeInterval, intervalSeconds: TimeInterval) {
        subscriptionManager.startAggressiveSubscriptionPolling(durationSeconds: durationSeconds, intervalSeconds: intervalSeconds) { [weak self] in
            self?.loadSubscriptionStatus()
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
    
    /// Lädt Ernährungspräferenzen aus Supabase (falls eingeloggt) oder fällt auf UserDefaults zurück.
    ///
    /// - Throws: Fehler aus `UserPreferencesClient`, wenn der Request selbst fehlschlägt.
    func loadPreferencesFromSupabase() async throws {
        Logger.debug("[AppState] loadPreferencesFromSupabase called", category: .data)
        Logger.debug("[AppState] accessToken available: \(accessToken != nil)", category: .auth)
        Logger.debug("[AppState] userId available: \(KeychainManager.get(key: "user_id") != nil)", category: .auth)
        
        guard let userId = KeychainManager.get(key: "user_id"),
              let token = accessToken else {
            // Not logged in - try loading from UserDefaults as fallback
            Logger.debug("[AppState] No userId or accessToken - loading from UserDefaults", category: .data)
            await MainActor.run {
                self.dietary = DietaryPreferences.load()
                // Ensure taste preferences are loaded from Keychain
                _ = TastePreferencesManager.load() // This will load or migrate from UserDefaults
            }
            return
        }
        
        if let prefs = try await preferencesClient.fetchPreferences(userId: userId, accessToken: token) {
            // Successfully loaded from Supabase - use these preferences
            Logger.sensitive("[AppState] Successfully loaded preferences from Supabase", category: .data)
            Logger.sensitive("[AppState] Dietary types: \(prefs.dietaryTypes)", category: .data)
            Logger.sensitive("[AppState] Allergies: \(prefs.allergies)", category: .data)
            await MainActor.run {
                var dietary = self.dietary
                dietary.allergies = prefs.allergies
                dietary.diets = Set(prefs.dietaryTypes)
                dietary.dislikes = prefs.dislikes
                dietary.notes = prefs.notes
                self.dietary = dietary
                
                // Save taste preferences to Keychain (secure storage)
                var tastePrefs = TastePreferencesManager.TastePreferences()
                tastePrefs.spicyLevel = prefs.tastePreferences.spicyLevel
                tastePrefs.sweet = prefs.tastePreferences.sweet ?? false
                tastePrefs.sour = prefs.tastePreferences.sour ?? false
                tastePrefs.bitter = prefs.tastePreferences.bitter ?? false
                tastePrefs.umami = prefs.tastePreferences.umami ?? false
                try? TastePreferencesManager.save(tastePrefs)
                
                // Mark onboarding as completed for this user
                let key = "onboarding_completed_\(userId)"
                UserDefaults.standard.set(prefs.onboardingCompleted, forKey: key)
            }
        } else {
            // No preferences in Supabase yet - try UserDefaults as fallback
            Logger.info("[AppState] No preferences in Supabase, using UserDefaults", category: .data)
            await MainActor.run {
                let loaded = DietaryPreferences.load()
                if !loaded.diets.isEmpty || !loaded.allergies.isEmpty || !loaded.dislikes.isEmpty {
                    Logger.info("[AppState] Loaded preferences from UserDefaults - diets: \(loaded.diets), allergies: \(loaded.allergies.count), dislikes: \(loaded.dislikes.count)", category: .data)
                    self.dietary = loaded
                } else {
                    Logger.info("[AppState] No preferences found in UserDefaults either - using defaults", category: .data)
                }
                // Ensure taste preferences are loaded from Keychain (or migrated from UserDefaults)
                let tastePrefs = TastePreferencesManager.load()
                Logger.info("[AppState] Loaded taste preferences from Keychain - spicyLevel: \(tastePrefs.spicyLevel), sweet: \(tastePrefs.sweet), sour: \(tastePrefs.sour), bitter: \(tastePrefs.bitter), umami: \(tastePrefs.umami)", category: .data)
            }
        }
    }
    
    // MARK: - Menus (Supabase)
    func fetchMenus(accessToken: String, userId: String) async throws -> [Menu] {
        try await menuManager.fetchMenus(accessToken: accessToken, userId: userId)
    }
    
    func createMenu(title: String, accessToken: String, userId: String) async throws -> Menu {
        try await menuManager.createMenu(title: title, accessToken: accessToken, userId: userId)
    }
    
    func addRecipeToMenu(menuId: String, recipeId: String, accessToken: String) async throws {
        try await menuManager.addRecipeToMenu(menuId: menuId, recipeId: recipeId, accessToken: accessToken)
    }
    
    func removeRecipeFromMenu(menuId: String, recipeId: String, accessToken: String) async throws {
        try await menuManager.removeRecipeFromMenu(menuId: menuId, recipeId: recipeId, accessToken: accessToken)
    }
    
    func fetchMenuRecipeIds(menuId: String, accessToken: String) async throws -> [String] {
        try await menuManager.fetchMenuRecipeIds(menuId: menuId, accessToken: accessToken)
    }

    // MARK: - Delete a menu
    func deleteMenu(menuId: String, accessToken: String) async throws {
        try await menuManager.deleteMenu(menuId: menuId, accessToken: accessToken)
    }

    // MARK: - Auto-generate recipes for a menu
    /// Nutzt das AI-Backend, um aus einem Menü und Vorschlags-Platzhaltern konkrete Rezepte zu generieren.
    ///
    /// - Hinweis: Berücksichtigt DSGVO-Consent (OpenAIConsentManager) und aktualisiert Menü-Suggestions
    ///   inkl. Fortschritt/Status in UserDefaults, ohne den UI-Flow zu verändern.
    func autoGenerateRecipesForMenu(menu: Menu, suggestions: [MenuSuggestion]) async {
        guard let token = self.accessToken, let userId = KeychainManager.get(key: "user_id") else { return }
        
        // Enforce OpenAI DSGVO consent for any automatic generation
        guard OpenAIConsentManager.hasConsent else {
            Logger.info("[AutoGen] OpenAI consent not granted; skipping auto-generation", category: .data)
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
                Logger.error("[AutoGen] Failed for \(s.name)", error: error, category: .data)
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
        Logger.debug("[saveRecipePlan] Received \(plan.ingredients.count) ingredients from AI", category: .data)
        
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
        let isOnline = pathMonitor?.currentPath.status == .satisfied
        do {
            try await recipeManager.deleteRecipe(recipeId: recipeId, accessToken: self.accessToken, isOnline: isOnline)
        } catch {
            // RecipeManager already queued the deletion if needed
            Logger.debug("Recipe deletion queued or failed: \(recipeId)", category: .data)
        }
    }

    // MARK: - Local Menu Suggestions (placeholders)
    typealias MenuSuggestion = MenuManager.MenuSuggestion

    func getMenuSuggestions(menuId: String) -> [MenuSuggestion] {
        menuManager.getMenuSuggestions(menuId: menuId)
    }

    func addMenuSuggestions(_ suggestions: [MenuSuggestion], to menuId: String) {
        menuManager.addMenuSuggestions(suggestions, to: menuId)
    }

    func removeMenuSuggestion(named name: String, from menuId: String) {
        menuManager.removeMenuSuggestion(named: name, from: menuId)
    }

    func removeAllMenuSuggestions(menuId: String) {
        menuManager.removeAllMenuSuggestions(menuId: menuId)
    }

    func setMenuSuggestionStatus(menuId: String, name: String, status: String?) {
        menuManager.setMenuSuggestionStatus(menuId: menuId, name: name, status: status)
    }

    func setMenuSuggestionProgress(menuId: String, name: String, progress: Double?) {
        menuManager.setMenuSuggestionProgress(menuId: menuId, name: name, progress: progress)
    }

    // MARK: - Menu course mapping (recipe_id -> course)
    func getMenuCourseMap(menuId: String) -> [String: String] {
        menuManager.getMenuCourseMap(menuId: menuId)
    }

    func setMenuCourse(menuId: String, recipeId: String, course: String) {
        menuManager.setMenuCourse(menuId: menuId, recipeId: recipeId, course: course)
    }

    func removeMenuCourse(menuId: String, recipeId: String) {
        menuManager.removeMenuCourse(menuId: menuId, recipeId: recipeId)
    }

    // Heuristic course guesser
    func guessCourse(name: String, description: String?) -> String {
        menuManager.guessCourse(name: name, description: description)
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
