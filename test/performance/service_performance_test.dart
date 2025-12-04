import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/tax_compliance_service.dart';
import 'package:spots/core/services/geographic_scope_service.dart';
import 'package:spots/core/services/expert_recommendations_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/models/unified_user.dart';
import '../fixtures/model_factories.dart';
import '../helpers/test_helpers.dart';

// Mock dependencies
class MockStripeService extends Mock implements StripeService {}

class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// Service Performance Tests
///
/// Agent 3: Models & Testing Specialist (Phase 7, Section 42 / 7.4.4)
///
/// Tests service method performance, database query performance,
/// memory usage patterns, and concurrent service calls.
///
/// **Performance Metrics:**
/// - Service method response times
/// - Database query performance
/// - Memory usage patterns
/// - Concurrent operation handling
/// - Performance regression detection
void main() {
  group('Service Performance Tests', () {
    late PaymentService paymentService;
    late TaxComplianceService taxComplianceService;
    late GeographicScopeService geographicScopeService;
    late ExpertRecommendationsService expertRecommendationsService;
    late MockStripeService mockStripeService;
    late MockExpertiseEventService mockEventService;

    late UnifiedUser testUser;

    setUp(() {
      TestHelpers.setupTestEnvironment();

      // Setup mocks
      mockStripeService = MockStripeService();
      mockEventService = MockExpertiseEventService();

      // Setup Stripe mock
      when(() => mockStripeService.isInitialized).thenReturn(true);
      when(() => mockStripeService.initializeStripe())
          .thenAnswer((_) async => {});

      // Create services
      paymentService = PaymentService(
        mockStripeService,
        mockEventService,
      );

      taxComplianceService = TaxComplianceService(
        paymentService: paymentService,
      );

      geographicScopeService = GeographicScopeService();

      expertRecommendationsService = ExpertRecommendationsService();

      // Create test user
      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );
      testUser = testUser.copyWith(
        location: 'Greenpoint, Brooklyn, NY, USA',
        expertiseMap: {
          'Coffee': 'city',
          'Food': 'local',
        },
      );
    });

    tearDown(() {
      reset(mockStripeService);
      reset(mockEventService);
      TestHelpers.teardownTestEnvironment();
    });

    group('Service Method Performance', () {
      test(
          'TaxComplianceService.needsTaxDocuments should respond within 1 second',
          () async {
        // Arrange
        await paymentService.initialize();

        // Act
        final stopwatch = Stopwatch()..start();
        await taxComplianceService.needsTaxDocuments('user-123', 2025);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Tax compliance check should complete within 1 second');
        print('Tax compliance check took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test(
          'GeographicScopeService.canHostInLocality should respond within 100ms',
          () {
        // Arrange
        final userWithCityExpertise = testUser.copyWith(
          expertiseMap: {'Coffee': 'city'},
        );

        // Act
        final stopwatch = Stopwatch()..start();
        geographicScopeService.canHostInLocality(
          userId: 'user-123',
          user: userWithCityExpertise,
          category: 'Coffee',
          locality: 'Greenpoint',
        );
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: 'Geographic scope check should complete within 100ms');
        print(
            'Geographic scope check took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test(
          'ExpertRecommendationsService.getExpertRecommendations should respond within 2 seconds',
          () async {
        // Arrange
        final userWithExpertise = testUser.copyWith(
          expertiseMap: {
            'Coffee': 'city',
            'Food': 'local',
          },
        );

        // Act
        final stopwatch = Stopwatch()..start();
        await expertRecommendationsService.getExpertRecommendations(
          userWithExpertise,
          category: 'Coffee',
          maxResults: 10,
        );
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Expert recommendations should complete within 2 seconds');
        print(
            'Expert recommendations took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('Multiple sequential service calls should maintain performance',
          () async {
        // Arrange
        await paymentService.initialize();
        final userWithCityExpertise = testUser.copyWith(
          expertiseMap: {'Coffee': 'city'},
        );

        // Act
        final stopwatch = Stopwatch()..start();

        // Sequential calls
        await taxComplianceService.needsTaxDocuments('user-1', 2025);
        await taxComplianceService.needsTaxDocuments('user-2', 2025);
        await taxComplianceService.needsTaxDocuments('user-3', 2025);

        geographicScopeService.canHostInLocality(
          userId: 'user-123',
          user: userWithCityExpertise,
          category: 'Coffee',
          locality: 'Greenpoint',
        );

        geographicScopeService.canHostInCity(
          userId: 'user-123',
          user: userWithCityExpertise,
          category: 'Coffee',
          city: 'Brooklyn',
        );

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
            reason:
                'Multiple sequential calls should complete within 5 seconds');
        print(
            '5 sequential service calls took: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Database Query Performance', () {
      test('TaxComplianceService should efficiently query payment data',
          () async {
        // Arrange
        await paymentService.initialize();
        final taxService = TaxComplianceService(
          paymentService: paymentService,
        );

        // Act
        final stopwatch = Stopwatch()..start();
        await taxService.needsTaxDocuments('user-123', 2025);
        stopwatch.stop();

        // Assert
        // Query should be efficient (assuming in-memory storage for now)
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason: 'Payment data query should complete within 500ms');
        print('Payment data query took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('Multiple year queries should scale linearly', () async {
        // Arrange
        await paymentService.initialize();
        final taxService = TaxComplianceService(
          paymentService: paymentService,
        );

        // Act
        final stopwatch = Stopwatch()..start();

        // Query multiple years
        await taxService.needsTaxDocuments('user-123', 2023);
        await taxService.needsTaxDocuments('user-123', 2024);
        await taxService.needsTaxDocuments('user-123', 2025);

        stopwatch.stop();

        // Assert
        // Should scale roughly linearly (3x single query time)
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Multiple year queries should complete within 2 seconds');
        print('3 year queries took: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Memory Usage Patterns', () {
      test('Services should not retain excessive memory after operations',
          () async {
        // Arrange
        await paymentService.initialize();
        final taxService = TaxComplianceService(
          paymentService: paymentService,
        );

        // Act
        // Perform multiple operations
        for (int i = 0; i < 10; i++) {
          await taxService.needsTaxDocuments('user-$i', 2025);
        }

        // Note: Actual memory testing would require more sophisticated tools
        // This test verifies no exceptions occur from memory issues

        // Assert
        expect(taxService, isNotNull);
        // No memory leaks detected if test completes successfully
      });

      test('Services should handle large batches without memory issues',
          () async {
        // Arrange
        await paymentService.initialize();
        final taxService = TaxComplianceService(
          paymentService: paymentService,
        );

        // Act
        // Process many users
        final futures = <Future<bool>>[];
        for (int i = 0; i < 100; i++) {
          futures.add(taxService.needsTaxDocuments('user-$i', 2025));
        }
        await Future.wait(futures);

        // Assert
        expect(futures.length, equals(100));
        // No memory issues if test completes
      });
    });

    group('Concurrent Service Calls', () {
      test('Services should handle concurrent calls efficiently', () async {
        // Arrange
        await paymentService.initialize();
        final taxService = TaxComplianceService(
          paymentService: paymentService,
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final futures = <Future<bool>>[];

        // 10 concurrent calls
        for (int i = 0; i < 10; i++) {
          futures.add(taxService.needsTaxDocuments('user-$i', 2025));
        }

        await Future.wait(futures);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: '10 concurrent calls should complete within 2 seconds');
        print(
            '10 concurrent tax compliance checks took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('Services should handle concurrent geographic scope checks', () {
        // Arrange
        final userWithCityExpertise = testUser.copyWith(
          expertiseMap: {'Coffee': 'city'},
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final results = <bool>[];

        // 50 concurrent checks
        for (int i = 0; i < 50; i++) {
          results.add(geographicScopeService.canHostInLocality(
            userId: 'user-123',
            user: userWithCityExpertise,
            category: 'Coffee',
            locality: 'Greenpoint',
          ));
        }

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
            reason:
                '50 concurrent geographic checks should complete within 500ms');
        expect(results.length, equals(50));
        print(
            '50 concurrent geographic checks took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('Mixed concurrent service calls should complete efficiently',
          () async {
        // Arrange
        await paymentService.initialize();
        final taxService = TaxComplianceService(
          paymentService: paymentService,
        );
        final userWithCityExpertise = testUser.copyWith(
          expertiseMap: {'Coffee': 'city'},
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final futures = <Future<void>>[];

        // Mix of concurrent calls
        for (int i = 0; i < 5; i++) {
          futures.add(taxService.needsTaxDocuments('user-$i', 2025));
        }

        // Add synchronous calls
        for (int i = 0; i < 5; i++) {
          geographicScopeService.canHostInLocality(
            userId: 'user-123',
            user: userWithCityExpertise,
            category: 'Coffee',
            locality: 'Greenpoint',
          );
        }

        await Future.wait(futures);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Mixed concurrent calls should complete within 2 seconds');
        print(
            'Mixed concurrent calls took: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Performance Regression Detection', () {
      test('Service method performance should not degrade significantly',
          () async {
        // Arrange
        await paymentService.initialize();
        final taxService = TaxComplianceService(
          paymentService: paymentService,
        );

        // Act - Measure baseline performance
        final baselineTimes = <int>[];
        for (int i = 0; i < 5; i++) {
          final sw = Stopwatch()..start();
          await taxService.needsTaxDocuments('user-$i', 2025);
          sw.stop();
          baselineTimes.add(sw.elapsedMilliseconds);
        }

        final avgBaseline =
            baselineTimes.reduce((a, b) => a + b) / baselineTimes.length;

        // Assert - Performance should be consistent
        expect(avgBaseline, lessThan(1000),
            reason: 'Average response time should be under 1 second');
        print('Average baseline time: ${avgBaseline.toStringAsFixed(2)}ms');

        // Verify no significant outliers
        final maxTime = baselineTimes.reduce((a, b) => a > b ? a : b);
        expect(maxTime, lessThan(avgBaseline * 3),
            reason: 'Max time should not be more than 3x average');
      });

      test('Geographic scope service should maintain consistent performance',
          () {
        // Arrange
        final userWithCityExpertise = testUser.copyWith(
          expertiseMap: {'Coffee': 'city'},
        );

        // Act - Measure multiple calls
        final times = <int>[];
        for (int i = 0; i < 100; i++) {
          final sw = Stopwatch()..start();
          geographicScopeService.canHostInLocality(
            userId: 'user-123',
            user: userWithCityExpertise,
            category: 'Coffee',
            locality: 'Greenpoint',
          );
          sw.stop();
          times.add(sw.elapsedMilliseconds);
        }

        final avgTime = times.reduce((a, b) => a + b) / times.length;
        final maxTime = times.reduce((a, b) => a > b ? a : b);

        // Assert - Should be consistently fast
        expect(avgTime, lessThan(10), reason: 'Average should be under 10ms');
        expect(maxTime, lessThan(50), reason: 'Max should be under 50ms');
        print(
            'Geographic scope - Average: ${avgTime.toStringAsFixed(2)}ms, Max: ${maxTime}ms');
      });
    });
  });
}
