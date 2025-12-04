# Phase 6 Agent Prompts - Local Expert System Redesign (Week 28)

**Date:** November 24, 2025  
**Purpose:** Ready-to-use prompts for Phase 6, Week 28 (Community Events - Phase 3, Week 1) agents  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 28 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Verify:** Week 26-27 (Phase 2) is COMPLETE - Event Discovery & Matching done

**Protocol Requirements:**
- ✅ **Shared files:** Use `docs/agents/status/status_tracker.md` (SINGLE FILE for all phases)
- ✅ **Shared files:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Shared files:** Use `docs/agents/protocols/` for workflows (shared across all phases)
- ✅ **Phase-specific:** Use `docs/agents/prompts/phase_6/week_28_prompts.md` (this file)
- ✅ **Phase-specific:** Use `docs/agents/tasks/phase_6/week_28_task_assignments.md`
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/` (organized by agent, then phase)

**❌ DO NOT:**
- ❌ Create files in `docs/` root (e.g., `docs/PHASE_6_*.md`)
- ❌ Create phase-specific status trackers (e.g., `status/status_tracker_phase_6.md`)
- ❌ Use old-style paths (e.g., `docs/AGENT_STATUS_TRACKER.md`)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: Tasks Are Assigned = Phase 6 Week 28 Is IN PROGRESS**

**This prompts document EXISTS (along with task assignments), which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 28 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document + task assignments exist):**

- ❌ **NO new tasks can be added** to Phase 6 Week 28
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 28 Overview**

**Duration:** Week 28 (5 days)  
**Focus:** Community Events (Non-Expert Hosting) - Phase 3, Week 1  
**Priority:** P1 - Core Functionality  
**Philosophy:** Anyone can host community events, enabling organic community building

**What Doors Does This Open?**
- **Hosting Doors:** Non-experts can host public community events
- **Community Doors:** Events create communities naturally
- **Upgrade Doors:** Successful community events can upgrade to local expert events
- **Access Doors:** No expertise required to start building community

**When Are Users Ready?**
- After users understand the platform
- System allows non-experts to create events
- Community events are public and free (no payment on app)
- Upgrade path available for successful events

**Why Critical:**
- Enables organic community building (no expertise gate)
- Allows anyone to host events (democratizes event hosting)
- Creates natural path from community events to expert events
- Tracks event metrics for upgrade eligibility

**Dependencies:**
- ✅ Week 26-27 (Phase 2) COMPLETE - Event Discovery & Matching done
- ✅ ExpertiseEventService exists
- ✅ ExpertiseEvent model exists

---

## 🤖 **Agent 1: Backend & Integration**

### **Week 28 Prompt:**

```
You are Agent 1 working on Phase 6, Week 28: Community Events (Non-Expert Hosting).

**Your Role:** Backend & Integration Specialist
**Focus:** CommunityEvent Model, CommunityEventService, CommunityEventUpgradeService

**Context:**
- ✅ Week 26-27 (Phase 2) is COMPLETE - Event Discovery & Matching done
- ✅ ExpertiseEventService exists (from Phase 1)
- ✅ ExpertiseEvent model exists (from Phase 1)
- 🎯 **START WORK NOW** - Create community events system for non-expert hosting

**Your Tasks:**

**Day 1-2: CommunityEvent Model**
1. Create `lib/core/models/community_event.dart`
   - Model for non-expert community events
   - Extends or separate from ExpertiseEvent (decision: extend with isCommunityEvent flag)
   - Add isCommunityEvent flag (true for community events)
   - Add hostExpertiseLevel (nullable - null for non-experts)
   - Enforce no payment on app (cash at door OK):
     * price must be null or 0.0
     * isPaid must be false
     * Validation in model or service
   - Add event metrics tracking:
     * Attendance count
     * Engagement score (views, saves, shares)
     * Growth metrics (attendance growth over time)
     * Diversity metrics (attendee diversity)
   - Add upgrade eligibility tracking:
     * isEligibleForUpgrade flag
     * upgradeEligibilityScore (0.0 to 1.0)
     * upgradeCriteria (which criteria met)
   - Follow existing ExpertiseEvent patterns:
     * Equatable implementation
     * JSON serialization/deserialization
     * CopyWith methods
     * Helper methods

**Day 3-4: CommunityEventService**
1. Create `lib/core/services/community_event_service.dart`
   - Allow non-experts to create events:
     * createCommunityEvent() method
     * No expertise level required
     * Host can be any user (not just experts)
   - Validate community event requirements:
     * No payment on app (price must be null or 0.0)
     * Public events only (isPublic must be true)
     * Valid event details (title, description, category, dates)
   - Track event metrics:
     * trackAttendance() - Update attendance count
     * trackEngagement() - Update engagement score
     * trackGrowth() - Update growth metrics
     * trackDiversity() - Update diversity metrics
   - Event management:
     * getCommunityEvents() - Get all community events
     * getCommunityEventsByHost() - Get events by host
     * getCommunityEventsByCategory() - Get events by category
     * updateCommunityEvent() - Update event details
     * cancelCommunityEvent() - Cancel event
   - Integration with ExpertiseEventService:
     * Community events appear in event search
     * Community events appear in event browse
     * Community events can be filtered separately

**Day 5: CommunityEventUpgradeService**
1. Create `lib/core/services/community_event_upgrade_service.dart`
   - Implement upgrade criteria evaluation:
     * Frequency hosting (host has hosted X events in Y time)
     * Strong following (active returns, growth in size + diversity):
       - Active returns: repeat attendees
       - Growth in size: attendance increasing
       - Diversity: diverse attendee base
     * User interaction patterns:
       - High engagement (views, saves, shares)
       - Positive feedback/ratings
       - Community building indicators
   - Calculate upgrade eligibility:
     * checkUpgradeEligibility() - Check if event is eligible
     * calculateUpgradeScore() - Calculate eligibility score (0.0 to 1.0)
     * getUpgradeCriteria() - Get which criteria are met
   - Create upgrade flow:
     * upgradeToLocalEvent() - Upgrade community event to local expert event
     * Update event type (community → local)
     * Update host expertise (if needed)
     * Preserve event history and metrics
     * Notify host of upgrade

**Deliverables:**
- CommunityEvent model created
- CommunityEventService created
- Non-experts can create community events
- Community events can't charge on app
- Event metrics tracking working
- CommunityEventUpgradeService created
- Upgrade path to local events working
- Zero linter errors
- All services follow existing patterns

**Dependencies:**
- ✅ Week 26-27 COMPLETE
- ✅ ExpertiseEventService (exists)
- ✅ ExpertiseEvent model (exists)
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
- lib/core/models/community_event.dart
- lib/core/services/community_event_service.dart
- lib/core/services/community_event_upgrade_service.dart

**Files to Modify:**
- lib/core/services/expertise_event_service.dart (integration - ensure community events appear in search)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_28_task_assignments.md`
- Implementation plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Requirements: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Week 28 Prompt:**

```
You are Agent 2 working on Phase 6, Week 28: Community Events (Non-Expert Hosting).

**Your Role:** Frontend & UX Specialist
**Focus:** CreateCommunityEventPage, Community Event Display Widgets

**Context:**
- ✅ Week 26-27 (Phase 2) is COMPLETE
- ✅ Agent 1 is creating CommunityEventService and CommunityEventUpgradeService
- 🎯 **START WORK NOW** - Create UI for community event creation and display

**Your Tasks:**

**Day 1-3: CreateCommunityEventPage**
1. Create `lib/presentation/pages/events/create_community_event_page.dart`
   - Form for creating community events:
     * Title input
     * Description input
     * Category selection
     * Event type selection
     * Date/time pickers (start, end)
     * Location input
     * Max attendees input
     * Public/private toggle (must be public for community events)
   - Validation:
     * No price field (community events are free)
     * Public events only (private not allowed)
     * Required fields validation
     * Date validation (start before end, future dates)
   - Use AppColors/AppTheme (100% adherence):
     * No direct Colors.* usage
     * All colors from AppColors
     * All styling from AppTheme
   - Follow existing UI patterns:
     * Similar to CreateEventPage but simplified
     * Clear indication this is a community event
     * Helpful messaging about community events

**Day 4-5: Community Event Display Widgets**
1. Create `lib/presentation/widgets/events/community_event_widget.dart`
   - Display community event card:
     * Event title and description
     * Host information (non-expert indicator)
     * Event type and category
     * Date, time, location
     * Attendance count
     * "Community Event" badge
     * Upgrade eligibility indicator (if eligible)
   - Use AppColors/AppTheme (100% adherence)
   - Follow existing ExpertiseEventWidget patterns
   - Show community event specific information

2. Update `lib/presentation/pages/events/events_browse_page.dart`
   - Add community event filtering:
     * Filter by community events
     * Show community events in Community tab
     * Distinguish community events from expert events
   - Integration with CommunityEventService:
     * Load community events
     * Display community events
     * Handle community event interactions

**Deliverables:**
- CreateCommunityEventPage created
- Community event form working
- Validation for community events (no payment, public only)
- CommunityEventWidget created
- Community events displayed in EventsBrowsePage
- Zero linter errors
- 100% AppColors/AppTheme adherence
- Responsive and accessible

**Dependencies:**
- ✅ Week 26-27 COMPLETE
- ✅ Agent 1 CommunityEventService (complete)
- ✅ Agent 1 CommunityEvent model (complete)

**Quality Standards:**
- Zero linter errors
- 100% AppColors/AppTheme adherence (NO direct Colors.*)
- Responsive design
- Accessibility support
- Follow existing UI patterns

**Status Tracking:**
- Update `docs/agents/status/status_tracker.md` with your progress
- Create completion report in `docs/agents/reports/agent_2/phase_6/`

**Files to Create:**
- lib/presentation/pages/events/create_community_event_page.dart
- lib/presentation/widgets/events/community_event_widget.dart

**Files to Modify:**
- lib/presentation/pages/events/events_browse_page.dart (community event integration)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_28_task_assignments.md`
```

---

## 🧪 **Agent 3: Models & Testing**

### **Week 28 Prompt:**

```
You are Agent 3 working on Phase 6, Week 28: Community Events (Non-Expert Hosting) - Testing.

**Your Role:** Models & Testing Specialist
**Focus:** Community Event Models, Tests, Documentation

**Context:**
- ✅ Week 26-27 (Phase 2) is COMPLETE
- ✅ Agent 1 is creating CommunityEvent model and services
- 🎯 **START WORK NOW** - Create models, tests, and documentation
- ⚠️ **CRITICAL:** Write tests based on specifications/requirements (TDD approach) - DO NOT wait for Agent 1's implementation
- ⚠️ **After Agent 1 completes:** Verify tests pass and update if implementation differs from spec
- 📖 **Full Protocol:** See `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md` for detailed workflow model

**Your Tasks:**

**Day 1-2: Community Event Models (if needed)**
1. Review CommunityEvent Model (created by Agent 1)
   - Verify model structure
   - Verify validation logic
   - Verify upgrade eligibility tracking
   - Create additional models if needed:
     * EventMetrics model (if not embedded)
     * UpgradeCriteria model (if not embedded)

**Day 3-5: Tests & Documentation**
1. Create `test/unit/models/community_event_test.dart`
   - Test model creation
   - Test validation (no payment, public only)
   - Test upgrade eligibility tracking
   - Test event metrics tracking
   - Test JSON serialization/deserialization

2. Create `test/unit/services/community_event_service_test.dart`
   - Test non-expert event creation
   - Test validation (no payment, public only)
   - Test event metrics tracking
   - Test event management (get, update, cancel)
   - Test integration with ExpertiseEventService

3. Create `test/unit/services/community_event_upgrade_service_test.dart`
   - Test upgrade criteria evaluation
   - Test upgrade eligibility calculation
   - Test upgrade flow (community → local)
   - Test upgrade score calculation
   - Test upgrade criteria checking

4. Create Integration Tests
   - Test end-to-end community event creation
   - Test community event upgrade flow
   - Test community events in event search
   - Test community events in event browse

5. Documentation
   - Document CommunityEvent model
   - Document CommunityEventService
   - Document CommunityEventUpgradeService
   - Document upgrade criteria and flow
   - Update system documentation

**Deliverables:**
- Community event model tests created
- CommunityEventService tests created
- CommunityEventUpgradeService tests created
- Integration tests created
- Documentation complete
- All tests pass
- Test coverage > 90%

**Dependencies:**
- ✅ Week 26-27 COMPLETE
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
- test/unit/models/community_event_test.dart
- test/unit/services/community_event_service_test.dart
- test/unit/services/community_event_upgrade_service_test.dart
- test/integration/community_event_integration_test.dart

**Files to Review:**
- lib/core/models/community_event.dart (created by Agent 1)
- lib/core/services/community_event_service.dart (created by Agent 1)
- lib/core/services/community_event_upgrade_service.dart (created by Agent 1)

**Reference:**
- Task assignments: `docs/agents/tasks/phase_6/week_28_task_assignments.md`
- Testing workflow: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
```

---

## 📊 **Success Criteria**

### **Community Event Model:**
- [ ] CommunityEvent model created
- [ ] No payment on app enforced
- [ ] Public events only enforced
- [ ] Event metrics tracking included
- [ ] Upgrade eligibility tracking included

### **CommunityEventService:**
- [ ] Non-experts can create events
- [ ] Validation working (no payment, public only)
- [ ] Event metrics tracking working
- [ ] Event management working
- [ ] Integration with ExpertiseEventService complete

### **CommunityEventUpgradeService:**
- [ ] Upgrade criteria evaluation working
- [ ] Upgrade eligibility calculation working
- [ ] Upgrade flow (community → local) working
- [ ] Upgrade preserves event history

### **UI:**
- [ ] CreateCommunityEventPage created
- [ ] Community event form working
- [ ] Community events displayed in EventsBrowsePage
- [ ] 100% AppColors/AppTheme adherence

---

## 📝 **Notes**

- **No Expertise Required:** Community events allow anyone to host, no expertise gate
- **No Payment on App:** Community events are free (cash at door OK)
- **Public Only:** Community events must be public
- **Upgrade Path:** Successful community events can upgrade to local expert events
- **Metrics Tracking:** Track attendance, engagement, growth, diversity for upgrade eligibility

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Start

