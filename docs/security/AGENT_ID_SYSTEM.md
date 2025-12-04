# Agent ID System Documentation

**Date:** December 1, 2025, 2:40 PM CST  
**Purpose:** Agent ID generation and user-agent mapping documentation  
**Phase:** Phase 7, Section 45-46 (7.3.7-8)

---

## Overview

The Agent ID System provides cryptographically secure anonymous identifiers for AI2AI network participation. Agent IDs are used instead of user IDs to ensure complete anonymity in the AI2AI network.

---

## Agent ID Format

**Format:** `agent_[32+ character base64url string]`

**Requirements:**
- Must start with "agent_"
- Minimum 32 characters after prefix
- Base64url encoded
- Cryptographically secure random generation

**Example:** `agent_aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA`

---

## Agent ID Generation

### Secure Generation

**Properties:**
- 256 bits of entropy
- Cryptographically secure random generation
- SHA-256 hashing for additional security
- Collision-resistant

**Generation Process:**
1. Generate 32 random bytes (256 bits)
2. Apply SHA-256 hashing
3. Base64url encode
4. Prepend "agent_" prefix
5. Validate format

**Security:**
- Uses secure random generator
- No predictable patterns
- Collision-resistant
- Cannot be reverse-engineered

---

## User-Agent Mapping

### Mapping Storage

**Location:** Database table `user_agent_mappings`

**Structure:**
- `user_id`: User ID (references auth.users)
- `agent_id`: Agent ID (unique, format validated)
- `created_at`: Creation timestamp
- `last_rotated_at`: Last rotation timestamp
- `last_accessed_at`: Last access timestamp
- `encryption_key_id`: Encryption key identifier
- `access_count`: Access counter
- `rotation_count`: Rotation counter

### Encryption of Mappings

**Encryption:**
- Mapping data encrypted at rest
- Encryption keys in secure storage
- Field-level encryption for sensitive fields

**Access Control:**
- RLS policies restrict access
- Users can only view their own mapping
- Service role for system operations

---

## Agent ID Usage

### AI2AI Network Participation

**Usage:**
- Agent IDs used instead of user IDs in AI2AI network
- No personal information associated with agent IDs
- Anonymous communication via agent IDs

**Benefits:**
- Complete anonymity
- No user identification possible
- Privacy protection
- Secure network participation

### Service Integration

**Services Using Agent IDs:**
- ConnectionOrchestrator
- PersonalityAdvertisingService
- AI2AIProtocol
- AnonymousCommunicationProtocol

**Pattern:**
- Convert UnifiedUser → AnonymousUser
- AnonymousUser contains agentId (not userId)
- All AI2AI operations use agentId

---

## Agent ID Rotation

### Rotation Process

**Purpose:**
- Enhance privacy
- Prevent tracking
- Security best practice

**Process:**
1. Generate new agent ID
2. Update mapping
3. Rotate encryption keys if needed
4. Update last_rotated_at timestamp
5. Increment rotation_count

**User Control:**
- Users can request rotation
- Automatic rotation options (future)
- Rotation history tracking

---

## Security Measures

### Access Control

**RLS Policies:**
- Users can only SELECT their own mapping
- Only service role can INSERT
- Users can UPDATE their own mapping (rotation)

### Encryption

**Field Encryption:**
- Sensitive mapping data encrypted
- Keys in secure storage
- AES-256-GCM encryption

### Audit Logging

**Tracking:**
- Agent ID generation
- Mapping access
- Rotation events
- Security events

---

## Validation

### Format Validation

**Checks:**
- Must start with "agent_"
- Minimum length requirements
- Valid base64url encoding
- No forbidden characters

**Implementation:**
- Validation in UserAnonymizationService
- AnonymousUser.validateNoPersonalData()
- Format checks in services

### Security Validation

**Checks:**
- No personal data in agent ID
- Cannot be reverse-engineered
- Cryptographically secure
- Collision-resistant

---

## Related Documentation

- [Security Architecture](SECURITY_ARCHITECTURE.md)
- [Encryption Guide](ENCRYPTION_GUIDE.md)
- [Best Practices](BEST_PRACTICES.md)

---

**Last Updated:** December 1, 2025, 2:40 PM CST  
**Status:** Active

