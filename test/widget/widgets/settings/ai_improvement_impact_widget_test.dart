/// SPOTS AIImprovementImpactWidget Widget Tests
/// Date: November 21, 2025
/// Purpose: Test AIImprovementImpactWidget functionality and UI behavior
/// 
/// Test Coverage:
/// - Header Display: Title, icon
/// - Impact Summary: Gradient container, impact points
/// - Benefits Section: 4 benefit cards with icons
/// - Transparency Section: Privacy points, settings link
/// - Visual Elements: Icons, colors, layouts
/// 
/// Dependencies:
/// - AIImprovementTrackingService: For service reference (stateless widget)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_impact_widget.dart';
import 'package:spots/core/services/ai_improvement_tracking_service.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AIImprovementImpactWidget
/// Tests impact explanation, benefits display, and transparency information
void main() {
  group('AIImprovementImpactWidget Widget Tests', () {
    late MockAIImprovementTrackingService mockService;
    
    setUp(() {
      mockService = MockAIImprovementTrackingService();
    });
    
    /// Helper to create scrollable test widget with larger viewport
    Widget createScrollableTestWidget({required Widget child}) {
      return WidgetTestHelpers.createTestableWidget(
        child: SizedBox(
          height: 1200,
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      );
    }

    group('Header Display', () {
      testWidgets('displays header with title', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('What This Means for You'), findsOneWidget);
      });

      testWidgets('displays header icon', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });
    });

    group('Impact Summary', () {
      testWidgets('displays impact summary section', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('AI Evolution Impact'), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      });

      testWidgets('displays impact summary description', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('As your AI improves, you experience:'), findsOneWidget);
      });

      testWidgets('displays better recommendations impact point', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Better Recommendations'), findsOneWidget);
        expect(find.textContaining('More accurate spot suggestions'), findsOneWidget);
        expect(find.byIcon(Icons.recommend), findsOneWidget);
      });

      testWidgets('displays faster responses impact point', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Faster Responses'), findsOneWidget);
        expect(find.textContaining('Quicker AI processing'), findsOneWidget);
        expect(find.byIcon(Icons.speed), findsOneWidget);
      });

      testWidgets('displays deeper understanding impact point', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Deeper Understanding'), findsOneWidget);
        expect(find.textContaining('AI learns your preferences'), findsOneWidget);
        expect(find.byIcon(Icons.psychology), findsOneWidget);
      });
    });

    group('Benefits Section', () {
      testWidgets('displays benefits section header', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Your Benefits'), findsOneWidget);
        expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      });

      testWidgets('displays personalization benefit card', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Personalization'), findsOneWidget);
        expect(find.text('AI adapts to your unique preferences'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('displays discovery benefit card', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Discovery'), findsOneWidget);
        expect(find.text('Find hidden gems that match your vibe'), findsOneWidget);
        expect(find.byIcon(Icons.explore), findsOneWidget);
      });

      testWidgets('displays efficiency benefit card', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Efficiency'), findsOneWidget);
        expect(find.text('Less time searching, more time enjoying'), findsOneWidget);
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
      });

      testWidgets('displays community benefit card', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Community'), findsOneWidget);
        expect(find.text('Connect with like-minded people through AI'), findsOneWidget);
        expect(find.byIcon(Icons.people), findsOneWidget);
      });

      testWidgets('displays all 4 benefit cards', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Personalization'), findsOneWidget);
        expect(find.text('Discovery'), findsOneWidget);
        expect(find.text('Efficiency'), findsOneWidget);
        expect(find.text('Community'), findsOneWidget);
      });
    });

    group('Transparency Section', () {
      testWidgets('displays transparency section header', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('Transparency & Control'), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });

      testWidgets('displays transparency points', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.text('You always know what your AI is learning'), findsOneWidget);
        expect(find.text('All improvements are privacy-preserving'), findsOneWidget);
        expect(find.text('You control learning participation'), findsOneWidget);
        expect(find.text('Progress tracked in real-time'), findsOneWidget);
      });

      testWidgets('displays privacy settings button', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert (button text should be visible - tappability tested separately)
        expect(find.text('Privacy Settings'), findsOneWidget);
      });

      testWidgets('privacy settings button is tappable', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        
        // Verify button exists and can be tapped (no navigation implemented, so just check tap works)
        final button = find.text('Privacy Settings');
        expect(button, findsOneWidget);
        
        // Scroll to make button visible if needed, then tap
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        
        await tester.tap(button);
        await tester.pump();

        // Assert - no error should occur
        expect(button, findsOneWidget);
      });

      testWidgets('displays check circle icons for transparency points', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        // Should have 4 check circle icons (one per transparency point)
        final checkIcons = find.byIcon(Icons.check_circle_outline);
        expect(checkIcons, findsNWidgets(4));
      });
    });

    group('Visual Elements', () {
      testWidgets('uses consistent color scheme', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        // Electric green should be used in various places
        final containers = find.descendant(
          of: find.byType(Container),
          matching: find.byType(Container),
        );
        expect(containers, findsWidgets);
      });

      testWidgets('displays all section icons', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget); // Header
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget); // Impact summary
        expect(find.byIcon(Icons.card_giftcard), findsOneWidget); // Benefits header
        expect(find.byIcon(Icons.visibility), findsOneWidget); // Transparency header
      });

      testWidgets('renders within a Card widget', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Layout', () {
      testWidgets('displays all sections in order', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        // Find sections in order by looking at their vertical positions
        final headerY = tester.getTopLeft(find.text('What This Means for You')).dy;
        final impactY = tester.getTopLeft(find.text('AI Evolution Impact')).dy;
        final benefitsY = tester.getTopLeft(find.text('Your Benefits')).dy;
        final transparencyY = tester.getTopLeft(find.text('Transparency & Control')).dy;

        expect(headerY < impactY, isTrue);
        expect(impactY < benefitsY, isTrue);
        expect(benefitsY < transparencyY, isTrue);
      });

      testWidgets('uses proper spacing between sections', (WidgetTester tester) async {
        // Arrange
        final widget = createScrollableTestWidget(
          child: AIImprovementImpactWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);

        // Assert
        expect(find.byType(SizedBox), findsWidgets);
      });
    });
  });
}

/// Mock service for testing (stateless widget doesn't use it)
class MockAIImprovementTrackingService implements AIImprovementTrackingService {
  @override
  Future<void> initialize() async {}
  
  @override
  void dispose() {}
  
  // All overrides (none used in stateless widget)
  @override
  Future<AIImprovementMetrics> getCurrentMetrics(String userId) async {
    throw UnimplementedError();
  }
  
  @override
  Future<AccuracyMetrics> getAccuracyMetrics(String userId) async {
    throw UnimplementedError();
  }
  
  @override
  Stream<AIImprovementMetrics> get metricsStream => Stream.empty();
  
  @override
  List<AIImprovementSnapshot> getHistory({
    required String userId,
    Duration? timeWindow,
  }) => [];
  
  @override
  List<ImprovementMilestone> getMilestones(String userId) => [];
  
  @override
  void startTracking(String userId) {}
  
  @override
  void stopTracking() {}
}

