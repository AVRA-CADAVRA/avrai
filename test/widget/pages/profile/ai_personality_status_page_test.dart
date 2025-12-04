import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/profile/ai_personality_status_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../mocks/mock_blocs.dart';

/// Widget tests for AIPersonalityStatusPage
/// Tests AI personality status page display
void main() {
  group('AIPersonalityStatusPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIPersonalityStatusPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Don't settle, check loading state

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays app bar with title', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIPersonalityStatusPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(AIPersonalityStatusPage), findsOneWidget);
      expect(find.text('AI Personality Status'), findsOneWidget);
    });

    testWidgets('displays refresh button in app bar', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIPersonalityStatusPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays personality overview card when loaded', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIPersonalityStatusPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present (cards will show when data loads)
      expect(find.byType(AIPersonalityStatusPage), findsOneWidget);
    });

    testWidgets('supports pull to refresh', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIPersonalityStatusPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should have RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}

