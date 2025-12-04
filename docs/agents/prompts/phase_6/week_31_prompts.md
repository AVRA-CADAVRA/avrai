# Phase 6 Agent Prompts - Local Expert System Redesign (Week 31)

**Date:** November 25, 2025  
**Purpose:** Ready-to-use prompts for agents working on Phase 6, Week 31 (UI/UX & Golden Expert - Phase 4)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_6/week_31_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`** - Detailed implementation plan
6. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`** - Complete requirements
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/week_31_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Week 31 Overview**

**Focus:** UI/UX & Golden Expert (Phase 4)  
**Duration:** 5 days  
**Priority:** P1 - Core Functionality

**What Doors Does This Open?**
- **Influence Doors:** Golden experts shape neighborhood character (10% higher influence)
- **Representation Doors:** AI personality reflects actual community values (golden expert perspective)
- **Recognition Doors:** Golden expert lists/reviews weighted more heavily
- **Community Doors:** Neighborhood character shaped by golden experts (along with all locals, but higher rate)
- **Polish Doors:** Final UI/UX polish for clubs/communities

**Philosophy Alignment:**
- Golden experts shape neighborhood character (doors for community representation)
- AI personality reflects actual community values (doors for authentic representation)
- Golden expert contributions have more influence (doors for recognition)
- Final polish enables better user experience (doors for engagement)

**Dependencies:**
- ✅ Week 30 (Phase 3, Week 3) COMPLETE - Expertise Expansion done
- ✅ ClubPage and CommunityPage exist (from Week 29)
- ✅ ExpertiseCoverageWidget exists (from Week 30)
- ✅ AI personality learning system exists (`lib/core/ai/personality_learning.dart`)

**Note:** Week 31 combines Golden Expert AI Influence (new work) with final UI/UX polish for clubs/communities (already created in Week 29-30).

---

## 🤖 **Agent 1: Backend & Integration**

### **Prompt for Agent 1:**

```
You are Agent 1: Backend & Integration Specialist working on Phase 6, Week 31 (UI/UX & Golden Expert - Phase 4).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 31 - UI/UX & Golden Expert (Phase 4)  
**Status:** Ready to Start  
**Dependencies:** Week 30 (Expertise Expansion) COMPLETE

**What You're Building:**
- GoldenExpertAIInfluenceService - Calculate and apply golden expert weight (10% higher, proportional to residency)
- LocalityPersonalityService - Manage locality AI personality with golden expert influence
- AI Personality Integration - Update personality learning to use golden expert data
- List/Review Weighting - Weight golden expert lists/reviews more heavily

**Philosophy:**
- Golden experts shape neighborhood character (10% higher influence)
- AI personality reflects actual community values (golden expert perspective)
- Golden expert contributions have more influence
- Neighborhood character shaped by golden experts (along with all locals, but higher rate)

## Tasks

**Day 1-2: GoldenExpertAIInfluenceService**
1. Create `lib/core/services/golden_expert_ai_influence_service.dart`
   - Calculate golden expert weight:
     - Base weight: 10% higher (1.1x)
     - Proportional to residency length:
       - Formula: `1.1 + (residencyYears / 100)`
       - Example: 30 years = 1.3x weight (1.1 + 0.2)
       - Example: 25 years = 1.25x weight (1.1 + 0.15)
       - Example: 20 years = 1.2x weight (1.1 + 0.1)
     - Minimum weight: 1.1x (10% higher)
     - Maximum weight: 1.5x (50% higher, for 40+ years)
   - Apply weight to golden expert actions:
     - calculateInfluenceWeight() - Calculate weight for a golden expert
     - applyWeightToBehavior() - Apply weight to behavior data
     - applyWeightToPreferences() - Apply weight to preference data
     - applyWeightToConnections() - Apply weight to connection data
   - Integration with existing services:
     - Use with AI personality learning
     - Use with list/review weighting
     - Use with locality personality shaping

**Day 3-4: LocalityPersonalityService & AI Personality Integration**
2. Create `lib/core/services/locality_personality_service.dart`
   - Manage locality AI personality:
     - getLocalityPersonality() - Get AI personality for a locality
     - updateLocalityPersonality() - Update AI personality based on user behavior
     - incorporateGoldenExpertInfluence() - Incorporate golden expert influence
   - Shape neighborhood "vibe" in system:
     - calculateLocalityVibe() - Calculate overall locality vibe
     - getLocalityPreferences() - Get locality preferences (shaped by golden experts)
     - getLocalityCharacteristics() - Get locality characteristics
   - Golden expert influence:
     - Golden expert behavior influences locality AI personality
     - Golden expert preferences shape locality representation
     - Central AI system uses golden expert perspective

3. Modify AI Personality Learning System
   - Find existing personality learning service (`lib/core/ai/personality_learning.dart`)
   - Update to use golden expert data:
     - Add golden expert weighting integration
     - Apply 10% higher weight to golden expert behavior
   - Update personality calculation:
     - Incorporate golden expert influence
     - Weight golden expert contributions more heavily
     - Shape locality personality based on golden experts

**Day 5: List/Review Weighting & Integration**
4. Modify List/Review Recommendation System
   - Find existing list/review recommendation service
   - Update to weight golden expert lists/reviews higher:
     - Add golden expert weighting
     - Apply weight to golden expert lists/reviews
   - Golden expert contributions have more influence:
     - Lists created by golden experts weighted higher
     - Reviews written by golden experts weighted higher
     - Recommendations prioritize golden expert content
   - Neighborhood character shaped by golden experts:
     - Golden expert lists shape neighborhood recommendations
     - Golden expert reviews influence spot ratings
     - Along with all locals, but higher rate

5. Integration & Updates
   - Integrate GoldenExpertAIInfluenceService with:
     - LocalityPersonalityService
     - AI personality learning system
     - List/review recommendation system
   - Update existing services to use golden expert weighting
   - Ensure backward compatibility

## Deliverables

- ✅ GoldenExpertAIInfluenceService created
- ✅ Golden expert weight calculation working (10% higher, proportional to residency)
- ✅ LocalityPersonalityService created
- ✅ AI personality influenced by golden experts
- ✅ List/review weighting for golden experts working
- ✅ Integration with existing systems complete
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

- ✅ Week 30 (Expertise Expansion) COMPLETE
- ✅ AI personality learning system exists (`lib/core/ai/personality_learning.dart`)
- ✅ List/review recommendation system exists (to be identified)

## Testing

- Agent 3 will create tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Update service documentation
- Document golden expert weight calculation
- Document AI personality influence
- Document list/review weighting
- Create completion report: `docs/agents/reports/agent_1/phase_6/week_31_golden_expert_services.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_31_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- AI Personality Learning: `lib/core/ai/personality_learning.dart`

**START WORK NOW.**
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Prompt for Agent 2:**

```
You are Agent 2: Frontend & UX Specialist working on Phase 6, Week 31 (UI/UX & Golden Expert - Phase 4).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 31 - UI/UX & Golden Expert (Phase 4)  
**Status:** Ready to Start  
**Dependencies:** Week 30 (Expertise Expansion) COMPLETE, Agent 1 creating golden expert services

**What You're Building:**
- Final UI/UX polish for ClubPage, CommunityPage, ExpertiseCoverageWidget
- Golden expert indicators (if needed)
- Final integration testing and polish

**Philosophy:**
- Show doors (polished UI) that users can open
- Make club/community features accessible and beautiful
- Display golden expert status (if applicable)
- Final polish enables better user experience

## Tasks

**Day 1-3: Club/Community UI Polish**
1. Update `lib/presentation/pages/clubs/club_page.dart`
   - Final polish and integration:
     - Ensure all features working correctly
     - Verify ExpertiseCoverageWidget integration
     - Verify ExpansionTimelineWidget integration
     - Verify leader expertise display
     - Add loading states and error handling
     - Improve accessibility
   - Golden expert indicators (if applicable):
     - Show golden expert status for leaders (if they are golden experts)
     - Display golden expert influence indicators
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Responsive design improvements

2. Update `lib/presentation/pages/communities/community_page.dart`
   - Final polish and integration:
     - Ensure all features working correctly
     - Verify expansion tracking display
     - Add loading states and error handling
     - Improve accessibility
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Responsive design improvements

3. Update `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`
   - Final polish:
     - Ensure map view working correctly
     - Verify coverage metrics display
     - Improve visual design
     - Add loading states
     - Improve accessibility
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)

**Day 4-5: Golden Expert UI Indicators (if needed)**
4. Create Golden Expert Indicators (if needed)
   - Create `lib/presentation/widgets/golden_expert_indicator.dart`:
     - Golden expert badge/indicator widget
     - Display golden expert status
     - Show residency length
     - Show influence weight
   - Display golden expert status in user profiles
   - Show golden expert influence in locality pages
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)

5. Final Integration Testing
   - Test all club/community UI flows
   - Test expertise coverage visualization
   - Test expansion timeline
   - Verify all integrations working
   - Test responsive design
   - Test accessibility

## Deliverables

- ✅ ClubPage polished and fully integrated
- ✅ CommunityPage polished and fully integrated
- ✅ ExpertiseCoverageWidget polished
- ✅ Golden expert indicators (if needed)
- ✅ Zero linter errors
- ✅ 100% AppColors/AppTheme adherence (NO direct Colors.* usage)
- ✅ Responsive and accessible
- ✅ All integrations working

## Quality Standards

- **Zero linter errors** (mandatory)
- **100% AppColors/AppTheme adherence** (NO direct Colors.* usage - will be flagged)
- **Follow existing UI patterns** (pages, widgets, navigation)
- **Responsive design** (mobile, tablet, desktop)
- **Accessibility** (semantic labels, keyboard navigation)
- **Philosophy alignment** (show doors, not badges)

## Dependencies

- ✅ Week 30 (Expertise Expansion) COMPLETE
- ⏳ Agent 1 creating GoldenExpertAIInfluenceService and LocalityPersonalityService (work in parallel)
- ✅ ClubPage and CommunityPage exist (from Week 29)
- ✅ ExpertiseCoverageWidget exists (from Week 30)

## Integration Points

- **GoldenExpertAIInfluenceService:** Load golden expert status, influence weight
- **LocalityPersonalityService:** Load locality personality data
- **ClubService:** Load club data, leader expertise
- **CommunityService:** Load community data

## Testing

- Agent 3 will create widget tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Document UI components
- Document integration points
- Create completion report: `docs/agents/reports/agent_2/phase_6/week_31_agent_2_completion.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_31_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Design Tokens: `lib/core/theme/colors.dart` and `lib/core/theme/app_theme.dart`

**START WORK NOW.**
```

---

## 🧪 **Agent 3: Models & Testing**

### **Prompt for Agent 3:**

```
You are Agent 3: Models & Testing Specialist working on Phase 6, Week 31 (UI/UX & Golden Expert - Phase 4).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 31 - UI/UX & Golden Expert (Phase 4)  
**Status:** Ready to Start  
**Dependencies:** Week 30 (Expertise Expansion) COMPLETE, Agent 1 creating golden expert services

**What You're Testing:**
- GoldenExpertAIInfluenceService - Calculate and apply golden expert weight
- LocalityPersonalityService - Manage locality AI personality with golden expert influence
- AI Personality Integration - Personality learning with golden expert data
- List/Review Weighting - Weight golden expert lists/reviews more heavily

**Philosophy:**
- Golden experts shape neighborhood character (10% higher influence)
- AI personality reflects actual community values (golden expert perspective)
- Golden expert contributions have more influence

## Testing Workflow (TDD Approach)

**Follow the parallel testing workflow protocol:**
- Read `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Write tests based on specifications (before or in parallel with Agent 1's implementation)
- Tests serve as specifications for Agent 1
- Verify implementation matches test specifications

## Tasks

**Day 1-2: Review Models (if needed)**
1. Review Golden Expert Model (if created by Agent 1)
   - Verify model structure
   - Verify residency length tracking
   - Verify influence weight calculation
   - Create additional models if needed

2. Review Locality Personality Model (if created by Agent 1)
   - Verify model structure
   - Verify golden expert influence integration
   - Verify personality data storage

**Day 3-5: Tests & Documentation**
3. Create `test/unit/services/golden_expert_ai_influence_service_test.dart`
   - Test weight calculation (10% higher, proportional to residency)
   - Test weight application to behavior
   - Test weight application to preferences
   - Test weight application to connections
   - Test integration with other services

4. Create `test/unit/services/locality_personality_service_test.dart`
   - Test locality personality management
   - Test golden expert influence incorporation
   - Test locality vibe calculation
   - Test locality preferences
   - Test locality characteristics

5. Create Integration Tests
   - Test golden expert influence on AI personality
   - Test list/review weighting for golden experts
   - Test neighborhood character shaping
   - Test end-to-end golden expert influence flow

6. Documentation
   - Document GoldenExpertAIInfluenceService
   - Document LocalityPersonalityService
   - Document golden expert weight calculation
   - Document AI personality influence
   - Document list/review weighting
   - Update system documentation

## Deliverables

- ✅ GoldenExpertAIInfluenceService tests created
- ✅ LocalityPersonalityService tests created
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

- ✅ Week 30 (Expertise Expansion) COMPLETE
- ⏳ Agent 1 creating GoldenExpertAIInfluenceService and LocalityPersonalityService (work in parallel)
- ✅ AI personality learning system exists (`lib/core/ai/personality_learning.dart`)

## Documentation

- Document all models and services
- Document golden expert weight calculation
- Document AI personality influence
- Document list/review weighting
- Update system documentation
- Create completion report: `docs/agents/reports/agent_3/phase_6/week_31_golden_expert_tests_documentation.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_31_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Testing Workflow: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- AI Personality Learning: `lib/core/ai/personality_learning.dart`

**START WORK NOW.**
```

---

## 📋 **Quick Reference**

### **Files to Create:**

**Agent 1:**
- `lib/core/services/golden_expert_ai_influence_service.dart`
- `lib/core/services/locality_personality_service.dart`

**Agent 2:**
- `lib/presentation/widgets/golden_expert_indicator.dart` (if needed)

**Agent 3:**
- `test/unit/services/golden_expert_ai_influence_service_test.dart`
- `test/unit/services/locality_personality_service_test.dart`
- `test/integration/golden_expert_influence_integration_test.dart`

### **Files to Modify:**

**Agent 1:**
- `lib/core/ai/personality_learning.dart` (golden expert integration)
- List/review recommendation service (to be identified)

**Agent 2:**
- `lib/presentation/pages/clubs/club_page.dart` (polish)
- `lib/presentation/pages/communities/community_page.dart` (polish)
- `lib/presentation/widgets/clubs/expertise_coverage_widget.dart` (polish)

---

## 🎯 **Success Criteria**

- ✅ All services created and tested
- ✅ All UI components polished
- ✅ Zero linter errors
- ✅ Test coverage > 90%
- ✅ Documentation complete
- ✅ Integration working

---

**Last Updated:** November 25, 2025  
**Status:** 🎯 Ready to Use

