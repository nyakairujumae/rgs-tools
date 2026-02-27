# Global Theme Application Guide

## Problem
The app currently has screens with hardcoded styles (Colors.white, Colors.black, custom BoxDecoration, etc.) instead of using the global theme system. This makes it difficult to apply changes globally.

## Solution
We've created reusable theme-aware components that automatically use the global theme. By replacing hardcoded styles with these components, you can apply theme changes globally.

---

## 🎨 Reusable Theme Components

### 1. ThemedCard
**Location:** `lib/widgets/common/themed_card.dart`

**Replaces:** `Container` with hardcoded `BoxDecoration`

**Before:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white, // ❌ Hardcoded
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey),
    boxShadow: [...],
  ),
  child: ...
)
```

**After:**
```dart
import 'package:rgsapp/widgets/common/themed_card.dart';

ThemedCard(
  padding: EdgeInsets.all(16),
  child: ...
)
```

**With tap:**
```dart
ThemedCard(
  onTap: () => _handleTap(),
  child: ...
)
```

---

### 2. ThemedTextField
**Location:** `lib/widgets/common/themed_text_field.dart`

**Replaces:** `TextFormField` with hardcoded `InputDecoration`

**Before:**
```dart
TextFormField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white, // ❌ Hardcoded
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey),
    ),
    // ... many more hardcoded properties
  ),
)
```

**After:**
```dart
import 'package:rgsapp/widgets/common/themed_text_field.dart';

ThemedTextField(
  controller: _controller,
  label: 'Email Address',
  hint: 'Enter your email',
  prefixIcon: Icons.email,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

**With label:**
```dart
ThemedLabeledField(
  label: 'Password',
  child: ThemedTextField(
    controller: _controller,
    obscureText: true,
  ),
)
```

---

### 3. ThemedButton
**Location:** `lib/widgets/common/themed_button.dart`

**Replaces:** `ElevatedButton` with hardcoded styles

**Before:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green, // ❌ Hardcoded
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // ❌ Hardcoded
    ),
    // ...
  ),
  child: Text('Submit'),
)
```

**After:**
```dart
import 'package:rgsapp/widgets/common/themed_button.dart';

ThemedButton(
  onPressed: () => _handleSubmit(),
  child: Text('Submit'),
)

// With loading state
ThemedButton(
  onPressed: isLoading ? null : _handleSubmit,
  isLoading: isLoading,
  child: Text('Submit'),
)
```

---

## 🔄 Refactoring Strategy

### Step 1: Import Theme Extensions
Add this import to any screen you're refactoring:
```dart
import '../theme/theme_extensions.dart';
```

### Step 2: Replace Hardcoded Containers

**Find:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
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
  padding: EdgeInsets.all(16), // Add your padding here
  child: ...
)
```

### Step 3: Replace Hardcoded TextFields

**Find:**
```dart
TextFormField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    // ... many properties
  ),
)
```

**Replace with:**
```dart
ThemedTextField(
  controller: _controller,
  label: 'Field Label',
  hint: 'Enter value',
  prefixIcon: Icons.icon_name,
)
```

### Step 4: Replace Hardcoded Buttons

**Find:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    // ... many properties
  ),
  child: Text('Button'),
)
```

**Replace with:**
```dart
ThemedButton(
  onPressed: () => _handleAction(),
  child: Text('Button'),
)
```

---

## 📋 Quick Reference

### Colors (Use Theme Extensions)
```dart
context.scaffoldBackground  // Pure white (#FFFFFF)
context.cardBackground       // Soft off-white (#F5F5F5)
context.cardBorder           // Light border (#E5E5E5)
context.inputBackground      // Input field background
```

### Spacing (Use Theme Constants)
```dart
AppTheme.spacingMicro    // 4px
AppTheme.spacingSmall    // 8px
AppTheme.spacingMedium   // 12px
AppTheme.spacingLarge    // 16px
```

### Border Radius (Use Theme Constants)
```dart
AppTheme.borderRadiusSmall   // 12px
AppTheme.borderRadiusMedium  // 14px (inputs)
AppTheme.borderRadiusLarge   // 16px (cards)
AppTheme.borderRadiusXLarge  // 20px (prominent cards)
```

### Shadows (Use Theme Extensions)
```dart
context.softShadow    // Single shadow
context.cardShadows   // List of shadows for cards
```

---

## 🎯 Priority Screens to Refactor

Based on analysis, these screens have the most hardcoded styles:

1. **High Priority:**
   - `lib/screens/tools_screen.dart`
   - `lib/screens/technician_home_screen.dart`
   - `lib/screens/admin_home_screen.dart`
   - `lib/screens/add_tool_screen.dart`
   - `lib/screens/add_tool_issue_screen.dart`

2. **Medium Priority:**
   - `lib/screens/checkin_screen.dart`
   - `lib/screens/reports_screen.dart`
   - `lib/screens/assign_tool_screen.dart`
   - `lib/screens/request_new_tool_screen.dart`

3. **Low Priority (Auth screens - already styled):**
   - `lib/screens/auth/login_screen.dart`
   - `lib/screens/auth/register_screen.dart`

---

## ✅ Benefits

1. **Global Changes:** Update `app_theme.dart` once, changes apply everywhere
2. **Consistency:** All screens use the same styling automatically
3. **Maintainability:** Less code duplication, easier to maintain
4. **Theme Support:** Automatic light/dark mode support
5. **Future-Proof:** Easy to update design system

---

## 🚀 Example: Complete Screen Refactor

**Before:**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade300),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    children: [
      TextFormField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      SizedBox(height: 16),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('Submit'),
      ),
    ],
  ),
)
```

**After:**
```dart
ThemedCard(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      ThemedTextField(
        controller: _controller,
        label: 'Field Label',
        hint: 'Enter value',
      ),
      SizedBox(height: AppTheme.spacingLarge),
      ThemedButton(
        onPressed: () => _handleSubmit(),
        child: Text('Submit'),
      ),
    ],
  ),
)
```

**Result:** 70% less code, automatically theme-aware, consistent styling!

---

## 📝 Notes

- The theme is already configured globally in `main.dart`
- All components automatically respect light/dark mode
- You can still override specific properties if needed (e.g., `ThemedCard(color: Colors.blue)`)
- The components use the ChatGPT-style theme by default

