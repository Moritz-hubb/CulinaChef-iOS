# Apple Sign In OAuth Setup Guide

## Übersicht

Dieser Guide erklärt, wie du "Sign in with Apple" für deine CulinaChef App konfigurierst. Der Code ist bereits implementiert, aber es müssen noch einige Konfigurationen vorgenommen werden.

## ✅ Was bereits implementiert ist

- ✅ Apple Sign In Button in `SignUpView.swift` und `SignInView.swift`
- ✅ OAuth Flow mit Nonce für Sicherheit
- ✅ Supabase Integration für Token Exchange
- ✅ Keychain Storage für Tokens

## 🔧 Schritt 1: Xcode Capabilities konfigurieren

### 1.1 Entitlements-Datei erstellen

1. Öffne dein Xcode-Projekt
2. Gehe zu **File → New → File**
3. Wähle **Property List** (nicht Entitlements!)
4. Nenne es `CulinaChef.entitlements`
5. Speichere es im `ios/Configs/` Ordner (oder im Root)

### 1.2 Entitlements konfigurieren

Öffne die `CulinaChef.entitlements` Datei und füge folgendes hinzu:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
</dict>
</plist>
```

### 1.3 Entitlements in Xcode zuweisen

1. Öffne dein Projekt in Xcode
2. Wähle das **CulinaChef** Target
3. Gehe zum Tab **Signing & Capabilities**
4. Klicke auf **+ Capability**
5. Wähle **Sign In with Apple**
6. Stelle sicher, dass die Entitlements-Datei im **Build Settings → Code Signing Entitlements** Feld referenziert ist

**Alternativ:** Wenn du `project.yml` verwendest, füge folgendes hinzu:

```yaml
targets:
  CulinaChef:
    entitlements:
      path: Configs/CulinaChef.entitlements
      properties:
        com.apple.developer.applesignin:
          - Default
```

## 🔧 Schritt 2: Apple Developer Console konfigurieren

### 2.1 App ID konfigurieren

1. Gehe zu [Apple Developer Console](https://developer.apple.com/account/)
2. Navigiere zu **Certificates, Identifiers & Profiles**
3. Klicke auf **Identifiers**
4. Wähle deine App ID (`com.moritzserrin.culinachef`)
5. Aktiviere **Sign In with Apple** Capability
6. Klicke auf **Save**

### 2.2 Service ID erstellen (für Web/Backend)

**WICHTIG:** Supabase benötigt eine Service ID für OAuth:

1. In **Identifiers**, klicke auf **+** um eine neue ID zu erstellen
2. Wähle **Services IDs**
3. Erstelle eine neue Service ID (z.B. `com.moritzserrin.culinachef.service`)
4. Aktiviere **Sign In with Apple**
5. Klicke auf **Configure**
6. Füge folgende Domains hinzu:
   - **Primary App ID**: Wähle `com.moritzserrin.culinachef` aus der Dropdown-Liste
   - **Website URLs**: 
     - ⚠️ **WICHTIG:** Gib hier NUR die Domain OHNE `https://` ein!
     - Beispiel: `ywduddopwudltshxiqyp.supabase.co`
     - ❌ FALSCH: `https://ywduddopwudltshxiqyp.supabase.co`
     - ✅ RICHTIG: `ywduddopwudltshxiqyp.supabase.co`
   - **Return URLs**:
     - ⚠️ **WICHTIG:** Hier die VOLLSTÄNDIGE URL MIT `https://` eingeben!
     - Beispiel: `https://ywduddopwudltshxiqyp.supabase.co/auth/v1/callback`
7. Klicke auf **Save** und dann auf **Continue**

**Häufige Fehler:**
- ❌ "one or more id is invalid" → Website URL enthält `https://` (sollte nur Domain sein)
- ❌ "Invalid return URL" → Return URL fehlt `https://` oder ist falsch formatiert
- ❌ "Primary App ID not found" → App ID muss zuerst in Schritt 2.1 erstellt/aktiviert sein

## 🔧 Schritt 3: Supabase konfigurieren

### 3.1 Apple Provider in Supabase aktivieren

1. Gehe zu deinem [Supabase Dashboard](https://app.supabase.com)
2. Wähle dein Projekt
3. Navigiere zu **Authentication → Providers**
4. Aktiviere **Apple**
5. Fülle folgende Felder aus:

**Client ID (Service ID):**
```
com.moritzserrin.culinachef.service
```
(Dies ist die Service ID, die du in Schritt 2.2 erstellt hast)

**Client Secret:**
- Du musst ein Apple Client Secret erstellen
- Gehe zu [Apple Developer Console](https://developer.apple.com/account/resources/services/list)
- Klicke auf **Keys**
- Erstelle einen neuen Key mit **Sign In with Apple** aktiviert
- Lade den Key herunter (nur einmal möglich!)
- Erstelle ein Client Secret mit diesem Tool: https://appleid.apple.com/signinwithapple/privatekey
- Oder verwende dieses Python-Script:

```python
import jwt
import time

# Deine Werte
team_id = "4Q33QP9G7Z"  # Deine Team ID
client_id = "com.moritzserrin.culinachef.service"  # Deine Service ID
key_id = "YOUR_KEY_ID"  # Die Key ID vom erstellten Key
private_key = """-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_CONTENT_HERE
-----END PRIVATE KEY-----"""

# JWT erstellen
now = int(time.time())
headers = {
    "kid": key_id
}
payload = {
    "iss": team_id,
    "iat": now,
    "exp": now + 15777000,  # 6 Monate
    "aud": "https://appleid.apple.com",
    "sub": client_id
}

secret = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
print(secret)
```

**Redirect URL:**
```
https://ywduddopwudltshxiqyp.supabase.co/auth/v1/callback
```

### 3.2 Supabase Settings speichern

Nach dem Ausfüllen aller Felder:
1. Klicke auf **Save**
2. Stelle sicher, dass **Apple** in der Liste der aktiven Provider erscheint

## 🧪 Schritt 4: Testen

### 4.1 In der App testen

1. Öffne die App im Simulator oder auf einem echten Gerät
2. Gehe zu **Sign Up** oder **Sign In**
3. Klicke auf den **"Sign in with Apple"** Button
4. Du solltest den Apple Sign In Dialog sehen
5. Nach erfolgreicher Authentifizierung solltest du automatisch angemeldet sein

### 4.2 Debugging

Falls es nicht funktioniert, prüfe:

**In Xcode Console:**
- Suche nach Fehlermeldungen wie "Apple Sign In failed"
- Prüfe ob der `idToken` korrekt empfangen wird

**In Supabase Logs:**
1. Gehe zu **Logs → Auth Logs** in Supabase
2. Prüfe ob Fehler beim Token Exchange auftreten

**Häufige Fehler:**

1. **"Invalid client_id"**
   - Prüfe ob die Service ID in Supabase korrekt ist
   - Stelle sicher, dass die Service ID in Apple Developer Console konfiguriert ist

2. **"Invalid redirect_uri"**
   - Prüfe ob die Return URL in Apple Developer Console korrekt ist
   - Muss exakt übereinstimmen: `https://ywduddopwudltshxiqyp.supabase.co/auth/v1/callback`

3. **"Capability not enabled"**
   - Prüfe ob Sign In with Apple in der App ID aktiviert ist
   - Prüfe ob die Entitlements-Datei korrekt zugewiesen ist

4. **"Token exchange failed"**
   - Prüfe ob das Client Secret korrekt ist
   - Prüfe ob der Client Secret nicht abgelaufen ist (gültig für 6 Monate)

## 📝 Checkliste

- [ ] Entitlements-Datei erstellt und konfiguriert
- [ ] Sign In with Apple Capability in Xcode aktiviert
- [ ] App ID in Apple Developer Console hat Sign In with Apple aktiviert
- [ ] Service ID erstellt und konfiguriert
- [ ] Client Secret generiert
- [ ] Apple Provider in Supabase aktiviert
- [ ] Client ID (Service ID) in Supabase eingetragen
- [ ] Client Secret in Supabase eingetragen
- [ ] Redirect URL in Supabase korrekt konfiguriert
- [ ] Return URL in Apple Developer Console korrekt konfiguriert
- [ ] App getestet - Sign In funktioniert

## 🔗 Nützliche Links

- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Supabase Apple Provider Docs](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Apple Client Secret Generator](https://appleid.apple.com/signinwithapple/privatekey)

## ⚠️ Wichtige Hinweise

1. **Client Secret Ablauf:** Das Client Secret läuft nach 6 Monaten ab. Du musst es regelmäßig erneuern.

2. **Service ID vs App ID:** 
   - App ID: Für native iOS Apps
   - Service ID: Für Web/Backend OAuth (Supabase)

3. **Test vs Production:**
   - In der Entwicklung funktioniert Sign In with Apple nur auf echten Geräten
   - Im Simulator funktioniert es nicht (Apple Beschränkung)

4. **Bundle ID:** Stelle sicher, dass die Bundle ID in Xcode exakt mit der App ID in Apple Developer Console übereinstimmt.

