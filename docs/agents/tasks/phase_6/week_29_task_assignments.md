# Phase 6 Task Assignments - Local Expert System Redesign (Week 29)

**Date:** November 24, 2025  
**Purpose:** Detailed task assignments for Phase 6, Week 29 (Clubs/Communities - Phase 3, Week 2)  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 6 Week 29 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md` - Detailed implementation plan
3. ✅ **Read:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md` - Complete requirements
4. ✅ **Read:** `docs/plans/philosophy_implementation/DOORS.md` - **MANDATORY** - Core philosophy
5. ✅ **Read:** `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - **MANDATORY** - Philosophy alignment
6. ✅ **Verify:** Week 28 (Phase 3, Week 1) is COMPLETE - Community Events done

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Protocols:** Use `docs/agents/protocols/` files (shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_6/` (organized by agent, then phase)

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

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: This Document Means Tasks Are Assigned**

**This task assignments document EXISTS, which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 6 Week 29 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document exists):**

- ❌ **NO new tasks can be added** to Phase 6 Week 29
- ❌ **NO modifications** to task scope or deliverables
- ❌ **NO changes** to week structure
- ✅ **ONLY status updates** allowed (completion, blockers, progress)
- ✅ **ONLY completion reports** can be added

**This rule prevents disruption of active agent work.**

---

## 🎯 **Phase 6 Week 29 Overview**

**Duration:** Week 29 (5 days)  
**Focus:** Clubs/Communities (Phase 3, Week 2)  
**Priority:** P1 - Core Functionality  
**Philosophy:** Events naturally create communities, communities can organize as clubs

**What Doors Does This Open?**
- **Community Doors:** Events create communities naturally (people who attend together)
- **Organization Doors:** Communities can organize as clubs (structure, leadership, hierarchy)
- **Expansion Doors:** Clubs can expand geographically (75% coverage rule - Week 30)
- **Leadership Doors:** Club leaders gain expertise recognition
- **Connection Doors:** People find their communities through events

**When Are Users Ready?**
- After attending events (communities form from event attendees)
- After communities grow (upgrade to clubs when structure needed)
- System recognizes successful community building
- Club leaders gain expertise recognition

**Why Critical:**
- Enables natural community formation from events
- Provides organizational structure for growing communities
- Recognizes community leaders as experts
- Creates path for geographic expansion (Week 30)

**Dependencies:**
- ✅ Week 28 (Phase 3, Week 1) COMPLETE - Community Events done
- ✅ CommunityEventService exists (from Week 28)
- ✅ ExpertiseEventService exists (from Phase 1)

**Note:** This is different from `ExpertiseCommunity` (expertise-based communities). This is about communities/clubs that form from events.

---

## 📋 **Agent Assignments**

### **Agent 1: Backend & Integration**
**Focus:** Community Model, Club Model, CommunityService, ClubService, ClubHierarchy

### **Agent 2: Frontend & UX**
**Focus:** Community/Club Pages, Expertise Coverage Visualization, Organizational UI

### **Agent 3: Models & Testing**
**Focus:** Community/Club Models, Tests, Documentation

---

## 📅 **Week 29: Clubs/Communities**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start  
**Focus:** Community Model, Club Model, Services

**Tasks:**

#### **Day 1-2: Community Model**
- [ ] **Create `lib/core/models/community.dart`**
  - [ ] Model for communities created from events
  - [ ] Link to originating event:
    - [ ] `originatingEventId` - ID of event that created this community
    - [ ] `originatingEventType` - Type of event (CommunityEvent or ExpertiseEvent)
  - [ ] Track members:
    - [ ] `memberIds` - List of user IDs
    - [ ] `memberCount` - Total member count
    - [ ] `founderId` - User who created the community (event host)
  - [ ] Track events:
    - [ ] `eventIds` - List of event IDs hosted by this community
    - [ ] `eventCount` - Total events hosted
  - [ ] Track growth:
    - [ ] `memberGrowthRate` - Growth rate of members
    - [ ] `eventGrowthRate` - Growth rate of events
    - [ ] `createdAt` - When community was created
    - [ ] `lastEventAt` - Last event hosted
  - [ ] Store community metrics:
    - [ ] `engagementScore` - Community engagement (0.0 to 1.0)
    - [ ] `diversityScore` - Member diversity (0.0 to 1.0)
    - [ ] `activityLevel` - Activity level (active, growing, stable, declining)
  - [ ] Geographic tracking:
    - [ ] `originalLocality` - Original locality where community formed
    - [ ] `currentLocalities` - List of localities where community is active
  - [ ] Follow existing model patterns:
    - [ ] Equatable implementation
    - [ ] JSON serialization/deserialization
    - [ ] CopyWith methods
    - [ ] Helper methods

#### **Day 3-4: Club Model & ClubHierarchy**
- [ ] **Create `lib/core/models/club.dart`**
  - [ ] Extends Community model
  - [ ] Add organizational structure:
    - [ ] `isClub` flag (true for clubs)
    - [ ] `leaders` - List of leader user IDs (founders, primary organizers)
    - [ ] `adminTeam` - List of admin user IDs (managers, moderators)
    - [ ] `hierarchy` - ClubHierarchy object (roles, permissions)
  - [ ] Member management:
    - [ ] `memberRoles` - Map of user ID → role
    - [ ] `pendingMembers` - List of pending member requests
    - [ ] `bannedMembers` - List of banned member IDs
  - [ ] Club-specific metrics:
    - [ ] `organizationalMaturity` - How structured the club is (0.0 to 1.0)
    - [ ] `leadershipStability` - Stability of leadership (0.0 to 1.0)
  - [ ] Geographic expansion tracking (for Week 30):
    - [ ] `expansionLocalities` - Localities where club has expanded
    - [ ] `expansionCities` - Cities where club has expanded
    - [ ] `coveragePercentage` - Coverage percentage for each geographic level

- [ ] **Create `lib/core/models/club_hierarchy.dart`**
  - [ ] Model for club organizational structure
  - [ ] Roles enum:
    - [ ] `Leader` - Founders, primary organizers (full permissions)
    - [ ] `Admin` - Managers, moderators (high permissions)
    - [ ] `Moderator` - Event organizers, content moderators (medium permissions)
    - [ ] `Member` - Regular members (basic permissions)
  - [ ] Permissions system:
    - [ ] `canCreateEvents` - Can create events
    - [ ] `canManageMembers` - Can add/remove members
    - [ ] `canManageAdmins` - Can promote to admin
    - [ ] `canManageLeaders` - Can promote to leader
    - [ ] `canModerateContent` - Can moderate content
    - [ ] `canViewAnalytics` - Can view analytics
  - [ ] Role hierarchy:
    - [ ] Leader > Admin > Moderator > Member
    - [ ] Each role has specific permissions

#### **Day 5: CommunityService & ClubService**
- [ ] **Create `lib/core/services/community_service.dart`**
  - [ ] Auto-create community from successful events:
    - [ ] `createCommunityFromEvent()` - Create community when event is successful
    - [ ] Success criteria:
      - [ ] Event had X+ attendees
      - [ ] Event had Y+ repeat attendees
      - [ ] Event had high engagement
      - [ ] Event host wants to create community
    - [ ] Link to originating event
    - [ ] Add event host as founder
    - [ ] Add event attendees as initial members
  - [ ] Manage community members:
    - [ ] `addMember()` - Add member to community
    - [ ] `removeMember()` - Remove member from community
    - [ ] `getMembers()` - Get all members
    - [ ] `isMember()` - Check if user is member
  - [ ] Manage community events:
    - [ ] `addEvent()` - Add event to community
    - [ ] `getEvents()` - Get all events hosted by community
    - [ ] `getUpcomingEvents()` - Get upcoming events
  - [ ] Track community growth:
    - [ ] `updateGrowthMetrics()` - Update growth metrics
    - [ ] `calculateEngagementScore()` - Calculate engagement score
    - [ ] `calculateDiversityScore()` - Calculate diversity score
  - [ ] Community management:
    - [ ] `getCommunityById()` - Get community by ID
    - [ ] `getCommunitiesByFounder()` - Get communities by founder
    - [ ] `getCommunitiesByCategory()` - Get communities by category
    - [ ] `updateCommunity()` - Update community details
    - [ ] `deleteCommunity()` - Delete community (if empty)

- [ ] **Create `lib/core/services/club_service.dart`**
  - [ ] Upgrade community to club:
    - [ ] `upgradeToClub()` - Upgrade community to club when structure needed
    - [ ] Upgrade criteria:
      - [ ] Community has X+ members
      - [ ] Community has hosted Y+ events
      - [ ] Community has stable leadership
      - [ ] Community needs organizational structure
    - [ ] Create club from community
    - [ ] Preserve community history
  - [ ] Manage club leaders:
    - [ ] `addLeader()` - Add leader to club
    - [ ] `removeLeader()` - Remove leader from club
    - [ ] `getLeaders()` - Get all leaders
    - [ ] `isLeader()` - Check if user is leader
  - [ ] Manage admin team:
    - [ ] `addAdmin()` - Add admin to club
    - [ ] `removeAdmin()` - Remove admin from club
    - [ ] `getAdmins()` - Get all admins
    - [ ] `isAdmin()` - Check if user is admin
  - [ ] Manage member roles:
    - [ ] `assignRole()` - Assign role to member
    - [ ] `getMemberRole()` - Get member's role
    - [ ] `hasPermission()` - Check if member has permission
  - [ ] Club management:
    - [ ] `getClubById()` - Get club by ID
    - [ ] `getClubsByLeader()` - Get clubs by leader
    - [ ] `getClubsByCategory()` - Get clubs by category
    - [ ] `updateClub()` - Update club details
  - [ ] Integration with CommunityService:
    - [ ] Use CommunityService for member/event management
    - [ ] Add club-specific organizational features

**Deliverables:**
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

**Files to Create:**
- `lib/core/models/community.dart`
- `lib/core/models/club.dart`
- `lib/core/models/club_hierarchy.dart`
- `lib/core/services/community_service.dart`
- `lib/core/services/club_service.dart`

**Files to Modify:**
- `lib/core/services/community_event_service.dart` (integration - auto-create community from successful events)

---

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start  
**Focus:** Community/Club Pages, Expertise Coverage Visualization

**Tasks:**

#### **Day 1-3: Community/Club Pages**
- [ ] **Create `lib/presentation/pages/communities/community_page.dart`**
  - [ ] Display community information:
    - [ ] Community name and description
    - [ ] Founder information
    - [ ] Member count and list
    - [ ] Event count and upcoming events
    - [ ] Community metrics (engagement, diversity, growth)
    - [ ] Original locality and current localities
  - [ ] Community actions:
    - [ ] Join/Leave community button
    - [ ] View members
    - [ ] View events
    - [ ] Create event (if member)
  - [ ] Use AppColors/AppTheme (100% adherence)
  - [ ] Follow existing page patterns

- [ ] **Create `lib/presentation/pages/clubs/club_page.dart`**
  - [ ] Display club information:
    - [ ] Club name and description
    - [ ] Leaders and admin team
    - [ ] Member count and list (with roles)
    - [ ] Event count and upcoming events
    - [ ] Club metrics (organizational maturity, leadership stability)
    - [ ] Expertise coverage visualization (prepared for Week 30)
  - [ ] Club actions:
    - [ ] Join/Leave club button
    - [ ] View members (with roles)
    - [ ] View events
    - [ ] Create event (if has permission)
    - [ ] Manage members (if admin/leader)
    - [ ] Manage roles (if leader)
  - [ ] Organizational structure display:
    - [ ] Show hierarchy (leaders, admins, moderators, members)
    - [ ] Show permissions per role
    - [ ] Show member roles
  - [ ] Use AppColors/AppTheme (100% adherence)
  - [ ] Follow existing page patterns

#### **Day 4-5: Expertise Coverage Visualization (Prep for Week 30)**
- [ ] **Create `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`**
  - [ ] Display expertise coverage by locality:
    - [ ] List of localities where club/community has expertise
    - [ ] Visual representation (list view, prepared for map view in Week 30)
    - [ ] Color-coded by expertise level (local, city, state, national, global, universal)
    - [ ] Coverage percentage for each geographic level
  - [ ] Coverage metrics display:
    - [ ] Locality coverage (list of all localities)
    - [ ] City coverage (75% threshold indicator - prepared for Week 30)
    - [ ] State coverage (75% threshold indicator - prepared for Week 30)
    - [ ] National coverage (75% threshold indicator - prepared for Week 30)
  - [ ] Expansion tracking display (prepared for Week 30):
    - [ ] Shows how community expanded from original locality
    - [ ] Timeline of expansion (if available)
    - [ ] Events hosted in each locality
  - [ ] Use AppColors/AppTheme (100% adherence)
  - [ ] Follow existing widget patterns

- [ ] **Update `lib/presentation/pages/events/events_browse_page.dart`**
  - [ ] Add Clubs/Communities tab integration:
    - [ ] Show club/community events in Clubs/Communities tab
    - [ ] Filter by club/community
    - [ ] Show club/community information
  - [ ] Integration with CommunityService and ClubService:
    - [ ] Load communities/clubs user is part of
    - [ ] Load communities/clubs user can join
    - [ ] Display club/community events

**Deliverables:**
- ✅ CommunityPage created
- ✅ ClubPage created
- ✅ ExpertiseCoverageWidget created (prepared for Week 30)
- ✅ Clubs/Communities tab integration in EventsBrowsePage
- ✅ Zero linter errors
- ✅ 100% AppColors/AppTheme adherence
- ✅ Responsive and accessible

**Files to Create:**
- `lib/presentation/pages/communities/community_page.dart`
- `lib/presentation/pages/clubs/club_page.dart`
- `lib/presentation/widgets/clubs/expertise_coverage_widget.dart`

**Files to Modify:**
- `lib/presentation/pages/events/events_browse_page.dart` (Clubs/Communities tab integration)

---

### **Agent 3: Models & Testing**
**Status:** 🟢 Ready to Start  
**Focus:** Community/Club Models, Tests, Documentation

**Tasks:**

#### **Day 1-2: Review Models (if needed)**
- [ ] **Review Community Model** (created by Agent 1)
  - [ ] Verify model structure
  - [ ] Verify event linking
  - [ ] Verify member/event tracking
  - [ ] Verify growth metrics
  - [ ] Create additional models if needed

- [ ] **Review Club Model** (created by Agent 1)
  - [ ] Verify extends Community correctly
  - [ ] Verify organizational structure
  - [ ] Verify member roles
  - [ ] Verify expansion tracking

- [ ] **Review ClubHierarchy Model** (created by Agent 1)
  - [ ] Verify roles enum
  - [ ] Verify permissions system
  - [ ] Verify role hierarchy

#### **Day 3-5: Tests & Documentation**
- [ ] **Create `test/unit/models/community_test.dart`**
  - [ ] Test model creation
  - [ ] Test event linking
  - [ ] Test member tracking
  - [ ] Test event tracking
  - [ ] Test growth metrics
  - [ ] Test JSON serialization/deserialization

- [ ] **Create `test/unit/models/club_test.dart`**
  - [ ] Test extends Community correctly
  - [ ] Test organizational structure
  - [ ] Test member roles
  - [ ] Test permissions
  - [ ] Test JSON serialization/deserialization

- [ ] **Create `test/unit/models/club_hierarchy_test.dart`**
  - [ ] Test roles enum
  - [ ] Test permissions system
  - [ ] Test role hierarchy
  - [ ] Test permission checking

- [ ] **Create `test/unit/services/community_service_test.dart`**
  - [ ] Test auto-create community from event
  - [ ] Test member management
  - [ ] Test event management
  - [ ] Test growth tracking
  - [ ] Test community management

- [ ] **Create `test/unit/services/club_service_test.dart`**
  - [ ] Test upgrade community to club
  - [ ] Test leader management
  - [ ] Test admin management
  - [ ] Test member role management
  - [ ] Test permissions
  - [ ] Test club management

- [ ] **Create Integration Tests**
  - [ ] Test end-to-end community creation from event
  - [ ] Test community upgrade to club
  - [ ] Test organizational structure
  - [ ] Test member roles and permissions

- [ ] **Documentation**
  - [ ] Document Community model
  - [ ] Document Club model
  - [ ] Document ClubHierarchy model
  - [ ] Document CommunityService
  - [ ] Document ClubService
  - [ ] Document upgrade flow (community → club)
  - [ ] Update system documentation

**Deliverables:**
- ✅ Community model tests created
- ✅ Club model tests created
- ✅ ClubHierarchy model tests created
- ✅ CommunityService tests created
- ✅ ClubService tests created
- ✅ Integration tests created
- ✅ Documentation complete
- ✅ All tests pass
- ✅ Test coverage > 90%

**Files to Create:**
- `test/unit/models/community_test.dart`
- `test/unit/models/club_test.dart`
- `test/unit/models/club_hierarchy_test.dart`
- `test/unit/services/community_service_test.dart`
- `test/unit/services/club_service_test.dart`
- `test/integration/community_club_integration_test.dart`

**Files to Review:**
- `lib/core/models/community.dart` (created by Agent 1)
- `lib/core/models/club.dart` (created by Agent 1)
- `lib/core/models/club_hierarchy.dart` (created by Agent 1)
- `lib/core/services/community_service.dart` (created by Agent 1)
- `lib/core/services/club_service.dart` (created by Agent 1)

---

## 🎯 **Success Criteria**

### **Community Model:**
- [ ] Community model created
- [ ] Links to originating event
- [ ] Tracks members, events, growth
- [ ] Stores community metrics

### **Club Model:**
- [ ] Club model created (extends Community)
- [ ] Organizational structure (leaders, admins, hierarchy) working
- [ ] Member roles and permissions working
- [ ] Expansion tracking included (for Week 30)

### **CommunityService:**
- [ ] Auto-create community from successful events working
- [ ] Member management working
- [ ] Event management working
- [ ] Growth tracking working

### **ClubService:**
- [ ] Upgrade community to club working
- [ ] Leader management working
- [ ] Admin management working
- [ ] Member role management working
- [ ] Permissions system working

### **UI:**
- [ ] CommunityPage created
- [ ] ClubPage created
- [ ] ExpertiseCoverageWidget created (prepared for Week 30)
- [ ] Clubs/Communities tab integration complete
- [ ] 100% AppColors/AppTheme adherence

---

## 📊 **Estimated Impact**

- **New Models:** 3 models (Community, Club, ClubHierarchy)
- **New Services:** 2 services (CommunityService, ClubService)
- **New UI:** 2 pages (CommunityPage, ClubPage), 1 widget (ExpertiseCoverageWidget)
- **Modified Services:** 1 service (CommunityEventService - auto-create community)
- **Modified UI:** 1 page (EventsBrowsePage - Clubs/Communities tab)
- **New Tests:** 6+ test files
- **Documentation:** Service documentation, system documentation

---

## 🚧 **Dependencies**

- ✅ Week 28 (Phase 3, Week 1) COMPLETE - Community Events done
- ✅ CommunityEventService exists
- ✅ ExpertiseEventService exists

---

## 📝 **Notes**

- **Different from ExpertiseCommunity:** This is about communities/clubs that form from events, not expertise-based communities
- **Natural Formation:** Communities form automatically from successful events
- **Upgrade Path:** Communities upgrade to clubs when organizational structure is needed
- **Organizational Structure:** Clubs have leaders, admins, moderators, members with different permissions
- **Week 30 Prep:** Expertise coverage visualization prepared for Week 30 (75% coverage rule)

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Ready to Start

