import 'package:flutter_test/flutter_test.dart';
import 'package:spots/data/repositories/tax_profile_repository.dart';
import 'package:spots/core/models/tax_profile.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:sembast/sembast.dart' as sembast;

/// SPOTS TaxProfileRepository Unit Tests
/// Date: December 1, 2025
/// Purpose: Test TaxProfileRepository functionality
/// 
/// Test Coverage:
/// - Save tax profile
/// - Get tax profile by user ID
/// - Get all tax profiles
/// - Get users with W-9 submitted
/// - Delete tax profile
/// - Error handling
/// 
/// Dependencies:
/// - SembastDatabase: In-memory database for testing
/// - TaxProfile: Tax profile model

void main() {
  group('TaxProfileRepository', () {
    late TaxProfileRepository repository;
    late TaxProfile testProfile;
    late DateTime testDate;

    setUp(() async {
      // Use in-memory database for tests
      SembastDatabase.useInMemoryForTests();
      repository = TaxProfileRepository();
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      // Clear store before each test for isolation
      final db = await SembastDatabase.database;
      final records = await SembastDatabase.taxProfilesStore.find(db, finder: sembast.Finder());
      for (final record in records) {
        await SembastDatabase.taxProfilesStore.record(record.key).delete(db);
      }
      
      testProfile = TaxProfile(
        userId: 'user-123',
        classification: TaxClassification.individual,
        w9Submitted: true,
        w9SubmittedAt: testDate,
        ssn: '123-45-6789',
      );
    });

    group('saveTaxProfile', () {
      test('should save tax profile successfully', () async {
        await expectLater(
          repository.saveTaxProfile(testProfile),
          completes,
        );
      });

      test('should update existing tax profile', () async {
        // Save initial profile
        await repository.saveTaxProfile(testProfile);
        
        // Update profile - create new profile with updated values
        // Note: copyWith may not handle null explicitly, so create new instance
        final updated = TaxProfile(
          userId: testProfile.userId,
          classification: testProfile.classification,
          w9Submitted: false,
          w9SubmittedAt: null, // Explicitly null
          ssn: testProfile.ssn,
        );
        await repository.saveTaxProfile(updated);
        
        // Verify update
        final retrieved = await repository.getTaxProfile('user-123');
        expect(retrieved, isNotNull);
        expect(retrieved?.w9Submitted, false);
        expect(retrieved?.w9SubmittedAt, isNull);
      });

      test('should save profile with business information', () async {
        final businessProfile = TaxProfile(
          userId: 'user-456',
          classification: TaxClassification.llc,
          w9Submitted: true,
          w9SubmittedAt: testDate,
          businessName: 'Test Business LLC',
          ein: '12-3456789',
        );
        
        await repository.saveTaxProfile(businessProfile);
        
        final retrieved = await repository.getTaxProfile('user-456');
        expect(retrieved, isNotNull);
        expect(retrieved?.businessName, 'Test Business LLC');
        expect(retrieved?.ein, '12-3456789');
        expect(retrieved?.classification, TaxClassification.llc);
      });
    });

    group('getTaxProfile', () {
      test('should get tax profile by user ID', () async {
        await repository.saveTaxProfile(testProfile);
        
        final retrieved = await repository.getTaxProfile('user-123');
        
        expect(retrieved, isNotNull);
        expect(retrieved?.userId, 'user-123');
        expect(retrieved?.classification, TaxClassification.individual);
        expect(retrieved?.w9Submitted, true);
        expect(retrieved?.w9SubmittedAt, testDate);
        expect(retrieved?.ssn, '123-45-6789');
      });

      test('should return null for non-existent profile', () async {
        final retrieved = await repository.getTaxProfile('non-existent');
        
        expect(retrieved, isNull);
      });
    });

    group('getAllTaxProfiles', () {
      test('should get all tax profiles', () async {
        // Save multiple profiles
        final profile1 = testProfile;
        final profile2 = TaxProfile(
          userId: 'user-456',
          classification: TaxClassification.soleProprietor,
          w9Submitted: false,
        );
        final profile3 = TaxProfile(
          userId: 'user-789',
          classification: TaxClassification.corporation,
          w9Submitted: true,
          w9SubmittedAt: testDate,
        );
        
        await repository.saveTaxProfile(profile1);
        await repository.saveTaxProfile(profile2);
        await repository.saveTaxProfile(profile3);
        
        final profiles = await repository.getAllTaxProfiles();
        
        expect(profiles.length, 3);
        expect(profiles.any((p) => p.userId == 'user-123'), isTrue);
        expect(profiles.any((p) => p.userId == 'user-456'), isTrue);
        expect(profiles.any((p) => p.userId == 'user-789'), isTrue);
      });

      test('should return empty list when no profiles exist', () async {
        final profiles = await repository.getAllTaxProfiles();
        
        expect(profiles, isEmpty);
      });
    });

    group('getUsersWithW9', () {
      test('should get users with W-9 submitted', () async {
        // Save profiles with different W-9 statuses
        final profile1 = testProfile; // w9Submitted: true
        final profile2 = TaxProfile(
          userId: 'user-456',
          classification: TaxClassification.individual,
          w9Submitted: false, // Not submitted
        );
        final profile3 = TaxProfile(
          userId: 'user-789',
          classification: TaxClassification.soleProprietor,
          w9Submitted: true, // Submitted
          w9SubmittedAt: testDate,
        );
        
        await repository.saveTaxProfile(profile1);
        await repository.saveTaxProfile(profile2);
        await repository.saveTaxProfile(profile3);
        
        final userIds = await repository.getUsersWithW9();
        
        expect(userIds.length, 2);
        expect(userIds.contains('user-123'), isTrue);
        expect(userIds.contains('user-789'), isTrue);
        expect(userIds.contains('user-456'), isFalse);
      });

      test('should return empty list when no users have W-9 submitted', () async {
        final profile = TaxProfile(
          userId: 'user-123',
          classification: TaxClassification.individual,
          w9Submitted: false,
        );
        await repository.saveTaxProfile(profile);
        
        final userIds = await repository.getUsersWithW9();
        
        expect(userIds, isEmpty);
      });
    });

    group('deleteTaxProfile', () {
      test('should delete tax profile successfully', () async {
        await repository.saveTaxProfile(testProfile);
        
        await expectLater(
          repository.deleteTaxProfile('user-123'),
          completes,
        );
        
        // Verify deletion
        final retrieved = await repository.getTaxProfile('user-123');
        expect(retrieved, isNull);
      });

      test('should handle deletion of non-existent profile', () async {
        await expectLater(
          repository.deleteTaxProfile('non-existent'),
          completes,
        );
      });
    });
  });
}

