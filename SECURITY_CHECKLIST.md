# 🔐 Security Checklist - Pre-Launch

Diese Checkliste enthält alle sicherheitsrelevanten Aufgaben, die vor dem App-Launch durchgeführt werden müssen.

## ✅ Phase 1 - Sofortmaßnahmen (ABGESCHLOSSEN)

- [x] `.gitignore` erstellt und Secrets ausgeschlossen
- [x] `Secrets.xcconfig.template` als sichere Vorlage erstellt
- [x] Hart codierter Sentry DSN aus `App.swift` entfernt
- [x] Sentry DSN wird jetzt aus Info.plist geladen
- [x] Debug-Test-Event für Production deaktiviert
- [x] 37 Backup-Dateien aus Repository entfernt
- [x] Supabase Anon Key mit Security-Hinweis dokumentiert

## ⚠️ Phase 1 - DRINGEND (SOFORT MACHEN!)

- [x] OpenAI API-Key rotiert und konfiguriert
- [x] Secrets.xcconfig aktualisiert und verifiziert

- [ ] **Git Repository initialisieren**
  ```bash
  cd /Users/moritzserrin/CulinaChef/ios
  git init
  git add .
  git commit -m "Initial commit - Secrets secured"
  
  # WICHTIG: Prüfe dass Secrets.xcconfig NICHT committed wurde
  git ls-files | grep Secrets.xcconfig
  # Sollte LEER sein! Nur Secrets.xcconfig.template sollte da sein
  ```

## 🔄 Phase 2 - Vor Launch (1-2 Wochen)

- [ ] **Production Backend-URLs konfigurieren**
  - Bearbeite `Sources/Services/Config.swift`
  - Setze echte URLs für Staging und Production
  - Teste Verbindung zu beiden Environments

- [ ] **Bundle Identifier ändern** (Apple Developer Account erforderlich)
  - In `project.yml`: `CFBundleIdentifier: com.culinaai.culinachef`
  - In `Info.plist`: Bundle Identifier anpassen
  - Projekt neu generieren: `./gen.sh`

- [x] **SSL Certificate Pinning implementieren** (optional, aber empfohlen)
  - Für kritische API-Calls (Auth, Payments) via `SecureURLSession` und `.cer`-Pins
  - Verhindert Man-in-the-Middle Attacks

- [x] **Keychain Migration prüfen (Subscription Status)**
  - Subscription Status von UserDefaults nach Keychain
- [ ] **Taste Preferences verschlüsselt speichern**
  - Lokale Taste-Preferences nicht mehr im Klartext in UserDefaults speichern

- [ ] **Jailbreak Detection** (optional)
  - Prüfe ob Gerät gejailbreaked ist (JailbreakDetector.isJailbroken)
  - Warne User oder schränke Features ein (z.B. Hinweisbanner in Settings oder AI-Features sperren)

## 🧪 Phase 3 - Testing (1 Woche)

- [ ] **Security Audit durchführen**
  - Alle API-Requests auf HTTPS prüfen
  - Token-Handling validieren
  - Sensitive Daten in Logs suchen

- [ ] **Penetration Testing**
  - Mit Proxy (z.B. Charles, mitmproxy) API-Traffic analysieren
  - Prüfe ob Secrets im Traffic sichtbar sind
  - Teste Token-Invalidierung

- [ ] **TestFlight Beta**
  - Lade Beta-Tester ein
  - Sammle Feedback zu Security-Flows
  - Prüfe Crash-Reports in Sentry

## 🚀 Phase 4 - Launch Day

- [ ] **Finale Checks**
  - Alle Secrets in Production rotiert
  - Debug-Logging deaktiviert
  - Sentry auf Production-Mode
  - Backend-URLs auf Production

- [ ] **Monitoring aktivieren**
  - Sentry Alerts konfigurieren
  - App Store Connect Crashes monitoren
  - API Error-Rates überwachen

## 📋 Laufende Wartung (Post-Launch)

- [ ] **Monatlich:**
  - Dependencies auf Updates prüfen
  - Sentry Issues reviewen
  - API-Keys auf Kompromittierung prüfen

- [ ] **Quartalsweise:**
  - Security Audit wiederholen
  - Penetration Testing
  - DSGVO-Compliance review

## 🚨 Im Notfall

**Falls API-Keys kompromittiert wurden:**

1. **SOFORT rotieren:**
   - OpenAI: https://platform.openai.com/api-keys
   - Supabase: https://supabase.com/dashboard (neues Projekt)
   - Sentry: Neues Projekt erstellen

2. **App-Update ausrollen:**
   - Neue Keys in Secrets.xcconfig
   - Build erstellen
   - Über TestFlight testen
   - Expedited Review bei Apple beantragen

3. **Kosten überwachen:**
   - OpenAI Billing Dashboard checken
   - Ungewöhnliche Aktivität melden

## 📞 Security Kontakte

- **OpenAI Support:** https://help.openai.com
- **Supabase Support:** https://supabase.com/support
- **Apple Security:** product-security@apple.com

## 🔗 Ressourcen

- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/security)
