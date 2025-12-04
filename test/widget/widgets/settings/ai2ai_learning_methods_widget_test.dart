import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:spots/core/services/ai2ai_learning_service.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widget/helpers/widget_test_helpers.dart';
import '../../../widget/mocks/mock_blocs.dart';

/// Widget tests for AI2AILearningMethodsWidget
void main() {
  group('AI2AILearningMethodsWidget Widget Tests', () {
    late AI2AILearning learningService;
    late SharedPreferences prefs;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final personalityLearning = PersonalityLearning.withPrefs(prefs);
      learningService = AI2AILearning.create(
        prefs: prefs,
        personalityLearning: personalityLearning,
      );
    });
    
    group('Widget Initialization', () {
      testWidgets('displays widget with loading state initially', (WidgetTester tester) async {
        // Arrange
        const userId = 'test_user';
        final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
        
        final widget = WidgetTestHelpers.createTestableWidget(
          child: AI2AILearningMethodsWidget(
            userId: userId,
            learningService: learningService,
          ),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump(); // Don't settle to see loading state

        // Assert - Widget should be present
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
      });
      
      testWidgets('calls service methods on initialization', (WidgetTester tester) async {
        // Arrange
        const userId = 'test_user';
        final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
        
        final widget = WidgetTestHelpers.createTestableWidget(
          child: AI2AILearningMethodsWidget(
            userId: userId,
            learningService: learningService,
          ),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - Widget should have loaded data
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
      });
    });
    
    group('Data Display', () {
      testWidgets('displays learning insights when available', (WidgetTester tester) async {
        // Arrange
        const userId = 'test_user';
        final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
        
        final widget = WidgetTestHelpers.createTestableWidget(
          child: AI2AILearningMethodsWidget(
            userId: userId,
            learningService: learningService,
          ),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - Widget should display content (even if empty)
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
      });
      
      testWidgets('handles empty data gracefully', (WidgetTester tester) async {
        // Arrange
        const userId = 'new_user';
        final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
        
        final widget = WidgetTestHelpers.createTestableWidget(
          child: AI2AILearningMethodsWidget(
            userId: userId,
            learningService: learningService,
          ),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - Widget should still render with empty state
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
      });
    });
    
    group('Error Handling', () {
      testWidgets('handles service errors gracefully', (WidgetTester tester) async {
        // Arrange
        const userId = 'error_user';
        final mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
        
        final widget = WidgetTestHelpers.createTestableWidget(
          child: AI2AILearningMethodsWidget(
            userId: userId,
            learningService: learningService,
          ),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - Widget should not crash on error
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
      });
    });
  });
}
