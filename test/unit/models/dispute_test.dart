import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/dispute.dart';
import 'package:spots/core/models/dispute_type.dart';
import 'package:spots/core/models/dispute_status.dart';

/// SPOTS Dispute Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test Dispute model functionality
/// 
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Status Checks: Active, resolved, closed
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
/// - DisputeMessage: Message handling
/// 
/// Dependencies:
/// - DisputeType: Dispute type enum
/// - DisputeStatus: Dispute status enum
/// - DisputeMessage: Message model

void main() {
  group('Dispute', () {
    late Dispute dispute;
    late DateTime testDate;
    late DisputeMessage testMessage;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      testMessage = DisputeMessage(
        senderId: 'user-789',
        message: 'I did not receive my refund',
        timestamp: testDate,
      );
      
      dispute = Dispute(
        id: 'dispute-123',
        eventId: 'event-456',
        reporterId: 'user-789',
        reportedId: 'user-012',
        type: DisputeType.payment,
        description: 'Refund amount incorrect',
        evidenceUrls: ['evidence1.jpg', 'evidence2.jpg'],
        createdAt: testDate,
        status: DisputeStatus.pending,
        messages: [testMessage],
      );
    });

    group('Constructor and Properties', () {
      test('should create dispute with all required fields', () {
        expect(dispute.id, 'dispute-123');
        expect(dispute.eventId, 'event-456');
        expect(dispute.reporterId, 'user-789');
        expect(dispute.reportedId, 'user-012');
        expect(dispute.type, DisputeType.payment);
        expect(dispute.description, 'Refund amount incorrect');
        expect(dispute.evidenceUrls.length, 2);
        expect(dispute.status, DisputeStatus.pending);
        expect(dispute.messages.length, 1);
      });

      test('should create dispute with default values', () {
        final minimalDispute = Dispute(
          id: 'dispute-1',
          eventId: 'event-1',
          reporterId: 'user-1',
          reportedId: 'user-2',
          type: DisputeType.cancellation,
          description: 'Test dispute',
          createdAt: testDate,
        );

        expect(minimalDispute.evidenceUrls, isEmpty);
        expect(minimalDispute.status, DisputeStatus.pending);
        expect(minimalDispute.assignedAdminId, isNull);
        expect(minimalDispute.resolvedAt, isNull);
        expect(minimalDispute.resolution, isNull);
        expect(minimalDispute.messages, isEmpty);
        expect(minimalDispute.metadata, isEmpty);
      });
    });

    group('Status Checks', () {
      test('should identify active disputes', () {
        expect(dispute.status.isActive, true);
        expect(dispute.isInProgress, true);
      });

      test('should identify resolved disputes', () {
        final resolved = dispute.copyWith(
          status: DisputeStatus.resolved,
          resolvedAt: testDate.add(const Duration(hours: 1)),
          resolution: 'Refund processed',
        );
        expect(resolved.status.isResolved, true);
        expect(resolved.status.isTerminal, true);
        expect(resolved.isResolved, true);
      });

      test('should identify closed disputes', () {
        final closed = dispute.copyWith(
          status: DisputeStatus.closed,
        );
        expect(closed.status.isClosed, true);
        expect(closed.status.isTerminal, true);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = dispute.toJson();

        expect(json['id'], 'dispute-123');
        expect(json['eventId'], 'event-456');
        expect(json['reporterId'], 'user-789');
        expect(json['reportedId'], 'user-012');
        expect(json['type'], 'payment');
        expect(json['description'], 'Refund amount incorrect');
        expect(json['evidenceUrls'], ['evidence1.jpg', 'evidence2.jpg']);
        expect(json['status'], 'pending');
        expect(json['messages'], isA<List>());
      });

      test('should deserialize from JSON correctly', () {
        final json = dispute.toJson();
        final deserialized = Dispute.fromJson(json);

        expect(deserialized.id, dispute.id);
        expect(deserialized.eventId, dispute.eventId);
        expect(deserialized.reporterId, dispute.reporterId);
        expect(deserialized.reportedId, dispute.reportedId);
        expect(deserialized.type, dispute.type);
        expect(deserialized.description, dispute.description);
        expect(deserialized.status, dispute.status);
      });

      test('should handle null optional fields in JSON', () {
        final minimalDispute = Dispute(
          id: 'dispute-1',
          eventId: 'event-1',
          reporterId: 'user-1',
          reportedId: 'user-2',
          type: DisputeType.cancellation,
          description: 'Test',
          createdAt: testDate,
        );
        final json = minimalDispute.toJson();
        final deserialized = Dispute.fromJson(json);

        expect(deserialized.assignedAdminId, isNull);
        expect(deserialized.resolvedAt, isNull);
        expect(deserialized.resolution, isNull);
        expect(deserialized.refundAmount, isNull);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final dispute2 = dispute.copyWith();
        expect(dispute, equals(dispute2));
      });

      test('should not be equal when properties differ', () {
        final dispute2 = dispute.copyWith(
          status: DisputeStatus.resolved,
        );
        expect(dispute, isNot(equals(dispute2)));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final updated = dispute.copyWith(
          status: DisputeStatus.inReview,
          assignedAdminId: 'admin-1',
          assignedAt: testDate.add(const Duration(hours: 1)),
        );

        expect(updated.status, DisputeStatus.inReview);
        expect(updated.assignedAdminId, 'admin-1');
        expect(updated.assignedAt, isNotNull);
        expect(updated.id, dispute.id); // Unchanged
      });

      test('should preserve all fields when copying', () {
        final copied = dispute.copyWith();
        expect(copied, equals(dispute));
      });
    });
  });

  group('DisputeMessage', () {
    late DisputeMessage message;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      message = DisputeMessage(
        senderId: 'user-789',
        message: 'I have a concern about the refund',
        timestamp: testDate,
      );
    });

    group('Constructor and Properties', () {
      test('should create message with all required fields', () {
        expect(message.senderId, 'user-789');
        expect(message.message, 'I have a concern about the refund');
        expect(message.timestamp, testDate);
        expect(message.isAdminMessage, false);
      });

      test('should create message with attachments', () {
        final messageWithAttachments = DisputeMessage(
          senderId: 'user-789',
          message: 'See attached evidence',
          timestamp: testDate,
          attachments: ['receipt.pdf', 'screenshot.jpg'],
        );

        expect(messageWithAttachments.attachments, isNotNull);
        expect(messageWithAttachments.attachments?.length, 2);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = message.toJson();

        expect(json['senderId'], 'user-789');
        expect(json['message'], 'I have a concern about the refund');
        expect(json['isAdminMessage'], false);
      });

      test('should deserialize from JSON correctly', () {
        final json = message.toJson();
        final deserialized = DisputeMessage.fromJson(json);

        expect(deserialized.senderId, message.senderId);
        expect(deserialized.message, message.message);
        expect(deserialized.timestamp, message.timestamp);
        expect(deserialized.isAdminMessage, message.isAdminMessage);
      });
    });
  });
}

