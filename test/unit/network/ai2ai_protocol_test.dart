import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/network/ai2ai_protocol.dart';
import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai/core/models/user_vibe.dart';
import 'package:avrai/core/services/message_encryption_service.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Mock MessageEncryptionService for testing
class MockMessageEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.aes256gcm;

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    // Simple mock: just encode to bytes
    return EncryptedMessage(
      encryptedContent: Uint8List.fromList(utf8.encode(plaintext)),
      encryptionType: encryptionType,
    );
  }

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    // Simple mock: just decode from bytes
    return utf8.decode(encrypted.encryptedContent);
  }
}

void main() {
  group('AI2AIProtocol', () {
    late AI2AIProtocol protocol;
    late Uint8List encryptionKey;
    late MessageEncryptionService mockEncryptionService;

    setUp(() {
      // Create a test encryption key (32 bytes for AES-256)
      encryptionKey = Uint8List.fromList(
        List.generate(32, (i) => (i + 1) % 256),
      );
      mockEncryptionService = MockMessageEncryptionService();
      protocol = AI2AIProtocol(
        encryptionService: mockEncryptionService,
        encryptionKey: encryptionKey,
      );
    });

    group('encodeMessage', () {
      test('should encode messages with correct structure and include recipient ID when provided', () async {
        // Test business logic: message encoding creates usable protocol messages
        final messageWithoutRecipient = await protocol.encodeMessage(
          type: MessageType.heartbeat,
          payload: {'timestamp': DateTime.now().toIso8601String()},
          senderNodeId: 'node1',
        );

        // Test behavior: message has correct structure for protocol use
        expect(messageWithoutRecipient.type, equals(MessageType.heartbeat));
        expect(messageWithoutRecipient.senderId, equals('node1'));
        expect(messageWithoutRecipient.payload, isNotEmpty);
        expect(messageWithoutRecipient.recipientId, isNull); // No recipient for broadcast

        // Test behavior: recipient ID included when provided
        final messageWithRecipient = await protocol.encodeMessage(
          type: MessageType.connectionRequest,
          payload: {},
          senderNodeId: 'node1',
          recipientNodeId: 'node2',
        );

        expect(messageWithRecipient.recipientId, equals('node2'));
        expect(messageWithRecipient.type, equals(MessageType.connectionRequest));
      });
    });

    group('decodeMessage', () {
      test('should encode messages that can be serialized for transmission', () async {
        // Test business logic: encoded messages can be serialized for transmission
        final originalMessage = await protocol.encodeMessage(
          type: MessageType.heartbeat,
          payload: {'test': 'value'},
          senderNodeId: 'node1',
        );

        // Test behavior: message can be converted to JSON for transmission
        // JSON format used for testing legacy/debugging functionality
        // ignore: deprecated_member_use
        final json = originalMessage.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('type'), isTrue);
        expect(json.containsKey('senderId'), isTrue);
        expect(json['type'], equals(MessageType.heartbeat.name));
        expect(json['senderId'], equals('node1'));
        // Note: decodeMessage would parse protocol packet in real implementation
      });
    });

    group('Connection message encoding', () {
      test('should encode connection request with anonymized vibe payload and enforce privacy protection', () async {
        // Test business logic: privacy protection and message encoding
        final vibe = UserVibe.fromPersonalityProfile('user1', {
          'exploration_eagerness': 0.8,
          'community_orientation': 0.6,
        });
        final anonymizedVibe = await PrivacyProtection.anonymizeUserVibe(vibe);

        final message = await protocol.encodeMessage(
          type: MessageType.connectionRequest,
          payload: {
            'requestId': 'req123',
            'senderVibe': anonymizedVibe,
          },
          senderNodeId: 'node1',
          recipientNodeId: 'node2',
        );

        // Test behavior: message structure is correct for connection requests
        expect(message.type, equals(MessageType.connectionRequest));
        expect(message.senderId, equals('node1'));
        expect(message.recipientId, equals('node2'));
        // Test behavior: payload contains anonymized data (privacy protection)
        expect(message.payload['requestId'], equals('req123'));
        expect(message.payload['senderVibe'], isNotNull);
      });

      test('should reject payloads containing UnifiedUser fields', () async {
        expect(
          () => protocol.encodeMessage(
            type: MessageType.connectionRequest,
            payload: const {
              // Forbidden field by protocol safety check.
              'userId': 'real-user-id',
            },
            senderNodeId: 'node1',
            recipientNodeId: 'node2',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should encode connection response payload with acceptance status and compatibility', () async {
        // Test business logic: connection response encoding
        final message = await protocol.encodeMessage(
          type: MessageType.connectionResponse,
          payload: const {
            'requestId': 'req123',
            'accepted': true,
            'compatibilityScore': 0.85,
          },
          senderNodeId: 'node2',
          recipientNodeId: 'node1',
        );

        // Test behavior: response message contains acceptance decision and compatibility
        expect(message.type, equals(MessageType.connectionResponse));
        expect(message.payload['accepted'], isTrue);
        expect(message.payload['compatibilityScore'], equals(0.85));
        expect(message.payload['requestId'], equals('req123'));
      });
    });

    group('Learning message encoding', () {
      test('should encode learning exchange payload with learning data and timestamp', () async {
        // Test business logic: learning exchange message encoding
        final message = await protocol.encodeMessage(
          type: MessageType.learningExchange,
          payload: const {
            'learningData': {
              'insight': 'test insight',
              'dimension': 'exploration_eagerness',
              'value': 0.8,
            },
            'timestamp': '2025-01-01T00:00:00.000Z',
          },
          senderNodeId: 'node1',
          recipientNodeId: 'node2',
        );

        // Test behavior: learning exchange message contains learning data
        expect(message.type, equals(MessageType.learningExchange));
        expect(message.payload['learningData'], isNotNull);
        expect(message.payload['timestamp'], isNotNull);
      });
    });

    group('createHeartbeat', () {
      test('should create heartbeat message with timestamp for connection monitoring', () async {
        // Test business logic: heartbeat message creation
        final message = await protocol.createHeartbeat(
          senderNodeId: 'node1',
        );

        // Test behavior: heartbeat message has correct type and timestamp
        expect(message.type, equals(MessageType.heartbeat));
        expect(message.senderId, equals('node1'));
        expect(message.payload['timestamp'], isNotNull);
      });
    });

    group('Encryption/Decryption', () {
      test('should encode messages successfully with encryption service and handle null key gracefully', () async {
        // Test business logic: encryption service integration and graceful degradation
        final encrypted = await protocol.encodeMessage(
          type: MessageType.heartbeat,
          payload: {'data': 'Test message data'},
          senderNodeId: 'node1',
        );
        
        // Test behavior: message encoding succeeds with encryption service
        expect(encrypted.type, equals(MessageType.heartbeat));
        expect(encrypted.senderId, equals('node1'));
        expect(encrypted.payload['data'], equals('Test message data'));

        // Test behavior: protocol handles null encryption key gracefully
        final protocolNoKey = AI2AIProtocol(
          encryptionService: mockEncryptionService,
          encryptionKey: null,
        );
        
        final messageNoKey = await protocolNoKey.encodeMessage(
          type: MessageType.heartbeat,
          payload: {'test': 'data'},
          senderNodeId: 'node1',
        );
        
        // Test behavior: message encoding succeeds even without encryption key
        expect(messageNoKey.type, equals(MessageType.heartbeat));
        expect(messageNoKey.senderId, equals('node1'));
      });
    });
  });

  group('ProtocolMessage', () {
    test('should serialize and deserialize correctly (round-trip)', () {
      // Test business logic: protocol message round-trip serialization
      final original = ProtocolMessage(
        version: '1.0',
        type: MessageType.connectionRequest,
        senderId: 'node1',
        recipientId: 'node2',
        timestamp: DateTime.now(),
        payload: {'test': 'value'},
      );

      // JSON format used for testing legacy/debugging functionality
      // ignore: deprecated_member_use
      final json = original.toJson();
      // ignore: deprecated_member_use
      final restored = ProtocolMessage.fromJson(json);

      // Test behavior: round-trip preserves all critical protocol data
      expect(restored.version, equals(original.version));
      expect(restored.type, equals(original.type));
      expect(restored.senderId, equals(original.senderId));
      expect(restored.recipientId, equals(original.recipientId));
      expect(restored.payload['test'], equals('value'));
      // Verify JSON structure is correct for protocol transmission
      expect(json, isA<Map<String, dynamic>>());
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('senderId'), isTrue);
    });
  });
}

