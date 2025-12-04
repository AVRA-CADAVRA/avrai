# Phase 6 Agent Prompts - Local Expert System Redesign (Week 26-27)

**Date:** November 24, 2025  
**Purpose:** Ready-to-use prompts for Phase 6, Week 26-27 (Event Discovery & Matching - Phase 2) agents  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 26-27 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Verify:** Week 25.5 (Phase 1.5) is COMPLETE - Business-Expert Matching Updates done

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_6/week_26_27_prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_6/week_26_27_task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_6_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_6.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: Tasks Are Assigned = Phase 6 Week 26-27 Is IN PROGRESS**

**This prompts document EXISTS (along with task assignments), which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 26-27 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document + task assignments exist):**

- ❌ **NO new tasks can be added** to Phase 6 Week 26-27
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 26-27 Overview**

**Duration:** Week 26-27 (2 weeks)  
**Focus:** Event Discovery & Matching (Phase 2)  
**Priority:** P1 - Core Functionality  
**Philosophy:** Users find likeminded people and events, explore neighboring localities

**What Doors Does This Open?**
- **Discovery Doors:** Users find events from likeminded local experts
- **Connection Doors:** Users discover events in connected localities
- **Preference Doors:** System learns user preferences and recommends personalized events
- **Exploration Doors:** Users can explore events outside their typical behavior

**When Are Users Ready?**
- After local experts are hosting events
- System prioritizes local experts in event rankings
- Cross-locality connections are identified
- User preferences are learned and applied

**Why Critical:**
- Ensures local experts are prioritized in event discovery
- Enables cross-locality event sharing (neighborhood connections)
- Personalizes event recommendations based on user behavior
- Balances familiar preferences with exploration

**Dependencies:**
- ✅ Week 25.5 (Phase 1.5) COMPLETE - Business-Expert Matching Updates done
- ✅ Week 24-25 (Phase 1) COMPLETE - Geographic hierarchy and local expert qualification done
- ✅ ExpertiseEventService exists
- ✅ GeographicScopeService exists

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 26 Prompt:**

```
You are Agent 1 working on Phase 6, Week 26: Reputation/Matching System & Cross-Locality Connections.

**Your Role:** Backend & Integration Specialist
**Focus:** EventMatchingService, CrossLocalityConnectionService, Local Expert Priority Logic

**Context:**
- ✅ Week 25.5 (Phase 1.5) is COMPLETE - Business-Expert Matching Updates done
- ✅ Week 24-25 (Phase 1) is COMPLETE - Geographic hierarchy and local expert qualification done
- ✅ ExpertiseEventService exists (from Phase 1)
- ✅ GeographicScopeService exists (from Week 24)
- 🎯 **START WORK NOW** - Create event matching and cross-locality connection services

**Your Tasks:**

**Day 1-3: EventMatchingService (Reputation/Matching Score Service)**
1. Create `lib/core/services/event_matching_service.dart`
   - Calculate matching signals (not formal ranking):
     * Events hosted count (more events = higher signal)
     * Event ratings (average rating from attendees)
     * Followers count (users following the expert)
     * External social following (if available)
     * Community recognition (partnerships, collaborations)
     * Event growth (community building - attendance growth over time)
     * Active list respects (users adding events to their lists)
   - Implement locality-specific weighting:
     * Higher weight for signals in user's locality
     * Lower weight for signals outside locality
     * Geographic interaction patterns (where user attends events)
   - Create `calculateMatchingScore()` method:
     * Takes expert, user, category, locality
     * Returns matching score (0.0 to 1.0)
     * Uses locality-specific weighting
   - Create `getMatchingSignals()` method:
     * Returns breakdown of matching signals
     * Useful for debugging and UI display
   - Integrate with ExpertiseEventService:
     * Get events hosted by expert
     * Get event ratings and attendance
     * Get user interactions with events

2. Local Expert Priority Logic
   - Update event ranking algorithm in ExpertiseEventService:
     * Priority: Local expert > City expert (when hosting in locality)
     * Add locality matching boost
     * Ensure local experts rank higher in their locality
   - Create `_calculateLocalExpertPriority()` method:
     * Checks if expert is local level
     * Checks if event is in expert's locality
     * Returns priority boost (0.0 to 1.0)
   - Update `searchEvents()` in ExpertiseEventService:
     * Apply local expert priority boost
     * Sort events with local experts first (in their locality)

**Day 4-5: CrossLocalityConnectionService**
1. Create `lib/core/services/cross_locality_connection_service.dart`
   - Track user movement patterns:
     * Commute patterns (regular travel between localities)
     * Travel patterns (occasional travel)
     * Fun/exploration patterns (visiting new localities)
   - Identify connected localities:
     * Not just distance-based
     * Based on actual user movement
     * Transportation method tracking (car, transit, walking)
   - Metro area detection:
     * Identify metro areas (e.g., SF Bay Area, NYC Metro)
     * Connect localities within same metro area
   - Create `getConnectedLocalities()` method:
     * Takes user and locality
     * Returns list of connected localities
     * Sorted by connection strength
   - Create `getUserMovementPatterns()` method:
     * Returns user's movement patterns
     * Includes commute, travel, fun patterns
   - Create `isInSameMetroArea()` method:
     * Checks if two localities are in same metro area
     * Uses metro area definitions

2. Integration with Event Discovery
   - Integrate CrossLocalityConnectionService with ExpertiseEventService:
     * Include events from connected localities
     * Show events from connected localities in search results
     * Apply connection strength to ranking

**Deliverables:**
- EventMatchingService created with matching signals
- Locality-specific weighting implemented
- Local expert priority logic implemented
- CrossLocalityConnectionService created
- User movement patterns tracked
- Connected localities identified
- Metro area detection working
- Integration with ExpertiseEventService complete
- Zero linter errors
- All services follow existing patterns

**Dependencies:**
- ✅ Week 25.5 COMPLETE
- ✅ Week 24-25 COMPLETE
- ✅ ExpertiseEventService (exists)
- ✅ GeographicScopeService (exists)
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
- lib/core/services/event_matching_service.dart
- lib/core/services/cross_locality_connection_service.dart

**Files to Modify:**
- lib/core/services/expertise_event_service.dart (search/ranking updates)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_26_27_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

### **Week 27 Prompt:**

```
You are Agent 1 working on Phase 6, Week 27: Events Page Organization & User Preference Learning.

**Your Role:** Backend & Integration Specialist
**Focus:** UserPreferenceLearningService, EventRecommendationService

**Context:**
- ✅ Week 26 is COMPLETE - EventMatchingService and CrossLocalityConnectionService done
- ✅ ExpertiseEventService exists
- ✅ EventMatchingService exists (from Week 26)
- 🎯 **START WORK NOW** - Create preference learning and recommendation services

**Your Tasks:**

**Day 1-3: UserPreferenceLearningService**
1. Create `lib/core/services/user_preference_learning_service.dart`
   - Track user event attendance patterns:
     * Events attended (by category, locality, scope)
     * Events saved/added to list
     * Events shared/recommended
     * Events rated/reviewed
   - Learn preferences:
     * Local vs city experts (preference weight)
     * Category preferences (which categories user prefers)
     * Locality preferences (which localities user prefers)
     * Scope preferences (local vs city vs state events)
     * Event type preferences (workshop vs tour vs tasting)
   - Suggest events outside typical behavior (exploration):
     * Identify exploration opportunities
     * Balance familiar preferences with exploration
     * Suggest events in new categories/localities
   - Create `learnUserPreferences()` method:
     * Analyzes user event history
     * Updates user preference profile
     * Returns learned preferences
   - Create `getUserPreferences()` method:
     * Returns current user preferences
     * Includes preference weights
   - Create `suggestExplorationEvents()` method:
     * Suggests events outside typical behavior
     * Returns exploration opportunities

**Day 4-5: EventRecommendationService**
1. Create `lib/core/services/event_recommendation_service.dart`
   - Integrate preference learning with event matching:
     * Use UserPreferenceLearningService
     * Use EventMatchingService
     * Combine preferences with matching scores
   - Generate personalized event recommendations:
     * Balance familiar preferences with exploration
     * Show local expert events to users who prefer local events
     * Show city/state events to users who prefer broader scope
     * Include cross-locality events for users with movement patterns
   - Create `getPersonalizedRecommendations()` method:
     * Takes user and optional filters
     * Returns personalized event recommendations
     * Sorted by relevance score
   - Create `getRecommendationsForScope()` method:
     * Returns recommendations for specific scope (locality, city, etc.)
     * Uses user preferences for that scope
   - Integration with EventsBrowsePage:
     * Provide recommendations per tab
     * Support tab-based filtering

**Deliverables:**
- UserPreferenceLearningService created
- User preferences learned from attendance patterns
- Exploration suggestions working
- EventRecommendationService created
- Personalized recommendations generated
- Integration with EventsBrowsePage complete
- Zero linter errors
- All services follow existing patterns

**Dependencies:**
- ✅ Week 26 COMPLETE
- ✅ EventMatchingService (exists)
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
- lib/core/services/user_preference_learning_service.dart
- lib/core/services/event_recommendation_service.dart

**Files to Modify:**
- lib/core/services/expertise_event_service.dart (integration)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_26_27_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Week 26 Prompt:**

```
You are Agent 2 working on Phase 6, Week 26: Reputation/Matching System & Cross-Locality Connections.

**Your Role:** Frontend & UX Specialist
**Focus:** Events Page UI Prep (Week 26 prep, Week 27 main work)

**Context:**
- ✅ Week 25.5 (Phase 1.5) is COMPLETE
- ✅ Week 24-25 (Phase 1) is COMPLETE
- 🎯 **PREP FOR WEEK 27** - Review EventsBrowsePage and design tab structure

**Your Tasks:**

**Day 1-2: Review & Prepare for Week 27**
1. Review existing EventsBrowsePage
   - Understand current structure
   - Identify where tabs will be added
   - Plan tab-based filtering implementation
   - Review event search functionality

2. Design Tab Structure
   - Plan tabs: Community, Locality, City, State, Nation, Globe, Universe, Clubs/Communities
   - Design tab UI (following AppColors/AppTheme)
   - Plan filtering logic per tab
   - Plan event display per tab

**Day 3-5: Week 27 Prep (Early Start)**
1. Create Tab Widget (if starting early)
   - Create `lib/presentation/widgets/events/event_scope_tab_widget.dart`
   - Implement tab switching
   - Use AppColors/AppTheme (100% adherence)
   - Follow existing UI patterns

**Deliverables:**
- EventsBrowsePage reviewed and understood
- Tab structure designed
- Ready for Week 27 implementation

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress

**Files to Review:**
- lib/presentation/pages/events/events_browse_page.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_26_27_task_assignments.md`
```

### **Week 27 Prompt:**

```
You are Agent 2 working on Phase 6, Week 27: Events Page Organization & User Preference Learning.

**Your Role:** Frontend & UX Specialist
**Focus:** Events Page Tabs, Event Search Filtering

**Context:**
- ✅ Week 26 is COMPLETE - EventMatchingService and CrossLocalityConnectionService done
- ✅ Agent 1 is creating UserPreferenceLearningService and EventRecommendationService
- 🎯 **START WORK NOW** - Implement events page tabs and filtering

**Your Tasks:**

**Day 1-3: Events Page Tabs**
1. Update `lib/presentation/pages/events/events_browse_page.dart`
   - Add tab structure:
     * Community (non-expert events)
     * Locality
     * City
     * State
     * Nation
     * Globe
     * Universe
     * Clubs/Communities
   - Implement tab-based filtering:
     * Filter events by scope per tab
     * Update event search to filter by scope
     * Show events appropriate for each scope
   - Use AppColors/AppTheme (100% adherence):
     * Tab colors from AppColors
     * Tab styling from AppTheme
     * No direct Colors.* usage
   - Follow existing UI patterns:
     * Consistent with other tab implementations
     * Responsive design
     * Accessibility support

**Day 4-5: Event Search & Filtering Integration**
1. Update Event Search
   - Integrate with EventRecommendationService:
     * Use personalized recommendations per tab
     * Show recommendations based on user preferences
   - Integrate with EventMatchingService:
     * Show matching scores in UI (optional)
     * Sort by matching score
   - Integrate with CrossLocalityConnectionService:
     * Show events from connected localities
     * Indicate cross-locality events
   - Update filters:
     * Scope filter (already in tabs)
     * Category filter (per scope)
     * Location filter (per scope)
     * Date filter (per scope)
     * Price filter (per scope)

**Deliverables:**
- Events page tabs implemented
- Tab-based filtering working
- Event search updated for scope filtering
- Integration with recommendation service
- Integration with matching service
- Integration with cross-locality service
- Zero linter errors
- 100% AppColors/AppTheme adherence
- Responsive and accessible

**Dependencies:**
- ✅ Week 26 COMPLETE
- ✅ Agent 1 EventRecommendationService (complete)
- ✅ EventMatchingService (exists)
- ✅ CrossLocalityConnectionService (exists)

**Quality Standards:**
- Zero linter errors
- 100% AppColors/AppTheme adherence (NO direct Colors.*)
- Responsive design
- Accessibility support
- Follow existing UI patterns

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_2/phase_6/`

**Files to Modify:**
- lib/presentation/pages/events/events_browse_page.dart

**Files to Create (if needed):**
- lib/presentation/widgets/events/event_scope_tab_widget.dart
- lib/presentation/widgets/events/event_recommendation_widget.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_26_27_task_assignments.md`
```

---

## 🧪 **Agent 3: Models & Testing**

### **Week 26 Prompt:**

```
You are Agent 3 working on Phase 6, Week 26: Reputation/Matching System & Cross-Locality Connections - Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Event Matching Models, Tests, Documentation

**Context:**
- ✅ Week 25.5 (Phase 1.5) is COMPLETE
- ✅ Agent 1 is creating EventMatchingService and CrossLocalityConnectionService (in parallel)
- 🎯 **START WORK NOW** - Create models, tests, and documentation
- ⚠️ **CRITICAL:** Write tests based on specifications/requirements (TDD approach) - DO NOT wait for Agent 1's implementation
- ⚠️ **After Agent 1 completes:** Verify tests pass and update if implementation differs from spec
- 📖 **Full Protocol:** See `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md` for detailed workflow model

**Your Tasks:**

**Day 1-3: Event Matching Models**
1. Create `lib/core/models/event_matching_score.dart`
   - Model for event matching scores
   - Includes matching signals breakdown
   - Includes locality-specific weighting
   - Includes local expert priority boost

2. Create `lib/core/models/cross_locality_connection.dart`
   - Model for cross-locality connections
   - Includes connection strength
   - Includes movement pattern type
   - Includes transportation method

3. Create `lib/core/models/user_movement_pattern.dart`
   - Model for user movement patterns
   - Includes commute, travel, fun patterns
   - Includes frequency and timing
   - Includes transportation method

**Day 4-5: Tests & Documentation**
1. Create `test/unit/services/event_matching_service_test.dart`
   - Test matching signals calculation
   - Test locality-specific weighting
   - Test local expert priority
   - Test matching score calculation

2. Create `test/unit/services/cross_locality_connection_service_test.dart`
   - Test connected localities identification
   - Test user movement patterns tracking
   - Test metro area detection
   - Test connection strength calculation

3. Create Integration Tests
   - Test event ranking with local expert priority
   - Test cross-locality event discovery
   - Test matching score integration

4. Documentation
   - Document EventMatchingService
   - Document CrossLocalityConnectionService
   - Document local expert priority logic
   - Update system documentation

**Deliverables:**
- Event matching models created
- Cross-locality connection models created
- User movement pattern model created
- Comprehensive tests created
- Integration tests created
- Documentation complete
- All tests pass
- Test coverage > 90%

**Dependencies:**
- ✅ Week 25.5 COMPLETE
- ⚠️ **TESTING WORKFLOW:** Write tests based on specifications/requirements (TDD approach)
- ⚠️ **DO NOT WAIT** for Agent 1's implementation - write tests based on task assignments and requirements
- ⚠️ **After Agent 1 completes:** Verify tests pass and update if implementation differs from spec

**Quality Standards:**
- Zero linter errors
- All tests pass
- Test coverage > 90%
- All tests follow existing patterns
- Comprehensive test documentation

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_3/phase_6/`

**Files to Create:**
- lib/core/models/event_matching_score.dart
- lib/core/models/cross_locality_connection.dart
- lib/core/models/user_movement_pattern.dart
- test/unit/services/event_matching_service_test.dart
- test/unit/services/cross_locality_connection_service_test.dart
- test/integration/event_matching_integration_test.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_26_27_task_assignments.md`
```

### **Week 27 Prompt:**

```
You are Agent 3 working on Phase 6, Week 27: Events Page Organization & User Preference Learning - Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Preference Models, Tests, Documentation

**Context:**
- ✅ Week 26 is COMPLETE - EventMatchingService and CrossLocalityConnectionService done
- ✅ Agent 1 is creating UserPreferenceLearningService and EventRecommendationService (in parallel)
- 🎯 **START WORK NOW** - Create preference models, tests, and documentation
- ⚠️ **CRITICAL:** Write tests based on specifications/requirements (TDD approach) - DO NOT wait for Agent 1's implementation
- ⚠️ **After Agent 1 completes:** Verify tests pass and update if implementation differs from spec
- 📖 **Full Protocol:** See `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md` for detailed workflow model

**Your Tasks:**

**Day 1-2: Preference Models**
1. Create `lib/core/models/user_preferences.dart`
   - Model for user preferences
   - Includes preference weights
   - Includes category preferences
   - Includes locality preferences
   - Includes scope preferences

2. Create `lib/core/models/event_recommendation.dart`
   - Model for event recommendations
   - Includes relevance score
   - Includes recommendation reason
   - Includes preference match details

**Day 3-5: Tests & Documentation**
1. Create `test/unit/services/user_preference_learning_service_test.dart`
   - Test preference learning from attendance
   - Test preference weight calculation
   - Test exploration suggestions
   - Test preference updates

2. Create `test/unit/services/event_recommendation_service_test.dart`
   - Test personalized recommendations
   - Test scope-based recommendations
   - Test preference integration
   - Test exploration balance

3. Create Integration Tests
   - Test end-to-end recommendation flow
   - Test tab-based filtering
   - Test cross-locality recommendations

4. Documentation
   - Document UserPreferenceLearningService
   - Document EventRecommendationService
   - Document preference learning algorithm
   - Update system documentation

**Deliverables:**
- User preference models created
- Event recommendation models created
- Comprehensive tests created
- Integration tests created
- Documentation complete
- All tests pass
- Test coverage > 90%

**Dependencies:**
- ✅ Week 26 COMPLETE
- ⚠️ **TESTING WORKFLOW:** Write tests based on specifications/requirements (TDD approach)
- ⚠️ **DO NOT WAIT** for Agent 1's implementation - write tests based on task assignments and requirements
- ⚠️ **After Agent 1 completes:** Verify tests pass and update if implementation differs from spec

**Quality Standards:**
- Zero linter errors
- All tests pass
- Test coverage > 90%
- All tests follow existing patterns
- Comprehensive test documentation

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_3/phase_6/`

**Files to Create:**
- lib/core/models/user_preferences.dart
- lib/core/models/event_recommendation.dart
- test/unit/services/user_preference_learning_service_test.dart
- test/unit/services/event_recommendation_service_test.dart
- test/integration/event_recommendation_integration_test.dart

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_26_27_task_assignments.md`
```

---

## 📊 **Success Criteria**

### **Week 26:**
- [ ] EventMatchingService calculates matching signals correctly
- [ ] Locality-specific weighting works
- [ ] Local experts rank higher in their locality
- [ ] CrossLocalityConnectionService identifies connected localities
- [ ] User movement patterns tracked
- [ ] Metro area detection working
- [ ] Integration with ExpertiseEventService complete

### **Week 27:**
- [ ] Events page organized by scope (tabs)
- [ ] User preferences learned from attendance
- [ ] Personalized recommendations generated
- [ ] Exploration suggestions working
- [ ] Tab-based filtering working
- [ ] Integration complete

---

## 📝 **Notes**

- **Local Expert Priority:** Critical for ensuring local experts are visible in their locality
- **Cross-Locality Connections:** Enables neighborhood-level event discovery
- **Preference Learning:** Balances familiar preferences with exploration
- **Tab Organization:** Makes event discovery intuitive by scope

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Start

