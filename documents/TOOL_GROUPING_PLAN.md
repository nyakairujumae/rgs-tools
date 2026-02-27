# Tool Grouping Implementation Plan

## Problem Statement
- Company may have multiple instances of the same tool (e.g., 10 drills, 20 spanners)
- Each tool needs individual tracking (status, assignment, serial number, etc.)
- Displaying all instances as separate cards creates UI clutter
- Need to balance individual tracking with clean UI presentation

## Proposed Solution: UI-Level Grouping

### Approach
**Keep individual tool records in database** → **Group by composite key in UI** → **Show instances on detail view**

### Key Design Decisions

1. **Grouping Key**: Tools are grouped by `name + category + brand`
   - Same name + category + brand = same tool type
   - Different serial numbers, statuses, assignments = different instances

2. **UI Display**:
   - Main grid shows **one card per tool type** (grouped)
   - Card displays:
     - Tool name, category, brand
     - **Count badge**: "10 available" or "5 assigned, 5 available"
     - Representative image (first instance's image)
     - Status summary (e.g., "8 Available, 2 In Use")
   
3. **Detail View**:
   - Tapping a grouped card opens **Tool Instances Screen**
   - Shows all instances of that tool type
   - Each instance shows: serial number, status, assigned to, condition
   - Allows individual instance management (assign, return, edit, etc.)

4. **Search & Filters**:
   - Search works on grouped view (searches tool names, categories, brands)
   - Filters apply to grouped view (shows groups that have matching instances)
   - Instance-level filters available in detail view

### Implementation Steps

#### Step 1: Create ToolGroup Model
```dart
class ToolGroup {
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final List<Tool> instances;
  final String? representativeImage;
  
  // Computed properties
  int get totalCount => instances.length;
  int get availableCount => instances.where((t) => t.status == 'Available').length;
  int get assignedCount => instances.where((t) => t.assignedTo != null).length;
  String get statusSummary => ...; // "8 Available, 2 In Use"
  
  // Grouping key
  String get groupKey => '$name|$category|${brand ?? ''}';
}
```

#### Step 2: Add Grouping Logic to ToolsScreen
- Create `_groupTools(List<Tool> tools)` method
- Groups tools by composite key
- Returns `List<ToolGroup>`
- Update `filteredTools` to work with groups

#### Step 3: Update Tool Card UI
- Modify `_buildToolCard` to accept `ToolGroup` instead of `Tool`
- Add count badge showing total instances
- Add status summary (e.g., "8 Available, 2 In Use")
- Update tap handler to navigate to instances screen

#### Step 4: Create ToolInstancesScreen
- New screen showing all instances of a tool group
- List view with each instance as a card
- Shows: serial number, status, assigned to, condition
- Actions: assign, return, edit, view details
- Supports instance-level selection for bulk operations

#### Step 5: Update Search & Filters
- Search: Works on tool group properties (name, category, brand)
- Filters: Apply to groups (show group if any instance matches)
- Status filter: Shows groups where at least one instance matches

### Benefits
✅ **Individual Tracking**: Each tool remains a separate database record
✅ **Clean UI**: No duplicate cards cluttering the interface
✅ **Flexible Management**: Can manage individual instances when needed
✅ **Scalable**: Works with any number of instances
✅ **No Schema Changes**: Uses existing database structure

### Edge Cases to Handle
1. **Different brands/models**: "Drill" from DeWalt vs "Drill" from Milwaukee = separate groups
2. **Missing data**: Tools without brand still groupable by name + category
3. **Selection mode**: When selecting tools for assignment, show instance selection in detail view
4. **Bulk operations**: Add/remove multiple instances at once

### Alternative Approaches Considered

**Option A: Template + Instances (Rejected)**
- Create ToolTemplate table, ToolInstance table
- ❌ Requires database schema changes
- ❌ More complex data model
- ❌ Migration needed for existing data

**Option B: Quantity Field (Rejected)**
- Add `quantity` field to Tool model
- ❌ Loses individual tracking capability
- ❌ Can't track which specific tool is assigned
- ❌ Can't track serial numbers per instance

**Option C: UI Grouping (Selected)**
- Group in UI only, keep individual records
- ✅ No schema changes
- ✅ Maintains individual tracking
- ✅ Flexible and scalable

### Next Steps
1. Review and approve this plan
2. Implement ToolGroup model
3. Add grouping logic
4. Update UI components
5. Create ToolInstancesScreen
6. Test with multiple instances
7. Handle edge cases



