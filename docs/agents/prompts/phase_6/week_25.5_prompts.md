# Phase 6 Agent Prompts - Local Expert System Redesign (Week 25.5)

**Date:** November 24, 2025  
**Purpose:** Ready-to-use prompts for Phase 6, Week 25.5 (Business-Expert Matching Updates - Phase 1.5) agents  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 25.5 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Verify:** Week 24-25 (Phase 1) is COMPLETE - Geographic hierarchy and local expert qualification done

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_6/week_25.5_prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_6/week_25.5_task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_6_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_6.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: Tasks Are Assigned = Phase 6 Week 25.5 Is IN PROGRESS**

**This prompts document EXISTS (along with task assignments), which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 25.5 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document + task assignments exist):**

- ❌ **NO new tasks can be added** to Phase 6 Week 25.5
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 25.5 Overview**

**Duration:** Week 25.5 (3 days)  
**Focus:** Business-Expert Matching Updates (Phase 1.5)  
**Priority:** P1 - Critical (ensures local experts aren't excluded)  
**Philosophy:** Local experts are the bread and butter of SPOTS - they shouldn't be excluded from business matching

**What Doors Does This Open?**
- **Connection Doors:** Local experts can connect with businesses, not excluded by level filtering
- **Vibe Doors:** Vibe matches prioritized over geographic level - best fit experts found regardless of location
- **Opportunity Doors:** Remote experts with great vibe/expertise can connect with businesses
- **Authentic Matching Doors:** Matching based on personality fit, not just geographic proximity

**When Are Users Ready?**
- After businesses are using the platform to find experts
- System prioritizes vibe compatibility over geographic level
- Local experts are included in all business matching

**Why Critical:**
- Ensures local experts aren't excluded from business opportunities
- Prioritizes vibe matching (personality fit) over geographic level
- Makes location a preference boost, not a filter
- Updates AI prompts to emphasize vibe as PRIMARY factor

**Dependencies:**
- ✅ Week 24-25 (Phase 1) COMPLETE - Geographic hierarchy and local expert qualification done
- ✅ PartnershipMatchingService exists (from Phase 2) - Has vibe calculation
- ✅ BusinessExpertMatchingService exists (from Phase 2)

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 25.5 Prompt:**

```
You are Agent 1 working on Phase 6, Week 25.5: Business-Expert Matching Updates.

**Your Role:** Backend & Integration Specialist
**Focus:** Remove Level-Based Filtering, Integrate Vibe Matching, Update AI Prompts, Make Location Preference Boost

**Context:**
- ✅ Week 24-25 (Phase 1) is COMPLETE - Geographic hierarchy and local expert qualification done
- ✅ BusinessExpertMatchingService exists (from Phase 2)
- ✅ PartnershipMatchingService exists (from Phase 2) - Has vibe calculation
- ⚠️ **NOTE:** Some vibe-first matching may already be implemented - verify and enhance as needed
- 🎯 **START WORK NOW** - Ensure local experts aren't excluded, vibe matching is PRIMARY

**Your Tasks:**
1. Day 1: Remove Level-Based Filtering
   - Review BusinessExpertMatchingService._findExpertsFromCommunity() (lines 173-177)
     - Verify level-based filtering is removed (comments say it's done, verify)
     - Ensure all experts with required expertise are included (regardless of level)
     - Make level a preference boost only (in scoring, not filtering)
   - Review BusinessExpertMatchingService._applyPreferenceFilters()
     - Verify no level-based filtering remains
     - Ensure local experts are always included in matching pool
   - Update ExpertSearchService.getTopExperts() (line 84)
     - Verify it includes Local level experts (line 85 shows minLevel: ExpertiseLevel.local)
     - Ensure no City minimum remains
   - Review all other methods in BusinessExpertMatchingService
     - Verify no level-based filtering exists anywhere
     - Ensure all experts are included based on expertise match only

2. Day 2: Integrate Vibe Matching (Verify/Enhance)
   - Review BusinessExpertMatchingService._calculateVibeCompatibility() (line 467)
     - Verify it uses PartnershipService.calculateVibeCompatibility()
     - Ensure vibe compatibility is calculated correctly (0.0 to 1.0)
   - Review BusinessExpertMatchingService._calculateCommunityMatchScore() (line 442)
     - Verify vibe-first matching formula: 50% vibe + 30% expertise + 20% location
     - Ensure vibe is PRIMARY factor (50% weight)
     - Verify expertise is 30% weight
     - Verify location is 20% weight (preference boost, not filter)
   - Review BusinessExpertMatchingService._findExpertsByCategory()
     - Verify vibe-first matching is applied to all category matches
     - Ensure vibe compatibility is calculated for all matches
   - Verify 70%+ vibe compatibility is considered (but not required)
     - High vibe matches should rank higher, but lower vibe matches still included

3. Day 3: Update AI Prompts & Location Matching
   - Review BusinessExpertMatchingService._buildAIMatchingPrompt() (line 312)
     - Verify prompt emphasizes vibe as PRIMARY factor (line 380 shows this)
     - Verify prompt de-emphasizes geographic level
     - Verify prompt says "vibe match is most important"
     - Update if needed to make vibe emphasis even clearer
   - Review location matching in _applyPreferenceFilters() and _applyPreferenceScoring()
     - Verify location is preference boost only, not filter
     - Verify remote experts with great vibe/expertise are included
     - Verify local experts in locality get boost, but not required
   - Update comments and documentation
     - Document vibe-first matching (50% vibe, 30% expertise, 20% location)
     - Document that level is preference boost, not filter
     - Document that location is preference boost, not filter

**Deliverables:**
- Level-based filtering completely removed (verified)
- Local experts included in all business matching (verified)
- Vibe-first matching verified/enhanced (50% vibe, 30% expertise, 20% location)
- AI prompts emphasize vibe as PRIMARY factor (verified/enhanced)
- Location is preference boost, not filter (verified)
- Zero linter errors
- All services follow existing patterns

**Dependencies:**
- ✅ Week 24-25 COMPLETE
- ✅ PartnershipMatchingService (exists)
- ✅ BusinessExpertMatchingService (exists)
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

**Files to Modify:**
- lib/core/services/business_expert_matching_service.dart (verify/enhance)
- lib/core/services/expert_search_service.dart (verify Local level included)

**Files to Review:**
- lib/core/services/partnership_service.dart (vibe calculation method)
- lib/core/services/partnership_matching_service.dart (vibe matching patterns)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_25.5_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Week 25.5 Prompt:**

```
You are Agent 2 working on Phase 6, Week 25.5: Business-Expert Matching Updates.

**Your Role:** Frontend & UX Specialist
**Focus:** No UI work required for Week 25.5

**Context:**
- ✅ Week 24-25 (Phase 1) is COMPLETE
- ✅ Week 25.5 is backend-only changes
- 🎯 **NO UI WORK REQUIRED** - This phase is backend service updates only

**Your Tasks:**
- No UI work required for Week 25.5
- Backend service updates only (Agent 1's work)
- You can skip this phase or work on other tasks

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` to note "No UI work required"
- No completion report needed (no work assigned)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_25.5_task_assignments.md`
```

---

## 🧪 **Agent 3: Models & Testing**

### **Week 25.5 Prompt:**

```
You are Agent 3 working on Phase 6, Week 25.5: Business-Expert Matching Updates - Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Update Tests, Verify Vibe-First Matching

**Context:**
- ✅ Week 24-25 (Phase 1) is COMPLETE
- ✅ Agent 1 is updating BusinessExpertMatchingService
- ✅ BusinessExpertMatchingService exists (from Phase 2)
- 🎯 **START WORK NOW** - Update tests for vibe-first matching and local expert inclusion

**Your Tasks:**
1. Day 1-2: Update Tests
   - Review test/unit/services/business_expert_matching_service_test.dart
     - Verify tests don't assume level-based filtering
     - Add tests for local expert inclusion
     - Add tests for vibe-first matching (50% vibe, 30% expertise, 20% location)
     - Add tests for location as preference boost (not filter)
     - Add tests for remote experts with great vibe being included
   - Review test/unit/services/expert_search_service_test.dart
     - Verify tests include Local level experts
     - Verify no City minimum tests remain
   - Create integration tests for vibe-first matching
     - Test local expert included in business matching
     - Test vibe compatibility as PRIMARY factor
     - Test location as preference boost, not filter
     - Test remote experts with great vibe being included

2. Day 3: Verification & Documentation
   - Verify all tests pass
   - Verify test coverage > 90%
   - Document vibe-first matching in test files
   - Update test documentation if needed

**Deliverables:**
- Tests updated for vibe-first matching
- Tests verify local expert inclusion
- Tests verify location is preference boost, not filter
- Integration tests for vibe-first matching
- All tests pass
- Test coverage > 90%

**Dependencies:**
- ✅ Week 24-25 COMPLETE
- ✅ Agent 1 BusinessExpertMatchingService updates (complete)
- ✅ **NO BLOCKERS** - Start work after Agent 1 Day 1

**Quality Standards:**
- Zero linter errors
- All tests pass
- Test coverage > 90%
- All tests follow existing patterns
- Comprehensive test documentation

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_3/phase_6/`

**Files to Modify:**
- test/unit/services/business_expert_matching_service_test.dart
- test/unit/services/expert_search_service_test.dart

**Files to Create:**
- test/integration/business_expert_vibe_matching_integration_test.dart (if needed)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_25.5_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 📊 **Success Criteria**

### **Level-Based Filtering Removed:**
- [ ] No level-based filtering in BusinessExpertMatchingService
- [ ] Local experts included in all business matching
- [ ] Level is preference boost only (in scoring, not filtering)
- [ ] ExpertSearchService.getTopExperts() includes Local level experts

### **Vibe-First Matching Integrated:**
- [ ] Vibe compatibility calculated for all matches
- [ ] Vibe-first matching formula: 50% vibe + 30% expertise + 20% location
- [ ] Vibe is PRIMARY factor (50% weight)
- [ ] 70%+ vibe compatibility considered (but not required)

### **AI Prompts Updated:**
- [ ] AI prompts emphasize vibe as PRIMARY factor
- [ ] AI prompts de-emphasize geographic level
- [ ] AI prompts say "vibe match is most important"
- [ ] AI prompts focus on: event fit, product fit, idea fit, community fit, VIBE fit

### **Location as Preference Boost:**
- [ ] Location is preference boost only, not filter
- [ ] Remote experts with great vibe/expertise are included
- [ ] Local experts in locality get boost, but not required
- [ ] Location matching doesn't exclude any experts

---

## 📝 **Notes**

- **Verification First:** Some work may already be done (vibe-first matching appears implemented). Verify what's done vs what needs enhancement.
- **Critical for Local Experts:** This phase ensures local experts aren't excluded from business opportunities
- **Vibe Over Level:** Matching prioritizes personality fit over geographic level
- **Backward Compatibility:** All existing business-expert matches should continue to work

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Start

