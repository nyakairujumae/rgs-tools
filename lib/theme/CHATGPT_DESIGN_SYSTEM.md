# ChatGPT-Style Design System Reference

This document serves as the **single source of truth** for the premium ChatGPT-style light design system applied across the entire RGS Tools app.

## 🎨 Design Philosophy

- **Minimal & Clean**: White canvas with soft grey surfaces
- **Premium Enterprise Feel**: Suitable for HVAC tools management
- **Consistent Spacing**: Strict 4/8/12/16/20-24px scale
- **Gentle Shadows**: Ultra-soft depth (0.04 opacity)
- **iOS-Style Navigation**: Chevron-left back buttons
- **Modern Typography**: Clear hierarchy with #1A1A1A primary text

---

## 1️⃣ Global Colors

### Backgrounds
```dart
// Main app background
scaffoldBackgroundColor: Colors.white // #FFFFFF

// Card / Input / Surface background
cardBackground: Color(0xFFF5F5F5) // Soft off-white

// App bar background
appBarBackground: Colors.white // #FFFFFF
```

### Borders & Dividers
```dart
// Card borders
cardBorder: Color(0xFFE5E5E5)

// Dividers
dividerColor: Color(0xFFE0E0E0)
```

### Shadows
```dart
// Ultra-soft shadow for cards
BoxShadow(
  color: Colors.black.withOpacity(0.04), // rgba(0,0,0,0.04)
  blurRadius: 10,
  offset: Offset(0, 4),
)
```

### Text Colors
```dart
// Primary text (headings, body)
textPrimary: Color(0xFF1A1A1A) // Dark grey-black, not pure black

// Secondary text (subtitles, hints)
textSecondary: Color.fromRGBO(0, 0, 0, 0.6) // rgba(0,0,0,0.6)
```

### Accent Color
```dart
// Use AppTheme.secondaryColor (green) for:
// - Primary buttons
// - Focus states
// - Links
// - Selected states
accentColor: AppTheme.secondaryColor // #047857
```

---

## 2️⃣ Card Design

**Apply to ALL cards**: tool cards, featured cards, profile cards, container forms, etc.

```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFFF5F5F5), // Card background
    borderRadius: BorderRadius.circular(16), // 16-20px
    border: Border.all(
      color: Color(0xFFE5E5E5), // Border color
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(16), // Consistent padding
  child: // Your content
)
```

**Quick Reference:**
- Use `context.cardDecoration` for automatic styling
- Or use `Card` widget (automatically styled via `CardTheme`)

---

## 3️⃣ Input Field Design

**Apply to ALL TextFields and TextFormFields:**

```dart
TextFormField(
  filled: true,
  fillColor: Color(0xFFF5F5F5), // Input background
  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  style: TextStyle(
    fontSize: 15,
    color: Color(0xFF1A1A1A), // Primary text color
  ),
  decoration: InputDecoration(
    prefixIcon: Icon(..., size: 20, color: Colors.grey[600]),
    hintStyle: TextStyle(color: Colors.black54),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: AppTheme.secondaryColor, // Green
        width: 1.3,
      ),
    ),
  ),
)
```

**Spacing between input fields:** 12-14px (`context.spacingMedium`)

**Quick Reference:**
- Use `context.chatGPTInputDecoration` for automatic styling
- Or rely on global `InputDecorationTheme` (already applied)

---

## 4️⃣ Form Screens

**Layout structure for all form screens** (login, register, add tool, report issue, etc.):

```dart
Scaffold(
  backgroundColor: Colors.white,
  body: SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 20), // 20px horizontal padding
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24), // Top spacing
        
        // Large title
        Text(
          'Form Title',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        
        SizedBox(height: 8), // Small gap
        
        // Subtitle
        Text(
          'Subtitle with medium weight',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color.fromRGBO(0, 0, 0, 0.6),
          ),
        ),
        
        SizedBox(height: 24), // Major separation
        
        // Form fields (use input field design above)
        // Spacing between fields: 12-14px
        
        SizedBox(height: 20), // Gap before button
        
        // Primary action button
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), // 14-18px
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 52), // Large button
          ),
          child: Text('Submit'),
        ),
      ],
    ),
  ),
)
```

---

## 5️⃣ Spacing System

**Strict spacing scale - apply everywhere:**

```dart
// Available via context extensions:
context.spacingMicro  // 4px  → tiny spacing (icons, micro gaps)
context.spacingSmall   // 8px  → small spacing
context.spacingMedium  // 12px → medium spacing (between inputs, inside cards)
context.spacingLarge   // 16px → section spacing
// 20-24px → page top padding, major separation (use directly)
```

**Usage:**
```dart
SizedBox(height: context.spacingMedium), // 12px
SizedBox(height: context.spacingLarge),  // 16px
SizedBox(height: 24),                    // Major separation
```

---

## 6️⃣ Back Button Style

**Replace ALL back buttons with chevron-left:**

```dart
leading: IconButton(
  icon: Icon(
    Icons.chevron_left, // NOT arrow_back, NOT custom icons
    size: 28,
    color: Colors.black87, // Or Color(0xFF1A1A1A)
  ),
  onPressed: () => Navigator.pop(context),
  splashRadius: 24,
),
```

**Important:** 
- Use `Icons.chevron_left` (iOS-style chevron)
- Size: 28px
- Color: `Colors.black87` or `Color(0xFF1A1A1A)`
- `splashRadius: 24` for proper touch target

---

## 7️⃣ App Bar Style

**Apply to ALL AppBars:**

```dart
AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  shadowColor: Colors.black.withOpacity(0.04),
  surfaceTintColor: Colors.transparent,
  centerTitle: true,
  titleTextStyle: TextStyle(
    fontSize: 18, // 18-20px
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A1A1A),
  ),
  // Bottom corners rounded only for home dashboard AppBar
)
```

**Note:** Already applied globally via `AppBarTheme`, but can be overridden per screen if needed.

---

## 8️⃣ List Items & Tool Cards

**All tool cards MUST adopt:**

```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFFF5F5F5), // Card background
    borderRadius: BorderRadius.circular(16), // 16-20px
    border: Border.all(color: Color(0xFFE5E5E5), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(16),
  child: // Tool card content
)
```

**Chip Styles:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.white, // or very light grey
    borderRadius: BorderRadius.circular(10), // 10-12px
    border: Border.all(color: Color(0xFFE5E5E5), width: 1),
  ),
  child: Text(
    'Status',
    style: TextStyle(
      color: Color(0xFF1A1A1A),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

---

## 9️⃣ Remove Old Styles

**DO NOT USE:**
- ❌ Dark heavy shadows (`opacity > 0.1`)
- ❌ Overly rounded borders (`radius > 24px` except hero elements)
- ❌ Large inconsistent padding (`> 32px` without reason)
- ❌ Old grey backgrounds (`#FAFAFA`, `#EFEFEF`) → use `#F5F5F5`
- ❌ Old arrow_back icons → use `chevron_left`
- ❌ Pure black text → use `#1A1A1A`

---

## 🔟 Implementation Checklist

When updating a screen, ensure:

- [ ] Background is `Colors.white` (#FFFFFF)
- [ ] Cards use `#F5F5F5` background with `#E5E5E5` border
- [ ] Input fields use `#F5F5F5` background, 16px radius, proper padding
- [ ] Spacing follows 4/8/12/16/20-24px scale
- [ ] Text colors: `#1A1A1A` for primary, `rgba(0,0,0,0.6)` for secondary
- [ ] Shadows are ultra-soft (`opacity: 0.04`)
- [ ] Back button uses `Icons.chevron_left` (size 28)
- [ ] Buttons use `AppTheme.secondaryColor` (green) with 14-18px radius
- [ ] App bar is white with proper elevation and shadow
- [ ] No old styles remain (heavy shadows, inconsistent padding, etc.)

---

## 📚 Quick Reference Helpers

### Context Extensions (via `theme_extensions.dart`)

```dart
// Colors
context.scaffoldBackground  // White background
context.cardBackground     // #F5F5F5
context.cardBorder         // #E5E5E5
context.secondaryTextColor // rgba(0,0,0,0.6)

// Spacing
context.spacingMicro   // 4px
context.spacingSmall   // 8px
context.spacingMedium  // 12px
context.spacingLarge   // 16px

// Border Radius
context.borderRadiusSmall  // 12px
context.borderRadiusMedium // 14px
context.borderRadiusLarge  // 16px
context.borderRadiusXLarge // 20px

// Decorations
context.cardDecoration        // Full card decoration
context.chatGPTInputDecoration // Full input decoration
context.cardShadows          // Shadow list
```

### AppTheme Static Methods

```dart
AppTheme.getScaffoldBackground(context) // White
AppTheme.getCardBackground(context)      // #F5F5F5
AppTheme.getInputBackground(context)     // #F5F5F5
AppTheme.secondaryColor                  // Green accent
AppTheme.textPrimary                     // #1A1A1A
AppTheme.textSecondary                   // rgba(0,0,0,0.6)
```

---

## 🎯 Example: Complete Card Implementation

```dart
Container(
  decoration: context.cardDecoration, // Automatic styling
  padding: EdgeInsets.all(context.spacingLarge), // 16px
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Card Title',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary, // #1A1A1A
        ),
      ),
      SizedBox(height: context.spacingSmall), // 8px
      Text(
        'Card subtitle',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary, // rgba(0,0,0,0.6)
        ),
      ),
    ],
  ),
)
```

---

## ✅ Status

- ✅ Theme system updated with all design tokens
- ✅ Global colors defined
- ✅ Card design standardized
- ✅ Input field design standardized
- ✅ Spacing system implemented
- ✅ Back buttons updated to chevron_left
- ✅ App bar theme configured
- ✅ Text colors updated (#1A1A1A primary, rgba(0,0,0,0.6) secondary)

**Next Steps:**
- Apply design system to remaining screens incrementally
- Use this document as reference for all new screens
- Remove old styles as screens are updated

