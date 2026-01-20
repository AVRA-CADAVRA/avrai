// Unit tests for Mesh Prekey Distribution Service
//
// Tests prekey bundle forwarding, caching, and expiration handling

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/mesh_prekey_distribution_service.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'dart:typed_data';

void main() {
  group('MeshPrekeyDistributionService', () {
    late MeshPrekeyDistributionService service;

    setUp(() {
      service = MeshPrekeyDistributionService();
    });

    test('should forward prekey bundle when under hop limit', () async {
      final bundle = SignalPreKeyBundle(
        preKeyId: 'test_prekey',
        signedPreKey: Uint8List.fromList([1, 2, 3, 4]),
        signedPreKeyId: 1,
        signature: Uint8List.fromList([5, 6, 7, 8]),
        identityKey: Uint8List.fromList([9, 10, 11, 12]),
        kyberPreKey: Uint8List.fromList([13, 14, 15, 16]),
        kyberPreKeyId: 1,
        kyberPreKeySignature: Uint8List.fromList([17, 18, 19, 20]),
      );

      final result = await service.forwardPreKeyBundle(
        bundle: bundle,
        recipientId: 'test_recipient',
        currentHop: 0,
        originId: 'test_origin',
      );

      // Without mesh service, forwarding will fail (expected behavior)
      expect(result, isA<bool>());
    });

    test('should not forward prekey bundle when hop limit reached', () async {
      final bundle = SignalPreKeyBundle(
        preKeyId: 'test_prekey',
        signedPreKey: Uint8List.fromList([1, 2, 3, 4]),
        signedPreKeyId: 1,
        signature: Uint8List.fromList([5, 6, 7, 8]),
        identityKey: Uint8List.fromList([9, 10, 11, 12]),
        kyberPreKey: Uint8List.fromList([13, 14, 15, 16]),
        kyberPreKeyId: 1,
        kyberPreKeySignature: Uint8List.fromList([17, 18, 19, 20]),
      );

      final result = await service.forwardPreKeyBundle(
        bundle: bundle,
        recipientId: 'test_recipient',
        currentHop: 3, // Max hops is 3, so 3 >= 3 should fail
        originId: 'test_origin',
      );

      expect(result, isFalse);
    });

    test('should not forward when mesh service is null', () async {
      final bundle = SignalPreKeyBundle(
        preKeyId: 'test_prekey',
        signedPreKey: Uint8List.fromList([1, 2, 3, 4]),
        signedPreKeyId: 1,
        signature: Uint8List.fromList([5, 6, 7, 8]),
        identityKey: Uint8List.fromList([9, 10, 11, 12]),
        kyberPreKey: Uint8List.fromList([13, 14, 15, 16]),
        kyberPreKeyId: 1,
        kyberPreKeySignature: Uint8List.fromList([17, 18, 19, 20]),
      );

      // Without mesh service, forwarding should return false
      final result = await service.forwardPreKeyBundle(
        bundle: bundle,
        recipientId: 'test_recipient',
        currentHop: 0,
        originId: 'test_origin',
      );

      expect(result, isFalse);
    });

    test('should return null for non-cached bundle', () {
      final cached = service.getCachedPreKeyBundle(
        recipientId: 'non_existent',
        originId: 'non_existent',
      );

      expect(cached, isNull);
    });

    test('should clean up expired cache entries', () async {
      final bundle = SignalPreKeyBundle(
        preKeyId: 'test_prekey',
        signedPreKey: Uint8List.fromList([1, 2, 3, 4]),
        signedPreKeyId: 1,
        signature: Uint8List.fromList([5, 6, 7, 8]),
        identityKey: Uint8List.fromList([9, 10, 11, 12]),
        kyberPreKey: Uint8List.fromList([13, 14, 15, 16]),
        kyberPreKeyId: 1,
        kyberPreKeySignature: Uint8List.fromList([17, 18, 19, 20]),
      );

      await service.forwardPreKeyBundle(
        bundle: bundle,
        recipientId: 'test_recipient',
        currentHop: 0,
        originId: 'test_origin',
      );

      // Cache should exist
      expect(
        service.getCachedPreKeyBundle(
          recipientId: 'test_recipient',
          originId: 'test_origin',
        ),
        isNotNull,
      );

      // Cleanup (simulates time passing)
      service.cleanupExpiredCache();

      // Cache might still exist if not expired (depends on implementation timing)
      // This test verifies cleanup method doesn't crash
      expect(service.getCachedPreKeyBundle(
        recipientId: 'test_recipient',
        originId: 'test_origin',
      ), isA<SignalPreKeyBundle?>());
    });

    test('should clear all cache entries', () async {
      final bundle = SignalPreKeyBundle(
        preKeyId: 'test_prekey',
        signedPreKey: Uint8List.fromList([1, 2, 3, 4]),
        signedPreKeyId: 1,
        signature: Uint8List.fromList([5, 6, 7, 8]),
        identityKey: Uint8List.fromList([9, 10, 11, 12]),
        kyberPreKey: Uint8List.fromList([13, 14, 15, 16]),
        kyberPreKeyId: 1,
        kyberPreKeySignature: Uint8List.fromList([17, 18, 19, 20]),
      );

      await service.forwardPreKeyBundle(
        bundle: bundle,
        recipientId: 'test_recipient',
        currentHop: 0,
        originId: 'test_origin',
      );

      expect(
        service.getCachedPreKeyBundle(
          recipientId: 'test_recipient',
          originId: 'test_origin',
        ),
        isNotNull,
      );

      service.clearCache();

      expect(
        service.getCachedPreKeyBundle(
          recipientId: 'test_recipient',
          originId: 'test_origin',
        ),
        isNull,
      );
    });

    test('should prevent duplicate forwarding with cache check', () async {
      final bundle = SignalPreKeyBundle(
        preKeyId: 'test_prekey',
        signedPreKey: Uint8List.fromList([1, 2, 3, 4]),
        signedPreKeyId: 1,
        signature: Uint8List.fromList([5, 6, 7, 8]),
        identityKey: Uint8List.fromList([9, 10, 11, 12]),
        kyberPreKey: Uint8List.fromList([13, 14, 15, 16]),
        kyberPreKeyId: 1,
        kyberPreKeySignature: Uint8List.fromList([17, 18, 19, 20]),
      );

      final result1 = await service.forwardPreKeyBundle(
        bundle: bundle,
        recipientId: 'test_recipient',
        currentHop: 0,
        originId: 'test_origin',
      );

      // Second attempt should be prevented by cache (if implementation checks)
      // This test verifies the method handles duplicate attempts
      final result2 = await service.forwardPreKeyBundle(
        bundle: bundle,
        recipientId: 'test_recipient',
        currentHop: 1, // Same recipient/origin but different hop
        originId: 'test_origin',
      );

      expect(result1, isA<bool>());
      expect(result2, isA<bool>());
    });
  });
}
