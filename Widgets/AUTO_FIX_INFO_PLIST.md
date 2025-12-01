# Automatische Info.plist Reparatur

## Problem

XcodeGen überschreibt manchmal die `Info.plist` und entfernt dabei die `NSExtension`-Konfiguration, die für Widget Extensions erforderlich ist.

## Lösung

Ein Script wurde erstellt, das die NSExtension-Konfiguration automatisch hinzufügt, falls sie fehlt.

## Verwendung

### Nach jedem `xcodegen generate`:

```bash
cd ios
xcodegen generate
./Widgets/fix_info_plist.sh
```

### Oder als Einzeiler:

```bash
cd ios && xcodegen generate && ./Widgets/fix_info_plist.sh
```

## Was das Script macht

1. Prüft, ob die NSExtension-Konfiguration vorhanden ist
2. Falls nicht, fügt es die erforderliche Konfiguration hinzu:
   - `NSExtensionPointIdentifier`: `com.apple.widgetkit-extension`
   - `NSExtensionAttributes` mit `WidgetKind`: `CulinaChefTimerWidget`

## Automatisierung (Optional)

Du kannst das Script auch in einen Git-Hook einbauen oder als Xcode Build Phase hinzufügen.

### Als Xcode Build Phase:

1. Wähle das Target "CulinaChefTimerWidget"
2. Gehe zu "Build Phases"
3. Klicke "+" → "New Run Script Phase"
4. Füge hinzu:
   ```bash
   "${SRCROOT}/Widgets/fix_info_plist.sh"
   ```
5. Ziehe die Phase nach "Compile Sources"

## Wichtig

Die NSExtension-Konfiguration **MUSS** in der Info.plist vorhanden sein, sonst kann die Widget Extension nicht installiert werden!

