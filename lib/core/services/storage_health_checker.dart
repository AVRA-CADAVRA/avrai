import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spots/core/services/logger.dart';

/// Lightweight storage health checker.
/// Uses per-bucket object listing (reliable under anon role) and optional canary verification.
class StorageHealthChecker {
  final SupabaseClient client;
  static const String _logName = 'StorageHealthChecker';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  StorageHealthChecker(this.client);

  /// Returns true if the bucket exists and is accessible (even if empty).
  Future<bool> checkBucketAccessible(String bucket) async {
    try {
      // Some versions of supabase_flutter Storage list() don't support `limit`.
      // A simple list call is sufficient to validate access.
      await client.storage.from(bucket).list();
      return true;
    } catch (e) {
      _logger.warn('Bucket check failed for $bucket: $e', tag: _logName);
      return false;
    }
  }

  /// Optionally verify a public canary object if you have one.
  /// Expects a file at `health/_canary.txt` in each bucket.
  /// Returns null if no public URL is available or canary likely not present.
  Future<bool?> checkCanary(String bucket, {String path = 'health/_canary.txt'}) async {
    try {
      // Generate public URL; will work only if bucket is public and policies allow SELECT.
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      if (publicUrl.isEmpty) return null;

      // Perform a cheap HEAD via http client is not exposed here;
      // Use storage API to fetch metadata by listing the folder prefix.
      final folder = path.contains('/') ? path.split('/').first : '';
      final list = await client.storage.from(bucket).list(path: folder);
      final exists = list.any((f) => f.name.contains('_canary'));
      return exists;
    } catch (e) {
      _logger.warn('Canary check failed for $bucket: $e', tag: _logName);
      return null;
    }
  }

  /// Check a fixed set of buckets used by the app.
  Future<Map<String, bool>> checkAllBuckets(List<String> bucketNames) async {
    final results = <String, bool>{};
    for (final b in bucketNames) {
      results[b] = await checkBucketAccessible(b);
    }
    return results;
  }
}


