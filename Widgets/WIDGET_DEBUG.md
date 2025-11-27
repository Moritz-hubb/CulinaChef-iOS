# Widget wird nicht geladen - Debug Guide

## Problem: Widget zeigt nichts oder "Keine aktiven Timer"

Folge diesen Schritten **in dieser Reihenfolge**:

## 1. ✅ Widget-Dateien Target Membership prüfen (KRITISCH!)

**Die Widget-Dateien MÜSSEN aus dem Haupt-Target entfernt werden!**

1. Öffne Xcode
2. Wähle `CulinaChefTimerWidget.swift` im Project Navigator
3. Öffne File Inspector (rechts, ⌘⌥1)
4. Unter "Target Membership":
   - ✅ **NUR** "CulinaChefTimerWidget" aktivieren
   - ❌ "CulinaChef" **MUSS** deaktiviert sein

5. Wiederhole für `CulinaChefTimerWidgetBundle.swift`

**WICHTIG:** Wenn die Widget-Dateien im Haupt-Target sind, kann das Widget nicht korrekt gebaut werden!

## 2. ✅ App Groups prüfen

**Beide Targets müssen die App Group haben:**

1. Wähle Target "CulinaChef"
2. Signing & Capabilities → App Groups
3. Prüfe: `group.com.moritzserrin.culinachef` ist aktiviert

4. Wähle Target "CulinaChefTimerWidget"
5. Signing & Capabilities → App Groups
6. Prüfe: `group.com.moritzserrin.culinachef` ist aktiviert

**Beide müssen die GLEICHE App Group ID haben!**

## 3. ✅ Timer in der App starten

**Das Widget braucht Daten von der App:**

1. Führe die Haupt-App aus (Scheme "CulinaChef")
2. Öffne ein Rezept
3. Starte einen Timer
4. **Warte 2-3 Sekunden** (damit Daten gespeichert werden)
5. Gehe zum Home Screen (⌘⇧H)

## 4. ✅ Widget zum Home Screen hinzufügen

1. Langes Drücken auf Home Screen
2. Tippe auf "+"
3. Suche nach "CulinaChef" oder "Koch-Timer"
4. Widget hinzufügen

## 5. ✅ Widget aktualisieren

1. Langes Drücken auf das Widget
2. Tippe "Widget aktualisieren"
3. Oder: Widget entfernen und neu hinzufügen

## 6. ✅ Debug: Prüfe ob Daten gespeichert werden

**Im Terminal (während Simulator läuft):**

```bash
# Prüfe ob App Group existiert
xcrun simctl get_app_container booted com.moritzserrin.culinachef group.com.moritzserrin.culinachef

# Prüfe UserDefaults in App Group
xcrun simctl spawn booted defaults read group.com.moritzserrin.culinachef active_timers
```

**Oder in Xcode:**

1. Führe die App aus
2. Starte einen Timer
3. Setze einen Breakpoint in `TimerCenter.saveTimers()`
4. Prüfe, ob `saveTimers()` aufgerufen wird
5. Prüfe, ob `appGroupDefaults` nicht `nil` ist

## 7. ✅ Debug: Prüfe Widget-Logs

1. Führe das Widget Extension Scheme aus
2. Öffne Console (⌘⇧Y)
3. Filtere nach "widget" oder "TimerProvider"
4. Prüfe auf Fehler

**Oder füge Debug-Logs hinzu:**

In `CulinaChefTimerWidget.swift`, `loadTimers()` Funktion:

```swift
private func loadTimers() -> [TimerInfo] {
    let appGroupID = "group.com.moritzserrin.culinachef"
    guard let defaults = UserDefaults(suiteName: appGroupID) else {
        print("❌ [Widget] App Group UserDefaults nicht gefunden!")
        return []
    }
    
    guard let timerData = defaults.array(forKey: "active_timers") as? [[String: Any]] else {
        print("⚠️ [Widget] Keine Timer-Daten gefunden")
        return []
    }
    
    print("✅ [Widget] \(timerData.count) Timer gefunden")
    // ... rest of code
}
```

## 8. ✅ Clean Build

1. Product → Clean Build Folder (⇧⌘K)
2. Schließe Xcode
3. Führe aus: `cd ios && xcodegen generate`
4. Öffne Xcode neu
5. Baue beide Targets:
   - Haupt-App (⌘B)
   - Widget Extension (⌘B)

## 9. ✅ Simulator zurücksetzen

Falls nichts hilft:

1. Device → Erase All Content and Settings...
2. Warte, bis Simulator zurückgesetzt ist
3. Führe beide Targets aus:
   - Haupt-App (starte Timer)
   - Widget Extension
4. Gehe zum Home Screen
5. Füge Widget hinzu

## 10. ✅ Prüfe Build-Logs

1. Öffne Report Navigator (⌘9)
2. Führe Widget Extension Scheme aus
3. Prüfe Build-Logs auf Fehler:
   - "No such module 'WidgetKit'"
   - Code Signing Fehler
   - App Group Fehler

## Häufige Fehler:

### Fehler: Widget zeigt "Keine aktiven Timer"

**Mögliche Ursachen:**
- Timer wurde nicht gestartet
- `saveTimers()` wird nicht aufgerufen
- App Group funktioniert nicht
- Widget liest aus falscher App Group

**Lösung:**
1. Starte Timer in der App
2. Warte 2-3 Sekunden
3. Prüfe, ob `saveTimers()` aufgerufen wird
4. Prüfe App Group Konfiguration

### Fehler: Widget baut nicht

**Mögliche Ursachen:**
- Widget-Dateien sind im falschen Target
- Code Signing Fehler
- Info.plist Fehler

**Lösung:**
1. Prüfe Target Membership (Schritt 1)
2. Prüfe Build-Logs
3. Clean Build

### Fehler: "No such module 'WidgetKit'"

**Mögliche Ursachen:**
- Widget-Dateien sind im Haupt-Target
- Widget Extension Target ist nicht korrekt konfiguriert

**Lösung:**
1. Entferne Widget-Dateien aus Haupt-Target (Schritt 1)
2. Prüfe, dass Widget Extension Target existiert

## Debug-Checkliste:

- [ ] Widget-Dateien nur im Widget Extension Target
- [ ] App Groups in beiden Targets aktiviert
- [ ] Timer in der App gestartet
- [ ] 2-3 Sekunden gewartet
- [ ] Widget zum Home Screen hinzugefügt
- [ ] Widget aktualisiert
- [ ] Build-Logs ohne Fehler
- [ ] App Group UserDefaults existiert
- [ ] Timer-Daten werden gespeichert

## Test-Befehl:

Führe diesen Befehl aus, um zu prüfen, ob das Widget installiert ist:

```bash
xcrun simctl listapps booted | grep -i widget
```

Du solltest `com.moritzserrin.culinachef.widget` sehen.

## Nächste Schritte:

Wenn das Widget immer noch nicht funktioniert:

1. **Füge Debug-Logs hinzu** (siehe Schritt 7)
2. **Prüfe die Konsole** auf Fehler
3. **Teile die Fehlermeldungen** mit mir

