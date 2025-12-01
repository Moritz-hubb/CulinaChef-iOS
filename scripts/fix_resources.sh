#!/bin/bash

# Script to fix resource references in Xcode project after xcodegen generate
# This ensures that JSON localization files and certificates are properly referenced

IOS_DIR="/Users/moritzserrin/CulinaChef/ios"
PROJECT_FILE="$IOS_DIR/CulinaChef.xcodeproj/project.pbxproj"

echo "🔧 Fixing resource references in Xcode project..."

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

# Function to check if a file reference exists in the project
check_file_reference() {
    local file_name=$1
    if grep -q "$file_name" "$PROJECT_FILE"; then
        echo "✅ $file_name is referenced in project"
        return 0
    else
        echo "❌ $file_name is NOT referenced in project"
        return 1
    fi
}

# Check JSON files (now in Resources/Localization/)
echo ""
echo "📄 Checking JSON localization files..."
JSON_FILES=("de.json" "en.json" "es.json" "fr.json" "it.json")
MISSING_JSON=()

for json_file in "${JSON_FILES[@]}"; do
    # Check in Resources/Localization/ (new location)
    if [ -f "$IOS_DIR/Resources/Localization/$json_file" ]; then
        # Check if Resources folder is referenced (which includes Localization subfolder)
        if grep -q "Resources" "$PROJECT_FILE"; then
            echo "✅ $json_file is in Resources/Localization/ and Resources folder is referenced"
        else
            echo "❌ Resources folder is NOT referenced in project"
            MISSING_JSON+=("$json_file")
        fi
    # Check in root (old location, for backward compatibility)
    elif [ -f "$IOS_DIR/$json_file" ]; then
        if ! check_file_reference "$json_file"; then
            MISSING_JSON+=("$json_file")
        fi
    else
        echo "⚠️  $json_file does not exist (will be created if needed)"
    fi
done

# Check certificate files (in Resources/Certificates/ - REQUIRED for SSL pinning)
echo ""
echo "🔐 Checking certificate files (REQUIRED for SSL pinning)..."
CERT_FILES=("supabase.cer" "backend.cer")
MISSING_CERTS=()
EXISTING_CERTS_NOT_REFERENCED=()

for cert_file in "${CERT_FILES[@]}"; do
    # Check in Resources/Certificates/ (new location - automatically included via Resources folder)
    if [ -f "$IOS_DIR/Resources/Certificates/$cert_file" ]; then
        # Resources folder is referenced, so certificates are automatically included
        if grep -q "Resources" "$PROJECT_FILE"; then
            echo "✅ $cert_file found in Resources/Certificates/ and will be included via Resources folder"
        else
            echo "❌ $cert_file exists in Resources/Certificates/ but Resources folder is NOT in project"
            EXISTING_CERTS_NOT_REFERENCED+=("$cert_file")
        fi
    # Check in root (old location - for backward compatibility)
    elif [ -f "$IOS_DIR/$cert_file" ]; then
        echo "⚠️  $cert_file found in root - moving to Resources/Certificates/ for automatic inclusion"
        mkdir -p "$IOS_DIR/Resources/Certificates"
        cp "$IOS_DIR/$cert_file" "$IOS_DIR/Resources/Certificates/$cert_file"
        echo "   → Copied to Resources/Certificates/"
        if grep -q "Resources" "$PROJECT_FILE"; then
            echo "✅ $cert_file is now in Resources/Certificates/ and will be included"
        else
            echo "❌ Resources folder is NOT in project"
            EXISTING_CERTS_NOT_REFERENCED+=("$cert_file")
        fi
    else
        echo "❌ $cert_file does not exist - REQUIRED for SSL pinning!"
        echo "   Download with: ./scripts/download_ssl_certificates.sh"
        MISSING_CERTS+=("$cert_file")
    fi
done

# Check Certificates folder in Resources
echo ""
echo "📁 Checking Certificates folder in Resources..."
if [ -d "$IOS_DIR/Resources/Certificates" ]; then
    if grep -q "Resources" "$PROJECT_FILE"; then
        echo "✅ Resources/Certificates/ folder exists and will be included via Resources folder"
    else
        echo "❌ Resources folder is NOT in project"
        EXISTING_CERTS_NOT_REFERENCED+=("Resources/Certificates")
    fi
else
    echo "⚠️  Resources/Certificates/ folder does not exist"
    if [ ${#MISSING_CERTS[@]} -eq 0 ]; then
        echo "   Creating folder..."
        mkdir -p "$IOS_DIR/Resources/Certificates"
    fi
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ${#MISSING_JSON[@]} -eq 0 ] && [ ${#MISSING_CERTS[@]} -eq 0 ] && [ ${#EXISTING_CERTS_NOT_REFERENCED[@]} -eq 0 ]; then
    echo "✅ All resource references are correct!"
    echo "✅ JSON files are properly referenced"
    echo "✅ SSL certificates are properly referenced (REQUIRED for SSL pinning)"
    exit 0
else
    if [ ${#MISSING_JSON[@]} -gt 0 ]; then
        echo "❌ Critical: JSON files are missing from project references:"
        echo "   ${MISSING_JSON[*]}"
        echo ""
        echo "💡 Solution: Run 'xcodegen generate' in the ios/ directory"
        echo "   The project.yml should be configured correctly to include these files."
        exit 1
    fi
    
    if [ ${#MISSING_CERTS[@]} -gt 0 ]; then
        echo "❌ Critical: SSL certificates are missing (REQUIRED for SSL pinning):"
        echo "   ${MISSING_CERTS[*]}"
        echo ""
        echo "💡 Solution: Download certificates with:"
        echo "   ./scripts/download_ssl_certificates.sh"
        echo ""
        echo "   Then run 'xcodegen generate' again."
        exit 1
    fi
    
    if [ ${#EXISTING_CERTS_NOT_REFERENCED[@]} -gt 0 ]; then
        echo "❌ Critical: SSL certificates exist but are not properly referenced:"
        echo "   ${EXISTING_CERTS_NOT_REFERENCED[*]}"
        echo ""
        echo "💡 Solution: Run 'xcodegen generate' in the ios/ directory"
        echo "   Certificates should be in Resources/Certificates/ to be automatically included."
        exit 1
    fi
fi

