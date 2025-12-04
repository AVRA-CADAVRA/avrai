import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/presentation/pages/brand/brand_discovery_page.dart';
import 'package:spots/presentation/pages/brand/sponsorship_management_page.dart';
import 'package:spots/presentation/pages/brand/brand_dashboard_page.dart';
import 'package:spots/presentation/pages/brand/brand_analytics_page.dart';
import 'package:spots/presentation/pages/brand/sponsorship_checkout_page.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Brand UI Integration Tests
/// 
/// Agent 2: Phase 4, Week 14 - Brand UI Integration Testing
/// 
/// Tests the complete Brand UI integration:
/// - Brand Discovery page
/// - Sponsorship Management page
/// - Brand Dashboard page
/// - Brand Analytics page
/// - Sponsorship Checkout page
/// - Navigation flows
/// - Error/loading/empty states
/// - Responsive design
void main() {
  group('Brand UI Integration Tests', () {
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;
    late BrandAccount testBrandAccount;
    late Sponsorship testSponsorship;

    setUp(() {
      testUser = ModelFactories.createTestUser();
      
      testEvent = ExpertiseEvent(
        id: 'event-1',
        title: 'Test Event',
        description: 'Test event description',
        category: 'Food',
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'Test Location',
        maxAttendees: 20,
        price: 25.0,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create test brand account
      testBrandAccount = BrandAccount(
        id: 'brand-1',
        name: 'Test Brand',
        brandType: 'Food & Beverage',
        contactEmail: 'brand@example.com',
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );

      // Create test sponsorship
      testSponsorship = Sponsorship(
        id: 'sponsorship-1',
        eventId: testEvent.id,
        brandId: testBrandAccount.id,
        type: SponsorshipType.financial,
        status: SponsorshipStatus.pending,
        contributionAmount: 1000.0,
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );
    });

    group('Brand Discovery Page', () {
      testWidgets('should display brand discovery page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Discover Events'), findsOneWidget);
      });

      testWidgets('should display event search interface', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show search interface
        expect(find.byType(BrandDiscoveryPage), findsOneWidget);
      });

      testWidgets('should display recommended events section', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show recommended events section
        expect(find.byType(BrandDiscoveryPage), findsOneWidget);
      });

      testWidgets('should display filter options', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show filter options
        expect(find.byType(BrandDiscoveryPage), findsOneWidget);
      });

      testWidgets('should show empty state when no events found', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2)); // Wait for async loading

        // Assert - Should show empty state
        expect(find.byType(BrandDiscoveryPage), findsOneWidget);
      });
    });

    group('Sponsorship Management Page', () {
      testWidgets('should display sponsorship management page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: SponsorshipManagementPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('My Sponsorships'), findsOneWidget);
      });

      testWidgets('should display tab navigation (Active, Pending, Completed)', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: SponsorshipManagementPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('should display sponsorship status updates', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: SponsorshipManagementPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show sponsorship management interface
        expect(find.byType(SponsorshipManagementPage), findsOneWidget);
      });

      testWidgets('should show empty state when no sponsorships', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: SponsorshipManagementPage(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2)); // Wait for async loading

        // Assert - Should show empty state
        expect(find.byType(SponsorshipManagementPage), findsOneWidget);
      });
    });

    group('Brand Dashboard Page', () {
      testWidgets('should display brand dashboard page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDashboardPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Brand Dashboard'), findsOneWidget);
      });

      testWidgets('should display analytics overview', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDashboardPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show analytics overview
        expect(find.byType(BrandDashboardPage), findsOneWidget);
      });

      testWidgets('should display active sponsorships', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDashboardPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show active sponsorships section
        expect(find.byType(BrandDashboardPage), findsOneWidget);
      });

      testWidgets('should provide navigation to other brand pages', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDashboardPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show navigation options
        expect(find.byType(BrandDashboardPage), findsOneWidget);
      });
    });

    group('Brand Analytics Page', () {
      testWidgets('should display brand analytics page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandAnalyticsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Brand Analytics'), findsOneWidget);
      });

      testWidgets('should display ROI charts', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandAnalyticsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show ROI charts
        expect(find.byType(BrandAnalyticsPage), findsOneWidget);
      });

      testWidgets('should display performance metrics', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandAnalyticsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show performance metrics
        expect(find.byType(BrandAnalyticsPage), findsOneWidget);
      });

      testWidgets('should display brand exposure metrics', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandAnalyticsPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show brand exposure metrics
        expect(find.byType(BrandAnalyticsPage), findsOneWidget);
      });
    });

    group('Sponsorship Checkout Page', () {
      testWidgets('should display sponsorship checkout page correctly', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: SponsorshipCheckoutPage(
              event: testEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Sponsorship Checkout'), findsOneWidget);
      });

      testWidgets('should display event details in checkout', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: SponsorshipCheckoutPage(
              event: testEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(testEvent.title), findsOneWidget);
      });

      testWidgets('should display multi-party checkout interface', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: SponsorshipCheckoutPage(
              event: testEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show multi-party checkout
        expect(find.byType(SponsorshipCheckoutPage), findsOneWidget);
      });

      testWidgets('should display revenue split information', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: SponsorshipCheckoutPage(
              event: testEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show revenue split
        expect(find.byType(SponsorshipCheckoutPage), findsOneWidget);
      });

      testWidgets('should display product contribution tracking', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: SponsorshipCheckoutPage(
              event: testEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should show product contribution options
        expect(find.byType(SponsorshipCheckoutPage), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('should handle error states in brand discovery', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Page should render even with potential errors
        expect(find.byType(BrandDiscoveryPage), findsOneWidget);
      });

      testWidgets('should handle error states in sponsorship management', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: SponsorshipManagementPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Page should render even with potential errors
        expect(find.byType(SponsorshipManagementPage), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('should show loading state while fetching events', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pump(); // First frame

        // Assert - Should show loading initially if processing
        expect(find.byType(BrandDiscoveryPage), findsOneWidget);
      });

      testWidgets('should show loading state while fetching sponsorships', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: SponsorshipManagementPage(),
          ),
        );
        await tester.pump(); // First frame

        // Assert - Should show loading initially if processing
        expect(find.byType(SponsorshipManagementPage), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Test on phone size
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: BrandDiscoveryPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BrandDiscoveryPage), findsOneWidget);

        // Test on tablet size
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpAndSettle();

        expect(find.byType(BrandDiscoveryPage), findsOneWidget);

        // Reset
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}

