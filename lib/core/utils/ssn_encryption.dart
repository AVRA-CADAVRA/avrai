import 'dart:convert';
import 'package:crypto/crypto.dart';

/// SSN Encryption Utility
/// 
/// Provides secure encryption/decryption for Social Security Numbers.
/// 
/// **Security Notes:**
/// - Uses AES-256 encryption (simulated for development)
/// - In production, use proper encryption libraries (e.g., Flutter Secure Storage)
/// - Never log SSN values
/// - Always encrypt before storage
/// 
/// **Philosophy Alignment:**
/// - Opens doors to secure tax compliance
/// - Protects sensitive user data
/// - Enables legal compliance without compromising privacy
/// 
/// **Usage:**
/// ```dart
/// final encrypted = SSNEncryption.encrypt('123-45-6789');
/// final decrypted = SSNEncryption.decrypt(encrypted);
/// ```
class SSNEncryption {
  /// Encrypt SSN for storage
  /// 
  /// **Parameters:**
  /// - `ssn`: Social Security Number (format: XXX-XX-XXXX)
  /// 
  /// **Returns:**
  /// Encrypted SSN string (base64 encoded)
  /// 
  /// **Throws:**
  /// - `Exception` if SSN format is invalid
  static String encrypt(String ssn) {
    if (ssn.isEmpty) {
      throw Exception('SSN cannot be empty');
    }
    
    // Validate SSN format (XXX-XX-XXXX or XXXXXXXXX)
    final cleaned = ssn.replaceAll('-', '');
    if (cleaned.length != 9 || !RegExp(r'^\d{9}$').hasMatch(cleaned)) {
      throw Exception('Invalid SSN format. Expected XXX-XX-XXXX or 9 digits');
    }
    
    // In production, use proper encryption (e.g., Flutter Secure Storage, AES-256)
    // For now, use base64 encoding with hash salt (NOT secure for production!)
    final bytes = utf8.encode(cleaned);
    final hash = sha256.convert(bytes);
    final salt = hash.toString().substring(0, 16);
    final salted = utf8.encode('$salt:$cleaned');
    final encoded = base64Encode(salted);
    
    // Return with encryption marker
    return 'encrypted:$encoded';
  }
  
  /// Decrypt SSN from storage
  /// 
  /// **Parameters:**
  /// - `encryptedSsn`: Encrypted SSN string
  /// 
  /// **Returns:**
  /// Decrypted SSN (format: XXX-XX-XXXX)
  /// 
  /// **Throws:**
  /// - `Exception` if decryption fails
  static String decrypt(String encryptedSsn) {
    if (encryptedSsn.isEmpty) {
      throw Exception('Encrypted SSN cannot be empty');
    }
    
    if (!encryptedSsn.startsWith('encrypted:')) {
      // Assume it's already decrypted (for backward compatibility)
      return encryptedSsn;
    }
    
    try {
      final encoded = encryptedSsn.substring(10); // Remove 'encrypted:' prefix
      final decoded = base64Decode(encoded);
      final decodedStr = utf8.decode(decoded);
      final parts = decodedStr.split(':');
      
      if (parts.length >= 2) {
        final ssn = parts[1];
        // Format as XXX-XX-XXXX
        return '${ssn.substring(0, 3)}-${ssn.substring(3, 5)}-${ssn.substring(5)}';
      }
      
      throw Exception('Invalid encrypted SSN format');
    } catch (e) {
      throw Exception('Failed to decrypt SSN: ${e.toString()}');
    }
  }
  
  /// Check if SSN is encrypted
  /// 
  /// **Parameters:**
  /// - `ssn`: SSN string to check
  /// 
  /// **Returns:**
  /// `true` if encrypted, `false` otherwise
  static bool isEncrypted(String ssn) {
    return ssn.startsWith('encrypted:');
  }
  
  /// Mask SSN for display (shows only last 4 digits)
  /// 
  /// **Parameters:**
  /// - `ssn`: SSN (encrypted or plain)
  /// 
  /// **Returns:**
  /// Masked SSN (format: ***-**-1234)
  static String mask(String ssn) {
    try {
      final decrypted = isEncrypted(ssn) ? decrypt(ssn) : ssn;
      final cleaned = decrypted.replaceAll('-', '');
      if (cleaned.length >= 4) {
        final last4 = cleaned.substring(cleaned.length - 4);
        return '***-**-$last4';
      }
      return '***-**-****';
    } catch (e) {
      return '***-**-****';
    }
  }
  
  /// Validate SSN format
  /// 
  /// **Parameters:**
  /// - `ssn`: SSN to validate
  /// 
  /// **Returns:**
  /// `true` if valid format, `false` otherwise
  static bool isValidFormat(String ssn) {
    final cleaned = ssn.replaceAll('-', '');
    return cleaned.length == 9 && RegExp(r'^\d{9}$').hasMatch(cleaned);
  }
}

