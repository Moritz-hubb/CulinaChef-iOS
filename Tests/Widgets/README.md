# Timer Widget Setup

## Xcode Setup

Um das Widget zu aktivieren, musst du in Xcode:

1. **Widget Extension Target hinzufügen:**
   - File → New → Target
   - "Widget Extension" auswählen
   - Name: "CulinaChefTimerWidget"
   - Language: Swift
   - Include Configuration Intent: Nein

2. **App Group konfigurieren:**
   - In den Entitlements beider Targets (App + Widget) die App Group aktivieren:
     - `group.com.moritzserrin.culinachef`
   - In Xcode: Signing & Capabilities → App Groups hinzufügen

3. **Widget-Dateien zum Target hinzufügen:**
   - `CulinaChefTimerWidget.swift` → Widget Extension Target
   - `CulinaChefTimerWidgetBundle.swift` → Widget Extension Target

4. **Info.plist für Widget:**
   - Im Widget Target die App Group ID in Info.plist eintragen (falls nötig)

## Funktionalität

- Timer laufen im Hintergrund weiter
- Widget zeigt aktive Timer auf dem Home Screen
- Aktualisiert sich jede Minute
- Benachrichtigungen bei Timer-Ablauf

