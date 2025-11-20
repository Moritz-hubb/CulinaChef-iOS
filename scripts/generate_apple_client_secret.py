#!/usr/bin/env python3
"""
Apple Sign In Client Secret Generator

Dieses Script generiert ein Client Secret für Apple Sign In, das in Supabase verwendet wird.

Verwendung:
1. Lade einen Sign In with Apple Key von Apple Developer Console herunter
2. Fülle die Variablen unten aus
3. Führe das Script aus: python3 generate_apple_client_secret.py
4. Kopiere das generierte Secret in Supabase

WICHTIG: Das Secret läuft nach 6 Monaten ab und muss erneuert werden.
"""

import jwt
import time
import sys

# ============================================
# KONFIGURATION - Bitte ausfüllen:
# ============================================

# Deine Apple Developer Team ID (findest du in Apple Developer Console)
TEAM_ID = "4Q33QP9G7Z"

# Deine Service ID (die du in Apple Developer Console erstellt hast)
# Beispiel: com.moritzserrin.culinachef.service
CLIENT_ID = "com.moritzserrin.culinachef.service"

# Die Key ID vom erstellten Sign In with Apple Key
KEY_ID = "YOUR_KEY_ID_HERE"

# Der Inhalt der .p8 Datei (komplett, inkl. BEGIN/END Zeilen)
PRIVATE_KEY = """-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_CONTENT_HERE
-----END PRIVATE KEY-----"""

# ============================================
# Script (nicht ändern)
# ============================================

def generate_client_secret():
    """Generiert ein Apple Client Secret JWT."""
    
    # Validierung
    if KEY_ID == "YOUR_KEY_ID_HERE" or "YOUR_PRIVATE_KEY" in PRIVATE_KEY:
        print("❌ FEHLER: Bitte fülle alle Konfigurationsvariablen aus!")
        print("\nSchritte:")
        print("1. Gehe zu https://developer.apple.com/account/resources/authkeys/list")
        print("2. Erstelle einen neuen Key mit 'Sign In with Apple' aktiviert")
        print("3. Lade die .p8 Datei herunter (nur einmal möglich!)")
        print("4. Kopiere die Key ID und den Private Key Inhalt in dieses Script")
        sys.exit(1)
    
    # JWT Header
    headers = {
        "kid": KEY_ID,
        "alg": "ES256"
    }
    
    # JWT Payload
    now = int(time.time())
    payload = {
        "iss": TEAM_ID,
        "iat": now,
        "exp": now + 15777000,  # 6 Monate (15777000 Sekunden)
        "aud": "https://appleid.apple.com",
        "sub": CLIENT_ID
    }
    
    try:
        # JWT erstellen
        secret = jwt.encode(payload, PRIVATE_KEY, algorithm="ES256", headers=headers)
        
        print("✅ Client Secret erfolgreich generiert!")
        print("\n" + "="*60)
        print("CLIENT SECRET (für Supabase):")
        print("="*60)
        print(secret)
        print("="*60)
        print("\n📋 Nächste Schritte:")
        print("1. Kopiere das Secret oben")
        print("2. Gehe zu Supabase Dashboard → Authentication → Providers → Apple")
        print("3. Füge das Secret in das 'Client Secret' Feld ein")
        print("4. Speichere die Einstellungen")
        print("\n⚠️  WICHTIG: Das Secret läuft nach 6 Monaten ab!")
        print("   Erstelle einen Reminder, um es rechtzeitig zu erneuern.")
        
        return secret
        
    except Exception as e:
        print(f"❌ FEHLER beim Generieren des Secrets: {e}")
        print("\nMögliche Ursachen:")
        print("- Private Key Format ist falsch (muss BEGIN/END Zeilen enthalten)")
        print("- Key ID ist falsch")
        print("- Team ID ist falsch")
        sys.exit(1)

if __name__ == "__main__":
    generate_client_secret()

