-- ULTRA_SAFE_DATABASE_SETUP.sql
-- Ultra safe database setup that handles all edge cases

-- 1. Create users table (only if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'technician',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create technicians table (only if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.technicians (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create tools table (only if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.tools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    brand TEXT,
    model TEXT,
    serial_number TEXT,
    condition TEXT DEFAULT 'Good',
    status TEXT DEFAULT 'Available',
    tool_type TEXT DEFAULT 'inventory',
    location TEXT,
    notes TEXT,
    purchase_price DECIMAL(10,2),
    current_value DECIMAL(10,2),
    purchase_date DATE,
    image_url TEXT,
    assigned_to UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Add missing columns to tools table if they don't exist
DO $$ 
BEGIN
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
    
    -- Add image_url column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tools' AND column_name = 'image_url') THEN
        ALTER TABLE public.tools ADD COLUMN image_url TEXT;
    END IF;
END $$;

-- 5. Enable RLS (only if not already enabled)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'users' AND relrowsecurity = true) THEN
        ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'technicians' AND relrowsecurity = true) THEN
        ALTER TABLE public.technicians ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'tools' AND relrowsecurity = true) THEN
        ALTER TABLE public.tools ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- 6. Create policies (only if they don't exist)
DO $$
BEGIN
    -- Users policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can view all users') THEN
        CREATE POLICY "Users can view all users" ON public.users FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can update own profile') THEN
        CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can insert own profile') THEN
        CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    
    -- Technicians policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'technicians' AND policyname = 'Technicians can view all technicians') THEN
        CREATE POLICY "Technicians can view all technicians" ON public.technicians FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'technicians' AND policyname = 'Technicians can insert technicians') THEN
        CREATE POLICY "Technicians can insert technicians" ON public.technicians FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'technicians' AND policyname = 'Technicians can update technicians') THEN
        CREATE POLICY "Technicians can update technicians" ON public.technicians FOR UPDATE USING (auth.role() = 'authenticated');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'technicians' AND policyname = 'Technicians can delete technicians') THEN
        CREATE POLICY "Technicians can delete technicians" ON public.technicians FOR DELETE USING (auth.role() = 'authenticated');
    END IF;
    
    -- Tools policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tools' AND policyname = 'Users can view all tools') THEN
        CREATE POLICY "Users can view all tools" ON public.tools FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tools' AND policyname = 'Users can insert tools') THEN
        CREATE POLICY "Users can insert tools" ON public.tools FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tools' AND policyname = 'Users can update tools') THEN
        CREATE POLICY "Users can update tools" ON public.tools FOR UPDATE USING (auth.role() = 'authenticated');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tools' AND policyname = 'Users can delete tools') THEN
        CREATE POLICY "Users can delete tools" ON public.tools FOR DELETE USING (auth.role() = 'authenticated');
    END IF;
END $$;

-- 7. Create trigger function for new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'technician')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Create trigger (only if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
        CREATE TRIGGER on_auth_user_created
            AFTER INSERT ON auth.users
            FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
    END IF;
END $$;

-- 9. Add indexes for better performance (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_tools_brand ON public.tools(brand);
CREATE INDEX IF NOT EXISTS idx_tools_model ON public.tools(model);
CREATE INDEX IF NOT EXISTS idx_tools_serial_number ON public.tools(serial_number);
CREATE INDEX IF NOT EXISTS idx_tools_category ON public.tools(category);
CREATE INDEX IF NOT EXISTS idx_tools_status ON public.tools(status);
CREATE INDEX IF NOT EXISTS idx_tools_tool_type ON public.tools(tool_type);

-- 10. Grant permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.users TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.technicians TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.tools TO postgres, anon, authenticated, service_role;

SELECT 'Ultra safe database setup completed successfully!' as status;
