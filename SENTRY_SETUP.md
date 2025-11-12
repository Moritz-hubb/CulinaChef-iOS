# Sentry Crash Reporting Setup

## 🎯 Was ist Sentry?

Sentry ist ein professionelles Error-Tracking und Crash-Reporting Tool für iOS Apps. Es erfasst automatisch:
- Crashes und Exceptions
- Performance-Probleme
- Breadcrumbs (User-Aktionen vor Crash)
- Screenshots beim Crash
- View Hierarchy
- Network Requests

**Kostenlos:** Bis zu 5.000 Events/Monat im kostenlosen Plan

---

## 🚀 Setup-Schritte

### 1. Sentry Account erstellen

1. Gehe zu [sentry.io](https://sentry.io/signup/)
2. Erstelle einen kostenlosen Account
3. Wähle **"iOS"** als Plattform
4. Kopiere deinen **DSN** (sieht aus wie: `https://xxxxx@o123456.ingest.sentry.io/7890123`)

### 2. DSN in Xcode konfigurieren

1. Öffne `ios/Configs/Secrets.xcconfig`
2. Füge deinen DSN hinzu:

```
SENTRY_DSN = https://xxxxx@o123456.ingest.sentry.io/7890123
```

### 3. Xcode Projekt neu generieren

```bash
cd ios
./gen.sh
```

### 4. App starten

Das war's! Sentry ist jetzt aktiv und erfasst automatisch alle Crashes.

---

## 🧪 Testen

### In der App:

1. Öffne **Einstellungen**
2. Gehe zu **Entwickler > Crash Reporting** (nur im Debug-Build sichtbar)
3. **Test-Event senden**: Sendet ein Test-Event an Sentry
4. **Test-Crash auslösen**: Crasht die App absichtlich (⚠️ nur zu Testzwecken!)

### In Sentry Dashboard:

1. Gehe zu [sentry.io](https://sentry.io)
2. Wähle dein Projekt
3. Sieh dir **Issues**, **Performance** und **Releases** an

---

## 📊 Was wird erfasst?

### Automatisch:
- ✅ Crashes (NSException, Signals)
- ✅ Unhandled Errors
- ✅ Performance Metrics (App-Start, Screen-Load)
- ✅ Breadcrumbs (User-Actions, Network, Navigation)
- ✅ Screenshots beim Crash
- ✅ View Hierarchy
- ✅ Device Info (iOS Version, Model, etc.)

### Manuell hinzufügen (optional):

```swift
import Sentry

// Error loggen
SentrySDK.capture(error: someError)

// Message loggen
SentrySDK.capture(message: "Something important happened")

// Custom Event mit Context
SentrySDK.capture(message: "Payment failed") { scope in
    scope.setTag(value: "stripe", key: "payment_method")
    scope.setExtra(value: amount, key: "amount")
    scope.setLevel(.error)
}

// Breadcrumb hinzufügen
let crumb = Breadcrumb()
crumb.message = "User clicked buy button"
crumb.category = "action"
crumb.level = .info
SentrySDK.addBreadcrumb(crumb)

// User setzen
let user = User(userId: "12345")
user.email = "user@example.com"
user.username = "john_doe"
SentrySDK.setUser(user)
```

---

## 🔒 Datenschutz

### Was Sentry NICHT sieht:
- ❌ Keine Passwörter
- ❌ Keine API-Keys
- ❌ Keine sensiblen User-Daten (außer du sendest sie manuell)

### Was Sentry sieht:
- ✅ Stack Traces
- ✅ Device Info
- ✅ Screenshots (können deaktiviert werden)
- ✅ Breadcrumbs (User-Navigation)

### Datenschutz-Einstellungen anpassen:

In `App.swift`:

```swift
SentrySDK.start { options in
    options.dsn = "..."
    
    // Screenshots deaktivieren
    options.attachScreenshot = false
    
    // View Hierarchy deaktivieren
    options.attachViewHierarchy = false
    
    // Sampling Rate reduzieren (nur 50% der Events)
    options.tracesSampleRate = 0.5
}
```

### DSGVO-Konformität:
- Sentry ist DSGVO-konform
- Daten werden in der EU gespeichert (wählbar)
- Data Processing Agreement (DPA) verfügbar
- **In Datenschutzerklärung erwähnen!**

---

## 🎛 Production vs. Debug

### Aktuell:
- Debug: Sentry aktiv mit allen Features
- Production: Sentry aktiv mit allen Features

### Empfohlen für Production:

```swift
SentrySDK.start { options in
    // ...
    
    #if DEBUG
    options.debug = true // Verbose logging
    options.tracesSampleRate = 1.0 // 100% sampling
    #else
    options.debug = false
    options.tracesSampleRate = 0.2 // 20% sampling (spart Quota)
    #endif
}
```

---

## 💰 Kosten

### Free Plan:
- ✅ 5.000 Events/Monat
- ✅ 30 Tage Datenaufbewahrung
- ✅ Unbegrenzte Projekte
- ✅ Performance Monitoring (limitiert)

### Team Plan ($29/Monat):
- ✅ 50.000 Events/Monat
- ✅ 90 Tage Datenaufbewahrung
- ✅ Prioritäts-Support

**Tipp:** 5.000 Events sind für eine kleine App mehr als genug!

---

## 🐛 Troubleshooting

### Sentry empfängt keine Events

1. **DSN prüfen:**
   - Ist `SENTRY_DSN` in `Secrets.xcconfig` gesetzt?
   - Xcode Projekt neu generieren: `cd ios && ./gen.sh`

2. **Debug Mode aktivieren:**
   ```swift
   options.debug = true
   ```
   Dann in Xcode Console prüfen

3. **Test-Event senden:**
   - Settings > Entwickler > Crash Reporting > Test-Event senden
   - Prüfe Sentry Dashboard nach 1-2 Minuten

### App crasht beim Start

- Sentry DSN falsch formatiert?
- Sentry Package nicht korrekt installiert?
- Versuche: `cd ios && xcodegen generate`

---

## 📚 Weitere Ressourcen

- [Sentry iOS Docs](https://docs.sentry.io/platforms/apple/guides/ios/)
- [Performance Monitoring](https://docs.sentry.io/platforms/apple/performance/)
- [Release Health](https://docs.sentry.io/product/releases/health/)
- [Sentry Pricing](https://sentry.io/pricing/)

---

## ✅ Checklist für Launch

- [ ] Sentry Account erstellt
- [ ] DSN in `Secrets.xcconfig` eingetragen
- [ ] Xcode Projekt neu generiert
- [ ] Test-Event erfolgreich gesendet
- [ ] In Datenschutzerklärung erwähnt
- [ ] tracesSampleRate für Production reduziert (optional)
- [ ] Screenshots/View Hierarchy deaktiviert (optional, Datenschutz)
