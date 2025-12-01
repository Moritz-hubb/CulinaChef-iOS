# Widget-Daten Debugging

## Problem: Timer und Shopping-List-Items werden nicht im Widget angezeigt

## Lösung: Debug-Logs prüfen

### Schritt 1: App-Logs prüfen (wenn Timer/Shopping-List gespeichert wird)

**In Xcode Console (während App läuft):**

Suche nach:
- `[TimerCenter] saveTimers() VERIFIED` - Bestätigt, dass Timer gespeichert wurden
- `[ShoppingListManager] saveShoppingList() VERIFIED` - Bestätigt, dass Shopping-List gespeichert wurde
- `Widget timeline reload requested` - Bestätigt, dass Widget-Aktualisierung angefordert wurde

**Falls du "ERROR" siehst:**
- `Could not access App Group UserDefaults` → App Group Entitlements fehlen
- `Data not found after saving` → Speichern fehlgeschlagen

### Schritt 2: Widget-Logs prüfen

**Im Terminal (während Simulator läuft):**

```bash
# Timer Widget Logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget" AND category == "TimerProvider"'

# Shopping List Widget Logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.moritzserrin.culinachef.widget" AND category == "ShoppingListProvider"'
```

**Oder in Console.app:**
1. Öffne Console.app
2. Wähle Simulator
3. Suche nach: `[Widget]` oder `[ShoppingListWidget]`

### Schritt 3: Prüfen was die Widgets sehen

**Suche nach diesen Logs:**

✅ **GUT:**
- `[Widget] loadTimers() Found X timer entries in UserDefaults`
- `[ShoppingListWidget] loadShoppingList() loaded X items`
- `[Widget] getTimeline() loaded X timers`

❌ **SCHLECHT:**
- `[Widget] loadTimers() No timer data found in UserDefaults`
- `[Widget] loadTimers() ERROR: Could not access UserDefaults`
- `[ShoppingListWidget] loadShoppingList() No shopping list data found`

### Schritt 4: App Group prüfen

**Im Terminal:**

```bash
# Prüfe ob App Group konfiguriert ist
plutil -p ios/Configs/CulinaChef.entitlements | grep application-groups
plutil -p ios/Configs/CulinaChefWidget.entitlements | grep application-groups
```

**Sollte zeigen:**
```
"com.apple.security.application-groups" => [
    0 => "group.com.moritzserrin.culinachef"
]
```

### Schritt 5: Manuell prüfen ob Daten gespeichert sind

**Im Terminal (während Simulator läuft):**

```bash
# Prüfe Timer-Daten
xcrun simctl spawn booted defaults read group.com.moritzserrin.culinachef active_timers

# Prüfe Shopping-List-Daten
xcrun simctl spawn booted defaults read group.com.moritzserrin.culinachef shopping_list
```

**Falls Fehler:**
- `The domain/default pair of (group.com.moritzserrin.culinachef, active_timers) does not exist` → Daten wurden nicht gespeichert
- `Could not read domain` → App Group Entitlements fehlen

## Häufige Probleme:

### Problem 1: App Group Entitlements fehlen

**Lösung:**
- Prüfe `ios/Configs/CulinaChef.entitlements`
- Prüfe `ios/Configs/CulinaChefWidget.entitlements`
- Beide müssen `com.apple.security.application-groups` mit `group.com.moritzserrin.culinachef` enthalten

### Problem 2: Daten werden nicht gespeichert

**Lösung:**
- Prüfe App-Logs auf Fehler beim Speichern
- Prüfe ob `appGroupDefaults` nicht `nil` ist
- Prüfe ob `synchronize()` erfolgreich ist

### Problem 3: Widget lädt keine Daten

**Lösung:**
- Prüfe Widget-Logs auf Fehler beim Laden
- Prüfe ob `UserDefaults(suiteName:)` nicht `nil` ist
- Prüfe ob die Daten im richtigen Format sind

### Problem 4: Widget aktualisiert sich nicht

**Lösung:**
- Prüfe ob `WidgetCenter.shared.reloadTimelines()` aufgerufen wird
- Widget vom Home Screen entfernen und erneut hinzufügen
- Simulator neu starten

## Test-Prozedur:

1. **Timer starten:**
   - App öffnen
   - Timer in einem Rezept starten
   - Prüfe App-Logs: Sollte "VERIFIED" zeigen
   - Prüfe Widget-Logs: Sollte Timer-Daten laden

2. **Shopping-List-Item hinzufügen:**
   - App öffnen
   - Item zur Einkaufsliste hinzufügen
   - Prüfe App-Logs: Sollte "VERIFIED" zeigen
   - Prüfe Widget-Logs: Sollte Shopping-List-Daten laden

3. **Widget prüfen:**
   - Zum Home Screen wechseln
   - Widget sollte Timer/Items anzeigen
   - Falls nicht: Widget-Logs prüfen

