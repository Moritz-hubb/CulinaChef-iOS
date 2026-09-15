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
                VStack(spacing: 14) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.75))
                    Text(L.mealplan_emptyTitle.localized)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.black.opacity(0.78))
                        .multilineTextAlignment(.center)
                    Text(L.mealplan_emptyBody.localized)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.42))
                        .multilineTextAlignment(.center)
                    Button {
                        app.selectedTab = 1
                    } label: {
                        Text(L.mealplan_createCta.localized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    }
                    .padding(.top, 4)
                }
                .padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(plans) { plan in
                            Button { selected = plan } label: {
                                MealPlanBookCard(plan: plan)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { toDelete = plan } label: {
                                    Label(L.delete.localized, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
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
        } message: {
            Text(L.mealplan_deleteBody.localized)
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
            let recipeIds = try await MealPlanStore().deletePlan(id: plan.id, accessToken: token)
            plans.removeAll { $0.id == plan.id }
            if selected?.id == plan.id { selected = nil }
            removeRecipesFromCache(recipeIds)
        } catch {
            self.error = ErrorMessageHelper.userFriendlyMessage(from: error)
        }
        toDelete = nil
    }

    private func removeRecipesFromCache(_ recipeIds: [String]) {
        guard !recipeIds.isEmpty else { return }
        let ids = Set(recipeIds)
        app.cachedRecipes.removeAll { ids.contains($0.id) }
        app.saveCachedRecipesToDisk(recipes: app.cachedRecipes, menus: app.cachedMenus)
        NotificationCenter.default.post(name: .culinaDeletedRecipeIds, object: recipeIds)
    }
}

private struct MealPlanBookCard: View {
    let plan: SavedMealPlan

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Rectangle()
                .fill(Color(red: 0.95, green: 0.5, blue: 0.3))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black.opacity(0.86))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(metaLine)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.42))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black.opacity(0.22))
                .padding(.trailing, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var metaLine: String {
        var parts = [L.mealplan_cardSubtitle.localized(replacing: ["count": "\(plan.meal_count)"])]
        if let date = formattedDate { parts.append(date) }
        return parts.joined(separator: "  ·  ")
    }

    private var formattedDate: String? {
        guard let raw = plan.created_at, !raw.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: raw) ?? {
            iso.formatOptions = [.withInternetDateTime]
            return iso.date(from: raw)
        }()
        guard let date else { return nil }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .none
        return out.string(from: date)
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
            ZStack {
                MealPlanChrome.background.ignoresSafeArea()

                if loading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            MealPlanHeroCard(
                                title: plan.title,
                                mealCount: plan.meal_count,
                                calories: plan.nutrition_targets?.calories,
                                protein: plan.nutrition_targets?.protein_g,
                                fat: plan.nutrition_targets?.fat_g,
                                carbs: plan.nutrition_targets?.carbs_g,
                                onLight: false
                            )

                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                if let recipe = recipes.first(where: { $0.id == item.recipe_id }) {
                                    Button {
                                        pushRecipe = recipe
                                    } label: {
                                        MealPlanMealCard(
                                            index: index,
                                            slot: item.slot,
                                            title: recipe.title,
                                            calories: recipe.nutrition?.calories,
                                            proteinG: recipe.nutrition?.protein_g.map { Int($0.rounded()) },
                                            minutes: cookingMinutes(recipe.cooking_time),
                                            onLight: false
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .accessibilityLabel(L.close.localized)
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

    private func cookingMinutes(_ cookingTime: String?) -> Int? {
        guard let cookingTime else { return nil }
        let digits = cookingTime.filter(\.isNumber)
        return Int(digits)
    }

    private func load() async {
        guard let token = app.accessToken else {
            loading = false
            return
        }
        do {
            let fetched = try await MealPlanStore().fetchItems(accessToken: token, planId: plan.id)
            items = fetched.sorted { $0.sort_order < $1.sort_order }
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
