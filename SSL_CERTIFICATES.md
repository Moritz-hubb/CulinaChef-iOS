# SSL Public Key Pinning (SPKI)

## Übersicht

Die App verwendet **SPKI (Subject Public Key Info) Pinning** statt vollständigem Zertifikat-Pinning. Dabei wird der SHA-256-Hash des öffentlichen Schlüssels (Public Key) verglichen, nicht das gesamte Zertifikat.

**Vorteile gegenüber Leaf-Certificate-Pinning:**
- Überlebt Zertifikats-Rotationen, solange der Server den gleichen Key verwendet
- Kein Bundling von `.cer`-Dateien im App-Bundle notwendig
- Pin-Hashes werden als Konstanten in `Config.swift` gespeichert

**Graceful Degradation:**
Wenn der Pin-Vergleich fehlschlägt, aber die System-Trust-Validierung besteht (d.h. das Zertifikat ist gültig, nur der Key hat sich geändert), wird die Verbindung trotzdem zugelassen und ein Warning geloggt. Dadurch bricht die App bei Zertifikats-Rotationen von Railway/Supabase **nie** ab.

## Architektur

```
Verbindungsaufbau
    │
    ├─ System Trust Validation (iOS/macOS CA Store)
    │   ├─ ❌ Fehlgeschlagen → Verbindung BLOCKIERT (MITM oder abgelaufen)
    │   └─ ✅ Bestanden
    │       │
    │       ├─ SPKI Hash Match → ✅ Verbindung (mit Pinning)
    │       └─ SPKI Hash Mismatch → ✅ Verbindung (mit Warning-Log)
    │                                  → Pin-Hashes aktualisieren!
```

## SPKI-Hashes aktualisieren

### Automatisch (empfohlen)

```bash
cd ios
./scripts/download_ssl_certificates.sh
```

Das Script gibt die aktuellen SPKI-Hashes aus, die in `Config.swift` eingetragen werden müssen.

### Manuell

```bash
# SPKI SHA-256 Hash extrahieren
echo | openssl s_client -servername HOST -connect HOST:443 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | base64
```

### In Config.swift eintragen

```swift
static let backendPublicKeyHashes: Set<String> = [
    "AKTUELLER_HASH_BASE64",  // Aktueller Key
]
```

## CI/CD (GitHub Actions)

Die CI Pipeline kann die SPKI-Hashes automatisch prüfen, aber sie müssen **nicht** bei jedem Build heruntergeladen werden, da die Hashes als Konstanten in `Config.swift` stehen. Die `.cer`-Dateien werden nur noch vom Script zur Hash-Berechnung verwendet.

## Wichtige Hinweise

- **Railway** verwendet Let's Encrypt Zertifikate (90-Tage-Rotation)
- Bei Rotation kann sich der Public Key ändern → Graceful Degradation fängt das ab
- Logs prüfen: Bei Pin-Mismatch wird ein Error-Log geschrieben → Hashes aktualisieren
- **Supabase-Pinning** ist aktuell deaktiviert (`enableSupabasePinning = false`)

## Dateien

| Datei | Beschreibung |
|-------|-------------|
| `Sources/Services/SecureURLSession.swift` | SPKI-Pinning-Implementierung |
| `Sources/Services/Config.swift` | Pin-Hashes & Feature-Flags |
| `scripts/download_ssl_certificates.sh` | Hash-Extraktion-Script |

## Troubleshooting

### App kann keine Verbindung herstellen

1. Prüfe ob SSL-Pinning aktiv ist: `Config.enableSSLPinning` (nur in Production)
2. In Debug-Builds wird Pinning übersprungen
3. Prüfe Logs auf "SSL Pinning: Public key mismatch" → Hashes aktualisieren

### SPKI-Hash hat sich geändert

1. Script ausführen: `./scripts/download_ssl_certificates.sh`
2. Neuen Hash in `Config.backendPublicKeyHashes` eintragen
3. App neu builden und releasen
4. **Die App funktioniert dank Graceful Degradation auch mit veralteten Hashes weiter**
