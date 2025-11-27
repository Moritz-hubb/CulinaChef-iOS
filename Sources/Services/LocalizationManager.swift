import Foundation
import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String {
        didSet {
            // Don't save during initialization - we'll handle that separately
            if !_isInitializing {
                UserDefaults.standard.set(currentLanguage, forKey: "app_language")
                // Mark that user has explicitly set a language preference (unless we're resetting)
                if !_isResettingToDevice {
                    UserDefaults.standard.set(true, forKey: "app_language_explicitly_set")
                }
            }
            loadTranslations()
            // Trigger UI update via NotificationCenter
            NotificationCenter.default.post(name: .languageChanged, object: nil)
            // Force objectWillChange after a small delay to ensure translations are loaded
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    private var _isResettingToDevice = false
    private var _isInitializing = false
    
    private var translations: [String: String] = [:] {
        didSet {
            // Trigger UI update when translations change
            objectWillChange.send()
        }
    }
    private let fallbackLanguage = "en"
    
    let availableLanguages: [String: String] = [
        "de": "Deutsch",
        "en": "English",
        "fr": "Français",
        "it": "Italiano",
        "es": "Español"
    ]
    
    private init() {
        // Mark that we're initializing to prevent saving during init
        _isInitializing = true
        
        // Get device language - detect using the same logic as detectDeviceLanguage()
        // This will return a supported language or "en" as fallback
        var deviceLang: String? = nil
        
        // Method 1: Try Locale.preferredLanguages first (most reliable)
        // Check ALL preferred languages, not just the first one
        for preferredLang in Locale.preferredLanguages {
            // Extract language code from formats like "en-US", "en_US", "en"
            let components = preferredLang.components(separatedBy: CharacterSet(charactersIn: "-_"))
            if let langCode = components.first, langCode.count == 2 {
                let lowercased = langCode.lowercased()
                // If this language is in our available languages, use it
                if availableLanguages.keys.contains(lowercased) {
                    deviceLang = lowercased
                    break // Found a supported language, stop searching
                }
            }
        }
        
        // Method 2: Fallback to Locale.current.language.languageCode
        // Only use this if we didn't find a supported language in preferredLanguages
        if deviceLang == nil {
            if let langCode = Locale.current.language.languageCode?.identifier {
                let lowercased = langCode.lowercased()
                if lowercased.count == 2 && availableLanguages.keys.contains(lowercased) {
                    deviceLang = lowercased
                }
            }
        }
        
        // Method 3: Fallback to Locale.current.identifier
        // Only use this if we still haven't found a supported language
        if deviceLang == nil {
            let identifier = Locale.current.identifier
            let components = identifier.components(separatedBy: CharacterSet(charactersIn: "-_"))
            if let langCode = components.first, langCode.count == 2 {
                let lowercased = langCode.lowercased()
                if availableLanguages.keys.contains(lowercased) {
                    deviceLang = lowercased
                }
            }
        }
        
        // If no supported language was found, default to English
        let finalDeviceLang = deviceLang ?? fallbackLanguage
        if deviceLang == nil {
            #if DEBUG
            Logger.debug("[LocalizationManager] ⚠️ No supported language found in system preferences, defaulting to English", category: .data)
            #endif
        }
        
        #if DEBUG
        Logger.debug("[LocalizationManager] ========== INIT START ==========", category: .data)
        Logger.debug("[LocalizationManager] Detected device language: \(finalDeviceLang)", category: .data)
        Logger.debug("[LocalizationManager] Locale.current.language.languageCode: \(Locale.current.language.languageCode?.identifier ?? "nil")", category: .data)
        Logger.debug("[LocalizationManager] Locale.preferredLanguages: \(Locale.preferredLanguages)", category: .data)
        Logger.debug("[LocalizationManager] Locale.current.identifier: \(Locale.current.identifier)", category: .data)
        Logger.debug("[LocalizationManager] Available languages: \(availableLanguages.keys.sorted())", category: .data)
        Logger.debug("[LocalizationManager] UserDefaults before init:", category: .data)
        Logger.debug("[LocalizationManager]   app_language: \(UserDefaults.standard.string(forKey: "app_language") ?? "nil")", category: .data)
        Logger.debug("[LocalizationManager]   app_language_explicitly_set: \(UserDefaults.standard.bool(forKey: "app_language_explicitly_set"))", category: .data)
        #endif
        
        // Check if user is authenticated
        let isAuthenticated = KeychainManager.get(key: "access_token") != nil
        
        // Always check for explicit language preference first (regardless of auth state)
        // If user has explicitly set a language, use it
        let hasExplicitLanguage = UserDefaults.standard.bool(forKey: "app_language_explicitly_set")
        let savedLang = UserDefaults.standard.string(forKey: "app_language")
        
        #if DEBUG
        Logger.debug("[LocalizationManager] Checking saved language preference:", category: .data)
        Logger.debug("[LocalizationManager]   hasExplicitLanguage: \(hasExplicitLanguage)", category: .data)
        Logger.debug("[LocalizationManager]   savedLang: \(savedLang ?? "nil")", category: .data)
        Logger.debug("[LocalizationManager]   isAuthenticated: \(isAuthenticated)", category: .data)
        #endif
        
        // If not authenticated, always use device language (ignore saved preferences)
        let initialLang: String
        if !isAuthenticated {
            // Not authenticated - always use device language, ignore any saved preferences
            initialLang = finalDeviceLang
            // Clear any old saved language to ensure device language is always used
            UserDefaults.standard.removeObject(forKey: "app_language")
            UserDefaults.standard.set(false, forKey: "app_language_explicitly_set")
            #if DEBUG
            Logger.debug("[LocalizationManager] Not authenticated - using device language: \(finalDeviceLang)", category: .data)
            #endif
        } else {
            // User is authenticated - check if they have explicitly set a language preference
            if hasExplicitLanguage, let saved = savedLang, availableLanguages.keys.contains(saved) {
                // User has explicitly set a language, use it
                initialLang = saved
                // Save it properly
                UserDefaults.standard.set(initialLang, forKey: "app_language")
                #if DEBUG
                Logger.debug("[LocalizationManager] Authenticated with explicit language preference: \(saved)", category: .data)
                #endif
            } else {
                // No explicit preference - use device language
                initialLang = finalDeviceLang
                // Clear any old saved language to ensure device language is always used
                UserDefaults.standard.removeObject(forKey: "app_language")
                UserDefaults.standard.set(false, forKey: "app_language_explicitly_set")
                #if DEBUG
                Logger.debug("[LocalizationManager] Authenticated but no explicit preference - using device language: \(finalDeviceLang)", category: .data)
                #endif
            }
        }
        
        // Validate language exists, fallback to English if device language is not supported
        let validatedLang: String
        if availableLanguages.keys.contains(initialLang) {
            validatedLang = initialLang
        } else {
            // Device language is not supported - use English as fallback
            validatedLang = fallbackLanguage
            #if DEBUG
            Logger.debug("[LocalizationManager] ⚠️ Device language '\(initialLang)' is not supported, falling back to English", category: .data)
            #endif
        }
        
        #if DEBUG
        Logger.debug("[LocalizationManager] Initial language: \(initialLang), validated: \(validatedLang)", category: .data)
        Logger.debug("[LocalizationManager] Is authenticated: \(isAuthenticated)", category: .data)
        Logger.debug("[LocalizationManager] hasExplicitLanguage: \(UserDefaults.standard.bool(forKey: "app_language_explicitly_set"))", category: .data)
        Logger.debug("[LocalizationManager] savedLang: \(UserDefaults.standard.string(forKey: "app_language") ?? "nil")", category: .data)
        Logger.debug("[LocalizationManager] ========== INIT END ==========", category: .data)
        #endif
        
        // Set currentLanguage (won't save because _isInitializing is true)
        self.currentLanguage = validatedLang
        
        // Done initializing
        _isInitializing = false
        
        loadTranslations()
    }
    
    /// Check if user is authenticated and update language accordingly
    func updateLanguageForAuthState(isAuthenticated: Bool) {
        #if DEBUG
        Logger.debug("[LocalizationManager] updateLanguageForAuthState called: isAuthenticated=\(isAuthenticated), currentLanguage=\(currentLanguage)", category: .data)
        #endif
        
        // Only update if state actually changed
        if !isAuthenticated {
            // User logged out - reset to device language
            #if DEBUG
            Logger.debug("[LocalizationManager] User logged out - resetting to device language", category: .data)
            #endif
            resetToDeviceLanguage()
        } else {
            // User is authenticated - check if they have explicitly set a language preference
            let hasExplicitLanguage = UserDefaults.standard.bool(forKey: "app_language_explicitly_set")
            let savedLang = UserDefaults.standard.string(forKey: "app_language")
            
            #if DEBUG
            Logger.debug("[LocalizationManager] User authenticated - hasExplicitLanguage=\(hasExplicitLanguage), savedLang=\(savedLang ?? "nil")", category: .data)
            #endif
            
            if hasExplicitLanguage, let saved = savedLang, availableLanguages.keys.contains(saved) {
                // User has explicitly set a language preference - use it
                if currentLanguage != saved {
                    #if DEBUG
                    Logger.debug("[LocalizationManager] Switching to saved explicit language: \(saved)", category: .data)
                    #endif
                    _isInitializing = true
                    self.currentLanguage = saved
                    _isInitializing = false
                } else {
                    #if DEBUG
                    Logger.debug("[LocalizationManager] Already using explicit language: \(saved)", category: .data)
                    #endif
                }
            } else {
                // No explicit preference - keep current language (which should be system language)
                // Don't change the language when user authenticates - keep the system language
                // that was set before authentication
                #if DEBUG
                Logger.debug("[LocalizationManager] No explicit language preference - keeping current language: \(currentLanguage)", category: .data)
                #endif
                // Clear any old saved language to ensure we don't use stale preferences
                UserDefaults.standard.removeObject(forKey: "app_language")
                UserDefaults.standard.set(false, forKey: "app_language_explicitly_set")
            }
        }
    }
    
    /// Detect device language using the same method as init
    /// Returns a supported language code, or "en" as fallback if no supported language is found
    private func detectDeviceLanguage() -> String {
        var deviceLang: String? = nil
        
        // Method 1: Try Locale.preferredLanguages first (most reliable)
        // Check ALL preferred languages, not just the first one
        for preferredLang in Locale.preferredLanguages {
            // Extract language code from formats like "en-US", "en_US", "en"
            let components = preferredLang.components(separatedBy: CharacterSet(charactersIn: "-_"))
            if let langCode = components.first, langCode.count == 2 {
                let lowercased = langCode.lowercased()
                // If this language is in our available languages, use it
                if availableLanguages.keys.contains(lowercased) {
                    deviceLang = lowercased
                    break // Found a supported language, stop searching
                }
            }
        }
        
        // Method 2: Fallback to Locale.current.language.languageCode
        // Only use this if we didn't find a supported language in preferredLanguages
        if deviceLang == nil {
            if let langCode = Locale.current.language.languageCode?.identifier {
                let lowercased = langCode.lowercased()
                if lowercased.count == 2 && availableLanguages.keys.contains(lowercased) {
                    deviceLang = lowercased
                }
            }
        }
        
        // Method 3: Fallback to Locale.current.identifier
        // Only use this if we still haven't found a supported language
        if deviceLang == nil {
            let identifier = Locale.current.identifier
            let components = identifier.components(separatedBy: CharacterSet(charactersIn: "-_"))
            if let langCode = components.first, langCode.count == 2 {
                let lowercased = langCode.lowercased()
                if availableLanguages.keys.contains(lowercased) {
                    deviceLang = lowercased
                }
            }
        }
        
        // If no supported language was found, default to English
        let finalLang = deviceLang ?? fallbackLanguage
        if deviceLang == nil {
            #if DEBUG
            Logger.debug("[LocalizationManager] ⚠️ No supported language found in system preferences, defaulting to English", category: .data)
            #endif
        }
        return finalLang
    }
    
    /// Set language explicitly (e.g., from onboarding)
    func setLanguage(_ language: String) {
        guard availableLanguages.keys.contains(language) else { return }
        
        // Don't do anything if language is already set
        if currentLanguage == language {
            return
        }
        
        _isInitializing = true
        self.currentLanguage = language
        UserDefaults.standard.set(language, forKey: "app_language")
        UserDefaults.standard.set(true, forKey: "app_language_explicitly_set")
        _isInitializing = false
        
        // loadTranslations() is already called by currentLanguage.didSet, so we don't need to call it again
        // Just ensure notification is sent
        NotificationCenter.default.post(name: .languageChanged, object: nil)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    private func loadTranslations() {
        // Try multiple paths to find the JSON file
        var path: String?
        
        #if DEBUG
        Logger.debug("[LocalizationManager] loadTranslations() called for language: \(currentLanguage)", category: .data)
        Logger.debug("[LocalizationManager] Attempting to load translations for: \(currentLanguage)", category: .data)
        Logger.debug("[LocalizationManager] Bundle.main.resourcePath: \(Bundle.main.resourcePath ?? "nil")", category: .data)
        
        // List all JSON files in bundle
        if let resourcePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            if let files = try? fm.contentsOfDirectory(atPath: resourcePath) {
                let jsonFiles = files.filter { $0.hasSuffix(".json") }
                Logger.debug("[LocalizationManager] JSON files in bundle root: \(jsonFiles)", category: .data)
            }
        }
        #endif
        
        // Try 1: In Resources/Localization subdirectory
        path = Bundle.main.path(forResource: currentLanguage, ofType: "json", inDirectory: "Resources/Localization")
        #if DEBUG
        if path != nil { Logger.debug("[LocalizationManager] Found at: Resources/Localization/\(currentLanguage).json", category: .data) }
        #endif
        
        // Try 2: In Resources directory
        if path == nil {
            path = Bundle.main.path(forResource: currentLanguage, ofType: "json", inDirectory: "Resources")
            #if DEBUG
            if path != nil { Logger.debug("[LocalizationManager] Found at: Resources/\(currentLanguage).json", category: .data) }
            #endif
        }
        
        // Try 3: In root of bundle
        if path == nil {
            path = Bundle.main.path(forResource: currentLanguage, ofType: "json")
            #if DEBUG
            if path != nil { Logger.debug("[LocalizationManager] Found at: \(currentLanguage).json (root)", category: .data) }
            #endif
        }
        
        // Try 4: Direct search with resource name pattern
        if path == nil {
            if let resourcePath = Bundle.main.resourcePath {
                let possiblePath = "\(resourcePath)/\(currentLanguage).json"
                if FileManager.default.fileExists(atPath: possiblePath) {
                    path = possiblePath
                    #if DEBUG
                    Logger.debug("[LocalizationManager] Found at: \(possiblePath)", category: .data)
                    #endif
                }
            }
        }
        
        guard let validPath = path,
              let data = try? Data(contentsOf: URL(fileURLWithPath: validPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            #if DEBUG
            Logger.debug("[LocalizationManager] Failed to load translations for \(currentLanguage) in any location", category: .data)
            Logger.debug("[LocalizationManager] Searched paths:", category: .data)
            Logger.debug(" - Resources/Localization/\(currentLanguage).json", category: .data)
            Logger.debug(" - Resources/\(currentLanguage).json", category: .data)
            Logger.debug(" - \(currentLanguage).json", category: .data)
            if let resourcePath = Bundle.main.resourcePath {
                Logger.debug(" - \(resourcePath)/\(currentLanguage).json", category: .data)
            }
            #endif
            
            // Load fallback if current language failed and it's not already fallback
            if currentLanguage != fallbackLanguage {
                loadFallbackTranslations()
            }
            return
        }
        
        translations = json
        #if DEBUG
        Logger.debug("[LocalizationManager] ✅ Loaded \(translations.count) translations for \(currentLanguage) from: \(validPath)", category: .data)
        #endif
    }
    
    private func loadFallbackTranslations() {
        var fallbackPath: String?
        
        // Try multiple paths for fallback
        fallbackPath = Bundle.main.path(forResource: fallbackLanguage, ofType: "json", inDirectory: "Resources/Localization")
        
        if fallbackPath == nil {
            fallbackPath = Bundle.main.path(forResource: fallbackLanguage, ofType: "json", inDirectory: "Resources")
        }
        
        if fallbackPath == nil {
            fallbackPath = Bundle.main.path(forResource: fallbackLanguage, ofType: "json")
        }
        
        guard let validFallbackPath = fallbackPath,
              let fallbackData = try? Data(contentsOf: URL(fileURLWithPath: validFallbackPath)),
              let fallbackJson = try? JSONSerialization.jsonObject(with: fallbackData) as? [String: String] else {
            #if DEBUG
            Logger.debug("[LocalizationManager] Failed to load fallback translations for \(fallbackLanguage)", category: .data)
            #endif
            return
        }
        
        translations = fallbackJson
        #if DEBUG
        Logger.debug("[LocalizationManager] Loaded fallback translations (\(translations.count) keys) from: \(validFallbackPath)", category: .data)
        #endif
    }
    
    func string(forKey key: String) -> String {
        if let translation = translations[key] {
            return translation
        }
        
        // Log missing translation
        Logger.debug("[LocalizationManager] Missing translation: '\(key)' for language: \(currentLanguage)", category: .data)
        
        // Return key itself as fallback
        return key
    }
    
    /// Reset to device language and clear explicit preference
    func resetToDeviceLanguage() {
        // Get device language using the same method as init
        let deviceLang = detectDeviceLanguage()
        let validLang: String
        if availableLanguages.keys.contains(deviceLang) {
            validLang = deviceLang
        } else {
            // Device language is not supported - use English as fallback
            validLang = fallbackLanguage
            #if DEBUG
            Logger.debug("[LocalizationManager] ⚠️ Device language '\(deviceLang)' is not supported, falling back to English", category: .data)
            #endif
        }
        
        #if DEBUG
        Logger.debug("[LocalizationManager] resetToDeviceLanguage: detected=\(deviceLang), valid=\(validLang), current=\(currentLanguage)", category: .data)
        Logger.debug("[LocalizationManager] Locale.preferredLanguages: \(Locale.preferredLanguages)", category: .data)
        #endif
        
        // Don't do anything if already set to device language
        if currentLanguage == validLang {
            #if DEBUG
            Logger.debug("[LocalizationManager] Already set to device language, skipping reset", category: .data)
            #endif
            return
        }
        
        // Set flag to prevent marking as explicit
        _isResettingToDevice = true
        
        // Clear explicit preference flag and saved language
        UserDefaults.standard.set(false, forKey: "app_language_explicitly_set")
        UserDefaults.standard.removeObject(forKey: "app_language")
        
        #if DEBUG
        Logger.debug("[LocalizationManager] Resetting language from \(currentLanguage) to \(validLang)", category: .data)
        #endif
        
        // Set to device language
        self.currentLanguage = validLang
        
        // Reset flag
        _isResettingToDevice = false
    }
}

extension String {
    var localized: String {
        return LocalizationManager.shared.string(forKey: self)
    }
}

// MARK: - Reactive Localized Text View
struct LocalizedText: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let key: String
    
    var body: some View {
        Text(localizationManager.string(forKey: key))
    }
}

// MARK: - View Extension for Easy Localization
extension View {
    func localized(_ key: String) -> some View {
        LocalizedText(key: key)
    }
}

// Environment key for forcing view updates on language change
private struct LocalizationEnvironmentKey: EnvironmentKey {
    static let defaultValue: String = LocalizationManager.shared.currentLanguage
}

extension EnvironmentValues {
    var appLanguage: String {
        get { self[LocalizationEnvironmentKey.self] }
        set { self[LocalizationEnvironmentKey.self] = newValue }
    }
}

// String keys - centralized for easy management
enum L {
    // MARK: - Common
    static let done = "common.done"
    static let cancel = "common.cancel"
    static let save = "common.save"
    static let delete = "common.delete"
    static let edit = "common.edit"
    static let close = "common.close"
    static let yes = "common.yes"
    static let no = "common.no"
    static let ok = "common.ok"
    static let back = "common.back"
    static let next = "common.next"
    static let loading = "common.loading"
    static let error = "common.error"
    static let success = "common.success"
    static let search = "common.search"
    static let filter = "common.filter"
    static let share = "common.share"
    static let copy = "common.copy"
    static let copied = "common.copied"
    
    // MARK: - Recipe Sharing
    static let shareRecipeTitle = "share.recipeTitle"
    static let shareRecipeOriginal = "share.originalRecipe"
    static let shareRecipeImage = "share.image"
    static let shareRecipePhoto = "share.photo"
    static let shareRecipeCancel = "share.cancel"
    
    // MARK: - Authentication
    static let signIn = "auth.signIn"
    static let signUp = "auth.signUp"
    static let signOut = "auth.signOut"
    static let email = "auth.email"
    static let password = "auth.password"
    static let username = "auth.username"
    static let forgotPassword = "auth.forgotPassword"
    static let resetPasswordTitle = "auth.resetPasswordTitle"
    static let resetPasswordSubtitle = "auth.resetPasswordSubtitle"
    static let resetPasswordEmailSent = "auth.resetPasswordEmailSent"
    static let resetPasswordCheckEmail = "auth.resetPasswordCheckEmail"
    static let resetPasswordError = "auth.resetPasswordError"
    static let resetPasswordInvalidEmail = "auth.resetPasswordInvalidEmail"
    static let resetPasswordButton = "auth.resetPasswordButton"
    static let resetPasswordNewPasswordTitle = "auth.resetPasswordNewPasswordTitle"
    static let resetPasswordNewPasswordSubtitle = "auth.resetPasswordNewPasswordSubtitle"
    static let resetPasswordNewPassword = "auth.resetPasswordNewPassword"
    static let resetPasswordConfirmPassword = "auth.resetPasswordConfirmPassword"
    static let resetPasswordUpdateButton = "auth.resetPasswordUpdateButton"
    static let resetPasswordSuccess = "auth.resetPasswordSuccess"
    static let resetPasswordPasswordsDoNotMatch = "auth.resetPasswordPasswordsDoNotMatch"
    static let resetPasswordTooShort = "auth.resetPasswordTooShort"
    static let resetPasswordResendEmail = "auth.resetPasswordResendEmail"
    static let resetPasswordResendEmailSuccess = "auth.resetPasswordResendEmailSuccess"
    static let resetPasswordCheckStatus = "auth.resetPasswordCheckStatus"
    static let resetPasswordLinkClicked = "auth.resetPasswordLinkClicked"
    static let createAccount = "auth.createAccount"
    static let alreadyHaveAccount = "auth.alreadyHaveAccount"
    static let dontHaveAccount = "auth.dontHaveAccount"
    static let letsGetStarted = "auth.letsGetStarted"
    static let usernamePlaceholder = "auth.usernamePlaceholder"
    static let emailPlaceholder = "auth.emailPlaceholder"
    static let passwordPlaceholder = "auth.passwordPlaceholder"
    static let minCharacters = "auth.minCharacters"
    static let loginButton = "auth.loginButton"
    static let loginWithApple = "auth.loginWithApple"
    static let signUpWithApple = "auth.signUpWithApple"
    static let acceptTermsAndPrivacy = "auth.acceptTermsAndPrivacy"
    static let or = "auth.or"
    static let passwordPlaceholderDots = "auth.passwordPlaceholderDots"
    static let signUpButton = "auth.signUpButton"
    static let termsOfServiceShort = "auth.termsOfServiceShort"
    
    // MARK: - Settings
    static let settings = "settings.title"
    static let notifications = "settings.notifications"
    static let language = "settings.language"
    static let appearance = "settings.appearance"
    static let dietary = "settings.dietary"
    static let dietaryPreferences = "settings.dietaryPreferences"
    static let profile = "settings.profile"
    static let profileSettings = "settings.profileSettings"
    static let subscription = "settings.subscription"
    static let deleteAccount = "settings.deleteAccount"
    static let deleteAccountConfirm = "settings.deleteAccountConfirm"
    static let deleteAccountMessage = "settings.deleteAccountMessage"
    static let accountDeleted = "settings.accountDeleted"
    static let accountDeletedMessage = "settings.accountDeletedMessage"
    static let manageSubscription = "settings.manageSubscription"
    static let deleteNow = "settings.deleteNow"
    static let settings_about = "settings.about"
    static let settings_rateApp = "settings.rateApp"
    static let settings_rateAppHint = "settings.rateAppHint"
    static let settings_privacy = "settings.privacy"
    static let settings_openai_consent = "settings.openai_consent"
    static let settings_consent_granted = "settings.consent_granted"
    static let settings_consent_not_granted = "settings.consent_not_granted"
    static let settings_revoke_consent = "settings.revoke_consent"
    static let settings_revoke_consent_hint = "settings.revoke_consent_hint"
    static let settings_revoke_consent_confirm = "settings.revoke_consent_confirm"
    static let settings_revoke_consent_message = "settings.revoke_consent_message"
    
    // MARK: - Legal
    static let legalTerms = "legal.terms"
    static let legalPrivacy = "legal.privacy"
    static let legalImprint = "legal.imprint"
    static let legalContractLanguageNotice = "legal.contractLanguageNotice"
    static let legalEffectiveDate = "legal.effectiveDate"
    static let legalVersion = "legal.version"
    static let legalTermsTitle = "legal.terms.title"
    static let legalTermsSubtitle = "legal.terms.subtitle"
    static let legalTermsNavTitle = "legal.terms.navTitle"
    static let legalPrivacyTitle = "legal.privacy.title"
    static let legalPrivacySubtitle = "legal.privacy.subtitle"
    static let legalPrivacyNavTitle = "legal.privacy.navTitle"
    static let legalImprintTitle = "legal.imprint.title"
    static let legalImprintNavTitle = "legal.imprint.navTitle"
    static let legalFooterDate = "legal.footer.date"
        static let legalFairUseLink = "legal.fairUseLink"
        static let legalLanguageNotice = "legal.languageNotice"
        static let legalPurchaseConsentText = "legal.purchaseConsentText"
        static let legalFairUseCheckbox = "legal.fairUseCheckbox"
        static let legalCloseHint = "legal.closeHint"
        static let legalFairUseCheckboxLink = "legal.fairUseCheckboxLink"
        static let legalFairUseCheckboxRequired = "legal.fairUseCheckboxRequired"
    
    // MARK: - Dietary
    static let diets = "dietary.diets"
    static let allergies = "dietary.allergies"
    static let dislikes = "dietary.dislikes"
    static let notes = "dietary.notes"
    static let spicyLevel = "dietary.spicyLevel"
    static let tastePreferences = "dietary.tastePreferences"
    static let sweet = "dietary.sweet"
    static let sour = "dietary.sour"
    static let bitter = "dietary.bitter"
    static let umami = "dietary.umami"
    static let vegetarian = "dietary.vegetarian"
    static let vegan = "dietary.vegan"
    static let pescetarian = "dietary.pescetarian"
    static let lowCarb = "dietary.lowCarb"
    static let highProtein = "dietary.highProtein"
    static let glutenFree = "dietary.glutenFree"
    static let lactoseFree = "dietary.lactoseFree"
    static let halal = "dietary.halal"
    static let kosher = "dietary.kosher"
    
    // MARK: - Recipes
    static let recipes = "recipes.title"
    static let myRecipes = "recipes.myRecipes"
    static let community = "recipes.community"
    static let favorites = "recipes.favorites"
    static let createRecipe = "recipes.create"
    static let recipesCreateOwn = "recipes.createOwn"
    static let ingredients = "recipes.ingredients"
    static let instructions = "recipes.instructions"
    static let cookingTime = "recipes.cookingTime"
    static let servings = "recipes.servings"
    static let difficulty = "recipes.difficulty"
    static let easy = "recipes.easy"
    static let medium = "recipes.medium"
    static let hard = "recipes.hard"
    static let category = "recipes.category"
    static let upload = "recipes.upload"
    static let uploadSuccess = "recipes.uploadSuccess"
    static let generateRecipe = "recipes.generate"
    static let recipeGenerated = "recipes.recipeGenerated"
    static let saveRecipe = "recipes.save"
    static let recipeSaved = "recipes.saved"
    static let deleteRecipe = "recipes.deleteRecipe"
    static let deleteRecipeTitle = "recipes.deleteRecipeTitle"
    static let deleteMenuTitle = "recipes.deleteMenuTitle"
    static let recipeDeleted = "recipes.deleted"
    static let noRecipes = "recipes.noRecipes"
    static let noRecipesMessage = "recipes.noRecipesMessage"
    static let rateRecipe = "recipes.rate"
    static let rating = "recipes.rating"
    
    // MARK: - Shopping List
    static let shoppingList = "shopping.title"
    static let addItem = "shopping.addItem"
    static let removeItem = "shopping.removeItem"
    static let clearList = "shopping.clearList"
    static let clearListConfirm = "shopping.clearListConfirm"
    static let item = "shopping.item"
    static let quantity = "shopping.quantity"
    static let unit = "shopping.unit"
    
    // MARK: - Chat
    static let chat = "chat.title"
    static let askQuestion = "chat.askQuestion"
    static let typeMessage = "chat.typeMessage"
    static let sendMessage = "chat.sendMessage"
    static let newChat = "chat.newChat"
    static let chatHistory = "chat.chatHistory"
    static let clearHistory = "chat.clearHistory"
    static let cooking = "chat.cooking"
    static let cookingSubtitle = "chat.cookingSubtitle"
    static let messagePlaceholder = "chat.messagePlaceholder"
    static let culinaName = "chat.culinaName"
    static let chatWelcomeMessage = "chat.welcomeMessage"
    static let inRecipeAI = "chat.inRecipeAI"
    static let chat_consent_active = "chat.consent_active"
    static let chat_revoke_consent_hint = "chat.revoke_consent_hint"
    
    // MARK: - Notifications
    static let notificationsGeneral = "notifications.general"
    static let notificationsRecipe = "notifications.recipe"
    static let notificationsOffers = "notifications.offers"
    static let notificationsManage = "notifications.manage"
    
    // MARK: - Recipe Creator
    static let whatToCook = "creator.whatToCook"
    static let describeDish = "creator.describeDish"
    static let generate = "creator.generate"
    static let generatingRecipe = "creator.generating"
    static let useIngredients = "creator.useIngredients"
    static let ingredientsFromFridge = "creator.ingredientsFromFridge"
    
    // MARK: - Recipe Detail
    static let timer = "detail.timer"
    static let startTimer = "detail.startTimer"
    static let stopTimer = "detail.stopTimer"
    static let timerStarted = "detail.timerStarted"
    static let addToShoppingList = "detail.addToShoppingList"
    static let addedToShoppingList = "detail.addedToShoppingList"
    static let reportRecipe = "detail.reportRecipe"
    static let shareRecipe = "detail.shareRecipe"
    static let timerHide = "recipe.timerHide"
    static let timerActive = "recipe.timerActive"
    static let recipe_regenerateHint = "recipe.regenerateHint"
    
    // MARK: - Time Units
    static let minutes = "time.minutes"
    static let hours = "time.hours"
    static let seconds = "time.seconds"
    static let min = "time.min"
    static let hour = "time.hour"
    static let sec = "time.sec"
    
    // MARK: - Spicy Levels
    static let mild = "spicy.mild"
    static let normal = "spicy.normal"
    static let spicy = "spicy.spicy"
    static let verySpicy = "spicy.verySpicy"
    
    // MARK: - Courses
    static let starter = "course.starter"
    static let mainCourse = "course.main"
    static let dessert = "course.dessert"
    static let sideDish = "course.side"
    static let beverage = "course.beverage"
    static let appetizer = "course.appetizer"
    static let amuseBouche = "course.amuseBouche"
    static let aperitif = "course.aperitif"
    static let digestif = "course.digestif"
    static let cheese = "course.cheese"
    
    // MARK: - Onboarding
    static let welcome = "onboarding.welcome"
    static let welcomeMessage = "onboarding.welcomeMessage"
    static let getStarted = "onboarding.getStarted"
    static let skip = "onboarding.skip"
    
    // MARK: - Errors
    static let errorGeneric = "error.generic"
    static let errorNetwork = "error.network"
    static let errorAuth = "error.auth"
    static let errorRecipeNotFound = "error.recipeNotFound"
    static let errorRequired = "error.required"
    static let errorInvalidEmail = "error.invalidEmail"
    static let errorPasswordTooShort = "error.passwordTooShort"
    static let errorNotLoggedIn = "error.notLoggedIn"
    static let errorUploadFailed = "error.uploadFailed"
    static let errorSaveFailed = "error.saveFailed"
    static let errorInvalidRecipeRequest = "error.invalidRecipeRequest"
    static let errorNetworkConnection = "error.networkConnection"
    static let errorServerUnavailable = "error.serverUnavailable"
    static let errorAppleSignInFailed = "error.appleSignInFailed"
    static let errorAppleTokenInvalid = "error.appleTokenInvalid"
    static let errorPurchaseFailed = "error.purchaseFailed"
    static let errorRestoreFailed = "error.restoreFailed"
    static let errorJailbreakDetected = "error.jailbreakDetected"
    static let errorJailbreakCommunityUpload = "error.jailbreakCommunityUpload"
    static let errorChatError = "error.chatError"
    static let errorImageAnalysisError = "error.imageAnalysisError"
    static let errorExportFailed = "error.exportFailed"
    static let errorRateLimitExceeded = "error.rateLimitExceeded"
    static let errorGenericUserFriendly = "error.genericUserFriendly"
    static let errorAccountExists = "error.accountExists"
    static let errorAccountExistsLoginLink = "error.accountExistsLoginLink"
    static let errorApiClientNotConfigured = "error.apiClientNotConfigured"
    static let errorProcessingFailed = "error.processingFailed"
    
    // MARK: - Empty States
    static let emptyRecipes = "empty.recipes"
    static let emptyCommunity = "empty.community"
    static let emptyShoppingList = "empty.shoppingList"
    static let emptyChat = "empty.chat"
    
    // MARK: - Common Additional
    static let common_chooseImage = "common.chooseImage"
    static let common_takePhoto = "common.takePhoto"
    static let common_chooseFromGallery = "common.chooseFromGallery"
    static let common_add = "common.add"
    static let common_selectServings = "common.selectServings"
    static let common_openCulina = "common.openCulina"
    
    // MARK: - Error Messages
    static let error_deletePhotoFailed = "error.deletePhotoFailed"
    
    // MARK: - Recipe Additional
    static let recipe_aiGreeting = "recipe.aiGreeting"
    static let recipe_imageAnalysisPrefix = "recipe.imageAnalysisPrefix"
    static let recipe_imageAnalysisSuffix = "recipe.imageAnalysisSuffix"
    
    // MARK: - Dietary Placeholders
    static let dietary_allergiesPlaceholder = "dietary.allergiesPlaceholder"
    static let dietary_dislikesPlaceholder = "dietary.dislikesPlaceholder"
    static let dietary_notesPlaceholder = "dietary.notesPlaceholder"
    
    // MARK: - Timer Labels
    static let timer_simmer = "timer.simmer"
    static let timer_cool = "timer.cool"
    static let timer_rest = "timer.rest"
    static let timer_proof = "timer.proof"
    static let timer_marinate = "timer.marinate"
    static let timer_bake = "timer.bake"
    static let timer_fry = "timer.fry"
    static let timer_steep = "timer.steep"
    
    // MARK: - Recipe Submit
    static let recipe_submit = "recipe.submit"
    
    // MARK: - Creator System Prompts
    static let creator_allergiesLabel = "creator.allergiesLabel"
    static let creator_dietsLabel = "creator.dietsLabel"
    static let creator_spicyLabel = "creator.spicyLabel"
    static let creator_tastesLabel = "creator.tastesLabel"
    static let creator_systemPrompt = "creator.systemPrompt"
    
    // MARK: - Report
    static let report = "report.title"
    static let reportReason = "report.reason"
    static let reportReasonInappropriate = "report.reason.inappropriate"
    static let reportReasonSpam = "report.reason.spam"
    static let reportReasonMisleading = "report.reason.misleading"
    static let reportReasonOther = "report.reason.other"
    static let reportDescription = "report.description"
    static let reportSubmit = "report.submit"
    static let reportSuccess = "report.success"
    
    // MARK: - Tabs
    static let tabKulina = "tab.kulina"
    static let tabRecipes = "tab.recipes"
    static let tabRecipeBook = "tab.recipeBook"
    static let tabShopping = "tab.shopping"
    
    // MARK: - Paywall
    static let paywallUnlimited = "paywall.unlimited"
    static let paywallSubtitle = "paywall.subtitle"
    static let paywallPrice = "paywall.price"
    static let paywallPerMonth = "paywall.perMonth"
    static let paywallFeatureUnlimitedRecipes = "paywall.feature.unlimitedRecipes"
    static let paywallFeatureCommunityLibrary = "paywall.feature.communityLibrary"
    static let paywallFeatureNewFeatures = "paywall.feature.newFeatures"
    static let paywallFeatureSecure = "paywall.feature.secure"
    static let paywallSubscribeButton = "paywall.subscribeButton"
    static let paywallRestorePurchase = "paywall.restorePurchase"
    static let paywallContinueFree = "paywall.continueFree"
    static let paywallTerms = "paywall.terms"
    static let paywallImprintPlaceholder = "paywall.imprintPlaceholder"
    
    // MARK: - Subscription Settings
    static let subscriptionUnlimited = "subscription.unlimited"
    static let subscriptionUnlimitedActive = "subscription.unlimitedActive"
    static let subscriptionFreeTier = "subscription.freeTier"
    static let subscriptionPerMonth = "subscription.perMonth"
    static let subscriptionNextBilling = "subscription.nextBilling"
    static let subscriptionExpiresOn = "subscription.expiresOn"
    static let subscriptionAutoRenewOn = "subscription.autoRenewOn"
    static let subscriptionAutoRenewOff = "subscription.autoRenewOff"
    static let subscriptionKeepFeaturesUntilExpiry = "subscription.keepFeaturesUntilExpiry"
    static let subscriptionAllFeaturesExceptAI = "subscription.allFeaturesExceptAI"
    static let subscriptionUpgradeForAI = "subscription.upgradeForAI"
    static let subscriptionManageInAppleSettings = "subscription.manageInAppleSettings"
    static let subscriptionManageCancelInfo = "subscription.manageCancelInfo"
    static let subscriptionUnlockUnlimited = "subscription.unlockUnlimited"
    static let subscriptionRestorePurchases = "subscription.restorePurchases"
    static let subscriptionCancelAnytime = "subscription.cancelAnytime"
    static let subscriptionAIChatUnlimited = "subscription.aiChatUnlimited"
    static let subscriptionAIRecipeGenerator = "subscription.aiRecipeGenerator"
    static let subscriptionAINutritionAnalysis = "subscription.aiNutritionAnalysis"
    static let subscriptionNoLimits = "subscription.noLimits"
    static let subscriptionFairUseInfo = "subscription.fairUseInfo"

    // MARK: - Auto-generated Keys
    static let chat_bild_angehängt = "chat.bild_angehängt"
    static let chat_erstelle_ein_rezept = "chat.erstelle_ein_rezept"
    static let chat_wähle_wie_das_rezept = "chat.wähle_wie_das_rezept"
    static let chat_ich_suche_nach_einem = "chat.ich_suche_nach_einem"
    static let chat_das_perfekte_rezept_ist = "chat.das_perfekte_rezept_ist"
    static let chat_frage_mich_alles_übers = "chat.frage_mich_alles_übers"
    static let chat_rezepte_zutaten_tipps_tricks = "chat.rezepte_zutaten_tipps_tricks"
    static let community_bild_ist_optional_max = "community.bild_ist_optional_max"
    static let community_erfolgreich_in_der_community = "community.erfolgreich_in_der_community"
    static let community_veröffentlichen = "community.veröffentlichen"
    static let community_mit_der_veröffentlichung_wird = "community.mit_der_veröffentlichung_wird"
    static let settings_ernährung = "settings.ernährung"
    static let settings_ernährungsweisen = "settings.ernährungsweisen"
    static let settings_allergienunverträglichkeiten = "settings.allergienunverträglichkeiten"
    static let settings_geschmackspräferenzen = "settings.geschmackspräferenzen"
    static let settings_schärfelevel = "settings.schärfelevel"
    static let ui_zutaten = "ui.zutaten"
    static let ui_angaben_gemäß_5_tmg = "ui.angaben_gemäß_5_tmg"
    static let ui_die_europäische_kommission_stellt = "ui.die_europäische_kommission_stellt"
    static let recipe_foto_hinzufügen = "recipe.foto_hinzufügen"
    static let recipe_dein_rezept_wurde_erfolgreich = "recipe.dein_rezept_wurde_erfolgreich"
    static let onboarding_allergien_unverträglichkeiten = "onboarding.allergien_unverträglichkeiten"
    static let onboarding_damit_wir_deine_rezepte = "onboarding.damit_wir_deine_rezepte"
    static let onboarding_keine_allergien_perfekt_weiter = "onboarding.keine_allergien_perfekt_weiter"
    static let onboarding_ernährungsweise = "onboarding.ernährungsweise"
    static let onboarding_wähle_deine_ernährungspräferenzen_a = "onboarding.wähle_deine_ernährungspräferenzen_a"
    static let onboarding_keine_spezielle_ernährungsweise_kei = "onboarding.keine_spezielle_ernährungsweise_kei"
    static let onboarding_geschmackspräferenzen = "onboarding.geschmackspräferenzen"
    static let onboarding_was_möchtest_du_meiden = "onboarding.was_möchtest_du_meiden"
    static let onboarding_zutaten_die_du_nicht = "onboarding.zutaten_die_du_nicht"
    static let onboarding_keine_abneigungen_super_flexibel = "onboarding.keine_abneigungen_super_flexibel"
    static let onboarding_zurück = "onboarding.zurück"
    static let onboarding_stepOfTotal = "onboarding.stepOfTotal"
    static let onboarding_howSpicyDoYouLikeIt = "onboarding.howSpicyDoYouLikeIt"
    static let onboarding_additionalPreferencesOptional = "onboarding.additionalPreferencesOptional"
    static let onboarding_selectLanguageTitle = "onboarding.selectLanguageTitle"
    static let onboarding_selectLanguageSubtitle = "onboarding.selectLanguageSubtitle"
    static let ui_datenschutzerklärung = "ui.datenschutzerklärung"
    static let ui_der_schutz_ihrer_personenbezogenen = "ui.der_schutz_ihrer_personenbezogenen"
    static let ui_grundsätze_der_datenverarbeitung = "ui.grundsätze_der_datenverarbeitung"
    static let ui_erforderlich_bei_registrierung = "ui.erforderlich_bei_registrierung"
    static let ui_wir_nutzen_openai_gpt4omini = "ui.wir_nutzen_openai_gpt4omini"
    static let ui_übermittelte_daten = "ui.übermittelte_daten"
    static let ui_keychain_verschlüsselt = "ui.keychain_verschlüsselt"
    static let ui_folgende_drittanbieter_verarbeiten_ = "ui.folgende_drittanbieter_verarbeiten_"
    static let ui_zum_schutz_ihrer_daten = "ui.zum_schutz_ihrer_daten"
    static let ui_sie_haben_folgende_rechte = "ui.sie_haben_folgende_rechte"
    static let ui_übersicht_über_die_aufbewahrungsfri = "ui.übersicht_über_die_aufbewahrungsfri"
    static let ui_hinweis_chatnachrichten_werden_nur = "ui.hinweis_chatnachrichten_werden_nur"
    static let ui_wir_verzichten_vollständig_auf = "ui.wir_verzichten_vollständig_auf"
    static let ui_sie_können_ihr_konto = "ui.sie_können_ihr_konto"
    static let ui_folgende_daten_werden_gelöscht = "ui.folgende_daten_werden_gelöscht"
    static let ui_maßgebliche_rechtsgrundlagen = "ui.maßgebliche_rechtsgrundlagen"
    static let recipe_keine_fotos = "recipe.keine_fotos"
    static let recipe_in_menüs_speichern = "recipe.in_menüs_speichern"
    static let recipe_menü = "recipe.menü"
    static let recipe_nur_für_dich_sichtbar = "recipe.nur_für_dich_sichtbar"
    static let recipe_für_alle_sichtbar = "recipe.für_alle_sichtbar"
    static let recipe_rezept_schließen = "recipe.rezept_schließen"
    static let recipe_menü_auswählen = "recipe.menü_auswählen"
    static let recipe_alle_ohne_menü = "recipe.alle_ohne_menü"
    static let recipe_ernährung = "recipe.ernährung"
    static let recipe_schärfelevel = "recipe.schärfelevel"
    static let recipe_dabei_kann_ich_dir = "recipe.dabei_kann_ich_dir"
    static let recipe_ich_suche_nach_einem = "recipe.ich_suche_nach_einem"
    static let recipe_das_perfekte_rezept_ist = "recipe.das_perfekte_rezept_ist"
    static let recipe_keine_schritte_gefunden = "recipe.keine_schritte_gefunden"
    static let recipe_zutaten = "recipe.zutaten"
    static let recipe_zutaten_zur_einkaufsliste_hinzufüge = "recipe.zutaten_zur_einkaufsliste_hinzufüge"
    static let recipe_nährwerte = "recipe.nährwerte"
    static let recipe_nährwerte_pro_portion = "recipe.nährwerte_pro_portion"
    static let recipe_nährwerte_insgesamt = "recipe.nährwerte_insgesamt"
    static let recipe_keine_fotos_ce07 = "recipe.keine_fotos_ce07"
    static let recipe_in_der_zwischenzeit_führe = "recipe.in_der_zwischenzeit_führe"
    static let recipe_stell_mir_fragen_zu = "recipe.stell_mir_fragen_zu"
    static let recipe_zb_garzeiten_anpassen_ersatzzutaten = "recipe.zb_garzeiten_anpassen_ersatzzutaten"
    static let recipe_für_wie_viele_personen = "recipe.für_wie_viele_personen"
    static let recipe_die_mengen_werden_automatisch = "recipe.die_mengen_werden_automatisch"
    static let recipe_zur_einkaufsliste_hinzufügen = "recipe.zur_einkaufsliste_hinzufügen"
    static let recipe_bewerte_dieses_rezept = "recipe.bewerte_dieses_rezept"
    static let recipe_danke_für_deine_bewertung = "recipe.danke_für_deine_bewertung"
    static let recipe_keine_schritte_gefunden_2c3f = "recipe.keine_schritte_gefunden_2c3f"
    static let recipe_achtung_du_hast_das = "recipe.achtung_du_hast_das"
    static let recipe_zutaten_1272 = "recipe.zutaten_1272"
    static let recipe_in_der_zwischenzeit_führe_b7f6 = "recipe.in_der_zwischenzeit_führe_b7f6"
    static let recipe_stell_mir_fragen_zu_facc = "recipe.stell_mir_fragen_zu_facc"
    static let recipe_zb_garzeiten_anpassen_ersatzzutaten_b588 = "recipe.zb_garzeiten_anpassen_ersatzzutaten_b588"
    static let recipe_filter_löschen = "recipe.filter_löschen"
    static let recipe_sprache = "recipe.sprache"
    static let recipe_sprachen = "recipe.sprachen"
    static let recipe_menü_539e = "recipe.menü_539e"
    static let recipe_neues_menü = "recipe.neues_menü"
    static let recipe_menüname = "recipe.menüname"
    static let recipe_ich_bin_dabei_deine = "recipe.ich_bin_dabei_deine"
    static let recipe_erstelle_jetzt_dein_erstes = "recipe.erstelle_jetzt_dein_erstes"
    static let recipe_mit_ki_erstellen = "recipe.mit_ki_erstellen"
    static let recipe_ich_bin_dabei_deine_d9e2 = "recipe.ich_bin_dabei_deine_d9e2"
    static let recipe_dieses_rezept_wird_dauerhaft = "recipe.dieses_rezept_wird_dauerhaft"
    static let recipe_dieses_menü_ohne_rezepte = "recipe.dieses_menü_ohne_rezepte"
    static let recipe_keine_communitybeiträge = "recipe.keine_communitybeiträge"
    static let recipe_teile_deine_rezepte_mit = "recipe.teile_deine_rezepte_mit"
    static let recipe_dieses_rezept_wird_aus = "recipe.dieses_rezept_wird_aus"
    static let recipe_noch_keine_communityrezepte = "recipe.noch_keine_communityrezepte"
    static let recipe_sei_der_erste_und = "recipe.sei_der_erste_und"
    static let recipe_meine = "recipe.meine"
    static let recipe_keine_privaten_rezepte = "recipe.keine_privaten_rezepte"
    static let recipe_alle_deine_rezepte_sind = "recipe.alle_deine_rezepte_sind"
    static let ui_danke_für_deine_meldung = "ui.danke_für_deine_meldung"
    static let ui_grund_der_meldung = "ui.grund_der_meldung"
    static let ui_zusätzliche_details_optional = "ui.zusätzliche_details_optional"
    static let settings_ernährung_01ac = "settings.ernährung_01ac"
    static let settings_ernährungsweisen_003f = "settings.ernährungsweisen_003f"
    static let settings_allergienunverträglichkeiten_kommag = "settings.allergienunverträglichkeiten_kommag"
    static let settings_geschmackspräferenzen_2f71 = "settings.geschmackspräferenzen_2f71"
    static let settings_schärfelevel_b3e3 = "settings.schärfelevel_b3e3"
    static let settings_meine_daten = "settings.meine_daten"
    static let settings_passwort_ändern = "settings.passwort_ändern"
    static let settings_passwort_erfolgreich_geändert = "settings.passwort_erfolgreich_geändert"
    static let settings_passwort_bestätigen = "settings.passwort_bestätigen"
    static let settings_passwort_ändern_aea8 = "settings.passwort_ändern_aea8"
    static let settings_aktivität = "settings.aktivität"
    static let settings_präferenzen = "settings.präferenzen"
    static let settings_möchtest_du_eine_vollständige = "settings.möchtest_du_eine_vollständige"
    static let settings_culina_unlimited = "settings.culina_unlimited"
    static let settings_deine_vorteile = "settings.deine_vorteile"
    static let settings_automatische_verlängerung_ein = "settings.automatische_verlängerung_ein"
    static let settings_automatische_verlängerung_aus = "settings.automatische_verlängerung_aus"
    static let settings_du_behältst_alle_unlimitedfunktione = "settings.du_behältst_alle_unlimitedfunktione"
    static let settings_kein_aktives_abo = "settings.kein_aktives_abo"
    static let settings_schalte_alle_funktionen_mit = "settings.schalte_alle_funktionen_mit"
    static let settings_abo_kündigen_keine_weiteren = "settings.abo_kündigen_keine_weiteren"
    static let settings_wir_berechnen_nicht_mehr = "settings.wir_berechnen_nicht_mehr"
    static let settings_unlimited_jetzt_wieder_aktivieren = "settings.unlimited_jetzt_wieder_aktivieren"
    static let settings_unlimited_abonnieren_699_monat = "settings.unlimited_abonnieren_699_monat"
    static let settings_erscheinungsbild = "settings.erscheinungsbild"
    static let shopping_hinzufügen = "shopping.hinzufügen"
    static let shopping_erledigte_löschen = "shopping.erledigte_löschen"
    static let shopping_alle_löschen = "shopping.alle_löschen"
    static let shopping_einkaufsliste_ist_leer = "shopping.einkaufsliste_ist_leer"
    static let shopping_füge_zutaten_aus_rezepten = "shopping.füge_zutaten_aus_rezepten"
    static let shopping_eintrag_hinzufügen = "shopping.eintrag_hinzufügen"
    static let shopping_hinzufügen_5f41 = "shopping.hinzufügen_5f41"
    static let ui_willkommen_zurück = "ui.willkommen_zurück"
    static let ui_registrieren = "ui.registrieren"
    static let ui_passwort_bestätigen = "ui.passwort_bestätigen"
    static let ui_wiederholen = "ui.wiederholen"
    static let ui_wiederholen_dc04 = "ui.wiederholen_dc04"
    static let ui_ich_akzeptiere_die = "ui.ich_akzeptiere_die"
    static let ui_und_die = "ui.und_die"
    static let ui_datenschutzerklärung_2997 = "ui.datenschutzerklärung_2997"
    static let ui_ich_bestätige_dass_ich = "ui.ich_bestätige_dass_ich"
    static let ui_allgemeine_geschäftsbedingungen_agb = "ui.allgemeine_geschäftsbedingungen_agb"
    static let ui_der_nutzer_verpflichtet_sich = "ui.der_nutzer_verpflichtet_sich"
    static let ui_die_verarbeitung_personenbezogener_ = "ui.die_verarbeitung_personenbezogener_"
    static let ui_diese_ist_nicht_bestandteil = "ui.diese_ist_nicht_bestandteil"
    static let ui_zusammenfassung = "ui.zusammenfassung"
    
    // MARK: - Placeholders
    static let placeholder_askMe = "placeholder.askMe"
    static let placeholder_describeDish = "placeholder.describeDish"
    static let placeholder_maxTime = "placeholder.maxTime"
    static let placeholder_itemName = "placeholder.itemName"
    static let placeholder_quantity = "placeholder.quantity"
    static let placeholder_recipeName = "placeholder.recipeName"
    static let placeholder_ingredient = "placeholder.ingredient"
    static let placeholder_stepDescription = "placeholder.stepDescription"
    static let placeholder_allergies = "placeholder.allergies"
    static let placeholder_dislikes = "placeholder.dislikes"
    static let placeholder_notes = "placeholder.notes"
    static let placeholder_newAllergy = "placeholder.newAllergy"
    static let placeholder_newDislike = "placeholder.newDislike"
    static let placeholder_menuName = "placeholder.menuName"
    static let placeholder_searchCommunity = "placeholder.searchCommunity"
    static let placeholder_search = "placeholder.search"
    static let placeholder_minutes = "placeholder.minutes"
    
    // MARK: - Labels
    static let label_whatToCook = "label.whatToCook"
    static let label_maxTimeMinutes = "label.maxTimeMinutes"
    static let label_nutrition = "label.nutrition"
    static let label_kcalMin = "label.kcalMin"
    static let label_kcalMax = "label.kcalMax"
    static let label_proteinMin = "label.proteinMin"
    static let label_proteinMax = "label.proteinMax"
    static let label_fatMin = "label.fatMin"
    static let label_fatMax = "label.fatMax"
    static let label_carbsMin = "label.carbsMin"
    static let label_carbsMax = "label.carbsMax"
    static let label_categories = "label.categories"
    static let label_tastePreferences = "label.tastePreferences"
    static let label_spicyLevel = "label.spicyLevel"
    
    // MARK: - Spicy Levels
    static let spicy_mild = "spicy.mild"
    static let spicy_normal = "spicy.normal"
    static let spicy_hot = "spicy.hot"
    static let spicy_veryHot = "spicy.veryHot"
    
    // MARK: - Taste
    static let taste_sweet = "taste.sweet"
    static let taste_sour = "taste.sour"
    static let taste_bitter = "taste.bitter"
    static let taste_umami = "taste.umami"
    
    // MARK: - Categories
    static let category_vegetarian = "category.vegetarian"
    static let category_vegan = "category.vegan"
    static let category_pescetarian = "category.pescetarian"
    static let category_lowCarb = "category.lowCarb"
    static let category_highProtein = "category.highProtein"
    static let category_glutenFree = "category.glutenFree"
    static let category_lactoseFree = "category.lactoseFree"
    static let category_halal = "category.halal"
    static let category_kosher = "category.kosher"
    
    // MARK: - Buttons
    static let button_done = "button.done"
    static let button_cancel = "button.cancel"
    static let button_create = "button.create"
    static let button_save = "button.save"
    static let button_ok = "button.ok"
    static let button_generate = "button.generate"
    static let button_rateRecipe = "button.rateRecipe"
    static let button_finishRecipe = "button.finishRecipe"
    
    // MARK: - Labels (Additional)
    static let label_name = "label.name"
    static let label_quantityOptional = "label.quantityOptional"
    static let label_category = "label.category"
    static let label_autoDetected = "label.autoDetected"
    static let label_difficulty = "label.difficulty"
    static let label_servings = "label.servings"
    static let label_timeMinutes = "label.timeMinutes"
    static let label_nutritionOptional = "label.nutritionOptional"
    static let label_preparationSteps = "label.preparationSteps"
    static let label_basicInfo = "label.basicInfo"
    static let label_recipeName = "label.recipeName"
    static let label_photoOptional = "label.photoOptional"
    static let label_ingredients = "label.ingredients"
    static let label_calories = "label.calories"
    static let label_protein = "label.protein"
    static let label_carbs = "label.carbs"
    static let label_fat = "label.fat"
    static let label_timer = "label.timer"
    static let label_minutes = "label.minutes"
    static let label_step = "label.step"
    static let label_cookingTime = "label.cookingTime"
    static let label_tags = "label.tags"
    static let label_photo = "label.photo"
    
    // MARK: - Navigation
    static let nav_createRecipe = "nav.createRecipe"
    static let nav_addEntry = "nav.addEntry"
    
    // MARK: - Alerts
    static let alert_noRecipeRequest = "alert.noRecipeRequest"
    static let alert_recipeNotPossible = "alert.recipeNotPossible"
    static let alert_error = "alert.error"
    static let alert_successfullySaved = "alert.successfullySaved"
    
    // MARK: - Difficulty
    static let difficulty_easy = "difficulty.easy"
    static let difficulty_medium = "difficulty.medium"
    static let difficulty_hard = "difficulty.hard"
    
    // MARK: - Additional Buttons
    static let button_ownRecipe = "button.ownRecipe"
    static let button_ownRecipeCreate = "button.ownRecipeCreate"
    static let button_kiGenerator = "button.kiGenerator"
    static let button_share = "button.share"
    static let button_shareRecipe = "button.shareRecipe"
    static let button_remove = "button.remove"
    static let button_clearAll = "button.clearAll"
    
    // MARK: - Additional Labels
    static let label_all = "label.all"
    static let label_likes = "label.likes"
    
    // MARK: - Additional Navigation
    static let nav_myContributions = "nav.myContributions"
    
    // MARK: - Additional Alerts
    static let alert_removeContribution = "alert.removeContribution"
    static let alert_clearAllEntries = "alert.clearAllEntries"
    
    // MARK: - Additional Text
    static let text_prettyEmptyHere = "text.prettyEmptyHere"
    
    // MARK: - Shopping Categories
    static let category_meatPoultry = "category.meatPoultry"
    static let category_fishSeafood = "category.fishSeafood"
    static let category_vegetables = "category.vegetables"
    static let category_fruits = "category.fruits"
    static let category_dairy = "category.dairy"
    static let category_bakery = "category.bakery"
    static let category_grains = "category.grains"
    static let category_canned = "category.canned"
    static let category_spices = "category.spices"
    static let category_beverages = "category.beverages"
    static let category_frozen = "category.frozen"
    static let category_snacks = "category.snacks"
    static let category_other = "category.other"
    
    // MARK: - Tags
    static let tag_vegan = "tag.vegan"
    static let tag_vegetarian = "tag.vegetarian"
    static let tag_glutenFree = "tag.glutenFree"
    static let tag_lactoseFree = "tag.lactoseFree"
    static let tag_lowCarb = "tag.lowCarb"
    static let tag_highProtein = "tag.highProtein"
    static let tag_quick = "tag.quick"
    static let tag_budget = "tag.budget"
    static let tag_spicy = "tag.spicy"
    
    // MARK: - Language Tags
    static let tag_german = "tag.german"
    static let tag_english = "tag.english"
    static let tag_spanish = "tag.spanish"
    static let tag_french = "tag.french"
    static let tag_italian = "tag.italian"
    
    // MARK: - Settings Navigation
    static let nav_dietarySettings = "nav.dietarySettings"
    static let nav_profileSettings = "nav.profileSettings"
    static let nav_subscription = "nav.subscription"
    
    // MARK: - Additional Placeholders
    static let placeholder_searchCommunityLong = "placeholder.searchCommunityLong"
    
    // MARK: - Settings Additional
    static let settings_legal = "settings.legal"
    static let settings_account = "settings.account"
    static let settings_currentPassword = "settings.currentPassword"
    static let settings_newPassword = "settings.newPassword"
    static let settings_dataExport = "settings.dataExport"
    static let settings_perMonth = "settings.perMonth"
    static let settings_statusActive = "settings.statusActive"
    static let settings_nextBilling = "settings.nextBilling"
    static let settings_expiresOn = "settings.expiresOn"
    static let settings_dislikes = "settings.dislikes"
    static let settings_hints = "settings.hints"
    static let settings_finished = "settings.finished"
    static let settings_username = "settings.username"
    static let settings_recipesCount = "settings.recipesCount"
    static let settings_favoritesCount = "settings.favoritesCount"
    static let settings_ratingsCount = "settings.ratingsCount"
    static let settings_allergiesLabel = "settings.allergiesLabel"
    static let settings_dietaryTypesLabel = "settings.dietaryTypesLabel"
    static let settings_none = "settings.none"
    static let settings_passwordsDoNotMatch = "settings.passwordsDoNotMatch"
    static let settings_passwordTooShort = "settings.passwordTooShort"
    static let settings_emailNotFound = "settings.emailNotFound"
    static let settings_notLoggedIn = "settings.notLoggedIn"
    static let settings_wrongPassword = "settings.wrongPassword"
    static let settings_keine_aktiven_käufe_gefunden = "settings.keine_aktiven_käufe_gefunden"
    static let settings_perk_unlimited = "settings.perk_unlimited"
    static let settings_perk_community = "settings.perk_community"
    static let settings_perk_tracking = "settings.perk_tracking"
    static let settings_perk_features = "settings.perk_features"
    static let settings_perk_secure = "settings.perk_secure"
    
    // MARK: - Recipe Completion
    static let completion_enjoyYourMeal = "completion.enjoyYourMeal"
    static let completion_photo = "completion.photo"
    static let completion_saveRecipe = "completion.saveRecipe"
    static let completion_savePrivate = "completion.savePrivate"
    static let completion_shareCommunity = "completion.shareCommunity"
    static let completion_doNotSave = "completion.doNotSave"
    static let completion_successfullySaved = "completion.successfullySaved"
    static let completion_sharedInCommunity = "completion.sharedInCommunity"
    static let completion_savedInYourRecipes = "completion.savedInYourRecipes"
    static let completion_saveInMenu = "completion.saveInMenu"
    static let completion_withoutMenu = "completion.withoutMenu"
    
    // MARK: - Auth
    static let auth_letsGetStarted = "auth.letsGetStarted"
    static let auth_alreadyHaveAccount = "auth.alreadyHaveAccount"
    static let auth_termsOfService = "auth.termsOfService"
    static let auth_privacyPolicy = "auth.privacyPolicy"
    static let auth_imprint = "auth.imprint"
    static let auth_signInButton = "auth.signInButton"
    
    // MARK: - Generate
    static let generate_cookFromThis = "generate.cookFromThis"
    static let generate_suggestion = "generate.suggestion"
    static let generate_ingredientsCount = "generate.ingredientsCount"
    
    // MARK: - Report
    static let report_reported = "report.reported"
    static let report_reportRecipe = "report.reportRecipe"
    static let report_reportButton = "report.reportButton"

    // MARK: - Consent
    static let consent_title = "consent.title"
    static let consent_subtitle = "consent.subtitle"
    static let consent_decline = "consent.decline"
    static let consent_accept = "consent.accept"
    static let consent_required = "consent.required"
    static let consent_revoked = "consent.revoked"
}
