# Phase 6 Agent Prompts - Local Expert System Redesign (Week 30)

**Date:** November 24, 2025  
**Purpose:** Ready-to-use prompts for agents working on Phase 6, Week 30 (Expertise Expansion - Phase 3, Week 3)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_6/week_30_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`** - Detailed implementation plan
6. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`** - Complete requirements
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/week_30_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Week 30 Overview**

**Focus:** Expertise Expansion (Phase 3, Week 3)  
**Duration:** 5 days  
**Priority:** P1 - Core Functionality

**What Doors Does This Open?**
- **Expansion Doors:** Clubs can expand geographically (locality → city → state → nation → globe → universe)
- **Expertise Doors:** Club leaders gain expertise in all localities where club hosts events
- **Coverage Doors:** 75% coverage rule enables expertise gain at each geographic level
- **Recognition Doors:** Leadership role grants expert status
- **Growth Doors:** Natural geographic expansion through community growth

**Philosophy Alignment:**
- Clubs/communities can expand naturally (doors open through growth)
- Club leaders recognized as experts (doors for leaders)
- 75% coverage rule (fair expertise gain thresholds)
- Geographic expansion enabled (locality → universe)

**Dependencies:**
- ✅ Week 29 (Phase 3, Week 2) COMPLETE - Clubs/Communities done
- ✅ CommunityService exists
- ✅ ClubService exists
- ✅ Club model exists
- ✅ ExpertiseCalculationService exists

---

## 🤖 **Agent 1: Backend & Integration**

### **Prompt for Agent 1:**

```
You are Agent 1: Backend & Integration Specialist working on Phase 6, Week 30 (Expertise Expansion - Phase 3, Week 3).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 30 - Expertise Expansion (Phase 3, Week 3)  
**Status:** Ready to Start  
**Dependencies:** Week 29 (Clubs/Communities) COMPLETE

**What You're Building:**
- GeographicExpansion Model - Tracks expansion from original locality
- GeographicExpansionService - Tracks expansion, calculates coverage, checks 75% thresholds
- ExpansionExpertiseGainService - Grants expertise when expansion thresholds are met
- Club Leader Expertise Recognition - Leaders gain expertise in all localities where club hosts events

**Philosophy:**
- Clubs/communities can expand naturally (doors open through growth)
- Club leaders recognized as experts (doors for leaders)
- 75% coverage rule (fair expertise gain thresholds)
- Geographic expansion enabled (locality → universe)

## Tasks

**Day 1-2: GeographicExpansion Model & GeographicExpansionService**
1. Create `lib/core/models/geographic_expansion.dart`
   - Model for tracking expansion from original locality
   - Store original locality, expanded localities/cities/states/nations
   - Coverage percentages by geographic level (locality, city, state, nation, global)
   - Track coverage methods (commute patterns, event hosting locations)
   - Expansion timeline (expansion history, first/last expansion timestamps)
   - Follow existing model patterns (Equatable, JSON, CopyWith, helpers)

2. Create `lib/core/services/geographic_expansion_service.dart`
   - Track event expansion from original locality (trackEventExpansion, trackCommutePattern)
   - Measure coverage (commute patterns OR event hosting):
     - calculateLocalityCoverage, calculateCityCoverage, calculateStateCoverage, calculateNationCoverage, calculateGlobalCoverage
   - Calculate 75% thresholds for each geographic level:
     - hasReachedLocalityThreshold, hasReachedCityThreshold, hasReachedStateThreshold, hasReachedNationThreshold, hasReachedGlobalThreshold
   - Expansion management (getExpansionByClub, getExpansionByCommunity, updateExpansion, getExpansionHistory)

**Day 3-4: ExpansionExpertiseGainService & Club Leader Expertise**
3. Create `lib/core/services/expansion_expertise_gain_service.dart`
   - Implement expertise gain logic from expansion:
     - checkAndGrantLocalityExpertise, checkAndGrantCityExpertise, checkAndGrantStateExpertise, checkAndGrantNationExpertise, checkAndGrantGlobalExpertise, checkAndGrantUniversalExpertise
   - Update expertise when expansion thresholds met:
     - grantExpertiseFromExpansion (main method), updateUserExpertise, notifyExpertiseGain
   - Integration with ExpertiseCalculationService (use to update expertise, preserve existing expertise)

4. Modify `lib/core/services/club_service.dart`
   - Add club leader expertise recognition:
     - grantLeaderExpertise (grant expertise to leaders in all localities where club hosts events)
     - updateLeaderExpertise (update leader expertise when club expands)
     - getLeaderExpertise (get expertise for a club leader)
   - Integration with ExpansionExpertiseGainService (call when club expands, grant expertise to leaders automatically)

5. Modify `lib/core/services/expertise_calculation_service.dart`
   - Add expansion-based expertise calculation:
     - calculateExpertiseFromExpansion (calculate expertise from geographic expansion)
     - Integration with ExpansionExpertiseGainService
     - Preserve existing expertise calculation logic

**Day 5: Integration & Updates**
6. Update `lib/core/models/club.dart`
   - Add expansion tracking fields (if not already present):
     - geographicExpansion (GeographicExpansion object)
     - Verify expansionLocalities, expansionCities, coveragePercentage integration
   - Add leader expertise tracking:
     - leaderExpertise (Map of leader ID → expertise map)

7. Update `lib/core/services/community_service.dart`
   - Integration with GeographicExpansionService:
     - Track expansion when community hosts events in new localities
     - Update expansion history

## Deliverables

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
- ✅ Backward compatibility maintained

## Quality Standards

- **Zero linter errors** (mandatory)
- **Follow existing patterns** (models, services, error handling)
- **Comprehensive logging** (use AppLogger)
- **Error handling** (try-catch, validation, clear error messages)
- **Documentation** (inline comments, method documentation)
- **Philosophy alignment** (doors, not badges)

## Dependencies

- ✅ Week 29 (Clubs/Communities) COMPLETE
- ✅ CommunityService exists
- ✅ ClubService exists
- ✅ Club model exists
- ✅ ExpertiseCalculationService exists

## Testing

- Agent 3 will create tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Update service documentation
- Document 75% coverage rule
- Document club leader expertise recognition
- Document expansion flow
- Create completion report: `docs/agents/reports/agent_1/phase_6/week_30_expertise_expansion_services.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_30_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`

**START WORK NOW.**
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Prompt for Agent 2:**

```
You are Agent 2: Frontend & UX Specialist working on Phase 6, Week 30 (Expertise Expansion - Phase 3, Week 3).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 30 - Expertise Expansion (Phase 3, Week 3)  
**Status:** Ready to Start  
**Dependencies:** Week 29 (Clubs/Communities) COMPLETE, Agent 1 creating expansion services

**What You're Building:**
- ExpertiseCoverageWidget updates (add map view, enhanced coverage metrics)
- ExpansionTimelineWidget (new widget showing expansion timeline)
- ClubPage updates (add map visualization and timeline)
- CommunityPage updates (add expansion tracking)

**Philosophy:**
- Show doors (geographic expansion) that clubs can open
- Visualize expansion progress (locality → universe)
- Show expertise coverage (75% thresholds, coverage percentages)
- Display expansion timeline (when, where, how)

## Tasks

**Day 1-3: Expertise Coverage Map Visualization**
1. Update `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`
   - Add map view (prepared in Week 29, now implement):
     - Interactive map showing coverage by locality
     - Color-coded by expertise level (local, city, state, national, global, universal)
     - Show coverage percentage for each geographic level
     - Show 75% threshold indicators
   - Enhanced coverage metrics display:
     - Locality coverage (list of all localities with coverage percentages)
     - City coverage (75% threshold indicator, coverage percentage)
     - State coverage (75% threshold indicator, coverage percentage)
     - National coverage (75% threshold indicator, coverage percentage)
     - Global coverage (75% threshold indicator, coverage percentage)
     - Universal status (if achieved)
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Follow existing widget patterns

2. Create `lib/presentation/widgets/clubs/expansion_timeline_widget.dart`
   - Display expansion timeline:
     - Shows how community/club expanded from original locality
     - Timeline of expansion events (when, where, how)
     - Visual representation of expansion path
     - Show coverage milestones (75% thresholds reached)
   - Expansion details:
     - Events hosted in each locality
     - Commute patterns (people traveling to events)
     - Coverage percentages over time
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Follow existing widget patterns

**Day 4-5: Club/Community Page Updates**
3. Update `lib/presentation/pages/clubs/club_page.dart`
   - Add expertise coverage map visualization:
     - Integrate updated ExpertiseCoverageWidget
     - Show map view of coverage
     - Show coverage metrics
   - Add expansion timeline:
     - Integrate ExpansionTimelineWidget
     - Show expansion history
   - Add leader expertise display:
     - Show expertise levels of club leaders
     - Show expertise gained through club expansion
     - Geographic expertise map for each leader
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)

4. Update `lib/presentation/pages/communities/community_page.dart`
   - Add expansion tracking display:
     - Show current localities where community is active
     - Show expansion progress
     - Show coverage percentages (if available)

## Deliverables

- ✅ ExpertiseCoverageWidget updated with map view
- ✅ ExpansionTimelineWidget created
- ✅ ClubPage updated with map visualization and timeline
- ✅ CommunityPage updated with expansion tracking
- ✅ Zero linter errors
- ✅ 100% AppColors/AppTheme adherence (NO direct Colors.* usage)
- ✅ Responsive and accessible

## Quality Standards

- **Zero linter errors** (mandatory)
- **100% AppColors/AppTheme adherence** (NO direct Colors.* usage - will be flagged)
- **Follow existing UI patterns** (pages, widgets, navigation)
- **Responsive design** (mobile, tablet, desktop)
- **Accessibility** (semantic labels, keyboard navigation)
- **Philosophy alignment** (show doors, not badges)

## Dependencies

- ✅ Week 29 (Clubs/Communities) COMPLETE
- ⏳ Agent 1 creating GeographicExpansionService and ExpansionExpertiseGainService (work in parallel)
- ✅ CommunityService exists
- ✅ ClubService exists
- ✅ ExpertiseCalculationService exists

## Integration Points

- **GeographicExpansionService:** Load expansion data, coverage percentages
- **ExpansionExpertiseGainService:** Load expertise gain information
- **ClubService:** Load club expansion, leader expertise
- **CommunityService:** Load community expansion

## Testing

- Agent 3 will create widget tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Document UI components
- Document integration points
- Create completion report: `docs/agents/reports/agent_2/phase_6/week_30_agent_2_completion.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_30_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Design Tokens: `lib/core/theme/colors.dart` and `lib/core/theme/app_theme.dart`

**START WORK NOW.**
```

---

## 🧪 **Agent 3: Models & Testing**

### **Prompt for Agent 3:**

```
You are Agent 3: Models & Testing Specialist working on Phase 6, Week 30 (Expertise Expansion - Phase 3, Week 3).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 30 - Expertise Expansion (Phase 3, Week 3)  
**Status:** Ready to Start  
**Dependencies:** Week 29 (Clubs/Communities) COMPLETE, Agent 1 creating expansion services

**What You're Testing:**
- GeographicExpansion Model - Tracks expansion from original locality
- GeographicExpansionService - Tracks expansion, calculates coverage, checks 75% thresholds
- ExpansionExpertiseGainService - Grants expertise when expansion thresholds are met
- Club Leader Expertise Recognition - Leaders gain expertise in all localities where club hosts events

**Philosophy:**
- Clubs/communities can expand naturally (doors open through growth)
- Club leaders recognized as experts (doors for leaders)
- 75% coverage rule (fair expertise gain thresholds)
- Geographic expansion enabled (locality → universe)

## Testing Workflow (TDD Approach)

**Follow the parallel testing workflow protocol:**
- Read `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Write tests based on specifications (before or in parallel with Agent 1's implementation)
- Tests serve as specifications for Agent 1
- Verify implementation matches test specifications

## Tasks

**Day 1-2: Review Models (if needed)**
1. Review GeographicExpansion Model (created by Agent 1)
   - Verify model structure
   - Verify expansion tracking
   - Verify coverage calculation
   - Create additional models if needed

**Day 3-5: Tests & Documentation**
2. Create `test/unit/models/geographic_expansion_test.dart`
   - Test model creation
   - Test expansion tracking
   - Test coverage calculation
   - Test expansion history
   - Test JSON serialization/deserialization

3. Create `test/unit/services/geographic_expansion_service_test.dart`
   - Test event expansion tracking
   - Test commute pattern tracking
   - Test coverage calculation (locality, city, state, nation, global)
   - Test 75% threshold checking
   - Test expansion management

4. Create `test/unit/services/expansion_expertise_gain_service_test.dart`
   - Test expertise gain from expansion
   - Test 75% threshold expertise grants
   - Test locality expertise gain
   - Test city expertise gain
   - Test state expertise gain
   - Test nation expertise gain
   - Test global expertise gain
   - Test universal expertise gain
   - Test integration with ExpertiseCalculationService

5. Create Integration Tests
   - Test end-to-end expansion flow (event → expansion → expertise gain)
   - Test club leader expertise recognition
   - Test 75% coverage rule
   - Test expansion timeline

6. Documentation
   - Document GeographicExpansion model
   - Document GeographicExpansionService
   - Document ExpansionExpertiseGainService
   - Document 75% coverage rule
   - Document club leader expertise recognition
   - Update system documentation

## Deliverables

- ✅ GeographicExpansion model tests created
- ✅ GeographicExpansionService tests created
- ✅ ExpansionExpertiseGainService tests created
- ✅ Integration tests created
- ✅ Documentation complete
- ✅ All tests pass
- ✅ Test coverage > 90%

## Quality Standards

- **Comprehensive test coverage** (>90%)
- **Test edge cases** (error handling, boundary conditions)
- **Clear test names** (describe what is being tested)
- **Test organization** (group related tests)
- **Documentation** (test documentation, system documentation)

## Testing Workflow

**Follow TDD approach:**
1. Write tests based on specifications (before or in parallel with implementation)
2. Tests serve as specifications for Agent 1
3. Verify implementation matches test specifications
4. Update tests if needed based on actual implementation

**Reference:** `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`

## Dependencies

- ✅ Week 29 (Clubs/Communities) COMPLETE
- ⏳ Agent 1 creating GeographicExpansionService and ExpansionExpertiseGainService (work in parallel)
- ✅ CommunityService exists
- ✅ ClubService exists
- ✅ ExpertiseCalculationService exists

## Documentation

- Document all models and services
- Document 75% coverage rule
- Document club leader expertise recognition
- Document expansion flow
- Update system documentation
- Create completion report: `docs/agents/reports/agent_3/phase_6/week_30_expertise_expansion_tests_documentation.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_30_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Testing Workflow: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`

**START WORK NOW.**
```

---

## 📋 **Quick Reference**

### **Files to Create:**

**Agent 1:**
- `lib/core/models/geographic_expansion.dart`
- `lib/core/services/geographic_expansion_service.dart`
- `lib/core/services/expansion_expertise_gain_service.dart`

**Agent 2:**
- `lib/presentation/widgets/clubs/expansion_timeline_widget.dart`

**Agent 3:**
- `test/unit/models/geographic_expansion_test.dart`
- `test/unit/services/geographic_expansion_service_test.dart`
- `test/unit/services/expansion_expertise_gain_service_test.dart`
- `test/integration/expansion_expertise_gain_integration_test.dart`

### **Files to Modify:**

**Agent 1:**
- `lib/core/services/club_service.dart` (leader expertise recognition)
- `lib/core/services/expertise_calculation_service.dart` (expansion expertise)
- `lib/core/models/club.dart` (expansion tracking, leader expertise)
- `lib/core/services/community_service.dart` (expansion tracking)

**Agent 2:**
- `lib/presentation/widgets/clubs/expertise_coverage_widget.dart` (add map view)
- `lib/presentation/pages/clubs/club_page.dart` (add map and timeline)
- `lib/presentation/pages/communities/community_page.dart` (add expansion tracking)

---

## 🎯 **Success Criteria**

- ✅ All models created and tested
- ✅ All services created and tested
- ✅ All UI components created
- ✅ Zero linter errors
- ✅ Test coverage > 90%
- ✅ Documentation complete
- ✅ Integration working

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Use

