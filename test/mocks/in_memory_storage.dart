import 'dart:async';

/// Simple in-memory storage for tests
/// Avoids GetStorage's async flush mechanism that requires platform channels
class InMemoryStorage {
  final Map<String, dynamic> _storage = {};
  
  dynamic read(String key) {
    return _storage[key];
  }
  
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
  }
  
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
  
  void clear() {
    _storage.clear();
  }
  
  bool containsKey(String key) {
    return _storage.containsKey(key);
  }
}

