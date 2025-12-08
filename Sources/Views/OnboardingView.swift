import SwiftUI
import Foundation
import AVFoundation
import AudioToolbox

struct OnboardingView: View {
    // Keep @ObservedObject but prevent view recreation by not using .id() modifiers
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    
    // Track view instance for debugging
    private let viewId = UUID()
    
    init() {
        let id = UUID()
        Logger.debug("[OnboardingView] 🆕 VIEW CREATED with ID: \(id)", category: .ui)
    }
    
    @State private var currentStep: Int = {
        // Try to restore from UserDefaults, otherwise start with welcome screen
        // Use object(forKey:) to check if key exists (integer(forKey:) returns 0 if not set, which is ambiguous)
        let saved: Int
        if let savedValue = UserDefaults.standard.object(forKey: "onboarding_current_step") as? Int {
            saved = savedValue
        } else {
            saved = -999 // Special value meaning "not set"
        }
        let initialValue = (saved != -999) ? saved : -1
        Logger.debug("[OnboardingView] INIT: currentStep @State initialized to \(initialValue) (saved from UserDefaults: \(saved == -999 ? "not set" : String(saved)))", category: .ui)
        return initialValue
    }()
    @State private var buttonScale: CGFloat = 1.0
    @State private var isLanguageChanging = false // Flag to prevent TabView from changing currentStep during language change
    @State private var username: String = "" // Username entered during onboarding
    
    // Helper function to update currentStep and persist it
    private func updateCurrentStep(_ newStep: Int) {
        // Don't allow changes during language change unless explicitly restoring
        if isLanguageChanging && newStep != currentStep {
            Logger.debug("[OnboardingView] updateCurrentStep: BLOCKED during language change (\(currentStep) -> \(newStep))", category: .ui)
            return
        }
        
        let oldStep = currentStep
        Logger.debug("[OnboardingView] updateCurrentStep: \(oldStep) -> \(newStep)", category: .ui)
        currentStep = newStep
        UserDefaults.standard.set(newStep, forKey: "onboarding_current_step")
        Logger.debug("[OnboardingView] updateCurrentStep: Saved to UserDefaults: \(newStep)", category: .ui)
    }
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
    @State private var isSavingName = false
    
    // MARK: - Save Username to Database
    private func saveUsernameToDatabase(_ name: String) async {
        guard !isSavingName else { return }
        guard let accessToken = app.accessToken else {
            Logger.debug("[OnboardingView] Cannot save username: No access token available", category: .data)
            return
        }
        
        isSavingName = true
        
        do {
            try await app.saveProfile(fullName: name, email: nil)
            Logger.debug("[OnboardingView] ✅ Username '\(name)' saved successfully to database", category: .data)
        } catch {
            Logger.error("[OnboardingView] ❌ Failed to save username '\(name)': \(error.localizedDescription)", category: .data)
            #if DEBUG
            print("[OnboardingView] Error saving username: \(error)")
            #endif
        }
        
        isSavingName = false
    }
    
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
        let _ = Logger.debug("[OnboardingView] body computed (viewId: \(viewId)) - currentStep: \(currentStep)", category: .ui)
        return ZStack {
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
                // Progress indicator at top - only show for steps >= 0
                if currentStep >= 0 {
                    progressBar
                        .padding(.top, 20)
                    
                    // Penguin illustration below progress bar - only show for steps >= 0, but NOT for step 2 (greeting)
                    if currentStep != 2 {
                        if let uiImage = UIImage(named: "penguin-onboarding") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .padding(.top, 60)
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "list.clipboard")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.3))
                                .padding(.top, 60)
                                .accessibilityHidden(true)
                        }
                    }
                }
                
                // Content
                TabView(selection: $currentStep) {
                    stepWelcome.tag(-1)
                    step0LanguageSelection.tag(0)
                    step1Username.tag(1)
                    step2Greeting.tag(2)
                    step3Allergies.tag(3)
                    step4DietaryTypes.tag(4)
                    step5Preferences.tag(5)
                    step6Dislikes.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentStep)
                // CRITICAL: Don't add .id() modifier here - it causes the entire TabView to reset
                // and currentStep to be reset to -1 when language changes
                .onChange(of: currentStep) { oldValue, newValue in
                    if isLanguageChanging {
                        Logger.debug("[OnboardingView] ⚠️ BLOCKED: TabView tried to change currentStep from \(oldValue) to \(newValue) during language change!", category: .ui)
                        // Restore the saved step from UserDefaults
                        let savedStep: Int
                        if let savedValue = UserDefaults.standard.object(forKey: "onboarding_current_step") as? Int {
                            savedStep = savedValue
                        } else {
                            savedStep = -999
                        }
                        if savedStep != -999 && newValue != savedStep {
                            Logger.debug("[OnboardingView] Restoring currentStep to saved value: \(savedStep)", category: .ui)
                            DispatchQueue.main.async {
                                currentStep = savedStep
                            }
                        }
                    } else {
                        Logger.debug("[OnboardingView] TabView selection changed: \(oldValue) -> \(newValue) (allowed) - Syncing to UserDefaults", category: .ui)
                        // CRITICAL: Always sync to UserDefaults when user swipes or navigates
                        UserDefaults.standard.set(newValue, forKey: "onboarding_current_step")
                        UserDefaults.standard.synchronize()
                        Logger.debug("[OnboardingView] Synced currentStep \(newValue) to UserDefaults", category: .ui)
                    }
                }
                
                // Navigation buttons
                navigationButtons
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            Logger.debug("[OnboardingView] onAppear called - currentStep: \(currentStep)", category: .ui)
            // CRITICAL: Always restore currentStep from UserDefaults if view was recreated
            // This prevents reset to welcome screen when language changes
            let savedStep: Int
            if let savedValue = UserDefaults.standard.object(forKey: "onboarding_current_step") as? Int {
                savedStep = savedValue
            } else {
                savedStep = -999 // Not set
            }
            Logger.debug("[OnboardingView] onAppear - savedStep from UserDefaults: \(savedStep == -999 ? "not set" : String(savedStep))", category: .ui)
            
            if savedStep != -999 {
                // We have a saved step, restore it
                Logger.debug("[OnboardingView] onAppear - Found saved step: \(savedStep), currentStep: \(currentStep)", category: .ui)
                if currentStep != savedStep {
                    Logger.debug("[OnboardingView] onAppear - RESTORING currentStep from \(currentStep) to \(savedStep)", category: .ui)
                    currentStep = savedStep
                }
            } else if currentStep == -1 {
                // First appearance, save initial state
                Logger.debug("[OnboardingView] onAppear - First appearance, saving initial state -1", category: .ui)
                updateCurrentStep(-1)
            }
            
            // Initialize selectedLanguage with current language (system language) if not already set
            if selectedLanguage.isEmpty {
                selectedLanguage = localizationManager.currentLanguage
                Logger.debug("[OnboardingView] onAppear - Initialized selectedLanguage: \(selectedLanguage)", category: .ui)
            }
            initializeTastePreferences()
        }
        .onChange(of: localizationManager.currentLanguage) { oldLanguage, newLanguage in
            Logger.debug("[OnboardingView] onChange(language): \(oldLanguage) -> \(newLanguage)", category: .ui)
            Logger.debug("[OnboardingView] onChange(language) - currentStep BEFORE: \(currentStep)", category: .ui)
            
            // CRITICAL: Set flag to prevent TabView from changing currentStep
            isLanguageChanging = true
            
            // CRITICAL: Read the CORRECT step from UserDefaults (not currentStep, which might be wrong if view was recreated)
            let savedInDefaults: Int
            if let savedValue = UserDefaults.standard.object(forKey: "onboarding_current_step") as? Int {
                savedInDefaults = savedValue
            } else {
                savedInDefaults = -999 // Not set
            }
            // Also check currentStep - use the one that's more likely correct
            let currentStepValue = currentStep
            // Use UserDefaults value if it exists, otherwise use currentStep if it's valid
            let savedStep: Int
            if savedInDefaults != -999 {
                // UserDefaults has a value (including 0), use it as source of truth
                savedStep = savedInDefaults
            } else if currentStepValue >= -1 && currentStepValue <= 4 {
                // UserDefaults doesn't have a value, but currentStep is valid, use it
                savedStep = currentStepValue
                // Also save it
                UserDefaults.standard.set(savedStep, forKey: "onboarding_current_step")
                UserDefaults.standard.synchronize()
            } else {
                // Both are invalid, default to 0 (language selection)
                savedStep = 0
                UserDefaults.standard.set(0, forKey: "onboarding_current_step")
                UserDefaults.standard.synchronize()
            }
            
            Logger.debug("[OnboardingView] onChange(language) - savedStep (final): \(savedStep), savedInDefaults: \(savedInDefaults == -999 ? "not set" : String(savedInDefaults)), currentStepValue: \(currentStepValue)", category: .ui)
            
            // Ensure UserDefaults is up to date IMMEDIATELY with the correct value
            UserDefaults.standard.set(savedStep, forKey: "onboarding_current_step")
            UserDefaults.standard.synchronize() // Force immediate write
            
            // Re-initialize taste preferences when language changes
            initializeTastePreferences()
            // Reset selected diets when language changes (keys are localized)
            selectedDiets = []
            
            Logger.debug("[OnboardingView] onChange(language) - currentStep AFTER operations: \(currentStep)", category: .ui)
            
            // CRITICAL: Force restore currentStep immediately (bypassing the flag check)
            if currentStep != savedStep {
                Logger.debug("[OnboardingView] onChange(language) - FORCE RESTORING currentStep from \(currentStep) to \(savedStep) (immediate)", category: .ui)
                currentStep = savedStep
                UserDefaults.standard.set(savedStep, forKey: "onboarding_current_step")
                UserDefaults.standard.synchronize()
            } else {
                Logger.debug("[OnboardingView] onChange(language) - currentStep already correct: \(currentStep)", category: .ui)
            }
            
            // Also restore after a tiny delay as backup (in case view re-renders)
            DispatchQueue.main.async {
                let currentStepAfterDelay = currentStep
                Logger.debug("[OnboardingView] onChange(language) - After delay, currentStep: \(currentStepAfterDelay), savedStep: \(savedStep)", category: .ui)
                if currentStepAfterDelay != savedStep {
                    Logger.debug("[OnboardingView] onChange(language) - FORCE RESTORING currentStep from \(currentStepAfterDelay) to \(savedStep) (delayed)", category: .ui)
                    currentStep = savedStep
                    UserDefaults.standard.set(savedStep, forKey: "onboarding_current_step")
                    UserDefaults.standard.synchronize()
                }
                
                // Clear the flag after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLanguageChanging = false
                    Logger.debug("[OnboardingView] onChange(language) - Language change flag cleared", category: .ui)
                }
            }
        }
    }
    
    // MARK: - Step -1: Welcome Screen (Duolingo Style)
    private var stepWelcome: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // Waving Penguin (from Sign-Up Screen)
                WavingPenguinView()
                    .frame(height: 200)
                    .padding(.horizontal, 40)
                
                // Welcome Title
                VStack(spacing: 16) {
                    Text(L.welcome.localized)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .id(localizationManager.currentLanguage)
                    
                    Text(L.welcomeMessage.localized)
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 40)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    // MARK: - Waving Penguin View (from Sign-Up Screen)
    private struct WavingPenguinView: View {
        @State private var isFloating = false
        
        var body: some View {
            Group {
                // Penguin illustration with subtle floating animation (only upward)
                if let bundlePath = Bundle.main.path(forResource: "penguin-auth", ofType: "png", inDirectory: "Assets.xcassets/penguin-auth.imageset"),
                   let uiImage = UIImage(contentsOfFile: bundlePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                        .offset(y: isFloating ? -6 : 0)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isFloating)
                        .accessibilityHidden(true)
                } else if let uiImage = UIImage(named: "penguin-auth") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                        .offset(y: isFloating ? -6 : 0)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isFloating)
                        .accessibilityHidden(true)
                } else {
                    // Fallback: Penguin emoji
                    Text("🐧")
                        .font(.system(size: 120))
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                        .offset(y: isFloating ? -6 : 0)
                        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isFloating)
                }
            }
            .onAppear {
                isFloating = true
            }
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<7) { index in
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
                        .foregroundColor(.white)
                        .id(localizationManager.currentLanguage) // Force re-render on language change
                    Text(getSystemLocalizedSubtitle(systemLang: currentLang))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
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
                            // Light haptic only (no sound for selections)
                            OnboardingFeedback.playHaptic(style: .light)
                            
                            Logger.debug("[OnboardingView] Language selected: \(langCode), currentStep BEFORE: \(currentStep)", category: .ui)
                            let stepBeforeLanguageChange = currentStep
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15)) {
                                selectedLanguage = langCode
                                // Set language immediately when selected
                                localizationManager.setLanguage(langCode)
                            }
                            
                            // Check if currentStep changed after language change
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                Logger.debug("[OnboardingView] Language changed to \(langCode) - currentStep AFTER: \(currentStep), was: \(stepBeforeLanguageChange)", category: .ui)
                                let savedInDefaults: Int
                                if let savedValue = UserDefaults.standard.object(forKey: "onboarding_current_step") as? Int {
                                    savedInDefaults = savedValue
                                } else {
                                    savedInDefaults = -999
                                }
                                Logger.debug("[OnboardingView] Language changed - savedInDefaults: \(savedInDefaults == -999 ? "not set" : String(savedInDefaults))", category: .ui)
                                
                                if currentStep != stepBeforeLanguageChange {
                                    Logger.debug("[OnboardingView] ⚠️ BUG DETECTED: currentStep changed from \(stepBeforeLanguageChange) to \(currentStep) after language change! FORCE RESTORING...", category: .ui)
                                    // Force restore the step (bypassing the flag)
                                    currentStep = stepBeforeLanguageChange
                                    UserDefaults.standard.set(stepBeforeLanguageChange, forKey: "onboarding_current_step")
                                    UserDefaults.standard.synchronize()
                                }
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.95),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
    
    // MARK: - Step 1: Username Input
    private var step1Username: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_username_title.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .id(localizationManager.currentLanguage)
                        .opacity(currentStep == 1 ? 1 : 0)
                        .offset(y: currentStep == 1 ? 0 : -10)
                        .animation(.easeOut(duration: 0.3), value: currentStep)
                    
                    Text(L.onboarding_username_subtitle.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .id(localizationManager.currentLanguage)
                        .opacity(currentStep == 1 ? 1 : 0)
                        .offset(y: currentStep == 1 ? 0 : -10)
                        .animation(.easeOut(duration: 0.3).delay(0.05), value: currentStep)
                }
                .padding(.top, 20)
                
                // Username Input Field
                VStack(alignment: .leading, spacing: 12) {
                    Text(L.onboarding_username_label.localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .id(localizationManager.currentLanguage)
                    
                    TextField(L.onboarding_username_placeholder.localized, text: $username)
                        .font(.system(size: 17))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 24)
                .opacity(currentStep == 1 ? 1 : 0)
                .scaleEffect(currentStep == 1 ? 1 : 0.95)
                .animation(.easeOut(duration: 0.3).delay(0.1), value: currentStep)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .opacity(currentStep == 1 ? 1 : 0)
        .id("username-\(currentStep)") // Force re-render for smooth transition
    }
    
    // MARK: - Step 2: Greeting with Username
    private var step2Greeting: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Waving Penguin (smaller for better fit)
            WavingPenguinView()
                .frame(height: 150)
                .padding(.horizontal, 40)
                .opacity(currentStep == 2 ? 1 : 0)
                .scaleEffect(currentStep == 2 ? 1 : 0.8)
                .offset(y: currentStep == 2 ? 0 : 30)
                .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: currentStep)
            
            // Greeting Message
            VStack(spacing: 12) {
                Text(L.onboarding_greeting_title.localized.replacingOccurrences(of: "{username}", with: username.isEmpty ? L.onboarding_greeting_fallback.localized : username))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .id(localizationManager.currentLanguage)
                    .opacity(currentStep == 2 ? 1 : 0)
                    .offset(y: currentStep == 2 ? 0 : 30)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3), value: currentStep)
                
                Text(L.onboarding_greeting_message.localized)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 40)
                    .id(localizationManager.currentLanguage)
                    .opacity(currentStep == 2 ? 1 : 0)
                    .offset(y: currentStep == 2 ? 0 : 30)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.4), value: currentStep)
            }
            .padding(.top, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(currentStep == 2 ? 1 : 0)
        .id("greeting-\(currentStep)") // Force re-render for smooth transition
    }
    
    // MARK: - Step 3: Allergies
    private var step3Allergies: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_allergien_unverträglichkeiten.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_damit_wir_deine_rezepte.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
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
                                // Light haptic only (no sound for adding items)
                                OnboardingFeedback.playHaptic(style: .light)
                                
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
                            .foregroundColor(.white.opacity(0.7))
                            .italic()
                            .padding(.top, 8)
                            .id(localizationManager.currentLanguage)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.95),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Step 4: Dietary Types
    private var step4DietaryTypes: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_ernährungsweise.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_wähle_deine_ernährungspräferenzen_a.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 20)
                
                DietaryPreferencesList(selection: $selectedDiets)
                    .id(localizationManager.currentLanguage)
                
                if selectedDiets.isEmpty {
                    Text(L.onboarding_keine_spezielle_ernährungsweise_kei.localized)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                        .padding(.top, 8)
                        .id(localizationManager.currentLanguage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.95),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Step 5: Taste Preferences
    private var step5Preferences: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_geschmackspräferenzen.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_howSpicyDoYouLikeIt.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .id(localizationManager.currentLanguage)
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // Current selection display
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach(0..<4) { index in
                                Image(systemName: index <= Int(spicyLevel) ? "flame.fill" : "flame")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(
                                        index <= Int(spicyLevel) ?
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.95, green: 0.5, blue: 0.3),
                                                Color(red: 0.85, green: 0.4, blue: 0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(index <= Int(spicyLevel) ? 1.0 : 0.7)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: spicyLevel)
                            }
                        }
                        Text(spicyLabels[Int(spicyLevel)])
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
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
                        .foregroundColor(.white)
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
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.95),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Step 6: Dislikes
    private var step6Dislikes: some View {
        ScrollView {
            let _ = localizationManager.currentLanguage // Force recomputation
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.onboarding_was_möchtest_du_meiden.localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .id(localizationManager.currentLanguage)
                    Text(L.onboarding_zutaten_die_du_nicht.localized)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
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
                                // Light haptic only (no sound for adding items)
                                OnboardingFeedback.playHaptic(style: .light)
                                
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
                            .foregroundColor(.white.opacity(0.7))
                            .italic()
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.95),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if currentStep == -1 {
                // Welcome screen - show "Los geht's!" button
                Button {
                    // Rewarding sound and haptic for starting
                    OnboardingFeedback.playStartSound()
                    OnboardingFeedback.playHaptic(style: .medium)
                    
                    // Button animation
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        buttonScale = 0.95
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        Logger.debug("[OnboardingView] Welcome button - Moving from step -1 to 0", category: .ui)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                            buttonScale = 1.0
                            updateCurrentStep(0)
                        }
                    }
                } label: {
                    Text(L.getStarted.localized)
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
                .accessibilityLabel(L.getStarted.localized)
                .accessibilityHint("Startet das Onboarding")
            } else if currentStep < 6 {
                Button {
                    // For language selection step, ensure language is selected
                    if (currentStep == 0 && selectedLanguage.isEmpty) || (currentStep == 1 && username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        // Can't proceed without selecting a language
                        return
                    }
                    
                    // Light haptic feedback only (no sound on button press)
                    OnboardingFeedback.playHaptic(style: .light)
                    
                    // Play sound immediately when button is pressed (before step change)
                    OnboardingFeedback.playStepCompleteSound()
                    
                    // Button animation
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        buttonScale = 0.95
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        let nextStep = currentStep + 1
                        Logger.debug("[OnboardingView] Next button - Moving from step \(currentStep) to \(nextStep)", category: .ui)
                        
                        // Save username to database when moving from step 1 (username input) to step 2 (greeting)
                        if currentStep == 1 && nextStep == 2 {
                            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedUsername.isEmpty {
                                Task {
                                    await saveUsernameToDatabase(trimmedUsername)
                                }
                            }
                        }
                        
                        // Special animation for transition from username to greeting
                        let animation: Animation
                        if currentStep == 1 && nextStep == 2 {
                            // Smooth fade transition for username -> greeting
                            animation = .easeInOut(duration: 0.5)
                        } else {
                            animation = .spring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.3)
                        }
                        
                        withAnimation(animation) {
                            buttonScale = 1.0
                            updateCurrentStep(nextStep)
                        }
                        
                        // Additional haptic feedback when step transition completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            OnboardingFeedback.playHaptic(style: .medium)
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
                .disabled((currentStep == 0 && selectedLanguage.isEmpty) || (currentStep == 1 && username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            } else {
                Button {
                    // Final level completion celebration
                    OnboardingFeedback.playFinalCompleteSound()
                    OnboardingFeedback.playHaptic(style: .medium, notificationType: .success)
                    
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
            
            if currentStep > -1 {
                Button {
                    // Light haptic only for back button (no sound)
                    OnboardingFeedback.playHaptic(style: .light)
                    
                    let prevStep = currentStep - 1
                    Logger.debug("[OnboardingView] Back button - Moving from step \(currentStep) to \(prevStep)", category: .ui)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                        updateCurrentStep(prevStep)
                    }
                } label: {
                    Text(L.onboarding_zurück.localized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
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
            // Light haptic only (no sound for toggles)
            OnboardingFeedback.playHaptic(style: .light)
            
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
        
        // Clear saved currentStep so next onboarding starts fresh
        UserDefaults.standard.removeObject(forKey: "onboarding_current_step")
        
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

// MARK: - Dietary Preferences List
private struct DietaryPreferencesList: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var selection: Set<String>
    
    private var dietOptions: [(key: String, icon: String)] {
        let _ = localizationManager.currentLanguage // Force recomputation when language changes
        return [
            (L.vegetarian.localized, "leaf.fill"),
            (L.vegan.localized, "carrot.fill"),
            (L.pescetarian.localized, "fish.fill"),
            (L.lowCarb.localized, "arrow.down.circle.fill"),
            (L.highProtein.localized, "dumbbell.fill"),
            (L.glutenFree.localized, "checkmark.shield.fill"),
            (L.lactoseFree.localized, "xmark.circle.fill"),
            (L.halal.localized, "moon.stars.fill"),
            (L.kosher.localized, "star.fill")
        ]
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(dietOptions, id: \.key) { option in
                DietaryPreferenceRow(
                    title: option.key,
                    icon: option.icon,
                    isSelected: selection.contains(option.key),
                    onToggle: {
                        // Simple toggle - if currently selected, remove it; if not, add it
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.15)) {
                            if selection.contains(option.key) {
                                selection.remove(option.key)
                            } else {
                                selection.insert(option.key)
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Dietary Preference Row
private struct DietaryPreferenceRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            // Light haptic only (no sound for selections)
            OnboardingFeedback.playHaptic(style: .light)
            onToggle()
        }) {
            HStack(spacing: 16) {
                // Icon - weiß wenn ausgewählt, orange wenn nicht
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(red: 0.95, green: 0.5, blue: 0.3))
                    .frame(width: 32, height: 32)
                
                // Title - weiß wenn ausgewählt, schwarz wenn nicht
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Checkmark when selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        // Orange Gradient Hintergrund wenn ausgewählt
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        // Grauer Hintergrund wenn nicht ausgewählt
                        Color(UIColor.systemGray6)
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: isSelected ? Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.4) : .black.opacity(0.08),
                radius: isSelected ? 8 : 4,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WrapDietChips (kept for backward compatibility if needed)
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

// MARK: - Onboarding Feedback Helper
private struct OnboardingFeedback {
    // Game-like success sounds for level completion feeling
    // These sounds feel like completing a level in a video game
    private static let startSoundID: SystemSoundID = 1056  // Anticipate - rewarding start sound
    private static let levelCompleteSoundID: SystemSoundID = 1056  // Anticipate - more rewarding than Peek
    private static let finalLevelCompleteSoundID: SystemSoundID = 1053  // MailSent - celebration for final step
    
    /// Plays a rewarding sound when starting onboarding
    static func playStartSound() {
        // Play sound on main thread to ensure it's not blocked
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(startSoundID)
        }
    }
    
    /// Plays a game-like success sound when completing a step (like level completion)
    static func playStepCompleteSound() {
        // Play sound on main thread immediately to ensure it's not blocked
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(levelCompleteSoundID)
        }
    }
    
    /// Plays a celebration sound for final completion
    static func playFinalCompleteSound() {
        // Play sound on main thread to ensure it's not blocked
        DispatchQueue.main.async {
            AudioServicesPlaySystemSound(finalLevelCompleteSoundID)
        }
    }
    
    /// Plays haptic feedback with optional notification type
    static func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle, notificationType: UINotificationFeedbackGenerator.FeedbackType? = nil) {
        if let notificationType = notificationType {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(notificationType)
        } else {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
