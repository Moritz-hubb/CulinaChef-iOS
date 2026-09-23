import SwiftUI

struct MealPlanCreatorView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @FocusState private var isFocused: Bool

    @State private var selectedSlots: [String] = MealPlanSlot.defaultSelection
    @State private var snackCount: Int = 0
    @State private var notes: String = ""
    @State private var nutritionModeExact = false

    @State private var calories: String = ""
    @State private var proteinPct: Double = 30
    @State private var fatPct: Double = 30
    @State private var carbsPct: Double = 40
    @State private var caloriesMin: String = ""
    @State private var caloriesMax: String = ""
    @State private var proteinMin: String = ""
    @State private var proteinMax: String = ""
    @State private var fatMin: String = ""
    @State private var fatMax: String = ""
    @State private var carbsMin: String = ""
    @State private var carbsMax: String = ""

    @State private var selectedCategories: Set<String> = []
    @State private var spicyLevel: Double = 2
    @State private var tastePreferences: [String: Bool] = [:]
    @State private var slotPrefs: [String: MealSlotPrefState] = [:]
    @State private var expandedSlotPrefs: Set<String> = []

    @State private var generating = false
    @State private var error: String?
    @State private var showConsentDialog = false
    @State private var generated: GeneratedMealPlan?
    @State private var showResult = false

    private var categoryOptions: [String] {
        [
            L.category_vegetarian.localized,
            L.category_vegan.localized,
            L.category_pescetarian.localized,
            L.category_lowCarb.localized,
            L.category_highProtein.localized,
            L.category_glutenFree.localized,
            L.category_lactoseFree.localized,
            L.category_halal.localized,
            L.category_kosher.localized
        ]
    }

    private var spicyLabels: [String] {
        [L.spicy_mild.localized, L.spicy_normal.localized, L.spicy_hot.localized, L.spicy_veryHot.localized]
    }

    private var tastePreferenceKeys: [String] {
        [L.taste_sweet.localized, L.taste_sour.localized, L.taste_bitter.localized, L.taste_umami.localized]
    }

    var body: some View {
        Group {
            if generating {
                SearchingPenguinView()
            } else {
                form
            }
        }
        .sheet(isPresented: $showResult) {
            if let generated {
                MealPlanResultView(
                    plan: generated,
                    nutritionMode: nutritionModeExact ? "exact" : "range",
                    nutritionTargets: currentTargets(),
                    dietaryContext: buildDietaryContext()
                )
            }
        }
        .sheet(isPresented: $showConsentDialog) {
            OpenAIConsentDialog(
                onAccept: {
                    OpenAIConsentManager.hasConsent = true
                    Task { await generate() }
                },
                onDecline: { error = L.consent_required.localized }
            )
        }
        .alert(L.alert_error.localized, isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button(L.button_ok.localized) { error = nil }
        } message: {
            Text(error ?? "")
        }
        .onAppear { loadPreferences() }
    }

    private var form: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        GroupBoxLabel(L.mealplan_mealsCount.localized)
                        Spacer()
                        Text("\(plannedSlots.count)/6")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Text(L.mealplan_mealsHint.localized)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                    MealSlotChips(selected: $selectedSlots, reservedCount: snackCount)
                    HStack {
                        Text(L.mealplan_snacksCount.localized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        HStack(spacing: 8) {
                            Button {
                                if snackCount > 0 { snackCount -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                            .accessibilityLabel(L.a11y_decreaseCount.localized)
                            .accessibilityValue(L.mealplan_snacksCount.localized)
                            .disabled(snackCount == 0)
                            Text("\(snackCount)")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(minWidth: 28)
                            Button {
                                if snackCount < maxSnackCount { snackCount += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                            .accessibilityLabel(L.a11y_increaseCount.localized)
                            .accessibilityValue(L.mealplan_snacksCount.localized)
                            .disabled(snackCount >= maxSnackCount)
                        }
                    }
                    Text(L.mealplan_snacksHint.localized)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }

                GroupBoxLabel(L.mealplan_notes.localized)
                TextField(L.mealplan_notesPlaceholder.localized, text: $notes.limited(to: AIInputLimit.mealPlanNotes))
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .focused($isFocused)

                HStack {
                    GroupBoxLabel(L.label_nutrition.localized)
                    Spacer()
                    CulinaTabChips(
                        items: [
                            (false, L.mealplan_modeRange.localized),
                            (true, L.mealplan_modeExact.localized)
                        ],
                        selection: $nutritionModeExact,
                        style: .onGradient
                    )
                    .frame(maxWidth: 220)
                }

                if nutritionModeExact {
                    MealPlanNutrField(title: L.mealplan_kcal.localized, text: $calories, isFocused: $isFocused)
                    VStack(spacing: 14) {
                        HStack {
                            Text(L.mealplan_macroTotal.localized)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(macrosTotalPercent) %")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(macrosSumIs100 ? Color.white : Color.red)
                        }
                        MealPlanMacroSlider(title: L.mealplan_protein.localized, percent: $proteinPct, grams: proteinGrams)
                        MealPlanMacroSlider(title: L.mealplan_fat.localized, percent: $fatPct, grams: fatGrams)
                        MealPlanMacroSlider(title: L.mealplan_carbs.localized, percent: $carbsPct, grams: carbsGrams)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow {
                            MealPlanNutrField(title: L.label_kcalMin.localized, text: $caloriesMin, isFocused: $isFocused)
                            MealPlanNutrField(title: L.label_kcalMax.localized, text: $caloriesMax, isFocused: $isFocused)
                        }
                        GridRow {
                            MealPlanNutrField(title: L.label_proteinMin.localized, text: $proteinMin, isFocused: $isFocused)
                            MealPlanNutrField(title: L.label_proteinMax.localized, text: $proteinMax, isFocused: $isFocused)
                        }
                        GridRow {
                            MealPlanNutrField(title: L.label_fatMin.localized, text: $fatMin, isFocused: $isFocused)
                            MealPlanNutrField(title: L.label_fatMax.localized, text: $fatMax, isFocused: $isFocused)
                        }
                        GridRow {
                            MealPlanNutrField(title: L.label_carbsMin.localized, text: $carbsMin, isFocused: $isFocused)
                            MealPlanNutrField(title: L.label_carbsMax.localized, text: $carbsMax, isFocused: $isFocused)
                        }
                    }
                }

                HStack {
                    GroupBoxLabel(L.label_categories.localized)
                    Spacer()
                    Button(action: { app.selectedTab = 2 }) {
                        HStack(spacing: 6) {
                            Image(systemName: "leaf")
                            Text(L.recipe_ernährung.localized)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                    }
                }
                WrapChips(options: categoryOptions, selection: $selectedCategories, disabled: disabledMacroCategories)

                GroupBoxLabel(L.label_tastePreferences.localized)
                VStack(spacing: 10) {
                    HStack {
                        Text(L.label_spicyLevel.localized).font(.callout).foregroundStyle(.white)
                        Spacer()
                        Text(spicyLabels[Int(spicyLevel)])
                            .font(.callout.weight(.medium))
                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                    }
                    Slider(value: $spicyLevel, in: 0...3, step: 1)
                        .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                    ForEach(tastePreferenceKeys, id: \.self) { key in
                        Toggle(key, isOn: Binding(
                            get: { tastePreferences[key] ?? false },
                            set: { tastePreferences[key] = $0 }
                        ))
                        .font(.callout)
                        .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    GroupBoxLabel(L.mealplan_perMealPrefs.localized)
                    Text(L.mealplan_perMealPrefsHint.localized)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                    ForEach(plannedSlots, id: \.self) { slot in
                        MealSlotPreferenceCard(
                            slot: slot,
                            categoryOptions: categoryOptions,
                            disabledCategories: disabledMacroCategories,
                            spicyLabels: spicyLabels,
                            tasteKeys: tastePreferenceKeys,
                            state: Binding(
                                get: { slotPrefs[slot] ?? MealSlotPrefState() },
                                set: { slotPrefs[slot] = $0 }
                            ),
                            expanded: Binding(
                                get: { expandedSlotPrefs.contains(slot) },
                                set: { isOn in
                                    if isOn { expandedSlotPrefs.insert(slot) } else { expandedSlotPrefs.remove(slot) }
                                }
                            ),
                            isFocused: $isFocused
                        )
                    }
                }

                Button(action: { Task { await generate() } }) {
                    HStack { Image(systemName: "wand.and.stars"); Text(L.mealplan_generate.localized) }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 6)
                        .opacity(canGeneratePlan ? 1 : 0.45)
                }
                .disabled(!canGeneratePlan)
                .accessibilityLabel(L.mealplan_generate.localized)
            }
            .foregroundStyle(.white)
            .padding(16)
            .onTapGesture { isFocused = false }
            .onChange(of: nutritionSpecified) { _, specified in
                if specified { selectedCategories.subtract(macroCategoryLabels) }
            }
            .onChange(of: selectedSlots) { _, slots in
                pruneSlotPrefs(keep: MealPlanSlot.assembled(types: slots, snackCount: snackCount))
                if snackCount > maxSnackCount { snackCount = maxSnackCount }
            }
            .onChange(of: snackCount) { _, count in
                pruneSlotPrefs(keep: MealPlanSlot.assembled(types: selectedSlots, snackCount: count))
            }
        }
    }

    private func loadPreferences() {
        for key in tastePreferenceKeys { tastePreferences[key] = false }
        selectedCategories = app.dietary.diets
        let prefs = TastePreferencesManager.load()
        spicyLevel = prefs.spicyLevel
        tastePreferences[L.taste_sweet.localized] = prefs.sweet
        tastePreferences[L.taste_sour.localized] = prefs.sour
        tastePreferences[L.taste_bitter.localized] = prefs.bitter
        tastePreferences[L.taste_umami.localized] = prefs.umami
    }

    private func buildDietaryContext() -> String {
        var parts: [String] = []
        if !app.dietary.allergies.isEmpty {
            parts.append(L.creator_allergiesLabel.localized + " " + app.dietary.allergies.joined(separator: ", "))
        }
        if !selectedCategories.subtracting(disabledMacroCategories).isEmpty {
            parts.append(L.creator_dietsLabel.localized + " " + selectedCategories.subtracting(disabledMacroCategories).sorted().joined(separator: ", "))
        }
        parts.append(L.creator_spicyLabel.localized + " " + spicyLabels[Int(spicyLevel)])
        var tastes: [String] = []
        if tastePreferences[L.taste_sweet.localized] == true { tastes.append(L.taste_sweet.localized) }
        if tastePreferences[L.taste_sour.localized] == true { tastes.append(L.taste_sour.localized) }
        if tastePreferences[L.taste_bitter.localized] == true { tastes.append(L.taste_bitter.localized) }
        if tastePreferences[L.taste_umami.localized] == true { tastes.append(L.taste_umami.localized) }
        if !tastes.isEmpty {
            parts.append(L.creator_tastesLabel.localized + " " + tastes.joined(separator: ", "))
        }
        if parts.isEmpty { return "" }
        return L.creator_systemPrompt.localized + " " + parts.joined(separator: " | ")
    }

    private var macroCategoryLabels: Set<String> {
        [L.category_lowCarb.localized, L.category_highProtein.localized]
    }

    private var nutritionSpecified: Bool {
        if nutritionModeExact {
            return (Int(calories) ?? 0) > 0
        }
        return [caloriesMin, caloriesMax, proteinMin, proteinMax, fatMin, fatMax, carbsMin, carbsMax]
            .contains { (Int($0) ?? 0) > 0 }
    }

    private var disabledMacroCategories: Set<String> {
        nutritionSpecified ? macroCategoryLabels : []
    }

    private var categoriesForGeneration: [String] {
        var cats = selectedCategories
        if nutritionSpecified { cats.subtract(macroCategoryLabels) }
        return Array(cats)
    }

    private func mealPreferencesPayload() -> [MealPlanMealPreference] {
        plannedSlots.compactMap { slot in
            let state = slotPrefs[slot] ?? MealSlotPrefState()
            let slotNotes = AIInputLimit.clamp(state.notes.trimmingCharacters(in: .whitespacesAndNewlines), to: AIInputLimit.mealSlotNotes)
            guard state.customized || state.spicyOverride != nil || state.overrideTastes || !slotNotes.isEmpty else { return nil }
            var cats = state.categories
            if nutritionSpecified { cats.subtract(macroCategoryLabels) }
            return MealPlanMealPreference(
                slot: slot,
                override_diets: state.customized,
                categories: state.customized ? Array(cats) : [],
                spicy_level: state.spicyOverride,
                override_tastes: state.overrideTastes,
                tastes: state.overrideTastes ? tastePreferenceKeys.filter { state.tastes[$0] == true } : [],
                notes: slotNotes.isEmpty ? nil : slotNotes
            )
        }
    }

    private var dailyCalories: Double {
        max(0, Double(Int(calories) ?? 0))
    }

    private var macrosTotalPercent: Int {
        Int(proteinPct.rounded()) + Int(fatPct.rounded()) + Int(carbsPct.rounded())
    }

    private var macrosSumIs100: Bool {
        macrosTotalPercent == 100
    }

    private var plannedSlots: [String] {
        MealPlanSlot.assembled(types: selectedSlots, snackCount: snackCount)
    }

    private var maxSnackCount: Int {
        min(MealPlanSlot.maxSnacks, MealPlanSlot.maxMeals - selectedSlots.count)
    }

    private func pruneSlotPrefs(keep: [String]) {
        let keepSet = Set(keep)
        slotPrefs = slotPrefs.filter { keepSet.contains($0.key) }
        expandedSlotPrefs = expandedSlotPrefs.intersection(keepSet)
    }

    private var canGeneratePlan: Bool {
        !generating && !plannedSlots.isEmpty && (!nutritionModeExact || macrosSumIs100)
    }

    private var proteinGrams: Int {
        Int((dailyCalories * proteinPct / 100 / 4).rounded())
    }

    private var fatGrams: Int {
        Int((dailyCalories * fatPct / 100 / 9).rounded())
    }

    private var carbsGrams: Int {
        Int((dailyCalories * carbsPct / 100 / 4).rounded())
    }

    private func currentTargets() -> MealPlanNutritionTargets {
        if nutritionModeExact {
            let kcal = Int(calories)
            return MealPlanNutritionTargets(
                calories: kcal,
                protein_g: kcal == nil || kcal == 0 ? nil : proteinGrams,
                fat_g: kcal == nil || kcal == 0 ? nil : fatGrams,
                carbs_g: kcal == nil || kcal == 0 ? nil : carbsGrams
            )
        }
        return MealPlanNutritionTargets(
            calories_min: Int(caloriesMin),
            calories_max: Int(caloriesMax),
            protein_min_g: Int(proteinMin),
            protein_max_g: Int(proteinMax),
            fat_min_g: Int(fatMin),
            fat_max_g: Int(fatMax),
            carbs_min_g: Int(carbsMin),
            carbs_max_g: Int(carbsMax)
        )
    }

    private func generate() async {
        if nutritionModeExact && !macrosSumIs100 {
            error = L.mealplan_macrosMustBe100.localized
            return
        }
        if app.isJailbroken {
            error = L.errorJailbreakDetected.localized
            return
        }
        guard await app.ensureAIAccess(for: .aiMealPlan) else { return }
        guard OpenAIConsentManager.hasConsent else {
            showConsentDialog = true
            return
        }
        error = nil
        generating = true
        defer { generating = false }
        guard let token = app.accessToken else {
            error = L.errorNotLoggedIn.localized
            return
        }
        do {
            let txnID = await app.getOriginalTransactionId()
            _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: txnID)
        } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
            Logger.info("Backend unreachable, continuing without usage tracking", category: .network)
        } catch {
            if app.handleAISubscriptionDenied(error) { return }
            self.error = ErrorMessageHelper.userFriendlyMessage(from: error)
            return
        }
        guard let openai = app.openAI else {
            error = L.errorApiClientNotConfigured.localized
            return
        }
        let customContext = buildDietaryContext()
        let fullContext = [customContext, app.languageSystemPrompt(), app.hiddenIntentContext()]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        let trimmedNotes = AIInputLimit.clamp(notes.trimmingCharacters(in: .whitespacesAndNewlines), to: AIInputLimit.mealPlanNotes)
        do {
            let plan = try await openai.generateMealPlan(
                mealCount: plannedSlots.count,
                slots: plannedSlots,
                nutritionMode: nutritionModeExact ? "exact" : "range",
                nutritionTargets: currentTargets(),
                categories: categoriesForGeneration,
                mealPreferences: mealPreferencesPayload(),
                dietaryContext: fullContext.isEmpty ? nil : AIInputLimit.clamp(fullContext, to: AIInputLimit.dietaryContext),
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            guard plan.meals.count == plannedSlots.count else {
                self.error = L.errorInvalidRecipeRequest.localized
                return
            }
            generated = plan
            showResult = true
            selectedCategories = app.dietary.diets
        } catch {
            if app.handleAISubscriptionDenied(error) { return }
            self.error = ErrorMessageHelper.userFriendlyMessage(from: error)
        }
    }
}

private struct MealSlotPrefState: Equatable {
    var customized = false
    var categories: Set<String> = []
    var spicyOverride: Int? = nil
    var overrideTastes = false
    var tastes: [String: Bool] = [:]
    var notes: String = ""
}

private struct MealSlotPreferenceCard: View {
    let slot: String
    let categoryOptions: [String]
    let disabledCategories: Set<String>
    let spicyLabels: [String]
    let tasteKeys: [String]
    @Binding var state: MealSlotPrefState
    @Binding var expanded: Bool
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                expanded.toggle()
            } label: {
                HStack {
                    Text(MealPlanSlot.localizedTitle(slot))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if state.customized || state.spicyOverride != nil || state.overrideTastes || !state.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(L.mealplan_prefCustom.localized)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                HStack(spacing: 8) {
                    prefChip(title: L.mealplan_prefInherit.localized, isOn: !state.customized) {
                        state.customized = false
                        state.categories = []
                    }
                    prefChip(title: L.mealplan_prefCustom.localized, isOn: state.customized) {
                        state.customized = true
                    }
                }
                if state.customized {
                    WrapChips(options: categoryOptions, selection: $state.categories, disabled: disabledCategories)
                }

                Text(L.label_spicyLevel.localized)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                    prefChip(title: L.mealplan_prefInherit.localized, isOn: state.spicyOverride == nil) {
                        state.spicyOverride = nil
                    }
                    ForEach(Array(spicyLabels.enumerated()), id: \.offset) { index, title in
                        prefChip(title: title, isOn: state.spicyOverride == index) {
                            state.spicyOverride = index
                        }
                    }
                }

                Text(L.label_tastePreferences.localized)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 8) {
                    prefChip(title: L.mealplan_prefInherit.localized, isOn: !state.overrideTastes) {
                        state.overrideTastes = false
                        state.tastes = [:]
                    }
                    prefChip(title: L.mealplan_prefCustom.localized, isOn: state.overrideTastes) {
                        state.overrideTastes = true
                    }
                }
                if state.overrideTastes {
                    VStack(spacing: 8) {
                        ForEach(tasteKeys, id: \.self) { key in
                            Toggle(key, isOn: Binding(
                                get: { state.tastes[key] ?? false },
                                set: { state.tastes[key] = $0 }
                            ))
                            .font(.callout)
                            .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                            .foregroundStyle(.white)
                        }
                    }
                }

                Text(L.mealplan_slotNotes.localized)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                TextField(L.mealplan_slotNotesPlaceholder.localized, text: $state.notes.limited(to: AIInputLimit.mealSlotNotes), axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(2...4)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($isFocused)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func prefChip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    isOn
                    ? AnyShapeStyle(LinearGradient(
                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(Color.white.opacity(0.08))
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(isOn ? 0 : 0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

private struct MealSlotChips: View {
    @Binding var selected: [String]
    var reservedCount: Int = 0

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
            ForEach(MealPlanSlot.selectable, id: \.self) { slot in
                let isOn = selected.contains(slot)
                Button {
                    toggle(slot)
                } label: {
                    Text(MealPlanSlot.localizedTitle(slot))
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 9)
                        .background(chipBackground(isOn: isOn))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(isOn ? 0.0 : 0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }

    private func toggle(_ slot: String) {
        if let index = selected.firstIndex(of: slot) {
            if selected.count + reservedCount > 1 {
                selected.remove(at: index)
            }
            return
        }
        guard selected.count + reservedCount < MealPlanSlot.maxMeals else { return }
        selected.append(slot)
        selected.sort { lhs, rhs in
            let order = MealPlanSlot.dayOrder
            return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
        }
    }

    @ViewBuilder
    private func chipBackground(isOn: Bool) -> some View {
        if isOn {
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white.opacity(0.08)
        }
    }
}

private struct MealPlanNutrField: View {
    let title: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.7))
            TextField("", text: $text.limited(to: AIInputLimit.nutritionNumber))
                .keyboardType(.numberPad)
                .foregroundStyle(.white)
                .tint(.white)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($isFocused)
        }
    }
}

private struct MealPlanMacroSlider: View {
    let title: String
    @Binding var percent: Double
    let grams: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(percent.rounded())) %  ·  \(grams) g")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            Slider(value: $percent, in: 0...100, step: 1)
                .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
        }
    }
}
