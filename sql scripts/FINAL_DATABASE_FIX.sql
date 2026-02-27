-- FINAL_DATABASE_FIX.sql
-- Fix all missing columns including image_path

-- Add missing columns to tools table if they don't exist
DO $$ 
BEGIN
    -- Add image_path column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'image_path') THEN
        ALTER TABLE public.tools ADD COLUMN image_path TEXT;
    END IF;
    
    -- Add image_url column if it doesn't exist (backup column)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'image_url') THEN
        ALTER TABLE public.tools ADD COLUMN image_url TEXT;
    END IF;
    
    -- Add brand column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'brand') THEN
        ALTER TABLE public.tools ADD COLUMN brand TEXT;
    END IF;
    
    -- Add model column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'model') THEN
        ALTER TABLE public.tools ADD COLUMN model TEXT;
    END IF;
    
    -- Add serial_number column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'serial_number') THEN
        ALTER TABLE public.tools ADD COLUMN serial_number TEXT;
    END IF;
    
    -- Add condition column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'condition') THEN
        ALTER TABLE public.tools ADD COLUMN condition TEXT DEFAULT 'Good';
    END IF;
    
    -- Add location column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'location') THEN
        ALTER TABLE public.tools ADD COLUMN location TEXT;
    END IF;
    
    -- Add notes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'notes') THEN
        ALTER TABLE public.tools ADD COLUMN notes TEXT;
    END IF;
    
    -- Add purchase_price column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'purchase_price') THEN
        ALTER TABLE public.tools ADD COLUMN purchase_price DECIMAL(10,2);
    END IF;
    
    -- Add current_value column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'current_value') THEN
        ALTER TABLE public.tools ADD COLUMN current_value DECIMAL(10,2);
    END IF;
    
    -- Add purchase_date column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'purchase_date') THEN
        ALTER TABLE public.tools ADD COLUMN purchase_date DATE;
    END IF;
    
    -- Add tool_type column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'tool_type') THEN
        ALTER TABLE public.tools ADD COLUMN tool_type TEXT DEFAULT 'inventory';
    END IF;
    
    -- Add assigned_to column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'assigned_to') THEN
        ALTER TABLE public.tools ADD COLUMN assigned_to UUID REFERENCES public.users(id);
    END IF;
    
    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'created_at') THEN
        ALTER TABLE public.tools ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'updated_at') THEN
        ALTER TABLE public.tools ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Add indexes for better performance (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_tools_brand ON public.tools(brand);
CREATE INDEX IF NOT EXISTS idx_tools_model ON public.tools(model);
CREATE INDEX IF NOT EXISTS idx_tools_serial_number ON public.tools(serial_number);
CREATE INDEX IF NOT EXISTS idx_tools_category ON public.tools(category);
CREATE INDEX IF NOT EXISTS idx_tools_status ON public.tools(status);
CREATE INDEX IF NOT EXISTS idx_tools_tool_type ON public.tools(tool_type);
CREATE INDEX IF NOT EXISTS idx_tools_image_path ON public.tools(image_path);

SELECT 'Final database fix completed successfully! All missing columns added.' as status;
