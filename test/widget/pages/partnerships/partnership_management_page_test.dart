import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/presentation/pages/partnerships/partnership_management_page.dart';

/// Partnership Management Page Widget Tests
/// 
/// Agent 2: Partnership UI, Business UI (Week 8)
/// 
/// Tests the partnership management page functionality.
void main() {
  group('PartnershipManagementPage Widget Tests', () {
    testWidgets('should display partnership management page', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipManagementPage(),
        ),
      );

      // Assert
      expect(find.text('My Partnerships'), findsOneWidget);
    });

    testWidgets('should display tab navigation', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipManagementPage(),
        ),
      );

      // Assert
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('should display new partnership button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipManagementPage(),
        ),
      );

      // Assert
      expect(find.text('New Partnership'), findsOneWidget);
    });

    testWidgets('should show empty state when no partnerships', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should show empty state for at least one tab
      expect(find.text('No active partnerships'), findsOneWidget);
    });
  });
}

