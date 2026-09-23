import SwiftUI

struct MealPlanResultView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    let plan: GeneratedMealPlan
    let nutritionMode: String
    let nutritionTargets: MealPlanNutritionTargets
    let dietaryContext: String

    @State private var meals: [GeneratedMealPlanMeal]
    @State private var failedIndices: Set<Int> = []
    @State private var selectedRecipe: RecipePlan?
    @State private var saving = false
    @State private var error: String?
    @State private var saved = false

    private let maxConcurrentRecipeFills = 2

    init(
        plan: GeneratedMealPlan,
        nutritionMode: String,
        nutritionTargets: MealPlanNutritionTargets,
        dietaryContext: String
    ) {
        self.plan = plan
        self.nutritionMode = nutritionMode
        self.nutritionTargets = nutritionTargets
        self.dietaryContext = dietaryContext
        _meals = State(initialValue: plan.meals)
    }

    var body: some View {
        NavigationView {
            ZStack {
                MealPlanChrome.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        MealPlanHeroCard(
                            title: plan.title,
                            mealCount: plan.meal_count,
                            calories: dailyCalories,
                            protein: dailyProtein,
                            fat: dailyFat,
                            carbs: dailyCarbs,
                            onLight: false
                        )

                        ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                            mealRow(index: index, meal: meal)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 8)
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
            .safeAreaInset(edge: .bottom) {
                Button(action: { Task { await save() } }) {
                    HStack {
                        if saving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                        }
                        Text(allRecipesReady ? L.mealplan_save.localized : L.mealplan_saveNeedsRecipes.localized)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                }
                .disabled(saving || saved || !allRecipesReady)
                .opacity(saving || saved || !allRecipesReady ? 0.7 : 1)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.93, green: 0.66, blue: 0.55).opacity(0), Color(red: 0.93, green: 0.66, blue: 0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                )
            }
            .sheet(isPresented: Binding(get: { selectedRecipe != nil }, set: { if !$0 { selectedRecipe = nil } })) {
                if let selectedRecipe {
                    RecipeResultView(plan: selectedRecipe)
                }
            }
            .alert(L.alert_error.localized, isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button(L.button_ok.localized) { error = nil }
            } message: { Text(error ?? "") }
            .alert(L.alert_successfullySaved.localized, isPresented: $saved) {
                Button(L.button_ok.localized) {
                    app.selectedTab = 2
                    dismiss()
                }
            }
            .task {
                await fillMissingRecipes()
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func mealRow(index: Int, meal: GeneratedMealPlanMeal) -> some View {
        let failed = failedIndices.contains(index)
        let loading = meal.recipe == nil && !failed
        let card = MealPlanMealCard(
            index: index,
            slot: meal.slot,
            title: meal.recipe?.title ?? (failed ? L.mealplan_recipeFailed.localized : L.mealplan_creatingRecipe.localized),
            calories: meal.recipe?.nutrition?.calories,
            proteinG: meal.recipe?.nutrition?.protein_g.map { Int($0.rounded()) },
            minutes: meal.recipe?.total_time_minutes,
            onLight: false,
            isLoading: loading,
            failed: failed,
            onRetry: failed ? { Task { await retryMeal(at: index) } } : nil
        )

        if let recipe = meal.recipe {
            Button {
                selectedRecipe = recipe
            } label: {
                card
            }
            .buttonStyle(.plain)
        } else {
            card
        }
    }

    private var allRecipesReady: Bool {
        !meals.isEmpty && meals.allSatisfy { $0.recipe != nil }
    }

    private var dailyCalories: Int? {
        if let c = nutritionTargets.calories, c > 0 { return c }
        let sum = meals.compactMap { $0.recipe?.nutrition?.calories }.reduce(0, +)
        return sum > 0 ? sum : nil
    }

    private var dailyProtein: Int? {
        if let p = nutritionTargets.protein_g, p > 0 { return p }
        return summedMacro { $0.protein_g }
    }

    private var dailyFat: Int? {
        if let f = nutritionTargets.fat_g, f > 0 { return f }
        return summedMacro { $0.fat_g }
    }

    private var dailyCarbs: Int? {
        if let c = nutritionTargets.carbs_g, c > 0 { return c }
        return summedMacro { $0.carbs_g }
    }

    private func summedMacro(_ key: (NutritionInfo) -> Double?) -> Int? {
        let values = meals.compactMap { meal -> Double? in
            guard let n = meal.recipe?.nutrition else { return nil }
            return key(n)
        }
        guard !values.isEmpty else { return nil }
        return Int(values.reduce(0, +).rounded())
    }

    private func fillMissingRecipes() async {
        let pending = meals.indices.filter { meals[$0].recipe == nil }
        guard !pending.isEmpty else { return }
        guard app.openAI != nil else {
            failedIndices.formUnion(pending)
            error = L.errorApiClientNotConfigured.localized
            return
        }

        await withTaskGroup(of: (Int, Result<RecipePlan, Error>).self) { group in
            var iterator = pending.makeIterator()
            var inFlight = 0

            func enqueueAvailable() {
                while inFlight < maxConcurrentRecipeFills, let index = iterator.next() {
                    inFlight += 1
                    let meal = meals[index]
                    group.addTask { @MainActor in
                        let result = await generateMealResult(meal)
                        return (index, result)
                    }
                }
            }

            enqueueAvailable()
            for await (index, result) in group {
                inFlight -= 1
                apply(result, at: index)
                if Task.isCancelled {
                    group.cancelAll()
                    return
                }
                enqueueAvailable()
            }
        }
    }

    private func retryMeal(at index: Int) async {
        guard meals.indices.contains(index), meals[index].recipe == nil else { return }
        failedIndices.remove(index)
        let meal = meals[index]
        let result = await generateMealResult(meal)
        apply(result, at: index)
    }

    private func generateMealResult(_ meal: GeneratedMealPlanMeal) async -> Result<RecipePlan, Error> {
        guard let openai = app.openAI else {
            return .failure(NSError(domain: "BackendOpenAI", code: 503, userInfo: [NSLocalizedDescriptionKey: L.errorApiClientNotConfigured.localized]))
        }
        do {
            let recipe = try await openai.generateMealPlanMeal(
                slot: meal.slot,
                goal: meal.goal,
                nutritionTarget: meal.nutrition_target,
                categories: meal.categories ?? [],
                dietaryContext: meal.dietary_context,
                servings: meal.servings ?? 1
            )
            return .success(recipe)
        } catch {
            return .failure(error)
        }
    }

    private func apply(_ result: Result<RecipePlan, Error>, at index: Int) {
        guard meals.indices.contains(index) else { return }
        switch result {
        case .success(let recipe):
            guard !recipe.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                failedIndices.insert(index)
                return
            }
            meals[index].recipe = recipe
            failedIndices.remove(index)
        case .failure(let err):
            failedIndices.insert(index)
            if app.handleAISubscriptionDenied(err) {
                failedIndices.formUnion(meals.indices.filter { meals[$0].recipe == nil })
                if error == nil {
                    error = ErrorMessageHelper.userFriendlyMessage(from: err)
                }
            }
        }
    }

    private func save() async {
        guard allRecipesReady else { return }
        guard let token = app.accessToken,
              let userId = KeychainManager.get(key: "user_id"), !userId.isEmpty else {
            error = L.errorNotLoggedIn.localized
            return
        }
        saving = true
        defer { saving = false }
        let lang = app.currentLanguageCode()
        let recipes = meals.compactMap { meal -> Recipe? in
            guard let recipe = meal.recipe else { return nil }
            return recipe.asPersistedRecipe(
                userId: userId,
                languageCode: lang,
                extraTags: ["_slot:\(meal.slot)"]
            )
        }
        guard recipes.count == meals.count else {
            error = L.errorInvalidRecipeRequest.localized
            return
        }
        var savePlan = plan
        savePlan.meals = meals
        do {
            _ = try await MealPlanStore().saveGeneratedPlan(
                savePlan,
                recipes: recipes,
                nutritionMode: nutritionMode,
                nutritionTargets: nutritionTargets,
                dietaryContext: dietaryContext.isEmpty ? nil : String(dietaryContext.prefix(2000)),
                accessToken: token,
                userId: userId
            )
            saved = true
        } catch {
            self.error = ErrorMessageHelper.userFriendlyMessage(from: error)
        }
    }
}

enum MealPlanChrome {
    static var background: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.78, blue: 0.68),
                Color(red: 0.95, green: 0.74, blue: 0.64),
                Color(red: 0.93, green: 0.66, blue: 0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct MealPlanHeroCard: View {
    let title: String
    let mealCount: Int
    var calories: Int? = nil
    var protein: Int? = nil
    var fat: Int? = nil
    var carbs: Int? = nil
    var subtitle: String? = nil
    var onLight: Bool

    private var titleColor: Color { onLight ? Color.black.opacity(0.86) : .white }
    private var mutedColor: Color { onLight ? Color.black.opacity(0.42) : .white.opacity(0.7) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.mealplan_cardSubtitle.localized(replacing: ["count": "\(mealCount)"]).uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(mutedColor)

            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(titleColor)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(mutedColor)
            }

            if calories != nil || protein != nil || fat != nil || carbs != nil {
                Rectangle()
                    .fill(onLight ? Color.black.opacity(0.08) : Color.white.opacity(0.18))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    if let calories {
                        MealPlanMacroColumn(value: "\(calories)", unit: L.mealplan_kcal.localized, onLight: onLight)
                    }
                    if let protein {
                        MealPlanMacroColumn(value: "\(protein) g", unit: L.label_protein.localized, onLight: onLight)
                    }
                    if let fat {
                        MealPlanMacroColumn(value: "\(fat) g", unit: L.label_fat.localized, onLight: onLight)
                    }
                    if let carbs {
                        MealPlanMacroColumn(value: "\(carbs) g", unit: L.label_carbs.localized, onLight: onLight)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(onLight ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(onLight ? Color.black.opacity(0.06) : Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

struct MealPlanMealCard: View {
    let index: Int
    let slot: String
    let title: String
    var calories: Int? = nil
    var proteinG: Int? = nil
    var minutes: Int? = nil
    var onLight: Bool
    var isLoading: Bool = false
    var failed: Bool = false
    var onRetry: (() -> Void)? = nil

    private var titleColor: Color { onLight ? Color.black.opacity(0.86) : .white }
    private var mutedColor: Color { onLight ? Color.black.opacity(0.42) : .white.opacity(0.68) }

    private var metaLine: String? {
        var parts: [String] = []
        if let calories { parts.append("\(calories) kcal") }
        if let proteinG { parts.append("\(proteinG) g \(L.label_protein.localized)") }
        if let minutes { parts.append("\(minutes) min") }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 13, weight: .medium, design: .default).monospacedDigit())
                .foregroundStyle(mutedColor)
                .frame(width: 28, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(MealPlanSlot.localizedTitle(slot).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(mutedColor)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(titleColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let metaLine {
                    Text(metaLine)
                        .font(.system(size: 13))
                        .foregroundStyle(mutedColor)
                }
            }

            Spacer(minLength: 8)
            if isLoading {
                ProgressView()
                    .tint(titleColor)
                    .padding(.top, 4)
                    .accessibilityLabel(L.mealplan_creatingRecipe.localized)
            } else if failed, let onRetry {
                Button(action: onRetry) {
                    Text(L.mealplan_retry.localized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(titleColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(L.mealplan_retry.localized), \(title)")
                .padding(.top, 2)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(mutedColor.opacity(0.8))
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(onLight ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(onLight ? Color.black.opacity(0.06) : Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct MealPlanMacroColumn: View {
    let value: String
    let unit: String
    var onLight: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
            Text(unit)
                .font(.system(size: 11))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(onLight ? Color.black.opacity(0.8) : .white)
        .frame(maxWidth: .infinity)
    }
}
