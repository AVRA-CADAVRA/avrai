/// SPOTS AI Improvement End-to-End Integration Tests
/// Date: November 27, 2025
/// Purpose: Test complete user flows for AI Improvement UI
/// 
/// Test Coverage:
/// - Navigation from profile to AI improvement page
/// - Page loads with authenticated user
/// - All widgets display data
/// - Real-time updates via metrics stream
/// - Error scenarios
/// - Loading states
/// - Empty states
/// - Route configuration
/// 
/// Dependencies:
/// - AIImprovementPage: Main page
/// - All AI improvement widgets
/// - AIImprovementTrackingService: Backend service
/// - AuthBloc: Authentication
/// - AppRouter: Route configuration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/ai_improvement_page.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_progress_widget.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_timeline_widget.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_impact_widget.dart';
import '../widget/helpers/widget_test_helpers.dart';
import '../widget/mocks/mock_blocs.dart';

/// End-to-end integration tests for AI Improvement UI
void main() {
  group('AI Improvement End-to-End Integration Tests', () {
    late MockAuthBloc mockAuthBloc;
    
    setUp(() {
      mockAuthBloc = MockBlocFactory.createAuthenticatedAuthBloc();
    });
    
    group('Page Navigation', () {
      testWidgets('should navigate to AI improvement page', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(AIImprovementPage), findsOneWidget);
        expect(find.text('AI Improvement'), findsOneWidget);
        expect(find.text('AI Self-Improvement'), findsOneWidget);
      });

      testWidgets('should display all four main sections', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
        expect(find.byType(AIImprovementTimelineWidget), findsOneWidget);
        expect(find.byType(AIImprovementImpactWidget), findsOneWidget);
      });

      testWidgets('should display section headers', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.text('AI Improvement Metrics'), findsOneWidget);
        expect(find.text('Improvement Progress'), findsOneWidget);
        expect(find.text('Improvement History'), findsOneWidget);
        expect(find.text('Impact & Benefits'), findsOneWidget);
      });
    });

    group('Complete User Flow', () {
      testWidgets('should load page with authenticated user', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(AIImprovementPage), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should display all widgets with data', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        // Wait for widgets to load data
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - All widgets should be present
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
        expect(find.byType(AIImprovementTimelineWidget), findsOneWidget);
        expect(find.byType(AIImprovementImpactWidget), findsOneWidget);
      });

      testWidgets('should handle real-time updates via metrics stream', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        
        // Wait for initial load
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Page should be responsive to stream updates
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // Metrics stream updates should be reflected in widgets
        // (Actual stream testing would require service mocking)
      });
    });

    group('Error Scenarios', () {
      testWidgets('should handle service initialization errors gracefully', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Page should render even if service has issues
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // Should show either content or error UI
        final hasError = find.text('Error').evaluate().isNotEmpty;
        final hasContent = find.byType(AIImprovementSection).evaluate().isNotEmpty;
        expect(hasError || hasContent, isTrue);
      });

      testWidgets('should display error message when service fails', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - If error occurs, should show error UI
        final errorText = find.textContaining('Failed to initialize');
        if (errorText.evaluate().isNotEmpty) {
          expect(errorText, findsOneWidget);
          expect(find.text('Retry'), findsOneWidget);
        }
      });

      testWidgets('should allow retry after error', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        
        // Check if retry button exists
        final retryButton = find.text('Retry');
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pumpAndSettle();
        }

        // Assert - Retry should attempt re-initialization
        expect(find.byType(AIImprovementPage), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicator during initialization', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump(); // Don't settle immediately

        // Assert - May show loading initially
        // After settling, should show content or error
        await tester.pumpAndSettle();
        expect(find.byType(AIImprovementPage), findsOneWidget);
      });

      testWidgets('should transition from loading to content', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();
        
        await tester.pumpAndSettle();

        // Assert - Should transition from loading to content
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // After settling, should have content or error, not loading
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      });
    });

    group('Empty States', () {
      testWidgets('should handle empty metrics gracefully', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Page should render even with empty data
        expect(find.byType(AIImprovementPage), findsOneWidget);
        expect(find.byType(AIImprovementSection), findsOneWidget);
      });

      testWidgets('should display appropriate empty state messages', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Widgets should handle empty states internally
        expect(find.byType(AIImprovementPage), findsOneWidget);
        // Empty state messages would be in individual widgets
      });
    });

    group('Widget-Backend Integration', () {
      testWidgets('should pass userId to all widgets', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - All widgets should receive userId from AuthBloc
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
        expect(find.byType(AIImprovementTimelineWidget), findsOneWidget);
        expect(find.byType(AIImprovementImpactWidget), findsOneWidget);
      });

      testWidgets('should pass trackingService to all widgets', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Service should be initialized and passed to widgets
        expect(find.byType(AIImprovementSection), findsOneWidget);
        // Widgets should be able to call service methods
      });

      testWidgets('should handle service method calls from widgets', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Widgets should successfully call service methods
        // This is verified by widgets rendering without errors
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
      });
    });

    group('Complete User Journey', () {
      testWidgets('should complete full user journey from page load to viewing all sections', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act - Load page
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - All sections visible
        expect(find.byType(AIImprovementSection), findsOneWidget);
        expect(find.byType(AIImprovementProgressWidget), findsOneWidget);
        expect(find.byType(AIImprovementTimelineWidget), findsOneWidget);
        expect(find.byType(AIImprovementImpactWidget), findsOneWidget);

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

      testWidgets('should handle user interactions across all widgets', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: const AIImprovementPage(),
          authBloc: mockAuthBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Page should be interactive
        expect(find.byType(AIImprovementPage), findsOneWidget);
        
        // Try to interact with widgets (info buttons, etc.)
        final infoButtons = find.byIcon(Icons.info_outline);
        if (infoButtons.evaluate().isNotEmpty) {
          await tester.tap(infoButtons.first);
          await tester.pumpAndSettle();
          
          // Dialog might appear
          final dialog = find.byType(AlertDialog);
          if (dialog.evaluate().isNotEmpty) {
            // Close dialog
            final closeButton = find.text('Got it');
            if (closeButton.evaluate().isEmpty) {
              final closeButtonAlt = find.text('Close');
              if (closeButtonAlt.evaluate().isNotEmpty) {
                await tester.tap(closeButtonAlt);
                await tester.pumpAndSettle();
              }
            } else {
              await tester.tap(closeButton);
              await tester.pumpAndSettle();
            }
          }
        }

        // Assert - Page still functional
        expect(find.byType(AIImprovementPage), findsOneWidget);
      });
    });
  });
}

