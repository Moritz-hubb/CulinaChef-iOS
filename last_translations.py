#!/usr/bin/env python3
import json
from pathlib import Path

LOCALIZATION_DIR = Path("/Users/moritzserrin/CulinaChef/ios/Resources/Localization")

LAST_TRANSLATIONS = {
    "fr": {
        " und die ": " et la ",
        "Aktuelles Passwort ist falsch oder Änderung fehlgeschlagen": "Le mot de passe actuel est incorrect ou la modification a échoué",
        "Budget": "Budget",
        "Community-Bibliothek": "Bibliothèque communautaire",
        "Culina": "Culina",
        "Einkaufen": "Courses",
        "Glutenfrei": "Sans gluten",
        "High-Protein": "Riche en protéines",
        "Hinweise": "Remarques",
        "Ich akzeptiere die ": "J'accepte les ",
        "Impressum\\n\\nPlatzhalter - Text hier einfügen": "Mentions légales\\n\\nPlaceholder - Insérer le texte ici",
        "Keine": "Aucune",
        "Laktosefrei": "Sans lactose",
        "Legal": "Légal",
        "Low-Carb": "Faible en glucides",
        "Läuft am:": "Expire le:",
        "Meiden (Abneigungen)": "À éviter (aversions)",
        "Möchtest du eine vollständige Kopie deiner Daten? Kontaktiere unseren Support.": "Souhaitez-vous recevoir une copie complète de vos données? Contactez notre support.",
        "Nächste Abbuchung:": "Prochain prélèvement:",
        "Passwort erfolgreich geändert": "Mot de passe modifié avec succès",
        "Rezeptebuch": "Livre de recettes",
        "Schnell": "Rapide",
        "Vegan": "Végétalien",
        "Vegetarisch": "Végétarien",
        "Wir berechnen nichts mehr nach Ablauf des aktuellen Zeitraums": "Nous ne facturerons plus après l'expiration de la période en cours",
    },
    "it": {
        " und die ": " e la ",
        "Aktuelles Passwort ist falsch oder Änderung fehlgeschlagen": "La password attuale è errata o la modifica è fallita",
        "Budget": "Budget",
        "Community-Bibliothek": "Biblioteca della comunità",
        "Culina": "Culina",
        "Einkaufen": "Spesa",
        "Glutenfrei": "Senza glutine",
        "High-Protein": "Ad alto contenuto proteico",
        "Hinweise": "Note",
        "Ich akzeptiere die ": "Accetto i ",
        "Impressum\\n\\nPlatzhalter - Text hier einfügen": "Informazioni legali\\n\\nSegnaposto - Inserire il testo qui",
        "Keine": "Nessuna",
        "Laktosefrei": "Senza lattosio",
        "Legal": "Legale",
        "Low-Carb": "A basso contenuto di carboidrati",
        "Läuft am:": "Scade il:",
        "Meiden (Abneigungen)": "Da evitare (avversioni)",
        "Möchtest du eine vollständige Kopie deiner Daten? Kontaktiere unseren Support.": "Vuoi ricevere una copia completa dei tuoi dati? Contatta il nostro supporto.",
        "Nächste Abbuchung:": "Prossimo addebito:",
        "Passwort erfolgreich geändert": "Password modificata con successo",
        "Rezeptebuch": "Libro di ricette",
        "Schnell": "Veloce",
        "Vegan": "Vegano",
        "Vegetarisch": "Vegetariano",
        "Wir berechnen nichts mehr nach Ablauf des aktuellen Zeitraums": "Non addebiteremo più dopo la scadenza del periodo corrente",
    },
    "es": {
        " und die ": " y la ",
        "Aktuelles Passwort ist falsch oder Änderung fehlgeschlagen": "La contraseña actual es incorrecta o el cambio ha fallado",
        "Budget": "Presupuesto",
        "Community-Bibliothek": "Biblioteca comunitaria",
        "Culina": "Culina",
        "Einkaufen": "Compras",
        "Glutenfrei": "Sin gluten",
        "High-Protein": "Alto en proteínas",
        "Hinweise": "Notas",
        "Ich akzeptiere die ": "Acepto los ",
        "Impressum\\n\\nPlatzhalter - Text hier einfügen": "Aviso legal\\n\\nMarcador de posición - Insertar texto aquí",
        "Keine": "Ninguna",
        "Laktosefrei": "Sin lactosa",
        "Legal": "Legal",
        "Low-Carb": "Bajo en carbohidratos",
        "Läuft am:": "Vence el:",
        "Meiden (Abneigungen)": "Evitar (aversiones)",
        "Möchtest du eine vollständige Kopie deiner Daten? Kontaktiere unseren Support.": "¿Quieres recibir una copia completa de tus datos? Contacta con nuestro soporte.",
        "Nächste Abbuchung:": "Próximo cargo:",
        "Passwort erfolgreich geändert": "Contraseña cambiada con éxito",
        "Rezeptebuch": "Libro de recetas",
        "Schnell": "Rápido",
        "Vegan": "Vegano",
        "Vegetarisch": "Vegetariano",
        "Wir berechnen nichts mehr nach Ablauf des aktuellen Zeitraums": "No cobraremos más después de que expire el período actual",
    }
}

def translate_value(value, lang):
    if not value.startswith("[DE] "):
        return value
    
    german_text = value[5:]
    
    if german_text in LAST_TRANSLATIONS.get(lang, {}):
        return LAST_TRANSLATIONS[lang][german_text]
    
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
        print(f"✅ {lang}.json: Translated {translated} keys, {remaining} remaining with [DE]")
    else:
        print(f"⚠️  {lang}.json not found")

print("\n🎉 ALL TRANSLATIONS COMPLETE!")
