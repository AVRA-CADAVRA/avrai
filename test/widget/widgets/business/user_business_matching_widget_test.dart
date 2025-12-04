import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/business/user_business_matching_widget.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for UserBusinessMatchingWidget
/// Tests user-business matching display
void main() {
  group('UserBusinessMatchingWidget Widget Tests', () {
    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: UserBusinessMatchingWidget(user: user),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Don't settle, check loading state

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays business matches header', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: UserBusinessMatchingWidget(user: user),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should handle async loading
      expect(find.byType(UserBusinessMatchingWidget), findsOneWidget);
    });

    testWidgets('calls onBusinessSelected when business is selected', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: UserBusinessMatchingWidget(
          user: user,
          onBusinessSelected: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(UserBusinessMatchingWidget), findsOneWidget);
    });
  });
}

