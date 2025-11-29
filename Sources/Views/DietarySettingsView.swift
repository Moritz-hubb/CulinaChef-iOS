import SwiftUI

struct DietarySettingsView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var diets: Set<String> = []
    @State private var allergies: [String] = []
    @State private var newAllergyText: String = ""
    @State private var dislikes: [String] = []
    @State private var newDislikeText: String = ""
    @State private var notesText: String = ""
    @State private var spicyLevel: Double = 2
    @State private var tastePreferences: [String: Bool] = [
        "süß": false,
        "sauer": false,
        "bitter": false,
        "umami": false
    ]
    @State private var isSyncing = false
    @State private var isSaving = false

    private var dietOptions: [String] {
        let _ = localizationManager.currentLanguage // Force recomputation when language changes
        return [
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

    var body: some View {
        ZStack {
            backgroundGradient
            ScrollView {
                VStack(spacing: 16) {
                    headerView
                    preferencesContentView
                }
                .padding(16)
            }
        }
        .onAppear { 
            Logger.debug("[DietarySettingsView] onAppear called", category: .data)
            loadFromApp() 
        }
        .onDisappear { 
            Logger.debug("[DietarySettingsView] onDisappear called", category: .data)
            // Save taste preferences when view disappears to ensure they're persisted
            saveBack() 
        }
        .onChange(of: app.dietary) { oldValue, newValue in
            Logger.debug("[DietarySettingsView] onChange(of: app.dietary) triggered - oldValue: \(oldValue), newValue: \(newValue), isSaving: \(isSaving), valuesEqual: \(oldValue == newValue)", category: .data)
            // Only reload if dietary actually changed (not just a reference update)
            // But skip reloading if we're currently saving (to prevent overwriting taste preferences)
            if oldValue != newValue && !isSaving {
                Logger.debug("[DietarySettingsView] onChange: dietary changed and not saving, scheduling loadFromApp()", category: .data)
                // Small delay to ensure saveBack() has completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Logger.debug("[DietarySettingsView] onChange: delayed loadFromApp() check - isSaving: \(isSaving)", category: .data)
                    if !isSaving {
                        Logger.debug("[DietarySettingsView] onChange: calling loadFromApp()", category: .data)
                        loadFromApp()
                    } else {
                        Logger.debug("[DietarySettingsView] onChange: skipping loadFromApp() because isSaving is true", category: .data)
                    }
                }
            } else {
                if oldValue == newValue {
                    Logger.debug("[DietarySettingsView] onChange: skipping because oldValue == newValue", category: .data)
                }
                if isSaving {
                    Logger.debug("[DietarySettingsView] onChange: skipping because isSaving is true", category: .data)
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(colors: [Color.pink.opacity(0.2), Color.purple.opacity(0.3), Color.blue.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
    
    private var headerView: some View {
                    HStack {
                        Text(L.settings_ernährung.localized)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        Button(L.done.localized) { dismiss() }
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .accessibilityLabel(L.done.localized)
                            .accessibilityHint("Schließt die Ernährungspräferenzen")
        }
                    }

    private var preferencesContentView: some View {
                    VStack(alignment: .leading, spacing: 12) {
            dietsSection
            allergiesSection
            dislikesSection
            tastePreferencesSection
            notesSection
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var dietsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
                        Text(L.settings_ernährungsweisen.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        WrapDietChips(options: dietOptions, selection: $diets)
                            .padding(.bottom, 6)
                            .onChange(of: diets) { _, _ in saveBack() }
        }
    }

    private var allergiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
                        Text(L.settings_allergienunverträglichkeiten.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            TextField(L.dietary_allergiesPlaceholder.localized, text: $newAllergyText)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .tint(.white)
                                .accessibilityLabel("Allergie eingeben")
                                .accessibilityHint(L.dietary_allergiesPlaceholder.localized)
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Button(L.common_add.localized) {
                                let trimmed = newAllergyText.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    allergies.append(trimmed)
                                    newAllergyText = ""
                                    saveBack()
                                }
                            }
                            .accessibilityLabel(L.common_add.localized)
                            .accessibilityHint("Fügt die eingegebene Allergie hinzu")
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        if !allergies.isEmpty {
                            FlowLayout(items: allergies) { item in
                    allergyChipView(item: item)
                }
            }
        }
    }
    
    private func allergyChipView(item: String) -> some View {
                                HStack(spacing: 4) {
                                    Text(item)
                                        .font(.callout)
                                        .foregroundStyle(.white)
                                    Button(action: { 
                                        allergies.removeAll { $0 == item }
                                        saveBack()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                    .accessibilityLabel("\(item) entfernen")
                                    .accessibilityHint("Entfernt diese Allergie aus der Liste")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }

    private var dislikesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
                        Text(L.settings_dislikes.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            TextField(L.dietary_dislikesPlaceholder.localized, text: $newDislikeText)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .tint(.white)
                                .accessibilityLabel("Abneigung eingeben")
                                .accessibilityHint(L.dietary_dislikesPlaceholder.localized)
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Button(L.common_add.localized) {
                                let trimmed = newDislikeText.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    dislikes.append(trimmed)
                                    newDislikeText = ""
                                    saveBack()
                                }
                            }
                            .accessibilityLabel(L.common_add.localized)
                            .accessibilityHint("Fügt die eingegebene Abneigung hinzu")
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        if !dislikes.isEmpty {
                            FlowLayout(items: dislikes) { item in
                    dislikeChipView(item: item)
                }
            }
        }
    }
    
    private func dislikeChipView(item: String) -> some View {
                                HStack(spacing: 4) {
                                    Text(item)
                                        .font(.callout)
                                        .foregroundStyle(.white)
                                    Button(action: { 
                                        dislikes.removeAll { $0 == item }
                                        saveBack()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                    .accessibilityLabel("\(item) entfernen")
                                    .accessibilityHint("Entfernt diese Abneigung aus der Liste")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }

    private var tastePreferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
                        Text(L.settings_geschmackspräferenzen.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        VStack(spacing: 10) {
                            HStack {
                                Text(L.settings_schärfelevel.localized)
                                    .font(.callout)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(["Mild", "Normal", "Scharf", "Sehr Scharf"][Int(spicyLevel)])
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                            Slider(value: $spicyLevel, in: 0...3, step: 1)
                                .tint(.purple)
                                .accessibilityLabel(L.settings_schärfelevel.localized)
                                .accessibilityValue(["Mild", "Normal", "Scharf", "Sehr Scharf"][Int(spicyLevel)])
                                .onChange(of: spicyLevel) { _, _ in saveBack() }
                            
                            ForEach(Array(tastePreferences.keys.sorted()), id: \.self) { key in
                                Toggle(key.capitalized, isOn: Binding(
                                    get: { tastePreferences[key] ?? false },
                                    set: { newValue in
                                        tastePreferences[key] = newValue
                                        saveBack()
                                    }
                                ))
                                .font(.callout)
                                .foregroundStyle(.white)
                                .tint(.purple)
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
                        
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
                        Text(L.settings_hints.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        TextField(L.dietary_notesPlaceholder.localized, text: $notesText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .tint(.white)
                            .accessibilityLabel("Notizen")
                            .accessibilityHint(L.dietary_notesPlaceholder.localized)
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: notesText) { _, _ in saveBack() }
                    }
    }

    // Mapping of all possible localized diet strings to their localization keys
    // This allows us to map stored dietary types (in any language) to current localized strings
    private static let dietLocalizationMap: [String: String] = {
        var map: [String: String] = [:]
        
        // Get all localized versions from JSON files
        // German (de)
        map["vegetarisch"] = L.category_vegetarian
        map["vegan"] = L.category_vegan
        map["pescetarisch"] = L.category_pescetarian
        map["kohlenhydratarm"] = L.category_lowCarb
        map["proteinreich"] = L.category_highProtein
        map["glutenfrei"] = L.category_glutenFree
        map["laktosefrei"] = L.category_lactoseFree
        map["halal"] = L.category_halal
        map["koscher"] = L.category_kosher
        
        // English (en)
        map["vegetarian"] = L.category_vegetarian
        map["pescetarian"] = L.category_pescetarian
        map["pescatarian"] = L.category_pescetarian
        map["low-carb"] = L.category_lowCarb
        map["low carb"] = L.category_lowCarb
        map["high-protein"] = L.category_highProtein
        map["high protein"] = L.category_highProtein
        map["gluten-free"] = L.category_glutenFree
        map["gluten free"] = L.category_glutenFree
        map["lactose-free"] = L.category_lactoseFree
        map["lactose free"] = L.category_lactoseFree
        map["kosher"] = L.category_kosher
        
        // Spanish (es)
        map["vegetariano"] = L.category_vegetarian
        map["vegano"] = L.category_vegan
        map["pescetariano"] = L.category_pescetarian
        map["bajo en carbohidratos"] = L.category_lowCarb
        map["alto en proteínas"] = L.category_highProtein
        map["sin gluten"] = L.category_glutenFree
        map["sin lactosa"] = L.category_lactoseFree
        map["cosher"] = L.category_kosher
        
        // French (fr)
        map["végétarien"] = L.category_vegetarian
        map["végétalien"] = L.category_vegan
        map["pescétarien"] = L.category_pescetarian
        map["faible en glucides"] = L.category_lowCarb
        map["riche en protéines"] = L.category_highProtein
        map["sans gluten"] = L.category_glutenFree
        map["sans lactose"] = L.category_lactoseFree
        map["cacher"] = L.category_kosher
        
        // Italian (it)
        map["pescetariano"] = L.category_pescetarian
        map["basso contenuto di carboidrati"] = L.category_lowCarb
        map["ricco di proteine"] = L.category_highProtein
        map["senza glutine"] = L.category_glutenFree
        map["senza lattosio"] = L.category_lactoseFree
        map["casher"] = L.category_kosher
        
        return map
    }()
    
    private func loadFromApp() {
        Logger.debug("[DietarySettingsView] loadFromApp() called, isSaving: \(isSaving)", category: .data)
        let d = app.dietary
        
        // Map stored dietary types to current localized strings
        // This handles cases where dietary types were saved in a different language
        let currentOptions = dietOptions
        let storedDiets = d.diets
        
        var mappedDiets: Set<String> = []
        
        // Map each stored diet to the current localized equivalent
        for storedDiet in storedDiets {
            // Check if it already matches a current option
            if currentOptions.contains(storedDiet) {
                mappedDiets.insert(storedDiet)
            } else if let key = Self.dietLocalizationMap[storedDiet.lowercased()] {
                // Found a match in the map - use the current localized version
                let currentLocalized = key.localized
                mappedDiets.insert(currentLocalized)
                Logger.debug("[DietarySettingsView] Mapped stored diet '\(storedDiet)' to current localized '\(currentLocalized)'", category: .data)
            } else {
                // Try case-insensitive match
                let lowercased = storedDiet.lowercased()
                if let key = Self.dietLocalizationMap[lowercased] {
                    let currentLocalized = key.localized
                    mappedDiets.insert(currentLocalized)
                    Logger.debug("[DietarySettingsView] Mapped stored diet '\(storedDiet)' (case-insensitive) to current localized '\(currentLocalized)'", category: .data)
                } else {
                    // No match found - keep the original (might be a custom value or legacy)
                    mappedDiets.insert(storedDiet)
                    Logger.debug("[DietarySettingsView] Could not map stored diet '\(storedDiet)', keeping original", category: .data)
                }
            }
        }
        
        diets = mappedDiets
        allergies = d.allergies
        dislikes = d.dislikes
        notesText = d.notes ?? ""
        
        // Load taste preferences from Keychain (secure storage)
        let prefs = TastePreferencesManager.load()
        Logger.debug("[DietarySettingsView] Loaded taste preferences from Keychain - spicyLevel: \(prefs.spicyLevel), sweet: \(prefs.sweet), sour: \(prefs.sour), bitter: \(prefs.bitter), umami: \(prefs.umami)", category: .data)
        
        let oldSpicyLevel = spicyLevel
        let oldSweet = tastePreferences["süß"] ?? false
        let oldSour = tastePreferences["sauer"] ?? false
        let oldBitter = tastePreferences["bitter"] ?? false
        let oldUmami = tastePreferences["umami"] ?? false
        
        spicyLevel = prefs.spicyLevel
        tastePreferences["süß"] = prefs.sweet
        tastePreferences["sauer"] = prefs.sour
        tastePreferences["bitter"] = prefs.bitter
        tastePreferences["umami"] = prefs.umami
        
        if oldSpicyLevel != spicyLevel || oldSweet != prefs.sweet || oldSour != prefs.sour || oldBitter != prefs.bitter || oldUmami != prefs.umami {
            Logger.debug("[DietarySettingsView] Taste preferences CHANGED - old: spicyLevel=\(oldSpicyLevel), sweet=\(oldSweet), sour=\(oldSour), bitter=\(oldBitter), umami=\(oldUmami) -> new: spicyLevel=\(spicyLevel), sweet=\(prefs.sweet), sour=\(prefs.sour), bitter=\(prefs.bitter), umami=\(prefs.umami)", category: .data)
        } else {
            Logger.debug("[DietarySettingsView] Taste preferences unchanged", category: .data)
        }
    }

    private func saveBack() {
        Logger.debug("[DietarySettingsView] saveBack() called - spicyLevel: \(spicyLevel), sweet: \(tastePreferences["süß"] ?? false), sour: \(tastePreferences["sauer"] ?? false), bitter: \(tastePreferences["bitter"] ?? false), umami: \(tastePreferences["umami"] ?? false)", category: .data)
        
        isSaving = true
        Logger.debug("[DietarySettingsView] isSaving set to true", category: .data)
        defer { 
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isSaving = false
                Logger.debug("[DietarySettingsView] isSaving set to false (after delay)", category: .data)
            }
        }
        
        // Save taste preferences to Keychain FIRST, before app.dietary changes
        // This prevents loadFromApp() from overwriting them when onChange is triggered
        var prefs = TastePreferencesManager.TastePreferences()
        prefs.spicyLevel = spicyLevel
        prefs.sweet = tastePreferences["süß"] ?? false
        prefs.sour = tastePreferences["sauer"] ?? false
        prefs.bitter = tastePreferences["bitter"] ?? false
        prefs.umami = tastePreferences["umami"] ?? false
        
        Logger.debug("[DietarySettingsView] Saving taste preferences to Keychain - spicyLevel: \(prefs.spicyLevel), sweet: \(prefs.sweet), sour: \(prefs.sour), bitter: \(prefs.bitter), umami: \(prefs.umami)", category: .data)
        
        do {
            try TastePreferencesManager.save(prefs)
            Logger.debug("[DietarySettingsView] Successfully saved taste preferences to Keychain", category: .data)
        } catch {
            Logger.error("Failed to save taste preferences to Keychain", error: error, category: .data)
        }
        
        // Now update app.dietary (this will trigger onChange, but TastePreferences are already saved)
        var d = app.dietary
        let oldDietary = d
        d.diets = diets
        d.allergies = allergies
        d.dislikes = dislikes
        d.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Logger.debug("[DietarySettingsView] Updating app.dietary - old: \(oldDietary), new: \(d)", category: .data)
        app.dietary = d
        Logger.debug("[DietarySettingsView] app.dietary updated, onChange should trigger", category: .data)
        
        // Convert to dictionary for Supabase sync
        // Use English keys as expected by Supabase schema
        var tastePrefsDict: [String: Any] = ["spicy_level": spicyLevel]
        tastePrefsDict["sweet"] = tastePreferences["süß"] ?? false
        tastePrefsDict["sour"] = tastePreferences["sauer"] ?? false
        tastePrefsDict["bitter"] = tastePreferences["bitter"] ?? false
        tastePrefsDict["umami"] = tastePreferences["umami"] ?? false
        
        // Sync to Supabase in background
        Task {
            try? await app.savePreferencesToSupabase(
                allergies: allergies,
                dietaryTypes: diets,
                tastePreferences: tastePrefsDict,
                dislikes: dislikes,
                notes: d.notes,
                onboardingCompleted: true
            )
        }
    }
}

private struct FlowLayout<T: Hashable, V: View>: View {
    let items: [T]
    let content: (T) -> V
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        VStack {
            GeometryReader { geo in
                generateContent(in: geo)
            }
            .frame(height: totalHeight)
        }
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if index == items.count - 1 { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == items.count - 1 { height = 0 }
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

private struct WrapDietChips: View {
    let options: [String]
    @Binding var selection: Set<String>
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        VStack {
            GeometryReader { geo in
                generateContent(in: geo)
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
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
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
