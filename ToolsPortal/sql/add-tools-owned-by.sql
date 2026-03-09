-- Add owned_by to tools so admins can have "My Tools" (tools they added).
-- Run this in Supabase SQL Editor if the column does not exist yet.

ALTER TABLE public.tools
  ADD COLUMN IF NOT EXISTS owned_by UUID REFERENCES auth.users(id);

COMMENT ON COLUMN public.tools.owned_by IS 'Admin user id who added/owns this tool (for My Tools)';
