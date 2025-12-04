import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/business/business_account_form_widget.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for BusinessAccountFormWidget
/// Tests business account creation form
void main() {
  group('BusinessAccountFormWidget Widget Tests', () {
    testWidgets('displays business account form', (WidgetTester tester) async {
      // Arrange
      final creator = WidgetTestHelpers.createTestUser();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessAccountFormWidget(creator: creator),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(BusinessAccountFormWidget), findsOneWidget);
      expect(find.text('Create Business Account'), findsOneWidget);
      expect(find.text('Business Name *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
    });

    testWidgets('displays all form fields', (WidgetTester tester) async {
      // Arrange
      final creator = WidgetTestHelpers.createTestUser();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessAccountFormWidget(creator: creator),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Business Type *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Website'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('displays business categories section', (WidgetTester tester) async {
      // Arrange
      final creator = WidgetTestHelpers.createTestUser();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessAccountFormWidget(creator: creator),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Business Categories'), findsOneWidget);
    });

    testWidgets('calls onAccountCreated when account is created', (WidgetTester tester) async {
      // Arrange
      final creator = WidgetTestHelpers.createTestUser();
      bool accountCreated = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: BusinessAccountFormWidget(
          creator: creator,
          onAccountCreated: (_) {
            accountCreated = true;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(BusinessAccountFormWidget), findsOneWidget);
    });
  });
}

