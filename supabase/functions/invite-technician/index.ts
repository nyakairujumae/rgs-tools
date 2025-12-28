import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const INVITE_REDIRECT_URL = Deno.env.get("INVITE_REDIRECT_URL");
const DEFAULT_REDIRECT_URL = "com.rgs.app://auth/callback";

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
      JSON.stringify({ error: "Not authorized to invite technicians" }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  const { data: permission } = await supabase
    .from("position_permissions")
    .select("permission_name")
    .eq("position_id", requesterProfile.position_id)
    .in("permission_name", ["can_manage_technicians", "can_manage_admins"])
    .eq("is_granted", true)
    .maybeSingle();

  if (!permission) {
    return new Response(
      JSON.stringify({ error: "Missing technician management permission" }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  let payload: {
    email?: string;
    full_name?: string;
    department?: string;
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
  const department = payload.department?.trim();

  if (!email || !fullName) {
    return new Response(
      JSON.stringify({ error: "Missing required fields" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const redirectTo = INVITE_REDIRECT_URL?.trim() || DEFAULT_REDIRECT_URL;
  const { data: inviteData, error: inviteError } = await supabase.auth.admin.inviteUserByEmail(
    email,
    {
      data: {
        full_name: fullName,
        role: "technician",
        department: department ?? null,
      },
      redirectTo,
    },
  );

  if (inviteError || !inviteData?.user) {
    return new Response(
      JSON.stringify({ error: inviteError?.message ?? "Invite failed" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const userId = inviteData.user.id;

  const { error: upsertError } = await supabase
    .from("users")
    .upsert({
      id: userId,
      email,
      full_name: fullName,
      role: "technician",
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
