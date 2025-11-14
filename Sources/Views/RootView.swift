import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showOnboarding = false
    @State private var showSubscriptionPaywall = false
    @State private var languageRefreshTrigger = UUID()

    var body: some View {
        Group {
            if app.isAuthenticated {
                MainTabView()
                    .fullScreenCover(isPresented: $showOnboarding) {
                        OnboardingView()
                    }
                    .fullScreenCover(isPresented: $showSubscriptionPaywall, onDismiss: {
                        // Mark paywall as dismissed for this user
                        if let userId = KeychainManager.get(key: "user_id") {
                            let key = "paywall_dismissed_\(userId)"
                            UserDefaults.standard.set(true, forKey: key)
                        }
                    }) {
                        PaywallView()
                            .environmentObject(app)
                            .interactiveDismissDisabled(true)
                    }
                    .onAppear {
                        checkOnboardingStatus()
                        checkSubscriptionStatus()
                    }
                    .onChange(of: showOnboarding) { _, nowShown in
                        if nowShown == false {
                            // After onboarding dismissed, enforce paywall if needed
                            checkSubscriptionStatus()
                        }
                    }
            } else {
                AuthView()
            }
        }
        .alert(L.error.localized, isPresented: Binding(get: { app.error != nil }, set: { if !$0 { app.error = nil } })) {
            Button(L.ok.localized) { app.error = nil }
        } message: {
            Text(app.error ?? "")
        }
        .onChange(of: app.isAuthenticated) { _, newValue in
            if newValue {
                checkOnboardingStatus()
                checkSubscriptionStatus()
            } else {
                showOnboarding = false
                showSubscriptionPaywall = false
            }
        }
        .onChange(of: app.isSubscribed) { _, isActive in
            if isActive {
                showSubscriptionPaywall = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Force view refresh by updating UUID
            languageRefreshTrigger = UUID()
        }
        .id(languageRefreshTrigger)
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
        // Only enforce paywall after onboarding is completed
        guard app.isAuthenticated else { return }
        guard onboardingCompletedForCurrentUser() else { return }
        
        // Always trigger a refresh in the background
        app.loadSubscriptionStatus()
        
        // Avoid flashing the paywall before we have any subscription info
        guard app.subscriptionStatusInitialized else { return }
        
        if !app.isSubscribed && !paywallDismissedForCurrentUser() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showSubscriptionPaywall = true
            }
        } else {
            showSubscriptionPaywall = false
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showNotifications = false
    @State private var showSettings = false
    @State private var showDeepLinkRecipe = false
    @State private var deepLinkRecipeToShow: Recipe? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $app.selectedTab) {
                ChatView()
                    .tabItem { EmptyView() }
                    .tag(0)
                RecipeCreatorView()
                    .tabItem { EmptyView() }
                    .tag(1)
                RecipesView()
                    .tabItem { EmptyView() }
                    .tag(2)
                ShoppingListView()
                    .tabItem { EmptyView() }
                    .tag(3)
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
                    
                    Button(action: { showSettings = true }) {
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
            .padding(.bottom, 4)
            .background(.ultraThinMaterial.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
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
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSettings) {
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

