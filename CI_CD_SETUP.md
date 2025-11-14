# 🚀 CI/CD Setup - CulinaChef iOS

## Übersicht

Dieses Projekt nutzt **GitHub Actions** für Continuous Integration und Code-Qualität.

---

## ✅ Was wird automatisch geprüft?

### 1. **SwiftLint** (Code-Qualität)
- Prüft Code-Style und Best Practices
- Konfiguration in `.swiftlint.yml`
- Läuft bei jedem Push/PR

### 2. **Build & Test**
- Kompiliert die App für iOS Simulator
- Führt Unit-Tests aus (wenn vorhanden)
- Generiert Code-Coverage-Report

### 3. **Security Scan**
- Prüft auf hardcodierte Secrets
- Checkt, ob `Secrets.xcconfig` nicht committed wurde
- Warnt bei unsicheren Debug-Logs

### 4. **Code Metrics**
- Zählt Lines of Code
- Listet TODO/FIXME Kommentare
- Zeigt Code-Statistiken

---

## 🛠️ Lokale Installation

### SwiftLint installieren
```bash
# Via Homebrew (empfohlen)
brew install swiftlint

# Via Mint
mint install realm/SwiftLint
```

### Lokales Linting
```bash
# Alle Dateien prüfen
swiftlint lint

# Nur Warnungen anzeigen
swiftlint lint --strict

# Auto-Fix (wo möglich)
swiftlint lint --fix

# Spezifische Dateien
swiftlint lint Sources/Views/SettingsView.swift
```

---

## 📋 SwiftLint Regeln

### Aktive Regeln (Opt-In)
- ✅ `force_unwrapping` - Warnung bei `!` ohne Begründung
- ✅ `empty_count` - `.isEmpty` statt `.count == 0`
- ✅ `toggle_bool` - `.toggle()` statt `= !bool`
- ✅ `empty_string` - `.isEmpty` statt `== ""`

### Deaktivierte Regeln
- ❌ `line_length` - Zu viele Verstöße in bestehendem Code
- ❌ `type_body_length` - AppState ist bewusst groß
- ❌ `file_length` - AppState ist bewusst groß

### Custom Rules
- 🔒 `no_print_in_production` - Warnung bei `print()` ohne `#if DEBUG`
- 🔒 `force_unwrap_with_comment` - Force unwrap sollte begründet werden

---

## 🔧 Xcode Integration

### Build Phase hinzufügen

1. Öffne **CulinaChef.xcodeproj**
2. Target **CulinaChef** → **Build Phases**
3. Klicke **+** → **New Run Script Phase**
4. Füge ein:

```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, run: brew install swiftlint"
fi
```

5. Benenne die Phase um in **"SwiftLint"**
6. **Wichtig:** Ziehe die Phase **vor** "Compile Sources"

### Ergebnis
- SwiftLint läuft bei jedem Build in Xcode
- Warnungen werden direkt im Code angezeigt
- Fehler verhindern den Build (bei `--strict`)

---

## 🧪 Tests lokal ausführen

```bash
# Tests im Simulator
xcodebuild test \
  -project CulinaChef.xcodeproj \
  -scheme CulinaChef \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Mit Code Coverage
xcodebuild test \
  -project CulinaChef.xcodeproj \
  -scheme CulinaChef \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# Coverage Report anzeigen
xcrun xccov view --report DerivedData/*/Logs/Test/*.xcresult
```

---

## 📊 GitHub Actions Status

### Badges (für README.md)

```markdown
[![iOS CI](https://github.com/YOUR_USERNAME/CulinaChef/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/CulinaChef/actions/workflows/ios-ci.yml)
[![codecov](https://codecov.io/gh/YOUR_USERNAME/CulinaChef/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_USERNAME/CulinaChef)
```

### Workflow läuft bei:
- ✅ Push auf `main` oder `develop` Branch
- ✅ Pull Request zu `main` oder `develop`
- ✅ Manuell über GitHub Actions UI

---

## 🔒 Secrets in GitHub Actions

Für vollständige CI/CD Funktionalität benötigte Secrets:

### CODECOV_TOKEN (optional)
1. Gehe zu [codecov.io](https://codecov.io)
2. Verbinde dein GitHub Repository
3. Kopiere das Token
4. GitHub → Settings → Secrets → New repository secret
5. Name: `CODECOV_TOKEN`, Value: `<dein-token>`

---

## 🐛 Troubleshooting

### Problem: "SwiftLint not found"
**Lösung:**
```bash
brew install swiftlint
```

### Problem: "xcodebuild: command not found"
**Lösung:**
```bash
sudo xcode-select --install
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Problem: "Too many SwiftLint warnings"
**Lösung:** Passe `.swiftlint.yml` an oder deaktiviere Regeln:
```yaml
disabled_rules:
  - force_unwrapping  # Temporär deaktivieren
```

### Problem: "Tests fail in CI but pass locally"
**Ursachen:**
- Unterschiedliche Xcode-Versionen
- Fehlende Secrets.xcconfig in CI
- Zeitabhängige Tests

**Lösung:** Prüfe GitHub Actions Logs und passe Tests an

---

## 📈 Nächste Schritte

### Priorität 1: Tests schreiben
- [ ] AppState Unit Tests
- [ ] KeychainManager Tests
- [ ] BackendClient Tests
- Ziel: 30% Code Coverage

### Priorität 2: Pre-Commit Hooks
```bash
# Husky + SwiftLint Setup
# Verhindert Commits mit Linting-Fehlern
```

### Priorität 3: Fastlane Integration
```ruby
# Automatisierte TestFlight Deployments
# Screenshot-Generierung
# Metadata-Management
```

---

## 📞 Support

Bei Problemen mit CI/CD:
- **GitHub Issues:** [Projekt-Repository]
- **Dokumentation:** [GitHub Actions Docs](https://docs.github.com/en/actions)
- **SwiftLint Docs:** [realm.github.io/SwiftLint](https://realm.github.io/SwiftLint/)

---

**Erstellt:** 2025-11-14  
**Status:** ✅ Aktiv und funktional
