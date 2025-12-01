# Resource References Fix

## Problem

Die Referenzen für Language JSON-Dateien (`de.json`, `en.json`, etc.) und Zertifikate (`supabase.cer`, `backend.cer`) werden nach `xcodegen generate` immer wieder entfernt.

## Lösung

### 1. JSON-Dateien verschoben

Die JSON-Dateien wurden von `ios/` Root nach `ios/Resources/Localization/` verschoben. Dies stellt sicher, dass sie automatisch als Teil des `Resources` Ordners hinzugefügt werden.

**Vorher:**
```
ios/
  ├── de.json
  ├── en.json
  └── ...
```

**Nachher:**
```
ios/
  └── Resources/
      └── Localization/
          ├── de.json
          ├── en.json
          └── ...
```

### 2. `project.yml` wurde korrigiert

Die JSON-Dateien werden jetzt automatisch als Teil des `Resources` Ordners hinzugefügt:
```yaml
resources:
  - path: Resources
    type: folder
```

Die Zertifikate sind als `optional: true` markiert (da sie in `.gitignore` sind):
```yaml
resources:
  - path: supabase.cer
    optional: true
  - path: backend.cer
    optional: true
  - path: Certificates
    type: folder
    optional: true
```

### 2. Prüf-Script erstellt

Das Script `scripts/fix_resources.sh` prüft, ob alle Resource-Referenzen korrekt sind:

```bash
cd ios
./scripts/fix_resources.sh
```

### 3. Automatisches Fix-Script

Das Script `Widgets/fix_all.sh` wurde erweitert und führt jetzt automatisch aus:
1. `xcodegen generate`
2. Info.plist Fix
3. Entitlements Fix
4. Resource-Referenzen Prüfung

```bash
cd ios
./Widgets/fix_all.sh
```

## Verwendung

### Nach `xcodegen generate`:

```bash
cd ios
./Widgets/fix_all.sh
```

Dies stellt sicher, dass:
- ✅ Widget Info.plist korrekt konfiguriert ist
- ✅ App Group Entitlements vorhanden sind
- ✅ JSON-Dateien korrekt referenziert sind
- ✅ Zertifikate korrekt referenziert sind (falls vorhanden)

### Nur Resource-Referenzen prüfen:

```bash
cd ios
./scripts/fix_resources.sh
```

## Hinweise

- **JSON-Dateien**: Liegen jetzt in `ios/Resources/Localization/` und werden automatisch als Teil des `Resources` Ordners hinzugefügt
- **Zertifikate**: Sind optional und werden nicht in Git committed (`.gitignore`)
- **Zertifikate herunterladen**: `./scripts/download_ssl_certificates.sh`
- **LocalizationManager**: Sucht automatisch in mehreren Pfaden, inklusive `Resources/Localization/`

## Troubleshooting

### JSON-Dateien werden nicht gefunden

1. Prüfe, ob die Dateien in `ios/Resources/Localization/` liegen:
   ```bash
   ls -la ios/Resources/Localization/*.json
   ```

2. Prüfe, ob der `Resources` Ordner in `project.yml` referenziert ist:
   ```yaml
   resources:
     - path: Resources
       type: folder
   ```

3. Die `LocalizationManager` sucht automatisch in mehreren Pfaden:
   - `Resources/Localization/` (neue Position)
   - `Resources/`
   - Root-Verzeichnis (für Backward Compatibility)

### Zertifikate werden nicht gefunden

Das ist normal, wenn die Zertifikate nicht heruntergeladen wurden. Sie sind als `optional: true` markiert.

Zertifikate herunterladen:
```bash
cd ios
./scripts/download_ssl_certificates.sh
```

