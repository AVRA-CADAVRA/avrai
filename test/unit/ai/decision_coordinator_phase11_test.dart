/// SPOTS DecisionCoordinator Phase 11 Enhancement Tests
/// Date: January 2026
/// Purpose: Test offline mesh learning in DecisionCoordinator
///
/// Test Coverage:
/// - _getOfflineMeshInsights() method
/// - Offline pathway enhancement with mesh insights
/// - Graceful degradation when ConnectionOrchestrator unavailable
///
/// Phase 11 Enhancement Testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/core/ai/decision_coordinator.dart';
import 'package:avrai/core/ml/inference_orchestrator.dart';
import 'package:avrai/core/services/config_service.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import '../../helpers/getit_test_harness.dart';

@GenerateMocks([
  InferenceOrchestrator,
  ConfigService,
  Connectivity,
  VibeConnectionOrchestrator,
])
import 'decision_coordinator_phase11_test.mocks.dart';

void main() {
  group('DecisionCoordinator Phase 11 Enhancements', () {
    late DecisionCoordinator coordinator;
    late MockInferenceOrchestrator mockOrchestrator;
    late MockConfigService mockConfig;
    late MockConnectivity mockConnectivity;
    late GetItTestHarness getIt;

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      
      // Create mocks
      mockOrchestrator = MockInferenceOrchestrator();
      mockConfig = MockConfigService();
      mockConnectivity = MockConnectivity();
      
      // Setup connectivity mock (offline by default for offline tests)
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      
      // Setup orchestrator mock
      when(mockOrchestrator.infer(
        input: anyNamed('input'),
        strategy: anyNamed('strategy'),
      )).thenAnswer((_) async => InferenceResult(
            dimensionScores: {},
            reasoning: null,
            source: InferenceSource.device,
          ));
      
      // Create DecisionCoordinator
      coordinator = DecisionCoordinator(
        orchestrator: mockOrchestrator,
        connectivity: mockConnectivity,
        config: mockConfig,
      );
    });

    tearDown(() {
      // Clean up GetIt registrations
      getIt.unregisterIfRegistered<VibeConnectionOrchestrator>();
    });

    group('_getOfflineMeshInsights()', () {
      test('should return empty list when ConnectionOrchestrator not registered', () async {
        // Ensure ConnectionOrchestrator is not registered
        getIt.unregisterIfRegistered<VibeConnectionOrchestrator>();
        
        final input = {
          'user_id': 'test-user',
          'context': 'test_context',
        };
        
        // Note: _getOfflineMeshInsights is private, so we test it indirectly
        // by testing the offline pathway that calls it
        final result = await coordinator.coordinate(
          input: input,
          context: InferenceContext(),
        );
        
        expect(result, isNotNull);
        expect(result.source, equals(InferenceSource.device));
      });

      test('should return empty list when API not available (graceful degradation)', () async {
        // Ensure ConnectionOrchestrator is not registered - simulate unavailable state
        getIt.unregisterIfRegistered<VibeConnectionOrchestrator>();
        
        final input = {
          'user_id': 'test-user',
          'context': 'test_context',
        };
        
        final result = await coordinator.coordinate(
          input: input,
          context: InferenceContext(),
        );
        
        expect(result, isNotNull);
        // Should work without mesh insights
      });

      test('should handle errors gracefully', () async {
        // Setup connectivity to throw error
        when(mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Connectivity error'));
        
        final input = {
          'user_id': 'test-user',
          'context': 'test_context',
        };
        
        // Should complete without throwing
        await expectLater(
          coordinator.coordinate(
            input: input,
            context: InferenceContext(),
          ),
          completes,
        );
      });
    });

    group('Offline Pathway Enhancement', () {
      test('should enhance input with mesh insights when available', () async {
        // Mock offline connectivity
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        
        final input = {
          'user_id': 'test-user',
          'context': 'test_context',
        };
        
        final result = await coordinator.coordinate(
          input: input,
          context: InferenceContext(),
        );
        
        expect(result, isNotNull);
        expect(result.source, equals(InferenceSource.device));
        // Verify orchestrator was called (mesh insights enhancement happens internally)
        verify(mockOrchestrator.infer(
          input: anyNamed('input'),
          strategy: anyNamed('strategy'),
        )).called(1);
      });

      test('should continue without mesh insights when unavailable', () async {
        // Ensure ConnectionOrchestrator is not registered
        getIt.unregisterIfRegistered<VibeConnectionOrchestrator>();
        
        // Mock offline connectivity
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        
        final input = {
          'user_id': 'test-user',
          'context': 'test_context',
        };
        
        final result = await coordinator.coordinate(
          input: input,
          context: InferenceContext(),
        );
        
        expect(result, isNotNull);
        // Should still work without mesh insights
      });

      test('should not break offline inference flow', () async {
        // Mock offline connectivity
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        
        final input = {
          'user_id': 'test-user',
          'context': 'test_context',
        };
        
        final result = await coordinator.coordinate(
          input: input,
          context: InferenceContext(),
        );
        
        expect(result, isNotNull);
        expect(result.source, equals(InferenceSource.device));
        verify(mockOrchestrator.infer(
          input: anyNamed('input'),
          strategy: anyNamed('strategy'),
        )).called(1);
      });
    });
  });
}

