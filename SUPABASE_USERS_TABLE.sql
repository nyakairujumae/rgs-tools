-- Create users table for role management
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'technician')) DEFAULT 'technician',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
-- Users can read their own data
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Allow inserts for authenticated users
CREATE POLICY "Allow inserts for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Create function to automatically create user record on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'technician')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user record
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS on_users_updated ON users;
CREATE TRIGGER on_users_updated
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Insert admin user (replace with your admin email)
-- Uncomment and modify the email below to create an admin user
-- INSERT INTO users (id, email, full_name, role)
-- VALUES (
--   (SELECT id FROM auth.users WHERE email = 'admin@yourcompany.com' LIMIT 1),
--   'admin@yourcompany.com',
--   'Admin User',
--   'admin'
-- ) ON CONFLICT (id) DO UPDATE SET role = 'admin';

