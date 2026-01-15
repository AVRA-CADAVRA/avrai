import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_suggestions_widget.dart';
import 'package:avrai/core/services/reservation_recommendation_service.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/widget_test_helpers.dart' as helpers;

class MockReservationRecommendationService extends Mock
    implements ReservationRecommendationService {}

void main() {
  group('ReservationSuggestionsWidget', () {
    late MockReservationRecommendationService mockRecommendationService;

    setUp(() {
      mockRecommendationService = MockReservationRecommendationService();
    });

    testWidgets('should display loading indicator initially', (tester) async {
      when(() => mockRecommendationService.getAIPoweredReservations(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: ReservationSuggestionsWidget(
          userId: 'test-user-id',
          recommendationService: mockRecommendationService,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('AI Suggestions for You'), findsNothing);

      // Wait for async operation
      await tester.pumpAndSettle();

      // After loading, should show empty state (no suggestions)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display suggestions when loaded', (tester) async {
      final suggestions = [
        ReservationRecommendation(
          targetId: 'target-1',
          type: ReservationType.event,
          title: 'Test Event 1',
          description: 'Test description 1',
          compatibility: 0.85,
          recommendedTime: DateTime.now().add(const Duration(days: 1)),
          aiReason: 'Based on your preferences',
        ),
        ReservationRecommendation(
          targetId: 'target-2',
          type: ReservationType.spot,
          title: 'Test Spot 1',
          description: 'Test description 2',
          compatibility: 0.92,
          recommendedTime: DateTime.now().add(const Duration(days: 2)),
          aiReason: 'Matches your past reservations',
        ),
      ];

      when(() => mockRecommendationService.getAIPoweredReservations(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => suggestions);

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: ReservationSuggestionsWidget(
          userId: 'test-user-id',
          recommendationService: mockRecommendationService,
          maxSuggestions: 5,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Should display header
      expect(find.text('AI Suggestions for You'), findsOneWidget);

      // Should display both suggestions
      expect(find.text('Test Event 1'), findsOneWidget);
      expect(find.text('Test Spot 1'), findsOneWidget);

      // Should display descriptions
      expect(find.text('Test description 1'), findsOneWidget);
      expect(find.text('Test description 2'), findsOneWidget);

      // Should display compatibility scores
      expect(find.text('85% match'), findsOneWidget);
      expect(find.text('92% match'), findsOneWidget);

      // Should display AI reasons
      expect(find.text('Based on your preferences'), findsOneWidget);
      expect(find.text('Matches your past reservations'), findsOneWidget);
    });

    testWidgets('should display error message on failure', (tester) async {
      when(() => mockRecommendationService.getAIPoweredReservations(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('Failed to load'));

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: ReservationSuggestionsWidget(
          userId: 'test-user-id',
          recommendationService: mockRecommendationService,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.pumpAndSettle();

      // Should display error
      expect(find.textContaining('Failed to load suggestions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should call onSuggestionSelected when suggestion tapped',
        (tester) async {
      ReservationRecommendation? selectedSuggestion;
      final suggestion = ReservationRecommendation(
        targetId: 'target-1',
        type: ReservationType.event,
        title: 'Test Event',
        compatibility: 0.85,
      );

      when(() => mockRecommendationService.getAIPoweredReservations(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [suggestion]);

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: ReservationSuggestionsWidget(
          userId: 'test-user-id',
          recommendationService: mockRecommendationService,
          onSuggestionSelected: (suggestion) {
            selectedSuggestion = suggestion;
          },
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Tap on suggestion card
      await tester.tap(find.text('Test Event'));
      await tester.pumpAndSettle();

      // Should call callback
      expect(selectedSuggestion, isNotNull);
      expect(selectedSuggestion!.targetId, equals('target-1'));
    });

    testWidgets('should format recommended time correctly', (tester) async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final suggestion = ReservationRecommendation(
        targetId: 'target-1',
        type: ReservationType.event,
        title: 'Test Event',
        compatibility: 0.85,
        recommendedTime: tomorrow,
      );

      when(() => mockRecommendationService.getAIPoweredReservations(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [suggestion]);

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: ReservationSuggestionsWidget(
          userId: 'test-user-id',
          recommendationService: mockRecommendationService,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.pumpAndSettle();

      // Should display formatted time
      expect(find.textContaining('Tomorrow'), findsOneWidget);
    });

    testWidgets('should limit suggestions to maxSuggestions', (tester) async {
      final suggestions = List.generate(
        10,
        (index) => ReservationRecommendation(
          targetId: 'target-$index',
          type: ReservationType.event,
          title: 'Test Event $index',
          compatibility: 0.8,
        ),
      );

      when(() => mockRecommendationService.getAIPoweredReservations(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => suggestions);

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: ReservationSuggestionsWidget(
          userId: 'test-user-id',
          recommendationService: mockRecommendationService,
          maxSuggestions: 3,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Should only display 3 suggestions (service should limit, but verify UI)
      // Note: The service limits, so we verify the service was called with correct limit
      verify(() => mockRecommendationService.getAIPoweredReservations(
            userId: 'test-user-id',
            limit: 3,
          )).called(1);
    });

    testWidgets('should handle suggestions without optional fields',
        (tester) async {
      final suggestion = ReservationRecommendation(
        targetId: 'target-1',
        type: ReservationType.event,
        title: 'Test Event',
        compatibility: 0.85,
        // No description, recommendedTime, or aiReason
      );

      when(() => mockRecommendationService.getAIPoweredReservations(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [suggestion]);

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: ReservationSuggestionsWidget(
          userId: 'test-user-id',
          recommendationService: mockRecommendationService,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      await tester.pumpAndSettle();

      // Should still display the suggestion
      expect(find.text('Test Event'), findsOneWidget);
      expect(find.text('85% match'), findsOneWidget);

      // Should not display optional fields
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
      expect(find.byIcon(Icons.access_time), findsNothing);
    });
  });
}
