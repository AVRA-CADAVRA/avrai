# Phase 6 Agent Prompts - Local Expert System Redesign (Week 24-25)

**Date:** November 24, 2025  
**Purpose:** Ready-to-use prompts for Phase 6, Week 24-25 (Core Local Expert System - Phase 1) agents  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 24-25 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Read:** `docs/plans/expertise_system/MASTER_PLAN_OVERLAP_ANALYSIS.md` - Overlap analysis
5. ✅ **Verify:** Week 22-23 (Phase 0) is COMPLETE - All City level → Local level updates done

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_6/week_24_25_prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_6/week_24_25_task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_6_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_6.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: Tasks Are Assigned = Phase 6 Week 24-25 Is IN PROGRESS**

**This prompts document EXISTS (along with task assignments), which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 24-25 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document + task assignments exist):**

- ❌ **NO new tasks can be added** to Phase 6 Week 24-25
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 24-25 Overview**

**Duration:** Week 24-25 (10 days)  
**Focus:** Core Local Expert System (Phase 1)  
**Priority:** P1 - Core Functionality  
**Philosophy:** Local experts are the bread and butter of SPOTS - they don't need city-wide reach to host events

**What Doors Does This Open?**
- **Geographic Scope Doors:** Local experts can host events in their locality only, city experts can host in all localities in their city
- **Large City Doors:** Neighborhoods in large cities (Brooklyn, LA, etc.) can be separate localities, preserving neighborhood identity
- **Qualification Doors:** Users can become local experts based on what their locality values (dynamic thresholds)
- **Community Building Doors:** Enables neighborhood-level community building with locality-specific recognition

**When Are Users Ready?**
- After they've achieved Local level expertise in their category
- System recognizes locality-specific values and adjusts thresholds accordingly
- Geographic scope validation ensures experts host in appropriate areas

**Dependencies:**
- ✅ Week 22-23 (Phase 0) COMPLETE - All City level → Local level updates done
- ✅ Dynamic Expertise System exists (from Phase 2)
- ✅ Event System exists (from Phase 1)

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 24 Prompt:**

```
You are Agent 1 working on Phase 6, Week 24: Geographic Hierarchy Service.

**Your Role:** Backend & Integration Specialist
**Focus:** Geographic Hierarchy Services, Large City Detection

**Context:**
- ✅ Week 22-23 (Phase 0) is COMPLETE - All City level → Local level updates done
- ✅ Dynamic Expertise System exists (from Phase 2)
- ✅ Event System exists (from Phase 1)
- ✅ UnifiedUser model exists with expertise levels
- 🎯 **START WORK NOW** - Create geographic hierarchy services

**Your Tasks:**
1. GeographicScopeService (Day 1-3)
   - Create GeographicScopeService with hierarchy validation
   - Implement: Local → City → State → National → Global → Universal
   - Add methods:
     - canHostInLocality(String userId, String locality)
     - canHostInCity(String userId, String city)
     - getHostingScope(String userId)
     - validateEventLocation(String userId, String eventLocality)
   - Integrate with UnifiedUser (read expertise level and location)
   - Integrate with ExpertiseEventService (validate before event creation)
   - Create comprehensive test file
   - Test all hierarchy levels and edge cases

2. LargeCityDetectionService (Day 4-5)
   - Create LargeCityDetectionService
   - Detect large cities: Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos, etc.
   - Add methods:
     - isLargeCity(String cityName)
     - getNeighborhoods(String cityName)
     - isNeighborhoodLocality(String locality)
     - getParentCity(String locality)
   - Store large city configuration (geographic size, population, documented neighborhoods)
   - Create comprehensive test file
   - Test large city detection logic

3. Service Integration (Day 5)
   - Update ExpertiseEventService.createEvent() to use GeographicScopeService
   - Add geographic scope validation before event creation
   - Update error messages for geographic scope violations
   - Ensure backward compatibility

**Deliverables:**
- GeographicScopeService with hierarchy validation
- LargeCityDetectionService with large city support
- Integration with ExpertiseEventService
- Comprehensive test files
- Zero linter errors
- All services follow existing patterns

**Dependencies:**
- ✅ Week 22-23 COMPLETE
- ✅ UnifiedUser model (exists)
- ✅ ExpertiseEventService (exists)
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

**Files to Create:**
- lib/core/services/geographic_scope_service.dart
- lib/core/services/large_city_detection_service.dart
- test/unit/services/geographic_scope_service_test.dart
- test/unit/services/large_city_detection_service_test.dart

**Files to Modify:**
- lib/core/services/expertise_event_service.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_24_25_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

### **Week 25 Prompt:**

```
You are Agent 1 working on Phase 6, Week 25: Local Expert Qualification.

**Your Role:** Backend & Integration Specialist
**Focus:** Locality Value Analysis Service, Dynamic Threshold Service

**Context:**
- ✅ Week 24 COMPLETE - Geographic hierarchy services created
- ✅ GeographicScopeService exists
- ✅ LargeCityDetectionService exists
- ✅ ExpertiseCalculationService exists (from Phase 2)
- 🎯 **START WORK NOW** - Create locality value analysis and dynamic threshold services

**Your Tasks:**
1. LocalityValueAnalysisService (Day 1-3)
   - Create LocalityValueAnalysisService
   - Track what users interact with most in each locality
   - Calculate locality-specific weights for different activities
   - Add methods:
     - analyzeLocalityValues(String locality)
     - getActivityWeights(String locality)
   - Track: events hosted, lists created, reviews written, event attendance, etc.
   - Store locality value data
   - Create comprehensive test file
   - Test locality value analysis logic

2. DynamicThresholdService (Day 4-5)
   - Create DynamicThresholdService
   - Calculate locality-specific thresholds
   - Lower thresholds for activities valued by locality
   - Higher thresholds for activities less valued by locality
   - Add methods:
     - calculateLocalThreshold(String locality, String category)
     - getThresholdForActivity(String locality, String activity)
   - Implement threshold ebb and flow based on locality data
   - Update ExpertiseCalculationService to use dynamic thresholds
   - Create comprehensive test file
   - Test threshold calculation logic

**Deliverables:**
- LocalityValueAnalysisService
- DynamicThresholdService
- Integration with ExpertiseCalculationService
- Comprehensive test files
- Zero linter errors
- All services follow existing patterns

**Dependencies:**
- ✅ Week 24 COMPLETE
- ✅ ExpertiseCalculationService (exists)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- Zero linter errors
- All services follow existing patterns
- Comprehensive error handling
- Dynamic thresholds based on actual locality data
- Service documentation updated

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_1/phase_6/`

**Files to Create:**
- lib/core/services/locality_value_analysis_service.dart
- lib/core/services/dynamic_threshold_service.dart
- test/unit/services/locality_value_analysis_service_test.dart
- test/unit/services/dynamic_threshold_service_test.dart

**Files to Modify:**
- lib/core/services/expertise_calculation_service.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_24_25_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Week 24 Prompt:**

```
You are Agent 2 working on Phase 6, Week 24: Geographic Scope UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Geographic Scope UI, Locality Selection

**Context:**
- ✅ Week 22-23 COMPLETE - All UI components updated for Local level
- ✅ Agent 1 is creating GeographicScopeService (Day 1-3)
- ✅ create_event_page.dart exists (from Phase 1)
- 🎯 **START WORK NOW** - Add geographic scope validation to UI (after Agent 1 Day 3)

**Your Tasks:**
1. Geographic Scope UI (Day 1-2)
   - Update create_event_page.dart to show geographic scope validation
   - Add locality selection widget (if user is city expert, show all localities in city)
   - Add geographic scope indicator (show what areas user can host in)
   - Update error messages for geographic scope violations
   - Add helpful messaging for local vs city experts

2. Locality Selection Widget (Day 3)
   - Create locality_selection_widget.dart (if needed)
   - Show available localities based on user's expertise level
   - Filter localities based on geographic scope
   - Show large city neighborhoods as separate localities

3. Error Messages & User-Facing Text (Day 4)
   - Update all error messages for geographic scope violations
   - Add helpful tooltips explaining geographic scope
   - Update onboarding/tutorial content if needed

**Deliverables:**
- Geographic scope validation in UI
- Locality selection based on user's scope
- Clear error messages for scope violations
- 100% design token adherence
- Zero linter errors
- Responsive design

**Dependencies:**
- ✅ Agent 1 GeographicScopeService (Day 3 complete)
- ✅ create_event_page.dart (exists)
- ✅ **NO BLOCKERS** - Start work after Agent 1 Day 3

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme, never Colors.*)
- Zero linter errors
- Responsive design
- Error/loading states handled
- Clear user messaging

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_2/phase_6/`

**Files to Create:**
- lib/presentation/widgets/events/locality_selection_widget.dart (if needed)

**Files to Modify:**
- lib/presentation/pages/events/create_event_page.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_24_25_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

### **Week 25 Prompt:**

```
You are Agent 2 working on Phase 6, Week 25: Qualification UI.

**Your Role:** Frontend & UX Specialist
**Focus:** Qualification UI, Threshold Display

**Context:**
- ✅ Week 24 COMPLETE - Geographic scope UI created
- ✅ Agent 1 is creating LocalityValueAnalysisService and DynamicThresholdService
- ✅ Expertise display widgets exist (from Phase 2)
- 🎯 **START WORK NOW** - Add locality-specific threshold display to UI

**Your Tasks:**
1. Qualification UI (Day 1-2)
   - Update expertise display to show locality-specific thresholds
   - Add locality value indicators (show what locality values)
   - Update progress indicators to reflect dynamic thresholds
   - Add helpful messaging about locality-specific qualification

2. Threshold Display Widget (Day 3)
   - Create locality_threshold_widget.dart (if needed)
   - Show current threshold for user's locality
   - Show how locality values different activities
   - Show progress to local expert qualification

3. User-Facing Text (Day 4)
   - Update all text to explain locality-specific qualification
   - Add tooltips explaining dynamic thresholds
   - Update onboarding/tutorial content

**Deliverables:**
- Locality-specific threshold display
- Locality value indicators
- Progress indicators for dynamic thresholds
- 100% design token adherence
- Zero linter errors
- Responsive design

**Dependencies:**
- ✅ Week 24 COMPLETE
- ✅ Agent 1 LocalityValueAnalysisService and DynamicThresholdService (complete)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- 100% design token adherence (AppColors/AppTheme, never Colors.*)
- Zero linter errors
- Responsive design
- Error/loading states handled
- Clear user messaging

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_2/phase_6/`

**Files to Create:**
- lib/presentation/widgets/expertise/locality_threshold_widget.dart (if needed)

**Files to Modify:**
- lib/presentation/widgets/expertise/expertise_display_widget.dart
- lib/presentation/widgets/expertise/expertise_progress_widget.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_24_25_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 🧪 **Agent 3: Models & Testing**

### **Week 24 Prompt:**

```
You are Agent 3 working on Phase 6, Week 24: Geographic Models & Test Infrastructure.

**Your Role:** Models & Testing Specialist
**Focus:** Geographic Models, Test Infrastructure

**Context:**
- ✅ Week 22-23 COMPLETE - All models updated for Local level
- ✅ Agent 1 is creating GeographicScopeService and LargeCityDetectionService
- ✅ UnifiedUser and ExpertiseEvent models exist
- 🎯 **START WORK NOW** - Create geographic models and test infrastructure

**Your Tasks:**
1. Geographic Models (Day 1-2)
   - Create GeographicScope model (if needed)
   - Create Locality model (if needed)
   - Create LargeCity model (if needed)
   - Ensure models integrate with existing UnifiedUser and ExpertiseEvent models
   - Add model tests

2. Test Infrastructure (Day 3-4)
   - Create test helpers for geographic scope testing
   - Create test fixtures for localities and cities
   - Create integration tests for geographic scope validation
   - Test event creation with geographic scope validation
   - Test large city detection in integration tests

3. Documentation (Day 5)
   - Document geographic hierarchy system
   - Document large city detection logic
   - Update user documentation if needed

**Deliverables:**
- Geographic models (if needed)
- Test infrastructure for geographic scope
- Integration tests for geographic validation
- Test helpers and fixtures
- Documentation

**Dependencies:**
- ✅ Week 22-23 COMPLETE
- ✅ Agent 1 GeographicScopeService and LargeCityDetectionService (complete)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- Zero linter errors
- All models follow existing patterns
- Comprehensive test coverage (>90%)
- All tests pass
- Documentation comprehensive

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_3/phase_6/`

**Files to Create:**
- lib/core/models/geographic_scope.dart (if needed)
- lib/core/models/locality.dart (if needed)
- lib/core/models/large_city.dart (if needed)
- test/integration/geographic_scope_integration_test.dart
- Test helpers and fixtures

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_24_25_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

### **Week 25 Prompt:**

```
You are Agent 3 working on Phase 6, Week 25: Qualification Models & Test Infrastructure.

**Your Role:** Models & Testing Specialist
**Focus:** Qualification Models, Test Infrastructure

**Context:**
- ✅ Week 24 COMPLETE - Geographic models and test infrastructure created
- ✅ Agent 1 is creating LocalityValueAnalysisService and DynamicThresholdService
- ✅ Expertise models exist (from Phase 2)
- 🎯 **START WORK NOW** - Create qualification models and test infrastructure

**Your Tasks:**
1. Qualification Models (Day 1-2)
   - Create LocalityValue model (if needed)
   - Create DynamicThreshold model (if needed)
   - Create LocalExpertQualification model (if needed)
   - Ensure models integrate with existing expertise models
   - Add model tests

2. Test Infrastructure (Day 3-4)
   - Create test helpers for locality value testing
   - Create test fixtures for locality values and thresholds
   - Create integration tests for dynamic threshold calculation
   - Test local expert qualification logic
   - Test locality value analysis in integration tests

3. Documentation (Day 5)
   - Document locality value analysis system
   - Document dynamic threshold calculation
   - Update user documentation if needed

**Deliverables:**
- Qualification models (if needed)
- Test infrastructure for locality values and thresholds
- Integration tests for dynamic qualification
- Test helpers and fixtures
- Documentation

**Dependencies:**
- ✅ Week 24 COMPLETE
- ✅ Agent 1 LocalityValueAnalysisService and DynamicThresholdService (complete)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- Zero linter errors
- All models follow existing patterns
- Comprehensive test coverage (>90%)
- All tests pass
- Documentation comprehensive

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_3/phase_6/`

**Files to Create:**
- lib/core/models/locality_value.dart (if needed)
- lib/core/models/dynamic_threshold.dart (if needed)
- lib/core/models/local_expert_qualification.dart (if needed)
- test/integration/locality_value_integration_test.dart
- test/integration/dynamic_threshold_integration_test.dart
- Test helpers and fixtures

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_24_25_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 📊 **Success Criteria**

### **Week 24: Geographic Hierarchy**
- [ ] Local experts can only host events in their locality
- [ ] City experts can host events in all localities in their city
- [ ] Geographic hierarchy enforced (Local < City < State < National < Global < Universal)
- [ ] Large city detection working (Brooklyn, LA, etc. as separate localities)
- [ ] All geographic scope validation tests pass
- [ ] UI shows appropriate locality selection based on user's scope

### **Week 25: Local Expert Qualification**
- [ ] Locality value analysis working
- [ ] Dynamic thresholds calculated based on locality values
- [ ] Lower thresholds for activities valued by locality
- [ ] Higher thresholds for activities less valued by locality
- [ ] Local expert qualification factors implemented
- [ ] All threshold calculation tests pass
- [ ] UI shows locality-specific thresholds and progress

---

## 📝 **Notes**

- **Geographic Hierarchy:** Must enforce strict hierarchy - local experts cannot host outside their locality
- **Large Cities:** Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos should be detected and neighborhoods treated as separate localities
- **Dynamic Thresholds:** Thresholds should ebb and flow based on actual locality data, not be static
- **Backward Compatibility:** All existing events and users should continue to work

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Start

