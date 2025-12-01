#!/bin/bash

# Navigate to the iOS directory
cd /Users/moritzserrin/CulinaChef/ios

# Run xcodegen generate
echo "Running xcodegen generate..."
xcodegen generate

# Fix Info.plist
echo "Running Info.plist fix script..."
./Widgets/fix_info_plist.sh

# Fix Entitlements
echo "Running Entitlements fix script..."
./Widgets/fix_entitlements.sh

# Check resource references
echo "Checking resource references..."
./scripts/fix_resources.sh

# Check SSL certificates (required for SSL pinning)
echo ""
echo "Checking SSL certificates..."
./scripts/fix_certificates.sh

echo ""
echo "✅ All fixes applied!"

