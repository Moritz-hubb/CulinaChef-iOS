import SwiftUI

struct OnboardingView: View {
@ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var buttonScale: CGFloat = 1.0
    @State private var showSuccessAnimation = false
    @State private var selectedLanguage: String = ""
    @State private var allergies: [String] = []
    @State private var newAllergyText = ""
    @State private var selectedDiets: Set<String> = []
    @State private var spicyLevel: Double = 2 // 0=mild, 1=normal, 2=scharf, 3=sehr scharf
    @State private var tastePreferences: [String: Bool] = [:]
    
    private func initializeTastePreferences() {
        let keys = [
            L.taste_sweet.localized,
            L.taste_sour.localized,
            L.taste_bitter.localized,
            L.taste_umami.localized
        ]
        
        // Check if we need to migrate (if current keys don't match new keys)
        let currentKeys = Set(tastePreferences.keys)
        let newKeys = Set(keys)
        
        if currentKeys != newKeys {
            // Language changed - reset preferences with new keys
            tastePreferences = [:]
            for key in keys {
                tastePreferences[key] = false
            }
        } else {
            // Same language - just ensure all keys exist
            for key in keys {
                if tastePreferences[key] == nil {
                    tastePreferences[key] = false
                }
            }
        }
    }
    @State private var dislikes: [String] = []
    @State private var newDislikeText = ""
    @State private var isSaving = false
    
    private var dietOptions: [String] {
        let _ = localizationManager.currentLanguage // Force recomputation when language changes
        return [
            L.vegetarian.localized,
            L.vegan.localized,
            L.pescetarian.localized,
            L.lowCarb.localized,
            L.highProtein.localized,
            L.glutenFree.localized,
            L.lactoseFree.localized,
            L.halal.localized,
            L.kosher.localized
        ]
    }
    
    private var spicyLabels: [String] {
        let _ = localizationManager.currentLanguage // Force recomputation when language changes
        return [
            L.mild.localized,
            L.normal.localized,
            L.spicy.localized,
            L.verySpicy.localized
        ]
    }
    
    private var tastePreferenceKeys: [String] {
        let _ = localizationManager.currentLanguage // Force recomputation when language changes
        return [
            L.taste_sweet.localized,
            L.taste_sour.localized,
            L.taste_bitter.localized,
            L.taste_umami.localized
        ]
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching the app theme
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.85, blue: 0.75), // Light peach
                    Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Penguin illustration at top
                if let uiImage = UIImage(named: "penguin-onboarding") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, 50)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                        .padding(.top, 50)
                        .accessibilityHidden(true)
                }
                
                // Progress indicator
                progressBar
                
                // Content
                TabView(selection: $currentStep) {
                    step0LanguageSelection.tag(0)
                    step1Allergies.tag(1)
                    step2DietaryTypes.tag(2)
                    step3Preferences.tag(3)
                    step4Dislikes.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2), value: currentStep)
                .id(localizationManager.currentLanguage) // Force re-render when language changes
                
                // Navigation buttons
                navigationButtons
            }
        }
        .interactiveDismissDisabled()
        .id(localizationManager.currentLanguage) // Force entire view to re-render when language changes
        .onAppear {
            // Initialize selectedLanguage with current language (system language) if not already set
            if selectedLanguage.isEmpty {
                selectedLanguage = localizationManager.currentLanguage
            }
            initializeTastePreferences()
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Re-initialize taste preferences when language changes
            initializeTastePreferences()
            // Reset selected diets when language changes (keys are localized)
            selectedDiets = []
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index <= currentStep ? 
                              LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [Color.white.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 4)
                        .shadow(color: index <= currentStep ? Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3) : .clear, radius: 4)
                        .scaleEffect(index == currentStep && showSuccessAnimation ? 1.15 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15), value: currentStep)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showSuccessAnimation)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            
            Text(L.onboarding_stepOfTotal.localized.replacingOccurrences(of: "{step}", with: "\(currentStep + 1)").replacingOccurrences(of: "{total}", with: "5"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
                .id(localizationManager.currentLanguage) // Force update when language changes
        }
    }
    
    // MARK: - Step 0: Language Selection
    private var step0LanguageSelection: some View {
        let systemLang = getSystemLanguage()
        let currentLang = localizationManager.currentLanguage // Use current app language, not system language
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(getSystemLocalizedTitle(systemLang: currentLang))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .id(localizationManager.currentLanguage) // Force re-render on language change
                    Text(getSystemLocalizedSubtitle(systemLang: currentLang))
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.6))
                        .id(localizationManager.currentLanguage) // Force re-render on language change
                }
                .padding(.top, 20)
                
                VStack(spacing: 12) {
                    ForEach(Array(LocalizationManager.shared.availableLanguages.keys.sorted()), id: \.self) { langCode in
                        LanguageOption(
                            languageCode: langCode,
                            languageName: LocalizationManager.shared.availableLanguages[langCode] ?? langCode,
                            isSelected: selectedLanguage == langCode,
                            systemLanguage: systemLang
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15)) {
                                selectedLanguage = langCode
                                // Set language immediately when selected
                                localizationManager.setLanguage(langCode)
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .onAppear {
            // Initialize with current language (system language) if not set
            // This ensures the language shown in signup is pre-selected in onboarding
            if selectedLanguage.isEmpty {
                selectedLanguage = localizationManager.currentLanguage
                // Pre-select current language but don't explicitly set it yet - user should confirm
                // The language will only be explicitly set when user clicks on a language option
            }
        }
    }
    
    // Helper functions to get system language
    private func getSystemLanguage() -> String {
        // Get device language using the same method as LocalizationManager
        var deviceLang: String = "en"
        
        // Method 1: Try Locale.current.language.languageCode
        if let langCode = Locale.current.language.languageCode?.identifier {
            deviceLang = langCode
        }
        
        // Method 2: If that didn't work or gave a region code, try preferredLanguages
        if deviceLang == "en" || deviceLang.count > 2 {
            if let preferredLang = Locale.preferredLanguages.first {
                // Extract language code from "fr-FR" format
                let components = preferredLang.components(separatedBy: "-")
                if let langCode = components.first, langCode.count == 2 {
                    deviceLang = langCode.lowercased()
                }
            }
        }
        
        // Method 3: Try Locale.current.identifier
        if deviceLang == "en" || deviceLang.count > 2 {
            let identifier = Locale.current.identifier
            let components = identifier.components(separatedBy: "_")
            if let langCode = components.first, langCode.count == 2 {
                deviceLang = langCode.lowercased()
            }
        }
        
        return LocalizationManager.shared.availableLanguages.keys.contains(deviceLang) ? deviceLang : "en"
    }
    
    // Helper functions to get localized strings using LocalizationManager
    private func getSystemLocalizedTitle(systemLang: String) -> String {
        // Use LocalizationManager to get the translation in the current app language
        return L.onboarding_selectLanguageTitle.localized
    }
    
    private func getSystemLocalizedSubtitle(systemLang: String) -> String {
        // Use LocalizationManager to get the translation in the current app language
        return L.onboarding_selectLanguageSubtitle.localized
    }
    
    // MARK: - Step 1: Allergies
    private var step1Allergies: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_allergien_unverträglichkeiten.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_damit_wir_deine_rezepte.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.6))
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        TextField(L.placeholder_newAllergy.localized, text: $newAllergyText)
                            .id(localizationManager.currentLanguage)
                            .textFieldStyle(.plain)
                            .accessibilityLabel("Allergie eingeben")
                            .accessibilityHint(L.placeholder_newAllergy.localized)
                            .padding(12)
                            .background(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        
                        Button {
                            let trimmed = newAllergyText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15)) {
                                    allergies.append(trimmed)
                                    newAllergyText = ""
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        .accessibilityLabel("Allergie hinzufügen")
                        .accessibilityHint("Fügt die eingegebene Allergie zur Liste hinzu")
                    }
                    
                    if !allergies.isEmpty {
                        FlowLayout(items: allergies) { item in
                            allergyChip(item)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .id(localizationManager.currentLanguage) // Force re-render on language change
                    } else {
                        Text(L.onboarding_keine_allergien_perfekt_weiter.localized)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.4))
                            .italic()
                            .padding(.top, 8)
                            .id(localizationManager.currentLanguage)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Step 2: Dietary Types
    private var step2DietaryTypes: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_ernährungsweise.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_wähle_deine_ernährungspräferenzen_a.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.6))
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 20)
                
                WrapDietChips(options: dietOptions, selection: $selectedDiets)
                    .id(localizationManager.currentLanguage)
                
                if selectedDiets.isEmpty {
                    Text(L.onboarding_keine_spezielle_ernährungsweise_kei.localized)
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.4))
                        .italic()
                        .padding(.top, 8)
                        .id(localizationManager.currentLanguage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Step 3: Taste Preferences
    private var step3Preferences: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_geschmackspräferenzen.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_howSpicyDoYouLikeIt.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.6))
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // Current selection display
                    VStack(spacing: 8) {
                        Text(String(repeating: "🌶️", count: Int(spicyLevel) + 1))
                            .font(.system(size: 28))
                        Text(spicyLabels[Int(spicyLevel)])
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.2))
                            .id(localizationManager.currentLanguage)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    
                    // Slider
                    VStack(spacing: 12) {
                    Slider(value: $spicyLevel, in: 0...3, step: 1)
                        .tint(LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .leading, endPoint: .trailing))
                        .accessibilityLabel("Schärfelevel")
                        .accessibilityValue(spicyLabels[Int(spicyLevel)])
                        
                        // Labels below slider
                        HStack {
                            ForEach(0..<4) { index in
                                Text(spicyLabels[index])
                                    .font(.system(size: 11, weight: Int(spicyLevel) == index ? .bold : .regular))
                                    .foregroundColor(Int(spicyLevel) == index ? Color(red: 0.85, green: 0.4, blue: 0.2) : .black.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .id("\(localizationManager.currentLanguage)_\(index)")
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    Divider().padding(.vertical, 8)
                    
                    Text(L.onboarding_additionalPreferencesOptional.localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .id(localizationManager.currentLanguage)
                    
                    VStack(spacing: 10) {
                        ForEach(Array(tastePreferences.keys.sorted()), id: \.self) { key in
                            tastePreferenceToggle(key: key)
                                .id("\(localizationManager.currentLanguage)_\(key)")
                        }
                    }
                    .id(localizationManager.currentLanguage)
                }
                .padding(20)
                .background(.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Step 4: Dislikes
    private var step4Dislikes: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_was_möchtest_du_meiden.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_zutaten_die_du_nicht.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.6))
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        TextField(L.placeholder_newDislike.localized, text: $newDislikeText)
                            .id(localizationManager.currentLanguage)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                        
                        Button {
                            let trimmed = newDislikeText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15)) {
                                    dislikes.append(trimmed)
                                    newDislikeText = ""
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                    }
                    
                    if !dislikes.isEmpty {
                        FlowLayout(items: dislikes) { item in
                            dislikeChip(item)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .id(localizationManager.currentLanguage) // Force re-render on language change
                    } else {
                        Text(L.onboarding_keine_abneigungen_super_flexibel.localized)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.4))
                            .italic()
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if currentStep < 4 {
                Button {
                    // For language selection step, ensure language is selected
                    if currentStep == 0 && selectedLanguage.isEmpty {
                        // Can't proceed without selecting a language
                        return
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Button animation
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        buttonScale = 0.95
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                            buttonScale = 1.0
                            currentStep += 1
                        }
                        
                        // Trigger success animation with slight delay for smoother transition
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                showSuccessAnimation = true
                            }
                        }
                        
                        // Reset success animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSuccessAnimation = false
                            }
                        }
                    }
                } label: {
                    Text(L.next.localized)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.4), radius: 10, y: 4)
                        .id(localizationManager.currentLanguage)
                }
                .scaleEffect(buttonScale)
                .accessibilityLabel(L.next.localized)
                .accessibilityHint("Geht zum nächsten Schritt")
                .disabled(currentStep == 0 && selectedLanguage.isEmpty)
            } else {
                Button {
                    // Haptic feedback - success
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // Button animation
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        buttonScale = 0.95
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                            buttonScale = 1.0
                        }
                    }
                    
                    Task { await completeOnboarding() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(L.done.localized)
                                .font(.system(size: 17, weight: .semibold))
                                .id(localizationManager.currentLanguage)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(color: Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.4), radius: 10, y: 4)
                }
                .scaleEffect(buttonScale)
                .accessibilityLabel(isSaving ? L.loading.localized : L.done.localized)
                .accessibilityHint("Schließt das Onboarding ab und speichert die Einstellungen")
                .disabled(isSaving)
            }
            
            if currentStep > 0 {
                Button {
                    // Light haptic feedback for back button
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                        currentStep -= 1
                    }
                } label: {
                    Text(L.onboarding_zurück.localized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .id(localizationManager.currentLanguage)
                }
                .accessibilityLabel(L.onboarding_zurück.localized)
                .accessibilityHint("Geht zum vorherigen Schritt")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Helper Views
    private func allergyChip(_ item: String) -> some View {
        HStack(spacing: 6) {
            Text(item)
                .font(.system(size: 15, weight: .medium))
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    allergies.removeAll { $0 == item }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.4))
            }
            .accessibilityLabel("\(item) entfernen")
            .accessibilityHint("Entfernt diese Allergie aus der Liste")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
    
    private func dislikeChip(_ item: String) -> some View {
        HStack(spacing: 6) {
            Text(item)
                .font(.system(size: 15, weight: .medium))
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            dislikes.removeAll { $0 == item }
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.4))
                    }
                    .accessibilityLabel("\(item) entfernen")
                    .accessibilityHint("Entfernt diese Abneigung aus der Liste")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
    
    private func tastePreferenceToggle(key: String) -> some View {
        Button {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15)) {
                tastePreferences[key]?.toggle()
            }
        } label: {
            HStack {
                Text(key.capitalized)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(tastePreferences[key] == true ? 
                              LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 50, height: 30)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: tastePreferences[key] == true ? 10 : -10)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                }
            }
            .padding(12)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Actions
    private func completeOnboarding() async {
        isSaving = true
        
        // Save to AppState and UserDefaults
        var dietary = app.dietary
        dietary.allergies = allergies
        dietary.diets = selectedDiets
        dietary.dislikes = dislikes
        app.dietary = dietary
        
        // Prepare taste preferences dictionary for Supabase sync
        // Use English keys as expected by Supabase schema
        var tastePrefsDict: [String: Any] = ["spicy_level": spicyLevel]
        // Map localized keys to English keys for Supabase
        tastePrefsDict["sweet"] = tastePreferences[L.taste_sweet.localized] ?? false
        tastePrefsDict["sour"] = tastePreferences[L.taste_sour.localized] ?? false
        tastePrefsDict["bitter"] = tastePreferences[L.taste_bitter.localized] ?? false
        tastePrefsDict["umami"] = tastePreferences[L.taste_umami.localized] ?? false
        
        // Save to UserDefaults
        if let data = try? JSONSerialization.data(withJSONObject: tastePrefsDict) {
            UserDefaults.standard.set(data, forKey: "taste_preferences")
        }
        
        // Mark onboarding as completed FOR THIS USER
        if let userId = KeychainManager.get(key: "user_id") {
            let key = "onboarding_completed_\(userId)"
            UserDefaults.standard.set(true, forKey: key)
        }
        
        // Save to Supabase
        do {
            try await app.savePreferencesToSupabase(
                allergies: allergies,
                dietaryTypes: selectedDiets,
                tastePreferences: tastePrefsDict,
                dislikes: dislikes,
                notes: dietary.notes,
                onboardingCompleted: true
            )
        } catch {
            Logger.error("Failed to save onboarding preferences to Supabase", error: error, category: .data)
            // Continue anyway - data is saved locally
        }
        
        isSaving = false
        dismiss()
    }
}

// MARK: - FlowLayout (reused from DietarySettingsView)
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

// MARK: - WrapDietChips
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
        .id(options) // Force re-render when options change (language change)
    }
    
    private func chip(_ text: String) -> some View {
        let isOn = selection.contains(text)
        return Text(text)
            .font(.system(size: 15, weight: .medium))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(
                Group {
                    if isOn {
                        LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        Color.white
                    }
                }
            )
            .foregroundStyle(isOn ? .white : .black)
            .clipShape(Capsule())
            .shadow(color: isOn ? Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3) : .black.opacity(0.08), radius: isOn ? 8 : 4, y: 2)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15)) {
                    if isOn { selection.remove(text) } else { selection.insert(text) }
                }
            }
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

// MARK: - LanguageOption View
private struct LanguageOption: View {
    let languageCode: String
    let languageName: String
    let isSelected: Bool
    let systemLanguage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Flag emoji based on language code
                Text(getFlagEmoji(for: languageCode))
                    .font(.system(size: 32))
                    .accessibilityHidden(true)
                
                Text(languageName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.black.opacity(0.3))
                }
            }
            .padding(16)
            .background(isSelected ? 
                       LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.1), Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                       LinearGradient(colors: [Color.white], startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? 
                           LinearGradient(colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                           LinearGradient(colors: [Color.black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                           lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 8 : 4, y: 2)
        }
        .accessibilityLabel(languageName)
        .accessibilityHint(isSelected ? "Aktuell ausgewählt" : "Wählt \(languageName) als Sprache")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .buttonStyle(.plain)
    }
    
    private func getFlagEmoji(for code: String) -> String {
        let flags: [String: String] = [
            "de": "🇩🇪",
            "en": "🇬🇧",
            "fr": "🇫🇷",
            "es": "🇪🇸",
            "it": "🇮🇹"
        ]
        return flags[code] ?? "🌐"
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
