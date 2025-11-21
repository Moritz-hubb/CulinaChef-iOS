import SwiftUI

struct RecipeCreatorView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @FocusState private var isFocused: Bool

    @State private var goal: String = ""
    @State private var timeMinutesMax: String = ""
    @State private var servingsStr: String = "4"

    @State private var caloriesMin: String = ""
    @State private var caloriesMax: String = ""
    @State private var proteinMin: String = ""
    @State private var proteinMax: String = ""
    @State private var fatMin: String = ""
    @State private var fatMax: String = ""
    @State private var carbsMin: String = ""
    @State private var carbsMax: String = ""

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
    @State private var selectedCategories: Set<String> = []
    
    @State private var spicyLevel: Double = 2
    private var tastePreferenceKeys: [String] {
        [
            L.taste_sweet.localized,
            L.taste_sour.localized,
            L.taste_bitter.localized,
            L.taste_umami.localized
        ]
    }
    @State private var tastePreferences: [String: Bool] = [:]

    @State private var generating = false
    @State private var plan: RecipePlan?
    @State private var error: String?
    @State private var showResult = false
    @State private var showNotRecipeAlert = false
    @State private var showImpossibleRecipeAlert = false
    @State private var impossibleRecipeMessage = ""
    @State private var showConsentDialog = false

    var body: some View {
        Group {
            if app.hasAccess(to: .aiRecipeGenerator) {
                recipeCreatorContent
            } else {
                paywallContent
            }
        }
        .id(localizationManager.currentLanguage) // Force re-render on language change
    }
    
    private var recipeCreatorContent: some View {
        ZStack {
LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            if generating {
                SearchingPenguinView()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                    GroupBoxLabel(L.label_whatToCook.localized)
TextField(L.placeholder_describeDish.localized, text: $goal)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .focused($isFocused)
                        .accessibilityLabel(L.label_whatToCook.localized)
                        .accessibilityHint(L.placeholder_describeDish.localized)
                        .onAppear {
                            if let pending = app.pendingRecipeGoal {
                                // Combine name and description if description exists
                                if let desc = app.pendingRecipeDescription, !desc.isEmpty {
                                    goal = "\(pending): \(desc)"
                                } else {
                                    goal = pending
                                }
                                app.pendingRecipeGoal = nil
                                app.pendingRecipeDescription = nil
                            }
                            loadPreferences()
                        }

                    VStack(alignment: .leading) {
                        GroupBoxLabel(L.label_maxTimeMinutes.localized)
                        TextField(L.placeholder_maxTime.localized, text: $timeMinutesMax)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .tint(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focused($isFocused)
                            .accessibilityLabel(L.label_maxTimeMinutes.localized)
                            .accessibilityHint(L.placeholder_maxTime.localized)
                    }
                    
                    

                    GroupBoxLabel(L.label_nutrition.localized)
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow {
                            NutrField(title: L.label_kcalMin.localized, text: $caloriesMin, isFocused: $isFocused)
                            NutrField(title: L.label_kcalMax.localized, text: $caloriesMax, isFocused: $isFocused)
                        }
                        GridRow {
                            NutrField(title: L.label_proteinMin.localized, text: $proteinMin, isFocused: $isFocused)
                            NutrField(title: L.label_proteinMax.localized, text: $proteinMax, isFocused: $isFocused)
                        }
                        GridRow {
                            NutrField(title: L.label_fatMin.localized, text: $fatMin, isFocused: $isFocused)
                            NutrField(title: L.label_fatMax.localized, text: $fatMax, isFocused: $isFocused)
                        }
                        GridRow {
                            NutrField(title: L.label_carbsMin.localized, text: $carbsMin, isFocused: $isFocused)
                            NutrField(title: L.label_carbsMax.localized, text: $carbsMax, isFocused: $isFocused)
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
.background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .accessibilityLabel(L.recipe_ernährung.localized)
                        .accessibilityHint("Öffnet Einstellungen für Ernährungspräferenzen")
                    }
                    WrapChips(options: categoryOptions, selection: $selectedCategories)
                    
                    GroupBoxLabel(L.label_tastePreferences.localized)
                    VStack(spacing: 10) {
                        HStack {
                            Text(L.label_spicyLevel.localized)
                                .font(.callout)
                                .foregroundStyle(.white)
                            Spacer()
                            Text([L.spicy_mild.localized, L.spicy_normal.localized, L.spicy_hot.localized, L.spicy_veryHot.localized][Int(spicyLevel)])
                                .font(.callout.weight(.medium))
                                .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                        }
                        Slider(value: $spicyLevel, in: 0...3, step: 1)
                            .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                            .accessibilityLabel(L.label_spicyLevel.localized)
                            .accessibilityValue([L.spicy_mild.localized, L.spicy_normal.localized, L.spicy_hot.localized, L.spicy_veryHot.localized][Int(spicyLevel)])
                        
                        ForEach(tastePreferenceKeys, id: \.self) { key in
                            Toggle(key, isOn: Binding(
                                get: { tastePreferences[key] ?? false },
                                set: { newValue in
                                    tastePreferences[key] = newValue
                                }
                            ))
                            .font(.callout)
                            .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(action: { Task { await generate() } }) {
                        HStack { if generating { ProgressView() } else { Image(systemName: "wand.and.stars"); Text(L.button_generate.localized) } }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
.background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 6)
                    }
                    .accessibilityLabel(generating ? L.loading.localized : L.button_generate.localized)
                    .accessibilityHint("Generiert ein Rezept basierend auf den Eingaben")
                    .disabled(generating || goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .foregroundStyle(.white)
                .padding(16)
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = false
                }
            }
            }
        }
        .sheet(isPresented: $showResult) {
            if let plan { RecipeResultView(plan: plan) }
        }
        .sheet(isPresented: $showConsentDialog) {
            OpenAIConsentDialog(
                onAccept: {
                    OpenAIConsentManager.hasConsent = true
                    Task { await generate() }
                },
                onDecline: {
                    error = NSLocalizedString("consent.required", value: "KI-Funktionen benötigen Ihre Einwilligung", comment: "Consent required error")
                }
            )
        }
        .alert(L.alert_noRecipeRequest.localized, isPresented: $showNotRecipeAlert) {
            Button(L.button_ok.localized, role: .cancel) { }
        } message: {
            Text(L.recipe_dabei_kann_ich_dir.localized)
        }
        .alert(L.alert_recipeNotPossible.localized, isPresented: $showImpossibleRecipeAlert) {
            Button(L.button_ok.localized, role: .cancel) { }
        } message: {
            Text(impossibleRecipeMessage)
        }
        .alert(L.alert_error.localized, isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button(L.button_ok.localized) { error = nil }
        } message: {
            Text(error ?? "")
        }
    }
    
    private var paywallContent: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .white.opacity(0.3), radius: 20)
                    .accessibilityHidden(true)
                
                VStack(spacing: 12) {
                    Text("KI-Rezeptgenerator")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Diese Funktion ist nur für Unlimited-Mitglieder verfügbar")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: { Task { await app.purchaseStoreKit() } }) {
                    Text("Unlimited freischalten")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 300)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                }
                .accessibilityLabel("Unlimited freischalten")
                .accessibilityHint("Öffnet die Abo-Auswahl")
                .padding(.top, 16)
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L.button_done.localized) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
            }
        }
    }

    func loadPreferences() {
        // Initialize taste preferences
        for key in tastePreferenceKeys {
            tastePreferences[key] = false
        }
        
        // Load from user dietary settings
        selectedCategories = app.dietary.diets
        
        // Load taste preferences from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "taste_preferences"),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            spicyLevel = dict["spicy_level"] as? Double ?? 2
            tastePreferences[L.taste_sweet.localized] = dict["sweet"] as? Bool ?? false
            tastePreferences[L.taste_sour.localized] = dict["sour"] as? Bool ?? false
            tastePreferences[L.taste_bitter.localized] = dict["bitter"] as? Bool ?? false
            tastePreferences[L.taste_umami.localized] = dict["umami"] as? Bool ?? false
        }
    }
    
    func buildDietaryContext() -> String {
        var parts: [String] = []
        
        // ALWAYS include allergies and intolerances from settings
        if !app.dietary.allergies.isEmpty {
            parts.append(L.creator_allergiesLabel.localized + " " + app.dietary.allergies.joined(separator: ", "))
        }
        
        // Use current form values for categories (dietary types)
        if !selectedCategories.isEmpty {
            parts.append(L.creator_dietsLabel.localized + " " + selectedCategories.sorted().joined(separator: ", "))
        }
        
        // Use current form values for spiciness
        let spicyLabels = [L.spicy_mild.localized, L.spicy_normal.localized, L.spicy_hot.localized, L.spicy_veryHot.localized]
        parts.append(L.creator_spicyLabel.localized + " " + spicyLabels[Int(spicyLevel)])
        
        // Use current form values for taste preferences
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
    
    func generate() async {
        // Block AI features on jailbroken devices
        if app.isJailbroken {
            await MainActor.run {
                error = "KI-Funktionen sind auf modifizierten Geräten nicht verfügbar"
            }
            return
        }
        
        // Check feature access first
        guard app.hasAccess(to: .aiRecipeGenerator) else {
            return
        }
        
        // Check DSGVO consent before using OpenAI
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        
        error = nil
        generating = true
        defer { generating = false }
        // Enforce rate limit via backend before any OpenAI call
        guard let token = app.accessToken else { error = "Nicht angemeldet"; return }
        // Try to increment AI usage, but don't fail if backend is unreachable
        do {
            let txnID = await app.getOriginalTransactionId()
            _ = try await app.backend.incrementAIUsage(accessToken: token, originalTransactionId: txnID)
        } catch let error as URLError where error.code == .cannotFindHost || error.code == .cannotConnectToHost {
            Logger.info("Backend unreachable, continuing without usage tracking", category: .network)
        } catch {
            await MainActor.run { self.error = error.localizedDescription }
            return
        }
        guard let openai = app.openAI else { error = "Kein API-Client konfiguriert."; return }
        let nutrition = NutritionConstraint(
            calories_min: Int(caloriesMin), calories_max: Int(caloriesMax),
            protein_min_g: Int(proteinMin), protein_max_g: Int(proteinMax),
            fat_min_g: Int(fatMin), fat_max_g: Int(fatMax),
            carbs_min_g: Int(carbsMin), carbs_max_g: Int(carbsMax)
        )
        
        // Build custom dietary context from current form values
        let customContext = buildDietaryContext()
        let languageContext = app.languageSystemPrompt()
        let fullContext = [customContext, languageContext, app.hiddenIntentContext()].filter { !$0.isEmpty }.joined(separator: "\n")
        
        do {
            let plan = try await openai.generateRecipePlan(
                goal: goal,
                timeMinutesMin: nil,
                timeMinutesMax: Int(timeMinutesMax),
                nutrition: nutrition,
                categories: Array(selectedCategories),
                servings: 4,
                dietaryContext: fullContext
            )
            
            // Validate that the AI returned a usable recipe
            let titleTrimmed = plan.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasTitle = !titleTrimmed.isEmpty
            let hasIngredients = !plan.ingredients.isEmpty
            let hasSteps = !plan.steps.isEmpty
            let isValid = hasTitle && (hasIngredients || hasSteps)
            
            await MainActor.run {
                if isValid {
                    self.plan = plan
                    self.showResult = true
                    // Reset categories to user's permanent dietary settings
                    // This prevents temporary selections from persisting across multiple recipe generations
                    self.selectedCategories = app.dietary.diets
                } else {
                    self.error = L.errorInvalidRecipeRequest.localized
                }
            }
        } catch {
            await MainActor.run {
                // Check error type
                let desc = error.localizedDescription
                if desc.contains("NO_RECIPE_REQUEST") {
                    self.showNotRecipeAlert = true
                } else if desc.hasPrefix("IMPOSSIBLE_RECIPE:") {
                    // Extract explanation from error message
                    self.impossibleRecipeMessage = desc.replacingOccurrences(of: "IMPOSSIBLE_RECIPE:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    self.showImpossibleRecipeAlert = true
                } else {
                    self.error = desc
                }
            }
        }
    }
}

private struct GroupBoxLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
Text(text).font(.subheadline).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NutrField: View {
    let title: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.7))
TextField("", text: $text)
                .keyboardType(.numberPad)
                .foregroundStyle(.white)
                .tint(.white)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($isFocused)
        }
    }
}

private struct WrapChips: View {
    let options: [String]
    @Binding var selection: Set<String>
    @State private var totalHeight: CGFloat = .zero
    var body: some View {
        VStack {
            GeometryReader { geo in
                self.generateContent(in: geo)
            }
            .frame(height: totalHeight)
        }
    }
    private func chip(_ text: String) -> some View {
        let isOn = selection.contains(text)
        return Text(text)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Group {
                    if isOn {
                        LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Color.white.opacity(0.08)
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .onTapGesture { if isOn { selection.remove(text) } else { selection.insert(text) } }
    }
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
ForEach(options, id: \.self) { opt in
                chip(opt)
                    .padding([.horizontal, .vertical], 6)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if opt == options.last! { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if opt == options.last! { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async { binding.wrappedValue = geometry.size.height }
            return .clear
        }
    }
}

// MARK: - Searching Penguin View
private struct SearchingPenguinView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                // Suchender Pinguin
                if let bundlePath = Bundle.main.path(forResource: "penguin-searching", ofType: "png", inDirectory: "Assets.xcassets/penguin-searching.imageset"),
                   let uiImage = UIImage(contentsOfFile: bundlePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isAnimating ? 12 : 8)
                        .offset(y: isAnimating ? -8 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                } else if let uiImage = UIImage(named: "penguin-searching") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isAnimating ? 12 : 8)
                        .offset(y: isAnimating ? -8 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                } else {
                    // Fallback: Lupe Emoji
                    Text("🔍")
                        .font(.system(size: 100))
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: isAnimating ? 12 : 8)
                        .offset(y: isAnimating ? -8 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                // Text mit animierten Punkten
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text(L.recipe_ich_suche_nach_einem.localized)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        // Animierte Punkte
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Text(".")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .opacity(isAnimating ? 0.3 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.2),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                    
                    Text(L.recipe_das_perfekte_rezept_ist.localized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .shadow(color: Color.orange.opacity(0.3), radius: 15, x: 0, y: 8)
            )
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}
