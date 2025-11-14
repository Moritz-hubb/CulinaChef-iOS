# CulinaChef iOS App

[![iOS CI](https://img.shields.io/badge/CI-GitHub%20Actions-brightgreen)](https://github.com/moritzserrin/CulinaChef/actions)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://www.apple.com/ios/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

Eine KI-gestützte Rezept- und Ernährungs-App für iOS.

## 🚀 Setup

### 1. Secrets konfigurieren

Die App benötigt API-Keys, die aus Sicherheitsgründen nicht im Repository gespeichert werden.

```bash
# Kopiere das Template
cp Configs/Secrets.xcconfig.template Configs/Secrets.xcconfig

# Bearbeite die Datei und füge deine echten API-Keys ein:
# - OPENAI_API_KEY: Von https://platform.openai.com/api-keys
# - SENTRY_DSN: Von https://sentry.io (optional für Error-Tracking)
```

**⚠️ WICHTIG:** Die Datei `Configs/Secrets.xcconfig` wird von `.gitignore` ausgeschlossen und darf **niemals** committed werden!

### 2. Projekt generieren

Das Projekt nutzt [XcodeGen](https://github.com/yonaskolb/XcodeGen) zur Projektverwaltung:

```bash
# Installiere XcodeGen (falls noch nicht vorhanden)
brew install xcodegen

# Generiere das Xcode-Projekt
./gen.sh
```

### 3. Öffne das Projekt

```bash
open CulinaChef.xcodeproj
```

## 📋 Anforderungen

- **Xcode:** 15.0 oder höher
- **iOS Deployment Target:** 17.0+
- **Swift:** 5.9
- **Backend:** FastAPI-Backend muss laufen (siehe `/backend`)

## 🔧 Konfiguration

### Environments

Die App unterscheidet zwischen drei Environments (siehe `Config.swift`):

- **Development:** Localhost für Simulator, LAN-IP für Gerät
- **Staging:** Test-Backend (URL anpassen)
- **Production:** Live-Backend (URL anpassen)

### Backend-URLs anpassen

Bearbeite `Sources/Services/Config.swift` und setze die korrekten URLs:

```swift
case .staging:
    return URL(string: "https://staging-api.culinaai.com")!
    
case .production:
    return URL(string: "https://api.culinaai.com")!
```

## 🏗️ Architektur

```
Sources/
├── App.swift                 # App Entry Point
├── Services/                 # Business Logic & API Clients
│   ├── AppState.swift       # Central State Management
│   ├── BackendClient.swift  # Backend API
│   ├── OpenAIClient.swift   # OpenAI Integration
│   ├── SupabaseAuthClient.swift
│   └── Config.swift         # Environment Configuration
├── Views/                    # SwiftUI Views
├── Models/                   # Data Models
├── Managers/                 # Feature Managers
└── Utilities/               # Helper Functions
```

## 🔐 Sicherheit

- **Keychain:** Tokens werden sicher im iOS Keychain gespeichert
- **HTTPS:** Alle API-Requests nutzen TLS-Verschlüsselung
- **RLS:** Row Level Security in Supabase schützt User-Daten
- **Secrets:** API-Keys nie im Code, nur via `.xcconfig`

## 🧪 Testing

```bash
# Tests ausführen (wenn vorhanden)
xcodebuild test -project CulinaChef.xcodeproj -scheme CulinaChef -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📦 Dependencies

- **Sentry:** 8.57.2 - Error Tracking & Crash Reporting
- **StoreKit 2:** Native Apple In-App-Purchases

## 🔄 CI/CD & Code-Qualität

### GitHub Actions
- ✅ Automatische Builds bei Push/PR
- ✅ SwiftLint für Code-Qualität
- ✅ Security Scans (Secrets, Debug-Logs)
- ✅ Code Coverage Tracking

### Lokale Entwicklung
```bash
# SwiftLint installieren
brew install swiftlint

# Code prüfen
swiftlint lint

# Auto-Fix (wo möglich)
swiftlint lint --fix
```

📖 **Mehr Infos:** Siehe `CI_CD_SETUP.md`

## 📄 Dokumentation

- `AUTH_SETUP.md` - Authentifizierung & Session Management
- `SECURITY_CHECKLIST.md` - Pre-Launch Security Checks
- `COMPLETED_SECURITY_FIXES.md` - Abgeschlossene Security-Maßnahmen
- `CI_CD_SETUP.md` - CI/CD & Code-Qualität Setup
- `LOCALIZATION.md` - Mehrsprachigkeit
- `Legal_Texts/` - Datenschutz, AGB, Impressum

## 🚧 Vor dem Launch

### KRITISCH
- [x] ✅ Secrets Management (Keychain, .xcconfig)
- [x] ✅ DSGVO-konforme Datenschutzerklärung
- [x] ✅ OpenAI Consent Dialog integriert
- [x] ✅ Production-safe Logging (Logger.swift)
- [x] ✅ Datenexport-Funktion
- [ ] ⏳ Unit Tests (Ziel: 30% Coverage)
- [ ] ⏳ CI/CD Pipeline aktiviert
- [ ] ⏳ Bundle Identifier angepasst (`com.culinaai.culinachef`)

### EMPFOHLEN
- [ ] Production Backend-URLs gesetzt
- [ ] TestFlight Beta-Testing (2 Wochen, 20-50 Tester)
- [ ] Input Validation in kritischen Forms
- [ ] App Store Screenshots & Metadata vorbereitet

### OPTIONAL
- [ ] SSL Certificate Pinning aktiviert
- [ ] Server-Side Subscription Validation
- [ ] Jailbreak Detection

📊 **Production Readiness Score: 7.8/10** - Siehe vollständige Analyse

## 📞 Support

Bei Fragen oder Problemen:
- **E-Mail:** support@culinaai.com
- **Datenschutz:** datenschutz@culinaai.com

## 📝 Lizenz

Proprietär - Alle Rechte vorbehalten
