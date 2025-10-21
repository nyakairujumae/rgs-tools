-- Fix technicians table by adding missing department column
-- This addresses the PostgrestException: Could not find the 'department' column

-- Add the missing department column to technicians table
ALTER TABLE public.technicians 
ADD COLUMN IF NOT EXISTS department TEXT;

-- Update any existing records to have a default department if needed
UPDATE public.technicians 
SET department = 'General' 
WHERE department IS NULL;

-- Add an index for better performance on department queries
CREATE INDEX IF NOT EXISTS idx_technicians_department ON public.technicians(department);

-- Verify the table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'technicians' 
AND table_schema = 'public'
ORDER BY ordinal_position;
