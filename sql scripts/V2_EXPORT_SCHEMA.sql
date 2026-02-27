-- V2_EXPORT_SCHEMA.sql
-- Run this in the ORIGINAL project SQL Editor to generate schema DDL.
-- Copy the output and run it in the NEW v2 project.

-- This query returns the list of tables. Run each section below manually
-- or use the Supabase Table Editor: for each table, right-click → Copy as → Create statement.

-- First, get all table names in public schema:
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- NOTE: Supabase SQL Editor doesn't have a built-in "export full schema" on free tier.
-- Use one of these approaches:

-- APPROACH 1: Run your existing setup scripts in order in the NEW project:
--   1. sql scripts/SUPABASE_RECREATE_ALL_TABLES.sql (base tables)
--   2. sql scripts/APPROVAL_WORKFLOWS_TABLE.sql
--   3. sql scripts/PENDING_USER_APPROVALS.sql
--   4. sql scripts/SUPABASE_TOOL_ISSUES_TABLE.sql (or SUPABASE_TOOL_ISSUES_TABLE_SIMPLE.sql)
--   5. sql scripts/FIX_APPROVAL_WORKFLOWS_RLS.sql
--   6. sql scripts/FIX_ADMIN_NOTIFICATIONS_RLS_FINAL.sql (or similar)
--   7. sql scripts/ADMIN_POSITIONS_MIGRATION.sql
--   8. sql scripts/FIX_USER_FCM_TOKENS_TABLE.sql
--   ... and any other FIX_* or migration scripts your schema needs.

-- APPROACH 2: For each table from the SELECT above, in Supabase Table Editor:
--   - Open the table
--   - Use "Duplicate table" or view SQL - Supabase shows the schema
--   - Manually create tables in v2 with matching columns

-- Get column info for reference (run and save output):
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
ORDER BY table_name, ordinal_position;
