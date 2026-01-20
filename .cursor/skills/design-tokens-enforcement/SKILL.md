---
name: design-tokens-enforcement
description: Enforces design token usage (AppColors/AppTheme) instead of direct Colors.*. Use when writing UI code, reviewing widgets, or ensuring design consistency.
---

# Design Tokens Enforcement

## Mandatory Rule

**✅ ALWAYS use `AppColors` or `AppTheme` for colors**
**❌ NEVER use direct `Colors.*`**

## Import Pattern

```dart
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
```

## Color Usage

### ✅ GOOD
```dart
Container(
  color: AppColors.electricGreen,
  child: Text(
    'Hello',
    style: TextStyle(color: AppTheme.textPrimary),
  ),
)

// Background colors
Container(
  color: AppColors.grey50,  // Light background
  color: AppColors.grey900, // Dark background
)

// Semantic colors
Text(
  'Error message',
  style: TextStyle(color: AppColors.error),
)
```

### ❌ BAD
```dart
Container(
  color: Colors.blue,  // Don't use direct Colors.*
  color: Colors.green, // Don't use
  color: Color(0xFF00FF66), // Don't hardcode colors
)
```

## Theme Usage

Use `AppTheme` for consistent theme-aware styling:

```dart
Text(
  'Hello',
  style: TextStyle(
    color: AppTheme.textPrimary,
    fontSize: AppTheme.fontSizeLarge,
  ),
)
```

## Why This Matters

- **Design Consistency** - Ensures consistent design across app
- **Theme Support** - Supports light/dark themes
- **Maintainability** - Centralized design tokens
- **Brand Alignment** - Enforces brand colors

## Design Token Reference

See available tokens in:
- `lib/core/theme/colors.dart` - Color definitions
- `lib/core/theme/app_theme.dart` - Theme definitions

## Common Colors Available

```dart
AppColors.electricGreen  // Primary brand accent
AppColors.black          // Pure black
AppColors.white          // Pure white
AppColors.grey50         // Lightest grey
AppColors.grey900        // Darkest grey
AppColors.error          // Error red
AppColors.warning        // Warning yellow
AppColors.success        // Success green (electricGreen)
```

## Migration Pattern

When converting existing code:

```dart
// Before
Container(color: Colors.blue)

// After
Container(color: AppColors.electricGreen)
```

**Always use brand-accurate colors, not arbitrary color choices.**
