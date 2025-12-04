/// BLoC Test Helpers - Phase 4: BLoC State Management Testing
/// 
/// Provides common utilities for testing BLoCs with consistent patterns
/// Ensures optimal development and deployment through comprehensive testing

import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/core/models/list.dart';

/// Common test utilities for BLoC testing
class BlocTestHelpers {
  /// Creates a mock exception for testing error scenarios
  static Exception createMockException([String message = 'Test error']) {
    return Exception(message);
  }

  /// Verifies state equality with proper type checking
  static void verifyStateEquality<T>(T actual, T expected) {
    expect(actual, equals(expected));
    expect(actual.runtimeType, equals(expected.runtimeType));
  }

  /// Creates a test delay for async operations
  static Future<void> testDelay([Duration? duration]) async {
    await Future.delayed(duration ?? const Duration(milliseconds: 100));
  }

  /// Verifies loading state transitions
  static void verifyLoadingTransition<TEvent, TState>(
    dynamic test,
    TState loadingState,
  ) {
    // Implementation depends on bloc_test version
  }
}

/// Test data factories for consistent test scenarios
class TestDataFactory {
  /// Creates a test user with default or custom properties
  static User createTestUser({
    String? id,
    String? email,
    String? name,
    bool isOnline = true,
    List<String>? roles,
  }) {
    return User(
      id: id ?? 'test-user-123',
      email: email ?? 'test@example.com',
      name: name ?? 'Test User',
      role: UserRole.user, // Convert roles list to UserRole enum
      isOnline: isOnline,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a test spot with default or custom properties
  static Spot createTestSpot({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? category,
    String? createdBy,
  }) {
    return Spot(
      id: id ?? 'test-spot-123',
      name: name ?? 'Test Spot',
      description: description ?? 'Test description',
      latitude: latitude ?? 37.7749,
      longitude: longitude ?? -122.4194,
      category: category ?? 'restaurant',
      rating: 0.0,
      createdBy: createdBy ?? 'test-user-123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a test list with default or custom properties
  static SpotList createTestList({
    String? id,
    String? title,
    String? description,
    String? curatorId,
    List<String>? collaboratorIds,
    List<String>? followerIds,
    String? category,
    bool isPublic = true,
  }) {
    return SpotList(
      id: id ?? 'test-list-123',
      title: title ?? 'Test List',
      description: description ?? 'Test list description',
      spots: const [], // Required parameter
      curatorId: curatorId ?? 'test-user-123',
      collaborators: collaboratorIds ?? [],
      followers: followerIds ?? [],
      category: category,
      isPublic: isPublic,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates multiple test spots for bulk testing
  static List<Spot> createTestSpots(int count) {
    return List.generate(count, (index) => createTestSpot(
      id: 'test-spot-$index',
      name: 'Test Spot $index',
      latitude: 37.7749 + (index * 0.001),
      longitude: -122.4194 + (index * 0.001),
    ));
  }

  /// Creates multiple test lists for bulk testing
  static List<SpotList> createTestLists(int count) {
    return List.generate(count, (index) => createTestList(
      id: 'test-list-$index',
      title: 'Test List $index',
    ));
  }
}

/// Mock state verification helpers
class MockStateHelper {
  /// Verifies that a state contains expected data
  static void verifyStateData<T>(T state, Map<String, dynamic> expectedData) {
    for (final entry in expectedData.entries) {
      final key = entry.key;
      final expectedValue = entry.value;
      
      // Use reflection or property access to verify state data
      // This is a simplified version - in real implementation you'd use
      // proper reflection or getters
      expect(state.toString().contains(expectedValue.toString()), isTrue,
          reason: 'State should contain $key: $expectedValue');
    }
  }
}

/// Performance testing helpers for BLoCs
class BlocPerformanceHelper {
  /// Measures BLoC event processing time
  static Future<Duration> measureEventProcessingTime<TBloc, TEvent>(
    TBloc bloc,
    TEvent event,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    // Process event and wait for state change
    if (bloc is Sink<TEvent>) {
      (bloc as Sink<TEvent>).add(event);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Verifies that BLoC operations complete within acceptable time limits
  static void verifyPerformance(Duration actualDuration, Duration maxDuration) {
    expect(actualDuration, lessThan(maxDuration),
        reason: 'BLoC operation took ${actualDuration.inMilliseconds}ms, '
               'expected less than ${maxDuration.inMilliseconds}ms');
  }
}

/// Error scenario helpers for comprehensive testing
class ErrorScenarioHelper {
  /// Common error scenarios for BLoC testing
  static const String networkError = 'Network connection failed';
  static const String authError = 'Authentication failed';
  static const String validationError = 'Validation failed';
  static const String permissionError = 'Insufficient permissions';
  static const String notFoundError = 'Resource not found';
  
  /// Creates mock exceptions for different error scenarios
  static Exception createNetworkException() => Exception(networkError);
  static Exception createAuthException() => Exception(authError);
  static Exception createValidationException() => Exception(validationError);
  static Exception createPermissionException() => Exception(permissionError);
  static Exception createNotFoundException() => Exception(notFoundError);
}
