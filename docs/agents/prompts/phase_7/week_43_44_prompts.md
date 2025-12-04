# Phase 7 Agent Prompts - Feature Matrix Completion (Section 43-44 / 7.3.5-6)

**Date:** November 30, 2025, 9:54 PM CST  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Section 43-44 (7.3.5-6) (Data Anonymization & Database Security)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_43_44_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/security_implementation/SECURITY_IMPLEMENTATION_PLAN.md`** - Detailed security implementation plan
6. ✅ **`docs/SECURITY_ANALYSIS.md`** - Security analysis and requirements
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_43_44_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Section 43-44 (7.3.5-6) Overview**

**Focus:** Data Anonymization & Database Security  
**Duration:** 10 days  
**Priority:** 🟡 HIGH (Security Implementation - Phases 4-5)  
**Note:** Implement comprehensive data anonymization and database security to ensure no personal information leaks into AI2AI network and all sensitive data is encrypted at rest. This is foundational security work required before public launch.

**What Doors Does This Open?**
- **Privacy Doors:** Users can participate in AI2AI network without exposing personal information
- **Trust Doors:** Secure data handling builds user trust
- **Compliance Doors:** Meets GDPR/CCPA requirements for data protection
- **Security Doors:** Personal information protected at rest and in transit
- **Production Doors:** System ready for public launch (security foundation complete)

**Philosophy Alignment:**
- Privacy and control are non-negotiable (OUR_GUTS.md)
- Users should have complete control over their data
- Security enables authentic AI2AI connections
- "Doors, not badges" - Security opens doors to trust and compliance

**Current Status:**
- ⚠️ Basic anonymization validation exists but needs enhancement (logs warnings, doesn't block)
- ⚠️ No AnonymousUser model (services use UnifiedUser directly)
- ⚠️ No location obfuscation (exact coordinates shared)
- ⚠️ No field-level encryption (personal data stored in plain text)
- ⚠️ RLS policies need review/enhancement
- ✅ AnonymousCommunicationProtocol exists (basic structure)
- ✅ User models exist (UnifiedUser)
- ✅ Database infrastructure available

**Dependencies:**
- ✅ Section 42 (Integration Improvements) COMPLETE
- ✅ Core AI2AI services exist and are functional
- ✅ Database infrastructure available

---

## 🔧 **Agent 1: Backend & Integration Specialist**

### **Your Context**

You are working on **Phase 7, Section 43-44 (7.3.5-6): Data Anonymization & Database Security**.

**Your Focus:** Implement data anonymization validation, AnonymousUser model, location obfuscation, field-level encryption, and database access controls.

**Current State:** Basic anonymization validation exists but only logs warnings. No AnonymousUser model. No location obfuscation. No field-level encryption. Personal data may leak into AI2AI network.

### **Your Tasks**

**Day 1-2: Enhanced Anonymization Validation (Phase 4.1)**

1. **Review Existing Implementation**
   - Read `lib/core/ai2ai/anonymous_communication.dart`
   - Review `_validateAnonymousPayload()` method (lines 126-145)
   - Understand current validation logic (checks keys, logs warnings)

2. **Enhance Validation to Block Suspicious Payloads**
   - **CRITICAL CHANGE:** Change behavior from logging warnings to **blocking** (throwing exceptions)
   - Implement deep recursive validation (check nested objects, arrays)
   - Add comprehensive pattern matching:
     - Email regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
     - Phone numbers: US formats `(XXX) XXX-XXXX`, `XXX-XXX-XXXX`, international formats
     - Addresses: Street patterns, PO boxes, apartment numbers
     - SSN: `XXX-XX-XXXX` pattern
     - Credit cards: Common card number patterns (be careful with false positives)
   - Recursively check nested objects and arrays
   - Return specific error messages (which pattern was detected)

3. **Create Comprehensive Test Suite**
   - Test all pattern detections
   - Test nested structures
   - Test edge cases
   - Verify that suspicious payloads are **blocked** (not just logged)

**Day 3-4: AnonymousUser Model & User Anonymization Service (Phase 4.2)**

1. **Create AnonymousUser Model**
   - Review `lib/core/models/unified_user.dart` to understand UnifiedUser structure
   - Create `lib/core/models/anonymous_user.dart`
   - **MANDATORY:** NO personal information fields (no userId, email, name, phone, address)
   - Include: agentId (required), personalityDimensions, preferences (filtered), expertise, location (obfuscated)
   - Implement JSON serialization
   - Add validation methods

2. **Create User Anonymization Service**
   - Create `lib/core/services/user_anonymization_service.dart`
   - Implement conversion: `UnifiedUser` → `AnonymousUser`
   - Filter out ALL personal information
   - Use LocationObfuscationService for location
   - Add validation to prevent personal data leaks

3. **Update AI2AI Services**
   - Find all services that use UnifiedUser in AI2AI context:
     - ConnectionOrchestrator
     - PersonalityAdvertisingService
     - AI2AIProtocol
   - Update them to convert UnifiedUser → AnonymousUser before transmission
   - Add validation checks

**Day 5: Location Obfuscation Service (Phase 4.3)**

1. **Create Location Obfuscation Service**
   - Create `lib/core/services/location_obfuscation_service.dart`
   - Implement city-level obfuscation (round coordinates to city center)
   - Implement differential privacy (add controlled random noise)
   - Implement expiration checks (expire old location data)
   - **CRITICAL:** Never share home location (check against saved home location)

2. **Update Location Services**
   - Update services that share location in AI2AI network
   - Integrate obfuscation service
   - Ensure home location protection

**Day 6-7: Field-Level Encryption Service (Phase 5.1)**

1. **Create Field Encryption Service**
   - Create `lib/core/services/field_encryption_service.dart`
   - Use AES-256-GCM encryption
   - Use Flutter Secure Storage for encryption keys (Keychain/Keystore)
   - Implement encryption for: email, name, location, phone
   - Implement decryption (for authorized access only)
   - Implement key management (key rotation support)

2. **Update User Model**
   - Update UnifiedUser to support encrypted fields
   - Update serialization to handle encrypted data

3. **Create Database Migration**
   - Create migration for encrypted field storage
   - Ensure migration is reversible

**Day 8-9: Access Controls & RLS Policies (Phase 5.2)**

1. **Review and Enhance RLS Policies**
   - Review existing Supabase RLS policies
   - Ensure users can only access their own data
   - Add admin access with privacy filtering
   - Add service role access controls

2. **Implement Audit Logging**
   - Create/enhance `lib/core/services/audit_log_service.dart`
   - Log all sensitive data access
   - Store logs securely

3. **Implement Rate Limiting**
   - Add rate limiting for sensitive operations
   - Handle rate limit errors gracefully

4. **Create Database Migration**
   - Create migration for RLS policy updates
   - Create audit log table (if needed)

**Day 10: Integration & Testing**

1. **Integration Testing**
   - Test end-to-end anonymization flow
   - Test field encryption/decryption
   - Test RLS policies
   - Verify no personal data leaks

2. **Documentation**
   - Document security architecture
   - Document service usage
   - Document database schema changes

### **Key Files to Reference**

- `lib/core/ai2ai/anonymous_communication.dart` - Existing validation (needs enhancement)
- `lib/core/models/unified_user.dart` - User model reference
- `docs/plans/security_implementation/SECURITY_IMPLEMENTATION_PLAN.md` - Detailed plan
- Flutter Secure Storage documentation - For encryption keys

### **Success Criteria**

- ✅ Deep recursive validation blocks suspicious payloads (not just logs)
- ✅ AnonymousUser model created (zero personal data fields)
- ✅ User anonymization service converts UnifiedUser → AnonymousUser
- ✅ Location obfuscation implemented (city-level, differential privacy)
- ✅ Field-level encryption implemented (email, name, location, phone)
- ✅ RLS policies enforce access control
- ✅ Audit logging works
- ✅ Rate limiting implemented
- ✅ Zero linter errors

### **Deliverables**

- Enhanced anonymization validation
- AnonymousUser model
- User anonymization service
- Location obfuscation service
- Field encryption service
- Database migrations
- Updated AI2AI services
- Comprehensive tests
- Documentation
- Completion report: `docs/agents/reports/agent_1/phase_7/week_43_44_completion_report.md`

---

## 🎨 **Agent 2: Frontend & UX Specialist**

### **Your Context**

You are working on **Phase 7, Section 43-44 (7.3.5-6): Data Anonymization & Database Security**.

**Your Focus:** Verify and update UI components to ensure no personal information is displayed in AI2AI network contexts and all location displays use obfuscated locations.

### **Your Tasks**

**Day 1-5: UI Verification & Updates**

1. **Review UI for Personal Data Display**
   - Review all screens that display user information in AI2AI context
   - Check: Connection views, AI2AI network views, personality displays
   - Verify: No personal information (name, email, phone, address) displayed
   - Check location displays (should show obfuscated/city-level only)

2. **Update UI Components (if needed)**
   - Update components to use AnonymousUser model (instead of UnifiedUser)
   - Update location displays to show obfuscated locations
   - Add privacy indicators where appropriate
   - Ensure error messages are user-friendly (if validation fails)

3. **Verify Privacy Settings UI**
   - Check privacy settings screens
   - Verify location sharing controls work correctly
   - Verify anonymization preferences (if any)
   - Ensure users can control data sharing

4. **Update Navigation/Integration**
   - If AnonymousUser model affects navigation or routing, update accordingly
   - Update any user profile displays in AI2AI contexts

### **Key Files to Reference**

- UI components that display user information in AI2AI contexts
- Privacy settings screens
- Location display components

### **Success Criteria**

- ✅ No personal information displayed in AI2AI network contexts
- ✅ Location displays use obfuscated locations
- ✅ UI components handle AnonymousUser correctly
- ✅ Privacy controls are clear and functional
- ✅ Zero linter errors
- ✅ 100% design token compliance

### **Deliverables**

- Updated UI components (if needed)
- Verification report
- Completion report: `docs/agents/reports/agent_2/phase_7/week_43_44_completion_report.md`

---

## 🧪 **Agent 3: Models & Testing Specialist**

### **Your Context**

You are working on **Phase 7, Section 43-44 (7.3.5-6): Data Anonymization & Database Security**.

**Your Focus:** Create comprehensive test suites for all anonymization and security features.

### **Your Tasks**

**Day 1-5: Anonymization Testing**

1. **Enhanced Validation Tests**
   - Expand `test/unit/ai2ai/anonymous_communication_test.dart`
   - Test email detection (various formats)
   - Test phone number detection (various formats)
   - Test address detection (various formats)
   - Test SSN detection
   - Test credit card detection (be careful with false positives)
   - Test nested object validation
   - Test array validation
   - Test edge cases (unicode, obfuscated patterns)
   - **CRITICAL:** Verify suspicious payloads are **blocked** (exceptions thrown)

2. **AnonymousUser Model Tests**
   - Create `test/unit/models/anonymous_user_test.dart`
   - Test model creation
   - Test JSON serialization/deserialization
   - Test validation (rejects personal data)
   - Test equality and hashCode

3. **User Anonymization Service Tests**
   - Create `test/unit/services/user_anonymization_service_test.dart`
   - Test UnifiedUser → AnonymousUser conversion
   - Test personal data filtering
   - Test location obfuscation integration
   - Test validation
   - Test edge cases

4. **Location Obfuscation Service Tests**
   - Create `test/unit/services/location_obfuscation_service_test.dart`
   - Test city-level obfuscation
   - Test differential privacy
   - Test location expiration
   - Test home location protection

**Day 6-10: Database Security Testing**

1. **Field Encryption Service Tests**
   - Create `test/unit/services/field_encryption_service_test.dart`
   - Test email encryption/decryption
   - Test name encryption/decryption
   - Test location encryption/decryption
   - Test phone encryption/decryption
   - Test key management
   - Test key rotation
   - Test error handling

2. **RLS Policy Tests**
   - Create `test/integration/rls_policy_test.dart`
   - Test users can only access own data
   - Test admin access with privacy filtering
   - Test unauthorized access is blocked

3. **Audit Logging Tests**
   - Create or expand `test/unit/services/audit_log_service_test.dart`
   - Test audit log creation
   - Test audit log retrieval
   - Test audit log security

4. **Rate Limiting Tests**
   - Create or expand rate limiting tests
   - Test rate limiting triggers
   - Test rate limit reset
   - Test error handling

5. **Security Integration Tests**
   - Create `test/integration/security_integration_test.dart`
   - Test complete anonymization flow
   - Test field encryption integration
   - Test RLS policies with encrypted fields
   - Test no personal data leaks

### **Key Files to Reference**

- Existing test files in `test/unit/ai2ai/`
- `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md` - Testing workflow
- Test helpers and fixtures

### **Success Criteria**

- ✅ Comprehensive test coverage (>90% for new code)
- ✅ All anonymization tests passing
- ✅ All database security tests passing
- ✅ Integration tests verify end-to-end security
- ✅ All tests passing
- ✅ Test documentation complete

### **Deliverables**

- Enhanced anonymization validation tests
- AnonymousUser model tests
- User anonymization service tests
- Location obfuscation service tests
- Field encryption service tests
- RLS policy tests
- Audit logging tests
- Rate limiting tests
- Security integration tests
- Completion report: `docs/agents/reports/agent_3/phase_7/week_43_44_completion_report.md`

---

## 📚 **General Guidelines for All Agents**

### **Code Quality Standards**

- ✅ **Zero linter errors** (mandatory)
- ✅ **100% design token compliance** (Agent 2 - AppColors/AppTheme only)
- ✅ **Comprehensive error handling** (all async operations)
- ✅ **Proper logging** (use AppLogger or developer.log)
- ✅ **Security-first approach** (no shortcuts on security)

### **Security Requirements**

- ✅ **Block suspicious payloads** - Don't just log warnings, block them
- ✅ **No personal data in AnonymousUser** - Double-check all fields
- ✅ **Never share home location** - Always check against saved home location
- ✅ **Encrypt sensitive data** - Use AES-256-GCM for field-level encryption
- ✅ **Secure key management** - Use Flutter Secure Storage (Keychain/Keystore)
- ✅ **Test thoroughly** - Security bugs are critical

### **Testing Requirements**

- ✅ **Agent 3:** Create comprehensive tests for all new code
- ✅ **Test coverage:** >90% for new code
- ✅ **All tests must pass** before completion
- ✅ **Security tests are critical** - no shortcuts

### **Documentation Requirements**

- ✅ **Completion reports:** Required for all agents
- ✅ **Status tracker updates:** Update `docs/agents/status/status_tracker.md`
- ✅ **Follow refactoring protocol:** `docs/agents/REFACTORING_PROTOCOL.md`
- ✅ **Document security architecture:** Critical for production

---

## ✅ **Section 43-44 (7.3.5-6) Completion Checklist**

### **Agent 1:**
- [ ] Enhanced anonymization validation (blocks suspicious payloads)
- [ ] AnonymousUser model created (no personal data)
- [ ] User anonymization service created
- [ ] Location obfuscation service created
- [ ] Field encryption service created
- [ ] RLS policies enhanced
- [ ] Audit logging implemented
- [ ] Rate limiting implemented
- [ ] Database migrations created
- [ ] AI2AI services updated to use AnonymousUser
- [ ] Zero linter errors
- [ ] Completion report created

### **Agent 2:**
- [ ] UI reviewed for personal data display
- [ ] UI components updated (if needed)
- [ ] Privacy settings verified
- [ ] Location displays use obfuscated locations
- [ ] Zero linter errors
- [ ] 100% design token compliance verified
- [ ] Completion report created

### **Agent 3:**
- [ ] Enhanced validation tests created
- [ ] AnonymousUser model tests created
- [ ] User anonymization service tests created
- [ ] Location obfuscation service tests created
- [ ] Field encryption service tests created
- [ ] RLS policy tests created
- [ ] Audit logging tests created
- [ ] Rate limiting tests created
- [ ] Security integration tests created
- [ ] Test coverage >90%
- [ ] All tests passing
- [ ] Completion report created

---

**Status:** 🎯 **READY TO USE**  
**Next:** Agents start work on Section 43-44 (7.3.5-6) tasks

