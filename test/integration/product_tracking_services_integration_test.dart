import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import '../helpers/integration_test_helpers.dart';

// Mock dependencies
class MockSponsorshipService extends Mock implements SponsorshipService {}
class MockRevenueSplitService extends Mock implements RevenueSplitService {}

/// Product Tracking Services Integration Tests
/// 
/// Agent 1: Backend & Integration (Week 12)
/// 
/// Tests service-level integration for product tracking:
/// - ProductTrackingService product contribution tracking
/// - Product sales tracking
/// - Revenue attribution calculation
/// - Inventory management
/// - Sales report generation
/// 
/// **Test Scenarios:**
/// - Scenario 1: Product Contribution Tracking
/// - Scenario 2: Product Sales Tracking
/// - Scenario 3: Revenue Attribution
/// - Scenario 4: Inventory Management
/// - Scenario 5: Sales Report Generation
void main() {
  group('Product Tracking Services Integration Tests', () {
    late ProductTrackingService productTrackingService;
    late MockSponsorshipService mockSponsorshipService;
    late MockRevenueSplitService mockRevenueSplitService;
    
    late DateTime testDate;
    late Sponsorship testSponsorship;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      
      mockSponsorshipService = MockSponsorshipService();
      mockRevenueSplitService = MockRevenueSplitService();
      
      productTrackingService = ProductTrackingService(
        sponsorshipService: mockSponsorshipService,
        revenueSplitService: mockRevenueSplitService,
      );
      
      testSponsorship = IntegrationTestHelpers.createTestSponsorship(
        id: 'sponsor-123',
        eventId: 'event-456',
        brandId: 'brand-123',
        type: SponsorshipType.product,
        productValue: 500.00,
        status: SponsorshipStatus.approved,
      );
    });
    
    tearDown(() {
      reset(mockSponsorshipService);
      reset(mockRevenueSplitService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Product Contribution Tracking', () {
      test('should record product contribution successfully', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => testSponsorship);
        
        // Act
        final tracking = await productTrackingService.recordProductContribution(
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
          description: 'Premium quality olive oil',
        );
        
        // Assert
        expect(tracking, isNotNull);
        expect(tracking.sponsorshipId, equals('sponsor-123'));
        expect(tracking.productName, equals('Premium Olive Oil'));
        expect(tracking.quantityProvided, equals(20));
        expect(tracking.unitPrice, equals(25.00));
        expect(tracking.quantityRemaining, equals(20));
      });
      
      test('should throw exception if sponsorship not found', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => null);
        
        // Act & Assert
        expect(
          () => productTrackingService.recordProductContribution(
            sponsorshipId: 'sponsor-123',
            productName: 'Premium Olive Oil',
            quantityProvided: 20,
            unitPrice: 25.00,
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should throw exception if sponsorship type does not support products', () async {
        // Arrange
        final financialSponsorship = testSponsorship.copyWith(
          type: SponsorshipType.financial,
        );
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => financialSponsorship);
        
        // Act & Assert
        expect(
          () => productTrackingService.recordProductContribution(
            sponsorshipId: 'sponsor-123',
            productName: 'Premium Olive Oil',
            quantityProvided: 20,
            unitPrice: 25.00,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Scenario 2: Product Sales Tracking', () {
      test('should record product sale successfully', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => testSponsorship);
        
        final tracking = await productTrackingService.recordProductContribution(
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
        );
        
        // Act
        final updatedTracking = await productTrackingService.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 2,
          buyerId: 'buyer-123',
          salePrice: 25.00,
        );
        
        // Assert
        expect(updatedTracking.quantitySold, equals(2));
        expect(updatedTracking.totalSales, equals(50.00));
        expect(updatedTracking.platformFee, closeTo(5.00, 0.01)); // 10% of 50
        expect(updatedTracking.sales.length, equals(1));
      });
      
      test('should throw exception if insufficient quantity available', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => testSponsorship);
        
        final tracking = await productTrackingService.recordProductContribution(
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 5,
          unitPrice: 25.00,
        );
        
        // Act & Assert
        expect(
          () => productTrackingService.recordProductSale(
            productTrackingId: tracking.id,
            quantity: 10, // More than available
            buyerId: 'buyer-123',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Scenario 3: Revenue Attribution', () {
      test('should calculate revenue attribution for product sales', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => testSponsorship);
        
        final tracking = await productTrackingService.recordProductContribution(
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
        );
        
        await productTrackingService.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 5,
          buyerId: 'buyer-123',
        );
        
        // Act
        final distribution = await productTrackingService.calculateRevenueAttribution(
          productTrackingId: tracking.id,
        );
        
        // Assert
        expect(distribution, isNotEmpty);
        expect(distribution.containsKey('brand-123'), isTrue);
        expect(distribution['brand-123'], greaterThan(0));
      });
    });
    
    group('Scenario 4: Inventory Management', () {
      test('should update product quantity correctly', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => testSponsorship);
        
        final tracking = await productTrackingService.recordProductContribution(
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
        );
        
        // Act
        final updatedTracking = await productTrackingService.updateProductQuantity(
          productTrackingId: tracking.id,
          quantitySold: 10,
          quantityGivenAway: 3,
          quantityUsedInEvent: 2,
        );
        
        // Assert
        expect(updatedTracking.quantitySold, equals(10));
        expect(updatedTracking.quantityGivenAway, equals(3));
        expect(updatedTracking.quantityUsedInEvent, equals(2));
        expect(updatedTracking.quantityRemaining, equals(5)); // 20 - 10 - 3 - 2
      });
    });
    
    group('Scenario 5: Sales Report Generation', () {
      test('should generate sales report for sponsorship', () async {
        // Arrange
        when(() => mockSponsorshipService.getSponsorshipById('sponsor-123'))
            .thenAnswer((_) async => testSponsorship);
        
        final tracking = await productTrackingService.recordProductContribution(
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          unitPrice: 25.00,
        );
        
        await productTrackingService.recordProductSale(
          productTrackingId: tracking.id,
          quantity: 5,
          buyerId: 'buyer-123',
        );
        
        // Act
        final report = await productTrackingService.generateSalesReport(
          sponsorshipId: 'sponsor-123',
        );
        
        // Assert
        expect(report, isNotNull);
        expect(report.sponsorshipId, equals('sponsor-123'));
        expect(report.totalProducts, greaterThan(0));
        expect(report.totalSales, greaterThan(0));
      });
    });
  });
}

