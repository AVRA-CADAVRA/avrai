# Local Expert System Redesign - Implementation Plan

**Created:** November 23, 2025  
**Status:** 📋 Implementation Plan - Awaiting Approval  
**Purpose:** Comprehensive implementation plan for local expert system redesign  
**Requirements:** `LOCAL_EXPERT_SYSTEM_REDESIGN.md`

---

## 🚪 **Philosophy: Doors, Not Badges**

**This implementation follows SPOTS philosophy: "Doors, not badges"**

### **What Doors Does This Open?**

1. **Local Community Doors:**
   - Local experts can host events in their locality (house parties, neighborhood gatherings)
   - Users can find likeminded people in their neighborhood
   - Small communities can thrive without needing city-wide reach

2. **Exploration Doors:**
   - Users can explore neighboring localities through events
   - Cross-locality community building
   - Discovery of new places/spaces/spots through community events

3. **Community Building Doors:**
   - Events can create communities
   - Communities can become clubs with structure
   - Clubs can expand naturally, opening doors in new localities

4. **Expertise Recognition Doors:**
   - Multiple paths to expertise (not just city-level)
   - Local experts recognized for neighborhood knowledge
   - Club leaders recognized for community building

5. **AI Learning Doors:**
   - Golden experts shape neighborhood character
   - AI learns from locality-specific behavior
   - System reflects actual community values

### **When Are Users Ready?**

- **Local Experts:** Ready when they've built community in their locality
- **Community Events:** Ready immediately (no expertise required)
- **Clubs:** Ready when events create natural communities
- **Expansion:** Ready when community grows organically

### **Is This Being a Good Key?**

- ✅ Helps users find likeminded people (matching, not ranking)
- ✅ Respects user autonomy (they choose which events to attend)
- ✅ Opens doors naturally (not forced expansion)
- ✅ Recognizes authentic contributions (not gamification)

### **Is the AI Learning with the User?**

- ✅ AI learns locality-specific values
- ✅ AI tracks user movement patterns
- ✅ AI adapts thresholds based on community behavior
- ✅ Golden experts influence AI personality

---

## 🎯 **Overview**

**Total Timeline:** 9.5-13.5 weeks (depending on parallel work)
  - Added 3 days for Phase 1.5 (Business-Expert Matching Updates)  
**Priority:** P1 - Core Functionality (enables local community building)  
**Dependencies:** Existing expertise system, event system

**⚠️ CRITICAL: TOTAL IMPLEMENTATION REQUIREMENT**

**This implementation MUST be TOTAL and UNIVERSAL across the entire app. Every part of the expertise system must be updated to work exactly as specified in the requirements document. No exceptions.**

**What "Total Implementation" Means:**
- ✅ **ALL** code references to City level as event hosting requirement → Updated to Local
- ✅ **ALL** services checking expertise levels → Updated to new system
- ✅ **ALL** UI components showing requirements → Updated messaging
- ✅ **ALL** tests checking City level → Updated to Local (or removed if City is no longer minimum)
- ✅ **ALL** documentation → Updated to reflect new system
- ✅ **ALL** business logic → Updated to new geographic hierarchy
- ✅ **ALL** feature gates → Updated to new expertise requirements
- ✅ **NO** City level as minimum for ANY feature (unless explicitly required by design)

**Breakdown:**
- **Phase 0:** Codebase & Documentation Updates (1.5 weeks) - **MUST COMPLETE FIRST**
  - Expanded to include error messages, backward compatibility, and migration strategy
- **Phase 1:** Core Local Expert System (2 weeks)
- **Phase 1.5:** Business-Expert Matching Updates (3 days) - **CRITICAL**
  - Ensures local experts aren't excluded by businesses
  - Integrates vibe-first matching
- **Phase 2:** Event Discovery & Matching (2 weeks)
- **Phase 3:** Community Events & Clubs (3 weeks)
- **Phase 4:** UI/UX & Golden Expert (2 weeks)
- **Phase 5:** Neighborhood Boundaries (1 week)

**Key Changes:**
1. Local experts can host events (currently requires City level)
2. Geographic hierarchy enforcement (local → city → state → national)
3. Dynamic locality-specific thresholds
4. Community events (non-experts can host)
5. Events → Communities → Clubs system
6. 75% expansion rule for expertise gain
7. Golden expert AI influence
8. Reputation/matching system (locality-specific)

---

## 📅 **Implementation Phases**

### **PHASE 0: Codebase & Documentation Updates (Week 0)**

**Priority:** P0 - Critical (must be done before new features)  
**Status:** 📋 Planned  
**Timeline:** 1 week

#### **Week 0: Update Existing Codebase & Documentation**

**Goal:** Update all existing code and documentation that references City level as event hosting requirement

**Tasks:**

1. **Core Model Updates** (1 day)
   - Update `UnifiedUser.canHostEvents()` (line 298) - Change from City to Local level
   - Update `ExpertisePin.unlocksEventHosting()` (line 85) - Change from City to Local level
   - Update all expertise level checks in models
   - Review `BusinessAccount.minExpertLevel` - Ensure it doesn't default to City

2. **Service Updates** (3 days - expanded due to multiple services + business matching)
   - Update `ExpertiseEventService.createEvent()` (line 15 comment, line 36-37) - Change validation from City to Local
   - Update `ExpertiseService.getUnlockedFeatures()` (line 229) - Change event_hosting unlock from City to Local
   - Update `ExpertSearchService.getTopExperts()` (line 84) - Remove City minimum, include Local experts
   - Update `ExpertiseMatchingService._calculateComplementaryScore()` (lines 262-263) - Change "meaningful expertise" check from City to Local
   - Update `PartnershipService.checkPartnershipEligibility()` (line 347) - Update event hosting check
   - Review `ExpertiseCommunityService` - Ensure minLevel doesn't default to City
   - **CRITICAL:** Update `BusinessExpertMatchingService` (lines 173-177, 420-427) - Remove level-based filtering, add vibe-first matching
   - **CRITICAL:** Integrate vibe matching into business-expert matching (prioritize vibe over level)
   - **CRITICAL:** Update AI prompts to emphasize vibe as PRIMARY factor
   - Update all service comments mentioning City level requirements

3. **UI Component Updates** (2 days)
   - Update `create_event_page.dart` (lines 20, 94, 96, 109, 328, 330, 334) - Change City level checks to Local level
   - Update `event_review_page.dart` (line 342) - Change "Required: City level+" to "Required: Local level+"
   - Update `event_hosting_unlock_widget.dart` (lines 11, 100, 315, 345, 397, 552) - Change unlock logic and messaging
   - Update `expertise_display_widget.dart` (lines 170-177) - Include Local level in display (currently filters to City+)
   - Update any other UI components showing City level requirements
   - Review all UI text/messages mentioning City level

4. **Error Messages & User-Facing Text** (0.5 days)
   - Update all exception messages mentioning City level
   - Update all error messages in UI
   - Update all SnackBar messages
   - Update all code comments (documentation strings)
   - Files:
     - `lib/core/services/expertise_event_service.dart` (line 37)
     - `lib/presentation/pages/events/create_event_page.dart` (lines 96, 330, 334)
     - All other error/exception messages

5. **Additional System Components** (1 day)
   - Review and update AI prompts (if they mention City level)
   - Review constants/config files for expertise values
   - Review database schema/migrations for constraints
   - Review onboarding/tutorial content
   - Review route guards/navigation logic
   - Review analytics events
   - Review feature flags
   - **CRITICAL:** Plan backward compatibility strategy
   - **CRITICAL:** Plan data migration strategy for existing users/events

6. **Test Updates** (3 days - expanded due to large number of test files)
   - Update all integration tests checking for City level
   - Update test helpers (`IntegrationTestHelpers.createUserWithCityExpertise()` → add Local version)
   - Update test fixtures that create users with City expertise
   - Update all test assertions checking for City level
   
   **Integration Tests (8 files):**
   - `test/integration/expertise_event_integration_test.dart` - 18 City level references
   - `test/integration/expertise_model_relationships_test.dart` - 7 City level references
   - `test/integration/expertise_partnership_integration_test.dart` - 8 City level references
   - `test/integration/expertise_flow_integration_test.dart` - 3 City level references
   - `test/integration/event_hosting_integration_test.dart` - 10 City level references
   - `test/integration/event_discovery_integration_test.dart` - 4 City level references
   - `test/integration/payment_flow_integration_test.dart` - 1 City level reference
   - `test/integration/partnership_flow_integration_test.dart` - 1 City level reference
   - `test/integration/end_to_end_integration_test.dart` - 2 City level references
   
   **Unit Tests - Services (6 files):**
   - `test/unit/services/expertise_event_service_test.dart` - 2 City level tests (line 31, 52)
   - `test/unit/services/expertise_service_test.dart` - 9 City level references
   - `test/unit/services/expertise_community_service_test.dart` - 3 City level references
   - `test/unit/services/expert_search_service_test.dart` - 3 City level references
   - `test/unit/services/partnership_service_test.dart` - 1 City level reference
   - `test/unit/services/mentorship_service_test.dart` - 1 City level reference
   
   **Unit Tests - Models (4 files):**
   - `test/unit/models/expertise_level_test.dart` - OK (enum tests, no logic changes needed)
   - `test/unit/models/expertise_progress_test.dart` - 19 City level references (mostly as nextLevel - OK)
   - `test/unit/models/expertise_pin_test.dart` - 17 City level references (mostly examples - OK)
   - `test/unit/models/expertise_community_test.dart` - 3 City level references (minLevel checks)
   
   **Widget Tests (3 files):**
   - `test/widget/widgets/expertise/expertise_progress_widget_test.dart` - 6 City level references (as nextLevel - OK)
   - `test/widget/widgets/expertise/expertise_pin_widget_test.dart` - 3 City level references (examples - OK)
   - `test/widget/widgets/expertise/expertise_badge_widget_test.dart` - 3 City level references (examples - OK)
   
   **Test Helpers & Fixtures (2 files - CRITICAL):**
   - `test/helpers/integration_test_helpers.dart` - `createUserWithCityExpertise()` function (line 365)
   - `test/fixtures/integration_test_fixtures.dart` - City level references in fixtures
   
   **Total Test Files to Update:** 28 expertise-specific files (134 City level references found)
   
   **Update Strategy:**
   - **Critical Updates (Must Change):** 
     - Integration tests checking City level requirement for event hosting
     - Service tests validating City level for event creation
     - Test helpers (`createUserWithCityExpertise` - rename or update logic)
     - Tests asserting "City level required" → Change to "Local level required"
   
   - **OK as-is (No Changes Needed):**
     - Model/widget tests using City as examples (e.g., `ExpertiseLevel.city` in test data)
     - Tests using City as `nextLevel` (progression tests - City is still next after Local)
     - Enum tests (`expertise_level_test.dart` - just testing enum values)
   
   - **Review Needed (May Need Updates):**
     - Tests checking for City level as minimum requirement for other features
     - Tests with City level in test names/comments (update documentation)
     - Tests using City level in assertions (may need to change expected values)
   
   **Detailed Test File Breakdown:**
   
   **Integration Tests (9 files - HIGH PRIORITY):**
   1. `test/integration/expertise_event_integration_test.dart` - 18 references
      - Tests: "should require City level expertise to host events"
      - Tests: "should prevent event hosting without City level expertise"
      - **Action:** Change to Local level
   
   2. `test/integration/expertise_model_relationships_test.dart` - 7 references
      - Uses `createUserWithCityExpertise()` multiple times
      - **Action:** Update helper calls or change to Local
   
   3. `test/integration/expertise_partnership_integration_test.dart` - 8 references
      - Tests: "should require City level expertise to create partnership"
      - **Action:** Change to Local level
   
   4. `test/integration/expertise_flow_integration_test.dart` - 3 references
      - Checks `ExpertiseLevel.city` for event hosting
      - **Action:** Change to Local level
   
   5. `test/integration/event_hosting_integration_test.dart` - 10 references
      - Tests: "should create event when host has City level expertise"
      - Tests: "should fail to create event when host lacks City level expertise"
      - **Action:** Change to Local level
   
   6. `test/integration/event_discovery_integration_test.dart` - 4 references
      - Uses `createUserWithCityExpertise()`
      - **Action:** Update helper calls
   
   7. `test/integration/payment_flow_integration_test.dart` - 1 reference
      - Uses `createUserWithCityExpertise()`
      - **Action:** Update helper call
   
   8. `test/integration/partnership_flow_integration_test.dart` - 1 reference
      - Comment: "Add City-level expertise to enable event hosting"
      - **Action:** Update comment
   
   9. `test/integration/end_to_end_integration_test.dart` - 2 references
      - Checks for City level progression
      - **Action:** Review - may be OK (progression test)
   
   **Unit Tests - Services (6 files - HIGH PRIORITY):**
   1. `test/unit/services/expertise_event_service_test.dart` - 2 references
      - Test: "should create event when host has city level expertise"
      - Test: "should throw exception when host lacks city level expertise"
      - **Action:** Change to Local level
   
   2. `test/unit/services/expertise_service_test.dart` - 9 references
      - Tests City level calculation (3+ lists, 25+ reviews)
      - **Action:** Review - may keep City level tests but add Local level tests
   
   3. `test/unit/services/expertise_community_service_test.dart` - 3 references
      - Tests with `minLevel: ExpertiseLevel.city`
      - **Action:** Review - may need to change minimum level
   
   4. `test/unit/services/expert_search_service_test.dart` - 3 references
      - Tests with `minLevel: ExpertiseLevel.city`
      - **Action:** Review - may need to change minimum level
   
   5. `test/unit/services/partnership_service_test.dart` - 1 reference
      - Comment: "Create test user with City-level expertise"
      - **Action:** Update comment
   
   6. `test/unit/services/mentorship_service_test.dart` - 1 reference
      - Comment: "Create mentor with city level expertise"
      - **Action:** Update comment
   
   **Unit Tests - Models (4 files - LOW PRIORITY):**
   1. `test/unit/models/expertise_level_test.dart` - 17 references
      - **Action:** OK - Just testing enum values, no logic changes needed
   
   2. `test/unit/models/expertise_progress_test.dart` - 19 references
      - Uses City as `nextLevel` (progression)
      - **Action:** OK - City is still next level after Local
   
   3. `test/unit/models/expertise_pin_test.dart` - 17 references
      - Uses City level in examples
      - **Action:** OK - Just test data examples
   
   4. `test/unit/models/expertise_community_test.dart` - 3 references
      - Tests with `minLevel: ExpertiseLevel.city`
      - **Action:** Review - may need to change minimum level
   
   **Widget Tests (3 files - LOW PRIORITY):**
   1. `test/widget/widgets/expertise/expertise_progress_widget_test.dart` - 6 references
      - Uses City as `nextLevel`
      - **Action:** OK - City is still next level
   
   2. `test/widget/widgets/expertise/expertise_pin_widget_test.dart` - 3 references
      - Uses City level in examples
      - **Action:** OK - Just test data
   
   3. `test/widget/widgets/expertise/expertise_badge_widget_test.dart` - 3 references
      - Uses City level in examples
      - **Action:** OK - Just test data
   
   **Test Helpers & Fixtures (2 files - CRITICAL):**
   1. `test/helpers/integration_test_helpers.dart` - 9 references
      - Function: `createUserWithCityExpertise()` (line 365)
      - Function: `createUserWithoutHosting()` (line 398) - creates Local level
      - Function: `createExpertUser()` (line 412) - creates City level+
      - **Action:** 
        - Rename `createUserWithCityExpertise()` to `createUserWithLocalExpertise()` OR
        - Update function to create Local level (but keep name for backward compatibility)
        - Update `createUserWithoutHosting()` comment (says "below City level" - now Local can host)
        - Review `createExpertUser()` - may need update
   
   2. `test/fixtures/integration_test_fixtures.dart` - 4 references
      - Comments and test data with City level
      - **Action:** Update comments and test data

5. **Documentation Updates** (1 day)
   - Update `docs/USER_TO_EXPERT_JOURNEY.md` - Change "City unlocks event hosting" to "Local unlocks event hosting"
   - Update all plan documents referencing City level requirements
   - Update agent reports and status trackers
   - Update any user-facing documentation

**Deliverables:**
- ✅ All code updated to use Local level for event hosting
- ✅ All tests updated and passing
- ✅ All documentation updated
- ✅ No references to "City level required for event hosting" remain

**Files to Update:**

**Core Models:**
- `lib/core/models/unified_user.dart` (canHostEvents method - line 298)
- `lib/core/models/expertise_pin.dart` (unlocksEventHosting method - line 85)
- `lib/core/models/business_account.dart` (review minExpertLevel - ensure no City default)

**Services (7 files):**
- `lib/core/services/expertise_event_service.dart` (createEvent validation - lines 15, 36-37)
- `lib/core/services/expertise_service.dart` (getUnlockedFeatures - line 229)
- `lib/core/services/expert_search_service.dart` (getTopExperts - line 84)
- `lib/core/services/expertise_matching_service.dart` (_calculateComplementaryScore - lines 262-263)
- `lib/core/services/partnership_service.dart` (eligibility check - line 347)
- `lib/core/services/expertise_community_service.dart` (review minLevel usage)
- `lib/core/services/business_expert_matching_service.dart` (review for City level minimums)

**UI Components (4 files):**
- `lib/presentation/pages/events/create_event_page.dart` (lines 20, 94, 96, 109, 328, 330, 334)
- `lib/presentation/pages/events/event_review_page.dart` (line 342 - "Required: City level+")
- `lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart` (lines 11, 100, 315, 345, 397, 552)
- `lib/presentation/widgets/expertise/expertise_display_widget.dart` (lines 170-177 - filter includes Local, currently shows City+ only)

**Tests (80+ files with City level references):**
- `test/integration/expertise_event_integration_test.dart`
- `test/integration/expertise_model_relationships_test.dart`
- `test/integration/expertise_partnership_integration_test.dart`
- `test/integration/expertise_flow_integration_test.dart`
- `test/integration/event_hosting_integration_test.dart`
- `test/helpers/integration_test_helpers.dart` (createUserWithCityExpertise)
- `test/fixtures/integration_test_fixtures.dart`
- All other test files with City level references

**Documentation (20+ files):**
- `docs/USER_TO_EXPERT_JOURNEY.md` (lines 44, 74, 81-86 - "City unlocks event hosting")
- `docs/MASTER_PLAN.md` (if references City level)
- `docs/agents/status/status_tracker.md`
- `docs/plans/dynamic_expertise/DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md` (line 1806 - "City level = Can host events")
- `docs/plans/easy_event_hosting/EASY_EVENT_HOSTING_EXPLANATION.md`
- All plan documents in `docs/plans/` referencing City level requirements
- All agent reports mentioning City level
- All code comments mentioning City level requirements

**Estimated Impact:**
- **Code Files:** ~20 files (models, services, UI components)
- **Test Files:** 28 expertise-specific files (134 City level references found)
- **Documentation Files:** ~25+ files (plans, reports, user docs)
- **Total Updates:** ~73+ files (comprehensive coverage)

**Critical Update Locations:**
- **7 Core Services** with City level checks
- **4 UI Components** showing City level requirements
- **2 Core Models** with City level logic
- **9 Integration Tests** with City level assertions
- **6 Unit Service Tests** with City level checks
- **2 Test Helpers** creating City level users
- **25+ Documentation Files** with City level references

**Doors Opened:** Existing system updated to support Local expert event hosting

**⚠️ CRITICAL: Ensure City Level is NOT Minimum for ANY Feature**

**Update Strategy:**
- **Event Hosting:** City → Local (primary change)
- **Other Features:** Review ALL features that use City as minimum
  - If feature should require Local → Update to Local
  - If feature should require City → Keep City (but verify this is correct)
  - If feature should require higher level → Keep higher level
  - **Goal:** No feature should have City as minimum unless explicitly designed that way

**Services to Review for City Minimum:**
- `ExpertSearchService.getTopExperts()` - Currently uses City as minimum
  - **Decision:** Remove City minimum, include Local experts, rank by vibe + expertise
- `ExpertiseMatchingService._calculateComplementaryScore()` - Checks City for "meaningful expertise"
  - **Decision:** Should this be Local? Or removed?
- `ExpertiseCommunityService` - Uses minLevel parameter
  - **Decision:** Review all places that set minLevel to City - should they be Local?
- **CRITICAL:** `BusinessExpertMatchingService` - Currently filters by `minExpertLevel` (lines 173-177)
  - **Decision:** Remove level-based filtering, make level a preference boost only
  - **Decision:** Integrate vibe matching as PRIMARY factor (50% weight)
  - **Decision:** Make location a preference boost, not filter
  - **Decision:** Update AI prompts to emphasize vibe over level
- Any other services with City level minimums

**Test Update Strategy:**
- **Remove City as Minimum:** All tests checking City level as minimum for event hosting → Change to Local
- **Keep City for Other Features:** Tests checking City level for other features (expert validation, curation) → Keep City
- **Review All Assertions:** Ensure no test assumes City is minimum for general features

---

### **PHASE 1: Core Local Expert System (Weeks 1-2)**

**Priority:** P1 - Core Functionality  
**Status:** 📋 Planned  
**Timeline:** 2 weeks

#### **Week 1: Local Expert Event Hosting**

**Goal:** Enable local experts to host events in their locality

**Tasks:**

1. **Geographic Scope Enforcement** (3 days)
   - Create `GeographicScopeService` to validate event hosting scope
   - Implement hierarchy: Local → City → State → National
   - Add locality validation (local experts can only host in their locality)
   - Add city validation (city experts can host in all localities in their city)
   - Update event creation to check geographic scope
   - **Note:** Basic level change (City → Local) already done in Phase 0

2. **Geographic Scope Enforcement** (3 days)
   - Create `GeographicScopeService` to validate event hosting scope
   - Implement hierarchy: Local → City → State → National
   - Add locality validation (local experts can only host in their locality)
   - Add city validation (city experts can host in all localities in their city)
   - Update event creation to check geographic scope

3. **Large City Detection** (2 days)
   - Create `LargeCityDetectionService`
   - Detect cities based on: geographic size, population, documented neighborhoods
   - Store large city configuration
   - Allow neighborhood-level localities for large cities

**Deliverables:**
- ✅ Local experts can host events in their locality
- ✅ Geographic hierarchy enforced
- ✅ Large city detection working
- ✅ Tests for geographic scope validation

**Doors Opened:** Local experts can host events, enabling neighborhood community building

**Files to Create/Modify:**
- `lib/core/services/geographic_scope_service.dart` (NEW)
- `lib/core/services/large_city_detection_service.dart` (NEW)
- `lib/core/services/expertise_event_service.dart` (MODIFY)
- `lib/core/models/unified_user.dart` (MODIFY)
- `lib/presentation/pages/events/create_event_page.dart` (MODIFY)
- `test/unit/services/geographic_scope_service_test.dart` (NEW)
- `test/unit/services/large_city_detection_service_test.dart` (NEW)

---

#### **Week 2: Dynamic Local Expert Qualification**

**Goal:** Implement dynamic, locality-specific thresholds for local expert qualification

**Tasks:**

1. **Locality Value Analysis Service** (3 days)
   - Create `LocalityValueAnalysisService`
   - Track what users interact with most in each locality
   - Calculate locality-specific weights for different activities
   - Store locality preferences (events, lists, reviews, etc.)

2. **Dynamic Threshold Calculation** (2 days)
   - Update `ExpertiseCalculationService` to use locality-specific thresholds
   - Lower thresholds for activities valued by locality
   - Higher thresholds for activities less valued by locality
   - Implement threshold ebb and flow based on locality data

3. **Local Expert Qualification Factors** (2 days)
   - Update qualification to include:
     - Lists that others follow (locality-focused)
     - Event attendance and hosting
     - Professional background
     - Peer-reviewed reviews
     - Positive activity trends (category + locality)

**Deliverables:**
- ✅ Locality value analysis working
- ✅ Dynamic thresholds calculated
- ✅ Local expert qualification factors implemented
- ✅ Tests for threshold calculation

**Doors Opened:** Users can become local experts based on what their locality values

**Files to Create/Modify:**
- `lib/core/services/locality_value_analysis_service.dart` (NEW)
- `lib/core/services/expertise_calculation_service.dart` (MODIFY)
- `lib/core/models/expertise_requirements.dart` (MODIFY)
- `test/unit/services/locality_value_analysis_service_test.dart` (NEW)

---

### **PHASE 1.5: Business-Expert Matching Updates (Week 2.5)**

**Priority:** P1 - Critical (ensures local experts aren't excluded)  
**Status:** 📋 Planned  
**Timeline:** 3 days

#### **Goal:** Ensure local experts aren't skipped by businesses, prioritize vibe matching

**Tasks:**

1. **Remove Level-Based Filtering** (1 day)
   - Update `BusinessExpertMatchingService._findExpertsFromCommunity()` (lines 173-177)
   - Change `minExpertLevel` from filter to preference boost only
   - Ensure local experts are always included in matching pool
   - Update `ExpertSearchService.getTopExperts()` to include local experts

2. **Integrate Vibe Matching** (1 day)
   - Integrate `PartnershipMatchingService` vibe calculation into business-expert matching
   - Add vibe compatibility as PRIMARY factor (50% weight)
   - Update match scoring to prioritize vibe over level/location
   - Ensure 70%+ vibe compatibility is considered (but not required)

3. **Update AI Prompts** (0.5 day)
   - Update `_buildAIMatchingPrompt()` to emphasize vibe as PRIMARY factor
   - De-emphasize geographic level (local/city/state/national)
   - Focus on: event fit, product fit, idea fit, community fit, **VIBE fit**
   - Update prompt to say "vibe match is most important"

4. **Make Location a Preference, Not Filter** (0.5 day)
   - Update location matching to be boost only, not filter
   - Remote experts with great vibe/expertise should be included
   - Local experts in locality get boost, but not required

**Deliverables:**
- ✅ Local experts included in all business matching
- ✅ Vibe matching integrated as primary factor
- ✅ AI prompts emphasize vibe over level
- ✅ Location is preference boost, not filter
- ✅ Tests for vibe-first matching

**Doors Opened:** Local experts can connect with businesses, vibe matches prioritized over geographic level

**Files to Create/Modify:**
- `lib/core/services/business_expert_matching_service.dart` (MODIFY - major update)
- `lib/core/services/expert_search_service.dart` (MODIFY - remove City minimum)
- `test/unit/services/business_expert_matching_service_test.dart` (UPDATE)

**Detailed Changes Required:**

**1. Remove Level-Based Filtering:**
```dart
// CURRENT (lines 173-177):
bool levelMatch = business.minExpertLevel == null ||
    business.requiredExpertise.any((cat) {
      final level = member.getExpertiseLevel(cat);
      return level != null && level.index >= business.minExpertLevel!;
    });

// NEW: Make level a preference boost, not filter
// Remove this filter entirely - include all experts
// Apply level as boost in scoring instead
```

**2. Integrate Vibe Matching:**
```dart
// NEW: Add vibe compatibility calculation
Future<double> _calculateVibeCompatibility(
  UnifiedUser expert,
  BusinessAccount business,
) async {
  // Use PartnershipMatchingService or VibeAnalysisEngine
  // Calculate compatibility score (0.0 to 1.0)
  // Return vibe compatibility
}

// NEW: Update match scoring to prioritize vibe
double _calculateMatchScore(
  UnifiedUser expert,
  BusinessAccount business,
  double vibeCompatibility,
  ExpertiseLevel? expertLevel,
  String? expertLocation,
) {
  // Vibe: 50% weight (PRIMARY)
  double score = vibeCompatibility * 0.5;
  
  // Expertise: 30% weight
  score += expertiseMatch * 0.3;
  
  // Geographic: 20% weight (preference boost, not requirement)
  score += locationBoost * 0.2;
  
  // Level boost (if preferred, but not required)
  if (business.preferredExpertLevel != null && 
      expertLevel?.index == business.preferredExpertLevel) {
    score += 0.05; // Small boost for preferred level
  }
  
  return score.clamp(0.0, 1.0);
}
```

**3. Update AI Prompt:**
```dart
// CURRENT: Mentions minExpertLevel as requirement
// NEW: Emphasize vibe as PRIMARY factor

buffer.writeln('MATCHING PRIORITY (in order):');
buffer.writeln('1. VIBE/PERSONALITY COMPATIBILITY (PRIMARY - 50% weight)');
buffer.writeln('   - This is the MOST important factor');
buffer.writeln('   - Personality compatibility');
buffer.writeln('   - Value alignment');
buffer.writeln('   - Quality focus');
buffer.writeln('   - Community orientation');
buffer.writeln('2. Expertise Match (30% weight)');
buffer.writeln('3. Geographic Fit (20% weight - preference, not requirement)');
buffer.writeln('');
buffer.writeln('IMPORTANT:');
buffer.writeln('- Local experts should NOT be excluded just because they are local');
buffer.writeln('- Experts from different regions should be included if vibe/expertise match');
buffer.writeln('- Geographic level (local/city/state/national) is lowest priority');
buffer.writeln('- Vibe match is PRIMARY - suggest best match for event/product/idea/community/VIBE');
```

**4. Update Location Matching:**
```dart
// CURRENT: Location can filter out experts
// NEW: Location is preference boost only

// Remove location filtering from _applyPreferenceFilters()
// Instead, add location boost in _applyPreferenceScoring()
if (preferences.preferredLocation != null && expert.location != null) {
  if (expert.location!.toLowerCase().contains(
        preferences.preferredLocation!.toLowerCase(),
      )) {
    adjustedScore += 0.15; // Boost for location match
  } else {
    // Don't filter - remote experts with great vibe should be included
    // Maybe small penalty, but not exclusion
    adjustedScore -= 0.05; // Small penalty, but still included
  }
}
```

---

### **PHASE 2: Event Discovery & Matching (Weeks 3-4)**

**Priority:** P1 - Core Functionality  
**Status:** 📋 Planned  
**Timeline:** 2 weeks

#### **Week 3: Local Expert Priority & Cross-Locality Sharing**

**Goal:** Prioritize local experts in event rankings and enable cross-locality sharing

**Tasks:**

1. **Reputation/Matching Score Service** (3 days)
   - Create `EventMatchingService`
   - Calculate matching signals (not formal ranking):
     - Events hosted, ratings, followers
     - External social following
     - Community recognition
     - Event growth (community building)
     - Active list respects
   - Locality-specific weighting
   - Geographic interaction patterns

2. **Local Expert Priority Logic** (2 days)
   - Implement priority: Local expert > City expert (when hosting in locality)
   - Update event ranking algorithm
   - Add locality matching boost
   - Ensure local experts rank higher in their locality

3. **Cross-Locality Connection Service** (2 days)
   - Create `CrossLocalityConnectionService`
   - Track user movement patterns (commute, travel, fun)
   - Identify connected localities (not just distance)
   - Transportation method tracking
   - Metro area detection

**Deliverables:**
- ✅ Event matching service working
- ✅ Local expert priority implemented
- ✅ Cross-locality connections identified
- ✅ Tests for matching and priority

**Doors Opened:** Users find events from likeminded local experts, discover events in connected localities

**Files to Create/Modify:**
- `lib/core/services/event_matching_service.dart` (NEW)
- `lib/core/services/cross_locality_connection_service.dart` (NEW)
- `lib/core/services/expertise_event_service.dart` (MODIFY - search/ranking)
- `test/unit/services/event_matching_service_test.dart` (NEW)
- `test/unit/services/cross_locality_connection_service_test.dart` (NEW)

---

#### **Week 4: Events Page Organization & User Preference Learning**

**Goal:** Organize events by scope and learn user preferences

**Tasks:**

1. **Events Page Tabs** (3 days)
   - Update `events_browse_page.dart` to include tabs:
     - Community (non-expert events)
     - Locality
     - City
     - State
     - Nation
     - Globe
     - Universe
     - Clubs/Communities
   - Implement tab-based filtering
   - Update event search to filter by scope

2. **User Preference Learning** (2 days)
   - Create `UserPreferenceLearningService`
   - Track user event attendance patterns
   - Learn preferences (local vs city experts, categories, localities)
   - Suggest events outside typical behavior (exploration)

3. **Event Recommendation Engine** (2 days)
   - Integrate preference learning with event matching
   - Generate personalized event recommendations
   - Balance familiar preferences with exploration
   - Show local expert events to users who prefer local events

**Deliverables:**
- ✅ Events page organized by scope
- ✅ User preferences learned
- ✅ Event recommendations personalized
- ✅ Tests for preference learning

**Doors Opened:** Users discover events at appropriate scope levels, find likeminded people

**Files to Create/Modify:**
- `lib/core/services/user_preference_learning_service.dart` (NEW)
- `lib/core/services/event_recommendation_service.dart` (NEW)
- `lib/presentation/pages/events/events_browse_page.dart` (MODIFY)
- `test/unit/services/user_preference_learning_service_test.dart` (NEW)

---

### **PHASE 3: Community Events & Clubs (Weeks 5-7)**

**Priority:** P1 - Core Functionality  
**Status:** 📋 Planned  
**Timeline:** 3 weeks

#### **Week 5: Community Events (Non-Expert Hosting)**

**Goal:** Enable non-experts to host community events

**Tasks:**

1. **Community Event Model** (2 days)
   - Create `CommunityEvent` model (extends or separate from `ExpertiseEvent`)
   - Add `isCommunityEvent` flag
   - Add `hostExpertiseLevel` (null for non-experts)
   - Enforce no payment on app (cash at door OK)

2. **Community Event Service** (3 days)
   - Create `CommunityEventService`
   - Allow non-experts to create events
   - Validate: no payment, public events only
   - Track event metrics (attendance, engagement, growth)

3. **Community Event Upgrade Logic** (2 days)
   - Implement upgrade criteria:
     - Frequency hosting
     - Strong following (active returns, growth in size + diversity)
     - User interaction patterns
   - Create upgrade flow (community → local event)
   - Update event type when upgraded

**Deliverables:**
- ✅ Non-experts can host community events
- ✅ Community events can't charge on app
- ✅ Upgrade path to local events working
- ✅ Tests for community events

**Doors Opened:** Anyone can host community events, enabling organic community building

**Files to Create/Modify:**
- `lib/core/models/community_event.dart` (NEW)
- `lib/core/services/community_event_service.dart` (NEW)
- `lib/presentation/pages/events/create_community_event_page.dart` (NEW)
- `test/unit/services/community_event_service_test.dart` (NEW)

---

#### **Week 6: Events → Communities → Clubs System**

**Goal:** Enable events to create communities, communities to become clubs

**Tasks:**

1. **Community Model** (2 days)
   - Create `Community` model
   - Link to originating event
   - Track members, events, growth
   - Store community metrics

2. **Club Model & Structure** (3 days)
   - Create `Club` model (extends Community)
   - Add organizational structure:
     - Leaders (founders, primary organizers)
     - Admin team (managers, moderators)
     - Internal hierarchy (roles, permissions)
   - Member management system

3. **Community/Club Service** (2 days)
   - Create `CommunityService` and `ClubService`
   - Auto-create community from successful events
   - Upgrade community to club (when structure needed)
   - Manage leaders, admins, members

**Deliverables:**
- ✅ Events can create communities
- ✅ Communities can become clubs
- ✅ Club structure (leaders, admins, hierarchy) working
- ✅ Tests for communities and clubs

**Doors Opened:** Events naturally create communities, communities can organize as clubs

**Files to Create/Modify:**
- `lib/core/models/community.dart` (NEW)
- `lib/core/models/club.dart` (NEW)
- `lib/core/services/community_service.dart` (NEW)
- `lib/core/services/club_service.dart` (NEW)
- `test/unit/services/community_service_test.dart` (NEW)
- `test/unit/services/club_service_test.dart` (NEW)

---

#### **Week 7: Geographic Expansion & Expertise Gain (75% Rule)**

**Goal:** Implement 75% expansion rule for expertise gain

**Tasks:**

1. **Expansion Tracking Service** (3 days)
   - Create `GeographicExpansionService`
   - Track event expansion from original locality
   - Measure coverage: commute patterns OR event hosting
   - Calculate 75% thresholds for each geographic level

2. **Expertise Gain from Expansion** (2 days)
   - Implement expertise gain logic:
     - Neighboring locality expansion → gain local expertise
     - 75% city coverage → gain city expertise
     - 75% state coverage → gain state expertise
     - Pattern continues to nation, globe, universal
   - Update expertise when expansion thresholds met

3. **Club Leader Expertise Recognition** (2 days)
   - Club leaders gain expertise in all localities where club hosts events
   - Leadership role grants expert status
   - Track leader expertise from club expansion

**Deliverables:**
- ✅ Expansion tracking working
- ✅ 75% rule implemented
- ✅ Expertise gain from expansion working
- ✅ Club leaders recognized as experts
- ✅ Tests for expansion and expertise gain

**Doors Opened:** Communities/clubs can expand naturally, leaders gain expertise through expansion

**Files to Create/Modify:**
- `lib/core/services/geographic_expansion_service.dart` (NEW)
- `lib/core/services/expertise_calculation_service.dart` (MODIFY - expansion expertise)
- `lib/core/models/club.dart` (MODIFY - leader expertise)
- `test/unit/services/geographic_expansion_service_test.dart` (NEW)

---

### **PHASE 4: UI/UX & Golden Expert Integration (Weeks 8-9)**

**Priority:** P1 - Core Functionality  
**Status:** 📋 Planned  
**Timeline:** 2 weeks

#### **Week 8: Club/Community Pages & Expertise Coverage Visualization**

**Goal:** Create special UI/UX for club/community pages showing expertise coverage

**Tasks:**

1. **Club/Community Page** (3 days)
   - Create `club_page.dart` and `community_page.dart`
   - Display club/community information
   - Show leaders, admins, members
   - Show events hosted

2. **Expertise Coverage Visualization** (3 days)
   - Create `expertise_coverage_widget.dart`
   - Interactive map showing all localities with expertise
   - Color-coded by expertise level (local, city, state, etc.)
   - Show coverage percentage for each geographic level
   - Display expansion timeline

3. **Coverage Metrics Display** (1 day)
   - Show locality coverage (list of all localities)
   - Show city/state/nation/globe coverage (75% threshold indicators)
   - Show universal status (if achieved)
   - Display leader expertise

**Deliverables:**
- ✅ Club/community pages created
- ✅ Expertise coverage visualization working
- ✅ Coverage metrics displayed
- ✅ Tests for UI components

**Doors Opened:** Users can see club/community expertise coverage, understand expansion

**Files to Create/Modify:**
- `lib/presentation/pages/clubs/club_page.dart` (NEW)
- `lib/presentation/pages/clubs/community_page.dart` (NEW)
- `lib/presentation/widgets/clubs/expertise_coverage_widget.dart` (NEW)
- `lib/presentation/widgets/clubs/coverage_metrics_widget.dart` (NEW)
- `test/widget/clubs/expertise_coverage_widget_test.dart` (NEW)

---

#### **Week 9: Golden Expert AI Influence**

**Goal:** Implement Golden Local Expert AI influence on locality representation

**Tasks:**

1. **Golden Expert Weighting Service** (2 days)
   - Create `GoldenExpertInfluenceService`
   - Calculate weight: 10% higher (proportional to residency length)
   - Example: 30 years = 1.3x weight, 25 years = 1.25x weight
   - Apply weight to golden expert actions

2. **AI Personality Locality Influence** (3 days)
   - Update AI personality learning to use golden expert data
   - Golden expert behavior influences locality AI personality
   - Golden expert preferences shape locality representation
   - Central AI system uses golden expert perspective

3. **List/Review Weighting** (2 days)
   - Update recommendation system to weight golden expert lists/reviews higher
   - Golden expert contributions have more influence on recommendations
   - Neighborhood character shaped by golden experts (along with all locals, but higher rate)

**Deliverables:**
- ✅ Golden expert weighting implemented
- ✅ AI personality influenced by golden experts
- ✅ Golden expert lists/reviews weighted more heavily
- ✅ Tests for golden expert influence

**Doors Opened:** Golden experts shape neighborhood character, AI reflects actual community values

**Files to Create/Modify:**
- `lib/core/services/golden_expert_influence_service.dart` (NEW)
- `lib/core/ai/personality_learning.dart` (MODIFY - golden expert weighting)
- `lib/core/services/list_generator_service.dart` (MODIFY - golden expert weighting)
- `test/unit/services/golden_expert_influence_service_test.dart` (NEW)

---

### **PHASE 5: Neighborhood Boundaries & Dynamic Refinement (Week 10)**

**Priority:** P2 - Enhancement  
**Status:** 📋 Planned  
**Timeline:** 1 week

#### **Week 10: Dynamic Neighborhood Boundaries**

**Goal:** Implement dynamic neighborhood boundary refinement based on user behavior

**Tasks:**

1. **Neighborhood Boundary Service** (3 days)
   - Create `NeighborhoodBoundaryService`
   - Load boundaries from Google Maps
   - Handle hard borders (well-defined) vs soft borders (blended)
   - Store boundary data

2. **Soft Border Handling** (2 days)
   - Spots in soft border areas shared with both localities
   - Track which locality users visit spots more
   - Refine borders based on user behavior
   - Borders become more defined over time

3. **Dynamic Border Refinement** (2 days)
   - Continuously track user movement patterns
   - If Locality A users visit spot more than Locality B, spot becomes more associated with Locality A
   - Update boundaries based on actual community behavior
   - Visualize border changes

**Deliverables:**
- ✅ Neighborhood boundaries loaded from Google Maps
- ✅ Soft border handling working
- ✅ Dynamic border refinement implemented
- ✅ Tests for boundary refinement

**Doors Opened:** System reflects actual community boundaries, not just geographic lines

**Files to Create/Modify:**
- `lib/core/services/neighborhood_boundary_service.dart` (NEW)
- `lib/core/models/neighborhood_boundary.dart` (NEW)
- `test/unit/services/neighborhood_boundary_service_test.dart` (NEW)

---

## 📊 **Dependencies & Integration Points**

### **Existing Systems to Integrate With:**

1. **Expertise System:**
   - `ExpertiseCalculationService`
   - `MultiPathExpertiseService`
   - `ExpertiseLevel` enum
   - `ExpertisePin` model

2. **Event System:**
   - `ExpertiseEventService`
   - `ExpertiseEvent` model
   - Event creation/hosting flow

3. **User System:**
   - `UnifiedUser` model
   - User profiles
   - User preferences

4. **AI System:**
   - `PersonalityLearningService`
   - `ListGeneratorService`
   - AI personality profiles

### **New Systems to Create:**

1. Geographic scope validation
2. Locality value analysis
3. Event matching/reputation
4. Cross-locality connections
5. Community/club management
6. Geographic expansion tracking
7. Golden expert influence
8. Neighborhood boundaries

---

## 🧪 **Testing Strategy**

### **Unit Tests:**
- All new services (100% coverage)
- Geographic scope validation
- Threshold calculation
- Matching algorithms
- Expansion tracking
- Golden expert weighting

### **Integration Tests:**
- Event hosting with geographic scope
- Community event upgrade flow
- Club expansion and expertise gain
- Cross-locality event sharing
- Golden expert AI influence

### **Widget Tests:**
- Club/community pages
- Expertise coverage visualization
- Events page tabs
- Community event creation

---

## 📈 **Success Metrics**

### **Local Expert Engagement:**
- Number of local experts hosting events
- Average events hosted per local expert
- Cross-locality event attendance

### **Event Discovery:**
- Users finding events they like (match rate)
- Users exploring new categories/locales
- Community event upgrade rate

### **Geographic Diversity:**
- Events distributed across neighborhoods
- Small neighborhood events getting traction
- Cross-locality community building

### **AI Personality Accuracy:**
- Locality AI personalities reflecting actual neighborhood character
- Golden expert influence measurable in recommendations
- User satisfaction with locality-based recommendations

---

## 🚨 **Risks & Mitigation**

### **Risk 1: Complexity of Dynamic Thresholds**
**Mitigation:** Start with simple locality value tracking, iterate based on data

### **Risk 2: 75% Rule Calculation Performance**
**Mitigation:** Cache coverage calculations, update incrementally

### **Risk 3: Neighborhood Boundary Data Quality**
**Mitigation:** Start with Google Maps, allow manual corrections, refine with user behavior

### **Risk 4: Club/Community System Complexity**
**Mitigation:** Start with basic community model, add club features incrementally

---

## 📝 **Documentation Requirements**

### **Code Documentation:**
- All new services documented
- Complex algorithms explained
- Geographic hierarchy documented
- 75% rule calculation explained

### **User Documentation:**
- How to become a local expert
- How to host community events
- How clubs/communities work
- How expertise expansion works

### **API Documentation:**
- New service APIs
- Event matching API
- Expansion tracking API

---

## ✅ **Approval Checklist**

Before implementation begins, confirm:

- [ ] Requirements document approved (`LOCAL_EXPERT_SYSTEM_REDESIGN.md`)
- [ ] Implementation plan approved (this document)
- [ ] Timeline acceptable (9-13 weeks)
- [ ] Dependencies understood
- [ ] Testing strategy approved
- [ ] Success metrics defined
- [ ] Risks identified and acceptable
- [ ] **TOTAL implementation understood** - All 73+ files will be updated
- [ ] **City level as minimum removed** - No feature uses City as minimum unless explicitly designed
- [ ] **Geographic hierarchy understood** - Local → City → State → National
- [ ] **All expertise system references identified** - Comprehensive search completed

## 🔍 **Post-Implementation Verification**

After ALL phases complete, verify TOTAL implementation:

### **Code Verification:**
- [ ] Search codebase for "City level required for event hosting" - Should return 0 results
- [ ] Search codebase for "ExpertiseLevel.city.index" in event hosting context - Should return 0 results
- [ ] All services allow Local level for event hosting
- [ ] All UI components show "Local level" (not City) for event hosting requirements
- [ ] Geographic hierarchy enforced in all event creation flows
- [ ] Local experts can only host in their locality
- [ ] City experts can host in all localities in their city

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

### **Feature Verification:**
- [ ] Local experts can create events in their locality
- [ ] Local experts CANNOT create events in other localities
- [ ] City experts can create events in all localities in their city
- [ ] Geographic scope validation working
- [ ] Community events working (no expertise required)
- [ ] Event → Community → Club system working
- [ ] 75% expansion rule working
- [ ] Golden expert AI influence working
- [ ] Reputation/matching system working (locality-specific)
- [ ] Business-expert matching includes local experts
- [ ] Vibe matching is PRIMARY factor in business-expert matching (50% weight)
- [ ] Geographic level is preference boost, not filter
- [ ] Location is preference boost, not filter
- [ ] Remote experts with great vibe/expertise are included
- [ ] AI prompts emphasize vibe over level

### **System-Wide Verification:**
- [ ] No feature uses City level as minimum (unless explicitly designed)
- [ ] All expertise checks use correct geographic hierarchy
- [ ] All UI shows correct expertise requirements
- [ ] All services enforce correct expertise levels
- [ ] System works exactly as specified in requirements document

---

## 🔄 **Next Steps After Approval**

1. **Add to Master Plan:**
   - Integrate phases into `MASTER_PLAN.md`
   - Determine optimal placement based on dependencies
   - Update execution sequence
   - **Note:** Phase 0 must come first (updates existing code)

2. **Create Task Assignments:**
   - Break down into specific tasks
   - Assign to agents/developers
   - Set up tracking
   - **Priority:** Phase 0 is critical path

3. **Begin Implementation:**
   - Start with Phase 0 (Codebase Updates)
   - Then proceed to Phase 1, Week 1
   - Follow development methodology
   - Update progress regularly

## 📊 **Codebase Impact Summary**

### **Files Requiring Updates:**

**Core Code (20 files):**
- **Models:** 3 files
  - `unified_user.dart` (canHostEvents - line 298)
  - `expertise_pin.dart` (unlocksEventHosting - line 85)
  - `business_account.dart` (review minExpertLevel)
  
- **Services:** 7 files
  - `expertise_event_service.dart` (createEvent validation - lines 15, 36-37)
  - `expertise_service.dart` (getUnlockedFeatures - line 229)
  - `expert_search_service.dart` (getTopExperts - line 84 - Remove City minimum)
  - `expertise_matching_service.dart` (complementary score - lines 262-263 - City check)
  - `partnership_service.dart` (eligibility check - line 347)
  - `expertise_community_service.dart` (review minLevel usage)
  - **CRITICAL:** `business_expert_matching_service.dart` (lines 173-177, 420-427 - Remove level filtering, add vibe-first matching)
  
- **UI Components:** 4 files
  - `create_event_page.dart` (lines 20, 94, 96, 109, 328, 330, 334)
  - `event_review_page.dart` (line 342 - "Required: City level+")
  - `event_hosting_unlock_widget.dart` (lines 11, 100, 315, 345, 397, 552)
  - `expertise_display_widget.dart` (lines 170-177 - filter to include Local)
  
- **Other:** 6 files (routers, configs, etc.)

**Tests (28 expertise-specific files + related):**
- **Integration tests:** 9 files (52 City level references)
- **Unit tests - Services:** 6 files (19 City level references)
- **Unit tests - Models:** 4 files (mostly OK, some need review)
- **Widget tests:** 3 files (mostly OK)
- **Test helpers/fixtures:** 2 files (CRITICAL - createUserWithCityExpertise)
- **Other related tests:** 4 files (partnership, payment, etc.)
- **Total expertise test files:** 28 files with 134 City level references

**Documentation (25+ files):**
- **User documentation:** 3 files
  - `USER_TO_EXPERT_JOURNEY.md` (lines 44, 74, 81-86)
  - Other user-facing docs
- **Plan documents:** 15+ files
  - `DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md` (line 1806)
  - `EASY_EVENT_HOSTING_EXPLANATION.md`
  - All other plans referencing City level
- **Agent reports:** 5+ files
- **Status trackers:** 2+ files

**Total:** ~80+ files requiring updates (comprehensive coverage including gaps)

### **Backward Compatibility & Migration Strategy (CRITICAL):**

**Existing Users:**
- Users with City level expertise → Keep their expertise, but now Local can also host
- Users with Local level expertise → Can now host events (new capability)
- No downgrade needed - all existing expertise remains valid

**Existing Events:**
- Events created by City level experts → Remain valid (no change needed)
- Events created by users who now have Local level → Should be valid
- Historical event data → No migration needed (events remain valid)

**Data Migration:**
- No database schema changes needed (expertise level enum unchanged)
- No data transformation needed (Local level already exists in enum)
- Cache invalidation → Clear any cached "canHostEvents" calculations
- Recalculate `canHostEvents()` for all users (background job)

**Migration Steps:**
1. Deploy code changes (Local level can host)
2. Run background job to recalculate `canHostEvents()` for all users
3. Clear expertise-related caches
4. Update all error messages/UI text
5. Monitor for any issues with existing events

### **Additional Gaps Identified (Critical for Total Implementation):**

**Error Messages & Exception Text (3 locations):**
- `lib/core/services/expertise_event_service.dart` (line 37) - Exception: "Host must have City level or higher expertise to host events"
- `lib/presentation/pages/events/create_event_page.dart` (line 96) - Error: "You need City level or higher expertise to host events"
- `lib/presentation/pages/events/create_event_page.dart` (line 330) - Error: "You need City level or higher expertise in $_selectedCategory to host events"
- `lib/presentation/pages/events/create_event_page.dart` (line 334) - SnackBar: "You need City level+ expertise in $_selectedCategory to host events"
- `docs/plans/event_partnership/EVENT_PARTNERSHIP_MONETIZATION_PLAN.md` (line 291) - Exception: "Expert must have City-level expertise"

**AI Prompts & LLM Integration (1 file):**
- `lib/core/services/business_expert_matching_service.dart` (lines 298-335) - AI prompt builder mentions `minExpertLevel` but doesn't specify City as minimum (OK, but review)

**Code Comments & Documentation Strings (10+ locations):**
- `lib/core/services/expertise_event_service.dart` (line 15) - Comment: "Requires user to have City level or higher expertise"
- `lib/presentation/pages/events/create_event_page.dart` (line 20) - Comment: "Expertise verification (City level+ required)"
- All other code comments mentioning City level requirements

**Constants & Configuration (Review needed):**
- `lib/core/constants/app_constants.dart` - Review for expertise-related constants
- `packages/spots_core/lib/utils/constants.dart` - Review for expertise constants
- Any config files with hardcoded City level values

**Database Schema & Migrations (Review needed):**
- `supabase/migrations/001_initial_schema.sql` - Review for expertise level constraints
- `supabase/sql/supabase_schema.sql` - Review for expertise-related schema
- Any database constraints that might enforce City level minimums

**Onboarding & Tutorial Content (Review needed):**
- `lib/presentation/pages/onboarding/onboarding_page.dart` - Review for any expertise mentions
- Any tutorial or help content mentioning City level requirements

**Route Guards & Navigation (Review needed):**
- `lib/presentation/routes/app_router.dart` - Review for route guards checking expertise
- Any navigation logic that gates routes based on City level

**Feature Flags (Review needed):**
- Any feature flags related to expertise system
- Any A/B testing flags for expertise features

**Analytics Events (Review needed):**
- Any analytics tracking that logs "City level achieved" or "City level required"
- Any event tracking for expertise progression

**Backward Compatibility & Data Migration:**
- **CRITICAL:** Existing users with City level expertise - how to handle?
- **CRITICAL:** Existing events created by City level experts - should they remain valid?
- **CRITICAL:** Historical data showing City level as minimum - migration strategy?
- **CRITICAL:** Cached expertise data - invalidation strategy?

**Internationalization (i18n) - If Applicable:**
- Any translation files with "City level" text
- Any localized error messages mentioning City level

### **Update Complexity:**

- **Simple Updates:** Text changes, level enum changes, comments (~40 files)
  - Documentation updates
  - Code comments
  - UI text/messages
  - Test comments
  
- **Medium Updates:** Logic changes, validation updates (~25 files)
  - Service validation logic
  - Model methods (canHostEvents, unlocksEventHosting)
  - Test assertions
  - UI component logic
  
- **Complex Updates:** UI component refactoring, test rewrites, service refactoring (~8 files)
  - `expertise_display_widget.dart` (filter logic change)
  - `event_hosting_unlock_widget.dart` (unlock logic)
  - `expert_search_service.dart` (getTopExperts minimum change)
  - `expertise_matching_service.dart` (complementary score logic)
  - Test helper functions (createUserWithCityExpertise)
  - Integration test rewrites

### **Verification Checklist:**

After Phase 0 completion, verify:
- [ ] No code file references "City level required for event hosting"
- [ ] All services allow Local level for event hosting
- [ ] All UI components show "Local level" (not City) for event hosting
- [ ] All tests pass with Local level for event hosting
- [ ] All documentation updated
- [ ] No City level as minimum for features (unless explicitly designed)
- [ ] Geographic hierarchy enforced (Local → City → State → National)
- [ ] Local experts can host in their locality only
- [ ] City experts can host in all localities in their city

---

**Last Updated:** November 23, 2025  
**Status:** Awaiting Approval  
**Next:** Synthesize into Master Plan after approval

