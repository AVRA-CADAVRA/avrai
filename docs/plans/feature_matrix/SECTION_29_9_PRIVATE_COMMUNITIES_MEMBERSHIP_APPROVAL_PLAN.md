# Section 29.9: Private Communities/Clubs — Membership Approval Workflow (Execution Plan)

**Date:** 2026-01-02  
**Status:** 📋 Planning  
**Priority:** HIGH (core "doors" surface: private communities)  
**Primary Master Plan References:**
- `docs/MASTER_PLAN_APPENDIX.md` → **Section 29.9: Private Communities/Clubs**
- `docs/plans/feature_matrix/SECTION_29_6_8_CLUBS_COMMUNITIES_TRUE_COMPATIBILITY_EXECUTION_PLAN.md` (completed work)

**Cross-Phase Dependencies:**
- `docs/plans/feature_matrix/SECTION_29_6_8_CLUBS_COMMUNITIES_TRUE_COMPATIBILITY_EXECUTION_PLAN.md` (true compatibility system)
- Community/Club models and services (existing infrastructure)

---

## 🚪 Doors / Philosophy Alignment

**What doors does this open?**
- A **privacy door**: users can join private communities/clubs that maintain member privacy
- A **curated door**: group admins can select members based on compatibility and benefit to the group
- A **discovery door**: users can discover private groups via suggestions without seeing members until accepted
- A **trust door**: private groups enable more intimate, selective community spaces

**When are users ready?**
- After they've joined at least one public community (understand the value)
- When they want more curated, private experiences
- When group admins need to maintain privacy and selectivity

**Is this a good key?**
- Yes if: it preserves member privacy, enables discovery without exposure, and provides transparency to admins about benefit

**Is the AI learning with the user?**
- Yes if: membership requests, approvals, and compatibility scores are stored as signals that improve future suggestions

---

## ✅ Current State (already implemented)

**Community/Club models exist:**
- `Community` model (packages/avrai_core/lib/models/community.dart)
- `Club` model extends `Community` with organizational structure (lib/core/models/club.dart)
- `Club` has `pendingMembers` field (infrastructure exists but not fully utilized)

**True compatibility system exists:**
- `CommunityService.calculateUserCommunityTrueCompatibility()` calculates user fit
- `CommunityService.calculateUserCommunityTrueCompatibilityBreakdown()` provides detailed breakdown
- Formula: `C = 0.5·C_quantum + 0.3·C_topological + 0.2·C_weaveFit`

**Club service exists:**
- `ClubService` manages club lifecycle
- Organizational structure (leaders, admins, hierarchy)
- Member roles and permissions

**What's missing:**
- Privacy flag (`isPrivate`) on Community/Club models
- Membership request workflow (request → pending → approve/reject)
- Admin dashboard to view pending requests with compatibility scores
- Member list privacy (hide members from non-members)
- Discovery for private groups (show groups but hide members)

---

## 📋 Execution Plan

### **29.9.1** — Add Privacy Flags to Models

**Goal:** Communities and Clubs can be marked as private.

**Implementation:**
- Add `isPrivate` field to `Community` model (default: `false`)
- Add `isPrivate` field to `Club` model (default: `false`, inherits from `Community`)
- Add `privacyLevel` enum (optional future enhancement):
  ```dart
  enum CommunityPrivacyLevel {
    public,      // Anyone can see members and join directly
    discoverable, // Can be discovered, members hidden, requires approval
    hidden,       // Not discoverable, invite-only
  }
  ```
- Update database schema (if using Supabase):
  ```sql
  ALTER TABLE public.communities_v1
  ADD COLUMN is_private BOOLEAN NOT NULL DEFAULT FALSE;
  ```

**Acceptance:**
- Communities/Clubs can be created as private
- Private flag persists correctly
- Default is public (backward compatible)

**Tests:**
- Unit test: `Community` model with `isPrivate: true`
- Unit test: `Club` model inherits privacy from `Community`
- Serialization test: `isPrivate` persists in JSON

---

### **29.9.2** — Create Membership Request Model

**Goal:** Membership requests can be created, stored, and tracked.

**Implementation:**
- Create `MembershipRequest` model:
  ```dart
  class MembershipRequest {
    final String id;
    final String clubId;
    final String userId;
    final MembershipRequestStatus status; // pending, approved, rejected, cancelled
    final double? compatibilityScore; // Calculated benefit to group
    final CommunityTrueCompatibilityBreakdown? compatibilityBreakdown;
    final String? userMessage; // Optional message from user
    final String? adminNotes; // Admin-only notes
    final DateTime requestedAt;
    final DateTime? reviewedAt;
    final String? reviewedBy; // Admin ID who reviewed
    final String? rejectionReason; // If rejected
  }
  
  enum MembershipRequestStatus {
    pending,
    approved,
    rejected,
    cancelled, // User withdrew request
  }
  ```
- Create database table (if using Supabase):
  ```sql
  CREATE TABLE public.membership_requests_v1 (
    id TEXT PRIMARY KEY,
    club_id TEXT NOT NULL REFERENCES public.communities_v1(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    compatibility_score DOUBLE PRECISION,
    compatibility_breakdown JSONB,
    user_message TEXT,
    admin_notes TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(club_id, user_id)
  );
  ```

**Acceptance:**
- Membership requests can be created with status `pending`
- Requests are unique per (club, user)
- Compatibility breakdown can be stored with request

**Tests:**
- Unit test: create `MembershipRequest` with all fields
- Unit test: status transitions (pending → approved/rejected)
- Serialization test: JSON round-trip

---

### **29.9.3** — Implement Membership Request Service Methods

**Goal:** Users can request to join private clubs; requests are stored and tracked.

**Implementation:**
- Add to `ClubService`:
  ```dart
  /// Request to join a private club
  Future<MembershipRequest> requestToJoinPrivateClub({
    required String clubId,
    required String userId,
    String? userMessage,
  }) async {
    // 1. Get club
    // 2. Verify club is private
    // 3. Check if user already a member
    // 4. Check if request already exists
    // 5. Calculate compatibility score/breakdown
    // 6. Create membership request
    // 7. Add to club.pendingMembers
    // 8. Notify admins
  }
  
  /// Get pending membership requests for a club (admin-only)
  Future<List<MembershipRequest>> getPendingMembershipRequests({
    required String clubId,
    required String adminId,
  }) async {
    // 1. Verify admin has permission
    // 2. Get all pending requests for club
    // 3. Include compatibility scores/breakdowns
  }
  
  /// Approve membership request (admin-only)
  Future<MembershipRequest> approveMembershipRequest({
    required String requestId,
    required String adminId,
    String? adminNotes,
  }) async {
    // 1. Get request
    // 2. Verify admin has permission
    // 3. Update request status to approved
    // 4. Add user to club.memberIds
    // 5. Remove from club.pendingMembers
    // 6. Update club.memberCount
    // 7. Notify user
  }
  
  /// Reject membership request (admin-only)
  Future<MembershipRequest> rejectMembershipRequest({
    required String requestId,
    required String adminId,
    required String reason,
    String? adminNotes,
  }) async {
    // 1. Get request
    // 2. Verify admin has permission
    // 3. Update request status to rejected
    // 4. Remove from club.pendingMembers
    // 5. Store rejection reason
    // 6. Notify user
  }
  
  /// Cancel membership request (user can withdraw)
  Future<MembershipRequest> cancelMembershipRequest({
    required String requestId,
    required String userId,
  }) async {
    // 1. Get request
    // 2. Verify user owns request
    // 3. Update request status to cancelled
    // 4. Remove from club.pendingMembers
  }
  ```

**Acceptance:**
- Users can request to join private clubs
- Requests include compatibility scores calculated at request time
- Admins can view all pending requests with compatibility breakdowns
- Admins can approve/reject requests
- Users can cancel their own requests

**Tests:**
- Unit test: request creates pending request with compatibility score
- Unit test: admin can view pending requests
- Unit test: approve request adds user to club and removes from pending
- Unit test: reject request removes from pending and stores reason
- Unit test: user can cancel own request
- Integration test: full workflow (request → approve → user is member)

---

### **29.9.4** — Calculate Compatibility for Membership Requests

**Goal:** When users request to join, calculate their compatibility/benefit to the group for admins to review.

**Implementation:**
- Use existing `CommunityService.calculateUserCommunityTrueCompatibilityBreakdown()`:
  ```dart
  // In requestToJoinPrivateClub():
  final breakdown = await _communityService
      .calculateUserCommunityTrueCompatibilityBreakdown(
    communityId: clubId,
    userId: userId,
    memberSampleSize: 10,
  );
  
  final compatibilityScore = breakdown.combined;
  ```
- Store breakdown with request so admins can see:
  - **Quantum compatibility**: How user fits with community vibe centroid
  - **Topological compatibility**: Network position and connections
  - **Weave fit**: How user improves community stability
  - **Combined score**: Overall benefit (0.0 to 1.0)

**Acceptance:**
- Compatibility scores are calculated when request is created
- Breakdown shows all three components (quantum, topological, weave fit)
- Admins can see why user is a good fit (or not)

**Tests:**
- Unit test: request includes calculated compatibility score
- Unit test: breakdown matches `calculateUserCommunityTrueCompatibilityBreakdown()`
- Integration test: compatibility score is accurate for known user/group pairs

---

### **29.9.5** — Implement Member List Privacy

**Goal:** Private clubs hide member lists from non-members (including pending requesters).

**Implementation:**
- Update `Club` model:
  ```dart
  /// Get member IDs (respects privacy)
  List<String> getMemberIds({required String? requestingUserId}) {
    if (!isPrivate) return memberIds; // Public: show all
    if (requestingUserId == null) return []; // Not logged in: show none
    
    // Private: only show if user is member/admin/leader
    if (isMember(requestingUserId) || 
        isLeader(requestingUserId) || 
        isAdmin(requestingUserId)) {
      return memberIds;
    }
    return []; // Hide members
  }
  
  /// Get member count (always visible for discovery)
  int getMemberCount() => memberCount; // Always show count, not list
  ```
- Update `CommunityService.getRecommendedCommunitiesForUser()`:
  - Include private clubs in recommendations
  - Do not include `memberIds` in response for non-members
  - Show `memberCount` but not actual member list
- Update database RLS policies (if using Supabase):
  ```sql
  -- Members can only see other members if club is private and they're members
  CREATE POLICY community_members_v1_select_members_only
  ON public.community_members_v1
  FOR SELECT
  TO authenticated
  USING (
    -- Public communities: anyone can see members
    (SELECT is_private FROM public.communities_v1 WHERE id = community_id) = FALSE
    OR
    -- Private communities: only members can see other members
    (auth.uid() = user_id OR -- Own membership
     EXISTS (
       SELECT 1 FROM public.community_members_v1 cm
       WHERE cm.community_id = community_members_v1.community_id
       AND cm.user_id = auth.uid()
     ))
  );
  ```

**Acceptance:**
- Private clubs hide member lists from non-members
- Member count is always visible (for discovery)
- Members/admins/leaders can see full member list
- Public clubs show member lists to everyone

**Tests:**
- Unit test: `getMemberIds()` returns empty for non-members of private club
- Unit test: `getMemberIds()` returns full list for members of private club
- Unit test: member count always visible
- Integration test: discovery shows private clubs but not member lists

---

### **29.9.6** — Update Discovery to Include Private Clubs

**Goal:** Users can discover private clubs via suggestions, but members remain hidden until accepted.

**Implementation:**
- Update `CommunityService.getRecommendedCommunitiesForUser()`:
  ```dart
  Future<List<Community>> getRecommendedCommunitiesForUser({
    required String userId,
    String? category,
    int maxResults = 20,
    bool excludeJoined = true,
    bool includePrivate = true, // NEW: include private clubs
  }) async {
    final all = await _getAllCommunities();
    final candidates = all.where((c) {
      if (category != null && c.category != category) return false;
      if (excludeJoined && c.isMember(userId)) return false;
      if (!includePrivate && c.isPrivate) return false; // NEW: filter private
      return true;
    }).toList();
    
    // ... rest of scoring logic
    
    // NEW: For private clubs, remove memberIds before returning
    return scored.take(maxResults).map((s) {
      final community = s.community;
      if (community.isPrivate && !community.isMember(userId)) {
        // Hide members for non-members
        return community.copyWith(memberIds: []);
      }
      return community;
    }).toList();
  }
  ```
- Update UI to show private badge and "Request to Join" button instead of "Join":
  ```dart
  // In CommunitiesDiscoverPage:
  if (community.isPrivate && !community.isMember(currentUserId)) {
    return RequestToJoinButton(
      clubId: community.id,
      userId: currentUserId,
    );
  } else {
    return JoinButton(
      communityId: community.id,
      userId: currentUserId,
    );
  }
  ```

**Acceptance:**
- Private clubs appear in discovery with compatibility scores
- Member lists are hidden from non-members
- Member count is visible (e.g., "25 members")
- UI shows "Request to Join" instead of "Join" for private clubs

**Tests:**
- Unit test: private clubs included in recommendations
- Unit test: member lists hidden for non-members
- Widget test: "Request to Join" button appears for private clubs
- Integration test: discovery shows private clubs with hidden members

---

### **29.9.7** — Create Admin Dashboard for Pending Requests

**Goal:** Club admins can view pending membership requests with compatibility scores and approve/reject them.

**Implementation:**
- Create `PendingMembershipRequestsPage`:
  ```dart
  class PendingMembershipRequestsPage extends StatefulWidget {
    final String clubId;
    final String adminId;
    
    // Shows:
    // - List of pending requests
    // - User name (from user profile)
    // - Compatibility score (0.0-1.0)
    // - Compatibility breakdown (quantum, topological, weave fit)
    // - User message (if provided)
    // - Approve/Reject buttons
    // - Admin notes field
  }
  ```
- For each request, display:
  - **User info**: Name, profile picture (from `UnifiedUser`)
  - **Compatibility score**: Large badge showing 0.0-1.0 (e.g., "85% match")
  - **Compatibility breakdown**: Expandable section showing:
    - Quantum compatibility: X%
    - Topological compatibility: Y%
    - Weave fit: Z%
  - **Benefit explanation**: AI-generated text explaining why user is a good fit
  - **User message**: If user included a message
  - **Admin actions**: Approve, Reject (with reason field)

**Acceptance:**
- Admins can view all pending requests for their club
- Compatibility scores are clearly displayed
- Breakdown shows all three components
- Admins can approve/reject with notes
- UI is intuitive and responsive

**Tests:**
- Widget test: pending requests page displays requests correctly
- Widget test: compatibility breakdown expands/collapses
- Integration test: admin can approve request from page
- Integration test: admin can reject request with reason

---

### **29.9.8** — Add Notifications for Membership Requests

**Goal:** Users and admins are notified when requests are created, approved, or rejected.

**Implementation:**
- When user requests to join:
  - Notify all admins/leaders of the club
  - Notification: "New membership request from [User Name]"
- When admin approves request:
  - Notify user: "You've been accepted into [Club Name]!"
- When admin rejects request:
  - Notify user: "Your request to join [Club Name] was not approved. Reason: [reason]"
- Use existing notification system (if available)

**Acceptance:**
- Admins receive notifications for new requests
- Users receive notifications for approvals/rejections
- Notifications include relevant context (club name, user name, reason)

**Tests:**
- Unit test: notification sent when request created
- Unit test: notification sent when request approved
- Unit test: notification sent when request rejected
- Integration test: notifications appear in user's notification center

---

### **29.9.9** — Update Database Schema (Supabase)

**Goal:** Membership requests are persisted in database with proper RLS policies.

**Implementation:**
- Add migration:
  ```sql
  -- Add privacy flag to communities
  ALTER TABLE public.communities_v1
  ADD COLUMN IF NOT EXISTS is_private BOOLEAN NOT NULL DEFAULT FALSE;
  
  -- Create membership requests table
  CREATE TABLE IF NOT EXISTS public.membership_requests_v1 (
    id TEXT PRIMARY KEY,
    club_id TEXT NOT NULL REFERENCES public.communities_v1(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    compatibility_score DOUBLE PRECISION,
    compatibility_breakdown JSONB,
    user_message TEXT,
    admin_notes TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(club_id, user_id),
    CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'))
  );
  
  -- RLS policies
  ALTER TABLE public.membership_requests_v1 ENABLE ROW LEVEL SECURITY;
  
  -- Users can see their own requests
  CREATE POLICY membership_requests_v1_select_own
  ON public.membership_requests_v1
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
  
  -- Admins can see all requests for their clubs
  CREATE POLICY membership_requests_v1_select_admin
  ON public.membership_requests_v1
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.communities_v1 c
      WHERE c.id = membership_requests_v1.club_id
      AND (
        c.founder_user_id = auth.uid()
        OR EXISTS (
          -- Check if user is admin/leader (would need clubs table)
          SELECT 1 FROM public.community_members_v1 cm
          WHERE cm.community_id = c.id
          AND cm.user_id = auth.uid()
        )
      )
    )
  );
  
  -- Users can create their own requests
  CREATE POLICY membership_requests_v1_insert_own
  ON public.membership_requests_v1
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
  
  -- Admins can update requests (approve/reject)
  CREATE POLICY membership_requests_v1_update_admin
  ON public.membership_requests_v1
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.communities_v1 c
      WHERE c.id = membership_requests_v1.club_id
      AND (
        c.founder_user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM public.community_members_v1 cm
          WHERE cm.community_id = c.id
          AND cm.user_id = auth.uid()
        )
      )
    )
  )
  WITH CHECK (
    status IN ('approved', 'rejected') AND
    reviewed_by = auth.uid()
  );
  ```

**Acceptance:**
- Database schema supports membership requests
- RLS policies enforce proper access control
- Users can only see their own requests
- Admins can see all requests for their clubs

**Tests:**
- Integration test: membership requests persist correctly
- Integration test: RLS policies block unauthorized access
- Integration test: admin can update requests

---

## 📊 Implementation Checklist

### Phase 1: Core Models & Flags
- [ ] Add `isPrivate` to `Community` model
- [ ] Add `isPrivate` to `Club` model
- [ ] Create `MembershipRequest` model
- [ ] Create `MembershipRequestStatus` enum
- [ ] Update database schema (if using Supabase)

### Phase 2: Service Methods
- [ ] Implement `requestToJoinPrivateClub()`
- [ ] Implement `getPendingMembershipRequests()`
- [ ] Implement `approveMembershipRequest()`
- [ ] Implement `rejectMembershipRequest()`
- [ ] Implement `cancelMembershipRequest()`
- [ ] Integrate compatibility calculation into request flow

### Phase 3: Privacy & Discovery
- [ ] Implement member list privacy (`getMemberIds()` respects privacy)
- [ ] Update discovery to include private clubs
- [ ] Hide member lists from non-members in discovery
- [ ] Show "Request to Join" button for private clubs

### Phase 4: Admin Dashboard
- [ ] Create `PendingMembershipRequestsPage`
- [ ] Display compatibility scores and breakdowns
- [ ] Implement approve/reject actions
- [ ] Add admin notes functionality

### Phase 5: Notifications & Polish
- [ ] Add notifications for new requests (admins)
- [ ] Add notifications for approvals (users)
- [ ] Add notifications for rejections (users)
- [ ] Update UI to show private badges
- [ ] Add loading states and error handling

### Phase 6: Testing & Documentation
- [ ] Unit tests for all service methods
- [ ] Widget tests for UI components
- [ ] Integration tests for full workflow
- [ ] Update documentation with new features

---

## 📌 Notes / Risks

- **Privacy vs Discovery**: Balance between discoverability and privacy. Solution: Show groups but hide members until accepted.
- **Compatibility Calculation Cost**: Calculating compatibility for every request could be expensive. Solution: Cache results, use TTL, batch calculations.
- **Admin Spam**: Admins might get overwhelmed with requests. Solution: Add filtering, sorting by compatibility score, batch actions.
- **RLS Complexity**: Row-level security policies can be complex. Solution: Test thoroughly, document clearly, use policy helper functions.
- **Backward Compatibility**: Existing public communities/clubs should remain public. Solution: Default `isPrivate = false`, migration sets all existing to public.

---

## 🎯 Success Metrics

- **Adoption**: X% of new clubs are created as private
- **Request Volume**: Average Y requests per private club per month
- **Approval Rate**: Z% of requests are approved (indicates quality matching)
- **Admin Satisfaction**: Admins can review and approve requests in < 2 minutes
- **User Satisfaction**: Users receive responses within 24 hours (or set expectation)

---

## 🔗 Related Documents

- `docs/plans/feature_matrix/SECTION_29_6_8_CLUBS_COMMUNITIES_TRUE_COMPATIBILITY_EXECUTION_PLAN.md` (true compatibility system)
- `lib/core/services/community_service.dart` (community service)
- `lib/core/services/club_service.dart` (club service)
- `lib/core/models/club.dart` (club model)

---

**Next Steps:**
1. Review and approve plan
2. Create detailed implementation tickets
3. Begin Phase 1: Core Models & Flags
