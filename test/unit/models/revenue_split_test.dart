import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/revenue_split.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for RevenueSplit model
/// Tests solo event splits, N-way splits, locking, and validation
void main() {
  group('RevenueSplit Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Solo Event Revenue Split', () {
      test('should calculate solo event split correctly', () {
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        expect(split.eventId, equals('event-123'));
        expect(split.totalAmount, equals(100.00));
        expect(split.ticketsSold, equals(10));
        
        // Platform fee: 10%
        expect(split.platformFee, equals(10.00));
        expect(split.platformFeePercentage, closeTo(10.0, 0.01));
        
        // Processing fee: 2.9% + $0.30 per transaction
        // 2.9% of $100 = $2.90
        // $0.30 * 10 tickets = $3.00
        // Total = $5.90
        expect(split.processingFee, closeTo(5.90, 0.01));
        
        // Host payout: $100 - $10 - $5.90 = $84.10
        expect(split.hostPayout, closeTo(84.10, 0.01));
        expect(split.hostPayoutPercentage, closeTo(84.1, 0.01));
        
        expect(split.isValid, isTrue);
      });

      test('should validate solo event split adds up correctly', () {
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 500.00,
          ticketsSold: 20,
        );

        final sum = split.platformFee + split.processingFee + split.hostPayout!;
        expect(sum, closeTo(500.00, 0.01));
        expect(split.isValid, isTrue);
      });
    });

    group('N-Way Revenue Split', () {
      test('should calculate N-way split correctly', () {
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'Expert User',
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 30.0,
            name: 'Test Restaurant',
          ),
          SplitParty(
            partyId: 'sponsor-123',
            type: SplitPartyType.sponsor,
            percentage: 20.0,
            name: 'Sponsor Company',
          ),
        ];

        final split = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          partnershipId: 'partnership-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: parties,
        );

        expect(split.id, equals('split-123'));
        expect(split.eventId, equals('event-123'));
        expect(split.partnershipId, equals('partnership-123'));
        expect(split.totalAmount, equals(1000.00));
        expect(split.ticketsSold, equals(20));
        expect(split.parties, hasLength(3));

        // Platform fee: 10% = $100
        expect(split.platformFee, equals(100.00));
        
        // Processing fee: 2.9% + $0.30 per transaction
        // 2.9% of $1000 = $29.00
        // $0.30 * 20 tickets = $6.00
        // Total = $35.00
        expect(split.processingFee, closeTo(35.00, 0.01));
        
        // Split amount: $1000 - $100 - $35 = $865
        expect(split.splitAmount, closeTo(865.00, 0.01));

        // User: 50% of $865 = $432.50
        expect(split.parties[0].amount, closeTo(432.50, 0.01));
        expect(split.parties[0].percentage, equals(50.0));
        
        // Business: 30% of $865 = $259.50
        expect(split.parties[1].amount, closeTo(259.50, 0.01));
        expect(split.parties[1].percentage, equals(30.0));
        
        // Sponsor: 20% of $865 = $173.00
        expect(split.parties[2].amount, closeTo(173.00, 0.01));
        expect(split.parties[2].percentage, equals(20.0));

        expect(split.isValid, isTrue);
      });

      test('should validate N-way split percentages add up to 100%', () {
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
          ),
        ];

        final split = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 5,
          parties: parties,
        );

        expect(split.isValid, isTrue);
      });

      test('should reject invalid N-way split percentages', () {
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 40.0, // Only 90% total
          ),
        ];

        final split = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 5,
          parties: parties,
        );

        expect(split.isValid, isFalse);
      });
    });

    group('Locking Mechanism', () {
      test('should lock split before event starts', () {
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        expect(split.isLocked, isFalse);
        expect(split.canBeModified, isTrue);

        final locked = split.lock(lockedBy: 'user-123');

        expect(locked.isLocked, isTrue);
        expect(locked.canBeModified, isFalse);
        expect(locked.lockedBy, equals('user-123'));
        expect(locked.lockedAt, isNotNull);
      });

      test('should prevent locking already locked split', () {
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        final locked = split.lock(lockedBy: 'user-123');

        expect(
          () => locked.lock(lockedBy: 'user-456'),
          throwsStateError,
        );
      });
    });

    group('JSON Serialization', () {
      test('should serialize solo event split to JSON', () {
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        final json = split.toJson();

        expect(json['eventId'], equals('event-123'));
        expect(json['totalAmount'], equals(100.00));
        expect(json['platformFee'], equals(10.00));
        expect(json['hostPayout'], closeTo(84.10, 0.01));
        expect(json['ticketsSold'], equals(10));
      });

      test('should serialize N-way split to JSON', () {
        final parties = [
          SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            amount: 432.50,
            name: 'Expert User',
          ),
        ];

        final split = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: parties,
        );

        final json = split.toJson();

        expect(json['id'], equals('split-123'));
        expect(json['eventId'], equals('event-123'));
        expect(json['totalAmount'], equals(1000.00));
        expect(json['parties'], isA<List>());
        expect(json['parties'], hasLength(1));
        expect(json['isLocked'], isFalse);
      });

      test('should deserialize solo event split from JSON', () {
        final json = {
          'id': 'event-123',
          'eventId': 'event-123',
          'totalAmount': 100.00,
          'platformFee': 10.00,
          'processingFee': 5.90,
          'hostPayout': 84.10,
          'calculatedAt': testDate.toIso8601String(),
          'ticketsSold': 10,
          'metadata': {},
        };

        final split = RevenueSplit.fromJson(json);

        expect(split.eventId, equals('event-123'));
        expect(split.totalAmount, equals(100.00));
        expect(split.platformFee, equals(10.00));
        expect(split.hostPayout, closeTo(84.10, 0.01));
        expect(split.ticketsSold, equals(10));
      });

      test('should deserialize N-way split from JSON', () {
        final json = {
          'id': 'split-123',
          'eventId': 'event-123',
          'partnershipId': 'partnership-123',
          'totalAmount': 1000.00,
          'platformFee': 100.00,
          'processingFee': 35.00,
          'calculatedAt': testDate.toIso8601String(),
          'ticketsSold': 20,
          'parties': [
            {
              'partyId': 'user-123',
              'type': 'user',
              'percentage': 50.0,
              'amount': 432.50,
              'name': 'Expert User',
              'metadata': {},
            },
          ],
          'isLocked': false,
          'metadata': {},
        };

        final split = RevenueSplit.fromJson(json);

        expect(split.id, equals('split-123'));
        expect(split.partnershipId, equals('partnership-123'));
        expect(split.parties, hasLength(1));
        expect(split.parties[0].partyId, equals('user-123'));
        expect(split.parties[0].percentage, equals(50.0));
        expect(split.parties[0].amount, closeTo(432.50, 0.01));
      });
    });

    group('Split Party', () {
      test('should create split party with required fields', () {
        final party = SplitParty(
          partyId: 'user-123',
          type: SplitPartyType.user,
          percentage: 50.0,
        );

        expect(party.partyId, equals('user-123'));
        expect(party.type, equals(SplitPartyType.user));
        expect(party.percentage, equals(50.0));
        expect(party.amount, isNull);
      });

      test('should create split party with all fields', () {
        final party = SplitParty(
          partyId: 'business-123',
          type: SplitPartyType.business,
          percentage: 30.0,
          amount: 259.50,
          name: 'Test Restaurant',
          metadata: {'key': 'value'},
        );

        expect(party.partyId, equals('business-123'));
        expect(party.type, equals(SplitPartyType.business));
        expect(party.percentage, equals(30.0));
        expect(party.amount, equals(259.50));
        expect(party.name, equals('Test Restaurant'));
        expect(party.metadata, equals({'key': 'value'}));
      });

      test('should serialize split party to JSON', () {
        final party = SplitParty(
          partyId: 'user-123',
          type: SplitPartyType.user,
          percentage: 50.0,
          amount: 432.50,
          name: 'Expert User',
        );

        final json = party.toJson();

        expect(json['partyId'], equals('user-123'));
        expect(json['type'], equals('user'));
        expect(json['percentage'], equals(50.0));
        expect(json['amount'], equals(432.50));
        expect(json['name'], equals('Expert User'));
      });

      test('should deserialize split party from JSON', () {
        final json = {
          'partyId': 'user-123',
          'type': 'user',
          'percentage': 50.0,
          'amount': 432.50,
          'name': 'Expert User',
          'metadata': {},
        };

        final party = SplitParty.fromJson(json);

        expect(party.partyId, equals('user-123'));
        expect(party.type, equals(SplitPartyType.user));
        expect(party.percentage, equals(50.0));
        expect(party.amount, equals(432.50));
        expect(party.name, equals('Expert User'));
      });

      test('should copy split party with updated fields', () {
        final party = SplitParty(
          partyId: 'user-123',
          type: SplitPartyType.user,
          percentage: 50.0,
        );

        final updated = party.copyWith(
          amount: 432.50,
          name: 'Expert User',
        );

        expect(updated.partyId, equals(party.partyId));
        expect(updated.type, equals(party.type));
        expect(updated.percentage, equals(party.percentage));
        expect(updated.amount, equals(432.50));
        expect(updated.name, equals('Expert User'));
      });
    });

    group('Split Party Type Extension', () {
      test('should convert type to display name', () {
        expect(SplitPartyType.user.displayName, equals('User'));
        expect(SplitPartyType.business.displayName, equals('Business'));
        expect(SplitPartyType.sponsor.displayName, equals('Sponsor'));
        expect(SplitPartyType.other.displayName, equals('Other'));
      });

      test('should parse type from string', () {
        expect(
          SplitPartyTypeExtension.fromString('user'),
          equals(SplitPartyType.user),
        );
        expect(
          SplitPartyTypeExtension.fromString('business'),
          equals(SplitPartyType.business),
        );
        expect(
          SplitPartyTypeExtension.fromString('sponsor'),
          equals(SplitPartyType.sponsor),
        );
        expect(
          SplitPartyTypeExtension.fromString('other'),
          equals(SplitPartyType.other),
        );
        expect(
          SplitPartyTypeExtension.fromString('unknown'),
          equals(SplitPartyType.user), // Default
        );
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        final updated = split.copyWith(
          isLocked: true,
          lockedBy: 'user-123',
          lockedAt: testDate,
        );

        expect(updated.eventId, equals(split.eventId));
        expect(updated.isLocked, isTrue);
        expect(updated.lockedBy, equals('user-123'));
        expect(updated.lockedAt, equals(testDate));
      });
    });
  });
}

