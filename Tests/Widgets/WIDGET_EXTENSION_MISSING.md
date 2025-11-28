# Widget Extension fehlt - Lösung

## Problem: Widget Extension nicht installiert

**Terminal zeigt:**
- ✅ `com.moritzserrin.culinachef` (Haupt-App) - installiert
- ❌ `com.moritzserrin.culinachef.widget` (Widget Extension) - **FEHLT**

**Das bedeutet:** Das Widget Extension wurde nicht gebaut/installiert.

## Lösung: Widget Extension Scheme ausführen

### Schritt 1: Widget Extension Scheme wählen

1. **Öffne Xcode**
2. **Oben links:** Klicke auf das Scheme-Dropdown (zeigt aktuell "CulinaChef")
3. **Wähle "CulinaChefTimerWidget"** aus der Liste
4. **WICHTIG:** Es muss "CulinaChefTimerWidget" sein, nicht "CulinaChef"!

### Schritt 2: Widget Extension ausführen

1. **Wähle einen Simulator** (z.B. iPhone 15 Pro)
2. **Drücke ⌘R** (oder Play-Button)
3. **Wenn "Choose app to run" erscheint:**
   - Wähle **"CulinaChef"** (Haupt-App)
   - Klicke "Run"
4. **Warte**, bis der Simulator startet

### Schritt 3: Prüfen ob Widget Extension installiert ist

**Im Terminal (während Simulator läuft):**

```bash
xcrun simctl listapps booted | grep -i culinachef
```

**Du solltest jetzt beide sehen:**
- ✅ `com.moritzserrin.culinachef` (Haupt-App)
- ✅ `com.moritzserrin.culinachef.widget` (Widget Extension) ← **JETZT DA!**

## Falls Widget Extension Scheme nicht erscheint:

### Problem: Widget Extension Target fehlt

**Lösung:**
1. Prüfe, ob das Target existiert:
   - Wähle Projekt im Project Navigator
   - Prüfe, ob "CulinaChefTimerWidget" in der Target-Liste ist

2. Falls nicht:
   - Projekt neu generieren: `cd ios && xcodegen generate`
   - Xcode neu öffnen

### Problem: Build-Fehler

**Lösung:**
1. Öffne Report Navigator (⌘9)
2. Führe Widget Extension Scheme aus
3. Prüfe Build-Logs auf Fehler:
   - Info.plist Fehler
   - Code Signing Fehler
   - Missing files

## Nach erfolgreicher Installation:

### Widget zum Home Screen hinzufügen

1. **Gehe zum Home Screen** (⌘⇧H)
2. **Langes Drücken** auf leeren Bereich
3. **Tippe auf "+"** oben links
4. **Suche nach "CulinaChef"** oder "Koch-Timer"
5. **Widget sollte jetzt erscheinen!**

### Widget-Logs ansehen

**In Console.app:**
1. Öffne Console.app
2. Wähle Simulator
3. Suche nach: `culinachef.widget` oder `[Widget]`

**Im Terminal:**
```bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget"'
```

## Häufige Probleme:

### Problem: "Choose app to run" erscheint nicht

**Lösung:**
- Das ist normal für Widget Extensions
- Wähle "CulinaChef" (Haupt-App) aus
- Das Widget Extension wird zusammen mit der App installiert

### Problem: Widget Extension baut nicht

**Lösung:**
1. Product → Clean Build Folder (⇧⌘K)
2. Prüfe Build-Logs auf Fehler
3. Stelle sicher, dass Widget-Dateien im Widget Extension Target sind (nicht im Haupt-Target)

### Problem: Widget Extension installiert, aber Widget erscheint nicht

**Lösung:**
1. Gehe zum Home Screen
2. Versuche, Widget hinzuzufügen
3. Prüfe Widget-Logs auf Fehler

## Zusammenfassung:

❌ **Aktuell:** Widget Extension fehlt
✅ **Lösung:** Widget Extension Scheme ausführen
✅ **Dann:** Beide Apps sollten installiert sein
✅ **Dann:** Widget zum Home Screen hinzufügen

**Wichtigste Regel:** Das Widget Extension Scheme MUSS separat ausgeführt werden, damit es installiert wird!


