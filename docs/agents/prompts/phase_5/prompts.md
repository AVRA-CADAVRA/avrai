# Phase 5 Agent Prompts - Operations & Compliance

**Date:** November 23, 2025, 1:09 PM CST  
**Purpose:** Ready-to-use prompts for Phase 5 agents  
**Status:** 🎯 **READY FOR PHASE 5**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 5 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/agents/guides/PHASE_3_PREPARATION.md` - Setup guide (applies to Phase 5)
3. ✅ **Read:** `docs/agents/START_HERE_PHASE_3.md` - Quick checklist (applies to Phase 5)
4. ✅ **Read:** `docs/plans/operations_compliance/OPERATIONS_COMPLIANCE_PLAN.md` - Detailed plan

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_5/prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_5/task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_5/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_5_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_5.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: Tasks Are Assigned = Phase 5 Is IN PROGRESS**

**This prompts document EXISTS (along with task assignments), which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 5 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document + task assignments exist):**

- ❌ **NO new tasks can be added** to Phase 5 weeks in Master Plan
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**Before adding ANY new task to Phase 5:**
- ✅ Check Master Plan week status
- ✅ Verify week shows "🟢 Ready to Start" (not "🟡 In Progress")
- ✅ Verify no task assignments document exists
- ✅ If tasks are assigned, use a different week or wait for completion

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 5 Overview**

**Duration:** Weeks 16-21 (6 weeks)  
**Focus:** Operations & Compliance - Trust, Safety, and Legal Requirements  
**Agents:** 3 parallel agents working on different aspects

**Philosophy:** These features ensure trust and safety as the platform scales. They're not MVP blockers, but essential for growth. They open doors to user confidence, legal compliance, and platform security.

**When to Start:** After first 100 paid events (validate demand, then add compliance)

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 16-17 Prompt:**

```
You are Agent 1 working on Phase 5, Weeks 16-17: Basic Refund Policy & Post-Event Feedback.

**Your Role:** Backend & Integration Specialist
**Focus:** Cancellation Service, Refund Service, Feedback Service, Success Analysis Service

**Context:**
- Phase 4 (Integration Testing) is complete
- All code compiles with 0 errors
- Payment services exist (from Phase 1)
- Event services exist (from Phase 1)
- Partnership services exist (from Phase 2)
- Need comprehensive refund, cancellation, and feedback systems

**Your Tasks:**
1. Cancellation & Refund Service (Week 16, Day 1-3)
   - Create Cancellation model with CancellationInitiator enum
   - Create RefundPolicy class with time-based refund windows
   - Create CancellationService with attendeeCancelTicket(), hostCancelEvent(), emergencyCancelEvent()
   - Create RefundService with Stripe refund processing
   - Integration with PaymentService and RevenueSplitService
   - Test edge cases and error handling

2. Safety Guidelines Service (Week 16, Day 4-5)
   - Create EventSafetyGuidelines model
   - Create EventSafetyService with safety requirement determination
   - Integration with Event service

3. Dispute Resolution Service (Week 16, Day 5)
   - Create Dispute model
   - Create DisputeResolutionService with automated and manual resolution
   - Integration with CancellationService

4. Post-Event Feedback Service (Week 17, Day 1-3)
   - Create EventFeedback and PartnerRating models
   - Create PostEventFeedbackService with feedback collection and partner ratings
   - Integration with Event and Partnership services
   - Feed into vibe matching algorithm

5. Success Analysis Service (Week 17, Day 4-5)
   - Create EventSuccessMetrics model
   - Create EventSuccessAnalysisService with success level determination
   - Integration with Feedback service
   - Feed into recommendation algorithm

**Deliverables:**
- All service files
- Test files for all services
- Service documentation
- Integration with existing services

**Dependencies:**
- All Phase 1-4 services complete
- Payment service integration required

**Quality Standards:**
- Test coverage > 90% for services
- All tests pass
- All edge cases covered
- Error handling tested
- Integration verified

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- `docs/plans/operations_compliance/OPERATIONS_COMPLIANCE_PLAN.md` - Detailed plan
- Existing service files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 1, Week 16-17)
2. Reviewing existing service patterns
3. Creating CancellationService
4. Creating RefundService
5. Creating FeedbackService
```

---

### **Week 18-19 Prompt:**

```
You are Agent 1 working on Phase 5, Weeks 18-19: Tax Compliance & Legal.

**Your Role:** Backend & Integration Specialist
**Focus:** Tax Compliance Service, Sales Tax Service, Legal Document Service

**Context:**
- Week 16-17 services complete
- Tax compliance needed for revenue
- Legal documents needed for platform compliance

**Your Tasks:**
1. Tax Compliance Service (Week 18, Day 1-3)
   - Create TaxDocument and TaxProfile models
   - Create TaxComplianceService with 1099 generation
   - W-9 collection and processing
   - SSN encryption
   - Integration with Payment service (earnings calculation)
   - Integration with Stripe (tax document generation)

2. Sales Tax Service (Week 18, Day 4-5)
   - Create SalesTaxService with tax calculation
   - Tax rate API integration
   - Sales tax return filing
   - Integration with Event and Payment services

3. Legal Document Service (Week 19, Day 1-3)
   - Create TermsOfService class
   - Create UserAgreement model
   - Create EventWaiver class
   - Create LegalDocumentService with agreement tracking
   - Integration with User and Event services

4. Legal Document Integration (Week 19, Day 4-5)
   - Terms of Service acceptance flow
   - Privacy Policy acceptance flow
   - Event waiver generation and acceptance
   - Agreement version management

**Deliverables:**
- All service files
- Test files for all services
- Service documentation
- Legal document content

**Dependencies:**
- Week 16-17 services complete
- Payment service integration required

**Quality Standards:**
- Test coverage > 90% for services
- All tests pass
- Tax compliance accurate
- Legal documents complete
- All edge cases covered
- Error handling tested

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 16-17 service files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 1, Week 18-19)
2. Reviewing Week 16-17 service patterns
3. Creating TaxComplianceService
4. Creating SalesTaxService
5. Creating LegalDocumentService
```

---

### **Week 20-21 Prompt:**

```
You are Agent 1 working on Phase 5, Weeks 20-21: Fraud Prevention & Security.

**Your Role:** Backend & Integration Specialist
**Focus:** Fraud Detection Service, Identity Verification Service

**Context:**
- Week 18-19 services complete
- Fraud prevention needed for platform security
- Identity verification needed for high earners

**Your Tasks:**
1. Fraud Detection Service (Week 20, Day 1-3)
   - Create FraudScore model with FraudSignal enum
   - Create FraudDetectionService with event fraud analysis
   - Check for new host with expensive event
   - Validate location, check for stock photos
   - Check for duplicate events, suspicious prices
   - Calculate risk score and generate recommendations
   - Integration with Event and User services

2. Review Fraud Detection (Week 20, Day 4)
   - Create ReviewFraudDetectionService
   - Detect fake reviews (all 5-star, same-day clustering, generic text)
   - Integration with Feedback service

3. Identity Verification Service (Week 21, Day 1-3)
   - Create VerificationSession and VerificationResult models
   - Create IdentityVerificationService with Stripe Identity integration
   - Determine verification requirements
   - Initiate and check verification status
   - Integration with User service

4. Security Enhancements (Week 21, Day 4-5)
   - Review security practices
   - Implement additional security measures
   - Security audit
   - Documentation

**Deliverables:**
- All service files
- Test files for all services
- Service documentation
- Security audit report

**Dependencies:**
- Week 18-19 services complete
- Event and User services required

**Quality Standards:**
- Test coverage > 90% for services
- All tests pass
- Fraud detection accurate
- Identity verification working
- All edge cases covered
- Error handling tested
- Security verified

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 18-19 service files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 1, Week 20-21)
2. Reviewing Week 18-19 service patterns
3. Creating FraudDetectionService
4. Creating IdentityVerificationService
5. Security audit
```

---

## 🤖 **Agent 2: Frontend & UX**

### **🚨 START WORK NOW - All Dependencies Ready**

**Status:** 🟢 **READY TO START - BEGIN WORK IMMEDIATELY**

**Critical Context:**
- ✅ **Agent 1 Phase 5 COMPLETE** - All backend services ready (Weeks 16-21)
- ✅ **Agent 3 Phase 5 COMPLETE** - All models and integration tests ready (Weeks 16-21)
- ✅ **All dependencies satisfied** - Services, models, and tests are production-ready
- ✅ **Phase 4 COMPLETE** - Integration testing done, UI foundation solid
- 🎯 **Your Turn:** Begin Phase 5 UI implementation (Weeks 16-21)

**You can start work immediately - no blockers.**

---

### **Week 16-17 Prompt:**

```
You are Agent 2 working on Phase 5, Weeks 16-17: Cancellation UI, Feedback UI, Success Dashboard UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Cancellation Flow UI, Safety Checklist UI, Dispute UI, Feedback UI, Success Dashboard UI

**Context:**
- ✅ Phase 4 (Integration Testing) is COMPLETE
- ✅ Agent 1 Phase 5 COMPLETE - All Week 16-17 services ready (PostEventFeedbackService, EventSafetyService, EventSuccessAnalysisService, CancellationService fixes)
- ✅ Agent 3 Phase 5 COMPLETE - All Week 16-17 models ready (Cancellation, RefundDistribution, EventSafetyGuidelines, Dispute, EventFeedback, PartnerRating, EventSuccessMetrics models + integration tests)
- ✅ All backend services available and tested
- ✅ All models available and tested
- 🎯 **START WORK NOW** - All dependencies satisfied, begin UI implementation

**Your Tasks:**
1. Cancellation Flow UI (Week 16, Day 1-3)
   - Create CancellationFlowPage with reason selection, refund preview, confirmation
   - Add cancellation options to Event Details and My Events pages
   - Test cancellation flows

2. Safety Checklist UI (Week 16, Day 4)
   - Create SafetyChecklistWidget with requirements checklist
   - Integrate into Event Creation flow and Event Details page

3. Dispute Submission UI (Week 16, Day 5)
   - Create DisputeSubmissionPage with type selection, description, evidence upload
   - Create dispute status page
   - Add dispute link to Event Details page

4. Event Feedback UI (Week 17, Day 1-3)
   - Create EventFeedbackPage with star ratings, category ratings, highlights
   - Create PartnerRatingPage with partner ratings
   - Add feedback request notifications and links

5. Success Dashboard UI (Week 17, Day 4-5)
   - Create EventSuccessDashboard with:
     - Success level badge
     - Key metrics display (attendance, revenue, rating)
     - NPS score display
     - Success factors display
     - Improvement areas display
     - Partner satisfaction scores
     - Comparison to similar events
     - Actionable recommendations
   - Add success dashboard link to Event Details page
   - Add success dashboard to Host Dashboard

**Deliverables:**
- All UI page files
- Widget files
- UI integration updates
- Widget tests
- UI documentation

**Dependencies:**
- ✅ **Agent 1 Week 16-17 COMPLETE** - All services ready (PostEventFeedbackService, EventSafetyService, EventSuccessAnalysisService, CancellationService)
- ✅ **Agent 3 Week 16-17 COMPLETE** - All models ready (Cancellation, RefundDistribution, EventSafetyGuidelines, Dispute, EventFeedback, PartnerRating, EventSuccessMetrics)
- ✅ **Existing UI patterns** - All previous UI pages for reference
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Responsive design verified
- Error/loading/empty states handled
- Navigation flows complete

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing UI pages for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 2, Week 16-17)
2. Reviewing existing UI patterns
3. Creating CancellationFlowPage
4. Creating EventFeedbackPage
5. Creating EventSuccessDashboard
```

---

### **Week 18-19 Prompt:**

```
You are Agent 2 working on Phase 5, Weeks 18-19: Tax UI, Legal Document UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Tax Compliance UI, Sales Tax UI, Legal Document UI

**Context:**
- ✅ Agent 1 Week 18-19 COMPLETE - All services ready (TaxComplianceService, SalesTaxService, LegalDocumentService, PrivacyPolicy, SSNEncryption)
- ✅ Agent 3 Week 18-19 COMPLETE - All models ready (TaxDocument, TaxProfile, UserAgreement, TermsOfService, EventWaiver + integration tests)
- ✅ Week 16-17 UI should be complete before starting (or work in parallel if dependencies allow)
- 🎯 **Dependencies ready** - Begin tax and legal UI implementation

**Your Tasks:**
1. Tax Compliance UI (Week 18, Day 1-3)
   - Create TaxProfilePage with W-9 form
   - Create TaxDocumentsPage with document list and download
   - Add tax links to Settings
   - Tax document notifications

2. Sales Tax UI (Week 18, Day 4-5)
   - Display sales tax on checkout
   - Sales tax breakdown in payment summary
   - Tax-exempt event indicators

3. Legal Document UI (Week 19, Day 1-3)
   - Create TermsOfServicePage
   - Create PrivacyPolicyPage
   - Create EventWaiverPage
   - Add legal links to Settings
   - Require acceptance flows

4. Legal Document Integration (Week 19, Day 4-5)
   - Terms acceptance in onboarding
   - Event waiver in checkout flow
   - Agreement version updates

**Deliverables:**
- All UI page files
- UI integration updates
- Widget tests
- UI documentation

**Dependencies:**
- ✅ **Agent 1 Week 18-19 COMPLETE** - All services ready (TaxComplianceService, SalesTaxService, LegalDocumentService)
- ✅ **Agent 3 Week 18-19 COMPLETE** - All models ready (TaxDocument, TaxProfile, UserAgreement, TermsOfService, EventWaiver)
- ✅ **Existing UI patterns** - All previous UI pages for reference
- ✅ **NO BLOCKERS** - Services and models ready

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Responsive design verified
- Legal acceptance flows complete
- Error/loading states handled

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 16-17 UI files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 2, Week 18-19)
2. Reviewing Week 16-17 UI patterns
3. Creating TaxProfilePage
4. Creating TermsOfServicePage
5. Creating EventWaiverPage
```

---

### **Week 20-21 Prompt:**

```
You are Agent 2 working on Phase 5, Weeks 20-21: Fraud Review UI, Identity Verification UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Fraud Review UI, Identity Verification UI, Security UI Updates

**Context:**
- ✅ Agent 1 Week 20-21 COMPLETE - All services ready (FraudDetectionService, ReviewFraudDetectionService, IdentityVerificationService + test files)
- ✅ Agent 3 Week 20-21 COMPLETE - All models ready (FraudScore, FraudSignal, FraudRecommendation, ReviewFraudScore, VerificationSession, VerificationResult, VerificationStatus + integration tests)
- ✅ Week 18-19 UI should be complete before starting (or work in parallel if dependencies allow)
- 🎯 **Dependencies ready** - Begin fraud review and verification UI implementation

**Your Tasks:**
1. Fraud Review UI (Week 20, Day 1-3)
   - Create FraudReviewPage (Admin) with fraud score, signals, recommendations
   - Create fraud indicators on Event Details (if flagged)
   - Add fraud review to Admin Dashboard

2. Review Fraud UI (Week 20, Day 4)
   - Create ReviewFraudReviewPage (Admin)
   - Add review fraud review to Admin Dashboard

3. Identity Verification UI (Week 21, Day 1-3)
   - Create IdentityVerificationPage with instructions, status, progress
   - Add verification requirement notifications
   - Add verification link to Settings

4. Security UI Updates (Week 21, Day 4-5)
   - Security settings page updates
   - Security indicators
   - Security notifications

**Deliverables:**
- All UI page files
- UI integration updates
- Widget tests
- UI documentation

**Dependencies:**
- ✅ **Agent 1 Week 20-21 COMPLETE** - All services ready (FraudDetectionService, ReviewFraudDetectionService, IdentityVerificationService)
- ✅ **Agent 3 Week 20-21 COMPLETE** - All models ready (FraudScore, FraudSignal, FraudRecommendation, ReviewFraudScore, VerificationSession, VerificationResult, VerificationStatus)
- ✅ **Existing UI patterns** - All previous UI pages for reference
- ✅ **NO BLOCKERS** - Services and models ready

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Responsive design verified
- Admin flows complete
- Error/loading states handled

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 18-19 UI files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 2, Week 20-21)
2. Reviewing Week 18-19 UI patterns
3. Creating FraudReviewPage
4. Creating IdentityVerificationPage
5. Security UI updates
```

---

## 🤖 **Agent 3: Models & Testing**

### **Week 16-17 Prompt:**

```
You are Agent 3 working on Phase 5, Weeks 16-17: Refund Models, Feedback Models, Compliance Tests.

**Your Role:** Models & Testing Specialist
**Focus:** Refund Models, Safety Models, Dispute Models, Feedback Models, Success Metrics Models, Integration Tests

**Context:**
- Phase 4 (Integration Testing) is complete
- All models follow existing patterns
- Need refund, feedback, and success metrics models

**Your Tasks:**
1. Refund & Cancellation Models (Week 16, Day 1-2)
   - Create Cancellation model with all required fields
   - Create RefundDistribution model
   - Create RefundPolicy utility class
   - Create model tests
   - Verify integration with Payment and Event models

2. Safety & Dispute Models (Week 16, Day 3-4)
   - Create EventSafetyGuidelines model
   - Create EmergencyInformation model
   - Create InsuranceRecommendation model
   - Create Dispute and DisputeMessage models
   - Create model tests
   - Verify integration with Event models

3. Feedback Models (Week 17, Day 1-2)
   - Create EventFeedback model
   - Create PartnerRating model
   - Create model tests
   - Verify integration with Event and Partnership models

4. Success Metrics Models (Week 17, Day 3)
   - Create EventSuccessMetrics model
   - Create EventSuccessLevel enum
   - Create model tests
   - Verify integration with Event and Feedback models

5. Integration Tests (Week 17, Day 4-5)
   - Cancellation flow integration tests
   - Feedback flow integration tests
   - Success analysis integration tests
   - Dispute resolution integration tests

**Deliverables:**
- All model files
- Model test files
- Integration test files
- Model documentation

**Dependencies:**
- Agent 1 services ready (Week 16-17)
- Existing model patterns

**Quality Standards:**
- All models follow existing patterns (Equatable, toJson, fromJson, copyWith)
- Zero linter errors
- All model tests pass
- All integration tests pass
- Model relationships verified
- Test coverage > 90% for models

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing model files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 3, Week 16-17)
2. Reviewing existing model patterns
3. Creating Cancellation model
4. Creating EventFeedback model
5. Creating integration tests
```

---

### **Week 18-19 Prompt:**

```
You are Agent 3 working on Phase 5, Weeks 18-19: Tax Models, Legal Models, Compliance Tests.

**Your Role:** Models & Testing Specialist
**Focus:** Tax Models, Legal Models, Compliance Integration Tests

**Context:**
- Week 16-17 models complete
- Tax and legal models needed

**Your Tasks:**
1. Tax Models (Week 18, Day 1-2)
   - Create TaxDocument model
   - Create TaxProfile model
   - Create TaxFormType, TaxStatus, TaxClassification enums
   - Create model tests
   - Verify integration with User and Payment models

2. Legal Models (Week 19, Day 1-2)
   - Create UserAgreement model
   - Review TermsOfService and EventWaiver classes
   - Create model tests
   - Verify integration with User and Event models

3. Integration Tests (Week 18-19, Day 3-5)
   - Tax compliance flow integration tests
   - Sales tax flow integration tests
   - Legal document flow integration tests
   - Compliance verification tests

**Deliverables:**
- All model files
- Model test files
- Integration test files
- Model documentation

**Dependencies:**
- Agent 1 services ready (Week 18-19)
- Existing model patterns

**Quality Standards:**
- All models follow existing patterns
- Zero linter errors
- All model tests pass
- All integration tests pass
- Compliance verified
- Test coverage > 90% for models

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 16-17 model files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 3, Week 18-19)
2. Reviewing Week 16-17 model patterns
3. Creating TaxDocument model
4. Creating UserAgreement model
5. Creating integration tests
```

---

### **Week 20-21 Prompt:**

```
You are Agent 3 working on Phase 5, Weeks 20-21: Fraud Models, Verification Models, Security Tests.

**Your Role:** Models & Testing Specialist
**Focus:** Fraud Models, Verification Models, Security Integration Tests

**Context:**
- Week 18-19 models complete
- Fraud and verification models needed

**Your Tasks:**
1. Fraud Models (Week 20, Day 1-2)
   - Create FraudScore model
   - Create FraudSignal enum
   - Create FraudRecommendation enum
   - Create ReviewFraudScore model
   - Create model tests
   - Verify integration with Event and Feedback models

2. Verification Models (Week 21, Day 1-2)
   - Create VerificationSession model
   - Create VerificationResult model
   - Create VerificationStatus enum
   - Create model tests
   - Verify integration with User models

3. Integration Tests (Week 20-21, Day 3-5)
   - Fraud detection flow integration tests
   - Review fraud detection integration tests
   - Identity verification flow integration tests
   - Security verification tests

**Deliverables:**
- All model files
- Model test files
- Integration test files
- Model documentation

**Dependencies:**
- Agent 1 services ready (Week 20-21)
- Existing model patterns

**Quality Standards:**
- All models follow existing patterns
- Zero linter errors
- All model tests pass
- All integration tests pass
- Security verified
- Test coverage > 90% for models

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_5/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 18-19 model files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_5/task_assignments.md` (Agent 3, Week 20-21)
2. Reviewing Week 18-19 model patterns
3. Creating FraudScore model
4. Creating VerificationSession model
5. Creating integration tests
```

---

## 📚 **Key References**

- **Master Plan:** `docs/MASTER_PLAN.md` - Phase 5 requirements
- **Operations Compliance Plan:** `docs/plans/operations_compliance/OPERATIONS_COMPLIANCE_PLAN.md` - Detailed plan
- **Status Tracker:** `docs/agents/status/status_tracker.md` - Current status
- **Quick Reference:** `docs/agents/reference/quick_reference.md` - Code patterns
- **Task Assignments:** `docs/agents/tasks/phase_5/task_assignments.md` - Detailed tasks

---

**Last Updated:** November 23, 2025, 4:00 PM CST  
**Status:** 🟢 **AGENT 2 - START WORK NOW**

**Agent 2 Status:**
- 🟢 **READY TO START** - All dependencies complete (Agent 1 & Agent 3 Phase 5 COMPLETE)
- 🟢 **NO BLOCKERS** - All services and models ready for UI integration
- 🎯 **BEGIN IMMEDIATELY** - Week 16-17 UI work can start now

