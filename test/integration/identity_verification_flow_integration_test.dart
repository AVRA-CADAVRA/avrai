import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/verification_session.dart';
import 'package:spots/core/models/verification_result.dart';

/// Integration tests for identity verification flow
/// 
/// Tests model relationships and data flow for:
/// 1. Verification session creation → Status tracking
/// 2. Verification completion → Result generation
/// 3. Verification status flow
void main() {
  group('Identity Verification Flow Integration Tests', () {
    test('verification session created with pending status', () {
      final session = VerificationSession(
        id: 'session-123',
        userId: 'user-456',
        status: VerificationStatus.pending,
        verificationUrl: 'https://verify.stripe.com/session-123',
        stripeSessionId: 'stripe_session_123',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        metadata: {'verificationType': 'document_and_selfie'},
      );

      expect(session.userId, equals('user-456'));
      expect(session.status, equals(VerificationStatus.pending));
      expect(session.status == VerificationStatus.pending || session.status == VerificationStatus.processing, isTrue);
      expect(session.verificationUrl, isNotNull);
    });

    test('verification status flow: pending → processing → verified', () {
      var session = VerificationSession(
        id: 's1',
        userId: 'u1',
        status: VerificationStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(session.status, equals(VerificationStatus.pending));
      expect(session.status == VerificationStatus.pending || session.status == VerificationStatus.processing, isTrue);

      // Step 1: User starts verification (processing)
      session = session.copyWith(
        status: VerificationStatus.processing,
      );

      expect(session.status, equals(VerificationStatus.processing));
      expect(session.status == VerificationStatus.pending || session.status == VerificationStatus.processing, isTrue);

      // Step 2: Verification completed successfully
      session = session.copyWith(
        status: VerificationStatus.verified,
        completedAt: DateTime.now(),
      );

      expect(session.status, equals(VerificationStatus.verified));
      expect(session.status == VerificationStatus.verified || session.status == VerificationStatus.failed || session.status == VerificationStatus.expired, isTrue);
      expect(session.status == VerificationStatus.verified, isTrue);
    });

    test('verification result generated from session', () {
      final session = VerificationSession(
        id: 'session-123',
        userId: 'user-456',
        status: VerificationStatus.verified,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final result = VerificationResult(
        sessionId: session.id,
        status: session.status,
        verified: true,
        verifiedAt: session.completedAt,
      );

      expect(result.sessionId, equals(session.id));
      expect(result.verified, isTrue);
      expect(result.status == VerificationStatus.verified, isTrue);
    });

    test('verification failure flow', () {
      var session = VerificationSession(
        id: 's1',
        userId: 'u1',
        status: VerificationStatus.pending,
        createdAt: DateTime.now(),
      );

      // Verification fails
      session = session.copyWith(
        status: VerificationStatus.failed,
      );

      expect(session.status, equals(VerificationStatus.failed));
      expect(session.status == VerificationStatus.verified || session.status == VerificationStatus.failed || session.status == VerificationStatus.expired, isTrue);

      final result = VerificationResult(
        sessionId: session.id,
        status: session.status,
        verified: false,
        failureReason: 'Document unreadable',
      );

      expect(result.verified, isFalse);
      expect(result.failureReason, equals('Document unreadable'));
    });

    test('verification expiration', () {
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      final session = VerificationSession(
        id: 's1',
        userId: 'u1',
        status: VerificationStatus.pending,
        createdAt: expiredDate,
        expiresAt: expiredDate,
      );

      // Check if expired manually
      final isExpired = session.expiresAt != null && 
          session.expiresAt!.isBefore(DateTime.now());
      expect(isExpired, isTrue);

      final expiredSession = session.copyWith(
        status: VerificationStatus.expired,
      );

      expect(expiredSession.status, equals(VerificationStatus.expired));
      expect(expiredSession.status == VerificationStatus.verified || expiredSession.status == VerificationStatus.failed || expiredSession.status == VerificationStatus.expired, isTrue);
    });

    test('verification type tracking', () {
      final documentSession = VerificationSession(
        id: 's1',
        userId: 'u1',
        status: VerificationStatus.pending,
        createdAt: DateTime.now(),
        metadata: {'verificationType': 'document'},
      );

      final selfieSession = VerificationSession(
        id: 's2',
        userId: 'u2',
        status: VerificationStatus.pending,
        createdAt: DateTime.now(),
        metadata: {'verificationType': 'selfie'},
      );

      final documentAndSelfieSession = VerificationSession(
        id: 's3',
        userId: 'u3',
        status: VerificationStatus.pending,
        createdAt: DateTime.now(),
        metadata: {'verificationType': 'document_and_selfie'},
      );

      expect(documentSession.metadata['verificationType'], equals('document'));
      expect(selfieSession.metadata['verificationType'], equals('selfie'));
      expect(documentAndSelfieSession.metadata['verificationType'],
          equals('document_and_selfie'));
    });
  });
}
