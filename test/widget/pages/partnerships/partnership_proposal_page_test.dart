import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/presentation/pages/partnerships/partnership_proposal_page.dart';

/// Partnership Proposal Page Widget Tests
/// 
/// Agent 2: Partnership UI, Business UI (Week 8)
/// 
/// Tests the partnership proposal page functionality.
void main() {
  group('PartnershipProposalPage Widget Tests', () {
    late ExpertiseEvent testEvent;

    setUp(() {
      final host = UnifiedUser(
        id: 'user-1',
        email: 'host@example.com',
        displayName: 'Test Host',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
      );

      testEvent = ExpertiseEvent(
        id: 'event-1',
        title: 'Test Event',
        description: 'Test event description',
        category: 'Food',
        host: host,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'Test Location',
        maxAttendees: 20,
        price: 25.0,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display partnership proposal page', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipProposalPage(event: testEvent),
        ),
      );

      // Assert
      expect(find.text('Partnership Proposal'), findsOneWidget);
      expect(find.text('Find a Business Partner'), findsOneWidget);
      expect(find.text('Partner with businesses to host events together'), findsOneWidget);
    });

    testWidgets('should display search bar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipProposalPage(event: testEvent),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('🔍 Search businesses...'), findsOneWidget);
    });

    testWidgets('should display suggested partners section', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipProposalPage(event: testEvent),
        ),
      );

      // Assert
      expect(find.text('Suggested Partners (Vibe Match)'), findsOneWidget);
    });

    testWidgets('should show empty state when no suggestions', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: PartnershipProposalPage(event: testEvent),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No suggested partners yet'), findsOneWidget);
    });
  });
}

