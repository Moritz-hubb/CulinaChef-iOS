# CulinaChef Authentication Setup

## ✅ Was wurde implementiert

### Backend (Supabase)
- **PostgreSQL Datenbank** mit User Authentication
- **JWT Token-basierte Auth** über Supabase Auth API
- **RLS (Row Level Security)** für sichere Datenisolierung pro User

### iOS App (SwiftUI)
- ✅ **Sign Up Screen** - Registrierung mit Email/Passwort
  - Passwort-Stärke-Indikator
  - Passwort-Bestätigung mit visueller Validierung
  - Email-Validierung
  
- ✅ **Sign In Screen** - Anmeldung für bestehende User
  - Email und Passwort Felder
  - "Passwort anzeigen" Toggle
  - Error Handling
  
- ✅ **Keychain Storage** - Sichere Token-Speicherung
  - Access Token in iOS Keychain
  - Refresh Token für Session-Verlängerung
  - Automatische Session-Wiederherstellung beim App-Start

- ✅ **Auth State Management** - Zentrale Auth-Verwaltung
  - `AppState.isAuthenticated` steuert UI-Flow
  - Automatisches Token-Handling bei API-Calls
  - Logout-Funktion in Settings

- ✅ **Backend Integration**
  - Alle API-Calls nutzen User-Token
  - Recipes, Favorites, AI-Generation sind user-spezifisch

## 🎨 Design

Das Auth-System nutzt das gleiche Design wie der Rest der App:
- Warmer Gradient-Background (Peach/Orange Töne)
- Weiße Input-Felder mit Focus-Highlighting
- Smooth Animationen beim Wechsel zwischen Sign In/Sign Up
- Konsistente Icons und Typography

## 🔐 Sicherheit

- **Keychain**: Tokens werden in iOS Keychain gespeichert (nicht UserDefaults!)
- **HTTPS**: Alle Requests an Supabase nutzen HTTPS
- **JWT**: Supabase JWT Tokens mit automatischer Expiration
- **Password Requirements**: Minimum 6 Zeichen (kann angepasst werden)

## 📱 User Flow

1. **App Start**
   - Prüft Keychain auf gespeicherten Token
   - Falls vorhanden → automatisch angemeldet → MainTabView
   - Falls nicht → AuthView wird angezeigt

2. **Registration**
   - User gibt Email + Passwort ein
   - Supabase erstellt Account
   - Token wird in Keychain gespeichert
   - Automatischer Login

3. **Login**
   - User gibt Credentials ein
   - Supabase validiert
   - Token wird in Keychain gespeichert
   - App zeigt MainTabView

4. **Logout**
   - User klickt "Logout" in Settings
   - Token wird aus Keychain gelöscht
   - Supabase Session wird beendet
   - App zeigt AuthView

5. **Session Persistence**
   - Token bleibt in Keychain zwischen App-Neustarts
   - User muss sich nicht jedes Mal neu anmelden

## 🚀 Nächste Schritte

### Optional zu implementieren:
1. **Password Reset** - "Passwort vergessen?" Flow
2. **Email Verification** - Email-Bestätigung nach Registrierung
3. **Social Login** - Google, Apple Sign-In
4. **Biometric Auth** - Face ID / Touch ID für schnellen Login
5. **Token Refresh** - Automatisches Refresh bei Expiration

## 🧪 Testing

```bash
# Backend starten
cd /Users/moritzserrin/CulinaChef/backend
source .venv/bin/activate
source .env
uvicorn app.main:app --host 127.0.0.1 --port "$BACKEND_PORT" --reload

# iOS App
cd /Users/moritzserrin/CulinaChef/ios
open CulinaChef.xcodeproj
# Build & Run in Xcode
```

### Test Cases:
1. ✅ Neue User registrieren
2. ✅ Mit bestehendem User anmelden
3. ✅ Falsches Passwort → Error wird angezeigt
4. ✅ Logout → zurück zu AuthView
5. ✅ App schließen und neu öffnen → User bleibt angemeldet
6. ✅ Rezepte erstellen/laden → nur eigene Rezepte sichtbar

## 📝 Code-Struktur

```
ios/Sources/
├── Services/
│   ├── AppState.swift              # Auth State + Session Management
│   ├── SupabaseAuthClient.swift    # Supabase API Client
│   ├── BackendClient.swift         # Backend API mit Token
│   └── Config.swift                # Supabase URLs/Keys
└── Views/
    ├── AuthView.swift              # Auth Container (Sign In/Up Toggle)
    ├── SignInView.swift            # Sign In Screen
    ├── SignUpView.swift            # Sign Up Screen
    ├── RootView.swift              # Root mit Auth Gate
    └── SettingsView.swift          # Mit Logout Button
```

## 🔧 Konfiguration

Die Supabase URL und Keys sind bereits in `Config.swift` konfiguriert:
```swift
static let supabaseURL = URL(string: "https://ywduddopwudltshxiqyp.supabase.co")!
static let supabaseAnonKey = "..."
```

Das SQL Schema ist in `/CulinaChef/supabase.sql` definiert und bereits in Supabase deployed.
