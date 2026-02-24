import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const INVITE_REDIRECT_URL = Deno.env.get("INVITE_REDIRECT_URL");
const DEFAULT_REDIRECT_URL = "com.rgs.app://reset-password?mode=invite";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const supabase = SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    })
  : null;

async function findUserIdByEmail(email: string): Promise<string | null> {
  if (!supabase) return null;
  const normalizedEmail = email.trim().toLowerCase();

  const { data: authUser, error: authError } = await supabase
    .schema("auth")
    .from("users")
    .select("id, email")
    .eq("email", normalizedEmail)
    .maybeSingle();

  if (!authError && authUser?.id) {
    return authUser.id;
  }

  const { data: listData, error: listError } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
  });

  if (!listError && listData?.users) {
    const match = listData.users.find((user) =>
      user.email?.toLowerCase() === normalizedEmail
    );
    return match?.id ?? null;
  }

  return null;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests from browsers
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!supabase) {
    return jsonResponse({ error: "Server not configured" }, 500);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing authorization" }, 401);
  }

  const token = authHeader.replace("Bearer ", "");
  const { data: requesterData, error: requesterError } = await supabase.auth.getUser(token);
  if (requesterError || !requesterData?.user) {
    return jsonResponse({ error: "Invalid session" }, 401);
  }

  const requesterId = requesterData.user.id;
  const { data: requesterProfile, error: requesterProfileError } = await supabase
    .from("users")
    .select("role, position_id")
    .eq("id", requesterId)
    .maybeSingle();

  if (requesterProfileError || !requesterProfile) {
    return jsonResponse({ error: "Requester profile not found" }, 403);
  }

  if (requesterProfile.role !== "admin" || !requesterProfile.position_id) {
    return jsonResponse({ error: "Not authorized to invite admins" }, 403);
  }

  const { data: permission } = await supabase
    .from("position_permissions")
    .select("is_granted")
    .eq("position_id", requesterProfile.position_id)
    .eq("permission_name", "can_manage_admins")
    .eq("is_granted", true)
    .maybeSingle();

  if (!permission) {
    return jsonResponse({ error: "Missing admin management permission" }, 403);
  }

  let payload: {
    email?: string;
    full_name?: string;
    position_id?: string;
    status?: string;
  };

  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const email = payload.email?.trim();
  const fullName = payload.full_name?.trim();
  const positionId = payload.position_id?.trim();
  const status = payload.status?.trim() || "Pending Approval";

  if (!email || !fullName || !positionId) {
    return jsonResponse({ error: "Missing required fields" }, 400);
  }

  const redirectTo = INVITE_REDIRECT_URL?.trim() || DEFAULT_REDIRECT_URL;
  let userId: string | null = null;

  const { data: created, error: createError } = await supabase.auth.admin.createUser({
    email,
    email_confirm: true,
    user_metadata: {
      full_name: fullName,
      role: "admin",
      position_id: positionId,
    },
  });

  if (createError) {
    const message = createError.message ?? '';
    if (message.toLowerCase().includes('already')) {
      userId = await findUserIdByEmail(email);
    } else {
      return jsonResponse({ error: createError.message ?? "User creation failed" }, 400);
    }
  } else {
    userId = created.user?.id ?? null;
  }

  if (!userId) {
    userId = await findUserIdByEmail(email);
  }

  const { error: resetError } = await supabase.auth.resetPasswordForEmail(
    email,
    { redirectTo },
  );

  if (resetError) {
    return jsonResponse({ error: resetError.message ?? "Failed to send reset email" }, 400);
  }

  if (!userId) {
    return jsonResponse({ error: "User created but no user id returned" }, 500);
  }

  const { error: upsertError } = await supabase
    .from("users")
    .upsert({
      id: userId,
      email,
      full_name: fullName,
      role: "admin",
      position_id: positionId,
      status,
      updated_at: new Date().toISOString(),
    }, { onConflict: "id" });

  if (upsertError) {
    return jsonResponse({ error: `Invite created but user profile failed: ${upsertError.message}` }, 500);
  }

  return jsonResponse({ user_id: userId });
});
