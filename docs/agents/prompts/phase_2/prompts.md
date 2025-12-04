# Phase 2 Agent Prompts - Post-MVP Enhancements

**Date:** November 23, 2025, 2:09 AM CST  
**Purpose:** Ready-to-use prompts for Phase 2 agents  
**Status:** 🎯 **READY FOR PHASE 2**

---

## 🎯 **Phase 2 Overview**

**Duration:** Weeks 5-8 (4 weeks)  
**Focus:** Event Partnerships + Dynamic Expertise System  
**Agents:** 3 parallel agents working on different aspects

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 5 Prompt:**

```
You are Agent 1 working on Phase 2, Week 5: Event Partnership Foundation (Models Integration).

**Your Role:** Backend & Integration Specialist
**Focus:** Model Integration & Service Preparation

**Context:**
- Phase 1 (MVP Core) is complete
- All code compiles with 0 errors
- Payment processing works
- Event system works
- Expertise system works (basic)

**Your Tasks:**
1. Review existing Event models (`lib/core/models/`)
2. Review existing Payment models (from Phase 1)
3. Design Partnership model integration points
4. Prepare service layer architecture for partnerships
5. Document integration requirements

**Deliverables:**
- Integration design document
- Service layer architecture plan
- Integration requirements document

**Dependencies:**
- Wait for Agent 3 to complete Partnership models (Week 5)
- Review Agent 3's models before designing integration

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Zero linter errors
- Follow existing code patterns
- Document all decisions

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_2/task_assignments.md` - Your detailed tasks
- `docs/plans/monetization_business_expertise/MONETIZATION_BUSINESS_EXPERTISE_MASTER_PLAN.md` - Requirements
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking

**Start by:**
1. Reading `docs/agents/tasks/phase_2/task_assignments.md` (Agent 1, Week 5)
2. Reviewing existing Event models
3. Waiting for Agent 3's models (check status tracker)
4. Designing integration architecture
```

---

### **Week 6 Prompt:**

```
You are Agent 1 working on Phase 2, Week 6: Event Partnership Service + Business Service.

**Your Role:** Backend & Integration Specialist
**Focus:** Partnership Service, Business Service

**Context:**
- Agent 3 completed Partnership models (Week 5)
- You reviewed the models and designed integration
- Service layer architecture is ready

**Your Tasks:**
1. Create `PartnershipService`
   - Create partnership
   - Find partnerships for event
   - Update partnership status
   - Check partnership eligibility
   - Vibe matching (70%+ compatibility)
2. Create `BusinessService`
   - Create business account
   - Verify business
   - Update business info
   - Find businesses
   - Check business eligibility
3. Create `PartnershipMatchingService`
   - Vibe-based matching algorithm
   - Compatibility scoring
   - Partnership suggestions
4. Integrate with existing Event service
5. Create service tests

**Deliverables:**
- `lib/core/services/partnership_service.dart`
- `lib/core/services/business_service.dart`
- `lib/core/services/partnership_matching_service.dart`
- Service integration code
- Service tests

**Dependencies:**
- Agent 3's Partnership models (Week 5) - ✅ Complete
- Review Agent 3's models before starting

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing service patterns
- Vibe matching must use 70%+ threshold
- All services must have tests

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark services complete when done
- Communicate completion via status tracker

**Key Files:**
- `docs/agents/tasks/phase_2/task_assignments.md` - Your detailed tasks
- `docs/plans/monetization_business_expertise/MONETIZATION_BUSINESS_EXPERTISE_MASTER_PLAN.md` - Requirements
- `docs/plans/monetization_business_expertise/FORMULAS_AND_ALGORITHMS.md` - Vibe matching formula
- `lib/core/services/` - Existing service patterns
```

---

### **Week 7 Prompt:**

```
You are Agent 1 working on Phase 2, Week 7: Multi-party Payment Processing + Revenue Split Service.

**Your Role:** Backend & Integration Specialist
**Focus:** Multi-party Payment Processing, Revenue Split Service

**Context:**
- Partnership services complete (Week 6)
- Payment service exists (Phase 1)
- Need to extend for multi-party payments

**Your Tasks:**
1. Extend `PaymentService` for multi-party payments
   - N-way payment processing
   - Multi-party revenue splits
   - Stripe Connect integration
   - Payout scheduling
2. Create `RevenueSplitService`
   - Calculate N-way splits
   - Lock splits (pre-event)
   - Distribute payments
   - Track earnings
3. Create `PayoutService`
   - Schedule payouts
   - Track earnings
   - Generate payout reports
4. Integrate with existing Payment service
5. Create service tests

**Deliverables:**
- Extended `PaymentService` (multi-party)
- `lib/core/services/revenue_split_service.dart`
- `lib/core/services/payout_service.dart`
- Service integration code
- Service tests

**Dependencies:**
- Existing Payment service (Phase 1) - ✅ Complete
- Partnership models (Week 5) - ✅ Complete

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing payment patterns
- N-way splits must work correctly
- Pre-event locking must work
- All services must have tests

**Key Requirements:**
- 10% SPOTS fee on all payments
- ~3% Stripe processing fee
- Remaining split among partners
- Splits locked before event starts

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark services complete when done
```

---

### **Week 8 Prompt:**

```
You are Agent 1 working on Phase 2, Week 8: Final Integration & Testing.

**Your Role:** Backend & Integration Specialist
**Focus:** Final Integration & Testing

**Context:**
- All services complete (Weeks 5-7)
- Agent 2 working on UI
- Agent 3 working on expertise UI

**Your Tasks:**
1. Integration testing
   - Partnership flow tests
   - Payment flow tests
   - Business flow tests
2. End-to-end testing
   - Full partnership workflow
   - Full payment workflow
3. Performance testing
   - Service performance
   - Database queries
4. Bug fixes
5. Documentation

**Deliverables:**
- Integration tests
- End-to-end tests
- Performance test results
- Bug fix documentation
- Integration documentation

**Quality Standards:**
- All tests pass
- Performance meets requirements
- Zero bugs
- Documentation complete

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with completion
- Mark Phase 2 complete when done
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Week 5 Prompt:**

```
You are Agent 2 working on Phase 2, Week 5: UI Design & Preparation.

**Your Role:** Frontend & UX Specialist
**Focus:** UI Design & Preparation

**Context:**
- Phase 1 UI complete (Event discovery, hosting, payment)
- All UI follows design tokens
- Need to design Partnership and Business UIs

**Your Tasks:**
1. Design Partnership UI mockups
   - Partnership proposal UI
   - Partnership acceptance UI
   - Partnership management UI
2. Design Business UI mockups
   - Business account setup UI
   - Business verification UI
   - Business dashboard UI
3. Review existing event creation UI
4. Plan UI integration with event creation

**Deliverables:**
- UI mockup designs
- UI component specifications
- UI integration plan

**Dependencies:**
- Review Agent 3's models (Week 5) for UI design
- Review existing UI patterns

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Follow existing UI patterns
- Modern, beautiful UI
- Accessible design

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Share mockups with team
```

---

### **Week 6 Prompt:**

```
You are Agent 2 working on Phase 2, Week 6: UI Preparation & Design (Continued).

**Your Role:** Frontend & UX Specialist
**Focus:** UI Preparation & Design

**Context:**
- UI mockups complete (Week 5)
- Agent 3's models reviewed
- Ready to prepare UI components

**Your Tasks:**
1. Review Partnership models (from Agent 3, Week 5)
2. Finalize Partnership UI designs
3. Finalize Business UI designs
4. Create UI component specifications
5. Plan UI integration with event creation

**Deliverables:**
- Finalized UI designs
- UI component specifications
- UI integration plan

**Dependencies:**
- Agent 3's Partnership models (Week 5) - ✅ Complete
- Review models before finalizing designs

**Quality Standards:**
- 100% design token adherence
- Follow existing UI patterns
- Modern, beautiful UI

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
```

---

### **Week 7 Prompt:**

```
You are Agent 2 working on Phase 2, Week 7: Payment UI, Revenue Display UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Payment UI, Revenue Display UI

**Context:**
- UI designs complete (Weeks 5-6)
- Agent 1 working on payment services
- Need to create payment UI components

**Your Tasks:**
1. Create Partnership payment UI
   - Multi-party checkout
   - Revenue split display
   - Payment confirmation
2. Create Earnings dashboard UI
   - Earnings overview
   - Payout schedule
   - Revenue breakdown
3. Integrate with existing payment UI
4. Create UI tests

**Deliverables:**
- Partnership payment UI components
- Earnings dashboard UI
- UI integration code
- UI tests

**Dependencies:**
- Agent 1's payment services (Week 7) - In progress
- Review service APIs before implementing UI

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Zero linter errors
- Follow existing payment UI patterns
- All UI has tests

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check Agent 1's status for service APIs
```

---

### **Week 8 Prompt:**

```
You are Agent 2 working on Phase 2, Week 8: Partnership UI, Business UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Partnership UI, Business UI

**Context:**
- UI designs complete (Weeks 5-6)
- Payment UI complete (Week 7)
- Services complete (Week 7)
- Ready to implement full UI

**Your Tasks:**
1. Create Partnership proposal UI
   - Proposal form
   - Partnership terms
   - Revenue split configuration
   - Send proposal
2. Create Partnership acceptance UI
   - View proposal
   - Accept/decline
   - Agreement confirmation
3. Create Partnership management UI
   - View partnerships
   - Manage partnerships
   - Update agreements
4. Create Business account setup UI
   - Business registration
   - Business info form
   - Stripe Connect setup
5. Create Business verification UI
   - Upload documents
   - Verification status
   - Verification history
6. Integrate with event creation
7. Create UI tests

**Deliverables:**
- `lib/presentation/pages/partnerships/partnership_proposal_page.dart`
- `lib/presentation/pages/partnerships/partnership_acceptance_page.dart`
- `lib/presentation/pages/partnerships/partnership_management_page.dart`
- `lib/presentation/pages/business/business_setup_page.dart`
- `lib/presentation/pages/business/business_verification_page.dart`
- UI integration code
- UI tests

**Dependencies:**
- Agent 1's services (Weeks 6-7) - ✅ Complete
- Review service APIs before implementing

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Zero linter errors
- Follow existing UI patterns
- All UI has tests
- Beautiful, modern UI

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with completion
- Mark Phase 2 complete when done
```

---

## 🧪 **Agent 3: Models & Testing**

### **Week 5 Prompt:**

```
You are Agent 3 working on Phase 2, Week 5: Partnership Models, Business Models.

**Your Role:** Models & Testing Specialist
**Focus:** Partnership Models, Business Models

**Context:**
- Phase 1 complete
- Existing Event models in place
- Need to create Partnership and Business models

**Your Tasks:**
1. Create `EventPartnership` model
   - Partnership ID
   - Event reference
   - Partners (user + business)
   - Partnership status
   - Agreement terms
   - Created/updated timestamps
2. Create `RevenueSplit` model
   - Split ID
   - Partnership reference
   - Split parties (N-way)
   - Percentage per party
   - Amount per party
   - Locked status (pre-event)
   - Created/updated timestamps
3. Create `PartnershipEvent` model
   - Extends existing Event model
   - Partnership reference
   - Revenue split reference
   - Partnership-specific fields
4. Create `BusinessAccount` model
   - Business ID
   - Business name
   - Business type
   - Location
   - Verification status
   - Verification documents
   - Stripe Connect account ID
   - Created/updated timestamps
5. Create `BusinessVerification` model
   - Verification ID
   - Business reference
   - Verification type
   - Documents
   - Status (pending/approved/rejected)
   - Reviewed by
   - Reviewed at
6. Integrate with existing Event models
7. Create model tests

**Deliverables:**
- `lib/core/models/event_partnership.dart`
- `lib/core/models/revenue_split.dart`
- `lib/core/models/partnership_event.dart`
- `lib/core/models/business_account.dart`
- `lib/core/models/business_verification.dart`
- Model integration code
- Model tests

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing model patterns
- All models have tests
- Models support N-way revenue splits
- Models support pre-event agreement locking

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark models complete when done
- Communicate completion so Agent 1 can start services

**Key Files:**
- `docs/agents/tasks/phase_2/task_assignments.md` - Your detailed tasks
- `docs/plans/monetization_business_expertise/MONETIZATION_BUSINESS_EXPERTISE_MASTER_PLAN.md` - Requirements
- `lib/core/models/` - Existing model patterns
```

---

### **Week 6 Prompt:**

```
You are Agent 3 working on Phase 2, Week 6: Dynamic Expertise Models.

**Your Role:** Models & Testing Specialist
**Focus:** Dynamic Expertise Models

**Context:**
- Partnership models complete (Week 5)
- Existing expertise system in place (basic)
- Need to create dynamic expertise models

**Your Tasks:**
1. Create `ExpertiseRequirements` model
   - Category
   - Platform phase
   - Threshold values
   - Saturation metrics
   - Multi-path requirements
2. Create `PlatformPhase` model
   - Phase ID
   - Phase name
   - User count threshold
   - Category multipliers
   - Saturation factors
3. Create `SaturationMetrics` model
   - Category
   - Current expert count
   - Total user count
   - Saturation ratio
   - Quality score
   - Growth rate
   - Competition level
   - Market demand
4. Create `Visit` model
   - Visit ID
   - User reference
   - Location reference
   - Check-in time
   - Check-out time
   - Dwell time
   - Quality score
   - Automatic check-in flag
   - Geofencing data
   - Bluetooth data
5. Create `AutomaticCheckIn` model
   - Check-in ID
   - Visit reference
   - Geofence trigger
   - Bluetooth trigger
   - Dwell time
   - Quality score
6. Create multi-path expertise models
   - `ExplorationExpertise` (visits)
   - `CredentialExpertise` (degrees, certifications)
   - `InfluenceExpertise` (followers, shares)
   - `ProfessionalExpertise` (proof of work)
   - `CommunityExpertise` (community contributions)
   - `LocalExpertise` (locality-based)
7. Create model tests

**Deliverables:**
- `lib/core/models/expertise_requirements.dart`
- `lib/core/models/platform_phase.dart`
- `lib/core/models/saturation_metrics.dart`
- `lib/core/models/visit.dart`
- `lib/core/models/automatic_check_in.dart`
- Multi-path expertise models
- Model tests

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing model patterns
- All models have tests
- Models support dynamic thresholds
- Models support multi-path expertise
- Models support automatic check-ins

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark models complete when done
```

---

### **Week 7 Prompt:**

```
You are Agent 3 working on Phase 2, Week 7: Dynamic Expertise Service.

**Your Role:** Models & Testing Specialist
**Focus:** Dynamic Expertise Service

**Context:**
- Expertise models complete (Week 6)
- Existing expertise service in place (basic)
- Need to create dynamic expertise services

**Your Tasks:**
1. Create `ExpertiseCalculationService`
   - Multi-path scoring
   - Dynamic threshold calculation
   - Expertise level calculation
   - Category expertise calculation
2. Create `SaturationAlgorithmService`
   - 6-factor saturation analysis
   - Saturation score calculation
   - Threshold adjustment
   - Quality control
3. Create `AutomaticCheckInService`
   - Geofencing detection
   - Bluetooth ai2ai detection
   - Dwell time calculation
   - Quality scoring
   - Visit recording
4. Create `MultiPathExpertiseService`
   - Exploration path calculation
   - Credential path calculation
   - Influence path calculation
   - Professional path calculation
   - Community path calculation
   - Local path calculation
5. Integrate with existing Expertise service
6. Create service tests

**Deliverables:**
- `lib/core/services/expertise_calculation_service.dart`
- `lib/core/services/saturation_algorithm_service.dart`
- `lib/core/services/automatic_check_in_service.dart`
- `lib/core/services/multi_path_expertise_service.dart`
- Service integration code
- Service tests

**Dependencies:**
- Expertise models (Week 6) - ✅ Complete
- Review models before creating services

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing service patterns
- All services have tests
- Dynamic thresholds must work
- Multi-path expertise must work
- Saturation algorithm must work (6-factor)
- Automatic check-ins must work

**Key Requirements:**
- Dynamic thresholds scale with platform growth
- Multi-path expertise supports all paths
- Saturation algorithm uses 6 factors
- Automatic check-ins use geofencing + Bluetooth

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark services complete when done
```

---

### **Week 8 Prompt:**

```
You are Agent 3 working on Phase 2, Week 8: Expertise UI, Integration Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Expertise UI, Integration Testing

**Context:**
- All models complete (Weeks 5-6)
- All services complete (Week 7)
- Agent 2 working on partnership UI
- Need to create expertise UI and comprehensive tests

**Your Tasks:**
1. Create Expertise progress UI
   - Progress bars
   - Requirements display
   - Multi-path indicators
   - Threshold information
2. Create Expertise dashboard UI (enhance existing)
   - Multi-path breakdown
   - Saturation information
   - Expertise levels
   - Category expertise
3. Create Automatic check-in UI
   - Check-in status
   - Visit history
   - Quality indicators
   - Dwell time display
4. Create comprehensive integration tests
   - Partnership flow tests
   - Expertise flow tests
   - Payment flow tests
   - End-to-end tests
5. Update test infrastructure
6. Create test documentation

**Deliverables:**
- `lib/presentation/pages/expertise/expertise_progress_page.dart`
- `lib/presentation/pages/expertise/expertise_dashboard_page.dart` (enhanced)
- `lib/presentation/pages/expertise/check_in_status_page.dart`
- Integration test files
- Test infrastructure updates
- Test documentation

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Zero linter errors
- All integration tests pass
- All UI has tests
- Test infrastructure complete

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with completion
- Mark Phase 2 complete when done
```

---

## 📋 **Common Instructions for All Agents**

### **Before Starting:**
1. Read `docs/agents/tasks/phase_2/task_assignments.md` (your specific tasks)
2. Read `docs/plans/monetization_business_expertise/MONETIZATION_BUSINESS_EXPERTISE_MASTER_PLAN.md` (requirements)
3. Read `docs/agents/reference/quick_reference.md` (code patterns)
4. Check `docs/agents/status/status_tracker.md` (dependencies)

### **During Work:**
1. Update `docs/agents/status/status_tracker.md` with progress
2. Check dependencies before starting tasks
3. Follow design tokens (AppColors/AppTheme)
4. Write tests for all code
5. Document all decisions

### **Quality Standards:**
- ✅ Zero linter errors
- ✅ 100% design token adherence
- ✅ All code has tests
- ✅ Documentation complete
- ✅ Follow existing patterns

### **Status Tracking:**
- Update `docs/agents/status/status_tracker.md` regularly
- Mark tasks complete when done
- Communicate dependencies via status tracker

---

**Last Updated:** November 23, 2025, 2:09 AM CST  
**Status:** 🎯 **READY FOR PHASE 2**

