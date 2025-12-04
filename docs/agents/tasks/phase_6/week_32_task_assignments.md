# Phase 6 Task Assignments - Local Expert System Redesign (Week 32)

**Date:** November 25, 2025  
**Purpose:** Detailed task assignments for Phase 6, Week 32 (Neighborhood Boundaries - Phase 5)  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 32 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Read:** `docs/plans/philosophy_implementation/DOORS.md` - **MANDATORY** - Core philosophy
5. ✅ **Read:** `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - **MANDATORY** - Philosophy alignment
6. ✅ **Verify:** Week 31 (Phase 4) is COMPLETE - UI/UX & Golden Expert done

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
2. **Phase 6 Week 32 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document exists):**

- ❌ **NO new tasks can be added** to Phase 6 Week 32
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 32 Overview**

**Duration:** Week 32 (5 days)  
**Focus:** Neighborhood Boundaries (Phase 5)  
**Priority:** P1 - Core Functionality  
**Philosophy:** Neighborhood boundaries reflect actual community connections, not just geographic lines

**What Doors Does This Open?**
- **Boundary Doors:** System reflects actual community boundaries (hard/soft borders)
- **Refinement Doors:** Borders evolve based on actual user behavior (dynamic refinement)
- **Community Doors:** Soft border spots shared with both localities (community connections)
- **Visualization Doors:** Users can see and understand neighborhood boundaries (border visualization)
- **Integration Doors:** Boundaries integrated with geographic hierarchy (seamless integration)

**When Are Users Ready?**
- After users start visiting spots in different localities
- System has enough data to track user movement patterns
- Geographic hierarchy system ready
- Large city detection system ready

**Why Critical:**
- Enables accurate locality assignment for spots
- Reflects actual community connections (not just geographic lines)
- Allows soft border handling (spots shared with both localities)
- Enables dynamic border refinement based on user behavior
- Final piece of Local Expert System Redesign

**Dependencies:**
- ✅ Week 31 (Phase 4) COMPLETE - UI/UX & Golden Expert done
- ✅ Geographic hierarchy system exists
- ✅ Large city detection system exists (`LargeCityDetectionService`)
- ✅ User movement tracking system ready (or needs to be created)

**Note:** Week 32 is the FINAL week of Phase 6 (Local Expert System Redesign). This completes the entire redesign.

---

## 📋 **Agent Assignments**

### **Agent 1: Backend & Integration**
**Focus:** NeighborhoodBoundaryService, NeighborhoodBoundary Model, Hard/Soft Border Detection, Dynamic Border Refinement

### **Agent 2: Frontend & UX**
**Focus:** Border Visualization Widget, Border Management UI, Integration with Maps

### **Agent 3: Models & Testing**
**Focus:** NeighborhoodBoundary Model, Tests, Documentation

---

## 📅 **Week 32: Neighborhood Boundaries**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start  
**Focus:** Neighborhood Boundary Service & Dynamic Refinement

**Tasks:**

#### **Day 1-2: NeighborhoodBoundary Model & Service Foundation**
- [ ] **Create `lib/core/models/neighborhood_boundary.dart`**
  - [ ] Model fields:
    - [ ] `id` - Unique identifier
    - [ ] `locality1` - First locality name
    - [ ] `locality2` - Second locality name (for borders between two localities)
    - [ ] `boundaryType` - Enum: `HardBorder`, `SoftBorder`
    - [ ] `coordinates` - List of coordinate points defining the boundary
    - [ ] `source` - Source of boundary data (e.g., "Google Maps")
    - [ ] `softBorderSpots` - List of spot IDs in soft border areas
    - [ ] `userVisitCounts` - Map of spot ID to visit counts by locality
    - [ ] `refinementHistory` - List of refinement events
    - [ ] `lastRefinedAt` - Last refinement timestamp
    - [ ] `createdAt` - Creation timestamp
    - [ ] `updatedAt` - Update timestamp
  - [ ] Include `Equatable`, JSON serialization/deserialization, `copyWith` methods

- [ ] **Create `lib/core/services/neighborhood_boundary_service.dart`**
  - [ ] Load boundaries from Google Maps (or mock data for now):
    - [ ] `loadBoundariesFromGoogleMaps(String city)` - Load boundaries for a city
    - [ ] `getBoundary(String locality1, String locality2)` - Get boundary between two localities
    - [ ] `getBoundariesForLocality(String locality)` - Get all boundaries for a locality
  - [ ] Handle hard borders (well-defined):
    - [ ] `isHardBorder(String locality1, String locality2)` - Check if border is hard
    - [ ] `getHardBorders(String city)` - Get all hard borders for a city
  - [ ] Handle soft borders (blended):
    - [ ] `isSoftBorder(String locality1, String locality2)` - Check if border is soft
    - [ ] `getSoftBorders(String city)` - Get all soft borders for a city
  - [ ] Store boundary data:
    - [ ] `saveBoundary(NeighborhoodBoundary boundary)` - Save boundary
    - [ ] `updateBoundary(NeighborhoodBoundary boundary)` - Update boundary

#### **Day 3: Soft Border Handling**
- [ ] **Extend NeighborhoodBoundaryService with Soft Border Logic**
  - [ ] Track spots in soft border areas:
    - [ ] `addSoftBorderSpot(String spotId, String locality1, String locality2)` - Add spot to soft border
    - [ ] `getSoftBorderSpots(String locality1, String locality2)` - Get spots in soft border
    - [ ] `isSpotInSoftBorder(String spotId)` - Check if spot is in soft border
  - [ ] Track which locality users visit spots more:
    - [ ] `trackSpotVisit(String spotId, String locality)` - Track user visit to spot
    - [ ] `getSpotVisitCounts(String spotId)` - Get visit counts by locality
    - [ ] `getDominantLocality(String spotId)` - Get locality with most visits
  - [ ] Refine borders based on user behavior:
    - [ ] `refineSoftBorder(String locality1, String locality2)` - Refine soft border
    - [ ] `shouldRefineBorder(String locality1, String locality2)` - Check if border should be refined
    - [ ] `calculateBorderRefinement(String locality1, String locality2)` - Calculate refinement

#### **Day 4-5: Dynamic Border Refinement**
- [ ] **Implement Dynamic Border Refinement**
  - [ ] Continuously track user movement patterns:
    - [ ] `trackUserMovement(String userId, String spotId, String locality)` - Track user movement
    - [ ] `getUserMovementPatterns(String locality)` - Get movement patterns for locality
    - [ ] `analyzeMovementPatterns(String locality1, String locality2)` - Analyze patterns between localities
  - [ ] If Locality A users visit spot more than Locality B, spot becomes more associated with Locality A:
    - [ ] `associateSpotWithLocality(String spotId, String locality)` - Associate spot with locality
    - [ ] `getSpotLocalityAssociation(String spotId)` - Get locality association for spot
    - [ ] `updateSpotLocalityAssociation(String spotId)` - Update association based on visits
  - [ ] Update boundaries based on actual community behavior:
    - [ ] `updateBoundaryFromBehavior(String locality1, String locality2)` - Update boundary from behavior
    - [ ] `calculateBoundaryChanges(String locality1, String locality2)` - Calculate boundary changes
    - [ ] `applyBoundaryRefinement(String locality1, String locality2)` - Apply refinement
  - [ ] Integration with geographic hierarchy:
    - [ ] `integrateWithGeographicHierarchy(String locality)` - Integrate with hierarchy
    - [ ] `updateGeographicHierarchy(String locality)` - Update hierarchy based on boundaries

- [ ] **Integration & Updates**
  - [ ] Integrate with existing services:
    - [ ] LargeCityDetectionService (for large city neighborhoods)
    - [ ] Geographic hierarchy system
    - [ ] Spot/location services
  - [ ] Ensure backward compatibility
  - [ ] Add comprehensive logging

**Deliverables:**
- ✅ NeighborhoodBoundary model created
- ✅ NeighborhoodBoundaryService created
- ✅ Hard/soft border detection working
- ✅ Soft border handling working
- ✅ Dynamic border refinement implemented
- ✅ Integration with geographic hierarchy complete
- ✅ Zero linter errors
- ✅ All services follow existing patterns

**Files to Create:**
- `lib/core/models/neighborhood_boundary.dart`
- `lib/core/services/neighborhood_boundary_service.dart`

**Files to Modify:**
- Geographic hierarchy services (if needed)
- Spot/location services (if needed)

---

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start  
**Focus:** Border Visualization & Management UI

**Tasks:**

#### **Day 1-3: Border Visualization Widget**
- [ ] **Create `lib/presentation/widgets/boundaries/border_visualization_widget.dart`**
  - [ ] Display neighborhood boundaries on map:
    - [ ] Show hard borders (solid lines, distinct color)
    - [ ] Show soft borders (dashed lines, blended color)
    - [ ] Interactive map with boundary overlay
    - [ ] Zoom to locality boundaries
  - [ ] Visual indicators:
    - [ ] Color-coded borders (hard vs soft)
    - [ ] Border labels (locality names)
    - [ ] Soft border spots highlighted
    - [ ] Refinement indicators (if borders have been refined)
  - [ ] Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
  - [ ] Responsive design
  - [ ] Accessibility support

- [ ] **Create `lib/presentation/widgets/boundaries/border_management_widget.dart`**
  - [ ] Display border information:
    - [ ] Border type (hard/soft)
    - [ ] Border coordinates
    - [ ] Soft border spots list
    - [ ] Visit counts by locality
    - [ ] Refinement history
  - [ ] Border management actions (if applicable):
    - [ ] View border details
    - [ ] View refinement history
    - [ ] View soft border spots
  - [ ] Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
  - [ ] Responsive design
  - [ ] Accessibility support

#### **Day 4-5: Integration & Polish**
- [ ] **Integrate Border Visualization**
  - [ ] Add border visualization to locality pages
  - [ ] Add border visualization to map views
  - [ ] Add border management to admin/settings (if applicable)
  - [ ] Ensure smooth integration with existing UI

- [ ] **Final Polish**
  - [ ] Loading states
  - [ ] Error handling
  - [ ] Empty states
  - [ ] Responsive design improvements
  - [ ] Accessibility improvements
  - [ ] Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)

**Deliverables:**
- ✅ BorderVisualizationWidget created
- ✅ BorderManagementWidget created
- ✅ Border visualization integrated with maps
- ✅ Border management UI complete
- ✅ Zero linter errors
- ✅ 100% AppColors/AppTheme adherence
- ✅ Responsive and accessible
- ✅ All integrations working

**Files to Create:**
- `lib/presentation/widgets/boundaries/border_visualization_widget.dart`
- `lib/presentation/widgets/boundaries/border_management_widget.dart`

**Files to Modify:**
- Locality pages (add border visualization)
- Map views (add border overlay)

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start  
**Focus:** NeighborhoodBoundary Model, Tests, Documentation

**Tasks:**

#### **Day 1-2: Review Models**
- [ ] **Review NeighborhoodBoundary Model** (created by Agent 1)
  - [ ] Verify model structure
  - [ ] Verify boundary type enum
  - [ ] Verify coordinate storage
  - [ ] Verify soft border spot tracking
  - [ ] Verify user visit count tracking
  - [ ] Verify refinement history
  - [ ] Create additional models if needed

#### **Day 3-5: Tests & Documentation**
- [ ] **Create `test/unit/models/neighborhood_boundary_test.dart`**
  - [ ] Test model creation
  - [ ] Test boundary type enum
  - [ ] Test coordinate storage
  - [ ] Test soft border spot tracking
  - [ ] Test user visit count tracking
  - [ ] Test refinement history
  - [ ] Test JSON serialization/deserialization
  - [ ] Test copyWith methods

- [ ] **Create `test/unit/services/neighborhood_boundary_service_test.dart`**
  - [ ] Test boundary loading (Google Maps or mock)
  - [ ] Test hard border detection
  - [ ] Test soft border detection
  - [ ] Test soft border spot tracking
  - [ ] Test user visit tracking
  - [ ] Test border refinement
  - [ ] Test dynamic border updates
  - [ ] Test integration with geographic hierarchy

- [ ] **Create Integration Tests**
  - [ ] Test end-to-end border refinement flow
  - [ ] Test soft border spot association
  - [ ] Test boundary updates from user behavior
  - [ ] Test integration with geographic hierarchy
  - [ ] Test integration with large city detection

- [ ] **Documentation**
  - [ ] Document NeighborhoodBoundary model
  - [ ] Document NeighborhoodBoundaryService
  - [ ] Document hard/soft border system
  - [ ] Document dynamic border refinement
  - [ ] Document integration with geographic hierarchy
  - [ ] Update system documentation

**Deliverables:**
- ✅ NeighborhoodBoundary model tests created
- ✅ NeighborhoodBoundaryService tests created
- ✅ Integration tests created
- ✅ Documentation complete
- ✅ All tests pass
- ✅ Test coverage > 90%

**Files to Create:**
- `test/unit/models/neighborhood_boundary_test.dart`
- `test/unit/services/neighborhood_boundary_service_test.dart`
- `test/integration/neighborhood_boundary_integration_test.dart`

**Files to Review:**
- `lib/core/models/neighborhood_boundary.dart` (created by Agent 1)
- `lib/core/services/neighborhood_boundary_service.dart` (created by Agent 1)

---

## 🎯 **Success Criteria**

### **NeighborhoodBoundaryService:**
- [ ] Hard/soft border detection working
- [ ] Soft border spot tracking working
- [ ] User visit tracking working
- [ ] Dynamic border refinement working
- [ ] Integration with geographic hierarchy working

### **Border Visualization:**
- [ ] Hard borders displayed (solid lines)
- [ ] Soft borders displayed (dashed lines)
- [ ] Soft border spots highlighted
- [ ] Interactive map with boundary overlay
- [ ] 100% AppColors/AppTheme adherence

### **Dynamic Border Refinement:**
- [ ] User movement patterns tracked
- [ ] Spot-locality associations updated
- [ ] Borders refined based on behavior
- [ ] Refinement history tracked

---

## 📊 **Estimated Impact**

- **New Services:** 1 service (NeighborhoodBoundaryService)
- **New Models:** 1 model (NeighborhoodBoundary)
- **New UI:** 2 widgets (BorderVisualizationWidget, BorderManagementWidget)
- **New Tests:** 3+ test files
- **Documentation:** Service documentation, system documentation

---

## 🚧 **Dependencies**

- ✅ Week 31 (Phase 4) COMPLETE - UI/UX & Golden Expert done
- ✅ Geographic hierarchy system exists
- ✅ Large city detection system exists (`LargeCityDetectionService`)
- ⏳ User movement tracking system (may need to be created or integrated)

---

## 📝 **Notes**

- **Hard Borders:** Well-defined boundaries (e.g., NoHo/SoHo) - clear geographic lines
- **Soft Borders:** Not well-defined (e.g., Nolita/East Village) - blended areas
- **Soft Border Handling:** Spots in soft border areas shared with both localities
- **Dynamic Refinement:** Borders evolve based on actual user behavior (which locality visits spots more)
- **Google Maps Integration:** Primary source for boundary data (may use mock data initially)
- **Final Week:** Week 32 is the FINAL week of Phase 6 (Local Expert System Redesign)

---

**Last Updated:** November 25, 2025  
**Status:** 🎯 Ready to Start

