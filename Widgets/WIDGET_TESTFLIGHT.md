# Widgets in TestFlight - Checkliste

## ✅ Ja, Widgets funktionieren in TestFlight!

Aber es gibt einige wichtige Punkte, die beachtet werden müssen:

## Wichtige Voraussetzungen:

### 1. Beide Targets müssen hochgeladen werden

**WICHTIG:** Beim Upload zu App Store Connect müssen **beide Targets** enthalten sein:
- ✅ Haupt-App (`CulinaChef`)
- ✅ Widget Extension (`CulinaChefTimerWidget`)

Xcode sollte beide automatisch beim Archive/Upload mitnehmen, aber prüfe es!

### 2. App Groups in beiden Targets

**Beide Targets müssen die App Group haben:**

**Haupt-App (`CulinaChef`):**
- Entitlements: `Configs/CulinaChef.entitlements`
- App Group: `group.com.moritzserrin.culinachef`

**Widget Extension (`CulinaChefTimerWidget`):**
- Entitlements: `Configs/CulinaChefWidget.entitlements`
- App Group: `group.com.moritzserrin.culinachef`

**In Xcode prüfen:**
1. Wähle Target "CulinaChef"
2. Signing & Capabilities → App Groups
3. Prüfe: `group.com.moritzserrin.culinachef` ist aktiviert

4. Wähle Target "CulinaChefTimerWidget"
5. Signing & Capabilities → App Groups
6. Prüfe: `group.com.moritzserrin.culinachef` ist aktiviert

### 3. Code Signing

**Beide Targets müssen korrekt signiert sein:**

1. Wähle beide Targets
2. Gehe zu "Signing & Capabilities"
3. Prüfe, dass "Automatically manage signing" aktiviert ist
4. Oder: Stelle sicher, dass beide Targets das gleiche Team/Profil verwenden

### 4. Archive erstellen

**Beim Archive werden beide Targets automatisch mitgenommen:**

1. Product → Archive
2. Warte, bis Archive erstellt ist
3. Klicke "Distribute App"
4. Wähle "App Store Connect"
5. Prüfe im Upload-Dialog, dass beide Targets enthalten sind:
   - `CulinaChef.app`
   - `CulinaChefTimerWidget.appex`

### 5. TestFlight Upload prüfen

**Nach dem Upload zu App Store Connect:**

1. Gehe zu App Store Connect
2. Wähle deine App
3. Gehe zu TestFlight
4. Prüfe die Build-Details
5. Du solltest sehen:
   - Haupt-App
   - Widget Extension (als separate Komponente)

## Testen in TestFlight:

### 1. App installieren

1. Installiere die App aus TestFlight
2. Starte einen Timer in der App
3. Die Timer-Daten werden in der App Group gespeichert

### 2. Widget zum Home Screen hinzufügen

1. Gehe zum Home Screen
2. Langes Drücken → "+"
3. Suche nach "CulinaChef" oder "Koch-Timer"
4. Widget hinzufügen
5. Das Widget sollte die Timer aus der App anzeigen

## Häufige Probleme in TestFlight:

### Problem: Widget erscheint nicht in der Auswahl

**Mögliche Ursachen:**
- Widget Extension wurde nicht hochgeladen
- App Groups nicht korrekt konfiguriert
- Code Signing Fehler

**Lösung:**
1. Prüfe Archive-Details (beide Targets enthalten?)
2. Prüfe App Store Connect Build-Details
3. Prüfe Entitlements in beiden Targets

### Problem: Widget zeigt "Keine aktiven Timer"

**Mögliche Ursachen:**
- App Group nicht korrekt konfiguriert
- Timer-Daten werden nicht gespeichert

**Lösung:**
1. Prüfe, dass beide Targets die App Group haben
2. Starte einen Timer in der App
3. Warte ein paar Sekunden
4. Widget sollte sich aktualisieren

### Problem: Widget aktualisiert sich nicht

**Mögliche Ursachen:**
- App Group funktioniert nicht
- Timer-Daten werden nicht geteilt

**Lösung:**
1. Prüfe App Group Konfiguration
2. Stelle sicher, dass beide Targets die gleiche App Group ID haben
3. Teste lokal im Simulator zuerst

## Wichtig für Production:

### App Store Connect Konfiguration:

1. **App Information:**
   - Widget Extension wird automatisch als Teil der App behandelt
   - Keine separate Konfiguration nötig

2. **TestFlight:**
   - Widget Extension wird automatisch mit der App verteilt
   - Tester können Widgets normal verwenden

3. **App Store Review:**
   - Widgets werden automatisch mit der App überprüft
   - Keine separate Review nötig

## Checkliste vor TestFlight Upload:

- [ ] Beide Targets haben App Groups konfiguriert
- [ ] Beide Targets sind korrekt signiert
- [ ] Archive enthält beide Targets (`.app` + `.appex`)
- [ ] Upload zu App Store Connect erfolgreich
- [ ] Build-Details zeigen beide Komponenten
- [ ] Lokal im Simulator getestet

## Debug in TestFlight:

Falls Widgets nicht funktionieren:

1. **Prüfe Build-Details in App Store Connect:**
   - Sind beide Targets enthalten?
   - Gibt es Fehler/Warnungen?

2. **Teste lokal zuerst:**
   - Widgets müssen lokal funktionieren
   - Dann funktionieren sie auch in TestFlight

3. **Prüfe Logs:**
   - TestFlight Tester können Logs senden
   - Prüfe auf App Group Fehler

## Zusammenfassung:

✅ **Widgets funktionieren in TestFlight!**

**Voraussetzungen:**
- Beide Targets hochgeladen
- App Groups in beiden Targets
- Korrektes Code Signing
- Lokal getestet

**Nach dem Upload:**
- Widgets sind automatisch verfügbar
- Tester können sie normal verwenden
- Keine zusätzliche Konfiguration nötig

