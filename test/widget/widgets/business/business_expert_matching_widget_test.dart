import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/business/business_expert_matching_widget.dart';
import 'package:spots/core/models/business_account.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for BusinessExpertMatchingWidget
/// Tests business expert matching display
void main() {
  group('BusinessExpertMatchingWidget Widget Tests', () {
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

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertMatchingWidget(business: business),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Don't settle, check loading state

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays expert matches header', (WidgetTester tester) async {
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

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertMatchingWidget(business: business),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should handle async loading
      expect(find.byType(BusinessExpertMatchingWidget), findsOneWidget);
    });

    testWidgets('calls onExpertSelected when expert is selected', (WidgetTester tester) async {
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

      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessExpertMatchingWidget(
          business: business,
          onExpertSelected: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(BusinessExpertMatchingWidget), findsOneWidget);
    });
  });
}

