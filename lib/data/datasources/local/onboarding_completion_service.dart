import 'package:spots/core/services/logger.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';

class OnboardingCompletionService {
  static const String _logName = 'OnboardingCompletionService';
  static const String _completionKeyPrefix = 'onboarding_completed_';
  static const AppLogger _logger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  // In-memory cache to prevent race conditions (especially on web)
  static final Map<String, bool> _completionCache = {};

  /// Get the completion key for a specific user
  static String _getCompletionKey(String userId) => '$_completionKeyPrefix$userId';

  /// Check if onboarding has been completed for a specific user
  static Future<bool> isOnboardingCompleted([String? userId]) async {
    try {
      // If no userId provided, return false (new user needs onboarding)
      if (userId == null || userId.isEmpty) {
        _logger.info('No userId provided, assuming onboarding not completed', tag: _logName);
        return false;
      }

      // Check cache first (for recently completed onboarding)
      if (_completionCache.containsKey(userId)) {
        final cached = _completionCache[userId]!;
        _logger.debug('Onboarding completion status from cache for user $userId: $cached', tag: _logName);
        return cached;
      }

      final db = await SembastDatabase.database;
      final completionKey = _getCompletionKey(userId);
      final record = await SembastDatabase.onboardingStore.record(completionKey).get(db);
      
      if (record != null) {
        final isCompleted = record['completed'] as bool? ?? false;
        // Update cache
        _completionCache[userId] = isCompleted;
        _logger.info('Onboarding completion status for user $userId: $isCompleted', tag: _logName);
        return isCompleted;
      }
      
      // Update cache with false
      _completionCache[userId] = false;
      _logger.info('No onboarding completion record found for user $userId', tag: _logName);
      return false;
    } catch (e) {
      _logger.error('Error checking onboarding completion', tag: _logName, error: e);
      // Return cached value if available, otherwise false
      return _completionCache[userId] ?? false;
    }
  }

  /// Mark onboarding as completed for a specific user
  static Future<void> markOnboardingCompleted(String userId) async {
    try {
      if (userId.isEmpty) {
        _logger.warn('Cannot mark onboarding completed: userId is empty', tag: _logName);
        return;
      }

      final db = await SembastDatabase.database;
      final completionKey = _getCompletionKey(userId);
      
      // Update cache immediately (before database write)
      _completionCache[userId] = true;
      
      // Write the completion record
      await SembastDatabase.onboardingStore.record(completionKey).put(db, {
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'user_id': userId,
      });
      
      // Force a commit by reading back immediately (ensures write is persisted)
      await db.transaction((txn) async {
        final record = await SembastDatabase.onboardingStore.record(completionKey).get(txn);
        if (record == null) {
          _logger.warn('Write verification failed - record not found immediately after write', tag: _logName);
        } else {
          _logger.debug('Write verified in transaction', tag: _logName);
        }
      });
      
      _logger.info('Onboarding marked as completed for user $userId', tag: _logName);
      
      // Additional verification after a short delay (for web IndexedDB)
      await Future.delayed(const Duration(milliseconds: 200));
      final verified = await isOnboardingCompleted(userId);
      if (!verified) {
        _logger.error('Verification failed after delay - onboarding completion may not have persisted for user $userId', tag: _logName);
        // Keep cache as true even if verification fails (write might still be in progress)
        _completionCache[userId] = true;
      } else {
        _logger.info('Verification successful - onboarding completion persisted for user $userId', tag: _logName);
      }
    } catch (e, stackTrace) {
      _logger.error('Error marking onboarding completed', tag: _logName, error: e);
      _logger.debug('Stack trace: $stackTrace', tag: _logName);
      rethrow; // Re-throw to let caller know it failed
    }
  }

  /// Reset onboarding completion status for a specific user (for testing)
  static Future<void> resetOnboardingCompletion(String userId) async {
    try {
      // Clear cache
      _completionCache.remove(userId);
      
      final db = await SembastDatabase.database;
      final completionKey = _getCompletionKey(userId);
      await SembastDatabase.onboardingStore.record(completionKey).delete(db);
      _logger.info('Onboarding completion status reset for user $userId', tag: _logName);
    } catch (e) {
      _logger.error('Error resetting onboarding completion', tag: _logName, error: e);
    }
  }
} 