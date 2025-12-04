import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/business_account_service.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/business_verification.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'business_service_test.mocks.dart';

@GenerateMocks([BusinessAccountService])
void main() {
  group('BusinessService Tests', () {
    late BusinessService service;
    late MockBusinessAccountService mockAccountService;
    late UnifiedUser testCreator;

    setUp(() {
      mockAccountService = MockBusinessAccountService();
      service = BusinessService(accountService: mockAccountService);
      testCreator = ModelFactories.createTestUser(
        id: 'creator-123',
        displayName: 'Business Creator',
      );
    });

    group('createBusinessAccount', () {
      test('should create business account with required fields', () async {
        // Arrange
        final expectedBusiness = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        when(mockAccountService.createBusinessAccount(
          creator: anyNamed('creator'),
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          description: null,
          website: null,
          location: null,
          phone: null,
          logoUrl: null,
          categories: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => expectedBusiness);

        // Act
        final business = await service.createBusinessAccount(
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdBy: 'creator-123',
        );

        // Assert
        expect(business, isA<BusinessAccount>());
        expect(business.name, equals('Test Business'));
        expect(business.email, equals('test@business.com'));
        expect(business.businessType, equals('Restaurant'));
        verify(mockAccountService.createBusinessAccount(
          creator: anyNamed('creator'),
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          description: null,
          website: null,
          location: null,
          phone: null,
          logoUrl: null,
          categories: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).called(1);
      });

      test('should create business account with all optional fields', () async {
        // Arrange
        final expectedBusiness = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Retail',
          description: 'A test business',
          website: 'https://testbusiness.com',
          location: 'San Francisco',
          phone: '555-1234',
          categories: ['Food', 'Dining'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        when(mockAccountService.createBusinessAccount(
          creator: anyNamed('creator'),
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Retail',
          description: 'A test business',
          website: 'https://testbusiness.com',
          location: 'San Francisco',
          phone: '555-1234',
          logoUrl: null,
          categories: ['Food', 'Dining'],
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => expectedBusiness);

        // Act
        final business = await service.createBusinessAccount(
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Retail',
          createdBy: 'creator-123',
          description: 'A test business',
          website: 'https://testbusiness.com',
          location: 'San Francisco',
          phone: '555-1234',
          categories: ['Food', 'Dining'],
        );

        // Assert
        expect(business.description, equals('A test business'));
        expect(business.website, equals('https://testbusiness.com'));
        expect(business.location, equals('San Francisco'));
        expect(business.phone, equals('555-1234'));
        expect(business.categories, contains('Food'));
      });
    });

    group('verifyBusiness', () {
      test('should create verification record for business', () async {
        // Arrange
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);

        // Act
        final verification = await service.verifyBusiness(
          businessId: 'business-123',
          businessLicenseUrl: 'https://example.com/license.pdf',
          taxIdDocumentUrl: 'https://example.com/tax.pdf',
          legalBusinessName: 'Test Business LLC',
          taxId: '12-3456789',
          businessAddress: '123 Main St, San Francisco, CA',
          phoneNumber: '555-1234',
          websiteUrl: 'https://testbusiness.com',
        );

        // Assert
        expect(verification, isA<BusinessVerification>());
        expect(verification.businessAccountId, equals('business-123'));
        expect(verification.status, equals(VerificationStatus.pending));
        expect(verification.method, equals(VerificationMethod.hybrid));
        expect(verification.businessLicenseUrl, equals('https://example.com/license.pdf'));
        expect(verification.legalBusinessName, equals('Test Business LLC'));
      });

      test('should throw exception if business not found', () async {
        // Arrange
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.verifyBusiness(businessId: 'business-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Business not found'),
          )),
        );
      });
    });

    group('updateBusinessInfo', () {
      test('should update business account information', () async {
        // Arrange
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Original Name',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        final updatedBusiness = business.copyWith(
          name: 'Updated Name',
          description: 'Updated description',
          website: 'https://updated.com',
        );

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);
        when(mockAccountService.updateBusinessAccount(
          business,
          name: 'Updated Name',
          description: 'Updated description',
          website: 'https://updated.com',
          location: null,
          phone: null,
          categories: null,
        )).thenAnswer((_) async => updatedBusiness);

        // Act
        final updated = await service.updateBusinessInfo(
          businessId: 'business-123',
          name: 'Updated Name',
          description: 'Updated description',
          website: 'https://updated.com',
        );

        // Assert
        expect(updated.name, equals('Updated Name'));
        expect(updated.description, equals('Updated description'));
        expect(updated.website, equals('https://updated.com'));
      });

      test('should throw exception if business not found', () async {
        // Arrange
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.updateBusinessInfo(businessId: 'business-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Business not found'),
          )),
        );
      });
    });

    group('findBusinesses', () {
      test('should find businesses by category', () async {
        // Arrange
        final businesses = [
          BusinessAccount(
            id: 'business-1',
            name: 'Coffee Shop 1',
            email: 'shop1@coffee.com',
            businessType: 'Restaurant',
            categories: ['Coffee'],
            location: 'San Francisco',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
          BusinessAccount(
            id: 'business-2',
            name: 'Coffee Shop 2',
            email: 'shop2@coffee.com',
            businessType: 'Restaurant',
            categories: ['Coffee'],
            location: 'San Francisco',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
        ];

        when(mockAccountService.getBusinessAccountsByUser('system'))
            .thenAnswer((_) async => businesses);

        // Act
        final found = await service.findBusinesses(
          category: 'Coffee',
          location: 'San Francisco',
        );

        // Assert
        expect(found, isNotEmpty);
        expect(found.every((b) => b.categories.contains('Coffee')), isTrue);
      });

      test('should filter by verifiedOnly flag', () async {
        // Arrange
        final businesses = [
          BusinessAccount(
            id: 'business-1',
            name: 'Verified Business',
            email: 'verified@business.com',
            businessType: 'Restaurant',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
          BusinessAccount(
            id: 'business-2',
            name: 'Unverified Business',
            email: 'unverified@business.com',
            businessType: 'Restaurant',
            isVerified: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
        ];

        when(mockAccountService.getBusinessAccountsByUser('system'))
            .thenAnswer((_) async => businesses);

        // Act
        final found = await service.findBusinesses(
          verifiedOnly: true,
        );

        // Assert
        expect(found, isNotEmpty);
        expect(found.every((b) => b.isVerified), isTrue);
      });

      test('should respect maxResults limit', () async {
        // Arrange
        final businesses = List.generate(
          10,
          (i) => BusinessAccount(
            id: 'business-$i',
            name: 'Business $i',
            email: 'business$i@test.com',
            businessType: 'Restaurant',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
        );

        when(mockAccountService.getBusinessAccountsByUser('system'))
            .thenAnswer((_) async => businesses);

        // Act
        final found = await service.findBusinesses(maxResults: 5);

        // Assert
        expect(found.length, lessThanOrEqualTo(5));
      });
    });

    group('checkBusinessEligibility', () {
      test('should return true for eligible business', () async {
        // Arrange
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          isVerified: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);

        // Act
        final isEligible = await service.checkBusinessEligibility('business-123');

        // Assert
        expect(isEligible, isTrue);
      });

      test('should return false if business not found', () async {
        // Arrange
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);

        // Act
        final isEligible = await service.checkBusinessEligibility('business-123');

        // Assert
        expect(isEligible, isFalse);
      });

      test('should return false if business not verified', () async {
        // Arrange
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          isVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);

        // Act
        final isEligible = await service.checkBusinessEligibility('business-123');

        // Assert
        expect(isEligible, isFalse);
      });

      test('should return false if business not active', () async {
        // Arrange
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          isVerified: true,
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);

        // Act
        final isEligible = await service.checkBusinessEligibility('business-123');

        // Assert
        expect(isEligible, isFalse);
      });
    });

    group('getBusinessById', () {
      test('should return business by ID', () async {
        // Arrange
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);

        // Act
        final found = await service.getBusinessById('business-123');

        // Assert
        expect(found, isNotNull);
        expect(found?.id, equals('business-123'));
      });

      test('should return null if business not found', () async {
        // Arrange
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);

        // Act
        final found = await service.getBusinessById('business-123');

        // Assert
        expect(found, isNull);
      });
    });
  });
}

