# SSL Certificate Pinning

## Übersicht

Die App verwendet SSL Certificate Pinning für erhöhte Sicherheit. Die Zertifikate werden zur Build-Zeit ins App-Bundle eingebunden.

## Lokale Entwicklung

Für lokale Builds müssen die Zertifikate manuell heruntergeladen werden:

```bash
cd ios
./scripts/download_ssl_certificates.sh
```

Das Script:
- Liest die Supabase-URL aus `Configs/Secrets.xcconfig`
- Liest die Backend-URL aus `Sources/Services/Config.swift` (Production)
- Lädt die Zertifikate herunter und speichert sie in:
  - `Certificates/supabase.cer`
  - `Certificates/backend.cer`
  - `supabase.cer` (Root, für Backward Compatibility)
  - `backend.cer` (Root, für Backward Compatibility)

## CI/CD (GitHub Actions)

Die Zertifikate werden automatisch während des Build-Prozesses heruntergeladen:

1. **Automatischer Download**: Die CI/CD Pipeline lädt die Zertifikate vor dem Build herunter
2. **GitHub Secrets**: Die Supabase-URL kann als `SUPABASE_URL` Secret gesetzt werden (optional)
3. **Fallback**: Falls kein Secret gesetzt ist, wird die Standard-URL verwendet

## Production Builds

Für Production-Builds (App Store, TestFlight):

1. **Automatisch**: Wenn über CI/CD gebaut wird, werden Zertifikate automatisch heruntergeladen
2. **Manuell**: Wenn lokal gebaut wird, müssen Zertifikate vorher heruntergeladen werden

## Wichtige Hinweise

- ⚠️ **Zertifikate sind NICHT in Git**: Sie sind in `.gitignore` und werden nicht committed
- ✅ **Zertifikate sind öffentlich**: Sie können von jedem Server heruntergeladen werden (kein Sicherheitsrisiko)
- 🔄 **Zertifikate erneuern**: Wenn Server-Zertifikate erneuert werden, müssen die Zertifikate neu heruntergeladen werden
- 📱 **App-Bundle**: Die Zertifikate werden zur Build-Zeit ins App-Bundle eingebunden

## Troubleshooting

### SSL Pinning schlägt fehl

1. Prüfe, ob Zertifikate im Bundle sind:
   ```bash
   # Nach dem Build
   unzip -l CulinaChef.app | grep "\.cer"
   ```

2. Prüfe, ob Zertifikate aktuell sind:
   ```bash
   openssl x509 -in Certificates/supabase.cer -inform DER -noout -dates
   openssl x509 -in Certificates/backend.cer -inform DER -noout -dates
   ```

3. Lade Zertifikate neu herunter:
   ```bash
   ./scripts/download_ssl_certificates.sh
   ```

### Build schlägt fehl wegen fehlender Zertifikate

Die Zertifikate sind als `optional: true` markiert, daher sollte der Build auch ohne sie funktionieren. SSL Pinning wird dann jedoch nicht aktiviert.

## Zertifikate erneuern

Wenn Server-Zertifikate erneuert werden:

1. Lade neue Zertifikate herunter:
   ```bash
   ./scripts/download_ssl_certificates.sh
   ```

2. Baue die App neu

3. Teste SSL Pinning

## Implementierung

Die SSL Pinning-Implementierung befindet sich in:
- `Sources/Services/SecureURLSession.swift`
- Zertifikate werden aus dem Bundle geladen: `Bundle.main.url(forResource:name:withExtension:)`

