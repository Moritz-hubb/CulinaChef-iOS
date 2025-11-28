# Widget Extension Scheme - Executable Einstellung

## ✅ Für Widget Extensions: Executable leer lassen!

**WICHTIG:** Widget Extensions haben kein direktes Executable, das man starten kann. Sie werden vom System geladen.

## In Xcode Scheme Settings:

1. **Wähle Scheme "CulinaChefTimerWidget"**
2. **Product → Scheme → Edit Scheme...** (oder ⌘<)
3. **Wähle "Run"** (links)
4. **Unter "Executable":**
   - ✅ **"Ask on Launch"** wählen
   - Oder: **Leer lassen** (kein Executable)
   - ❌ **NICHT** "CulinaChefTimerWidget.appex" wählen

## Warum?

Widget Extensions sind keine Apps, die man direkt starten kann. Sie werden:
- Vom System geladen, wenn ein Widget angezeigt wird
- Automatisch gestartet, wenn Widgets aktualisiert werden
- Nicht direkt ausführbar wie normale Apps

## Aktuelle Konfiguration in project.yml:

```yaml
scheme:
  runAction:
    executable: ""
    askForAppToLaunch: false
```

Das ist korrekt! `executable: ""` bedeutet, dass kein Executable gesetzt ist.

## Was passiert beim Ausführen?

Wenn du das Widget Extension Scheme ausführst:
1. Xcode baut das Widget Extension Target
2. Installiert es im Simulator
3. **Aber:** Es startet keine App (weil es keine ist)
4. Du musst das Widget manuell zum Home Screen hinzufügen

## Alternative: Widget Extension Preview

Für die Entwicklung kannst du auch:
1. **Widget Preview in Xcode** verwenden
2. Öffne `CulinaChefTimerWidget.swift`
3. Klicke auf "Resume" im Canvas (rechts)
4. Oder drücke ⌘⌥↩ (Option + Command + Return)

Das zeigt eine Vorschau des Widgets ohne es installieren zu müssen.

## Zusammenfassung:

**Executable:** Leer lassen oder "Ask on Launch"
**NICHT:** Ein spezifisches Executable wählen
**Grund:** Widget Extensions werden vom System geladen, nicht direkt ausgeführt


