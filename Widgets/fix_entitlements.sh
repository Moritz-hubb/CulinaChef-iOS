#!/bin/bash

# Script to ensure App Group is present in both entitlement files
# This is required for Widget Extensions to access shared UserDefaults

MAIN_ENTITLEMENTS="Configs/CulinaChef.entitlements"
WIDGET_ENTITLEMENTS="Configs/CulinaChefWidget.entitlements"
APP_GROUP="group.com.moritzserrin.culinachef"

fix_entitlements() {
    local file=$1
    local app_group=$2
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "❌ Error: $file does not exist"
        return 1
    fi
    
    # Check if App Group already exists and is correct (check both XML and binary formats)
    if grep -q "application-groups" "$file" 2>/dev/null && grep -q "$app_group" "$file" 2>/dev/null; then
        echo "✅ App Group already exists in $file"
        return 0
    fi
    
    # Only modify if we're not in a build context
    # Check if we're being called during a build (Xcode sets certain environment variables)
    if [ -n "$CONFIGURATION" ] || [ -n "$BUILD_DIR" ]; then
        echo "⚠️  Warning: Entitlements file needs update but we're in a build context"
        echo "   Run './Widgets/fix_all.sh' before building to fix entitlements"
        return 1
    fi
    
    echo "🔧 Adding App Group to $file..."
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Use Python to properly edit the plist, preserving XML format if it was XML
    python3 << EOF
import plistlib
import sys
import os

plist_path = "$file"
app_group = "$app_group"

try:
    # Check if file is XML format (read as text first)
    is_xml = False
    try:
        with open(plist_path, 'r', encoding='utf-8') as f:
            first_line = f.readline()
            if '<?xml' in first_line or '<plist' in first_line:
                is_xml = True
    except:
        pass
    
    # Load the plist
    with open(plist_path, 'rb') as f:
        plist = plistlib.load(f)
    
    # Check if App Group already exists
    existing_groups = plist.get('com.apple.security.application-groups', [])
    if app_group in existing_groups:
        print(f"✅ App Group already exists in {plist_path}")
        sys.exit(0)
    
    # Add App Group if not present
    if 'com.apple.security.application-groups' not in plist:
        plist['com.apple.security.application-groups'] = [app_group]
    else:
        plist['com.apple.security.application-groups'].append(app_group)
    
    # Write back in the same format (XML if it was XML, binary otherwise)
    if is_xml:
        # Write as XML
        with open(plist_path, 'wb') as f:
            plistlib.dump(plist, f, fmt=plistlib.FMT_XML)
    else:
        # Write as binary
        with open(plist_path, 'wb') as f:
            plistlib.dump(plist, f)
    
    print(f"✅ App Group added to {plist_path}")
        
except Exception as e:
    print(f"❌ Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF
}

# Fix both entitlement files
fix_entitlements "$MAIN_ENTITLEMENTS" "$APP_GROUP"
fix_entitlements "$WIDGET_ENTITLEMENTS" "$APP_GROUP"

echo "Entitlements fixed!"

