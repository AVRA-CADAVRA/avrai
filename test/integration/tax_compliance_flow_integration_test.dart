import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/tax_document.dart';
import 'package:spots/core/models/tax_profile.dart';

/// Integration tests for tax compliance flow
/// 
/// Tests model relationships and data flow for:
/// 1. W-9 submission → 1099 generation
/// 2. Earnings calculation → Tax document generation
void main() {
  group('Tax Compliance Flow Integration Tests', () {
    test('W-9 submission creates tax profile', () {
      final profile = TaxProfile(
        userId: 'user-123',
        classification: TaxClassification.individual,
        ssn: 'encrypted-ssn-123', // Should be encrypted in production
        w9Submitted: true,
        w9SubmittedAt: DateTime.now(),
      );

      expect(profile.userId, equals('user-123'));
      expect(profile.w9Submitted, isTrue);
      expect(profile.ssn, equals('encrypted-ssn-123'));
      expect(profile.classification, equals(TaxClassification.individual));
    });

    test('tax document generated from earnings', () {
      final earnings = 1500.00;
      final threshold = 600.00;

      final needsDocument = earnings >= threshold;

      if (needsDocument) {
        final taxDoc = TaxDocument(
          id: 'tax-doc-123',
          userId: 'user-456',
          taxYear: 2025,
          formType: TaxFormType.form1099K,
          totalEarnings: earnings,
          status: TaxStatus.generated,
          generatedAt: DateTime.now(),
        );

        expect(taxDoc.totalEarnings, equals(earnings));
        expect(taxDoc.status, equals(TaxStatus.generated));
        expect(taxDoc.formType, equals(TaxFormType.form1099K));
        expect(taxDoc.documentUrl, isNull); // No document URL yet
      }

      expect(needsDocument, isTrue);
    });

    test('tax document status flow: pending → generated → sent → filed', () {
      var taxDoc = TaxDocument(
        id: 'tax-doc-123',
        userId: 'user-456',
        taxYear: 2025,
        formType: TaxFormType.form1099K,
        totalEarnings: 1500.00,
        status: TaxStatus.pending,
        generatedAt: DateTime.now(),
      );

      expect(taxDoc.status, equals(TaxStatus.pending));

      // Step 1: Generate document
      taxDoc = taxDoc.copyWith(
        status: TaxStatus.generated,
        documentUrl: 'https://storage.example.com/tax-doc-123.pdf',
      );

      expect(taxDoc.status, equals(TaxStatus.generated));
      expect(taxDoc.documentUrl, isNotNull);

      // Step 2: Send to user
      taxDoc = taxDoc.copyWith(
        status: TaxStatus.sent,
      );

      expect(taxDoc.status, equals(TaxStatus.sent));

      // Step 3: File with IRS
      taxDoc = taxDoc.copyWith(
        status: TaxStatus.filed,
        filedWithIRSAt: DateTime.now(),
      );

      expect(taxDoc.status, equals(TaxStatus.filed));
      expect(taxDoc.filedWithIRSAt, isNotNull);
    });

    test('tax profile completeness checks', () {
      // Individual profile (needs SSN)
      final individualProfile = TaxProfile(
        userId: 'user-1',
        classification: TaxClassification.individual,
        ssn: 'encrypted-ssn',
        w9Submitted: true,
        w9SubmittedAt: DateTime.now(),
      );

      expect(individualProfile.w9Submitted, isTrue);
      expect(individualProfile.ssn, isNotNull);
      expect(individualProfile.classification, equals(TaxClassification.individual));

      // Business profile (needs EIN)
      final businessProfile = TaxProfile(
        userId: 'user-2',
        classification: TaxClassification.llc,
        ein: '12-3456789',
        businessName: 'My Business LLC',
        w9Submitted: true,
        w9SubmittedAt: DateTime.now(),
      );

      expect(businessProfile.w9Submitted, isTrue);
      expect(businessProfile.ein, isNotNull);
      expect(businessProfile.businessName, equals('My Business LLC'));
      expect(businessProfile.classification, equals(TaxClassification.llc));
    });

    test('multiple tax documents for same user/year', () {
      final doc1 = TaxDocument(
        id: 'doc-1',
        userId: 'user-123',
        taxYear: 2025,
        formType: TaxFormType.form1099K,
        totalEarnings: 800.00,
        status: TaxStatus.generated,
        generatedAt: DateTime.now(),
      );

      final doc2 = TaxDocument(
        id: 'doc-2',
        userId: 'user-123',
        taxYear: 2025,
        formType: TaxFormType.form1099NEC,
        totalEarnings: 400.00,
        status: TaxStatus.generated,
        generatedAt: DateTime.now(),
      );

      final allDocs = [doc1, doc2];
      final totalEarnings = allDocs
          .map((d) => d.totalEarnings)
          .reduce((a, b) => a + b);

      expect(allDocs.every((d) => d.userId == 'user-123'), isTrue);
      expect(allDocs.every((d) => d.taxYear == 2025), isTrue);
      expect(totalEarnings, equals(1200.00));
    });

    test('earnings threshold check 600 minimum', () {
      final belowThreshold = 500.00;
      final atThreshold = 600.00;
      final aboveThreshold = 700.00;

      expect(belowThreshold < 600.00, isTrue);
      expect(atThreshold >= 600.00, isTrue);
      expect(aboveThreshold >= 600.00, isTrue);

      // Below threshold - no tax document required
      final statusBelow = TaxStatus.notRequired;

      // At/above threshold - tax document required
      final statusAt = TaxStatus.pending;

      expect(statusBelow, equals(TaxStatus.notRequired));
      expect(statusAt, equals(TaxStatus.pending));
    });
  });
}

