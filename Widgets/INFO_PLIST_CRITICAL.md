# ⚠️ KRITISCH: Info.plist NSExtension-Konfiguration

## WICHTIG: Diese Konfiguration darf NIEMALS entfernt werden!

Die `NSExtension`-Sektion in `Widgets/Info.plist` ist **absolut erforderlich** für Widget Extensions.

## Was passiert, wenn sie entfernt wird?

- ❌ Fehler: "extensionDictionary must be set in placeholder attributes"
- ❌ App kann nicht installiert werden
- ❌ Widget Extension wird nicht erkannt

## Die erforderliche Konfiguration:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>WidgetKind</key>
        <string>CulinaChefTimerWidget</string>
    </dict>
</dict>
```

## Warum wird sie entfernt?

Mögliche Ursachen:
1. **Manuelles Bearbeiten in Xcode** - Die Info.plist wird in Xcode geöffnet und die Sektion wird versehentlich gelöscht
2. **Git-Merge-Konflikte** - Bei Git-Merges kann die Konfiguration verloren gehen
3. **XcodeGen** - Sollte die Datei nicht überschreiben, da `info: path:` verwendet wird

## Lösung:

### Falls die Konfiguration fehlt:

1. Öffne `ios/Widgets/Info.plist` in einem Text-Editor
2. Füge die NSExtension-Konfiguration vor dem schließenden `</dict>` hinzu
3. Speichere die Datei
4. Führe `cd ios && xcodegen generate` aus
5. Xcode neu öffnen

### Schutz vor versehentlichem Entfernen:

1. **NICHT** die Info.plist in Xcode öffnen und manuell bearbeiten
2. Wenn du die Info.plist bearbeiten musst, verwende einen Text-Editor
3. **IMMER** prüfen, ob die NSExtension-Konfiguration vorhanden ist, bevor du committest

## Prüfen ob Konfiguration vorhanden ist:

```bash
grep -A 10 "NSExtension" ios/Widgets/Info.plist
```

Sollte die NSExtension-Konfiguration zeigen.

## Zusammenfassung:

✅ **NSExtension-Konfiguration MUSS vorhanden sein**
❌ **NIEMALS manuell entfernen**
⚠️ **Immer prüfen vor Git-Commit**

