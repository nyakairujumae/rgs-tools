# Bulk Refactoring Guide - ChatGPT Style Theme

## Quick Find & Replace Patterns

Use these patterns in your IDE to quickly refactor screens:

### 1. Replace Hardcoded Shadows
**Find:**
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
],
```

**Replace with:**
```dart
boxShadow: context.cardShadows, // ChatGPT-style: ultra-soft shadow
```

**Or for single shadow:**
```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.08),
  blurRadius: 18,
  offset: Offset(0, 7),
)
```

**Replace with:**
```dart
context.cardShadows[0] // or just context.cardShadows
```

### 2. Replace Hardcoded Card Backgrounds
**Find:**
```dart
color: Colors.white,
```
**Or:**
```dart
color: isDarkMode ? colorScheme.surface : Colors.white,
```

**Replace with:**
```dart
color: context.cardBackground, // ChatGPT-style: #F5F5F5
```

### 3. Replace Hardcoded Borders
**Find:**
```dart
border: Border.all(
  color: Colors.grey.shade300,
  width: 1,
),
```
**Or:**
```dart
border: isDarkMode
    ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)
    : null,
```

**Replace with:**
```dart
border: Border.all(
  color: context.cardBorder, // ChatGPT-style: #E5E5E5
  width: 1,
),
```

### 4. Replace Hardcoded Container with ThemedCard
**Find:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white, // or context.cardBackground
    borderRadius: BorderRadius.circular(16),
    border: Border.all(...),
    boxShadow: [...],
  ),
  child: ...
)
```

**Replace with:**
```dart
ThemedCard(
  radius: 16,
  padding: EdgeInsets.all(16), // Add your padding
  child: ...
)
```

### 5. Add Theme Extensions Import
**At top of file, add:**
```dart
import '../theme/theme_extensions.dart';
import '../widgets/common/themed_card.dart';
```

### 6. Replace Hardcoded Colors (Semantic Colors)
**For status/condition colors, keep them but use AppTheme constants:**
- `Colors.green` → `AppTheme.successColor` (for success states)
- `Colors.red` → `AppTheme.errorColor` (for error states)
- `Colors.orange` → `AppTheme.warningColor` (for warning states)
- `Colors.blue` → `AppTheme.primaryColor` (for primary actions)

**Note:** Status colors (available=green, maintenance=red) are semantic and can stay as-is.

---

## Files to Refactor (Priority Order)

### ✅ Completed
- `technician_home_screen.dart` - Main dashboard

### 🔄 In Progress
- `technician_my_tools_screen.dart`
- `technician_add_tool_screen.dart`

### 📋 Remaining Technician Screens
- `technician_registration_screen.dart` (mostly done, minor fixes)
- `technician_detail_screen.dart`
- `add_technician_screen.dart`

### 📋 Admin Screens
- `admin_home_screen.dart`
- `admin_registration_screen.dart` (mostly done)
- `add_tool_screen.dart`
- `tools_screen.dart`
- `reports_screen.dart`

### 📋 Common Screens
- `checkin_screen.dart`
- `tool_detail_screen.dart`
- `assign_tool_screen.dart`
- `request_new_tool_screen.dart`
- `add_tool_issue_screen.dart`

---

## Verification Checklist

After refactoring each screen:

- [ ] All `BoxShadow` use `context.cardShadows`
- [ ] All card backgrounds use `context.cardBackground`
- [ ] All borders use `context.cardBorder`
- [ ] All inputs use theme (via `InputDecorationTheme` or `ThemedTextField`)
- [ ] All buttons use theme (via `ElevatedButtonTheme` or `ThemedButton`)
- [ ] No hardcoded `Colors.white` for cards (use `context.cardBackground`)
- [ ] No hardcoded `Colors.black` for shadows (use `context.cardShadows`)
- [ ] Import `theme_extensions.dart` if using `context.cardBackground`, etc.
- [ ] Test in both light and dark mode
- [ ] Verify no logic broken (navigation, state management, etc.)

---

## Common Issues

### Issue 1: Missing Import
**Error:** `context.cardBackground` not found
**Fix:** Add `import '../theme/theme_extensions.dart';`

### Issue 2: Shadow Syntax Error
**Error:** `boxShadow: context.cardShadows,` causes error
**Fix:** Ensure `context.cardShadows` returns `List<BoxShadow>`, which it does.

### Issue 3: Border Always Shows
**Before:**
```dart
border: isDarkMode ? Border.all(...) : null,
```

**After:**
```dart
border: Border.all(
  color: context.cardBorder,
  width: 1,
),
```

---

## Time-Saving Tips

1. **Use IDE Find & Replace** with regex for bulk changes
2. **Focus on high-impact screens first** (home screens, main lists)
3. **Leave semantic colors** (status colors) as-is - they're intentional
4. **Test incrementally** - refactor one screen, test, move to next
5. **Use ThemedCard component** where possible - it handles everything automatically

