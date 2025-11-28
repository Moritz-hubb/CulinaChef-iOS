# Widget im Simulator testen

## Methode 1: Widget Extension direkt ausführen (Empfohlen)

1. **In Xcode:**
   - Öffne das Projekt
   - Wähle oben links das Scheme-Dropdown
   - Wähle "CulinaChefTimerWidget" (oder das Widget Extension Target)
   - Wähle einen Simulator (z.B. iPhone 15 Pro)
   - Drücke ⌘R (oder klicke auf Play)

2. **Im Simulator:**
   - Der Simulator startet automatisch
   - Du siehst eine Widget-Auswahl
   - Wähle die Widget-Größe (Small, Medium, Large)
   - Das Widget wird angezeigt

## Methode 2: Widget zum Home Screen hinzufügen

1. **App zuerst ausführen:**
   - Führe die Haupt-App (CulinaChef) im Simulator aus
   - Starte einen Timer in der App
   - Die App speichert die Timer-Daten in der App Group

2. **Widget hinzufügen:**
   - Im Simulator: Gehe zum Home Screen (⌘⇧H oder Home-Button)
   - Langes Drücken auf einen leeren Bereich
   - Tippe auf das "+" Symbol oben links
   - Suche nach "CulinaChef" oder "Koch-Timer"
   - Wähle die gewünschte Widget-Größe
   - Tippe auf "Widget hinzufügen"

3. **Widget aktualisieren:**
   - Widgets aktualisieren sich automatisch
   - Bei laufenden Timern: alle 10 Sekunden
   - Bei pausierten Timern: alle 60 Sekunden
   - Du kannst auch manuell aktualisieren: Langes Drücken auf Widget → "Widget aktualisieren"

## Methode 3: Widget Preview in Xcode

1. **Preview öffnen:**
   - Öffne `CulinaChefTimerWidget.swift` in Xcode
   - Klicke auf "Resume" im Canvas (rechts)
   - Oder drücke ⌘⌥↩ (Option + Command + Return)

2. **Verschiedene Größen testen:**
   - Im Preview kannst du zwischen Small, Medium und Large wechseln
   - Unten im Preview kannst du verschiedene Timeline-Entries sehen

## Tipps für das Testen:

### Timer-Daten simulieren:
- Starte Timer in der App, bevor du das Widget hinzufügst
- Die Timer-Daten werden über die App Group geteilt
- Das Widget liest automatisch die neuesten Timer-Daten

### Widget aktualisieren erzwingen:
- Im Simulator: Langes Drücken auf Widget → "Widget aktualisieren"
- Oder: Widget entfernen und neu hinzufügen

### Debugging:
- Widget-Logs erscheinen in der Xcode-Konsole
- Prüfe, ob die App Group korrekt konfiguriert ist
- Stelle sicher, dass beide Targets (App + Widget) die App Group haben

## Häufige Probleme:

**Problem:** Widget zeigt "Keine aktiven Timer"
- **Lösung:** Starte zuerst einen Timer in der App, dann füge das Widget hinzu

**Problem:** Widget aktualisiert sich nicht
- **Lösung:** Warte 10-60 Sekunden oder aktualisiere manuell

**Problem:** Widget Extension baut nicht
- **Lösung:** Stelle sicher, dass das Widget Extension Target existiert und korrekt konfiguriert ist

## App Group prüfen:

Beide Targets müssen die App Group haben:
- `group.com.moritzserrin.culinachef`

In Xcode:
1. Wähle das Target (App oder Widget)
2. Gehe zu "Signing & Capabilities"
3. Prüfe, ob "App Groups" aktiviert ist
4. Stelle sicher, dass `group.com.moritzserrin.culinachef` hinzugefügt ist

