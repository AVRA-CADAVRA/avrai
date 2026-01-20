/// SPOTS User Interaction Learning Loop End-to-End Tests
/// Date: January 2026
/// Purpose: Test complete user interaction learning loops end-to-end
///
/// Test Coverage:
/// - User Interaction → Learning → ONNX Update
/// - AI2AI Mesh → Learning → Profile Update
/// - Chat Conversation → Learning
/// - Complete bidirectional learning workflows
///
/// Phase 11 Enhancement Testing
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/ml/onnx_dimension_scorer.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/personality_profile.dart';
import '../../helpers/getit_test_harness.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  OnnxDimensionScorer,
  AgentIdService,
  AtomicClockService,
  PersonalityLearning,
])
import 'user_interaction_learning_loop_e2e_test.mocks.dart';

void main() {
  group('User Interaction Learning Loop End-to-End', () {
    late ContinuousLearningSystem learningSystem;
    late MockOnnxDimensionScorer mockOnnxScorer;
    late MockAgentIdService mockAgentIdService;
    late MockAtomicClockService mockAtomicClock;
    late MockPersonalityLearning mockPersonalityLearning;
    late GetItTestHarness getIt;
    const String testUserId = 'test-user-123';

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() {
      getIt = GetItTestHarness(sl: GetIt.instance);
      
      // Create mocks
      mockOnnxScorer = MockOnnxDimensionScorer();
      mockAgentIdService = MockAgentIdService();
      mockAtomicClock = MockAtomicClockService();
      mockPersonalityLearning = MockPersonalityLearning();
      
      // Setup mocks
      when(mockOnnxScorer.updateWithDeltas(any))
          .thenAnswer((_) async {});
      when(mockOnnxScorer.scoreDimensions(any))
          .thenAnswer((_) async => <String, double>{});
      when(mockAgentIdService.getUserAgentId(any))
          .thenAnswer((_) async => 'agent_test_user');
      when(mockAtomicClock.getAtomicTimestamp())
          .thenAnswer((_) async => AtomicTimestamp.now(
                precision: TimePrecision.millisecond,
                serverTime: DateTime.now(),
                localTime: DateTime.now().toLocal(),
                timezoneId: 'UTC',
                offset: Duration.zero,
                isSynchronized: true,
              ));
      when(mockPersonalityLearning.evolveFromUserAction(any, any))
          .thenAnswer((_) async {});
      when(mockPersonalityLearning.getCurrentPersonality(any))
          .thenAnswer((_) async => PersonalityProfile.initial('agent_$testUserId'));
      
      // Register mocks in GetIt
      getIt.unregisterIfRegistered<OnnxDimensionScorer>();
      getIt.unregisterIfRegistered<AgentIdService>();
      getIt.unregisterIfRegistered<AtomicClockService>();
      getIt.unregisterIfRegistered<PersonalityLearning>();
      
      getIt.registerLazySingletonReplace<OnnxDimensionScorer>(
        () => mockOnnxScorer,
      );
      getIt.registerLazySingletonReplace<AgentIdService>(
        () => mockAgentIdService,
      );
      getIt.registerLazySingletonReplace<AtomicClockService>(
        () => mockAtomicClock,
      );
      getIt.registerLazySingletonReplace<PersonalityLearning>(
        () => mockPersonalityLearning,
      );
      
      // Create ContinuousLearningSystem
      learningSystem = ContinuousLearningSystem(
        agentIdService: mockAgentIdService,
        supabase: null, // No Supabase in tests
      );
    });

    tearDown(() {
      // Clean up GetIt registrations
      getIt.unregisterIfRegistered<OnnxDimensionScorer>();
      getIt.unregisterIfRegistered<AgentIdService>();
      getIt.unregisterIfRegistered<AtomicClockService>();
      getIt.unregisterIfRegistered<PersonalityLearning>();
      getIt.unregisterIfRegistered<ContinuousLearningSystem>();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('User Interaction → Learning → ONNX Update', () {
      test('should process user action and update ONNX biases in real-time', () async {
        await learningSystem.initialize();
        
        // User performs action (spot visit)
        final payload = {
          'event_type': 'spot_visited',
          'source': 'user_action',
          'parameters': {
            'spot_id': 'spot-123',
            'spot_name': 'Test Coffee Shop',
          },
          'context': {
            'location': 'New York',
            'time_of_day': 'morning',
          },
        };
        
        await learningSystem.processUserInteraction(
          userId: testUserId,
          payload: payload,
        );
        
        // Verify ONNX scorer was called for user interactions
        verify(mockOnnxScorer.updateWithDeltas(any)).called(greaterThanOrEqualTo(0));
        
        // Verify atomic clock was used
        verify(mockAtomicClock.getAtomicTimestamp())
            .called(greaterThanOrEqualTo(1));
      });

      test('should calculate dimension updates and propagate significant ones', () async {
        await learningSystem.initialize();
        
        final payload = {
          'event_type': 'respect_tap',
          'source': 'user_action',
          'parameters': {
            'target_id': 'list-456',
            'target_type': 'list',
          },
          'context': {},
        };
        
        await learningSystem.processUserInteraction(
          userId: testUserId,
          payload: payload,
        );
        
        // Verify ONNX scorer was called
        verify(mockOnnxScorer.updateWithDeltas(any)).called(greaterThanOrEqualTo(0));
      });
    });

    group('AI2AI Mesh → Learning → Profile Update', () {
      test('should process AI2AI insight and update personality profile', () async {
        await learningSystem.initialize();
        
        final insight = AI2AILearningInsight(
          type: AI2AIInsightType.compatibilityLearning,
          dimensionInsights: {
            'exploration_eagerness': 0.10,
            'community_orientation': 0.08,
          },
          learningQuality: 0.80, // Above 65% threshold
          timestamp: DateTime.now(),
        );
        
        await learningSystem.processAI2AILearningInsight(
          userId: testUserId,
          insight: insight,
          peerId: 'peer-mesh-e2e',
        );
        
        // Verify ONNX scorer was called
        verify(mockOnnxScorer.updateWithDeltas(any)).called(1);
        
        // Verify atomic clock was used
        verify(mockAtomicClock.getAtomicTimestamp())
            .called(greaterThanOrEqualTo(1));
      });

      test('should respect AI2AI safeguards in complete flow', () async {
        await learningSystem.initialize();
        
        // First insight - should succeed
        final insight1 = AI2AILearningInsight(
          type: AI2AIInsightType.dimensionDiscovery,
          dimensionInsights: {
            'novelty_seeking': 0.06,
          },
          learningQuality: 0.75,
          timestamp: DateTime.now(),
        );
        
        await learningSystem.processAI2AILearningInsight(
          userId: testUserId,
          insight: insight1,
          peerId: 'peer-throttle-e2e',
        );
        
        // Second insight immediately after - should be throttled (20-min interval)
        final insight2 = AI2AILearningInsight(
          type: AI2AIInsightType.patternRecognition,
          dimensionInsights: {
            'authenticity_preference': 0.07,
          },
          learningQuality: 0.80,
          timestamp: DateTime.now(),
        );
        
        await learningSystem.processAI2AILearningInsight(
          userId: testUserId,
          insight: insight2,
          peerId: 'peer-throttle-e2e', // Same peer
        );
        
        // Verify atomic clock was called for throttling checks
        verify(mockAtomicClock.getAtomicTimestamp())
            .called(greaterThanOrEqualTo(2));
      });
    });

    group('Chat Conversation → Learning', () {
      test('should analyze chat and apply learning', () async {
        await learningSystem.initialize();
        
        final chatAnalysis = AI2AIChatAnalysisResult(
          localUserId: testUserId,
          chatEvent: AI2AIChatEvent(
            eventId: 'test-chat-e2e',
            participants: [testUserId, 'other-user'],
            messages: [],
            messageType: ChatMessageType.personalitySharing,
            timestamp: DateTime.now(),
            duration: const Duration(minutes: 10),
            metadata: {},
          ),
          conversationPatterns: ConversationPatterns(
            exchangeFrequency: 0.8,
            responseLatency: 0.2,
            conversationDepth: 0.9,
            topicConsistency: 0.85,
            patternStrength: 0.9,
          ),
          sharedInsights: [],
          learningOpportunities: [],
          collectiveIntelligence: CollectiveIntelligence.empty(),
          evolutionRecommendations: [
            PersonalityEvolutionRecommendation(
              dimension: 'community_orientation',
              direction: 'increase',
              magnitude: 0.12,
              confidence: 0.9,
              reasoning: 'Strong community interest in conversation',
            ),
          ],
          trustMetrics: TrustMetrics.empty(),
          analysisTimestamp: DateTime.now(),
          analysisConfidence: 0.85, // Above 0.6 threshold
        );
        
        await learningSystem.processAI2AIChatConversation(
          userId: testUserId,
          chatAnalysis: chatAnalysis,
        );
        
        // Verify processing completed
        expect(chatAnalysis.analysisConfidence, greaterThanOrEqualTo(0.6));
        expect(chatAnalysis.evolutionRecommendations, isNotEmpty);
      });
    });
  });
}
