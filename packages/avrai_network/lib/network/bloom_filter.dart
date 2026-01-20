import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Optimized Bloom filter for loop prevention in mesh networking
///
/// **BitChat-Inspired Pattern:** Similar to BitChat's OptimizedBloomFilter
/// **AI2AI-Enhanced:** Geographic scope-aware capacities (locality=1K, city=5K, region=10K, global=20K)
///
/// **Security Features:**
/// - Configurable capacity and false positive rate
/// - Multiple hash functions (3 hash functions for optimal performance)
/// - Automatic capacity adjustment based on geographic scope
/// - Memory-efficient bit array storage
///
/// **AI2AI-Specific:**
/// - Geographic scope-aware capacities (complements AdaptiveMeshNetworkingService)
/// - Check BEFORE adaptive hop limits (early rejection)
/// - Per-scope Bloom filters for efficient memory usage
class OptimizedBloomFilter {
  static const String _logName = 'OptimizedBloomFilter';

  /// Geographic scope capacities (AI2AI-specific)
  static const Map<String, int> scopeCapacities = {
    'locality': 1000, // 1K items
    'city': 5000, // 5K items
    'region': 10000, // 10K items
    'country': 20000, // 20K items
    'global': 20000, // 20K items (same as country)
  };

  /// Default capacity (if scope not specified)
  static const int defaultCapacity = 5000;

  /// False positive rate (1% = 0.01)
  static const double falsePositiveRate = 0.01;

  /// Number of hash functions (optimal for given false positive rate)
  static const int numHashFunctions = 3;

  /// Bit array for storing filter
  final Uint8List _bitArray;

  /// Number of bits in the filter
  final int _numBits;

  /// Number of items added
  int _itemCount = 0;

  /// Geographic scope (AI2AI-specific)
  final String? _geographicScope;

  /// Capacity for this filter
  final int _capacity;

  OptimizedBloomFilter({
    String? geographicScope, // AI2AI-specific: for capacity determination
    int? capacity, // Override capacity if specified
  }) : _geographicScope = geographicScope,
       _capacity =
           capacity ?? scopeCapacities[geographicScope] ?? defaultCapacity,
       _numBits = _calculateNumBits(
         capacity ?? scopeCapacities[geographicScope] ?? defaultCapacity,
         falsePositiveRate,
       ),
       _bitArray = Uint8List(
         _calculateNumBits(
                   capacity ??
                       scopeCapacities[geographicScope] ??
                       defaultCapacity,
                   falsePositiveRate,
                 ) ~/
                 8 +
             1,
       ) {
    developer.log(
      'Created Bloom filter: scope=$geographicScope, capacity=$_capacity, bits=$_numBits',
      name: _logName,
    );
  }

  /// Calculate number of bits needed for given capacity and false positive rate
  /// Formula: m = -n * ln(p) / (ln(2)^2)
  /// where m = bits, n = capacity, p = false positive rate
  static int _calculateNumBits(int capacity, double falsePositiveRate) {
    final m = (-capacity * log(falsePositiveRate)) / (log(2) * log(2));
    return m.ceil();
  }

  /// Add item to filter
  ///
  /// **Parameters:**
  /// - `item`: Item to add (typically message hash or ID)
  ///
  /// **Returns:**
  /// `true` if item was added, `false` if filter is at capacity
  bool add(String item) {
    if (_itemCount >= _capacity) {
      developer.log(
        'Bloom filter at capacity: $_itemCount >= $_capacity',
        name: _logName,
      );
      return false; // Filter is full
    }

    final hashes = _getHashes(item);
    for (final hash in hashes) {
      final bitIndex = hash % _numBits;
      final byteIndex = bitIndex ~/ 8;
      final bitOffset = bitIndex % 8;
      _bitArray[byteIndex] |= (1 << bitOffset);
    }

    _itemCount++;
    return true;
  }

  /// Check if item might be in filter (may have false positives)
  ///
  /// **Parameters:**
  /// - `item`: Item to check
  ///
  /// **Returns:**
  /// `true` if item might be in filter (definitely not in if false)
  bool mightContain(String item) {
    final hashes = _getHashes(item);
    for (final hash in hashes) {
      final bitIndex = hash % _numBits;
      final byteIndex = bitIndex ~/ 8;
      final bitOffset = bitIndex % 8;
      if ((_bitArray[byteIndex] & (1 << bitOffset)) == 0) {
        return false; // Definitely not in filter
      }
    }
    return true; // Might be in filter (could be false positive)
  }

  /// Get hash values for item (using multiple hash functions)
  List<int> _getHashes(String item) {
    final bytes = utf8.encode(item);
    final hashes = <int>[];

    // Use multiple hash functions (SHA-256 with different salts)
    for (int i = 0; i < numHashFunctions; i++) {
      final salted = Uint8List(bytes.length + 4);
      salted.setRange(0, bytes.length, bytes);
      // Add salt (4 bytes) - simple approach: use index as salt
      final saltBytes = ByteData(4);
      saltBytes.setUint32(0, i, Endian.little);
      salted.setRange(
        bytes.length,
        bytes.length + 4,
        saltBytes.buffer.asUint8List(),
      );

      final hash = sha256.convert(salted);
      // Use first 4 bytes as 32-bit integer
      final hashBytes = Uint8List.fromList(hash.bytes.sublist(0, 4));
      final hashInt = ByteData.sublistView(
        hashBytes,
      ).getUint32(0, Endian.little);
      hashes.add(hashInt);
    }

    return hashes;
  }

  /// Clear filter (reset to empty state)
  void clear() {
    _bitArray.fillRange(0, _bitArray.length, 0);
    _itemCount = 0;
    developer.log('Bloom filter cleared', name: _logName);
  }

  /// Get current item count
  int get itemCount => _itemCount;

  /// Get capacity
  int get capacity => _capacity;

  /// Get geographic scope
  String? get geographicScope => _geographicScope;

  /// Get fill ratio (itemCount / capacity)
  double get fillRatio => _itemCount / _capacity;

  /// Check if filter is at capacity
  bool get isFull => _itemCount >= _capacity;

  /// Get statistics for debugging
  Map<String, dynamic> getStats() {
    return {
      'itemCount': _itemCount,
      'capacity': _capacity,
      'fillRatio': fillRatio,
      'isFull': isFull,
      'geographicScope': _geographicScope,
      'numBits': _numBits,
    };
  }
}
