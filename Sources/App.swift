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
            #else
            options.debug = false
            options.tracesSampleRate = 0.2 // 20% sampling in production (saves quota)
            options.environment = "production"
            #endif
            
            options.enableAutoSessionTracking = true
            options.attachScreenshot = true // Attach screenshots on crashes
            options.attachViewHierarchy = true // Attach view hierarchy
            
            // Enable breadcrumbs for better debugging
            options.enableAutoBreadcrumbTracking = true
            options.enableNetworkBreadcrumbs = true
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
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        #if DEBUG
        Logger.debug("[DeepLink] Received URL: \(url)")
        #endif
        
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
            #if DEBUG
            Logger.debug("[DeepLink] Opening recipe: \(recipeId)")
            #endif
            openRecipe(recipeId: recipeId)
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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

