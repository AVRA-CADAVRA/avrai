import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/onboarding/onboarding_step.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for PermissionsPage (in onboarding_step.dart)
/// Tests permissions page for enabling connectivity and location
void main() {
  group('PermissionsPage Widget Tests', () {
    testWidgets('displays permissions page', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PermissionsPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(PermissionsPage), findsOneWidget);
      expect(find.text('Enable Connectivity & Location'), findsOneWidget);
    });

    testWidgets('displays permission request buttons', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PermissionsPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Enable All'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('displays permission descriptions', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PermissionsPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show description text
      expect(find.textContaining('To enable ai2ai connectivity'), findsOneWidget);
    });

    testWidgets('handles permission status display', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const PermissionsPage(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should handle permission statuses
      expect(find.byType(PermissionsPage), findsOneWidget);
    });

    testWidgets('displays OnboardingStep enum values', (WidgetTester tester) async {
      // Assert - Test OnboardingStepType enum
      expect(OnboardingStepType.values.length, equals(5));
      expect(OnboardingStepType.homebase, isNotNull);
      expect(OnboardingStepType.favoritePlaces, isNotNull);
      expect(OnboardingStepType.preferences, isNotNull);
      expect(OnboardingStepType.baselineLists, isNotNull);
      expect(OnboardingStepType.friends, isNotNull);
    });
  });
}

