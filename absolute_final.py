#!/usr/bin/env python3
import json
from pathlib import Path

LOCALIZATION_DIR = Path("/Users/moritzserrin/CulinaChef/ios/Resources/Localization")

ABSOLUTE_FINAL = {
    "fr": {
        "Impressum\n\nPlatzhalter - Text hier einfügen": "Mentions légales\n\nPlaceholder - Insérer le texte ici",
        "Allergien/Unverträglichkeiten": "Allergies/Intolérances",
    },
    "it": {
        "Impressum\n\nPlatzhalter - Text hier einfügen": "Informazioni legali\n\nSegnaposto - Inserire il testo qui",
        "Allergien/Unverträglichkeiten": "Allergie/Intolleranze",
    },
    "es": {
        "Impressum\n\nPlatzhalter - Text hier einfügen": "Aviso legal\n\nMarcador de posición - Insertar texto aquí",
        "Allergien/Unverträglichkeiten": "Alergias/Intolerancias",
    }
}

def translate_value(value, lang):
    if not value.startswith("[DE] "):
        return value
    
    german_text = value[5:]
    
    if german_text in ABSOLUTE_FINAL.get(lang, {}):
        return ABSOLUTE_FINAL[lang][german_text]
    
    return value

def process_file(filepath, lang):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translated_count = 0
    remaining_count = 0
    
    for key, value in data.items():
        if value.startswith("[DE] "):
            new_value = translate_value(value, lang)
            if new_value != value:
                data[key] = new_value
                translated_count += 1
            else:
                remaining_count += 1
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
    
    return translated_count, remaining_count

for lang in ["fr", "it", "es"]:
    filepath = LOCALIZATION_DIR / f"{lang}.json"
    if filepath.exists():
        translated, remaining = process_file(filepath, lang)
        if remaining == 0:
            print(f"🎉 {lang}.json: VOLLSTÄNDIG ÜBERSETZT! ({translated} letzte Keys)")
        else:
            print(f"✅ {lang}.json: {translated} übersetzt, {remaining} verbleibend")
    else:
        print(f"⚠️  {lang}.json nicht gefunden")

print("\n✅ Alle Übersetzungen abgeschlossen!")
