# Phase 6 Agent Prompts - Local Expert System Redesign (Week 32)

**Date:** November 25, 2025  
**Purpose:** Ready-to-use prompts for agents working on Phase 6, Week 32 (Neighborhood Boundaries - Phase 5)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_6/week_32_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`** - Detailed implementation plan
6. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`** - Complete requirements
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/week_32_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Week 32 Overview**

**Focus:** Neighborhood Boundaries (Phase 5)  
**Duration:** 5 days  
**Priority:** P1 - Core Functionality  
**Note:** This is the FINAL week of Phase 6 (Local Expert System Redesign)

**What Doors Does This Open?**
- **Boundary Doors:** System reflects actual community boundaries (hard/soft borders)
- **Refinement Doors:** Borders evolve based on actual user behavior (dynamic refinement)
- **Community Doors:** Soft border spots shared with both localities (community connections)
- **Visualization Doors:** Users can see and understand neighborhood boundaries (border visualization)
- **Integration Doors:** Boundaries integrated with geographic hierarchy (seamless integration)

**Philosophy Alignment:**
- Neighborhood boundaries reflect actual community connections (doors for authentic representation)
- Borders evolve based on user behavior (doors for learning and adaptation)
- Soft border spots shared with both localities (doors for community connections)
- Final piece of Local Expert System Redesign (doors for complete system)

**Dependencies:**
- ✅ Week 31 (Phase 4) COMPLETE - UI/UX & Golden Expert done
- ✅ Geographic hierarchy system exists
- ✅ Large city detection system exists (`LargeCityDetectionService`)
- ⏳ User movement tracking system (may need to be created or integrated)

**Key Concepts:**
- **Hard Borders:** Well-defined boundaries (e.g., NoHo/SoHo) - clear geographic lines
- **Soft Borders:** Not well-defined (e.g., Nolita/East Village) - blended areas
- **Soft Border Handling:** Spots in soft border areas shared with both localities
- **Dynamic Refinement:** Borders evolve based on actual user behavior (which locality visits spots more)
- **Google Maps Integration:** Primary source for boundary data (may use mock data initially)

---

## 🤖 **Agent 1: Backend & Integration**

### **Prompt for Agent 1:**

```
You are Agent 1: Backend & Integration Specialist working on Phase 6, Week 32 (Neighborhood Boundaries - Phase 5).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 32 - Neighborhood Boundaries (Phase 5)  
**Status:** Ready to Start  
**Dependencies:** Week 31 (UI/UX & Golden Expert) COMPLETE  
**Note:** This is the FINAL week of Phase 6 (Local Expert System Redesign)

**What You're Building:**
- NeighborhoodBoundary model - Model for neighborhood boundaries (hard/soft)
- NeighborhoodBoundaryService - Service for managing boundaries, hard/soft detection, dynamic refinement
- Hard/Soft Border Detection - Detect and handle hard vs soft borders
- Soft Border Handling - Track spots in soft border areas, track user visits
- Dynamic Border Refinement - Refine borders based on actual user behavior

**Philosophy:**
- Neighborhood boundaries reflect actual community connections (not just geographic lines)
- Borders evolve based on user behavior (dynamic refinement)
- Soft border spots shared with both localities (community connections)
- System learns and refines boundaries based on actual user behavior

## Tasks

**Day 1-2: NeighborhoodBoundary Model & Service Foundation**
1. Create `lib/core/models/neighborhood_boundary.dart`
   - Model fields:
     - id, locality1, locality2, boundaryType (HardBorder/SoftBorder enum)
     - coordinates (List of coordinate points)
     - source (e.g., "Google Maps")
     - softBorderSpots (List of spot IDs)
     - userVisitCounts (Map of spot ID to visit counts by locality)
     - refinementHistory (List of refinement events)
     - lastRefinedAt, createdAt, updatedAt
   - Include Equatable, JSON serialization/deserialization, copyWith methods

2. Create `lib/core/services/neighborhood_boundary_service.dart`
   - Load boundaries from Google Maps (or mock data for now):
     - loadBoundariesFromGoogleMaps(String city)
     - getBoundary(String locality1, String locality2)
     - getBoundariesForLocality(String locality)
   - Handle hard borders (well-defined):
     - isHardBorder(String locality1, String locality2)
     - getHardBorders(String city)
   - Handle soft borders (blended):
     - isSoftBorder(String locality1, String locality2)
     - getSoftBorders(String city)
   - Store boundary data:
     - saveBoundary(NeighborhoodBoundary boundary)
     - updateBoundary(NeighborhoodBoundary boundary)

**Day 3: Soft Border Handling**
3. Extend NeighborhoodBoundaryService with Soft Border Logic
   - Track spots in soft border areas:
     - addSoftBorderSpot(String spotId, String locality1, String locality2)
     - getSoftBorderSpots(String locality1, String locality2)
     - isSpotInSoftBorder(String spotId)
   - Track which locality users visit spots more:
     - trackSpotVisit(String spotId, String locality)
     - getSpotVisitCounts(String spotId)
     - getDominantLocality(String spotId)
   - Refine borders based on user behavior:
     - refineSoftBorder(String locality1, String locality2)
     - shouldRefineBorder(String locality1, String locality2)
     - calculateBorderRefinement(String locality1, String locality2)

**Day 4-5: Dynamic Border Refinement**
4. Implement Dynamic Border Refinement
   - Continuously track user movement patterns:
     - trackUserMovement(String userId, String spotId, String locality)
     - getUserMovementPatterns(String locality)
     - analyzeMovementPatterns(String locality1, String locality2)
   - If Locality A users visit spot more than Locality B, spot becomes more associated with Locality A:
     - associateSpotWithLocality(String spotId, String locality)
     - getSpotLocalityAssociation(String spotId)
     - updateSpotLocalityAssociation(String spotId)
   - Update boundaries based on actual community behavior:
     - updateBoundaryFromBehavior(String locality1, String locality2)
     - calculateBoundaryChanges(String locality1, String locality2)
     - applyBoundaryRefinement(String locality1, String locality2)
   - Integration with geographic hierarchy:
     - integrateWithGeographicHierarchy(String locality)
     - updateGeographicHierarchy(String locality)

5. Integration & Updates
   - Integrate with existing services:
     - LargeCityDetectionService (for large city neighborhoods)
     - Geographic hierarchy system
     - Spot/location services
   - Ensure backward compatibility
   - Add comprehensive logging

## Deliverables

- ✅ NeighborhoodBoundary model created
- ✅ NeighborhoodBoundaryService created
- ✅ Hard/soft border detection working
- ✅ Soft border handling working
- ✅ Dynamic border refinement implemented
- ✅ Integration with geographic hierarchy complete
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

- ✅ Week 31 (UI/UX & Golden Expert) COMPLETE
- ✅ Geographic hierarchy system exists
- ✅ Large city detection system exists (`LargeCityDetectionService`)
- ⏳ User movement tracking system (may need to be created or integrated)

## Testing

- Agent 3 will create tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Update service documentation
- Document hard/soft border system
- Document dynamic border refinement
- Document integration with geographic hierarchy
- Create completion report: `docs/agents/reports/agent_1/phase_6/week_32_neighborhood_boundaries.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_32_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Large City Detection: `lib/core/services/large_city_detection_service.dart`

**START WORK NOW.**
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Prompt for Agent 2:**

```
You are Agent 2: Frontend & UX Specialist working on Phase 6, Week 32 (Neighborhood Boundaries - Phase 5).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 32 - Neighborhood Boundaries (Phase 5)  
**Status:** Ready to Start  
**Dependencies:** Week 31 (UI/UX & Golden Expert) COMPLETE, Agent 1 creating boundary services  
**Note:** This is the FINAL week of Phase 6 (Local Expert System Redesign)

**What You're Building:**
- BorderVisualizationWidget - Display neighborhood boundaries on map (hard/soft borders)
- BorderManagementWidget - Display border information and management UI
- Integration with maps and locality pages
- Final polish and integration

**Philosophy:**
- Show doors (boundary visualization) that users can understand
- Make neighborhood boundaries visible and accessible
- Display hard/soft borders clearly
- Final polish enables better user experience

## Tasks

**Day 1-3: Border Visualization Widget**
1. Create `lib/presentation/widgets/boundaries/border_visualization_widget.dart`
   - Display neighborhood boundaries on map:
     - Show hard borders (solid lines, distinct color)
     - Show soft borders (dashed lines, blended color)
     - Interactive map with boundary overlay
     - Zoom to locality boundaries
   - Visual indicators:
     - Color-coded borders (hard vs soft)
     - Border labels (locality names)
     - Soft border spots highlighted
     - Refinement indicators (if borders have been refined)
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Responsive design
   - Accessibility support

2. Create `lib/presentation/widgets/boundaries/border_management_widget.dart`
   - Display border information:
     - Border type (hard/soft)
     - Border coordinates
     - Soft border spots list
     - Visit counts by locality
     - Refinement history
   - Border management actions (if applicable):
     - View border details
     - View refinement history
     - View soft border spots
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Responsive design
   - Accessibility support

**Day 4-5: Integration & Polish**
3. Integrate Border Visualization
   - Add border visualization to locality pages
   - Add border visualization to map views
   - Add border management to admin/settings (if applicable)
   - Ensure smooth integration with existing UI

4. Final Polish
   - Loading states
   - Error handling
   - Empty states
   - Responsive design improvements
   - Accessibility improvements
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)

## Deliverables

- ✅ BorderVisualizationWidget created
- ✅ BorderManagementWidget created
- ✅ Border visualization integrated with maps
- ✅ Border management UI complete
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

- ✅ Week 31 (UI/UX & Golden Expert) COMPLETE
- ⏳ Agent 1 creating NeighborhoodBoundaryService (work in parallel)
- ✅ Geographic hierarchy system exists
- ✅ Large city detection system exists

## Integration Points

- **NeighborhoodBoundaryService:** Load boundary data, track visits, refine borders
- **Geographic hierarchy system:** Integrate with locality data
- **Map services:** Display boundaries on maps
- **Locality pages:** Add border visualization

## Testing

- Agent 3 will create widget tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Document UI components
- Document integration points
- Create completion report: `docs/agents/reports/agent_2/phase_6/week_32_agent_2_completion.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_32_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Design Tokens: `lib/core/theme/colors.dart` and `lib/core/theme/app_theme.dart`

**START WORK NOW.**
```

---

## 🧪 **Agent 3: Models & Testing**

### **Prompt for Agent 3:**

```
You are Agent 3: Models & Testing Specialist working on Phase 6, Week 32 (Neighborhood Boundaries - Phase 5).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 32 - Neighborhood Boundaries (Phase 5)  
**Status:** Ready to Start  
**Dependencies:** Week 31 (UI/UX & Golden Expert) COMPLETE, Agent 1 creating boundary services  
**Note:** This is the FINAL week of Phase 6 (Local Expert System Redesign)

**What You're Testing:**
- NeighborhoodBoundary model - Model for neighborhood boundaries (hard/soft)
- NeighborhoodBoundaryService - Service for managing boundaries, hard/soft detection, dynamic refinement
- Hard/Soft Border Detection - Detect and handle hard vs soft borders
- Soft Border Handling - Track spots in soft border areas, track user visits
- Dynamic Border Refinement - Refine borders based on actual user behavior

**Philosophy:**
- Neighborhood boundaries reflect actual community connections (not just geographic lines)
- Borders evolve based on user behavior (dynamic refinement)
- Soft border spots shared with both localities (community connections)

## Testing Workflow (TDD Approach)

**Follow the parallel testing workflow protocol:**
- Read `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Write tests based on specifications (before or in parallel with Agent 1's implementation)
- Tests serve as specifications for Agent 1
- Verify implementation matches test specifications

## Tasks

**Day 1-2: Review Models**
1. Review NeighborhoodBoundary Model (created by Agent 1)
   - Verify model structure
   - Verify boundary type enum (HardBorder/SoftBorder)
   - Verify coordinate storage
   - Verify soft border spot tracking
   - Verify user visit count tracking
   - Verify refinement history
   - Create additional models if needed

**Day 3-5: Tests & Documentation**
2. Create `test/unit/models/neighborhood_boundary_test.dart`
   - Test model creation
   - Test boundary type enum
   - Test coordinate storage
   - Test soft border spot tracking
   - Test user visit count tracking
   - Test refinement history
   - Test JSON serialization/deserialization
   - Test copyWith methods

3. Create `test/unit/services/neighborhood_boundary_service_test.dart`
   - Test boundary loading (Google Maps or mock)
   - Test hard border detection
   - Test soft border detection
   - Test soft border spot tracking
   - Test user visit tracking
   - Test border refinement
   - Test dynamic border updates
   - Test integration with geographic hierarchy

4. Create Integration Tests
   - Test end-to-end border refinement flow
   - Test soft border spot association
   - Test boundary updates from user behavior
   - Test integration with geographic hierarchy
   - Test integration with large city detection

5. Documentation
   - Document NeighborhoodBoundary model
   - Document NeighborhoodBoundaryService
   - Document hard/soft border system
   - Document dynamic border refinement
   - Document integration with geographic hierarchy
   - Update system documentation

## Deliverables

- ✅ NeighborhoodBoundary model tests created
- ✅ NeighborhoodBoundaryService tests created
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

- ✅ Week 31 (UI/UX & Golden Expert) COMPLETE
- ⏳ Agent 1 creating NeighborhoodBoundaryService (work in parallel)
- ✅ Geographic hierarchy system exists
- ✅ Large city detection system exists

## Documentation

- Document all models and services
- Document hard/soft border system
- Document dynamic border refinement
- Document integration with geographic hierarchy
- Update system documentation
- Create completion report: `docs/agents/reports/agent_3/phase_6/week_32_neighborhood_boundaries_tests_documentation.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_32_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Testing Workflow: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Large City Detection: `lib/core/services/large_city_detection_service.dart`

**START WORK NOW.**
```

---

## 📋 **Quick Reference**

### **Files to Create:**

**Agent 1:**
- `lib/core/models/neighborhood_boundary.dart`
- `lib/core/services/neighborhood_boundary_service.dart`

**Agent 2:**
- `lib/presentation/widgets/boundaries/border_visualization_widget.dart`
- `lib/presentation/widgets/boundaries/border_management_widget.dart`

**Agent 3:**
- `test/unit/models/neighborhood_boundary_test.dart`
- `test/unit/services/neighborhood_boundary_service_test.dart`
- `test/integration/neighborhood_boundary_integration_test.dart`

### **Files to Modify:**

**Agent 1:**
- Geographic hierarchy services (if needed)
- Spot/location services (if needed)

**Agent 2:**
- Locality pages (add border visualization)
- Map views (add border overlay)

---

## 🎯 **Success Criteria**

- ✅ All services created and tested
- ✅ All UI components created
- ✅ Zero linter errors
- ✅ Test coverage > 90%
- ✅ Documentation complete
- ✅ Integration working
- ✅ **Phase 6 COMPLETE** (Final week)

---

**Last Updated:** November 25, 2025  
**Status:** 🎯 Ready to Use

