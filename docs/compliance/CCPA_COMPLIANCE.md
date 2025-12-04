# CCPA Compliance Documentation

**Date:** December 1, 2025, 2:40 PM CST  
**Purpose:** CCPA compliance measures and consumer rights documentation  
**Phase:** Phase 7, Section 45-46 (7.3.7-8)

---

## Overview

SPOTS complies with the California Consumer Privacy Act (CCPA) to protect consumer privacy rights. This document outlines our CCPA compliance measures, consumer rights, and how consumers can exercise their rights.

---

## CCPA Principles

### 1. Transparency

**Implementation:**
- Clear privacy policy explaining data collection
- Disclosure of data categories collected
- Disclosure of data sharing practices

**Technical Measures:**
- Privacy policy accessible in-app
- Data collection transparency
- Clear disclosure of data practices

### 2. Consumer Rights

**Implementation:**
- Right to know
- Right to delete
- Right to opt-out of sale
- Right to non-discrimination

**Technical Measures:**
- Data access mechanisms
- Data deletion functionality
- Opt-out mechanisms
- Non-discrimination policies

### 3. Data Security

**Implementation:**
- Encryption of sensitive data
- Access controls
- Security monitoring
- Breach prevention

**Technical Measures:**
- Field-level encryption (AES-256-GCM)
- RLS policies for database access
- Audit logging
- Security event monitoring

---

## Consumer Rights Under CCPA

### Right to Know (Sections 1798.100, 1798.110, 1798.115)

**Description:** Consumers have the right to know what personal information is collected, used, shared, or sold.

**Categories of Personal Information Collected:**
1. **Identifiers:** Email address, user ID (encrypted)
2. **Personal Information:** Name, display name (encrypted)
3. **Location Data:** City-level location (obfuscated)
4. **Internet Activity:** App usage, preferences
5. **Personality Data:** Anonymized personality dimensions
6. **Geolocation Data:** Obfuscated city-level location

**How Information is Used:**
- Provide SPOTS services
- Improve user experience
- AI2AI network matching (anonymized)
- Recommendations (based on anonymized data)

**Information Sharing:**
- AI2AI network (anonymized only - no personal information)
- Service providers (under strict agreements)
- Legal compliance (when required)

**Sale of Information:**
- SPOTS does NOT sell personal information
- No sale of data to third parties

**How to Exercise:**
1. Go to Settings > Privacy
2. Select "View My Data"
3. Review collected information
4. Request detailed report via support

**Technical Implementation:**
- Data view in app
- Data export functionality
- Detailed data report generation

### Right to Delete (Section 1798.105)

**Description:** Consumers have the right to request deletion of personal information.

**Implementation:**
- Account deletion functionality
- Complete data removal (with exceptions)
- Encryption key deletion

**How to Exercise:**
1. Go to Settings > Privacy
2. Select "Delete Account"
3. Confirm deletion (irreversible)
4. All personal information will be deleted

**Technical Implementation:**
- Account deletion service
- Cascade deletion of related data
- Encryption key deletion
- Audit log entry for deletion

**Exceptions:**
- Complete transactions (e.g., tax documents for required retention)
- Legal obligations (e.g., tax document retention)
- Security purposes (audit logs for security events)
- Anonymized data (no personal identifiers - cannot identify consumer)

### Right to Opt-Out of Sale (Section 1798.120)

**Description:** Consumers have the right to opt-out of the sale of personal information.

**Implementation:**
- SPOTS does NOT sell personal information
- No sale of data to third parties
- Opt-out mechanisms available (for other data sharing)

**How to Exercise:**
1. Go to Settings > Privacy
2. Select "Privacy Preferences"
3. Opt-out of data sharing features

**Technical Implementation:**
- Privacy preference system
- Opt-out flags
- Data sharing controls

**Note:** Since SPOTS does not sell personal information, this right primarily applies to other data sharing (with user consent).

### Right to Non-Discrimination (Section 1798.125)

**Description:** Consumers cannot be discriminated against for exercising CCPA rights.

**Implementation:**
- No discrimination for exercising rights
- Same services regardless of privacy choices
- No price differences based on privacy choices

**Policy:**
- All users receive same service
- No penalties for privacy choices
- Equal access to features

---

## Data Categories and Collection

### Categories Collected

**Personal Information Categories:**
1. **Identifiers:** Email, user ID (encrypted)
2. **Personal Information:** Name, display name (encrypted)
3. **Location Data:** City-level location (obfuscated)
4. **Internet Activity:** App usage, preferences
5. **Personality Data:** Anonymized personality dimensions
6. **Geolocation Data:** Obfuscated location

**Sources:**
- Directly from consumer (profile information)
- Generated from usage (personality dimensions)
- Device information (for functionality)

**Business Purposes:**
- Providing SPOTS services
- Improving user experience
- AI2AI network matching (anonymized)
- Recommendations (based on anonymized data)

### Data Sharing

**Categories of Third Parties:**
- Service providers (under strict agreements)
- AI2AI network participants (anonymized only)
- Legal/compliance (when required)

**Purposes:**
- Service provision
- Network functionality (anonymized)
- Legal compliance

**Sale of Information:**
- NO sale of personal information
- No sale of data to third parties

---

## Privacy Controls

### Data Minimization

**Implementation:**
- Only collect necessary data
- Anonymize data before sharing
- Remove personal identifiers

**Technical Measures:**
- UserAnonymizationService
- AnonymousUser model
- Location obfuscation

### Data Security

**Implementation:**
- Encryption at rest (AES-256-GCM)
- Encryption in transit (TLS)
- Access controls (RLS policies)
- Audit logging

**Technical Measures:**
- FieldEncryptionService
- Flutter Secure Storage for keys
- Database RLS policies
- AuditLogService

### Access Controls

**Implementation:**
- User authentication required
- Role-based access control
- Audit logging of all access

**Technical Measures:**
- Authentication system
- Admin/godmode access controls
- Comprehensive audit logging

---

## Consumer Requests

### How to Submit Requests

**Methods:**
1. In-App: Settings > Privacy > Contact Support
2. Email: privacy@spots.app
3. Support Portal: [URL]

**Information Required:**
- User ID or email
- Request type (access, delete, opt-out)
- Verification of identity

**Response Time:**
- Access requests: 45 days (can extend to 90 with notice)
- Deletion requests: 45 days (can extend to 90 with notice)
- Opt-out requests: Immediate effect

### Verification Process

**Identity Verification:**
- Email verification
- Account password verification
- Additional verification for sensitive requests

**Security Measures:**
- Secure request submission
- Identity verification
- Audit logging of requests

---

## Data Deletion

### Deletion Process

**Steps:**
1. Receive deletion request
2. Verify consumer identity
3. Delete personal information
4. Delete encryption keys
5. Retain anonymized data (cannot identify consumer)
6. Confirm deletion

**Technical Implementation:**
- Account deletion service
- Cascade deletion
- Encryption key deletion
- Audit log entry

**Exceptions:**
- Complete transactions (e.g., tax documents)
- Legal obligations
- Security purposes (audit logs)
- Anonymized data (no personal identifiers)

### Data Retention

**Retention Periods:**
- Active accounts: Until deletion request
- Inactive accounts: 90 days after inactivity
- Audit logs: 90 days (security events)
- Tax documents: As required by law

---

## Opt-Out Mechanisms

### AI2AI Network Participation

**Implementation:**
- Users can opt-out of AI2AI network
- Privacy controls in settings
- Immediate effect

**How to Opt-Out:**
1. Go to Settings > Privacy
2. Disable "AI2AI Network Participation"
3. Changes take effect immediately

**Technical Implementation:**
- Privacy preference flags
- AI2AI participation toggle
- Respects opt-out preferences

### Data Sharing Preferences

**Implementation:**
- Granular privacy controls
- Opt-out of specific features
- Easy to change preferences

**How to Opt-Out:**
1. Go to Settings > Privacy
2. Adjust privacy preferences
3. Opt-out of specific features

---

## Non-Discrimination

### Policy

**Commitment:**
- No discrimination for exercising CCPA rights
- Same services for all users
- No price differences based on privacy choices

**Implementation:**
- Equal access to features
- No penalties for privacy choices
- Same quality of service

---

## Data Security Measures

### Encryption

**Implementation:**
- Field-level encryption (AES-256-GCM)
- Encryption keys in secure storage
- Data encrypted at rest

**Technical Measures:**
- FieldEncryptionService
- Flutter Secure Storage
- AES-256-GCM encryption

### Access Controls

**Implementation:**
- User authentication required
- Role-based access control
- Audit logging

**Technical Measures:**
- Authentication system
- RLS policies
- AuditLogService

### Monitoring

**Implementation:**
- Security event monitoring
- Anomaly detection
- Audit log analysis

**Technical Measures:**
- Security event logging
- Failed authentication tracking
- Unusual access pattern detection

---

## Compliance Verification

### Regular Audits

**Process:**
- Quarterly security reviews
- Annual CCPA compliance audit
- Data protection assessments

### Monitoring

**Measures:**
- Audit log review
- Security event monitoring
- Compliance metrics tracking

---

## Consumer Contact

### Exercising Rights

**Contact Information:**
- Email: privacy@spots.app
- In-App: Settings > Privacy > Contact Support
- Support Portal: [URL]

**Response Time:**
- Access requests: 45 days (can extend to 90)
- Deletion requests: 45 days (can extend to 90)
- Opt-out requests: Immediate

---

## Compliance Status

**Current Status:** ✅ Compliant

**Last Review:** December 1, 2025

**Next Review:** March 1, 2026

---

## Related Documentation

- [GDPR Compliance](GDPR_COMPLIANCE.md)
- [Security Architecture](../security/SECURITY_ARCHITECTURE.md)
- [Encryption Guide](../security/ENCRYPTION_GUIDE.md)
- [Privacy Policy](../../README.md) (Link to privacy policy)

---

**Last Updated:** December 1, 2025, 2:40 PM CST  
**Status:** Active - Compliant

