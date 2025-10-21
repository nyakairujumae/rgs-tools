-- Fix technicians table by adding missing columns
-- This addresses the PostgrestException errors for missing columns

-- Add the missing columns to technicians table
ALTER TABLE public.technicians 
ADD COLUMN IF NOT EXISTS department TEXT,
ADD COLUMN IF NOT EXISTS employee_id TEXT,
ADD COLUMN IF NOT EXISTS hire_date DATE;

-- Update any existing records to have default values if needed
UPDATE public.technicians 
SET department = 'General' 
WHERE department IS NULL;

UPDATE public.technicians 
SET employee_id = 'EMP-' || id::text 
WHERE employee_id IS NULL;

UPDATE public.technicians 
SET hire_date = CURRENT_DATE 
WHERE hire_date IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_technicians_department ON public.technicians(department);
CREATE INDEX IF NOT EXISTS idx_technicians_employee_id ON public.technicians(employee_id);
CREATE INDEX IF NOT EXISTS idx_technicians_hire_date ON public.technicians(hire_date);

-- Verify the table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'technicians' 
AND table_schema = 'public'
ORDER BY ordinal_position;
