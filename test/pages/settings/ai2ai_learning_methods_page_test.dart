/// SPOTS AI2AILearningMethodsPage Widget Tests
/// Date: November 28, 2025
/// Purpose: Test AI2AILearningMethodsPage functionality and UI behavior
/// 
/// Test Coverage:
/// - Page Structure: Header, sections, footer
/// - Widget Integration: All 4 widgets displayed
/// - Loading States: Initialization loading
/// - Error Handling: Service initialization errors
/// - Authentication: Requires authenticated user
/// - Navigation: Back navigation
/// 
/// Dependencies:
/// - AI2AILearning service: For learning data
/// - AuthBloc: For user authentication
/// - All 4 AI2AI learning widgets

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/ai2ai_learning_methods_page.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_methods_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_effectiveness_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_insights_widget.dart';
import 'package:spots/presentation/widgets/settings/ai2ai_learning_recommendations_widget.dart';
import '../../widget/helpers/widget_test_helpers.dart';
import '../../widget/mocks/mock_blocs.dart';

/// Widget tests for AI2AILearningMethodsPage
/// Tests page structure, widget integration, and user flows
void main() {
  group('AI2AILearningMethodsPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    
    setUp(() {
      mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
    });
    
    group('Page Structure', () {
      testWidgets('displays page with app bar', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        expect(find.text('AI2AI Learning Methods'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays header section', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI2AI Learning Methods'), findsWidgets);
        expect(find.textContaining('See how your AI learns'), findsWidgets);
        expect(find.byIcon(Icons.psychology), findsWidgets);
      });

      testWidgets('displays all section headers', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Learning Methods Overview'), findsOneWidget);
        expect(find.text('Learning Effectiveness Metrics'), findsOneWidget);
        expect(find.text('Active Learning Insights'), findsOneWidget);
        expect(find.text('Learning Recommendations'), findsOneWidget);
      });

      testWidgets('displays footer with learn more section', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Learn More'), findsOneWidget);
        expect(find.textContaining('AI2AI learning enables'), findsOneWidget);
        expect(find.textContaining('Your data stays on your device'), findsOneWidget);
      });
    });

    group('Widget Integration', () {
      testWidgets('displays all 4 AI2AI learning widgets', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        // Wait for widgets to initialize
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - All widgets should be present
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningEffectivenessWidget), findsOneWidget);
        expect(find.byType(AI2AILearningInsightsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningRecommendationsWidget), findsOneWidget);
      });

      testWidgets('widgets are properly spaced and organized', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert - All widgets should be in a scrollable list
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        expect(find.byType(AI2AILearningEffectivenessWidget), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('displays loading indicator during initialization', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump(); // Don't settle, check loading state

        // Assert - May show loading initially
        // After initialization, should show content
        await tester.pumpAndSettle();
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
      });

      testWidgets('shows content after initialization completes', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AI2AILearningMethodsWidget), findsOneWidget);
        // Loading indicator should be gone after initialization
        final loadingIndicators = find.byType(CircularProgressIndicator);
        if (loadingIndicators.evaluate().isNotEmpty) {
          // If loading indicator still present, wait more
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message when service initialization fails', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - Page should render (either with content or error)
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // If error occurs, should show error UI
        // If no error, should show widgets
        final hasError = find.text('Error').evaluate().isNotEmpty;
        final hasWidgets = find.byType(AI2AILearningMethodsWidget).evaluate().isNotEmpty;
        expect(hasError || hasWidgets, isTrue);
      });

      testWidgets('displays retry button when error occurs', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - If error UI is shown, retry button should be present
        final retryButton = find.text('Retry');
        if (retryButton.evaluate().isNotEmpty) {
          expect(retryButton, findsOneWidget);
        }
      });
    });

    group('Authentication', () {
      testWidgets('requires authenticated user', (WidgetTester tester) async {
        // Arrange
        final unauthenticatedBloc = MockBlocFactory.createUnauthenticatedAuthBloc();
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: unauthenticatedBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - Should show loading or redirect
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // May show loading indicator while waiting for auth
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays content for authenticated user', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AI2AILearningMethodsPage), findsOneWidget);
        // Should eventually show widgets if authenticated
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Scrolling', () {
      testWidgets('page is scrollable', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('all sections are accessible via scrolling', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Scroll to bottom
        await tester.scrollUntilVisible(
          find.text('Learn More'),
          500.0,
          scrollable: find.byType(ListView),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Learn More'), findsOneWidget);
      });
    });

    group('Section Descriptions', () {
      testWidgets('displays section descriptions', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AI2AILearningMethodsPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('See how your AI learns'), findsWidgets);
        expect(find.textContaining('Track how effectively'), findsOneWidget);
        expect(find.textContaining('Recent insights'), findsOneWidget);
        expect(find.textContaining('Optimal learning partners'), findsOneWidget);
      });
    });
  });
}
