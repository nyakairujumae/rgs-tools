import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const INVITE_REDIRECT_URL = Deno.env.get("INVITE_REDIRECT_URL");
const DEFAULT_REDIRECT_URL = "com.rgs.app://reset-password?mode=invite";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
}

const supabase = SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    })
  : null;

Deno.serve(async (req) => {
  if (!supabase) {
    return new Response(
      JSON.stringify({ error: "Server not configured" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: "Missing authorization" }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const token = authHeader.replace("Bearer ", "");
  const { data: requesterData, error: requesterError } = await supabase.auth.getUser(token);
  if (requesterError || !requesterData?.user) {
    return new Response(
      JSON.stringify({ error: "Invalid session" }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const requesterId = requesterData.user.id;
  const { data: requesterProfile, error: requesterProfileError } = await supabase
    .from("users")
    .select("role, position_id")
    .eq("id", requesterId)
    .maybeSingle();

  if (requesterProfileError || !requesterProfile) {
    return new Response(
      JSON.stringify({ error: "Requester profile not found" }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  if (requesterProfile.role !== "admin" || !requesterProfile.position_id) {
    return new Response(
      JSON.stringify({ error: "Not authorized to invite admins" }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  const { data: permission } = await supabase
    .from("position_permissions")
    .select("is_granted")
    .eq("position_id", requesterProfile.position_id)
    .eq("permission_name", "can_manage_admins")
    .eq("is_granted", true)
    .maybeSingle();

  if (!permission) {
    return new Response(
      JSON.stringify({ error: "Missing admin management permission" }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
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
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const email = payload.email?.trim();
  const fullName = payload.full_name?.trim();
  const positionId = payload.position_id?.trim();
  const status = payload.status?.trim() || "Pending Approval";

  if (!email || !fullName || !positionId) {
    return new Response(
      JSON.stringify({ error: "Missing required fields" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
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
      const { data: existingUser } = await supabase
        .from("auth.users")
        .select("id")
        .eq("email", email)
        .maybeSingle();
      userId = existingUser?.id ?? null;
    } else {
      return new Response(
        JSON.stringify({ error: createError.message ?? "User creation failed" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
  } else {
    userId = created.user?.id ?? null;
  }

  if (!userId) {
    const { data: fallbackUser } = await supabase
      .from("auth.users")
      .select("id")
      .eq("email", email)
      .maybeSingle();
    userId = fallbackUser?.id ?? null;
  }

  const { error: resetError } = await supabase.auth.resetPasswordForEmail(
    email,
    { redirectTo },
  );

  if (resetError) {
    return new Response(
      JSON.stringify({ error: resetError.message ?? "Failed to send reset email" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  if (!userId) {
    return new Response(
      JSON.stringify({ error: "User created but no user id returned" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
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
    return new Response(
      JSON.stringify({ error: `Invite created but user profile failed: ${upsertError.message}` }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ user_id: userId }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
