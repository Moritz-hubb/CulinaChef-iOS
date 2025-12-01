#!/bin/bash

# Script to ensure NSExtension configuration is present in Info.plist
# This is required for Widget Extensions to work

INFO_PLIST="Widgets/Info.plist"

# Check if NSExtension already exists
if grep -q "NSExtension" "$INFO_PLIST"; then
    echo "NSExtension configuration already exists in Info.plist"
    exit 0
fi

# Create backup
cp "$INFO_PLIST" "$INFO_PLIST.backup"

# Add NSExtension configuration before closing </dict>
python3 << 'EOF'
import plistlib
import sys

plist_path = "Widgets/Info.plist"

try:
    with open(plist_path, 'rb') as f:
        plist = plistlib.load(f)
    
    # Add NSExtension if not present
    if 'NSExtension' not in plist:
        plist['NSExtension'] = {
            'NSExtensionPointIdentifier': 'com.apple.widgetkit-extension',
            'NSExtensionAttributes': {
                'WidgetKind': 'CulinaChefTimerWidget'
            }
        }
        
        with open(plist_path, 'wb') as f:
            plistlib.dump(plist, f)
        
        print("NSExtension configuration added to Info.plist")
    else:
        print("NSExtension configuration already exists")
        
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
EOF

