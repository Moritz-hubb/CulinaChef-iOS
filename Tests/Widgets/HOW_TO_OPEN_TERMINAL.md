# Terminal in Xcode öffnen

## Option 1: macOS Terminal verwenden (Empfohlen)

**Xcode hat kein integriertes Terminal.** Du musst das normale macOS Terminal verwenden:

### Terminal öffnen:

1. **Spotlight öffnen:** Drücke ⌘Space
2. **"Terminal" eingeben**
3. **Enter drücken**

Oder:

1. **Finder öffnen**
2. **Gehe zu:** Programme → Dienstprogramme
3. **Öffne "Terminal"**

### Terminal-Befehle ausführen:

1. Terminal öffnen
2. Navigiere zum Projekt:
   ```bash
   cd /Users/moritzserrin/CulinaChef/ios
   ```

3. Führe den Befehl aus (während Simulator läuft):
   ```bash
   xcrun simctl listapps booted | grep -i culinachef
   ```

## Option 2: Terminal direkt im Projekt-Ordner öffnen

### Im Finder:

1. Öffne Finder
2. Navigiere zu: `/Users/moritzserrin/CulinaChef/ios`
3. Rechtsklick auf den Ordner
4. Wähle "Neues Terminal-Fenster im Ordner"

### Im Terminal:

1. Terminal öffnen
2. Tippe:
   ```bash
   cd /Users/moritzserrin/CulinaChef/ios
   ```

## Option 3: Xcode Console verwenden (für Logs)

**Für Build-Logs und App-Logs:**

1. In Xcode: View → Debug Area → Show Debug Area (⇧⌘Y)
2. Unten erscheint die Console
3. Hier siehst du Build-Logs und App-Logs

**Aber:** Terminal-Befehle wie `xcrun simctl` funktionieren hier nicht!

## Für Widget-Debugging:

### Terminal-Befehl ausführen:

1. **Terminal öffnen** (siehe Option 1)
2. **Simulator starten** (in Xcode)
3. **Befehl ausführen:**
   ```bash
   xcrun simctl listapps booted | grep -i culinachef
   ```

### Was der Befehl macht:

- `xcrun simctl` - Simulator Control Tool
- `listapps booted` - Liste alle Apps im laufenden Simulator
- `grep -i culinachef` - Filtere nach "culinachef" (case-insensitive)

### Erwartetes Ergebnis:

```
com.moritzserrin.culinachef
com.moritzserrin.culinachef.widget
```

## Tipp: Terminal immer griffbereit

Du kannst Terminal im Dock behalten:
1. Terminal öffnen
2. Rechtsklick auf Terminal-Icon im Dock
3. "Im Dock behalten" wählen

## Zusammenfassung:

- **Xcode hat kein Terminal** - verwende macOS Terminal
- **Terminal öffnen:** ⌘Space → "Terminal"
- **Oder:** Finder → Programme → Dienstprogramme → Terminal
- **Für Logs:** Xcode Console (⇧⌘Y) - aber keine Terminal-Befehle!

