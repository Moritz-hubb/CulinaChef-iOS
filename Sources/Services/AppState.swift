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

    // Subscription state (DEV MODE: Always enabled, no subscription checks)
    /// Ob die App aktuell davon ausgeht, dass der Nutzer ein aktives Abo hat.
    /// DEV MODE: Immer true, da Abo-Prüfungen während der Entwicklungsphase deaktiviert sind.
    @Published var isSubscribed: Bool = true
    /// Becomes true once we have loaded the initial subscription status
    /// (from StoreKit, backend, Supabase, or local cache).
    /// Used to avoid briefly showing the paywall before we know the real state.
    /// DEV MODE: Immer true, da Abo-Prüfungen während der Entwicklungsphase deaktiviert sind.
    @Published var subscriptionStatusInitialized: Bool = true

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
    
    // Recipe state preservation (for app backgrounding)
    @Published var preservedRecipeId: String? = nil
    @Published var preservedRecipePage: Int = 0
    
    // Cached recipes for instant display in recipe book tab
    @Published var cachedRecipes: [Recipe] = []
    @Published var cachedMenus: [Menu] = []
    @Published var recipesCacheTimestamp: Date? = nil
    
    // Cached community recipes for instant display
    @Published var cachedCommunityRecipes: [Recipe] = []
    @Published var communityRecipesCacheTimestamp: Date? = nil
    
    // Rating cache: recipeId -> (average: Double?, count: Int)
    // Used to avoid individual API calls for each recipe card
    var ratingCache: [String: (average: Double?, count: Int)] = [:]
    
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
        
        // DEVELOPMENT MODE: RevenueCat initialization disabled
        // Initialize RevenueCat (uncomment before launch):
        // if let userId = KeychainManager.get(key: "user_id") {
        //     RevenueCatManager.shared.configure(userId: userId)
        // } else {
        //     RevenueCatManager.shared.configure()
        // }
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
        
        // DEV MODE: Subscription migration disabled
        // subscriptionManager.migrateSubscriptionDataToKeychain()
        
        // Check for existing session
        checkSession()
        
        // DEVELOPMENT MODE: RevenueCat identify disabled
        // Update RevenueCat user ID when user logs in (uncomment before launch):
        // Task {
        //     if let userId = KeychainManager.get(key: "user_id") {
        //         try? await RevenueCatManager.shared.identify(userId: userId)
        //     }
        // }
        // DEV MODE: Subscription status always active, no checks needed
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.refreshSubscriptionStatusFromStoreKit()
        }
        // DEV MODE: Subscription polling disabled
        // self.startSubscriptionPolling()
        // Load OpenAI consent status
        openAIConsentGranted = OpenAIConsentManager.hasConsent
        
        // Listen for consent changes
        NotificationCenter.default.addObserver(
            forName: OpenAIConsentManager.consentChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                if let newValue = notification.userInfo?["hasConsent"] as? Bool {
                    self?.openAIConsentGranted = newValue
                } else {
                    self?.openAIConsentGranted = OpenAIConsentManager.hasConsent
                }
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
        
        // OPTIMIZATION: Load cached recipes from disk immediately for instant display
        loadCachedRecipesFromDisk()
        
        // Load initial data after a short delay to ensure everything is initialized
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Small delay to ensure all initialization is complete
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await self.loadInitialData()
            
            // OPTIMIZATION: Preload recipes and community recipes in background after initial load
            // This ensures tabs show data instantly without API calls
            if let userId = KeychainManager.get(key: "user_id"),
               let token = self.accessToken {
                Task.detached(priority: .utility) {
                    await self.preloadAllRecipesInBackground(userId: userId, token: token)
                }
            }
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
            
            // DEVELOPMENT MODE: RevenueCat identify disabled
            // Identify user in RevenueCat when session is restored (uncomment before launch):
            // if let userId = KeychainManager.get(key: "user_id") {
            //     Task {
            //         try? await RevenueCatManager.shared.identify(userId: userId)
            //     }
            // }
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
        
        // OPTIMIZATION: Load recipes and menus in background for instant display
        // This allows the recipe book tab to show cached data immediately
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self,
                  let userId = KeychainManager.get(key: "user_id"),
                  let token = await self.accessToken else { return }
            
            await self.preloadRecipesAndMenus(userId: userId, token: token)
        }
        
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
        
        // DEBUG: Log all dietary preferences
        Logger.info("[DEBUG Dietary] ========== DIETARY PREFERENCES DEBUG ==========", category: .data)
        Logger.info("[DEBUG Dietary] User ID: \(KeychainManager.get(key: "user_id") ?? "nil")", category: .data)
        Logger.info("[DEBUG Dietary] Dietary.diets: \(dietary.diets)", category: .data)
        Logger.info("[DEBUG Dietary] Dietary.allergies: \(dietary.allergies)", category: .data)
        Logger.info("[DEBUG Dietary] Dietary.dislikes: \(dietary.dislikes)", category: .data)
        Logger.info("[DEBUG Dietary] Dietary.notes: \(dietary.notes ?? "nil")", category: .data)
        print("🔍 [DEBUG Dietary] ========== DIETARY PREFERENCES DEBUG ==========")
        print("🔍 [DEBUG Dietary] User ID: \(KeychainManager.get(key: "user_id") ?? "nil")")
        print("🔍 [DEBUG Dietary] Dietary.diets: \(dietary.diets)")
        print("🔍 [DEBUG Dietary] Dietary.allergies: \(dietary.allergies)")
        print("🔍 [DEBUG Dietary] Dietary.dislikes: \(dietary.dislikes)")
        print("🔍 [DEBUG Dietary] Dietary.notes: \(dietary.notes ?? "nil")")
        
        // STRIKTE Anforderungen (Allergien & Ernährungsweisen)
        // WICHTIG: Ernährungsweisen müssen IMMER respektiert werden - Rezepte entsprechend anpassen
        if !dietary.diets.isEmpty {
            strictParts.append("Ernährungsweisen (IMMER respektieren, Rezepte entsprechend anpassen): " + dietary.diets.sorted().joined(separator: ", "))
            Logger.info("[DEBUG Dietary] Added diets to strictParts: \(dietary.diets)", category: .data)
            print("🔍 [DEBUG Dietary] Added diets to strictParts: \(dietary.diets)")
        }
        if !dietary.allergies.isEmpty {
            strictParts.append("Allergien/Unverträglichkeiten (IMMER vermeiden): " + dietary.allergies.joined(separator: ", "))
            Logger.info("[DEBUG Dietary] Added allergies to strictParts: \(dietary.allergies)", category: .data)
            print("🔍 [DEBUG Dietary] Added allergies to strictParts: \(dietary.allergies)")
        }
        if !dietary.dislikes.isEmpty {
            strictParts.append("Bitte meiden: " + dietary.dislikes.joined(separator: ", "))
            Logger.info("[DEBUG Dietary] Added dislikes to strictParts: \(dietary.dislikes)", category: .data)
            print("🔍 [DEBUG Dietary] Added dislikes to strictParts: \(dietary.dislikes)")
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
            // WICHTIG: Ernährungsweisen müssen IMMER respektiert werden - Rezepte entsprechend anpassen
            result.append("STRIKTE Anforderungen (IMMER beachten): " + strictParts.joined(separator: " | ") + " | WICHTIG: Ernährungsweisen müssen IMMER respektiert werden - wenn der Benutzer z.B. vegetarisch ist und 'Beef Stroganoff' anfordert, erstelle eine vegetarische Variante (z.B. mit Pilzen oder Seitan statt Rindfleisch).")
        }
        if !preferencesParts.isEmpty {
            result.append("Geschmackspräferenzen (nur wenn sinnvoll anwenden, NICHT zwingend in jedes Rezept einbauen): " + preferencesParts.joined(separator: " | "))
        }
        
        if result.isEmpty {
            Logger.info("[DEBUG Dietary] Result is EMPTY - no dietary preferences", category: .data)
            print("🔍 [DEBUG Dietary] Result is EMPTY - no dietary preferences")
            return ""
        }
        let finalPrompt = result.joined(separator: "\n")
        Logger.info("[DEBUG Dietary] Final dietary prompt: \(finalPrompt)", category: .data)
        print("🔍 [DEBUG Dietary] Final dietary prompt: \(finalPrompt)")
        Logger.info("[DEBUG Dietary] ========== END DIETARY PREFERENCES DEBUG ==========", category: .data)
        print("🔍 [DEBUG Dietary] ========== END DIETARY PREFERENCES DEBUG ==========")
        return finalPrompt
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
        // Build a compact dietary context (only essential info to stay under 2500 char limit)
        let code = currentLanguageCode()
        var essentialDietary: [String] = []
        
        // Language-specific dietary labels
        let (allergiesLabel, dietLabel, spicyLabel): (String, String, String) = {
            switch code {
            case "en": return ("Allergies", "Diet", "Spiciness: High")
            case "es": return ("Alergias", "Dieta", "Picante: Alto")
            case "fr": return ("Allergies", "Régime", "Épicé: Élevé")
            case "it": return ("Allergie", "Dieta", "Piccante: Alto")
            default: return ("Allergien", "Ernährung", "Schärfe: Hoch")
            }
        }()
        
        if !dietary.allergies.isEmpty {
            essentialDietary.append("\(allergiesLabel): " + dietary.allergies.joined(separator: ", "))
        }
        let importantDiets = ["halal", "vegan", "vegetarisch", "pescetarisch", "koscher"]
        let userImportantDiets = dietary.diets.filter { importantDiets.contains($0.lowercased()) }
        if !userImportantDiets.isEmpty {
            essentialDietary.append("\(dietLabel): " + userImportantDiets.sorted().joined(separator: ", "))
        }
        let prefs = TastePreferencesManager.load()
        if prefs.spicyLevel > 2.5 {
            essentialDietary.append(spicyLabel)
        }
        let dietaryStr = essentialDietary.isEmpty ? "" : essentialDietary.joined(separator: " | ")
        
        // Compact chat prompt (under 2000 chars to leave room for dietary context)
        // Add variety prompts to encourage different recipe suggestions each time
        // All prompts are now language-aware
        let (varietyHints, chatPrompt): ([String], String) = {
            switch code {
            case "en":
                let hints = [
                    "Vary your recipe suggestions - show different cuisines, cooking methods, and flavor profiles.",
                    "Be creative and surprising - avoid repeating similar recipes.",
                    "Show diversity: different cultures, preparation methods, and ingredient combinations."
                ]
                let prompt = """
DOMAIN: Kitchen/Cooking. Treat all cooking-related requests as relevant.

Off-Topic: ONLY for completely unrelated requests with NO connection to food/cooking (e.g., pure mathematics, programming, politics without context) respond briefly: "I'm sorry, I can't help you with that. But I'd be happy to answer your cooking questions."
IMPORTANT: If a question can be connected to food, cooking, ingredients, nutrition, kitchen, groceries, drinks, restaurants, etc. in ANY way - ALWAYS ANSWER IT, even if the connection is only remote.

ANSWER TYPES - You can answer different types of questions:

1. RECIPE SUGGESTIONS (only when explicitly asked for recipes/ideas):
   - Give ONLY short suggestions (Name + 1-2 sentences). NO complete recipes.
   - Format: 🍴 **[Name]** ⟦course: [Appetizer|Main Course|Dessert|...]⟧ [Description]
   - At the end: ⟦kind: menu⟧ for menus, ⟦kind: ideas⟧ for loose ideas
   - Standard: 5 ideas. Max 10 if explicitly requested. Min 5 unless explicitly fewer requested.
   - LIMITS: Max 10 recipe ideas, max 12 menu courses. NEVER exceed.
   - IMPORTANT - Variety: \(hints.randomElement() ?? hints[0]) Each request should provide different and varied recipe suggestions.

2. GENERAL COOKING QUESTIONS (instructions, tips, explanations):
   - When asked "How do I make...", "How do you cook...", "How do I prepare...", "What is...", "Which...", etc. → Give normal, helpful answers
   - DO NOT use special format tags (⟦course:⟧, ⟦kind:⟧) - just normal text
   - Give detailed instructions, tips, explanations, comparisons, etc.
   - Examples: "How do I make goulash tender?" → Give instructions with tips. "Which meat for burgers?" → Explain options.

3. GENERAL COOKING TIPS AND QUESTIONS:
   - "How do I store X?" → Practical tips
   - "What goes with Y?" → Suggestions for matching ingredients/dishes
   - "What's the difference between X and Y?" → Explain differences

Examples of questions you should ALWAYS answer:
- "What can I cook today with steak?" → Give 5 different steak recipe suggestions (format with tags)
- "I have no idea" → Give simple, basic recipe suggestions (format with tags)
- "How do I make goulash tender without it getting dry?" → Give normal instructions with tips (NO tags)
- "What meat is best for burgers?" → Explain different options and their pros/cons (NO tags)
- "How do you cook perfect pasta?" → Give detailed instructions (NO tags)
- "What goes with X?" → Suggestions for matching ingredients/dishes (NO tags)
- "How do I store tomatoes?" → Practical tips (NO tags)

Your goal is to ALWAYS help the user, never reject.
"""
                return (hints, prompt)
            case "es":
                let hints = [
                    "Varía tus sugerencias de recetas - muestra diferentes cocinas, métodos de cocción y perfiles de sabor.",
                    "Sé creativo y sorprendente - evita repetir recetas similares.",
                    "Muestra diversidad: diferentes culturas, métodos de preparación y combinaciones de ingredientes."
                ]
                let prompt = """
DOMINIO: Cocina/Cocinar. Trata todas las solicitudes relacionadas con la cocina como relevantes.

Fuera de tema: SOLO para solicitudes completamente no relacionadas SIN conexión con comida/cocina (ej., matemáticas puras, programación, política sin contexto) responde brevemente: "Lo siento, no puedo ayudarte con eso. Pero estaré encantado de responder tus preguntas de cocina."
IMPORTANTE: Si una pregunta puede conectarse con comida, cocina, ingredientes, nutrición, cocina, comestibles, bebidas, restaurantes, etc. de CUALQUIER manera - SIEMPRE RESPÓNDELA, incluso si la conexión es solo remota.

TIPOS DE RESPUESTA - Puedes responder diferentes tipos de preguntas:

1. SUGERENCIAS DE RECETAS (solo cuando se pide explícitamente recetas/ideeas):
   - Da SOLO sugerencias cortas (Nombre + 1-2 frases). NO recetas completas.
   - Formato: 🍴 **[Nombre]** ⟦course: [Entrante|Plato Principal|Postre|...]⟧ [Descripción]
   - Al final: ⟦kind: menu⟧ para menús, ⟦kind: ideas⟧ para ideas sueltas
   - Estándar: 5 ideas. Máx 10 si se solicita explícitamente. Mín 5 a menos que se solicite explícitamente menos.
   - LÍMITES: Máx 10 sugerencias de recetas, máx 12 platos de menú. NUNCA exceder.
   - IMPORTANTE - Variedad: \(hints.randomElement() ?? hints[0]) Cada solicitud debe proporcionar sugerencias diferentes y variadas.

2. PREGUNTAS GENERALES DE COCINA (instrucciones, consejos, explicaciones):
   - Cuando se pregunta "¿Cómo hago...", "¿Cómo se cocina...", "¿Cómo preparo...", "¿Qué es...", "¿Cuál...", etc. → Da respuestas normales y útiles
   - NO uses etiquetas de formato especiales (⟦course:⟧, ⟦kind:⟧) - solo texto normal
   - Da instrucciones detalladas, consejos, explicaciones, comparaciones, etc.
   - Ejemplos: "¿Cómo hago un guiso tierno?" → Da instrucciones con consejos. "¿Qué carne para hamburguesas?" → Explica opciones.

3. CONSEJOS Y PREGUNTAS GENERALES DE COCINA:
   - "¿Cómo almaceno X?" → Consejos prácticos
   - "¿Qué va con Y?" → Sugerencias para ingredientes/platos que combinan
   - "¿Cuál es la diferencia entre X y Y?" → Explica diferencias

Ejemplos de preguntas que debes SIEMPRE responder:
- "¿Qué puedo cocinar hoy con bistec?" → Da 5 sugerencias diferentes de recetas con bistec (formato con etiquetas)
- "No tengo idea" → Da sugerencias de recetas simples y básicas (formato con etiquetas)
- "¿Cómo hago un guiso tierno sin que se seque?" → Da instrucciones normales con consejos (SIN etiquetas)
- "¿Qué carne es mejor para hamburguesas?" → Explica diferentes opciones y sus pros/contras (SIN etiquetas)
- "¿Cómo se cocina la pasta perfecta?" → Da instrucciones detalladas (SIN etiquetas)
- "¿Qué va con X?" → Sugerencias para ingredientes/platos que combinan (SIN etiquetas)
- "¿Cómo almaceno tomates?" → Consejos prácticos (SIN etiquetas)

Tu objetivo es SIEMPRE ayudar al usuario, nunca rechazar.
"""
                return (hints, prompt)
            case "fr":
                let hints = [
                    "Variez vos suggestions de recettes - montrez différentes cuisines, méthodes de cuisson et profils de saveurs.",
                    "Soyez créatif et surprenant - évitez de répéter des recettes similaires.",
                    "Montrez la diversité: différentes cultures, méthodes de préparation et combinaisons d'ingrédients."
                ]
                let prompt = """
DOMAINE: Cuisine/Cuisiner. Traitez toutes les demandes liées à la cuisine comme pertinentes.

Hors sujet: SEULEMENT pour les demandes complètement non liées SANS connexion avec nourriture/cuisine (ex., mathématiques pures, programmation, politique sans contexte) répondez brièvement: "Je suis désolé, je ne peux pas vous aider avec cela. Mais je serais ravi de répondre à vos questions sur la cuisine."
IMPORTANT: Si une question peut être connectée à la nourriture, la cuisine, les ingrédients, la nutrition, la cuisine, les produits alimentaires, les boissons, les restaurants, etc. de N'IMPORTE QUELLE manière - RÉPONDEZ-Y TOUJOURS, même si la connexion est seulement distante.

TYPES DE RÉPONSES - Vous pouvez répondre à différents types de questions:

1. SUGGESTIONS DE RECETTES (seulement quand on demande explicitement des recettes/idées):
   - Donnez SEULEMENT des suggestions courtes (Nom + 1-2 phrases). PAS de recettes complètes.
   - Format: 🍴 **[Nom]** ⟦course: [Entrée|Plat Principal|Dessert|...]⟧ [Description]
   - À la fin: ⟦kind: menu⟧ pour les menus, ⟦kind: ideas⟧ pour les idées libres
   - Standard: 5 idées. Max 10 si explicitement demandé. Min 5 sauf si explicitement moins demandé.
   - LIMITES: Max 10 idées de recettes, max 12 plats de menu. NE JAMAIS dépasser.
   - IMPORTANT - Variété: \(hints.randomElement() ?? hints[0]) Chaque demande doit fournir des suggestions différentes et variées.

2. QUESTIONS GÉNÉRALES DE CUISINE (instructions, conseils, explications):
   - Quand on demande "Comment faire...", "Comment cuisiner...", "Comment préparer...", "Qu'est-ce que...", "Quel...", etc. → Donnez des réponses normales et utiles
   - N'utilisez PAS d'étiquettes de format spéciales (⟦course:⟧, ⟦kind:⟧) - juste du texte normal
   - Donnez des instructions détaillées, des conseils, des explications, des comparaisons, etc.
   - Exemples: "Comment faire un goulash tendre?" → Donnez des instructions avec conseils. "Quelle viande pour les hamburgers?" → Expliquez les options.

3. CONSEILS ET QUESTIONS GÉNÉRAUX DE CUISINE:
   - "Comment conserver X?" → Conseils pratiques
   - "Qu'est-ce qui va avec Y?" → Suggestions pour des ingrédients/plats qui se marient
   - "Quelle est la différence entre X et Y?" → Expliquez les différences

Exemples de questions que vous devriez TOUJOURS répondre:
- "Que puis-je cuisiner aujourd'hui avec du steak?" → Donnez 5 suggestions différentes de recettes avec steak (format avec étiquettes)
- "Je n'ai aucune idée" → Donnez des suggestions de recettes simples et basiques (format avec étiquettes)
- "Comment faire un goulash tendre sans qu'il devienne sec?" → Donnez des instructions normales avec conseils (SANS étiquettes)
- "Quelle viande est la meilleure pour les hamburgers?" → Expliquez différentes options et leurs avantages/inconvénients (SANS étiquettes)
- "Comment cuisiner des pâtes parfaites?" → Donnez des instructions détaillées (SANS étiquettes)
- "Qu'est-ce qui va avec X?" → Suggestions pour des ingrédients/plats qui se marient (SANS étiquettes)
- "Comment conserver les tomates?" → Conseils pratiques (SANS étiquettes)

Votre objectif est de TOUJOURS aider l'utilisateur, jamais rejeter.
"""
                return (hints, prompt)
            case "it":
                let hints = [
                    "Varia le tue suggerimenti di ricette - mostra diverse cucine, metodi di cottura e profili di sapore.",
                    "Sii creativo e sorprendente - evita di ripetere ricette simili.",
                    "Mostra diversità: diverse culture, metodi di preparazione e combinazioni di ingredienti."
                ]
                let prompt = """
DOMINIO: Cucina/Cucinare. Tratta tutte le richieste relative alla cucina come rilevanti.

Fuori tema: SOLO per richieste completamente non correlate SENZA connessione con cibo/cucina (es., matematica pura, programmazione, politica senza contesto) rispondi brevemente: "Mi dispiace, non posso aiutarti con questo. Ma sarò felice di rispondere alle tue domande di cucina."
IMPORTANTE: Se una domanda può essere collegata a cibo, cucina, ingredienti, nutrizione, cucina, generi alimentari, bevande, ristoranti, ecc. in QUALSIASI modo - RISpondi SEMPRE, anche se la connessione è solo remota.

TIPI DI RISPOSTA - Puoi rispondere a diversi tipi di domande:

1. SUGGERIMENTI DI RICETTE (solo quando si chiede esplicitamente ricette/idee):
   - Dai SOLO suggerimenti brevi (Nome + 1-2 frasi). NO ricette complete.
   - Formato: 🍴 **[Nome]** ⟦course: [Antipasto|Primo|Secondo|Dolce|...]⟧ [Descrizione]
   - Alla fine: ⟦kind: menu⟧ per i menu, ⟦kind: ideas⟧ per idee libere
   - Standard: 5 idee. Max 10 se esplicitamente richiesto. Min 5 a meno che non sia esplicitamente richiesto meno.
   - LIMITI: Max 10 idee di ricette, max 12 portate di menu. MAI superare.
   - IMPORTANTE - Varietà: \(hints.randomElement() ?? hints[0]) Ogni richiesta deve fornire suggerimenti diversi e variati.

2. DOMANDE GENERALI DI CUCINA (istruzioni, consigli, spiegazioni):
   - Quando si chiede "Come faccio...", "Come si cucina...", "Come preparo...", "Cos'è...", "Quale...", ecc. → Dai risposte normali e utili
   - NON usare etichette di formato speciali (⟦course:⟧, ⟦kind:⟧) - solo testo normale
   - Dai istruzioni dettagliate, consigli, spiegazioni, confronti, ecc.
   - Esempi: "Come faccio uno spezzatino tenero?" → Dai istruzioni con consigli. "Quale carne per gli hamburger?" → Spiega le opzioni.

3. CONSIGLI E DOMANDE GENERALI DI CUCINA:
   - "Come conservo X?" → Consigli pratici
   - "Cosa va bene con Y?" → Suggerimenti per ingredienti/piatti che si abbinano
   - "Qual è la differenza tra X e Y?" → Spiega le differenze

Esempi di domande che dovresti SEMPRE rispondere:
- "Cosa posso cucinare oggi con bistecca?" → Dai 5 suggerimenti diversi di ricette con bistecca (formato con etichette)
- "Non ho idea" → Dai suggerimenti di ricette semplici e di base (formato con etichette)
- "Come faccio uno spezzatino tenero senza che diventi secco?" → Dai istruzioni normali con consigli (SENZA etichette)
- "Quale carne è migliore per gli hamburger?" → Spiega diverse opzioni e i loro pro/contro (SENZA etichette)
- "Come si cucina la pasta perfetta?" → Fornisci istruzioni dettagliate (SENZA etichette)
- "Cosa va bene con X?" → Suggerimenti per ingredienti/piatti che si abbinano (SENZA etichette)
- "Come conservo i pomodori?" → Consigli pratici (SENZA etichette)

Il tuo obiettivo è AIUTARE SEMPRE l'utente, mai rifiutare.
"""
                return (hints, prompt)
            default: // German
                let hints = [
                    "Variiere deine Rezeptvorschläge - zeige unterschiedliche Küchen, Zubereitungsarten und Geschmacksrichtungen.",
                    "Sei kreativ und überraschend - vermeide Wiederholungen von ähnlichen Rezepten.",
                    "Zeige Vielfalt: verschiedene Kulturen, Zubereitungsmethoden und Zutatenkombinationen."
                ]
                let prompt = """
DOMAIN: Küche/Kochen. Behandle alle kochbezogenen Anfragen als relevant.

Off-Topic: NUR bei komplett unverwandten Anfragen ohne JEDEN Bezug zu Essen/Kochen (z.B. reine Mathematik, Programmierung, Politik ohne Kontext) antworte kurz: "Ich kann dir damit leider nicht helfen. Ich kann dir aber gerne deine Fragen übers Kochen beantworten."
WICHTIG: Wenn eine Frage IRGENDWIE mit Essen, Kochen, Zutaten, Ernährung, Küche, Lebensmitteln, Getränken, Restaurants, etc. in Verbindung gebracht werden kann - BEANTWORTE SIE IMMER, auch wenn der Bezug nur entfernt ist.

ANTWORT-TYPEN - Du kannst verschiedene Arten von Fragen beantworten:

1. REZEPTVORSCHLÄGE (nur wenn explizit nach Rezepten/Ideen gefragt wird):
   - Gib NUR kurze Vorschläge (Name + 1-2 Sätze). KEINE kompletten Rezepte.
   - Format: 🍴 **[Name]** ⟦course: [Vorspeise|Hauptspeise|Nachspeise|...]⟧ [Beschreibung]
   - Am Ende: ⟦kind: menu⟧ für Menüs, ⟦kind: ideas⟧ für lose Ideen
   - Standard: 5 Ideen. Max 10 wenn explizit gewünscht. Min 5 außer explizit weniger gewünscht.
   - LIMITS: Max 10 Rezept-Ideen, max 12 Menü-Gänge. NIEMALS überschreiten.
   - WICHTIG - Vielfalt: \(hints.randomElement() ?? hints[0]) Jede Anfrage sollte unterschiedliche und abwechslungsreiche Rezeptvorschläge liefern.

2. ALLGEMEINE KOCHFRAGEN (Anleitungen, Tipps, Erklärungen):
   - Wenn nach "Wie mache ich...", "Wie kocht man...", "Wie bereite ich...", "Was ist...", "Welches...", etc. gefragt wird → Gib normale, hilfreiche Antworten
   - KEINE speziellen Format-Tags verwenden (⟦course:⟧, ⟦kind:⟧) - nur normale Texte
   - Gib detaillierte Anleitungen, Tipps, Erklärungen, Vergleiche, etc.
   - Beispiele: "Wie mache ich Gulasch zart?" → Gib Anleitung mit Tipps. "Welches Fleisch für Burger?" → Erkläre Optionen.

3. ALLGEMEINE KOCHTIPS UND FRAGEN:
   - "Wie lagere ich X?" → Praktische Tipps
   - "Was passt zu Y?" → Vorschläge für passende Zutaten/Gerichte
   - "Was ist der Unterschied zwischen X und Y?" → Erkläre Unterschiede

Beispiele für Fragen, die du IMMER beantworten sollst:
- "Was kann ich heute mit Steak kochen?" → Gib 5 verschiedene Steak-Rezeptvorschläge (Format mit Tags)
- "Ich habe keine Ahnung" → Gib einfache, grundlegende Rezeptvorschläge (Format mit Tags)
- "Wie mache ich ein Gulasch zart ohne das es trocken wird?" → Gib normale Anleitung mit Tipps (KEINE Tags)
- "Welches Fleisch ist am besten für Burger?" → Erkläre verschiedene Optionen und ihre Vor-/Nachteile (KEINE Tags)
- "Wie kocht man perfekte Pasta?" → Gib detaillierte Anleitung (KEINE Tags)
- "Was passt zu X?" → Vorschläge für passende Zutaten/Gerichte (KEINE Tags)
- "Wie lagere ich Tomaten?" → Praktische Tipps (KEINE Tags)

Dein Ziel ist es, dem Nutzer IMMER zu helfen, niemals abzulehnen.
"""
                return (hints, prompt)
            }
        }()
        
        let randomVarietyHint = varietyHints.randomElement() ?? varietyHints[0]
        let finalChatPrompt = chatPrompt.replacingOccurrences(of: "\(varietyHints.randomElement() ?? varietyHints[0])", with: randomVarietyHint)
        
        var parts: [String] = []
        if !dietaryStr.isEmpty {
            parts.append(dietaryStr)
        }
        // Language instruction is already included in finalChatPrompt, so we don't need lang separately
        parts.append(finalChatPrompt)
        
        let full = parts.filter { !$0.isEmpty }.joined(separator: "\n\n")
        
        // Truncate if still too long (shouldn't happen, but safety check)
        if full.count > 2400 {
            return String(full.prefix(2400))
        }
        
        return full
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
            // DEV MODE: Keep subscription active even after sign out
            // self.isSubscribed = false
            self.isSubscribed = true
            
            // CRITICAL: Clear shopping list to prevent cache bleeding
            self.shoppingListManager.clearShoppingList()
        }
        // DEV MODE: Subscription polling disabled
        // stopSubscriptionPolling()
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
        // DEVELOPMENT MODE: Use StoreKit only
        await subscriptionManager.openManageSubscriptions()
        
        // PRODUCTION (uncomment before launch):
        // // Use RevenueCat Customer Center if available
        // if RevenueCatManager.shared.canShowCustomerCenter {
        //     RevenueCatManager.shared.showCustomerCenter()
        // } else {
        //     // Fallback to StoreKit
        //     await subscriptionManager.openManageSubscriptions()
        // }
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
    /// DEV MODE: Immer true, da Abo-Prüfungen während der Entwicklungsphase deaktiviert sind.
    func refreshSubscriptionStatusFromStoreKit() async {
        Logger.info("[AppState] DEV MODE: Subscription checks disabled - always returning active", category: .data)
        await MainActor.run {
            self.isSubscribed = true
            self.subscriptionStatusInitialized = true
            Logger.info("[AppState] Subscription status: active (DEV MODE)", category: .data)
        }
    }
    
    // moved to SubscriptionManager.extendIfAutoRenewNeeded()
    
    /// DEV MODE: Subscription checks disabled - always returns active
    func loadSubscriptionStatus() {
        // DEV MODE: Always set as subscribed, no actual checks
        self.isSubscribed = true
        self.subscriptionStatusInitialized = true
        Logger.info("[AppState] DEV MODE: Subscription status set to active (no checks performed)", category: .data)
        return
        
        // Original code commented out for DEV MODE:
        /*
        Task { [weak self] in
            guard let self else { return }
            
            // DEVELOPMENT MODE: Always set as subscribed
            await MainActor.run {
                self.isSubscribed = true
                self.subscriptionStatusInitialized = true
            }
            
            // PRODUCTION (uncomment before launch):
            // // Use RevenueCat as primary source
            // await RevenueCatManager.shared.loadCustomerInfo()
            // let isSubscribed = RevenueCatManager.shared.isSubscribed
            // 
            // // Fallback to SubscriptionManager if RevenueCat not available
            // if !isSubscribed {
            // let status = await self.subscriptionManager.loadSubscriptionStatus(accessToken: self.accessToken)
            // await MainActor.run {
            //         self.isSubscribed = status.isSubscribed || isSubscribed
            //     self.subscriptionStatusInitialized = true
            //     }
            // } else {
            //     await MainActor.run {
            //         self.isSubscribed = isSubscribed
            //         self.subscriptionStatusInitialized = true
            //     }
            // }
        }
        */
    }
    
    /// DEV MODE: Subscription checks disabled - always returns active
    private func loadSubscriptionStatusLocal() {
        // DEV MODE: Always set as subscribed, no actual checks
        Task { @MainActor in
            self.isSubscribed = true
            self.subscriptionStatusInitialized = true
            Logger.info("[AppState] DEV MODE: Local subscription status set to active", category: .data)
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
    /// DEV MODE: Subscription checks disabled - always returns active
    func restorePurchases() async {
        // DEV MODE: Always set as subscribed, no actual restore
        await MainActor.run {
            self.isSubscribed = true
            self.subscriptionStatusInitialized = true
            Logger.info("[AppState] DEV MODE: Restore purchases - always returning active", category: .data)
        }
    }

    /// DEV MODE: Subscription checks disabled - always returns active
    func refreshSubscriptionFromEntitlements() async {
        // DEV MODE: Always set as subscribed, no actual checks
        await MainActor.run {
            self.isSubscribed = true
            self.subscriptionStatusInitialized = true
            Logger.info("[AppState] DEV MODE: Subscription status set to active (no entitlement checks)", category: .data)
        }
    }
    
    /// Returns the original transaction ID of the current subscription (if any).
    /// This is used for transaction-based rate limiting to prevent multi-account abuse.
    /// - Returns: originalTransactionId as String, or nil if no active subscription
    func getOriginalTransactionId() async -> String? {
        await subscriptionManager.getOriginalTransactionId()
    }

    // MARK: - Subscription polling helpers
    /// DEV MODE: Subscription polling disabled - all features available
    private func startSubscriptionPolling() {
        // DEV MODE: No polling needed, subscription always active
        Logger.info("[AppState] DEV MODE: Subscription polling disabled", category: .data)
    }
    
    /// DEV MODE: Subscription polling disabled
    private func stopSubscriptionPolling() {
        // DEV MODE: No polling to stop
    }
    
    /// DEV MODE: Subscription polling disabled
    func startAggressiveSubscriptionPolling(durationSeconds: TimeInterval, intervalSeconds: TimeInterval) {
        // DEV MODE: No polling needed, subscription always active
        Logger.info("[AppState] DEV MODE: Aggressive subscription polling disabled", category: .data)
    }

    #if canImport(UIKit)
    @objc private func onDidBecomeActive() {
        startSubscriptionPolling()
        restoreRecipeStateIfNeeded()
    }

    @objc private func onWillResignActive() {
        // DEV MODE: Subscription polling disabled
        // stopSubscriptionPolling()
    }
    #endif
    
    // MARK: - Recipe State Preservation
    /// Stellt den Rezeptzustand wieder her, wenn die App zurückkommt
    private func restoreRecipeStateIfNeeded() {
        guard let recipeId = preservedRecipeId else { return }
        
        // Kleine Verzögerung, damit die UI bereit ist
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Lade das Rezept und navigiere dorthin
            guard let token = accessToken else {
                // Reset preserved state if not authenticated
                preservedRecipeId = nil
                preservedRecipePage = 0
                return
            }
            
            do {
                let recipe = try await fetchRecipeForStateRestore(id: recipeId, token: token)
                deepLinkRecipe = recipe
                // Die preservedRecipePage wird in RecipeDetailView verwendet
            } catch {
                Logger.error("Failed to restore recipe state", error: error, category: .data)
                // Reset on error
                preservedRecipeId = nil
                preservedRecipePage = 0
            }
        }
    }
    
    private func fetchRecipeForStateRestore(id: String, token: String) async throws -> Recipe {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [
            URLQueryItem(name: "id", value: "eq.\(id)"),
            URLQueryItem(name: "select", value: "*")
        ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let recipes = try JSONDecoder().decode([Recipe].self, from: data)
        guard let recipe = recipes.first else {
            throw URLError(.fileDoesNotExist)
        }
        
        return recipe
    }
    
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
    
    // MARK: - Recipe Caching
    /// Lädt gecachte Rezepte aus UserDefaults (für sofortige Anzeige nach App-Neustart)
    private func loadCachedRecipesFromDisk() {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        
        let cacheKey = "cached_recipes_\(userId)"
        let menusKey = "cached_menus_\(userId)"
        let timestampKey = "recipes_cache_timestamp_\(userId)"
        
        // Lade Rezepte
        if let recipesData = UserDefaults.standard.data(forKey: cacheKey),
           let recipes = try? JSONDecoder().decode([Recipe].self, from: recipesData) {
            self.cachedRecipes = recipes
            Logger.info("[AppState] Loaded \(recipes.count) cached recipes from disk", category: .data)
        }
        
        // Lade Menüs
        if let menusData = UserDefaults.standard.data(forKey: menusKey),
           let menus = try? JSONDecoder().decode([Menu].self, from: menusData) {
            self.cachedMenus = menus
            Logger.info("[AppState] Loaded \(menus.count) cached menus from disk", category: .data)
        }
        
        // Lade Timestamp
        if let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date {
            self.recipesCacheTimestamp = timestamp
        }
    }
    
    /// Speichert Rezepte und Menüs in UserDefaults für Persistenz
    func saveCachedRecipesToDisk(recipes: [Recipe], menus: [Menu]) {
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        
        let cacheKey = "cached_recipes_\(userId)"
        let menusKey = "cached_menus_\(userId)"
        let timestampKey = "recipes_cache_timestamp_\(userId)"
        
        // Speichere Rezepte
        if let recipesData = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(recipesData, forKey: cacheKey)
        }
        
        // Speichere Menüs
        if let menusData = try? JSONEncoder().encode(menus) {
            UserDefaults.standard.set(menusData, forKey: menusKey)
        }
        
        // Speichere Timestamp
        UserDefaults.standard.set(Date(), forKey: timestampKey)
        
        Logger.info("[AppState] Saved \(recipes.count) recipes and \(menus.count) menus to disk cache", category: .data)
    }
    
    /// Lädt Rezepte und Menüs im Hintergrund und speichert sie im Cache für sofortige Anzeige
    private func preloadRecipesAndMenus(userId: String, token: String) async {
        let startTime = Date()
        print("📦 [PERFORMANCE] Preload Recipes & Menus STARTED at \(startTime)")
        
        do {
            // Lade Rezepte und Menüs parallel
            let networkStartTime = Date()
            print("📡 [PERFORMANCE] Starting parallel network requests (recipes + menus)...")
            async let recipesTask = loadRecipesForCache(userId: userId, token: token)
            async let menusTask = menuManager.fetchMenus(accessToken: token, userId: userId)
            
            let (recipes, menus) = try await (recipesTask, menusTask)
            let networkDuration = Date().timeIntervalSince(networkStartTime)
            print("📡 [PERFORMANCE] Network requests completed in \(String(format: "%.3f", networkDuration))s")
            print("📡 [PERFORMANCE] Received: \(recipes.count) recipes, \(menus.count) menus")
            
            let cacheStartTime = Date()
            await MainActor.run {
                self.cachedRecipes = recipes
                self.cachedMenus = menus
                self.recipesCacheTimestamp = Date()
                let cacheDuration = Date().timeIntervalSince(cacheStartTime)
                print("💾 [PERFORMANCE] Cache updated in \(String(format: "%.3f", cacheDuration))s")
                print("💾 [PERFORMANCE] Cached \(recipes.count) recipes and \(menus.count) menus")
                Logger.info("[AppState] Preloaded \(recipes.count) recipes and \(menus.count) menus to cache", category: .data)
            }
            
            // Speichere auch auf Disk für Persistenz
            let diskStartTime = Date()
            saveCachedRecipesToDisk(recipes: recipes, menus: menus)
            let diskDuration = Date().timeIntervalSince(diskStartTime)
            print("💿 [PERFORMANCE] Disk save completed in \(String(format: "%.3f", diskDuration))s")
            
            let totalDuration = Date().timeIntervalSince(startTime)
            print("✅ [PERFORMANCE] Preload Recipes & Menus COMPLETED in \(String(format: "%.3f", totalDuration))s")
        } catch {
            let totalDuration = Date().timeIntervalSince(startTime)
            print("❌ [PERFORMANCE] Preload Recipes & Menus FAILED after \(String(format: "%.3f", totalDuration))s: \(error.localizedDescription)")
            Logger.error("[AppState] Failed to preload recipes and menus", error: error, category: .data)
        }
    }
    
    /// Lädt Rezepte für den Cache
    private func loadRecipesForCache(userId: String, token: String) async throws -> [Recipe] {
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15.0
        
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Recipe].self, from: data)
    }
    
    // MARK: - Background Preloading
    
    /// Preloads all recipes (personal + community) in background for instant tab display
    private func preloadAllRecipesInBackground(userId: String, token: String) async {
        let totalStartTime = Date()
        print("🚀 [PERFORMANCE] ========================================")
        print("🚀 [PERFORMANCE] Background Preload STARTED at \(Date())")
        print("🚀 [PERFORMANCE] ========================================")
        Logger.info("[AppState] 🚀 Background preload STARTED", category: .data)
        
        // Load personal recipes and menus
        let personalStartTime = Date()
        print("📦 [PERFORMANCE] Loading personal recipes and menus...")
        await preloadRecipesAndMenus(userId: userId, token: token)
        let personalDuration = Date().timeIntervalSince(personalStartTime)
        print("✅ [PERFORMANCE] Personal recipes loaded in \(String(format: "%.3f", personalDuration))s")
        
        // Load community recipes (multiple pages for better coverage)
        let communityStartTime = Date()
        print("🌍 [PERFORMANCE] Loading community recipes (3 pages)...")
        await preloadCommunityRecipes(token: token, pages: 3, pageSize: 15)
        let communityDuration = Date().timeIntervalSince(communityStartTime)
        print("✅ [PERFORMANCE] Community recipes loaded in \(String(format: "%.3f", communityDuration))s")
        
        let totalDuration = Date().timeIntervalSince(totalStartTime)
        print("🎉 [PERFORMANCE] ========================================")
        print("🎉 [PERFORMANCE] Background Preload COMPLETED")
        print("🎉 [PERFORMANCE] Total duration: \(String(format: "%.3f", totalDuration))s")
        print("🎉 [PERFORMANCE] Personal: \(String(format: "%.3f", personalDuration))s")
        print("🎉 [PERFORMANCE] Community: \(String(format: "%.3f", communityDuration))s")
        print("🎉 [PERFORMANCE] ========================================")
        Logger.info("[AppState] 🎉 Background preload COMPLETED in \(String(format: "%.3f", totalDuration))s", category: .data)
    }
    
    /// Preloads community recipes in background (multiple pages)
    private func preloadCommunityRecipes(token: String, pages: Int, pageSize: Int) async {
        let startTime = Date()
        print("🌍 [PERFORMANCE] Preload Community Recipes STARTED at \(startTime)")
        print("🌍 [PERFORMANCE] Loading \(pages) pages (pageSize: \(pageSize)) = ~\(pages * pageSize) recipes")
        
        do {
            var allRecipes: [Recipe] = []
            var successfulPages = 0
            
            // Load multiple pages in parallel for faster loading
            // OPTIMIZATION: Use timeout per page to prevent blocking
            let networkStartTime = Date()
            print("📡 [PERFORMANCE] Starting parallel network requests for \(pages) pages...")
            var tasks: [Task<[Recipe], Error>] = []
            for page in 0..<pages {
                tasks.append(Task {
                    // Add timeout wrapper to prevent 60+ second hangs
                    return try await withThrowingTaskGroup(of: [Recipe].self) { group in
                        group.addTask {
                            let pageStartTime = Date()
                            let recipes = try await self.loadCommunityRecipesPage(page: page, pageSize: pageSize, token: token)
                            let pageDuration = Date().timeIntervalSince(pageStartTime)
                            print("📡 [PERFORMANCE] Page \(page) loaded in \(String(format: "%.3f", pageDuration))s (\(recipes.count) recipes)")
                            return recipes
                        }
                        
                        // Timeout after 6 seconds per page (shorter than request timeout for faster failure)
                        group.addTask {
                            try await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
                            throw URLError(.timedOut)
                        }
                        
                        // Return first completed task (either success or timeout)
                        let result = try await group.next()!
                        group.cancelAll()
                        return result
                    }
                })
            }
            
            // Wait for all pages to load (with timeout protection)
            var pageIndex = 0
            for task in tasks {
                do {
                    let recipes = try await task.value
                    allRecipes.append(contentsOf: recipes)
                    successfulPages += 1
                    print("✅ [PERFORMANCE] Page \(pageIndex) completed: \(recipes.count) recipes")
                    pageIndex += 1
                } catch {
                    print("❌ [PERFORMANCE] Page \(pageIndex) FAILED: \(error.localizedDescription)")
                    Logger.error("[AppState] Failed to load community recipes page: \(error.localizedDescription)", category: .data)
                    pageIndex += 1
                }
            }
            
            print("📊 [PERFORMANCE] Successfully loaded \(successfulPages)/\(pages) pages")
            
            let networkDuration = Date().timeIntervalSince(networkStartTime)
            print("📡 [PERFORMANCE] All \(pages) pages loaded in \(String(format: "%.3f", networkDuration))s")
            print("📡 [PERFORMANCE] Total recipes received: \(allRecipes.count)")
            
            // Remove duplicates (by ID) and sort by created_at desc
            let processingStartTime = Date()
            var uniqueRecipes: [Recipe] = []
            var seenIds: Set<String> = []
            for recipe in allRecipes {
                if !seenIds.contains(recipe.id) {
                    uniqueRecipes.append(recipe)
                    seenIds.insert(recipe.id)
                }
            }
            
            // Sort by created_at desc (newest first)
            uniqueRecipes.sort { recipe1, recipe2 in
                let date1 = recipe1.created_at ?? ""
                let date2 = recipe2.created_at ?? ""
                return date1 > date2
            }
            
            let processingDuration = Date().timeIntervalSince(processingStartTime)
            print("🔄 [PERFORMANCE] Processing (dedupe + sort) completed in \(String(format: "%.3f", processingDuration))s")
            print("🔄 [PERFORMANCE] Unique recipes: \(uniqueRecipes.count) (removed \(allRecipes.count - uniqueRecipes.count) duplicates)")
            
            // OPTIMIZATION: Cache even if not all pages loaded successfully
            // This ensures the cache is available even if some pages timeout
            let cacheStartTime = Date()
            await MainActor.run {
                // Only update cache if we got at least some recipes
                if !uniqueRecipes.isEmpty {
                    self.cachedCommunityRecipes = uniqueRecipes
                    self.communityRecipesCacheTimestamp = Date()
                    let cacheDuration = Date().timeIntervalSince(cacheStartTime)
                    print("💾 [PERFORMANCE] Community cache updated in \(String(format: "%.3f", cacheDuration))s")
                    print("💾 [PERFORMANCE] Cached \(uniqueRecipes.count) community recipes (from \(successfulPages)/\(pages) pages)")
                    Logger.info("[AppState] Preloaded \(uniqueRecipes.count) community recipes to cache (from \(successfulPages)/\(pages) pages)", category: .data)
                } else {
                    print("⚠️ [PERFORMANCE] No recipes to cache (all pages failed or empty)")
                }
            }
            
            let totalDuration = Date().timeIntervalSince(startTime)
            print("✅ [PERFORMANCE] Preload Community Recipes COMPLETED in \(String(format: "%.3f", totalDuration))s")
            print("✅ [PERFORMANCE] Breakdown: Network=\(String(format: "%.3f", networkDuration))s, Processing=\(String(format: "%.3f", processingDuration))s, Success=\(successfulPages)/\(pages) pages")
        } catch {
            let totalDuration = Date().timeIntervalSince(startTime)
            print("❌ [PERFORMANCE] Preload Community Recipes FAILED after \(String(format: "%.3f", totalDuration))s: \(error.localizedDescription)")
            Logger.error("[AppState] Failed to preload community recipes", error: error, category: .data)
        }
    }
    
    /// Helper function to load a page of community recipes
    private func loadCommunityRecipesPage(page: Int, pageSize: Int, token: String) async throws -> [Recipe] {
        let requestStartTime = Date()
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        
        let offset = page * pageSize
        let selectFields = "id,user_id,title,image_url,cooking_time,difficulty,tags,language,created_at"
        
        var urlString = url.absoluteString
        urlString += "?select=\(selectFields.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? selectFields)"
        urlString += "&is_public=eq.true"
        urlString += "&order=created_at.desc"
        urlString += "&limit=\(pageSize)"
        urlString += "&offset=\(offset)"
        
        guard let finalURL = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        // Aggressive timeout - Query sollte <2 Sekunden dauern mit Indizes
        request.timeoutInterval = 5.0
        
        let networkStartTime = Date()
        let (data, response) = try await SecureURLSession.shared.data(for: request)
        let networkDuration = Date().timeIntervalSince(networkStartTime)
        let dataSizeKB = Double(data.count) / 1024.0
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let totalDuration = Date().timeIntervalSince(requestStartTime)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("❌ [PERFORMANCE] Page \(page) request FAILED after \(String(format: "%.3f", totalDuration))s (HTTP \(statusCode))")
            throw URLError(.badServerResponse)
        }
        
        let decodeStartTime = Date()
        let recipes = try JSONDecoder().decode([Recipe].self, from: data)
        let decodeDuration = Date().timeIntervalSince(decodeStartTime)
        let totalDuration = Date().timeIntervalSince(requestStartTime)
        
        print("📡 [PERFORMANCE] Page \(page): Network=\(String(format: "%.3f", networkDuration))s, Decode=\(String(format: "%.3f", decodeDuration))s, Total=\(String(format: "%.3f", totalDuration))s, Size=\(String(format: "%.2f", dataSizeKB))KB, Recipes=\(recipes.count)")
        
        return recipes
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
        // Add filter tags with _filter: prefix (these are invisible but used for filtering)
        if let filterTags = plan.filter_tags, !filterTags.isEmpty {
            let hiddenFilterTags = filterTags.map { "_filter:\($0.lowercased())" }
            tagsArray.append(contentsOf: hiddenFilterTags)
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
    
    /// Loads rating statistics for multiple recipes in a single batch request.
    /// Results are cached in ratingCache for fast access.
    ///
    /// - Parameters:
    ///   - recipeIds: List of recipe IDs to fetch ratings for (max 100)
    ///   - accessToken: Supabase access token
    func loadBatchRatings(recipeIds: [String], accessToken: String) async {
        guard !recipeIds.isEmpty else { return }
        
        // Filter out recipes that are already cached
        let uncachedIds = recipeIds.filter { ratingCache[$0] == nil }
        guard !uncachedIds.isEmpty else { return }
        
        // Split into batches of 100 (API limit)
        let batchSize = 100
        for i in stride(from: 0, to: uncachedIds.count, by: batchSize) {
            let batch = Array(uncachedIds[i..<min(i + batchSize, uncachedIds.count)])
            
            do {
                let response = try await backend.getBatchRatings(recipeIds: batch, accessToken: accessToken)
                
                // Update cache with results
                for rating in response.ratings {
                    ratingCache[rating.recipe_id] = (rating.average_rating, rating.total_ratings)
                }
            } catch {
                Logger.error("Failed to load batch ratings: \(error.localizedDescription)", category: .network)
            }
        }
    }
    
    /// Gets rating statistics from cache. Returns nil if not cached.
    func getCachedRatingStats(recipeId: String) -> (average: Double?, count: Int)? {
        return ratingCache[recipeId]
    }
    
    /// Clears the rating cache (e.g., after user rates a recipe)
    func clearRatingCache() {
        ratingCache.removeAll()
    }
    
    func upsertRating(recipeId: String, rating: Int, accessToken: String, userId: String) async throws {
        _ = try await backend.rateRecipe(recipeId: recipeId, rating: rating, accessToken: accessToken)
        // Clear cache for this recipe so it gets refreshed
        ratingCache.removeValue(forKey: recipeId)
    }
}

private extension String {
    func nilIfBlank() -> String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
