#!/bin/bash

# Edge Function Direct Test Script
# This script tests the send-push-notification Edge Function directly

# ============================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================
SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY"
FCM_TOKEN="YOUR_FCM_TOKEN_HERE"  # Get from user_fcm_tokens table
USER_ID="YOUR_USER_ID_HERE"       # Optional: if you want to test with user_id instead

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Edge Function Direct Test"
echo "=============================="
echo ""

# Test 1: Check secrets configuration
echo "1️⃣ Testing secrets configuration..."
SECRETS_RESPONSE=$(curl -s "${SUPABASE_URL}/functions/v1/send-push-notification?test=secrets" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}")

if echo "$SECRETS_RESPONSE" | grep -q '"allSecretsSet":true'; then
  echo -e "${GREEN}✅ All secrets are configured${NC}"
  echo "$SECRETS_RESPONSE" | jq '.' 2>/dev/null || echo "$SECRETS_RESPONSE"
else
  echo -e "${RED}❌ Secrets are missing or misconfigured${NC}"
  echo "$SECRETS_RESPONSE" | jq '.' 2>/dev/null || echo "$SECRETS_RESPONSE"
  exit 1
fi

echo ""
echo "2️⃣ Sending test notification..."

# Test 2: Send notification with FCM token
if [ -n "$FCM_TOKEN" ] && [ "$FCM_TOKEN" != "YOUR_FCM_TOKEN_HERE" ]; then
  echo "   Using FCM token directly..."
  NOTIFICATION_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/send-push-notification" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"token\": \"${FCM_TOKEN}\",
      \"title\": \"🧪 Test from Edge Function\",
      \"body\": \"This is a direct test from the Edge Function. If you see this, the Edge Function works!\",
      \"data\": {
        \"type\": \"test\",
        \"test_id\": \"$(date +%s)\"
      }
    }")
  
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${SUPABASE_URL}/functions/v1/send-push-notification" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"token\": \"${FCM_TOKEN}\",
      \"title\": \"Test\",
      \"body\": \"Test\"
    }")

  if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Notification sent successfully (HTTP 200)${NC}"
    echo "$NOTIFICATION_RESPONSE" | jq '.' 2>/dev/null || echo "$NOTIFICATION_RESPONSE"
  else
    echo -e "${RED}❌ Notification failed (HTTP $HTTP_STATUS)${NC}"
    echo "$NOTIFICATION_RESPONSE" | jq '.' 2>/dev/null || echo "$NOTIFICATION_RESPONSE"
  fi
fi

# Test 3: Send notification with user_id (if provided)
if [ -n "$USER_ID" ] && [ "$USER_ID" != "YOUR_USER_ID_HERE" ]; then
  echo ""
  echo "3️⃣ Testing with user_id (fetches token from database)..."
  USER_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/send-push-notification" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"user_id\": \"${USER_ID}\",
      \"title\": \"🧪 Test from Edge Function (via user_id)\",
      \"body\": \"This notification was sent using your user_id. The Edge Function fetched your token from the database.\",
      \"data\": {
        \"type\": \"test\",
        \"method\": \"user_id\"
      }
    }")
  
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${SUPABASE_URL}/functions/v1/send-push-notification" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"user_id\": \"${USER_ID}\",
      \"title\": \"Test\",
      \"body\": \"Test\"
    }")

  if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Notification sent successfully via user_id (HTTP 200)${NC}"
    echo "$USER_RESPONSE" | jq '.' 2>/dev/null || echo "$USER_RESPONSE"
  else
    echo -e "${YELLOW}⚠️  Notification via user_id returned HTTP $HTTP_STATUS${NC}"
    echo "$USER_RESPONSE" | jq '.' 2>/dev/null || echo "$USER_RESPONSE"
  fi
fi

echo ""
echo "=============================="
echo "✅ Test complete!"
echo ""
echo "📱 Check your device for the notification"
echo "📊 Check Edge Function logs in Supabase Dashboard for detailed execution logs"
echo ""
echo "If you see the notification on your device, the Edge Function is working correctly!"
echo "If not, check the logs for error messages."



