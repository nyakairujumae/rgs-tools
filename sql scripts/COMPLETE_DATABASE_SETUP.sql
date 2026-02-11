-- COMPLETE_DATABASE_SETUP.sql
-- Complete database setup with all required tables

-- 1. Drop existing tables in correct order
DROP TABLE IF EXISTS public.tools CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.technicians CASCADE;

-- 2. Drop existing policies
DROP POLICY IF EXISTS "Users can view all users" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view all tools" ON public.tools;
DROP POLICY IF EXISTS "Users can insert tools" ON public.tools;
DROP POLICY IF EXISTS "Users can update tools" ON public.tools;
DROP POLICY IF EXISTS "Users can delete tools" ON public.tools;
DROP POLICY IF EXISTS "Technicians can view all technicians" ON public.technicians;
DROP POLICY IF EXISTS "Technicians can insert technicians" ON public.technicians;
DROP POLICY IF EXISTS "Technicians can update technicians" ON public.technicians;
DROP POLICY IF EXISTS "Technicians can delete technicians" ON public.technicians;

-- 3. Drop existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 4. Create users table
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'technician',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create technicians table
CREATE TABLE public.technicians (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create tools table
CREATE TABLE public.tools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    status TEXT DEFAULT 'Available',
    tool_type TEXT DEFAULT 'inventory',
    assigned_to UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tools ENABLE ROW LEVEL SECURITY;

-- 8. Create policies for users
CREATE POLICY "Users can view all users" ON public.users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 9. Create policies for technicians
CREATE POLICY "Technicians can view all technicians" ON public.technicians
    FOR SELECT USING (true);

CREATE POLICY "Technicians can insert technicians" ON public.technicians
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Technicians can update technicians" ON public.technicians
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Technicians can delete technicians" ON public.technicians
    FOR DELETE USING (auth.role() = 'authenticated');

-- 10. Create policies for tools
CREATE POLICY "Users can view all tools" ON public.tools
    FOR SELECT USING (true);

CREATE POLICY "Users can insert tools" ON public.tools
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update tools" ON public.tools
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete tools" ON public.tools
    FOR DELETE USING (auth.role() = 'authenticated');

-- 11. Create trigger function for new users
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

-- 12. Create trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 13. Grant permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.users TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.technicians TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.tools TO postgres, anon, authenticated, service_role;

SELECT 'Complete database setup finished successfully!' as status;

