#!/usr/bin/env python3
"""
Translate remaining [TRANSLATE: ...] placeholders in en.json
"""

import json
import re

EN_JSON = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization/en.json"

# Comprehensive German to English translation map
TRANSLATIONS = {
    # Common phrases
    "Wähle, wie das Rezept erstellt werden soll": "Choose how the recipe should be created",
    "Ich suche nach einem Rezept für dich": "I'm searching for a recipe for you",
    "Das perfekte Rezept ist gleich fertig!": "The perfect recipe will be ready soon!",
    "Frage mich alles übers Kochen!": "Ask me anything about cooking!",
    "Rezepte • Zutaten • Tipps & Tricks": "Recipes • Ingredients • Tips & Tricks",
    "Bild ist optional (max. 1)": "Image is optional (max. 1)",
    "Erfolgreich in der Community veröffentlicht!": "Successfully published in the community!",
    "Mit der Veröffentlichung wird dein Rezept von unserer KI überprüft.": "Upon publication, your recipe will be reviewed by our AI.",
    "Dein Rezept wurde erfolgreich gespeichert.": "Your recipe was saved successfully.",
    "Damit wir deine Rezepte sicher und passend gestalten können": "So we can create your recipes safely and appropriately",
    "Keine Allergien? Perfekt! Weiter zum nächsten Schritt →": "No allergies? Perfect! Continue to the next step →",
    "Wähle deine Ernährungspräferenzen aus": "Choose your dietary preferences",
    "Keine spezielle Ernährungsweise? Kein Problem!": "No special diet? No problem!",
    "Was möchtest du meiden?": "What would you like to avoid?",
    "Zutaten die du nicht magst oder vermeiden möchtest": "Ingredients you don't like or want to avoid",
    "Keine Abneigungen? Super flexibel!": "No dislikes? Super flexible!",
    
    # Privacy/Legal
    "Angaben gemäß § 5 TMG": "Information according to § 5 TMG",
    "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit:": "The European Commission provides a platform for online dispute resolution (ODR):",
    "Der Schutz Ihrer personenbezogenen Daten ist uns ein wichtiges Anliegen. Wir verarbeiten personenbezogene Daten ausschließlich im Einklang mit der DSGVO, dem BDSG sowie weiteren einschlägigen Rechtsvorschriften.": "The protection of your personal data is important to us. We process personal data exclusively in accordance with GDPR, BDSG and other applicable legal regulations.",
    "Wir nutzen OpenAI GPT-4o-mini für:": "We use OpenAI GPT-4o-mini for:",
    
    # Recipe related
    "Erledigte löschen": "Delete completed",
    "Einkaufsliste ist leer": "Shopping list is empty",
    "Füge Zutaten aus Rezepten hinzu oder erstelle eigene Einträge": "Add ingredients from recipes or create your own entries",
    "Eintrag hinzufügen": "Add entry",
    "Menge (optional)": "Amount (optional)",
    "(automatisch erkannt)": "(automatically detected)",
    
    # Recipe creator
    "Schärfe-Level": "Spice level",
    "Rezept erzeugen": "Generate recipe",
    "Dabei kann ich dir leider nicht helfen. Bitte frage nach einem Rezept oder einem Gericht, das du kochen möchtest.": "Unfortunately I can't help with that. Please ask for a recipe or a dish you want to cook.",
    "Keine Rezeptanfrage": "Not a recipe request",
    "Rezept nicht möglich": "Recipe not possible",
    "Max Zeit (Minuten)": "Max time (minutes)",
    "Nährwerte (min/max)": "Nutrition values (min/max)",
    "Geschmackspräferenzen": "Taste preferences",
    
    # Manual recipe builder
    "Rezeptname *": "Recipe name *",
    "Portionen *": "Servings *",
    "Zeit (Min)": "Time (min)",
    "Foto hinzufügen": "Add photo",
    "Rezept speichern": "Save recipe",
    "Schritt": "Step",
    "Timer:": "Timer:",
    "Minuten": "Minutes",
    "Erfolgreich gespeichert!": "Saved successfully!",
    "Rezept erstellen": "Create recipe",
    
    # Settings
    "Ernährungsweisen": "Dietary preferences",
    "Allergien/Unverträglichkeiten (kommagetrennt)": "Allergies/Intolerances (comma-separated)",
    "Meiden (Abneigungen)": "Avoid (dislikes)",
    "Hinweise": "Notes",
    "Meine Daten": "My data",
    "Passwort ändern": "Change password",
    "✓ Passwort erfolgreich geändert": "✓ Password changed successfully",
    "Aktuelles Passwort": "Current password",
    "Neues Passwort": "New password",
    "Passwort bestätigen": "Confirm password",
    "Aktivität": "Activity",
    "Präferenzen": "Preferences",
    "Datenexport": "Data export",
    "Möchtest du eine vollständige Kopie deiner Daten erhalten? Kontaktiere uns unter datenschutz@culinaai.com": "Would you like to receive a complete copy of your data? Contact us at datenschutz@culinaai.com",
    "Culina Unlimited": "Culina Unlimited",
    "Deine Vorteile": "Your benefits",
    "Status: Aktiv": "Status: Active",
    "Automatische Verlängerung: Ein": "Automatic renewal: On",
    "Automatische Verlängerung: Aus": "Automatic renewal: Off",
    "Du behältst alle Unlimited‑Funktionen bis zum Periodenende.": "You keep all Unlimited features until the end of the period.",
    "Kein aktives Abo": "No active subscription",
    "Schalte alle Funktionen mit Unlimited frei.": "Unlock all features with Unlimited.",
    "Abo kündigen – keine weiteren Zahlungen": "Cancel subscription – no further payments",
    "Wir berechnen nicht mehr. Der Zugang bleibt bis zum Ende deines aktuellen Monats erhalten.": "We will not charge anymore. Access remains until the end of your current month.",
    "Unlimited jetzt wieder aktivieren": "Reactivate Unlimited now",
    "Unlimited abonnieren (6,99 €/Monat)": "Subscribe to Unlimited (€6.99/month)",
    "Erscheinungsbild": "Appearance",
    
    # Report system
    "Gemeldet": "Reported",
    "Danke für deine Meldung. Wir prüfen das Rezept.": "Thank you for your report. We are reviewing the recipe.",
    "Rezept melden": "Report recipe",
    "Grund der Meldung": "Reason for report",
    "Zusätzliche Details (optional)": "Additional details (optional)",
    "Melden": "Report",
    
    # Recipe completion
    "Rezept erfolgreich generiert!": "Recipe generated successfully!",
    "Speichern & zur Bibliothek": "Save & go to library",
    "Neu generieren": "Generate new",
    "Abbrechen": "Cancel",
    "Möchtest du ein neues Rezept generieren? Das aktuelle geht verloren.": "Do you want to generate a new recipe? The current one will be lost.",
    "Zutaten kopiert!": "Ingredients copied!",
    "Anleitung kopiert!": "Instructions copied!",
    
    # Recipe detail
    "Zutaten zur Einkaufsliste hinzugefügt": "Ingredients added to shopping list",
    "Rezept wurde gespeichert": "Recipe was saved",
    "Rezept aus Favoriten entfernt": "Recipe removed from favorites",
    "Bewerte dieses Rezept": "Rate this recipe",
    "Kcal pro Portion": "Kcal per serving",
    
    # Onboarding
    "Allergien und Unverträglichkeiten": "Allergies and intolerances",
    "Kommagetrennt eingeben, z.B. 'Erdnüsse, Laktose'": "Enter comma-separated, e.g. 'Peanuts, Lactose'",
    "Los geht's": "Let's go",
    "Überspringen": "Skip",
    "Weiter": "Continue",
    "Zurück": "Back",
}

def translate_text(text):
    """Translate German text to English"""
    # Direct lookup
    if text in TRANSLATIONS:
        return TRANSLATIONS[text]
    
    # Try to find partial matches for dynamic content
    for de, en in TRANSLATIONS.items():
        if de in text or text in de:
            # For simple replacements with dynamic parts
            if "\\(" in text:  # Contains string interpolation
                # Keep interpolation syntax
                return en
    
    # Fallback: return original with warning
    print(f"  ⚠️  Manual translation needed: {text[:60]}...")
    return text

def main():
    print("=" * 70)
    print("Translating remaining strings")
    print("=" * 70)
    
    # Load English JSON
    with open(EN_JSON, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translated_count = 0
    remaining_count = 0
    
    # Process each entry
    for key, value in data.items():
        if '[TRANSLATE:' in value:
            # Extract German text
            match = re.search(r'\[TRANSLATE:\s*([^\]]+)\]', value)
            if match:
                german_text = match.group(1).strip()
                english_text = translate_text(german_text)
                
                # Update if translated
                if english_text != german_text:
                    data[key] = english_text
                    print(f"✓ {key}: {english_text}")
                    translated_count += 1
                else:
                    remaining_count += 1
    
    # Save updated JSON
    with open(EN_JSON, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n{'=' * 70}")
    print(f"Summary:")
    print(f"  Translated: {translated_count}")
    print(f"  Remaining (need manual): {remaining_count}")
    print(f"  Total keys: {len(data)}")
    print(f"{'=' * 70}")

if __name__ == '__main__':
    main()
