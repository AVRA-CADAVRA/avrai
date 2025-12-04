# Phase 6 Agent Prompts - Local Expert System Redesign (Week 29)

**Date:** November 24, 2025  
**Purpose:** Ready-to-use prompts for agents working on Phase 6, Week 29 (Clubs/Communities - Phase 3, Week 2)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_6/week_29_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`** - Detailed implementation plan
6. ✅ **`docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`** - Complete requirements
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/week_29_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

**📁 Report Organization Schema (MANDATORY):**
- **Reports MUST be organized by agent first, then phase:** `docs/agents/reports/agent_X/[phase]/[filename].md`
- **Phase folder naming:**
  - Phase 1 (Weeks 1-4): `trial_run/`
  - Phase 2 (Weeks 5-8): `phase_2/`
  - Phase 3 (Weeks 9-12): `phase_3/`
  - Phase 4 (Weeks 13-14): `phase_4/`
  - Phase 4.5: `phase_4.5/`
  - Phase 5 (Weeks 16-21): `phase_5/`
  - Phase 6 (Weeks 22+): `phase_6/`
- **File naming:** Use descriptive names like `AGENT_X_WEEK_Y_COMPLETION.md` or `week_Y_[feature]_documentation.md`
- **See:** `docs/agents/reports/README.md` for complete organization schema
- **❌ DO NOT:** Create reports in agent root folder - always use phase subfolders

---

## 🎯 **Week 29 Overview**

**Focus:** Clubs/Communities (Phase 3, Week 2)  
**Duration:** 5 days  
**Priority:** P1 - Core Functionality

**What Doors Does This Open?**
- **Community Doors:** Events create communities naturally (people who attend together)
- **Organization Doors:** Communities can organize as clubs (structure, leadership, hierarchy)
- **Expansion Doors:** Clubs can expand geographically (75% coverage rule - Week 30)
- **Leadership Doors:** Club leaders gain expertise recognition
- **Connection Doors:** People find their communities through events

**Philosophy Alignment:**
- Events naturally create communities (doors open from events)
- Communities can organize as clubs (structure when needed)
- Club leaders recognized as experts (doors for leaders)
- Geographic expansion enabled (Week 30 - 75% coverage rule)

**Dependencies:**
- ✅ Week 28 (Phase 3, Week 1) COMPLETE - Community Events done
- ✅ CommunityEventService exists
- ✅ ExpertiseEventService exists

**Note:** This is different from `ExpertiseCommunity` (expertise-based communities). This is about communities/clubs that form from events.

---

## 🤖 **Agent 1: Backend & Integration**

### **Prompt for Agent 1:**

```
You are Agent 1: Backend & Integration Specialist working on Phase 6, Week 29 (Clubs/Communities - Phase 3, Week 2).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 29 - Clubs/Communities (Phase 3, Week 2)  
**Status:** Ready to Start  
**Dependencies:** Week 28 (Community Events) COMPLETE

**What You're Building:**
- Community Model - Communities that form from events
- Club Model - Clubs (extends Community) with organizational structure
- ClubHierarchy Model - Organizational structure (roles, permissions)
- CommunityService - Auto-create communities from successful events
- ClubService - Upgrade communities to clubs, manage organizational structure

**Philosophy:**
- Events naturally create communities (people who attend together)
- Communities can organize as clubs when structure is needed
- Club leaders gain expertise recognition
- This is different from ExpertiseCommunity (expertise-based communities)

## Tasks

**Day 1-2: Community Model**
1. Create `lib/core/models/community.dart`
   - Model for communities created from events
   - Link to originating event (originatingEventId, originatingEventType)
   - Track members (memberIds, memberCount, founderId)
   - Track events (eventIds, eventCount)
   - Track growth (memberGrowthRate, eventGrowthRate, createdAt, lastEventAt)
   - Store community metrics (engagementScore, diversityScore, activityLevel)
   - Geographic tracking (originalLocality, currentLocalities)
   - Follow existing model patterns (Equatable, JSON, CopyWith, helpers)

**Day 3-4: Club Model & ClubHierarchy**
2. Create `lib/core/models/club.dart`
   - Extends Community model
   - Add organizational structure (isClub, leaders, adminTeam, hierarchy)
   - Member management (memberRoles, pendingMembers, bannedMembers)
   - Club-specific metrics (organizationalMaturity, leadershipStability)
   - Geographic expansion tracking (for Week 30)

3. Create `lib/core/models/club_hierarchy.dart`
   - Model for club organizational structure
   - Roles enum (Leader, Admin, Moderator, Member)
   - Permissions system (canCreateEvents, canManageMembers, etc.)
   - Role hierarchy (Leader > Admin > Moderator > Member)

**Day 5: CommunityService & ClubService**
4. Create `lib/core/services/community_service.dart`
   - Auto-create community from successful events (createCommunityFromEvent)
   - Success criteria: X+ attendees, Y+ repeat attendees, high engagement
   - Manage community members (addMember, removeMember, getMembers, isMember)
   - Manage community events (addEvent, getEvents, getUpcomingEvents)
   - Track community growth (updateGrowthMetrics, calculateEngagementScore, calculateDiversityScore)
   - Community management (getCommunityById, getCommunitiesByFounder, getCommunitiesByCategory, updateCommunity, deleteCommunity)

5. Create `lib/core/services/club_service.dart`
   - Upgrade community to club (upgradeToClub)
   - Upgrade criteria: X+ members, Y+ events, stable leadership, needs structure
   - Manage club leaders (addLeader, removeLeader, getLeaders, isLeader)
   - Manage admin team (addAdmin, removeAdmin, getAdmins, isAdmin)
   - Manage member roles (assignRole, getMemberRole, hasPermission)
   - Club management (getClubById, getClubsByLeader, getClubsByCategory, updateClub)
   - Integration with CommunityService

6. Modify `lib/core/services/community_event_service.dart`
   - Integration: Auto-create community from successful events
   - Call CommunityService.createCommunityFromEvent() when event is successful

## Deliverables

- ✅ Community model created
- ✅ Club model created (extends Community)
- ✅ ClubHierarchy model created
- ✅ CommunityService created
- ✅ Auto-create community from successful events working
- ✅ ClubService created
- ✅ Upgrade community to club working
- ✅ Organizational structure (leaders, admins, hierarchy) working
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

- ✅ Week 28 (Community Events) COMPLETE
- ✅ CommunityEventService exists
- ✅ ExpertiseEventService exists

## Testing

- Agent 3 will create tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Update service documentation
- Document upgrade flow (community → club)
- Document organizational structure
- Create completion report: `docs/agents/reports/agent_1/phase_6/week_29_community_club_services.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_29_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`

**START WORK NOW.**
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Prompt for Agent 2:**

```
You are Agent 2: Frontend & UX Specialist working on Phase 6, Week 29 (Clubs/Communities - Phase 3, Week 2).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 29 - Clubs/Communities (Phase 3, Week 2)  
**Status:** Ready to Start  
**Dependencies:** Week 28 (Community Events) COMPLETE, Agent 1 creating models/services

**What You're Building:**
- CommunityPage - Display community information and actions
- ClubPage - Display club information, organizational structure, and actions
- ExpertiseCoverageWidget - Display expertise coverage by locality (prepared for Week 30)
- Clubs/Communities tab integration in EventsBrowsePage

**Philosophy:**
- Events naturally create communities (people who attend together)
- Communities can organize as clubs when structure is needed
- Club leaders gain expertise recognition
- Show doors (communities, clubs) that users can open

## Tasks

**Day 1-3: Community/Club Pages**
1. Create `lib/presentation/pages/communities/community_page.dart`
   - Display community information (name, description, founder, members, events, metrics)
   - Community actions (join/leave, view members, view events, create event)
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Follow existing page patterns

2. Create `lib/presentation/pages/clubs/club_page.dart`
   - Display club information (name, description, leaders, admins, members, events, metrics)
   - Club actions (join/leave, view members, view events, create event, manage members/roles)
   - Organizational structure display (hierarchy, roles, permissions)
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Follow existing page patterns

**Day 4-5: Expertise Coverage Visualization (Prep for Week 30)**
3. Create `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`
   - Display expertise coverage by locality (list view, prepared for map view in Week 30)
   - Coverage metrics (locality, city, state, national - 75% threshold indicators)
   - Expansion tracking display (prepared for Week 30)
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Follow existing widget patterns

4. Update `lib/presentation/pages/events/events_browse_page.dart`
   - Add Clubs/Communities tab integration
   - Show club/community events in Clubs/Communities tab
   - Filter by club/community
   - Integration with CommunityService and ClubService

## Deliverables

- ✅ CommunityPage created
- ✅ ClubPage created
- ✅ ExpertiseCoverageWidget created (prepared for Week 30)
- ✅ Clubs/Communities tab integration in EventsBrowsePage
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

- ✅ Week 28 (Community Events) COMPLETE
- ⏳ Agent 1 creating Community/Club models and services (work in parallel)
- ✅ CommunityEventService exists
- ✅ ExpertiseEventService exists

## Integration Points

- **CommunityService:** Load communities, join/leave, create events
- **ClubService:** Load clubs, join/leave, manage members/roles, create events
- **CommunityEventService:** Load community events
- **ExpertiseEventService:** Load club events

## Testing

- Agent 3 will create widget tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Document UI components
- Document integration points
- Create completion report: `docs/agents/reports/agent_2/phase_6/week_29_agent_2_completion.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_29_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Design Tokens: `lib/core/theme/colors.dart` and `lib/core/theme/app_theme.dart`

**START WORK NOW.**
```

---

## 🧪 **Agent 3: Models & Testing**

### **Prompt for Agent 3:**

```
You are Agent 3: Models & Testing Specialist working on Phase 6, Week 29 (Clubs/Communities - Phase 3, Week 2).

## Context

**Phase:** Phase 6 - Local Expert System Redesign  
**Week:** Week 29 - Clubs/Communities (Phase 3, Week 2)  
**Status:** Ready to Start  
**Dependencies:** Week 28 (Community Events) COMPLETE, Agent 1 creating models/services

**What You're Testing:**
- Community Model - Communities that form from events
- Club Model - Clubs (extends Community) with organizational structure
- ClubHierarchy Model - Organizational structure (roles, permissions)
- CommunityService - Auto-create communities from successful events
- ClubService - Upgrade communities to clubs, manage organizational structure

**Philosophy:**
- Events naturally create communities (people who attend together)
- Communities can organize as clubs when structure is needed
- Club leaders gain expertise recognition

## Testing Workflow (TDD Approach)

**Follow the parallel testing workflow protocol:**
- Read `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Write tests based on specifications (before or in parallel with Agent 1's implementation)
- Tests serve as specifications for Agent 1
- Verify implementation matches test specifications

## Tasks

**Day 1-2: Review Models (if needed)**
1. Review Community Model (created by Agent 1)
   - Verify model structure
   - Verify event linking
   - Verify member/event tracking
   - Verify growth metrics
   - Create additional models if needed

2. Review Club Model (created by Agent 1)
   - Verify extends Community correctly
   - Verify organizational structure
   - Verify member roles
   - Verify expansion tracking

3. Review ClubHierarchy Model (created by Agent 1)
   - Verify roles enum
   - Verify permissions system
   - Verify role hierarchy

**Day 3-5: Tests & Documentation**
4. Create `test/unit/models/community_test.dart`
   - Test model creation
   - Test event linking
   - Test member tracking
   - Test event tracking
   - Test growth metrics
   - Test JSON serialization/deserialization

5. Create `test/unit/models/club_test.dart`
   - Test extends Community correctly
   - Test organizational structure
   - Test member roles
   - Test permissions
   - Test JSON serialization/deserialization

6. Create `test/unit/models/club_hierarchy_test.dart`
   - Test roles enum
   - Test permissions system
   - Test role hierarchy
   - Test permission checking

7. Create `test/unit/services/community_service_test.dart`
   - Test auto-create community from event
   - Test member management
   - Test event management
   - Test growth tracking
   - Test community management

8. Create `test/unit/services/club_service_test.dart`
   - Test upgrade community to club
   - Test leader management
   - Test admin management
   - Test member role management
   - Test permissions
   - Test club management

9. Create Integration Tests
   - Test end-to-end community creation from event
   - Test community upgrade to club
   - Test organizational structure
   - Test member roles and permissions

10. Documentation
    - Document Community model
    - Document Club model
    - Document ClubHierarchy model
    - Document CommunityService
    - Document ClubService
    - Document upgrade flow (community → club)
    - Update system documentation

## Deliverables

- ✅ Community model tests created
- ✅ Club model tests created
- ✅ ClubHierarchy model tests created
- ✅ CommunityService tests created
- ✅ ClubService tests created
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

- ✅ Week 28 (Community Events) COMPLETE
- ⏳ Agent 1 creating Community/Club models and services (work in parallel)
- ✅ CommunityEventService exists
- ✅ ExpertiseEventService exists

## Documentation

- Document all models and services
- Document upgrade flow (community → club)
- Document organizational structure
- Update system documentation
- Create completion report: `docs/agents/reports/agent_3/phase_6/week_29_community_club_tests_documentation.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_6/week_29_task_assignments.md`
- Implementation Plan: `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Testing Workflow: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`

**START WORK NOW.**
```

---

## 📋 **Quick Reference**

### **Files to Create:**

**Agent 1:**
- `lib/core/models/community.dart`
- `lib/core/models/club.dart`
- `lib/core/models/club_hierarchy.dart`
- `lib/core/services/community_service.dart`
- `lib/core/services/club_service.dart`

**Agent 2:**
- `lib/presentation/pages/communities/community_page.dart`
- `lib/presentation/pages/clubs/club_page.dart`
- `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`

**Agent 3:**
- `test/unit/models/community_test.dart`
- `test/unit/models/club_test.dart`
- `test/unit/models/club_hierarchy_test.dart`
- `test/unit/services/community_service_test.dart`
- `test/unit/services/club_service_test.dart`
- `test/integration/community_club_integration_test.dart`

### **Files to Modify:**

**Agent 1:**
- `lib/core/services/community_event_service.dart` (auto-create community integration)

**Agent 2:**
- `lib/presentation/pages/events/events_browse_page.dart` (Clubs/Communities tab)

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

