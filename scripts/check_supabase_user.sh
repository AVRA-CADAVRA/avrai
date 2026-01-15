#!/bin/bash

# Script to check if a user exists in Supabase and can sign in
# Usage: ./scripts/check_supabase_user.sh <email> <password>

set -e

SUPABASE_URL="https://nfzlwgbvezwwrutqpedy.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5memx3Z2J2ZXp3d3J1dHFwZWR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MDU5MDUsImV4cCI6MjA3OTA4MTkwNX0.TimlFKPLvhF7NU1JmaiMVbkq0KxSJoiMlyhA8YIUef0"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <email> <password>"
    exit 1
fi

EMAIL="$1"
PASSWORD="$2"

echo "Checking if user can sign in..."
echo "Email: $EMAIL"
echo ""

JSON_PAYLOAD=$(cat <<EOF
{
  "email": "$EMAIL",
  "password": "$PASSWORD"
}
EOF
)

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "$SUPABASE_URL/auth/v1/token?grant_type=password")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ User exists and can sign in!"
    USER_ID=$(echo "$BODY" | grep -o '"user":{"id":"[^"]*"' | cut -d'"' -f6 || echo "N/A")
    echo "   User ID: $USER_ID"
    exit 0
else
    echo "❌ User cannot sign in (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
    exit 1
fi
