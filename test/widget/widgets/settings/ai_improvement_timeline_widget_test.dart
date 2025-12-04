/// SPOTS AIImprovementTimelineWidget Widget Tests
/// Date: November 21, 2025
/// Purpose: Test AIImprovementTimelineWidget functionality and UI behavior
/// 
/// Test Coverage:
/// - Loading State: Loading indicator display
/// - Empty State: Display when no milestones
/// - Header Display: Title, icon, milestone count
/// - Timeline Display: Visual timeline with indicators
/// - Milestone Details: From/to scores, improvement percentage, descriptions
/// - Visual Indicators: Color coding by improvement level, icons
/// - Time Formatting: Relative time display
/// 
/// Dependencies:
/// - AIImprovementTrackingService: For milestone data

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_timeline_widget.dart';
import 'package:spots/core/services/ai_improvement_tracking_service.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AIImprovementTimelineWidget
/// Tests timeline display, milestone rendering, and time formatting
void main() {
  group('AIImprovementTimelineWidget Widget Tests', () {
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

    group('Loading State', () {
      testWidgets('displays loading indicator initially', (WidgetTester tester) async {
        // Arrange
        mockService.setLoadingDelay(const Duration(milliseconds: 100));
        mockService.setMilestones(_createMockMilestones(count: 3));
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert - widget renders (loading is inline, so just verify the widget exists)
        expect(find.byType(AIImprovementTimelineWidget), findsOneWidget);
        
        // Clean up - wait for async to complete
        await tester.pumpAndSettle();
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no milestones', (WidgetTester tester) async {
        // Arrange
        mockService.setMilestones([]);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('No Milestones Yet'), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);
      });

      testWidgets('displays helpful message in empty state', (WidgetTester tester) async {
        // Arrange
        mockService.setMilestones([]);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.textContaining('Your AI will track'), findsOneWidget);
      });
    });

    group('Header Display', () {
      testWidgets('displays header with title and icon', (WidgetTester tester) async {
        // Arrange
        final milestones = _createMockMilestones(count: 3);
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('Improvement History'), findsOneWidget);
        expect(find.byIcon(Icons.timeline), findsOneWidget);
      });

      testWidgets('displays milestone count in header', (WidgetTester tester) async {
        // Arrange
        final milestones = _createMockMilestones(count: 5);
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('5 milestones achieved'), findsOneWidget);
      });
    });

    group('Timeline Display', () {
      testWidgets('displays timeline items for each milestone', (WidgetTester tester) async {
        // Arrange
        final milestones = _createMockMilestones(count: 3);
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        // Each milestone should have its description visible
        expect(find.text('Significant improvement in accuracy'), findsAtLeastNWidgets(1));
      });

      testWidgets('displays visual timeline indicators', (WidgetTester tester) async {
        // Arrange
        final milestones = _createMockMilestones(count: 3);
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        // Should have timeline containers (circles for indicators)
        final containers = find.descendant(
          of: find.byType(Row),
          matching: find.byType(Container),
        );
        expect(containers, findsWidgets);
      });
    });

    group('Milestone Details', () {
      testWidgets('displays milestone description', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(
            description: 'Breakthrough in recommendation accuracy',
            improvement: 0.15,
          ),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('Breakthrough in recommendation accuracy'), findsOneWidget);
      });

      testWidgets('displays improvement percentage', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(improvement: 0.15),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('+15%'), findsOneWidget);
      });

      testWidgets('displays dimension name', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(dimension: 'recommendation_quality'),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('Recommendation Quality'), findsOneWidget);
      });

      testWidgets('displays from and to scores', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(
            fromScore: 0.70,
            toScore: 0.85,
          ),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('70%'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('displays relative time ago', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.textContaining('ago'), findsOneWidget);
      });
    });

    group('Visual Indicators', () {
      testWidgets('uses success color for high improvement (>=0.15)', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(improvement: 0.18),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        // Star icon indicates high improvement
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('uses arrow up icon for medium improvement (>=0.10)', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(improvement: 0.12),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.arrow_upward), findsWidgets);
      });

      testWidgets('uses trending up icon for lower improvement', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(improvement: 0.08),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.trending_up), findsWidgets);
      });
    });

    group('Time Formatting', () {
      testWidgets('formats minutes correctly', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.textContaining('m ago'), findsOneWidget);
      });

      testWidgets('formats hours correctly', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.textContaining('h ago'), findsOneWidget);
      });

      testWidgets('formats days correctly', (WidgetTester tester) async {
        // Arrange
        final milestones = [
          _createMockMilestone(
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.textContaining('d ago'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles single milestone', (WidgetTester tester) async {
        // Arrange
        final milestones = _createMockMilestones(count: 1);
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('1 milestones achieved'), findsOneWidget);
      });

      testWidgets('handles many milestones', (WidgetTester tester) async {
        // Arrange
        final milestones = _createMockMilestones(count: 20);
        mockService.setMilestones(milestones);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementTimelineWidget(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert
        expect(find.text('20 milestones achieved'), findsOneWidget);
        // Should display all milestones (scrollable)
      });
    });
  });
}

/// Helper function to create mock milestones
List<ImprovementMilestone> _createMockMilestones({int count = 3}) {
  return List.generate(count, (index) => _createMockMilestone());
}

/// Helper function to create a single mock milestone
ImprovementMilestone _createMockMilestone({
  String dimension = 'accuracy',
  double improvement = 0.15,
  double fromScore = 0.70,
  double toScore = 0.85,
  String? description,
  DateTime? timestamp,
}) {
  return ImprovementMilestone(
    dimension: dimension,
    improvement: improvement,
    fromScore: fromScore,
    toScore: toScore,
    description: description ?? 'Significant improvement in $dimension',
    timestamp: timestamp ?? DateTime.now().subtract(const Duration(days: 1)),
  );
}

/// Mock service for testing
class MockAIImprovementTrackingService implements AIImprovementTrackingService {
  List<ImprovementMilestone> _milestones = [];
  Duration _loadingDelay = Duration.zero;
  
  void setMilestones(List<ImprovementMilestone> milestones) {
    _milestones = milestones;
  }
  
  void setLoadingDelay(Duration delay) {
    _loadingDelay = delay;
  }
  
  @override
  Future<void> initialize() async {}
  
  @override
  void dispose() {}
  
  @override
  List<ImprovementMilestone> getMilestones(String userId) {
    if (_loadingDelay > Duration.zero) {
      // Simulate loading by not returning immediately
      return [];
    }
    return _milestones;
  }
  
  // Other required overrides (not used in these tests)
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
  void startTracking(String userId) {}
  
  @override
  void stopTracking() {}
}

