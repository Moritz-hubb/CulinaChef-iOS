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

                        ForEach(Array(plan.meals.enumerated()), id: \.element.id) { index, meal in
                            Button {
                                selectedRecipe = meal.recipe
                            } label: {
                                MealPlanMealCard(
                                    index: index,
                                    slot: meal.slot,
                                    title: meal.recipe.title,
                                    calories: meal.recipe.nutrition?.calories,
                                    proteinG: meal.recipe.nutrition?.protein_g.map { Int($0.rounded()) },
                                    minutes: meal.recipe.total_time_minutes,
                                    onLight: false
                                )
                            }
                            .buttonStyle(.plain)
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
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                }
                .disabled(saving || saved)
                .opacity(saving || saved ? 0.7 : 1)
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
        }
        .navigationViewStyle(.stack)
    }

    private var dailyCalories: Int? {
        if let c = nutritionTargets.calories, c > 0 { return c }
        let sum = plan.meals.compactMap { $0.recipe.nutrition?.calories }.reduce(0, +)
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
        let values = plan.meals.compactMap { meal -> Double? in
            guard let n = meal.recipe.nutrition else { return nil }
            return key(n)
        }
        guard !values.isEmpty else { return nil }
        return Int(values.reduce(0, +).rounded())
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
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(mutedColor.opacity(0.8))
                .padding(.top, 6)
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
