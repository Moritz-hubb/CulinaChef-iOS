# CulinaChef Widget-Logs finden

## Problem: Logs zeigen nur Apple News Widget

Die Console zeigt aktuell nur Logs von `com.apple.news.widget` (Apple News), nicht von unserem Widget.

## Lösung: Widget Extension ausführen

**Unser Widget Extension muss zuerst ausgeführt werden, damit Logs erscheinen!**

### Schritt 1: Widget Extension Scheme ausführen

1. **Öffne Xcode**
2. **Wähle Scheme "CulinaChefTimerWidget"** (oben links)
3. **Wähle einen Simulator**
4. **Drücke ⌘R** (oder Play)
5. **Wenn "Choose app to run" erscheint:** Wähle "CulinaChef" (Haupt-App)

### Schritt 2: Widget-Logs in Console.app finden

1. **Öffne Console.app** (Programme → Dienstprogramme)
2. **Wähle deinen Simulator** (links)
3. **Im Suchfeld oben rechts:** Tippe `culinachef.widget`
4. **Oder:** Tippe `[Widget]`

**Du solltest jetzt unsere Widget-Logs sehen!**

### Schritt 3: Terminal log stream (Alternative)

**Im Terminal (während Simulator läuft):**

```bash
# Nur CulinaChef Widget-Logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget"'

# Oder alle CulinaChef-Logs (App + Widget)
xcrun simctl spawn booted log stream --predicate 'subsystem contains "culinachef"'
```

## Erwartete Logs (wenn Widget läuft):

```
[Widget] CulinaChefTimerWidget initialized with kind: CulinaChefTimerWidget
[Widget] getTimeline() called - context.isPreview: false
[Widget] loadTimers() called, appGroupID: group.com.moritzserrin.culinachef
[Widget] loadTimers() UserDefaults accessed successfully
[Widget] loadTimers() Found X timer entries in UserDefaults
[Widget] TimerWidgetEntryView rendering - family: Medium, timers: X
```

## Wenn keine Logs erscheinen:

### Problem 1: Widget Extension nicht ausgeführt

**Lösung:**
- Führe Widget Extension Scheme aus (siehe Schritt 1)
- Warte, bis Simulator startet
- Prüfe Console.app erneut

### Problem 2: Widget Extension nicht installiert

**Prüfe im Terminal:**
```bash
xcrun simctl listapps booted | grep -i culinachef
```

**Du solltest sehen:**
- `com.moritzserrin.culinachef` (Haupt-App)
- `com.moritzserrin.culinachef.widget` (Widget Extension)

**Wenn `.widget` fehlt:**
- Widget Extension wurde nicht installiert
- Führe Widget Extension Scheme aus

### Problem 3: Widget wurde noch nicht zum Home Screen hinzugefügt

**Lösung:**
1. Gehe zum Home Screen (⌘⇧H)
2. Langes Drücken → "+" → Suche nach "CulinaChef"
3. Widget hinzufügen
4. Widget-Logs sollten jetzt erscheinen

## Debug-Workflow:

1. **Zuerst:** Widget Extension Scheme ausführen
2. **Dann:** Haupt-App ausführen und Timer starten
3. **Dann:** Widget zum Home Screen hinzufügen
4. **Dann:** Console.app öffnen und nach `culinachef.widget` suchen
5. **Oder:** Terminal log stream verwenden

## Zusammenfassung:

❌ **Aktuell:** Nur Apple News Widget-Logs sichtbar
✅ **Lösung:** Widget Extension Scheme ausführen
✅ **Dann:** Logs in Console.app oder Terminal finden

**Wichtig:** Widget-Logs erscheinen nur, wenn das Widget Extension ausgeführt wurde oder das Widget zum Home Screen hinzugefügt wurde!

