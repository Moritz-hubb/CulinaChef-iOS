# StoreKit Subscription Setup - Behoben

## Problem
Die App zeigte "Produkt nicht gefunden" beim Versuch, das Subscription-Produkt zu kaufen.

## Ursache
Das Xcode Scheme hat die StoreKit Configuration Datei nicht geladen, wodurch die Test-Produkte im Simulator/Debug-Modus nicht verfügbar waren.

## Lösung
1. ✅ StoreKit Configuration (`Configs/StoreKit.storekit`) wurde zum Xcode Scheme hinzugefügt
2. ✅ Die Datei enthält das Produkt: `com.moritzserrin.culinachef.unlimited.subscription`

## Test-Schritte
1. **Öffne das Projekt in Xcode**
   ```bash
   open /Users/moritzserrin/CulinaChef/ios/CulinaChef.xcodeproj
   ```

2. **Stelle sicher, dass das Scheme korrekt ist**
   - Product → Scheme → Edit Scheme
   - Run → Options → StoreKit Configuration
   - Es sollte `StoreKit.storekit` ausgewählt sein

3. **Build und Run im Simulator (DEBUG Modus)**
   - Die App nutzt im Debug-Modus eine **simulierte** Subscription (siehe `PaywallView.swift` Zeile 206-213)
   - Kein Apple Developer Account notwendig für Tests

4. **Test der StoreKit Integration (Release/Production)**
   - Zum Testen der echten StoreKit Integration:
     - Build Configuration auf Release setzen
     - Die App lädt dann die Produkte aus der StoreKit Configuration
     - Prüfe die Console auf: `[StoreKit] Failed to load products:` Fehlermeldungen

## StoreKit Configuration Details
- **Product ID**: `com.moritzserrin.culinachef.unlimited.subscription`
- **Bundle ID**: `com.moritzserrin.culinachef`
- **Preis**: €5.99/Monat
- **Intro Offer**: €0.99 (1 Monat gratis)
- **Typ**: Auto-Renewable Subscription

## Für Production (App Store)
Wenn du die App im App Store veröffentlichen willst:

1. **App Store Connect**
   - Gehe zu [App Store Connect](https://appstoreconnect.apple.com)
   - Erstelle das Subscription-Produkt mit derselben Product ID
   - Konfiguriere Preise und Beschreibungen

2. **Testing mit TestFlight**
   - Lade eine TestFlight Build hoch
   - Verwende einen Sandbox Tester Account
   - Teste Käufe ohne echte Zahlungen

3. **Wichtig**: Die `StoreKit.storekit` Datei ist nur für lokale Tests!
   - Production Apps laden Produkte direkt von App Store Connect
   - Die Configuration Datei wird nicht in der App Bundle eingebettet

## Debug Commands
```bash
# Prüfe ob die Datei existiert
ls -la /Users/moritzserrin/CulinaChef/ios/Configs/StoreKit.storekit

# Öffne die StoreKit Configuration in Xcode
open /Users/moritzserrin/CulinaChef/ios/Configs/StoreKit.storekit
```

## Code-Verweise
- **StoreKitManager**: `Sources/Services/StoreKitManager.swift`
- **PaywallView**: `Sources/Views/PaywallView.swift`
- **AppState**: `Sources/Services/AppState.swift` (Zeile 869: `purchaseStoreKit()`)
- **Product Loading**: `AppState.swift` (Zeile 123: `storeKit.loadProducts()`)

## Nächste Schritte
1. Öffne Xcode und starte die App im Simulator
2. Navigiere zur Paywall (z.B. über Settings oder beim Versuch, Premium-Features zu nutzen)
3. Versuche einen Kauf - es sollte jetzt funktionieren!
4. Im Debug-Modus wird der Kauf simuliert (siehe Badge: "🧪 Debug: Simulated purchase")
