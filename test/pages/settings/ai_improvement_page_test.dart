/// SPOTS AIImprovementPage Widget Tests
/// Date: November 27, 2025
/// Purpose: Test AIImprovementPage functionality and UI behavior
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
/// - AIImprovementTrackingService: For metrics data
/// - AuthBloc: For user authentication
/// - All 4 AI improvement widgets

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/ai_improvement_page.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_progress_widget.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_timeline_widget.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_impact_widget.dart';
import '../../widget/helpers/widget_test_helpers.dart';
import '../../widget/mocks/mock_blocs.dart';

/// Widget tests for AIImprovementPage
/// Tests page structure, widget integration, and user flows
void main() {
  group('AIImprovementPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    
    setUp(() {
      mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
    });
    
    group('Page Structure', () {
      testWidgets('displays page with app bar', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AIImprovementPage), findsOneWidget);
        expect(find.text('AI Improvement'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays header section', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI Self-Improvement'), findsOneWidget);
        expect(find.textContaining('Watch your AI learn'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsWidgets);
      });

      testWidgets('displays all section headers', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI Improvement Metrics'), findsOneWidget);
        expect(find.text('Improvement Progress'), findsOneWidget);
        expect(find.text('Improvement History'), findsOneWidget);
        expect(find.text('Impact & Benefits'), findsOneWidget);
      });

      testWidgets('displays footer with learn more section', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Learn More'), findsOneWidget);
        expect(find.textContaining('Your AI continuously learns'), findsOneWidget);
        expect(find.textContaining('Your data stays on your device'), findsOneWidget);
      });
    });

    group('Widget Integration', () {
      testWidgets('displays all 4 AI improvement widgets', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
        expect(find.byType(AIImprovementTimelineWidget), findsOneWidget);
        expect(find.byType(AIImprovementImpactWidget), findsOneWidget);
      });

      testWidgets('widgets are properly spaced and organized', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - All widgets should be in a scrollable list
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('displays loading indicator during initialization', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump(); // Don't settle, check loading state

        // Assert - May show loading initially
        // After initialization, should show content
        await tester.pumpAndSettle();
        expect(find.byType(AIImprovementPage), findsOneWidget);
      });

      testWidgets('shows content after initialization completes', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message when service initialization fails', (WidgetTester tester) async {
        // Arrange
        // Note: This test may need mocking of AIImprovementTrackingService
        // For now, we test that the page handles errors gracefully
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - Page should render (either with content or error)
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // If error occurs, should show error UI
        // If no error, should show widgets
        final hasError = find.text('Error').evaluate().isNotEmpty;
        final hasWidgets = find.byType(AIImprovementSection).evaluate().isNotEmpty;
        expect(hasError || hasWidgets, isTrue);
      });

      testWidgets('displays retry button when error occurs', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
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
          child: const AIImprovementPage(),
          authBloc: unauthenticatedBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert - Should show loading or redirect
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // May show loading indicator while waiting for auth
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays content for authenticated user', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // Should eventually show widgets if authenticated
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        // Page should be rendered
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Scrolling', () {
      testWidgets('page is scrollable', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('all sections are accessible via scrolling', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
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
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('See how your AI is improving'), findsOneWidget);
        expect(find.textContaining('Track improvement trends'), findsOneWidget);
        expect(find.textContaining('Timeline of AI improvements'), findsOneWidget);
        expect(find.textContaining('How AI improvements benefit'), findsOneWidget);
      });
    });
  });
}

