import 'package:flutter_test/flutter_test.dart';
import 'package:spots/data/repositories/tax_document_repository.dart';
import 'package:spots/core/models/tax_document.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:sembast/sembast.dart' as sembast;

/// SPOTS TaxDocumentRepository Unit Tests
/// Date: December 1, 2025
/// Purpose: Test TaxDocumentRepository functionality
/// 
/// Test Coverage:
/// - Save tax document
/// - Get tax document by ID
/// - Get tax documents for user and year
/// - Get all tax documents for user
/// - Get tax documents for year
/// - Get users with earnings above threshold
/// - Delete tax document
/// - Error handling
/// 
/// Dependencies:
/// - SembastDatabase: In-memory database for testing
/// - TaxDocument: Tax document model

void main() {
  group('TaxDocumentRepository', () {
    late TaxDocumentRepository repository;
    late TaxDocument testDocument;
    late DateTime testDate;

    setUp(() async {
      // Use in-memory database for tests
      SembastDatabase.useInMemoryForTests();
      repository = TaxDocumentRepository();
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      // Clear store before each test for isolation
      final db = await SembastDatabase.database;
      final records = await SembastDatabase.taxDocumentsStore.find(db, finder: sembast.Finder());
      for (final record in records) {
        await SembastDatabase.taxDocumentsStore.record(record.key).delete(db);
      }
      
      testDocument = TaxDocument(
        id: 'tax-doc-123',
        userId: 'user-456',
        taxYear: 2025,
        formType: TaxFormType.form1099K,
        totalEarnings: 1250.00,
        status: TaxStatus.generated,
        generatedAt: testDate,
      );
    });

    group('saveTaxDocument', () {
      test('should save tax document successfully', () async {
        await expectLater(
          repository.saveTaxDocument(testDocument),
          completes,
        );
      });

      test('should update existing tax document', () async {
        // Save initial document
        await repository.saveTaxDocument(testDocument);
        
        // Update document
        final updated = testDocument.copyWith(
          status: TaxStatus.sent,
          documentUrl: 'https://example.com/doc.pdf',
        );
        await repository.saveTaxDocument(updated);
        
        // Verify update
        final retrieved = await repository.getTaxDocument('tax-doc-123');
        expect(retrieved, isNotNull);
        expect(retrieved?.status, TaxStatus.sent);
        expect(retrieved?.documentUrl, 'https://example.com/doc.pdf');
      });
    });

    group('getTaxDocument', () {
      test('should get tax document by ID', () async {
        await repository.saveTaxDocument(testDocument);
        
        final retrieved = await repository.getTaxDocument('tax-doc-123');
        
        expect(retrieved, isNotNull);
        expect(retrieved?.id, 'tax-doc-123');
        expect(retrieved?.userId, 'user-456');
        expect(retrieved?.taxYear, 2025);
        expect(retrieved?.formType, TaxFormType.form1099K);
        expect(retrieved?.totalEarnings, 1250.00);
        expect(retrieved?.status, TaxStatus.generated);
      });

      test('should return null for non-existent document', () async {
        final retrieved = await repository.getTaxDocument('non-existent');
        
        expect(retrieved, isNull);
      });
    });

    group('getTaxDocuments', () {
      test('should get tax documents for user and year', () async {
        // Save multiple documents
        final doc1 = testDocument;
        final doc2 = testDocument.copyWith(
          id: 'tax-doc-124',
          formType: TaxFormType.form1099NEC,
        );
        final doc3 = testDocument.copyWith(
          id: 'tax-doc-125',
          userId: 'user-789', // Different user
        );
        
        await repository.saveTaxDocument(doc1);
        await repository.saveTaxDocument(doc2);
        await repository.saveTaxDocument(doc3);
        
        final documents = await repository.getTaxDocuments('user-456', 2025);
        
        expect(documents.length, 2);
        expect(documents.any((d) => d.id == 'tax-doc-123'), isTrue);
        expect(documents.any((d) => d.id == 'tax-doc-124'), isTrue);
        expect(documents.any((d) => d.id == 'tax-doc-125'), isFalse);
      });

      test('should return empty list when no documents match', () async {
        final documents = await repository.getTaxDocuments('user-999', 2024);
        
        expect(documents, isEmpty);
      });
    });

    group('getAllTaxDocuments', () {
      test('should get all tax documents for user', () async {
        // Save documents for same user across different years
        final doc1 = testDocument;
        final doc2 = testDocument.copyWith(
          id: 'tax-doc-124',
          taxYear: 2024,
        );
        final doc3 = testDocument.copyWith(
          id: 'tax-doc-125',
          userId: 'user-789', // Different user
        );
        
        await repository.saveTaxDocument(doc1);
        await repository.saveTaxDocument(doc2);
        await repository.saveTaxDocument(doc3);
        
        final documents = await repository.getAllTaxDocuments('user-456');
        
        expect(documents.length, 2);
        expect(documents.any((d) => d.id == 'tax-doc-123'), isTrue);
        expect(documents.any((d) => d.id == 'tax-doc-124'), isTrue);
        expect(documents.any((d) => d.id == 'tax-doc-125'), isFalse);
      });

      test('should return empty list when user has no documents', () async {
        final documents = await repository.getAllTaxDocuments('user-999');
        
        expect(documents, isEmpty);
      });
    });

    group('getTaxDocumentsForYear', () {
      test('should get all tax documents for a year', () async {
        // Save documents for same year but different users
        final doc1 = testDocument;
        final doc2 = testDocument.copyWith(
          id: 'tax-doc-124',
          userId: 'user-789',
        );
        final doc3 = testDocument.copyWith(
          id: 'tax-doc-125',
          taxYear: 2024, // Different year
        );
        
        await repository.saveTaxDocument(doc1);
        await repository.saveTaxDocument(doc2);
        await repository.saveTaxDocument(doc3);
        
        final documents = await repository.getTaxDocumentsForYear(2025);
        
        expect(documents.length, 2);
        expect(documents.any((d) => d.id == 'tax-doc-123'), isTrue);
        expect(documents.any((d) => d.id == 'tax-doc-124'), isTrue);
        expect(documents.any((d) => d.id == 'tax-doc-125'), isFalse);
      });

      test('should return empty list when year has no documents', () async {
        final documents = await repository.getTaxDocumentsForYear(2020);
        
        expect(documents, isEmpty);
      });
    });

    group('getUsersWithEarningsAboveThreshold', () {
      test('should get users with earnings above threshold', () async {
        // Save documents with different earnings
        final doc1 = testDocument; // 1250.00
        final doc2 = testDocument.copyWith(
          id: 'tax-doc-124',
          userId: 'user-789',
          totalEarnings: 500.00, // Below threshold
        );
        final doc3 = testDocument.copyWith(
          id: 'tax-doc-125',
          userId: 'user-999',
          totalEarnings: 2000.00, // Above threshold
        );
        
        await repository.saveTaxDocument(doc1);
        await repository.saveTaxDocument(doc2);
        await repository.saveTaxDocument(doc3);
        
        final userIds = await repository.getUsersWithEarningsAboveThreshold(2025, 1000.0);
        
        expect(userIds.length, 2);
        expect(userIds.contains('user-456'), isTrue);
        expect(userIds.contains('user-999'), isTrue);
        expect(userIds.contains('user-789'), isFalse);
      });

      test('should return empty list when no users meet threshold', () async {
        final doc1 = testDocument.copyWith(totalEarnings: 500.00);
        await repository.saveTaxDocument(doc1);
        
        final userIds = await repository.getUsersWithEarningsAboveThreshold(2025, 1000.0);
        
        expect(userIds, isEmpty);
      });
    });

    group('deleteTaxDocument', () {
      test('should delete tax document successfully', () async {
        await repository.saveTaxDocument(testDocument);
        
        await expectLater(
          repository.deleteTaxDocument('tax-doc-123'),
          completes,
        );
        
        // Verify deletion
        final retrieved = await repository.getTaxDocument('tax-doc-123');
        expect(retrieved, isNull);
      });

      test('should handle deletion of non-existent document', () async {
        await expectLater(
          repository.deleteTaxDocument('non-existent'),
          completes,
        );
      });
    });
  });
}

