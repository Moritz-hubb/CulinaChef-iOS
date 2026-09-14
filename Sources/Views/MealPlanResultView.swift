import SwiftUI

struct MealPlanResultView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    let plan: GeneratedMealPlan
    let nutritionMode: String
    let nutritionTargets: MealPlanNutritionTargets
    let dietaryContext: String

    @State private var selectedRecipe: RecipePlan?
    @State private var saving = false
    @State private var error: String?
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
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

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(plan.title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(L.mealplan_resultHint.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))

                        ForEach(plan.meals) { meal in
                            Button {
                                selectedRecipe = meal.recipe
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(MealPlanSlot.localizedTitle(meal.slot))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text(meal.recipe.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    if let kcal = meal.recipe.nutrition?.calories {
                                        Text("\(kcal) kcal")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: { Task { await save() } }) {
                            HStack {
                                if saving { ProgressView().tint(.white) }
                                else { Image(systemName: "square.and.arrow.down") }
                                Text(L.mealplan_save.localized)
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
                                in: Capsule()
                            )
                        }
                        .disabled(saving || saved)
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.button_done.localized) { dismiss() }
                        .foregroundStyle(.white)
                }
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
        }
        .navigationViewStyle(.stack)
    }

    private func save() async {
        guard let token = app.accessToken,
              let userId = KeychainManager.get(key: "user_id"), !userId.isEmpty else {
            error = L.errorNotLoggedIn.localized
            return
        }
        saving = true
        defer { saving = false }
        let lang = app.currentLanguageCode()
        let recipes = plan.meals.map { meal in
            meal.recipe.asPersistedRecipe(
                userId: userId,
                languageCode: lang,
                extraTags: ["_slot:\(meal.slot)"]
            )
        }
        do {
            _ = try await MealPlanStore().saveGeneratedPlan(
                plan,
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

