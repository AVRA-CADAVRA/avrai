# Phase 6 Task Assignments - Local Expert System Redesign (Week 31)

**Date:** November 25, 2025  
**Purpose:** Detailed task assignments for Phase 6, Week 31 (UI/UX & Golden Expert - Phase 4)  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 31 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Read:** `docs/plans/philosophy_implementation/DOORS.md` - **MANDATORY** - Core philosophy
5. ✅ **Read:** `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - **MANDATORY** - Philosophy alignment
6. ✅ **Verify:** Week 30 (Phase 3, Week 3) is COMPLETE - Expertise Expansion done

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
2. **Phase 6 Week 31 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document exists):**

- ❌ **NO new tasks can be added** to Phase 6 Week 31
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 31 Overview**

**Duration:** Week 31 (5 days)  
**Focus:** UI/UX & Golden Expert (Phase 4)  
**Priority:** P1 - Core Functionality  
**Philosophy:** Golden experts shape neighborhood character, AI reflects actual community values

**What Doors Does This Open?**
- **Influence Doors:** Golden experts shape neighborhood character (10% higher influence)
- **Representation Doors:** AI personality reflects actual community values (golden expert perspective)
- **Recognition Doors:** Golden expert lists/reviews weighted more heavily
- **Community Doors:** Neighborhood character shaped by golden experts (along with all locals, but higher rate)
- **Polish Doors:** Final UI/UX polish for clubs/communities

**When Are Users Ready?**
- After users become golden experts (long-term residents with local expertise)
- System recognizes golden expert status
- AI personality learning system ready
- Club/community UI already created (Week 29-30)

**Why Critical:**
- Enables golden experts to shape neighborhood character
- AI personality reflects actual community values
- Golden expert contributions have more influence
- Final polish for club/community UI

**Dependencies:**
- ✅ Week 30 (Phase 3, Week 3) COMPLETE - Expertise Expansion done
- ✅ ClubPage and CommunityPage exist (from Week 29)
- ✅ ExpertiseCoverageWidget exists (from Week 30)
- ✅ AI personality learning system exists (from earlier phases)

**Note:** Week 31 combines Golden Expert AI Influence (new work) with final UI/UX polish for clubs/communities (already created in Week 29-30).

---

## 📋 **Agent Assignments**

### **Agent 1: Backend & Integration**
**Focus:** GoldenExpertAIInfluenceService, LocalityPersonalityService, AI Personality Integration, List/Review Weighting

### **Agent 2: Frontend & UX**
**Focus:** Final UI/UX polish for ClubPage, CommunityPage, ExpertiseCoverageWidget, Golden Expert indicators

### **Agent 3: Models & Testing**
**Focus:** Golden Expert Models, Tests, Documentation

---

## 📅 **Week 31: UI/UX & Golden Expert**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start  
**Focus:** Golden Expert AI Influence Services

**Tasks:**

#### **Day 1-2: GoldenExpertAIInfluenceService**
- [ ] **Create `lib/core/services/golden_expert_ai_influence_service.dart`**
  - [ ] Calculate golden expert weight:
    - [ ] Base weight: 10% higher (1.1x)
    - [ ] Proportional to residency length:
      - [ ] Example: 30 years = 1.3x weight (1.1 + 0.2)
      - [ ] Example: 25 years = 1.25x weight (1.1 + 0.15)
      - [ ] Example: 20 years = 1.2x weight (1.1 + 0.1)
      - [ ] Formula: `1.1 + (residencyYears / 100)`
    - [ ] Minimum weight: 1.1x (10% higher)
    - [ ] Maximum weight: 1.5x (50% higher, for 40+ years)
  - [ ] Apply weight to golden expert actions:
    - [ ] `calculateInfluenceWeight()` - Calculate weight for a golden expert
    - [ ] `applyWeightToBehavior()` - Apply weight to behavior data
    - [ ] `applyWeightToPreferences()` - Apply weight to preference data
    - [ ] `applyWeightToConnections()` - Apply weight to connection data
  - [ ] Integration with existing services:
    - [ ] Use with AI personality learning
    - [ ] Use with list/review weighting
    - [ ] Use with locality personality shaping

#### **Day 3-4: LocalityPersonalityService & AI Personality Integration**
- [ ] **Create `lib/core/services/locality_personality_service.dart`**
  - [ ] Manage locality AI personality:
    - [ ] `getLocalityPersonality()` - Get AI personality for a locality
    - [ ] `updateLocalityPersonality()` - Update AI personality based on user behavior
    - [ ] `incorporateGoldenExpertInfluence()` - Incorporate golden expert influence
  - [ ] Shape neighborhood "vibe" in system:
    - [ ] `calculateLocalityVibe()` - Calculate overall locality vibe
    - [ ] `getLocalityPreferences()` - Get locality preferences (shaped by golden experts)
    - [ ] `getLocalityCharacteristics()` - Get locality characteristics
  - [ ] Golden expert influence:
    - [ ] Golden expert behavior influences locality AI personality
    - [ ] Golden expert preferences shape locality representation
    - [ ] Central AI system uses golden expert perspective

- [ ] **Modify AI Personality Learning System**
  - [ ] Update to use golden expert data:
    - [ ] Find existing personality learning service
    - [ ] Add golden expert weighting integration
    - [ ] Apply 10% higher weight to golden expert behavior
  - [ ] Update personality calculation:
    - [ ] Incorporate golden expert influence
    - [ ] Weight golden expert contributions more heavily
    - [ ] Shape locality personality based on golden experts

#### **Day 5: List/Review Weighting & Integration**
- [ ] **Modify List/Review Recommendation System**
  - [ ] Update recommendation system to weight golden expert lists/reviews higher:
    - [ ] Find existing list/review recommendation service
    - [ ] Add golden expert weighting
    - [ ] Apply weight to golden expert lists/reviews
  - [ ] Golden expert contributions have more influence:
    - [ ] Lists created by golden experts weighted higher
    - [ ] Reviews written by golden experts weighted higher
    - [ ] Recommendations prioritize golden expert content
  - [ ] Neighborhood character shaped by golden experts:
    - [ ] Golden expert lists shape neighborhood recommendations
    - [ ] Golden expert reviews influence spot ratings
    - [ ] Along with all locals, but higher rate

- [ ] **Integration & Updates**
  - [ ] Integrate GoldenExpertAIInfluenceService with:
    - [ ] LocalityPersonalityService
    - [ ] AI personality learning system
    - [ ] List/review recommendation system
  - [ ] Update existing services to use golden expert weighting
  - [ ] Ensure backward compatibility

**Deliverables:**
- ✅ GoldenExpertAIInfluenceService created
- ✅ Golden expert weight calculation working (10% higher, proportional to residency)
- ✅ LocalityPersonalityService created
- ✅ AI personality influenced by golden experts
- ✅ List/review weighting for golden experts working
- ✅ Integration with existing systems complete
- ✅ Zero linter errors
- ✅ All services follow existing patterns

**Files to Create:**
- `lib/core/services/golden_expert_ai_influence_service.dart`
- `lib/core/services/locality_personality_service.dart`

**Files to Modify:**
- AI personality learning service (to be identified)
- List/review recommendation service (to be identified)

---

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start  
**Focus:** Final UI/UX Polish

**Tasks:**

#### **Day 1-3: Club/Community UI Polish**
- [ ] **Update `lib/presentation/pages/clubs/club_page.dart`**
  - [ ] Final polish and integration:
    - [ ] Ensure all features working correctly
    - [ ] Verify ExpertiseCoverageWidget integration
    - [ ] Verify ExpansionTimelineWidget integration
    - [ ] Verify leader expertise display
    - [ ] Add loading states and error handling
    - [ ] Improve accessibility
  - [ ] Golden expert indicators (if applicable):
    - [ ] Show golden expert status for leaders (if they are golden experts)
    - [ ] Display golden expert influence indicators
  - [ ] Use AppColors/AppTheme (100% adherence)
  - [ ] Responsive design improvements

- [ ] **Update `lib/presentation/pages/communities/community_page.dart`**
  - [ ] Final polish and integration:
    - [ ] Ensure all features working correctly
    - [ ] Verify expansion tracking display
    - [ ] Add loading states and error handling
    - [ ] Improve accessibility
  - [ ] Use AppColors/AppTheme (100% adherence)
  - [ ] Responsive design improvements

- [ ] **Update `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`**
  - [ ] Final polish:
    - [ ] Ensure map view working correctly
    - [ ] Verify coverage metrics display
    - [ ] Improve visual design
    - [ ] Add loading states
    - [ ] Improve accessibility
  - [ ] Use AppColors/AppTheme (100% adherence)

#### **Day 4-5: Golden Expert UI Indicators (if needed)**
- [ ] **Create Golden Expert Indicators** (if needed)
  - [ ] Golden expert badge/indicator widget
  - [ ] Display golden expert status in user profiles
  - [ ] Show golden expert influence in locality pages
  - [ ] Use AppColors/AppTheme (100% adherence)

- [ ] **Final Integration Testing**
  - [ ] Test all club/community UI flows
  - [ ] Test expertise coverage visualization
  - [ ] Test expansion timeline
  - [ ] Verify all integrations working
  - [ ] Test responsive design
  - [ ] Test accessibility

**Deliverables:**
- ✅ ClubPage polished and fully integrated
- ✅ CommunityPage polished and fully integrated
- ✅ ExpertiseCoverageWidget polished
- ✅ Golden expert indicators (if needed)
- ✅ Zero linter errors
- ✅ 100% AppColors/AppTheme adherence
- ✅ Responsive and accessible
- ✅ All integrations working

**Files to Modify:**
- `lib/presentation/pages/clubs/club_page.dart` (polish)
- `lib/presentation/pages/communities/community_page.dart` (polish)
- `lib/presentation/widgets/clubs/expertise_coverage_widget.dart` (polish)

**Files to Create (if needed):**
- `lib/presentation/widgets/golden_expert_indicator.dart` (if needed)

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start  
**Focus:** Golden Expert Models, Tests, Documentation

**Tasks:**

#### **Day 1-2: Review Models (if needed)**
- [ ] **Review Golden Expert Model** (if created by Agent 1)
  - [ ] Verify model structure
  - [ ] Verify residency length tracking
  - [ ] Verify influence weight calculation
  - [ ] Create additional models if needed

- [ ] **Review Locality Personality Model** (if created by Agent 1)
  - [ ] Verify model structure
  - [ ] Verify golden expert influence integration
  - [ ] Verify personality data storage

#### **Day 3-5: Tests & Documentation**
- [ ] **Create `test/unit/services/golden_expert_ai_influence_service_test.dart`**
  - [ ] Test weight calculation (10% higher, proportional to residency)
  - [ ] Test weight application to behavior
  - [ ] Test weight application to preferences
  - [ ] Test weight application to connections
  - [ ] Test integration with other services

- [ ] **Create `test/unit/services/locality_personality_service_test.dart`**
  - [ ] Test locality personality management
  - [ ] Test golden expert influence incorporation
  - [ ] Test locality vibe calculation
  - [ ] Test locality preferences
  - [ ] Test locality characteristics

- [ ] **Create Integration Tests**
  - [ ] Test golden expert influence on AI personality
  - [ ] Test list/review weighting for golden experts
  - [ ] Test neighborhood character shaping
  - [ ] Test end-to-end golden expert influence flow

- [ ] **Documentation**
  - [ ] Document GoldenExpertAIInfluenceService
  - [ ] Document LocalityPersonalityService
  - [ ] Document golden expert weight calculation
  - [ ] Document AI personality influence
  - [ ] Document list/review weighting
  - [ ] Update system documentation

**Deliverables:**
- ✅ GoldenExpertAIInfluenceService tests created
- ✅ LocalityPersonalityService tests created
- ✅ Integration tests created
- ✅ Documentation complete
- ✅ All tests pass
- ✅ Test coverage > 90%

**Files to Create:**
- `test/unit/services/golden_expert_ai_influence_service_test.dart`
- `test/unit/services/locality_personality_service_test.dart`
- `test/integration/golden_expert_influence_integration_test.dart`

**Files to Review:**
- `lib/core/services/golden_expert_ai_influence_service.dart` (created by Agent 1)
- `lib/core/services/locality_personality_service.dart` (created by Agent 1)

---

## 🎯 **Success Criteria**

### **GoldenExpertAIInfluenceService:**
- [ ] Weight calculation working (10% higher, proportional to residency)
- [ ] Weight application to behavior/preferences/connections working
- [ ] Integration with AI personality learning working

### **LocalityPersonalityService:**
- [ ] Locality personality management working
- [ ] Golden expert influence incorporation working
- [ ] Locality vibe calculation working

### **AI Personality Integration:**
- [ ] AI personality influenced by golden experts
- [ ] Golden expert behavior shapes locality personality
- [ ] Central AI system uses golden expert perspective

### **List/Review Weighting:**
- [ ] Golden expert lists/reviews weighted higher
- [ ] Recommendations prioritize golden expert content
- [ ] Neighborhood character shaped by golden experts

### **UI:**
- [ ] ClubPage polished and fully integrated
- [ ] CommunityPage polished and fully integrated
- [ ] ExpertiseCoverageWidget polished
- [ ] 100% AppColors/AppTheme adherence

---

## 📊 **Estimated Impact**

- **New Services:** 2 services (GoldenExpertAIInfluenceService, LocalityPersonalityService)
- **Modified Services:** 2+ services (AI personality learning, list/review recommendation)
- **Modified UI:** 3 components (ClubPage, CommunityPage, ExpertiseCoverageWidget)
- **New Tests:** 3+ test files
- **Documentation:** Service documentation, system documentation

---

## 🚧 **Dependencies**

- ✅ Week 30 (Phase 3, Week 3) COMPLETE - Expertise Expansion done
- ✅ ClubPage and CommunityPage exist (from Week 29)
- ✅ ExpertiseCoverageWidget exists (from Week 30)
- ✅ AI personality learning system exists (from earlier phases)

---

## 📝 **Notes**

- **Golden Expert Weight:** 10% higher base weight, proportional to residency length (30 years = 1.3x, 25 years = 1.25x, etc.)
- **AI Personality Influence:** Golden expert behavior influences locality AI personality at 10% higher rate
- **List/Review Weighting:** Golden expert lists/reviews weighted more heavily in recommendations
- **Neighborhood Character:** Shaped by golden experts (along with all locals, but higher rate)
- **Final Polish:** Week 31 includes final UI/UX polish for clubs/communities (already created in Week 29-30)

---

**Last Updated:** November 25, 2025  
**Status:** 🎯 Ready to Start

