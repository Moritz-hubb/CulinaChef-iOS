# Multi-Language Support Documentation

## Overview

The CulinaChef iOS app now supports 5 languages:
- **German** (`de`) - Default
- **English** (`en`)
- **Spanish** (`es`)
- **French** (`fr`)
- **Italian** (`it`)

## Architecture

### LocalizationManager
- Singleton class that manages runtime language switching
- Loads strings from JSON files in `Resources/Localization/`
- Observable object that triggers UI updates when language changes

### String Keys (L enum)
- Centralized enum with all localization keys
- Type-safe access to localized strings
- Example: `L.done`, `L.settings.title`, `L.recipes.create`

## Usage in SwiftUI

### Basic Usage
```swift
Text(L.done.localized)
Button(L.save.localized) { /* action */ }
```

### Observing Language Changes
```swift
@ObservedObject private var localizationManager = LocalizationManager.shared

var body: some View {
    Text(L.welcome.localized)
        .onReceive(localizationManager.$currentLanguage) { _ in
            // UI updates automatically
        }
}
```

## Language Switching

Users can change language in:
**Settings → Language → Select from dropdown**

Changes are:
1. Saved to `UserDefaults` under key `app_language`
2. Applied to LocalizationManager immediately
3. Reflected in AI-generated content (OpenAI prompts updated)

## Backend Integration

The app's AI features automatically adapt to the selected language:

### AppState.languageSystemPrompt()
Returns language-specific instructions for OpenAI:
- German: "Antworte ausschließlich auf Deutsch."
- English: "Respond exclusively in English."
- Spanish: "Responde exclusivamente en español."
- French: "Réponds exclusivement en français."
- Italian: "Rispondi esclusivamente in italiano."

### Affected Features
- Recipe generation (text, instructions, ingredients)
- Chat responses
- Timer labels (automatically extracted in selected language)
- Taste preferences (spicy level labels)
- Course types (starter, main, dessert, etc.)

## Timer Extraction

The app automatically creates timers from recipe steps. The `duration_minutes` field in recipe steps is language-independent (integer), so timer functionality works across all languages automatically.

## Adding New Strings

### 1. Add key to L enum in `LocalizationManager.swift`
```swift
enum L {
    // ...
    static let myNewKey = "category.myNewKey"
}
```

### 2. Add translations to all JSON files
In `Resources/Localization/de.json`:
```json
{
  "category.myNewKey": "Mein neuer Text"
}
```

In `Resources/Localization/en.json`:
```json
{
  "category.myNewKey": "My new text"
}
```

Repeat for `es.json`, `fr.json`, `it.json`.

### 3. Use in SwiftUI
```swift
Text(L.myNewKey.localized)
```

## Testing

### Manual Testing Steps
1. Open Settings → Language
2. Select each language
3. Navigate through all app screens
4. Verify:
   - UI text updates immediately
   - No missing translations (keys should not appear)
   - AI responses are in selected language
   - User preferences persist after app restart

### Automated Testing (Future)
Consider adding XCTest cases to verify:
- All keys exist in all language files
- No duplicate keys
- JSON files are valid
- LocalizationManager loads all languages correctly

## Migration from Hardcoded Strings

To convert existing hardcoded German strings:

1. Find hardcoded text: `grep -r "Text(\".*[äöüß].*\")" ios/Sources/`
2. Add key to L enum
3. Add translations to all JSON files
4. Replace `Text("Hardcoded")` with `Text(L.key.localized)`

### Example
**Before:**
```swift
Text("Einstellungen")
```

**After:**
```swift
// 1. Add to L enum: static let settings = "settings.title"
// 2. Add to JSON files: "settings.title": "Einstellungen" (de), "Settings" (en), etc.
// 3. Update code:
Text(L.settings.localized)
```

## Known Limitations

1. **Legal Documents**: Terms, Privacy Policy, and Imprint are currently not fully localized (only titles)
2. **Error Messages**: Some backend error messages are still in English
3. **Dietary Options**: Diet names (vegetarian, vegan, etc.) are hardcoded in SettingsView but localized in JSON

## Future Enhancements

- [ ] Add more languages (Portuguese, Dutch, etc.)
- [ ] Implement SwiftUI's native Localizable.strings format
- [ ] Add RTL language support (Arabic, Hebrew)
- [ ] Localize legal documents (full text)
- [ ] Add language-specific date/number formatting
- [ ] Add plural forms support (e.g., "1 recipe" vs "2 recipes")

## Files Modified

- `ios/Sources/Services/LocalizationManager.swift` - New file
- `ios/Resources/Localization/*.json` - New files (de, en, es, fr, it)
- `ios/Sources/Views/SettingsView.swift` - Updated language picker
- `ios/Sources/Services/AppState.swift` - Updated languageSystemPrompt()
- `ios/project.yml` - Added Resources path

## Regenerating Xcode Project

After adding new localization files, regenerate the Xcode project:

```bash
cd ios
./gen.sh  # or: xcodegen generate
```

Then open `CulinaChef.xcodeproj` in Xcode.
