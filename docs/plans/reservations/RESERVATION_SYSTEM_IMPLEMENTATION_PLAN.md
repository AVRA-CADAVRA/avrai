# Reservation System Implementation Plan

**Date:** November 27, 2025, 12:19 PM CST  
**Last Updated:** November 27, 2025 (Gap fixes integrated)  
**Status:** 📋 **COMPREHENSIVE PLAN WITH GAP FIXES - AWAITING APPROVAL**  
**Purpose:** Complete implementation plan for reservation system allowing users to make reservations to any and all places in SPOTS

**Gap Analysis:** All 18 identified gaps have been integrated into the plan. See gap fixes marked throughout phases.

**CRITICAL UPDATE (November 27, 2025):** This plan now uses **agentId** (not userId) for all internal tracking, with optional **EventUserData** for business/host requirements. This dual identity system applies to ALL event types: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events.

---

## 🔐 **DUAL IDENTITY SYSTEM (agentId + Optional User Data)**

### **Overview**

**Security Implementation (Phase 7.3) requires:**
- Use `agentId` for all internal SPOTS tracking (privacy-protected)
- No personal information in AI2AI network
- Complete anonymity for AI2AI connections

**Event System (ALL Event Types) requires:**
- Businesses/hosts may need real user data (name, phone, email, birthday) for reservations/events
- Users should have control over what data to share per reservation/event

### **The Solution: Dual Identity Pattern**

**Internal SPOTS Tracking (agentId):**
- Use `agentId` for all internal tracking (privacy-protected)
- Never share `agentId` with businesses/hosts
- Applies to: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events

**Optional User Data Sharing (EventUserData):**
- Users can optionally share: name, phone, email, birthday, company affiliation
- User controls what to share per reservation/event
- Data encrypted and only shared if user consents
- Applies to: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events

### **User Flow:**

```
User registers/reserves for event (any type)
  ↓
Event/host requires data? (name, phone, email, etc.)
  ↓
YES → Show user data sharing options
  ↓
User chooses what to share
  ↓
Store: agentId (internal) + EventUserData (optional, user-controlled)
  ↓
Share EventUserData with host (if user consented)
  ↓
Keep agentId internal (never share with host)
```

### **Applies To:**
- ✅ **Reservations** (Phase 9)
- ✅ **Community Events** (existing system - needs update)
- ✅ **Club Events** (existing/future - needs update)
- ✅ **Expert Events** (existing ExpertiseEvent - needs update)
- ✅ **Business Events** (existing/future - needs update)
- ✅ **Company Events** (existing/future - needs update)

**Reference:** `docs/MASTER_PLAN_GAP_FILLING_EXPLANATION.md` for complete explanation

---

## 🎯 Executive Summary

**Goal:** Enable users to make reservations to any spot, business, or event in SPOTS - opening doors to experiences through seamless booking.

**Philosophy Alignment:** 
- **"Doors, not badges"** - Reservations are doors to experiences at spots
- **"The key opens doors"** - Reservation system is a key that opens doors to places
- **"Spots → Community → Life"** - Reservations help users access their spots and communities

**Scope:**
- Reservations for any Spot (restaurants, bars, venues, etc.)
- Reservations for Business Accounts (verified businesses)
- Reservations for Events (expertise events)
- **Offline-first ticket system** - Internal ticket queue for limited seats (offline users can still get tickets)
- **Free by default** - Reservations are free unless business/expert requires a fee
- **SPOTS fee** - 10% of ticket fee (if paid reservation)
- **Cancellation policies** - Businesses can set own policies, baseline 24-hour policy available
- **Dispute system** - For extenuating circumstances (injury, illness, death)
- **No-show handling** - Fee required, possible expertise rating impact
- **Reservation limits** - Unlimited different reservations, one per event/spot (multiple tickets per reservation)
- **Optional deposits** - Businesses can require deposits (SPOTS takes 10% of deposit)
- **Seating charts** - Optional feature for businesses (concerts, galas, etc.)

**Timeline:** 12-15 weeks (phased approach, updated due to gap fixes)  
**Priority:** P1 - High Value Feature  
**Gap Fixes:** All 18 gaps integrated into plan phases

---

## 🔧 Gap Fixes Integrated

**All 18 identified gaps have been integrated into the plan. Summary:**

### **Critical Gaps (5) - Integrated:**
1. ✅ **Waitlist Functionality** - Phase 1.9 (Waitlist Service), Phase 2.1 (Waitlist UI)
2. ✅ **Rate Limiting & Abuse Prevention** - Phase 1.8 (Rate Limiting Service), Phase 2.1 (Rate Limit UI)
3. ✅ **Business Hours Integration** - Phase 1.4 (Availability Service), Phase 2.1 (Business Hours UI)
4. ✅ **Real-Time Capacity Updates** - Phase 1.4 (Atomic Capacity Updates)
5. ✅ **Notification Service Integration** - Phase 1.10 (Notification Infrastructure Clarified)

### **High Priority Gaps (8) - Integrated:**
6. ✅ **Modification Limits** - Phase 1.2 (Reservation Service), Phase 2.2 (Modification UI)
7. ✅ **Large Group Reservations** - Phase 2.1 (Large Group UI), Phase 3.2 (Group Settings)
8. ✅ **Business Verification** - Phase 3.2 (Business Setup/Verification)
9. ✅ **Error Handling Details** - Phase 8.1 (Error Handling Tests), Phase 9.2 (Error Handling Strategy)
10. ✅ **Performance at Scale** - Phase 8.1 (Performance Tests), Phase 9.2 (Performance Optimization)
11. ✅ **Data Migration** - Phase 9.1 (Migration Guide)
12. ✅ **Analytics Integration** - Phase 7.1 (Analytics Integration Details)
13. ✅ **Backup & Recovery** - Phase 9.1 (Backup & Recovery Docs), Phase 9.2 (Backup System)

### **Medium Priority Gaps (5) - Integrated:**
14. ✅ **Accessibility Details** - Phase 9.2 (Accessibility Requirements)
15. ✅ **Internationalization** - Phase 9.2 (Internationalization - if needed)
16. ✅ **RevenueSplitService Integration** - Phase 4.1 (Service Integration Details)
17. ✅ **Holiday/Closure Handling** - Phase 1.4 (Holiday/Closure Handling), Phase 3.2 (Holiday Calendar)
18. ✅ **RefundService Integration** - Phase 4.1 (Service Integration Details)

**All gap fixes are marked with "(CRITICAL GAP FIX)", "(HIGH PRIORITY GAP FIX)", or "(MEDIUM PRIORITY GAP FIX)" throughout the plan.**

---

## 📚 Architecture References

**⚠️ MANDATORY:** This plan aligns with SPOTS architecture:

- **Online/Offline Strategy:** [`../architecture/ONLINE_OFFLINE_STRATEGY.md`](../architecture/ONLINE_OFFLINE_STRATEGY.md) - 83% offline-first
- **Architecture Index:** [`../architecture/ARCHITECTURE_INDEX.md`](../architecture/ARCHITECTURE_INDEX.md) - Central index
- **SPOTS Philosophy:** [`../philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`](../philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md) - Doors philosophy
- **Development Methodology:** [`../methodology/DEVELOPMENT_METHODOLOGY.md`](../methodology/DEVELOPMENT_METHODOLOGY.md) - Implementation approach

---

## 🚪 Philosophy: Reservations as Doors

**Every reservation is a door:**
- A door to a spot you want to visit
- A door to an experience you're ready for
- A door to a community gathering
- A door to a business you trust

**The AI learns:**
- Which spots you reserve (doors you're ready to open)
- When you make reservations (timing patterns)
- What types of reservations resonate (restaurants, events, venues)
- How reservations lead to more doors (spot → community → events)

**Not just booking - door opening:**
- Reservations aren't just transactions
- They're commitments to open doors
- They show intent to engage with spots/communities
- They're signals of readiness for experiences

---

## 📊 Current State Assessment

### **What Exists:**
- ✅ `Spot` model - Places users can reserve
- ✅ `BusinessAccount` model - Businesses that can accept reservations
- ✅ `ExpertiseEvent` model - Events that can have reservations
- ✅ `PaymentService` - Payment processing for paid reservations
- ✅ `StripeService` - Payment integration
- ✅ `BusinessService` - Business management
- ✅ `ExpertiseEventService` - Event management
- ✅ Offline-first architecture - Local storage, sync when online

### **What's Missing:**
- ❌ `Reservation` model
- ❌ `ReservationService` - Core reservation management
- ❌ **Atomic Clock Service** - Synchronized timestamps across app (CRITICAL for ticket queue)
- ❌ Reservation UI/UX (pages, widgets)
- ❌ Business reservation management UI
- ❌ Reservation notifications/reminders
- ❌ Reservation cancellation/refund flow
- ❌ Reservation history
- ❌ Integration with existing systems

---

## 🏗️ Phase 1: Foundation - Models & Core Service (Weeks 1-2)

### **1.0 Atomic Clock Service** (Week 1, Day 1) - **CRITICAL FOUNDATION - APP-WIDE**

**File:** `lib/core/services/atomic_clock_service.dart`

**Purpose:** Synchronized atomic clock across entire SPOTS app for exact timestamp recognition with nanosecond/millisecond precision - enables true first-come-first-served for offline/online ticket purchases and exact time tracking across all systems

**Precision:**
- **Target:** Nanosecond precision (if platform supports)
- **Fallback:** Millisecond precision (if nanoseconds not available)
- **Platform Support:** Check platform capabilities, use highest available precision

**Why Critical:**
- Offline users need exact purchase time to compare with online users
- First-come-first-served must be truly universal (online and offline)
- Payment processing depends on accurate timestamps
- Queue conflict resolution requires synchronized time
- **AI2AI system** needs exact connection timestamps for learning effectiveness
- **Live tracker** needs exact location/activity timestamps
- **Admin systems** need exact timestamps for all operations
- **Everything** that needs exact time tracking uses this service

**Core Methods:**
```dart
class AtomicClockService {
  // Get synchronized timestamp (atomic across app, nanosecond/millisecond precision)
  Future<AtomicTimestamp> getAtomicTimestamp();
  
  // Sync with server time (when online)
  Future<void> syncWithServer();
  
  // Get time offset (device time vs. server time)
  Duration getTimeOffset();
  
  // Check if clock is synchronized
  bool isSynchronized();
  
  // Get timestamp for ticket purchase (with atomic guarantee)
  Future<AtomicTimestamp> getTicketPurchaseTimestamp();
  
  // Get timestamp for AI2AI connection (exact connection time)
  Future<AtomicTimestamp> getAI2AIConnectionTimestamp();
  
  // Get timestamp for live tracking (exact location/activity time)
  Future<AtomicTimestamp> getLiveTrackingTimestamp();
  
  // Get timestamp for admin operations (exact operation time)
  Future<AtomicTimestamp> getAdminOperationTimestamp();
  
  // Get precision level (nanosecond or millisecond)
  TimePrecision getPrecision();
}
```

**Model:**
```dart
class AtomicTimestamp {
  final DateTime serverTime; // Server-synchronized time (nanosecond/millisecond precision)
  final DateTime deviceTime; // Device time (nanosecond/millisecond precision)
  final Duration offset; // Offset between device and server
  final String timestampId; // Unique ID for this timestamp
  final bool isSynchronized; // Whether clock is synced
  final TimePrecision precision; // nanosecond or millisecond
  final int nanoseconds; // Nanoseconds component (if available)
  final int milliseconds; // Milliseconds component (always available)
}

enum TimePrecision {
  nanosecond, // Nanosecond precision available
  millisecond, // Millisecond precision (fallback)
}
```

**Synchronization Strategy:**
- **When Online:** Sync with server time on app start and periodically (every 30 seconds)
- **When Offline:** Use device time + last known offset
- **Precision Detection:** Check platform capabilities on initialization
- **On Ticket Purchase:** Get atomic timestamp (server time if synced, device time + offset if offline)
- **On AI2AI Connection:** Get atomic timestamp for exact connection time
- **On Live Tracking:** Get atomic timestamp for exact location/activity time
- **On Admin Operations:** Get atomic timestamp for exact operation time
- **On Sync:** Recalculate offsets and resolve conflicts

**App-Wide Integration:**
- ✅ **Reservations:** `ReservationTicketQueueService` for queue ordering
- ✅ **Payments:** `PaymentService` for payment timestamps
- ✅ **AI2AI System:** `ConnectionOrchestrator`, `ConnectionMetrics`, `AI2AIChatAnalyzer` for connection timestamps
- ✅ **Live Tracker:** Location tracking, activity tracking, movement patterns
- ✅ **Admin Systems:** `AdminGodModeService`, `AdminCommunicationService` for all admin operations
- ✅ **Automatic Check-In:** `AutomaticCheckInService` for check-in timestamps
- ✅ **Visit Tracking:** Visit start/end times
- ✅ **Event Tracking:** Event creation, registration, attendance times
- ✅ **Analytics:** All analytics timestamps
- ✅ **Monitoring:** Connection monitoring, network analytics timestamps

**AI2AI System Integration:**
- Connection start/end times (exact compatibility check moments)
- Learning exchange timestamps (exact learning moments)
- Interaction event timestamps (exact interaction times)
- Connection duration calculations (precise duration tracking)

**Live Tracker Integration:**
- Location update timestamps (exact location moments)
- Activity timestamps (exact activity start/end)
- Movement pattern timestamps (exact movement moments)
- Geofence trigger timestamps (exact entry/exit times)

**Admin System Integration:**
- All admin operation timestamps (exact operation times)
- Real-time data stream timestamps (exact data moments)
- AI snapshot timestamps (exact snapshot times)
- User data update timestamps (exact update times)
- Business operation timestamps (exact business operation times)

**Deliverables:**
- ✅ `AtomicClockService` (nanosecond/millisecond precision)
- ✅ `AtomicTimestamp` model (with precision information)
- ✅ `TimePrecision` enum
- ✅ Server time synchronization (high precision)
- ✅ Offline time offset management
- ✅ Timestamp ID generation
- ✅ **AI2AI system integration**
- ✅ **Live tracker integration**
- ✅ **Admin system integration**
- ✅ **Platform precision detection**
- ✅ Service tests

**Estimated Effort:** 14-18 hours (increased due to app-wide integration, precision requirements)

---

### **1.1 Reservation Model** (Week 1, Days 2-3)

**File:** `lib/core/models/reservation.dart`

**Model Structure:**
```dart
class Reservation {
  final String id;
  final String agentId; // User making reservation (privacy-protected, internal SPOTS use only)
  final ReservationType type; // spot, business, event
  final String targetId; // Spot ID, Business ID, or Event ID
  final ReservationStatus status; // pending, confirmed, cancelled, completed, no_show
  final DateTime reservationTime; // When reservation is for
  final DateTime? arrivalTime; // Actual arrival time
  final int partySize; // Number of people (tickets)
  final int ticketCount; // Number of tickets (can be same as partySize or business limit)
  final String? specialRequests; // Dietary restrictions, accessibility needs, etc.
  
  // Optional user data (shared with business/host if user consents)
  // Applies to ALL event types: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events
  final EventUserData? userData; // Optional, user-controlled data sharing
  
  // Pricing (free by default, business can require fee)
  final double? ticketPrice; // Per-ticket price (if paid)
  final double? totalPrice; // Total price (ticketPrice * ticketCount)
  final double? depositAmount; // Optional deposit
  final double? spotsFee; // 10% of ticket fee
  final String? paymentId; // If paid reservation
  final String? depositPaymentId; // If deposit paid
  
  // Seating (optional)
  final String? seatId; // If seating chart used
  final String? seatSection; // Section/area
  final String? seatNumber; // Specific seat number
  
  // Cancellation
  final CancellationPolicy? cancellationPolicy; // Business policy or baseline
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final bool? refundIssued; // If refund was issued
  final DisputeStatus? disputeStatus; // If dispute filed
  
  // No-show tracking
  final bool isNoShow;
  final String? noShowReason; // If legitimate reason provided
  final bool expertiseImpactApplied; // If expertise rating was impacted
  
  final ReservationMetadata metadata; // Additional context
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// General EventUserData model - Used by ALL event types
/// Applies to: Reservations, Community Events, Club Events, Expert Events, Business Events, Company Events
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

**Additional Models:**
```dart
class CancellationPolicy {
  final String id;
  final String? businessId; // If business-specific, null if baseline
  final int? hoursBeforeForRefund; // e.g., 24 hours
  final bool allowsRefund; // If refunds allowed
  final double? refundPercentage; // Partial refunds
  final bool allowsDisputes; // If disputes allowed for extenuating circumstances
}

class SeatingChart {
  final String id;
  final String businessId; // Business that owns this chart
  final String name; // "Main Floor", "VIP Section", etc.
  final List<Seat> seats;
  final Map<String, double> seatPricing; // Seat ID → Price
}

class Seat {
  final String id;
  final String section;
  final String? row;
  final String? number;
  final SeatType type; // standard, vip, accessible, etc.
  final bool isAvailable;
  final double? basePrice; // Base price for this seat
}

enum SeatType {
  standard,
  vip,
  accessible,
  premium,
}
```

**Enums:**
```dart
enum ReservationType {
  spot,      // Reservation at a spot (restaurant, bar, venue)
  business,  // Reservation with a business account
  event,     // Reservation for an event
}

enum ReservationStatus {
  pending,    // Awaiting confirmation
  confirmed,  // Confirmed by business/spot
  cancelled,  // Cancelled (by user or business)
  completed,  // Reservation fulfilled
  noShow,     // User didn't show up
}
```

**Deliverables:**
- ✅ `Reservation` model with all fields (pricing, deposits, seating, cancellation)
- ✅ `ReservationType` enum
- ✅ `ReservationStatus` enum
- ✅ `CancellationPolicy` model
- ✅ `SeatingChart` model
- ✅ `Seat` model
- ✅ `SeatType` enum
- ✅ `DisputeStatus` enum
- ✅ `ReservationMetadata` class (optional fields)
- ✅ JSON serialization/deserialization
- ✅ Model tests (`reservation_test.dart`)

**Estimated Effort:** 8-10 hours (increased due to additional models)

**Note:** Reservation model includes `atomicTimestamp` field for ticket purchase time tracking

---

### **1.2 Reservation Service** (Week 1, Days 3-5)

**File:** `lib/core/services/reservation_service.dart`

**Core Methods:**
```dart
class ReservationService {
  // Create reservation (free by default, business can require fee)
  Future<Reservation> createReservation({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int partySize,
    int? ticketCount, // Can be different from partySize if business has limit
    String? specialRequests,
    double? ticketPrice, // Only if business requires fee
    double? depositAmount, // Optional deposit
    String? seatId, // If seating chart used
  });
  
  // Get user's reservations
  // CRITICAL: Uses agentId (not userId) for privacy-protected internal tracking
  Future<List<Reservation>> getUserReservations({
    String? agentId, // Uses agentId, not userId
    ReservationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get reservations for a spot/business/event
  Future<List<Reservation>> getReservationsForTarget({
    required ReservationType type,
    required String targetId,
    DateTime? date,
    ReservationStatus? status,
  });
  
  // Check if user already has reservation for this target/time (one per event/spot instance)
  // Note: User can have multiple reservations at same spot/event for different times/days
  // CRITICAL: Uses agentId (not userId)
  Future<bool> hasExistingReservation({
    required String agentId, // Uses agentId, not userId
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime, // Check for specific time
  });
  
  // Get user's reservations for a spot/event (all times)
  // CRITICAL: Uses agentId (not userId)
  Future<List<Reservation>> getUserReservationsForTarget({
    required String agentId, // Uses agentId, not userId
    required ReservationType type,
    required String targetId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Update reservation (with modification limits)
  Future<Reservation> updateReservation({
    required String reservationId,
    DateTime? reservationTime,
    int? partySize,
    int? ticketCount,
    String? specialRequests,
  });
  
  // Check if reservation can be modified (HIGH PRIORITY GAP FIX)
  Future<ModificationCheckResult> canModifyReservation({
    required String reservationId,
    required DateTime newReservationTime,
  });
  
  // Get modification count
  Future<int> getModificationCount(String reservationId);
  
  // Cancel reservation (applies cancellation policy)
  Future<Reservation> cancelReservation({
    required String reservationId,
    required String reason,
    bool applyPolicy = true, // Apply business/baseline policy
  });
  
  // File dispute for extenuating circumstances
  Future<Reservation> fileDispute({
    required String reservationId,
    required DisputeReason reason, // injury, illness, death, other
    required String description,
    List<String>? evidenceUrls, // Photos, documents
  });
  
  // Confirm reservation (for businesses)
  Future<Reservation> confirmReservation(String reservationId);
  
  // Mark as completed
  Future<Reservation> completeReservation(String reservationId);
  
  // Mark as no-show (applies fee and possible expertise impact)
  Future<Reservation> markNoShow({
    required String reservationId,
    String? reason, // If legitimate reason (injury, illness, death)
  });
  
  // Check availability
  Future<bool> checkAvailability({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int partySize,
  });
}
```

**Integration Points:**
- `PaymentService` - For paid reservations
- `BusinessService` - For business account reservations
- `ExpertiseEventService` - For event reservations
- `StorageService` - For offline storage
- `SupabaseService` - For cloud sync

**Offline-First Strategy:**
- Create reservation locally first (<50ms)
- **Internal ticket queue system** - For limited seats, queue tickets locally
- **Offline ticket allocation** - Reserve tickets in local queue even when offline
- Queue for sync when online
- Show confirmation immediately (optimistic UI)
- Sync in background when connectivity available
- **Conflict resolution** - Handle ticket conflicts when syncing (first-come-first-served)

**Modification Limits (HIGH PRIORITY GAP FIX):**
- **Max modifications:** 3 modifications per reservation
- **Time restrictions:** Can't modify within 1 hour of reservation time
- **Modification tracking:** Track modification count and history
- **Modification reasons:** Optional reason for modification

**Deliverables:**
- ✅ `ReservationService` with all core methods
- ✅ **Offline ticket queue system** (for limited seats)
- ✅ **One reservation per event/spot limit** enforcement
- ✅ **Multiple tickets per reservation** support
- ✅ **Modification limits** (max 3, time restrictions) (HIGH PRIORITY GAP FIX)
- ✅ **Modification tracking** (HIGH PRIORITY GAP FIX)
- ✅ Offline-first implementation (local storage + sync)
- ✅ Integration with PaymentService (ticket fees, deposits, SPOTS 10% fee)
- ✅ Integration with BusinessService
- ✅ Integration with ExpertiseEventService
- ✅ **Cancellation policy system** (business-specific + baseline)
- ✅ **Dispute system** for extenuating circumstances
- ✅ **No-show handling** (fee + expertise impact)
- ✅ Service tests (`reservation_service_test.dart`)

**Estimated Effort:** 24-30 hours (increased due to modification limits, ticket queue, policies, disputes)

---

### **1.3 Offline Ticket Queue Service** (Week 2, Days 1-3)

**File:** `lib/core/services/reservation_ticket_queue_service.dart`

**Purpose:** Internal ticket queue system for limited seats - allows offline users to get tickets with atomic timestamp ordering

**Core Methods:**
```dart
class ReservationTicketQueueService {
  // Queue ticket request (works offline, uses atomic timestamp)
  // CRITICAL: Uses agentId (not userId) for privacy-protected queue tracking
  Future<TicketQueueEntry> queueTicketRequest({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int ticketCount,
    required String agentId, // Uses agentId, not userId
    required AtomicTimestamp purchaseTimestamp, // From AtomicClockService
  });
  
  // Process ticket queue (when online, sorts by atomic timestamp)
  Future<List<TicketAllocation>> processTicketQueue({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
  });
  
  // Get user's position in queue (based on atomic timestamp)
  // CRITICAL: Uses agentId (not userId)
  Future<int?> getQueuePosition({
    required String agentId, // Uses agentId, not userId
    required String queueEntryId,
  });
  
  // Allocate tickets from queue (first-come-first-served by atomic timestamp)
  Future<TicketAllocation> allocateTickets({
    required String queueEntryId,
    required int availableTickets,
  });
  
  // Handle queue conflicts (when syncing, uses atomic timestamps)
  Future<void> resolveQueueConflicts({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
  });
  
  // Check if user's ticket request will be fulfilled (before payment)
  Future<QueueStatus> checkQueueStatus({
    required String queueEntryId,
  });
}
```

**Model Updates:**
```dart
class TicketQueueEntry {
  final String id;
  final String agentId; // Uses agentId, not userId (privacy-protected)
  final ReservationType type;
  final String targetId;
  final DateTime reservationTime;
  final int ticketCount;
  final AtomicTimestamp purchaseTimestamp; // CRITICAL: Atomic timestamp
  final QueueStatus status; // pending, allocated, failed
  final DateTime createdAt;
}

enum QueueStatus {
  pending,      // Waiting for queue processing
  allocated,    // Tickets allocated
  failed,        // Too late, no tickets available
  refunded,      // Refunded due to failed allocation
}
```

**Offline-First Strategy:**
- Queue ticket requests locally (<50ms)
- **Get atomic timestamp** from `AtomicClockService` for purchase time
- **Hold payment** (don't charge until queue is processed)
- Allocate tickets optimistically (show confirmation)
- Sync queue when online
- **Sort by atomic timestamp** (true first-come-first-served)
- **Resolve conflicts** using atomic timestamps (offline vs. online)
- **Handle failed allocations** (refund or cancel payment hold)

**Payment Hold Strategy:**
- **Don't charge immediately** - Create payment intent but hold it
- **Process queue** when online (sort by atomic timestamp)
- **Charge only if tickets allocated** - Release hold if failed
- **Full refund** if user loses priority (too late in queue)
- **Better: Payment hold** - Don't charge until allocation confirmed

**Deliverables:**
- ✅ `ReservationTicketQueueService`
- ✅ `TicketQueueEntry` model (with atomic timestamp)
- ✅ `TicketAllocation` model
- ✅ `QueueStatus` enum
- ✅ **Atomic timestamp integration**
- ✅ **Payment hold mechanism**
- ✅ Offline queue management
- ✅ **True first-come-first-served** (atomic timestamp-based)
- ✅ Conflict resolution (atomic timestamps)
- ✅ Failed allocation handling (refund/hold release)
- ✅ Service tests

**Estimated Effort:** 14-18 hours (increased due to atomic clock integration, payment holds)

**Deliverables:**
- ✅ `ReservationTicketQueueService`
- ✅ `TicketQueueEntry` model
- ✅ `TicketAllocation` model
- ✅ Offline queue management
- ✅ Conflict resolution
- ✅ Service tests

**Estimated Effort:** 10-12 hours

---

### **1.4 Reservation Availability Service** (Week 2, Days 3-4)

**File:** `lib/core/services/reservation_availability_service.dart`

**Purpose:** Check availability, manage capacity, handle time slots, seating charts, business hours, holidays/closures

**Core Methods:**
```dart
class ReservationAvailabilityService {
  // Check if spot/business/event is available
  Future<AvailabilityResult> checkAvailability({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int partySize,
    int? ticketCount,
  });
  
  // Get available time slots (respects business hours)
  Future<List<TimeSlot>> getAvailableTimeSlots({
    required ReservationType type,
    required String targetId,
    required DateTime date,
    int? partySize,
  });
  
  // Get capacity for date/time (atomic update)
  Future<CapacityInfo> getCapacity({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
  });
  
  // Atomically reserve capacity (prevents overbooking)
  Future<bool> reserveCapacity({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int ticketCount,
    required String reservationId, // Lock identifier
  });
  
  // Release capacity reservation (if reservation cancelled)
  Future<void> releaseCapacity({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int ticketCount,
    required String reservationId,
  });
  
  // Check business hours (CRITICAL GAP FIX)
  Future<bool> isWithinBusinessHours({
    required String businessId,
    required DateTime reservationTime,
  });
  
  // Check if business is closed (holidays/closures)
  Future<bool> isBusinessClosed({
    required String businessId,
    required DateTime reservationTime,
  });
  
  // Get seating chart (if available)
  Future<SeatingChart?> getSeatingChart({
    required String businessId,
    required DateTime reservationTime,
  });
  
  // Get available seats
  Future<List<Seat>> getAvailableSeats({
    required String seatingChartId,
    required DateTime reservationTime,
    int? ticketCount,
  });
  
  // Get seat pricing
  Future<Map<String, double>> getSeatPricing({
    required String seatingChartId,
    required List<String> seatIds,
  });
}
```

**Integration:**
- Uses `ReservationService` to check existing reservations
- Integrates with `ExpertiseEventService` for event capacity
- **Integrates with business hours model** (CRITICAL GAP FIX)
- **Integrates with holiday/closure calendar** (CRITICAL GAP FIX)
- **Atomic capacity updates** (CRITICAL GAP FIX - prevents overbooking)
- Integrates with `SeatingChart` model for seat-based reservations
- Time zone handling

**Real-Time Capacity Updates (CRITICAL GAP FIX):**
- **Atomic capacity reservation** - Lock capacity when reservation created
- **Capacity lock mechanism** - Prevent concurrent reservations from overbooking
- **Real-time synchronization** - Update capacity immediately across all devices
- **Conflict resolution** - Handle concurrent reservation attempts gracefully

**Business Hours Integration (CRITICAL GAP FIX):**
- Check business hours before allowing reservation
- Respect time zones
- Handle special hours (holidays, events)
- Block reservations outside business hours

**Holiday/Closure Handling (CRITICAL GAP FIX):**
- Check holiday calendar
- Check closure dates
- Automatic cancellation on closures (with notification)
- User notification of closures

**Deliverables:**
- ✅ `ReservationAvailabilityService`
- ✅ `AvailabilityResult` model
- ✅ `TimeSlot` model
- ✅ `CapacityInfo` model
- ✅ **Atomic capacity reservation mechanism**
- ✅ **Business hours integration**
- ✅ **Holiday/closure handling**
- ✅ Seating chart integration
- ✅ Seat availability checking
- ✅ Time zone handling
- ✅ Service tests

**Estimated Effort:** 16-20 hours (increased due to business hours, atomic capacity, holiday handling)

---

### **1.5 Cancellation Policy Service** (Week 2, Days 5)

**File:** `lib/core/services/reservation_cancellation_policy_service.dart`

**Purpose:** Manage cancellation policies (business-specific + baseline)

**Core Methods:**
```dart
class ReservationCancellationPolicyService {
  // Get cancellation policy for business/event/spot
  Future<CancellationPolicy> getCancellationPolicy({
    required ReservationType type,
    required String targetId,
  });
  
  // Set business cancellation policy
  Future<CancellationPolicy> setBusinessPolicy({
    required String businessId,
    int? hoursBeforeForRefund,
    bool allowsRefund = true,
    double? refundPercentage,
    bool allowsDisputes = true,
  });
  
  // Get baseline policy (24 hours default)
  CancellationPolicy getBaselinePolicy();
  
  // Check if cancellation qualifies for refund
  Future<bool> qualifiesForRefund({
    required Reservation reservation,
    required DateTime cancellationTime,
  });
  
  // Calculate refund amount
  Future<double> calculateRefund({
    required Reservation reservation,
    required DateTime cancellationTime,
  });
}
```

**Baseline Policy:**
- 24 hours before reservation for full refund
- Less than 24 hours = no refund (unless dispute)
- Disputes allowed for extenuating circumstances

**Deliverables:**
- ✅ `ReservationCancellationPolicyService`
- ✅ Baseline policy (24 hours)
- ✅ Business-specific policy support
- ✅ Refund calculation
- ✅ Service tests

**Estimated Effort:** 6-8 hours

---

### **1.6 Reservation Dispute Service** (Week 2, Days 5)

**File:** `lib/core/services/reservation_dispute_service.dart`

**Purpose:** Handle disputes for extenuating circumstances

**Core Methods:**
```dart
class ReservationDisputeService {
  // File dispute
  Future<ReservationDispute> fileDispute({
    required String reservationId,
    required DisputeReason reason, // injury, illness, death, other
    required String description,
    List<String>? evidenceUrls,
  });
  
  // Review dispute (admin/business)
  Future<ReservationDispute> reviewDispute({
    required String disputeId,
    required DisputeDecision decision, // approved, denied
    String? adminNotes,
  });
  
  // Process approved dispute (issue refund)
  Future<void> processApprovedDispute(String disputeId);
  
  // Get user's disputes
  // CRITICAL: Uses agentId (not userId)
  Future<List<ReservationDispute>> getUserDisputes(String agentId); // Uses agentId, not userId
}
```

**Dispute Reasons:**
- Injury
- Illness
- Death (family member)
- Other extenuating circumstances

**Deliverables:**
- ✅ `ReservationDisputeService`
- ✅ `ReservationDispute` model
- ✅ `DisputeReason` enum
- ✅ `DisputeDecision` enum
- ✅ Dispute review process
- ✅ Service tests

**Estimated Effort:** 6-8 hours

---

### **1.7 Reservation Notification Service** (Week 2, Days 5)

**File:** `lib/core/services/reservation_notification_service.dart`

**Purpose:** Send reminders, confirmations, updates

**Core Methods:**
```dart
class ReservationNotificationService {
  // Send confirmation
  Future<void> sendConfirmation(Reservation reservation);
  
  // Send reminder (24h before, 1h before)
  Future<void> sendReminder(Reservation reservation, Duration beforeTime);
  
  // Send cancellation notice
  Future<void> sendCancellationNotice(Reservation reservation);
  
  // Schedule reminders
  Future<void> scheduleReminders(Reservation reservation);
}
```

**Deliverables:**
- ✅ `ReservationNotificationService`
- ✅ Notification scheduling
- ✅ Integration with local notifications
- ✅ Service tests

**Estimated Effort:** 4-6 hours

---

## 🎨 Phase 2: User-Facing UI (Weeks 3-5)

### **2.1 Reservation Creation UI** (Week 3, Days 1-5) - **UPDATED FOR GAP FIXES**

**Pages:**
- `lib/presentation/pages/reservations/create_reservation_page.dart`
- `lib/presentation/pages/reservations/reservation_confirmation_page.dart`

**Widgets:**
- `lib/presentation/widgets/reservations/reservation_form_widget.dart`
- `lib/presentation/widgets/reservations/time_slot_picker_widget.dart`
- `lib/presentation/widgets/reservations/party_size_picker_widget.dart`
- `lib/presentation/widgets/reservations/ticket_count_picker_widget.dart` (NEW)
- `lib/presentation/widgets/reservations/seating_chart_picker_widget.dart` (NEW)
- `lib/presentation/widgets/reservations/seat_selector_widget.dart` (NEW)
- `lib/presentation/widgets/reservations/pricing_display_widget.dart` (NEW)
- `lib/presentation/widgets/reservations/special_requests_widget.dart`

**Features:**
- Select spot/business/event
- **Check business hours** (show available hours, block outside hours) (CRITICAL GAP FIX)
- **Check for closures/holidays** (warn if business closed) (CRITICAL GAP FIX)
- Choose date and time
- Select party size
- **Large group handling** (max party size, group pricing if applicable) (HIGH PRIORITY GAP FIX)
- **Select ticket count** (up to business limit or party size)
- **Select seats** (if seating chart available)
- **View pricing** (free or paid, deposits, SPOTS fee)
- **Rate limit check** (warn if approaching limit) (CRITICAL GAP FIX)
- Add special requests
- Review and confirm
- Payment flow (if paid reservation or deposit)
- **Waitlist option** (if sold out) (CRITICAL GAP FIX)

**Reservation Limits:**
- **Unlimited different reservations** - User can reserve at many different spots/events
- **One per event/spot instance** - Only one active reservation per specific event/spot at a specific time
- **Multiple times allowed** - User can have multiple reservations at same restaurant/spot for:
  - Multiple contiguous times in one night (e.g., 6pm and 8pm same day)
  - Multiple non-contiguous times in one night (e.g., 5pm and 9pm same day)
  - Multiple days in a row (e.g., Monday, Tuesday, Wednesday)
- **Multiple tickets** - Single reservation can hold multiple tickets

**Integration:**
- Spot details page → "Make Reservation" button
- Business profile → "Reserve" button
- Event details → "Reserve Spot" button
- **Check for existing reservation at same time** (prevent duplicate at same time)
- **Allow multiple reservations** for different times/days at same spot

**Deliverables:**
- ✅ Create reservation page
- ✅ Reservation form widgets
- ✅ **Business hours display** (CRITICAL GAP FIX)
- ✅ **Closure/holiday warnings** (CRITICAL GAP FIX)
- ✅ Time slot picker (respects business hours)
- ✅ Party size selector
- ✅ **Large group handling UI** (HIGH PRIORITY GAP FIX)
- ✅ **Ticket count selector** (with business limit)
- ✅ **Seating chart picker** (if available)
- ✅ **Seat selector** (if seating chart)
- ✅ **Pricing display** (free/paid, deposits, SPOTS fee)
- ✅ **Rate limit warnings** (CRITICAL GAP FIX)
- ✅ Special requests input
- ✅ **Existing reservation check**
- ✅ **Waitlist join option** (if sold out) (CRITICAL GAP FIX)
- ✅ Confirmation page
- ✅ Integration with spot/business/event pages
- ✅ Widget tests

**Estimated Effort:** 28-36 hours (increased due to gap fixes: business hours, closures, waitlist, rate limiting, large groups)

---

### **2.2 Reservation Management UI** (Week 4, Days 1-3) - **UPDATED FOR GAP FIXES**

**Pages:**
- `lib/presentation/pages/reservations/my_reservations_page.dart`
- `lib/presentation/pages/reservations/reservation_details_page.dart`
- `lib/presentation/pages/reservations/reservation_history_page.dart`
- `lib/presentation/pages/reservations/reservation_dispute_page.dart` (NEW)

**Widgets:**
- `lib/presentation/widgets/reservations/reservation_card_widget.dart`
- `lib/presentation/widgets/reservations/reservation_status_widget.dart`
- `lib/presentation/widgets/reservations/reservation_actions_widget.dart`
- `lib/presentation/widgets/reservations/cancellation_policy_widget.dart` (NEW)
- `lib/presentation/widgets/reservations/dispute_form_widget.dart` (NEW)
- `lib/presentation/widgets/reservations/refund_status_widget.dart` (NEW)

**Features:**
- View upcoming reservations
- View past reservations
- View reservation details
- **View cancellation policy** (before cancelling)
- Cancel reservation (with policy application)
- **File dispute** (for extenuating circumstances)
- **Modify reservation** (with modification limit display) (HIGH PRIORITY GAP FIX)
- **Modification count display** (HIGH PRIORITY GAP FIX)
- **Modification time restrictions** (can't modify within 1 hour) (HIGH PRIORITY GAP FIX)
- View reservation history
- **View refund status**
- **View waitlist position** (if on waitlist) (CRITICAL GAP FIX)

**Deliverables:**
- ✅ My reservations page
- ✅ Reservation details page
- ✅ Reservation history page
- ✅ **Reservation dispute page**
- ✅ Reservation card widget
- ✅ Status indicators
- ✅ Action buttons (cancel, modify, dispute)
- ✅ **Cancellation policy display**
- ✅ **Dispute form**
- ✅ **Refund status display**
- ✅ **Modification limit display** (HIGH PRIORITY GAP FIX)
- ✅ **Modification count indicator** (HIGH PRIORITY GAP FIX)
- ✅ **Waitlist position display** (CRITICAL GAP FIX)
- ✅ Widget tests

**Estimated Effort:** 20-26 hours (increased due to gap fixes: modification limits, waitlist)

---

### **2.3 Reservation Integration with Spots** (Week 4, Days 1-2)

**Integration Points:**
- Spot details page → "Make Reservation" button
- Spot list → Reservation availability indicator
- Map view → Reservation-enabled spots

**Files to Modify:**
- `lib/presentation/pages/spots/spot_details_page.dart`
- `lib/presentation/widgets/spots/spot_card_widget.dart`
- `lib/presentation/pages/maps/map_view.dart`

**Features:**
- "Make Reservation" button on spot details
- Reservation availability badge
- Quick reservation (from spot card)
- Reservation count/status on spot

**Deliverables:**
- ✅ Spot details integration
- ✅ Spot card reservation button
- ✅ Map view reservation indicators
- ✅ Quick reservation flow
- ✅ Widget tests

**Estimated Effort:** 8-10 hours

---

### **2.4 Reservation Integration with Businesses** (Week 4, Days 3-4)

**Integration Points:**
- Business profile → Reservation booking
- Business dashboard → Reservation management
- Business settings → Reservation preferences

**Files to Modify:**
- `lib/presentation/pages/business/business_profile_page.dart`
- `lib/presentation/pages/business/business_dashboard_page.dart`

**Features:**
- Business reservation booking
- Business reservation settings (hours, capacity, time slots)
- Business reservation preferences

**Deliverables:**
- ✅ Business profile integration
- ✅ Business reservation settings
- ✅ Business reservation preferences
- ✅ Widget tests

**Estimated Effort:** 8-10 hours

---

### **2.5 Reservation Integration with Events** (Week 4, Day 5)

**Integration Points:**
- Event details → Reservation option
- Event registration → Reservation flow

**Files to Modify:**
- `lib/presentation/pages/events/event_details_page.dart`
- `lib/presentation/pages/events/event_registration_page.dart`

**Features:**
- Event reservation option
- Event capacity management
- Event reservation vs. registration flow

**Deliverables:**
- ✅ Event details integration
- ✅ Event reservation flow
- ✅ Event capacity integration
- ✅ Widget tests

**Estimated Effort:** 6-8 hours

---

## 🏢 Phase 3: Business Management UI (Weeks 5-6)

### **3.1 Business Reservation Dashboard** (Week 5, Days 1-3)

**Pages:**
- `lib/presentation/pages/business/reservations/reservation_dashboard_page.dart`
- `lib/presentation/pages/business/reservations/reservation_calendar_page.dart`

**Widgets:**
- `lib/presentation/widgets/business/reservations/reservation_list_widget.dart`
- `lib/presentation/widgets/business/reservations/reservation_calendar_widget.dart`
- `lib/presentation/widgets/business/reservations/reservation_stats_widget.dart`

**Features:**
- View all reservations
- Calendar view of reservations
- Filter by status, date, time
- Reservation statistics
- Quick actions (confirm, cancel, mark no-show)

**Deliverables:**
- ✅ Business reservation dashboard
- ✅ Reservation calendar view
- ✅ Reservation list with filters
- ✅ Reservation statistics
- ✅ Quick actions
- ✅ Widget tests

**Estimated Effort:** 16-20 hours

---

### **3.2 Business Reservation Settings** (Week 5, Days 4-6) - **UPDATED FOR GAP FIXES**

**Pages:**
- `lib/presentation/pages/business/reservations/reservation_settings_page.dart`

**Widgets:**
- `lib/presentation/widgets/business/reservations/availability_settings_widget.dart`
- `lib/presentation/widgets/business/reservations/capacity_settings_widget.dart`
- `lib/presentation/widgets/business/reservations/time_slot_settings_widget.dart`
- `lib/presentation/widgets/business/reservations/pricing_settings_widget.dart`
- `lib/presentation/widgets/business/reservations/cancellation_policy_widget.dart`
- `lib/presentation/widgets/business/reservations/seating_chart_settings_widget.dart`

**Features:**
- **Business verification for reservations** (HIGH PRIORITY GAP FIX)
- **Business capability setup** (can they handle reservations?) (HIGH PRIORITY GAP FIX)
- Set business hours (CRITICAL GAP FIX)
- **Set holiday/closure dates** (CRITICAL GAP FIX)
- Set reservation availability
- Configure time slots
- Set capacity limits
- **Set max party size** (for large groups) (HIGH PRIORITY GAP FIX)
- **Set group pricing** (discounts for large groups) (HIGH PRIORITY GAP FIX)
- Set advance booking limits
- **Set ticket pricing** (free by default, can require fee)
- **Set deposit requirements** (optional)
- **Set cancellation policy** (custom or use baseline)
- **Create seating charts** (optional - for concerts, galas, etc.)
- **Set seat pricing** (different prices per seat/section)
- **Set ticket limits** (max tickets per reservation)
- **Set rate limits** (prevent abuse) (CRITICAL GAP FIX)

**Deliverables:**
- ✅ Reservation settings page
- ✅ **Business verification/setup** (HIGH PRIORITY GAP FIX)
- ✅ **Business hours configuration** (CRITICAL GAP FIX)
- ✅ **Holiday/closure calendar** (CRITICAL GAP FIX)
- ✅ Availability configuration
- ✅ Capacity settings
- ✅ Time slot configuration
- ✅ **Max party size settings** (HIGH PRIORITY GAP FIX)
- ✅ **Group pricing configuration** (HIGH PRIORITY GAP FIX)
- ✅ **Pricing settings** (free/paid, deposits)
- ✅ **Cancellation policy settings** (custom or baseline)
- ✅ **Rate limit settings** (CRITICAL GAP FIX)
- ✅ **Seating chart creation/management**
- ✅ **Seat pricing configuration**
- ✅ **Ticket limit settings**
- ✅ Booking policies
- ✅ Widget tests

**Estimated Effort:** 26-34 hours (increased due to gap fixes: business verification, hours, holidays, rate limits, large groups)

---

### **3.3 Business Reservation Notifications** (Week 6, Days 1-2)

**Features:**
- New reservation notifications
- Reservation modification notifications
- Cancellation notifications
- No-show alerts
- Daily reservation summary

**Deliverables:**
- ✅ Business notification system
- ✅ Notification preferences
- ✅ Notification history
- ✅ Widget tests

**Estimated Effort:** 6-8 hours

---

## 💳 Phase 4: Payment Integration (Week 6, Days 3-5)

### **4.1 Paid Reservations & Fees** (Week 6, Days 3-5) - **UPDATED FOR GAP FIXES**

**Pricing Model:**
- **Free by default** - Reservations are free unless business/expert requires fee
- **Business can require fee** - Set ticket price per reservation
- **SPOTS fee** - 10% of ticket fee (calculated automatically)
- **Optional deposits** - Business can require deposit (SPOTS takes 10% of deposit too)
- **Multiple tickets** - User can reserve multiple tickets (up to business limit or party size)

**Payment Hold Strategy (CRITICAL for Ticket Queue):**
- **For limited seats/tickets:** Don't charge immediately
- **Create payment intent** but hold it (Stripe payment intent with `capture_method: manual`)
- **Get atomic timestamp** for purchase time
- **Queue ticket request** with atomic timestamp
- **Process queue** when online (sort by atomic timestamp)
- **Charge only if tickets allocated** - Release hold if failed
- **Full refund** if user loses priority (too late in queue)
- **Better: Payment hold** - Don't charge until allocation confirmed

**Integration:**
- `PaymentService` - Process payment for paid reservations
- `ReservationService` - Link payment to reservation
- `ReservationTicketQueueService` - Queue ticket requests
- `AtomicClockService` - Get atomic timestamp for purchase time
- `RevenueSplitService` - Calculate SPOTS 10% fee (MEDIUM PRIORITY GAP FIX - detail integration)
- `RefundService` - Process refunds (MEDIUM PRIORITY GAP FIX - detail integration)
- Reservation confirmation → Payment confirmation (only if allocated)

**RevenueSplitService Integration (MEDIUM PRIORITY GAP FIX):**
- RevenueSplitService is designed for events/partnerships
- For reservations, create reservation-specific fee calculation OR adapt RevenueSplitService
- SPOTS fee: 10% of ticket fee (automatic)
- SPOTS deposit fee: 10% of deposit (automatic)
- Fee calculation happens in PaymentService, not RevenueSplitService (reservations are simpler)

**RefundService Integration (MEDIUM PRIORITY GAP FIX):**
- Use existing `RefundService.processRefund()` for cancellation refunds
- Integration flow: Cancellation → Policy check → RefundService → Stripe refund
- Refund status tracked in Reservation model
- Refund history accessible via RefundService

**Flow (For Limited Seats/Tickets):**
```
User creates reservation (limited seats)
    ↓
Get atomic timestamp (AtomicClockService)
    ↓
Check if business requires fee
    ├─ Free → Queue ticket request with atomic timestamp
    └─ Paid → Create payment intent (HOLD, not charged)
        ├─ Ticket price * ticket count
        ├─ Deposit (if required)
        ├─ SPOTS fee (10% of ticket fee)
        └─ SPOTS deposit fee (10% of deposit)
    ↓
Queue ticket request with atomic timestamp
    ↓
Show confirmation (optimistic UI)
    ↓
When online → Process queue (sort by atomic timestamp)
    ↓
Check if tickets available for this position
    ├─ YES → Allocate tickets, charge payment (capture intent)
    └─ NO → Release payment hold, refund if already charged, notify user
```

**Flow (For Regular Reservations - No Limited Seats):**
```
User creates reservation (no limited seats)
    ↓
Check if business requires fee
    ├─ Free → Create reservation directly
    └─ Paid → Calculate total:
        ├─ Ticket price * ticket count
        ├─ Deposit (if required)
        ├─ SPOTS fee (10% of ticket fee)
        └─ SPOTS deposit fee (10% of deposit)
    ↓
PaymentService.processPayment()
    ↓
Payment success → Reservation confirmed
Payment failure → Reservation cancelled
```

**Features:**
- Free reservations (default)
- Paid reservations (if business requires)
- Deposit payments (optional)
- SPOTS fee calculation (10% automatic)
- Multiple tickets per reservation
- Payment history

**Deliverables:**
- ✅ Payment integration
- ✅ Free/paid reservation flow
- ✅ **Payment hold mechanism** (for limited seats)
- ✅ **Atomic timestamp integration** (for queue ordering)
- ✅ **Queue-based payment processing** (charge only if allocated)
- ✅ **Payment hold release** (if allocation fails)
- ✅ SPOTS fee calculation (10%) - reservation-specific logic
- ✅ **RevenueSplitService integration details** (MEDIUM PRIORITY GAP FIX)
- ✅ **RefundService integration details** (MEDIUM PRIORITY GAP FIX)
- ✅ Deposit handling
- ✅ Multiple tickets support
- ✅ Refund handling
- ✅ Payment history
- ✅ Integration tests

**Estimated Effort:** 22-28 hours (increased due to service integration details)

---

### **4.2 Reservation Refunds & Cancellation Policies** (Week 6, Day 5)

**Cancellation Policy System:**
- **Business can set own policy** - Custom hours, refund percentage, etc.
- **Baseline policy** - 24 hours before for refund (if business doesn't set policy)
- **Automatic refund** - If cancelled within policy window
- **No refund** - If cancelled outside policy window (unless dispute)
- **Dispute refund** - For extenuating circumstances (injury, illness, death)

**Integration:**
- `RefundService` - Process refunds
- `ReservationService` - Handle cancellation
- `ReservationCancellationPolicyService` - Apply policy
- `ReservationDisputeService` - Handle disputes

**Flow:**
```
User cancels reservation
    ↓
Get cancellation policy (business or baseline)
    ↓
Check cancellation time vs. policy
    ├─ Within policy → Automatic refund
    ├─ Outside policy → No refund (unless dispute)
    └─ Dispute filed → Review process
        ├─ Approved → Refund issued
        └─ Denied → No refund
```

**Features:**
- Automatic refund (within policy)
- Policy-based refund calculation
- Dispute-based refunds
- Refund history
- Refund status tracking

**Deliverables:**
- ✅ Refund integration
- ✅ Cancellation policy application
- ✅ Automatic refunds (within policy)
- ✅ Dispute-based refunds
- ✅ Refund status tracking
- ✅ Integration tests

**Estimated Effort:** 8-10 hours

---

## 🔔 Phase 5: Notifications & Reminders (Week 7)

### **5.1 User Notifications** (Week 7, Days 1-2)

**Features:**
- Reservation confirmation
- 24-hour reminder
- 1-hour reminder
- Cancellation notices
- Modification notices

**Implementation:**
- Local notifications (offline-first)
- Push notifications (when online)
- In-app notifications

**Deliverables:**
- ✅ Notification service
- ✅ Reminder scheduling
- ✅ Notification preferences
- ✅ Widget tests

**Estimated Effort:** 8-10 hours

---

### **5.2 Business Notifications** (Week 7, Days 3-4)

**Features:**
- New reservation alerts
- Reservation modification alerts
- Cancellation alerts
- No-show alerts
- Daily summary

**Deliverables:**
- ✅ Business notification system
- ✅ Notification preferences
- ✅ Notification history
- ✅ Widget tests

**Estimated Effort:** 6-8 hours

---

## 🔍 Phase 6: Search & Discovery (Week 7, Day 5 - Week 8, Day 2)

### **6.1 Reservation-Enabled Search** (Week 7, Day 5)

**Features:**
- Filter spots by "reservation available"
- Search for reservable spots
- Show reservation availability in search results

**Integration:**
- `HybridSearchUseCase` - Add reservation filter
- Search results → Reservation availability badge

**Deliverables:**
- ✅ Search filter for reservations
- ✅ Reservation availability in results
- ✅ Quick reservation from search
- ✅ Widget tests

**Estimated Effort:** 6-8 hours

---

### **6.2 AI-Powered Reservation Suggestions** (Week 8, Days 1-2)

**Features:**
- AI suggests spots to reserve based on:
  - User preferences
  - Past reservations
  - Personality profile
  - Time patterns
  - Community activity

**Integration:**
- `LLMService` - AI suggestions
- `PersonalityLearning` - User preferences
- `AISearchSuggestionsService` - Suggestion engine

**Deliverables:**
- ✅ AI reservation suggestions
- ✅ Suggestion engine
- ✅ Integration with personality learning
- ✅ Widget tests

**Estimated Effort:** 8-10 hours

---

## 📊 Phase 7: Analytics & Insights (Week 8, Days 3-5) - **UPDATED FOR GAP FIXES**

### **7.1 User Reservation Analytics** (Week 8, Days 3-4)

**Features:**
- Reservation history
- Favorite spots (by reservation count)
- Reservation patterns (time, day, type)
- Cancellation rate
- Completion rate
- **Modification patterns** (HIGH PRIORITY GAP FIX)
- **Waitlist history** (CRITICAL GAP FIX)

**Analytics Integration (HIGH PRIORITY GAP FIX):**
- **Event tracking:** Track reservation events (create, modify, cancel, complete)
- **Metrics collection:** Reservation metrics feed into analytics system
- **Integration with existing analytics:** Connect to Firebase Analytics or custom analytics
- **Analytics dashboard updates:** Add reservation metrics to analytics dashboard

**Deliverables:**
- ✅ User analytics page
- ✅ Reservation insights
- ✅ Pattern visualization
- ✅ **Analytics event tracking** (HIGH PRIORITY GAP FIX)
- ✅ **Analytics integration** (HIGH PRIORITY GAP FIX)
- ✅ Widget tests

**Estimated Effort:** 12-16 hours (increased due to analytics integration)

---

### **7.2 Business Reservation Analytics** (Week 8, Day 5)

**Features:**
- Reservation volume
- Peak times
- No-show rate
- Cancellation rate
- Revenue from reservations
- Customer retention
- **Rate limit usage** (CRITICAL GAP FIX)
- **Waitlist metrics** (CRITICAL GAP FIX)
- **Capacity utilization** (CRITICAL GAP FIX)

**Deliverables:**
- ✅ Business analytics dashboard
- ✅ Reservation metrics
- ✅ Revenue tracking
- ✅ **Rate limit analytics** (CRITICAL GAP FIX)
- ✅ **Waitlist analytics** (CRITICAL GAP FIX)
- ✅ Widget tests

**Estimated Effort:** 10-14 hours (increased due to gap fixes)

---

## 🧪 Phase 8: Testing & Quality Assurance (Week 9) - **UPDATED FOR GAP FIXES**

### **8.1 Unit Tests** (Week 9, Days 1-2)

**Error Handling Testing (HIGH PRIORITY GAP FIX):**
- Test error handling strategy
- Test error types and codes
- Test user-friendly error messages
- Test error recovery mechanisms
- Test error logging

**Performance Testing (HIGH PRIORITY GAP FIX):**
- Test queue processing with many tickets
- Test concurrent reservation handling
- Test database query performance
- Test caching effectiveness
- Load testing (many concurrent users)

**Test Files:**
- `test/unit/models/reservation_test.dart`
- `test/unit/services/reservation_service_test.dart`
- `test/unit/services/reservation_availability_service_test.dart`
- `test/unit/services/reservation_notification_service_test.dart`
- `test/unit/services/reservation_rate_limiting_service_test.dart` (CRITICAL GAP FIX)
- `test/unit/services/reservation_waitlist_service_test.dart` (CRITICAL GAP FIX)
- `test/unit/services/atomic_clock_service_test.dart`

**Coverage Target:** 90%+

**Deliverables:**
- ✅ All model tests
- ✅ All service tests
- ✅ **Error handling tests** (HIGH PRIORITY GAP FIX)
- ✅ **Performance tests** (HIGH PRIORITY GAP FIX)
- ✅ 90%+ coverage
- ✅ Test documentation

**Estimated Effort:** 18-24 hours (increased due to gap fixes: error handling, performance, new services)

---

### **8.2 Integration Tests** (Week 9, Days 3-5) - **UPDATED FOR GAP FIXES**

**Test Files:**
- `test/integration/reservation_payment_integration_test.dart`
- `test/integration/reservation_business_integration_test.dart`
- `test/integration/reservation_event_integration_test.dart`
- `test/integration/reservation_offline_sync_test.dart`
- `test/integration/reservation_waitlist_integration_test.dart` (CRITICAL GAP FIX)
- `test/integration/reservation_rate_limiting_integration_test.dart` (CRITICAL GAP FIX)
- `test/integration/reservation_business_hours_integration_test.dart` (CRITICAL GAP FIX)
- `test/integration/reservation_capacity_atomic_test.dart` (CRITICAL GAP FIX)
- `test/integration/reservation_refund_integration_test.dart` (MEDIUM PRIORITY GAP FIX)

**Coverage:**
- Payment flow
- Business management flow
- Event integration flow
- Offline sync flow
- **Waitlist flow** (CRITICAL GAP FIX)
- **Rate limiting flow** (CRITICAL GAP FIX)
- **Business hours enforcement** (CRITICAL GAP FIX)
- **Atomic capacity updates** (CRITICAL GAP FIX)
- **Refund flow** (MEDIUM PRIORITY GAP FIX)

**Deliverables:**
- ✅ Payment integration tests
- ✅ Business integration tests
- ✅ Event integration tests
- ✅ Offline sync tests
- ✅ **Waitlist integration tests** (CRITICAL GAP FIX)
- ✅ **Rate limiting integration tests** (CRITICAL GAP FIX)
- ✅ **Business hours integration tests** (CRITICAL GAP FIX)
- ✅ **Atomic capacity tests** (CRITICAL GAP FIX)
- ✅ **Refund integration tests** (MEDIUM PRIORITY GAP FIX)
- ✅ Test documentation

**Estimated Effort:** 20-28 hours (increased due to gap fixes)

---

### **8.3 Widget Tests** (Week 9, Day 5)

**Test Files:**
- `test/widget/reservations/create_reservation_page_test.dart`
- `test/widget/reservations/my_reservations_page_test.dart`
- `test/widget/reservations/reservation_details_page_test.dart`
- `test/widget/business/reservations/reservation_dashboard_test.dart`

**Coverage Target:** 85%+

**Deliverables:**
- ✅ All page tests
- ✅ All widget tests
- ✅ 85%+ coverage
- ✅ Test documentation

**Estimated Effort:** 8-10 hours

---

## 📚 Phase 9: Documentation & Polish (Week 10) - **UPDATED FOR GAP FIXES**

### **9.1 Documentation** (Week 10, Days 1-2)

**Documents:**
- API documentation
- User guide
- Business guide
- Developer guide
- Architecture documentation
- **Error handling documentation** (HIGH PRIORITY GAP FIX)
- **Performance optimization guide** (HIGH PRIORITY GAP FIX)
- **Backup & recovery procedures** (HIGH PRIORITY GAP FIX)
- **Data migration guide** (if applicable) (HIGH PRIORITY GAP FIX)

**Deliverables:**
- ✅ Complete API documentation
- ✅ User guides
- ✅ Business guides
- ✅ Developer documentation
- ✅ Architecture docs
- ✅ **Error handling documentation** (HIGH PRIORITY GAP FIX)
- ✅ **Performance guide** (HIGH PRIORITY GAP FIX)
- ✅ **Backup & recovery docs** (HIGH PRIORITY GAP FIX)
- ✅ **Migration guide** (if needed) (HIGH PRIORITY GAP FIX)

**Estimated Effort:** 12-16 hours (increased due to gap fixes)

---

### **9.2 Final Polish** (Week 10, Days 3-5) - **UPDATED FOR GAP FIXES**

**Tasks:**
- UI/UX polish
- Performance optimization (HIGH PRIORITY GAP FIX)
- Error handling improvements (HIGH PRIORITY GAP FIX)
- **Accessibility improvements** (detailed requirements) (MEDIUM PRIORITY GAP FIX)
- **Internationalization** (if needed) (MEDIUM PRIORITY GAP FIX)
- Final testing
- Bug fixes

**Performance Optimization (HIGH PRIORITY GAP FIX):**
- Database query optimization
- Caching strategy implementation
- Queue processing optimization
- Concurrent reservation handling optimization
- Load testing and tuning

**Error Handling (HIGH PRIORITY GAP FIX):**
- Comprehensive error handling strategy
- Error types and codes
- User-friendly error messages
- Error recovery mechanisms
- Error logging and monitoring

**Accessibility (MEDIUM PRIORITY GAP FIX):**
- Screen reader support
- Keyboard navigation
- Color contrast compliance
- Accessibility testing
- WCAG compliance

**Internationalization (MEDIUM PRIORITY GAP FIX - if needed):**
- Multi-language support
- Localization
- Currency handling (if international)
- Time zone handling

**Backup & Recovery (HIGH PRIORITY GAP FIX):**
- Data backup strategy
- Recovery procedures
- Disaster recovery plan
- Data retention policies

**Deliverables:**
- ✅ Polished UI/UX
- ✅ **Optimized performance** (HIGH PRIORITY GAP FIX)
- ✅ **Comprehensive error handling** (HIGH PRIORITY GAP FIX)
- ✅ **Accessibility compliance** (detailed) (MEDIUM PRIORITY GAP FIX)
- ✅ **Internationalization** (if needed) (MEDIUM PRIORITY GAP FIX)
- ✅ **Backup & recovery system** (HIGH PRIORITY GAP FIX)
- ✅ Zero linter errors
- ✅ All tests passing

**Estimated Effort:** 20-28 hours (increased due to gap fixes: performance, error handling, accessibility, backup)

---

## 🔄 **EXISTING EVENT SYSTEM UPDATES REQUIRED**

### **Overview**

The dual identity system (agentId + optional EventUserData) applies to ALL event types, not just reservations. Existing event models must be updated to use this pattern.

### **Event Models Requiring Updates:**

#### **1. ExpertiseEvent Model** (Existing)
**File:** `lib/core/models/expertise_event.dart`

**Current:**
```dart
class ExpertiseEvent {
  final List<String> attendeeIds; // Uses userId
  // ...
}
```

**Required Update:**
```dart
class ExpertiseEvent {
  final List<String> attendeeAgentIds; // Changed from attendeeIds (uses agentId)
  final Map<String, EventUserData>? attendeeUserData; // NEW: Optional user data per attendee (agentId → EventUserData)
  // ... other fields
}
```

**Migration:**
- Update `attendeeIds` → `attendeeAgentIds`
- Add `attendeeUserData` map (optional)
- Update all services that use `attendeeIds`
- Update all UI that displays attendees

#### **2. CommunityEvent Model** (Existing)
**File:** `lib/core/models/community_event.dart`

**Current:**
- Extends `ExpertiseEvent`
- Inherits `attendeeIds` from `ExpertiseEvent`

**Required Update:**
- Inherits updated `ExpertiseEvent` with `attendeeAgentIds` and `attendeeUserData`
- No additional changes needed (inherits pattern)

#### **3. ClubEvent Model** (If Exists)
**File:** `lib/core/models/club_event.dart` (if exists)

**Required Update:**
```dart
class ClubEvent {
  final String agentId; // Internal tracking (privacy-protected)
  final EventUserData? userData; // Optional user data (shared with club if user consents)
  // ... other fields
}
```

#### **4. BusinessEvent Model** (If Exists)
**File:** `lib/core/models/business_event.dart` (if exists)

**Required Update:**
```dart
class BusinessEvent {
  final String agentId; // Internal tracking (privacy-protected)
  final EventUserData? userData; // Optional user data (shared with business if user consents)
  // ... other fields
}
```

#### **5. CompanyEvent Model** (If Exists)
**File:** `lib/core/models/company_event.dart` (if exists)

**Required Update:**
```dart
class CompanyEvent {
  final String agentId; // Internal tracking (privacy-protected)
  final EventUserData? userData; // Optional user data (shared with company if user consents)
  // ... other fields
}
```

### **Service Updates Required:**

#### **ExpertiseEventService** (Existing)
**File:** `lib/core/services/expertise_event_service.dart`

**Required Updates:**
- `registerForEvent()` - Use `agentId` (not `userId`), accept optional `EventUserData`
- `getEventsByAttendee()` - Use `agentId` (not `userId`)
- `getAttendees()` - Return `attendeeAgentIds` and optional `attendeeUserData`
- All methods that use `userId` → change to `agentId`

#### **CommunityEventService** (Existing)
**File:** `lib/core/services/community_event_service.dart`

**Required Updates:**
- Inherit updates from `ExpertiseEventService`
- Use `agentId` pattern for all attendee tracking

### **UI Updates Required:**

#### **Event Registration UI**
- Show data sharing options when registering for events
- Allow users to choose what data to share (name, phone, email, birthday, etc.)
- Works for: Community Events, Club Events, Expert Events, Business Events, Company Events

#### **Event Attendee Lists**
- Display attendees using `agentId` internally (privacy-protected)
- Display user data (if shared) to event host only
- Hide `agentId` from hosts (never share)

### **Timeline:**

**These updates should be done:**
- **Before Phase 9 starts** (if possible) - Ensures event system uses agentId
- **Or during Phase 9** - As part of reservation system integration
- **Critical:** Must complete before Phase 9 creates reservations that reference events

### **Migration Order:**

1. Update `ExpertiseEvent` model (attendeeIds → attendeeAgentIds)
2. Update `ExpertiseEventService` (use agentId)
3. Update `CommunityEvent` (inherits from ExpertiseEvent)
4. Update event registration UI (data sharing options)
5. Update event attendee display (privacy-protected)
6. Test event system with agentId
7. Phase 9 can then create reservations that reference events

---

## 📊 Implementation Summary

### **Timeline:**
- **Phase 1:** Weeks 1-2 (Foundation) - **UPDATED: Includes gap fixes**
- **Phase 2:** Weeks 3-5 (User UI) - **UPDATED: Includes gap fixes**
- **Phase 3:** Weeks 5-6 (Business UI) - **UPDATED: Includes gap fixes**
- **Phase 4:** Week 6 (Payment) - **UPDATED: Includes gap fixes**
- **Phase 5:** Week 7 (Notifications)
- **Phase 6:** Week 7-8 (Search & Discovery)
- **Phase 7:** Week 8 (Analytics) - **UPDATED: Includes gap fixes**
- **Phase 8:** Week 9 (Testing) - **UPDATED: Includes gap fixes**
- **Phase 9:** Week 10 (Documentation & Polish) - **UPDATED: Includes gap fixes**

**Total:** 10-12 weeks (updated due to gap fixes)

### **Effort Estimate:**
- **Phase 1:** 100-126 hours (increased due to gap fixes: waitlist, rate limiting, business hours, atomic capacity, notification infrastructure, modification limits)
- **Phase 2:** 64-82 hours (increased due to gap fixes: business hours UI, closures, waitlist UI, rate limiting UI, large groups, modification limits)
- **Phase 3:** 50-66 hours (increased due to gap fixes: business verification, hours, holidays, rate limits, large groups)
- **Phase 4:** 22-28 hours (increased due to service integration details)
- **Phase 5:** 14-18 hours
- **Phase 6:** 14-18 hours
- **Phase 7:** 22-30 hours (increased due to analytics integration)
- **Phase 8:** 50-64 hours (increased due to gap fixes: error handling tests, performance tests, new service tests)
- **Phase 9:** 32-44 hours (increased due to gap fixes: performance, error handling, accessibility, backup)

**Total:** 368-476 hours (9-12 weeks full-time, 12-15 weeks part-time)

---

## 🚪 Doors Opened

**For Users:**
- ✅ Reserve spots they want to visit (doors to experiences)
- ✅ Secure access to popular spots (doors that might be hard to open)
- ✅ Plan ahead for special occasions (doors to meaningful moments)
- ✅ Access events through reservations (doors to communities)
- ✅ Build reservation history (doors they've opened)

**For Businesses:**
- ✅ Manage reservations efficiently (doors to customer relationships)
- ✅ Optimize capacity (doors to revenue)
- ✅ Build customer loyalty (doors to repeat business)
- ✅ Track reservation patterns (doors to insights)

**For SPOTS:**
- ✅ New revenue stream (paid reservations)
- ✅ Increased engagement (reservations = commitment)
- ✅ Data for AI learning (reservation patterns)
- ✅ Platform value (reservations = utility)

---

## 🔗 Integration Points

### **Existing Systems:**
- **Spots:** Reservation button on spot details, availability in search
- **Businesses:** Reservation management dashboard, settings
- **Events:** Reservation option for events, capacity management
- **Payment:** Paid reservations, refunds on cancellation
- **Notifications:** Reminders, confirmations, updates
- **AI2AI System:** Atomic clock integration for connection timestamps
- **Live Tracker:** Atomic clock integration for location/activity timestamps
- **Admin Systems:** Atomic clock integration for all admin operations

### **New Systems:**
- **AtomicClockService:** App-wide synchronized time (nanosecond/millisecond precision)
  - Used by: Reservations, AI2AI, Live Tracker, Admin Systems, and everywhere exact time is needed
- **ReservationService:** Core reservation management
- **ReservationAvailabilityService:** Availability checking
- **ReservationNotificationService:** Notifications and reminders
- **ReservationTicketQueueService:** Offline ticket queue with atomic timestamps
- **ReservationCancellationPolicyService:** Cancellation policy management
- **ReservationDisputeService:** Dispute handling
- **ReservationNoShowService:** No-show handling

---

## 🔒 Privacy & Security

**Privacy:**
- Reservation data stored locally (offline-first)
- Sync to cloud with user consent
- Business can only see reservation data (not personal info)
- Admin privacy filter applies to reservation data

**Security:**
- Payment processing through Stripe (secure)
- Reservation data encrypted in transit
- Access control (users see their reservations, businesses see their reservations)
- No personal data shared without consent

---

## 📈 Success Metrics

**User Metrics:**
- Reservation creation rate
- Reservation completion rate
- Cancellation rate
- Repeat reservation rate
- Reservation-to-visit conversion

**Business Metrics:**
- Reservation volume
- No-show rate
- Revenue from reservations
- Customer retention

**Platform Metrics:**
- Total reservations
- Paid vs. free reservations
- Reservation-enabled spots
- User engagement increase

---

## 🎯 Dependencies

**Required:**
- ✅ PaymentService (for paid reservations)
- ✅ BusinessService (for business reservations)
- ✅ ExpertiseEventService (for event reservations)
- ✅ StorageService (for offline storage)
- ✅ SupabaseService (for cloud sync)

**Optional:**
- LLMService (for AI suggestions)
- PersonalityLearning (for personalized suggestions)
- NotificationService (for reminders)

---

## ⚠️ Risks & Mitigation

**Risk 1: Business Adoption**
- **Mitigation:** Make business setup easy, provide value (customer management), baseline policies available

**Risk 2: No-Show Rate**
- **Mitigation:** Reminders, cancellation policies, deposit requirements, expertise rating impact

**Risk 3: Payment Integration Complexity**
- **Mitigation:** Leverage existing PaymentService, follow established patterns, SPOTS fee calculation

**Risk 4: Offline Sync Complexity**
- **Mitigation:** Follow offline-first architecture, use existing StorageService patterns, internal ticket queue system

**Risk 5: Ticket Queue Conflicts**
- **Mitigation:** First-come-first-served based on atomic timestamp, conflict resolution on sync

**Risk 6: Cancellation Policy Complexity**
- **Mitigation:** Baseline policy (24 hours), businesses can adopt or customize, clear UI

**Risk 7: Seating Chart Complexity**
- **Mitigation:** Optional feature, simple implementation for basic use cases, can expand later

**Risk 8: Atomic Clock Synchronization**
- **Mitigation:** Sync on app start, periodic sync, use device time + offset when offline, clear conflict resolution

**Risk 9: Payment Hold Complexity**
- **Mitigation:** Use Stripe payment intents with manual capture, clear hold release logic, comprehensive testing

**Risk 10: Atomic Clock Precision Across Platforms**
- **Mitigation:** Platform-specific precision detection, fallback to milliseconds, comprehensive testing on all platforms

**Risk 11: App-Wide Integration Complexity**
- **Mitigation:** Start with core services (reservations, AI2AI, admin), gradual rollout, comprehensive integration testing

**Risk 12: Overbooking (CRITICAL GAP FIX)**
- **Mitigation:** Atomic capacity updates, capacity lock mechanism, real-time synchronization, conflict resolution

**Risk 13: Reservation Abuse (CRITICAL GAP FIX)**
- **Mitigation:** Rate limiting service, spam detection, account restrictions, business-side limits

**Risk 14: Business Hours Violations (CRITICAL GAP FIX)**
- **Mitigation:** Business hours integration, availability checking, holiday/closure handling, time zone support

**Risk 15: Waitlist Management (CRITICAL GAP FIX)**
- **Mitigation:** Atomic timestamp ordering, automatic notifications, time-limited responses, position tracking

**Risk 16: Performance at Scale (HIGH PRIORITY GAP FIX)**
- **Mitigation:** Database optimization, caching strategy, queue processing optimization, load testing

**Risk 17: Error Handling Consistency (HIGH PRIORITY GAP FIX)**
- **Mitigation:** Comprehensive error handling strategy, error types/codes, user-friendly messages, error recovery

---

## 📝 Next Steps

**Upon Approval:**
1. Create detailed task breakdown
2. Assign to agents (if using parallel work)
3. Begin Phase 1 implementation
4. Set up tracking and progress monitoring

## ✅ Requirements Summary

**All Requirements Addressed:**

1. ✅ **Offline-first ticket system** - Internal ticket queue for limited seats
2. ✅ **Atomic clock system** - Synchronized timestamps across entire app (nanosecond/millisecond precision)
   - Used in reservations, AI2AI system, live tracker, admin systems, and everywhere exact time is needed
3. ✅ **Payment hold mechanism** - Don't charge until queue processed, refund if failed
4. ✅ **Free by default** - Reservations free unless business/expert requires fee
5. ✅ **SPOTS fee** - 10% of ticket fee (automatic)
6. ✅ **Cancellation policies** - Business can set own, baseline 24-hour policy available
7. ✅ **Dispute system** - For extenuating circumstances (injury, illness, death)
8. ✅ **No-show handling** - Fee required, possible expertise rating impact
9. ✅ **Reservation limits** - One per event/spot instance, multiple for different times/days
10. ✅ **Multiple tickets** - Single reservation can hold multiple tickets
11. ✅ **Optional deposits** - Businesses can require deposits (SPOTS takes 10% of deposit)
12. ✅ **Seating charts** - Optional feature for businesses (concerts, galas, etc.)

**All Gap Fixes Addressed:**

**Critical Gaps (5):**
13. ✅ **Waitlist functionality** - Waitlist system for sold-out events/spots
14. ✅ **Rate limiting & abuse prevention** - Rate limiting service, spam detection
15. ✅ **Business hours integration** - Business hours checking, availability enforcement
16. ✅ **Real-time capacity updates** - Atomic capacity updates, prevents overbooking
17. ✅ **Notification service integration** - Local, push, in-app notification infrastructure

**High Priority Gaps (8):**
18. ✅ **Modification limits** - Max 3 modifications, time restrictions
19. ✅ **Large group reservations** - Max party size, group pricing
20. ✅ **Business verification** - Business setup/verification for reservations
21. ✅ **Error handling details** - Comprehensive error handling strategy
22. ✅ **Performance at scale** - Optimization, caching, load testing
23. ✅ **Data migration** - Migration strategy (if needed)
24. ✅ **Analytics integration** - Event tracking, metrics collection
25. ✅ **Backup & recovery** - Backup strategy, recovery procedures

**Medium Priority Gaps (5):**
26. ✅ **Accessibility details** - Screen reader, keyboard navigation, WCAG compliance
27. ✅ **Internationalization** - Multi-language, localization (if needed)
28. ✅ **RevenueSplitService integration** - Integration details for fee calculation
29. ✅ **Holiday/closure handling** - Holiday calendar, closure dates, automatic cancellation
30. ✅ **RefundService integration** - Integration details for refund processing

**All questions answered in plan implementation.**

---

## ✅ Approval Checklist

**Before Implementation:**
- [ ] Plan reviewed and approved
- [ ] Timeline acceptable
- [ ] Resource allocation confirmed
- [ ] Dependencies verified
- [ ] Questions answered
- [ ] Integration points confirmed
- [ ] Success metrics agreed upon

---

**Status:** 📋 **AWAITING APPROVAL**  
**Created:** November 27, 2025, 12:19 PM CST  
**Next Review:** Upon user approval/denial

