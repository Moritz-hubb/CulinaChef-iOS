#!/bin/bash

# Script to fix resource references in Xcode project after xcodegen generate
# This ensures that JSON localization files are properly referenced

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

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ${#MISSING_JSON[@]} -eq 0 ]; then
    echo "✅ All resource references are correct!"
    echo "✅ JSON files are properly referenced"
    exit 0
else
    echo "❌ Critical: JSON files are missing from project references:"
    echo "   ${MISSING_JSON[*]}"
    echo ""
    echo "💡 Solution: Run 'xcodegen generate' in the ios/ directory"
    echo "   The project.yml should be configured correctly to include these files."
    exit 1
fi

