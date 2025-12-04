import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/revenue_split.dart';

/// Revenue Split Calculation Tests
/// 
/// Tests revenue split calculations for various ticket prices.
/// Verifies that calculations are accurate:
/// - Platform fee: 10% to SPOTS
/// - Processing fee: ~3% to Stripe (2.9% + $0.30 per transaction)
/// - Host payout: Remaining amount
void main() {
  group('RevenueSplit Calculation', () {
    test('calculates revenue split correctly for \$25 ticket (1 ticket)', () {
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-1',
        totalAmount: 25.00,
        ticketsSold: 1,
      );
      
      // Platform fee: 10% = $2.50
      expect(revenueSplit.platformFee, closeTo(2.50, 0.01));
      
      // Processing fee: 2.9% + $0.30 = $0.725 + $0.30 = $1.025
      expect(revenueSplit.processingFee, closeTo(1.025, 0.01));
      
      // Host payout: $25.00 - $2.50 - $1.025 = $21.475
      expect(revenueSplit.hostPayout, closeTo(21.475, 0.01));
      
      // Verify total is correct
      expect(revenueSplit.isValid, isTrue);
      expect(
        revenueSplit.platformFee + revenueSplit.processingFee + revenueSplit.hostPayout,
        closeTo(25.00, 0.01),
      );
    });
    
    test('calculates revenue split correctly for \$50 ticket (1 ticket)', () {
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-2',
        totalAmount: 50.00,
        ticketsSold: 1,
      );
      
      // Platform fee: 10% = $5.00
      expect(revenueSplit.platformFee, closeTo(5.00, 0.01));
      
      // Processing fee: 2.9% + $0.30 = $1.45 + $0.30 = $1.75
      expect(revenueSplit.processingFee, closeTo(1.75, 0.01));
      
      // Host payout: $50.00 - $5.00 - $1.75 = $43.25
      expect(revenueSplit.hostPayout, closeTo(43.25, 0.01));
      
      // Verify total is correct
      expect(revenueSplit.isValid, isTrue);
      expect(
        revenueSplit.platformFee + revenueSplit.processingFee + revenueSplit.hostPayout,
        closeTo(50.00, 0.01),
      );
    });
    
    test('calculates revenue split correctly for \$100 ticket (1 ticket)', () {
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-3',
        totalAmount: 100.00,
        ticketsSold: 1,
      );
      
      // Platform fee: 10% = $10.00
      expect(revenueSplit.platformFee, closeTo(10.00, 0.01));
      
      // Processing fee: 2.9% + $0.30 = $2.90 + $0.30 = $3.20
      expect(revenueSplit.processingFee, closeTo(3.20, 0.01));
      
      // Host payout: $100.00 - $10.00 - $3.20 = $86.80
      expect(revenueSplit.hostPayout, closeTo(86.80, 0.01));
      
      // Verify total is correct
      expect(revenueSplit.isValid, isTrue);
      expect(
        revenueSplit.platformFee + revenueSplit.processingFee + revenueSplit.hostPayout,
        closeTo(100.00, 0.01),
      );
    });
    
    test('calculates revenue split correctly for multiple tickets', () {
      // $25 ticket, 5 tickets sold = $125 total
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-4',
        totalAmount: 125.00,
        ticketsSold: 5,
      );
      
      // Platform fee: 10% = $12.50
      expect(revenueSplit.platformFee, closeTo(12.50, 0.01));
      
      // Processing fee: 2.9% + ($0.30 * 5) = $3.625 + $1.50 = $5.125
      expect(revenueSplit.processingFee, closeTo(5.125, 0.01));
      
      // Host payout: $125.00 - $12.50 - $5.125 = $107.375
      expect(revenueSplit.hostPayout, closeTo(107.375, 0.01));
      
      // Verify total is correct
      expect(revenueSplit.isValid, isTrue);
      expect(
        revenueSplit.platformFee + revenueSplit.processingFee + revenueSplit.hostPayout,
        closeTo(125.00, 0.01),
      );
    });
    
    test('verifies percentage calculations are correct', () {
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-5',
        totalAmount: 100.00,
        ticketsSold: 1,
      );
      
      // Platform fee should be ~10%
      expect(revenueSplit.platformFeePercentage, closeTo(10.0, 0.1));
      
      // Processing fee should be ~3.2%
      expect(revenueSplit.processingFeePercentage, closeTo(3.2, 0.1));
      
      // Host payout should be ~86.8%
      expect(revenueSplit.hostPayoutPercentage, closeTo(86.8, 0.1));
    });
    
    test('handles edge case: free event (zero amount)', () {
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-6',
        totalAmount: 0.00,
        ticketsSold: 0,
      );
      
      expect(revenueSplit.platformFee, 0.0);
      expect(revenueSplit.processingFee, 0.0);
      expect(revenueSplit.hostPayout, 0.0);
      expect(revenueSplit.isValid, isTrue);
    });
  });
}

