import 'dart:async';
import 'package:get_storage/get_storage.dart';

/// Mock GetStorage implementation for testing
/// Wraps GetStorage creation in error handling to avoid platform channel issues
/// 
/// NOTE: GetStorage requires platform channels, so this will throw MissingPluginException
/// in unit tests. Tests should use runTestWithPlatformChannelHandling to catch and handle this.
class MockGetStorage {
  static final Map<String, GetStorage?> _instances = {};
  static final Map<String, Map<String, dynamic>> _initialData = {};
  
  /// Get a GetStorage instance for testing
  /// This will throw MissingPluginException in unit tests - use runTestWithPlatformChannelHandling
  /// 
  /// [boxName] - Optional box name, defaults to 'test_box'
  static GetStorage? getInstance({String boxName = 'test_box'}) {
    if (!_instances.containsKey(boxName)) {
      try {
        // Try to create GetStorage with initialData
        // This will fail in unit tests due to MissingPluginException
        final data = _initialData[boxName] ?? <String, dynamic>{};
        _instances[boxName] = GetStorage(boxName, null, data);
      } catch (e) {
        // MissingPluginException expected in unit tests
        // Return null - tests should handle this gracefully
        _instances[boxName] = null;
      }
    }
    return _instances[boxName];
  }
  
  /// Reset all storage instances
  static void reset() {
    for (var instance in _instances.values) {
      try {
        instance?.erase();
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    _instances.clear();
    _initialData.clear();
  }
  
  /// Clear all stored data for a specific box
  static void clear({String boxName = 'test_box'}) {
    _initialData[boxName]?.clear();
    try {
      _instances[boxName]?.erase();
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
  
  /// Set initial data for a box
  static void setInitialData(String boxName, Map<String, dynamic> data) {
    _initialData[boxName] = Map<String, dynamic>.from(data);
  }
}

