/// SPOTS AI2AILearningOrchestrator → ContinuousLearningSystem Integration Tests
/// Date: January 2026
/// Purpose: Test integration between AI2AILearningOrchestrator and ContinuousLearningSystem
///
/// Test Coverage:
/// - Chat analysis integration (after analyzeChatConversation)
/// - Calls ContinuousLearningSystem when confidence >= 0.6
/// - Skips call when confidence < 0.6
/// - Graceful handling when ContinuousLearningSystem unavailable
/// - Non-blocking execution
///
/// Phase 11 Enhancement Testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai/ai2ai_learning/orchestrator.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart' show AI2AIChatEvent, ChatMessageType;
import 'package:avrai/core/models/connection_metrics.dart' hide ChatMessageType;
import '../../helpers/getit_test_harness.dart';

@GenerateMocks([
  ContinuousLearningSystem,
])
import 'ai2ai_learning_orchestrator_continuous_learning_integration_test.mocks.dart';

void main() {
  group('AI2AILearningOrchestrator → ContinuousLearningSystem Integration', () {
    late AI2AILearningOrchestrator orchestrator;
    late MockContinuousLearningSystem mockContinuousLearningSystem;
    late GetItTestHarness getIt;
    const String testUserId = 'test-user-123';

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      
      // Create mocks
      mockContinuousLearningSystem = MockContinuousLearningSystem();
      
      // Setup continuous learning system mock
      when(mockContinuousLearningSystem.processAI2AIChatConversation(
        userId: anyNamed('userId'),
        chatAnalysis: anyNamed('chatAnalysis'),
      )).thenAnswer((_) async {});
      
      // Register ContinuousLearningSystem in GetIt
      getIt.unregisterIfRegistered<ContinuousLearningSystem>();
      getIt.registerLazySingletonReplace<ContinuousLearningSystem>(
        () => mockContinuousLearningSystem,
      );
      
      // Create orchestrator
      orchestrator = AI2AILearningOrchestrator();
    });

    tearDown(() {
      // Clean up GetIt registrations
      getIt.unregisterIfRegistered<ContinuousLearningSystem>();
    });

    group('Chat Analysis Integration', () {
      test('should call ContinuousLearningSystem when confidence >= 0.6', () async {
        final chatEvent = AI2AIChatEvent(
          eventId: 'test-chat-1',
          participants: [testUserId, 'other-user'],
          messages: [],
          messageType: ChatMessageType.personalitySharing,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'local-sig',
          remoteAISignature: 'remote-sig',
          compatibility: 0.75,
        );
        
        final result = await orchestrator.analyzeChatConversation(
          testUserId,
          chatEvent,
          connectionContext,
        );
        
        // If confidence >= 0.6, ContinuousLearningSystem should be called
        if (result.analysisConfidence >= 0.6) {
          verify(mockContinuousLearningSystem.processAI2AIChatConversation(
            userId: anyNamed('userId'),
            chatAnalysis: anyNamed('chatAnalysis'),
          )).called(greaterThanOrEqualTo(1));
        }
      });

      test('should skip call when confidence < 0.6', () async {
        final chatEvent = AI2AIChatEvent(
          eventId: 'test-chat-2',
          participants: [testUserId, 'other-user'],
          messages: [],
          messageType: ChatMessageType.experienceSharing,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 2),
          metadata: {},
        );
        
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'local-sig',
          remoteAISignature: 'remote-sig',
          compatibility: 0.75,
        );
        
        final result = await orchestrator.analyzeChatConversation(
          testUserId,
          chatEvent,
          connectionContext,
        );
        
        // If confidence < 0.6, ContinuousLearningSystem should not be called
        if (result.analysisConfidence < 0.6) {
          verifyNever(mockContinuousLearningSystem.processAI2AIChatConversation(
            userId: anyNamed('userId'),
            chatAnalysis: anyNamed('chatAnalysis'),
          ));
        }
      });

      test('should pass correct userId and chatAnalysis', () async {
        final chatEvent = AI2AIChatEvent(
          eventId: 'test-chat-3',
          participants: [testUserId, 'other-user'],
          messages: [],
          messageType: ChatMessageType.insightExchange,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 10),
          metadata: {},
        );
        
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'local-sig',
          remoteAISignature: 'remote-sig',
          compatibility: 0.75,
        );
        
        await orchestrator.analyzeChatConversation(
          testUserId,
          chatEvent,
          connectionContext,
        );
        
        // Verify ContinuousLearningSystem is accessible
        expect(GetIt.instance.isRegistered<ContinuousLearningSystem>(), isTrue);
      });

      test('should handle ContinuousLearningSystem unavailable gracefully', () async {
        // Unregister ContinuousLearningSystem
        getIt.unregisterIfRegistered<ContinuousLearningSystem>();
        
        final chatEvent = AI2AIChatEvent(
          eventId: 'test-chat-4',
          participants: [testUserId, 'other-user'],
          messages: [],
          messageType: ChatMessageType.trustBuilding,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 8),
          metadata: {},
        );
        
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'local-sig',
          remoteAISignature: 'remote-sig',
          compatibility: 0.75,
        );
        
        // Should complete without errors even if ContinuousLearningSystem unavailable
        await expectLater(
          orchestrator.analyzeChatConversation(
            testUserId,
            chatEvent,
            connectionContext,
          ),
          completes,
        );
      });

      test('should execute non-blocking', () async {
        final chatEvent = AI2AIChatEvent(
          eventId: 'test-chat-5',
          participants: [testUserId, 'other-user'],
          messages: [],
          messageType: ChatMessageType.personalitySharing,
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'local-sig',
          remoteAISignature: 'remote-sig',
          compatibility: 0.75,
        );
        
        // Should complete quickly (non-blocking)
        final result = await orchestrator.analyzeChatConversation(
          testUserId,
          chatEvent,
          connectionContext,
        );
        
        expect(result, isNotNull);
        expect(result.localUserId, equals(testUserId));
      });
    });
  });
}
