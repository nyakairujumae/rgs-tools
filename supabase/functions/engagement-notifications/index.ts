import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

// ── Helpers ───────────────────────────────────────────────────────────────────

async function push(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
) {
  try {
    await supabase.functions.invoke("send-push-notification", {
      body: { user_id: userId, title, body, data },
    });
  } catch (e) {
    console.warn(`push failed for ${userId}:`, e);
  }
}

async function getAllAdminIds(): Promise<string[]> {
  const { data } = await supabase
    .from("users")
    .select("id")
    .eq("role", "admin");
  return (data ?? []).map((r: { id: string }) => r.id);
}

async function pushToAllAdmins(
  title: string,
  body: string,
  data?: Record<string, string>,
) {
  const ids = await getAllAdminIds();
  await Promise.allSettled(ids.map((id) => push(id, title, body, data)));
}

// ── Notification jobs ─────────────────────────────────────────────────────────

/** Daily: remind all technicians to keep their tools logged in the app. */
async function remindTechsToAddTools() {
  const { data: techs } = await supabase
    .from("users")
    .select("id")
    .eq("role", "technician");

  if (!techs?.length) return;

  await Promise.allSettled(
    techs.map((tech: { id: string }) =>
      push(
        tech.id,
        "Keep your tools up to date 🔧",
        "Make sure all the tools you're using are logged in the app so your team stays in sync.",
        { type: "engagement_add_tools" },
      )
    ),
  );
}

/** Daily: remind all technicians to mark any shared tools they're currently using. */
async function remindTechsToMarkSharedTools() {
  const { data: techs } = await supabase
    .from("users")
    .select("id")
    .eq("role", "technician");

  if (!techs?.length) return;

  await Promise.allSettled(
    techs.map((tech: { id: string }) =>
      push(
        tech.id,
        "Using a shared tool? Mark it 📋",
        "If you're currently using any shared tools, mark them in the app so your teammates know their availability.",
        { type: "mark_shared_tool_reminder" },
      )
    ),
  );
}

/**
 * Mon / Wed / Fri: pick a random shared tool that's currently held by someone
 * and nudge all other technicians that they can request it.
 */
async function sharedToolAwarenessNudge() {
  // Fetch all shared tools that are currently assigned
  const { data: heldTools } = await supabase
    .from("tools")
    .select("id, name, assigned_to")
    .eq("tool_type", "shared")
    .not("assigned_to", "is", null);

  if (!heldTools?.length) return;

  // Pick one at random
  const tool = heldTools[Math.floor(Math.random() * heldTools.length)] as {
    id: string;
    name: string;
    assigned_to: string;
  };

  // Get the holder's display name
  const { data: holder } = await supabase
    .from("users")
    .select("full_name")
    .eq("id", tool.assigned_to)
    .maybeSingle();

  const holderName = holder?.full_name ?? "A colleague";

  // Notify all technicians who are NOT the current holder
  const { data: techs } = await supabase
    .from("users")
    .select("id")
    .eq("role", "technician")
    .neq("id", tool.assigned_to);

  if (!techs?.length) return;

  await Promise.allSettled(
    techs.map((tech: { id: string }) =>
      push(
        tech.id,
        `${holderName} has the ${tool.name}`,
        "If you need it, you can send a request through the app.",
        { type: "shared_tool_awareness", tool_id: tool.id },
      )
    ),
  );
}

/** Daily: remind admins if there are open/in-progress tool issues. */
async function remindAdminsPendingIssues() {
  const { count } = await supabase
    .from("tool_issues")
    .select("id", { count: "exact", head: true })
    .in("status", ["Open", "In Progress"]);

  if (!count || count === 0) return;

  const plural = count === 1;
  await pushToAllAdmins(
    `${count} tool ${plural ? "issue" : "issues"} need attention`,
    plural
      ? "1 open tool issue is waiting for your review."
      : `${count} open tool issues are waiting for your review.`,
    { type: "pending_issues_reminder" },
  );
}

/** Daily: remind admins if there are pending tool/assignment requests. */
async function remindAdminsPendingRequests() {
  const { count } = await supabase
    .from("approval_workflows")
    .select("id", { count: "exact", head: true })
    .eq("status", "Pending");

  if (!count || count === 0) return;

  const plural = count === 1;
  await pushToAllAdmins(
    `${count} pending ${plural ? "request" : "requests"}`,
    plural
      ? "1 tool request is waiting for your approval."
      : `${count} tool requests are waiting for your approval.`,
    { type: "pending_requests_reminder" },
  );
}

/** 1st of month: prompt admins to review last month's report. */
async function remindAdminsMonthlyReport() {
  const lastMonth = new Date();
  lastMonth.setMonth(lastMonth.getMonth() - 1);
  const monthName = lastMonth.toLocaleString("default", { month: "long" });

  await pushToAllAdmins(
    "Time for your monthly report 📊",
    `Review ${monthName}'s tools, issues, and repairs before the month gets away.`,
    { type: "monthly_report_reminder" },
  );
}

// ── Entry point ───────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  // Guard: only allow calls with the correct secret header (set CRON_SECRET in Supabase secrets)
  if (CRON_SECRET) {
    const provided = req.headers.get("x-cron-secret");
    if (provided !== CRON_SECRET) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  const now = new Date();
  const dayOfMonth = now.getUTCDate();
  const dayOfWeek = now.getUTCDay(); // 0 = Sun, 1 = Mon, …, 5 = Fri

  const tasks: Promise<void>[] = [];

  // ── Daily jobs ──
  tasks.push(remindTechsToAddTools());
  tasks.push(remindTechsToMarkSharedTools());
  tasks.push(remindAdminsPendingIssues());
  tasks.push(remindAdminsPendingRequests());

  // ── Mon / Wed / Fri ──
  if (dayOfWeek === 1 || dayOfWeek === 3 || dayOfWeek === 5) {
    tasks.push(sharedToolAwarenessNudge());
  }

  // ── 1st of every month ──
  if (dayOfMonth === 1) {
    tasks.push(remindAdminsMonthlyReport());
  }

  await Promise.allSettled(tasks);

  return new Response(
    JSON.stringify({ ok: true, timestamp: now.toISOString() }),
    { headers: { "Content-Type": "application/json" } },
  );
});
