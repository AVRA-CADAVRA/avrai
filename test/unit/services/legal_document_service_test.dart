import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/legal_document_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/user_agreement.dart';
import 'package:spots/core/models/unified_user.dart';

import 'legal_document_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService])
void main() {
  group('LegalDocumentService', () {
    late LegalDocumentService service;
    late MockExpertiseEventService mockEventService;
    
    late ExpertiseEvent testEvent;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      service = LegalDocumentService(eventService: mockEventService);

      testEvent = ExpertiseEvent(
        id: 'event-123',
        host: UnifiedUser(
          id: 'host-123',
          name: 'Test Host',
        ),
        title: 'Test Event',
        description: 'Test Description',
        startTime: DateTime.now().add(const Duration(days: 5)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
        maxAttendees: 50,
        attendeeCount: 10,
        eventType: ExpertiseEventType.workshop,
        isPaid: true,
        price: 25.00,
        location: 'Test Location',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('acceptTermsOfService', () {
      test('should create and save Terms of Service agreement', () async {
        // Act
        final agreement = await service.acceptTermsOfService(
          userId: 'user-123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Agent',
        );

        // Assert
        expect(agreement, isA<UserAgreement>());
        expect(agreement.userId, equals('user-123'));
        expect(agreement.documentType, equals('terms_of_service'));
        expect(agreement.version, equals('1.0.0'));
        expect(agreement.isActive, isTrue);
        expect(agreement.ipAddress, equals('192.168.1.1'));
      });

      test('should revoke old Terms of Service agreement when accepting new', () async {
        // Arrange
        await service.acceptTermsOfService(
          userId: 'user-123',
          ipAddress: '192.168.1.1',
        );

        // Act
        await service.acceptTermsOfService(
          userId: 'user-123',
          ipAddress: '192.168.1.2',
        );

        // Assert
        final agreements = await service.getUserAgreements('user-123');
        final activeAgreements = agreements.where((a) => a.isActive).toList();
        expect(activeAgreements.length, equals(1));
        expect(activeAgreements.first.ipAddress, equals('192.168.1.2'));
      });
    });

    group('acceptPrivacyPolicy', () {
      test('should create and save Privacy Policy agreement', () async {
        // Act
        final agreement = await service.acceptPrivacyPolicy(
          userId: 'user-123',
          ipAddress: '192.168.1.1',
        );

        // Assert
        expect(agreement, isA<UserAgreement>());
        expect(agreement.documentType, equals('privacy_policy'));
        expect(agreement.version, equals('1.0.0'));
        expect(agreement.isActive, isTrue);
      });
    });

    group('acceptEventWaiver', () {
      test('should create and save event waiver agreement', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final agreement = await service.acceptEventWaiver(
          userId: 'user-123',
          eventId: 'event-123',
          ipAddress: '192.168.1.1',
        );

        // Assert
        expect(agreement, isA<UserAgreement>());
        expect(agreement.documentType, equals('event_waiver'));
        expect(agreement.eventId, equals('event-123'));
        expect(agreement.isActive, isTrue);
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.acceptEventWaiver(
            userId: 'user-123',
            eventId: 'event-123',
          ),
          throwsException,
        );
      });
    });

    group('hasAcceptedTerms', () {
      test('should return false if user has not accepted Terms', () async {
        // Act
        final hasAccepted = await service.hasAcceptedTerms('user-123');

        // Assert
        expect(hasAccepted, isFalse);
      });

      test('should return true if user has accepted current version', () async {
        // Arrange
        await service.acceptTermsOfService(
          userId: 'user-123',
          ipAddress: '192.168.1.1',
        );

        // Act
        final hasAccepted = await service.hasAcceptedTerms('user-123');

        // Assert
        expect(hasAccepted, isTrue);
      });
    });

    group('hasAcceptedPrivacyPolicy', () {
      test('should return false if user has not accepted Privacy Policy', () async {
        // Act
        final hasAccepted = await service.hasAcceptedPrivacyPolicy('user-123');

        // Assert
        expect(hasAccepted, isFalse);
      });

      test('should return true if user has accepted current version', () async {
        // Arrange
        await service.acceptPrivacyPolicy(
          userId: 'user-123',
          ipAddress: '192.168.1.1',
        );

        // Act
        final hasAccepted = await service.hasAcceptedPrivacyPolicy('user-123');

        // Assert
        expect(hasAccepted, isTrue);
      });
    });

    group('hasAcceptedEventWaiver', () {
      test('should return false if user has not accepted waiver', () async {
        // Act
        final hasAccepted = await service.hasAcceptedEventWaiver('user-123', 'event-123');

        // Assert
        expect(hasAccepted, isFalse);
      });

      test('should return true if user has accepted waiver', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        
        await service.acceptEventWaiver(
          userId: 'user-123',
          eventId: 'event-123',
        );

        // Act
        final hasAccepted = await service.hasAcceptedEventWaiver('user-123', 'event-123');

        // Assert
        expect(hasAccepted, isTrue);
      });
    });

    group('generateEventWaiver', () {
      test('should generate waiver text for event', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final waiver = await service.generateEventWaiver('event-123');

        // Assert
        expect(waiver, isNotEmpty);
        expect(waiver, contains('Test Event'));
        verify(mockEventService.getEventById('event-123')).called(1);
      });
    });

    group('needsTermsUpdate', () {
      test('should return true if user has not accepted Terms', () async {
        // Act
        final needsUpdate = await service.needsTermsUpdate('user-123');

        // Assert
        expect(needsUpdate, isTrue);
      });

      test('should return false if user has accepted current version', () async {
        // Arrange
        await service.acceptTermsOfService(
          userId: 'user-123',
          ipAddress: '192.168.1.1',
        );

        // Act
        final needsUpdate = await service.needsTermsUpdate('user-123');

        // Assert
        expect(needsUpdate, isFalse);
      });
    });

    group('revokeAgreement', () {
      test('should revoke an agreement', () async {
        // Arrange
        final agreement = await service.acceptTermsOfService(
          userId: 'user-123',
          ipAddress: '192.168.1.1',
        );

        // Act
        final revoked = await service.revokeAgreement(
          agreementId: agreement.id,
          reason: 'User requested',
        );

        // Assert
        expect(revoked.isActive, isFalse);
        expect(revoked.revokedAt, isNotNull);
        expect(revoked.revocationReason, equals('User requested'));
      });
    });
  });
}

