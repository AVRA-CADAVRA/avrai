# Phase 3 Agent Prompts - Advanced Features (Brand Sponsorship)

**Date:** November 23, 2025, 11:40 AM CST  
**Purpose:** Ready-to-use prompts for Phase 3 agents  
**Status:** 🎯 **READY FOR PHASE 3**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 3 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/agents/guides/PHASE_3_PREPARATION.md` - Setup guide
3. ✅ **Read:** `docs/agents/START_HERE_PHASE_3.md` - Quick checklist

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_3/prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_3/task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_3/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_3_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_3.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🎯 **Phase 3 Overview**

**Duration:** Weeks 9-12 (4 weeks)  
**Focus:** Brand Sponsorship System  
**Agents:** 3 parallel agents working on different aspects

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 9 Prompt:**

```
You are Agent 1 working on Phase 3, Week 9: Brand Sponsorship Foundation (Service Architecture).

**Your Role:** Backend & Integration Specialist
**Focus:** Service Architecture & Integration Design

**Context:**
- Phase 2 (Event Partnerships) is complete
- All code compiles with 0 errors
- Partnership services work
- Payment services work
- Need to extend for Brand Sponsorships

**Your Tasks:**
1. Review existing Partnership models and services (from Phase 2)
2. Review existing Payment models and services
3. Design Brand Sponsorship service architecture
4. Design integration with Partnership system
5. Document integration requirements

**Deliverables:**
- Integration design document
- Service architecture plan
- Integration requirements document

**Dependencies:**
- Wait for Agent 3 to complete Brand models (Week 9)
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
- `docs/agents/tasks/phase_3/task_assignments.md` - Your detailed tasks
- `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md` - Requirements
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking

**Start by:**
1. Reading `docs/agents/tasks/phase_3/task_assignments.md` (Agent 1, Week 9)
2. Reviewing existing Partnership services
3. Waiting for Agent 3's models (check status tracker)
4. Designing integration architecture
```

---

### **Week 10 Prompt:**

```
You are Agent 1 working on Phase 3, Week 10: Brand Sponsorship Services.

**Your Role:** Backend & Integration Specialist
**Focus:** Brand Sponsorship Services

**Context:**
- Agent 3 completed Brand models (Week 9)
- You reviewed the models and designed integration
- Service layer architecture is ready

**Your Tasks:**
1. Create `SponsorshipService`
   - Create sponsorship
   - Find sponsorships for event
   - Update sponsorship status
   - Check sponsorship eligibility
   - Vibe matching (70%+ compatibility)
2. Create `BrandDiscoveryService`
   - Brand search functionality
   - Event search for brands
   - Vibe-based matching algorithm
   - Compatibility scoring
   - Sponsorship suggestions
3. Create `ProductTrackingService`
   - Track product contributions
   - Track product sales
   - Calculate revenue attribution
   - Generate sales reports
4. Integrate with existing Partnership service
5. Create service tests

**Deliverables:**
- `lib/core/services/sponsorship_service.dart`
- `lib/core/services/brand_discovery_service.dart`
- `lib/core/services/product_tracking_service.dart`
- Service integration code
- Service tests

**Dependencies:**
- Agent 3's Brand models (Week 9) - ✅ Complete
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
- `docs/agents/tasks/phase_3/task_assignments.md` - Your detailed tasks
- `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md` - Requirements
- `lib/core/services/` - Existing service patterns
```

---

### **Week 11 Prompt:**

```
You are Agent 1 working on Phase 3, Week 11: Payment & Revenue Services.

**Your Role:** Backend & Integration Specialist
**Focus:** Payment & Revenue Services

**Context:**
- Brand Sponsorship services complete (Week 10)
- Revenue split service exists (Phase 2)
- Need to extend for N-way brand sponsorships

**Your Tasks:**
1. Extend `RevenueSplitService` for N-way brand sponsorships
   - Multi-party revenue splits (3+ partners)
   - Product sales revenue attribution
   - Hybrid sponsorship splits (cash + product)
2. Create `ProductSalesService`
   - Track product sales at events
   - Calculate product revenue
   - Attribute revenue to sponsors
   - Generate sales reports
3. Create `BrandAnalyticsService`
   - ROI tracking for brands
   - Performance metrics
   - Brand exposure analytics
   - Event performance tracking
4. Integrate with existing Payment service
5. Create service tests

**Deliverables:**
- Extended `RevenueSplitService` (N-way brand sponsorships)
- `lib/core/services/product_sales_service.dart`
- `lib/core/services/brand_analytics_service.dart`
- Service integration code
- Service tests

**Dependencies:**
- Existing RevenueSplitService (Phase 2) - ✅ Complete
- Brand models (Week 9) - ✅ Complete

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing payment patterns
- N-way splits must work correctly
- Product tracking must work
- All services must have tests

**Key Requirements:**
- 10% SPOTS fee on all sponsorships
- ~3% Stripe processing fee
- Remaining split among partners
- Product sales tracked and attributed

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark services complete when done
```

---

### **Week 12 Prompt:**

```
You are Agent 1 working on Phase 3, Week 12: Final Integration & Testing.

**Your Role:** Backend & Integration Specialist
**Focus:** Final Integration & Testing

**Context:**
- All services complete (Weeks 9-11)
- Agent 2 working on UI
- Agent 3 working on integration tests

**Your Tasks:**
1. Integration testing
   - Brand discovery flow tests
   - Sponsorship creation flow tests
   - Payment flow tests
   - Product tracking flow tests
2. End-to-end testing
   - Full brand sponsorship workflow
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
- Mark Phase 3 complete when done
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Week 9 Prompt:**

```
You are Agent 2 working on Phase 3, Week 9: UI Design & Preparation.

**Your Role:** Frontend & UX Specialist
**Focus:** UI Design & Preparation

**Context:**
- Phase 2 UI complete (Partnership UI, Business UI)
- All UI follows design tokens
- Need to design Brand Discovery and Sponsorship UIs

**Your Tasks:**
1. Design Brand Discovery UI mockups
   - Brand search interface
   - Event search for brands
   - Filter and matching
   - Compatibility display
2. Design Sponsorship Management UI mockups
   - View sponsorships
   - Create sponsorship proposals
   - Manage sponsorship agreements
   - Track sponsorship status
3. Design Brand Dashboard UI mockups
   - Brand account overview
   - Active sponsorships
   - Analytics dashboard
   - ROI tracking
4. Review existing partnership UI patterns
5. Plan UI integration with partnership system

**Deliverables:**
- UI mockup designs
- UI component specifications
- UI integration plan

**Dependencies:**
- Review Agent 3's models (Week 9) for UI design
- Review existing UI patterns

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Follow existing UI patterns
- Modern, beautiful UI
- Accessible design

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Share mockups with team

**Key Files to Review:**
- `docs/agents/tasks/phase_3/task_assignments.md` - Your detailed tasks
- `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md` - Requirements
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- `lib/presentation/` - Existing UI patterns
- `lib/core/theme/` - Design tokens (AppColors/AppTheme)

**Start by:**
1. Reading `docs/agents/tasks/phase_3/task_assignments.md` (Agent 2, Week 9)
2. Reviewing existing Partnership UI patterns in `lib/presentation/`
3. Reviewing design tokens in `lib/core/theme/`
4. Checking Agent 3's status for Brand models (check status tracker)
5. Reviewing Agent 3's models once available
6. Designing UI mockups based on models and requirements
```

---

### **Week 10 Prompt:**

```
You are Agent 2 working on Phase 3, Week 10: UI Preparation & Design (Continued).

**Your Role:** Frontend & UX Specialist
**Focus:** UI Preparation & Design

**Context:**
- UI mockups complete (Week 9)
- Agent 3's models reviewed
- Ready to prepare UI components

**Your Tasks:**
1. Review Brand models (from Agent 3, Week 9)
2. Finalize Brand Discovery UI designs
3. Finalize Sponsorship Management UI designs
4. Finalize Brand Dashboard UI designs
5. Create UI component specifications
6. Plan UI integration with partnership system

**Deliverables:**
- Finalized UI designs
- UI component specifications
- UI integration plan

**Dependencies:**
- Agent 3's Brand models (Week 9) - ✅ Complete
- Review models before finalizing designs

**Quality Standards:**
- 100% design token adherence
- Follow existing UI patterns
- Modern, beautiful UI

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
```

---

### **Week 11 Prompt:**

```
You are Agent 2 working on Phase 3, Week 11: Payment UI, Analytics UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Payment UI, Analytics UI

**Context:**
- UI designs complete (Weeks 9-10)
- Agent 1 working on payment/analytics services
- Need to create payment and analytics UI components

**Your Tasks:**
1. Create Brand sponsorship payment UI
   - Multi-party checkout
   - Product contribution tracking
   - Revenue split display
   - Payment confirmation
2. Create Brand analytics dashboard UI
   - ROI overview
   - Performance metrics
   - Brand exposure analytics
   - Event performance tracking
3. Integrate with existing payment UI
4. Create UI tests

**Deliverables:**
- Brand sponsorship payment UI components
- Brand analytics dashboard UI
- UI integration code
- UI tests

**Dependencies:**
- Agent 1's payment/analytics services (Week 11) - In progress
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

### **Week 12 Prompt:**

```
You are Agent 2 working on Phase 3, Week 12: Brand Discovery UI, Sponsorship Management UI, Brand Dashboard.

**Your Role:** Frontend & UX Specialist
**Focus:** Brand Discovery UI, Sponsorship Management UI, Brand Dashboard

**Context:**
- UI designs complete (Weeks 9-10)
- Payment/Analytics UI complete (Week 11)
- Services complete (Week 11)
- Ready to implement full UI

**Your Tasks:**
1. Create Brand Discovery UI
   - Brand search interface
   - Event search for brands
   - Filter and matching
   - Compatibility display
2. Create Sponsorship Management UI
   - View sponsorships
   - Create sponsorship proposals
   - Manage sponsorship agreements
   - Track sponsorship status
3. Create Brand Dashboard UI
   - Brand account overview
   - Active sponsorships
   - Analytics dashboard
   - ROI tracking
4. Integrate with partnership system
5. Create UI tests

**Deliverables:**
- `lib/presentation/pages/brand/brand_discovery_page.dart`
- `lib/presentation/pages/brand/sponsorship_management_page.dart`
- `lib/presentation/pages/brand/brand_dashboard_page.dart`
- UI integration code
- UI tests

**Dependencies:**
- Agent 1's services (Weeks 10-11) - ✅ Complete
- Review service APIs before implementing

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Zero linter errors
- Follow existing UI patterns
- All UI has tests
- Beautiful, modern UI

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with completion
- Mark Phase 3 complete when done
```

---

## 🧪 **Agent 3: Models & Testing**

### **Week 9 Prompt:**

```
You are Agent 3 working on Phase 3, Week 9: Brand Sponsorship Models.

**Your Role:** Models & Testing Specialist
**Focus:** Brand Sponsorship Models

**Context:**
- Phase 2 complete
- Existing Partnership models in place
- Need to create Brand Sponsorship models

**Your Tasks:**
1. Create `Sponsorship` model
   - Sponsorship ID
   - Event reference
   - Brand reference
   - Sponsorship type (financial, product, hybrid)
   - Contribution amount/value
   - Status
   - Agreement terms
   - Created/updated timestamps
2. Create `BrandAccount` model
   - Brand ID
   - Brand name
   - Brand type/category
   - Contact information
   - Verification status
   - Stripe Connect account ID
   - Created/updated timestamps
3. Create `ProductTracking` model
   - Product ID
   - Sponsorship reference
   - Product name
   - Quantity provided
   - Quantity sold
   - Unit price
   - Total sales
   - Revenue attribution
   - Created/updated timestamps
4. Create `MultiPartySponsorship` model
   - Sponsorship ID
   - Event reference
   - Multiple brand references (N-way)
   - Revenue split configuration
   - Agreement status
   - Created/updated timestamps
5. Create `BrandDiscovery` model
   - Search criteria
   - Matching results
   - Compatibility scores
   - Vibe matching (70%+ threshold)
6. Integrate with existing Partnership models
7. Create model tests

**Deliverables:**
- `lib/core/models/sponsorship.dart`
- `lib/core/models/brand_account.dart`
- `lib/core/models/product_tracking.dart`
- `lib/core/models/multi_party_sponsorship.dart`
- `lib/core/models/brand_discovery.dart`
- Model integration code
- Model tests

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing model patterns
- All models have tests
- Models support N-way sponsorships
- Models support product tracking

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark models complete when done
- Communicate completion so Agent 1 can start services

**Key Files:**
- `docs/agents/tasks/phase_3/task_assignments.md` - Your detailed tasks
- `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md` - Requirements
- `lib/core/models/` - Existing model patterns
```

---

### **Week 10 Prompt:**

```
You are Agent 3 working on Phase 3, Week 10: Model Integration & Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Model Integration & Testing

**Context:**
- Brand models complete (Week 9)
- Agent 1 working on services
- Need to integrate models and test

**Your Tasks:**
1. Integrate Brand models with Partnership models
2. Create model integration tests
3. Verify model relationships
4. Update existing model tests if needed

**Deliverables:**
- Model integration code
- Model integration tests
- Model relationship documentation

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing model patterns
- All models have tests
- Model relationships verified

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark integration complete when done
```

---

### **Week 11 Prompt:**

```
You are Agent 3 working on Phase 3, Week 11: Model Extensions & Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Model Extensions & Testing

**Context:**
- Brand models complete (Week 9)
- Model integration complete (Week 10)
- Agent 1 working on payment/revenue services
- Need to extend models if needed

**Your Tasks:**
1. Extend models if needed for payment/revenue
2. Create payment/revenue model tests
3. Verify model relationships
4. Update integration tests

**Deliverables:**
- Model extensions (if needed)
- Payment/revenue model tests
- Integration test updates

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Follow existing model patterns
- All models have tests

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Mark extensions complete when done
```

---

### **Week 12 Prompt:**

```
You are Agent 3 working on Phase 3, Week 12: Integration Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Integration Testing

**Context:**
- All models complete (Weeks 9-11)
- All services complete (Week 11)
- Agent 2 working on UI
- Need to create comprehensive integration tests

**Your Tasks:**
1. Create comprehensive integration tests
   - Brand discovery flow tests
   - Sponsorship creation flow tests
   - Payment flow tests
   - Product tracking flow tests
   - End-to-end tests
2. Update test infrastructure
3. Create test documentation

**Deliverables:**
- Integration test files
- Test infrastructure updates
- Test documentation

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- All integration tests pass
- Test infrastructure complete

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with completion
- Mark Phase 3 complete when done
```

---

## 📋 **Common Instructions for All Agents**

### **Before Starting:**
1. Read `docs/agents/tasks/phase_3/task_assignments.md` (your specific tasks)
2. Read `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md` (requirements)
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

**Last Updated:** November 23, 2025, 11:40 AM CST  
**Status:** 🎯 **READY FOR PHASE 3**

