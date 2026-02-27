-- ============================================================================
-- V2 MULTI-TENANT FOUNDATION
-- Run this FIRST before any other schema scripts on a fresh Supabase project.
-- ============================================================================
-- Creates: organizations (tenant) table, helper functions, and extensions.
-- All other tables will reference organization_id for tenant isolation.
-- ============================================================================

-- Enable UUID extension (usually already enabled in Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. ORGANIZATIONS TABLE (The Tenant)
-- ============================================================================
CREATE TABLE IF NOT EXISTS organizations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for slug lookups (e.g. subdomain, invite links)
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);

-- RLS: Organizations are readable by authenticated users (for org switching/display)
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (true);

-- Only service role or a bootstrap function can create organizations
-- For self-service: add a policy that allows first user to create org
CREATE POLICY "Authenticated users can insert organizations"
  ON organizations FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================================================
-- 2. HELPER FUNCTION: Get current user's organization
-- ============================================================================
CREATE OR REPLACE FUNCTION public.current_organization_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT organization_id FROM users WHERE id = auth.uid() LIMIT 1;
$$;

-- ============================================================================
-- 3. HELPER: Check if user belongs to organization
-- ============================================================================
CREATE OR REPLACE FUNCTION public.user_belongs_to_org(org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND organization_id = org_id
  );
$$;

-- ============================================================================
-- 4. updated_at trigger for organizations
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. INSERT DEFAULT ORGANIZATION (optional - for bootstrap)
-- ============================================================================
-- Uncomment to create a default org for the first tenant:
/*
INSERT INTO organizations (name, slug)
VALUES ('Default Organization', 'default')
ON CONFLICT (slug) DO NOTHING;
*/

SELECT '✅ Multi-tenant foundation ready. Run V2_002_* next.' as status;
