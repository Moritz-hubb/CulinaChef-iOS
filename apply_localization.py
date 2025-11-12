#!/usr/bin/env python3
"""
Systematic localization replacement tool
Generates keys, updates JSON files, and replaces strings in Swift files
"""

import re
import json
import os
from collections import defaultdict
from pathlib import Path
import hashlib

# Configuration
VIEWS_DIR = "/Users/moritzserrin/CulinaChef/ios/Sources/Views"
DE_JSON = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization/de.json"
EN_JSON = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization/en.json"
L_ENUM_FILE = "/Users/moritzserrin/CulinaChef/ios/Sources/Services/LocalizationManager.swift"

# Load existing translations
with open(DE_JSON, 'r', encoding='utf-8') as f:
    de_translations = json.load(f)

with open(EN_JSON, 'r', encoding='utf-8') as f:
    en_translations = json.load(f)

# Track used keys to avoid duplicates
used_keys = set(de_translations.keys())

def is_likely_german(text):
    """Check if text is likely German"""
    if text.startswith('L.') or text.startswith('$') or '\\(' in text:
        return False
    if '.' in text and ' ' not in text:
        return False
    
    german_indicators = ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü']
    has_german_char = any(c in text for c in german_indicators)
    
    german_words = ['und', 'oder', 'für', 'mit', 'von', 'zu', 'der', 'die', 'das', 'ein', 'eine', 'ist', 'sind', 'mein', 'dein', 'keine', 'alle', 'hinzu']
    has_german_word = any(word in text.lower() for word in german_words)
    
    return (has_german_char or has_german_word) and len(text) >= 2

def sanitize_key_part(text):
    """Sanitize text to create a valid key part"""
    # Remove special characters
    text = re.sub(r'[^\w\s]', '', text)
    # Convert to lowercase and limit words
    words = text.strip().lower().split()[:4]
    return '_'.join(words)[:35]

def generate_smart_key(text, filename):
    """Generate a smart localization key based on context"""
    # Determine context from filename
    context_map = {
        'Shopping': 'shopping',
        'Recipe': 'recipe',
        'Auth': 'auth',
        'Settings': 'settings',
        'Chat': 'chat',
        'Onboarding': 'onboarding',
        'Dietary': 'dietary',
        'Community': 'community',
        'Detail': 'detail',
    }
    
    context = 'ui'
    for key_part, ctx_name in context_map.items():
        if key_part in filename:
            context = ctx_name
            break
    
    # Generate base key
    base = sanitize_key_part(text)
    candidate = f"{context}.{base}"
    
    # Ensure uniqueness
    if candidate in used_keys:
        # Add hash suffix
        hash_suffix = hashlib.md5(text.encode()).hexdigest()[:4]
        candidate = f"{context}.{base}_{hash_suffix}"
    
    used_keys.add(candidate)
    return candidate

def translate_to_english(german_text):
    """Simple translation mapping for common phrases"""
    translations = {
        'Hinzufügen': 'Add',
        'Abbrechen': 'Cancel',
        'Fertig': 'Done',
        'Löschen': 'Delete',
        'Speichern': 'Save',
        'Bearbeiten': 'Edit',
        'Erstellen': 'Create',
        'Suchen': 'Search',
        'Fehler': 'Error',
        'Erfolgreich': 'Success',
        'Laden': 'Loading',
        'Keine': 'No',
        'Alle': 'All',
        'Meine': 'My',
        'Name': 'Name',
        'Zeit': 'Time',
        'Portionen': 'Servings',
        'Zutaten': 'Ingredients',
        'Anleitung': 'Instructions',
        'Schwierigkeit': 'Difficulty',
        'Kategorie': 'Category',
        'Einkaufsliste': 'Shopping List',
        'Rezept': 'Recipe',
        'Community': 'Community',
        'Profil': 'Profile',
        'Einstellungen': 'Settings',
    }
    
    # Try direct translation
    if german_text in translations:
        return translations[german_text]
    
    # Try word-by-word translation for short texts
    words = german_text.split()
    if len(words) <= 3:
        translated_words = [translations.get(w, w) for w in words]
        return ' '.join(translated_words)
    
    # Fallback: return original (will need manual translation)
    return f"[TRANSLATE: {german_text}]"

def process_file(filepath):
    """Process a single Swift file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    filename = Path(filepath).name
    
    # Find all Text("...") patterns
    pattern = r'Text\("([^"\\]*)"\)'
    
    replacements = []
    for match in re.finditer(pattern, content):
        text = match.group(1)
        if is_likely_german(text) and text not in ['', ' ']:
            key = generate_smart_key(text, filename)
            en_text = translate_to_english(text)
            
            # Store for JSON updates
            de_translations[key] = text
            en_translations[key] = en_text
            
            # Prepare replacement
            old = match.group(0)
            # Convert key to L enum format
            l_key = key.replace('.', '_').replace('-', '_')
            new = f'Text(L.{l_key}.localized)'
            
            replacements.append({
                'old': old,
                'new': new,
                'key': key,
                'l_key': l_key,
                'de': text,
                'en': en_text
            })
    
    # Apply replacements
    for rep in replacements:
        content = content.replace(rep['old'], rep['new'], 1)
    
    # Check if changed
    if content != original_content:
        return content, replacements
    else:
        return None, []

def update_l_enum(new_keys):
    """Update the L enum with new keys"""
    with open(L_ENUM_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the end of the L enum (before the closing brace)
    enum_pattern = r'(enum L \{.*?)(^})'
    match = re.search(enum_pattern, content, re.DOTALL | re.MULTILINE)
    
    if not match:
        print("Warning: Could not find L enum")
        return content
    
    enum_content = match.group(1)
    closing_brace = match.group(2)
    
    # Add new keys before the closing brace
    new_lines = []
    for key_data in new_keys:
        l_key = key_data['l_key']
        original_key = key_data['key']
        new_lines.append(f'    static let {l_key} = "{original_key}"')
    
    if new_lines:
        # Add a comment and new keys
        addition = '\n    // MARK: - Auto-generated Keys\n' + '\n'.join(new_lines) + '\n'
        new_content = content.replace(match.group(0), enum_content + addition + closing_brace)
        return new_content
    
    return content

def main():
    print("=" * 70)
    print("Systematic Localization Application")
    print("=" * 70)
    
    all_replacements = []
    files_modified = 0
    
    # Process all view files
    for swift_file in sorted(Path(VIEWS_DIR).glob('*.swift')):
        print(f"\nProcessing {swift_file.name}...")
        new_content, replacements = process_file(swift_file)
        
        if new_content:
            # Backup original
            backup_path = swift_file.with_suffix('.swift.backup')
            with open(backup_path, 'w', encoding='utf-8') as f:
                with open(swift_file, 'r', encoding='utf-8') as orig:
                    f.write(orig.read())
            
            # Write new content
            with open(swift_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            print(f"  ✓ Updated {len(replacements)} strings")
            files_modified += 1
            all_replacements.extend(replacements)
        else:
            print(f"  - No changes needed")
    
    # Update JSON files
    if all_replacements:
        print(f"\n{'=' * 70}")
        print(f"Writing updated JSON files...")
        
        with open(DE_JSON, 'w', encoding='utf-8') as f:
            json.dump(de_translations, f, ensure_ascii=False, indent=2)
        print(f"  ✓ Updated {DE_JSON}")
        
        with open(EN_JSON, 'w', encoding='utf-8') as f:
            json.dump(en_translations, f, ensure_ascii=False, indent=2)
        print(f"  ✓ Updated {EN_JSON}")
        
        # Update L enum
        print(f"\nUpdating L enum...")
        new_enum_content = update_l_enum(all_replacements)
        
        # Backup L enum
        backup_path = Path(L_ENUM_FILE).with_suffix('.swift.backup')
        with open(backup_path, 'w', encoding='utf-8') as f:
            with open(L_ENUM_FILE, 'r', encoding='utf-8') as orig:
                f.write(orig.read())
        
        with open(L_ENUM_FILE, 'w', encoding='utf-8') as f:
            f.write(new_enum_content)
        print(f"  ✓ Updated L enum with {len(all_replacements)} new keys")
    
    print(f"\n{'=' * 70}")
    print(f"Summary:")
    print(f"  Files modified: {files_modified}")
    print(f"  Total replacements: {len(all_replacements)}")
    print(f"  New localization keys: {len(all_replacements)}")
    print(f"\n  Backups created with .backup extension")
    print(f"={'=' * 70}")

if __name__ == '__main__':
    main()
