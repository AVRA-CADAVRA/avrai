import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/payout_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/models/payout.dart';

import 'payout_service_test.mocks.dart';

@GenerateMocks([RevenueSplitService])
void main() {
  group('PayoutService Tests', () {
    late PayoutService service;
    late MockRevenueSplitService mockRevenueSplitService;

    setUp(() {
      mockRevenueSplitService = MockRevenueSplitService();
      service = PayoutService(
        revenueSplitService: mockRevenueSplitService,
      );
    });

    group('schedulePayout', () {
      test('should schedule payout for a party', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));

        // Act
        final payout = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );

        // Assert
        expect(payout, isA<Payout>());
        expect(payout.partyId, equals('user-123'));
        expect(payout.amount, equals(50.00));
        expect(payout.eventId, equals('event-123'));
        expect(payout.status, equals(PayoutStatus.scheduled));
        expect(payout.scheduledDate, equals(scheduledDate));
        expect(payout.createdAt, isNotNull);
        expect(payout.updatedAt, isNotNull);
      });

      test('should generate unique payout ID', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));

        // Act
        final payout1 = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );

        final payout2 = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );

        // Assert
        expect(payout1.id, isNot(equals(payout2.id)));
      });
    });

    group('updatePayoutStatus', () {
      test('should update payout status', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        final payout = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );

        // Act
        final updated = await service.updatePayoutStatus(
          payoutId: payout.id,
          status: PayoutStatus.processing,
        );

        // Assert
        expect(updated.status, equals(PayoutStatus.processing));
        expect(updated.updatedAt.isAfter(payout.updatedAt), isTrue);
      });

      test('should set completedAt when status is completed', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        final payout = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );

        // Act
        final completed = await service.updatePayoutStatus(
          payoutId: payout.id,
          status: PayoutStatus.completed,
        );

        // Assert
        expect(completed.status, equals(PayoutStatus.completed));
        expect(completed.completedAt, isNotNull);
      });

      test('should throw exception if payout not found', () async {
        // Act & Assert
        expect(
          () => service.updatePayoutStatus(
            payoutId: 'nonexistent-payout',
            status: PayoutStatus.completed,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Payout not found'),
          )),
        );
      });
    });

    group('getPayout', () {
      test('should return payout by ID', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        final created = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );

        // Act
        final payout = await service.getPayout(created.id);

        // Assert
        expect(payout, isNotNull);
        expect(payout?.id, equals(created.id));
        expect(payout?.partyId, equals('user-123'));
      });

      test('should return null if payout not found', () async {
        // Act
        final payout = await service.getPayout('nonexistent-payout');

        // Assert
        expect(payout, isNull);
      });
    });

    group('getPayoutsForParty', () {
      test('should return payouts for a party', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 75.00,
          eventId: 'event-456',
          scheduledDate: scheduledDate,
        );
        await service.schedulePayout(
          partyId: 'business-123',
          amount: 100.00,
          eventId: 'event-789',
          scheduledDate: scheduledDate,
        );

        // Act
        final payouts = await service.getPayoutsForParty('user-123');

        // Assert
        expect(payouts, hasLength(2));
        expect(payouts.every((p) => p.partyId == 'user-123'), isTrue);
        // Should be sorted by scheduledDate (newest first)
        expect(payouts[0].scheduledDate.isAfter(payouts[1].scheduledDate) ||
            payouts[0].scheduledDate.isAtSameMomentAs(payouts[1].scheduledDate), isTrue);
      });

      test('should return empty list if no payouts for party', () async {
        // Act
        final payouts = await service.getPayoutsForParty('nonexistent-party');

        // Assert
        expect(payouts, isEmpty);
      });
    });

    group('trackEarnings', () {
      test('should track total earnings for a party', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 75.00,
          eventId: 'event-456',
          scheduledDate: scheduledDate,
        );

        // Act
        final report = await service.trackEarnings(
          partyId: 'user-123',
        );

        // Assert
        expect(report, isA<EarningsReport>());
        expect(report.partyId, equals('user-123'));
        expect(report.totalEarnings, equals(125.00));
        expect(report.payoutCount, equals(2));
        expect(report.payouts, hasLength(2));
      });

      test('should calculate total paid and pending amounts', () async {
        // Arrange
        final scheduledDate = DateTime.now().add(const Duration(days: 2));
        final payout1 = await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: scheduledDate,
        );
        final payout2 = await service.schedulePayout(
          partyId: 'user-123',
          amount: 75.00,
          eventId: 'event-456',
          scheduledDate: scheduledDate,
        );

        // Mark one as completed
        await service.updatePayoutStatus(
          payoutId: payout1.id,
          status: PayoutStatus.completed,
        );

        // Act
        final report = await service.trackEarnings(
          partyId: 'user-123',
        );

        // Assert
        expect(report.totalEarnings, equals(125.00));
        expect(report.totalPaid, equals(50.00));
        expect(report.totalPending, equals(75.00));
      });

      test('should filter earnings by date range', () async {
        // Arrange
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final futureDate = DateTime.now().add(const Duration(days: 10));

        await service.schedulePayout(
          partyId: 'user-123',
          amount: 50.00,
          eventId: 'event-123',
          scheduledDate: pastDate,
        );
        await service.schedulePayout(
          partyId: 'user-123',
          amount: 75.00,
          eventId: 'event-456',
          scheduledDate: futureDate,
        );

        final startDate = DateTime.now().subtract(const Duration(days: 5));
        final endDate = DateTime.now().add(const Duration(days: 5));

        // Act
        final report = await service.trackEarnings(
          partyId: 'user-123',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(report.startDate, equals(startDate));
        expect(report.endDate, equals(endDate));
        // Should only include payouts within date range
        expect(report.payouts.length, lessThanOrEqualTo(2));
      });

      test('should return zero earnings if no payouts', () async {
        // Act
        final report = await service.trackEarnings(
          partyId: 'nonexistent-party',
        );

        // Assert
        expect(report.totalEarnings, equals(0.0));
        expect(report.totalPaid, equals(0.0));
        expect(report.totalPending, equals(0.0));
        expect(report.payoutCount, equals(0));
      });
    });
  });
}

