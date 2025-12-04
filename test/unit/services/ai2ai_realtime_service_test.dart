import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/services/ai2ai_realtime_service.dart';
import 'package:spots/core/ai2ai/connection_orchestrator.dart';
import 'package:spots_network/spots_network.dart';
import 'package:spots/core/ai2ai/aipersonality_node.dart';

class MockRealtimeBackend extends Mock implements RealtimeBackend {}
class MockVibeConnectionOrchestrator extends Mock implements VibeConnectionOrchestrator {}
class MockAIPersonalityNode extends Mock implements AIPersonalityNode {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(UserPresence(
      userId: 'test-user',
      userName: 'Test User',
      lastSeen: DateTime.now(),
      isOnline: true,
    ));
    registerFallbackValue(RealtimeMessage(
      id: 'test-id',
      senderId: 'test-sender',
      content: 'test-content',
      type: 'test-type',
      timestamp: DateTime.now(),
    ));
  });
  group('AI2AIRealtimeService', () {
    late AI2AIRealtimeService service;
    late MockRealtimeBackend mockBackend;
    late MockVibeConnectionOrchestrator mockOrchestrator;

    setUp(() {
      mockBackend = MockRealtimeBackend();
      mockOrchestrator = MockVibeConnectionOrchestrator();
      service = AI2AIRealtimeService(mockBackend, mockOrchestrator);
      
      // Mock getCurrentVibe to avoid web-specific code paths
      when(() => mockOrchestrator.getCurrentVibe()).thenReturn(null);
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});

        final result = await service.initialize();

        expect(result, isTrue);
        verify(() => mockBackend.connect()).called(1);
        verify(() => mockBackend.joinChannel(any())).called(4); // 4 channels
      });

      test('should handle initialization failure', () async {
        when(() => mockBackend.connect()).thenThrow(Exception('Connection failed'));

        final result = await service.initialize();

        expect(result, isFalse);
      });

      test('should subscribe to all AI2AI channels', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});

        await service.initialize();

        verify(() => mockBackend.joinChannel('ai2ai-network')).called(1);
        verify(() => mockBackend.joinChannel('personality-discovery')).called(1);
        verify(() => mockBackend.joinChannel('vibe-learning')).called(1);
        verify(() => mockBackend.joinChannel('anonymous-communication')).called(1);
      });
    });

    group('broadcasting', () {
      setUp(() async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        await service.initialize();
      });

      test('should broadcast personality discovery', () async {
        final mockNode = MockAIPersonalityNode();
        when(() => mockNode.nodeId).thenReturn('node-123');
        when(() => mockNode.vibeSignature).thenReturn('sig-123');
        when(() => mockNode.compatibilityScore).thenReturn(0.85);
        when(() => mockNode.learningPotential).thenReturn(0.9);
        when(() => mockBackend.sendMessage(any(), any())).thenAnswer((_) async => {});

        await service.broadcastPersonalityDiscovery(mockNode);

        verify(() => mockBackend.sendMessage(
          'personality-discovery',
          any(),
        )).called(1);
      });

      test('should broadcast vibe learning insights', () async {
        final dimensionUpdates = {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.8,
        };
        when(() => mockBackend.sendMessage(any(), any())).thenAnswer((_) async => {});

        await service.broadcastVibeLearning(dimensionUpdates);

        verify(() => mockBackend.sendMessage(
          'vibe-learning',
          any(),
        )).called(1);
      });

      test('should send anonymous message', () async {
        final payload = {'key': 'value'};
        when(() => mockBackend.sendMessage(any(), any())).thenAnswer((_) async => {});

        await service.sendAnonymousMessage('test_message', payload);

        verify(() => mockBackend.sendMessage(
          'anonymous-communication',
          any(),
        )).called(1);
      });

      test('should send private message', () async {
        final payload = {'message': 'test'};
        when(() => mockBackend.sendMessage(any(), any())).thenAnswer((_) async => {});

        await service.sendPrivateMessage('user-123', payload);

        verify(() => mockBackend.sendMessage(
          'ai2ai-network',
          any(),
        )).called(1);
      });
    });

    group('listening', () {
      test('should listen to AI2AI network when connected', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        
        final stream = Stream<RealtimeMessage>.value(
          RealtimeMessage(
            id: '1',
            senderId: 'sender',
            content: 'test',
            type: 'test',
            timestamp: DateTime.now(),
          ),
        );
        when(() => mockBackend.subscribeToMessages('ai2ai-network')).thenAnswer((_) => stream);

        await service.initialize();
        final result = service.listenToAI2AINetwork();

        expect(result, isA<Stream<RealtimeMessage>>());
      });

      test('should return empty stream when not connected', () {
        final result = service.listenToAI2AINetwork();

        expect(result, isA<Stream<RealtimeMessage>>());
      });

      test('should listen to personality discovery', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        
        final stream = Stream<RealtimeMessage>.empty();
        when(() => mockBackend.subscribeToMessages('personality-discovery')).thenAnswer((_) => stream);

        await service.initialize();
        final result = service.listenToPersonalityDiscovery();

        expect(result, isA<Stream<RealtimeMessage>>());
      });

      test('should listen to vibe learning', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        
        final stream = Stream<RealtimeMessage>.empty();
        when(() => mockBackend.subscribeToMessages('vibe-learning')).thenAnswer((_) => stream);

        await service.initialize();
        final result = service.listenToVibeLearning();

        expect(result, isA<Stream<RealtimeMessage>>());
      });

      test('should listen to anonymous communication', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        
        final stream = Stream<RealtimeMessage>.empty();
        when(() => mockBackend.subscribeToMessages('anonymous-communication')).thenAnswer((_) => stream);

        await service.initialize();
        final result = service.listenToAnonymousCommunication();

        expect(result, isA<Stream<RealtimeMessage>>());
      });
    });

    group('presence', () {
      test('should watch AI network presence when connected', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        
        final stream = Stream<List<UserPresence>>.value([]);
        when(() => mockBackend.subscribeToPresence('ai2ai-network')).thenAnswer((_) => stream);

        await service.initialize();
        final result = service.watchAINetworkPresence();

        expect(result, isA<Stream<List<UserPresence>>>());
      });

      test('should return empty stream when not connected', () {
        final result = service.watchAINetworkPresence();

        expect(result, isA<Stream<List<UserPresence>>>());
      });
    });

    group('disconnection', () {
      test('should disconnect from all channels', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        when(() => mockBackend.leaveChannel(any())).thenAnswer((_) async => {});

        await service.initialize();
        await service.disconnect();

        verify(() => mockBackend.leaveChannel(any())).called(4); // 4 channels
        expect(service.isConnected, isFalse);
        expect(service.activeChannels, isEmpty);
      });

      test('should handle disconnection errors gracefully', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        when(() => mockBackend.leaveChannel(any())).thenThrow(Exception('Disconnect failed'));

        await service.initialize();
        await service.disconnect();

        // Should not throw, just log error
        expect(service.activeChannels, isEmpty);
      });
    });

    group('connection status', () {
      test('should return false when not connected', () {
        expect(service.isConnected, isFalse);
        expect(service.activeChannels, isEmpty);
      });

      test('should return true when connected', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});

        await service.initialize();

        expect(service.isConnected, isTrue);
        expect(service.activeChannels.length, equals(4));
      });
    });

    group('latency measurement', () {
      test('should measure realtime latency', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});

        final sendTime = DateTime.now();
        final traceId = DateTime.now().microsecondsSinceEpoch.toString();
        
        final stream = Stream<RealtimeMessage>.value(
          RealtimeMessage(
            id: traceId,
            senderId: 'sender',
            content: 'latency_ping',
            type: 'latency_ping',
            timestamp: sendTime.add(const Duration(milliseconds: 50)),
            metadata: {
              'trace_id': traceId,
              'send_ts': sendTime.toIso8601String(),
            },
          ),
        );
        when(() => mockBackend.subscribeToMessages(any())).thenAnswer((_) => stream);
        when(() => mockBackend.sendMessage(any(), any())).thenAnswer((_) async => {});

        await service.initialize();
        final latency = await service.measureRealtimeLatency();

        // Should return a latency value (may be null if timeout)
        expect(latency, isA<int?>());
      });

      test('should handle latency measurement timeout', () async {
        when(() => mockBackend.connect()).thenAnswer((_) async => {});
        when(() => mockBackend.joinChannel(any())).thenAnswer((_) async => {});
        when(() => mockBackend.updatePresence(any(), any())).thenAnswer((_) async => {});
        
        final stream = Stream<RealtimeMessage>.empty();
        when(() => mockBackend.subscribeToMessages(any())).thenAnswer((_) => stream);
        when(() => mockBackend.sendMessage(any(), any())).thenAnswer((_) async => {});

        await service.initialize();
        final latency = await service.measureRealtimeLatency(
          timeout: const Duration(milliseconds: 100),
        );

        expect(latency, isNull);
      });
    });
  });
}

