#!/bin/bash

# Backend Health-Check Script
# Testet ob dein Backend auf Railway läuft

echo "🔍 CulinaChef Backend Health-Check"
echo "=================================="
echo ""

# Ersetze mit deiner Railway URL oder Custom Domain
BACKEND_URL="https://api.culinaai.com"

echo "Testing: $BACKEND_URL"
echo ""

# Health Endpoint
echo "📡 Testing /health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BACKEND_URL/health" 2>&1)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Health check passed!"
    echo "   Response: $BODY"
else
    echo "❌ Health check failed!"
    echo "   HTTP Code: $HTTP_CODE"
    echo "   Response: $BODY"
fi

echo ""
echo "=================================="
echo "🎉 Test completed!"
echo ""
echo "Next steps:"
echo "1. If health check passed: Backend is ready!"
echo "2. Configure custom domain: api.culinaai.com"
echo "3. Test iOS app with production backend"
