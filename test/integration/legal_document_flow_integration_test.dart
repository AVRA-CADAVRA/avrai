import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/user_agreement.dart';
import 'package:spots/core/legal/terms_of_service.dart';
import 'package:spots/core/legal/event_waiver.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for legal document flow
/// 
/// Tests model relationships and data flow for:
/// 1. Terms acceptance → Agreement tracking
/// 2. Event waiver → Acceptance tracking
void main() {
  group('Legal Document Flow Integration Tests', () {
    late ExpertiseEvent testEvent;

    setUp(() {
      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Workshop',
        description: 'Learn about coffee',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('terms of service agreement creates user agreement', () {
      final agreement = UserAgreement(
        id: 'agreement-123',
        userId: 'user-456',
        documentType: 'terms_of_service',
        version: TermsOfService.version,
        agreedAt: DateTime.now(),
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0...',
        updatedAt: DateTime.now(),
      );

      expect(agreement.userId, equals('user-456'));
      expect(agreement.documentType, equals('terms_of_service'));
      expect(agreement.version, equals(TermsOfService.version));
      expect(agreement.isTermsOfService, isTrue);
      expect(agreement.isActive, isTrue);
      expect(agreement.isRevoked, isFalse);
    });

    test('privacy policy agreement creates user agreement', () {
      final agreement = UserAgreement(
        id: 'agreement-456',
        userId: 'user-789',
        documentType: 'privacy_policy',
        version: '1.0.0',
        agreedAt: DateTime.now(),
        ipAddress: '192.168.1.2',
        updatedAt: DateTime.now(),
      );

      expect(agreement.isPrivacyPolicy, isTrue);
      expect(agreement.isEventWaiver, isFalse);
    });

    test('event waiver agreement creates user agreement', () {
      final agreement = UserAgreement(
        id: 'agreement-789',
        userId: 'user-012',
        documentType: 'event_waiver',
        version: '1.0.0',
        eventId: testEvent.id,
        agreedAt: DateTime.now(),
        ipAddress: '192.168.1.3',
        updatedAt: DateTime.now(),
      );

      expect(agreement.isEventWaiver, isTrue);
      expect(agreement.eventId, equals(testEvent.id));
      expect(agreement.documentType, equals('event_waiver'));
    });

    test('event waiver generation for high-risk event', () {
      final highRiskEvent = testEvent.copyWith(
        eventType: ExpertiseEventType.tour,
        maxAttendees: 100,
      );

      final requiresFull = EventWaiver.requiresFullWaiver(highRiskEvent);
      final waiverType = EventWaiver.getWaiverType(highRiskEvent);

      expect(requiresFull, isTrue);
      expect(waiverType, equals('full'));

      final waiver = EventWaiver.generateWaiver(highRiskEvent);
      expect(waiver, contains(highRiskEvent.title));
      expect(waiver, contains('WAIVER AND RELEASE'));
      expect(waiver, contains('risks'));
    });

    test('event waiver generation for low-risk event', () {
      final lowRiskEvent = testEvent.copyWith(
        eventType: ExpertiseEventType.workshop,
        maxAttendees: 20,
      );

      final requiresFull = EventWaiver.requiresFullWaiver(lowRiskEvent);
      final waiverType = EventWaiver.getWaiverType(lowRiskEvent);

      expect(requiresFull, isFalse);
      expect(waiverType, equals('simplified'));

      final waiver = EventWaiver.generateSimplifiedWaiver(lowRiskEvent);
      expect(waiver, contains(lowRiskEvent.title));
      expect(waiver, contains('ACKNOWLEDGMENT'));
    });

    test('terms of service version tracking', () {
      final currentVersion = TermsOfService.version;
      final effectiveDate = TermsOfService.effectiveDate;

      expect(currentVersion, equals('1.0.0'));
      expect(effectiveDate, isA<DateTime>());

      final isCurrent = TermsOfService.isCurrentVersion('1.0.0');
      expect(isCurrent, isTrue);

      final isNotCurrent = TermsOfService.isCurrentVersion('0.9.0');
      expect(isNotCurrent, isFalse);
    });

    test('user agreement revocation', () {
      final agreement = UserAgreement(
        id: 'agreement-123',
        userId: 'user-456',
        documentType: 'terms_of_service',
        version: '1.0.0',
        agreedAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      expect(agreement.isActive, isTrue);
      expect(agreement.isRevoked, isFalse);

      final revoked = agreement.copyWith(
        isActive: false,
        revokedAt: DateTime.now(),
        revocationReason: 'User requested account deletion',
        updatedAt: DateTime.now(),
      );

      expect(revoked.isActive, isFalse);
      expect(revoked.isRevoked, isTrue);
      expect(revoked.revocationReason, isNotNull);
    });

    test('multiple agreements for same user', () {
      final termsAgreement = UserAgreement(
        id: 'a1',
        userId: 'user-123',
        documentType: 'terms_of_service',
        version: '1.0.0',
        agreedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final privacyAgreement = UserAgreement(
        id: 'a2',
        userId: 'user-123',
        documentType: 'privacy_policy',
        version: '1.0.0',
        agreedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final allAgreements = [termsAgreement, privacyAgreement];
      final userAgreements = allAgreements
          .where((a) => a.userId == 'user-123')
          .toList();

      expect(userAgreements.length, equals(2));
      expect(userAgreements.any((a) => a.isTermsOfService), isTrue);
      expect(userAgreements.any((a) => a.isPrivacyPolicy), isTrue);
    });

    test('event waiver agreement with event details', () {
      final waiver = EventWaiver.generateWaiver(testEvent);
      final agreement = UserAgreement(
        id: 'waiver-123',
        userId: 'attendee-456',
        documentType: 'event_waiver',
        version: '1.0.0',
        eventId: testEvent.id,
        agreedAt: DateTime.now(),
        ipAddress: '192.168.1.1',
        updatedAt: DateTime.now(),
      );

      expect(waiver, contains(testEvent.title));
      expect(agreement.eventId, equals(testEvent.id));
      expect(agreement.isEventWaiver, isTrue);
    });
  });
}

