# Widget erscheint nicht in der Auswahl - Komplette Lösung

## Problem: Widget wird nicht in der Widget-Auswahl angezeigt

Folge diesen Schritten **in dieser exakten Reihenfolge**:

## Schritt 1: Prüfe ob beide Apps installiert sind

**Im Terminal (während Simulator läuft):**

```bash
xcrun simctl listapps booted | grep -i culinachef
```

**Du solltest beide sehen:**
- `com.moritzserrin.culinachef` (Haupt-App)
- `com.moritzserrin.culinachef.widget` (Widget Extension)

**Wenn `.widget` fehlt:**
- Widget Extension wurde nicht installiert
- Gehe zu Schritt 2

## Schritt 2: Widget Extension Target ausführen

**WICHTIG:** Das Widget Extension Target MUSS separat ausgeführt werden!

1. Öffne Xcode
2. **Wähle Scheme "CulinaChefTimerWidget"** (oben links, NICHT "CulinaChef"!)
3. Wähle einen Simulator
4. Drücke ⌘R (oder Play)
5. **Warte**, bis der Simulator startet
6. Prüfe Terminal-Befehl erneut (Schritt 1)

**Wenn Widget Extension nicht startet:**
- Prüfe Build-Logs auf Fehler
- Gehe zu Schritt 3

## Schritt 3: Widget-Dateien Target Membership prüfen (KRITISCH!)

**Die Widget-Dateien MÜSSEN aus dem Haupt-Target entfernt werden!**

1. Wähle `CulinaChefTimerWidget.swift` im Project Navigator
2. Öffne File Inspector (rechts, ⌘⌥1)
3. Unter "Target Membership":
   - ✅ **NUR** "CulinaChefTimerWidget" aktivieren
   - ❌ "CulinaChef" **MUSS** deaktiviert sein (wenn aktiviert)

4. Wiederhole für `CulinaChefTimerWidgetBundle.swift`

**WICHTIG:** Wenn die Widget-Dateien im Haupt-Target sind, funktioniert das Widget Extension nicht!

## Schritt 4: Clean Build

1. Product → Clean Build Folder (⇧⌘K)
2. Warte, bis Clean abgeschlossen ist
3. Schließe Xcode
4. Führe aus: `cd ios && xcodegen generate`
5. Öffne Xcode neu

## Schritt 5: Beide Targets ausführen

**Reihenfolge ist wichtig!**

1. **Zuerst:** Führe Widget Extension aus
   - Scheme "CulinaChefTimerWidget"
   - ⌘R
   - Warte, bis Simulator startet

2. **Dann:** Führe Haupt-App aus
   - Scheme "CulinaChef"
   - ⌘R
   - Warte, bis App startet

3. **Prüfe Terminal-Befehl:**
   ```bash
   xcrun simctl listapps booted | grep -i culinachef
   ```
   Beide sollten jetzt sichtbar sein!

## Schritt 6: Widget zum Home Screen hinzufügen

1. Gehe zum Home Screen (⌘⇧H)
2. Langes Drücken auf leeren Bereich
3. Tippe auf "+" oben links
4. **Suche nach "CulinaChef"** (nicht "Koch-Timer")
5. Widget sollte jetzt erscheinen!

## Schritt 7: Widget Extension Target prüfen

1. Wähle Projekt im Project Navigator
2. Wähle Target "CulinaChefTimerWidget"
3. Gehe zu "General"
4. Prüfe:
   - **Bundle Identifier:** `com.moritzserrin.culinachef.widget`
   - **Display Name:** "Koch-Timer"
   - **Version:** 1.0

5. Gehe zu "Info"
6. Prüfe unter "NSExtension":
   - **NSExtensionPointIdentifier:** `com.apple.widgetkit-extension`

**Wenn das fehlt oder falsch ist:**
- Projekt neu generieren: `cd ios && xcodegen generate`
- Xcode neu öffnen

## Schritt 8: App Groups prüfen

**Beide Targets müssen die App Group haben:**

1. Wähle Target "CulinaChef"
2. Signing & Capabilities → App Groups
3. Prüfe: `group.com.moritzserrin.culinachef` ist aktiviert

4. Wähle Target "CulinaChefTimerWidget"
5. Signing & Capabilities → App Groups
6. Prüfe: `group.com.moritzserrin.culinachef` ist aktiviert

**Wenn App Groups fehlen:**
- Füge sie manuell hinzu
- Oder prüfe Entitlements-Dateien

## Schritt 9: Simulator zurücksetzen

**Wenn nichts hilft:**

1. Device → Erase All Content and Settings...
2. Warte, bis Simulator zurückgesetzt ist
3. Wiederhole Schritt 5 (beide Targets ausführen)
4. Versuche erneut, Widget hinzuzufügen

## Debug: Build-Logs prüfen

1. Öffne Report Navigator (⌘9)
2. Führe Widget Extension Scheme aus
3. Prüfe Build-Logs auf Fehler:
   - "No such module 'WidgetKit'"
   - Code Signing Fehler
   - Info.plist Fehler
   - "Cannot find type 'Widget'"

**Wenn Fehler vorhanden:**
- Widget-Dateien sind im falschen Target (Schritt 3)
- Oder Widget Extension Target ist falsch konfiguriert

## Häufigste Ursachen:

### 1. Widget-Dateien im Haupt-Target (90% der Fälle!)
- **Lösung:** Schritt 3 - Target Membership prüfen

### 2. Widget Extension nicht installiert
- **Lösung:** Schritt 2 - Widget Extension Target ausführen

### 3. Beide Targets nicht installiert
- **Lösung:** Schritt 5 - Beide Targets ausführen

### 4. App Groups fehlen
- **Lösung:** Schritt 8 - App Groups prüfen

## Test-Befehl:

Führe diesen Befehl aus, um zu prüfen, ob alles installiert ist:

```bash
# Prüfe installierte Apps
xcrun simctl listapps booted | grep -i culinachef

# Prüfe Widget Extensions
xcrun simctl listapps booted | grep -i widget
```

**Erwartetes Ergebnis:**
- `com.moritzserrin.culinachef` (Haupt-App)
- `com.moritzserrin.culinachef.widget` (Widget Extension)

## Wenn NICHTS hilft:

1. **Xcode komplett neu starten**
2. **Simulator komplett zurücksetzen**
3. **Projekt neu generieren:** `cd ios && xcodegen generate`
4. **Beide Targets neu ausführen**
5. **Widget-Dateien Target Membership nochmal prüfen**

## Wichtigste Regel:

**Widget-Dateien müssen NUR im Widget Extension Target sein, NIEMALS im Haupt-Target!**

Wenn die Widget-Dateien im Haupt-Target sind, wird das Widget Extension nicht korrekt gebaut und erscheint nicht in der Auswahl.

