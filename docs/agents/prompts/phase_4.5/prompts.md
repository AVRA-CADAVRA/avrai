# Phase 4.5 Agent Prompts - Partnership Profile Visibility & Expertise Boost

**Date:** November 23, 2025, 4:30 PM CST  
**Purpose:** Ready-to-use prompts for Phase 4.5 (Week 15) agents  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 4.5 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/agents/guides/PHASE_3_PREPARATION.md` - Setup guide (applies to Phase 4.5)
3. ✅ **Read:** `docs/agents/START_HERE_PHASE_3.md` - Quick checklist (applies to Phase 4.5)
4. ✅ **Read:** `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md` - Detailed plan

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_4.5/prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_4.5/task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_4.5/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_4.5_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_4.5.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: Tasks Are Assigned = Phase 4.5 Is IN PROGRESS**

**This prompts document EXISTS (along with task assignments), which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 4.5 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document + task assignments exist):**

- ❌ **NO new tasks can be added** to Phase 4.5
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 4.5 Overview**

**Duration:** Week 15 (5 days)  
**Focus:** Partnership Profile Visibility & Expertise Boost  
**Priority:** P1 HIGH VALUE  
**Philosophy:** "Doors, not badges" - Partnerships open doors to collaboration and expertise recognition

**What Doors Does This Open?**
- **Visibility:** Users can showcase their professional collaborations and partnerships
- **Recognition:** Successful partnerships boost expertise, recognizing collaborative contributions
- **Discovery:** Other users can see who partners with whom, opening doors to new connections
- **Credibility:** Partnership visibility builds trust and demonstrates real-world collaboration

**When Are Users Ready?**
- After they've completed partnerships (active or completed status)
- Partnership systems are live and functioning
- Users can opt-in to display partnerships on their profiles

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 15 Prompt:**

```
You are Agent 1 working on Phase 4.5, Week 15: Partnership Profile Visibility & Expertise Boost.

**Your Role:** Backend & Integration Specialist
**Focus:** Partnership Profile Service, Expertise Calculation Service Integration

**Context:**
- ✅ Phase 4 (Integration Testing) is COMPLETE
- ✅ PartnershipService exists (from Phase 2)
- ✅ SponsorshipService exists (from Phase 3)
- ✅ BusinessService exists (from Phase 2)
- ✅ ExpertiseCalculationService exists (from Phase 2)
- 🎯 **START WORK NOW** - Create partnership profile service and integrate expertise boost

**Your Tasks:**
1. Partnership Profile Service (Day 1-2)
   - Create PartnershipProfileService with methods to:
     - Get all partnerships for a user
     - Get active partnerships only
     - Get completed partnerships
     - Filter partnerships by type (business, brand, company)
     - Calculate partnership expertise boost
   - Integrate with PartnershipService (read-only)
   - Integrate with SponsorshipService (read-only)
   - Integrate with BusinessService (read-only)
   - Create UserPartnership model (per plan specification)
   - Create ProfilePartnershipType enum
   - Test edge cases and error handling

2. Expertise Calculation Integration (Day 3-4)
   - Update ExpertiseCalculationService to:
     - Add calculatePartnershipBoost() method
     - Integrate partnership boost into calculateExpertise()
     - Add partnership boost to Community Path (60% of boost)
     - Add partnership boost to Professional Path (30% of boost)
     - Add partnership boost to Influence Path (10% of boost)
   - Implement partnership boost formula:
     - Status boost (active: +0.05, completed: +0.10, ongoing: +0.08)
     - Quality boost (vibe compatibility, revenue success, feedback)
     - Category alignment (same: 100%, related: 50%, unrelated: 25%)
     - Count multiplier (3-5: 1.2x, 6+: 1.5x)
     - Cap at 0.50 (50% max boost)
   - Integration with PartnershipProfileService
   - Test expertise calculation with partnership boost

3. Service Tests (Day 5)
   - Create comprehensive unit tests for PartnershipProfileService
   - Create comprehensive unit tests for expertise boost calculation
   - Test all edge cases and error handling
   - Ensure test coverage > 90%

**Deliverables:**
- PartnershipProfileService
- UserPartnership model
- PartnershipExpertiseBoost model
- Updated ExpertiseCalculationService
- Comprehensive test files
- Service documentation

**Dependencies:**
- ✅ PartnershipService (exists from Phase 2)
- ✅ SponsorshipService (exists from Phase 3)
- ✅ BusinessService (exists from Phase 2)
- ✅ ExpertiseCalculationService (exists from Phase 2)
- ✅ **NO BLOCKERS** - Start work immediately

**Quality Standards:**
- All services follow existing patterns
- Zero linter errors
- Partnership boost calculation accurate
- All edge cases handled
- Error handling comprehensive
- Test coverage > 90% for services

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4.5/task_assignments.md` - Your detailed tasks
- `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md` - Detailed plan
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing service files (PartnershipService, ExpertiseCalculationService) for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4.5/task_assignments.md` (Agent 1, Week 15)
2. Reviewing existing PartnershipService and ExpertiseCalculationService patterns
3. Creating PartnershipProfileService
4. Updating ExpertiseCalculationService
5. Creating comprehensive tests
```

---

## 🤖 **Agent 2: Frontend & UX**

### **Week 15 Prompt:**

```
You are Agent 2 working on Phase 4.5, Week 15: Partnership Profile Visibility & Expertise Boost.

**Your Role:** Frontend & UX Specialist
**Focus:** Partnership Display Widget, Profile Page Integration, Partnerships Detail Page, Expertise Boost UI

**Context:**
- ✅ Phase 4 (Integration Testing) is COMPLETE
- ✅ Profile page exists (from Phase 1)
- ✅ Expertise Dashboard exists (from Phase 1)
- ✅ Partnership management UI exists (from Phase 2)
- 🎯 **START WORK NOW** - Create partnership profile visibility UI and expertise boost indicators

**Your Tasks:**
1. Partnership Display Widget (Day 1-2)
   - Create PartnershipDisplayWidget to display list of partnerships
   - Create PartnershipCard component for individual partnerships
   - Create PartnershipVisibilityToggle for privacy controls
   - Filter by partnership type (business, brand, company)
   - Show partner logo/name, status, event count
   - Link to partnership details

2. Profile Page Integration (Day 2-3)
   - Add partnerships section to ProfilePage
   - Show active partnerships prominently (3 max preview)
   - Show expertise boost indicator
   - Add "View All Partnerships" link
   - Ensure design token compliance
   - Responsive design verified

3. Partnerships Detail Page (Day 3-4)
   - Create PartnershipsPage with full list of all partnerships
   - Filter by type (Business, Brand, Company)
   - Filter by status (Active, Completed, All)
   - Show partnership detail cards
   - Show expertise boost breakdown
   - Visibility/privacy controls
   - Add route to app_router.dart

4. Expertise Boost UI (Day 4-5)
   - Create PartnershipExpertiseBoostWidget
   - Show partnership contribution to expertise
   - Visual indicator (e.g., "+X% from partnerships")
   - Breakdown by category
   - Link to partnerships page
   - Update ExpertiseDashboardPage with partnership boost section
   - Update ExpertiseDisplayWidget with partnership boost indicator

**Deliverables:**
- All UI widget files
- All UI page files
- UI integration updates
- Widget tests
- UI documentation

**Dependencies:**
- ✅ Agent 1 PartnershipProfileService (will be ready Day 2)
- ✅ Profile page exists
- ✅ Expertise Dashboard exists
- ✅ Existing UI patterns

**Quality Standards:**
- 100% design token adherence
- Zero linter errors
- Responsive design verified
- Error/loading/empty states handled
- Navigation flows complete

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4.5/task_assignments.md` - Your detailed tasks
- `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md` - Detailed plan
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing UI pages (ProfilePage, ExpertiseDashboardPage) for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4.5/task_assignments.md` (Agent 2, Week 15)
2. Reviewing existing UI patterns (ProfilePage, PartnershipManagementPage)
3. Creating PartnershipDisplayWidget
4. Updating ProfilePage
5. Creating PartnershipsPage
```

---

## 🤖 **Agent 3: Models & Testing**

### **Week 15 Prompt:**

```
You are Agent 3 working on Phase 4.5, Week 15: Partnership Profile Visibility & Expertise Boost.

**Your Role:** Models & Testing Specialist
**Focus:** UserPartnership Model, PartnershipExpertiseBoost Model, Integration Tests

**Context:**
- ✅ Phase 4 (Integration Testing) is COMPLETE
- ✅ EventPartnership model exists (from Phase 2)
- ✅ Sponsorship model exists (from Phase 3)
- ✅ BusinessAccount model exists (from Phase 2)
- ✅ Expertise models exist (from Phase 2)
- 🎯 **START WORK NOW** - Create profile partnership models and comprehensive integration tests

**Your Tasks:**
1. UserPartnership Model (Day 1-2)
   - Create UserPartnership model with all required fields:
     - id, type, partnerId, partnerName, partnerLogoUrl
     - status, startDate, endDate, category
     - vibeCompatibility, eventCount, isPublic
   - Follow existing patterns (Equatable, toJson, fromJson, copyWith)
   - Create ProfilePartnershipType enum (business, brand, company)
   - Integrate with existing PartnershipStatus enum
   - Create comprehensive model tests
   - Verify integration with Partnership models
   - Verify integration with Sponsorship models

2. PartnershipExpertiseBoost Model (Day 2-3)
   - Create PartnershipExpertiseBoost model with:
     - Total boost amount
     - Breakdown by status (active, completed, ongoing)
     - Breakdown by quality factors
     - Breakdown by category alignment
     - Partnership count multiplier
   - Follow existing patterns (Equatable, toJson, fromJson, copyWith)
   - Create comprehensive model tests
   - Verify integration with Expertise models

3. Integration Tests (Day 3-5)
   - Create partnership profile flow integration tests:
     - Get user partnerships flow
     - Filter partnerships by type flow
     - Calculate expertise boost flow
     - Profile visibility controls flow
   - Create expertise boost partnership integration tests:
     - Partnership boost calculation accuracy
     - Expertise calculation with partnership boost
     - Community/Professional/Influence path integration
     - Edge cases (no partnerships, many partnerships, etc.)
   - Create profile partnership display integration tests:
     - Profile page partnership display
     - Partnerships page navigation
     - Expertise boost indicator display
     - Visibility controls integration

**Deliverables:**
- All model files
- Model test files
- Integration test files
- Model documentation

**Dependencies:**
- ✅ EventPartnership model (exists from Phase 2)
- ✅ Sponsorship model (exists from Phase 3)
- ✅ BusinessAccount model (exists from Phase 2)
- ✅ Expertise models (exist from Phase 2)
- ✅ Agent 1 services (will be ready Day 2)
- ✅ Agent 2 UI (will be ready Day 4)
- ✅ **NO BLOCKERS** - Models can start immediately

**Quality Standards:**
- All models follow existing patterns (Equatable, toJson, fromJson, copyWith)
- Zero linter errors
- All model tests pass
- All integration tests pass
- Model relationships verified
- Test coverage > 90% for models

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Check dependencies before starting
- Communicate completion via status tracker

**Key Files to Review:**
- `docs/agents/tasks/phase_4.5/task_assignments.md` - Your detailed tasks
- `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md` - Detailed plan
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
- Existing model files (EventPartnership, Sponsorship) for patterns

**Start by:**
1. Reading `docs/agents/tasks/phase_4.5/task_assignments.md` (Agent 3, Week 15)
2. Reviewing existing model patterns (EventPartnership, Sponsorship)
3. Creating UserPartnership model
4. Creating PartnershipExpertiseBoost model
5. Creating comprehensive integration tests
```

---

## 📚 **Key References**

- **Master Plan:** `docs/MASTER_PLAN.md` - Phase 4.5 requirements
- **Partnership Profile Plan:** `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md` - Detailed plan
- **Status Tracker:** `docs/agents/status/status_tracker.md` - Current status
- **Quick Reference:** `docs/agents/reference/quick_reference.md` - Code patterns
- **Task Assignments:** `docs/agents/tasks/phase_4.5/task_assignments.md` - Detailed tasks
- **Event Partnership Plan:** `docs/plans/event_partnership/EVENT_PARTNERSHIP_MONETIZATION_PLAN.md`
- **Brand Sponsorship Plan:** `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md`
- **Expertise System:** `docs/plans/dynamic_expertise/DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md`

---

**Last Updated:** November 23, 2025, 4:30 PM CST  
**Status:** 🎯 **READY TO START**

