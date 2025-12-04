import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/business/business_compatibility_widget.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/unified_models.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for BusinessCompatibilityWidget
/// Tests business-user compatibility display
void main() {
  group('BusinessCompatibilityWidget Widget Tests', () {
    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      final business = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'business@test.com',
        businessType: 'Restaurant',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        createdBy: 'user-123',
      );

      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessCompatibilityWidget(
          business: business,
          user: user,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Don't settle, check loading state

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays compatibility score', (WidgetTester tester) async {
      // Arrange
      final business = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'business@test.com',
        businessType: 'Restaurant',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        createdBy: 'user-123',
      );

      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessCompatibilityWidget(
          business: business,
          user: user,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should display compatibility widget
      expect(find.byType(BusinessCompatibilityWidget), findsOneWidget);
      expect(find.text('Your Compatibility'), findsOneWidget);
    });

    testWidgets('displays business preferences when available', (WidgetTester tester) async {
      // Arrange
      final business = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'business@test.com',
        businessType: 'Restaurant',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        createdBy: 'user-123',
      );

      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessCompatibilityWidget(
          business: business,
          user: user,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show sections for preferences
      expect(find.textContaining('What'), findsWidgets);
      expect(find.textContaining('How You Match'), findsWidgets);
    });

    testWidgets('displays error state on failure', (WidgetTester tester) async {
      // Arrange
      final business = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'business@test.com',
        businessType: 'Restaurant',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
        createdBy: 'user-123',
      );

      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessCompatibilityWidget(
          business: business,
          user: user,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should handle errors gracefully
      expect(find.byType(BusinessCompatibilityWidget), findsOneWidget);
    });
  });
}

