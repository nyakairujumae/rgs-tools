-- Add user_id column to technicians table to link to auth.users
-- This allows admin-created technicians to have auth accounts

-- Step 1: Add user_id column if it doesn't exist
ALTER TABLE technicians 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Step 2: Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_technicians_user_id ON technicians(user_id);

-- Step 3: Add comment explaining the column
COMMENT ON COLUMN technicians.user_id IS 'Links technician to auth.users account. Set when admin creates technician account.';

-- Step 4: Verify the column was added
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'technicians' 
  AND column_name = 'user_id';
