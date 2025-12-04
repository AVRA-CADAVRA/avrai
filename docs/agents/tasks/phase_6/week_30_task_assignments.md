# Phase 6 Task Assignments - Local Expert System Redesign (Week 30)

**Date:** November 24, 2025  
**Purpose:** Detailed task assignments for Phase 6, Week 30 (Expertise Expansion - Phase 3, Week 3)  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 30 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Read:** `docs/plans/philosophy_implementation/DOORS.md` - **MANDATORY** - Core philosophy
5. ✅ **Read:** `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - **MANDATORY** - Philosophy alignment
6. ✅ **Verify:** Week 29 (Phase 3, Week 2) is COMPLETE - Clubs/Communities done

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
2. **Phase 6 Week 30 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document exists):**

- ❌ **NO new tasks can be added** to Phase 6 Week 30
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 30 Overview**

**Duration:** Week 30 (5 days)  
**Focus:** Expertise Expansion (Phase 3, Week 3)  
**Priority:** P1 - Core Functionality  
**Philosophy:** Clubs/communities can expand naturally, leaders gain expertise through expansion

**What Doors Does This Open?**
- **Expansion Doors:** Clubs can expand geographically (locality → city → state → nation → globe → universe)
- **Expertise Doors:** Club leaders gain expertise in all localities where club hosts events
- **Coverage Doors:** 75% coverage rule enables expertise gain at each geographic level
- **Recognition Doors:** Leadership role grants expert status
- **Growth Doors:** Natural geographic expansion through community growth

**When Are Users Ready?**
- After clubs/communities are established (Week 29)
- When clubs start hosting events in multiple localities
- When 75% coverage thresholds are met
- System recognizes successful geographic expansion

**Why Critical:**
- Enables natural geographic expansion (no artificial barriers)
- Recognizes club leaders as experts (leadership expertise)
- Implements 75% coverage rule (fair expertise gain thresholds)
- Creates path for global expansion (locality → universe)

**Dependencies:**
- ✅ Week 29 (Phase 3, Week 2) COMPLETE - Clubs/Communities done
- ✅ CommunityService exists (from Week 29)
- ✅ ClubService exists (from Week 29)
- ✅ Club model exists (from Week 29)
- ✅ ExpertiseCalculationService exists (from Phase 1)

---

## 📋 **Agent Assignments**

### **Agent 1: Backend & Integration**
**Focus:** GeographicExpansionService, ExpansionExpertiseGainService, GeographicExpansion Model, Club Leader Expertise Recognition

### **Agent 2: Frontend & UX**
**Focus:** Expertise Coverage Map Visualization, Expansion Timeline, Coverage Metrics UI

### **Agent 3: Models & Testing**
**Focus:** GeographicExpansion Model, Tests, Documentation

---

## 📅 **Week 30: Expertise Expansion**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start  
**Focus:** Geographic Expansion Services, Expertise Gain Logic

**Tasks:**

#### **Day 1-2: GeographicExpansion Model & GeographicExpansionService**
- [ ] **Create `lib/core/models/geographic_expansion.dart`**
  - [ ] Model for tracking expansion from original locality
  - [ ] Store original locality
  - [ ] Track expanded localities (list of localities where club/community is active)
  - [ ] Track expanded cities (list of cities where club/community is active)
  - [ ] Track expanded states (list of states where club/community is active)
  - [ ] Track expanded nations (list of nations where club/community is active)
  - [ ] Coverage percentages by geographic level:
    - [ ] `localityCoverage` - Map of locality → coverage percentage
    - [ ] `cityCoverage` - Map of city → coverage percentage
    - [ ] `stateCoverage` - Map of state → coverage percentage
    - [ ] `nationCoverage` - Map of nation → coverage percentage
  - [ ] Track coverage methods:
    - [ ] `commutePatterns` - People commuting to events (locality → list of source localities)
    - [ ] `eventHostingLocations` - Events hosted in each locality
  - [ ] Expansion timeline:
    - [ ] `expansionHistory` - List of expansion events (when, where, how)
    - [ ] `firstExpansionAt` - When first expansion occurred
    - [ ] `lastExpansionAt` - When last expansion occurred
  - [ ] Follow existing model patterns (Equatable, JSON, CopyWith, helpers)

- [ ] **Create `lib/core/services/geographic_expansion_service.dart`**
  - [ ] Track event expansion from original locality:
    - [ ] `trackEventExpansion()` - Track when event is hosted in new locality
    - [ ] `trackCommutePattern()` - Track when people commute to events
    - [ ] `updateExpansionHistory()` - Update expansion timeline
  - [ ] Measure coverage (commute patterns OR event hosting):
    - [ ] `calculateLocalityCoverage()` - Calculate coverage for a locality
    - [ ] `calculateCityCoverage()` - Calculate coverage for a city (75% threshold)
    - [ ] `calculateStateCoverage()` - Calculate coverage for a state (75% threshold)
    - [ ] `calculateNationCoverage()` - Calculate coverage for a nation (75% threshold)
    - [ ] `calculateGlobalCoverage()` - Calculate coverage globally (75% threshold)
  - [ ] Calculate 75% thresholds for each geographic level:
    - [ ] `hasReachedLocalityThreshold()` - Check if locality threshold reached
    - [ ] `hasReachedCityThreshold()` - Check if 75% city coverage reached
    - [ ] `hasReachedStateThreshold()` - Check if 75% state coverage reached
    - [ ] `hasReachedNationThreshold()` - Check if 75% nation coverage reached
    - [ ] `hasReachedGlobalThreshold()` - Check if 75% global coverage reached
  - [ ] Expansion management:
    - [ ] `getExpansionByClub()` - Get expansion for a club
    - [ ] `getExpansionByCommunity()` - Get expansion for a community
    - [ ] `updateExpansion()` - Update expansion data
    - [ ] `getExpansionHistory()` - Get expansion timeline

#### **Day 3-4: ExpansionExpertiseGainService & Club Leader Expertise**
- [ ] **Create `lib/core/services/expansion_expertise_gain_service.dart`**
  - [ ] Implement expertise gain logic from expansion:
    - [ ] `checkAndGrantLocalityExpertise()` - Grant local expertise for neighboring locality expansion
    - [ ] `checkAndGrantCityExpertise()` - Grant city expertise when 75% city coverage reached
    - [ ] `checkAndGrantStateExpertise()` - Grant state expertise when 75% state coverage reached
    - [ ] `checkAndGrantNationExpertise()` - Grant nation expertise when 75% nation coverage reached
    - [ ] `checkAndGrantGlobalExpertise()` - Grant global expertise when 75% global coverage reached
    - [ ] `checkAndGrantUniversalExpertise()` - Grant universal expertise when 75% universe coverage reached
  - [ ] Update expertise when expansion thresholds met:
    - [ ] `grantExpertiseFromExpansion()` - Main method to check and grant expertise
    - [ ] `updateUserExpertise()` - Update user's expertise map
    - [ ] `notifyExpertiseGain()` - Notify user of expertise gain
  - [ ] Integration with ExpertiseCalculationService:
    - [ ] Use ExpertiseCalculationService to update expertise
    - [ ] Preserve existing expertise
    - [ ] Add new expertise levels based on expansion

- [ ] **Modify `lib/core/services/club_service.dart`**
  - [ ] Add club leader expertise recognition:
    - [ ] `grantLeaderExpertise()` - Grant expertise to club leaders in all localities where club hosts events
    - [ ] `updateLeaderExpertise()` - Update leader expertise when club expands
    - [ ] `getLeaderExpertise()` - Get expertise for a club leader
  - [ ] Integration with ExpansionExpertiseGainService:
    - [ ] Call ExpansionExpertiseGainService when club expands
    - [ ] Grant expertise to leaders automatically

- [ ] **Modify `lib/core/services/expertise_calculation_service.dart`**
  - [ ] Add expansion-based expertise calculation:
    - [ ] `calculateExpertiseFromExpansion()` - Calculate expertise from geographic expansion
    - [ ] Integration with ExpansionExpertiseGainService
    - [ ] Preserve existing expertise calculation logic

#### **Day 5: Integration & Updates**
- [ ] **Update `lib/core/models/club.dart`**
  - [ ] Add expansion tracking fields (if not already present):
    - [ ] `geographicExpansion` - GeographicExpansion object
    - [ ] `expansionLocalities` - Already exists, verify integration
    - [ ] `expansionCities` - Already exists, verify integration
    - [ ] `coveragePercentage` - Already exists, verify integration
  - [ ] Add leader expertise tracking:
    - [ ] `leaderExpertise` - Map of leader ID → expertise map

- [ ] **Update `lib/core/services/community_service.dart`**
  - [ ] Integration with GeographicExpansionService:
    - [ ] Track expansion when community hosts events in new localities
    - [ ] Update expansion history

**Deliverables:**
- ✅ GeographicExpansion model created
- ✅ GeographicExpansionService created
- ✅ Expansion tracking working (commute patterns, event hosting)
- ✅ 75% coverage calculation working
- ✅ ExpansionExpertiseGainService created
- ✅ Expertise gain from expansion working
- ✅ Club leader expertise recognition working
- ✅ Integration with ExpertiseCalculationService
- ✅ Zero linter errors
- ✅ All services follow existing patterns

**Files to Create:**
- `lib/core/models/geographic_expansion.dart`
- `lib/core/services/geographic_expansion_service.dart`
- `lib/core/services/expansion_expertise_gain_service.dart`

**Files to Modify:**
- `lib/core/services/club_service.dart` (leader expertise recognition)
- `lib/core/services/expertise_calculation_service.dart` (expansion expertise)
- `lib/core/models/club.dart` (expansion tracking, leader expertise)
- `lib/core/services/community_service.dart` (expansion tracking)

---

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start  
**Focus:** Expertise Coverage Map Visualization, Expansion Timeline UI

**Tasks:**

#### **Day 1-3: Expertise Coverage Map Visualization**
- [ ] **Update `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`**
  - [ ] Add map view (prepared in Week 29, now implement):
    - [ ] Interactive map showing coverage by locality
    - [ ] Color-coded by expertise level (local, city, state, national, global, universal)
    - [ ] Show coverage percentage for each geographic level
    - [ ] Show 75% threshold indicators
  - [ ] Enhanced coverage metrics display:
    - [ ] Locality coverage (list of all localities with coverage percentages)
    - [ ] City coverage (75% threshold indicator, coverage percentage)
    - [ ] State coverage (75% threshold indicator, coverage percentage)
    - [ ] National coverage (75% threshold indicator, coverage percentage)
    - [ ] Global coverage (75% threshold indicator, coverage percentage)
    - [ ] Universal status (if achieved)
  - [ ] Use AppColors/AppTheme (100% adherence)
  - [ ] Follow existing widget patterns

- [ ] **Create `lib/presentation/widgets/clubs/expansion_timeline_widget.dart`**
  - [ ] Display expansion timeline:
    - [ ] Shows how community/club expanded from original locality
    - [ ] Timeline of expansion events (when, where, how)
    - [ ] Visual representation of expansion path
    - [ ] Show coverage milestones (75% thresholds reached)
  - [ ] Expansion details:
    - [ ] Events hosted in each locality
    - [ ] Commute patterns (people traveling to events)
    - [ ] Coverage percentages over time
  - [ ] Use AppColors/AppTheme (100% adherence)
  - [ ] Follow existing widget patterns

#### **Day 4-5: Club/Community Page Updates**
- [ ] **Update `lib/presentation/pages/clubs/club_page.dart`**
  - [ ] Add expertise coverage map visualization:
    - [ ] Integrate updated ExpertiseCoverageWidget
    - [ ] Show map view of coverage
    - [ ] Show coverage metrics
  - [ ] Add expansion timeline:
    - [ ] Integrate ExpansionTimelineWidget
    - [ ] Show expansion history
  - [ ] Add leader expertise display:
    - [ ] Show expertise levels of club leaders
    - [ ] Show expertise gained through club expansion
    - [ ] Geographic expertise map for each leader
  - [ ] Use AppColors/AppTheme (100% adherence)

- [ ] **Update `lib/presentation/pages/communities/community_page.dart`**
  - [ ] Add expansion tracking display:
    - [ ] Show current localities where community is active
    - [ ] Show expansion progress
    - [ ] Show coverage percentages (if available)

**Deliverables:**
- ✅ ExpertiseCoverageWidget updated with map view
- ✅ ExpansionTimelineWidget created
- ✅ ClubPage updated with map visualization and timeline
- ✅ CommunityPage updated with expansion tracking
- ✅ Zero linter errors
- ✅ 100% AppColors/AppTheme adherence
- ✅ Responsive and accessible

**Files to Create:**
- `lib/presentation/widgets/clubs/expansion_timeline_widget.dart`

**Files to Modify:**
- `lib/presentation/widgets/clubs/expertise_coverage_widget.dart` (add map view)
- `lib/presentation/pages/clubs/club_page.dart` (add map and timeline)
- `lib/presentation/pages/communities/community_page.dart` (add expansion tracking)

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start  
**Focus:** GeographicExpansion Model, Tests, Documentation

**Tasks:**

#### **Day 1-2: Review Models (if needed)**
- [ ] **Review GeographicExpansion Model** (created by Agent 1)
  - [ ] Verify model structure
  - [ ] Verify expansion tracking
  - [ ] Verify coverage calculation
  - [ ] Create additional models if needed

#### **Day 3-5: Tests & Documentation**
- [ ] **Create `test/unit/models/geographic_expansion_test.dart`**
  - [ ] Test model creation
  - [ ] Test expansion tracking
  - [ ] Test coverage calculation
  - [ ] Test expansion history
  - [ ] Test JSON serialization/deserialization

- [ ] **Create `test/unit/services/geographic_expansion_service_test.dart`**
  - [ ] Test event expansion tracking
  - [ ] Test commute pattern tracking
  - [ ] Test coverage calculation (locality, city, state, nation, global)
  - [ ] Test 75% threshold checking
  - [ ] Test expansion management

- [ ] **Create `test/unit/services/expansion_expertise_gain_service_test.dart`**
  - [ ] Test expertise gain from expansion
  - [ ] Test 75% threshold expertise grants
  - [ ] Test locality expertise gain
  - [ ] Test city expertise gain
  - [ ] Test state expertise gain
  - [ ] Test nation expertise gain
  - [ ] Test global expertise gain
  - [ ] Test universal expertise gain
  - [ ] Test integration with ExpertiseCalculationService

- [ ] **Create Integration Tests**
  - [ ] Test end-to-end expansion flow (event → expansion → expertise gain)
  - [ ] Test club leader expertise recognition
  - [ ] Test 75% coverage rule
  - [ ] Test expansion timeline

- [ ] **Documentation**
  - [ ] Document GeographicExpansion model
  - [ ] Document GeographicExpansionService
  - [ ] Document ExpansionExpertiseGainService
  - [ ] Document 75% coverage rule
  - [ ] Document club leader expertise recognition
  - [ ] Update system documentation

**Deliverables:**
- ✅ GeographicExpansion model tests created
- ✅ GeographicExpansionService tests created
- ✅ ExpansionExpertiseGainService tests created
- ✅ Integration tests created
- ✅ Documentation complete
- ✅ All tests pass
- ✅ Test coverage > 90%

**Files to Create:**
- `test/unit/models/geographic_expansion_test.dart`
- `test/unit/services/geographic_expansion_service_test.dart`
- `test/unit/services/expansion_expertise_gain_service_test.dart`
- `test/integration/expansion_expertise_gain_integration_test.dart`

**Files to Review:**
- `lib/core/models/geographic_expansion.dart` (created by Agent 1)
- `lib/core/services/geographic_expansion_service.dart` (created by Agent 1)
- `lib/core/services/expansion_expertise_gain_service.dart` (created by Agent 1)

---

## 🎯 **Success Criteria**

### **GeographicExpansionService:**
- [ ] Expansion tracking working (commute patterns, event hosting)
- [ ] Coverage calculation working (locality, city, state, nation, global)
- [ ] 75% threshold checking working
- [ ] Expansion history tracking working

### **ExpansionExpertiseGainService:**
- [ ] Expertise gain from expansion working
- [ ] 75% threshold expertise grants working
- [ ] Integration with ExpertiseCalculationService working
- [ ] Expertise updates working

### **Club Leader Expertise:**
- [ ] Club leaders gain expertise in all localities where club hosts events
- [ ] Leadership role grants expert status
- [ ] Leader expertise updates when club expands

### **UI:**
- [ ] ExpertiseCoverageWidget updated with map view
- [ ] ExpansionTimelineWidget created
- [ ] ClubPage updated with map and timeline
- [ ] 100% AppColors/AppTheme adherence

---

## 📊 **Estimated Impact**

- **New Models:** 1 model (GeographicExpansion)
- **New Services:** 2 services (GeographicExpansionService, ExpansionExpertiseGainService)
- **New UI:** 1 widget (ExpansionTimelineWidget)
- **Modified Services:** 3 services (ClubService, ExpertiseCalculationService, CommunityService)
- **Modified Models:** 1 model (Club)
- **Modified UI:** 3 components (ExpertiseCoverageWidget, ClubPage, CommunityPage)
- **New Tests:** 4+ test files
- **Documentation:** Service documentation, system documentation

---

## 🚧 **Dependencies**

- ✅ Week 29 (Phase 3, Week 2) COMPLETE - Clubs/Communities done
- ✅ CommunityService exists
- ✅ ClubService exists
- ✅ Club model exists
- ✅ ExpertiseCalculationService exists

---

## 📝 **Notes**

- **75% Coverage Rule:** Expertise gain requires 75% coverage at each geographic level (city, state, nation, global, universal)
- **Two Coverage Methods:** Commute patterns (people traveling to events) OR event hosting (events hosted in localities)
- **Club Leader Expertise:** Leaders gain expertise in all localities where club hosts events
- **Natural Expansion:** Expansion happens organically through community growth, not forced

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Start

