#!/usr/bin/env python3
"""
Auto-translate common localization keys
"""
import json
import re
from pathlib import Path

LOCALIZATION_DIR = Path(__file__).parent / "Resources" / "Localization"

# Common translations dictionary
TRANSLATIONS = {
    "fr": {
        # Common actions
        "Abbrechen": "Annuler",
        "Fertig": "Terminé",
        "Speichern": "Enregistrer",
        "Löschen": "Supprimer",
        "Bearbeiten": "Modifier",
        "Erstellen": "Créer",
        "Teilen": "Partager",
        "Schließen": "Fermer",
        "Zurück": "Retour",
        "Weiter": "Suivant",
        "OK": "OK",
        "Ja": "Oui",
        "Nein": "Non",
        "Alle löschen": "Tout supprimer",
        "Alle": "Tous",
        "Entfernen": "Retirer",
        
        # Food & Cooking
        "Rezept": "Recette",
        "Rezepte": "Recettes",
        "Zutaten": "Ingrédients",
        "Nährwerte": "Valeurs nutritionnelles",
        "Kochen": "Cuisiner",
        "Ernährung": "Alimentation",
        "Menü": "Menu",
        "Einkaufsliste": "Liste de courses",
        "Community": "Communauté",
        
        # Settings
        "Einstellungen": "Paramètres",
        "Profil": "Profil",
        "Konto": "Compte",
        "Abonnement": "Abonnement",
        "Benachrichtigungen": "Notifications",
        "Sprache": "Langue",
        "Datenschutz": "Confidentialité",
        "AGB": "CGV",
        "Impressum": "Mentions légales",
        
        # Time
        "Minuten": "Minutes",
        "Stunden": "Heures",
        "Sekunden": "Secondes",
        
        # Common phrases
        "Erstelle jetzt dein erstes Rezept": "Créez votre première recette maintenant",
        "Mit KI erstellen": "Créer avec l'IA",
        "Eigenes Rezept erstellen": "Créer sa propre recette",
        "Neues Menü": "Nouveau menu",
        "Menüname": "Nom du menu",
    },
    "it": {
        # Common actions
        "Abbrechen": "Annulla",
        "Fertig": "Fatto",
        "Speichern": "Salva",
        "Löschen": "Elimina",
        "Bearbeiten": "Modifica",
        "Erstellen": "Crea",
        "Teilen": "Condividi",
        "Schließen": "Chiudi",
        "Zurück": "Indietro",
        "Weiter": "Avanti",
        "OK": "OK",
        "Ja": "Sì",
        "Nein": "No",
        "Alle löschen": "Elimina tutto",
        "Alle": "Tutti",
        "Entfernen": "Rimuovi",
        
        # Food & Cooking
        "Rezept": "Ricetta",
        "Rezepte": "Ricette",
        "Zutaten": "Ingredienti",
        "Nährwerte": "Valori nutrizionali",
        "Kochen": "Cucinare",
        "Ernährung": "Alimentazione",
        "Menü": "Menu",
        "Einkaufsliste": "Lista della spesa",
        "Community": "Comunità",
        
        # Settings
        "Einstellungen": "Impostazioni",
        "Profil": "Profilo",
        "Konto": "Account",
        "Abonnement": "Abbonamento",
        "Benachrichtigungen": "Notifiche",
        "Sprache": "Lingua",
        "Datenschutz": "Privacy",
        "AGB": "Termini e Condizioni",
        "Impressum": "Informazioni legali",
        
        # Time
        "Minuten": "Minuti",
        "Stunden": "Ore",
        "Sekunden": "Secondi",
        
        # Common phrases
        "Erstelle jetzt dein erstes Rezept": "Crea ora la tua prima ricetta",
        "Mit KI erstellen": "Crea con IA",
        "Eigenes Rezept erstellen": "Crea ricetta personalizzata",
        "Neues Menü": "Nuovo menu",
        "Menüname": "Nome del menu",
    },
    "es": {
        # Common actions
        "Abbrechen": "Cancelar",
        "Fertig": "Listo",
        "Speichern": "Guardar",
        "Löschen": "Eliminar",
        "Bearbeiten": "Editar",
        "Erstellen": "Crear",
        "Teilen": "Compartir",
        "Schließen": "Cerrar",
        "Zurück": "Atrás",
        "Weiter": "Siguiente",
        "OK": "OK",
        "Ja": "Sí",
        "Nein": "No",
        "Alle löschen": "Eliminar todo",
        "Alle": "Todos",
        "Entfernen": "Eliminar",
        
        # Food & Cooking
        "Rezept": "Receta",
        "Rezepte": "Recetas",
        "Zutaten": "Ingredientes",
        "Nährwerte": "Valores nutricionales",
        "Kochen": "Cocinar",
        "Ernährung": "Alimentación",
        "Menü": "Menú",
        "Einkaufsliste": "Lista de compras",
        "Community": "Comunidad",
        
        # Settings
        "Einstellungen": "Ajustes",
        "Profil": "Perfil",
        "Konto": "Cuenta",
        "Abonnement": "Suscripción",
        "Benachrichtigungen": "Notificaciones",
        "Sprache": "Idioma",
        "Datenschutz": "Privacidad",
        "AGB": "Términos y Condiciones",
        "Impressum": "Aviso legal",
        
        # Time
        "Minuten": "Minutos",
        "Stunden": "Horas",
        "Sekunden": "Segundos",
        
        # Common phrases
        "Erstelle jetzt dein erstes Rezept": "Crea tu primera receta ahora",
        "Mit KI erstellen": "Crear con IA",
        "Eigenes Rezept erstellen": "Crear receta propia",
        "Neues Menü": "Nuevo menú",
        "Menüname": "Nombre del menú",
    }
}

def translate_text(text, lang):
    """Translate German text to target language using dictionary"""
    if not text.startswith("[DE] "):
        return text
    
    # Remove [DE] prefix
    german_text = text[5:]
    
    # Try direct translation
    if german_text in TRANSLATIONS.get(lang, {}):
        return TRANSLATIONS[lang][german_text]
    
    # Try word-by-word translation for simple cases
    words = german_text.split()
    if len(words) <= 3:
        translated_words = []
        for word in words:
            if word in TRANSLATIONS.get(lang, {}):
                translated_words.append(TRANSLATIONS[lang][word])
            else:
                # Keep [DE] prefix if we can't translate
                return text
        return " ".join(translated_words)
    
    # Keep [DE] prefix for complex phrases
    return text

def auto_translate():
    """Auto-translate common keys in all language files"""
    for lang in ["fr", "it", "es"]:
        lang_file = LOCALIZATION_DIR / f"{lang}.json"
        if not lang_file.exists():
            print(f"⚠️  {lang}.json not found")
            continue
        
        with open(lang_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        translated_count = 0
        for key, value in data.items():
            if value.startswith("[DE] "):
                new_value = translate_text(value, lang)
                if not new_value.startswith("[DE] "):
                    data[key] = new_value
                    translated_count += 1
        
        # Save updated file
        with open(lang_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')
        
        print(f"✅ Translated {translated_count} keys in {lang}.json")

if __name__ == "__main__":
    print("🔄 Auto-translating common keys...\n")
    auto_translate()
    print("\n✅ Translation complete!")
    print("⚠️  Remaining [DE] prefixed keys need manual translation")
