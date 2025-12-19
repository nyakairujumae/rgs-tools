// Supabase Edge Function to send FCM push notifications using v1 API
// Uses GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY, and GOOGLE_PROJECT_ID from secrets

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GOOGLE_PROJECT_ID = Deno.env.get("GOOGLE_PROJECT_ID");
const GOOGLE_CLIENT_EMAIL = Deno.env.get("GOOGLE_CLIENT_EMAIL");
const GOOGLE_PRIVATE_KEY = Deno.env.get("GOOGLE_PRIVATE_KEY");
const FCM_V1_URL = `https://fcm.googleapis.com/v1/projects/${GOOGLE_PROJECT_ID}/messages:send`;

// Generate OAuth2 access token from service account credentials
async function getAccessToken(): Promise<string> {
  const jwt = await createJWT();
  
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    let errorData;
    try {
      errorData = JSON.parse(errorText);
    } catch {
      errorData = { error: errorText };
    }
    
    console.error("❌ OAuth2 token request failed");
    console.error("❌ Status:", tokenResponse.status, tokenResponse.statusText);
    console.error("❌ Error response:", errorData);
    
    throw new Error(`Failed to get OAuth2 access token (${tokenResponse.status}): ${JSON.stringify(errorData)}`);
  }

  const tokenData = await tokenResponse.json();
  console.log("✅ OAuth2 access token obtained successfully");
  console.log("✅ Token type:", tokenData.token_type || "Bearer");
  console.log("✅ Token expires in:", tokenData.expires_in || "unknown", "seconds");
  console.log("✅ Access token length:", tokenData.access_token?.length || 0);
  console.log("✅ Access token preview:", tokenData.access_token ? `${tokenData.access_token.substring(0, 30)}...` : "MISSING");
  console.log("✅ Token scope:", tokenData.scope || "not provided in response");
  
  if (!tokenData.access_token) {
    throw new Error("OAuth2 response missing access_token");
  }
  
  // Verify token format
  if (!tokenData.access_token.startsWith("ya29.") && !tokenData.access_token.startsWith("1//")) {
    console.warn("⚠️ Token doesn't start with expected prefix - might be invalid");
  }
  
  // Test token by calling Google OAuth2 tokeninfo endpoint
  try {
    const tokenInfoResponse = await fetch(`https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=${tokenData.access_token}`);
    if (tokenInfoResponse.ok) {
      const tokenInfo = await tokenInfoResponse.json();
      console.log("✅ Token validated successfully");
      console.log("✅ Token info - email:", tokenInfo.email || "N/A");
      console.log("✅ Token info - scope:", tokenInfo.scope || "N/A");
      console.log("✅ Token info - expires_in:", tokenInfo.expires_in || "N/A");
    } else {
      console.warn("⚠️ Token validation failed:", await tokenInfoResponse.text());
    }
  } catch (tokenInfoError) {
    console.warn("⚠️ Could not validate token:", tokenInfoError);
  }
  
  return tokenData.access_token;
}

// Create JWT for service account authentication
async function createJWT(): Promise<string> {
  if (!GOOGLE_CLIENT_EMAIL || !GOOGLE_PRIVATE_KEY) {
    throw new Error("GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be set");
  }

  console.log("🔐 Creating JWT for service account:", GOOGLE_CLIENT_EMAIL.substring(0, 30) + "...");
  console.log("🔐 Private key length:", GOOGLE_PRIVATE_KEY.length);
  console.log("🔐 Private key starts with:", GOOGLE_PRIVATE_KEY.substring(0, 50));

  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600; // 1 hour

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const payload = {
    iss: GOOGLE_CLIENT_EMAIL,
    sub: GOOGLE_CLIENT_EMAIL,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: expiry,
    // Use cloud-platform scope which includes FCM messaging
    scope: "https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/firebase.messaging",
  };
  
  console.log("🔐 JWT payload created for scope: firebase.messaging");
  console.log("🔐 JWT payload:", JSON.stringify(payload, null, 2));

  // Base64 URL encode
  const base64UrlEncode = (str: string): string => {
    return btoa(str)
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));

  // Sign with private key
  const message = `${encodedHeader}.${encodedPayload}`;
  
  // Decode private key (handle both with and without newlines)
  let privateKey = GOOGLE_PRIVATE_KEY.replace(/\\n/g, "\n");
  
  // Ensure the key has proper BEGIN/END markers
  if (!privateKey.includes("BEGIN PRIVATE KEY")) {
    console.error("❌ Private key missing BEGIN PRIVATE KEY marker");
    throw new Error("Invalid private key format: missing BEGIN PRIVATE KEY marker");
  }
  if (!privateKey.includes("END PRIVATE KEY")) {
    console.error("❌ Private key missing END PRIVATE KEY marker");
    throw new Error("Invalid private key format: missing END PRIVATE KEY marker");
  }
  
  console.log("🔐 Private key format validated");
  
  // Import key and sign
  let keyData: CryptoKey;
  try {
    keyData = await crypto.subtle.importKey(
      "pkcs8",
      pemToArrayBuffer(privateKey),
      {
        name: "RSASSA-PKCS1-v1_5",
        hash: "SHA-256",
      },
      false,
      ["sign"]
    );
    console.log("✅ Private key imported successfully");
  } catch (keyError: any) {
    console.error("❌ Failed to import private key:", keyError);
    throw new Error(`Failed to import private key: ${keyError?.message || "Unknown error"}. Make sure the GOOGLE_PRIVATE_KEY is in correct PEM format.`);
  }

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    keyData,
    new TextEncoder().encode(message)
  );

  const encodedSignature = base64UrlEncode(
    String.fromCharCode(...new Uint8Array(signature))
  );

  return `${message}.${encodedSignature}`;
}

// Convert PEM to ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

serve(async (req) => {
  try {
    // Handle test endpoint to verify secrets
    if (req.method === "GET" && new URL(req.url).searchParams.get("test") === "secrets") {
      const secretsStatus = {
        GOOGLE_PROJECT_ID: GOOGLE_PROJECT_ID ? `✅ Set (${GOOGLE_PROJECT_ID})` : "❌ Missing",
        GOOGLE_CLIENT_EMAIL: GOOGLE_CLIENT_EMAIL ? `✅ Set (${GOOGLE_CLIENT_EMAIL.substring(0, 30)}...)` : "❌ Missing",
        GOOGLE_PRIVATE_KEY: GOOGLE_PRIVATE_KEY ? `✅ Set (${GOOGLE_PRIVATE_KEY.length} chars, starts with: ${GOOGLE_PRIVATE_KEY.substring(0, 30)}...)` : "❌ Missing",
        privateKeyHasBegin: GOOGLE_PRIVATE_KEY?.includes("BEGIN PRIVATE KEY") ? "✅ Yes" : "❌ No",
        privateKeyHasEnd: GOOGLE_PRIVATE_KEY?.includes("END PRIVATE KEY") ? "✅ Yes" : "❌ No",
      };
      
      return new Response(
        JSON.stringify({
          message: "Secrets status check",
          secrets: secretsStatus,
          allSecretsSet: !!GOOGLE_PROJECT_ID && !!GOOGLE_CLIENT_EMAIL && !!GOOGLE_PRIVATE_KEY,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
    
    // Get request body
    const { token, title, body, data } = await req.json();
    
    // Validate required fields
    if (!token || !title || !body) {
      return new Response(
        JSON.stringify({ 
          error: "Missing required fields: token, title, and body are required" 
        }),
        { 
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
    
    // Check if required secrets are configured
    if (!GOOGLE_PROJECT_ID) {
      console.error("GOOGLE_PROJECT_ID not configured in Supabase secrets");
      return new Response(
        JSON.stringify({ 
          error: "GOOGLE_PROJECT_ID not configured. Please add it in Supabase Dashboard → Settings → Edge Functions → Secrets" 
        }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
    
    if (!GOOGLE_CLIENT_EMAIL || !GOOGLE_PRIVATE_KEY) {
      console.error("GOOGLE_CLIENT_EMAIL or GOOGLE_PRIVATE_KEY not configured");
      return new Response(
        JSON.stringify({ 
          error: "GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured in Supabase secrets" 
        }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
    
    // Get OAuth2 access token
    let accessToken: string;
    try {
      console.log("🔐 Attempting to get OAuth2 access token...");
      console.log("🔐 GOOGLE_PROJECT_ID:", GOOGLE_PROJECT_ID ? "✅ Set" : "❌ Missing");
      console.log("🔐 GOOGLE_CLIENT_EMAIL:", GOOGLE_CLIENT_EMAIL ? `✅ Set (${GOOGLE_CLIENT_EMAIL.substring(0, 30)}...)` : "❌ Missing");
      console.log("🔐 GOOGLE_PRIVATE_KEY:", GOOGLE_PRIVATE_KEY ? `✅ Set (${GOOGLE_PRIVATE_KEY.length} chars, starts with: ${GOOGLE_PRIVATE_KEY.substring(0, 30)}...)` : "❌ Missing");
      
      accessToken = await getAccessToken();
      console.log("✅ Successfully obtained access token");
    } catch (tokenError: any) {
      console.error("❌ Error getting access token:", tokenError);
      console.error("❌ Error message:", tokenError?.message);
      console.error("❌ Error stack:", tokenError?.stack);
      
      // Provide more specific error messages
      let errorMessage = "Failed to authenticate with Google";
      if (tokenError?.message) {
        errorMessage += ": " + tokenError.message;
      }
      
      // Check for common issues
      if (tokenError?.message?.includes("Invalid key") || tokenError?.message?.includes("key")) {
        errorMessage += "\n\n💡 TROUBLESHOOTING: The private key format might be incorrect. Make sure:";
        errorMessage += "\n   1. The GOOGLE_PRIVATE_KEY includes the full key with BEGIN/END markers";
        errorMessage += "\n   2. Newlines are preserved (\\n characters are fine)";
        errorMessage += "\n   3. No extra spaces or quotes around the key";
      }
      
      return new Response(
        JSON.stringify({ 
          error: errorMessage,
          details: {
            error: tokenError?.message || "Unknown error",
            hint: "Check Supabase Edge Function logs for more details"
          }
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
    
    // Prepare FCM v1 API payload
    // Note: "from" is the Firebase project (identified by OAuth token in Authorization header)
    // "to" is the device token (sent as "token" field)
    const safeData = data ? Object.fromEntries(
      Object.entries(data).map(([key, value]) => [key, String(value)])
    ) : undefined;

    const fcmPayload = {
      message: {
        token,
        notification: {
          title,
          body,
        },
        data: safeData,
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    console.log("✅ Final FCM payload", JSON.stringify(fcmPayload));
    
    // Send to FCM v1 API
    console.log("📤 Preparing FCM v1 API request...");
    console.log("📤 FCM URL:", FCM_V1_URL);
    console.log("📤 Access token length:", accessToken?.length || 0);
    console.log("📤 Access token preview:", accessToken ? `${accessToken.substring(0, 30)}...` : "MISSING");
    console.log("📤 Access token full (first 100 chars):", accessToken ? accessToken.substring(0, 100) : "MISSING");
    console.log("📤 Authorization header value:", `Bearer ${accessToken?.substring(0, 30)}...`);
    console.log("📤 FCM payload:", JSON.stringify(fcmPayload, null, 2));
    
    // Verify token format
    if (!accessToken || accessToken.length < 100) {
      throw new Error(`Invalid access token: token is ${accessToken?.length || 0} characters (expected > 100)`);
    }
    
    if (!accessToken.startsWith("ya29.") && !accessToken.startsWith("1//")) {
      console.warn("⚠️ Access token doesn't start with expected prefix (ya29. or 1//)");
    }
    
    const requestHeaders = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${accessToken}`,
    };
    
    console.log("📤 Request headers:", JSON.stringify({
      "Content-Type": requestHeaders["Content-Type"],
      "Authorization": `Bearer ${accessToken.substring(0, 30)}...`,
    }, null, 2));
    
    const response = await fetch(FCM_V1_URL, {
      method: "POST",
      headers: requestHeaders,
      body: JSON.stringify(fcmPayload),
    });
    
    console.log("📥 FCM API response status:", response.status, response.statusText);
    const responseData = await response.json();
    console.log("📥 FCM API response data:", JSON.stringify(responseData, null, 2));
    
    if (!response.ok) {
      console.error("❌ FCM v1 API error:", responseData);
      console.error("❌ Response status:", response.status);
      console.error("❌ Response headers:", Object.fromEntries(response.headers.entries()));
      return new Response(
        JSON.stringify({ 
          error: "Failed to send notification",
          details: responseData 
        }),
        { 
          status: response.status,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
    
    console.log("Push notification sent successfully:", responseData);
    
    return new Response(
      JSON.stringify({ 
        success: true,
        name: responseData.name 
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error sending push notification:", error);
    return new Response(
      JSON.stringify({ 
        error: error.message || "Internal server error" 
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
