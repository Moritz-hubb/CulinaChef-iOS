import SwiftUI
import Combine
import AVFoundation

struct RecipeResultView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    let plan: RecipePlan
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var nutritionMode: NutritionMode = .perServing
    @State private var showAISheet = false
    @State private var currentPage: Int = 0
    @State private var showCompletion = false
    @State private var timersExpanded = true
    @StateObject private var timerCenter = TimerCenter()
    @State private var servings: Int = 1
    @State private var showCloseConfirmation = false
    @State private var recipeSaved = false

    var body: some View {
        NavigationView {
            ZStack {
LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                TabView(selection: $currentPage) {
                    overviewPage.tag(0)
                    if plan.steps.isEmpty {
                        VStack(spacing: 12) {
                            Text(L.recipe_keine_schritte_gefunden_2c3f.localized).foregroundStyle(.white)
                            Text(L.recipe_regenerateHint.localized).font(.footnote).foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(24)
                        .tag(1)
                    } else {
                        ForEach(plan.steps.indices, id: \.self) { idx in
                            let step = plan.steps[idx]
                            stepPage(index: idx + 1, step: step).tag(idx + 1)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
            .navigationTitle(plan.title)
            .onAppear {
                let base = plan.servings ?? 4
                servings = max(1, base)
            }
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAISheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                                .imageScale(.medium)
                                .fontWeight(.semibold)
                            Text("Culina")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), in: Capsule()
                        )
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .contentShape(Capsule())
                        .accessibilityLabel(L.common_openCulina.localized)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        if recipeSaved {
                            dismiss()
                        } else {
                            showCloseConfirmation = true
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                }
            }
.sheet(isPresented: $showAISheet) {
                RecipeAISheet(plan: plan, currentStepIndex: max(currentPage - 1, -1))
                    .environmentObject(app)
                    .presentationDetents([.fraction(0.6), .large])
                    .presentationDragIndicator(.visible)
            }
            .safeAreaInset(edge: .bottom) {
                if !timerCenter.timers.isEmpty {
                    VStack(spacing: 8) {
                        if timersExpanded {
                            ForEach(timerCenter.timers) { timer in
                                FloatingTimerView(center: timerCenter, timer: timer)
                            }
                        }
                        
                        // Collapse/Expand button
                        Button(action: { 
                            withAnimation(.spring(response: 0.3)) {
                                timersExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: timersExpanded ? "chevron.down" : "chevron.up")
                                    .font(.caption.bold())
                                Text(timersExpanded ? L.timerHide.localized : "\(timerCenter.timers.count) \(L.timerActive.localized)")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial.opacity(0.3))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
.fullScreenCover(isPresented: $showCompletion) {
                RecipeCompletionView(recipe: convertToRecipe(), onCloseRecipe: { 
                    recipeSaved = true
                    dismiss() 
                })
                    .environmentObject(app)
            }
            .alert(L.recipe_rezept_schließen.localized, isPresented: $showCloseConfirmation) {
                Button(L.close.localized, role: .destructive) {
                    dismiss()
                }
                Button(L.completion_saveRecipe.localized) {
                    showCompletion = true
                }
                Button(L.cancel.localized, role: .cancel) {}
            } message: {
                Text(L.recipe_achtung_du_hast_das.localized)
            }
        }
    }
    
    // Convert RecipePlan to Recipe for completion view
    private func convertToRecipe() -> Recipe {
        let ingredientNames: [String] = plan.ingredients.map { item in
            var parts: [String] = []
            if let amount = item.amount {
                let amountStr = amount.truncatingRemainder(dividingBy: 1) == 0 
                    ? String(Int(amount)) 
                    : String(format: "%.1f", amount)
                parts.append(amountStr)
            }
            if let unit = item.unit, !unit.isEmpty {
                parts.append(unit)
            }
            parts.append(item.name)
            return parts.joined(separator: " ")
        }
        let instructionTexts = plan.steps.map { "⟦label:\($0.title)⟧ " + $0.description }
        
        let tt = plan.total_time_minutes
        let cookStr = tt.map { "\($0) Min" }

        // Start with AI categories (capitalized) and ALWAYS add a language tag for this recipe.
        var tags: [String] = plan.categories?.map { $0.capitalized } ?? []
        let langTag = app.recipeLanguageTag()
        if !tags.contains(langTag) {
            tags.append(langTag)
        }

        return Recipe(
            id: UUID().uuidString,
            user_id: KeychainManager.get(key: "user_id") ?? "",
            title: plan.title,
            ingredients: ingredientNames,
            instructions: instructionTexts,
            nutrition: Nutrition(
                calories: plan.nutrition?.calories,
                protein_g: plan.nutrition?.protein_g,
                carbs_g: plan.nutrition?.carbs_g,
                fat_g: plan.nutrition?.fat_g
            ),
            created_at: nil,
            is_favorite: false,
            user_email: nil,
            is_public: nil,
            image_url: nil,
            cooking_time: cookStr,
            difficulty: nil,
            tags: tags.isEmpty ? nil : tags,
            rating: nil
        )
    }

    private var overviewPage: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Zusammenfassung
                VStack(alignment: .leading, spacing: 12) {
                    // Portion control
                    HStack {
                        Text(L.label_servings.localized).font(.subheadline).foregroundStyle(.white)
                        Spacer()
                        HStack(spacing: 8) {
                            Button(action: { if servings > 1 { servings -= 1 } }) {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.white).font(.title3)
                            }
                            Text(String(servings)).font(.headline).foregroundStyle(.white)
                                .frame(minWidth: 28)
                            Button(action: { servings += 1 }) {
                                Image(systemName: "plus.circle.fill").foregroundStyle(.white).font(.title3)
                            }
                        }
                    }
                    if let tt = plan.total_time_minutes { LabeledRow(L.label_cookingTime.localized.replacingOccurrences(of: ":", with: ""), String(tt) + " min") }
                    if let cats = plan.categories, !cats.isEmpty { LabeledRow(L.label_categories.localized, cats.joined(separator: ", ")) }
                    if let n = plan.nutrition {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker(L.recipe_nährwerte.localized, selection: $nutritionMode) {
                                Text(L.recipe_nährwerte_pro_portion.localized).tag(NutritionMode.perServing)
                                Text(L.recipe_nährwerte_insgesamt.localized).tag(NutritionMode.total)
                            }
                            .pickerStyle(.segmented)

                            Group {
                                LabeledRow(L.label_calories.localized, formatCalories(n.calories))
                                LabeledRow(L.label_protein.localized, formatGrams(n.protein_g))
                                LabeledRow(L.label_fat.localized, formatGrams(n.fat_g))
                                LabeledRow(L.label_carbs.localized, formatGrams(n.carbs_g))
                            }
                        }
                    }
                    if let notes = plan.notes, !notes.isEmpty {
                        Text(L.settings_hints.localized).font(.headline).foregroundStyle(.white)
                        Text(notes).foregroundStyle(.white)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Zutaten
                VStack(alignment: .leading, spacing: 12) {
Text(L.recipe_zutaten_1272.localized).font(.headline).foregroundStyle(.white)
                    ForEach(plan.ingredients) { ing in
                        HStack {
Text(ing.name).font(.body).foregroundStyle(.white)
                            Spacer()
                            Text(formatAmount(ing, baseServings: plan.servings, currentServings: servings)).foregroundStyle(.white)
                        }
                        .padding(.vertical, 6)
                        .overlay(Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1), alignment: .bottom)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            }
            .padding(16)
        }
    }

    private func stepPage(index: Int, step: RecipeStep) -> some View {
        let isLastStep = index == plan.steps.count
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(step.title).font(.title3.bold()).foregroundStyle(.white)
                if let d = step.duration_minutes { LabeledRow(L.label_cookingTime.localized.replacingOccurrences(of: ":", with: ""), String(d) + " min") }
                Text(scaleInstruction(step.description, baseServings: plan.servings, currentServings: servings)).foregroundStyle(.white)

                if let cookMins = parseCookMinutes(from: step.description) {
                    SharedTimerControl(minutes: cookMins, label: step.title, center: timerCenter)
                    // Nur Hinweis zeigen, wenn Timer >= 5 Min UND es weitere Schritte gibt
                    if cookMins >= 5 && !isLastStep {
                        Text(L.recipe_in_der_zwischenzeit_führe_b7f6.localized)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                if isLastStep {
                    Button(action: { showCompletion = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(L.button_finishRecipe.localized)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                } else {
                    // Next button for non-last steps
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            currentPage = index + 1
                        }
                    }) {
                        HStack {
                            Text(L.next.localized)
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(16)
        }
        .navigationTitle("\(L.label_step.localized) \(index)")
    }

    private func formatAmount(_ ing: IngredientItem, baseServings: Int?, currentServings: Int) -> String {
        let unit = ing.unit ?? ""
        if let base = baseServings, base > 0, let amount = ing.amount {
            let scaled = amount * Double(currentServings) / Double(base)
            let fmt = scaled.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", scaled) : String(format: "%.1f", scaled)
            return [fmt, unit].filter { !$0.isEmpty }.joined(separator: " ")
        } else if let amount = ing.amount {
            let fmt = amount.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", amount) : String(format: "%.1f", amount)
            return [fmt, unit].filter { !$0.isEmpty }.joined(separator: " ")
        }
        return unit
    }
}

// MARK: - AI Q&A Sheet (Chat-Style)
private struct RecipeAISheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    let plan: RecipePlan
    // -1 means overview page (keine Schritt-spezifische Auswahl)
    let currentStepIndex: Int

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var sending = false
    @State private var error: String?
    @State private var showConsentDialog = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.96, green: 0.78, blue: 0.68), Color(red: 0.95, green: 0.74, blue: 0.64), Color(red: 0.93, green: 0.66, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Culina")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
.padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 10)

                // Chat list
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            if messages.isEmpty {
                                VStack(spacing: 10) {
                                    Text(L.recipe_stell_mir_fragen_zu_facc.localized)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text(L.recipe_zb_garzeiten_anpassen_ersatzzutaten_b588.localized)
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(messages) { msg in
                                    RecipeChatBubble(message: msg)
                                }
                                if sending {
                                    CulinaThinkingPenguinView()
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.easeOut) { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                }
            }
        }
        .sheet(isPresented: $showConsentDialog) {
            OpenAIConsentDialog(
                onAccept: {
                    OpenAIConsentManager.hasConsent = true
                },
                onDecline: {}
            )
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Nachricht…").foregroundStyle(.white.opacity(0.5))
                    }
                    TextField("", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .tint(.white)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.clear)
                .frame(minHeight: 42)

                Button(action: { Task { await sendText() } }) {
                    Group { if sending { ProgressView().tint(.white) } else { Image(systemName: "paperplane.fill").foregroundStyle(.white) } }
                        .frame(width: 42, height: 42)
                        .background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        .shadow(color: Color.orange.opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .disabled(sending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            .opacity(0.6)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
                    .shadow(color: .purple.opacity(0.25), radius: 30, x: 0, y: 12)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onAppear {
            if messages.isEmpty {
                messages.append(.init(role: .assistant, text: "Hi! Ich helfe dir bei diesem Rezept. Was möchtest du wissen?"))
            }
        }
    }

    private func sendText() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Check DSGVO consent before using OpenAI
        guard OpenAIConsentManager.hasConsent else {
            await MainActor.run { showConsentDialog = true }
            return
        }
        
        inputText = ""
        let userMsg = ChatMessage(role: .user, text: text)
        messages.append(userMsg)
        sending = true
        defer { sending = false }
        do {
            guard let token = app.accessToken else {
                throw NSError(domain: "rate_limit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])
            }
            do { _ = try await app.backend.incrementAIUsage(accessToken: token) } catch {
                await MainActor.run { self.error = error.localizedDescription }
                return
            }
            guard let openai = (app.recipeAI ?? app.openAI) else { throw NSError(domain: "no_api", code: 0) }

            let sysGeneral = app.systemContext()
            let recipeJSON = try encodePlan(plan)
            var sysRecipe = "Du bist ein Kochassistent. Verwende ausschließlich die bereitgestellten Rezeptdaten.\nRezeptdaten (JSON):\n\(recipeJSON)\n"
            if currentStepIndex >= 0 {
                sysRecipe += "Aktueller Schritt Index (1-basiert): \(currentStepIndex + 1). Beziehe dich darauf in deiner Antwort.\n"
            } else {
                sysRecipe += "Der Nutzer ist auf der Übersicht.\n"
            }
            var prefixed: [ChatMessage] = []
            if !sysGeneral.isEmpty { prefixed.append(.init(role: .system, text: sysGeneral)) }
            prefixed.append(.init(role: .system, text: sysRecipe))
            prefixed.append(contentsOf: messages)

            let reply = try await openai.chatReply(messages: prefixed, maxHistory: prefixed.count)
            await MainActor.run { messages.append(.init(role: .assistant, text: reply)) }
        } catch {
            await MainActor.run { messages.append(.init(role: .assistant, text: "Fehler: \(error.localizedDescription)")) }
        }
    }

    private func encodePlan(_ plan: RecipePlan) throws -> String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.withoutEscapingSlashes]
        let data = try enc.encode(plan)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - Recipe Chat Bubble
private struct RecipeChatBubble: View {
    let message: ChatMessage
    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 24) }
            Text(message.text)
                .foregroundStyle(.white)
                .padding(12)
                .background {
                    if isUser {
                        LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(isUser ? 0.15 : 0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 6)
                .id(message.id)
            if !isUser { Spacer(minLength: 24) }
        }
        .padding(.horizontal, 4)
    }
}


private enum NutritionMode { case perServing, total }

private struct LabeledRow: View {
    var key: String
    var value: String
    init(_ key: String, _ value: String) { self.key = key; self.value = value }
    var body: some View {
        HStack {
            Text(key).font(.subheadline).foregroundStyle(.white)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.white)
        }
        .padding(.vertical, 4)
        .overlay(Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - Helpers
extension RecipeResultView {
    private func formatCalories(_ perServing: Int?) -> String {
        guard let per = perServing else { return "-" }
        if nutritionMode == .total { return String(per * servings) + " kcal" }
        return String(per) + " kcal"
    }
    private func formatGrams(_ perServing: Double?) -> String {
        guard let per = perServing else { return "-" }
        if nutritionMode == .total { return String(format: "%.0f g", per * Double(servings)) }
        return String(format: "%.0f g", per)
    }

    // Scale numeric ingredient quantities inside free-text step instructions based on servings
    fileprivate func scaleInstruction(_ text: String, baseServings: Int?, currentServings: Int) -> String {
        guard let base = baseServings, base > 0, base != currentServings else { return text }
        let scale = Double(currentServings) / Double(base)
        // Exclude time/temperature units; scale only known food quantity units
        let allowedUnits = ["g","gramm","kg","ml","l","dl","cl","EL","TL","Prise","Stück","Stueck","Scheiben","Dosen","Tassen","cup","cups","tbsp","tsp"]
        let timeUnits = ["min","minute","minuten","sek","sekunden","std","stunde","stunden","°c","grad","c"]
        // Regex: number (int|decimal|fraction) + optional space + unit
        // number group allows: 1/2, 3/4, 0.5, 0,5, 2
        let pattern = #"(?i)(\b\d+\/\d+|\b\d+[\.,]\d+|\b\d+)\s*(\p{L}+\b)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
        let ns = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty { return text }
        var result = text
        // Replace from end to start to keep ranges valid
        for m in matches.reversed() {
            guard m.numberOfRanges >= 3 else { continue }
            let numRange = m.range(at: 1)
            let unitRange = m.range(at: 2)
            // Extract strings for decision making
            guard let numStr = Range(numRange, in: result).map({ String(result[$0]) }),
                  let unitStr = Range(unitRange, in: result).map({ String(result[$0]) }) else { continue }
            let unitLower = unitStr.lowercased()
            if timeUnits.contains(unitLower) { continue }
            if !allowedUnits.contains(where: { $0.lowercased() == unitLower }) { continue }
            guard let value = parseQuantityNumber(numStr) else { continue }
            let scaled = value * scale
            let replacement = formatScaledQuantity(scaled, original: numStr) + " " + unitStr
            // Replace the entire matched span (number + optional space + unit)
            let fullRange = m.range
            guard let swiftRange = Range(fullRange, in: result) else { continue }
            result.replaceSubrange(swiftRange, with: replacement)
        }
        return result
    }

    private func parseQuantityNumber(_ s: String) -> Double? {
        let t = s.trimmingCharacters(in: .whitespaces)
        if t.contains("/") {
            let parts = t.split(separator: "/").map { String($0) }
            if parts.count == 2, let a = Double(parts[0].replacingOccurrences(of: ",", with: ".")), let b = Double(parts[1].replacingOccurrences(of: ",", with: ".")), b != 0 {
                return a / b
            }
        }
        let norm = t.replacingOccurrences(of: ",", with: ".")
        return Double(norm)
    }

    private func formatScaledQuantity(_ value: Double, original: String) -> String {
        // Keep integers as whole numbers; else one decimal
        if abs(value.rounded() - value) < 0.001 { return String(format: "%.0f", value.rounded()) }
        return String(format: "%.1f", value)
    }

    // Parse lower-bound minutes from text, supporting minutes and hours (e.g., "20 Minuten", "1 Stunde 30 Minuten", "4 Stunden", "2-3 h", "4 bis 5 Stunden").
    fileprivate func parseCookMinutes(from text: String) -> Int? {
        let s = text.lowercased()
        let fullRange = NSRange(location: 0, length: s.utf16.count)
        
        // 1) "X Stunde(n) Y Minute(n)" (with optional minutes)
        if let re = try? NSRegularExpression(pattern: #"(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)(?:\s+(\d+)\s*(?:min|minute|minuten))?"#, options: []) {
            if let m = re.firstMatch(in: s, options: [], range: fullRange) {
                if let r1 = Range(m.range(at: 1), in: s) {
                    let hoursStr = String(s[r1]).replacingOccurrences(of: ",", with: ".")
                    let hours = Double(hoursStr) ?? 0
                    var minutes = Int(hours * 60)
                    if m.numberOfRanges >= 3, m.range(at: 2).location != NSNotFound, let r2 = Range(m.range(at: 2), in: s) {
                        minutes += Int(s[r2]) ?? 0
                    }
                    if minutes > 0 { return minutes }
                }
            }
        }
        
        // 2) Hours range: use lower bound (e.g., "2-3 Stunden", "2 bis 3 h")
        let hourRangePatterns = [
            #"(\d+(?:[\.,]\d+)?)\s*[–-]\s*(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)"#,
            #"(\d+(?:[\.,]\d+)?)\s*(?:bis)\s*(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)"#
        ]
        for p in hourRangePatterns {
            if let re = try? NSRegularExpression(pattern: p, options: []) {
                if let m = re.firstMatch(in: s, options: [], range: fullRange), let r1 = Range(m.range(at: 1), in: s) {
                    let hoursStr = String(s[r1]).replacingOccurrences(of: ",", with: ".")
                    let hours = Double(hoursStr) ?? 0
                    let minutes = Int(hours * 60)
                    if minutes > 0 { return minutes }
                }
            }
        }
        
        // 3) Single hours: "4 h", "4 Stunden"
        if let re = try? NSRegularExpression(pattern: #"(\d+(?:[\.,]\d+)?)\s*(?:h|std\.?|stunde|stunden)"#, options: []) {
            if let m = re.firstMatch(in: s, options: [], range: fullRange), let r1 = Range(m.range(at: 1), in: s) {
                let hoursStr = String(s[r1]).replacingOccurrences(of: ",", with: ".")
                let hours = Double(hoursStr) ?? 0
                let minutes = Int(hours * 60)
                if minutes > 0 { return minutes }
            }
        }
        
        // 4) Minute ranges
        let minuteRangePatterns = [
            #"(\d+)\s*[–-]\s*(\d+)\s*(?:min|minute|minuten)"#,
            #"(\d+)\s*(?:bis)\s*(\d+)\s*(?:min|minute|minuten)"#
        ]
        for p in minuteRangePatterns {
            if let re = try? NSRegularExpression(pattern: p, options: []) {
                if let m = re.firstMatch(in: s, options: [], range: fullRange), let r1 = Range(m.range(at: 1), in: s) {
                    return Int(s[r1])
                }
            }
        }
        
        // 5) Single minutes
        if let re = try? NSRegularExpression(pattern: #"(\d+)\s*(?:min|minute|minuten)"#, options: []) {
            if let m = re.firstMatch(in: s, options: [], range: fullRange), let r1 = Range(m.range(at: 1), in: s) {
                return Int(s[r1])
            }
        }
        
        return nil
    }
}


// Step-local control to start or control shared timer
private struct SharedTimerControl: View {
    let minutes: Int
    let label: String
    @ObservedObject var center: TimerCenter
    
    // Find timer for this specific step
    private var myTimer: RunningTimer? {
        center.timers.first { $0.label == label }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let has = myTimer != nil
            HStack(spacing: 8) {
                Image(systemName: "timer")
                Text(has ? "Timer läuft" : "Timer")
                Spacer()
                Text(formatted(myTimer?.remaining ?? minutes * 60))
                    .monospacedDigit()
                    .font(.headline)
            }
            .foregroundStyle(.white)
            HStack {
                Button(action: {
                    if let cur = myTimer { cur.running.toggle() }
                    else { center.start(minutes: minutes, label: label) }
                }) {
                    Label(myTimer == nil ? "Start" : ((myTimer?.running ?? false) ? "Pause" : "Start"), systemImage: (myTimer == nil) ? "play.fill" : ((myTimer?.running ?? false) ? "pause.fill" : "play.fill"))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                .foregroundStyle(.white)

                Button(action: { myTimer?.reset() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .foregroundStyle(.white)

                Spacer()

                Stepper("", value: Binding(get: { myTimer?.baseMinutes ?? minutes }, set: { newVal in
                    let v = max(1, newVal)
                    if let cur = myTimer { cur.baseMinutes = v; cur.remaining = v * 60 }
                }), in: 1...720)
                .labelsHidden()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// Floating control visible on all pages when a timer is running
private struct FloatingTimerView: View {
    @ObservedObject var center: TimerCenter
    @ObservedObject var timer: RunningTimer

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Text(formatted(timer.remaining))
                    .monospacedDigit()
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Spacer()
            if timer.remaining == 0 {
                Button(action: { 
                    timer.audioPlayer?.stop()
                    center.remove(timer: timer)
                }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
                Button(action: { timer.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.white)
                }
            } else {
                Button(action: { timer.running.toggle() }) {
                    Image(systemName: timer.running ? "pause.fill" : "play.fill")
                        .foregroundStyle(.white)
                }
                Button(action: { timer.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
