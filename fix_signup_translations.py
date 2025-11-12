#!/usr/bin/env python3
import json

localization_dir = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization"

# Fix existing keys that have wrong translations
translation_fixes = {
    "ui.passwort_bestätigen": {
        "de": "Passwort bestätigen",
        "en": "Confirm Password",
        "fr": "Confirmer le mot de passe",
        "it": "Conferma password",
        "es": "Confirmar contraseña"
    },
    "ui.wiederholen": {
        "de": "Wiederholen",
        "en": "Repeat",
        "fr": "Répéter",
        "it": "Ripeti",
        "es": "Repetir"
    },
    "ui.ich_akzeptiere_die": {
        "de": "Ich akzeptiere die ",
        "en": "I accept the ",
        "fr": "J'accepte les ",
        "it": "Accetto i ",
        "es": "Acepto los "
    },
    "ui.und_die": {
        "de": " und die ",
        "en": " and the ",
        "fr": " et la ",
        "it": " e la ",
        "es": " y la "
    },
    "ui.datenschutzerklärung_2997": {
        "de": "Datenschutzerklärung",
        "en": "Privacy Policy",
        "fr": "Politique de confidentialité",
        "it": "Informativa sulla privacy",
        "es": "Política de privacidad"
    },
    "ui.datenschutzerklärung": {
        "de": "Datenschutzerklärung",
        "en": "Privacy Policy",
        "fr": "Politique de confidentialité",
        "it": "Informativa sulla privacy",
        "es": "Política de privacidad"
    }
}

# New key for "Sign Up" button
new_keys = {
    "auth.signUpButton": {
        "de": "Registrieren",
        "en": "Sign Up",
        "fr": "S'inscrire",
        "it": "Iscriviti",
        "es": "Registrarse"
    },
    "auth.termsOfServiceShort": {
        "de": "AGB",
        "en": "Terms",
        "fr": "CGU",
        "it": "Termini",
        "es": "Términos"
    }
}

languages = ["de", "en", "fr", "it", "es"]

for lang in languages:
    file_path = f"{localization_dir}/{lang}.json"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Fix existing keys
    for key, translations in translation_fixes.items():
        data[key] = translations[lang]
    
    # Add new keys
    for key, translations in new_keys.items():
        data[key] = translations[lang]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"Updated {lang}.json")

print("\nAll localization files updated successfully!")
print("\nFixed keys:")
for key in translation_fixes.keys():
    print(f"  - {key}")
print("\nAdded new keys:")
for key in new_keys.keys():
    print(f"  - {key}")
