# Theme System Guide

## Overview
The app now uses a centralized theme system that makes it easy to apply color changes across the entire app while respecting theme awareness (light/dark mode).

## Key Colors

### Light Mode (Default)
- **Scaffold Background**: Pure white (`Colors.white`)
- **Card Background**: Light gray (`Color(0xFFF5F5F5)`)
- **Input Field Background**: White (`Colors.white`)
- **App Bar Background**: Pure white (`Colors.white`)

### Dark Mode
- **Scaffold Background**: Pure black (`Color(0xFF000000)`)
- **Card Background**: Dark gray (`Color(0xFF161B22)`)
- **Input Field Background**: Dark surface (`Color(0xFF0D1117)`)
- **App Bar Background**: Pure black (`Color(0xFF000000)`)

## How to Use

### Method 1: Using Theme Extension (Recommended)
Import the extension and use it directly in your widgets:

```dart
import '../theme/theme_extensions.dart';

// In your widget build method:
Container(
  color: context.scaffoldBackground, // Automatically adapts to theme
  child: Card(
    color: context.cardBackground, // f5f5f5 in light, dark gray in dark
    child: ...
  ),
)

// For input fields:
TextFormField(
  decoration: InputDecoration(
    fillColor: context.inputBackground,
  ),
)
```

### Method 2: Using AppTheme Static Methods
Use the static methods directly:

```dart
import '../theme/app_theme.dart';

Container(
  color: AppTheme.getScaffoldBackground(context),
  child: Card(
    color: AppTheme.getCardBackground(context),
    child: ...
  ),
)
```

### Method 3: Using Theme.of(context) (For ThemeData properties)
The theme is already configured, so you can use:

```dart
Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Already white
  body: Card(
    color: Theme.of(context).cardTheme.color, // Already f5f5f5
    child: ...
  ),
)
```

## Refactoring Existing Screens

### Before:
```dart
Container(
  color: Colors.white, // Hard-coded
  child: Container(
    decoration: BoxDecoration(
      color: isDarkMode ? theme.colorScheme.surface : Colors.white,
    ),
  ),
)
```

### After:
```dart
import '../theme/theme_extensions.dart';

Container(
  color: context.scaffoldBackground, // Theme-aware
  child: Container(
    decoration: BoxDecoration(
      color: context.cardBackground, // Theme-aware
    ),
  ),
)
```

## Benefits

1. **Single Source of Truth**: Change colors in `app_theme.dart` and they apply everywhere
2. **Theme Awareness**: Automatically adapts to light/dark mode
3. **Easy Refactoring**: Simple find-and-replace operations
4. **Type Safety**: Compile-time checking
5. **Consistency**: All screens use the same color system

## Changing Colors Globally

To change colors for the entire app, simply update the constants in `app_theme.dart`:

```dart
// In app_theme.dart
static const Color scaffoldBackground = Colors.white; // Change this
static const Color cardBackground = Color(0xFFF5F5F5); // Change this
```

All screens using the theme system will automatically update!

## Migration Checklist

When refactoring a screen:
- [ ] Import `theme_extensions.dart`
- [ ] Replace hard-coded `Colors.white` with `context.scaffoldBackground` or `context.cardBackground`
- [ ] Replace `isDarkMode ? darkColor : lightColor` patterns with theme extension methods
- [ ] Test in both light and dark mode
- [ ] Remove unused color constants from the screen



