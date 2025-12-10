-- Add tool_type column to distinguish between inventory and shared tools
-- Migration for existing tools table

-- Add the new column with a default value
ALTER TABLE tools 
ADD COLUMN IF NOT EXISTS tool_type VARCHAR(20) DEFAULT 'inventory';

-- Update the column to be NOT NULL after setting default values
ALTER TABLE tools 
ALTER COLUMN tool_type SET NOT NULL;

-- Add a check constraint to ensure valid values
ALTER TABLE tools 
ADD CONSTRAINT tools_tool_type_check 
CHECK (tool_type IN ('inventory', 'shared', 'assigned'));

-- Create an index for better query performance
CREATE INDEX IF NOT EXISTS idx_tools_tool_type ON tools(tool_type);

-- Add a comment to explain the column
COMMENT ON COLUMN tools.tool_type IS 'Tool type: inventory (in main inventory), shared (available for checkout), assigned (permanently assigned)';

-- Update existing tools to be 'inventory' type (since they were added to main inventory)
UPDATE tools SET tool_type = 'inventory' WHERE tool_type IS NULL;
