#!/usr/bin/env python3
import json

localization_dir = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization"

# Legal UI keys - titles, navigation, and important notices
legal_keys = {
    # Common
    "legal.contractLanguageNotice": {
        "de": "Vertragssprache: Deutsch",
        "en": "Contract Language: German (legally binding)",
        "fr": "Langue du contrat : Allemand (juridiquement contraignant)",
        "it": "Lingua del contratto: Tedesco (legalmente vincolante)",
        "es": "Idioma del contrato: Alemán (jurídicamente vinculante)"
    },
    "legal.effectiveDate": {
        "de": "Stand: 04.11.2025",
        "en": "Effective: November 4, 2025",
        "fr": "En vigueur : 4 novembre 2025",
        "it": "Vigente dal: 4 novembre 2025",
        "es": "Vigente desde: 4 de noviembre de 2025"
    },
    "legal.version": {
        "de": "Version 1.0",
        "en": "Version 1.0",
        "fr": "Version 1.0",
        "it": "Versione 1.0",
        "es": "Versión 1.0"
    },
    
    # Terms of Service
    "legal.terms.title": {
        "de": "Allgemeine Geschäftsbedingungen (AGB)",
        "en": "Terms and Conditions",
        "fr": "Conditions Générales d'Utilisation (CGU)",
        "it": "Termini e Condizioni",
        "es": "Términos y Condiciones"
    },
    "legal.terms.subtitle": {
        "de": "für die App \"CulinaChef (CulinaAI)\"",
        "en": "for the App \"CulinaChef (CulinaAI)\"",
        "fr": "pour l'application \"CulinaChef (CulinaAI)\"",
        "it": "per l'App \"CulinaChef (CulinaAI)\"",
        "es": "para la App \"CulinaChef (CulinaAI)\""
    },
    "legal.terms.navTitle": {
        "de": "AGB",
        "en": "Terms",
        "fr": "CGU",
        "it": "Termini",
        "es": "Términos"
    },
    
    # Privacy Policy
    "legal.privacy.title": {
        "de": "Datenschutzerklärung",
        "en": "Privacy Policy",
        "fr": "Politique de Confidentialité",
        "it": "Informativa sulla Privacy",
        "es": "Política de Privacidad"
    },
    "legal.privacy.subtitle": {
        "de": "für die iOS-App \"CulinaChef (CulinaAI)\"",
        "en": "for the iOS App \"CulinaChef (CulinaAI)\"",
        "fr": "pour l'application iOS \"CulinaChef (CulinaAI)\"",
        "it": "per l'App iOS \"CulinaChef (CulinaAI)\"",
        "es": "para la App iOS \"CulinaChef (CulinaAI)\""
    },
    "legal.privacy.navTitle": {
        "de": "Datenschutz",
        "en": "Privacy",
        "fr": "Confidentialité",
        "it": "Privacy",
        "es": "Privacidad"
    },
    
    # Imprint
    "legal.imprint.title": {
        "de": "Impressum",
        "en": "Imprint",
        "fr": "Mentions Légales",
        "it": "Colophon",
        "es": "Aviso Legal"
    },
    "legal.imprint.navTitle": {
        "de": "Impressum",
        "en": "Imprint",
        "fr": "Mentions",
        "it": "Colophon",
        "es": "Aviso"
    },
    
    # Footer
    "legal.footer.date": {
        "de": "Stand: 04. November 2025",
        "en": "Effective: November 4, 2025",
        "fr": "En vigueur : 4 novembre 2025",
        "it": "Vigente dal: 4 novembre 2025",
        "es": "Vigente desde: 4 de noviembre de 2025"
    },
    
    # Fair Use Link
    "legal.fairUseLink": {
        "de": "Fair Use Policy ansehen",
        "en": "View Fair Use Policy",
        "fr": "Voir la Politique d'utilisation équitable",
        "it": "Visualizza la Fair Use Policy",
        "es": "Ver Política de Uso Justo"
    },
    
    # Language Notice (prominent display)
    "legal.languageNotice": {
        "de": "Diese Dokumente sind auf Deutsch verfasst. Die deutsche Version ist rechtlich bindend.",
        "en": "These documents are written in German. The German version is legally binding.",
        "fr": "Ces documents sont rédigés en allemand. La version allemande est juridiquement contraignante.",
        "it": "Questi documenti sono scritti in tedesco. La versione tedesca è legalmente vincolante.",
        "es": "Estos documentos están escritos en alemán. La versión alemana es legalmente vinculante."
    }
}

languages = ["de", "en", "fr", "it", "es"]

for lang in languages:
    file_path = f"{localization_dir}/{lang}.json"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Add new keys
    for key, translations in legal_keys.items():
        data[key] = translations[lang]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"Updated {lang}.json")

print("\nAll legal UI localization keys added successfully!")
print(f"Total keys added: {len(legal_keys)}")
