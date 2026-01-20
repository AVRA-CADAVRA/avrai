// Unit tests for Deniability Flags in Binary Packet Codec
//
// Tests encoding and decoding of deniability flags in binary packets

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_network/network/binary_packet_codec.dart';
import 'package:avrai_network/network/ai2ai_protocol.dart';
import 'dart:typed_data';

void main() {
  group('Binary Packet Codec - Deniability Flags', () {
    test('should encode deniability flag in binary packet', () {
      final message = ProtocolMessage(
        version: '2.0',
        type: MessageType.learningInsight,
        senderId: 'test_sender',
        recipientId: null,
        timestamp: DateTime.now(),
        payload: {'test': 'data'},
      );

      final encryptedPayload = Uint8List.fromList([1, 2, 3, 4, 5]);

      final packet = BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encryptedPayload,
        isDeniable: true, // Phase 4.2: Deniability flag
      );

      // Decode and verify flag
      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.isDeniable, isTrue);
    });

    test('should not set deniability flag when false', () {
      final message = ProtocolMessage(
        version: '2.0',
        type: MessageType.heartbeat,
        senderId: 'test_sender',
        recipientId: null,
        timestamp: DateTime.now(),
        payload: {'test': 'data'},
      );

      final encryptedPayload = Uint8List.fromList([1, 2, 3, 4, 5]);

      final packet = BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encryptedPayload,
        isDeniable: false,
      );

      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.isDeniable, isFalse);
    });

    test('should default deniability flag to false', () {
      final message = ProtocolMessage(
        version: '2.0',
        type: MessageType.heartbeat,
        senderId: 'test_sender',
        recipientId: null,
        timestamp: DateTime.now(),
        payload: {'test': 'data'},
      );

      final encryptedPayload = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Encode without specifying isDeniable (should default to false)
      final packet = BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encryptedPayload,
      );

      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.isDeniable, isFalse);
    });

    test('should handle round-trip encoding/decoding with deniability flag', () {
      final message = ProtocolMessage(
        version: '2.0',
        type: MessageType.learningExchange,
        senderId: 'test_sender',
        recipientId: 'test_recipient',
        timestamp: DateTime(2020, 1, 1, 12, 0, 0),
        payload: {'insight': 'test'},
      );

      final encryptedPayload = Uint8List.fromList(List.generate(100, (i) => i % 256));

      final packet = BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encryptedPayload,
        isDeniable: true,
        requiresAck: false,
      );

      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.isDeniable, isTrue);
      expect(decoded.message.type, MessageType.learningExchange);
      expect(decoded.encryptedPayload.length, encryptedPayload.length);
    });

    test('should set deniability flag for learning insight messages', () {
      // This tests the integration in ai2ai_protocol.dart
      // Learning insights should be marked as deniable
      final message = ProtocolMessage(
        version: '2.0',
        type: MessageType.learningInsight,
        senderId: 'test_sender',
        recipientId: null,
        timestamp: DateTime.now(),
        payload: {'insight': 'data'},
      );

      final encryptedPayload = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Simulate what ai2ai_protocol.dart does: mark learning insights as deniable
      final isDeniable = message.type == MessageType.learningInsight ||
          message.type == MessageType.learningExchange;

      expect(isDeniable, isTrue);

      final packet = BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encryptedPayload,
        isDeniable: isDeniable,
      );

      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.isDeniable, isTrue);
      expect(decoded.message.type, MessageType.learningInsight);
    });

    test('should not set deniability flag for non-learning messages', () {
      final message = ProtocolMessage(
        version: '2.0',
        type: MessageType.heartbeat,
        senderId: 'test_sender',
        recipientId: null,
        timestamp: DateTime.now(),
        payload: {'data': 'test'},
      );

      final encryptedPayload = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Non-learning messages should not be deniable
      final isDeniable = message.type == MessageType.learningInsight ||
          message.type == MessageType.learningExchange;

      expect(isDeniable, isFalse);

      final packet = BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encryptedPayload,
        isDeniable: isDeniable,
      );

      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.isDeniable, isFalse);
    });

    test('should preserve all flags when deniability flag is set', () {
      final message = ProtocolMessage(
        version: '2.0',
        type: MessageType.learningInsight,
        senderId: 'test_sender',
        recipientId: 'test_recipient',
        timestamp: DateTime.now(),
        payload: {'data': 'test'},
      );

      final encryptedPayload = Uint8List.fromList([1, 2, 3, 4, 5]);

      final packet = BinaryPacketCodec.encode(
        message: message,
        encryptedPayload: encryptedPayload,
        requiresAck: true,
        isDeniable: true,
      );

      final decoded = BinaryPacketCodec.decode(packet);

      expect(decoded.isDeniable, isTrue);
      expect(decoded.requiresAck, isTrue);
      // Note: senderId and recipientId are hashed/truncated in binary format
      // The decoded message will have hashed IDs (not original strings)
      expect(decoded.message.senderId, isA<String>());
      expect(decoded.message.senderId.length, 16); // 8 bytes = 16 hex chars
      expect(decoded.message.type, MessageType.learningInsight);
    });
  });
}
