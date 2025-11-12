#!/usr/bin/env python3
"""
Sync localization files - adds missing keys from de.json to other language files
"""
import json
import sys
from pathlib import Path

LOCALIZATION_DIR = Path(__file__).parent / "Resources" / "Localization"
BASE_LANG = "de"
TARGET_LANGS = ["fr", "it", "es"]

def load_json(filepath):
    """Load JSON file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(filepath, data):
    """Save JSON file with proper formatting"""
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')  # Add trailing newline

def sync_localizations():
    """Sync all localization files with base language"""
    base_file = LOCALIZATION_DIR / f"{BASE_LANG}.json"
    if not base_file.exists():
        print(f"Error: Base file {base_file} not found")
        return False
    
    base_data = load_json(base_file)
    print(f"✅ Loaded {len(base_data)} keys from {BASE_LANG}.json")
    
    for lang in TARGET_LANGS:
        lang_file = LOCALIZATION_DIR / f"{lang}.json"
        if not lang_file.exists():
            print(f"⚠️  {lang}.json not found, creating new file")
            lang_data = {}
        else:
            lang_data = load_json(lang_file)
            print(f"📖 Loaded {len(lang_data)} existing keys from {lang}.json")
        
        # Find missing keys
        missing_keys = set(base_data.keys()) - set(lang_data.keys())
        
        if missing_keys:
            print(f"➕ Adding {len(missing_keys)} missing keys to {lang}.json")
            for key in sorted(missing_keys):
                # Use German text with [DE] prefix as placeholder
                lang_data[key] = f"[DE] {base_data[key]}"
        else:
            print(f"✅ {lang}.json is up to date")
        
        # Sort keys alphabetically
        lang_data = dict(sorted(lang_data.items()))
        
        # Save updated file
        save_json(lang_file, lang_data)
        print(f"💾 Saved {len(lang_data)} keys to {lang}.json")
        print()
    
    return True

if __name__ == "__main__":
    print("🔄 Syncing localization files...\n")
    success = sync_localizations()
    if success:
        print("✅ All localization files synced successfully!")
        print("\n⚠️  Note: New keys are marked with [DE] prefix and need manual translation")
        sys.exit(0)
    else:
        print("❌ Failed to sync localization files")
        sys.exit(1)
