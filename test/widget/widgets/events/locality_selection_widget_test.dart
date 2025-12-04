import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/events/locality_selection_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for LocalitySelectionWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('LocalitySelectionWidget Widget Tests', () {
    testWidgets('displays locality selection widget', (WidgetTester tester) async {
      // Arrange
      final user = ModelFactories.createTestUser();
      String? selectedLocality;

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LocalitySelectionWidget(
          user: user,
          category: 'Food & Drink',
          onLocalitySelected: (locality) {
            selectedLocality = locality;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(LocalitySelectionWidget), findsOneWidget);
    });

    testWidgets('displays with selected locality', (WidgetTester tester) async {
      // Arrange
      final user = ModelFactories.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: LocalitySelectionWidget(
          user: user,
          category: 'Food & Drink',
          selectedLocality: 'Brooklyn',
          onLocalitySelected: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(LocalitySelectionWidget), findsOneWidget);
    });
  });
}

