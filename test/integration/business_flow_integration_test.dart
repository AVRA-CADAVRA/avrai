import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/business_verification.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import '../helpers/integration_test_helpers.dart';

// Mock dependencies
class MockBusinessAccountService extends Mock implements BusinessAccountService {}

/// Business Flow Integration Tests
/// 
/// Agent 1: Backend & Integration (Week 8)
/// 
/// Tests business account and verification flow:
/// - Business account creation
/// - Business verification workflow
/// - Business eligibility checks
/// - Business search and filtering
/// 
/// **Test Scenarios:**
/// - Scenario 1: Business Account Creation
/// - Scenario 2: Business Verification Workflow
/// - Scenario 3: Business Eligibility Checks
/// - Scenario 4: Business Search and Filtering
void main() {
  group('Business Flow Integration Tests', () {
    late BusinessService businessService;
    late MockBusinessAccountService mockAccountService;
    
    setUp(() {
      mockAccountService = MockBusinessAccountService();
      businessService = BusinessService(
        accountService: mockAccountService,
      );
    });
    
    tearDown(() {
      reset(mockAccountService);
    });
    
    group('Scenario 1: Business Account Creation', () {
      test('should create business account successfully', () async {
        // Arrange
        final businessAccount = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
        );
        
        when(() => mockAccountService.createBusinessAccount(
          creator: any(named: 'creator'),
          name: any(named: 'name'),
          email: any(named: 'email'),
          businessType: any(named: 'businessType'),
          description: any(named: 'description'),
          website: any(named: 'website'),
          location: any(named: 'location'),
          phone: any(named: 'phone'),
          categories: any(named: 'categories'),
        )).thenAnswer((_) async => businessAccount);
        
        // Act
        final created = await businessService.createBusinessAccount(
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          createdBy: 'user-1',
        );
        
        // Assert
        expect(created, isNotNull);
        expect(created.name, equals('Test Restaurant'));
        expect(created.email, equals('test@restaurant.com'));
        expect(created.businessType, equals('Restaurant'));
      });
    });
    
    group('Scenario 2: Business Verification Workflow', () {
      test('should create verification request', () async {
        // Arrange
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          isVerified: false,
        );
        
        when(() => mockAccountService.getBusinessAccount(any()))
            .thenAnswer((_) async => business);
        
        // Act
        final verification = await businessService.verifyBusiness(
          businessId: business.id,
          legalBusinessName: 'Test Restaurant LLC',
          businessAddress: '123 Main St, New York, NY',
          phoneNumber: '555-1234',
        );
        
        // Assert
        expect(verification, isNotNull);
        expect(verification.businessAccountId, equals(business.id));
        expect(verification.status, equals(VerificationStatus.pending));
        expect(verification.legalBusinessName, equals('Test Restaurant LLC'));
      });
    });
    
    group('Scenario 3: Business Eligibility Checks', () {
      test('should return true if business is eligible', () async {
        // Arrange
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          isVerified: true,
          isActive: true,
        );
        
        when(() => mockAccountService.getBusinessAccount(any()))
            .thenAnswer((_) async => business);
        
        // Act
        final isEligible = await businessService.checkBusinessEligibility(business.id);
        
        // Assert
        expect(isEligible, isTrue);
      });
      
      test('should return false if business not verified', () async {
        // Arrange
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          isVerified: false, // Not verified
          isActive: true,
        );
        
        when(() => mockAccountService.getBusinessAccount(any()))
            .thenAnswer((_) async => business);
        
        // Act
        final isEligible = await businessService.checkBusinessEligibility(business.id);
        
        // Assert
        expect(isEligible, isFalse);
      });
      
      test('should return false if business not active', () async {
        // Arrange
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          isVerified: true,
          isActive: false, // Not active
        );
        
        when(() => mockAccountService.getBusinessAccount(any()))
            .thenAnswer((_) async => business);
        
        // Act
        final isEligible = await businessService.checkBusinessEligibility(business.id);
        
        // Assert
        expect(isEligible, isFalse);
      });
    });
    
    group('Scenario 4: Business Search and Filtering', () {
      test('should find businesses by category', () async {
        // Arrange
        final businesses = [
          IntegrationTestHelpers.createTestBusinessAccount(
            id: 'business-1',
            categories: ['Coffee'],
          ),
          IntegrationTestHelpers.createTestBusinessAccount(
            id: 'business-2',
            categories: ['Restaurants'],
          ),
        ];
        
        when(() => mockAccountService.getBusinessAccountsByUser(any()))
            .thenAnswer((_) async => businesses);
        
        // Act
        final found = await businessService.findBusinesses(
          category: 'Coffee',
        );
        
        // Assert
        expect(found.length, equals(1));
        expect(found.first.categories, contains('Coffee'));
      });
      
      test('should filter by verified status', () async {
        // Arrange
        final businesses = [
          IntegrationTestHelpers.createTestBusinessAccount(
            id: 'business-1',
            isVerified: true,
          ),
          IntegrationTestHelpers.createTestBusinessAccount(
            id: 'business-2',
            isVerified: false,
          ),
        ];
        
        when(() => mockAccountService.getBusinessAccountsByUser(any()))
            .thenAnswer((_) async => businesses);
        
        // Act
        final verified = await businessService.findBusinesses(
          verifiedOnly: true,
        );
        
        // Assert
        expect(verified.length, equals(1));
        expect(verified.first.isVerified, isTrue);
      });
    });
  });
}

