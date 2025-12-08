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
    const error = await tokenResponse.text();
    throw new Error(`Failed to get access token: ${error}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

// Create JWT for service account authentication
async function createJWT(): Promise<string> {
  if (!GOOGLE_CLIENT_EMAIL || !GOOGLE_PRIVATE_KEY) {
    throw new Error("GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be set");
  }

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
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

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
  const privateKey = GOOGLE_PRIVATE_KEY.replace(/\\n/g, "\n");
  
  // Import key and sign
  const keyData = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

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
      accessToken = await getAccessToken();
      console.log("✅ Successfully obtained access token");
    } catch (tokenError) {
      console.error("Error getting access token:", tokenError);
      return new Response(
        JSON.stringify({ 
          error: "Failed to authenticate with Google: " + tokenError.message 
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }
    
    // Prepare FCM v1 API payload
    const fcmPayload = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: data ? Object.fromEntries(
          Object.entries(data).map(([key, value]) => [key, String(value)])
        ) : {},
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      },
    };
    
    // Send to FCM v1 API
    const response = await fetch(FCM_V1_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify(fcmPayload),
    });
    
    const responseData = await response.json();
    
    if (!response.ok) {
      console.error("FCM v1 API error:", responseData);
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
