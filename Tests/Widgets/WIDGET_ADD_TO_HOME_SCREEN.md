# Widget zum Home Screen hinzufügen

## ✅ GUT: "Koch-Timer" erscheint im Simulator

Das bedeutet, dass das Widget Extension erfolgreich gebaut und installiert wurde!

**WICHTIG:** Die "Koch-Timer" App lässt sich nicht öffnen - das ist normal! Widget Extensions sind keine Apps, die man öffnen kann. Sie werden nur vom System verwendet.

## So fügst du das Widget zum Home Screen hinzu:

### Schritt 1: Haupt-App ausführen und Timer starten

1. Wähle Scheme "CulinaChef" (Haupt-App)
2. Führe die App aus (⌘R)
3. Starte einen Timer in der App
4. Die App speichert die Timer-Daten in der App Group

### Schritt 2: Zum Home Screen gehen

1. Im Simulator: Drücke ⌘⇧H (oder klicke auf den Home-Button)
2. Du bist jetzt auf dem Home Screen

### Schritt 3: Widget hinzufügen

1. **Langes Drücken** auf einen leeren Bereich des Home Screens
2. Die Apps beginnen zu wackeln
3. Tippe auf das **"+"** Symbol oben links (oder oben in der Mitte)
4. Es öffnet sich die Widget-Auswahl

### Schritt 4: Widget finden und hinzufügen

1. In der Widget-Auswahl:
   - Suche nach **"CulinaChef"** oder **"Koch-Timer"**
   - Oder scrolle durch die Liste
2. Wähle das Widget aus
3. Wähle die gewünschte Größe (Small, Medium, Large)
4. Tippe auf **"Widget hinzufügen"**
5. Das Widget erscheint auf dem Home Screen!

### Schritt 5: Widget positionieren

1. Das Widget ist jetzt auf dem Home Screen
2. Du kannst es verschieben (langes Drücken und ziehen)
3. Drücke den Home-Button oder ⌘⇧H, um den Bearbeitungsmodus zu verlassen

## Falls "CulinaChef" oder "Koch-Timer" nicht in der Widget-Auswahl erscheint:

### Lösung 1: Haupt-App zuerst ausführen

Das Widget Extension muss zusammen mit der Haupt-App installiert sein:

1. Führe die Haupt-App aus (Scheme "CulinaChef")
2. Gehe zum Home Screen
3. Versuche erneut, das Widget hinzuzufügen

### Lösung 2: Beide Targets bauen

1. Wähle Scheme "CulinaChef"
2. Product → Build (⌘B)
3. Wähle Scheme "CulinaChefTimerWidget"
4. Product → Build (⌘B)
5. Gehe zum Home Screen und versuche erneut

### Lösung 3: Simulator zurücksetzen

1. Device → Erase All Content and Settings...
2. Warte, bis Simulator zurückgesetzt ist
3. Führe beide Targets aus (App + Widget Extension)
4. Versuche erneut

## Debug: Prüfe ob Widget Extension installiert ist

Im Terminal (während Simulator läuft):

```bash
xcrun simctl listapps booted | grep -i culinachef
```

Du solltest beide sehen:
- `com.moritzserrin.culinachef` (Haupt-App)
- `com.moritzserrin.culinachef.widget` (Widget Extension)

## Wichtig:

- **"Koch-Timer" App lässt sich nicht öffnen** = Das ist normal! ✅
- **Widget zum Home Screen hinzufügen** = Das ist der richtige Weg! ✅
- Widget zeigt automatisch die Timer aus der Haupt-App an

