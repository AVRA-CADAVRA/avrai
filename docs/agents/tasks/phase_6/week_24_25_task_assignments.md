# Phase 6 Task Assignments - Local Expert System Redesign (Week 24-25)

**Date:** November 24, 2025  
**Purpose:** Detailed task assignments for Phase 6, Week 24-25 (Core Local Expert System - Phase 1)  
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
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Protocols:** Use `docs/agents/protocols/` files (shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/` (organized by agent, then phase)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: This Document Means Tasks Are Assigned**

**This task assignments document EXISTS, which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 24-25 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document exists):**

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

## 📋 **Agent Assignments**

### **Agent 1: Backend & Integration**
**Focus:** Geographic Hierarchy Services, Large City Detection, Service Integration

### **Agent 2: Frontend & UX**
**Focus:** Geographic Scope UI, Locality Selection, Error Messages

### **Agent 3: Models & Testing**
**Focus:** Locality Models, Qualification Models, Test Infrastructure

---

## 📅 **Week 24: Geographic Hierarchy Service**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start  
**Focus:** Geographic Hierarchy Services, Large City Detection

**Tasks:**
- [ ] **GeographicScopeService (Day 1-3)**
  - [ ] Create `lib/core/services/geographic_scope_service.dart`
    - [ ] Implement hierarchy validation: Local → City → State → National → Global → Universal
    - [ ] `canHostInLocality(String userId, String locality)` - Check if user can host in locality
    - [ ] `canHostInCity(String userId, String city)` - Check if user can host in city
    - [ ] `getHostingScope(String userId)` - Get all localities/cities user can host in
    - [ ] `validateEventLocation(String userId, String eventLocality)` - Validate event location for user
    - [ ] Integration with UnifiedUser (read expertise level and location)
    - [ ] Integration with ExpertiseEventService (validate before event creation)
  - [ ] Create comprehensive test file (`test/unit/services/geographic_scope_service_test.dart`)
  - [ ] Test all hierarchy levels and edge cases
  - [ ] Test locality validation (local experts can only host in their locality)
  - [ ] Test city validation (city experts can host in all localities in their city)

- [ ] **LargeCityDetectionService (Day 4-5)**
  - [ ] Create `lib/core/services/large_city_detection_service.dart`
    - [ ] `isLargeCity(String cityName)` - Detect if city is large and diverse
    - [ ] `getNeighborhoods(String cityName)` - Get neighborhoods for large city
    - [ ] `isNeighborhoodLocality(String locality)` - Check if locality is a neighborhood
    - [ ] `getParentCity(String locality)` - Get parent city for neighborhood locality
    - [ ] Store large city configuration (geographic size, population, documented neighborhoods)
    - [ ] Support for: Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos, etc.
  - [ ] Create comprehensive test file (`test/unit/services/large_city_detection_service_test.dart`)
  - [ ] Test large city detection logic
  - [ ] Test neighborhood locality handling

- [ ] **Service Integration (Day 5)**
  - [ ] Update `ExpertiseEventService.createEvent()` to use GeographicScopeService
  - [ ] Add geographic scope validation before event creation
  - [ ] Update error messages for geographic scope violations
  - [ ] Ensure backward compatibility

**Deliverables:**
- ✅ GeographicScopeService with hierarchy validation
- ✅ LargeCityDetectionService with large city support
- ✅ Integration with ExpertiseEventService
- ✅ Comprehensive test files
- ✅ Zero linter errors
- ✅ All services follow existing patterns

**Files to Create:**
- `lib/core/services/geographic_scope_service.dart`
- `lib/core/services/large_city_detection_service.dart`
- `test/unit/services/geographic_scope_service_test.dart`
- `test/unit/services/large_city_detection_service_test.dart`

**Files to Modify:**
- `lib/core/services/expertise_event_service.dart`

---

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start (after Agent 1 Day 3)  
**Focus:** Geographic Scope UI, Locality Selection

**Tasks:**
- [ ] **Geographic Scope UI (Day 1-2)**
  - [ ] Update `create_event_page.dart` to show geographic scope validation
  - [ ] Add locality selection widget (if user is city expert, show all localities in city)
  - [ ] Add geographic scope indicator (show what areas user can host in)
  - [ ] Update error messages for geographic scope violations
  - [ ] Add helpful messaging for local vs city experts

- [ ] **Locality Selection Widget (Day 3)**
  - [ ] Create `locality_selection_widget.dart` (if needed)
  - [ ] Show available localities based on user's expertise level
  - [ ] Filter localities based on geographic scope
  - [ ] Show large city neighborhoods as separate localities

- [ ] **Error Messages & User-Facing Text (Day 4)**
  - [ ] Update all error messages for geographic scope violations
  - [ ] Add helpful tooltips explaining geographic scope
  - [ ] Update onboarding/tutorial content if needed

**Deliverables:**
- ✅ Geographic scope validation in UI
- ✅ Locality selection based on user's scope
- ✅ Clear error messages for scope violations
- ✅ 100% design token adherence
- ✅ Zero linter errors
- ✅ Responsive design

**Files to Create:**
- `lib/presentation/widgets/events/locality_selection_widget.dart` (if needed)

**Files to Modify:**
- `lib/presentation/pages/events/create_event_page.dart`

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start  
**Focus:** Geographic Models, Test Infrastructure

**Tasks:**
- [ ] **Geographic Models (Day 1-2)**
  - [ ] Create `GeographicScope` model (if needed)
  - [ ] Create `Locality` model (if needed)
  - [ ] Create `LargeCity` model (if needed)
  - [ ] Ensure models integrate with existing UnifiedUser and ExpertiseEvent models
  - [ ] Add model tests

- [ ] **Test Infrastructure (Day 3-4)**
  - [ ] Create test helpers for geographic scope testing
  - [ ] Create test fixtures for localities and cities
  - [ ] Create integration tests for geographic scope validation
  - [ ] Test event creation with geographic scope validation
  - [ ] Test large city detection in integration tests

- [ ] **Documentation (Day 5)**
  - [ ] Document geographic hierarchy system
  - [ ] Document large city detection logic
  - [ ] Update user documentation if needed

**Deliverables:**
- ✅ Geographic models (if needed)
- ✅ Test infrastructure for geographic scope
- ✅ Integration tests for geographic validation
- ✅ Test helpers and fixtures
- ✅ Documentation

**Files to Create:**
- `lib/core/models/geographic_scope.dart` (if needed)
- `lib/core/models/locality.dart` (if needed)
- `lib/core/models/large_city.dart` (if needed)
- `test/integration/geographic_scope_integration_test.dart`
- Test helpers and fixtures

---

## 📅 **Week 25: Local Expert Qualification**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start (after Week 24)  
**Focus:** Locality Value Analysis Service, Dynamic Threshold Service

**Tasks:**
- [ ] **LocalityValueAnalysisService (Day 1-3)**
  - [ ] Create `lib/core/services/locality_value_analysis_service.dart`
    - [ ] `analyzeLocalityValues(String locality)` - Analyze what locality values most
    - [ ] `getActivityWeights(String locality)` - Get weights for different activities
    - [ ] Track: events hosted, lists created, reviews written, event attendance, etc.
    - [ ] Calculate locality-specific preferences
    - [ ] Store locality value data
  - [ ] Create comprehensive test file (`test/unit/services/locality_value_analysis_service_test.dart`)
  - [ ] Test locality value analysis logic
  - [ ] Test activity weight calculation

- [ ] **DynamicThresholdService (Day 4-5)**
  - [ ] Create `lib/core/services/dynamic_threshold_service.dart`
    - [ ] `calculateLocalThreshold(String locality, String category)` - Calculate locality-specific threshold
    - [ ] `getThresholdForActivity(String locality, String activity)` - Get threshold for specific activity
    - [ ] Lower thresholds for activities valued by locality
    - [ ] Higher thresholds for activities less valued by locality
    - [ ] Implement threshold ebb and flow based on locality data
  - [ ] Update `ExpertiseCalculationService` to use dynamic thresholds
  - [ ] Create comprehensive test file (`test/unit/services/dynamic_threshold_service_test.dart`)
  - [ ] Test threshold calculation logic
  - [ ] Test integration with ExpertiseCalculationService

**Deliverables:**
- ✅ LocalityValueAnalysisService
- ✅ DynamicThresholdService
- ✅ Integration with ExpertiseCalculationService
- ✅ Comprehensive test files
- ✅ Zero linter errors
- ✅ All services follow existing patterns

**Files to Create:**
- `lib/core/services/locality_value_analysis_service.dart`
- `lib/core/services/dynamic_threshold_service.dart`
- `test/unit/services/locality_value_analysis_service_test.dart`
- `test/unit/services/dynamic_threshold_service_test.dart`

**Files to Modify:**
- `lib/core/services/expertise_calculation_service.dart`

---

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start (after Week 24)  
**Focus:** Qualification UI, Threshold Display

**Tasks:**
- [ ] **Qualification UI (Day 1-2)**
  - [ ] Update expertise display to show locality-specific thresholds
  - [ ] Add locality value indicators (show what locality values)
  - [ ] Update progress indicators to reflect dynamic thresholds
  - [ ] Add helpful messaging about locality-specific qualification

- [ ] **Threshold Display Widget (Day 3)**
  - [ ] Create `locality_threshold_widget.dart` (if needed)
  - [ ] Show current threshold for user's locality
  - [ ] Show how locality values different activities
  - [ ] Show progress to local expert qualification

- [ ] **User-Facing Text (Day 4)**
  - [ ] Update all text to explain locality-specific qualification
  - [ ] Add tooltips explaining dynamic thresholds
  - [ ] Update onboarding/tutorial content

**Deliverables:**
- ✅ Locality-specific threshold display
- ✅ Locality value indicators
- ✅ Progress indicators for dynamic thresholds
- ✅ 100% design token adherence
- ✅ Zero linter errors
- ✅ Responsive design

**Files to Create:**
- `lib/presentation/widgets/expertise/locality_threshold_widget.dart` (if needed)

**Files to Modify:**
- `lib/presentation/widgets/expertise/expertise_display_widget.dart`
- `lib/presentation/widgets/expertise/expertise_progress_widget.dart`

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start (after Week 24)  
**Focus:** Qualification Models, Test Infrastructure

**Tasks:**
- [ ] **Qualification Models (Day 1-2)**
  - [ ] Create `LocalityValue` model (if needed)
  - [ ] Create `DynamicThreshold` model (if needed)
  - [ ] Create `LocalExpertQualification` model (if needed)
  - [ ] Ensure models integrate with existing expertise models
  - [ ] Add model tests

- [ ] **Test Infrastructure (Day 3-4)**
  - [ ] Create test helpers for locality value testing
  - [ ] Create test fixtures for locality values and thresholds
  - [ ] Create integration tests for dynamic threshold calculation
  - [ ] Test local expert qualification logic
  - [ ] Test locality value analysis in integration tests

- [ ] **Documentation (Day 5)**
  - [ ] Document locality value analysis system
  - [ ] Document dynamic threshold calculation
  - [ ] Update user documentation if needed

**Deliverables:**
- ✅ Qualification models (if needed)
- ✅ Test infrastructure for locality values and thresholds
- ✅ Integration tests for dynamic qualification
- ✅ Test helpers and fixtures
- ✅ Documentation

**Files to Create:**
- `lib/core/models/locality_value.dart` (if needed)
- `lib/core/models/dynamic_threshold.dart` (if needed)
- `lib/core/models/local_expert_qualification.dart` (if needed)
- `test/integration/locality_value_integration_test.dart`
- `test/integration/dynamic_threshold_integration_test.dart`
- Test helpers and fixtures

---

## 🎯 **Success Criteria**

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

## 📊 **Estimated Impact**

- **New Services:** 4 services (GeographicScopeService, LargeCityDetectionService, LocalityValueAnalysisService, DynamicThresholdService)
- **New Models:** 3-6 models (depending on design decisions)
- **Modified Services:** 2 services (ExpertiseEventService, ExpertiseCalculationService)
- **Modified UI:** 2-3 UI components
- **Test Files:** 8+ test files (unit + integration)

---

## 🚧 **Dependencies**

- ✅ Week 22-23 (Phase 0) COMPLETE - All City level → Local level updates done
- ✅ Dynamic Expertise System (complete)
- ✅ Event System (complete)
- ✅ UnifiedUser model (complete)

---

## 📝 **Notes**

- **Geographic Hierarchy:** Must enforce strict hierarchy - local experts cannot host outside their locality
- **Large Cities:** Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos should be detected and neighborhoods treated as separate localities
- **Dynamic Thresholds:** Thresholds should ebb and flow based on actual locality data, not be static
- **Backward Compatibility:** All existing events and users should continue to work

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Start

