# Widget Extension Build-Logs prüfen

## Problem: Widget Extension wird nicht gebaut

Wenn du das `CulinaChefTimerWidget` Schema ausführst, wird möglicherweise nur die Haupt-App gebaut, nicht das Widget Extension Target.

## Lösung: Build-Logs prüfen

### Schritt 1: Report Navigator öffnen

1. **Öffne Xcode**
2. **Drücke ⌘9** (Report Navigator)
3. **Wähle das letzte Build** (sollte "CulinaChefTimerWidget" heißen)

### Schritt 2: Build-Logs durchsuchen

**Suche nach diesen Zeilen:**

✅ **GUT - Widget Extension wird gebaut:**
```
Build target CulinaChefTimerWidget of project CulinaChef with configuration Debug
Compiling CulinaChefTimerWidget.swift
Compiling CulinaChefTimerWidgetBundle.swift
...
Ld .../CulinaChefTimerWidget.appex
```

❌ **SCHLECHT - Nur Haupt-App wird gebaut:**
```
Build target CulinaChef of project CulinaChef with configuration Debug
...
(KEINE Zeile mit "CulinaChefTimerWidget")
```

### Schritt 3: Wenn Widget Extension nicht gebaut wird

#### Lösung 1: Schema manuell prüfen

1. **Wähle Scheme "CulinaChefTimerWidget"** (oben links)
2. **Product → Scheme → Edit Scheme...** (oder ⌘<)
3. **Wähle "Build"** (links)
4. **Prüfe, ob "CulinaChefTimerWidget" in der Liste ist:**
   - ✅ Sollte aktiviert sein
   - ✅ Sollte vor "CulinaChef" stehen (oder beide aktiviert)

5. **Falls nicht:**
   - Klicke auf "+" unten
   - Wähle "CulinaChefTimerWidget"
   - Ziehe es nach oben (vor "CulinaChef")

#### Lösung 2: Widget-Dateien Target Membership prüfen

**KRITISCH:** Die Widget-Dateien müssen im Widget Extension Target sein!

1. **Wähle `CulinaChefTimerWidget.swift`** im Project Navigator
2. **Öffne File Inspector** (rechts, ⌘⌥1)
3. **Unter "Target Membership":**
   - ✅ **"CulinaChefTimerWidget"** aktiviert
   - ❌ **"CulinaChef"** DEAKTIVIERT (falls aktiviert)

4. **Wiederhole für `CulinaChefTimerWidgetBundle.swift`**

#### Lösung 3: Widget Extension Target manuell bauen

1. **Wähle das Projekt** im Project Navigator
2. **Wähle das Target "CulinaChefTimerWidget"**
3. **Product → Build** (⌘B)
4. **Prüfe Build-Logs** auf Fehler

#### Lösung 4: Clean Build

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Warte**, bis Clean abgeschlossen ist
3. **Projekt neu generieren:**
   ```bash
   cd ios
   xcodegen generate
   ```
4. **Xcode neu öffnen**
5. **Widget Extension Schema erneut ausführen**

### Schritt 4: Prüfen ob Widget Extension installiert ist

**Nach erfolgreichem Build:**

```bash
xcrun simctl listapps booted | grep -i culinachef
```

**Du solltest beide sehen:**
- ✅ `com.moritzserrin.culinachef` (Haupt-App)
- ✅ `com.moritzserrin.culinachef.widget` (Widget Extension)

## Häufige Build-Fehler

### Fehler 1: "Multiple commands produce Info.plist"

**Lösung:** Info.plist ist bereits ausgeschlossen in `project.yml`:
```yaml
sources:
  - path: Widgets
    excludes:
      - "**/Info.plist"
```

### Fehler 2: "No such module 'WidgetKit'"

**Lösung:** WidgetKit Framework fehlt
1. Wähle Widget Extension Target
2. Build Phases → Link Binary With Libraries
3. Füge "WidgetKit.framework" hinzu (falls fehlt)

### Fehler 3: "Cannot find type 'Widget' in scope"

**Lösung:** Import fehlt
- Prüfe, ob `import WidgetKit` in den Widget-Dateien ist

## Zusammenfassung

✅ **Widget Extension wird gebaut:** Siehst du "Build target CulinaChefTimerWidget" in den Logs?
✅ **Widget Extension installiert:** Erscheint `com.moritzserrin.culinachef.widget` in `listapps`?
✅ **Widget-Dateien im richtigen Target:** Nur "CulinaChefTimerWidget", nicht "CulinaChef"?

Wenn alle drei ✅ sind, sollte das Widget funktionieren!

