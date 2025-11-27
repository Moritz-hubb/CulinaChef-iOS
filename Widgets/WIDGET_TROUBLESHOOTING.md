# Widget Troubleshooting - Schritt für Schritt

## Problem: Widgets werden nicht angezeigt

Folge diesen Schritten **in dieser Reihenfolge**:

### 1. ✅ Entitlements prüfen

**Widget Entitlements** (`Configs/CulinaChefWidget.entitlements`):
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.moritzserrin.culinachef</string>
</array>
```

**App Entitlements** (`Configs/CulinaChef.entitlements`):
- Muss auch die App Group haben!

**In Xcode prüfen:**
1. Wähle Target "CulinaChefTimerWidget"
2. Gehe zu "Signing & Capabilities"
3. Prüfe, dass "App Groups" sichtbar ist
4. Prüfe, dass `group.com.moritzserrin.culinachef` hinzugefügt ist

### 2. ✅ Widget-Dateien Target Membership prüfen

**WICHTIG:** Widget-Dateien müssen **NUR** im Widget Extension Target sein!

1. Wähle `CulinaChefTimerWidget.swift` im Project Navigator
2. Öffne File Inspector (rechts, ⌘⌥1)
3. Unter "Target Membership":
   - ✅ **NUR** "CulinaChefTimerWidget" aktivieren
   - ❌ "CulinaChef" **MUSS** deaktiviert sein

4. Wiederhole für `CulinaChefTimerWidgetBundle.swift`

### 3. ✅ Widget Extension Target ausführen

1. Wähle Scheme "CulinaChefTimerWidget" (oben links)
2. Wähle einen Simulator (z.B. iPhone 15 Pro)
3. Drücke ⌘R (oder Play)
4. **Warte**, bis der Simulator startet
5. Du solltest eine Widget-Auswahl sehen

### 4. ✅ Clean Build

1. Product → Clean Build Folder (⇧⌘K)
2. Warte, bis Clean abgeschlossen ist
3. Projekt neu generieren: `cd ios && xcodegen generate`
4. Xcode neu öffnen

### 5. ✅ Widget Extension installieren

**Wichtig:** Das Widget Extension Target muss gebaut und installiert sein!

1. Führe das Widget Extension Scheme aus (siehe Schritt 3)
2. Oder: Führe die Haupt-App aus, dann baue das Widget Extension Target:
   - Product → Build For → Running (⌘B)
   - Wähle Target "CulinaChefTimerWidget"

### 6. ✅ Widget zum Home Screen hinzufügen

1. **Zuerst:** Führe die Haupt-App aus und starte einen Timer
2. Gehe zum Home Screen im Simulator (⌘⇧H)
3. Langes Drücken auf leeren Bereich
4. Tippe auf "+" oben links
5. Suche nach "CulinaChef" oder "Koch-Timer"
6. Wenn es nicht erscheint → siehe Schritt 7

### 7. ✅ Simulator zurücksetzen

Falls Widgets immer noch nicht erscheinen:

1. Device → Erase All Content and Settings...
2. Warte, bis Simulator zurückgesetzt ist
3. Wiederhole Schritt 3-6

### 8. ✅ Bundle Identifier prüfen

In Xcode:
1. Wähle Target "CulinaChefTimerWidget"
2. Gehe zu "General"
3. Prüfe Bundle Identifier: `com.moritzserrin.culinachef.widget`
4. Sollte mit `.widget` enden!

### 9. ✅ Widget Extension Point prüfen

In Xcode:
1. Wähle Target "CulinaChefTimerWidget"
2. Gehe zu "Info"
3. Prüfe "NSExtension" → "NSExtensionPointIdentifier"
4. Sollte sein: `com.apple.widgetkit-extension`

### 10. ✅ Logs prüfen

1. Öffne Console in Xcode (⌘⇧Y)
2. Filtere nach "widget" oder "CulinaChefTimerWidget"
3. Führe Widget Extension aus
4. Prüfe auf Fehler

## Häufige Fehler:

**Fehler:** "No such module 'WidgetKit'"
- **Lösung:** Widget-Dateien sind im falschen Target. Siehe Schritt 2.

**Fehler:** "Widget not found"
- **Lösung:** Widget Extension Target wurde nicht gebaut/installiert. Siehe Schritt 5.

**Fehler:** "App Group not found"
- **Lösung:** Entitlements fehlen. Siehe Schritt 1.

**Fehler:** Widget erscheint, zeigt aber "Keine aktiven Timer"
- **Lösung:** Das ist normal! Starte einen Timer in der App, dann aktualisiert sich das Widget.

## Debug-Tipp:

Führe diesen Befehl im Terminal aus, um zu prüfen, ob das Widget installiert ist:

```bash
xcrun simctl listapps booted | grep -i widget
```

Du solltest `com.moritzserrin.culinachef.widget` sehen.

