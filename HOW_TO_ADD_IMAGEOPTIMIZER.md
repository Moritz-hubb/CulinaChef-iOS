# ImageOptimizer.swift zu Xcode-Projekt hinzufügen

## Problem
Die Datei `ImageOptimizer.swift` existiert im Dateisystem, ist aber nicht im Xcode-Projekt registriert, daher der Fehler: `Cannot find 'ImageOptimizer' in scope`.

## Lösung: Manuell in Xcode hinzufügen

### Schritt 1: Xcode öffnen
Öffne das Projekt in Xcode:
```
/Users/moritzserrin/CulinaChef/ios/CulinaChef.xcodeproj
```

### Schritt 2: Datei zum Projekt hinzufügen
1. **Rechtsklick** auf den Ordner `Sources/Utilities` im Project Navigator (linke Seitenleiste)
2. Wähle **"Add Files to CulinaChef..."**
3. Navigiere zu: `Sources/Utilities/ImageOptimizer.swift`
4. **WICHTIG:** Stelle sicher, dass:
   - ✅ **"Copy items if needed"** ist **NICHT** angehakt (Datei existiert bereits)
   - ✅ **"Add to targets: CulinaChef"** ist **ANGEHAKT**
5. Klicke auf **"Add"**

### Schritt 3: Überprüfen
1. Die Datei sollte jetzt im Project Navigator unter `Sources/Utilities/` sichtbar sein
2. **Clean Build Folder**: `Product` → `Clean Build Folder` (⇧⌘K)
3. **Build**: `Product` → `Build` (⌘B)

### Schritt 4: Fehler sollte verschwunden sein
Der Fehler `Cannot find 'ImageOptimizer' in scope` sollte jetzt behoben sein.

## Alternative: Terminal-Befehl (wenn Xcode nicht funktioniert)

Falls Xcode das Projekt nicht öffnet, kannst du die Datei auch über das Terminal hinzufügen, aber das ist riskant. Besser ist es, Xcode zu verwenden.

## Warum manuell?
Die `project.pbxproj` Datei ist sehr empfindlich und muss exakt formatiert sein. Xcode fügt Dateien sicher hinzu und stellt sicher, dass alle Referenzen korrekt sind.

