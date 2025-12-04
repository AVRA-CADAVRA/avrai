import 'package:spots/core/models/tax_profile.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/core/services/logger.dart';

/// Tax Profile Repository
/// 
/// Handles persistence of tax profiles using Sembast database.
class TaxProfileRepository {
  static const AppLogger _logger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  /// Save tax profile
  Future<void> saveTaxProfile(TaxProfile profile) async {
    try {
      final db = await SembastDatabase.database;
      await SembastDatabase.taxProfilesStore.record(profile.userId).put(
        db,
        profile.toJson(),
      );
      _logger.info('Tax profile saved: ${profile.userId}', tag: 'TaxProfileRepository');
    } catch (e) {
      _logger.error('Failed to save tax profile', error: e, tag: 'TaxProfileRepository');
      rethrow;
    }
  }
  
  /// Get tax profile by user ID
  Future<TaxProfile?> getTaxProfile(String userId) async {
    try {
      final db = await SembastDatabase.database;
      final data = await SembastDatabase.taxProfilesStore.record(userId).get(db);
      
      if (data == null) {
        return null;
      }
      
      return TaxProfile.fromJson(data);
    } catch (e) {
      _logger.error('Failed to get tax profile', error: e, tag: 'TaxProfileRepository');
      rethrow;
    }
  }
  
  /// Get all tax profiles
  Future<List<TaxProfile>> getAllTaxProfiles() async {
    try {
      final db = await SembastDatabase.database;
      final records = await SembastDatabase.taxProfilesStore.find(db);
      
      return records.map((record) => TaxProfile.fromJson(record.value)).toList();
    } catch (e) {
      _logger.error('Failed to get all tax profiles', error: e, tag: 'TaxProfileRepository');
      rethrow;
    }
  }
  
  /// Get users with W-9 submitted
  Future<List<String>> getUsersWithW9() async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(filter: Filter.equals('w9Submitted', true));
      final records = await SembastDatabase.taxProfilesStore.find(db, finder: finder);
      
      return records.map((record) => record.key).toList();
    } catch (e) {
      _logger.error('Failed to get users with W-9', error: e, tag: 'TaxProfileRepository');
      rethrow;
    }
  }
  
  /// Delete tax profile
  Future<void> deleteTaxProfile(String userId) async {
    try {
      final db = await SembastDatabase.database;
      await SembastDatabase.taxProfilesStore.record(userId).delete(db);
      _logger.info('Tax profile deleted: $userId', tag: 'TaxProfileRepository');
    } catch (e) {
      _logger.error('Failed to delete tax profile', error: e, tag: 'TaxProfileRepository');
      rethrow;
    }
  }
}

