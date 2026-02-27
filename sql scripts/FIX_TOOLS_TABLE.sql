-- FIX_TOOLS_TABLE.sql
-- Add missing columns to the tools table

-- Add missing columns to tools table
ALTER TABLE public.tools 
ADD COLUMN IF NOT EXISTS brand TEXT,
ADD COLUMN IF NOT EXISTS model TEXT,
ADD COLUMN IF NOT EXISTS serial_number TEXT,
ADD COLUMN IF NOT EXISTS condition TEXT DEFAULT 'Good',
ADD COLUMN IF NOT EXISTS location TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS purchase_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS current_value DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS purchase_date DATE,
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Update existing tools to have default values for new columns
UPDATE public.tools 
SET condition = 'Good' 
WHERE condition IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tools_brand ON public.tools(brand);
CREATE INDEX IF NOT EXISTS idx_tools_model ON public.tools(model);
CREATE INDEX IF NOT EXISTS idx_tools_serial_number ON public.tools(serial_number);
CREATE INDEX IF NOT EXISTS idx_tools_category ON public.tools(category);
CREATE INDEX IF NOT EXISTS idx_tools_status ON public.tools(status);

SELECT 'Tools table updated successfully!' as status;
