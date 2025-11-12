#!/usr/bin/env python3
import json

localization_dir = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization"

# New keys to add for SignIn
new_keys = {
    "auth.loginButton": {
        "de": "Anmelden",
        "en": "Log In",
        "fr": "Se connecter",
        "it": "Accedi",
        "es": "Iniciar sesión"
    },
    "auth.loginWithApple": {
        "de": "Mit Apple anmelden",
        "en": "Log in with Apple",
        "fr": "Se connecter avec Apple",
        "it": "Accedi con Apple",
        "es": "Iniciar sesión con Apple"
    },
    "auth.or": {
        "de": "oder",
        "en": "or",
        "fr": "ou",
        "it": "o",
        "es": "o"
    },
    "auth.passwordPlaceholderDots": {
        "de": "••••••••",
        "en": "••••••••",
        "fr": "••••••••",
        "it": "••••••••",
        "es": "••••••••"
    }
}

languages = ["de", "en", "fr", "it", "es"]

for lang in languages:
    file_path = f"{localization_dir}/{lang}.json"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Add new keys
    for key, translations in new_keys.items():
        data[key] = translations[lang]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"Updated {lang}.json")

print("All localization files updated successfully!")
