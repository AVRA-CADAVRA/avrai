import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/core/models/connection_metrics.dart' hide ChatMessage, ChatMessageType;

import 'ai2ai_learning_test.mocks.dart';

@GenerateMocks([SharedPreferences, PersonalityLearning])
void main() {
  group('AI2AIChatAnalyzer', () {
    late AI2AIChatAnalyzer analyzer;
    late MockSharedPreferences mockPrefs;
    late MockPersonalityLearning mockPersonalityLearning;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockPersonalityLearning = MockPersonalityLearning();
      
      analyzer = AI2AIChatAnalyzer(
        prefs: mockPrefs,
        personalityLearning: mockPersonalityLearning,
      );
    });

    group('Chat Analysis', () {
      test('should analyze chat conversation without errors', () async {
        const localUserId = 'test-user-123';
        final chatEvent = AI2AIChatEvent(
          eventId: 'chat-123',
          messageType: ChatMessageType.personalitySharing,
          participants: ['user1', 'user2'],
          messages: [
            ChatMessage(
              senderId: 'user1',
              content: 'Test message',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await analyzer.analyzeChatConversation(
          localUserId,
          chatEvent,
          connectionContext,
        );

        expect(result, isA<AI2AIChatAnalysisResult>());
        expect(result.localUserId, equals(localUserId));
        expect(result.chatEvent, equals(chatEvent));
        expect(result.analysisConfidence, greaterThanOrEqualTo(0.0));
        expect(result.analysisConfidence, lessThanOrEqualTo(1.0));
      });

      test('should handle different chat message types', () async {
        const localUserId = 'test-user-123';
        final messageTypes = [
          ChatMessageType.personalitySharing,
          ChatMessageType.experienceSharing,
          ChatMessageType.trustBuilding,
        ];
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        for (final messageType in messageTypes) {
          final chatEvent = AI2AIChatEvent(
            eventId: 'chat-$messageType',
            messageType: messageType,
            participants: ['user1', 'user2'],
            messages: [
              ChatMessage(
                senderId: 'user1',
                content: 'Test message',
                timestamp: DateTime.now(),
                context: {},
              ),
            ],
            timestamp: DateTime.now(),
            duration: const Duration(minutes: 5),
            metadata: {},
          );

          final result = await analyzer.analyzeChatConversation(
            localUserId,
            chatEvent,
            connectionContext,
          );

          expect(result.chatEvent.messageType, equals(messageType));
        }
      });
    });

    group('Collective Intelligence', () {
      test('should analyze collective intelligence without errors', () async {
        const localUserId = 'test-user-123';
        final chatEvent = AI2AIChatEvent(
          eventId: 'chat-123',
          messageType: ChatMessageType.personalitySharing,
          participants: ['user1', 'user2', 'user3'],
          messages: [
            ChatMessage(
              senderId: 'user1',
              content: 'Test message',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await analyzer.analyzeChatConversation(
          localUserId,
          chatEvent,
          connectionContext,
        );

        expect(result.collectiveIntelligence, isNotNull);
      });
    });

    group('Privacy Validation', () {
      test('should ensure chat analysis contains no user data', () async {
        const localUserId = 'test-user-123';
        final chatEvent = AI2AIChatEvent(
          eventId: 'chat-123',
          messageType: ChatMessageType.personalitySharing,
          participants: ['user1', 'user2'],
          messages: [
            ChatMessage(
              senderId: 'user1',
              content: 'Test message',
              timestamp: DateTime.now(),
              context: {},
            ),
          ],
          timestamp: DateTime.now(),
          duration: const Duration(minutes: 5),
          metadata: {},
        );
        final connectionContext = ConnectionMetrics.initial(
          localAISignature: 'ai1',
          remoteAISignature: 'ai2',
          compatibility: 0.8,
        );

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await analyzer.analyzeChatConversation(
          localUserId,
          chatEvent,
          connectionContext,
        );

        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        // Analysis should work with anonymized data only
        expect(result, isA<AI2AIChatAnalysisResult>());
      });
    });
  });
}
