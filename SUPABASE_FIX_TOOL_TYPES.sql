-- Fix tool types for existing tools
-- Run this in your Supabase SQL Editor

-- First, check what tool types currently exist
SELECT tool_type, COUNT(*) as count 
FROM tools 
GROUP BY tool_type;

-- Update any tools that don't have the correct tool_type
-- Set all tools to 'inventory' by default (admin tools)
UPDATE tools 
SET tool_type = 'inventory' 
WHERE tool_type IS NULL OR tool_type NOT IN ('inventory', 'shared', 'assigned');

-- Verify the fix
SELECT tool_type, COUNT(*) as count 
FROM tools 
GROUP BY tool_type;

