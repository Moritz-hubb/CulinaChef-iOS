# Widget Debug Logs - Anleitung

## Debug-Logs wurden hinzugefügt!

Umfassende Logging wurde zu folgenden Bereichen hinzugefügt:

### 1. TimerProvider (Widget Timeline Provider)
- `placeholder()` - Wird aufgerufen für Previews
- `getSnapshot()` - Wird aufgerufen für schnelle Vorschau
- `getTimeline()` - Wird aufgerufen für Widget-Updates
- `loadTimers()` - Lädt Timer aus App Group UserDefaults

### 2. TimerWidgetEntryView (Widget UI)
- `body` - Loggt jedes Rendering mit Timer-Anzahl und Widget-Familie

### 3. CulinaChefTimerWidget (Widget Definition)
- `init()` - Loggt Widget-Initialisierung

### 4. TimerCenter (App-seitig)
- `saveTimers()` - Loggt wenn Timer gespeichert werden

## Logs ansehen:

### Methode 1: Xcode Console

1. **Führe Widget Extension Scheme aus**
2. **Öffne Debug Area** (⇧⌘Y)
3. **Console Tab** öffnen
4. **Filtere nach:** `[Widget]` oder `TimerCenter`

### Methode 2: Console.app (macOS)

1. **Öffne Console.app** (Programme → Dienstprogramme)
2. **Wähle deinen Simulator** (links)
3. **Filtere nach:** `com.moritzserrin.culinachef.widget`
4. **Oder suche nach:** `[Widget]`

### Methode 3: Terminal (log stream)

```bash
# Alle Widget-Logs vom Simulator
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget"'

# Oder alle CulinaChef-Logs
xcrun simctl spawn booted log stream --predicate 'subsystem contains "culinachef"'
```

## Was die Logs zeigen:

### Widget wird geladen:
```
[Widget] CulinaChefTimerWidget initialized with kind: CulinaChefTimerWidget
[Widget] getTimeline() called - context.isPreview: false
[Widget] loadTimers() called, appGroupID: group.com.moritzserrin.culinachef
[Widget] loadTimers() UserDefaults accessed successfully
[Widget] loadTimers() Found 2 timer entries in UserDefaults
[Widget] loadTimers() returning 2 valid timers
[Widget] getTimeline() loaded 2 timers
```

### Timer werden geladen:
```
[Widget] loadTimers() Adding timer: label='Pasta kochen', remaining=420, running=true
[Widget] loadTimers() Adding timer: label='Sauce köcheln', remaining=180, running=true
```

### Widget rendert:
```
[Widget] TimerWidgetEntryView rendering - family: Medium, timers: 2
[Widget] Timer 0: label='Pasta kochen', remaining=420, running=true
[Widget] Timer 1: label='Sauce köcheln', remaining=180, running=true
```

### Timer werden gespeichert (App-seitig):
```
[TimerCenter] saveTimers() saving 2 timers to App Group
[TimerCenter] saveTimers() synchronize result: true, timers: Pasta kochen: 420s (running), Sauce köcheln: 180s (running)
```

## Häufige Probleme erkennen:

### Problem: Keine Timer geladen

**Log zeigt:**
```
[Widget] loadTimers() No timer data found in UserDefaults for key 'active_timers'
```

**Lösung:**
- Timer wurden nicht gespeichert
- App Group nicht korrekt konfiguriert
- Haupt-App hat noch keinen Timer gestartet

### Problem: App Group nicht erreichbar

**Log zeigt:**
```
[Widget] loadTimers() ERROR: Could not access UserDefaults with suiteName: group.com.moritzserrin.culinachef
```

**Lösung:**
- App Group nicht in beiden Targets konfiguriert
- Entitlements fehlen

### Problem: Widget wird nicht aktualisiert

**Log zeigt:**
```
[Widget] getTimeline() loaded 0 timers
```

**Lösung:**
- Timer wurden nicht gespeichert
- App Group funktioniert nicht
- Widget liest aus falscher App Group

## Debug-Befehl für Terminal:

```bash
# Alle Widget-Logs in Echtzeit
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget"' --level debug

# Oder speichere in Datei
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget"' > widget_logs.txt
```

## Zusammenfassung:

✅ **Umfassende Logs hinzugefügt**
✅ **Alle wichtigen Schritte werden geloggt**
✅ **Logs in Xcode Console, Console.app oder Terminal sichtbar**
✅ **Hilft bei der Diagnose von Widget-Problemen**

**Nächste Schritte:**
1. Führe Widget Extension aus
2. Öffne Console (⇧⌘Y in Xcode)
3. Prüfe die Logs
4. Teile die relevanten Log-Zeilen, wenn Probleme auftreten


