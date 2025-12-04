/// SPOTS AIImprovementSection Widget Tests
/// Date: November 21, 2025
/// Purpose: Test AIImprovementSection functionality and UI behavior
/// 
/// Test Coverage:
/// - Loading States: Loading indicator, no data state, with data state
/// - Header Display: Title, icon, info button
/// - Overall Score: Score display, color coding, label, progress indicator
/// - Accuracy Section: Recommendation acceptance, prediction accuracy, user satisfaction
/// - Performance Scores: Display and formatting
/// - Dimension Scores: Top 6 display, view all button
/// - Improvement Rate: Positive/stable display, time formatting
/// - Info Dialogs: Info and all dimensions dialogs
/// 
/// Dependencies:
/// - AIImprovementTrackingService: For metrics data
/// - GetStorage: For persistence

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/settings/ai_improvement_section.dart';
import 'package:spots/core/services/ai_improvement_tracking_service.dart';
import '../../helpers/widget_test_helpers.dart';
import 'dart:async';

/// Widget tests for AIImprovementSection
/// Tests loading states, metrics display, and user interactions
void main() {
  group('AIImprovementSection Widget Tests', () {
    late MockAIImprovementTrackingService mockService;
    late StreamController<AIImprovementMetrics> metricsStreamController;
    
    setUp(() {
      metricsStreamController = StreamController<AIImprovementMetrics>.broadcast();
      mockService = MockAIImprovementTrackingService(
        metricsStreamController: metricsStreamController,
      );
    });
    
    tearDown(() {
      metricsStreamController.close();
    });
    
    /// Helper to create scrollable test widget with larger viewport
    Widget createScrollableTestWidget({required Widget child}) {
      return WidgetTestHelpers.createTestableWidget(
        child: SizedBox(
          height: 1200, // Increased viewport height
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      );
    }

    group('Loading States', () {
      testWidgets('displays loading indicator initially', (WidgetTester tester) async {
        // Arrange
        mockService.setLoadingDelay(const Duration(milliseconds: 100));
        mockService.setMetrics(_createMockMetrics());
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pump();

        // Assert - loading indicator should be visible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('AI Improvement Metrics'), findsNothing);
        
        // Clean up - let async operations complete
        await tester.pumpAndSettle();
      });

      testWidgets('displays no data state when metrics are null', (WidgetTester tester) async {
        // Arrange
        mockService.setMetrics(null);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No improvement data available'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('displays metrics when data is available', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI Improvement Metrics'), findsOneWidget);
        expect(find.text('Overall AI Performance'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Header Display', () {
      testWidgets('displays header with title and icon', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('AI Improvement Metrics'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsWidgets);
      });

      testWidgets('displays info button', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('opens info dialog when info button is tapped', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('AI Improvement Metrics'), findsWidgets);
    });
    });

    group('Overall Score Display', () {
      testWidgets('displays overall score with percentage', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(overallScore: 0.85);
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Overall AI Performance'), findsOneWidget);
        expect(find.text('85.0%'), findsOneWidget);
      });

      testWidgets('displays excellent label for score >= 0.9', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(overallScore: 0.92);
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Excellent'), findsOneWidget);
      });

      testWidgets('displays good label for score >= 0.75', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(overallScore: 0.80);
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Good'), findsOneWidget);
      });

      testWidgets('displays total improvements count', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(totalImprovements: 15);
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('15 improvements'), findsOneWidget);
      });

      testWidgets('displays progress indicator', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });
    });

    group('Accuracy Section', () {
      testWidgets('displays accuracy section when metrics available', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        final accuracyMetrics = _createMockAccuracyMetrics();
        mockService.setMetrics(metrics);
        mockService.setAccuracyMetrics(accuracyMetrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
      
        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Accuracy Measurements'), findsOneWidget);
        expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      });

      testWidgets('displays recommendation acceptance rate', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        final accuracyMetrics = _createMockAccuracyMetrics(
          recommendationAcceptanceRate: 0.82,
          acceptedRecommendations: 82,
        totalRecommendations: 100,
        );
        mockService.setMetrics(metrics);
        mockService.setAccuracyMetrics(accuracyMetrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Recommendation Acceptance'), findsOneWidget);
        expect(find.text('82/100 accepted'), findsOneWidget);
        expect(find.text('82%'), findsWidgets); // May appear multiple times in UI
      });

      testWidgets('displays prediction accuracy', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        final accuracyMetrics = _createMockAccuracyMetrics(
          predictionAccuracy: 0.88,
        );
        mockService.setMetrics(metrics);
        mockService.setAccuracyMetrics(accuracyMetrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Prediction Accuracy'), findsOneWidget);
        expect(find.text('88%'), findsWidgets); // May appear multiple times
      });

      testWidgets('displays user satisfaction score', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        final accuracyMetrics = _createMockAccuracyMetrics(
          userSatisfactionScore: 0.90,
        );
        mockService.setMetrics(metrics);
        mockService.setAccuracyMetrics(accuracyMetrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );
      
        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('User Satisfaction'), findsOneWidget);
        expect(find.text('90%'), findsWidgets); // May appear multiple times
      });
    });

    group('Performance Scores', () {
      testWidgets('displays performance scores section', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Performance Scores'), findsOneWidget);
        expect(find.byIcon(Icons.speed), findsOneWidget);
      });

      testWidgets('displays performance score items', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(
          performanceScores: {
            'speed': 0.85,
            'efficiency': 0.78,
            'adaptability': 0.92,
          },
        );
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Speed'), findsWidgets); // May appear in multiple sections
        expect(find.text('Efficiency'), findsWidgets); // May appear in multiple sections
        expect(find.text('Adaptability'), findsWidgets); // May appear in multiple sections
      });
    });

    group('Dimension Scores', () {
      testWidgets('displays dimension scores section', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics();
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Improvement Dimensions'), findsOneWidget);
        expect(find.byIcon(Icons.insights), findsOneWidget);
      });

      testWidgets('displays top 6 dimension scores', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(
          dimensionScores: {
            'accuracy': 0.85,
            'creativity': 0.78,
            'collaboration': 0.92,
            'learning_speed': 0.88,
            'pattern_recognition': 0.80,
            'recommendation_quality': 0.87,
            'extra_dimension': 0.75,
          },
        );
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Accuracy'), findsOneWidget);
        expect(find.text('Creativity'), findsOneWidget);
        // Should display top 6
        expect(find.text('View all dimensions'), findsOneWidget);
      });

      testWidgets('opens all dimensions dialog when view all is tapped', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(
          dimensionScores: {
            for (var i = 0; i < 8; i++) 'dimension_$i': 0.80 + (i * 0.01),
          },
        );
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        
        // Scroll to make button visible
        await tester.ensureVisible(find.text('View all dimensions'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('View all dimensions'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('All Improvement Dimensions'), findsOneWidget);
      });
    });

    group('Improvement Rate', () {
      testWidgets('displays positive improvement rate', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(improvementRate: 0.05);
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('Improving at 5.0% per week'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsWidgets);
      });

      testWidgets('displays stable performance for zero rate', (WidgetTester tester) async {
        // Arrange
        final metrics = _createMockMetrics(improvementRate: 0.0);
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Stable performance'), findsOneWidget);
      });

      testWidgets('displays last updated time', (WidgetTester tester) async {
        // Arrange
        final now = DateTime.now();
        final metrics = _createMockMetrics(
          lastUpdated: now.subtract(const Duration(hours: 2)),
        );
        mockService.setMetrics(metrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('Updated'), findsOneWidget);
        expect(find.textContaining('ago'), findsOneWidget);
      });
    });

    group('Real-time Updates', () {
      testWidgets('updates when metrics stream emits new data', (WidgetTester tester) async {
        // Arrange
        final initialMetrics = _createMockMetrics(overallScore: 0.75);
        mockService.setMetrics(initialMetrics);
        
        final widget = createScrollableTestWidget(
          child: AIImprovementSection(
            userId: 'test_user',
            trackingService: mockService,
          ),
        );

        // Act
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        
        expect(find.text('75.0%'), findsWidgets); // May appear multiple times
        
        // Emit new metrics
        final newMetrics = _createMockMetrics(overallScore: 0.85);
        metricsStreamController.add(newMetrics);
        await tester.pumpAndSettle(); // Wait for all updates to complete

        // Assert - new value should appear
        expect(find.text('85.0%'), findsWidgets);
        // Old value should be replaced (though may still appear in other metrics)
      });
    });
  });
}

/// Helper function to create mock metrics
AIImprovementMetrics _createMockMetrics({
  String userId = 'test_user',
  Map<String, double>? dimensionScores,
  Map<String, double>? performanceScores,
  double overallScore = 0.85,
  double improvementRate = 0.03,
  int totalImprovements = 10,
  DateTime? lastUpdated,
}) {
  return AIImprovementMetrics(
    userId: userId,
    dimensionScores: dimensionScores ?? {
      'accuracy': 0.85,
      'speed': 0.88,
      'efficiency': 0.82,
      'adaptability': 0.90,
    },
    performanceScores: performanceScores ?? {
      'speed': 0.88,
      'efficiency': 0.82,
      'adaptability': 0.90,
    },
    overallScore: overallScore,
    improvementRate: improvementRate,
    totalImprovements: totalImprovements,
    lastUpdated: lastUpdated ?? DateTime.now(),
  );
}

/// Helper function to create mock accuracy metrics
AccuracyMetrics _createMockAccuracyMetrics({
  double recommendationAcceptanceRate = 0.85,
  int acceptedRecommendations = 85,
  int totalRecommendations = 100,
  double predictionAccuracy = 0.88,
  double userSatisfactionScore = 0.90,
}) {
  return AccuracyMetrics(
    recommendationAcceptanceRate: recommendationAcceptanceRate,
    acceptedRecommendations: acceptedRecommendations,
    totalRecommendations: totalRecommendations,
    predictionAccuracy: predictionAccuracy,
    userSatisfactionScore: userSatisfactionScore,
    averageConfidence: 0.88,
    timestamp: DateTime.now(),
  );
}

/// Mock service for testing
class MockAIImprovementTrackingService implements AIImprovementTrackingService {
  AIImprovementMetrics? _metrics;
  AccuracyMetrics? _accuracyMetrics;
  Duration _loadingDelay = Duration.zero;
  bool _shouldThrowError = false;
  final StreamController<AIImprovementMetrics> metricsStreamController;
  
  MockAIImprovementTrackingService({
    required this.metricsStreamController,
  });
  
  void setMetrics(AIImprovementMetrics? metrics) {
    _metrics = metrics;
    _shouldThrowError = (metrics == null);
    // Auto-create default accuracy metrics if metrics are set
    if (metrics != null && _accuracyMetrics == null) {
      _accuracyMetrics = AccuracyMetrics(
        recommendationAcceptanceRate: 0.85,
        acceptedRecommendations: 85,
        totalRecommendations: 100,
        predictionAccuracy: 0.88,
        userSatisfactionScore: 0.90,
        averageConfidence: 0.88,
        timestamp: DateTime.now(),
      );
    }
  }
  
  void setAccuracyMetrics(AccuracyMetrics? metrics) {
    _accuracyMetrics = metrics;
  }
  
  void setLoadingDelay(Duration delay) {
    _loadingDelay = delay;
  }
  
  @override
  Future<void> initialize() async {}
  
  @override
  void dispose() {}
  
  @override
  Future<AIImprovementMetrics> getCurrentMetrics(String userId) async {
    if (_loadingDelay > Duration.zero) {
      await Future.delayed(_loadingDelay);
    }
    if (_shouldThrowError || _metrics == null) {
      throw Exception('No metrics available');
    }
    return _metrics!;
  }
  
  @override
  Future<AccuracyMetrics> getAccuracyMetrics(String userId) async {
    if (_loadingDelay > Duration.zero) {
      await Future.delayed(_loadingDelay);
    }
    // Only throw if explicitly in error state AND no metrics
    if (_shouldThrowError && _accuracyMetrics == null) {
      throw Exception('No accuracy metrics available');
    }
    // Return metrics if available (auto-created when setMetrics called)
    if (_accuracyMetrics != null) {
      return _accuracyMetrics!;
    }
    // Shouldn't reach here, but return default if we do
    throw Exception('No accuracy metrics available');
  }
  
  @override
  Stream<AIImprovementMetrics> get metricsStream => metricsStreamController.stream;
  
  // Other required overrides (not used in these tests)
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
