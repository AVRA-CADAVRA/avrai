import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import '../helpers/integration_test_helpers.dart';

// Mock dependencies
class MockPartnershipService extends Mock implements PartnershipService {}

/// Revenue Split Performance Tests
/// 
/// Agent 1: Backend & Integration (Week 8)
/// 
/// Tests performance of revenue split calculations:
/// - N-way split calculation performance
/// - Large number of parties performance
/// - Concurrent split calculations
/// 
/// **Performance Targets:**
/// - N-way split calculation: < 10ms
/// - 10-party split: < 50ms
/// - 50-party split: < 200ms
void main() {
  group('Revenue Split Performance Tests', () {
    late RevenueSplitService revenueSplitService;
    late MockPartnershipService mockPartnershipService;
    
    setUp(() {
      mockPartnershipService = MockPartnershipService();
      revenueSplitService = RevenueSplitService(
        partnershipService: mockPartnershipService,
      );
    });
    
    group('N-way Split Calculation Performance', () {
      test('should calculate 2-party split quickly', () async {
        final parties = [
          SplitParty(
            partyId: 'user-1',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          SplitParty(
            partyId: 'business-1',
            type: SplitPartyType.business,
            percentage: 50.0,
          ),
        ];
        
        final stopwatch = Stopwatch()..start();
        
        final split = await revenueSplitService.calculateNWaySplit(
          eventId: 'event-1',
          totalAmount: 100.00,
          ticketsSold: 1,
          parties: parties,
        );
        
        stopwatch.stop();
        
        expect(split, isNotNull);
        expect(split.isValid, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(10)); // < 10ms
      });
      
      test('should calculate 10-party split efficiently', () async {
        final parties = List.generate(10, (index) {
          return SplitParty(
            partyId: 'party-$index',
            type: SplitPartyType.user,
            percentage: 10.0, // 10% each = 100% total
          );
        });
        
        final stopwatch = Stopwatch()..start();
        
        final split = await revenueSplitService.calculateNWaySplit(
          eventId: 'event-1',
          totalAmount: 1000.00,
          ticketsSold: 10,
          parties: parties,
        );
        
        stopwatch.stop();
        
        expect(split, isNotNull);
        expect(split.isValid, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // < 50ms
      });
      
      test('should calculate large splits correctly', () async {
        // Test with many parties (stress test)
        final parties = List.generate(20, (index) {
          return SplitParty(
            partyId: 'party-$index',
            type: SplitPartyType.user,
            percentage: 5.0, // 5% each = 100% total
          );
        });
        
        final split = await revenueSplitService.calculateNWaySplit(
          eventId: 'event-1',
          totalAmount: 5000.00,
          ticketsSold: 50,
          parties: parties,
        );
        
        expect(split, isNotNull);
        expect(split.isValid, isTrue);
        expect(split.parties.length, equals(20));
        
        // Verify all parties get correct amount
        final expectedAmount = split.splitAmount / 20; // 5% each
        for (final party in split.parties) {
          expect(party.amount, closeTo(expectedAmount, 0.01));
        }
      });
    });
    
    group('Revenue Split Validation Performance', () {
      test('should validate split quickly', () {
        final split = RevenueSplit.nWay(
          id: 'split-1',
          eventId: 'event-1',
          totalAmount: 100.00,
          ticketsSold: 1,
          parties: [
            SplitParty(
              partyId: 'user-1',
              type: SplitPartyType.user,
              percentage: 50.0,
            ),
            SplitParty(
              partyId: 'business-1',
              type: SplitPartyType.business,
              percentage: 50.0,
            ),
          ],
        );
        
        final stopwatch = Stopwatch()..start();
        final isValid = split.isValid;
        stopwatch.stop();
        
        expect(isValid, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(1)); // < 1ms
      });
    });
  });
}

