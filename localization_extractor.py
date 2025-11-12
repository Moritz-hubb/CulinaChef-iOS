#!/usr/bin/env python3
"""
Systematic localization extraction and replacement tool
Extracts hardcoded German strings from Swift files and generates localization keys
"""

import re
import json
import os
from collections import defaultdict
from pathlib import Path

# Configuration
VIEWS_DIR = "/Users/moritzserrin/CulinaChef/ios/Sources/Views"
DE_JSON = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization/de.json"
EN_JSON = "/Users/moritzserrin/CulinaChef/ios/Resources/Localization/en.json"

# Patterns to match hardcoded strings
PATTERNS = [
    # Text("String")
    (r'Text\("([^"]+)"\)', 'text'),
    # .alert("String", ...)
    (r'\.alert\("([^"]+)"', 'alert'),
    # Button("String")
    (r'Button\("([^"]+)"\)', 'button'),
    # .navigationTitle("String")
    (r'\.navigationTitle\("([^"]+)"\)', 'nav_title'),
    # placeholder: "String"
    (r'placeholder:\s*"([^"]+)"', 'placeholder'),
    # Label("String", ...)
    (r'Label\("([^"]+)"', 'label'),
]

def is_likely_german(text):
    """Check if text is likely German (not variable names, not English-only)"""
    # Skip if it looks like a variable or key
    if text.startswith('L.') or text.startswith('$'):
        return False
    
    # Skip if it's already a localization key pattern
    if '.' in text and not ' ' in text:
        return False
    
    # German indicators
    german_indicators = ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü']
    has_german_char = any(c in text for c in german_indicators)
    
    # Common German words
    german_words = ['und', 'oder', 'für', 'mit', 'von', 'zu', 'der', 'die', 'das', 'ein', 'eine', 'ist', 'sind']
    has_german_word = any(word in text.lower() for word in german_words)
    
    return has_german_char or has_german_word or len(text) > 3

def generate_key(text, context='general'):
    """Generate a localization key from text"""
    # Clean text
    clean = re.sub(r'[^\w\s]', '', text)
    clean = clean.strip().lower()
    
    # Take first 3-4 words
    words = clean.split()[:4]
    key_suffix = '_'.join(words)
    
    # Limit length
    if len(key_suffix) > 40:
        key_suffix = key_suffix[:40]
    
    return f"{context}.{key_suffix}"

def extract_strings_from_file(filepath):
    """Extract all hardcoded German strings from a Swift file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    found_strings = []
    
    for pattern, context in PATTERNS:
        matches = re.finditer(pattern, content)
        for match in matches:
            text = match.group(1)
            if is_likely_german(text):
                found_strings.append({
                    'text': text,
                    'context': context,
                    'pattern': pattern,
                    'full_match': match.group(0)
                })
    
    return found_strings

def extract_all_strings():
    """Extract strings from all view files"""
    all_strings = defaultdict(list)
    
    for swift_file in Path(VIEWS_DIR).glob('*.swift'):
        strings = extract_strings_from_file(swift_file)
        if strings:
            all_strings[swift_file.name] = strings
            print(f"Found {len(strings)} strings in {swift_file.name}")
    
    return all_strings

def main():
    print("=" * 60)
    print("Systematic Localization Extraction")
    print("=" * 60)
    
    # Extract all strings
    all_strings = extract_all_strings()
    
    # Summarize findings
    total = sum(len(strings) for strings in all_strings.values())
    print(f"\nTotal hardcoded German strings found: {total}")
    print(f"Files with strings: {len(all_strings)}")
    
    # Show top files
    print("\nTop files by string count:")
    sorted_files = sorted(all_strings.items(), key=lambda x: len(x[1]), reverse=True)
    for filename, strings in sorted_files[:10]:
        print(f"  {filename}: {len(strings)} strings")
    
    # Export to JSON for review
    output_file = "/Users/moritzserrin/CulinaChef/ios/extracted_strings.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({k: [s['text'] for s in v] for k, v in all_strings.items()}, f, ensure_ascii=False, indent=2)
    
    print(f"\nExtracted strings saved to: {output_file}")
    
    return all_strings

if __name__ == '__main__':
    main()
