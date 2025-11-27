# Widget Extension öffnet App statt Widget-Auswahl - FIX

## Problem:
Wenn du das Widget Extension Scheme ausführst, öffnet sich die App normal statt der Widget-Auswahl.

## Lösung:

### 1. Prüfe Build-Logs

1. Öffne Xcode
2. Wähle Scheme "CulinaChefTimerWidget"
3. Öffne die Report Navigator (⌘9)
4. Führe das Widget Extension Scheme aus (⌘R)
5. Prüfe die Build-Logs auf Fehler

**Suche nach:**
- "No such module 'WidgetKit'"
- "Cannot find type 'Widget' in scope"
- Code Signing Fehler
- Info.plist Fehler

### 2. Widget-Dateien Target Membership (KRITISCH!)

**Die Widget-Dateien MÜSSEN aus dem Haupt-Target entfernt werden!**

1. Wähle `CulinaChefTimerWidget.swift` im Project Navigator
2. Öffne File Inspector (rechts, ⌘⌥1)
3. Unter "Target Membership":
   - ✅ **NUR** "CulinaChefTimerWidget" aktivieren
   - ❌ "CulinaChef" **MUSS** deaktiviert sein (wenn aktiviert)

4. Wiederhole für `CulinaChefTimerWidgetBundle.swift`

**WICHTIG:** Wenn die Widget-Dateien im Haupt-Target sind, wird das Widget Extension nicht korrekt gebaut!

### 3. Widget Extension Target prüfen

1. Wähle das Projekt im Project Navigator
2. Wähle das Target "CulinaChefTimerWidget"
3. Gehe zu "General"
4. Prüfe:
   - **Bundle Identifier:** `com.moritzserrin.culinachef.widget`
   - **Display Name:** "Koch-Timer"
   - **Version:** 1.0
   - **Build:** 1

5. Gehe zu "Info"
6. Prüfe unter "NSExtension":
   - **NSExtensionPointIdentifier:** `com.apple.widgetkit-extension`

### 4. Clean Build

1. Product → Clean Build Folder (⇧⌘K)
2. Warte, bis Clean abgeschlossen ist
3. Schließe Xcode
4. Führe aus: `cd ios && xcodegen generate`
5. Öffne Xcode neu

### 5. Widget Extension erneut ausführen

1. Wähle Scheme "CulinaChefTimerWidget"
2. Wähle einen Simulator
3. Drücke ⌘R
4. **Prüfe die Konsole** auf Fehler

### 6. Alternative: Widget Extension manuell prüfen

Falls die Widget-Auswahl immer noch nicht erscheint:

1. Führe die Haupt-App aus
2. Gehe zum Home Screen
3. Langes Drücken → "+"
4. Suche nach "CulinaChef"
5. Wenn es nicht erscheint, wurde das Widget Extension nicht installiert

### 7. Debug: Prüfe ob Widget Extension installiert ist

Im Terminal (während Simulator läuft):

```bash
xcrun simctl listapps booted | grep -i widget
```

Du solltest `com.moritzserrin.culinachef.widget` sehen.

Wenn nicht:
- Widget Extension wurde nicht gebaut/installiert
- Prüfe Build-Logs auf Fehler
- Stelle sicher, dass Widget-Dateien nur im Widget Extension Target sind

### 8. Häufige Fehler:

**Fehler:** "No such module 'WidgetKit'"
- **Lösung:** Widget-Dateien sind im falschen Target. Siehe Schritt 2.

**Fehler:** Code Signing Fehler
- **Lösung:** Prüfe, dass `GENERATE_INFOPLIST_FILE = YES` gesetzt ist

**Fehler:** Widget Extension baut, aber öffnet App
- **Lösung:** Widget-Dateien sind noch im Haupt-Target. Siehe Schritt 2.

## Wichtigste Regel:

**Widget-Dateien müssen NUR im Widget Extension Target sein, NIEMALS im Haupt-Target!**

