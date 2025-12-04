import 'package:spots/core/models/tax_document.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/core/services/logger.dart';

/// Tax Document Repository
/// 
/// Handles persistence of tax documents using Sembast database.
class TaxDocumentRepository {
  static const AppLogger _logger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  /// Save tax document
  Future<void> saveTaxDocument(TaxDocument document) async {
    try {
      final db = await SembastDatabase.database;
      await SembastDatabase.taxDocumentsStore.record(document.id).put(
        db,
        document.toJson(),
      );
      _logger.info('Tax document saved: ${document.id}', tag: 'TaxDocumentRepository');
    } catch (e) {
      _logger.error('Failed to save tax document', error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }
  
  /// Get tax document by ID
  Future<TaxDocument?> getTaxDocument(String documentId) async {
    try {
      final db = await SembastDatabase.database;
      final data = await SembastDatabase.taxDocumentsStore.record(documentId).get(db);
      
      if (data == null) {
        return null;
      }
      
      return TaxDocument.fromJson(data);
    } catch (e) {
      _logger.error('Failed to get tax document', error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }
  
  /// Get tax documents for user and year
  Future<List<TaxDocument>> getTaxDocuments(String userId, int year) async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(
        filter: Filter.and([
          Filter.equals('userId', userId),
          Filter.equals('taxYear', year),
        ]),
      );
      final records = await SembastDatabase.taxDocumentsStore.find(db, finder: finder);
      
      return records.map((record) => TaxDocument.fromJson(record.value)).toList();
    } catch (e) {
      _logger.error('Failed to get tax documents', error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }
  
  /// Get all tax documents for a user
  Future<List<TaxDocument>> getAllTaxDocuments(String userId) async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(filter: Filter.equals('userId', userId));
      final records = await SembastDatabase.taxDocumentsStore.find(db, finder: finder);
      
      return records.map((record) => TaxDocument.fromJson(record.value)).toList();
    } catch (e) {
      _logger.error('Failed to get all tax documents', error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }
  
  /// Get all tax documents for a year
  Future<List<TaxDocument>> getTaxDocumentsForYear(int year) async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(filter: Filter.equals('taxYear', year));
      final records = await SembastDatabase.taxDocumentsStore.find(db, finder: finder);
      
      return records.map((record) => TaxDocument.fromJson(record.value)).toList();
    } catch (e) {
      _logger.error('Failed to get tax documents for year', error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }
  
  /// Get users with earnings >= threshold for a year
  Future<List<String>> getUsersWithEarningsAboveThreshold(int year, double threshold) async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(
        filter: Filter.and([
          Filter.equals('taxYear', year),
          Filter.greaterThanOrEquals('totalEarnings', threshold),
        ]),
      );
      final records = await SembastDatabase.taxDocumentsStore.find(db, finder: finder);
      
      // Extract unique user IDs
      final userIds = <String>{};
      for (final record in records) {
        final doc = TaxDocument.fromJson(record.value);
        userIds.add(doc.userId);
      }
      
      return userIds.toList();
    } catch (e) {
      _logger.error('Failed to get users with earnings above threshold', error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }
  
  /// Delete tax document
  Future<void> deleteTaxDocument(String documentId) async {
    try {
      final db = await SembastDatabase.database;
      await SembastDatabase.taxDocumentsStore.record(documentId).delete(db);
      _logger.info('Tax document deleted: $documentId', tag: 'TaxDocumentRepository');
    } catch (e) {
      _logger.error('Failed to delete tax document', error: e, tag: 'TaxDocumentRepository');
      rethrow;
    }
  }
}

