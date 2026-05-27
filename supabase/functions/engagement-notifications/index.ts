import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const CRON_SECRET = Deno.env.get("CRON_SECRET");

// Fallback to the secret hardcoded in SETUP_ENGAGEMENT_NOTIFICATIONS_CRON.sql
const EXPECTED_SECRET = CRON_SECRET ?? "46d377b2166574d994ffc3862b8fe7e082bfecc13261f4461300fdc9ec94d051";

const supabase = SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false },
    })
  : null;

async function sendPushToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<boolean> {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) return false;
  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/send-push-notification`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify({ user_id: userId, title, body, data }),
    });
    return res.ok;
  } catch (e) {
    console.warn(`⚠️ Push failed for user ${userId}:`, e);
    return false;
  }
}

Deno.serve(async (req) => {
  // Only allow POST (from pg_cron via net.http_post)
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Validate cron secret
  const secret = req.headers.get("x-cron-secret");
  if (!secret || secret !== EXPECTED_SECRET) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!supabase) {
    return new Response(JSON.stringify({ error: "Server not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Find active issues not updated in the last 24 hours
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const { data: staleIssues, error } = await supabase
    .from("tool_issues")
    .select("id, tool_name, status, reported_by_user_id, updated_at")
    .in("status", ["Open", "Seen", "In Review", "In Progress"])
    .lt("updated_at", oneDayAgo)
    .not("reported_by_user_id", "is", null);

  if (error) {
    console.error("Failed to fetch stale issues:", error);
    return new Response(JSON.stringify({ error: "Failed to fetch issues" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!staleIssues || staleIssues.length === 0) {
    console.log("No stale issues found, nothing to notify.");
    return new Response(
      JSON.stringify({ message: "No stale issues", notified: 0 }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  // Group issues by technician
  const byTech = new Map<string, typeof staleIssues>();
  for (const issue of staleIssues) {
    const uid = issue.reported_by_user_id as string;
    if (!byTech.has(uid)) byTech.set(uid, []);
    byTech.get(uid)!.push(issue);
  }

  let notified = 0;
  for (const [userId, issues] of byTech.entries()) {
    const count = issues.length;
    const title = count === 1 ? "Tool Issue Update" : `${count} Tool Issues Pending`;
    const body =
      count === 1
        ? `Your issue with ${issues[0].tool_name} is still being handled (${issues[0].status}). We're on it.`
        : `You have ${count} open tool issues still being handled. We're working on them.`;

    const sent = await sendPushToUser(userId, title, body, {
      type: "engagement_reminder",
      issue_count: String(count),
    });

    if (sent) notified++;
    console.log(`${sent ? "✅" : "❌"} Notified user ${userId} (${count} issue${count > 1 ? "s" : ""})`);
  }

  console.log(`Engagement run complete — notified ${notified}/${byTech.size} technicians`);
  return new Response(
    JSON.stringify({
      message: "Engagement notifications sent",
      notified,
      technicians: byTech.size,
      total_issues: staleIssues.length,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
