#!/bin/bash

# Script to create a user in Supabase via REST API
# Usage: ./scripts/create_supabase_user.sh <email> <password> [name]
# Example: ./scripts/create_supabase_user.sh reis@avrai.org avrai "Reis Gordon"

set -e

# Supabase configuration - from lib/supabase_config.dart
SUPABASE_URL="https://nfzlwgbvezwwrutqpedy.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5memx3Z2J2ZXp3d3J1dHFwZWR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MDU5MDUsImV4cCI6MjA3OTA4MTkwNX0.TimlFKPLvhF7NU1JmaiMVbkq0KxSJoiMlyhA8YIUef0"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <email> <password> [name]"
    echo ""
    echo "Example:"
    echo '  $0 reis@avrai.org avrai "Reis Gordon"'
    exit 1
fi

EMAIL="$1"
PASSWORD="$2"
NAME="${3:-${EMAIL%@*}}"

echo ""
echo "============================================================"
echo "Creating Supabase User"
echo "============================================================"
echo ""
echo "Email: $EMAIL"
echo "Name: $NAME"
echo "Password: $(printf '*%.0s' {1..${#PASSWORD}})"
echo ""

# Create JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "email": "$EMAIL",
  "password": "$PASSWORD",
  "data": {
    "name": "$NAME"
  }
}
EOF
)

# Make the API call
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "$SUPABASE_URL/auth/v1/signup")

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ User created successfully!"
    
    # Extract user info from response
    USER_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "N/A")
    USER_EMAIL=$(echo "$BODY" | grep -o '"email":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "N/A")
    
    echo "   User ID: $USER_ID"
    echo "   Email: $USER_EMAIL"
    
    # Check if email is confirmed
    if echo "$BODY" | grep -q '"email_confirmed_at":null'; then
        echo ""
        echo "⚠️  WARNING: Email confirmation required"
        echo "   The user will need to confirm their email before they can sign in."
        echo "   You can confirm the email in the Supabase dashboard:"
        echo "   Authentication → Users → Find user → Confirm email"
    else
        echo "   Email Confirmed: Yes"
    fi
    
    echo ""
    echo "============================================================"
    echo "✅ SUCCESS: User created"
    echo "============================================================"
    echo ""
    echo "You can now sign in with:"
    echo "  Email: $EMAIL"
    echo "  Password: $PASSWORD"
    echo ""
else
    echo "❌ ERROR: Failed to create user"
    echo "   HTTP Status: $HTTP_CODE"
    echo "   Response: $BODY"
    echo ""
    
    ERROR_MSG=$(echo "$BODY" | grep -o '"message":"[^"]*"' | cut -d'"' -f4 || echo "")
    
    if echo "$ERROR_MSG" | grep -qi "user already registered\|email already exists"; then
        echo "ℹ️  This email is already registered."
        echo "   Try signing in instead, or use a different email."
    elif echo "$ERROR_MSG" | grep -qi "password.*weak"; then
        echo "ℹ️  Password is too weak."
        echo "   Supabase requires stronger passwords."
    elif echo "$ERROR_MSG" | grep -qi "rate limit\|over_email_send_rate_limit"; then
        echo "ℹ️  Rate limit exceeded."
        echo "   Wait a few minutes and try again."
    fi
    
    exit 1
fi
