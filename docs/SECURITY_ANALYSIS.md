# SPOTS Security Analysis & Gap Assessment

**Date:** November 27, 2025  
**Status:** Critical Security Review  
**Purpose:** Comprehensive security analysis focusing on personal information protection and AI2AI network security

---

## 🎯 **EXECUTIVE SUMMARY**

This document identifies critical security gaps in the SPOTS application, with a focus on:
1. **Personal Information Protection** - Ensuring no name, email, phone, or address data is associated with user agents
2. **AI2AI Network Security** - Preventing unauthorized access and impersonation attacks
3. **Data Anonymization** - Ensuring only anonymous information is available in the AI2AI network

### **Architecture Clarification**

**User Account vs AI Agent Separation:**
- **User Account** (email/password) → Used for login, basic preferences, location tracking
- **AI Agent ID** (randomized) → Used in AI2AI network communication
- **Mapping** → User account → AI Agent ID (stored separately, encrypted)

**Security Goal:** The AI Agent ID should be completely anonymous and unlinkable to user accounts from the AI2AI network perspective.

**Key Findings:**
- ⚠️ **CRITICAL:** Personality profiles contain `userId` which can link back to user accounts
- ⚠️ **CRITICAL:** No secure mapping system between user accounts and AI agent IDs
- ⚠️ **HIGH:** User models contain personal information (email, name, location) that could leak into AI2AI network
- ⚠️ **HIGH:** Weak encryption in AI2AI protocol (XOR encryption, not production-ready)
- ⚠️ **HIGH:** AI agent ID generation may not be cryptographically secure
- ⚠️ **MEDIUM:** No device/node ID verification to prevent impersonation
- ⚠️ **MEDIUM:** LLM context includes userId which could leak personal information
- ⚠️ **MEDIUM:** Database stores personal information in plain text

---

## 🔴 **CRITICAL SECURITY GAPS**

### **1. Personality Profile Contains User ID**

**Location:** `lib/core/models/personality_profile.dart`

**Issue:**
```dart
class PersonalityProfile {
  final String userId;  // ⚠️ CRITICAL: Links personality to user account
  // ...
}
```

**Risk:**
- Personality profiles are used in AI2AI network communication
- The `userId` field can be used to link anonymous personality data back to user accounts
- This violates the requirement that "no personal information should be associated with user agents"

**Evidence:**
- `PersonalityProfile.toJson()` includes `'user_id': userId` (line 385)
- Personality profiles are exchanged in AI2AI protocol (see `ai2ai_protocol.dart`)
- Personality profiles are used in connection orchestration

**Recommendation:**
1. **Replace `userId` with `agentId` in PersonalityProfile** - Use anonymous agent ID instead
2. **Create secure mapping system** - Store userId → agentId mapping separately with:
   - Encrypted storage (AES-256)
   - Access-controlled (only authenticated user can access their own mapping)
   - Separate database table with strict RLS policies
   - No reverse lookup from agentId → userId (one-way mapping)
3. **Anonymize before transmission** - Strip userId before any AI2AI network communication
4. **Add validation** - Ensure no userId appears in any AI2AI payload
5. **Agent ID generation** - Use cryptographically secure random generation (see Gap #13)

---

### **2. User Models Contain Personal Information**

**Location:** Multiple files
- `lib/core/models/unified_user.dart`
- `packages/spots_core/lib/models/user.dart`
- `lib/core/models/unified_models.dart`

**Issue:**
```dart
class UnifiedUser {
  final String id;
  final String email;        // ⚠️ PERSONAL INFO
  final String? displayName; // ⚠️ POTENTIALLY PERSONAL
  final String? location;    // ⚠️ PERSONAL INFO
  // ...
}
```

**Risk:**
- User models are used throughout the application
- Personal information (email, name, location) could leak into AI2AI network if not properly filtered
- Location data could be used to identify users

**Evidence:**
- User models are serialized to JSON and could be included in network payloads
- LLM service includes user context which may contain personal information
- No comprehensive filtering before AI2AI transmission

**Recommendation:**
1. **Create AnonymousUser model** - Separate model with no personal information
2. **Strict filtering** - Never include email, name, phone, address in AI2AI payloads
3. **Location anonymization** - Use approximate location (city-level) instead of exact coordinates
4. **Validation layer** - Add pre-transmission validation to strip personal information

---

### **3. Weak Encryption in AI2AI Protocol**

**Location:** `lib/core/network/ai2ai_protocol.dart`

**Issue:**
```dart
/// Encrypt data (simple XOR encryption for now, should use AES in production)
Uint8List _encrypt(Uint8List data) {
  if (_encryptionKey == null) return data;
  
  final encrypted = Uint8List(data.length);
  for (int i = 0; i < data.length; i++) {
    encrypted[i] = data[i] ^ _encryptionKey![i % _encryptionKey!.length];
  }
  return encrypted;
}
```

**Risk:**
- XOR encryption is not secure for production use
- Comments indicate this is placeholder code
- No proper key management or key rotation
- Vulnerable to cryptanalysis

**Evidence:**
- Line 321: Comment says "should use AES in production"
- No proper cryptographic library usage
- Encryption key management is unclear

**Recommendation:**
1. **Implement AES-256-GCM** - Use proper authenticated encryption
2. **Key management** - Implement secure key generation, storage, and rotation
3. **Perfect Forward Secrecy** - Use ephemeral keys for each session
4. **Certificate pinning** - Verify device identities with certificates

---

### **4. No Device/Node Identity Verification**

**Location:** `lib/core/p2p/node_manager.dart`, `lib/core/network/ai2ai_protocol.dart`

**Issue:**
```dart
Future<String> _generateSecureNodeId() async {
  final random = math.Random.secure();
  final bytes = List<int>.generate(16, (i) => random.nextInt(256));
  return 'node_${base64Encode(bytes).replaceAll('=', '').substring(0, 12)}';
}
```

**Risk:**
- Node IDs are randomly generated but not cryptographically verified
- No mechanism to prevent impersonation attacks
- Attacker could generate fake node IDs and join the network
- No certificate-based authentication

**Evidence:**
- Node IDs are generated locally without server verification
- No signature or certificate attached to node IDs
- No validation that a node ID belongs to a legitimate device

**Recommendation:**
1. **Device certificates** - Issue certificates for each device/user agent
2. **Digital signatures** - Sign all messages with device private key
3. **Certificate validation** - Verify certificates before accepting connections
4. **Revocation list** - Maintain list of revoked/compromised certificates
5. **Trust network** - Build trust scores based on verified interactions

---

### **5. LLM Context Includes User ID**

**Location:** `lib/core/services/llm_service.dart`

**Issue:**
```dart
class LLMContext {
  final String? userId;  // ⚠️ Could leak personal information
  final Position? location;  // ⚠️ Exact location
  // ...
  
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (userId != null) json['userId'] = userId;  // ⚠️ Included in JSON
    // ...
  }
}
```

**Risk:**
- LLM context is sent to external services (Supabase Edge Functions)
- User ID could be used to link requests to user accounts
- Location data could identify users

**Evidence:**
- Line 545: `if (userId != null) json['userId'] = userId;`
- Context is sent to LLM services which may log or store data
- No anonymization before sending to external services

**Recommendation:**
1. **Anonymize user ID** - Use anonymous session ID instead of userId
2. **Location obfuscation** - Use approximate location (city-level)
3. **Context filtering** - Remove all personal information before sending
4. **Audit logging** - Log what data is sent to external services

---

### **6. Database Stores Personal Information in Plain Text**

**Location:** `supabase/migrations/001_initial_schema.sql`

**Issue:**
```sql
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,  -- ⚠️ Plain text
    name TEXT,                    -- ⚠️ Plain text
    location TEXT,                 -- ⚠️ Plain text
    -- ...
);
```

**Risk:**
- Personal information stored in plain text in database
- Database breaches would expose all user personal information
- No encryption at rest for sensitive fields

**Evidence:**
- Line 8: `email TEXT UNIQUE NOT NULL`
- Line 9: `name TEXT`
- Line 12: `location TEXT`
- No encryption columns or encrypted fields

**Recommendation:**
1. **Encrypt sensitive fields** - Use database-level encryption for email, name, location
2. **Field-level encryption** - Encrypt before storing in database
3. **Access controls** - Strict RLS policies to limit access
4. **Audit logging** - Log all access to personal information
5. **Data minimization** - Only store necessary personal information

---

### **13. No Secure User Account → AI Agent Mapping System**

**Location:** Agent ID generation and storage

**Issue:**
- No dedicated system for mapping user accounts to AI agent IDs
- Agent IDs are generated but not securely stored/retrieved
- No protection against reverse lookup (agentId → userId)
- No encryption of the mapping relationship

**Risk:**
- If mapping is compromised, attacker could link agent IDs to user accounts
- No audit trail for mapping access
- No access controls on mapping table
- Could enable de-anonymization attacks

**Current State:**
```dart
// Agent IDs are generated but mapping is unclear
String _generateAnonymousAgentId() {
  final random = Random.secure();
  final bytes = List<int>.generate(8, (i) => random.nextInt(256));
  return 'anon_${sha256.convert(bytes).toString().substring(0, 8)}';
}
```

**Recommendation:**
1. **Create Secure Mapping Table**
   ```sql
   CREATE TABLE user_agent_mappings (
     user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
     agent_id TEXT UNIQUE NOT NULL,
     created_at TIMESTAMP DEFAULT NOW(),
     last_rotated_at TIMESTAMP,
     encryption_key_id TEXT, -- Reference to key used for encryption
     -- Encrypted fields
     encrypted_metadata BYTEA, -- Encrypted additional metadata
     -- Access control
     access_count INTEGER DEFAULT 0,
     last_accessed_at TIMESTAMP
   );
   
   -- RLS Policy: Users can only access their own mapping
   CREATE POLICY "Users can only access own mapping" 
   ON user_agent_mappings
   FOR SELECT USING (auth.uid() = user_id);
   ```

2. **Cryptographically Secure Agent ID Generation**
   ```dart
   Future<String> generateSecureAgentId() async {
     // Use cryptographically secure random
     final random = Random.secure();
     final bytes = List<int>.generate(32, (i) => random.nextInt(256));
     
     // Hash with SHA-256 for additional security
     final hash = sha256.convert(bytes);
     
     // Use longer ID for better security (32 chars = 128 bits)
     return 'agent_${hash.toString().substring(0, 32)}';
   }
   ```

3. **One-Way Mapping Protection**
   - Store only userId → agentId (forward lookup)
   - Do NOT store agentId → userId (reverse lookup)
   - Use separate encrypted index if reverse lookup needed (with access controls)
   - Hash agentId before storing in any logs

4. **Mapping Encryption**
   - Encrypt the mapping relationship itself
   - Use separate encryption keys per user
   - Rotate keys periodically
   - Store keys in secure key management service

5. **Access Controls**
   - Only authenticated user can access their own mapping
   - Log all mapping access attempts
   - Rate limit mapping lookups
   - Require re-authentication for sensitive operations

6. **Agent ID Rotation**
   - Allow users to rotate their agent ID
   - Maintain history of old agent IDs (encrypted)
   - Grace period for old agent ID to expire
   - Notify connected agents of rotation

---

## 🟡 **HIGH PRIORITY SECURITY GAPS**

### **7. Anonymization Validation is Incomplete**

**Location:** `lib/core/ai2ai/anonymous_communication.dart`

**Issue:**
```dart
Future<void> _validateAnonymousPayload(Map<String, dynamic> payload) async {
  final forbiddenKeys = ['userId', 'email', 'name', 'phone', 'address', 'personalInfo'];
  
  for (final key in forbiddenKeys) {
    if (payload.containsKey(key)) {
      throw AnonymousCommunicationException('Payload contains user data: $key');
    }
  }
  
  // Deep scan for potential user data
  final payloadString = jsonEncode(payload).toLowerCase();
  final suspiciousPatterns = ['user_', 'personal_', '@', 'phone', 'address'];
  
  for (final pattern in suspiciousPatterns) {
    if (payloadString.contains(pattern)) {
      developer.log('Warning: Potentially suspicious data pattern detected', name: _logName);
      // ⚠️ Only logs warning, doesn't block
    }
  }
}
```

**Risk:**
- Validation only checks top-level keys
- Nested objects may contain personal information
- Warnings are logged but don't block transmission
- Pattern matching is too simplistic

**Recommendation:**
1. **Deep validation** - Recursively check all nested objects
2. **Block on detection** - Reject payloads with suspicious patterns
3. **Comprehensive patterns** - Add more patterns (phone numbers, email regex, etc.)
4. **Automated testing** - Test validation with various payload structures

---

### **8. No Rate Limiting on AI2AI Network**

**Location:** AI2AI network communication

**Issue:**
- No rate limiting on connection requests
- No protection against DDoS attacks
- No throttling for suspicious activity
- Attacker could flood network with requests

**Recommendation:**
1. **Rate limiting** - Limit connection requests per device/time period
2. **DDoS protection** - Implement circuit breakers
3. **Throttling** - Slow down suspicious devices
4. **Monitoring** - Alert on unusual activity patterns

---

### **9. Session Management Weaknesses**

**Location:** Authentication services

**Issue:**
- Session tokens may not be properly validated
- No token rotation mechanism
- Long-lived sessions increase attack window
- No device fingerprinting

**Recommendation:**
1. **Token rotation** - Rotate tokens periodically
2. **Device binding** - Bind sessions to device fingerprints
3. **Short-lived tokens** - Reduce session lifetime
4. **Revocation** - Implement token revocation mechanism

---

## 🟢 **MEDIUM PRIORITY SECURITY GAPS**

### **10. Location Data Could Identify Users**

**Location:** Multiple files

**Issue:**
- Exact coordinates (latitude/longitude) are used
- Location history could identify users
- Home/work locations are particularly sensitive

**Recommendation:**
1. **Location obfuscation** - Use approximate locations (city-level)
2. **Differential privacy** - Add noise to location data
3. **Temporal expiration** - Expire location data after time period
4. **Home location protection** - Never share home location in AI2AI network

---

### **11. Admin Authentication Weaknesses**

**Location:** `lib/core/services/admin_auth_service.dart`

**Issue:**
```dart
/// Verify admin credentials
/// In production, this would call a secure backend API
Future<bool> _verifyCredentials(String username, String password, String? twoFactorCode) async {
  // Hash password for comparison
  final passwordHash = sha256.convert(utf8.encode(password)).toString();
  
  // In production, this would check against a secure database
  // TODO: Implement secure credential verification via backend API
```

**Risk:**
- Admin authentication is placeholder code
- No proper backend verification
- Password hashing is client-side (should be server-side)
- 2FA is not properly implemented

**Recommendation:**
1. **Backend verification** - Move authentication to secure backend
2. **Server-side hashing** - Never hash passwords client-side
3. **Proper 2FA** - Implement TOTP or hardware keys
4. **Audit logging** - Log all admin access

---

### **12. No Data Retention Policies**

**Location:** Data storage

**Issue:**
- No automatic deletion of old data
- Personal information may be retained indefinitely
- No user data deletion mechanism

**Recommendation:**
1. **Retention policies** - Automatically delete old data
2. **User deletion** - Allow users to delete their data
3. **Anonymization** - Anonymize data before deletion
4. **Compliance** - Ensure GDPR/CCPA compliance

---

## 🔒 **SECURITY RECOMMENDATIONS SUMMARY**

### **Immediate Actions (Critical)**

1. **Implement Secure User Account → AI Agent Mapping**
   - Create secure mapping table with encryption
   - Implement cryptographically secure agent ID generation
   - Add one-way mapping protection (no reverse lookup)
   - Implement access controls and audit logging
   - Add agent ID rotation capability

2. **Remove userId from PersonalityProfile**
   - Replace with agentId in PersonalityProfile
   - Update all AI2AI communication to use agent IDs only
   - Add validation to ensure no userId leaks

2. **Implement Proper Encryption**
   - Replace XOR encryption with AES-256-GCM
   - Implement proper key management
   - Add perfect forward secrecy

3. **Add Device Identity Verification**
   - Issue device certificates
   - Sign all messages with device keys
   - Verify certificates before accepting connections

4. **Anonymize User Data**
   - Create AnonymousUser model
   - Filter all personal information before AI2AI transmission
   - Add comprehensive validation

### **Short-term Actions (High Priority)**

5. **Enhance Anonymization Validation**
   - Deep recursive validation
   - Block suspicious payloads
   - Comprehensive pattern matching

6. **Implement Rate Limiting**
   - Limit connection requests
   - Add DDoS protection
   - Monitor for suspicious activity

7. **Encrypt Database Fields**
   - Encrypt email, name, location at rest
   - Use field-level encryption
   - Implement access controls

### **Long-term Actions (Medium Priority)**

8. **Location Obfuscation**
   - Use approximate locations
   - Add differential privacy
   - Expire location data

9. **Session Management**
   - Token rotation
   - Device binding
   - Short-lived sessions

10. **Data Retention**
    - Automatic deletion policies
    - User data deletion
    - Compliance with regulations

---

## 📋 **IMPLEMENTATION CHECKLIST**

### **Phase 1: Critical Fixes (Week 1-2)**

- [ ] Create secure user account → AI agent mapping system
- [ ] Implement cryptographically secure agent ID generation
- [ ] Create encrypted mapping table with RLS policies
- [ ] Replace userId with agentId in PersonalityProfile
- [ ] Implement one-way mapping protection
- [ ] Add agent ID rotation capability
- [ ] Implement AES-256-GCM encryption
- [ ] Add device certificate system
- [ ] Create AnonymousUser model
- [ ] Add comprehensive data filtering

### **Phase 2: High Priority (Week 3-4)**

- [ ] Enhance anonymization validation
- [ ] Implement rate limiting
- [ ] Encrypt database fields
- [ ] Add deep payload validation
- [ ] Implement DDoS protection

### **Phase 3: Medium Priority (Week 5-6)**

- [ ] Location obfuscation
- [ ] Session management improvements
- [ ] Data retention policies
- [ ] Admin authentication fixes
- [ ] Audit logging

---

## 🔍 **TESTING REQUIREMENTS**

### **Security Testing**

1. **Penetration Testing**
   - Attempt to extract personal information from AI2AI network
   - Try to impersonate devices
   - Test encryption strength
   - Attempt to bypass anonymization

2. **Data Leakage Testing**
   - Verify no personal information in AI2AI payloads
   - Check logs for personal information
   - Verify anonymization works correctly
   - Test edge cases

3. **Authentication Testing**
   - Test device certificate validation
   - Attempt to bypass authentication
   - Test session management
   - Verify token security

---

## 📚 **REFERENCES**

- **Privacy Protection:** `VIBE_CODING/IMPLEMENTATION/privacy_protection.md`
- **AI2AI Architecture:** `VIBE_CODING/ARCHITECTURE/architecture_layers.md`
- **Anonymous Communication:** `lib/core/ai2ai/anonymous_communication.dart`
- **AI2AI Protocol:** `lib/core/network/ai2ai_protocol.dart`

---

## ✅ **COMPLIANCE CONSIDERATIONS**

### **GDPR Requirements**

- ✅ Right to be forgotten (data deletion)
- ⚠️ Data minimization (need to reduce personal data collection)
- ⚠️ Privacy by design (need to improve anonymization)
- ⚠️ Data protection (need encryption at rest)

### **CCPA Requirements**

- ✅ User data access
- ⚠️ Data deletion
- ⚠️ Opt-out mechanisms
- ⚠️ Data security (need encryption)

---

---

## 🔐 **ADDITIONAL SECURITY RECOMMENDATIONS FOR USER ACCOUNT → AI AGENT SEPARATION**

### **1. Agent ID Generation Best Practices**

**Cryptographically Secure Generation:**
```dart
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecureAgentIdGenerator {
  /// Generate cryptographically secure agent ID
  /// 
  /// Security properties:
  /// - 32 bytes of entropy (256 bits)
  /// - SHA-256 hashing for additional security
  /// - No predictable patterns
  /// - Collision-resistant
  static String generateAgentId() {
    // Generate 32 bytes of cryptographically secure random data
    final random = Random.secure();
    final entropy = List<int>.generate(32, (i) => random.nextInt(256));
    
    // Hash with SHA-256 for additional security and fixed length
    final hash = sha256.convert(entropy);
    
    // Return as base64url (URL-safe, no padding)
    final base64 = base64Encode(hash.bytes);
    return 'agent_${base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '')}';
  }
  
  /// Validate agent ID format
  static bool isValidAgentId(String agentId) {
    if (!agentId.startsWith('agent_')) return false;
    if (agentId.length < 50) return false; // Minimum length check
    return RegExp(r'^agent_[A-Za-z0-9_-]+$').hasMatch(agentId);
  }
}
```

**Key Security Features:**
- ✅ 256 bits of entropy (cryptographically secure)
- ✅ SHA-256 hashing for additional security
- ✅ URL-safe encoding
- ✅ Format validation
- ✅ No predictable patterns

---

### **2. Secure Mapping Storage**

**Database Schema:**
```sql
-- Secure user-agent mapping table
CREATE TABLE user_agent_mappings (
  -- Primary key
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  
  -- Agent ID (indexed for fast lookup, but no reverse index)
  agent_id TEXT UNIQUE NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_rotated_at TIMESTAMP WITH TIME ZONE,
  last_accessed_at TIMESTAMP WITH TIME ZONE,
  
  -- Security metadata
  encryption_key_id TEXT, -- Reference to encryption key
  access_count INTEGER DEFAULT 0,
  rotation_count INTEGER DEFAULT 0,
  
  -- Encrypted metadata (optional additional data)
  encrypted_metadata BYTEA,
  
  -- Constraints
  CONSTRAINT agent_id_format CHECK (agent_id ~ '^agent_[A-Za-z0-9_-]{32,}$')
);

-- Index for fast agent ID lookup (one-way only)
CREATE INDEX idx_user_agent_mappings_agent_id ON user_agent_mappings(agent_id);

-- RLS Policies
ALTER TABLE user_agent_mappings ENABLE ROW LEVEL SECURITY;

-- Users can only access their own mapping
CREATE POLICY "Users can access own mapping"
  ON user_agent_mappings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Only system can insert mappings (via service role)
CREATE POLICY "System can insert mappings"
  ON user_agent_mappings
  FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- Users can update their own mapping (for rotation)
CREATE POLICY "Users can update own mapping"
  ON user_agent_mappings
  FOR UPDATE
  USING (auth.uid() = user_id);
```

---

### **3. Agent ID Rotation**

**Rotation Strategy:**
```dart
class AgentIdRotationService {
  /// Rotate agent ID for a user
  /// 
  /// Security considerations:
  /// - Old agent ID remains valid for grace period
  /// - New agent ID is generated securely
  /// - Old mappings are encrypted and archived
  /// - Connected agents are notified
  Future<String> rotateAgentId(String userId) async {
    // 1. Generate new agent ID
    final newAgentId = SecureAgentIdGenerator.generateAgentId();
    
    // 2. Get old agent ID
    final oldMapping = await _getMapping(userId);
    final oldAgentId = oldMapping.agentId;
    
    // 3. Create rotation record (encrypted)
    await _createRotationRecord(
      userId: userId,
      oldAgentId: oldAgentId,
      newAgentId: newAgentId,
      rotatedAt: DateTime.now(),
    );
    
    // 4. Update mapping
    await _updateMapping(
      userId: userId,
      newAgentId: newAgentId,
      lastRotatedAt: DateTime.now(),
    );
    
    // 5. Notify connected agents (via encrypted channel)
    await _notifyConnectedAgents(
      oldAgentId: oldAgentId,
      newAgentId: newAgentId,
    );
    
    // 6. Schedule old agent ID expiration
    await _scheduleExpiration(oldAgentId, gracePeriod: Duration(days: 7));
    
    return newAgentId;
  }
}
```

**Rotation Benefits:**
- ✅ Limits exposure window if agent ID is compromised
- ✅ Allows users to reset their network identity
- ✅ Grace period prevents connection disruption
- ✅ Audit trail of all rotations

---

### **4. Access Control & Audit Logging**

**Access Control:**
```dart
class AgentMappingService {
  /// Get agent ID for user (with access control)
  Future<String?> getAgentIdForUser(String userId, {required String sessionToken}) async {
    // 1. Verify session token
    final isValid = await _verifySessionToken(sessionToken);
    if (!isValid) {
      throw UnauthorizedException('Invalid session token');
    }
    
    // 2. Verify user owns the session
    final sessionUserId = await _getUserIdFromSession(sessionToken);
    if (sessionUserId != userId) {
      throw UnauthorizedException('Session does not match user');
    }
    
    // 3. Log access
    await _logMappingAccess(
      userId: userId,
      accessedAt: DateTime.now(),
      accessType: 'lookup',
    );
    
    // 4. Get mapping (via RLS-protected query)
    final mapping = await _database
        .from('user_agent_mappings')
        .select()
        .eq('user_id', userId)
        .single();
    
    // 5. Update access metadata
    await _updateAccessMetadata(userId);
    
    return mapping['agent_id'] as String;
  }
  
  /// Audit log structure
  Future<void> _logMappingAccess({
    required String userId,
    required DateTime accessedAt,
    required String accessType,
  }) async {
    await _database.from('agent_mapping_audit_log').insert({
      'user_id': userId,
      'accessed_at': accessedAt.toIso8601String(),
      'access_type': accessType,
      'ip_address': await _getClientIpAddress(),
      'user_agent': await _getUserAgent(),
    });
  }
}
```

---

### **5. Preventing Reverse Lookup**

**One-Way Mapping Protection:**
```dart
class AgentMappingService {
  /// Get user ID from agent ID (restricted access only)
  /// 
  /// SECURITY: This should only be accessible to:
  /// - System services (with service role)
  /// - User's own account (with authentication)
  /// - Never exposed via public API
  Future<String?> getUserIdFromAgentId(
    String agentId, {
    required String serviceToken, // Service role token only
  }) async {
    // 1. Verify service token
    final isServiceRole = await _verifyServiceToken(serviceToken);
    if (!isServiceRole) {
      throw UnauthorizedException('Service role required');
    }
    
    // 2. Log reverse lookup (high security event)
    await _logReverseLookup(
      agentId: agentId,
      accessedAt: DateTime.now(),
      serviceToken: serviceToken,
    );
    
    // 3. Get mapping (encrypted query)
    final mapping = await _database
        .from('user_agent_mappings')
        .select('user_id')
        .eq('agent_id', agentId)
        .single();
    
    return mapping['user_id'] as String;
  }
  
  /// Public API should NEVER expose reverse lookup
  /// Only forward lookup (userId → agentId) is allowed
}
```

---

### **6. Encryption of Mapping Data**

**Field-Level Encryption:**
```dart
class EncryptedMappingService {
  /// Encrypt mapping metadata
  Future<Uint8List> encryptMappingMetadata(Map<String, dynamic> metadata) async {
    // 1. Get encryption key (from key management service)
    final key = await _getEncryptionKey();
    
    // 2. Serialize metadata
    final json = jsonEncode(metadata);
    final bytes = utf8.encode(json);
    
    // 3. Encrypt with AES-256-GCM
    final encrypted = await _encryptAES256GCM(bytes, key);
    
    return encrypted;
  }
  
  /// Decrypt mapping metadata
  Future<Map<String, dynamic>> decryptMappingMetadata(Uint8List encrypted) async {
    // 1. Get decryption key
    final key = await _getEncryptionKey();
    
    // 2. Decrypt
    final decrypted = await _decryptAES256GCM(encrypted, key);
    
    // 3. Deserialize
    final json = utf8.decode(decrypted);
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
```

---

### **7. Additional Security Measures**

**Rate Limiting:**
- Limit mapping lookups per user per time period
- Prevent brute force attacks on agent IDs
- Throttle rotation requests

**Monitoring:**
- Alert on unusual mapping access patterns
- Monitor for reverse lookup attempts
- Track agent ID rotation frequency

**Backup & Recovery:**
- Encrypted backups of mapping table
- Secure key management for backups
- Disaster recovery procedures

**Compliance:**
- GDPR: Right to be forgotten (delete mapping)
- CCPA: Data deletion requests
- Audit trail for compliance reporting

---

**Document Status:** Active  
**Last Updated:** November 27, 2025  
**Next Review:** After Phase 1 implementation

