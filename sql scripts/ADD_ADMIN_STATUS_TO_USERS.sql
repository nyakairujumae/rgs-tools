-- Add status column to users table for admin management
ALTER TABLE users
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Active';
