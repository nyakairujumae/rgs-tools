import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const supabase = SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    })
  : null;

const jsonResponse = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

async function safeUpdate(
  table: string,
  column: string,
  value: string,
  data: Record<string, unknown>,
) {
  if (!supabase) return;
  const { error } = await supabase.from(table).update(data).eq(column, value);
  if (error) {
    console.warn(`[delete-account] ${table} update failed: ${error.message}`);
  }
}

async function safeDelete(table: string, column: string, value: string) {
  if (!supabase) return;
  const { error } = await supabase.from(table).delete().eq(column, value);
  if (error) {
    console.warn(`[delete-account] ${table} delete failed: ${error.message}`);
  }
}

Deno.serve(async (req) => {
  if (!supabase) {
    return jsonResponse(500, { error: "Server not configured" });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse(401, { error: "Missing authorization" });
  }

  const token = authHeader.replace("Bearer ", "");
  const { data: requesterData, error: requesterError } = await supabase.auth.getUser(token);
  if (requesterError || !requesterData?.user) {
    return jsonResponse(401, { error: "Invalid session" });
  }

  const userId = requesterData.user.id;
  const { data: profile, error: profileError } = await supabase
    .from("users")
    .select("role")
    .eq("id", userId)
    .maybeSingle();

  if (profileError) {
    return jsonResponse(403, { error: "Profile lookup failed" });
  }

  const roleFromProfile = profile?.role?.toString().toLowerCase();
  const roleFromMetadata = requesterData.user.user_metadata?.role?.toString().toLowerCase();
  const roleFromAppMetadata = requesterData.user.app_metadata?.role?.toString().toLowerCase();
  const isAdmin = roleFromProfile === "admin" ||
    roleFromMetadata === "admin" ||
    roleFromAppMetadata === "admin";

  if (!isAdmin) {
    return jsonResponse(403, {
      error: "Technician accounts must be deleted by an administrator.",
    });
  }

  await safeUpdate("pending_user_approvals", "reviewed_by", userId, {
    reviewed_by: null,
  });
  await safeDelete("pending_user_approvals", "user_id", userId);

  await safeUpdate("tools", "assigned_to", userId, { assigned_to: null });
  await safeUpdate("approval_workflows", "assigned_to", userId, {
    assigned_to: null,
  });
  await safeUpdate("approval_workflows", "approved_by", userId, {
    approved_by: null,
  });
  await safeUpdate("approval_workflows", "rejected_by", userId, {
    rejected_by: null,
  });
  await safeUpdate("tool_issues", "reported_by_user_id", userId, {
    reported_by_user_id: null,
  });
  await safeUpdate("tool_issues", "assigned_to_user_id", userId, {
    assigned_to_user_id: null,
  });

  await safeDelete("user_fcm_tokens", "user_id", userId);

  const { error: profileDeleteError } = await supabase
    .from("users")
    .delete()
    .eq("id", userId);
  if (profileDeleteError) {
    return jsonResponse(500, { error: "Failed to delete user profile" });
  }

  const { error: authDeleteError } = await supabase.auth.admin.deleteUser(userId);
  if (authDeleteError) {
    const message = authDeleteError.message?.toLowerCase() ?? "";
    if (!message.includes("not found")) {
      return jsonResponse(500, { error: "Failed to delete auth account" });
    }
  }

  return jsonResponse(200, { success: true });
});
