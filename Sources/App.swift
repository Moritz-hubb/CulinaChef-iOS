import SwiftUI
import Sentry

@main
struct CulinaChefApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var localizationManager = LocalizationManager.shared

    init() {
        UIAppearanceConfigurator.configure()
        
        // Initialize Sentry only when enabled and a valid DSN is present
        if Config.enableSentry,
           let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
           Self.isValidSentryDSN(dsn) {
            SentrySDK.start { options in
                options.dsn = dsn
                
                #if DEBUG
                options.debug = true // Verbose logging in debug
                options.tracesSampleRate = 1.0 // 100% sampling in debug
                options.environment = "debug"
                // In Debug-Builds Screenshots/View-Hierarchy erlauben
                options.attachScreenshot = true
                options.attachViewHierarchy = true
                #else
                options.debug = false
                options.tracesSampleRate = 0.2 // 20% sampling in production (saves quota)
                options.environment = "production"
                // In Production-Builds aus Datenschutzgründen deaktivieren
                options.attachScreenshot = false
                options.attachViewHierarchy = false
                #endif
                
                options.enableAutoSessionTracking = true
                
                // Enable breadcrumbs for better debugging
                options.enableAutoBreadcrumbTracking = true
                options.enableNetworkBreadcrumbs = true
                
                // GDPR: Scrub PII (Personally Identifiable Information) before sending to Sentry
                options.beforeSend = { event in
                    // Remove user identifiers to comply with GDPR
                    event.user = nil
                    
                    // Remove sensitive breadcrumbs (tokens, user_ids, emails)
                    if let breadcrumbs = event.breadcrumbs {
                        event.breadcrumbs = breadcrumbs.filter { crumb in
                            let message = (crumb.message ?? "").lowercased()
                            let dataStr = crumb.data?.description.lowercased() ?? ""
                            let combined = message + " " + dataStr
                            let sensitive = ["user_id", "token", "email", "password", "consent", "auth", "apikey", "key"]
                            return !sensitive.contains { combined.contains($0) }
                        }
                    }
                    
                    // Remove sensitive context/extra data
                    if var extra = event.extra {
                        ["user_id", "email", "token", "authorization", "auth", "apikey"].forEach { extra.removeValue(forKey: $0) }
                        event.extra = extra
                    }
                    
                    return event
                }
            }
        } else {
            Logger.info("Sentry disabled (missing DSN or disabled by config)", category: .config)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environmentObject(appState)
                .environment(\.appLanguage, localizationManager.currentLanguage)
                .id(localizationManager.currentLanguage)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        handleDeepLink(url)
                    }
                }
                .onAppear {
                    // Track app launches for App Store review requests
                    AppStoreReviewManager.incrementLaunchCount()
                }
        }
    }
    
    private static func isCulinaChefUniversalLinkHost(_ host: String?) -> Bool {
        host == "culinaai.com" || host == "www.culinaai.com"
    }

    private func handleDeepLink(_ url: URL) {
        Logger.debug("Received deep link: \(PasswordResetLink.safeDescription(url))", category: .ui)
        Monetization.shared.handleDeepLink(url)
        
        // Handle culinachef:// scheme (non-secret routes only: import, recipe)
        if url.scheme == "culinachef" {
            handleCulinaChefURL(url)
        }
        // Handle Universal Links (https://culinaai.com/...)
        else if Self.isCulinaChefUniversalLinkHost(url.host) {
            handleCulinaChefURL(url)
        }
    }
    
    private func handleCulinaChefURL(_ url: URL) {
        // culinachef://import?url=…  (Share Extension von TikTok & Co.)
        if url.scheme == "culinachef", url.host == "import" {
            openSocialImport(from: url)
            return
        }
        // https://culinaai.com/import?url=…
        if Self.isCulinaChefUniversalLinkHost(url.host), url.path.contains("import") {
            openSocialImport(from: url)
            return
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        if PasswordResetLink.isResetURL(url) {
            handlePasswordResetLink(url: url)
            return
        }
        
        // Check for /recipe/{id} pattern
        if pathComponents.count == 2 && pathComponents[0] == "recipe" {
            let recipeId = pathComponents[1]
            Logger.debug("Opening recipe from deep link: \(recipeId)", category: .ui)
            openRecipe(recipeId: recipeId)
        }
    }

    private func openSocialImport(from url: URL) {
        Logger.debug("[SocialImport] openSocialImport received: \(PasswordResetLink.safeDescription(url))", category: .ui)
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems,
              let raw = items.first(where: { $0.name == "url" })?.value else {
            Logger.error("[SocialImport] deep link missing url query: \(PasswordResetLink.safeDescription(url))", category: .ui)
            return
        }
        let decoded = raw.removingPercentEncoding ?? raw
        let extra = items.first(where: { $0.name == "extra" })?.value.map { $0.removingPercentEncoding ?? $0 }
        #if DEBUG
        Logger.debug(
            "[SocialImport] decoded url len=\(decoded.count) extra=\(extra != nil) tab=2 sheet=true preview=\(decoded.prefix(120))",
            category: .ui
        )
        #endif
        Task { @MainActor in
            appState.pendingSocialImportURL = decoded
            appState.pendingSocialImportExtra = extra
            appState.selectedTab = 2
            appState.showSocialImportFromShare = true
        }
    }
    
    private func handlePasswordResetLink(url: URL) {
        switch PasswordResetLink.parse(url) {
        case .notAResetLink:
            return
        case .rejectedCustomScheme:
            Logger.warning("Ignored password reset on custom URL scheme", category: .auth)
        case .missingCredentials:
            Logger.error("Password reset Universal Link missing auth code", category: .auth)
        case .pkce(let code):
            Task { @MainActor in
                do {
                    let session = try await appState.auth.exchangePKCECode(code)
                    presentPasswordReset(accessToken: session.access_token, refreshToken: session.refresh_token)
                } catch {
                    Logger.error("Password reset PKCE exchange failed", error: error, category: .auth)
                }
            }
        case .implicit(let accessToken, let refreshToken):
            Task { @MainActor in
                presentPasswordReset(accessToken: accessToken, refreshToken: refreshToken)
            }
        }
    }

    @MainActor
    private func presentPasswordReset(accessToken: String, refreshToken: String) {
        appState.passwordResetToken = accessToken
        appState.passwordResetRefreshToken = refreshToken
        appState.showPasswordReset = true
        Logger.debug("Password reset view should now be visible", category: .auth)
    }
    
    private func openRecipe(recipeId: String) {
        // Fetch recipe from backend and navigate to detail view
        Task {
            do {
                guard let token = appState.accessToken else {
                    return
                }
                
                let recipe = try await fetchRecipe(id: recipeId, token: token)
                
                await MainActor.run {
                    // Navigate to recipe detail
                    appState.deepLinkRecipe = recipe
                }
            } catch {
                // Error logged to Sentry automatically
            }
        }
    }
    
    private func fetchRecipe(id: String, token: String) async throws -> Recipe {
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

    /// Very small DSN sanity check to avoid Sentry fatal logs when `SENTRY_DSN`
    /// is unset or malformed in local/TestFlight builds.
    private static func isValidSentryDSN(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$") else { return false }
        // Sentry DSNs are URLs and must have a host. Common forms: https://<key>@<host>/<project>
        guard let comps = URLComponents(string: trimmed), let host = comps.host, !host.isEmpty else {
            return false
        }
        guard let scheme = comps.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return false
        }
        return true
    }
}

