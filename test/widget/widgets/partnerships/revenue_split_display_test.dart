import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/presentation/widgets/partnerships/revenue_split_display.dart';

/// Revenue Split Display Widget Tests
/// 
/// Agent 2: Payment UI, Revenue Display UI (Week 7)
/// 
/// Tests the revenue split display widget for partnerships.
void main() {
  group('RevenueSplitDisplay Widget Tests', () {
    testWidgets('should display solo event revenue split', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-123',
        totalAmount: 100.00,
        ticketsSold: 1,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevenueSplitDisplay(
              split: revenueSplit,
              showDetails: true,
              showLockStatus: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Revenue Breakdown'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('\$100.00'), findsWidgets);
      expect(find.text('Platform Fee'), findsOneWidget);
      expect(find.text('Processing Fee'), findsOneWidget);
      expect(find.text('Host Payout'), findsOneWidget);
    });

    testWidgets('should display N-way partnership revenue split', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit.nWay(
        id: 'split-123',
        eventId: 'event-456',
        totalAmount: 1000.00,
        ticketsSold: 20,
        parties: [
          SplitParty(
            partyId: 'user-1',
            type: SplitPartyType.user,
            percentage: 50.0,
            amount: 434.00,
            name: 'John Doe',
          ),
          SplitParty(
            partyId: 'biz-1',
            type: SplitPartyType.business,
            percentage: 30.0,
            amount: 260.40,
            name: 'Coffee Shop',
          ),
          SplitParty(
            partyId: 'sponsor-1',
            type: SplitPartyType.sponsor,
            percentage: 20.0,
            amount: 173.60,
            name: 'Tech Corp',
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevenueSplitDisplay(
              split: revenueSplit,
              showDetails: true,
              showLockStatus: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Revenue Breakdown'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('\$1,000.00'), findsWidgets);
      expect(find.text('Partner Distribution'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Coffee Shop'), findsOneWidget);
      expect(find.text('Tech Corp'), findsOneWidget);
    });

    testWidgets('should show locked status when split is locked', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-123',
        totalAmount: 100.00,
        ticketsSold: 1,
      ).lock(lockedBy: 'user-1');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevenueSplitDisplay(
              split: revenueSplit,
              showDetails: true,
              showLockStatus: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Locked'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('should show warning when split is not locked', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-123',
        totalAmount: 100.00,
        ticketsSold: 1,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevenueSplitDisplay(
              split: revenueSplit,
              showDetails: true,
              showLockStatus: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Revenue split must be locked before event starts'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('should hide details when showDetails is false', (WidgetTester tester) async {
      // Arrange
      final revenueSplit = RevenueSplit.calculate(
        eventId: 'event-123',
        totalAmount: 100.00,
        ticketsSold: 1,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevenueSplitDisplay(
              split: revenueSplit,
              showDetails: false,
              showLockStatus: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Platform Fee'), findsNothing);
      expect(find.text('Processing Fee'), findsNothing);
      expect(find.text('Total Revenue'), findsOneWidget); // Still shows total
    });
  });
}

