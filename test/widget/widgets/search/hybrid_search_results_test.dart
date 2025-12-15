import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/search/hybrid_search_results.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for HybridSearchResults
/// Tests search results display and BLoC integration
void main() {
  group('HybridSearchResults Widget Tests', () {
    late MockHybridSearchBloc mockHybridSearchBloc;

    setUp(() {
      mockHybridSearchBloc = MockHybridSearchBloc();
    });

    testWidgets('displays initial state message', (WidgetTester tester) async {
      // Arrange
      mockHybridSearchBloc.setState(HybridSearchInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchResults(),
        hybridSearchBloc: mockHybridSearchBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show initial message
      expect(find.text('Search for spots'), findsOneWidget);
      expect(find.text('Find community spots and external places'), findsOneWidget);
    });

    testWidgets('displays loading state', (WidgetTester tester) async {
      // Arrange
      mockHybridSearchBloc.setState(HybridSearchLoading());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchResults(),
        hybridSearchBloc: mockHybridSearchBloc,
      );

      // Act
      // Don't use pumpAndSettle here: indeterminate progress animations keep scheduling frames.
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - Should show loading indicator
      expect(find.text('Searching community and external sources...'), findsOneWidget);
    });

    testWidgets('displays error state', (WidgetTester tester) async {
      // Arrange
      mockHybridSearchBloc.setState(HybridSearchError('Test error'));
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchResults(),
        hybridSearchBloc: mockHybridSearchBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show error message
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}

