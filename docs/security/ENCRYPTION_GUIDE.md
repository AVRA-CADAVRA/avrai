# Encryption Guide

**Date:** December 1, 2025, 2:40 PM CST  
**Purpose:** Field-level encryption implementation guide  
**Phase:** Phase 7, Section 45-46 (7.3.7-8)

---

## Overview

SPOTS uses field-level encryption to protect sensitive user data at rest. This guide documents the encryption implementation, key management, and encryption/decryption processes.

---

## Encryption Algorithm

### AES-256-GCM

**Algorithm:** AES-256-GCM (Advanced Encryption Standard with 256-bit keys in Galois/Counter Mode)

**Properties:**
- Authenticated encryption (provides confidentiality and authenticity)
- 256-bit keys (strong encryption)
- GCM mode (authenticated, fast)

**Why AES-256-GCM:**
- Industry standard
- Strong security
- Authenticated encryption
- Performance optimized

---

## Field-Level Encryption

### Encryptable Fields

**Fields Encrypted:**
- email
- name, displayName
- phone, phoneNumber
- location
- address

### Encryption Service

**Service:** FieldEncryptionService

**Location:** `lib/core/services/field_encryption_service.dart`

**Key Methods:**
- `encryptField(fieldName, value, userId)` - Encrypt a field
- `decryptField(fieldName, encryptedValue, userId)` - Decrypt a field
- `shouldEncryptField(fieldName)` - Check if field should be encrypted

---

## Key Management

### Key Storage

**Storage:** Flutter Secure Storage

**Platforms:**
- iOS: Keychain (KeychainAccessibility.first_unlock_this_device)
- Android: Keystore

**Key Properties:**
- Keys stored securely (hardware-backed when available)
- User-specific keys (per field/user combination)
- Field-specific keys (different key per field)

### Key Generation

**Process:**
1. Check if key exists for field/user combination
2. If exists, retrieve from secure storage
3. If not, generate new 32-byte key (256 bits)
4. Store in secure storage
5. Return key for encryption/decryption

**Key Identifier:**
- Format: `field_encryption_key_{fieldName}_{userId}`
- Example: `field_encryption_key_email_user-123`

### Key Rotation

**Rotation Process:**
1. Delete old key from secure storage
2. Generate new key on next encryption
3. Re-encrypt all data with new key (migration)

**Implementation:**
- `rotateKey(fieldName, userId)` - Rotate encryption key
- Requires data migration to re-encrypt with new key

---

## Encryption Process

### Encrypting a Field

**Steps:**
1. Check if value is empty (skip encryption if empty)
2. Get or generate encryption key for field/user
3. Encrypt value using AES-256-GCM
4. Base64 encode encrypted value
5. Return encrypted value

**Example:**
```dart
final encrypted = await encryptionService.encryptField(
  'email',
  'user@example.com',
  'user-123',
);
// Returns: 'encrypted:base64encodedvalue'
```

### Decrypting a Field

**Steps:**
1. Check if encrypted value is empty (skip decryption if empty)
2. Get encryption key for field/user
3. Base64 decode encrypted value
4. Decrypt using AES-256-GCM
5. Verify authentication tag
6. Return decrypted value

**Example:**
```dart
final decrypted = await encryptionService.decryptField(
  'email',
  encrypted,
  'user-123',
);
// Returns: 'user@example.com'
```

---

## Implementation Details

### Current Implementation

**Status:** Simplified implementation (placeholder for production)

**Notes:**
- Current implementation is simplified
- Production should use proper cryptographic library (e.g., pointycastle)
- Proper IV generation required
- Authentication tag verification required

### Production Requirements

**Required:**
- Proper AES-256-GCM implementation
- Secure IV generation (per encryption)
- Authentication tag verification
- Proper error handling
- Key rotation with data migration

**Libraries:**
- pointycastle (Dart cryptographic library)
- crypto (Dart crypto package)

---

## Security Considerations

### Key Protection

**Measures:**
- Keys stored in secure storage
- Hardware-backed storage when available
- Keys never exposed in logs
- Keys not transmitted over network

### Key Rotation

**Best Practices:**
- Regular key rotation
- Rotation after security incidents
- Rotation when user requests
- Secure key deletion

### Data Protection

**Measures:**
- All sensitive fields encrypted
- Empty values not encrypted (performance)
- Encryption transparent to application
- Audit logging of encryption/decryption

---

## Usage Examples

### Encrypting User Data

```dart
final encryptionService = FieldEncryptionService();

// Encrypt email
final encryptedEmail = await encryptionService.encryptField(
  'email',
  user.email,
  user.id,
);

// Store encryptedEmail in database
```

### Decrypting User Data

```dart
final encryptionService = FieldEncryptionService();

// Decrypt email
final decryptedEmail = await encryptionService.decryptField(
  'email',
  encryptedEmail,
  user.id,
);

// Use decryptedEmail in application
```

### Checking if Field Should Be Encrypted

```dart
final encryptionService = FieldEncryptionService();

if (encryptionService.shouldEncryptField('email')) {
  // Encrypt field
  final encrypted = await encryptionService.encryptField(...);
}
```

---

## Key Deletion

### Deleting Keys

**Purpose:**
- User account deletion
- Right to be forgotten (GDPR)
- Security incidents

**Process:**
1. Delete encryption key from secure storage
2. Encrypted data becomes unrecoverable
3. Audit log entry

**Warning:**
- Key deletion makes encrypted data unrecoverable
- Use only for account deletion or security incidents

**Example:**
```dart
await encryptionService.deleteKey('email', 'user-123');
```

---

## Related Documentation

- [Security Architecture](SECURITY_ARCHITECTURE.md)
- [Agent ID System](AGENT_ID_SYSTEM.md)
- [Best Practices](BEST_PRACTICES.md)

---

**Last Updated:** December 1, 2025, 2:40 PM CST  
**Status:** Active

