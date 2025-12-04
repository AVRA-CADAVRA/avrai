import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/dispute_resolution_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/refund_service.dart';
import 'package:spots/core/models/dispute.dart';
import 'package:spots/core/models/dispute_type.dart';
import 'package:spots/core/models/dispute_status.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';

import 'dispute_resolution_service_test.mocks.dart';

@GenerateMocks([
  ExpertiseEventService,
  RefundService,
])
void main() {
  group('DisputeResolutionService', () {
    late DisputeResolutionService service;
    late MockExpertiseEventService mockEventService;
    late MockRefundService mockRefundService;
    
    late ExpertiseEvent testEvent;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockRefundService = MockRefundService();
      
      service = DisputeResolutionService(
        eventService: mockEventService,
        refundService: mockRefundService,
      );

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

    group('submitDispute', () {
      test('should create dispute successfully', () async {
        // Act
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue',
        );

        // Assert
        expect(dispute, isA<Dispute>());
        expect(dispute.eventId, equals('event-123'));
        expect(dispute.reporterId, equals('user-456'));
        expect(dispute.reportedId, equals('user-789'));
        expect(dispute.type, equals(DisputeType.payment));
        expect(dispute.status, equals(DisputeStatus.pending));
      });

      test('should include evidence URLs if provided', () async {
        // Act
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.event,
          description: 'Event quality issue',
          evidenceUrls: ['https://example.com/evidence1.jpg'],
        );

        // Assert
        expect(dispute.evidenceUrls, hasLength(1));
        expect(dispute.evidenceUrls, contains('https://example.com/evidence1.jpg'));
      });
    });

    group('reviewDispute', () {
      test('should update dispute status to inReview', () async {
        // Arrange
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue',
        );

        // Act
        final reviewed = await service.reviewDispute(
          disputeId: dispute.id,
          adminId: 'admin-123',
        );

        // Assert
        expect(reviewed.status, equals(DisputeStatus.inReview));
        expect(reviewed.assignedAdminId, equals('admin-123'));
        expect(reviewed.assignedAt, isNotNull);
      });
    });

    group('attemptAutomatedResolution', () {
      test('should auto-resolve payment disputes when possible', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Refund disagreement',
        );

        // Act
        final resolved = await service.attemptAutomatedResolution(dispute.id);

        // Assert
        expect(resolved, isNotNull);
        expect(resolved?.status, equals(DisputeStatus.resolved));
        expect(resolved?.resolution, isNotNull);
      });
    });

    group('resolveDispute', () {
      test('should resolve dispute with resolution details', () async {
        // Arrange
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.event,
          description: 'Event quality issue',
        );

        // Act
        final resolved = await service.resolveDispute(
          disputeId: dispute.id,
          adminId: 'admin-123',
          resolution: 'Issue resolved with full refund',
          refundAmount: 25.00,
        );

        // Assert
        expect(resolved.status, equals(DisputeStatus.resolved));
        expect(resolved.resolution, equals('Issue resolved with full refund'));
        expect(resolved.refundAmount, equals(25.00));
        expect(resolved.resolvedAt, isNotNull);
      });
    });

    group('getDispute', () {
      test('should return dispute if exists', () async {
        // Arrange
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue',
        );

        // Act
        final retrieved = await service.getDispute(dispute.id);

        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved?.id, equals(dispute.id));
      });

      test('should return null if dispute not found', () async {
        // Act
        final dispute = await service.getDispute('non-existent');

        // Assert
        expect(dispute, isNull);
      });
    });

    group('getDisputesForEvent', () {
      test('should return all disputes for event', () async {
        // Arrange
        await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue 1',
        );
        await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-999',
          reportedId: 'user-789',
          type: DisputeType.event,
          description: 'Event quality issue',
        );

        // Act
        final disputes = await service.getDisputesForEvent('event-123');

        // Assert
        expect(disputes, hasLength(2));
        expect(disputes.every((d) => d.eventId == 'event-123'), isTrue);
      });
    });
  });
}

