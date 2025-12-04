# Phase 6 Task Assignments - Local Expert System Redesign (Week 22-23)

**Date:** November 23, 2025  
**Purpose:** Detailed task assignments for Phase 6, Week 22-23 (Codebase & Documentation Updates)  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Read:** `docs/plans/expertise_system/MASTER_PLAN_OVERLAP_ANALYSIS.md` - Overlap analysis

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Protocols:** Use `docs/agents/protocols/` files (shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/` (organized by agent, then phase)

**📁 Report Organization Schema (MANDATORY):**
- **Reports MUST be organized by agent first, then phase:** `docs/agents/reports/agent_X/[phase]/[filename].md`
- **Phase folder naming:**
  - Phase 1 (Weeks 1-4): `trial_run/`
  - Phase 2 (Weeks 5-8): `phase_2/`
  - Phase 3 (Weeks 9-12): `phase_3/`
  - Phase 4 (Weeks 13-14): `phase_4/`
  - Phase 4.5: `phase_4.5/`
  - Phase 5 (Weeks 16-21): `phase_5/`
  - Phase 6 (Weeks 22+): `phase_6/`
- **File naming:** Use descriptive names like `AGENT_X_WEEK_Y_COMPLETION.md` or `week_Y_[feature]_documentation.md`
- **See:** `docs/agents/reports/README.md` for complete organization schema
- **❌ DO NOT:** Create reports in agent root folder - always use phase subfolders

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: This Document Means Tasks Are Assigned**

**This task assignments document EXISTS, which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 22-23 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document exists):**

- ❌ **NO new tasks can be added** to Phase 6 Week 22-23
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 22-23 Overview**

**Duration:** Week 22-23 (10 days)  
**Focus:** Codebase & Documentation Updates (Phase 0)  
**Priority:** P0 - Critical (must be done before new features)  
**Philosophy:** Local experts are the bread and butter of SPOTS - they don't need city-wide reach to host events

**What Doors Does This Open?**
- **Local Community Doors:** Local experts can host events in their locality (house parties, neighborhood gatherings)
- **Accessibility:** Lower barrier to event hosting - users don't need city-wide expertise
- **Community Building:** Enables neighborhood-level community building without requiring city-wide reach

**When Are Users Ready?**
- After they've achieved Local level expertise in their category
- System is ready to recognize local experts as event hosts

**Why Critical:**
- Must update existing Dynamic Expertise System before adding new features
- Changes event hosting requirement from City level → Local level across entire codebase
- 134 "City level" references found in 28 test files
- ~73+ files need updates (code, tests, documentation)

---

## 📋 **Agent Assignments**

### **Agent 1: Backend & Integration**
**Focus:** Service Updates, Business-Expert Matching Updates

### **Agent 2: Frontend & UX**
**Focus:** UI Component Updates, Error Messages, User-Facing Text

### **Agent 3: Models & Testing**
**Focus:** Model Updates, Test Updates, Documentation Updates

---

## 📅 **Week 22: Core Model & Service Updates**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start  
**Focus:** Service Updates, Business-Expert Matching Updates

**Tasks:**
- [ ] **Service Updates (Day 1-3)**
  - [ ] Update `lib/core/services/expertise_event_service.dart`
    - [ ] Update `createEvent()` validation (line 15 comment, lines 36-37) - Change from City to Local level
    - [ ] Update error messages mentioning City level
    - [ ] Update service comments mentioning City level requirements
  - [ ] Update `lib/core/services/expertise_service.dart`
    - [ ] Update `getUnlockedFeatures()` (line 229) - Change event_hosting unlock from City to Local
    - [ ] Update service comments
  - [ ] Update `lib/core/services/expert_search_service.dart`
    - [ ] Update `getTopExperts()` (line 84) - Remove City minimum, include Local experts
    - [ ] Update service comments
  - [ ] Update `lib/core/services/expertise_matching_service.dart`
    - [ ] Update `_calculateComplementaryScore()` (lines 262-263) - Change "meaningful expertise" check from City to Local
    - [ ] Update service comments
  - [ ] Update `lib/core/services/partnership_service.dart`
    - [ ] Update `checkPartnershipEligibility()` (line 347) - Update event hosting check
    - [ ] Update service comments
  - [ ] Review `lib/core/services/expertise_community_service.dart`
    - [ ] Ensure minLevel doesn't default to City
    - [ ] Update if needed

- [ ] **CRITICAL: Business-Expert Matching Updates (Day 4-5)**
  - [ ] Update `lib/core/services/business_expert_matching_service.dart`
    - [ ] Remove level-based filtering (lines 173-177, 420-427)
    - [ ] Integrate vibe-first matching (50% vibe, 30% expertise, 20% location)
    - [ ] Make location a preference boost, not filter
    - [ ] Update AI prompts to emphasize vibe as PRIMARY factor
    - [ ] Ensure local experts are included in all business matching
  - [ ] Update service comments and documentation
  - [ ] Verify backward compatibility

**Deliverables:**
- ✅ All services updated to use Local level for event hosting
- ✅ Business-expert matching updated (remove level filtering, add vibe-first matching)
- ✅ All service comments updated
- ✅ Zero linter errors
- ✅ All services follow existing patterns

**Files to Update:**
- `lib/core/services/expertise_event_service.dart`
- `lib/core/services/expertise_service.dart`
- `lib/core/services/expert_search_service.dart`
- `lib/core/services/expertise_matching_service.dart`
- `lib/core/services/partnership_service.dart`
- `lib/core/services/expertise_community_service.dart`
- `lib/core/services/business_expert_matching_service.dart` (CRITICAL)

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start  
**Focus:** Model Updates

**Tasks:**
- [ ] **Core Model Updates (Day 1)**
  - [ ] Update `lib/core/models/unified_user.dart`
    - [ ] Update `canHostEvents()` method (line 298) - Change from City to Local level
    - [ ] Update method comments
    - [ ] Verify backward compatibility
  - [ ] Update `lib/core/models/expertise_pin.dart`
    - [ ] Update `unlocksEventHosting()` method (line 85) - Change from City to Local level
    - [ ] Update method comments
  - [ ] Review `lib/core/models/business_account.dart`
    - [ ] Ensure `minExpertLevel` doesn't default to City
    - [ ] Update if needed
  - [ ] Update all expertise level checks in models
  - [ ] Update model comments mentioning City level requirements

**Deliverables:**
- ✅ All models updated to use Local level for event hosting
- ✅ All model comments updated
- ✅ Zero linter errors
- ✅ Backward compatibility maintained

**Files to Update:**
- `lib/core/models/unified_user.dart`
- `lib/core/models/expertise_pin.dart`
- `lib/core/models/business_account.dart` (review)

---

## 📅 **Week 23: UI Component Updates & Documentation**

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start (after Week 22)  
**Focus:** UI Component Updates, Error Messages, User-Facing Text

**Tasks:**
- [ ] **UI Component Updates (Day 1-2)**
  - [ ] Update `lib/presentation/pages/events/create_event_page.dart`
    - [ ] Update City level checks (lines 20, 94, 96, 109, 328, 330, 334) - Change to Local level
    - [ ] Update error messages (lines 330, 334)
    - [ ] Update SnackBar messages
  - [ ] Update `lib/presentation/pages/events/event_review_page.dart`
    - [ ] Update "Required: City level+" (line 342) - Change to "Required: Local level+"
  - [ ] Update `lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart`
    - [ ] Update unlock logic (lines 11, 100, 315, 345, 397, 552) - Change from City to Local
    - [ ] Update messaging
  - [ ] Update `lib/presentation/widgets/expertise/expertise_display_widget.dart`
    - [ ] Include Local level in display (lines 170-177) - Currently filters to City+, include Local
  - [ ] Review all UI components showing City level requirements
  - [ ] Update all UI text/messages mentioning City level

- [ ] **Error Messages & User-Facing Text (Day 3)**
  - [ ] Update all exception messages mentioning City level
  - [ ] Update all error messages in UI
  - [ ] Update all SnackBar messages
  - [ ] Update all code comments (documentation strings)
  - [ ] Review onboarding/tutorial content
  - [ ] Review route guards/navigation logic

**Deliverables:**
- ✅ All UI components updated to show Local level requirements
- ✅ All error messages updated
- ✅ All user-facing text updated
- ✅ 100% design token adherence
- ✅ Zero linter errors
- ✅ Responsive design maintained

**Files to Update:**
- `lib/presentation/pages/events/create_event_page.dart`
- `lib/presentation/pages/events/event_review_page.dart`
- `lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart`
- `lib/presentation/widgets/expertise/expertise_display_widget.dart`
- All other UI components showing City level requirements

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start (after Week 22)  
**Focus:** Test Updates, Documentation Updates

**Tasks:**
- [ ] **Test Updates (Day 1-3)**
  - [ ] Update test helpers (`test/helpers/integration_test_helpers.dart`)
    - [ ] Update `createUserWithCityExpertise()` function (line 365) - Rename to `createUserWithLocalExpertise()` OR update to create Local level
    - [ ] Update `createUserWithoutHosting()` comment (line 398) - Now Local can host
    - [ ] Review `createExpertUser()` (line 412) - May need update
  - [ ] Update test fixtures (`test/fixtures/integration_test_fixtures.dart`)
    - [ ] Update comments and test data with City level
  - [ ] Update integration tests (8 files - HIGH PRIORITY):
    - [ ] `test/integration/expertise_event_integration_test.dart` - 18 City level references
    - [ ] `test/integration/expertise_model_relationships_test.dart` - 7 City level references
    - [ ] `test/integration/expertise_partnership_integration_test.dart` - 8 City level references
    - [ ] `test/integration/expertise_flow_integration_test.dart` - 3 City level references
    - [ ] `test/integration/event_hosting_integration_test.dart` - 10 City level references
    - [ ] `test/integration/event_discovery_integration_test.dart` - 4 City level references
    - [ ] `test/integration/payment_flow_integration_test.dart` - 1 City level reference
    - [ ] `test/integration/partnership_flow_integration_test.dart` - 1 City level reference
    - [ ] `test/integration/end_to_end_integration_test.dart` - 2 City level references
  - [ ] Update unit service tests (6 files - HIGH PRIORITY):
    - [ ] `test/unit/services/expertise_event_service_test.dart` - 2 City level tests
    - [ ] `test/unit/services/expertise_service_test.dart` - 9 City level references
    - [ ] `test/unit/services/expertise_community_service_test.dart` - 3 City level references
    - [ ] `test/unit/services/expert_search_service_test.dart` - 3 City level references
    - [ ] `test/unit/services/partnership_service_test.dart` - 1 City level reference
    - [ ] `test/unit/services/mentorship_service_test.dart` - 1 City level reference
  - [ ] Review unit model tests (4 files - LOW PRIORITY):
    - [ ] `test/unit/models/expertise_level_test.dart` - OK (enum tests)
    - [ ] `test/unit/models/expertise_progress_test.dart` - Review (mostly nextLevel - OK)
    - [ ] `test/unit/models/expertise_pin_test.dart` - OK (examples)
    - [ ] `test/unit/models/expertise_community_test.dart` - Review (minLevel checks)
  - [ ] Review widget tests (3 files - LOW PRIORITY):
    - [ ] `test/widget/widgets/expertise/expertise_progress_widget_test.dart` - OK (nextLevel)
    - [ ] `test/widget/widgets/expertise/expertise_pin_widget_test.dart` - OK (examples)
    - [ ] `test/widget/widgets/expertise/expertise_badge_widget_test.dart` - OK (examples)
  - [ ] Verify all tests pass with Local level for event hosting
  - [ ] Verify no test assumes City is minimum for event hosting

- [ ] **Documentation Updates (Day 4)**
  - [ ] Update `docs/plans/phase_1_3/USER_TO_EXPERT_JOURNEY.md` - Change "City unlocks event hosting" to "Local unlocks event hosting"
  - [ ] Update `docs/MASTER_PLAN.md` - Update any City level references
  - [ ] Update `docs/agents/status/status_tracker.md` - Update status
  - [ ] Update `docs/plans/dynamic_expertise/DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md` - Update "City level = Can host events"
  - [ ] Update `docs/plans/easy_event_hosting/EASY_EVENT_HOSTING_EXPLANATION.md`
  - [ ] Review and update all plan documents in `docs/plans/` referencing City level requirements
  - [ ] Update all code comments mentioning City level requirements

**Deliverables:**
- ✅ All tests updated and passing
- ✅ All test helpers updated
- ✅ All documentation updated
- ✅ No references to "City level required for event hosting" remain
- ✅ Test coverage maintained (>90%)

**Files to Update:**
- `test/helpers/integration_test_helpers.dart` (CRITICAL)
- `test/fixtures/integration_test_fixtures.dart`
- 8 integration test files
- 6 unit service test files
- 4 unit model test files (review)
- 3 widget test files (review)
- 20+ documentation files

---

## 🎯 **Success Criteria**

### **Code Verification:**
- [ ] Search codebase for "City level required for event hosting" - Should return 0 results
- [ ] Search codebase for `ExpertiseLevel.city.index` in event hosting context - Should return 0 results
- [ ] All services allow Local level for event hosting
- [ ] All UI components show "Local level" (not City) for event hosting requirements
- [ ] Business-expert matching includes local experts (no level filtering)
- [ ] Vibe-first matching integrated (50% vibe, 30% expertise, 20% location)

### **Test Verification:**
- [ ] All tests pass with Local level for event hosting
- [ ] No test assumes City is minimum for event hosting
- [ ] Test helpers updated (createUserWithCityExpertise → Local version or updated)
- [ ] Integration tests updated and passing
- [ ] Unit tests updated and passing
- [ ] Widget tests updated and passing

### **Documentation Verification:**
- [ ] All user documentation updated
- [ ] All plan documents updated
- [ ] All agent reports updated (if still relevant)
- [ ] No documentation says "City level unlocks event hosting"
- [ ] All documentation says "Local level unlocks event hosting"

---

## 📊 **Estimated Impact**

- **Code Files:** ~20 files (models, services, UI components)
- **Test Files:** 28 expertise-specific files (134 City level references found)
- **Documentation Files:** ~25+ files (plans, reports, user docs)
- **Total Updates:** ~73+ files (comprehensive coverage)

---

## 🚧 **Dependencies**

- ✅ Dynamic Expertise System (complete)
- ✅ Event System (complete)
- ✅ Partnership System (complete)

---

## 📝 **Notes**

- **Backward Compatibility:** Must maintain backward compatibility for existing users/events
- **Data Migration:** Plan data migration strategy for existing users/events (if needed)
- **Geographic Scope:** Local experts can only host in their locality (validation added in later phases)
- **Business Matching:** Critical update - local experts must be included in all business matching

---

**Last Updated:** November 23, 2025  
**Status:** 🎯 Ready to Start

