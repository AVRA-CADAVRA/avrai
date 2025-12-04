# Phase 7 Agent Prompts - Feature Matrix Completion (Section 45-46 / 7.3.7-8)

**Date:** December 1, 2025, 10:03 AM CST  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Section 45-46 (7.3.7-8) (Security Testing & Compliance Validation)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_45_46_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/security_implementation/SECURITY_IMPLEMENTATION_PLAN.md`** - Detailed security implementation plan
6. ✅ **`docs/SECURITY_ANALYSIS.md`** - Security analysis and requirements
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_45_46_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Section 45-46 (7.3.7-8) Overview**

**Focus:** Security Testing & Compliance Validation  
**Priority:** 🟡 HIGH  
**Timeline:** 10 days

**What This Section Does:**
- Comprehensive security testing (penetration, data leakage, authentication)
- Compliance validation (GDPR, CCPA)
- Security documentation
- Production deployment preparation

**What Doors Does This Open?**
- **Security Doors:** Validated security measures build user trust
- **Compliance Doors:** Meets GDPR/CCPA requirements for regulatory compliance
- **Production Doors:** System ready for public launch with validated security
- **Trust Doors:** Comprehensive testing demonstrates commitment to user privacy

**Philosophy Alignment:**
- Privacy and control are non-negotiable (OUR_GUTS.md)
- Security enables authentic AI2AI connections
- Compliance opens doors to global user base
- "Doors, not badges" - Security testing validates trust

**Current Status:**
- ✅ Section 43-44 COMPLETE - All anonymization and security features implemented
- ✅ AnonymousUser model implemented
- ✅ User anonymization service implemented
- ✅ Location obfuscation service implemented
- ✅ Field encryption service implemented
- ✅ AI2AI services updated to use AnonymousUser (integration complete)
- ✅ Audit logging implemented
- ✅ RLS policies enhanced
- ⚠️ Security testing needed to validate all measures
- ⚠️ Compliance validation needed (GDPR/CCPA)
- ⚠️ Security documentation needed
- ⚠️ Production deployment preparation needed

**Dependencies:**
- ✅ Section 43-44 (Data Anonymization & Database Security) COMPLETE
- ✅ All security features implemented
- ✅ AI2AI services integration complete

---

## 🔧 **Agent 1: Backend & Integration Specialist**

### **Your Context**

You are working on **Phase 7, Section 45-46 (7.3.7-8): Security Testing & Compliance Validation**.

**Your Focus:** Implement comprehensive security testing, validate compliance (GDPR/CCPA), create security documentation, and prepare for production deployment.

**Current State:** All security features are implemented (Section 43-44 complete), but they need to be tested and validated. Compliance needs to be verified and documented. Production deployment needs to be prepared.

### **Your Tasks**

**Day 1-3: Security Testing Implementation (Section 45 / 7.3.7 - Phase 6.1)**

1. **Create Penetration Tests**
   - Create `test/security/penetration_tests.dart`
   - Test attempts to extract personal information
   - Test device impersonation attempts
   - Test encryption strength (AES-256-GCM)
   - Test anonymization bypass attempts
   - Test RLS policy bypass attempts
   - Test audit log tampering attempts

2. **Create Data Leakage Tests**
   - Create `test/security/data_leakage_tests.dart`
   - Verify no personal info in AI2AI payloads (test all services: ConnectionOrchestrator, PersonalityAdvertisingService, AI2AIProtocol)
   - Check logs for personal information leaks
   - Verify anonymization works correctly
   - Test AnonymousUser validation (ensure no personal data)
   - Test location obfuscation (verify city-level only)
   - Test field encryption (verify encrypted at rest)

3. **Create Authentication Tests**
   - Create `test/security/authentication_tests.dart`
   - Test device certificate validation
   - Test authentication bypass attempts
   - Test session management
   - Test unauthorized access attempts
   - Test admin/godmode access controls

**Day 4-5: Compliance Validation (Section 46 / 7.3.8 - Phase 6.2)**

1. **GDPR Compliance Check**
   - Verify right to be forgotten (data deletion)
   - Verify data minimization (only collect necessary data)
   - Verify privacy by design (anonymization, encryption)
   - Verify user consent mechanisms
   - Verify data portability (if applicable)

2. **CCPA Compliance Check**
   - Verify data deletion mechanisms
   - Verify opt-out mechanisms
   - Verify data security measures
   - Verify user rights (access, deletion, opt-out)

3. **Create Compliance Documentation**
   - Create `docs/compliance/GDPR_COMPLIANCE.md`
   - Create `docs/compliance/CCPA_COMPLIANCE.md`
   - Document compliance measures
   - Document user rights and how to exercise them

**Day 6-7: Security Documentation (Section 46 / 7.3.8 - Phase 7.1)**

1. **Create Security Architecture Documentation**
   - Create `docs/security/SECURITY_ARCHITECTURE.md`
   - Document security layers (anonymization, encryption, validation, audit, RLS)
   - Document data flow (UnifiedUser → AnonymousUser → AI2AI)
   - Create architecture diagrams

2. **Create Agent ID System Documentation**
   - Create `docs/security/AGENT_ID_SYSTEM.md`
   - Document agent ID generation
   - Document user-agent mapping
   - Document encryption of mappings

3. **Create Encryption Documentation**
   - Create `docs/security/ENCRYPTION_GUIDE.md`
   - Document field-level encryption (AES-256-GCM)
   - Document key management (Flutter Secure Storage)
   - Document encryption/decryption process

4. **Create Security Best Practices**
   - Create `docs/security/BEST_PRACTICES.md`
   - Document security best practices for developers
   - Document security guidelines
   - Document security review process

**Day 8-10: Deployment Preparation (Section 46 / 7.3.8 - Phase 7.2)**

1. **Deployment Verification**
   - Verify database migrations are ready
   - Verify code changes are production-ready
   - Create deployment checklist
   - Verify production security configuration

2. **Security Monitoring Setup**
   - Set up security alert mechanisms
   - Document security monitoring process
   - Create security incident response plan
   - Document security audit process

### **Deliverables**

- ✅ `test/security/penetration_tests.dart` - Comprehensive penetration tests
- ✅ `test/security/data_leakage_tests.dart` - Data leakage validation
- ✅ `test/security/authentication_tests.dart` - Authentication security
- ✅ `docs/compliance/GDPR_COMPLIANCE.md` - GDPR compliance documentation
- ✅ `docs/compliance/CCPA_COMPLIANCE.md` - CCPA compliance documentation
- ✅ `docs/security/SECURITY_ARCHITECTURE.md` - Security architecture
- ✅ `docs/security/AGENT_ID_SYSTEM.md` - Agent ID system
- ✅ `docs/security/ENCRYPTION_GUIDE.md` - Encryption guide
- ✅ `docs/security/BEST_PRACTICES.md` - Security best practices
- ✅ Deployment checklist
- ✅ Security monitoring documentation
- ✅ Security incident response plan
- ✅ All security tests passing
- ✅ Zero linter errors
- ✅ Completion report: `docs/agents/reports/agent_1/phase_7/week_45_46_completion_report.md`

### **Quality Standards**

- ✅ All security tests pass
- ✅ No vulnerabilities found
- ✅ Personal information protected
- ✅ GDPR requirements met
- ✅ CCPA requirements met
- ✅ Compliance documented
- ✅ Security documentation complete
- ✅ Production deployment ready
- ✅ Zero linter errors

---

## 🎨 **Agent 2: Frontend & UX Specialist**

### **Your Context**

You are working on **Phase 7, Section 45-46 (7.3.7-8): Security Testing & Compliance Validation**.

**Your Focus:** Verify UI security (no personal data leaks), verify privacy controls, and verify compliance UI elements.

**Current State:** UI components exist, but need security verification to ensure no personal data is displayed in AI2AI contexts.

### **Your Tasks**

**Day 1-3: UI Security Verification**

1. **UI Data Leakage Check**
   - Review all AI2AI UI components for personal data display
   - Verify no personal information in connection views
   - Verify location displays use obfuscated locations
   - Verify user names/emails not displayed in AI2AI contexts
   - Test UI components with AnonymousUser data
   - Files to check:
     - `lib/presentation/widgets/network/ai2ai_connection_view_widget.dart`
     - `lib/presentation/pages/network/ai2ai_connection_view.dart`
     - `lib/presentation/widgets/ai2ai/user_connections_display.dart`
     - `lib/presentation/widgets/ai2ai/personality_overview_card.dart`
     - Any other AI2AI-related UI components

2. **Privacy Controls UI**
   - Verify privacy controls are accessible
   - Verify user can control data sharing
   - Verify opt-out mechanisms work in UI
   - Verify data deletion UI works

3. **Security Indicators**
   - Verify security indicators are visible (if applicable)
   - Verify encryption status indicators (if applicable)
   - Verify privacy status indicators

**Day 4-5: Compliance UI (Optional)**

1. **GDPR/CCPA UI Elements**
   - Verify consent mechanisms in UI (if applicable)
   - Verify data deletion UI works
   - Verify opt-out UI works
   - Verify user rights UI (access, deletion, opt-out)

### **Deliverables**

- ✅ UI security verification report
- ✅ Privacy controls verification
- ✅ Compliance UI verification (if applicable)
- ✅ Zero linter errors
- ✅ 100% design token compliance (AppColors/AppTheme, NO direct Colors.*)
- ✅ Completion report: `docs/agents/reports/agent_2/phase_7/week_45_46_completion_report.md`

### **Quality Standards**

- ✅ No personal data in AI2AI UI contexts
- ✅ Privacy controls accessible
- ✅ Compliance UI verified (if applicable)
- ✅ Zero linter errors
- ✅ 100% design token compliance

---

## 🧪 **Agent 3: Models & Testing Specialist**

### **Your Context**

You are working on **Phase 7, Section 45-46 (7.3.7-8): Security Testing & Compliance Validation**.

**Your Focus:** Create comprehensive security test suite (penetration, data leakage, authentication) and compliance test suite (GDPR, CCPA).

**Current State:** Security features are implemented, but comprehensive security tests need to be created to validate all measures.

### **Your Tasks**

**Day 1-5: Security Test Suite Creation**

1. **Create Penetration Tests**
   - Create `test/security/penetration_tests.dart`
   - Test all attack vectors
   - Test encryption strength
   - Test anonymization bypass
   - Test authentication bypass
   - Test RLS policy bypass
   - Comprehensive test coverage

2. **Create Data Leakage Tests**
   - Create `test/security/data_leakage_tests.dart`
   - Test all AI2AI services for personal data leaks
   - Test AnonymousUser validation
   - Test location obfuscation
   - Test field encryption
   - Test log sanitization
   - Comprehensive test coverage

3. **Create Authentication Tests**
   - Create `test/security/authentication_tests.dart`
   - Test device certificate validation
   - Test authentication bypass attempts
   - Test session management
   - Test unauthorized access
   - Test admin/godmode access
   - Comprehensive test coverage

4. **Create Integration Security Tests**
   - Update/create `test/integration/security_integration_test.dart`
   - Test end-to-end security flows
   - Test cross-service security
   - Test security error handling

**Day 6-7: Compliance Test Suite**

1. **Create GDPR Compliance Tests**
   - Create `test/compliance/gdpr_compliance_test.dart`
   - Test right to be forgotten (data deletion)
   - Test data minimization
   - Test privacy by design
   - Test user consent mechanisms

2. **Create CCPA Compliance Tests**
   - Create `test/compliance/ccpa_compliance_test.dart`
   - Test data deletion
   - Test opt-out mechanisms
   - Test data security
   - Test user rights

**Day 8-10: Test Documentation & Review**

1. **Test Documentation**
   - Document all security tests
   - Document test coverage
   - Document test execution process
   - Create test report template

2. **Test Review**
   - Review all security tests
   - Verify test coverage (>90% for security features)
   - Fix any failing tests
   - Optimize test performance

### **Deliverables**

- ✅ `test/security/penetration_tests.dart` - Comprehensive penetration tests
- ✅ `test/security/data_leakage_tests.dart` - Data leakage validation
- ✅ `test/security/authentication_tests.dart` - Authentication security
- ✅ `test/integration/security_integration_test.dart` - Integration security tests
- ✅ `test/compliance/gdpr_compliance_test.dart` - GDPR compliance tests
- ✅ `test/compliance/ccpa_compliance_test.dart` - CCPA compliance tests
- ✅ Test documentation
- ✅ Test coverage report (>90% for security features)
- ✅ All tests passing
- ✅ Zero linter errors
- ✅ Completion report: `docs/agents/reports/agent_3/phase_7/week_45_46_completion_report.md`

### **Quality Standards**

- ✅ Comprehensive security test suite created
- ✅ All security tests passing
- ✅ Test coverage >90% for security features
- ✅ Compliance tests created
- ✅ All compliance tests passing
- ✅ Test documentation complete
- ✅ Zero linter errors

### **Testing Workflow**

Follow the **Parallel Testing Workflow** (`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`):
- Write tests based on specifications
- Tests should validate security measures work correctly
- Tests should catch vulnerabilities
- Tests should validate compliance requirements

---

## 📋 **Common Instructions for All Agents**

### **Status Updates**

**When Starting Work:**
- Update `docs/agents/status/status_tracker.md` to show Section 45-46 IN PROGRESS

**When Completing Work:**
- Update `docs/agents/status/status_tracker.md` to show Section 45-46 COMPLETE
- Create completion report in `docs/agents/reports/agent_X/phase_7/week_45_46_completion_report.md`

### **File Organization**

- ✅ All new files in appropriate directories (`test/security/`, `docs/compliance/`, `docs/security/`)
- ✅ Follow existing code patterns and conventions
- ✅ Use design tokens (AppColors/AppTheme) - NO direct Colors.* usage
- ✅ Follow documentation protocol (`docs/agents/REFACTORING_PROTOCOL.md`)

### **Quality Requirements**

- ✅ Zero linter errors
- ✅ All tests passing
- ✅ Code follows existing patterns
- ✅ Documentation complete
- ✅ Design token compliance (Agent 2)

### **Philosophy Alignment**

**Doors This Opens:**
- Security (validated security measures)
- Compliance (GDPR/CCPA compliance)
- Production (system ready for public launch)
- Trust (comprehensive testing demonstrates commitment)

**When Users Are Ready:**
- Security is foundational - must be validated before launch
- Compliance is required for global user base
- Testing demonstrates commitment to user privacy

**Is This Being a Good Key?**
- Yes - Validates security measures protect user privacy
- Demonstrates commitment to user trust
- Opens doors to global user base through compliance

**Is the AI Learning With the User?**
- Yes - Secure anonymization enables safe AI2AI learning
- Privacy protection allows more open learning
- Trust network enables better learning outcomes

---

## 🎯 **Success Criteria**

**Overall Section Success:**
- ✅ All security tests pass
- ✅ No vulnerabilities found
- ✅ Personal information protected
- ✅ GDPR requirements met
- ✅ CCPA requirements met
- ✅ Compliance documented
- ✅ Security documentation complete
- ✅ Production deployment ready
- ✅ Zero linter errors
- ✅ All tests passing (>90% coverage)

---

**Status:** 🎯 **READY TO USE**  
**Next Step:** Agents begin work on Section 45-46 tasks

