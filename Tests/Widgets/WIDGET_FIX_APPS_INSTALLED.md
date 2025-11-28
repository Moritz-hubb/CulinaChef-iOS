# Widget erscheint nicht - aber beide Apps sind installiert

## ✅ GUT: Beide Apps sind installiert!

Dein Terminal-Output zeigt:
- ✅ `com.moritzserrin.culinachef` (Haupt-App) - installiert
- ✅ `com.moritzserrin.culinachef.widget` (Widget Extension) - installiert
- ✅ Beide haben die App Group: `group.com.moritzserrin.culinachef`
- ✅ Beide zeigen auf die gleiche App Group

**Das ist perfekt!** Die Installation ist korrekt.

## Problem: Widget erscheint nicht in der Auswahl

Wenn beide Apps installiert sind, aber das Widget nicht erscheint, probiere folgendes:

### Lösung 1: Simulator neu starten

1. **Simulator schließen** (⌘Q)
2. **Xcode:** Product → Destination → Wähle Simulator neu
3. **Beide Targets erneut ausführen:**
   - Zuerst Widget Extension (Scheme "CulinaChefTimerWidget")
   - Dann Haupt-App (Scheme "CulinaChef")
4. **Gehe zum Home Screen** (⌘⇧H)
5. **Versuche erneut**, Widget hinzuzufügen

### Lösung 2: Widget-Auswahl aktualisieren

1. **Gehe zum Home Screen** (⌘⇧H)
2. **Langes Drücken** auf leeren Bereich
3. **Tippe auf "+"** oben links
4. **Scrolle nach oben/unten** in der Widget-Auswahl
5. **Suche nach "CulinaChef"** (nicht "Koch-Timer")
6. **Warte ein paar Sekunden** - manchmal braucht die Liste Zeit zum Laden

### Lösung 3: Haupt-App zuerst starten

**Reihenfolge ist wichtig:**

1. **Zuerst:** Haupt-App ausführen (Scheme "CulinaChef")
2. **Warte**, bis App vollständig gestartet ist
3. **Dann:** Widget Extension ausführen (Scheme "CulinaChefTimerWidget")
4. **Gehe zum Home Screen**
5. **Versuche**, Widget hinzuzufügen

### Lösung 4: Widget Extension Target prüfen

1. Wähle Target "CulinaChefTimerWidget" in Xcode
2. Gehe zu "Info"
3. Prüfe:
   - **NSExtensionPointIdentifier:** `com.apple.widgetkit-extension`
   - **CFBundleDisplayName:** "Koch-Timer"

**Wenn das fehlt:**
- Projekt neu generieren: `cd ios && xcodegen generate`
- Xcode neu öffnen

### Lösung 5: Simulator komplett zurücksetzen

**Wenn nichts hilft:**

1. **Simulator:** Device → Erase All Content and Settings...
2. **Warte**, bis Reset abgeschlossen ist
3. **Beide Targets erneut ausführen:**
   - Widget Extension zuerst
   - Dann Haupt-App
4. **Gehe zum Home Screen**
5. **Versuche**, Widget hinzuzufügen

### Lösung 6: Widget Extension Scheme prüfen

1. **Wähle Scheme "CulinaChefTimerWidget"**
2. **Product → Scheme → Edit Scheme...**
3. **Wähle "Run"** (links)
4. **Prüfe "Executable":**
   - Sollte sein: `CulinaChefTimerWidget.appex`
   - Oder: Automatisch ausgewählt

5. **Prüfe "Info" Tab:**
   - **Build Configuration:** Debug
   - **Launch:** Automatically

### Lösung 7: Build-Logs prüfen

1. **Öffne Report Navigator** (⌘9)
2. **Führe Widget Extension Scheme aus**
3. **Prüfe Build-Logs** auf Warnungen:
   - "Widget Extension may not be properly configured"
   - Info.plist Warnungen
   - Code Signing Warnungen

**Wenn Warnungen vorhanden:**
- Prüfe Widget Extension Target Konfiguration
- Prüfe Info.plist Einstellungen

## Debug: Widget Extension prüfen

**Im Terminal (während Simulator läuft):**

```bash
# Prüfe Widget Extensions
xcrun simctl listapps booted | grep -i widget

# Prüfe alle Extensions
xcrun simctl listapps booted | grep -i extension
```

**Erwartetes Ergebnis:**
- `com.moritzserrin.culinachef.widget` sollte erscheinen

## Häufigste Ursache wenn Apps installiert sind:

### Widget-Auswahl wurde nicht aktualisiert

**Lösung:**
1. Simulator neu starten
2. Beide Apps erneut ausführen
3. Widget-Auswahl erneut öffnen
4. Nach "CulinaChef" suchen (nicht "Koch-Timer")

### Widget Extension wurde nicht korrekt registriert

**Lösung:**
1. Widget Extension Target prüfen (Lösung 4)
2. Info.plist Einstellungen prüfen
3. Projekt neu generieren

## Test: Widget manuell prüfen

**Im Terminal:**

```bash
# Prüfe ob Widget Extension korrekt installiert ist
xcrun simctl get_app_container booted com.moritzserrin.culinachef.widget
```

**Wenn Fehler:**
- Widget Extension wurde nicht korrekt installiert
- Wiederhole Installation

## Zusammenfassung:

✅ **Beide Apps sind installiert** - das ist gut!
✅ **App Group ist korrekt** - das ist gut!

**Wenn Widget nicht erscheint:**
1. Simulator neu starten
2. Beide Apps erneut ausführen
3. Widget-Auswahl erneut öffnen
4. Nach "CulinaChef" suchen

**Meistens hilft:** Simulator neu starten + beide Apps erneut ausführen

