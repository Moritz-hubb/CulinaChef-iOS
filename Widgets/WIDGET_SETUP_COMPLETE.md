# Widget Extension Target Setup - WICHTIG!

Das Widget Extension Target wurde zur `project.yml` hinzugefügt. **Du musst jetzt in Xcode folgende Schritte durchführen:**

## 1. Widget-Dateien aus Haupt-Target entfernen

Die Widget-Dateien dürfen **NUR** im Widget Extension Target sein, nicht im Haupt-Target:

1. Öffne Xcode
2. Wähle `CulinaChefTimerWidget.swift` im Project Navigator
3. Öffne den File Inspector (rechts)
4. Unter "Target Membership":
   - ✅ **NUR** "CulinaChefTimerWidget" aktivieren
   - ❌ "CulinaChef" **DEAKTIVIEREN**

5. Wiederhole das für `CulinaChefTimerWidgetBundle.swift`

## 2. Widget Extension Target prüfen

1. Wähle das Projekt im Project Navigator
2. Wähle das Target "CulinaChefTimerWidget"
3. Gehe zu "Signing & Capabilities"
4. Prüfe, dass "App Groups" aktiviert ist mit:
   - `group.com.moritzserrin.culinachef`

## 3. Widget Extension ausführen

1. Wähle oben links das Scheme-Dropdown
2. Wähle "CulinaChefTimerWidget"
3. Wähle einen Simulator
4. Drücke ⌘R (oder Play)

## 4. Widget zum Home Screen hinzufügen

1. Führe zuerst die Haupt-App aus und starte einen Timer
2. Gehe zum Home Screen im Simulator
3. Langes Drücken auf leeren Bereich → "+" oben links
4. Suche nach "CulinaChef" oder "Koch-Timer"
5. Widget hinzufügen

## Falls Widgets immer noch nicht angezeigt werden:

1. **Clean Build Folder:** Product → Clean Build Folder (⇧⌘K)
2. **Projekt neu generieren:** `cd ios && xcodegen generate`
3. **Xcode neu starten**
4. **Simulator zurücksetzen:** Device → Erase All Content and Settings

## Wichtig:

- Widget-Dateien müssen **NUR** im Widget Extension Target sein
- Beide Targets (App + Widget) müssen die App Group haben
- Das Widget Extension Target muss gebaut und installiert sein

