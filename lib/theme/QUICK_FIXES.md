# Quick Fixes - ChatGPT Style Theme

## ✅ Completed Screens
1. ✅ `technician_home_screen.dart` - Main dashboard
2. ✅ `technician_my_tools_screen.dart` - Tool list
3. ✅ `technician_add_tool_screen.dart` - Add tool form
4. ✅ `technician_registration_screen.dart` - Registration (mostly done)
5. ✅ `admin_registration_screen.dart` - Admin registration (mostly done)

## 🔄 Remaining Critical Screens

### High Priority (Most Visible)
- `admin_home_screen.dart` - Admin dashboard
- `tools_screen.dart` - Main tools list
- `technicians_screen.dart` - Technicians list
- `checkin_screen.dart` - Check-in screen
- `tool_detail_screen.dart` - Tool details

### Medium Priority
- `add_tool_screen.dart` - Add tool (admin)
- `reports_screen.dart` - Reports
- `assign_tool_screen.dart` - Assign tool
- `request_new_tool_screen.dart` - Request tool
- `add_tool_issue_screen.dart` - Report issue

### Lower Priority (Less Visible)
- Other detail/edit screens
- Settings screens
- Utility screens

## 🚀 Quick Fix Patterns

### Pattern 1: Replace All Shadows
**Find (Regex):**
```
boxShadow:\s*\[\s*BoxShadow\([^)]*Colors\.black[^)]*\)[^]]*\]
```

**Replace with:**
```
boxShadow: context.cardShadows, // ChatGPT-style: ultra-soft shadow
```

### Pattern 2: Replace Card Backgrounds
**Find:**
```
color: Colors\.white
```

**Replace with:**
```
color: context.cardBackground
```

### Pattern 3: Replace Borders
**Find:**
```
border: Border\.all\([^)]*Colors\.(white|grey|black)[^)]*\)
```

**Replace with:**
```
border: Border.all(color: context.cardBorder, width: 1)
```

## 📝 Manual Fixes Needed

Some screens need manual attention:
- Screens with complex gradients (keep gradients, just fix shadows/borders)
- Screens with semantic colors (status colors - keep as-is)
- Screens with special effects (glassmorphism, etc. - keep effects, fix base colors)

