import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/presentation/pages/partnerships/partnership_acceptance_page.dart';

/// Partnership Acceptance Page Widget Tests
/// 
/// Agent 2: Partnership UI, Business UI (Week 8)
/// 
/// Tests the partnership acceptance page functionality.
void main() {
  group('PartnershipAcceptancePage Widget Tests', () {
    late EventPartnership testPartnership;
    late ExpertiseEvent testEvent;

    setUp(() {
      final user = UnifiedUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
      );

      final business = BusinessAccount(
        id: 'biz-1',
        name: 'Test Business',
        email: 'business@example.com',
        businessType: 'Restaurant',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testEvent = ExpertiseEvent(
        id: 'event-1',
        title: 'Test Event',
        description: 'Test event description',
        category: 'Food',
        host: user,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'Test Location',
        maxAttendees: 20,
        price: 25.0,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testPartnership = EventPartnership(
        id: 'partnership-1',
        eventId: testEvent.id,
        userId: user.id,
        businessId: business.id,
        user: user,
        business: business,
        status: PartnershipStatus.proposed,
        vibeCompatibilityScore: 0.85,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display partnership acceptance page', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipAcceptancePage(partnership: testPartnership),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Partnership Proposal'), findsOneWidget);
      expect(find.text('Partnership Details'), findsOneWidget);
    });

    testWidgets('should display accept and decline buttons', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipAcceptancePage(partnership: testPartnership),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Accept Partnership'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('should display event details', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipAcceptancePage(partnership: testPartnership),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Event Details'), findsOneWidget);
    });
  });
}

