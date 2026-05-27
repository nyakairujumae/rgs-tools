-- =============================================================
-- Engagement Notifications — Cron Schedule
-- =============================================================
-- Run this once in your Supabase SQL editor.
-- Requires pg_cron to be enabled (it is on all Supabase projects).
--
-- The cron calls the engagement-notifications Edge Function every day at 8:00 AM UTC.
-- Adjust the time to match your team's timezone if needed.
-- =============================================================

select cron.schedule(
  'engagement-notifications-daily',
  '0 8 * * *',
  $$
  select
    net.http_post(
      url := 'https://npgwikkvtxebzwtpzwgx.supabase.co/functions/v1/engagement-notifications',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'x-cron-secret', '46d377b2166574d994ffc3862b8fe7e082bfecc13261f4461300fdc9ec94d051'
      ),
      body := '{}'::jsonb
    )
  $$
);

-- =============================================================
-- To verify the cron job was created:
-- =============================================================
-- select * from cron.job;

-- =============================================================
-- To remove the cron job:
-- =============================================================
-- select cron.unschedule('engagement-notifications-daily');
