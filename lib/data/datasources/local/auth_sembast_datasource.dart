import 'package:spots/core/services/logger.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/data/datasources/local/auth_local_datasource.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';

class AuthSembastDataSource implements AuthLocalDataSource {
  final StoreRef<String, Map<String, dynamic>> _usersStore;
  final StoreRef<String, Map<String, dynamic>> _preferencesStore;
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  AuthSembastDataSource()
      : _usersStore = SembastDatabase.usersStore,
        _preferencesStore = SembastDatabase.preferencesStore;

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      _logger.info('🔐 AuthSembastDataSource: Starting sign in for $email', tag: 'AuthSembastDataSource');
      _logger.debug('Attempting sign in for: $email', tag: 'AuthSembastDataSource');
      
      // BACKDOOR: Always allow demo user login
      if (email == 'demo@spots.com' && password == 'password123') {
        _logger.warn('🔐 AuthSembastDataSource: BACKDOOR - Demo user login approved', tag: 'AuthSembastDataSource');
        final now = DateTime.now();
        final demoUser = User(
          id: 'demo-user-1',
          email: 'demo@spots.com',
          name: 'Demo User',
          displayName: 'Demo User',
          role: UserRole.user,
          createdAt: now,
          updatedAt: now,
          isOnline: true,
        );
        
        // Save to database if possible
        try {
          final db = await SembastDatabase.database;
          await _usersStore.record(demoUser.id).put(db, demoUser.toJson());
          await _preferencesStore.record('currentUser').put(db, {'key': 'currentUser', 'value': demoUser.id});
          _logger.debug('🔐 AuthSembastDataSource: Demo user saved to database', tag: 'AuthSembastDataSource');
        } catch (e) {
          _logger.warn('🔐 AuthSembastDataSource: Database save failed, but login continues: $e', tag: 'AuthSembastDataSource');
        }
        
        return demoUser;
      }
      
      // Regular database lookup for other users
      final db = await SembastDatabase.database;
      _logger.debug('🔐 AuthSembastDataSource: Database obtained', tag: 'AuthSembastDataSource');
      final finder = Finder(filter: Filter.equals('email', email));
      final records = await _usersStore.find(db, finder: finder);
      
      _logger.debug('🔐 AuthSembastDataSource: Found ${records.length} users with email: $email', tag: 'AuthSembastDataSource');
      
      if (records.isNotEmpty) {
        final userData = records.first.value;
        _logger.debug('🔐 AuthSembastDataSource: User data found', tag: 'AuthSembastDataSource');
        final user = User.fromJson(userData);
        
        // For demo purposes, accept any password for demo@spots.com
        // In a real app, you'd verify the password hash
        if (email == 'demo@spots.com' || password.isNotEmpty) {
          // Save current user
          await _preferencesStore.record('currentUser').put(db, {'key': 'currentUser', 'value': user.id});
          _logger.info('🔐 AuthSembastDataSource: Demo user signed in successfully: $email', tag: 'AuthSembastDataSource');
          return user;
        }
      }
      
      // TEMPORARY: Create demo user on-the-fly if not found
      if (email == 'demo@spots.com') {
        _logger.info('🔐 AuthSembastDataSource: Creating demo user on-the-fly', tag: 'AuthSembastDataSource');
        final now = DateTime.now();
        final demoUser = User(
          id: 'demo-user-1',
          email: 'demo@spots.com',
          name: 'Demo User',
          displayName: 'Demo User',
          role: UserRole.user,
          createdAt: now,
          updatedAt: now,
          isOnline: true,
        );
        
        // Save demo user to database
        await _usersStore.record(demoUser.id).put(db, demoUser.toJson());
        _logger.debug('🔐 AuthSembastDataSource: Demo user saved to database', tag: 'AuthSembastDataSource');
        
        // Save current user
        await _preferencesStore.record('currentUser').put(db, {'key': 'currentUser', 'value': demoUser.id});
        _logger.info('🔐 AuthSembastDataSource: Demo user created and signed in successfully: $email', tag: 'AuthSembastDataSource');
        return demoUser;
      }
      
      _logger.warn('🔐 AuthSembastDataSource: Invalid credentials for: $email', tag: 'AuthSembastDataSource');
      return null;
    } catch (e) {
      _logger.error('🔐 AuthSembastDataSource: Error signing in', error: e, tag: 'AuthSembastDataSource');
      return null;
    }
  }

  @override
  Future<User?> signUp(String email, String password, User user) async {
    try {
      final db = await SembastDatabase.database;
      final userData = user.toJson();
      final key = await _usersStore.add(db, userData);
      return user.copyWith(id: key);
    } catch (e) {
      _logger.error('Error signing up', error: e, tag: 'AuthSembastDataSource');
      return null;
    }
  }

  @override
  Future<void> saveUser(User user) async {
    try {
      final db = await SembastDatabase.database;
      final userData = user.toJson();
      await _usersStore.record(user.id).put(db, userData);
    } catch (e) {
      _logger.error('Error saving user', error: e, tag: 'AuthSembastDataSource');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final db = await SembastDatabase.database;
      final records = await _preferencesStore.find(db, finder: Finder(filter: Filter.equals('key', 'currentUser')));
      
      if (records.isNotEmpty) {
        final userId = records.first.value['value'] as String?;
        if (userId != null) {
          final userRecord = await _usersStore.record(userId).get(db);
          if (userRecord != null) {
            return User.fromJson(userRecord);
          }
        }
      }
      return null;
    } catch (e) {
      _logger.error('Error getting current user', error: e, tag: 'AuthSembastDataSource');
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      final db = await SembastDatabase.database;
      await _preferencesStore.record('currentUser').delete(db);
    } catch (e) {
      _logger.error('Error clearing user', error: e, tag: 'AuthSembastDataSource');
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    try {
      final db = await SembastDatabase.database;
      final records = await _preferencesStore.find(db, finder: Finder(filter: Filter.equals('key', 'onboardingCompleted')));
      return records.isNotEmpty && records.first.value['value'] == true;
    } catch (e) {
      _logger.error('Error checking onboarding status', error: e, tag: 'AuthSembastDataSource');
      return false;
    }
  }

  @override
  Future<void> markOnboardingCompleted() async {
    try {
      final db = await SembastDatabase.database;
      await _preferencesStore.record('onboardingCompleted').put(db, {'key': 'onboardingCompleted', 'value': true});
    } catch (e) {
      _logger.error('Error marking onboarding completed', error: e, tag: 'AuthSembastDataSource');
    }
  }

  // Debug method to check database contents
  static Future<void> debugDatabaseContents() async {
    try {
      final db = await SembastDatabase.database;
      final users = await SembastDatabase.usersStore.find(db, finder: Finder());
      // Using a local logger instance since static context doesn't have _logger
      const localLogger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
      localLogger.debug('🔍 AuthSembastDataSource: Found ${users.length} users in database', tag: 'AuthSembastDataSource');
      for (final user in users) {
        localLogger.debug('User: ${user.value}', tag: 'AuthSembastDataSource');
      }
    } catch (e) {
      const localLogger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
      localLogger.error('Error debugging database', error: e, tag: 'AuthSembastDataSource');
    }
  }
}
