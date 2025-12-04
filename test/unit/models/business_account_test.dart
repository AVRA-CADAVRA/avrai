import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/business_verification.dart';
import 'package:spots/core/models/business_expert_preferences.dart';
import 'package:spots/core/models/business_patron_preferences.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BusinessAccount model
/// Tests business account creation, JSON serialization, and business logic
void main() {
  group('BusinessAccount Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create business account with required fields', () {
        final account = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(account.id, equals('business-123'));
        expect(account.name, equals('Test Restaurant'));
        expect(account.email, equals('test@restaurant.com'));
        expect(account.businessType, equals('Restaurant'));
        expect(account.createdAt, equals(testDate));
        expect(account.updatedAt, equals(testDate));
        expect(account.createdBy, equals('user-123'));
        
        // Test default values
        expect(account.description, isNull);
        expect(account.website, isNull);
        expect(account.location, isNull);
        expect(account.phone, isNull);
        expect(account.logoUrl, isNull);
        expect(account.categories, isEmpty);
        expect(account.requiredExpertise, isEmpty);
        expect(account.preferredCommunities, isEmpty);
        expect(account.expertPreferences, isNull);
        expect(account.patronPreferences, isNull);
        expect(account.isActive, isTrue);
        expect(account.isVerified, isFalse);
        expect(account.verification, isNull);
        expect(account.connectedExpertIds, isEmpty);
        expect(account.pendingConnectionIds, isEmpty);
      });

      test('should create business account with all optional fields', () {
        final verification = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.verified,
          submittedAt: testDate,
          updatedAt: testDate,
        );

        final expertPrefs = BusinessExpertPreferences(
          requiredExpertiseCategories: ['Coffee', 'Food'],
          minExpertLevel: 3,
        );

        final patronPrefs = BusinessPatronPreferences(
          preferredInterests: ['Food', 'Social'],
        );

        final account = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          description: 'A great restaurant',
          website: 'https://testrestaurant.com',
          location: '123 Main St, NYC',
          phone: '+1-555-0123',
          logoUrl: 'https://testrestaurant.com/logo.png',
          businessType: 'Restaurant',
          categories: ['Food', 'Dining'],
          requiredExpertise: ['Culinary', 'Hospitality'],
          preferredCommunities: ['community-1', 'community-2'],
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          preferredLocation: 'NYC',
          minExpertLevel: 3,
          isActive: true,
          isVerified: true,
          verification: verification,
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
          connectedExpertIds: ['expert-1', 'expert-2'],
          pendingConnectionIds: ['expert-3'],
        );

        expect(account.description, equals('A great restaurant'));
        expect(account.website, equals('https://testrestaurant.com'));
        expect(account.location, equals('123 Main St, NYC'));
        expect(account.phone, equals('+1-555-0123'));
        expect(account.logoUrl, equals('https://testrestaurant.com/logo.png'));
        expect(account.categories, equals(['Food', 'Dining']));
        expect(account.requiredExpertise, equals(['Culinary', 'Hospitality']));
        expect(account.preferredCommunities, equals(['community-1', 'community-2']));
        expect(account.expertPreferences, equals(expertPrefs));
        expect(account.patronPreferences, equals(patronPrefs));
        expect(account.preferredLocation, equals('NYC'));
        expect(account.minExpertLevel, equals(3));
        expect(account.isActive, isTrue);
        expect(account.isVerified, isTrue);
        expect(account.verification, equals(verification));
        expect(account.connectedExpertIds, equals(['expert-1', 'expert-2']));
        expect(account.pendingConnectionIds, equals(['expert-3']));
      });

      test('should create business account with Stripe Connect account ID', () {
        final account = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          stripeConnectAccountId: 'acct_1234567890',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(account.stripeConnectAccountId, equals('acct_1234567890'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final verification = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.verified,
          submittedAt: testDate,
          updatedAt: testDate,
        );

        final account = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          description: 'A great restaurant',
          website: 'https://testrestaurant.com',
          businessType: 'Restaurant',
          categories: ['Food', 'Dining'],
          isVerified: true,
          verification: verification,
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final json = account.toJson();

        expect(json['id'], equals('business-123'));
        expect(json['name'], equals('Test Restaurant'));
        expect(json['email'], equals('test@restaurant.com'));
        expect(json['description'], equals('A great restaurant'));
        expect(json['website'], equals('https://testrestaurant.com'));
        expect(json['businessType'], equals('Restaurant'));
        expect(json['categories'], equals(['Food', 'Dining']));
        expect(json['isVerified'], isTrue);
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
        expect(json['createdBy'], equals('user-123'));
        expect(json['verification'], isNotNull);
      });

      test('should serialize Stripe Connect account ID to JSON', () {
        final account = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          stripeConnectAccountId: 'acct_1234567890',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final json = account.toJson();

        expect(json['stripeConnectAccountId'], equals('acct_1234567890'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'business-123',
          'name': 'Test Restaurant',
          'email': 'test@restaurant.com',
          'description': 'A great restaurant',
          'website': 'https://testrestaurant.com',
          'location': '123 Main St',
          'phone': '+1-555-0123',
          'logoUrl': 'https://testrestaurant.com/logo.png',
          'businessType': 'Restaurant',
          'categories': ['Food', 'Dining'],
          'requiredExpertise': ['Culinary'],
          'preferredCommunities': ['community-1'],
          'preferredLocation': 'NYC',
          'minExpertLevel': 3,
          'isActive': true,
          'isVerified': true,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'createdBy': 'user-123',
          'connectedExpertIds': ['expert-1'],
          'pendingConnectionIds': ['expert-2'],
          'stripeConnectAccountId': 'acct_1234567890',
        };

        final account = BusinessAccount.fromJson(json);

        expect(account.id, equals('business-123'));
        expect(account.name, equals('Test Restaurant'));
        expect(account.email, equals('test@restaurant.com'));
        expect(account.description, equals('A great restaurant'));
        expect(account.website, equals('https://testrestaurant.com'));
        expect(account.location, equals('123 Main St'));
        expect(account.phone, equals('+1-555-0123'));
        expect(account.logoUrl, equals('https://testrestaurant.com/logo.png'));
        expect(account.businessType, equals('Restaurant'));
        expect(account.categories, equals(['Food', 'Dining']));
        expect(account.requiredExpertise, equals(['Culinary']));
        expect(account.preferredCommunities, equals(['community-1']));
        expect(account.preferredLocation, equals('NYC'));
        expect(account.minExpertLevel, equals(3));
        expect(account.isActive, isTrue);
        expect(account.isVerified, isTrue);
        expect(account.createdAt, equals(testDate));
        expect(account.updatedAt, equals(testDate));
        expect(account.createdBy, equals('user-123'));
        expect(account.connectedExpertIds, equals(['expert-1']));
        expect(account.pendingConnectionIds, equals(['expert-2']));
        expect(account.stripeConnectAccountId, equals('acct_1234567890'));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'business-123',
          'name': 'Test Restaurant',
          'email': 'test@restaurant.com',
          'businessType': 'Restaurant',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'createdBy': 'user-123',
        };

        final account = BusinessAccount.fromJson(json);

        expect(account.description, isNull);
        expect(account.website, isNull);
        expect(account.location, isNull);
        expect(account.phone, isNull);
        expect(account.logoUrl, isNull);
        expect(account.categories, isEmpty);
        expect(account.requiredExpertise, isEmpty);
        expect(account.preferredCommunities, isEmpty);
        expect(account.expertPreferences, isNull);
        expect(account.patronPreferences, isNull);
        expect(account.verification, isNull);
      });

      test('should handle nested preferences in JSON', () {
        final expertPrefsJson = {
          'requiredExpertiseCategories': ['Coffee'],
          'minExpertLevel': 3,
        };

        final patronPrefsJson = {
          'preferredInterests': ['Food'],
        };

        final verificationJson = {
          'id': 'verification-123',
          'businessAccountId': 'business-123',
          'status': 'verified',
          'submittedAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final json = {
          'id': 'business-123',
          'name': 'Test Restaurant',
          'email': 'test@restaurant.com',
          'businessType': 'Restaurant',
          'expertPreferences': expertPrefsJson,
          'patronPreferences': patronPrefsJson,
          'verification': verificationJson,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'createdBy': 'user-123',
        };

        final account = BusinessAccount.fromJson(json);

        expect(account.expertPreferences, isNotNull);
        expect(account.expertPreferences!.requiredExpertiseCategories, equals(['Coffee']));
        expect(account.expertPreferences!.minExpertLevel, equals(3));
        expect(account.patronPreferences, isNotNull);
        expect(account.patronPreferences!.preferredInterests, equals(['Food']));
        expect(account.verification, isNotNull);
        expect(account.verification!.status, equals(VerificationStatus.verified));
      });
    });

    group('copyWith', () {
      test('should create copy with modified fields', () {
        final original = BusinessAccount(
          id: 'business-123',
          name: 'Original Name',
          email: 'original@test.com',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          email: 'updated@test.com',
          isActive: false,
        );

        expect(updated.id, equals('business-123')); // Unchanged
        expect(updated.name, equals('Updated Name')); // Changed
        expect(updated.email, equals('updated@test.com')); // Changed
        expect(updated.businessType, equals('Restaurant')); // Unchanged
        expect(updated.isActive, isFalse); // Changed
        expect(updated.createdAt, equals(testDate)); // Unchanged
      });

      test('should create copy with null fields', () {
        final original = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          description: 'Original description',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        // Note: copyWith doesn't support null values - passing null keeps original value
        // This is standard Dart copyWith behavior using ?? operator
        final updated = original.copyWith(description: null);

        expect(updated.description, equals('Original description')); // Keeps original value
        expect(updated.name, equals('Test Restaurant')); // Unchanged
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final account1 = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final account2 = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(account1, equals(account2));
      });

      test('should not be equal when properties differ', () {
        final account1 = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final account2 = BusinessAccount(
          id: 'business-456', // Different ID
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(account1, isNot(equals(account2)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        final account = BusinessAccount(
          id: 'business-123',
          name: '',
          email: '',
          businessType: '',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: '',
        );

        expect(account.name, isEmpty);
        expect(account.email, isEmpty);
        expect(account.businessType, isEmpty);
        expect(account.createdBy, isEmpty);
      });

      test('should handle very long strings', () {
        final longName = 'A' * 1000;
        final longDescription = 'B' * 5000;

        final account = BusinessAccount(
          id: 'business-123',
          name: longName,
          email: 'test@restaurant.com',
          description: longDescription,
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(account.name, equals(longName));
        expect(account.description, equals(longDescription));
      });

      test('should handle special characters in strings', () {
        final account = BusinessAccount(
          id: 'business-123',
          name: r'Restaurant @#$%^&*()_+ Name',
          email: 'test+special@restaurant-domain.co.uk',
          description: r'Description with !@#$%^&*()_+ chars',
          businessType: 'Restaurant & Café',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(account.name, contains(r'@#$%^&*()_+'));
        expect(account.email, contains('+'));
        expect(account.description, contains(r'!@#$%^&*()_+'));
        expect(account.businessType, contains('&'));
      });

      test('should handle unicode characters', () {
        final account = BusinessAccount(
          id: 'business-123',
          name: 'Café Münü 我的餐厅',
          email: 'café@тест.рф',
          description: 'Descripción con ñ, à, é, î, ö, ü',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(account.name, contains('我的餐厅'));
        expect(account.email, contains('тест.рф'));
        expect(account.description, contains('ñ'));
      });
    });
  });
}

