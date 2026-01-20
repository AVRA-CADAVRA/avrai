// Friend QR Service Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/friend_qr_service.dart';

void main() {
  group('FriendQRService', () {
    test('should generate QR code data with correct format', () {
      const agentId = 'agent_test123456789';
      final qrData = FriendQRService.generateFriendQRCodeData(agentId);

      expect(qrData, startsWith('SPOTS:FRIEND:CONNECT:'));
      expect(qrData, contains(agentId));
      expect(qrData.split(':').length, greaterThan(4)); // Should have agentId and timestamp
    });

    test('should parse valid QR code data', () {
      const agentId = 'agent_test123456789';
      final qrData = FriendQRService.generateFriendQRCodeData(agentId);
      final parsed = FriendQRService.parseFriendQRCodeData(qrData);

      expect(parsed, isNotNull);
      expect(parsed!.agentId, equals(agentId));
      expect(parsed.timestamp, isA<DateTime>());
    });

    test('should return null for invalid QR code format', () {
      final parsed = FriendQRService.parseFriendQRCodeData('INVALID:FORMAT');
      expect(parsed, isNull);
    });

    test('should return null for QR code without prefix', () {
      final parsed = FriendQRService.parseFriendQRCodeData('SOME:OTHER:FORMAT');
      expect(parsed, isNull);
    });

    test('should return null for QR code with invalid agentId format', () {
      final parsed = FriendQRService.parseFriendQRCodeData(
        'SPOTS:FRIEND:CONNECT:invalid_agent_id:1234567890',
      );
      expect(parsed, isNull);
    });

    test('should validate QR code signature', () {
      const agentId = 'agent_test123456789';
      final qrData = FriendQRService.generateFriendQRCodeData(agentId);
      final isValid = FriendQRService.validateQRCodeSignature(qrData);

      expect(isValid, isTrue);
    });

    test('should return false for invalid QR code signature', () {
      final isValid = FriendQRService.validateQRCodeSignature('INVALID:FORMAT');
      expect(isValid, isFalse);
    });

    group('FriendQRData', () {
      test('should detect expired QR codes (older than 24 hours)', () {
        final oldTimestamp = DateTime.now().subtract(const Duration(hours: 25));
        final data = FriendQRData(
          agentId: 'agent_test123456789',
          timestamp: oldTimestamp,
        );

        expect(data.isExpired, isTrue);
      });

      test('should not detect non-expired QR codes', () {
        final recentTimestamp = DateTime.now().subtract(const Duration(hours: 1));
        final data = FriendQRData(
          agentId: 'agent_test123456789',
          timestamp: recentTimestamp,
        );

        expect(data.isExpired, isFalse);
      });

      test('should calculate age in minutes correctly', () {
        final timestamp = DateTime.now().subtract(const Duration(minutes: 30));
        final data = FriendQRData(
          agentId: 'agent_test123456789',
          timestamp: timestamp,
        );

        expect(data.ageInMinutes, greaterThanOrEqualTo(29));
        expect(data.ageInMinutes, lessThanOrEqualTo(31));
      });
    });
  });
}
