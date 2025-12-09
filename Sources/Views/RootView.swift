import SwiftUI

// MARK: - Root View Modifiers
private struct RootViewModifiers: ViewModifier {
    @ObservedObject var app: AppState
    @Binding var showOnboarding: Bool
    @Binding var showSubscriptionPaywall: Bool
    @Binding var languageRefreshTrigger: UUID
    @Binding var hasTrackedLaunch: Bool
    var scenePhase: ScenePhase
    var localizationManager: LocalizationManager
    var checkOnboardingStatus: () -> Void
    var checkSubscriptionStatus: () -> Void
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $app.showPasswordReset) {
                ResetPasswordView()
                    .environmentObject(app)
            }
            .onAppear(perform: handleAppear)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
            }
            .onChange(of: app.showPasswordReset) { _, shouldShow in
                handlePasswordResetChange(shouldShow)
            }
            .alert(L.error.localized, isPresented: errorBinding, actions: {
                Button(L.ok.localized) { app.error = nil }
            }, message: {
                Text(app.error ?? "")
            })
            .onChange(of: app.isAuthenticated) { _, newValue in
                handleAuthChange(newValue)
            }
            .onChange(of: app.isSubscribed) { _, isActive in
                handleSubscriptionChange(isActive)
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { notification in
                handleLanguageChange(notification)
            }
            .id(viewId)
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { app.error != nil },
            set: { if !$0 { app.error = nil } }
        )
    }
    
    private var viewId: String {
        app.showSettings || app.showLanguageSettings 
            ? "stable" 
            : "\(languageRefreshTrigger)_\(localizationManager.currentLanguage)"
    }
    
    private func handleAppear() {
        if app.passwordResetToken != nil && app.passwordResetRefreshToken != nil {
            app.showPasswordReset = true
        }
        
        if !hasTrackedLaunch {
            AppStoreReviewManager.incrementLaunchCount()
            hasTrackedLaunch = true
        }
    }
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        if oldPhase == .background && newPhase == .active && !hasTrackedLaunch {
            AppStoreReviewManager.incrementLaunchCount()
            hasTrackedLaunch = true
        }
    }
    
    private func handlePasswordResetChange(_ shouldShow: Bool) {
        if shouldShow {
            Logger.debug("Password reset view should be shown", category: .auth)
        }
    }
    
    private func handleAuthChange(_ newValue: Bool) {
        localizationManager.updateLanguageForAuthState(isAuthenticated: newValue)
        
        if newValue {
            checkOnboardingStatus()
            checkSubscriptionStatus()
        } else {
            showOnboarding = false
            showSubscriptionPaywall = false
        }
    }
    
    private func handleSubscriptionChange(_ isActive: Bool) {
        if isActive {
            showSubscriptionPaywall = false
        }
    }
    
    private func handleLanguageChange(_ notification: Notification) {
        if !showOnboarding {
            if app.showSettings || app.showLanguageSettings {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !app.showSettings && !app.showLanguageSettings {
                    languageRefreshTrigger = UUID()
                }
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showOnboarding = false
    @State private var showSubscriptionPaywall = false
    @State private var languageRefreshTrigger = UUID()
    @State private var hasTrackedLaunch = false

    var body: some View {
        contentView
            .modifier(RootViewModifiers(
                app: app,
                showOnboarding: $showOnboarding,
                showSubscriptionPaywall: $showSubscriptionPaywall,
                languageRefreshTrigger: $languageRefreshTrigger,
                hasTrackedLaunch: $hasTrackedLaunch,
                scenePhase: scenePhase,
                localizationManager: localizationManager,
                checkOnboardingStatus: checkOnboardingStatus,
                checkSubscriptionStatus: checkSubscriptionStatus
            ))
    }
    
    @ViewBuilder
    private var contentView: some View {
        if app.isAuthenticated {
            if app.isInitialDataLoaded {
                // Check onboarding status before showing main view
                if shouldShowOnboarding() {
                    OnboardingView()
                        .onAppear {
                            // Set flag so we know onboarding is showing
                            showOnboarding = true
                        }
                        .onDisappear {
                            showOnboarding = false
                            checkSubscriptionStatus()
                        }
                } else {
                authenticatedContentView
                }
            } else {
                LoadingView()
            }
        } else {
            AuthView()
                .id(localizationManager.currentLanguage)
        }
    }
    
    private var authenticatedContentView: some View {
        MainTabView()
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
            // DEVELOPMENT MODE: Paywall disabled
            // .fullScreenCover(isPresented: $showSubscriptionPaywall, onDismiss: paywallDismissed) {
            //     RevenueCatPaywallView()
            //         .environmentObject(app)
            //         .interactiveDismissDisabled(true)
            // }
            .onAppear {
                checkSubscriptionStatus()
            }
            .onChange(of: showOnboarding) { _, nowShown in
                if nowShown == false {
                    checkSubscriptionStatus()
                }
            }
    }
    
    private func shouldShowOnboarding() -> Bool {
        guard let userId = KeychainManager.get(key: "user_id") else { return false }
        let key = "onboarding_completed_\(userId)"
        return !UserDefaults.standard.bool(forKey: key)
    }
    
    private func paywallDismissed() {
        if let userId = KeychainManager.get(key: "user_id") {
            let key = "paywall_dismissed_\(userId)"
            UserDefaults.standard.set(true, forKey: key)
        }
    }
    
    private func onboardingCompletedForCurrentUser() -> Bool {
        guard let userId = KeychainManager.get(key: "user_id") else { return false }
        let key = "onboarding_completed_\(userId)"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func paywallDismissedForCurrentUser() -> Bool {
        guard let userId = KeychainManager.get(key: "user_id") else { return false }
        let key = "paywall_dismissed_\(userId)"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func checkOnboardingStatus() {
        // Check if onboarding is completed for THIS user
        guard let userId = KeychainManager.get(key: "user_id") else { return }
        let key = "onboarding_completed_\(userId)"
        let completed = UserDefaults.standard.bool(forKey: key)
        
        if !completed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showOnboarding = true
            }
        }
    }
    
    private func checkSubscriptionStatus() {
        // DEVELOPMENT MODE: Paywall disabled
        // Always trigger a refresh in the background
        app.loadSubscriptionStatus()
        
        // Don't show paywall in development
        showSubscriptionPaywall = false
    }
}

struct MainTabView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showNotifications = false
    @State private var showDeepLinkRecipe = false
    @State private var deepLinkRecipeToShow: Recipe? = nil
    @State private var animationTrigger: UUID = UUID()
    @State private var previousTab: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $app.selectedTab) {
                ChatView()
                    .tabItem { EmptyView() }
                    .tag(0)
                    .id("\(localizationManager.currentLanguage)_0_\(animationTrigger)")
                    .modifier(PageTransitionModifier(tabIndex: 0, selectedTab: app.selectedTab))
                RecipeCreatorView()
                    .tabItem { EmptyView() }
                    .tag(1)
                    .id("\(localizationManager.currentLanguage)_1_\(animationTrigger)")
                    .modifier(PageTransitionModifier(tabIndex: 1, selectedTab: app.selectedTab))
                RecipesView()
                    .tabItem { EmptyView() }
                    .tag(2)
                    .id("\(localizationManager.currentLanguage)_2_\(animationTrigger)")
                    .modifier(PageTransitionModifier(tabIndex: 2, selectedTab: app.selectedTab))
                ShoppingListView()
                    .tabItem { EmptyView() }
                    .tag(3)
                    .id("\(localizationManager.currentLanguage)_3_\(animationTrigger)")
                    .modifier(PageTransitionModifier(tabIndex: 3, selectedTab: app.selectedTab))
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Text("CulinaAi")
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showNotifications = true }) {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                            .padding(6)
                            .background(.white, in: Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                    
                    Button(action: { app.showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                            .padding(6)
                            .background(.white, in: Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                .white,
                ignoresSafeAreaEdges: .top
            )
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 1),
                alignment: .bottom
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 0) {
                TabBarButton(icon: "sparkles", title: L.tabKulina.localized, tag: 0, selectedTab: $app.selectedTab)
                TabBarButton(icon: "frying.pan", title: L.tabRecipes.localized, tag: 1, selectedTab: $app.selectedTab)
                TabBarButton(icon: "book", title: L.tabRecipeBook.localized, tag: 2, selectedTab: $app.selectedTab)
                TabBarButton(icon: "cart", title: L.tabShopping.localized, tag: 3, selectedTab: $app.selectedTab)
            }
            .id(localizationManager.currentLanguage)
            .padding(.horizontal)
            .padding(.bottom, -8)
        }
        .background(
LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.78, blue: 0.68),
                    Color(red: 0.95, green: 0.74, blue: 0.64),
                    Color(red: 0.93, green: 0.66, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showNotifications) {
            NotificationsSettingsSheet()
                .presentationDetents([PresentationDetent.large])
        }
        .sheet(isPresented: $app.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showDeepLinkRecipe) {
            if let recipe = deepLinkRecipeToShow {
                NavigationView {
                    RecipeDetailView(recipe: recipe)
                        .environmentObject(app)
                }
            }
        }
        .onChange(of: app.deepLinkRecipe) { _, newRecipe in
            if let recipe = newRecipe {
                deepLinkRecipeToShow = recipe
                showDeepLinkRecipe = true
                // Reset after showing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    app.deepLinkRecipe = nil
                }
            }
        }
        .onChange(of: app.selectedTab) { oldValue, newValue in
            // Trigger rebuild when tab changes
            if oldValue != newValue {
                previousTab = oldValue
                animationTrigger = UUID()
            }
        }
        .onAppear {
            previousTab = app.selectedTab
        }
    }
}

// MARK: - Page Transition Modifier
struct PageTransitionModifier: ViewModifier {
    let tabIndex: Int
    let selectedTab: Int
    @State private var isVisible = false
    
    var isActive: Bool {
        selectedTab == tabIndex
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.98)
            .offset(y: isVisible ? 0 : 10)
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == tabIndex && oldValue != tabIndex {
                    // Tab just became active - trigger fast animation
                    isVisible = false
                    withAnimation(.easeOut(duration: 0.15)) {
                        isVisible = true
                    }
                } else if newValue != tabIndex {
                    // Tab is no longer active
                    isVisible = false
                }
            }
            .onAppear {
                if isActive {
                    isVisible = false
                    withAnimation(.easeOut(duration: 0.15)) {
                        isVisible = true
                    }
                }
            }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let tag: Int
    @Binding var selectedTab: Int
    
    private var isSelected: Bool { selectedTab == tag }
    
    var body: some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? Color(red: 0.95, green: 0.5, blue: 0.3) : .white)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "Aktuell ausgewählt" : "Wechselt zu \(title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legal Placeholder View
private struct LegalPlaceholderView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let title: String
    let text: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(text)
                        .font(.body)
                        .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.done.localized) { dismiss() }
                }
            }
        }
    }
}

