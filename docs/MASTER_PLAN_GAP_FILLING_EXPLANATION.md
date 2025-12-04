# Master Plan Gap Filling - What Needs to Be Done

**Created:** November 27, 2025  
**Status:** 📋 **Explanation Document**  
**Purpose:** Explain what needs to be done to fill identified gaps before implementation

---

## 🎯 **OVERVIEW**

Four major gaps need to be filled:
1. **Service Versioning Document** - Prevent service conflicts between phases
2. **Atomic Clock Mandate** - Ensure consistent timestamp usage
3. **Migration Ordering Sequence** - Prevent database migration conflicts
4. **Phase 9/10 userId vs agentId Logic** - Handle privacy vs business requirements

---

## 1. **SERVICE VERSIONING DOCUMENT**

### **What This Solves:**
Prevents service conflicts when multiple phases modify the same services simultaneously.

### **What Needs to Be Done:**

#### **A. Define Service Locking Strategy**
- **Identify which services are "locked" during which phases**
  - Example: `PaymentService` is locked during Phase 7 (payment features) and Phase 9 (reservations)
  - Example: `BusinessService` is locked during Phase 7 (business features) and Phase 9 (reservations)
  - Example: `PersonalityProfile` is locked during Phase 7.3 (security changes)

- **Define "locked" meaning:**
  - Service API cannot change (backward compatible changes only)
  - Service interface is frozen
  - Only bug fixes allowed, no new features

- **Define "unlocked" meaning:**
  - Service can be modified
  - Breaking changes allowed
  - New features can be added

#### **B. Create Service Interface Contracts**
- **Document service interfaces (not implementations)**
  - Define public API contracts
  - Document expected inputs/outputs
  - Document error handling
  - Document side effects

- **Create service versioning system:**
  - Version 1.0: Current API
  - Version 2.0: New API (backward compatible)
  - Version 3.0: Breaking changes (requires migration)

#### **C. Define Service Deprecation Process**
- **How to deprecate services:**
  - Announce deprecation (2 phases ahead)
  - Maintain backward compatibility
  - Provide migration guide
  - Remove after 2 phases

#### **D. Define Breaking Change Protocol**
- **When breaking changes are allowed:**
  - Service is "unlocked" (not in use by other phases)
  - All dependent phases are complete
  - Migration path provided

- **When breaking changes are NOT allowed:**
  - Service is "locked" (in use by active phase)
  - Dependent phase is in progress
  - No migration path available

#### **E. Create Service Dependency Graph**
- **Map service dependencies:**
  - Which services depend on which
  - Which phases use which services
  - Dependency chains and conflicts

#### **F. Define Integration Testing Requirements**
- **When to test service integrations:**
  - After each phase that modifies services
  - Before phases that depend on services
  - Continuous integration tests

### **Deliverables:**
1. Service locking matrix (which services locked during which phases)
2. Service interface contracts document
3. Service versioning strategy
4. Service deprecation process
5. Service dependency graph
6. Integration testing requirements

---

## 2. **ATOMIC CLOCK MANDATE**

### **What This Solves:**
Ensures consistent timestamp usage across all features, preventing queue conflicts and data inconsistencies.

### **What Needs to Be Done:**

#### **A. Add Mandate to Master Plan**
- **Add to Master Plan philosophy section:**
  - "All new features requiring timestamps MUST use AtomicClockService"
  - "No direct DateTime.now() usage in new code"
  - "Existing DateTime.now() usage should be migrated gradually"

#### **B. Create Migration Plan for Existing Code**
- **Identify all DateTime.now() usage:**
  - Search codebase for DateTime.now()
  - Categorize by priority (critical vs non-critical)
  - Document each usage location

- **Create migration priority:**
  - Priority 1: Payment timestamps (critical for queue ordering)
  - Priority 2: AI2AI connection timestamps (critical for learning)
  - Priority 3: Admin operation timestamps (critical for audit)
  - Priority 4: Analytics timestamps (important for accuracy)
  - Priority 5: Other timestamps (can be migrated later)

- **Create migration process:**
  - Replace DateTime.now() with AtomicClockService.getAtomicTimestamp()
  - Update tests to use AtomicClockService
  - Verify timestamp precision
  - Test queue ordering

#### **C. Add to Code Review Checklist**
- **Mandatory checks:**
  - No DateTime.now() in new code
  - All timestamps use AtomicClockService
  - Timestamp precision documented
  - Queue ordering tested

#### **D. Document Integration Points**
- **List all systems that need Atomic Clock:**
  - Reservations (ticket queue ordering)
  - Payments (payment timestamps)
  - AI2AI (connection timestamps)
  - Live Tracker (location timestamps)
  - Admin Systems (operation timestamps)
  - Analytics (event timestamps)

- **Document integration requirements:**
  - How to integrate AtomicClockService
  - When to sync with server
  - How to handle offline mode
  - How to resolve conflicts

### **Deliverables:**
1. Master Plan mandate update
2. DateTime.now() usage inventory
3. Migration priority list
4. Migration process document
5. Code review checklist update
6. Integration points documentation

---

## 3. **MIGRATION ORDERING SEQUENCE**

### **What This Solves:**
Prevents database migration conflicts and ensures migrations run in correct order.

### **What Needs to Be Done:**

#### **A. Inventory All Database Migrations**
- **Phase 7.3 (Security) migrations:**
  - `user_agent_mappings` table creation
  - `PersonalityProfile` schema change (userId → agentId)
  - `AnonymousUser` table creation
  - Encrypted field additions
  - RLS policy updates

- **Phase 9 (Reservations) migrations:**
  - `reservations` table creation
  - `reservation_tickets` table creation
  - `cancellation_policies` table creation
  - `seating_charts` table creation
  - `reservation_user_data` table creation (for optional user data sharing)

- **Phase 8 (Model Deployment) migrations:**
  - Model-related tables (if any)
  - ML feature tables (if any)

#### **B. Map Migration Dependencies**
- **Identify dependencies:**
  - Phase 7.3 creates `user_agent_mappings` → Phase 9 must reference it
  - Phase 7.3 changes `PersonalityProfile` → Phase 9 must use agentId
  - Phase 9 creates `reservations` → Must use agentId (not userId)

- **Create dependency graph:**
  - Which migrations depend on which
  - Which migrations can run in parallel
  - Which migrations must run sequentially

#### **C. Define Migration Sequence**
- **Order migrations:**
  1. Phase 7.3: `user_agent_mappings` table (foundation)
  2. Phase 7.3: Migrate existing users to agent IDs
  3. Phase 7.3: Update `PersonalityProfile` schema
  4. Phase 9: Create `reservations` table (uses agentId)
  5. Phase 9: Create reservation-related tables
  6. Phase 8: Create model-related tables (if any)

#### **D. Create Migration Rollback Procedures**
- **For each migration:**
  - Define rollback SQL
  - Define rollback conditions
  - Define rollback testing
  - Define data preservation strategy

#### **E. Create Migration Testing Strategy**
- **Test each migration:**
  - Test on development database
  - Test on staging database
  - Test rollback procedures
  - Test data integrity after migration

#### **F. Document Migration Locking**
- **Define when migrations are "locked":**
  - Migration is running → No other migrations can run
  - Migration is in testing → No conflicting migrations can start
  - Migration is rolled back → Can be retried after fix

### **Deliverables:**
1. Migration inventory (all migrations from all phases)
2. Migration dependency graph
3. Migration sequence document
4. Migration rollback procedures
5. Migration testing strategy
6. Migration locking mechanism

---

## 4. **PHASE 9/10 userId vs agentId LOGIC (ALL EVENTS)**

### **What This Solves:**
Handles the conflict between privacy (agentId) and business/event requirements (user data like name, phone, email, birthday) across ALL event types.

### **The Core Problem:**

**Security Implementation (Phase 7.3) requires:**
- Use `agentId` for all internal SPOTS tracking (privacy)
- No personal information (name, email, phone) in AI2AI network
- Complete anonymity for AI2AI connections

**Event System (ALL Event Types) requires:**
- **Reservations (Phase 9):** Businesses may need real user data (name, phone, email, birthday)
- **Community Events:** May need user data for coordination (name, phone)
- **Club Events:** May need user data for membership verification (name, email)
- **Expert Events:** May need user data for event coordination (name, phone, email)
- **Business Events:** May need user data for business requirements (name, phone, email, birthday)
- **Company Events:** May need user data for corporate requirements (name, email, company affiliation)
- Users should have control over what data to share per event/reservation

### **The Solution: Dual Identity System (Applies to ALL Events)**

#### **A. Internal SPOTS Tracking (agentId)**
- **Use agentId for:**
  - Internal event/reservation tracking
  - SPOTS analytics
  - AI2AI network (if events shared)
  - Privacy-protected operations
  - All event types: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events

- **Never share agentId with businesses/hosts:**
  - Businesses/hosts don't need to know agentId
  - agentId stays internal to SPOTS
  - Applies to all event types

#### **B. Event Data Sharing (Optional User Data)**
- **Users can optionally share:**
  - Name (for reservations, event coordination)
  - Phone number (for confirmations, coordination)
  - Email (for confirmations, updates)
  - Birthday (for age verification, special offers)
  - Company affiliation (for company events)
  - Other event-specific data

- **User controls:**
  - Choose what data to share per reservation/event
  - Choose what data to share per business/host
  - Revoke data sharing at any time
  - See what data is shared with which businesses/hosts
  - Set default sharing preferences per event type

#### **C. Data Storage Strategy (General Pattern for ALL Events)**

**General EventUserData Model (Used by ALL Event Types):**
```dart
/// Shared user data model for ALL event types
/// Used by: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events
class EventUserData {
  final String? name;        // User-provided, optional
  final String? phoneNumber; // User-provided, optional
  final String? email;       // User-provided, optional
  final DateTime? birthday; // User-provided, optional
  final String? companyAffiliation; // For company events
  final Map<String, dynamic>? additionalData; // Event-specific fields
  
  // Privacy controls
  final bool sharedWithHost; // User consent flag (host = business/expert/community/club/company)
  final DateTime? sharedAt;      // When data was shared
  final DateTime? revokedAt;     // When data was revoked (if applicable)
  final String eventType; // Type of event (reservation, community_event, club_event, expert_event, business_event, company_event)
}
```

**Reservation Model Structure:**
```dart
class Reservation {
  // Internal SPOTS tracking (privacy-protected)
  final String agentId;  // For SPOTS internal use only
  
  // Optional user data (shared with business if user consents)
  final EventUserData? userData;  // Optional, user-controlled (uses general EventUserData)
  
  // ... other fields
}
```

**ExpertiseEvent Model Structure (Existing - Needs Update):**
```dart
class ExpertiseEvent {
  // Existing fields...
  final List<String> attendeeIds; // Should be List<String> attendeeAgentIds (for privacy)
  
  // NEW: Optional user data per attendee (shared with host if user consents)
  final Map<String, EventUserData>? attendeeUserData; // agentId → EventUserData
  
  // ... other fields
}
```

**CommunityEvent Model Structure (Existing - Needs Update):**
```dart
class CommunityEvent extends ExpertiseEvent {
  // Inherits attendeeAgentIds and attendeeUserData from ExpertiseEvent
  // Community events use same dual identity pattern
}
```

**Club Event Model Structure (If Exists - Needs Update):**
```dart
class ClubEvent {
  final String agentId; // Internal tracking
  final EventUserData? userData; // Optional user data (shared with club if user consents)
  // ... other fields
}
```

**Business Event Model Structure (If Exists - Needs Update):**
```dart
class BusinessEvent {
  final String agentId; // Internal tracking
  final EventUserData? userData; // Optional user data (shared with business if user consents)
  // ... other fields
}
```

**Company Event Model Structure (If Exists - Needs Update):**
```dart
class CompanyEvent {
  final String agentId; // Internal tracking
  final EventUserData? userData; // Optional user data (shared with company if user consents)
  // ... other fields
}
```

#### **D. Logic for When to Use agentId vs User Data (ALL Event Types)**

**Use agentId when:**
- Internal SPOTS tracking (all event types)
- Analytics and reporting (all event types)
- AI2AI network sharing (if applicable, all event types)
- Privacy-protected operations (all event types)
- SPOTS-side operations (all event types)
- Event attendee lists (internal tracking)
- Event history (internal tracking)

**Use userData when:**
- **Reservations:** Business requires it (restaurant needs name, phone)
- **Community Events:** Host needs it for coordination (name, phone, email)
- **Club Events:** Club needs it for membership verification (name, email)
- **Expert Events:** Expert needs it for event coordination (name, phone, email)
- **Business Events:** Business requires it (name, phone, email, birthday)
- **Company Events:** Company requires it (name, email, company affiliation)
- User has consented to share
- Event confirmation/communication
- Age verification (if required)
- Special offers (birthday discounts)
- Membership verification (club events)
- Corporate requirements (company events)

**Decision Flow (Applies to ALL Event Types):**
```
User registers/reserves for event (any type)
  ↓
Event/host requires data? (name, phone, email, etc.)
  ↓
YES → Show user data sharing options
  ↓
User chooses what to share
  ↓
Store: agentId (internal) + userData (optional, user-controlled)
  ↓
Share userData with host (if user consented)
  ↓
Keep agentId internal (never share with host)
```

**Applies to:**
- ✅ Reservations (Phase 9)
- ✅ Community Events (existing)
- ✅ Club Events (existing/future)
- ✅ Expert Events (existing ExpertiseEvent)
- ✅ Business Events (existing/future)
- ✅ Company Events (existing/future)

#### **E. Privacy Protection**

**Data Storage:**
- `agentId` stored in `reservations` table (internal)
- `userData` stored in `reservation_user_data` table (encrypted, user-controlled)
- `userData` only shared with business if `sharedWithBusiness = true`

**Data Access:**
- SPOTS can access `agentId` (internal tracking)
- Business can access `userData` (only if user consented)
- User can revoke `userData` sharing at any time
- User can see what data is shared with which businesses

**Data Encryption:**
- `userData` encrypted at rest
- `userData` encrypted in transit
- Business only sees decrypted data (if user consented)

#### **F. User Experience Flow (ALL Event Types)**

**Reservation/Event Registration Creation (Any Event Type):**
1. User selects spot/business/event (reservation, community event, club event, expert event, business event, company event)
2. User selects date/time (if applicable)
3. System checks if event/host requires data
4. If required: Show data sharing options
5. User chooses what to share (name, phone, email, birthday, company affiliation, etc.)
6. User confirms reservation/registration
7. System stores: `agentId` (internal) + `userData` (optional)
8. System shares `userData` with host (if consented)
9. Host receives reservation/registration with user data (if shared)

**Data Management (All Event Types):**
1. User can view all shared data in settings
2. User can revoke data sharing per reservation/event
3. User can revoke data sharing per business/host
4. User can set default sharing preferences per event type
5. User can see what data is shared with which hosts
6. User can manage data sharing for:
   - Reservations
   - Community Events
   - Club Events
   - Expert Events
   - Business Events
   - Company Events

### **What Needs to Be Done:**

#### **A. Create General EventUserData Model (Used by ALL Event Types)**
- Define optional user data fields (name, phone, email, birthday, company affiliation, etc.)
- Add privacy control fields (sharedWithHost, sharedAt, revokedAt)
- Add event type field (to track which event type this data is for)
- Add encryption support
- Make it reusable across all event types

#### **B. Update Reservation Model (Phase 9)**
- Replace `userId` with `agentId` (for internal tracking)
- Add `EventUserData?` field (for optional business data, uses general model)
- Add privacy control fields

#### **C. Update Existing Event Models (All Event Types)**
- **ExpertiseEvent:** Replace `attendeeIds` with `attendeeAgentIds`, add `Map<String, EventUserData>? attendeeUserData`
- **CommunityEvent:** Inherits from ExpertiseEvent, uses same pattern
- **ClubEvent (if exists):** Add `agentId` and `EventUserData?`
- **BusinessEvent (if exists):** Add `agentId` and `EventUserData?`
- **CompanyEvent (if exists):** Add `agentId` and `EventUserData?`

#### **D. Create Data Sharing UI (Reusable for ALL Event Types)**
- Event/host data requirements display
- User data sharing options
- Privacy controls
- Data sharing consent flow
- Works for: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events

#### **E. Create Data Sharing Service (Reusable for ALL Event Types)**
- Handle user data sharing logic (all event types)
- Encrypt user data
- Manage data sharing consent (all event types)
- Handle data revocation (all event types)
- Support all event types: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events

#### **F. Update Event/Host Integration (All Event Types)**
- Host receives user data (if shared) - applies to businesses, experts, communities, clubs, companies
- Host cannot access agentId (applies to all host types)
- Host data requirements configuration (applies to all host types)

#### **G. Update Privacy Documentation**
- Document dual identity system (all event types)
- Document data sharing controls (all event types)
- Document user privacy rights (all event types)
- Document which event types require which data

### **Deliverables:**
1. General EventUserData model (reusable across all event types)
2. Updated Reservation model (agentId + optional EventUserData)
3. Updated ExpertiseEvent model (attendeeAgentIds + optional attendeeUserData)
4. Updated CommunityEvent model (inherits from ExpertiseEvent)
5. Updated ClubEvent model (if exists)
6. Updated BusinessEvent model (if exists)
7. Updated CompanyEvent model (if exists)
8. Data sharing UI components (reusable for all event types)
9. Data sharing service (reusable for all event types)
10. Event/host integration updates (all event types)
11. Privacy documentation (all event types)

---

## 📊 **IMPLEMENTATION PRIORITY**

### **Critical (Must Do Before Phase 9 Starts):**
1. ✅ **Service Versioning Document** - Prevents service conflicts
2. ✅ **Migration Ordering Sequence** - Prevents database conflicts
3. ✅ **Phase 9/10 userId vs agentId Logic** - Prevents data model conflicts

### **High Priority (Should Do Soon):**
4. ✅ **Atomic Clock Mandate** - Prevents timestamp conflicts

---

## 🎯 **NEXT STEPS**

1. **Create Service Versioning Document** (prevents service conflicts)
2. **Create Migration Ordering Sequence** (prevents database conflicts)
3. **Update Phase 9 Plan** (agentId + optional userData)
4. **Update Phase 10 Plan** (agentId + optional userData)
5. **Add Atomic Clock Mandate to Master Plan** (prevents timestamp conflicts)

---

**Report Generated:** November 27, 2025  
**Status:** 📋 **Ready for Implementation**

**Key Insight:** The userId vs agentId logic requires a **dual identity system** - agentId for internal privacy, optional userData for business requirements, with user control over data sharing.

