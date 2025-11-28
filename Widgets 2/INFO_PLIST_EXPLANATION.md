# Info.plist für Widget Extension

## ✅ Keine manuelle Info.plist nötig!

Wir haben `GENERATE_INFOPLIST_FILE = YES` in der `project.yml` gesetzt. Das bedeutet:

- ✅ Xcode generiert die Info.plist **automatisch**
- ✅ Du musst **keine** Info.plist Datei erstellen
- ✅ Alle Einstellungen kommen aus `INFOPLIST_KEY_*` in der `project.yml`

## Aktuelle Konfiguration:

In `project.yml` sind diese Einstellungen:

```yaml
GENERATE_INFOPLIST_FILE: YES
INFOPLIST_KEY_CFBundleDisplayName: "Koch-Timer"
INFOPLIST_KEY_NSHumanReadableCopyright: ""
INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier: com.apple.widgetkit-extension
INFOPLIST_KEY_CFBundlePackageType: XPC!
INFOPLIST_KEY_CFBundleVersion: 1
INFOPLIST_KEY_CFBundleShortVersionString: 1.0
```

Diese werden automatisch in die generierte Info.plist übernommen.

## Falls du doch eine manuelle Info.plist erstellen willst:

### Dateiname:
- `Info.plist` (im Widgets-Ordner)
- Oder: `CulinaChefTimerWidget-Info.plist`

### Pfad:
- `ios/Widgets/Info.plist`

### Inhalt (Beispiel):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Koch-Timer</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
```

### Dann in project.yml ändern:

```yaml
info:
  path: Widgets/Info.plist
```

**Aber:** Das ist **nicht nötig**, da `GENERATE_INFOPLIST_FILE = YES` bereits gesetzt ist!

## Prüfen ob Info.plist generiert wurde:

### In Xcode:

1. Wähle Target "CulinaChefTimerWidget"
2. Gehe zu "Build Settings"
3. Suche nach "Info.plist File"
4. Du solltest sehen: `$(SRCROOT)/Widgets/Info.plist` (generiert)

### Im Build-Ordner:

Nach dem Build findest du die generierte Info.plist in:
```
DerivedData/CulinaChef-.../Build/Products/Debug-iphonesimulator/CulinaChefTimerWidget.appex/Info.plist
```

## Wichtig:

- ✅ **Aktuell:** Keine manuelle Info.plist nötig
- ✅ **Xcode generiert sie automatisch**
- ✅ **Alle Einstellungen kommen aus project.yml**

## Falls Probleme auftreten:

### Problem: "Info.plist not found"

**Lösung:**
1. Prüfe, dass `GENERATE_INFOPLIST_FILE = YES` in project.yml ist
2. Projekt neu generieren: `cd ios && xcodegen generate`
3. Xcode neu öffnen
4. Clean Build (⇧⌘K)

### Problem: "NSExtensionPointIdentifier missing"

**Lösung:**
1. Prüfe, dass `INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier: com.apple.widgetkit-extension` in project.yml ist
2. Projekt neu generieren
3. Clean Build

## Zusammenfassung:

**Du musst keine Info.plist Datei erstellen!**

- ✅ `GENERATE_INFOPLIST_FILE = YES` ist gesetzt
- ✅ Xcode generiert die Info.plist automatisch
- ✅ Alle Einstellungen kommen aus `INFOPLIST_KEY_*` in project.yml
- ✅ Das ist die moderne, empfohlene Methode

Falls du trotzdem eine manuelle Info.plist erstellen willst:
- Name: `Info.plist`
- Pfad: `ios/Widgets/Info.plist`
- Dann `info: path: Widgets/Info.plist` in project.yml hinzufügen

Aber das ist **nicht nötig**!

