-- Safe migration script to add missing columns to existing tools table
-- Run this in your Supabase SQL Editor

-- Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add category column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'category') THEN
        ALTER TABLE tools ADD COLUMN category TEXT NOT NULL DEFAULT 'Other';
    END IF;

    -- Add brand column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'brand') THEN
        ALTER TABLE tools ADD COLUMN brand TEXT;
    END IF;

    -- Add model column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'model') THEN
        ALTER TABLE tools ADD COLUMN model TEXT;
    END IF;

    -- Add serial_number column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'serial_number') THEN
        ALTER TABLE tools ADD COLUMN serial_number TEXT UNIQUE;
    END IF;

    -- Add purchase_date column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'purchase_date') THEN
        ALTER TABLE tools ADD COLUMN purchase_date DATE;
    END IF;

    -- Add purchase_price column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'purchase_price') THEN
        ALTER TABLE tools ADD COLUMN purchase_price DECIMAL(10,2);
    END IF;

    -- Add current_value column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'current_value') THEN
        ALTER TABLE tools ADD COLUMN current_value DECIMAL(10,2);
    END IF;

    -- Add condition column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'condition') THEN
        ALTER TABLE tools ADD COLUMN condition TEXT CHECK(condition IN ('Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair')) DEFAULT 'Good';
    END IF;

    -- Add location column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'location') THEN
        ALTER TABLE tools ADD COLUMN location TEXT;
    END IF;

    -- Add status column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'status') THEN
        ALTER TABLE tools ADD COLUMN status TEXT CHECK(status IN ('Available', 'In Use', 'Maintenance', 'Retired')) DEFAULT 'Available';
    END IF;

    -- Add image_path column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'image_path') THEN
        ALTER TABLE tools ADD COLUMN image_path TEXT;
    END IF;

    -- Add notes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'notes') THEN
        ALTER TABLE tools ADD COLUMN notes TEXT;
    END IF;

    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'created_at') THEN
        ALTER TABLE tools ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tools' AND column_name = 'updated_at') THEN
        ALTER TABLE tools ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Create indexes for better performance (ignore errors if they already exist)
CREATE INDEX IF NOT EXISTS idx_tools_category ON tools(category);
CREATE INDEX IF NOT EXISTS idx_tools_status ON tools(status);
CREATE INDEX IF NOT EXISTS idx_tools_serial_number ON tools(serial_number);

-- Enable Row Level Security (RLS) if not already enabled
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

-- Create policies for tools table (only if they don't exist)
DO $$
BEGIN
    -- Create admin policy if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tools' AND policyname = 'Admins can manage all tools') THEN
        CREATE POLICY "Admins can manage all tools" ON tools
          FOR ALL USING (
            EXISTS (
              SELECT 1 FROM users 
              WHERE users.id = auth.uid() 
              AND users.role = 'admin'
            )
          );
    END IF;

    -- Create technician policy if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tools' AND policyname = 'Technicians can view all tools') THEN
        CREATE POLICY "Technicians can view all tools" ON tools
          FOR SELECT USING (
            EXISTS (
              SELECT 1 FROM users 
              WHERE users.id = auth.uid() 
              AND users.role IN ('admin', 'technician')
            )
          );
    END IF;
END $$;

-- Create function to update updated_at timestamp if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_tools_updated_at') THEN
        CREATE TRIGGER update_tools_updated_at 
          BEFORE UPDATE ON tools 
          FOR EACH ROW 
          EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
