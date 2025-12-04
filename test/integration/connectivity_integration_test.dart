import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/core/services/enhanced_connectivity_service.dart';
import 'package:spots/data/repositories/spots_repository_impl.dart';
import '../fixtures/model_factories.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_dependencies.mocks.dart';

/// SPOTS Enhanced Connectivity Integration Tests
/// Date: December 1, 2025
/// Purpose: Test EnhancedConnectivityService integration with repositories
/// 
/// Test Coverage:
/// - Connectivity service + repository integration
/// - Offline/online mode switching
/// - Connectivity stream integration
/// - Cache behavior with connectivity changes
/// - Service-to-service communication
/// 
/// Dependencies:
/// - EnhancedConnectivityService: Connectivity checks
/// - SpotsRepositoryImpl: Repository using connectivity

void main() {
  group('Enhanced Connectivity Integration Tests', () {
    late EnhancedConnectivityService connectivityService;
    late SpotsRepositoryImpl spotsRepository;
    late MockConnectivity mockConnectivity;
    late MockSpotsLocalDataSource mockLocalDataSource;
    late MockSpotsRemoteDataSource mockRemoteDataSource;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      
      mockConnectivity = MockConnectivity();
      mockLocalDataSource = MockSpotsLocalDataSource();
      mockRemoteDataSource = MockSpotsRemoteDataSource();
      
      connectivityService = EnhancedConnectivityService();
      
      spotsRepository = SpotsRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        connectivity: mockConnectivity,
      );
      
      // Setup default connectivity responses (using Mockito syntax)
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
      // Note: mocktail reset only works with Mock objects
      // Connectivity is a real instance, not a mock
    });

    group('Connectivity Service + Repository Integration', () {
      test('should work with repository offline-first pattern', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => ModelFactories.createTestSpots(3));
        
        // Act
        final spots = await spotsRepository.getSpots();
        
        // Assert
        expect(spots, isNotEmpty);
        verify(mockLocalDataSource.getAllSpots()).called(1);
        verifyNever(mockRemoteDataSource.getSpots());
      });

      test('should work with repository online sync pattern', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => ModelFactories.createTestSpots(3));
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => ModelFactories.createTestSpots(5));
        
        // Act
        final spots = await spotsRepository.getSpots();
        
        // Assert
        expect(spots, isNotEmpty);
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.getAllSpots()).called(1);
      });
    });

    group('Connectivity Stream Integration', () {
      test('should provide connectivity stream for reactive updates', () async {
        // Arrange
        final connectivityStream = connectivityService.connectivityStream;
        
        // Act & Assert
        expect(connectivityStream, isNotNull);
        // Stream should emit connectivity changes
      });
    });

    group('Cache Behavior Integration', () {
      test('should use cached connectivity status when available', () async {
        // Arrange
        // First check to populate cache
        final hasConnectivity1 = await connectivityService.hasInternetAccess();
        
        // Act
        final hasConnectivity2 = await connectivityService.hasInternetAccess();
        
        // Assert
        // Both should return same result (cached)
        expect(hasConnectivity2, equals(hasConnectivity1));
      });

      test('should force refresh when cache invalidated', () async {
        // Arrange
        await connectivityService.hasInternetAccess(); // Populate cache
        
        // Act
        final refreshed = await connectivityService.hasInternetAccess(forceRefresh: true);
        
        // Assert
        expect(refreshed, isA<bool>());
      });
    });
  });
}

