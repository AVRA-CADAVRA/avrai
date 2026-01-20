// Unit tests for AI Agent Fingerprint Service
//
// Tests fingerprint generation, formatting, and QR code functionality

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/crypto/signal/ai_agent_fingerprint_service.dart';
import 'dart:typed_data';

void main() {
  group('AIAgentFingerprintService', () {
    test('should generate fingerprint from identity key', () {
      // Generate test identity key (32 bytes)
      final identityKey = Uint8List.fromList(List.generate(32, (i) => i));

      final fingerprint = AIAgentFingerprintService.generateFingerprint(identityKey);

      expect(fingerprint.fingerprintBytes.length, 32);
      expect(fingerprint.hexString.length, 64); // SHA-256 hex string
      expect(fingerprint.hexString, isA<String>());
    });

    test('should throw ArgumentError for empty identity key', () {
      expect(
        () => AIAgentFingerprintService.generateFingerprint(Uint8List(0)),
        throwsArgumentError,
      );
    });

    test('should generate consistent fingerprints for same key', () {
      final identityKey = Uint8List.fromList(List.generate(32, (i) => i));

      final fingerprint1 = AIAgentFingerprintService.generateFingerprint(identityKey);
      final fingerprint2 = AIAgentFingerprintService.generateFingerprint(identityKey);

      expect(fingerprint1.hexString, fingerprint2.hexString);
      expect(fingerprint1.fingerprintBytes, fingerprint2.fingerprintBytes);
    });

    test('should generate different fingerprints for different keys', () {
      final key1 = Uint8List.fromList(List.generate(32, (i) => i));
      final key2 = Uint8List.fromList(List.generate(32, (i) => i + 1));

      final fingerprint1 = AIAgentFingerprintService.generateFingerprint(key1);
      final fingerprint2 = AIAgentFingerprintService.generateFingerprint(key2);

      expect(fingerprint1.hexString, isNot(fingerprint2.hexString));
    });

    test('should format fingerprint for display correctly', () {
      // Generate real fingerprint from test key
      final identityKey = Uint8List.fromList(List.generate(32, (i) => i));
      final fingerprint = AIAgentFingerprintService.generateFingerprint(identityKey);

      final formatted = AIAgentFingerprintService.formatForDisplay(fingerprint);

      expect(formatted, contains(' ')); // Should have spaces
      expect(formatted.length, greaterThan(fingerprint.hexString.length)); // Formatted should be longer due to spaces
      expect(formatted.toUpperCase(), formatted); // Should be uppercase
    });

    test('should format fingerprint for QR code correctly', () {
      final identityKey = Uint8List.fromList(List.generate(32, (i) => i));
      final fingerprint = AIAgentFingerprintService.generateFingerprint(identityKey);

      final qrCode = AIAgentFingerprintService.formatForQRCode(fingerprint);

      expect(qrCode, startsWith('AI2AI:FINGERPRINT:'));
      expect(qrCode, contains(fingerprint.hexString));
    });

    test('should parse fingerprint from QR code correctly', () {
      final identityKey = Uint8List.fromList(List.generate(32, (i) => i));
      final originalFingerprint = AIAgentFingerprintService.generateFingerprint(identityKey);
      final qrCode = AIAgentFingerprintService.formatForQRCode(originalFingerprint);

      final fingerprint = AIAgentFingerprintService.parseFromQRCode(qrCode);

      expect(fingerprint, isNotNull);
      expect(fingerprint!.hexString, originalFingerprint.hexString);
      expect(fingerprint.fingerprintBytes.length, 32);
    });

    test('should return null for invalid QR code format', () {
      expect(
        AIAgentFingerprintService.parseFromQRCode('invalid_format'),
        isNull,
      );
      expect(
        AIAgentFingerprintService.parseFromQRCode('AI2AI:INVALID:data'),
        isNull,
      );
    });

    test('should return null for QR code with invalid hex length', () {
      expect(
        AIAgentFingerprintService.parseFromQRCode('AI2AI:FINGERPRINT:short'),
        isNull,
      );
    });

    test('should compare fingerprints correctly', () {
      final identityKey = Uint8List.fromList(List.generate(32, (i) => i));
      final fingerprint1 = AIAgentFingerprintService.generateFingerprint(identityKey);
      final fingerprint2 = AIAgentFingerprintService.generateFingerprint(identityKey);
      final fingerprint3 = AIAgentFingerprintService.generateFingerprint(
        Uint8List.fromList(List.generate(32, (i) => i + 1)),
      );

      expect(
        AIAgentFingerprintService.compareFingerprints(fingerprint1, fingerprint2),
        isTrue,
      );
      expect(
        AIAgentFingerprintService.compareFingerprints(fingerprint1, fingerprint3),
        isFalse,
      );
    });

    test('should handle round-trip QR code encoding/decoding', () {
      final identityKey = Uint8List.fromList(List.generate(32, (i) => i));
      final originalFingerprint = AIAgentFingerprintService.generateFingerprint(identityKey);

      final qrCode = AIAgentFingerprintService.formatForQRCode(originalFingerprint);
      final parsedFingerprint = AIAgentFingerprintService.parseFromQRCode(qrCode);

      expect(parsedFingerprint, isNotNull);
      expect(
        AIAgentFingerprintService.compareFingerprints(
          originalFingerprint,
          parsedFingerprint!,
        ),
        isTrue,
      );
    });
  });

  group('AgentFingerprint', () {
    test('should create fingerprint with valid data', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final hexString = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      final fingerprint = AgentFingerprint(
        fingerprintBytes: bytes,
        hexString: hexString,
      );

      expect(fingerprint.fingerprintBytes, bytes);
      expect(fingerprint.hexString, hexString);
    });

    test('should throw ArgumentError for invalid fingerprint bytes length', () {
      expect(
        () => AgentFingerprint(
          fingerprintBytes: Uint8List(31),
          hexString: 'a' * 64,
        ),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError for invalid hex string length', () {
      expect(
        () => AgentFingerprint(
          fingerprintBytes: Uint8List(32),
          hexString: 'short',
        ),
        throwsArgumentError,
      );
    });

    test('should serialize and deserialize to JSON correctly', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final hexString = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      final fingerprint = AgentFingerprint(
        fingerprintBytes: bytes,
        hexString: hexString,
      );

      final json = fingerprint.toJson();
      final restored = AgentFingerprint.fromJson(json);

      expect(restored.fingerprintBytes, fingerprint.fingerprintBytes);
      expect(restored.hexString, fingerprint.hexString);
    });

    test('should provide display format and QR code format', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final hexString = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      final fingerprint = AgentFingerprint(
        fingerprintBytes: bytes,
        hexString: hexString,
      );

      expect(fingerprint.displayFormat, isA<String>());
      expect(fingerprint.qrCodeFormat, startsWith('AI2AI:FINGERPRINT:'));
    });

    test('should compare fingerprints for equality correctly', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final hexString = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      final fingerprint1 = AgentFingerprint(
        fingerprintBytes: bytes,
        hexString: hexString,
      );
      final fingerprint2 = AgentFingerprint(
        fingerprintBytes: bytes,
        hexString: hexString,
      );

      expect(fingerprint1, fingerprint2);
      expect(fingerprint1.hashCode, fingerprint2.hashCode);
    });
  });
}
