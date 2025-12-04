import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/app.dart';
import 'package:spots/injection_container.dart' as di;
import 'package:spots/data/datasources/local/sembast_seeder.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/data/datasources/local/auth_sembast_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:spots/core/services/storage_health_checker.dart';
import 'package:spots/core/services/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const logger = AppLogger(defaultTag: 'MAIN', minimumLevel: LogLevel.debug);

  // Initialize Firebase (mobile and desktop; web via options)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.info('Firebase initialized');
  } catch (e) {
    logger.warn('Firebase init skipped or failed: $e');
  }
  
  // Helper function to check if data already exists
  Future<bool> _checkIfDataExists() async {
    try {
      final db = await SembastDatabase.database;
      final users = await SembastDatabase.usersStore.find(db, finder: Finder());
      logger.debug('Found ${users.length} users in database');
      return users.isNotEmpty;
    } catch (e) {
      logger.error('Error checking data', error: e);
      return false;
    }
  }
  
  try {
    // Initialize DI and backend (spots_network creates Supabase backend under the hood)
    logger.info('Initializing dependency injection...');
    await di.init();
    logger.info('Dependency injection initialized.');

    // Storage health check (non-fatal)
    try {
      final client = Supabase.instance.client;
      final storageHealth = StorageHealthChecker(client);
      final results = await storageHealth.checkAllBuckets([
        'user-avatars',
        'spot-images',
        'list-images',
      ]);
      logger.info('Storage health: ' + results.entries
          .map((e) => '${e.key}=${e.value ? 'OK' : 'FAIL'}')
          .join(', '));
    } catch (e) {
      logger.warn('Storage health check error: $e');
    }
    
    // Initialize Sembast database (works on both web and mobile now)
    logger.info('Initializing Sembast database...');
    final database = await SembastDatabase.database;
    logger.info('Sembast database initialized.');
    
    // Check if data already exists before seeding
    final hasData = await _checkIfDataExists();
    if (!hasData) {
      logger.info('Seeding demo data...');
      await SembastSeeder.seedDatabase();
      logger.info('Demo data seeded.');
    } else {
      logger.info('Data already exists, skipping seeding.');
    }
    
    // Debug: Check database contents
    await AuthSembastDataSource.debugDatabaseContents();
    
    // Also check if demo user exists specifically
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(filter: Filter.equals('email', 'demo@spots.com'));
      final records = await SembastDatabase.usersStore.find(db, finder: finder);
      logger.debug('Found ${records.length} demo users in database');
      for (final record in records) {
        logger.debug('Demo user record: ${record.value}');
      }
      
      // Test the auth data source directly
      final authDataSource = AuthSembastDataSource();
      final testUser = await authDataSource.signIn('demo@spots.com', 'password123');
      logger.debug('Direct auth test result: ${testUser?.email ?? 'null'}');
    } catch (e) {
      logger.warn('Error checking demo user: $e');
    }

    logger.info('Running app...');
    runApp(const SpotsApp());
  } catch (e) {
    logger.error('Error during app initialization', error: e);
    // Still run the app even if there are errors
    runApp(const SpotsApp());
  }
}
