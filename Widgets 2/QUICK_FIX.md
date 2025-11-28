# Widget wird nicht angezeigt - Schnell-Fix

## Schritt 1: Widget Extension Target ausführen (WICHTIG!)

**Das Widget Extension Target MUSS zuerst ausgeführt werden, damit es installiert wird!**

1. Öffne Xcode
2. **Wähle oben links das Scheme "CulinaChefTimerWidget"** (nicht "CulinaChef"!)
3. Wähle einen Simulator (z.B. iPhone 15 Pro)
4. Drücke ⌘R (oder Play-Button)
5. **Warte**, bis der Simulator startet
6. Du solltest eine Widget-Auswahl sehen (Small, Medium, Large)

**WICHTIG:** Wenn du nur die Haupt-App ausführst, wird das Widget Extension nicht installiert!

## Schritt 2: Widget-Dateien Target Membership prüfen

Die Widget-Dateien müssen **NUR** im Widget Extension Target sein:

1. Wähle `CulinaChefTimerWidget.swift` im Project Navigator
2. Öffne File Inspector (rechts, ⌘⌥1)
3. Unter "Target Membership":
   - ✅ "CulinaChefTimerWidget" aktivieren
   - ❌ "CulinaChef" **DEAKTIVIEREN** (wenn aktiviert)

4. Wiederhole für `CulinaChefTimerWidgetBundle.swift`

## Schritt 3: Clean Build

1. Product → Clean Build Folder (⇧⌘K)
2. Warte, bis Clean abgeschlossen ist

## Schritt 4: Widget Extension erneut ausführen

1. Wähle Scheme "CulinaChefTimerWidget"
2. Drücke ⌘R
3. Warte, bis Widget-Auswahl erscheint

## Schritt 5: Widget zum Home Screen hinzufügen

1. **Zuerst:** Führe die Haupt-App aus und starte einen Timer
2. Gehe zum Home Screen (⌘⇧H)
3. Langes Drücken auf leeren Bereich
4. Tippe auf "+" oben links
5. Suche nach "CulinaChef" oder "Koch-Timer"
6. Wähle Widget-Größe
7. Tippe "Widget hinzufügen"

## Häufigster Fehler:

**Du führst nur die Haupt-App aus, aber nicht das Widget Extension Target!**

Das Widget Extension Target muss separat ausgeführt werden, damit es installiert wird.

## Debug-Check:

Führe diesen Befehl im Terminal aus, während der Simulator läuft:

```bash
xcrun simctl listapps booted | grep -i culinachef
```

Du solltest beide sehen:
- `com.moritzserrin.culinachef` (Haupt-App)
- `com.moritzserrin.culinachef.widget` (Widget Extension)

Wenn `com.moritzserrin.culinachef.widget` fehlt, wurde das Widget Extension nicht installiert!

