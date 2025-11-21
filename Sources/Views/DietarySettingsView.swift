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

    private let dietOptions: [String] = [
        "vegetarisch", "vegan", "pescetarisch", "low-carb", "high-protein", "glutenfrei", "laktosefrei", "halal", "koscher"
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.pink.opacity(0.2), Color.purple.opacity(0.3), Color.blue.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.settings_ernährungsweisen.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        WrapDietChips(options: dietOptions, selection: $diets)
                            .padding(.bottom, 6)
                            .onChange(of: diets) { _, _ in saveBack() }

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
                        }

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
                        }

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
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .padding(16)
            }
        }
        .onAppear { loadFromApp() }
    }

    private func loadFromApp() {
        let d = app.dietary
        diets = d.diets
        allergies = d.allergies
        dislikes = d.dislikes
        notesText = d.notes ?? ""
        
        // Load taste preferences from Keychain (secure storage)
        let prefs = TastePreferencesManager.load()
        spicyLevel = prefs.spicyLevel
        tastePreferences["süß"] = prefs.sweet
        tastePreferences["sauer"] = prefs.sour
        tastePreferences["bitter"] = prefs.bitter
        tastePreferences["umami"] = prefs.umami
    }

    private func saveBack() {
        var d = app.dietary
        d.diets = diets
        d.allergies = allergies
        d.dislikes = dislikes
        d.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        app.dietary = d
        
        // Save taste preferences to Keychain (secure storage)
        var prefs = TastePreferencesManager.TastePreferences()
        prefs.spicyLevel = spicyLevel
        prefs.sweet = tastePreferences["süß"] ?? false
        prefs.sour = tastePreferences["sauer"] ?? false
        prefs.bitter = tastePreferences["bitter"] ?? false
        prefs.umami = tastePreferences["umami"] ?? false
        
        do {
            try TastePreferencesManager.save(prefs)
        } catch {
            Logger.error("Failed to save taste preferences to Keychain", error: error, category: .data)
        }
        
        // Convert to dictionary for Supabase sync
        var tastePrefsDict: [String: Any] = ["spicy_level": spicyLevel]
        for (key, value) in tastePreferences {
            tastePrefsDict[key] = value
        }
        
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
