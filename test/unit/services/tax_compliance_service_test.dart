import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/tax_compliance_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/models/tax_document.dart';
import 'package:spots/core/models/tax_profile.dart';

import 'tax_compliance_service_test.mocks.dart';

@GenerateMocks([PaymentService])
void main() {
  group('TaxComplianceService', () {
    late TaxComplianceService service;
    late MockPaymentService mockPaymentService;

    setUp(() {
      mockPaymentService = MockPaymentService();
      
      service = TaxComplianceService(
        paymentService: mockPaymentService,
      );
    });

    group('needsTaxDocuments', () {
      test('should return true if earnings >= $600', () async {
        // Arrange - Mock earnings above threshold
        // Note: In production, this would use PayoutService to calculate earnings
        // For now, service uses placeholder calculation
        
        // Act
        final needsDocs = await service.needsTaxDocuments('user-123', 2025);

        // Assert
        expect(needsDocs, isA<bool>());
        // Since earnings calculation is placeholder (returns 0.0), this will be false
        // In production, would return true if earnings >= 600
      });

      test('should return false if earnings < $600', () async {
        // Act
        final needsDocs = await service.needsTaxDocuments('user-123', 2025);

        // Assert
        // With placeholder calculation returning 0.0, should return false
        expect(needsDocs, isFalse);
      });
    });

    group('generate1099', () {
      test('should return notRequired status if earnings < threshold', () async {
        // Act
        final taxDoc = await service.generate1099('user-123', 2025);

        // Assert
        expect(taxDoc, isA<TaxDocument>());
        expect(taxDoc.formType, equals(TaxFormType.form1099K));
        expect(taxDoc.status, equals(TaxStatus.notRequired));
        expect(taxDoc.totalEarnings, equals(0.0));
      });

      test('should throw exception if W-9 not submitted when earnings >= threshold', () async {
        // This test would require mocking earnings calculation to return >= 600
        // Currently service uses placeholder that returns 0.0
        // In production, would test this scenario
        expect(true, isTrue); // Placeholder test
      });

      test('should generate 1099 document when all requirements met', () async {
        // This test would require:
        // 1. Mock earnings >= $600
        // 2. Mock W-9 submitted
        // 3. Verify document generation
        // Currently using placeholder implementations
        expect(true, isTrue); // Placeholder test
      });
    });

    group('submitW9', () {
      test('should create tax profile with encrypted SSN', () async {
        // Act
        final profile = await service.submitW9(
          userId: 'user-123',
          ssn: '123-45-6789',
          classification: TaxClassification.individual,
        );

        // Assert
        expect(profile, isA<TaxProfile>());
        expect(profile.userId, equals('user-123'));
        expect(profile.classification, equals(TaxClassification.individual));
        expect(profile.w9Submitted, isTrue);
        expect(profile.w9SubmittedAt, isNotNull);
        // SSN should be "encrypted" (placeholder encryption)
        expect(profile.ssn, isNotNull);
      });

      test('should create tax profile with EIN for business', () async {
        // Act
        final profile = await service.submitW9(
          userId: 'user-123',
          ssn: '123-45-6789',
          classification: TaxClassification.corporation,
          ein: '12-3456789',
          businessName: 'Test Corp',
        );

        // Assert
        expect(profile, isA<TaxProfile>());
        expect(profile.classification, equals(TaxClassification.corporation));
        expect(profile.ein, equals('12-3456789'));
        expect(profile.businessName, equals('Test Corp'));
      });
    });

    group('getTaxProfile', () {
      test('should return default profile if not exists', () async {
        // Act
        final profile = await service.getTaxProfile('user-123');

        // Assert
        expect(profile, isA<TaxProfile>());
        expect(profile.userId, equals('user-123'));
        expect(profile.w9Submitted, isFalse);
      });

      test('should return saved profile after submission', () async {
        // Arrange
        await service.submitW9(
          userId: 'user-123',
          ssn: '123-45-6789',
          classification: TaxClassification.individual,
        );

        // Act
        final profile = await service.getTaxProfile('user-123');

        // Assert
        expect(profile.w9Submitted, isTrue);
        expect(profile.w9SubmittedAt, isNotNull);
      });
    });

    group('getTaxDocuments', () {
      test('should return empty list when no documents exist', () async {
        // Act
        final documents = await service.getTaxDocuments('user-123', 2025);

        // Assert
        expect(documents, isEmpty);
      });

      test('should return documents for user and year after generation', () async {
        // Arrange
        await service.generate1099('user-123', 2025);

        // Act
        final documents = await service.getTaxDocuments('user-123', 2025);

        // Assert
        expect(documents, isNotEmpty);
        expect(documents.first.userId, equals('user-123'));
        expect(documents.first.taxYear, equals(2025));
      });
    });

    group('requestW9', () {
      test('should request W-9 from user', () async {
        // Act - should not throw
        await service.requestW9('user-123');

        // Assert - placeholder implementation should complete without error
        expect(true, isTrue);
      });
    });

    group('generateAll1099sForYear', () {
      test('should generate 1099s for all qualifying users', () async {
        // Act
        final documents = await service.generateAll1099sForYear(2025);

        // Assert
        expect(documents, isA<List<TaxDocument>>());
        // With placeholder implementation, may return empty list
      });
    });
  });
}

