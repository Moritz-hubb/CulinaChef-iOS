#!/usr/bin/env python3
import json
from pathlib import Path

LOCALIZATION_DIR = Path("/Users/moritzserrin/CulinaChef/ios/Resources/Localization")

# Final remaining translations
FINAL_TRANSLATIONS = {
    "fr": {
        "Menge (optional)": "Quantité (optionnelle)",
        "Rezeptname *": "Nom de la recette *",
        "Portionen": "Portions",
        "Schritt": "Étape",
        "Zeit (Min)": "Temps (Min)",
        "Timer:": "Minuteur:",
        "Abo": "Abonnement",
        "Impressum\\n\\nPlatzhalter - Text hier einfügen": "Mentions légales\\n\\nPlaceholder - Insérer le texte ici",
        "6,99 €": "6,99 €",
        "Dein Rezept wurde erfolgreich gespeichert.": "Votre recette a été enregistrée avec succès.",
        "Foto hinzufügen": "Ajouter une photo",
        "Melden": "Signaler",
        "Rezept melden": "Signaler la recette",
        "Gemeldet": "Signalé",
        "Abo kündigen (keine weiteren Abbuchungen)": "Annuler l'abonnement (aucun prélèvement supplémentaire)",
        "Account": "Compte",
        "Allergien": "Allergies",
        "Aktuelles Passwort": "Mot de passe actuel",
        "Datenexport": "Export de données",
        "Ernährungsweisen": "Types d'alimentation",
        "dietaryTypesLabel": "Types de régime",
        "Abneigungen": "Aversions",
        "Nein": "Non",
        "Neue Passwörter stimmen nicht überein": "Les nouveaux mots de passe ne correspondent pas",
        "Passwort muss mindestens 6 Zeichen lang sein": "Le mot de passe doit contenir au moins 6 caractères",
        "E-Mail nicht gefunden": "E-mail introuvable",
        "Falsches Passwort oder Änderung fehlgeschlagen": "Mot de passe incorrect ou échec de la modification",
        "Neues Passwort": "Nouveau mot de passe",
        "Nächstes Mal": "Prochaine fois",
        "Status: Aktiv": "Statut: Actif",
        "Läuft aus am:": "Expire le:",
        "Perk Unlimited": "Avantage Illimité",
        "Perk Community": "Avantage Communauté",
        "Perk Tracking": "Avantage Suivi",
        "Perk Features": "Avantage Fonctionnalités",
        "Perk Secure": "Avantage Sécurisé",
        "Finanzielle Limits": "Limites financières",
        "In Ordnung": "D'accord",
        "Notizen": "Notes",
        "Benutzername": "Nom d'utilisateur",
        "Favoriten": "Favoris",
        "Bewertungen": "Évaluations",
        "Kein Netzwerk": "Pas de réseau",
        "Timeout": "Délai d'attente",
        "Nützlich": "Utile",
        "Schmeckt gut": "Bon goût",
        "Herausfordernd": "Challenging",
        "Mild": "Doux",
        "Normal": "Normal",
        "Scharf": "Épicé",
        "Sehr Scharf": "Très épicé",
        "Heiß": "Chaud",
        "Sehr heiß": "Très chaud",
        "süß": "sucré",
        "sauer": "acide",
        "bitter": "amer",
        "umami": "umami",
    },
    "it": {
        "Menge (optional)": "Quantità (opzionale)",
        "Rezeptname *": "Nome della ricetta *",
        "Portionen": "Porzioni",
        "Schritt": "Passaggio",
        "Zeit (Min)": "Tempo (Min)",
        "Timer:": "Timer:",
        "Abo": "Abbonamento",
        "Impressum\\n\\nPlatzhalter - Text hier einfügen": "Informazioni legali\\n\\nSegnaposto - Inserire il testo qui",
        "6,99 €": "6,99 €",
        "Dein Rezept wurde erfolgreich gespeichert.": "La tua ricetta è stata salvata con successo.",
        "Foto hinzufügen": "Aggiungi foto",
        "Melden": "Segnala",
        "Rezept melden": "Segnala ricetta",
        "Gemeldet": "Segnalato",
        "Abo kündigen (keine weiteren Abbuchungen)": "Annulla abbonamento (nessun addebito aggiuntivo)",
        "Account": "Account",
        "Allergien": "Allergie",
        "Aktuelles Passwort": "Password attuale",
        "Datenexport": "Esportazione dati",
        "Ernährungsweisen": "Tipi di alimentazione",
        "dietaryTypesLabel": "Tipi di dieta",
        "Abneigungen": "Avversioni",
        "Nein": "No",
        "Neue Passwörter stimmen nicht überein": "Le nuove password non corrispondono",
        "Passwort muss mindestens 6 Zeichen lang sein": "La password deve contenere almeno 6 caratteri",
        "E-Mail nicht gefunden": "E-mail non trovata",
        "Falsches Passwort oder Änderung fehlgeschlagen": "Password errata o modifica fallita",
        "Neues Passwort": "Nuova password",
        "Nächstes Mal": "Prossima volta",
        "Status: Aktiv": "Stato: Attivo",
        "Läuft aus am:": "Scade il:",
        "Perk Unlimited": "Vantaggio Illimitato",
        "Perk Community": "Vantaggio Comunità",
        "Perk Tracking": "Vantaggio Tracciamento",
        "Perk Features": "Vantaggio Funzionalità",
        "Perk Secure": "Vantaggio Sicuro",
        "Finanzielle Limits": "Limiti finanziari",
        "In Ordnung": "Va bene",
        "Notizen": "Note",
        "Benutzername": "Nome utente",
        "Favoriten": "Preferiti",
        "Bewertungen": "Valutazioni",
        "Kein Netzwerk": "Nessuna rete",
        "Timeout": "Timeout",
        "Nützlich": "Utile",
        "Schmeckt gut": "Buon sapore",
        "Herausfordernd": "Impegnativo",
        "Mild": "Dolce",
        "Normal": "Normale",
        "Scharf": "Piccante",
        "Sehr Scharf": "Molto piccante",
        "Heiß": "Caldo",
        "Sehr heiß": "Molto caldo",
        "süß": "dolce",
        "sauer": "acido",
        "bitter": "amaro",
        "umami": "umami",
    },
    "es": {
        "Menge (optional)": "Cantidad (opcional)",
        "Rezeptname *": "Nombre de la receta *",
        "Portionen": "Porciones",
        "Schritt": "Paso",
        "Zeit (Min)": "Tiempo (Min)",
        "Timer:": "Temporizador:",
        "Abo": "Suscripción",
        "Impressum\\n\\nPlatzhalter - Text hier einfügen": "Aviso legal\\n\\nMarcador de posición - Insertar texto aquí",
        "6,99 €": "6,99 €",
        "Dein Rezept wurde erfolgreich gespeichert.": "Tu receta se ha guardado con éxito.",
        "Foto hinzufügen": "Añadir foto",
        "Melden": "Reportar",
        "Rezept melden": "Reportar receta",
        "Gemeldet": "Reportado",
        "Abo kündigen (keine weiteren Abbuchungen)": "Cancelar suscripción (sin más cargos)",
        "Account": "Cuenta",
        "Allergien": "Alergias",
        "Aktuelles Passwort": "Contraseña actual",
        "Datenexport": "Exportación de datos",
        "Ernährungsweisen": "Tipos de alimentación",
        "dietaryTypesLabel": "Tipos de dieta",
        "Abneigungen": "Aversiones",
        "Nein": "No",
        "Neue Passwörter stimmen nicht überein": "Las nuevas contraseñas no coinciden",
        "Passwort muss mindestens 6 Zeichen lang sein": "La contraseña debe tener al menos 6 caracteres",
        "E-Mail nicht gefunden": "Correo electrónico no encontrado",
        "Falsches Passwort oder Änderung fehlgeschlagen": "Contraseña incorrecta o cambio fallido",
        "Neues Passwort": "Nueva contraseña",
        "Nächstes Mal": "Próxima vez",
        "Status: Aktiv": "Estado: Activo",
        "Läuft aus am:": "Vence el:",
        "Perk Unlimited": "Ventaja Ilimitado",
        "Perk Community": "Ventaja Comunidad",
        "Perk Tracking": "Ventaja Seguimiento",
        "Perk Features": "Ventaja Funciones",
        "Perk Secure": "Ventaja Seguro",
        "Finanzielle Limits": "Límites financieros",
        "In Ordnung": "De acuerdo",
        "Notizen": "Notas",
        "Benutzername": "Nombre de usuario",
        "Favoriten": "Favoritos",
        "Bewertungen": "Calificaciones",
        "Kein Netzwerk": "Sin red",
        "Timeout": "Tiempo de espera",
        "Nützlich": "Útil",
        "Schmeckt gut": "Buen sabor",
        "Herausfordernd": "Desafiante",
        "Mild": "Suave",
        "Normal": "Normal",
        "Scharf": "Picante",
        "Sehr Scharf": "Muy picante",
        "Heiß": "Caliente",
        "Sehr heiß": "Muy caliente",
        "süß": "dulce",
        "sauer": "ácido",
        "bitter": "amargo",
        "umami": "umami",
    }
}

def translate_value(value, lang):
    """Translate a value if it starts with [DE]"""
    if not value.startswith("[DE] "):
        return value
    
    german_text = value[5:]
    
    if german_text in FINAL_TRANSLATIONS.get(lang, {}):
        return FINAL_TRANSLATIONS[lang][german_text]
    
    return value

def process_file(filepath, lang):
    """Process a single localization file"""
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
        print(f"✅ {lang}.json: Translated {translated} additional keys, {remaining} remaining")
    else:
        print(f"⚠️  {lang}.json not found")

print("\n✅ Final translations complete!")
