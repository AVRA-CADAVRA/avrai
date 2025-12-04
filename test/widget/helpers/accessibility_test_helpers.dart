import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/theme/colors.dart';

/// Accessibility testing helpers for WCAG 2.1 AA compliance
class AccessibilityTestHelpers {
  /// Minimum touch target size (44x44pt for iOS, 48x48dp for Android)
  /// Using 44pt as the minimum standard
  static const double minTouchTargetSize = 44.0;

  /// Minimum contrast ratio for normal text (WCAG 2.1 AA)
  static const double minContrastRatioNormal = 4.5;

  /// Minimum contrast ratio for large text (WCAG 2.1 AA)
  static const double minContrastRatioLarge = 3.0;

  /// Minimum contrast ratio for UI components (WCAG 2.1 AA)
  static const double minContrastRatioUI = 3.0;

  /// Calculates the relative luminance of a color (0-1)
  /// Based on WCAG 2.1 formula
  static double getRelativeLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    // Apply gamma correction
    final rLinear = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
    final gLinear = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
    final bLinear = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }

  /// Calculates contrast ratio between two colors
  /// Returns a value between 1 and 21
  static double getContrastRatio(Color color1, Color color2) {
    final lum1 = getRelativeLuminance(color1);
    final lum2 = getRelativeLuminance(color2);

    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Verifies color contrast meets WCAG 2.1 AA requirements
  /// Returns true if contrast is sufficient, false otherwise
  static bool verifyContrastRatio(
    Color foreground,
    Color background, {
    bool isLargeText = false,
    bool isUIComponent = false,
  }) {
    final ratio = getContrastRatio(foreground, background);

    if (isUIComponent) {
      return ratio >= minContrastRatioUI;
    } else if (isLargeText) {
      return ratio >= minContrastRatioLarge;
    } else {
      return ratio >= minContrastRatioNormal;
    }
  }

  /// Verifies touch target size meets minimum requirements
  /// Returns true if size is sufficient, false otherwise
  static bool verifyTouchTargetSize(Size size) {
    return size.width >= minTouchTargetSize && size.height >= minTouchTargetSize;
  }

  /// Verifies a widget has semantic labels for screen readers
  static bool hasSemanticLabel(WidgetTester tester, Finder finder) {
    final semantics = tester.getSemantics(finder);
    if (semantics == null) return false;
    final label = semantics.label;
    return label != null && label.isNotEmpty;
  }

  /// Verifies a widget is keyboard accessible
  static bool isKeyboardAccessible(WidgetTester tester, Finder finder) {
    final widget = tester.widget(finder);
    return widget is Focus ||
        widget is TextField ||
        widget is TextFormField ||
        widget is ElevatedButton ||
        widget is TextButton ||
        widget is OutlinedButton ||
        widget is IconButton ||
        widget is Switch ||
        widget is Checkbox ||
        widget is Radio ||
        widget is Slider;
  }

  /// Verifies focus indicators are visible
  static bool hasFocusIndicator(WidgetTester tester, Finder finder) {
    final widget = tester.widget(finder);
    // Check if widget has focus decoration or border
    if (widget is Container) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        return decoration.border != null;
      }
    }
    // Material widgets typically have focus indicators
    return widget is Material || widget is InkWell || widget is InkResponse;
  }

  /// Tests all interactive elements for accessibility
  static Map<String, dynamic> testWidgetAccessibility(
    WidgetTester tester,
    Finder widgetFinder,
  ) {
    final results = <String, dynamic>{
      'hasSemanticLabel': false,
      'isKeyboardAccessible': false,
      'hasFocusIndicator': false,
      'touchTargetSize': null,
      'contrastRatio': null,
    };

    if (widgetFinder.evaluate().isEmpty) {
      return results;
    }

    results['hasSemanticLabel'] = hasSemanticLabel(tester, widgetFinder);
    results['isKeyboardAccessible'] = isKeyboardAccessible(tester, widgetFinder);
    results['hasFocusIndicator'] = hasFocusIndicator(tester, widgetFinder);

    // Get widget size
    try {
      final renderObject = tester.getSize(widgetFinder);
      results['touchTargetSize'] = {
        'width': renderObject.width,
        'height': renderObject.height,
        'meetsMinimum': verifyTouchTargetSize(renderObject),
      };
    } catch (e) {
      // Widget size not available
    }

    return results;
  }

  /// Validates common color combinations from AppColors
  static Map<String, dynamic> validateAppColorsContrast() {
    final results = <String, dynamic>{
      'normalText': <String, bool>{},
      'largeText': <String, bool>{},
      'uiComponents': <String, bool>{},
      'violations': <String>[],
    };

    // Test common text color combinations
    final textColors = [
      AppColors.textPrimary,
      AppColors.textSecondary,
      AppColors.textHint,
      AppColors.black,
      AppColors.white,
    ];

    final backgroundColors = [
      AppColors.white,
      AppColors.grey100,
      AppColors.grey200,
      AppColors.grey300,
      AppColors.grey800,
      AppColors.grey900,
      AppColors.black,
      AppColors.electricGreen,
    ];

    for (final textColor in textColors) {
      for (final bgColor in backgroundColors) {
        final key = '${textColor.value.toRadixString(16)}_on_${bgColor.value.toRadixString(16)}';
        
        // Normal text
        final normalPass = verifyContrastRatio(textColor, bgColor, isLargeText: false);
        results['normalText'][key] = normalPass;
        if (!normalPass) {
          results['violations'].add('Normal text: $key');
        }

        // Large text
        final largePass = verifyContrastRatio(textColor, bgColor, isLargeText: true);
        results['largeText'][key] = largePass;
        if (!largePass) {
          results['violations'].add('Large text: $key');
        }
      }
    }

    // Test UI component colors
    final uiColors = [
      AppColors.electricGreen,
      AppColors.error,
      AppColors.warning,
      AppColors.success,
    ];

    for (final uiColor in uiColors) {
      for (final bgColor in backgroundColors) {
        final key = '${uiColor.value.toRadixString(16)}_on_${bgColor.value.toRadixString(16)}';
        final uiPass = verifyContrastRatio(uiColor, bgColor, isUIComponent: true);
        results['uiComponents'][key] = uiPass;
        if (!uiPass) {
          results['violations'].add('UI component: $key');
        }
      }
    }

    return results;
  }
}

