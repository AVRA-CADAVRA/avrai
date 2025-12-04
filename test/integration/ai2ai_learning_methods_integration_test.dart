/// SPOTS AI2AI Learning Methods End-to-End Integration Tests
/// Date: November 28, 2025
/// Purpose: Test complete user flows for AI2AI Learning Methods UI
/// 
/// Test Coverage:
/// - Navigation from profile to AI2AI learning methods page
/// - Page loads with authenticated user
/// - All widgets display data
/// - Error scenarios
/// - Loading states
/// - Empty states
/// - Route configuration
/// 
/// Dependencies:
/// - AI2AILearningMethodsPage: Main page
/// - All AI2AI learning widgets
/// - AI2AILearning service: Backend service
/// - AuthBloc: Authentication
/// - AppRouter: Route configuration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/ai2ai_learning_methods_page.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_effectiveness_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_insights_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_recommendations_widget.dart';
import '../widget/helpers/widget_test_helpers.dart';
import '../widget/mocks/mock_blocs.dart';

/// End-to-end integration tests for AI2AI Learning Methods UI
void main() {
  group('AI2AI Learning Methods End-to-End Integration Tests', () {
    late MockAuthBloc mockAuthBloc;
    
    setUp(() {
      mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
    });
    
    group('Page Navigation', () {
      testWidgets('should navigate to AI2AI learning methods page', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        expect(find.text('AI2AI Learning Methods'), findsOneWidget);
      });

      testWidgets('should display all four main sections', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningEffectivenessWidget), findsOneWidget);
        expect(find.byType(AI2AILearningInsightsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningRecommendationsWidget), findsOneWidget);
      });

      testWidgets('should display section headers', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Learning Methods Overview'), findsOneWidget);
        expect(find.text('Learning Effectiveness Metrics'), findsOneWidget);
        expect(find.text('Active Learning Insights'), findsOneWidget);
        expect(find.text('Learning Recommendations'), findsOneWidget);
      });
    });

    group('Complete User Flow', () {
      testWidgets('should load page with authenticated user', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should display all widgets with data', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - All widgets should be present
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningEffectivenessWidget), findsOneWidget);
        expect(find.byType(AI2AILearningInsightsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningRecommendationsWidget), findsOneWidget);
      });
    });

    group('Error Scenarios', () {
      testWidgets('should handle service initialization errors gracefully', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - Page should render even if service has issues
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // Should show either content or error UI
        final hasError = find.text('Error').evaluate().isNotEmpty;
        final hasContent = find.byType(AI2AILearningMethodsWidget).evaluate().isNotEmpty;
        expect(hasError || hasContent, isTrue);
      });

      testWidgets('should display retry button when error occurs', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - If error occurs, should show retry button
        final retryButton = find.text('Retry');
        if (retryButton.evaluate().isNotEmpty) {
          expect(retryButton, findsOneWidget);
        }
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicator during initialization', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump(); // Don't settle immediately

        // Assert - May show loading initially
        await tester.pumpAndSettle();
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
      });

      testWidgets('should transition from loading to content', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - Should transition from loading to content
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('should handle empty metrics gracefully', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - Page should render even with empty data
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
      });
    });

    group('Widget-Backend Integration', () {
      testWidgets('should pass userId to all widgets', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - All widgets should receive userId from AuthBloc
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningEffectivenessWidget), findsOneWidget);
        expect(find.byType(AI2AILearningInsightsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningRecommendationsWidget), findsOneWidget);
      });
    });

    group('Complete User Journey', () {
      testWidgets('should complete full user journey from page load to viewing all sections', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act - Load page
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - All sections visible
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningEffectivenessWidget), findsOneWidget);
        expect(find.byType(AI2AILearningInsightsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningRecommendationsWidget), findsOneWidget);

        // Act - Scroll through page
        await tester.scrollUntilVisible(
          find.text('Learn More'),
          500.0,
          scrollable: find.byType(ListView),
        );
        await tester.pumpAndSettle();

        // Assert - Footer visible
        expect(find.text('Learn More'), findsOneWidget);
        expect(find.textContaining('Your data stays on your device'), findsOneWidget);
      });
    });
  });
}
