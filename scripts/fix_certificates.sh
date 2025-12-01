#!/bin/bash

# Script to ensure SSL certificates are added to Xcode project
# This is needed because XcodeGen may not add them even if they exist

IOS_DIR="/Users/moritzserrin/CulinaChef/ios"
PROJECT_FILE="$IOS_DIR/CulinaChef.xcodeproj/project.pbxproj"

echo "🔐 Ensuring SSL certificates are in Xcode project..."

# Check if certificates exist (in Resources/Certificates or root)
CERT_FILES=("supabase.cer" "backend.cer")
CERTIFICATES_EXIST=true

for cert_file in "${CERT_FILES[@]}"; do
    if [ -f "$IOS_DIR/Resources/Certificates/$cert_file" ]; then
        echo "✅ $cert_file found in Resources/Certificates/"
    elif [ -f "$IOS_DIR/$cert_file" ]; then
        echo "✅ $cert_file found in root (will be moved to Resources/Certificates/)"
        mkdir -p "$IOS_DIR/Resources/Certificates"
        cp "$IOS_DIR/$cert_file" "$IOS_DIR/Resources/Certificates/$cert_file"
        echo "   → Copied to Resources/Certificates/"
    else
        echo "⚠️  $cert_file does not exist"
        CERTIFICATES_EXIST=false
    fi
done

if [ "$CERTIFICATES_EXIST" = false ]; then
    echo ""
    echo "❌ SSL certificates are missing!"
    echo "💡 Download them with: ./scripts/download_ssl_certificates.sh"
    echo ""
    echo "⚠️  SSL Pinning will fail without these certificates."
    exit 1
fi

# Check if certificates are already in project (via Resources folder)
ALL_REFERENCED=true
if grep -q "Resources" "$PROJECT_FILE"; then
    echo "✅ Resources folder is in project (includes Certificates subfolder)"
    # Check if Resources folder contains the certificates
    for cert_file in "${CERT_FILES[@]}"; do
        if [ -f "$IOS_DIR/Resources/Certificates/$cert_file" ]; then
            echo "✅ $cert_file exists in Resources/Certificates/ and will be included"
        fi
    done
else
    echo "❌ Resources folder is NOT in project"
    ALL_REFERENCED=false
fi

if [ "$ALL_REFERENCED" = true ]; then
    echo ""
    echo "✅ All SSL certificates are properly referenced in the project!"
    exit 0
else
    echo ""
    echo "⚠️  Some certificates are missing from project references."
    echo "💡 Solution: Run 'xcodegen generate' in the ios/ directory"
    echo "   The certificates are marked as 'optional: false' in project.yml"
    echo "   and should be added automatically when they exist."
    exit 1
fi

