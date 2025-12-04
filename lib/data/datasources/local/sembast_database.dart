import 'package:sembast/sembast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart' as sembast_memory;
import 'package:flutter/foundation.dart';
import 'package:spots/core/services/logger.dart';

class SembastDatabase {
  static const AppLogger _logger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  static const String _preferencesStoreName = 'preferences';
  static const String _onboardingStoreName = 'onboarding';

  static Database? _database;
  static bool _initializing = false;
  static late StoreRef<String, Map<String, dynamic>> _usersStore;
  static late StoreRef<String, Map<String, dynamic>> _spotsStore;
  static late StoreRef<String, Map<String, dynamic>> _listsStore;
  static late StoreRef<String, Map<String, dynamic>> _preferencesStore;
  static late StoreRef<String, Map<String, dynamic>> _onboardingStore;

  static const String _dbName = 'spots.db';

  // Allow tests to override DB factory to in-memory
  static DatabaseFactory? _overrideFactory;
  static void useInMemoryForTests() {
    _overrideFactory = sembast_memory.databaseFactoryMemory;
  }

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    
    // Prevent concurrent initialization
    if (_initializing) {
      // Wait a bit and retry
      await Future.delayed(const Duration(milliseconds: 100));
      return database;
    }
    
    _initializing = true;
    try {
      // Database not initialized yet, initialize it
      if (_overrideFactory != null) {
        _database = await _overrideFactory!.openDatabase('spots_test.db');
      } else if (kIsWeb) {
        // Use web factory for web platform (IndexedDB)
        // On web, Sembast uses IndexedDB automatically via sembast_io
        try {
          _database = await databaseFactoryIo.openDatabase('spots_web.db');
        } catch (e) {
          // Fallback to in-memory if IndexedDB fails
          _logger.warn('IndexedDB initialization failed, using in-memory database: $e', tag: 'SembastDatabase');
          _database = await sembast_memory.databaseFactoryMemory.openDatabase('spots_web_memory.db');
        }
      } else {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final path = join(documentsDirectory.path, _dbName);
        _database = await databaseFactoryIo.openDatabase(path);
      }
      _initializing = false;
      return _database!;
    } catch (e, stackTrace) {
      _initializing = false;
      _logger.error('Database initialization failed', tag: 'SembastDatabase', error: e);
      _logger.debug('Stack trace: $stackTrace', tag: 'SembastDatabase');
      // Try fallback to in-memory database
      try {
        _database = await sembast_memory.databaseFactoryMemory.openDatabase('spots_fallback.db');
        _initializing = false;
        return _database!;
      } catch (fallbackError) {
        _logger.error('Fallback database also failed', tag: 'SembastDatabase', error: fallbackError);
        rethrow;
      }
    }
  }

  // Store references
  static final StoreRef<String, Map<String, dynamic>> usersStore = 
      stringMapStoreFactory.store('users');
  static final StoreRef<String, Map<String, dynamic>> listsStore = 
      stringMapStoreFactory.store('lists');
  static final StoreRef<String, Map<String, dynamic>> spotsStore = 
      stringMapStoreFactory.store('spots');
  static final StoreRef<String, Map<String, dynamic>> preferencesStore = 
      stringMapStoreFactory.store('preferences');
  static final StoreRef<String, Map<String, dynamic>> onboardingStore = 
      stringMapStoreFactory.store('onboarding');
  static final StoreRef<String, Map<String, dynamic>> respectsStore = 
      stringMapStoreFactory.store('respects');
  static final StoreRef<String, Map<String, dynamic>> taxProfilesStore = 
      stringMapStoreFactory.store('tax_profiles');
  static final StoreRef<String, Map<String, dynamic>> taxDocumentsStore = 
      stringMapStoreFactory.store('tax_documents');
}
