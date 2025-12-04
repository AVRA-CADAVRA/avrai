import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai2ai/anonymous_communication.dart';

void main() {
  group('AnonymousCommunicationProtocol - Enhanced Validation', () {
    late AnonymousCommunicationProtocol protocol;

    setUp(() {
      protocol = AnonymousCommunicationProtocol();
    });

    test('should block payload with userId', () async {
      final payload = {
        'userId': 'user-123',
        'data': 'some data',
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should block payload with email', () async {
      final payload = {
        'email': 'user@example.com',
        'data': 'some data',
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should block payload with email pattern in string', () async {
      final payload = {
        'message': 'Contact me at user@example.com',
        'data': 'some data',
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should block payload with phone number pattern', () async {
      final payload = {
        'contact': '(555) 123-4567',
        'data': 'some data',
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should block payload with SSN pattern', () async {
      final payload = {
        'identifier': '123-45-6789',
        'data': 'some data',
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should block nested forbidden keys', () async {
      final payload = {
        'user': {
          'profile': {
            'email': 'user@example.com',
          },
        },
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should block forbidden keys in arrays', () async {
      final payload = {
        'users': [
          {'userId': 'user-1'},
          {'userId': 'user-2'},
        ],
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('should allow valid anonymous payload', () async {
      final payload = {
        'agentId': 'agent-123',
        'personalityDimensions': {
          'exploration': 0.5,
          'social': 0.7,
        },
        'preferences': {
          'food': 'vegetarian',
        },
      };

      // Should not throw
      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          payload,
        ),
        returnsNormally,
      );
    });
  });
}
