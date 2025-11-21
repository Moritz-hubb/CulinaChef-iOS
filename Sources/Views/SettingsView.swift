import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @FocusState private var isFocused: Bool
    @State private var showDietary = false
    @State private var showProfile = false
    @State private var showSubscription = false
    @State private var showNotifications = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteSuccess = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showImprint = false
    @State private var showFairUse = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    private var backgroundGradient: LinearGradient {
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
    
    private var generalSettingsSection: some View {
        SectionCard(title: L.settings.localized) {
            VStack(spacing: 12) {
                Button(action: { showNotifications = true }) {
                    settingsRow(icon: "bell", text: L.notifications.localized)
                }
                .accessibilityLabel(L.notifications.localized)
                .accessibilityHint("Öffnet Benachrichtigungseinstellungen")
                Button(action: { app.showLanguageSettings = true }) {
                    settingsRow(icon: "globe", text: L.language.localized)
                }
                .accessibilityLabel(L.language.localized)
                .accessibilityHint("Öffnet Spracheinstellungen")
            }
        }
    }
    
    private var dietarySection: some View {
        SectionCard(title: L.dietary.localized) {
            Button(action: { showDietary = true }) {
                HStack {
                    Image(systemName: "leaf").foregroundStyle(.green)
                    Text(L.dietaryPreferences.localized).font(.subheadline).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.6))
                }
                .padding(12)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .accessibilityLabel(L.dietaryPreferences.localized)
            .accessibilityHint("Öffnet Ernährungspräferenzen")
        }
    }
    
    private var privacySection: some View {
        SectionCard(title: NSLocalizedString("settings.privacy", value: "Datenschutz & KI", comment: "Privacy section title")) {
            VStack(spacing: 12) {
                // OpenAI Consent Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text(NSLocalizedString("settings.openai_consent", value: "OpenAI Einwilligung", comment: "OpenAI consent setting"))
                                .font(.subheadline)
                        }
                        Text(OpenAIConsentManager.hasConsent 
                            ? NSLocalizedString("settings.consent_granted", value: "Erteilt", comment: "Consent granted") 
                            : NSLocalizedString("settings.consent_not_granted", value: "Nicht erteilt", comment: "Consent not granted"))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    if OpenAIConsentManager.hasConsent {
                        Button(NSLocalizedString("settings.revoke_consent", value: "Widerrufen", comment: "Revoke consent button")) {
                            OpenAIConsentManager.resetConsent()
                        }
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.15), in: Capsule())
                    }
                }
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
    }
    
    private var legalSection: some View {
        SectionCard(title: L.settings_legal.localized) {
            VStack(spacing: 12) {
                Button(action: { showTerms = true }) {
                    settingsRow(icon: "doc.text", text: L.legalTerms.localized)
                }
                .accessibilityLabel(L.legalTerms.localized)
                .accessibilityHint("Öffnet die Nutzungsbedingungen")
                Button(action: { showPrivacy = true }) {
                    settingsRow(icon: "hand.raised", text: L.legalPrivacy.localized)
                }
                .accessibilityLabel(L.legalPrivacy.localized)
                .accessibilityHint("Öffnet die Datenschutzerklärung")
                Button(action: { showImprint = true }) {
                    settingsRow(icon: "info.circle", text: L.legalImprint.localized)
                }
                .accessibilityLabel(L.legalImprint.localized)
                .accessibilityHint("Öffnet das Impressum")
                Button(action: { showFairUse = true }) {
                    settingsRow(icon: "shield.checkered", text: "Fair Use Policy")
                }
                .accessibilityLabel("Fair Use Policy")
                .accessibilityHint("Öffnet die Fair Use Policy")
            }
        }
    }
    
    private var accountSection: some View {
        SectionCard(title: L.profile.localized) {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: { showProfile = true }) {
                    settingsRow(icon: "person.crop.circle", text: L.nav_profileSettings.localized)
                }
                .accessibilityLabel(L.nav_profileSettings.localized)
                .accessibilityHint("Öffnet Profileinstellungen")
                Button(action: { showSubscription = true }) {
                    settingsRow(icon: "creditcard", text: L.nav_subscription.localized)
                }
                .accessibilityLabel(L.nav_subscription.localized)
                .accessibilityHint("Öffnet Abo-Verwaltung")
                Button(action: { Task { await app.signOut() } }) {
                    Text(L.signOut.localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                        .shadow(color: .pink.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .accessibilityLabel(L.signOut.localized)
                .accessibilityHint("Meldet Sie ab")
                Button(role: .destructive, action: { showDeleteConfirm = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text(L.deleteAccount.localized).font(.subheadline)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .accessibilityLabel(L.deleteAccount.localized)
                .accessibilityHint("Löscht das Konto und alle Daten")
            }
        }
    }
    
    private func settingsRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text).font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.6))
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    generalSettingsSection
                    dietarySection
                    privacySection
                    legalSection
                    accountSection
                }
                .padding(16)
            }
        }
.sheet(isPresented: $showDietary) {
            DietarySettingsSheet()
                .presentationDetents([PresentationDetent.large])
        }
        .sheet(isPresented: $showProfile) {
            ProfileSettingsSheet()
                .presentationDetents([PresentationDetent.large])
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionSettingsSheet()
                .presentationDetents([PresentationDetent.large])
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSettingsSheet()
                .presentationDetents([PresentationDetent.large])
        }
        .sheet(isPresented: $app.showLanguageSettings) {
            LanguageSettingsSheet()
                .presentationDetents([PresentationDetent.large])
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showImprint) {
            ImprintView()
        }
        .sheet(isPresented: $showFairUse) {
            FairUseView()
        }
        .alert(L.deleteAccountConfirm.localized, isPresented: $showDeleteConfirm) {
            Button(L.manageSubscription.localized, role: .none) {
                Task { await app.openManageSubscriptions() }
            }
            Button(L.deleteNow.localized, role: .destructive) {
                Task {
                    await app.deleteAccountAndData()
                    showDeleteSuccess = true
                }
            }
            Button(L.cancel.localized, role: .cancel) { }
        } message: {
            Text(L.deleteAccountMessage.localized)
        }
        .alert(L.accountDeleted.localized, isPresented: $showDeleteSuccess) {
            Button(L.ok.localized, role: .cancel) {
                Task { await app.signOut() }
            }
        } message: {
            Text(L.accountDeletedMessage.localized)
        }
        .alert(L.alert_error.localized, isPresented: $showError) {
            Button(L.button_ok.localized, role: .cancel) { }
        } message: {
            Text(errorMessage ?? L.errorGeneric.localized)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L.done.localized) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
            }
        }
    }
}

// MARK: - Legal Placeholder View
private struct LegalPlaceholderView: View {
    let title: String
    let text: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(text)
                        .font(.body)
                        .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.done.localized) { dismiss() }
                }
            }
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
                .id(localizationManager.currentLanguage)
            content
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// Sheet embedded here to avoid project file regeneration when adding new files
private struct DietarySettingsSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var diets: Set<String> = []
    @State private var allergiesText: String = ""
    @State private var dislikesText: String = ""
    @State private var notesText: String = ""
    @State private var spicyLevel: Double = 2
    @State private var tastePreferences: [String: Bool] = [
        "süß": false,
        "sauer": false,
        "bitter": false,
        "umami": false
    ]
    @State private var isAIDisclaimerExpanded = false

    private var dietOptions: [String] {
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
    
    private var isGerman: Bool {
        localizationManager.currentLanguage == "de"
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text(L.settings_ernährung_01ac.localized)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        Button(L.settings_finished.localized) { dismiss() }
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
.background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    
                    // Ausklappbare KI-Disclaimer-Box
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isAIDisclaimerExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.title3)
                                Text(isGerman ? "Wichtiger Hinweis zu KI-generierten Rezepten" : "Important Notice Regarding AI-Generated Recipes")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: isAIDisclaimerExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .font(.caption)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(12, corners: isAIDisclaimerExpanded ? [.topLeft, .topRight] : .allCorners)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if isAIDisclaimerExpanded {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(isGerman ?
                                    "KI-Systeme können Fehler machen. Bitte überprüfen Sie alle KI-generierten Rezepte sorgfältig, bevor Sie sie zubereiten. Insbesondere bei Allergien, Unverträglichkeiten oder speziellen Ernährungsanforderungen sollten Sie die Zutatenliste und Anweisungen doppelt prüfen." :
                                    "AI systems can make errors. Please carefully review all AI-generated recipes before preparing them. Especially if you have allergies, intolerances, or special dietary requirements, you should double-check the ingredient list and instructions.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .lineSpacing(4)
                                
                                Text(isGerman ?
                                    "Wir übernehmen keine Haftung für gesundheitliche Folgen, die durch die Verwendung von KI-generierten Rezepten entstehen. Die Verantwortung für die Überprüfung der Rezepte und die Entscheidung, ob ein Rezept für Ihre individuellen Bedürfnisse geeignet ist, liegt allein bei Ihnen." :
                                    "We assume no liability for health consequences arising from the use of AI-generated recipes. The responsibility for reviewing recipes and deciding whether a recipe is suitable for your individual needs lies solely with you.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .lineSpacing(4)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.settings_ernährungsweisen_003f.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        WrapDietChipsInline(options: dietOptions, selection: $diets)
                            .padding(.bottom, 6)
                            .onChange(of: diets) { _, _ in saveBack() }

                        Text(L.settings_allergienunverträglichkeiten_kommag.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        TextField(L.placeholder_allergies.localized, text: $allergiesText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .tint(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: allergiesText) { _, _ in saveBack() }

                        Text(L.settings_dislikes.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        TextField(L.placeholder_dislikes.localized, text: $dislikesText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .tint(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: dislikesText) { _, _ in saveBack() }

                        Text(L.settings_geschmackspräferenzen_2f71.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        VStack(spacing: 10) {
                            HStack {
                                Text(L.settings_schärfelevel_b3e3.localized)
                                    .font(.callout)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text([L.spicy_mild.localized, L.spicy_normal.localized, L.spicy_hot.localized, L.spicy_veryHot.localized][Int(spicyLevel)])
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                            Slider(value: $spicyLevel, in: 0...3, step: 1)
                                .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                                .onChange(of: spicyLevel) { _, _ in saveBack() }
                            
                            ForEach(["süß", "sauer", "bitter", "umami"], id: \.self) { key in
                                Toggle(localizedTasteName(key), isOn: Binding(
                                    get: { tastePreferences[key] ?? false },
                                    set: { newValue in
                                        tastePreferences[key] = newValue
                                        saveBack()
                                    }
                                ))
                                .font(.callout)
                                .foregroundStyle(.white)
                                .tint(Color(red: 0.95, green: 0.5, blue: 0.3))
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text(L.settings_hints.localized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        TextField(L.placeholder_notes.localized, text: $notesText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .tint(.white)
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
        .onAppear {
            loadFromApp()
        }
    }
    
    private func localizedTasteName(_ key: String) -> String {
        switch key {
        case "süß": return L.taste_sweet.localized
        case "sauer": return L.taste_sour.localized
        case "bitter": return L.taste_bitter.localized
        case "umami": return L.taste_umami.localized
        default: return key
        }
    }
    
    private func loadFromApp() {
        let d = app.dietary
        diets = d.diets
        allergiesText = d.allergies.joined(separator: ", ")
        dislikesText = d.dislikes.joined(separator: ", ")
        notesText = d.notes ?? ""
        
        // Load taste preferences from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "taste_preferences"),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            spicyLevel = dict["spicy_level"] as? Double ?? 2
            tastePreferences["süß"] = dict["sweet"] as? Bool ?? false
            tastePreferences["sauer"] = dict["sour"] as? Bool ?? false
            tastePreferences["bitter"] = dict["bitter"] as? Bool ?? false
            tastePreferences["umami"] = dict["umami"] as? Bool ?? false
        }
    }

    private func saveBack() {
        var d = app.dietary
        d.diets = diets
        d.allergies = allergiesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        d.dislikes = dislikesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        d.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        app.dietary = d
        
        // Save taste preferences to UserDefaults
        var tastePrefsDict: [String: Any] = ["spicy_level": spicyLevel]
        for (key, value) in tastePreferences {
            tastePrefsDict[key] = value
        }
        if let data = try? JSONSerialization.data(withJSONObject: tastePrefsDict) {
            UserDefaults.standard.set(data, forKey: "taste_preferences")
        }
        
        // Sync to Supabase in background
        Task {
            do {
                Logger.sensitive("[DietarySettings] Saving to Supabase - diets: \(Array(diets)), allergies: \(d.allergies), dislikes: \(d.dislikes), tastePrefs: \(tastePrefsDict)", category: .data)
                try await app.savePreferencesToSupabase(
                    allergies: d.allergies,
                    dietaryTypes: diets,
                    tastePreferences: tastePrefsDict,
                    dislikes: d.dislikes,
                    notes: d.notes,
                    onboardingCompleted: true
                )
                Logger.sensitive("[DietarySettings] Successfully saved to Supabase", category: .data)
            } catch {
                Logger.error("[DietarySettings] Error saving to Supabase", error: error, category: .data)
            }
        }
    }
}

// MARK: - Account Settings Sheets
private struct ProfileSettingsSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var loading = false
    @State private var error: String?
    @State private var saved = false
    @State private var recipesCount = 0
    @State private var favoritesCount = 0
    @State private var ratingsCount = 0
    @State private var allergies: String = ""
    @State private var dietTypes: String = ""
    
    @State private var showPasswordChange = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordError: String?
    @State private var passwordSuccess = false
    
    private var isGerman: Bool {
        localizationManager.currentLanguage == "de"
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Spacer()
                    if loading { ProgressView().tint(.white) }
                    Button(L.settings_finished.localized) { dismiss() }
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                if let error { Text(error).foregroundStyle(.red).font(.footnote) }
                ScrollView {
                    VStack(spacing: 20) {
                        // Account Section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                                Text(L.settings_account.localized)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.bottom, 4)
                            
                            DataRow(label: L.settings_username.localized, value: username.isEmpty ? "–" : username)
                            DataRow(label: L.email.localized, value: app.userEmail ?? "–")
                            
                            Divider().background(.white.opacity(0.2))
                            
                            Button {
                                showPasswordChange.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                                    Text(L.settings_passwort_ändern.localized)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: showPasswordChange ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                            
                            if showPasswordChange {
                                VStack(spacing: 12) {
                                    if let passwordError {
                                        Text(passwordError)
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                    if passwordSuccess {
                                        Text(L.settings_passwort_erfolgreich_geändert.localized)
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L.settings_currentPassword.localized)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                        SecureField("", text: $currentPassword)
                                            .textFieldStyle(.plain)
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L.settings_newPassword.localized)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                        SecureField("", text: $newPassword)
                                            .textFieldStyle(.plain)
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L.settings_passwort_bestätigen.localized)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                        SecureField("", text: $confirmPassword)
                                            .textFieldStyle(.plain)
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    
                                    Button {
                                        Task { await changePassword() }
                                    } label: {
                                        Text(L.settings_passwort_ändern_aea8.localized)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(red: 0.95, green: 0.5, blue: 0.3), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                                    .opacity(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty ? 0.5 : 1)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(18)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        
                        // Activity Section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                                Text(L.settings_aktivität.localized)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.bottom, 4)
                            
                            HStack(spacing: 20) {
                                StatCard(icon: "book.fill", label: L.settings_recipesCount.localized, value: "\(recipesCount)")
                                StatCard(icon: "heart.fill", label: L.settings_favoritesCount.localized, value: "\(favoritesCount)")
                                StatCard(icon: "star.fill", label: L.settings_ratingsCount.localized, value: "\(ratingsCount)")
                            }
                        }
                        .padding(18)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        
                        // Preferences Section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                                Text(L.settings_präferenzen.localized)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.bottom, 4)
                            
                            DataRow(label: L.settings_allergiesLabel.localized, value: allergies.isEmpty ? L.settings_none.localized : allergies)
                            DataRow(label: L.settings_dietaryTypesLabel.localized, value: dietTypes.isEmpty ? L.settings_none.localized : dietTypes)
                        }
                        .padding(18)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        
                        // Export Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                                Text(isGerman ? "Datenexport" : "Data Export")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(isGerman ? 
                                    "Du kannst deine Rezepte jederzeit als JSON-Datei exportieren." :
                                    "You can export your recipes as a JSON file at any time.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                
                                Button {
                                    Task { await exportRecipes() }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text(isGerman ? "Rezepte exportieren" : "Export Recipes")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                
                                Divider().background(.white.opacity(0.2)).padding(.vertical, 4)
                                
                                Text(isGerman ?
                                    "Für vollständigen Datenexport (inkl. personenbezogener Daten) kontaktiere:" :
                                    "For complete data export (incl. personal data) contact:")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                Link(destination: URL(string: "mailto:datenschutz@culinaai.com?subject=Datenexport%20Anfrage")!) {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                        Text("datenschutz@culinaai.com")
                                            .font(.caption.weight(.medium))
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                        }
                        .padding(18)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                }
            }
            .padding(16)
        }
        .task { await load() }
    }

    private func load() async {
        loading = true; error = nil; saved = false
        defer { loading = false }
        do {
            if let p = try await app.fetchProfile() {
                fullName = p.full_name ?? ""
                email = p.email ?? app.userEmail ?? ""
                username = p.username
            } else {
                fullName = ""
                email = app.userEmail ?? ""
                username = ""
            }
            
            // Load dietary preferences
            let prefs = UserDefaults.standard
            if let allergyData = prefs.string(forKey: "allergies") {
                allergies = allergyData
            }
            if let dietsData = prefs.data(forKey: "dietary_types"),
               let dietsSet = try? JSONDecoder().decode(Set<String>.self, from: dietsData) {
                dietTypes = Array(dietsSet).sorted().joined(separator: ", ")
            }
            
            // Load counts (backend endpoints pending)
            // Placeholder values until backend provides endpoints
            recipesCount = 0
            favoritesCount = 0
            ratingsCount = 0
            
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() async {
        loading = true; error = nil; saved = false
        defer { loading = false }
        do {
            try await app.saveProfile(fullName: fullName, email: email)
            saved = true
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func changePassword() async {
        passwordError = nil
        passwordSuccess = false
        
        // Validate passwords match
        guard newPassword == confirmPassword else {
            passwordError = L.settings_passwordsDoNotMatch.localized
            return
        }
        
        // Validate password length (same as SignUp)
        guard newPassword.count >= 6 else {
            passwordError = L.settings_passwordTooShort.localized
            return
        }
        
        loading = true
        defer { loading = false }
        
        do {
            // First verify current password by attempting to sign in
            guard let email = app.userEmail else {
                passwordError = L.settings_emailNotFound.localized
                return
            }
            
            _ = try await app.auth.signIn(email: email, password: currentPassword)
            
            // If sign in successful, change password
            guard let token = app.accessToken else {
                passwordError = L.settings_notLoggedIn.localized
                return
            }
            
            try await app.auth.changePassword(accessToken: token, newPassword: newPassword)
            
            // Clear fields and show success
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            passwordSuccess = true
            
            // Hide success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                passwordSuccess = false
            }
            
        } catch {
            passwordError = L.settings_wrongPassword.localized
        }
    }
    
    private func exportRecipes() async {
        loading = true
        defer { loading = false }
        
        do {
            // Fetch all recipes from backend
            guard let token = app.accessToken else {
                error = L.errorNotLoggedIn.localized
                return
            }
            
            var url = Config.supabaseURL
            url.append(path: "/rest/v1/recipes")
            url.append(queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ])
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await SecureURLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                error = L.errorExportFailed.localized
                return
            }
            
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            
            // Create export data structure
            let exportData: [String: Any] = [
                "export_date": ISO8601DateFormatter().string(from: Date()),
                "user_email": app.userEmail ?? "unknown",
                "recipe_count": recipes.count,
                "recipes": recipes.map { recipe in
                    [
                        "id": recipe.id,
                        "title": recipe.title,
                        "ingredients": recipe.ingredients,
                        "instructions": recipe.instructions,
                        "nutrition": recipe.nutrition,
                        "created_at": recipe.created_at ?? "unknown"
                    ]
                }
            ]
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            
            // Save to temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "CulinaChef_Export_\(ISO8601DateFormatter().string(from: Date())).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            
            // Share via ShareSheet
            await MainActor.run {
                let activityVC = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    activityVC.popoverPresentationController?.sourceView = window
                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    activityVC.popoverPresentationController?.permittedArrowDirections = []
                    rootVC.present(activityVC, animated: true)
                }
            }
            
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct SubscriptionSettingsSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showFairUsePolicy = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var hasAcceptedFairUse = false
    @State private var showError = false
    @State private var errorMessage: String?

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Status Badge
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: app.isSubscribed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(app.isSubscribed ? .green : .orange)
                                Text(app.isSubscribed ? L.subscriptionUnlimitedActive.localized : L.subscriptionFreeTier.localized)
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            Spacer()
                        }
                        
                        // Plan header
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(.white)
                                .shadow(color: .white.opacity(0.3), radius: 10)
                            
                            Text(L.subscriptionUnlimited.localized)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("5,99€")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(L.subscriptionPerMonth.localized)
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))

                        // Perks
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L.settings_deine_vorteile.localized).font(.headline).foregroundStyle(.white)
                            PerkRow(icon: "sparkles", text: L.subscriptionAIChatUnlimited.localized)
                            PerkRow(icon: "wand.and.stars", text: L.subscriptionAIRecipeGenerator.localized)
                            PerkRow(icon: "chart.bar", text: L.subscriptionAINutritionAnalysis.localized)
                            PerkRow(icon: "infinity", text: L.subscriptionNoLimits.localized)
                            PerkRow(icon: "books.vertical", text: L.settings_perk_community.localized)
                            
                            Divider().background(.white.opacity(0.2)).padding(.vertical, 4)
                            
                            // Fair Use Policy Link
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L.subscriptionFairUseInfo.localized)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                
                                Button {
                                    showFairUsePolicy = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                        Text(L.legalFairUseLink.localized)
                                            .font(.caption)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))

                        // Status card
                        VStack(alignment: .leading, spacing: 8) {
                            let auto = app.getSubscriptionAutoRenew()
                            let periodEnd = app.getSubscriptionPeriodEnd()
                            let active = app.isSubscribed
                            if active {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(L.subscriptionUnlimitedActive.localized)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                if auto {
                                    if let end = periodEnd { 
                                        Text("\(L.subscriptionNextBilling.localized) \(dateFormatter.string(from: end))")
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                    }
                                    Text(L.subscriptionAutoRenewOn.localized)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                } else {
                                    if let end = periodEnd { 
                                        Text("\(L.subscriptionExpiresOn.localized) \(dateFormatter.string(from: end))")
                                            .font(.subheadline)
                                            .foregroundStyle(.orange)
                                    }
                                    Text(L.subscriptionAutoRenewOff.localized)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text(L.subscriptionKeepFeaturesUntilExpiry.localized)
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            } else {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text(L.subscriptionFreeTier.localized)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                Text(L.subscriptionAllFeaturesExceptAI.localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                                Text(L.subscriptionUpgradeForAI.localized)
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))

                        // Actions
                        VStack(spacing: 16) {
                            if app.isSubscribed {
                                // Apple Subscription Management
                                Button {
                                    Task { await app.openManageSubscriptions() }
                                } label: {
                                    HStack {
                                        Image(systemName: "gearshape.fill")
                                        Text(L.subscriptionManageInAppleSettings.localized)
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                                }
                                
                                Text(L.subscriptionManageCancelInfo.localized)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            } else {
                                // Fair Use Policy Checkbox
                                VStack(spacing: 12) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Button(action: { hasAcceptedFairUse.toggle() }) {
                                            Image(systemName: hasAcceptedFairUse ? "checkmark.square.fill" : "square")
                                                .font(.title3)
                                                .foregroundStyle(hasAcceptedFairUse ? Color(red: 0.2, green: 0.6, blue: 0.9) : .white.opacity(0.7))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 4) {
                                                Text(L.legalFairUseCheckbox.localized)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.white)
                                                
                                                Button(action: { showFairUsePolicy = true }) {
                                                    Text(L.legalFairUseCheckboxLink.localized)
                                                        .font(.subheadline)
                                                        .underline()
                                                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.9))
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                    
                                    // Purchase Button
                                    Button {
                                    // Validate Fair Use Policy acceptance
                                    guard hasAcceptedFairUse else {
                                        errorMessage = L.legalFairUseCheckboxRequired.localized
                                        showError = true
                                        return
                                    }
                                    
                                    isPurchasing = true
                                    errorMessage = nil
                                    Task {
                                        await app.purchaseStoreKit()
                                        isPurchasing = false
                                    }
                                } label: {
                                    HStack {
                                        if isPurchasing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "sparkles")
                                            Text(L.subscriptionUnlockUnlimited.localized)
                                        }
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                                }
                                .disabled(isPurchasing)
                                
                                // Restore Button
                                Button {
                                    isRestoring = true
                                    Task {
                                        await app.restorePurchases()
                                        isRestoring = false
                                    }
                                } label: {
                                    HStack {
                                        if isRestoring {
                                            ProgressView()
                                                .tint(.white.opacity(0.7))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text(L.subscriptionRestorePurchases.localized)
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                }
                                .disabled(isRestoring)
                                
                                Text(L.subscriptionCancelAnytime.localized)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // Legal Footer
                        VStack(spacing: 8) {
                            Divider().background(.white.opacity(0.2))
                            
                            Text(L.legalPurchaseConsentText.localized)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                Button(L.legalTermsNavTitle.localized) {
                                    showTerms = true
                                }
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                                
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.4))
                                
                                Button(L.legalPrivacyNavTitle.localized) {
                                    showPrivacy = true
                                }
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.settings_finished.localized) { dismiss() }
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            }
        }
        .onAppear { 
            Task {
                await app.refreshSubscriptionStatusFromStoreKit()
                await app.storeKit.loadProducts()
            }
        }
        .sheet(isPresented: $showFairUsePolicy) {
            FairUseView()
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .alert(L.alert_error.localized, isPresented: $showError) {
            Button(L.button_ok.localized, role: .cancel) { }
        } message: {
            Text(errorMessage ?? L.errorGeneric.localized)
        }
    }
}

private struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct PerkRow: View {
    var icon: String
    var text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct LabeledField: View {
    var label: String
    var placeholder: String
    @State private var value: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline).foregroundStyle(.white)
TextField(placeholder, text: $value)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct PlanPill: View {
    var title: String
    var highlight: Bool
    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Group {
                    if highlight {
                        LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Color.white.opacity(0.08)
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - General Settings Sheets
private struct AppearanceSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text(L.settings_erscheinungsbild.localized).font(.title2.bold()).foregroundStyle(.white)
                    Spacer()
                    Button(L.settings_finished.localized) { dismiss() }
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
.background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
.tint(Color(red: 0.95, green: 0.5, blue: 0.3))
.foregroundStyle(.white)
                        .onChange(of: isDarkMode) { _, _ in
                            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                        }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .padding(16)
        }
    }
}

struct NotificationsSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notif_general") private var notifGeneral: Bool = true
    @AppStorage("notif_recipe") private var notifRecipe: Bool = true
    @AppStorage("notif_offers") private var notifOffers: Bool = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text(L.notifications.localized).font(.title2.bold()).foregroundStyle(.white)
                    Spacer()
                    Button(L.done.localized) { dismiss() }
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
.background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                VStack(alignment: .leading, spacing: 12) {
Toggle(L.notificationsGeneral.localized, isOn: $notifGeneral).tint(Color(red: 0.95, green: 0.5, blue: 0.3)).foregroundStyle(.white)
Toggle(L.notificationsRecipe.localized, isOn: $notifRecipe).tint(Color(red: 0.95, green: 0.5, blue: 0.3)).foregroundStyle(.white)
Toggle(L.notificationsOffers.localized, isOn: $notifOffers).tint(Color(red: 0.95, green: 0.5, blue: 0.3)).foregroundStyle(.white)
                    Text(L.notificationsManage.localized).font(.footnote).foregroundStyle(.white.opacity(0.7))
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .padding(16)
        }
    }
}

private struct LanguageSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedLanguage: String
    
    init() {
        // Initialize with current language
        _selectedLanguage = State(initialValue: LocalizationManager.shared.currentLanguage)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.75), Color(red: 1.0, green: 0.8, blue: 0.7), Color(red: 0.99, green: 0.7, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text(L.language.localized).font(.title2.bold()).foregroundStyle(.white)
                    Spacer()
                    Button(L.done.localized) {
                        // Save the current settings sheet state
                        let wasSettingsOpen = app.showSettings
                        
                        // Close the language settings sheet first
                        dismiss()
                        
                        // Apply language change after a delay to ensure sheet is closed
                        if selectedLanguage != localizationManager.currentLanguage {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // Change language
                                localizationManager.currentLanguage = selectedLanguage
                                
                                // Ensure settings sheet stays open if it was open before
                                if wasSettingsOpen {
                                    // Use another small delay to ensure the view hierarchy is stable
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        app.showSettings = true
                                    }
                                }
                            }
                        }
                    }
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                VStack(spacing: 12) {
                    ForEach(Array(localizationManager.availableLanguages.keys.sorted()), id: \.self) { code in
                        Button {
                            // Only update local state, not the actual language
                            selectedLanguage = code
                        } label: {
                            HStack {
                                Text(languageFlag(code))
                                    .font(.title2)
                                Text(localizationManager.availableLanguages[code] ?? code)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                Spacer()
                                if selectedLanguage == code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(red: 0.95, green: 0.5, blue: 0.3))
                                }
                            }
                            .padding(16)
                            .background(
                                selectedLanguage == code 
                                    ? Color.white.opacity(0.15) 
                                    : Color.white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                
                Spacer()
            }
            .padding(16)
        }
    }
    
    private func languageFlag(_ code: String) -> String {
        switch code {
        case "de": return "🇩🇪"
        case "en": return "🇬🇧"
        case "fr": return "🇫🇷"
        case "it": return "🇮🇹"
        case "es": return "🇪🇸"
        default: return "🌐"
        }
    }
}

private struct WrapDietChipsInline: View {
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
