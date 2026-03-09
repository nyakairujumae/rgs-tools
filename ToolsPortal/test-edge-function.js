#!/usr/bin/env node

/**
 * Edge Function Direct Test Script (Node.js)
 * 
 * This script tests the send-push-notification Edge Function directly
 * to verify if push notifications work when sent from the Edge Function.
 * 
 * Usage:
 *   1. Update the configuration below with your values
 *   2. Run: node test-edge-function.js
 * 
 * Prerequisites:
 *   - Get your FCM token from Supabase Dashboard → Table Editor → user_fcm_tokens
 *   - Get your Supabase URL and Anon Key from Dashboard → Settings → API
 */

// ============================================
// CONFIGURATION - UPDATE THESE VALUES
// ============================================
const CONFIG = {
  SUPABASE_URL: 'https://YOUR_PROJECT_REF.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_KEY',
  FCM_TOKEN: 'YOUR_FCM_TOKEN_HERE',  // Get from user_fcm_tokens table
  USER_ID: 'YOUR_USER_ID_HERE',       // Optional: for testing with user_id
};

// ============================================
// TEST FUNCTIONS
// ============================================

/**
 * Test 1: Check if secrets are configured
 */
async function testSecrets() {
  console.log('1️⃣  Testing secrets configuration...\n');
  
  try {
    const url = `${CONFIG.SUPABASE_URL}/functions/v1/send-push-notification?test=secrets`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`,
      },
    });
    
    const data = await response.json();
    
    if (data.allSecretsSet) {
      console.log('✅ All secrets are configured correctly\n');
      console.log(JSON.stringify(data, null, 2));
      return true;
    } else {
      console.log('❌ Secrets are missing or misconfigured\n');
      console.log(JSON.stringify(data, null, 2));
      return false;
    }
  } catch (error) {
    console.error('❌ Error checking secrets:', error.message);
    return false;
  }
}

/**
 * Test 2: Send notification with FCM token directly
 */
async function testWithToken() {
  if (!CONFIG.FCM_TOKEN || CONFIG.FCM_TOKEN === 'YOUR_FCM_TOKEN_HERE') {
    console.log('⚠️  Skipping token test: FCM_TOKEN not configured\n');
    return;
  }
  
  console.log('2️⃣  Sending test notification with FCM token...\n');
  
  try {
    const url = `${CONFIG.SUPABASE_URL}/functions/v1/send-push-notification`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        token: CONFIG.FCM_TOKEN,
        title: '🧪 Test from Edge Function',
        body: 'This is a direct test from the Edge Function. If you see this, the Edge Function works!',
        data: {
          type: 'test',
          test_id: Date.now().toString(),
        },
      }),
    });
    
    const data = await response.json();
    
    if (response.ok && data.success) {
      console.log('✅ Notification sent successfully!\n');
      console.log('Response:', JSON.stringify(data, null, 2));
      console.log('\n📱 Check your device for the notification!');
      return true;
    } else {
      console.log(`❌ Notification failed (HTTP ${response.status})\n`);
      console.log('Response:', JSON.stringify(data, null, 2));
      return false;
    }
  } catch (error) {
    console.error('❌ Error sending notification:', error.message);
    return false;
  }
}

/**
 * Test 3: Send notification with user_id (fetches token from database)
 */
async function testWithUserId() {
  if (!CONFIG.USER_ID || CONFIG.USER_ID === 'YOUR_USER_ID_HERE') {
    console.log('⚠️  Skipping user_id test: USER_ID not configured\n');
    return;
  }
  
  console.log('3️⃣  Sending test notification with user_id...\n');
  
  try {
    const url = `${CONFIG.SUPABASE_URL}/functions/v1/send-push-notification`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${CONFIG.SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user_id: CONFIG.USER_ID,
        platform: 'android', // or 'ios', or omit for both
        title: '🧪 Test from Edge Function (via user_id)',
        body: 'This notification was sent using your user_id. The Edge Function fetched your token from the database.',
        data: {
          type: 'test',
          method: 'user_id',
        },
      }),
    });
    
    const data = await response.json();
    
    if (response.ok && data.success) {
      console.log('✅ Notification sent successfully via user_id!\n');
      console.log('Response:', JSON.stringify(data, null, 2));
      console.log('\n📱 Check your device for the notification!');
      return true;
    } else {
      console.log(`⚠️  Notification via user_id returned HTTP ${response.status}\n`);
      console.log('Response:', JSON.stringify(data, null, 2));
      return false;
    }
  } catch (error) {
    console.error('❌ Error sending notification with user_id:', error.message);
    return false;
  }
}

// ============================================
// MAIN EXECUTION
// ============================================

async function runTests() {
  console.log('🧪 Edge Function Direct Test');
  console.log('==============================\n');
  
  // Validate configuration
  if (CONFIG.SUPABASE_URL.includes('YOUR_PROJECT_REF') || 
      CONFIG.SUPABASE_ANON_KEY.includes('YOUR_SUPABASE_ANON_KEY')) {
    console.error('❌ Please update CONFIG with your Supabase credentials!');
    console.error('   Get them from: Supabase Dashboard → Settings → API\n');
    process.exit(1);
  }
  
  // Run tests
  const secretsOk = await testSecrets();
  console.log('');
  
  if (!secretsOk) {
    console.log('❌ Secrets are not configured. Please set them in:');
    console.log('   Supabase Dashboard → Settings → Edge Functions → Secrets\n');
    process.exit(1);
  }
  
  await testWithToken();
  console.log('');
  
  await testWithUserId();
  console.log('');
  
  console.log('==============================');
  console.log('✅ Test complete!');
  console.log('\n📊 Check Edge Function logs in Supabase Dashboard for detailed execution logs');
  console.log('📱 If you see the notification on your device, the Edge Function is working!');
}

// Run the tests
runTests().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});



