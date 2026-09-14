import SwiftUI

struct MealPlansListView: View {
    @EnvironmentObject var app: AppState
    @State private var plans: [SavedMealPlan] = []
    @State private var loading = true
    @State private var error: String?
    @State private var toDelete: SavedMealPlan?
    @State private var selected: SavedMealPlan?

    var body: some View {
        Group {
            if loading {
                ProgressView().tint(Color(red: 0.85, green: 0.4, blue: 0.2))
            } else if let error {
                Text(error).foregroundColor(.red).padding()
            } else if plans.isEmpty {
                VStack(spacing: 12) {
                    Text("🗓️").font(.system(size: 56))
                    Text(L.mealplan_emptyTitle.localized)
                        .font(.title3.bold())
                    Text(L.mealplan_emptyBody.localized)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.55))
                        .multilineTextAlignment(.center)
                    Button {
                        app.selectedTab = 1
                    } label: {
                        Text(L.mealplan_createCta.localized)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                }
                .padding(24)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(plans) { plan in
                            Button { selected = plan } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plan.title)
                                            .font(.headline)
                                            .foregroundColor(.black.opacity(0.85))
                                        Text(L.mealplan_cardSubtitle.localized(replacing: ["count": "\(plan.meal_count)"]))
                                            .font(.caption)
                                            .foregroundColor(.black.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.black.opacity(0.3))
                                }
                                .padding(14)
                                .background(Color(UIColor.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { toDelete = plan } label: {
                                    Label(L.delete.localized, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $selected) { plan in
            MealPlanDetailView(plan: plan)
        }
        .alert(L.mealplan_deleteTitle.localized, isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } })) {
            Button(L.delete.localized, role: .destructive) {
                if let plan = toDelete {
                    Task { await delete(plan) }
                }
            }
            Button(L.cancel.localized, role: .cancel) { toDelete = nil }
        }
    }

    private func load() async {
        guard let token = app.accessToken,
              let userId = KeychainManager.get(key: "user_id") else {
            loading = false
            error = L.errorNotLoggedIn.localized
            return
        }
        do {
            plans = try await MealPlanStore().fetchPlans(accessToken: token, userId: userId)
            error = nil
        } catch {
            self.error = ErrorMessageHelper.userFriendlyMessage(from: error)
        }
        loading = false
    }

    private func delete(_ plan: SavedMealPlan) async {
        guard let token = app.accessToken else { return }
        do {
            try await MealPlanStore().deletePlan(id: plan.id, accessToken: token)
            plans.removeAll { $0.id == plan.id }
        } catch {
            self.error = ErrorMessageHelper.userFriendlyMessage(from: error)
        }
        toDelete = nil
    }
}

struct MealPlanDetailView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let plan: SavedMealPlan
    @State private var recipes: [Recipe] = []
    @State private var items: [SavedMealPlanItem] = []
    @State private var loading = true
    @State private var pushRecipe: Recipe?

    var body: some View {
        NavigationView {
            Group {
                if loading {
                    ProgressView()
                } else {
                    List {
                        ForEach(items) { item in
                            if let recipe = recipes.first(where: { $0.id == item.recipe_id }) {
                                Button {
                                    pushRecipe = recipe
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(MealPlanSlot.localizedTitle(item.slot))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(recipe.title)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(plan.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.button_done.localized) { dismiss() }
                }
            }
            .task { await load() }
            .sheet(item: $pushRecipe) { recipe in
                NavigationView {
                    RecipeDetailView(recipe: recipe)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func load() async {
        guard let token = app.accessToken else {
            loading = false
            return
        }
        do {
            let fetched = try await MealPlanStore().fetchItems(accessToken: token, planId: plan.id)
            items = fetched
            let ids = fetched.map(\.recipe_id)
            recipes = try await fetchRecipes(ids: ids, token: token)
        } catch {
            Logger.error("Meal plan detail load failed: \(error)", category: .network)
        }
        loading = false
    }

    private func fetchRecipes(ids: [String], token: String) async throws -> [Recipe] {
        guard !ids.isEmpty else { return [] }
        let sanitized = ids.compactMap { UUID(uuidString: $0)?.uuidString.lowercased() }
        guard !sanitized.isEmpty else { return [] }
        var url = Config.supabaseURL
        url.append(path: "/rest/v1/recipes")
        url.append(queryItems: [
            URLQueryItem(name: "id", value: "in.(\(sanitized.joined(separator: ",")))"),
            URLQueryItem(name: "select", value: "*")
        ])
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await SecureURLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([Recipe].self, from: data)
    }
}

