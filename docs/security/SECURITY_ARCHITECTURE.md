# Security Architecture Documentation

**Date:** December 1, 2025, 2:40 PM CST  
**Purpose:** Comprehensive security architecture documentation  
**Phase:** Phase 7, Section 45-46 (7.3.7-8)

---

## Overview

SPOTS implements a multi-layered security architecture to protect user privacy and data. This document describes the security layers, data flow, and security measures throughout the system.

---

## Security Layers

### Layer 1: Data Anonymization

**Purpose:** Remove all personal identifiers before AI2AI transmission.

**Implementation:**
- **UserAnonymizationService:** Converts UnifiedUser → AnonymousUser
- **AnonymousUser Model:** Contains NO personal data fields
- **Validation:** Deep recursive validation blocks personal data

**Data Flow:**
```
UnifiedUser (with personal data)
  ↓
UserAnonymizationService.anonymizeUser()
  ↓
AnonymousUser (no personal data)
  ↓
AI2AI Network
```

**Key Features:**
- Filters email, name, phone, address
- Removes userId from payloads
- Validates no personal data leakage
- Blocks suspicious payloads

**Files:**
- `lib/core/services/user_anonymization_service.dart`
- `lib/core/models/anonymous_user.dart`
- `lib/core/ai2ai/anonymous_communication.dart`

---

### Layer 2: Location Obfuscation

**Purpose:** Protect user location by obfuscating to city-level.

**Implementation:**
- **LocationObfuscationService:** Obfuscates locations
- **City-level precision:** ~1km precision (0.01 degrees)
- **Differential privacy:** Adds controlled noise
- **Home location protection:** Never shares home location

**Data Flow:**
```
Exact Location
  ↓
LocationObfuscationService.obfuscateLocation()
  ↓
ObfuscatedLocation (city-level only)
  ↓
AI2AI Network
```

**Key Features:**
- City-level obfuscation (not exact coordinates)
- Differential privacy noise (~500m)
- Home location protection
- Expiration (24 hours)
- Admin/godmode can access exact locations

**Files:**
- `lib/core/services/location_obfuscation_service.dart`
- `lib/core/models/anonymous_user.dart` (ObfuscatedLocation)

---

### Layer 3: Field-Level Encryption

**Purpose:** Encrypt sensitive fields at rest.

**Implementation:**
- **FieldEncryptionService:** Encrypts sensitive fields
- **AES-256-GCM:** Authenticated encryption
- **Flutter Secure Storage:** Key management (Keychain/Keystore)
- **Field-specific keys:** Different keys per field/user

**Data Flow:**
```
Sensitive Field (email, name, phone, location)
  ↓
FieldEncryptionService.encryptField()
  ↓
Encrypted Value (base64 encoded)
  ↓
Database Storage
```

**Key Features:**
- AES-256-GCM encryption
- Keys stored in secure storage
- Field-specific encryption keys
- Key rotation support
- User-specific keys

**Files:**
- `lib/core/services/field_encryption_service.dart`

**Encryptable Fields:**
- email
- name, displayName
- phone, phoneNumber
- location
- address

---

### Layer 4: Payload Validation

**Purpose:** Block personal information in AI2AI payloads.

**Implementation:**
- **Deep recursive validation:** Checks nested objects and arrays
- **Pattern matching:** Detects email, phone, address, SSN, credit cards
- **Blocking behavior:** Throws exceptions (doesn't just log)

**Data Flow:**
```
AI2AI Payload
  ↓
AnonymousCommunicationProtocol._validateAnonymousPayload()
  ↓
Deep Recursive Validation
  ↓
Pattern Matching Check
  ↓
If valid: Proceed
If invalid: Throw Exception (blocked)
```

**Key Features:**
- Recursive validation of nested structures
- Pattern matching for personal information
- Blocks suspicious payloads
- Specific error messages

**Files:**
- `lib/core/ai2ai/anonymous_communication.dart`

---

### Layer 5: Audit Logging

**Purpose:** Track all sensitive data access and security events.

**Implementation:**
- **AuditLogService:** Logs all data access
- **Immutable logs:** No update/delete policies
- **Comprehensive tracking:** Data access, security events, modifications

**Data Flow:**
```
Data Access / Security Event
  ↓
AuditLogService.logXXX()
  ↓
Audit Log Entry
  ↓
Database (audit_logs table)
```

**Key Features:**
- Immutable audit logs
- Comprehensive event tracking
- RLS policies for access control
- Retention policies (30-90 days)

**Files:**
- `lib/core/services/audit_log_service.dart`
- `supabase/migrations/010_audit_log_table.sql`

**Log Types:**
- `data_access`: Sensitive data access
- `security_event`: Authentication, authorization events
- `data_modification`: Data changes
- `anonymization`: User anonymization events

---

### Layer 6: Row-Level Security (RLS)

**Purpose:** Database-level access control.

**Implementation:**
- **RLS Policies:** Users can only access their own data
- **Service role:** Admin access for system operations
- **No public access:** All tables have RLS enabled

**Data Flow:**
```
Database Query
  ↓
RLS Policy Check
  ↓
If authorized: Return data
If unauthorized: Return empty/error
```

**Key Features:**
- User-specific access control
- Service role for admin operations
- No public access
- Policy enforcement at database level

**Files:**
- `supabase/migrations/011_enhance_rls_policies.sql`

**RLS Policies:**
- Users can only SELECT their own data
- Users can only UPDATE their own data
- Users can only DELETE their own data
- Service role can access all data (admin)

---

## Data Flow Architecture

### User Data → AI2AI Network Flow

```
1. UnifiedUser (Personal Data)
   ↓
2. UserAnonymizationService.anonymizeUser()
   - Filters personal data
   - Converts to AnonymousUser
   ↓
3. LocationObfuscationService.obfuscateLocation()
   - Obfuscates to city-level
   - Adds differential privacy noise
   ↓
4. AnonymousUser (No Personal Data)
   - agentId only (no userId)
   - Obfuscated location
   - No email, name, phone, address
   ↓
5. Payload Validation
   - Deep recursive validation
   - Pattern matching
   - Blocks suspicious payloads
   ↓
6. AI2AI Network Transmission
   - Only anonymous data
   - Encrypted in transit (TLS)
   ↓
7. Audit Logging
   - Logs anonymization event
   - Tracks data access
```

### Sensitive Data Storage Flow

```
1. User Input (Sensitive Field)
   ↓
2. FieldEncryptionService.encryptField()
   - Generates/retrieves encryption key
   - Encrypts with AES-256-GCM
   ↓
3. Encrypted Value
   - Base64 encoded
   - Stored in database
   ↓
4. Key Management
   - Keys in Flutter Secure Storage
   - Keychain (iOS) / Keystore (Android)
   ↓
5. Decryption (on read)
   - Retrieves encryption key
   - Decrypts field value
   ↓
6. Audit Logging
   - Logs field access
   - Tracks encryption/decryption
```

---

## Security Measures by Component

### AI2AI Services

**ConnectionOrchestrator:**
- Uses AnonymousUser (not UnifiedUser)
- Validates payloads before transmission
- Logs connection events

**PersonalityAdvertisingService:**
- Anonymizes user data before advertising
- Validates no UnifiedUser in payloads
- Uses AnonymousUser for AI2AI network

**AI2AIProtocol:**
- Validates payloads
- Encrypts messages in transit
- Blocks personal information

### Database Security

**RLS Policies:**
- Users can only access their own data
- Service role for admin operations
- No public access

**Audit Logging:**
- Immutable logs
- Comprehensive tracking
- Retention policies

**Encryption:**
- Field-level encryption (at rest)
- Keys in secure storage
- AES-256-GCM

### Authentication & Authorization

**User Authentication:**
- Secure authentication
- Session management
- Password hashing

**Admin/Godmode Access:**
- Strict authentication
- Permission checks
- Audit logging

---

## Security Principles

### 1. Defense in Depth

Multiple security layers protect user data:
- Data anonymization
- Location obfuscation
- Field encryption
- Payload validation
- Audit logging
- RLS policies

### 2. Privacy by Design

Security measures built into architecture:
- AnonymousUser model (no personal data)
- Anonymization before transmission
- Encryption by default
- Minimal data collection

### 3. Principle of Least Privilege

Access control minimizes data exposure:
- RLS policies limit access
- Users can only access their own data
- Admin access only when needed
- Audit logging tracks all access

### 4. Zero Trust

Never trust, always verify:
- Validate all payloads
- Verify anonymization
- Check access permissions
- Audit all operations

---

## Threat Model

### Protected Against

**Personal Information Leakage:**
- Email addresses
- Names
- Phone numbers
- Addresses
- User IDs

**Location Tracking:**
- Exact coordinates
- Home location
- Frequent locations

**Data Access:**
- Unauthorized database access
- Cross-user data access
- Admin privilege abuse

**Network Attacks:**
- Impersonation
- Payload injection
- Man-in-the-middle

### Attack Vectors Mitigated

**Data Extraction:**
- ✅ AnonymousUser contains no personal data
- ✅ Location obfuscated to city-level
- ✅ Personal information filtered

**Impersonation:**
- ✅ Agent ID validation
- ✅ Device certificate validation
- ✅ Authentication required

**Encryption Bypass:**
- ✅ Strong encryption (AES-256-GCM)
- ✅ Secure key management
- ✅ Field-specific keys

**RLS Bypass:**
- ✅ Database-level enforcement
- ✅ No public access
- ✅ Service role only for admin

**Audit Tampering:**
- ✅ Immutable logs
- ✅ No update/delete policies
- ✅ Comprehensive tracking

---

## Compliance

### GDPR Compliance

- **Right to be forgotten:** Data deletion mechanisms
- **Data minimization:** Only collect necessary data
- **Privacy by design:** Anonymization, encryption
- **User consent:** Clear consent mechanisms

### CCPA Compliance

- **Right to know:** Data access mechanisms
- **Right to delete:** Data deletion functionality
- **Opt-out mechanisms:** Privacy controls
- **Data security:** Encryption, access controls

---

## Security Monitoring

### Audit Log Analysis

**Track:**
- Data access patterns
- Security events
- Failed authentication attempts
- Unusual access patterns

**Alerts:**
- Multiple failed authentication attempts
- Unusual data access volume
- Bulk data modifications
- Anonymization failures

### Security Event Monitoring

**Monitor:**
- Authentication failures
- Authorization failures
- Encryption errors
- Validation failures

**Response:**
- Automated alerts
- Security team notification
- Incident response process

---

## Related Documentation

- [Agent ID System](AGENT_ID_SYSTEM.md)
- [Encryption Guide](ENCRYPTION_GUIDE.md)
- [Best Practices](BEST_PRACTICES.md)
- [GDPR Compliance](../compliance/GDPR_COMPLIANCE.md)
- [CCPA Compliance](../compliance/CCPA_COMPLIANCE.md)
- [Audit Log Monitoring](AUDIT_LOG_MONITORING.md)

---

**Last Updated:** December 1, 2025, 2:40 PM CST  
**Status:** Active

