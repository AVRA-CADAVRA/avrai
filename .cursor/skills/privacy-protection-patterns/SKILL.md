---
name: privacy-protection-patterns
description: Enforces privacy protection patterns: anonymization, no PII in logs, secure data handling, GDPR compliance. Use when handling user data, implementing AI2AI, or ensuring privacy compliance.
---

# Privacy Protection Patterns

## Core Principle

**Complete privacy protection with zero personal data exposure for AI2AI personality learning.**

## Anonymization Pattern

### Anonymize Personal Data
```dart
/// Anonymize personality profile for AI2AI communication
/// Ensures zero personal data exposure while preserving learning value
Future<AnonymizedPersonalityData> anonymizePersonalityProfile(
  PersonalityProfile profile,
) async {
  // Generate cryptographically secure random salt
  final salt = _generateSecureSalt();
  
  // Create anonymized dimension vectors (no personal identifiers)
  final anonymizedDimensions = await _anonymizeDimensions(
    profile.dimensions,
    salt,
  );
  
  // Create personality archetype hash (no personal identifiers)
  final archetypeHash = await _createArchetypeHash(profile.archetype, salt);
  
  // Generate anonymized fingerprint
  final fingerprint = await _createAnonymizedFingerprint(
    anonymizedDimensions,
    archetypeHash,
    salt,
  );
  
  return AnonymizedPersonalityData(
    anonymizedDimensions: anonymizedDimensions,
    archetypeHash: archetypeHash,
    fingerprint: fingerprint,
    // NO user ID, email, name, or other PII
  );
}
```

### No Personal Identifiers
```dart
/// ❌ BAD: Contains personal identifiers
class BadPersonalityData {
  final String userId; // ❌ Personal identifier
  final String email; // ❌ Personal identifier
  final String name; // ❌ Personal identifier
  final PersonalityDimensions dimensions;
}

/// ✅ GOOD: Anonymized data only
class AnonymizedPersonalityData {
  final Map<String, double> anonymizedDimensions; // ✅ Anonymized
  final String archetypeHash; // ✅ Hash, not personal data
  final String fingerprint; // ✅ Anonymous fingerprint
  // NO personal identifiers
}
```

## Logging Privacy

### ❌ NEVER Log Personal Data
```dart
// ❌ BAD: Logs personal data
developer.log('User ${user.email} signed in'); // ❌ Email in logs
developer.log('Processing payment for ${user.name}'); // ❌ Name in logs
developer.log('User ID: ${user.id}'); // ❌ User ID in logs (if sensitive)
```

### ✅ Log Anonymized Data
```dart
// ✅ GOOD: Anonymized logging
developer.log('User signed in', name: 'AuthService');
developer.log('Processing payment', name: 'PaymentService');
developer.log('User operation completed', name: 'UserService');
// No personal identifiers in logs
```

## Secure Data Handling

### Encrypt Sensitive Data
```dart
/// Encrypt sensitive data at rest
Future<String> encryptSensitiveData(String data) async {
  final key = await _getEncryptionKey();
  final encrypted = await encrypt(data, key: key);
  return encrypted;
}

/// Decrypt sensitive data
Future<String> decryptSensitiveData(String encrypted) async {
  final key = await _getEncryptionKey();
  final decrypted = await decrypt(encrypted, key: key);
  return decrypted;
}
```

### Secure Storage
```dart
/// Store sensitive data securely
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  
  Future<void> storeSensitiveData(String key, String value) async {
    await _secureStorage.write(
      key: key,
      value: value,
      // Encrypted at rest
    );
  }
  
  Future<String?> getSensitiveData(String key) async {
    return await _secureStorage.read(key: key);
  }
}
```

## AI2AI Privacy Requirements

### Anonymized Data Exchange
```dart
/// AI2AI data exchange must be anonymized
Future<void> exchangePersonalityData(Device device) async {
  // Extract anonymized personality (no PII)
  final anonymizedData = await PrivacyProtection.anonymizePersonalityProfile(
    _user.personality,
  );
  
  // Exchange anonymized data only
  await _sendToDevice(device, anonymizedData);
  
  // Never send: userId, email, name, or other PII
}
```

### Privacy Validation
```dart
/// Validate anonymization quality
Future<bool> validateAnonymization(
  PersonalityProfile original,
  AnonymizedPersonalityData anonymized,
) async {
  // Verify no personal identifiers present
  final hasPersonalData = anonymized.fingerprint.contains(
    RegExp(r'user|email|name|id'),
  );
  
  if (hasPersonalData) {
    developer.log('Privacy violation: Personal data in anonymized data');
    return false;
  }
  
  return true;
}
```

## GDPR Compliance

### Data Minimization
```dart
/// Collect only necessary data
class DataCollectionService {
  /// ❌ BAD: Collect unnecessary data
  Future<void> collectUserDataBad() async {
    // Collecting more than necessary
    await store('email', email);
    await store('phone', phone);
    await store('address', address);
  }
  
  /// ✅ GOOD: Collect only necessary data
  Future<void> collectUserDataGood() async {
    // Collect only what's needed for functionality
    await store('personality_dimensions', dimensions);
    // Don't collect: email, phone, address (unless required)
  }
}
```

### Right to Deletion
```dart
/// Implement user data deletion
Future<void> deleteUserData(String userId) async {
  // Delete all user data
  await _database.delete('users', where: 'id = ?', whereArgs: [userId]);
  await _database.delete('spots', where: 'userId = ?', whereArgs: [userId]);
  await _secureStorage.delete(key: userId);
  
  // Log deletion (anonymized)
  developer.log('User data deleted', name: 'DataDeletionService');
}
```

## Privacy Checklist

- [ ] No personal identifiers in logs
- [ ] All AI2AI data is anonymized
- [ ] Sensitive data encrypted at rest
- [ ] Secure storage for sensitive data
- [ ] Data minimization (collect only necessary)
- [ ] User data deletion supported
- [ ] No PII in error messages
- [ ] Privacy validation in place
- [ ] GDPR compliance verified

## Reference

- `lib/core/ai/privacy_protection.dart` - Privacy protection implementation
- `lib/core/models/anonymized_personality_data.dart` - Anonymized data models
