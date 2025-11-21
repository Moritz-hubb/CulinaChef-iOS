#!/bin/bash
# SSL Certificate Download Script
# Downloads SSL certificates from Supabase and Backend for SSL pinning
#
# Usage:
#   1. Set SUPABASE_URL and BACKEND_URL environment variables, OR
#   2. Edit this script and set the URLs directly
#   3. Run: ./scripts/download_ssl_certificates.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
CERT_DIR="$IOS_DIR/Certificates"

# Create Certificates directory if it doesn't exist
mkdir -p "$CERT_DIR"

echo "🔐 SSL Certificate Download Script"
echo "===================================="
echo ""

# IMPORTANT: Set these URLs from your actual configuration
# You can get them from:
# - Supabase Dashboard → Settings → API → Project URL
# - Your backend deployment URL
SUPABASE_URL="${SUPABASE_URL:-}"
BACKEND_URL="${BACKEND_URL:-}"

# Try to read SUPABASE_URL from Secrets.xcconfig (if it exists)
if [ -z "$SUPABASE_URL" ] && [ -f "$IOS_DIR/Configs/Secrets.xcconfig" ]; then
    SUPABASE_URL=$(grep "SUPABASE_URL" "$IOS_DIR/Configs/Secrets.xcconfig" | cut -d'=' -f2 | tr -d ' ' | sed 's/\$()//g' | sed 's|https:/$()/|https://|')
fi

# Try to read BACKEND_URL from Config.swift (production URL)
if [ -z "$BACKEND_URL" ] && [ -f "$IOS_DIR/Sources/Services/Config.swift" ]; then
    BACKEND_URL=$(grep -A 5 "case .production:" "$IOS_DIR/Sources/Services/Config.swift" | grep "return URL" | sed -E 's/.*return URL\(string: "([^"]+)".*/\1/')
fi

# Fallback to default backend URL if still not set
if [ -z "$BACKEND_URL" ]; then
    BACKEND_URL="https://culinachef-backend-production.up.railway.app"
fi

if [ -z "$SUPABASE_URL" ]; then
    echo "❌ Error: SUPABASE_URL not set"
    echo "   Please set it as environment variable or in Configs/Secrets.xcconfig"
    echo "   Example: SUPABASE_URL=https://your-project.supabase.co ./scripts/download_ssl_certificates.sh"
    exit 1
fi

# Extract hostnames
SUPABASE_HOST=$(echo "$SUPABASE_URL" | sed -E 's|https?://([^/]+).*|\1|')
BACKEND_HOST=$(echo "$BACKEND_URL" | sed -E 's|https?://([^/]+).*|\1|')

echo "📥 Downloading certificates..."
echo "   Supabase: $SUPABASE_HOST"
echo "   Backend: $BACKEND_HOST"
echo ""

# Function to download certificate
download_cert() {
    local host=$1
    local output_file=$2
    
    echo "Downloading certificate for $host..."
    
    # Use openssl to get the certificate
    if echo | openssl s_client -showcerts -servername "$host" -connect "$host:443" 2>/dev/null | \
       openssl x509 -outform DER > "$output_file" 2>/dev/null; then
        echo "✅ Successfully downloaded: $output_file"
        # Show certificate info
        openssl x509 -in "$output_file" -inform DER -noout -subject -dates 2>/dev/null | sed 's/^/   /'
        return 0
    else
        echo "❌ Failed to download certificate for $host"
        echo "   Make sure the host is reachable and uses HTTPS"
        return 1
    fi
}

# Download Supabase certificate
if download_cert "$SUPABASE_HOST" "$CERT_DIR/supabase.cer"; then
    # Also copy to root for backward compatibility
    cp "$CERT_DIR/supabase.cer" "$IOS_DIR/supabase.cer"
    echo "   Also copied to: $IOS_DIR/supabase.cer"
fi

echo ""

# Download Backend certificate
if download_cert "$BACKEND_HOST" "$CERT_DIR/backend.cer"; then
    # Also copy to root for backward compatibility
    cp "$CERT_DIR/backend.cer" "$IOS_DIR/backend.cer"
    echo "   Also copied to: $IOS_DIR/backend.cer"
fi

echo ""
echo "✅ Certificate download complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Verify certificates are correct"
echo "   2. Rebuild the iOS app"
echo "   3. Test SSL pinning works correctly"
echo ""
echo "⚠️  IMPORTANT: These certificates are now in .gitignore"
echo "   They will NOT be committed to the repository."
