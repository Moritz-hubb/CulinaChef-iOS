#!/usr/bin/env python3
"""
Add @ObservedObject localizationManager to all views that use localization
"""

import re
from pathlib import Path

VIEWS_DIR = "/Users/moritzserrin/CulinaChef/ios/Sources/Views"

def needs_observer(content):
    """Check if file uses L.*.localized but doesn't have observer"""
    has_localization = 'L.' in content and '.localized' in content
    has_observer = '@ObservedObject private var localizationManager' in content
    return has_localization and not has_observer

def add_observer_to_view(content):
    """Add observer declaration to a View struct"""
    # Pattern: struct SomeView: View {
    #          @EnvironmentObject...
    #          @State...
    
    # Find the first property declaration after struct ... : View {
    pattern = r'(struct\s+\w+\s*:\s*View\s*\{)'
    
    match = re.search(pattern, content)
    if not match:
        return None
    
    # Find position after the opening brace
    insert_pos = match.end()
    
    # Look ahead to see if there are already property declarations
    after_match = content[insert_pos:insert_pos+200]
    
    # Check if next non-whitespace line is a property
    lines_after = after_match.split('\n')
    
    indent = '    '  # Default 4 spaces
    insert_newline = '\n'
    
    # If first line has content, we need to insert on a new line
    if lines_after[0].strip():
        insert_newline = '\n    '
    
    # Insert the observer
    observer_line = '@ObservedObject private var localizationManager = LocalizationManager.shared'
    
    new_content = (
        content[:insert_pos] + 
        insert_newline + 
        observer_line + 
        '\n' +
        content[insert_pos:]
    )
    
    return new_content

def process_file(filepath):
    """Process a single Swift file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if needs_observer(content):
        new_content = add_observer_to_view(content)
        if new_content:
            return new_content
    
    return None

def main():
    print("=" * 70)
    print("Adding LocalizationManager Observers")
    print("=" * 70)
    
    files_modified = 0
    
    for swift_file in sorted(Path(VIEWS_DIR).glob('*.swift')):
        new_content = process_file(swift_file)
        
        if new_content:
            # Backup
            backup_path = swift_file.with_suffix('.swift.observer_backup')
            with open(swift_file, 'r', encoding='utf-8') as f:
                with open(backup_path, 'w', encoding='utf-8') as backup:
                    backup.write(f.read())
            
            # Write new content
            with open(swift_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            print(f"✓ {swift_file.name}")
            files_modified += 1
        else:
            print(f"- {swift_file.name} (no changes)")
    
    print(f"\n{'=' * 70}")
    print(f"Summary: {files_modified} files modified")
    print(f"{'=' * 70}")

if __name__ == '__main__':
    main()
