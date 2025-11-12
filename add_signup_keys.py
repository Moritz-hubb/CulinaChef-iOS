#!/usr/bin/env python3
import json
from pathlib import Path

LOCALIZATION_DIR = Path("/Users/moritzserrin/CulinaChef/ios/Resources/Localization")

NEW_KEYS = {
    "de": {
        "auth.letsGetStarted": "Loslegen!",
        "auth.usernamePlaceholder": "z.B. chefmax",
        "auth.emailPlaceholder": "E-Mail",
        "auth.passwordPlaceholder": "Mind. 6 Zeichen",
        "auth.minCharacters": "Mind. 6 Zeichen",
    },
    "en": {
        "auth.letsGetStarted": "Let's get started!",
        "auth.usernamePlaceholder": "e.g. chefmax",
        "auth.emailPlaceholder": "Email",
        "auth.passwordPlaceholder": "Min. 6 characters",
        "auth.minCharacters": "Min. 6 characters",
    },
    "fr": {
        "auth.letsGetStarted": "C'est parti!",
        "auth.usernamePlaceholder": "par ex. chefmax",
        "auth.emailPlaceholder": "E-mail",
        "auth.passwordPlaceholder": "Min. 6 caractères",
        "auth.minCharacters": "Min. 6 caractères",
    },
    "it": {
        "auth.letsGetStarted": "Iniziamo!",
        "auth.usernamePlaceholder": "ad es. chefmax",
        "auth.emailPlaceholder": "Email",
        "auth.passwordPlaceholder": "Min. 6 caratteri",
        "auth.minCharacters": "Min. 6 caratteri",
    },
    "es": {
        "auth.letsGetStarted": "¡Empecemos!",
        "auth.usernamePlaceholder": "por ej. chefmax",
        "auth.emailPlaceholder": "Correo electrónico",
        "auth.passwordPlaceholder": "Mín. 6 caracteres",
        "auth.minCharacters": "Mín. 6 caracteres",
    }
}

for lang in ["de", "en", "fr", "it", "es"]:
    filepath = LOCALIZATION_DIR / f"{lang}.json"
    if filepath.exists():
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Add new keys
        for key, value in NEW_KEYS[lang].items():
            if key not in data:
                data[key] = value
        
        # Sort and save
        data = dict(sorted(data.items()))
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')
        
        print(f"✅ Updated {lang}.json")

print("\n✅ All localization files updated!")
