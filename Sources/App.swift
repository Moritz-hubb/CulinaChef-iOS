import SwiftUI
import Sentry

@main
struct CulinaChefApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var localizationManager = LocalizationManager.shared

    init() {
        UIAppearanceConfigurator.configure()
        
        // Initialize Sentry for crash reporting and error tracking
        SentrySDK.start { options in
            // Load DSN from Info.plist (configured via Secrets.xcconfig)
            if let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
               !dsn.isEmpty,
               !dsn.hasPrefix("$") {
                options.dsn = dsn
            }
            
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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environment(\.appLanguage, localizationManager.currentLanguage)
                .id(localizationManager.currentLanguage)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onAppear {
                    // Track app launches for App Store review requests
                    AppStoreReviewManager.incrementLaunchCount()
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        Logger.debug("Received deep link: \(url)", category: .ui)
        
        // Handle culinachef:// scheme
        if url.scheme == "culinachef" {
            handleCulinaChefURL(url)
        }
        // Handle Universal Links (https://culinachef.app/...)
        else if url.host == "culinachef.app" {
            handleCulinaChefURL(url)
        }
    }
    
    private func handleCulinaChefURL(_ url: URL) {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // Check for /recipe/{id} pattern
        if pathComponents.count == 2 && pathComponents[0] == "recipe" {
            let recipeId = pathComponents[1]
            Logger.debug("Opening recipe from deep link: \(recipeId)", category: .ui)
            openRecipe(recipeId: recipeId)
        }
        // Check for /reset-password pattern
        else if pathComponents.count >= 1 && pathComponents[0] == "reset-password" {
            handlePasswordResetLink(url: url)
        }
        // Also check if URL contains reset-password (for Universal Links or different URL structures)
        else if url.absoluteString.contains("reset-password") {
            handlePasswordResetLink(url: url)
        }
    }
    
    private func handlePasswordResetLink(url: URL) {
        // Supabase sends tokens as URL fragments (after #) or query parameters
        // Try both methods
        var accessToken: String?
        var refreshToken: String?
        
        Logger.debug("Parsing password reset URL: \(url.absoluteString)", category: .auth)
        
        // Method 1: Check query parameters
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                if item.name == "access_token" {
                    accessToken = item.value
                } else if item.name == "refresh_token" {
                    refreshToken = item.value
                }
            }
        }
        
        // Method 2: Check URL fragment (Supabase often uses this)
        if accessToken == nil || refreshToken == nil {
            if let fragment = url.fragment {
                Logger.debug("Found URL fragment: \(fragment.prefix(50))...", category: .auth)
                // Parse fragment like: access_token=xxx&refresh_token=yyy&type=recovery
                let pairs = fragment.components(separatedBy: "&")
                for pair in pairs {
                    let keyValue = pair.components(separatedBy: "=")
                    if keyValue.count == 2 {
                        let key = keyValue[0]
                        let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                        if key == "access_token" {
                            accessToken = value
                        } else if key == "refresh_token" {
                            refreshToken = value
                        }
                    }
                }
            }
        }
        
        // Method 3: Check if Supabase redirects to a web URL first, then extracts tokens
        // Sometimes Supabase sends: culinachef://reset-password#access_token=xxx&refresh_token=yyy
        // But the URL might be encoded differently
        if accessToken == nil || refreshToken == nil {
            let urlString = url.absoluteString
            Logger.debug("Full URL string: \(urlString)", category: .auth)
            
            // Try to extract from the full URL string
            if let hashRange = urlString.range(of: "#") {
                let fragmentString = String(urlString[hashRange.upperBound...])
                let pairs = fragmentString.components(separatedBy: "&")
                for pair in pairs {
                    let keyValue = pair.components(separatedBy: "=")
                    if keyValue.count == 2 {
                        let key = keyValue[0]
                        let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                        if key == "access_token" {
                            accessToken = value
                        } else if key == "refresh_token" {
                            refreshToken = value
                        }
                    }
                }
            }
        }
        
        if let token = accessToken, let refresh = refreshToken {
            Logger.debug("Password reset tokens extracted successfully", category: .auth)
            // Save tokens temporarily for password reset
            Task { @MainActor in
                appState.passwordResetToken = token
                appState.passwordResetRefreshToken = refresh
                // Small delay to ensure RootView is ready
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                appState.showPasswordReset = true
                Logger.debug("Password reset view should now be visible", category: .auth)
            }
        } else {
            Logger.error("Password reset link missing tokens. URL: \(url.absoluteString)", category: .auth)
            Logger.error("Access token found: \(accessToken != nil), Refresh token found: \(refreshToken != nil)", category: .auth)
        }
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
}

