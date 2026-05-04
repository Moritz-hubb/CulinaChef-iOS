#!/bin/bash
# SSL Certificate & SPKI Hash Script
# Downloads SSL certificates and extracts SPKI (Subject Public Key Info) SHA-256 hashes
# for public key pinning in the iOS app.
#
# Usage:
#   1. Set SUPABASE_URL and BACKEND_URL environment variables, OR
#   2. Edit this script and set the URLs directly
#   3. Run: ./scripts/download_ssl_certificates.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
CERT_DIR="$IOS_DIR/Certificates"

mkdir -p "$CERT_DIR"

echo "🔐 SSL Certificate & SPKI Hash Script"
echo "======================================="
echo ""

SUPABASE_URL="${SUPABASE_URL:-}"
BACKEND_URL="${BACKEND_URL:-}"

if [ -z "$SUPABASE_URL" ] && [ -f "$IOS_DIR/Configs/Secrets.xcconfig" ]; then
    SUPABASE_URL=$(grep "SUPABASE_URL" "$IOS_DIR/Configs/Secrets.xcconfig" | cut -d'=' -f2 | tr -d ' ' | sed 's/\$()//g' | sed 's|https:/$()/|https://|')
fi

if [ -z "$BACKEND_URL" ] && [ -f "$IOS_DIR/Sources/Services/Config.swift" ]; then
    BACKEND_URL=$(grep -A 5 "case .production:" "$IOS_DIR/Sources/Services/Config.swift" | grep "return URL" | sed -E 's/.*return URL\(string: "([^"]+)".*/\1/')
fi

if [ -z "$BACKEND_URL" ]; then
    BACKEND_URL="https://culinachef-backend-production.up.railway.app"
fi

if [ -z "$SUPABASE_URL" ]; then
    echo "⚠️  Warning: SUPABASE_URL not set"
    echo "   Please set it as environment variable or in Configs/Secrets.xcconfig"
    echo ""
fi

SUPABASE_HOST=$(echo "$SUPABASE_URL" | sed -E 's|https?://([^/]+).*|\1|')
BACKEND_HOST=$(echo "$BACKEND_URL" | sed -E 's|https?://([^/]+).*|\1|')

echo "📥 Downloading certificates & extracting SPKI hashes..."
echo "   Backend:  $BACKEND_HOST"
if [ -n "$SUPABASE_HOST" ]; then
    echo "   Supabase: $SUPABASE_HOST"
fi
echo ""

# Downloads the leaf certificate and extracts the SPKI SHA-256 hash.
# Outputs the hash in base64 format (ready for Config.swift).
download_and_hash() {
    local host=$1
    local name=$2
    local output_file="$CERT_DIR/$name.cer"

    echo "━━━ $name ($host) ━━━"

    if ! echo | openssl s_client -showcerts -servername "$host" -connect "$host:443" 2>/dev/null | \
         openssl x509 -outform DER > "$output_file" 2>/dev/null; then
        echo "❌ Failed to download certificate for $host"
        return 1
    fi

    echo "✅ Certificate downloaded: $output_file"
    openssl x509 -in "$output_file" -inform DER -noout -subject -issuer -dates 2>/dev/null | sed 's/^/   /'

    # Extract SPKI SHA-256 hash (base64)
    local spki_hash
    spki_hash=$(openssl x509 -in "$output_file" -inform DER -pubkey -noout 2>/dev/null | \
                openssl pkey -pubin -outform DER 2>/dev/null | \
                openssl dgst -sha256 -binary 2>/dev/null | \
                base64)

    if [ -n "$spki_hash" ]; then
        echo ""
        echo "   🔑 SPKI SHA-256 (base64): $spki_hash"
        echo ""
        echo "   → Copy this hash into Config.swift:"
        echo "     Config.${name}PublicKeyHashes = ["
        echo "         \"$spki_hash\","
        echo "     ]"
    else
        echo "   ❌ Could not extract SPKI hash"
    fi

    # Copy .cer to Resources for bundle inclusion
    mkdir -p "$IOS_DIR/Resources/Certificates"
    cp "$output_file" "$IOS_DIR/Resources/Certificates/$name.cer"

    echo ""
    return 0
}

# Backend certificate
download_and_hash "$BACKEND_HOST" "backend"

# Supabase certificate (if URL is set)
if [ -n "$SUPABASE_HOST" ]; then
    download_and_hash "$SUPABASE_HOST" "supabase"
fi

echo ""
echo "✅ Done!"
echo ""
echo "📋 Next steps:"
echo "   1. Copy the SPKI hash(es) above into ios/Sources/Services/Config.swift"
echo "   2. Rebuild the iOS app"
echo "   3. Test that SSL pinning works"
echo ""
echo "💡 Tip: The app uses graceful degradation — if the pinned key rotates"
echo "   but the certificate is still system-trusted, connections will proceed"
echo "   with a warning logged. Update pins proactively to maintain strict pinning."
