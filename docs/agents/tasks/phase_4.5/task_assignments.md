# Phase 4.5 Task Assignments - Partnership Profile Visibility & Expertise Boost

**Date:** November 23, 2025, 4:30 PM CST  
**Purpose:** Detailed task assignments for Phase 4.5 (Week 15)  
**Status:** 🎯 **READY TO START**

---

## 🚨 **CRITICAL: Protocol Compliance**

**Before starting Phase 4.5 work, you MUST:**

1. ✅ **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **MANDATORY**
2. ✅ **Read:** `docs/agents/guides/PHASE_3_PREPARATION.md` - Setup guide (applies to Phase 4.5)
3. ✅ **Read:** `docs/agents/START_HERE_PHASE_3.md` - Quick checklist (applies to Phase 4.5)
4. ✅ **Read:** `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md` - Detailed plan

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)
- ✅ **Protocols:** Use `docs/agents/protocols/` files (shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_4.5/` (organized by agent, then phase)

**All paths in this document follow the protocol. Use them exactly as written.**

---

## 🚨 **CRITICAL: Task Assignment = In-Progress (LOCKED)**

### **⚠️ MANDATORY RULE: This Document Means Tasks Are Assigned**

**This task assignments document EXISTS, which means:**

1. **Tasks are ASSIGNED to agents**
2. **Phase 4.5 is IN PROGRESS** (not "ready to start")
3. **Master Plan has been updated** to show "🟡 IN PROGRESS - Tasks assigned to agents"
4. **Status Tracker has been updated** with agent assignments

### **⚠️ In-Progress Tasks Are LOCKED and NOT EDITABLE**

**When tasks are assigned (this document exists):**

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
**Philosophy:** Partnerships open doors to collaboration and expertise recognition - "Doors, not badges"

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

## 📋 **Agent Assignments**

### **Agent 1: Backend & Integration**
**Focus:** Partnership Profile Service, Expertise Calculation Service Integration

### **Agent 2: Frontend & UX**
**Focus:** Partnership Display Widget, Profile Page Integration, Partnerships Detail Page, Expertise Boost UI

### **Agent 3: Models & Testing**
**Focus:** UserPartnership Model, PartnershipExpertiseBoost Model, Integration Tests

---

## 📅 **Week 15: Partnership Profile Visibility + Expertise Boost**

### **Agent 1: Backend & Integration**
**Status:** 🟢 Ready to Start  
**Focus:** Partnership Profile Service, Expertise Calculation Integration

**Tasks:**
- [ ] **Partnership Profile Service (Day 1-2)**
  - [ ] Create `lib/core/services/partnership_profile_service.dart`
    - [ ] `getUserPartnerships(String userId)` - Get all partnerships for user
    - [ ] `getActivePartnerships(String userId)` - Get active partnerships only
    - [ ] `getCompletedPartnerships(String userId)` - Get completed partnerships
    - [ ] `getPartnershipsByType(String userId, ProfilePartnershipType type)` - Filter by type
    - [ ] `getPartnershipExpertiseBoost(String userId, String category)` - Calculate expertise boost
    - [ ] Integration with PartnershipService (read-only)
    - [ ] Integration with SponsorshipService (read-only)
    - [ ] Integration with BusinessService (read-only)
    - [ ] Privacy/visibility controls support
  - [ ] Create enum `ProfilePartnershipType` (business, brand, company)
  - [ ] Create class `UserPartnership` (model) - See plan for structure
  - [ ] Create class `PartnershipExpertiseBoost` (result model)
  - [ ] Test edge cases and error handling

- [ ] **Expertise Calculation Integration (Day 3-4)**
  - [ ] Update `lib/core/services/expertise_calculation_service.dart`
    - [ ] Add `calculatePartnershipBoost()` method
    - [ ] Integrate partnership boost into `calculateExpertise()` method
    - [ ] Add partnership boost to Community Path calculation (60% of boost)
    - [ ] Add partnership boost to Professional Path calculation (30% of boost)
    - [ ] Add partnership boost to Influence Path calculation (10% of boost)
    - [ ] Add partnership boost to total score calculation
  - [ ] Implement partnership boost calculation formula:
    - [ ] Status boost (active: +0.05, completed: +0.10, ongoing: +0.08)
    - [ ] Quality boost (vibe compatibility, revenue success, feedback)
    - [ ] Category alignment (same: 100%, related: 50%, unrelated: 25%)
    - [ ] Count multiplier (3-5: 1.2x, 6+: 1.5x)
    - [ ] Cap at 0.50 (50% max boost)
  - [ ] Integration with PartnershipProfileService
  - [ ] Test expertise calculation with partnership boost

- [ ] **Service Tests (Day 5)**
  - [ ] Create `test/unit/services/partnership_profile_service_test.dart`
  - [ ] Create `test/unit/services/expertise_calculation_partnership_boost_test.dart`
  - [ ] Test all service methods
  - [ ] Test expertise boost calculation accuracy
  - [ ] Test edge cases and error handling

**Deliverables:**
- `lib/core/services/partnership_profile_service.dart`
- `lib/core/models/user_partnership.dart`
- `lib/core/models/partnership_expertise_boost.dart`
- Updated `lib/core/services/expertise_calculation_service.dart`
- Test files for all services
- Service documentation

**Acceptance Criteria:**
- ✅ All services follow existing patterns
- ✅ Zero linter errors
- ✅ Partnership boost calculation accurate
- ✅ All edge cases handled
- ✅ Error handling comprehensive
- ✅ Test coverage > 90% for services

---

### **Agent 2: Frontend & UX**
**Status:** 🟢 Ready to Start  
**Focus:** Partnership Display Widget, Profile Page Integration, Partnerships Page, Expertise Boost UI

**Tasks:**
- [ ] **Partnership Display Widget (Day 1-2)**
  - [ ] Create `lib/presentation/widgets/profile/partnership_display_widget.dart`
    - [ ] Display list of partnerships (active + completed)
    - [ ] Show partnership cards with partner logo/name
    - [ ] Filter by partnership type (business, brand, company)
    - [ ] Toggle visibility controls
    - [ ] Link to partnership details
  - [ ] Create `lib/presentation/widgets/profile/partnership_card.dart`
    - [ ] Individual partnership card component
    - [ ] Partner logo/name display
    - [ ] Partnership type badge
    - [ ] Status indicator (active/completed)
    - [ ] Event count display
    - [ ] View details link
  - [ ] Create `lib/presentation/widgets/profile/partnership_visibility_toggle.dart`
    - [ ] Privacy controls widget
    - [ ] Show/hide toggle per partnership
    - [ ] Bulk visibility settings

- [ ] **Profile Page Integration (Day 2-3)**
  - [ ] Update `lib/presentation/pages/profile/profile_page.dart`
    - [ ] Add partnerships section below user info card
    - [ ] Show active partnerships prominently (3 max preview)
    - [ ] Show expertise boost indicator (if partnerships contribute)
    - [ ] Add "View All Partnerships" link
    - [ ] Integrate PartnershipDisplayWidget
  - [ ] Ensure design token compliance
  - [ ] Responsive design verified

- [ ] **Partnerships Detail Page (Day 3-4)**
  - [ ] Create `lib/presentation/pages/profile/partnerships_page.dart`
    - [ ] Full list of all partnerships
    - [ ] Filter by type (Business, Brand, Company)
    - [ ] Filter by status (Active, Completed, All)
    - [ ] Partnership detail cards
    - [ ] Expertise boost breakdown
    - [ ] Visibility/privacy controls
  - [ ] Add route to `lib/presentation/routes/app_router.dart`
  - [ ] Navigation from profile page

- [ ] **Expertise Boost UI (Day 4-5)**
  - [ ] Create `lib/presentation/widgets/expertise/partnership_expertise_boost_widget.dart`
    - [ ] Show partnership contribution to expertise
    - [ ] Visual indicator (e.g., "+X% from partnerships")
    - [ ] Breakdown of partnership boost by category
    - [ ] Link to partnerships page
  - [ ] Update `lib/presentation/pages/expertise/expertise_dashboard_page.dart`
    - [ ] Add partnership boost section
    - [ ] Show how partnerships contribute to expertise
    - [ ] Partnership breakdown by category
    - [ ] Partnership quality metrics
  - [ ] Update `lib/presentation/widgets/expertise/expertise_display_widget.dart`
    - [ ] Show partnership boost indicator
    - [ ] Visual representation of partnership contribution

**Deliverables:**
- `lib/presentation/widgets/profile/partnership_display_widget.dart`
- `lib/presentation/widgets/profile/partnership_card.dart`
- `lib/presentation/widgets/profile/partnership_visibility_toggle.dart`
- `lib/presentation/pages/profile/partnerships_page.dart`
- `lib/presentation/widgets/expertise/partnership_expertise_boost_widget.dart`
- Updated `lib/presentation/pages/profile/profile_page.dart`
- Updated `lib/presentation/pages/expertise/expertise_dashboard_page.dart`
- Updated `lib/presentation/widgets/expertise/expertise_display_widget.dart`
- Updated `lib/presentation/routes/app_router.dart`
- Widget tests
- UI documentation

**Acceptance Criteria:**
- ✅ All UI pages functional
- ✅ 100% design token adherence
- ✅ Zero linter errors
- ✅ Responsive design verified
- ✅ Error/loading/empty states handled
- ✅ Navigation flows complete

---

ok, can that plan be added to th 

---

## 📚 **References**

- **Master Plan:** `docs/MASTER_PLAN.md` - Phase 4.5 requirements
- **Partnership Profile Plan:** `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md` - Detailed plan
- **Status Tracker:** `docs/agents/status/status_tracker.md` - Current status
- **Quick Reference:** `docs/agents/reference/quick_reference.md` - Code patterns
- **Event Partnership Plan:** `docs/plans/event_partnership/EVENT_PARTNERSHIP_MONETIZATION_PLAN.md`
- **Brand Sponsorship Plan:** `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md`
- **Expertise System:** `docs/plans/dynamic_expertise/DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md`

---

**Last Updated:** November 23, 2025, 4:30 PM CST  
**Status:** 🎯 **READY TO START**

