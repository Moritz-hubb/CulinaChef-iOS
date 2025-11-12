# iOS App Mehrsprachigkeit: Deutsch & Englisch

## 🎯 Ziel
Die iOS App soll vollständig auf Deutsch und Englisch verfügbar sein, mit der Möglichkeit in den Einstellungen zwischen den Sprachen zu wechseln.

---

## 📊 Aktueller Stand

### ✅ Was existiert bereits
- **JSON-Dateien**: `ios/Resources/Localization/de.json`, `en.json` (+ es, fr, it)
- **LocalizationManager**: Swift-Klasse vorhanden, aber nur hardcoded Deutsch
- **L enum**: Zentrale Keys definiert (z.B. `L.done`, `L.settings`)
- **Dokumentation**: `LOCALIZATION.md` (veraltet, beschreibt System das nicht implementiert ist)

### ❌ Was fehlt
- LocalizationManager lädt keine JSON-Dateien
- Alle Texte sind hardcoded auf Deutsch
- Language Switcher funktioniert nicht
- Backend AI-Prompts senden keine Language Info

---

## 🏗️ Architektur-Übersicht

```
┌─────────────────────────────────────────────┐
│           iOS App (SwiftUI)                 │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  LocalizationManager (Singleton)     │  │
│  │  - Lädt JSON-Dateien                 │  │
│  │  - ObservableObject                  │  │
│  │  - currentLanguage: String           │  │
│  │  - translations: [String: Any]       │  │
│  └──────────────────────────────────────┘  │
│             ▲                               │
│             │                               │
│  ┌──────────┴────────────────────────────┐ │
│  │         Views (SwiftUI)               │ │
│  │  Text(L.done.localized)               │ │
│  │  @ObservedObject localizationManager  │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   SettingsView                        │ │
│  │   Language Picker: 🇩🇪 Deutsch       │ │
│  │                    🇬🇧 English        │ │
│  └───────────────────────────────────────┘ │
│                                             │
└─────────────────────────────────────────────┘
           │
           │ Accept-Language: en
           ▼
┌─────────────────────────────────────────────┐
│      FastAPI Backend                        │
│  - Recipe Generation (EN/DE)                │
│  - Chat Responses (EN/DE)                   │
└─────────────────────────────────────────────┘
```

---

## 🛠️ Implementierungs-Plan

### Phase 1: LocalizationManager Fix (Core System)

#### 1.1 LocalizationManager komplett neu schreiben
**Datei**: `ios/Sources/Services/LocalizationManager.swift`

**Was ändern:**
- ✅ JSON-Dateien laden aus Bundle
- ✅ Nested keys unterstützen (z.B. `settings.title`)
- ✅ ObservableObject für Live-Updates
- ✅ UserDefaults für persistente Sprach-Wahl
- ✅ Fallback zu Deutsch wenn Key fehlt

**Implementation:**
```swift
import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            loadTranslations()
            objectWillChange.send() // Trigger UI update
        }
    }
    
    private var translations: [String: Any] = [:]
    private let fallbackLanguage = "de"
    
    let availableLanguages = [
        "de": "Deutsch",
        "en": "English"
    ]
    
    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "app_language") ?? Locale.current.language.languageCode?.identifier ?? "de"
        
        // Validate language exists, fallback to German
        if !availableLanguages.keys.contains(currentLanguage) {
            currentLanguage = fallbackLanguage
        }
        
        loadTranslations()
    }
    
    private func loadTranslations() {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "json", inDirectory: "Resources/Localization"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ Failed to load translations for \(currentLanguage)")
            
            // Load fallback
            if currentLanguage != fallbackLanguage {
                if let fallbackPath = Bundle.main.path(forResource: fallbackLanguage, ofType: "json", inDirectory: "Resources/Localization"),
                   let fallbackData = try? Data(contentsOf: URL(fileURLWithPath: fallbackPath)),
                   let fallbackJson = try? JSONSerialization.jsonObject(with: fallbackData) as? [String: Any] {
                    translations = fallbackJson
                }
            }
            return
        }
        
        translations = json
    }
    
    func string(forKey key: String) -> String {
        // Support nested keys like "settings.title"
        let keys = key.split(separator: ".").map(String.init)
        var current: Any? = translations
        
        for k in keys {
            if let dict = current as? [String: Any] {
                current = dict[k]
            } else {
                // Key not found, return key itself as fallback
                print("⚠️ Missing translation: \(key) for language: \(currentLanguage)")
                return key
            }
        }
        
        return current as? String ?? key
    }
}

extension String {
    var localized: String {
        return LocalizationManager.shared.string(forKey: self)
    }
}

// String keys enum (centralized)
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
    
    // MARK: - Authentication
    static let signIn = "auth.signIn"
    static let signUp = "auth.signUp"
    static let signOut = "auth.signOut"
    static let email = "auth.email"
    static let password = "auth.password"
    static let username = "auth.username"
    static let forgotPassword = "auth.forgotPassword"
    static let createAccount = "auth.createAccount"
    static let alreadyHaveAccount = "auth.alreadyHaveAccount"
    static let dontHaveAccount = "auth.dontHaveAccount"
    
    // MARK: - Settings
    static let settings = "settings.title"
    static let notifications = "settings.notifications"
    static let language = "settings.language"
    static let appearance = "settings.appearance"
    static let darkMode = "settings.darkMode"
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
    
    // MARK: - Legal
    static let terms = "legal.terms"
    static let privacy = "legal.privacy"
    static let imprint = "legal.imprint"
    
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
    
    // MARK: - Recipes
    static let recipes = "recipes.title"
    static let myRecipes = "recipes.myRecipes"
    static let community = "recipes.community"
    static let favorites = "recipes.favorites"
    static let createRecipe = "recipes.create"
    static let ingredients = "recipes.ingredients"
    static let instructions = "recipes.instructions"
    static let cookingTime = "recipes.cookingTime"
    static let servings = "recipes.servings"
    static let difficulty = "recipes.difficulty"
    static let category = "recipes.category"
    static let generateRecipe = "recipes.generate"
    static let saveRecipe = "recipes.save"
    static let deleteRecipe = "recipes.deleteRecipe"
    
    // MARK: - Shopping List
    static let shoppingList = "shopping.title"
    static let addItem = "shopping.addItem"
    static let clearList = "shopping.clearList"
    static let item = "shopping.item"
    
    // MARK: - Chat
    static let chat = "chat.title"
    static let askQuestion = "chat.askQuestion"
    static let typeMessage = "chat.typeMessage"
    static let cooking = "chat.cooking"
    static let cookingSubtitle = "chat.cookingSubtitle"
    
    // MARK: - Notifications
    static let notificationsGeneral = "notifications.general"
    static let notificationsRecipe = "notifications.recipe"
    static let notificationsOffers = "notifications.offers"
    static let notificationsManage = "notifications.manage"
}
```

---

### Phase 2: JSON-Dateien bereinigen & ergänzen

#### 2.1 Prüfen ob de.json und en.json vollständig sind
```bash
cd /Users/moritzserrin/CulinaChef/ios/Resources/Localization
# Prüfe ob alle L enum Keys in JSON vorhanden sind
```

#### 2.2 JSON-Struktur anpassen
**Format**: Nested JSON mit Kategorien

**Beispiel de.json:**
```json
{
  "common": {
    "done": "Fertig",
    "cancel": "Abbrechen",
    "save": "Speichern",
    "delete": "Löschen"
  },
  "settings": {
    "title": "Einstellungen",
    "language": "Sprache",
    "notifications": "Benachrichtigungen"
  },
  "recipes": {
    "title": "Rezepte",
    "myRecipes": "Meine Rezepte",
    "create": "Rezept erstellen"
  }
}
```

**Beispiel en.json:**
```json
{
  "common": {
    "done": "Done",
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete"
  },
  "settings": {
    "title": "Settings",
    "language": "Language",
    "notifications": "Notifications"
  },
  "recipes": {
    "title": "Recipes",
    "myRecipes": "My Recipes",
    "create": "Create Recipe"
  }
}
```

#### 2.3 Fehlende Übersetzungen hinzufügen
- Alle Keys aus L enum müssen in de.json UND en.json existieren
- Tools: Script schreiben um fehlende Keys zu finden

---

### Phase 3: SettingsView - Language Picker

#### 3.1 Language Picker UI implementieren
**Datei**: `ios/Sources/Views/SettingsView.swift`

**Hinzufügen:**
```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Language Section
                Section {
                    Picker(L.language.localized, selection: $localizationManager.currentLanguage) {
                        ForEach(Array(localizationManager.availableLanguages.keys.sorted()), id: \.self) { code in
                            HStack {
                                Text(languageFlag(code))
                                Text(localizationManager.availableLanguages[code] ?? code)
                            }
                            .tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(L.language.localized)
                }
                
                // Weitere Settings...
            }
            .navigationTitle(L.settings.localized)
        }
    }
    
    private func languageFlag(_ code: String) -> String {
        switch code {
        case "de": return "🇩🇪"
        case "en": return "🇬🇧"
        default: return "🌐"
        }
    }
}
```

---

### Phase 4: Backend Integration (AI Language Support)

#### 4.1 AppState.swift anpassen
**Datei**: `ios/Sources/Services/AppState.swift`

**Funktion hinzufügen:**
```swift
func languageSystemPrompt() -> String {
    let lang = LocalizationManager.shared.currentLanguage
    switch lang {
    case "de":
        return "Antworte ausschließlich auf Deutsch. Verwende deutsche Begriffe für Zutaten und Rezepte."
    case "en":
        return "Respond exclusively in English. Use English terms for ingredients and recipes."
    default:
        return "Antworte ausschließlich auf Deutsch."
    }
}
```

#### 4.2 API-Requests mit Accept-Language Header
**Wo**: Alle API-Calls (RecipeService, ChatService, etc.)

**Hinzufügen:**
```swift
func makeAPIRequest() async throws {
    var request = URLRequest(url: url)
    request.setValue(LocalizationManager.shared.currentLanguage, forHTTPHeaderField: "Accept-Language")
    // ... rest of request
}
```

---

### Phase 5: Views migrieren (Hardcoded Strings ersetzen)

#### 5.1 Alle Views durchgehen und hardcoded Strings ersetzen

**Vorher:**
```swift
Text("Einstellungen")
Button("Speichern") { }
```

**Nachher:**
```swift
Text(L.settings.localized)
Button(L.save.localized) { }
```

#### 5.2 Priority Liste für View-Migration

**High Priority (User-facing):**
1. ✅ SettingsView
2. ✅ RecipeListView / RecipeDetailView
3. ✅ RecipeCreatorView
4. ✅ ChatView
5. ✅ ShoppingListView

**Medium Priority:**
6. ✅ MenuPlannerView
7. ✅ ProfileView
8. ✅ NotificationSettingsView

**Low Priority (wenig Text):**
9. ✅ LegalViews (AGB, Datenschutz, Impressum - nur Titel)
10. ✅ Onboarding

#### 5.3 Automatisierung mit Script
```bash
# Finde alle hardcoded German strings
grep -r 'Text(".*[äöüßÄÖÜ].*")' ios/Sources/Views/

# Oder alle deutschen Wörter
grep -r 'Text(".*")' ios/Sources/Views/ | grep -v ".localized"
```

---

## 📦 JSON-Dateien Struktur (Vollständig)

### Kategorien im JSON

```
common.*          - Buttons, allgemeine UI-Elemente
auth.*            - Login, Registrierung
settings.*        - Einstellungen-Screen
dietary.*         - Ernährungspräferenzen
legal.*           - AGB, Datenschutz, Impressum
recipes.*         - Rezept-bezogen
shopping.*        - Einkaufsliste
chat.*            - Chat/AI-Assistent
notifications.*   - Benachrichtigungen
menu.*            - Menüplaner (falls vorhanden)
creator.*         - Rezept-Erstellung
profile.*         - Profil-Screen
```

---

## 🧪 Testing-Checkliste

### Manuelle Tests
- [ ] Settings → Language wechseln (DE ↔ EN)
- [ ] Alle Screens checken (keine Keys sichtbar)
- [ ] App neu starten → Sprache bleibt erhalten
- [ ] AI-Chat antwortet in richtiger Sprache
- [ ] Rezept-Generierung in richtiger Sprache
- [ ] Fehlende Übersetzungen werden logged

### Automated Tests (Optional)
```swift
func testLocalizationManager() {
    let manager = LocalizationManager.shared
    manager.currentLanguage = "de"
    XCTAssertEqual(L.done.localized, "Fertig")
    
    manager.currentLanguage = "en"
    XCTAssertEqual(L.done.localized, "Done")
}
```

---

## 📝 Schritt-für-Schritt Umsetzung

### ✅ Sprint 1: Core System (2h)
1. LocalizationManager komplett neu schreiben
2. JSON-Dateien laden & nested keys unterstützen
3. Language Picker in SettingsView
4. Testen ob Switching funktioniert

### ✅ Sprint 2: JSON vervollständigen (1-2h)
1. Script: Fehlende Keys finden
2. de.json vervollständigen
3. en.json übersetzen (alle Keys)
4. Validieren (alle L enum Keys vorhanden?)

### ✅ Sprint 3: Views migrieren (3-4h)
1. SettingsView
2. RecipeListView, RecipeDetailView
3. RecipeCreatorView
4. ChatView
5. ShoppingListView
6. Weitere Views

### ✅ Sprint 4: Backend Integration (1h)
1. languageSystemPrompt() in AppState
2. Accept-Language Header in API-Calls
3. Testen (Rezept-Generierung DE/EN)

### ✅ Sprint 5: Testing & Polish (1h)
1. Alle Screens manuell testen
2. Fehlende Übersetzungen ergänzen
3. Edge Cases (App-Start, Language-Wechsel während laufender AI-Request)

**Total: 8-10 Stunden**

---

## 🚨 Häufige Probleme & Lösungen

### Problem: JSON wird nicht geladen
**Lösung**: 
- Prüfe `project.yml` → Resources muss richtig konfiguriert sein
- `./gen.sh` ausführen um Xcode-Projekt neu zu generieren
- Bundle-Pfad in LocalizationManager prüfen

### Problem: UI updated nicht nach Language-Wechsel
**Lösung**:
- `@ObservedObject private var localizationManager = LocalizationManager.shared` in View
- `objectWillChange.send()` in LocalizationManager nach Language-Änderung

### Problem: Nested Keys funktionieren nicht
**Lösung**:
- JSON-Struktur mit verschachtelten Objekten (nicht flach)
- LocalizationManager muss Keys mit `.` splitten

### Problem: Fehlende Übersetzungen
**Lösung**:
- Logging: `print("⚠️ Missing translation: \(key)")`
- Fallback: Zeige Key selbst an
- Script schreiben um Keys zu vergleichen

---

## 🔧 Helper Scripts

### find_missing_keys.py
```python
import json
import sys

# Load both JSON files
with open('de.json') as f:
    de = json.load(f)
with open('en.json') as f:
    en = json.load(f)

def flatten_dict(d, parent_key=''):
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}.{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key).items())
        else:
            items.append((new_key, v))
    return dict(items)

de_flat = flatten_dict(de)
en_flat = flatten_dict(en)

# Find missing keys
missing_in_en = set(de_flat.keys()) - set(en_flat.keys())
missing_in_de = set(en_flat.keys()) - set(de_flat.keys())

print("Missing in en.json:")
for key in missing_in_en:
    print(f"  - {key}: {de_flat[key]}")

print("\nMissing in de.json:")
for key in missing_in_de:
    print(f"  - {key}: {en_flat[key]}")
```

---

## 🎯 Definition of Done

- [x] LocalizationManager lädt JSON-Dateien
- [x] Language Picker in Settings funktioniert
- [x] Alle L enum Keys in de.json & en.json vorhanden
- [x] Keine hardcoded Strings mehr in Views
- [x] AI-Chat antwortet in gewählter Sprache
- [x] Language-Präferenz wird gespeichert (UserDefaults)
- [x] Keine fehlenden Keys (oder logged als Warning)
- [x] App läuft auf Simulator & echtem Device

---

**Stand:** November 2025  
**Version:** 1.0  
**Author:** CulinaChef Team
