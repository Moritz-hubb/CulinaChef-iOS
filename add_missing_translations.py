#!/usr/bin/env python3
import json

# Missing translations to add
new_translations = {
    "recipe.foto_hinzufügen": {
        "de": "Foto hinzufügen",
        "en": "Add Photo",
        "fr": "Ajouter une photo",
        "it": "Aggiungi foto",
        "es": "Añadir foto"
    },
    "error.notLoggedIn": {
        "de": "Nicht angemeldet",
        "en": "Not logged in",
        "fr": "Non connecté",
        "it": "Non connesso",
        "es": "No conectado"
    },
    "error.uploadFailed": {
        "de": "Fehler beim Hochladen",
        "en": "Upload failed",
        "fr": "Échec du téléchargement",
        "it": "Caricamento fallito",
        "es": "Error al cargar"
    },
    "error.saveFailed": {
        "de": "Fehler beim Speichern",
        "en": "Save failed",
        "fr": "Échec de l'enregistrement",
        "it": "Salvataggio fallito",
        "es": "Error al guardar"
    },
    "recipe.timerHide": {
        "de": "Timer verstecken",
        "en": "Hide timer",
        "fr": "Masquer le minuteur",
        "it": "Nascondi timer",
        "es": "Ocultar temporizador"
    },
    "recipe.timerActive": {
        "de": "Timer aktiv",
        "en": "timer active",
        "fr": "minuteur actif",
        "it": "timer attivo",
        "es": "temporizador activo"
    },
    "chat.messagePlaceholder": {
        "de": "Nachricht…",
        "en": "Message…",
        "fr": "Message…",
        "it": "Messaggio…",
        "es": "Mensaje…"
    },
    "chat.culinaName": {
        "de": "Culina",
        "en": "Culina",
        "fr": "Culina",
        "it": "Culina",
        "es": "Culina"
    },
    "chat.welcomeMessage": {
        "de": "Hi! Ich helfe dir bei diesem Rezept. Was möchtest du wissen?",
        "en": "Hi! I'll help you with this recipe. What would you like to know?",
        "fr": "Salut ! Je t'aide avec cette recette. Que veux-tu savoir ?",
        "it": "Ciao! Ti aiuto con questa ricetta. Cosa vorresti sapere?",
        "es": "¡Hola! Te ayudo con esta receta. ¿Qué te gustaría saber?"
    },
    "chat.inRecipeAI": {
        "de": "In-Rezept KI",
        "en": "In-Recipe AI",
        "fr": "IA de recette",
        "it": "AI ricetta",
        "es": "IA de receta"
    },
    "common.ok": {
        "de": "OK",
        "en": "OK",
        "fr": "OK",
        "it": "OK",
        "es": "OK"
    }
}

# Languages to update
languages = ["de", "en", "fr", "it", "es"]

for lang in languages:
    file_path = f"/Users/moritzserrin/CulinaChef/ios/Localization/{lang}.json"
    
    # Read existing file
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Add new translations
    for key, translations in new_translations.items():
        data[key] = translations[lang]
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"✓ Updated {lang}.json")

print("\nAll language files updated!")
