# Phase 4 Agent Prompts - Integration Testing

**Date:** November 23, 2025, 12:39 PM CST  
**Purpose:** Ready-to-use prompts for Phase 4 agents  
**Status:** 🎯 **READY FOR PHASE 4**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 4 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/agents/guides/PHASE_3_PREPARATION.md` - Setup guide (applies to Phase 4)
3. ✅ **Read:** `docs/agents/START_HERE_PHASE_3.md` - Quick checklist (applies to Phase 4)

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_4/prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_4/task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_4/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_4_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_4.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🎯 **Phase 4 Overview**

**Duration:** Weeks 13-14 (2 weeks)  
**Focus:** Integration Testing & Quality Assurance  
**Agents:** 3 parallel agents working on different aspects

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 13 Prompt:**

```
You are Agent 1 working on Phase 4, Week 13: Event Partnership Tests + Payment Processing Tests.

**Your Role:** Backend & Integration Specialist
**Focus:** Service Testing, Payment Testing

**Context:**
- Phase 3 (Brand Sponsorship) is complete
- All code compiles with 0 errors
- Partnership services exist (from Phase 2)
- Payment services exist (from Phase 1)
- Need comprehensive testing

**Your Tasks:**
1. Partnership Service Tests (Day 1-2)
   - Unit tests for PartnershipService
   - Unit tests for PartnershipMatchingService
   - Unit tests for BusinessService
   - Test edge cases and error handling
   - Test integration with Event service

2. Payment Processing Tests (Day 3-4)
   - Unit tests for PaymentService (partnership flows)
   - Unit tests for RevenueSplitService (partnership splits)
   - Unit tests for PayoutService
   - Test edge cases and error handling
   - Test integration with Partnership service

3. Integration Tests (Day 5)
   - End-to-end partnership flow tests
   - Integration tests for payment-partnership flow
   - Integration tests for revenue split-partnership flow
   - Performance tests

**Deliverables:**
- Unit test files for all services
- Integration test files
- Test documentation
- Performance benchmarks

**Dependencies:**
- All Phase 2 services complete
- All Phase 1 services complete

**Quality Standards:**
- Test coverage > 90% for services
- All tests pass
- All edge cases covered
- Error handling tested
- Performance benchmarks established

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing test files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4/task_assignments.md` (Agent 1, Week 13)
2. Reviewing existing test patterns
3. Creating unit tests for PartnershipService
4. Creating unit tests for PaymentService
5. Creating integration tests
```

---

### **Week 14 Prompt:**

```
You are Agent 1 working on Phase 4, Week 14: Brand Sponsorship Tests + Multi-party Revenue Tests.

**Your Role:** Backend & Integration Specialist
**Focus:** Brand Sponsorship Service Tests, Multi-party Revenue Tests

**Context:**
- Week 13 tests complete
- Brand sponsorship services exist (from Phase 3)
- Need comprehensive testing

**Your Tasks:**
1. Sponsorship Service Tests (Day 1-2)
   - Unit tests for SponsorshipService
   - Unit tests for BrandDiscoveryService
   - Unit tests for ProductTrackingService
   - Test edge cases and error handling
   - Test integration with Partnership service

2. Multi-party Revenue Tests (Day 3)
   - Unit tests for RevenueSplitService (brand sponsorships)
   - Unit tests for ProductSalesService
   - Unit tests for BrandAnalyticsService
   - Test edge cases and error handling

3. Integration Tests (Day 4-5)
   - End-to-end brand sponsorship flow tests
   - Integration tests for brand-payment flow
   - Integration tests for brand-analytics flow
   - Performance tests

**Deliverables:**
- Unit test files for all brand services
- Integration test files
- Test documentation
- Performance benchmarks

**Dependencies:**
- All Phase 3 services complete
- Week 13 tests complete

**Quality Standards:**
- Test coverage > 90% for services
- All tests pass
- All edge cases covered
- Error handling tested
- Performance benchmarks established

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 13 test files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4/task_assignments.md` (Agent 1, Week 14)
2. Reviewing Week 13 test patterns
3. Creating unit tests for SponsorshipService
4. Creating unit tests for RevenueSplitService (brand)
5. Creating integration tests
```

---

## 🤖 **Agent 2: Frontend & UX**

### **Week 13 Prompt:**

```
You are Agent 2 working on Phase 4, Week 13: Expertise Dashboard Navigation + UI Integration Testing.

**Your Role:** Frontend & UX Specialist
**Focus:** Navigation Polish, UI Integration Testing

**Context:**
- Phase 3 (Brand Sponsorship UI) is complete
- All code compiles with 0 errors
- Partnership UI exists (from Phase 2)
- Payment UI exists (from Phase 1)
- Expertise Dashboard page exists (from Phase 1)
- Need navigation polish and integration testing

**Your Tasks:**
1. Expertise Dashboard Navigation (Day 1)
   - Add route to app_router.dart: `/profile/expertise-dashboard`
   - Add settings menu item to profile_page.dart
   - Test navigation flow
   - Verify route works correctly

2. UI Integration Testing (Day 2-5)
   - Test Partnership UI integration
   - Test Payment UI integration
   - Test Business UI integration
   - Test navigation flows
   - Test responsive design
   - Test error/loading/empty states

**Deliverables:**
- Updated app_router.dart
- Updated profile_page.dart
- UI integration test files
- Navigation flow documentation

**Dependencies:**
- All Phase 1-3 UI complete
- Expertise Dashboard page exists

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Zero linter errors
- All navigation flows work
- Responsive design verified
- Error/loading/empty states tested

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4/task_assignments.md` - Your detailed tasks
- `docs/USER_TO_EXPERT_JOURNEY.md` - Navigation requirements
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing UI pages for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4/task_assignments.md` (Agent 2, Week 13)
2. Reviewing app_router.dart structure
3. Adding Expertise Dashboard route
4. Adding settings menu item
5. Testing navigation
6. Creating UI integration tests
```

---

### **Week 14 Prompt:**

```
You are Agent 2 working on Phase 4, Week 14: Brand UI Integration Testing + User Flow Testing.

**Your Role:** Frontend & UX Specialist
**Focus:** Brand UI Integration Testing, User Flow Testing

**Context:**
- Week 13 navigation and tests complete
- Brand UI exists (from Phase 3)
- Need comprehensive integration testing

**Your Tasks:**
1. Brand UI Integration Testing (Day 1-3)
   - Test Brand Discovery UI integration
   - Test Sponsorship Management UI integration
   - Test Brand Dashboard UI integration
   - Test Brand Analytics UI integration
   - Test Sponsorship Checkout UI integration

2. User Flow Testing (Day 4-5)
   - Test complete brand sponsorship flow
   - Test complete user partnership flow
   - Test complete business flow
   - Test navigation between all pages
   - Test responsive design
   - Test error/loading/empty states

**Deliverables:**
- UI integration test files
- User flow test documentation
- Navigation flow verification

**Dependencies:**
- All Phase 3 UI complete
- Week 13 tests complete

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme)
- Zero linter errors
- All user flows work correctly
- Navigation verified
- Responsive design verified
- Error/loading/empty states tested

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 13 test files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4/task_assignments.md` (Agent 2, Week 14)
2. Reviewing Week 13 test patterns
3. Creating Brand UI integration tests
4. Testing complete user flows
5. Documenting test results
```

---

## 🤖 **Agent 3: Models & Testing**

### **Week 13 Prompt:**

```
You are Agent 3 working on Phase 4, Week 13: Integration Tests + End-to-End Tests.

**Your Role:** Models & Testing Specialist
**Focus:** Integration Tests, End-to-End Tests

**Context:**
- Phase 3 (Brand Models) is complete
- All code compiles with 0 errors
- Partnership models exist (from Phase 2)
- Payment models exist (from Phase 1)
- Need comprehensive integration testing

**Your Tasks:**
1. Integration Tests (Day 1-4)
   - Partnership flow integration tests
   - Payment flow integration tests
   - Business flow integration tests
   - End-to-end partnership payment workflow tests
   - Test model relationships

2. Test Infrastructure (Day 5)
   - Review and update test helpers
   - Create test fixtures for partnerships
   - Create test fixtures for payments
   - Create test fixtures for businesses
   - Document test patterns
   - Update test documentation

**Deliverables:**
- Integration test files
- End-to-end test files
- Test fixtures and helpers
- Test documentation

**Dependencies:**
- All Phase 1-3 models complete
- Agent 1 service tests (for integration)

**Quality Standards:**
- All integration tests pass
- All end-to-end tests pass
- Test infrastructure complete
- Test fixtures available
- Test documentation complete

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing integration test files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4/task_assignments.md` (Agent 3, Week 13)
2. Reviewing existing integration test patterns
3. Creating partnership flow integration tests
4. Creating payment flow integration tests
5. Creating end-to-end tests
6. Updating test infrastructure
```

---

### **Week 14 Prompt:**

```
You are Agent 3 working on Phase 4, Week 14: Dynamic Expertise Tests + Integration Tests.

**Your Role:** Models & Testing Specialist
**Focus:** Expertise System Tests, Integration Tests

**Context:**
- Week 13 integration tests complete
- Expertise system exists (from Phase 2)
- Need comprehensive testing

**Your Tasks:**
1. Expertise Calculation Tests (Day 1-2)
   - Unit tests for ExpertiseCalculationService
   - Unit tests for expertise thresholds
   - Test expertise progression
   - Test expertise unlocking
   - Test edge cases

2. Saturation Algorithm Tests (Day 3)
   - Unit tests for SaturationAlgorithmService
   - Test saturation thresholds
   - Test saturation impact on expertise
   - Test edge cases

3. Automatic Check-in Tests (Day 4-5)
   - Unit tests for AutomaticCheckInService
   - Integration tests for check-in flow
   - Test edge cases
   - Test offline functionality

4. Integration Tests (Day 4-5)
   - End-to-end expertise flow tests
   - Integration tests for expertise-partnership flow
   - Integration tests for expertise-event flow
   - Test model relationships

**Deliverables:**
- Unit test files for expertise services
- Integration test files
- Test documentation

**Dependencies:**
- All Phase 2 expertise services complete
- Week 13 tests complete

**Quality Standards:**
- All unit tests pass
- All integration tests pass
- Test coverage > 90% for services
- All edge cases covered
- Error handling tested
- Offline functionality tested

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Week 13 test files for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4/task_assignments.md` (Agent 3, Week 14)
2. Reviewing Week 13 test patterns
3. Creating expertise calculation tests
4. Creating saturation algorithm tests
5. Creating automatic check-in tests
6. Creating integration tests
```

---

## 📋 **Common Instructions for All Agents**

### **Before Starting:**
1. Read `docs/agents/tasks/phase_4/task_assignments.md` for your specific tasks
2. Check `docs/agents/status/status_tracker.md` for dependencies
3. Review existing test patterns in the codebase
4. Understand the feature you're testing

### **During Work:**
1. Follow existing test patterns
2. Write comprehensive tests (unit, integration, end-to-end)
3. Test edge cases and error handling
4. Document test results
5. Update status tracker regularly

### **After Completing:**
1. Verify all tests pass
2. Check test coverage (> 90% for services)
3. Document test results
4. Update status tracker with completion
5. Create completion report in `docs/agents/reports/agent_X/phase_4/`

### **Quality Checklist:**
- ✅ All tests pass
- ✅ Test coverage > 90% for services
- ✅ All edge cases covered
- ✅ Error handling tested
- ✅ Performance benchmarks established (where applicable)
- ✅ Test documentation complete
- ✅ Zero linter errors

---

## 📚 **Key Reference Documents**

- **Task Assignments:** `docs/agents/tasks/phase_4/task_assignments.md`
- **Status Tracker:** `docs/agents/status/status_tracker.md`
- **Quick Reference:** `docs/agents/reference/quick_reference.md`
- **Protocol:** `docs/agents/REFACTORING_PROTOCOL.md`
- **Phase 3 Completion:** `docs/PHASE_3_COMPLETION_REPORT.md`
- **Master Plan:** `docs/MASTER_PLAN.md`

---

**Last Updated:** November 23, 2025, 12:39 PM CST  
**Status:** 🎯 **READY FOR PHASE 4**

