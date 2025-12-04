# New Components Required for Local Expert System

**Created:** November 23, 2025  
**Status:** 📋 Comprehensive List  
**Purpose:** Complete list of NEW components that must be built from scratch (not just updated)

---

## 🎯 **Overview**

This document lists ALL new components that need to be built from scratch for the Local Expert System redesign. These are in addition to the 80+ files that need to be updated.

**Total New Components:** ~50+ new files/components

---

## 📍 **1. Geographic Scope & Validation System**

### **NEW Services (3 files):**

1. **`GeographicScopeService`** (NEW)
   - Validate event hosting scope based on expertise level
   - Enforce hierarchy: Local → City → State → National
   - Check if local expert can host in locality
   - Check if city expert can host in all localities in city
   - Validate geographic boundaries
   - **Location:** `lib/core/services/geographic_scope_service.dart`
   - **Tests:** `test/unit/services/geographic_scope_service_test.dart`

2. **`LargeCityDetectionService`** (NEW)
   - Detect large diverse cities (Brooklyn, LA, Chicago, etc.)
   - Based on: geographic size, population, documented neighborhoods
   - Store large city configuration
   - Allow neighborhood-level localities for large cities
   - **Location:** `lib/core/services/large_city_detection_service.dart`
   - **Tests:** `test/unit/services/large_city_detection_service_test.dart`

3. **`NeighborhoodBoundaryService`** (NEW)
   - Manage hard vs soft neighborhood borders
   - Track user movement patterns to refine borders
   - Share soft border spots with both localities
   - Dynamically refine borders based on user behavior
   - **Location:** `lib/core/services/neighborhood_boundary_service.dart`
   - **Tests:** `test/unit/services/neighborhood_boundary_service_test.dart`

### **NEW Models (2 files):**

4. **`GeographicScope`** (NEW)
   - Model for geographic scope of expertise
   - Stores: location, level, boundaries
   - **Location:** `lib/core/models/geographic_scope.dart`
   - **Tests:** `test/unit/models/geographic_scope_test.dart`

5. **`NeighborhoodBoundary`** (NEW)
   - Model for neighborhood boundaries (hard/soft)
   - Stores: boundaries, user behavior data, refinement history
   - **Location:** `lib/core/models/neighborhood_boundary.dart`
   - **Tests:** `test/unit/models/neighborhood_boundary_test.dart`

---

## 🎪 **2. Community Events System**

### **NEW Models (1 file):**

6. **`CommunityEvent`** (NEW)
   - Model for non-expert community events
   - Extends or separate from `ExpertiseEvent`
   - Fields: `isCommunityEvent`, `hostExpertiseLevel` (null for non-experts)
   - Enforces: no payment on app (cash at door OK)
   - **Location:** `lib/core/models/community_event.dart`
   - **Tests:** `test/unit/models/community_event_test.dart`

### **NEW Services (2 files):**

7. **`CommunityEventService`** (NEW)
   - Allow non-experts to create events
   - Validate: no payment, public events only
   - Track event metrics (attendance, engagement, growth)
   - Handle upgrade to local event
   - **Location:** `lib/core/services/community_event_service.dart`
   - **Tests:** `test/unit/services/community_event_service_test.dart`

8. **`CommunityEventUpgradeService`** (NEW)
   - Implement upgrade criteria:
     - Frequency hosting
     - Strong following (active returns, growth in size + diversity)
     - User interaction patterns
   - Create upgrade flow (community → local event)
   - Update event type when upgraded
   - **Location:** `lib/core/services/community_event_upgrade_service.dart`
   - **Tests:** `test/unit/services/community_event_upgrade_service_test.dart`

### **NEW UI Components (2 files):**

9. **`CreateCommunityEventPage`** (NEW)
   - UI for non-experts to create community events
   - Simplified form (no expertise required)
   - Payment disabled (cash at door only)
   - **Location:** `lib/presentation/pages/events/create_community_event_page.dart`
   - **Tests:** `test/widget/pages/events/create_community_event_page_test.dart`

10. **`CommunityEventWidget`** (NEW)
    - Widget to display community events
    - Shows "Community Event" badge
    - Different styling from expert events
    - **Location:** `lib/presentation/widgets/events/community_event_widget.dart`
    - **Tests:** `test/widget/widgets/events/community_event_widget_test.dart`

---

## 👥 **3. Clubs & Communities System**

### **NEW Models (3 files):**

11. **`Community`** (NEW)
    - Model for communities created from events
    - Links to originating event
    - Tracks: members, events, growth, metrics
    - **Location:** `lib/core/models/community.dart`
    - **Tests:** `test/unit/models/community_test.dart`

12. **`Club`** (NEW)
    - Model for clubs (extends Community)
    - Organizational structure:
      - Leaders (founders, primary organizers)
      - Admin team (managers, moderators)
      - Internal hierarchy (roles, permissions)
    - Member management system
    - **Location:** `lib/core/models/club.dart`
    - **Tests:** `test/unit/models/club_test.dart`

13. **`ClubHierarchy`** (NEW)
    - Model for club organizational structure
    - Roles: Leader, Admin, Moderator, Member
    - Permissions system
    - **Location:** `lib/core/models/club_hierarchy.dart`
    - **Tests:** `test/unit/models/club_hierarchy_test.dart`

### **NEW Services (3 files):**

14. **`CommunityService`** (NEW)
    - Auto-create community from successful events
    - Manage community members, events, growth
    - Track community metrics
    - **Location:** `lib/core/services/community_service.dart`
    - **Tests:** `test/unit/services/community_service_test.dart`

15. **`ClubService`** (NEW)
    - Upgrade community to club (when structure needed)
    - Manage leaders, admins, members
    - Handle club permissions and hierarchy
    - **Location:** `lib/core/services/club_service.dart`
    - **Tests:** `test/unit/services/club_service_test.dart`

16. **`CommunityToClubUpgradeService`** (NEW)
    - Handle upgrade from community to club
    - Set up organizational structure
    - Transfer leadership
    - **Location:** `lib/core/services/community_to_club_upgrade_service.dart`
    - **Tests:** `test/unit/services/community_to_club_upgrade_service_test.dart`

### **NEW UI Components (4 files):**

17. **`ClubPage`** (NEW)
    - Special page for club/community
    - Shows expertise coverage by locality
    - Visual map of geographic coverage
    - Coverage metrics (locality, city, state, national, global)
    - Expansion tracking timeline
    - Leader expertise display
    - **Location:** `lib/presentation/pages/clubs/club_page.dart`
    - **Tests:** `test/widget/pages/clubs/club_page_test.dart`

18. **`ClubExpertiseCoverageWidget`** (NEW)
    - Widget showing club expertise coverage map
    - Color-coded by expertise level
    - Shows coverage percentage for each geographic level
    - **Location:** `lib/presentation/widgets/clubs/club_expertise_coverage_widget.dart`
    - **Tests:** `test/widget/widgets/clubs/club_expertise_coverage_widget_test.dart`

19. **`ClubManagementPage`** (NEW)
    - UI for club leaders/admins to manage club
    - Manage members, roles, permissions
    - Approve events, manage hierarchy
    - **Location:** `lib/presentation/pages/clubs/club_management_page.dart`
    - **Tests:** `test/widget/pages/clubs/club_management_page_test.dart`

20. **`ClubHierarchyWidget`** (NEW)
    - Widget displaying club organizational structure
    - Shows leaders, admins, moderators, members
    - Role management UI
    - **Location:** `lib/presentation/widgets/clubs/club_hierarchy_widget.dart`
    - **Tests:** `test/widget/widgets/clubs/club_hierarchy_widget_test.dart`

---

## 📊 **4. Geographic Expansion & 75% Rule**

### **NEW Services (2 files):**

21. **`GeographicExpansionService`** (NEW)
    - Track event expansion from original locality
    - Measure coverage: commute patterns OR event hosting
    - Calculate 75% thresholds for each geographic level
    - Track expansion timeline
    - **Location:** `lib/core/services/geographic_expansion_service.dart`
    - **Tests:** `test/unit/services/geographic_expansion_service_test.dart`

22. **`ExpansionExpertiseGainService`** (NEW)
    - Implement expertise gain logic from expansion:
      - Neighboring locality expansion → gain local expertise
      - 75% city coverage → gain city expertise
      - 75% state coverage → gain state expertise
      - Pattern continues to nation, globe, universal
    - Update expertise when expansion thresholds met
    - **Location:** `lib/core/services/expansion_expertise_gain_service.dart`
    - **Tests:** `test/unit/services/expansion_expertise_gain_service_test.dart`

### **NEW Models (1 file):**

23. **`GeographicExpansion`** (NEW)
    - Model tracking expansion from original locality
    - Stores: original locality, expanded localities, coverage percentages
    - Tracks: commute patterns, event hosting locations
    - **Location:** `lib/core/models/geographic_expansion.dart`
    - **Tests:** `test/unit/models/geographic_expansion_test.dart`

---

## 🏆 **5. Reputation & Matching System**

### **NEW Services (3 files):**

24. **`ReputationCalculationService`** (NEW)
    - Calculate reputation scores (locality-specific)
    - Components:
      - Number of successful events hosted
      - Average event ratings
      - SPOTS followers
      - External social following
      - Community recognition
      - Growth of event size per user
      - Active respects to lists
    - Apply locality-specific weighting
    - **Location:** `lib/core/services/reputation_calculation_service.dart`
    - **Tests:** `test/unit/services/reputation_calculation_service_test.dart`

25. **`LocalityValueAnalysisService`** (NEW)
    - Track what users interact with most in each locality
    - Calculate locality-specific weights for different activities
    - Store locality preferences (events, lists, reviews, etc.)
    - Determine what locality values (for threshold calculation)
    - **Location:** `lib/core/services/locality_value_analysis_service.dart`
    - **Tests:** `test/unit/services/locality_value_analysis_service_test.dart`

26. **`EventMatchingService`** (NEW)
    - Match users to events based on reputation signals
    - Prioritize local experts in their locality
    - Learn user preferences (local vs city experts)
    - Suggest events outside typical behavior (exploration)
    - **Location:** `lib/core/services/event_matching_service.dart`
    - **Tests:** `test/unit/services/event_matching_service_test.dart`

### **NEW Models (2 files):**

27. **`ReputationScore`** (NEW)
    - Model for reputation scores (locality-specific)
    - Stores: score, components, locality, category
    - **Location:** `lib/core/models/reputation_score.dart`
    - **Tests:** `test/unit/models/reputation_score_test.dart`

28. **`LocalityValues`** (NEW)
    - Model for locality-specific values/preferences
    - Stores: what locality values (events, lists, reviews, etc.)
    - Weighting factors for different activities
    - **Location:** `lib/core/models/locality_values.dart`
    - **Tests:** `test/unit/models/locality_values_test.dart`

---

## 🎓 **6. Dynamic Local Expert Qualification**

### **NEW Services (1 file):**

29. **`DynamicThresholdService`** (NEW)

---

## 🤝 **7. Business-Expert Vibe-First Matching**

### **NEW Services (1 file):**

30. **`BusinessExpertVibeMatchingService`** (NEW)
    - Integrate vibe matching into business-expert matching
    - Calculate vibe compatibility (using existing PartnershipMatchingService)
    - Prioritize vibe (50% weight) over level/location
    - Ensure local experts are included regardless of level
    - Make location a preference boost, not filter
    - **Location:** `lib/core/services/business_expert_vibe_matching_service.dart`
    - **Tests:** `test/unit/services/business_expert_vibe_matching_service_test.dart`

### **MODIFY Services (1 file):**

31. **`BusinessExpertMatchingService`** (MAJOR UPDATE)
    - Remove level-based filtering (lines 173-177, 420-427)
    - Integrate vibe matching as PRIMARY factor
    - Update `_applyPreferenceScoring()` to prioritize vibe
    - Update `_buildAIMatchingPrompt()` to emphasize vibe
    - Make `minExpertLevel` a preference boost only, not filter
    - Make location preferences boosts, not filters
    - **Location:** `lib/core/services/business_expert_matching_service.dart`
    - **Tests:** `test/unit/services/business_expert_matching_service_test.dart` (UPDATE)

---

## ✨ **8. Golden Local Expert AI Influence**
    - Calculate dynamic, locality-specific thresholds
    - Lower thresholds for activities valued by locality
    - Higher thresholds for activities less valued by locality
    - Implement threshold ebb and flow based on locality data
    - **Location:** `lib/core/services/dynamic_threshold_service.dart`
    - **Tests:** `test/unit/services/dynamic_threshold_service_test.dart`

---

## ✨ **7. Golden Local Expert AI Influence**

### **NEW Services (2 files):**

30. **`GoldenExpertAIInfluenceService`** (NEW)
    - Apply 10% higher weight (proportional to residency length)
    - Influence AI personality representation
    - Weight lists/reviews more heavily in locality recommendations
    - Shape neighborhood character in system
    - **Location:** `lib/core/services/golden_expert_ai_influence_service.dart`
    - **Tests:** `test/unit/services/golden_expert_ai_influence_service_test.dart`

31. **`LocalityPersonalityService`** (NEW)
    - Manage locality AI personality
    - Incorporate golden expert influence
    - Shape neighborhood "vibe" in system
    - **Location:** `lib/core/services/locality_personality_service.dart`
    - **Tests:** `test/unit/services/locality_personality_service_test.dart`

---

## 🔍 **8. Event Discovery & User Preferences**

### **NEW Services (2 files):**

32. **`UserPreferenceLearningService`** (NEW)
    - Track user event attendance patterns
    - Learn preferences (local vs city experts, categories, localities)
    - Suggest events outside typical behavior (exploration)
    - **Location:** `lib/core/services/user_preference_learning_service.dart`
    - **Tests:** `test/unit/services/user_preference_learning_service_test.dart`

33. **`EventRecommendationService`** (NEW)
    - Integrate preference learning with event matching
    - Generate personalized event recommendations
    - Balance familiar preferences with exploration
    - Show local expert events to users who prefer local events
    - **Location:** `lib/core/services/event_recommendation_service.dart`
    - **Tests:** `test/unit/services/event_recommendation_service_test.dart`

### **NEW UI Components (1 file):**

34. **`EventsBrowsePage`** (MODIFY - Major Update)
    - Add tabs for event organization:
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
    - **Location:** `lib/presentation/pages/events/events_browse_page.dart`
    - **Tests:** `test/widget/pages/events/events_browse_page_test.dart`

---

## 🗺️ **9. Cross-Locality Connection System**

### **NEW Services (1 file):**

35. **`CrossLocalityConnectionService`** (NEW)
    - Determine "neighboring" localities (not just distance)
    - Based on: how connected places are, commute patterns, transportation
    - Track user movement between localities
    - Share local expert events with connected localities
    - **Location:** `lib/core/services/cross_locality_connection_service.dart`
    - **Tests:** `test/unit/services/cross_locality_connection_service_test.dart`

### **NEW Models (1 file):**

36. **`LocalityConnection`** (NEW)
    - Model for connections between localities
    - Stores: connection strength, commute patterns, transportation methods
    - **Location:** `lib/core/models/locality_connection.dart`
    - **Tests:** `test/unit/models/locality_connection_test.dart`

---

## 📱 **10. UI/UX Components**

### **NEW Pages (2 files):**

37. **`ClubDiscoveryPage`** (NEW)
    - Page for discovering clubs/communities
    - Browse by category, location, expertise coverage
    - Join clubs/communities
    - **Location:** `lib/presentation/pages/clubs/club_discovery_page.dart`
    - **Tests:** `test/widget/pages/clubs/club_discovery_page_test.dart`

38. **`CommunityEventsPage`** (NEW)
    - Dedicated page for community events
    - Filter by type, location, host
    - Show upgrade eligibility
    - **Location:** `lib/presentation/pages/events/community_events_page.dart`
    - **Tests:** `test/widget/pages/events/community_events_page_test.dart`

### **NEW Widgets (5 files):**

39. **`EventScopeTabsWidget`** (NEW)
    - Widget for event scope tabs (Community, Locality, City, etc.)
    - Tab navigation and filtering
    - **Location:** `lib/presentation/widgets/events/event_scope_tabs_widget.dart`
    - **Tests:** `test/widget/widgets/events/event_scope_tabs_widget_test.dart`

40. **`LocalExpertPriorityBadge`** (NEW)
    - Badge showing local expert priority
    - Displayed on local expert events in their locality
    - **Location:** `lib/presentation/widgets/expertise/local_expert_priority_badge.dart`
    - **Tests:** `test/widget/widgets/expertise/local_expert_priority_badge_test.dart`

41. **`ReputationScoreWidget`** (NEW)
    - Widget displaying reputation score (for matching, not ranking)
    - Shows locality-specific reputation
    - **Location:** `lib/presentation/widgets/expertise/reputation_score_widget.dart`
    - **Tests:** `test/widget/widgets/expertise/reputation_score_widget_test.dart`

42. **`ExpansionTimelineWidget`** (NEW)
    - Widget showing expansion timeline for clubs/communities
    - Visual representation of geographic expansion
    - **Location:** `lib/presentation/widgets/clubs/expansion_timeline_widget.dart`
    - **Tests:** `test/widget/widgets/clubs/expansion_timeline_widget_test.dart`

43. **`LocalityValuesWidget`** (NEW)
    - Widget showing what a locality values
    - Display locality preferences (events, lists, reviews, etc.)
    - **Location:** `lib/presentation/widgets/locality/locality_values_widget.dart`
    - **Tests:** `test/widget/widgets/locality/locality_values_widget_test.dart`

---

## 🧪 **11. Test Files**

### **Integration Tests (8 files):**

44. **`geographic_scope_integration_test.dart`** (NEW)
45. **`community_events_integration_test.dart`** (NEW)
46. **`clubs_communities_integration_test.dart`** (NEW)
47. **`expansion_expertise_gain_integration_test.dart`** (NEW)
48. **`reputation_matching_integration_test.dart`** (NEW)
49. **`local_expert_qualification_integration_test.dart`** (NEW)
50. **`golden_expert_ai_influence_integration_test.dart`** (NEW)
51. **`event_discovery_preferences_integration_test.dart`** (NEW)

---

## 📊 **Summary**

### **By Category:**

- **Services:** 19 new services (+ 1 major update to existing)
- **Models:** 8 new models
- **UI Pages:** 4 new pages
- **UI Widgets:** 7 new widgets
- **Integration Tests:** 8 new test files
- **Unit Tests:** ~36 new test files (one per service/model)
- **Widget Tests:** ~11 new test files (one per widget/page)

### **Total New Files:**

- **Core Code:** ~27 new files (services + models)
- **UI Code:** ~11 new files (pages + widgets)
- **Test Code:** ~55 new test files
- **Total:** ~93 new files to create

### **Major Updates to Existing Files:**

- **`BusinessExpertMatchingService`** - Major refactor for vibe-first matching
  - Remove level-based filtering
  - Integrate vibe matching (50% weight)
  - Update AI prompts
  - Make location preferences, not filters

### **Compilation Requirements:**

- All new services must be registered in dependency injection
- All new models must have JSON serialization
- All new UI components must use AppColors/AppTheme
- All new routes must be added to app_router.dart
- All new services must have logging
- All new components must follow SPOTS philosophy

---

## 🚨 **Critical Dependencies**

**Before building new components, ensure:**

1. ✅ Phase 0 complete (existing codebase updated)
2. ✅ Geographic hierarchy understood
3. ✅ Database schema supports new models
4. ✅ Dependency injection configured
5. ✅ Routing system ready for new pages
6. ✅ Test infrastructure in place

---

**Last Updated:** November 23, 2025  
**Status:** Complete List - Ready for Implementation

