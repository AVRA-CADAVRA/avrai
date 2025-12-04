import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spots/core/services/logger.dart';

/// Secure SSN/EIN Encryption Utility
/// 
/// Uses Flutter Secure Storage for production-ready encryption.
/// 
/// **Security Notes:**
/// - Uses platform-native secure storage (Keychain on iOS, Keystore on Android)
/// - AES-256 encryption at rest
/// - Never logs SSN/EIN values
/// - Keys are stored securely per platform
/// 
/// **Philosophy Alignment:**
/// - Opens doors to secure tax compliance
/// - Protects sensitive user data
/// - Enables legal compliance without compromising privacy
/// 
/// **Usage:**
/// ```dart
/// final encryption = SecureSSNEncryption();
/// await encryption.encryptSSN('user-123', '123-45-6789');
/// final ssn = await encryption.decryptSSN('user-123');
/// ```
class SecureSSNEncryption {
  static const AppLogger _logger = AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  // Secure storage with platform-specific options
  // Note: encryptedSharedPreferences is deprecated - it's always true now
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  /// Encrypt and store SSN for a user
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `ssn`: Social Security Number (format: XXX-XX-XXXX or 9 digits)
  /// 
  /// **Throws:**
  /// - `Exception` if SSN format is invalid
  /// - `Exception` if storage fails
  Future<void> encryptSSN(String userId, String ssn) async {
    try {
      // Validate SSN format
      final cleaned = ssn.replaceAll('-', '');
      if (cleaned.length != 9 || !RegExp(r'^\d{9}$').hasMatch(cleaned)) {
        throw Exception('Invalid SSN format. Expected XXX-XX-XXXX or 9 digits');
      }
      
      // Store in secure storage (automatically encrypted)
      await _storage.write(
        key: _getSSNKey(userId),
        value: cleaned, // Store as 9 digits (no dashes)
      );
      
      _logger.info('SSN encrypted and stored for user: $userId', tag: 'SecureSSNEncryption');
    } catch (e) {
      _logger.error('Failed to encrypt SSN', error: e, tag: 'SecureSSNEncryption');
      rethrow;
    }
  }
  
  /// Decrypt and retrieve SSN for a user
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// Decrypted SSN (format: XXX-XX-XXXX) or null if not found
  /// 
  /// **Throws:**
  /// - `Exception` if decryption fails
  Future<String?> decryptSSN(String userId) async {
    try {
      final encrypted = await _storage.read(key: _getSSNKey(userId));
      
      if (encrypted == null) {
        return null;
      }
      
      // Format as XXX-XX-XXXX
      return '${encrypted.substring(0, 3)}-${encrypted.substring(3, 5)}-${encrypted.substring(5)}';
    } catch (e) {
      _logger.error('Failed to decrypt SSN', error: e, tag: 'SecureSSNEncryption');
      rethrow;
    }
  }
  
  /// Encrypt and store EIN for a user
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `ein`: Employer Identification Number (format: XX-XXXXXXX or 9 digits)
  /// 
  /// **Throws:**
  /// - `Exception` if EIN format is invalid
  Future<void> encryptEIN(String userId, String ein) async {
    try {
      // Validate EIN format
      final cleaned = ein.replaceAll('-', '');
      if (cleaned.length != 9 || !RegExp(r'^\d{9}$').hasMatch(cleaned)) {
        throw Exception('Invalid EIN format. Expected XX-XXXXXXX or 9 digits');
      }
      
      // Store in secure storage
      await _storage.write(
        key: _getEINKey(userId),
        value: cleaned,
      );
      
      _logger.info('EIN encrypted and stored for user: $userId', tag: 'SecureSSNEncryption');
    } catch (e) {
      _logger.error('Failed to encrypt EIN', error: e, tag: 'SecureSSNEncryption');
      rethrow;
    }
  }
  
  /// Decrypt and retrieve EIN for a user
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// Decrypted EIN (format: XX-XXXXXXX) or null if not found
  Future<String?> decryptEIN(String userId) async {
    try {
      final encrypted = await _storage.read(key: _getEINKey(userId));
      
      if (encrypted == null) {
        return null;
      }
      
      // Format as XX-XXXXXXX
      return '${encrypted.substring(0, 2)}-${encrypted.substring(2)}';
    } catch (e) {
      _logger.error('Failed to decrypt EIN', error: e, tag: 'SecureSSNEncryption');
      rethrow;
    }
  }
  
  /// Delete SSN for a user
  Future<void> deleteSSN(String userId) async {
    try {
      await _storage.delete(key: _getSSNKey(userId));
      _logger.info('SSN deleted for user: $userId', tag: 'SecureSSNEncryption');
    } catch (e) {
      _logger.error('Failed to delete SSN', error: e, tag: 'SecureSSNEncryption');
      rethrow;
    }
  }
  
  /// Delete EIN for a user
  Future<void> deleteEIN(String userId) async {
    try {
      await _storage.delete(key: _getEINKey(userId));
      _logger.info('EIN deleted for user: $userId', tag: 'SecureSSNEncryption');
    } catch (e) {
      _logger.error('Failed to delete EIN', error: e, tag: 'SecureSSNEncryption');
      rethrow;
    }
  }
  
  /// Check if SSN exists for a user
  Future<bool> hasSSN(String userId) async {
    try {
      final ssn = await _storage.read(key: _getSSNKey(userId));
      return ssn != null;
    } catch (e) {
      _logger.error('Failed to check SSN existence', error: e, tag: 'SecureSSNEncryption');
      return false;
    }
  }
  
  /// Check if EIN exists for a user
  Future<bool> hasEIN(String userId) async {
    try {
      final ein = await _storage.read(key: _getEINKey(userId));
      return ein != null;
    } catch (e) {
      _logger.error('Failed to check EIN existence', error: e, tag: 'SecureSSNEncryption');
      return false;
    }
  }
  
  /// Get last 4 digits of SSN (safe for display)
  Future<String?> getSSNLast4(String userId) async {
    try {
      final ssn = await decryptSSN(userId);
      if (ssn == null) return null;
      
      final cleaned = ssn.replaceAll('-', '');
      if (cleaned.length >= 4) {
        return cleaned.substring(cleaned.length - 4);
      }
      return null;
    } catch (e) {
      _logger.error('Failed to get SSN last 4', error: e, tag: 'SecureSSNEncryption');
      return null;
    }
  }
  
  /// Get last 4 digits of EIN (safe for display)
  Future<String?> getEINLast4(String userId) async {
    try {
      final ein = await decryptEIN(userId);
      if (ein == null) return null;
      
      final cleaned = ein.replaceAll('-', '');
      if (cleaned.length >= 4) {
        return cleaned.substring(cleaned.length - 4);
      }
      return null;
    } catch (e) {
      _logger.error('Failed to get EIN last 4', error: e, tag: 'SecureSSNEncryption');
      return null;
    }
  }
  
  // Private helper methods
  
  String _getSSNKey(String userId) => 'tax_ssn_$userId';
  String _getEINKey(String userId) => 'tax_ein_$userId';
}

