# Phase 6 Agent Prompts - Local Expert System Redesign (Week 22-23)

**Date:** November 23, 2025  
**Purpose:** Ready-to-use prompts for Phase 6, Week 22-23 (Codebase & Documentation Updates) agents  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Read:** `docs/plans/expertise_system/MASTER_PLAN_OVERLAP_ANALYSIS.md` - Overlap analysis

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_6/prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_6/task_assignments.md`
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

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_6_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_6.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: Tasks Are Assigned = Phase 6 Week 22-23 Is IN PROGRESS**

**This prompts document EXISTS (along with task assignments), which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 22-23 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document + task assignments exist):**

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

## 🤖 **Agent 1: Backend & Integration**

### **Week 22 Prompt:**

```
You are Agent 1 working on Phase 6, Week 22: Core Model & Service Updates.

**Your Role:** Backend & Integration Specialist
**Focus:** Service Updates, Business-Expert Matching Updates

**Context:**
- ✅ Phase 5 (Operations & Compliance) is COMPLETE
- ✅ Phase 4.5 (Partnership Profile Visibility) is COMPLETE
- ✅ Dynamic Expertise System exists (from Phase 2)
- ✅ All existing services are functional
- 🎯 **START WORK NOW** - Update all services to use Local level for event hosting

**Your Tasks:**
1. Service Updates (Day 1-3)
   - Update ExpertiseEventService.createEvent() validation - Change from City to Local level
   - Update ExpertiseService.getUnlockedFeatures() - Change event_hosting unlock from City to Local
   - Update ExpertSearchService.getTopExperts() - Remove City minimum, include Local experts
   - Update ExpertiseMatchingService._calculateComplementaryScore() - Change "meaningful expertise" check from City to Local
   - Update PartnershipService.checkPartnershipEligibility() - Update event hosting check
   - Review ExpertiseCommunityService - Ensure minLevel doesn't default to City
   - Update all service comments mentioning City level requirements

2. CRITICAL: Business-Expert Matching Updates (Day 4-5)
   - Update BusinessExpertMatchingService - Remove level-based filtering
   - Integrate vibe-first matching (50% vibe, 30% expertise, 20% location)
   - Make location a preference boost, not filter
   - Update AI prompts to emphasize vibe as PRIMARY factor
   - Ensure local experts are included in all business matching
   - Verify backward compatibility

**Deliverables:**
- All services updated to use Local level for event hosting
- Business-expert matching updated (remove level filtering, add vibe-first matching)
- All service comments updated
- Zero linter errors
- All services follow existing patterns

**Dependencies:**
- ✅ Dynamic Expertise System (exists from Phase 2)
- ✅ PartnershipService (exists from Phase 2)
- ✅ BusinessExpertMatchingService (exists from Phase 2)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- Zero linter errors
- All services follow existing patterns
- Comprehensive error handling
- Backward compatibility maintained
- Service documentation updated

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_1/phase_6/`

**Files to Update:**
- lib/core/services/expertise_event_service.dart
- lib/core/services/expertise_service.dart
- lib/core/services/expert_search_service.dart
- lib/core/services/expertise_matching_service.dart
- lib/core/services/partnership_service.dart
- lib/core/services/expertise_community_service.dart
- lib/core/services/business_expert_matching_service.dart (CRITICAL)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Week 23 Prompt:**

```
You are Agent 2 working on Phase 6, Week 23: UI Component Updates & Documentation.

**Your Role:** Frontend & UX Specialist
**Focus:** UI Component Updates, Error Messages, User-Facing Text

**Context:**
- ✅ Agent 1 completed Week 22 service updates
- ✅ Agent 3 completed Week 22 model updates
- ✅ All backend services now use Local level for event hosting
- 🎯 **START WORK NOW** - Update all UI components to show Local level requirements

**Your Tasks:**
1. UI Component Updates (Day 1-2)
   - Update create_event_page.dart - Change City level checks to Local level
   - Update event_review_page.dart - Change "Required: City level+" to "Required: Local level+"
   - Update event_hosting_unlock_widget.dart - Change unlock logic and messaging from City to Local
   - Update expertise_display_widget.dart - Include Local level in display (currently filters to City+)
   - Review all UI components showing City level requirements
   - Update all UI text/messages mentioning City level

2. Error Messages & User-Facing Text (Day 3)
   - Update all exception messages mentioning City level
   - Update all error messages in UI
   - Update all SnackBar messages
   - Update all code comments (documentation strings)
   - Review onboarding/tutorial content
   - Review route guards/navigation logic

**Deliverables:**
- All UI components updated to show Local level requirements
- All error messages updated
- All user-facing text updated
- 100% design token adherence
- Zero linter errors
- Responsive design maintained

**Dependencies:**
- ✅ Agent 1 Week 22 service updates (complete)
- ✅ Agent 3 Week 22 model updates (complete)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme, never Colors.*)
- Zero linter errors
- Responsive design
- Error/loading states handled
- All UI text updated

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_2/phase_6/`

**Files to Update:**
- lib/presentation/pages/events/create_event_page.dart
- lib/presentation/pages/events/event_review_page.dart
- lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart
- lib/presentation/widgets/expertise/expertise_display_widget.dart
- All other UI components showing City level requirements

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 🧪 **Agent 3: Models & Testing**

### **Week 22 Prompt:**

```
You are Agent 3 working on Phase 6, Week 22: Core Model Updates.

**Your Role:** Models & Testing Specialist
**Focus:** Model Updates

**Context:**
- ✅ Phase 5 (Operations & Compliance) is COMPLETE
- ✅ Phase 4.5 (Partnership Profile Visibility) is COMPLETE
- ✅ Dynamic Expertise System exists (from Phase 2)
- ✅ All existing models are functional
- 🎯 **START WORK NOW** - Update all models to use Local level for event hosting

**Your Tasks:**
1. Core Model Updates (Day 1)
   - Update UnifiedUser.canHostEvents() method - Change from City to Local level
   - Update ExpertisePin.unlocksEventHosting() method - Change from City to Local level
   - Review BusinessAccount.minExpertLevel - Ensure it doesn't default to City
   - Update all expertise level checks in models
   - Update all model comments mentioning City level requirements

**Deliverables:**
- All models updated to use Local level for event hosting
- All model comments updated
- Zero linter errors
- Backward compatibility maintained

**Dependencies:**
- ✅ Dynamic Expertise System (exists from Phase 2)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- Zero linter errors
- All models follow existing patterns
- Backward compatibility maintained
- Model documentation updated

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_3/phase_6/`

**Files to Update:**
- lib/core/models/unified_user.dart
- lib/core/models/expertise_pin.dart
- lib/core/models/business_account.dart (review)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

### **Week 23 Prompt:**

```
You are Agent 3 working on Phase 6, Week 23: Test Updates & Documentation.

**Your Role:** Models & Testing Specialist
**Focus:** Test Updates, Documentation Updates

**Context:**
- ✅ Agent 1 completed Week 22 service updates
- ✅ Agent 2 completed Week 22 model updates (you)
- ✅ Agent 2 completed Week 23 UI updates
- ✅ All code now uses Local level for event hosting
- 🎯 **START WORK NOW** - Update all tests and documentation

**Your Tasks:**
1. Test Updates (Day 1-3)
   - Update test helpers (createUserWithCityExpertise → createUserWithLocalExpertise or update logic)
   - Update test fixtures (comments and test data with City level)
   - Update integration tests (8 files - HIGH PRIORITY):
     - expertise_event_integration_test.dart - 18 City level references
     - expertise_model_relationships_test.dart - 7 City level references
     - expertise_partnership_integration_test.dart - 8 City level references
     - expertise_flow_integration_test.dart - 3 City level references
     - event_hosting_integration_test.dart - 10 City level references
     - event_discovery_integration_test.dart - 4 City level references
     - payment_flow_integration_test.dart - 1 City level reference
     - partnership_flow_integration_test.dart - 1 City level reference
     - end_to_end_integration_test.dart - 2 City level references
   - Update unit service tests (6 files - HIGH PRIORITY):
     - expertise_event_service_test.dart - 2 City level tests
     - expertise_service_test.dart - 9 City level references
     - expertise_community_service_test.dart - 3 City level references
     - expert_search_service_test.dart - 3 City level references
     - partnership_service_test.dart - 1 City level reference
     - mentorship_service_test.dart - 1 City level reference
   - Review unit model tests (4 files - LOW PRIORITY)
   - Review widget tests (3 files - LOW PRIORITY)
   - Verify all tests pass with Local level for event hosting
   - Verify no test assumes City is minimum for event hosting

2. Documentation Updates (Day 4)
   - Update USER_TO_EXPERT_JOURNEY.md - Change "City unlocks event hosting" to "Local unlocks event hosting"
   - Update MASTER_PLAN.md - Update any City level references
   - Update status_tracker.md - Update status
   - Update DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md - Update "City level = Can host events"
   - Update EASY_EVENT_HOSTING_EXPLANATION.md
   - Review and update all plan documents in docs/plans/ referencing City level requirements
   - Update all code comments mentioning City level requirements

**Deliverables:**
- All tests updated and passing
- All test helpers updated
- All documentation updated
- No references to "City level required for event hosting" remain
- Test coverage maintained (>90%)

**Dependencies:**
- ✅ Agent 1 Week 22 service updates (complete)
- ✅ Agent 2 Week 23 UI updates (complete)
- ✅ Agent 3 Week 22 model updates (complete)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- Zero linter errors
- All tests pass
- Test coverage > 90%
- All tests follow existing patterns
- Documentation comprehensive and accurate

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_3/phase_6/`

**Files to Update:**
- test/helpers/integration_test_helpers.dart (CRITICAL)
- test/fixtures/integration_test_fixtures.dart
- 8 integration test files
- 6 unit service test files
- 4 unit model test files (review)
- 3 widget test files (review)
- 20+ documentation files

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 📊 **Success Criteria**

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

## 📝 **Notes**

- **Backward Compatibility:** Must maintain backward compatibility for existing users/events
- **Data Migration:** Plan data migration strategy for existing users/events (if needed)
- **Geographic Scope:** Local experts can only host in their locality (validation added in later phases)
- **Business Matching:** Critical update - local experts must be included in all business matching

---

**Last Updated:** November 23, 2025  
**Status:** 🎯 Ready to Start

