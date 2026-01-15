# Reservation System API Documentation

**Date:** January 6, 2026  
**Phase:** Phase 9.1 - Documentation  
**Status:** ✅ Complete  
**Version:** 1.0

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication & Privacy](#authentication--privacy)
3. [Core Services](#core-services)
   - [ReservationService](#reservationservice)
   - [ReservationAvailabilityService](#reservationavailabilityservice)
   - [ReservationRateLimitService](#reservationratelimitservice)
   - [ReservationWaitlistService](#reservationwaitlistservice)
   - [ReservationAnalyticsService](#reservationanalyticsservice)
   - [BusinessReservationAnalyticsService](#businessreservationanalyticsservice)
   - [ReservationNotificationService](#reservationnotificationservice)
   - [ReservationCalendarService](#reservationcalendarservice)
   - [ReservationRecurrenceService](#reservationrecurrenceservice)
   - [ReservationSharingService](#reservationsharingservice)
4. [Data Models](#data-models)
5. [Error Handling](#error-handling)
6. [Integration Patterns](#integration-patterns)

---

## Overview

The Reservation System API provides a comprehensive set of services for managing reservations in SPOTS. All services follow the same architectural patterns:

- **Offline-First**: All operations work offline, syncing when online
- **Privacy by Design**: Uses `agentId` (not `userId`) for internal tracking
- **Quantum Integration**: Automatically generates quantum states for compatibility matching
- **Knot Theory Integration**: Creates fabrics for group reservations
- **AI2AI Mesh Learning**: Tracks learning from reservation outcomes

### Base URL

All services are available via dependency injection (GetIt). No HTTP endpoints required for internal use.

### Service Initialization

```dart
// Services are registered in injection_container.dart
final reservationService = GetIt.instance<ReservationService>();
final availabilityService = GetIt.instance<ReservationAvailabilityService>();
// ... etc
```

---

## Authentication & Privacy

### AgentId System

**CRITICAL:** All reservation services use `agentId` (not `userId`) for privacy-protected internal tracking.

**How it Works:**
1. Services accept `userId` as a parameter (for API compatibility)
2. Services internally convert `userId` → `agentId` using `AgentIdService`
3. All internal storage and tracking uses `agentId`
4. External systems never see `agentId` - only business systems can request optional `userData`

**Example:**
```dart
// API accepts userId
final reservation = await reservationService.createReservation(
  userId: 'user-123', // User's ID
  // ... other params
);

// Internally, service converts to agentId
// Storage uses agentId: 'agent-456'
// Privacy preserved!
```

### Optional User Data

For business requirements (e.g., contact info for reservations), services support optional `userData`:

```dart
final reservation = await reservationService.createReservation(
  userId: 'user-123',
  userData: {
    'name': 'John Doe', // Only if user consents
    'email': 'john@example.com', // Only if user consents
    'phone': '+1234567890', // Only if user consents
  },
  // ... other params
);
```

**Privacy Guarantee:** `userData` is only shared if user explicitly consents.

---

## Core Services

### ReservationService

Main service for reservation CRUD operations. Orchestrates payment, quantum state creation, and analytics tracking.

#### `createReservation`

Creates a new reservation. Handles payment processing, quantum state creation, and offline-first storage.

**Method Signature:**
```dart
Future<Reservation> createReservation({
  required String userId, // Will be converted to agentId internally
  required ReservationType type, // spot, business, or event
  required String targetId, // Spot ID, Business ID, or Event ID
  required DateTime reservationTime,
  required int partySize,
  int? ticketCount, // Optional, defaults to partySize
  String? specialRequests, // Optional special requests
  double? ticketPrice, // Optional, only if business requires fee
  double? depositAmount, // Optional deposit
  String? seatId, // Optional seat ID if seating chart used
  CancellationPolicy? cancellationPolicy, // Optional, defaults to 24-hour policy
  Map<String, dynamic>? userData, // Optional user data (only if user consents)
})
```

**Parameters:**
- `userId` (required): User's ID (converted to agentId internally)
- `type` (required): `ReservationType.spot`, `ReservationType.business`, or `ReservationType.event`
- `targetId` (required): ID of the spot, business, or event
- `reservationTime` (required): Date and time of the reservation
- `partySize` (required): Number of people in the party
- `ticketCount` (optional): Number of tickets (defaults to `partySize`)
- `specialRequests` (optional): Special requests or notes
- `ticketPrice` (optional): Price per ticket (if business requires fee)
- `depositAmount` (optional): Deposit amount (if applicable)
- `seatId` (optional): Seat ID if seating chart is used
- `cancellationPolicy` (optional): Cancellation policy (defaults to 24-hour full refund)
- `userData` (optional): User data (name, email, phone) - only if user consents

**Returns:**
- `Future<Reservation>`: Created reservation object

**Payment Integration:**
- If `ticketPrice > 0` and `PaymentService` is available: Processes payment
- Payment success → Reservation confirmed
- Payment failure → Reservation creation fails (throws exception)
- Free reservations (`ticketPrice == null` or `0`) → Automatically confirmed

**Quantum Integration:**
- Automatically creates quantum state for reservation
- Uses `ReservationQuantumService` to generate reservation-specific quantum state
- Stores quantum state in `Reservation.quantumState` field

**Knot Theory Integration:**
- If `partySize > 1`: Automatically creates fabric using `KnotFabricService`
- Stores fabric data in reservation metadata

**Offline-First:**
- Stores reservation locally first (<50ms)
- Syncs to cloud when online (non-blocking)
- Works completely offline

**Example:**
```dart
// Free spot reservation
final reservation = await reservationService.createReservation(
  userId: 'user-123',
  type: ReservationType.spot,
  targetId: 'spot-456',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  partySize: 2,
);

// Paid event reservation
final paidReservation = await reservationService.createReservation(
  userId: 'user-123',
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 14)),
  partySize: 4,
  ticketCount: 4,
  ticketPrice: 25.0, // $25 per ticket
  specialRequests: 'Window seat preferred',
);

// Group reservation (creates fabric automatically)
final groupReservation = await reservationService.createReservation(
  userId: 'user-123',
  type: ReservationType.business,
  targetId: 'business-abc',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  partySize: 6, // Fabric created for 6-person group
);
```

**Errors:**
- `Exception`: If payment processing fails
- `Exception`: If reservation validation fails
- `Exception`: If quantum state creation fails (rare)

---

#### `getUserReservations`

Gets all reservations for a user, with optional filtering.

**Method Signature:**
```dart
Future<List<Reservation>> getUserReservations({
  String? userId, // Will be converted to agentId internally
  ReservationStatus? status, // Optional status filter
  DateTime? startDate, // Optional start date filter
  DateTime? endDate, // Optional end date filter
})
```

**Parameters:**
- `userId` (optional): User's ID (if not provided, returns all reservations - use with caution)
- `status` (optional): Filter by status (`pending`, `confirmed`, `cancelled`, `completed`, `noShow`)
- `startDate` (optional): Filter reservations from this date onwards
- `endDate` (optional): Filter reservations up to this date

**Returns:**
- `Future<List<Reservation>>`: List of reservations matching filters

**Offline-First:**
- Gets from local storage first (fast)
- Merges with cloud data when online (non-blocking)
- Returns local data if cloud unavailable

**Example:**
```dart
// Get all user's reservations
final allReservations = await reservationService.getUserReservations(
  userId: 'user-123',
);

// Get only confirmed reservations
final confirmed = await reservationService.getUserReservations(
  userId: 'user-123',
  status: ReservationStatus.confirmed,
);

// Get reservations for next week
final nextWeek = await reservationService.getUserReservations(
  userId: 'user-123',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 7)),
);
```

---

#### `getReservationsForTarget`

Gets all reservations for a specific spot, business, or event.

**Method Signature:**
```dart
Future<List<Reservation>> getReservationsForTarget({
  required ReservationType type,
  required String targetId,
  DateTime? date, // Optional date filter
  ReservationStatus? status, // Optional status filter
})
```

**Parameters:**
- `type` (required): Reservation type (`spot`, `business`, or `event`)
- `targetId` (required): ID of the spot, business, or event
- `date` (optional): Filter reservations for specific date
- `status` (optional): Filter by status

**Returns:**
- `Future<List<Reservation>>`: List of reservations for the target

**Use Case:** Business owners viewing all reservations for their spot/event

**Example:**
```dart
// Get all reservations for a spot
final spotReservations = await reservationService.getReservationsForTarget(
  type: ReservationType.spot,
  targetId: 'spot-456',
);

// Get reservations for a specific date
final todayReservations = await reservationService.getReservationsForTarget(
  type: ReservationType.business,
  targetId: 'business-abc',
  date: DateTime.now(),
  status: ReservationStatus.confirmed,
);
```

---

#### `updateReservation`

Updates an existing reservation (time, party size, special requests).

**Method Signature:**
```dart
Future<Reservation> updateReservation({
  required String reservationId,
  DateTime? reservationTime, // Optional new time
  int? partySize, // Optional new party size
  int? ticketCount, // Optional new ticket count
  String? specialRequests, // Optional new special requests
})
```

**Parameters:**
- `reservationId` (required): ID of the reservation to update
- `reservationTime` (optional): New reservation time
- `partySize` (optional): New party size
- `ticketCount` (optional): New ticket count
- `specialRequests` (optional): New special requests

**Returns:**
- `Future<Reservation>`: Updated reservation

**Modification Limits:**
- Maximum 3 modifications per reservation
- Cannot modify within 24 hours of reservation time
- Automatically increments `modificationCount`

**Example:**
```dart
// Update reservation time
final updated = await reservationService.updateReservation(
  reservationId: 'reservation-123',
  reservationTime: DateTime.now().add(Duration(days: 8)),
);

// Update party size and special requests
final updated2 = await reservationService.updateReservation(
  reservationId: 'reservation-123',
  partySize: 4,
  specialRequests: 'Vegetarian options please',
);
```

**Errors:**
- `Exception`: If reservation not found
- `Exception`: If modification limit exceeded
- `Exception`: If too close to reservation time

---

#### `cancelReservation`

Cancels an existing reservation. Applies cancellation policy and processes refunds if applicable.

**Method Signature:**
```dart
Future<Reservation> cancelReservation({
  required String reservationId,
  required String reason, // Cancellation reason
  bool applyPolicy = true, // Apply cancellation policy (default: true)
})
```

**Parameters:**
- `reservationId` (required): ID of the reservation to cancel
- `reason` (required): Reason for cancellation
- `applyPolicy` (optional): Whether to apply cancellation policy (default: `true`)

**Returns:**
- `Future<Reservation>`: Cancelled reservation

**Cancellation Policy:**
- Checks `hoursBefore` requirement
- Processes refund if `fullRefund` or `partialRefund` applies
- Applies cancellation fee if `hasCancellationFee` is true
- Uses `RefundService` if available

**Example:**
```dart
// Cancel reservation
final cancelled = await reservationService.cancelReservation(
  reservationId: 'reservation-123',
  reason: 'Change of plans',
);

// Cancel without applying policy (admin use)
final cancelledNoPolicy = await reservationService.cancelReservation(
  reservationId: 'reservation-123',
  reason: 'Business request',
  applyPolicy: false,
);
```

**Errors:**
- `Exception`: If reservation not found
- `Exception`: If already cancelled
- `Exception`: If cancellation policy prevents cancellation (too close to time)

---

#### `hasExistingReservation`

Checks if user already has a reservation for a specific target/time.

**Method Signature:**
```dart
Future<bool> hasExistingReservation({
  required String userId, // Will be converted to agentId internally
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime, // Check for specific time (within 1 hour window)
})
```

**Parameters:**
- `userId` (required): User's ID
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (required): Reservation time to check

**Returns:**
- `Future<bool>`: `true` if user has existing reservation at this target/time (within 1 hour window)

**Use Case:** Prevent duplicate reservations

**Example:**
```dart
// Check if user already has reservation
final hasExisting = await reservationService.hasExistingReservation(
  userId: 'user-123',
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 7)),
);

if (hasExisting) {
  // Show message: "You already have a reservation for this event"
}
```

---

### ReservationAvailabilityService

Checks availability and manages capacity for reservations.

#### `checkAvailability`

Checks if a spot/business/event is available for reservation at a specific time.

**Method Signature:**
```dart
Future<AvailabilityResult> checkAvailability({
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime,
  required int partySize,
  int? ticketCount, // Optional, defaults to partySize
})
```

**Parameters:**
- `type` (required): Reservation type (`spot`, `business`, or `event`)
- `targetId` (required): ID of the spot, business, or event
- `reservationTime` (required): Date and time to check
- `partySize` (required): Number of people
- `ticketCount` (optional): Number of tickets needed (defaults to `partySize`)

**Returns:**
- `Future<AvailabilityResult>`: Availability result with status and details

**AvailabilityResult:**
```dart
class AvailabilityResult {
  final bool isAvailable; // Whether reservation is available
  final String? reason; // Reason if not available
  final int? availableCapacity; // Available capacity (if applicable)
  final bool waitlistAvailable; // Whether waitlist is available
}
```

**Example:**
```dart
// Check event availability
final availability = await availabilityService.checkAvailability(
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  partySize: 2,
  ticketCount: 2,
);

if (availability.isAvailable) {
  // Proceed with reservation creation
  print('Available: ${availability.availableCapacity} tickets remaining');
} else {
  // Show unavailability message
  print('Not available: ${availability.reason}');
  if (availability.waitlistAvailable) {
    // Show waitlist option
  }
}
```

**Errors:**
- Returns `AvailabilityResult.unavailable()` with error message if check fails

---

#### `getCapacity`

Gets current capacity for a spot/business/event.

**Method Signature:**
```dart
Future<CapacityInfo?> getCapacity({
  required ReservationType type,
  required String targetId,
  DateTime? reservationTime, // Optional time to check capacity
})
```

**Parameters:**
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (optional): Time to check capacity

**Returns:**
- `Future<CapacityInfo?>`: Capacity information, or `null` if unlimited

**CapacityInfo:**
```dart
class CapacityInfo {
  final int current; // Current bookings/capacity used
  final int? max; // Maximum capacity (null if unlimited)
  final int? available; // Available capacity (null if unlimited)
  final DateTime? lastUpdated; // Last capacity update
}
```

**Example:**
```dart
// Get event capacity
final capacity = await availabilityService.getCapacity(
  type: ReservationType.event,
  targetId: 'event-789',
);

if (capacity != null) {
  print('Capacity: ${capacity.current}/${capacity.max} (${capacity.available} available)');
} else {
  print('Unlimited capacity');
}
```

---

#### `reserveCapacity`

Reserves capacity atomically (prevents overbooking).

**Method Signature:**
```dart
Future<bool> reserveCapacity({
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime,
  required int ticketCount,
  required String reservationId, // Reservation ID to reserve for
})
```

**Parameters:**
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (required): Reservation time
- `ticketCount` (required): Number of tickets to reserve
- `reservationId` (required): Reservation ID (for tracking)

**Returns:**
- `Future<bool>`: `true` if capacity reserved successfully, `false` if insufficient capacity

**Use Case:** Called before creating reservation to prevent overbooking

**Example:**
```dart
// Reserve capacity before creating reservation
final reserved = await availabilityService.reserveCapacity(
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  ticketCount: 2,
  reservationId: 'reservation-123',
);

if (reserved) {
  // Proceed with reservation creation
} else {
  // Show insufficient capacity error
}
```

---

#### `releaseCapacity`

Releases reserved capacity (e.g., on cancellation).

**Method Signature:**
```dart
Future<void> releaseCapacity({
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime,
  required int ticketCount,
  required String reservationId, // Reservation ID that reserved capacity
})
```

**Parameters:**
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (required): Reservation time
- `ticketCount` (required): Number of tickets to release
- `reservationId` (required): Reservation ID that originally reserved capacity

**Returns:**
- `Future<void>`: Completes when capacity released

**Use Case:** Called when reservation is cancelled

**Example:**
```dart
// Release capacity on cancellation
await availabilityService.releaseCapacity(
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: reservation.reservationTime,
  ticketCount: reservation.ticketCount,
  reservationId: reservation.id,
);
```

---

### ReservationRateLimitService

Enforces rate limiting to prevent abuse and spam reservations.

#### `checkRateLimit`

Checks if user is allowed to create a reservation (rate limit check).

**Method Signature:**
```dart
Future<RateLimitCheckResult> checkRateLimit({
  required String userId, // Will be converted to agentId internally
  required ReservationType type,
  required String targetId,
  DateTime? reservationTime, // Optional, for time-based limits
})
```

**Parameters:**
- `userId` (required): User's ID (converted to agentId internally)
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (optional): Reservation time

**Returns:**
- `Future<RateLimitCheckResult>`: Rate limit check result

**RateLimitCheckResult:**
```dart
class RateLimitCheckResult {
  final bool allowed; // Whether request is allowed
  final String? reason; // Reason if not allowed
  final int? remaining; // Remaining requests in current window
  final DateTime? resetAt; // When rate limit resets
  final int? retryAfter; // Retry after (seconds)
}
```

**Rate Limits:**
- Per-user: 10 reservations per hour, 50 reservations per day
- Per-target: 3 reservations per day per spot/event, 10 reservations per week per spot/event

**Example:**
```dart
// Check rate limit before creating reservation
final rateLimit = await rateLimitService.checkRateLimit(
  userId: 'user-123',
  type: ReservationType.spot,
  targetId: 'spot-456',
);

if (rateLimit.allowed) {
  // Proceed with reservation creation
  print('Rate limit OK: ${rateLimit.remaining} remaining');
} else {
  // Show rate limit error
  print('Rate limit exceeded: ${rateLimit.reason}');
  print('Retry after: ${rateLimit.retryAfter} seconds');
  print('Resets at: ${rateLimit.resetAt}');
}
```

---

#### `recordReservation`

Records a reservation for rate limiting tracking.

**Method Signature:**
```dart
Future<void> recordReservation({
  required String userId, // Will be converted to agentId internally
  required ReservationType type,
  required String targetId,
  DateTime? reservationTime, // Optional
})
```

**Parameters:**
- `userId` (required): User's ID
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (optional): Reservation time

**Returns:**
- `Future<void>`: Completes when reservation recorded

**Use Case:** Called after successful reservation creation to track usage

**Example:**
```dart
// Record reservation for rate limiting
await rateLimitService.recordReservation(
  userId: 'user-123',
  type: ReservationType.spot,
  targetId: 'spot-456',
);
```

---

### ReservationWaitlistService

Manages waitlists when capacity is full.

#### `addToWaitlist`

Adds user to waitlist when capacity is full.

**Method Signature:**
```dart
Future<WaitlistEntry> addToWaitlist({
  required String userId, // Will be converted to agentId internally
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime,
  required int ticketCount,
})
```

**Parameters:**
- `userId` (required): User's ID (converted to agentId internally)
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (required): Reservation time
- `ticketCount` (required): Number of tickets requested

**Returns:**
- `Future<WaitlistEntry>`: Waitlist entry with position

**WaitlistEntry:**
```dart
class WaitlistEntry {
  final String id; // Entry ID
  final String agentId; // User's agentId (privacy-protected)
  final ReservationType type;
  final String targetId;
  final DateTime reservationTime;
  final int ticketCount;
  final AtomicTimestamp entryTimestamp; // Used for position ordering
  final int? position; // Position in waitlist (1-based)
  final WaitlistStatus status; // waiting, promoted, expired, cancelled
  final DateTime? promotedAt; // When entry was promoted
  final String? reservationId; // Reservation ID if promoted
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Position Calculation:**
- Position based on `entryTimestamp` (atomic timestamp)
- First-come-first-served (true chronological ordering)
- Position recalculated when entries are promoted/expired

**Example:**
```dart
// Add to waitlist
final entry = await waitlistService.addToWaitlist(
  userId: 'user-123',
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  ticketCount: 2,
);

print('Added to waitlist: Position ${entry.position}');
```

---

#### `getWaitlistPosition`

Gets current waitlist position for a user's entry.

**Method Signature:**
```dart
Future<int?> getWaitlistPosition({
  required String userId, // Will be converted to agentId internally
  required String waitlistEntryId,
})
```

**Parameters:**
- `userId` (required): User's ID
- `waitlistEntryId` (required): Waitlist entry ID

**Returns:**
- `Future<int?>`: Position in waitlist (1-based), or `null` if entry not found or doesn't belong to user

**Example:**
```dart
// Get waitlist position
final position = await waitlistService.getWaitlistPosition(
  userId: 'user-123',
  waitlistEntryId: 'waitlist-entry-456',
);

if (position != null) {
  print('Your position in waitlist: $position');
} else {
  print('Entry not found or access denied');
}
```

---

#### `processWaitlist`

Processes waitlist when capacity becomes available. Automatically promotes eligible entries.

**Method Signature:**
```dart
Future<List<WaitlistEntry>> processWaitlist({
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime,
  required int availableCapacity,
})
```

**Parameters:**
- `type` (required): Reservation type
- `targetId` (required): Target ID
- `reservationTime` (required): Reservation time
- `availableCapacity` (required): Available capacity

**Returns:**
- `Future<List<WaitlistEntry>>`: List of promoted waitlist entries

**Promotion Logic:**
- Promotes entries in chronological order (by `entryTimestamp`)
- Promotes up to `availableCapacity` tickets
- Sends notifications to promoted users
- Creates reservations for promoted entries (if auto-create enabled)

**Example:**
```dart
// Process waitlist when capacity becomes available
final promoted = await waitlistService.processWaitlist(
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  availableCapacity: 5, // 5 tickets available
);

print('Promoted ${promoted.length} waitlist entries');
for (final entry in promoted) {
  print('Promoted: ${entry.id}, Position was ${entry.position}');
}
```

---

#### `removeFromWaitlist`

Removes user from waitlist (e.g., if they no longer want to wait).

**Method Signature:**
```dart
Future<bool> removeFromWaitlist({
  required String userId, // Will be converted to agentId internally
  required String waitlistEntryId,
})
```

**Parameters:**
- `userId` (required): User's ID
- `waitlistEntryId` (required): Waitlist entry ID

**Returns:**
- `Future<bool>`: `true` if removed successfully, `false` if not found or doesn't belong to user

**Example:**
```dart
// Remove from waitlist
final removed = await waitlistService.removeFromWaitlist(
  userId: 'user-123',
  waitlistEntryId: 'waitlist-entry-456',
);

if (removed) {
  print('Removed from waitlist');
} else {
  print('Entry not found or access denied');
}
```

---

### ReservationAnalyticsService

Provides analytics for users about their reservation patterns and compatibility insights.

#### `getUserAnalytics`

Gets comprehensive analytics for a user's reservations.

**Method Signature:**
```dart
Future<UserReservationAnalytics> getUserAnalytics({
  required String userId,
  DateTime? startDate, // Optional start date filter
  DateTime? endDate, // Optional end date filter
})
```

**Parameters:**
- `userId` (required): User's ID
- `startDate` (optional): Start date for analytics period
- `endDate` (optional): End date for analytics period

**Returns:**
- `Future<UserReservationAnalytics>`: Comprehensive analytics data

**UserReservationAnalytics:**
```dart
class UserReservationAnalytics {
  final int totalReservations;
  final int completedReservations;
  final int cancelledReservations;
  final int pendingReservations;
  final double completionRate; // 0.0 to 1.0
  final double cancellationRate; // 0.0 to 1.0
  final List<FavoriteSpot> favoriteSpots; // Top 3 favorite spots
  final ReservationPatterns patterns; // Time patterns, day patterns
  final ModificationPatterns modificationPatterns;
  final WaitlistHistory waitlistHistory;
  final StringEvolutionPatterns? stringEvolutionPatterns; // Knot string evolution
  final FabricStabilityAnalytics? fabricStabilityAnalytics; // Group reservation analytics
  final WorldsheetEvolutionAnalytics? worldsheetEvolutionAnalytics; // Temporal patterns
  final QuantumCompatibilityHistory? quantumCompatibilityHistory; // Compatibility trends
  final AI2AILearningInsights? ai2aiLearningInsights; // Learning insights
}
```

**Example:**
```dart
// Get user analytics
final analytics = await analyticsService.getUserAnalytics(
  userId: 'user-123',
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

print('Total reservations: ${analytics.totalReservations}');
print('Completion rate: ${(analytics.completionRate * 100).toStringAsFixed(1)}%');
print('Favorite spots: ${analytics.favoriteSpots.length}');
print('Average compatibility: ${analytics.quantumCompatibilityHistory?.averageCompatibility ?? 0.0}');
```

---

#### `trackReservationEvent`

Tracks a reservation event for analytics.

**Method Signature:**
```dart
Future<void> trackReservationEvent({
  required String userId,
  required String eventType, // reservation_created, reservation_modified, etc.
  required Map<String, dynamic> parameters, // Event parameters
})
```

**Parameters:**
- `userId` (required): User's ID
- `eventType` (required): Event type (`reservation_created`, `reservation_modified`, `reservation_cancelled`, etc.)
- `parameters` (required): Event parameters (reservation ID, type, etc.)

**Returns:**
- `Future<void>`: Completes when event tracked

**Event Types:**
- `reservation_created`
- `reservation_modified`
- `reservation_cancelled`
- `reservation_completed`
- `reservation_waitlist_joined`
- `reservation_waitlist_converted`

**Example:**
```dart
// Track reservation creation
await analyticsService.trackReservationEvent(
  userId: 'user-123',
  eventType: 'reservation_created',
  parameters: {
    'reservation_id': reservation.id,
    'type': reservation.type.toString(),
    'target_id': reservation.targetId,
  },
);
```

---

### BusinessReservationAnalyticsService

Provides analytics for businesses about their reservations.

#### `getBusinessAnalytics`

Gets comprehensive analytics for a business's reservations.

**Method Signature:**
```dart
Future<BusinessReservationAnalytics> getBusinessAnalytics({
  required String businessId,
  required ReservationType type, // spot, business, or event
  DateTime? startDate, // Optional start date filter
  DateTime? endDate, // Optional end date filter
})
```

**Parameters:**
- `businessId` (required): Business ID
- `type` (required): Reservation type
- `startDate` (optional): Start date for analytics period
- `endDate` (optional): End date for analytics period

**Returns:**
- `Future<BusinessReservationAnalytics>`: Business analytics data

**BusinessReservationAnalytics:**
```dart
class BusinessReservationAnalytics {
  final int totalReservations;
  final int confirmedReservations;
  final int cancelledReservations;
  final int noShowReservations;
  final double cancellationRate;
  final double noShowRate;
  final ReservationVolumeMetrics volumeMetrics; // Peak times, trends
  final RevenueMetrics revenueMetrics; // Total revenue, average ticket price
  final CustomerRetentionMetrics retentionMetrics; // Repeat customers, retention rate
  final RateLimitMetrics? rateLimitMetrics; // Rate limit usage
  final WaitlistMetrics? waitlistMetrics; // Waitlist statistics
  final CapacityUtilizationMetrics? capacityMetrics; // Capacity utilization
  final StringEvolutionPatterns? stringEvolutionPatterns; // Business patterns
  final FabricStabilityAnalytics? fabricStabilityAnalytics; // Group reservations
  final QuantumCompatibilityTrends? quantumCompatibilityTrends; // Compatibility trends
  final AI2AILearningInsights? ai2aiLearningInsights; // Learning insights
}
```

**Example:**
```dart
// Get business analytics
final analytics = await businessAnalyticsService.getBusinessAnalytics(
  businessId: 'business-abc',
  type: ReservationType.business,
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

print('Total reservations: ${analytics.totalReservations}');
print('Cancellation rate: ${(analytics.cancellationRate * 100).toStringAsFixed(1)}%');
print('Peak time: ${analytics.volumeMetrics.peakTime}');
print('Total revenue: \$${analytics.revenueMetrics.totalRevenue}');
```

---

### ReservationNotificationService

Sends notifications for reservations (confirmations, reminders, cancellations).

#### `sendConfirmation`

Sends confirmation notification when reservation is created/confirmed.

**Method Signature:**
```dart
Future<void> sendConfirmation(Reservation reservation)
```

**Parameters:**
- `reservation` (required): Reservation object

**Returns:**
- `Future<void>`: Completes when notification sent (non-blocking, errors don't throw)

**Example:**
```dart
// Send confirmation
await notificationService.sendConfirmation(reservation);
```

---

#### `sendReminder`

Sends reminder notification (24h before or 1h before).

**Method Signature:**
```dart
Future<void> sendReminder(
  Reservation reservation,
  Duration beforeTime, // Duration before reservation time
)
```

**Parameters:**
- `reservation` (required): Reservation object
- `beforeTime` (required): Duration before reservation (e.g., `Duration(hours: 24)`)

**Returns:**
- `Future<void>`: Completes when notification sent (non-blocking)

**Example:**
```dart
// Send 24-hour reminder
await notificationService.sendReminder(
  reservation,
  Duration(hours: 24),
);

// Send 1-hour reminder
await notificationService.sendReminder(
  reservation,
  Duration(hours: 1),
);
```

---

#### `scheduleReminders`

Schedules automatic reminders for a reservation (24h and 1h before).

**Method Signature:**
```dart
Future<void> scheduleReminders(Reservation reservation)
```

**Parameters:**
- `reservation` (required): Reservation object

**Returns:**
- `Future<void>`: Completes when reminders scheduled (non-blocking)

**Example:**
```dart
// Schedule reminders for reservation
await notificationService.scheduleReminders(reservation);
```

---

#### `sendCancellationNotice`

Sends cancellation notification when reservation is cancelled.

**Method Signature:**
```dart
Future<void> sendCancellationNotice(Reservation reservation)
```

**Parameters:**
- `reservation` (required): Cancelled reservation object

**Returns:**
- `Future<void>`: Completes when notification sent (non-blocking)

**Example:**
```dart
// Send cancellation notice
await notificationService.sendCancellationNotice(cancelledReservation);
```

---

### ReservationCalendarService

Integrates reservations with device calendar (iOS Calendar, Google Calendar). Enables users to sync reservations to their calendar and receive calendar-based reminders.

**Phase:** 10.2 - Calendar Integration  
**Status:** ✅ Complete

#### `syncReservationToCalendar`

Syncs a reservation to the device calendar, creating a calendar event.

**Method Signature:**
```dart
Future<CalendarSyncResult> syncReservationToCalendar({
  required String reservationId,
  String? calendarId, // Optional calendar ID (uses default if not provided)
})
```

**Parameters:**
- `reservationId` (required): Reservation ID to sync
- `calendarId` (optional): Calendar ID (uses default calendar if not provided)

**Returns:**
- `Future<CalendarSyncResult>`: Result with success status and event ID

**CalendarSyncResult:**
```dart
class CalendarSyncResult {
  final bool success; // Whether sync was successful
  final String? eventId; // Calendar event ID (if successful)
  final String? error; // Error message (if failed)
  final CalendarEventMetadata? metadata; // Event metadata
}
```

**Example:**
```dart
// Sync reservation to calendar
final result = await calendarService.syncReservationToCalendar(
  reservationId: 'reservation-123',
);

if (result.success) {
  print('Synced to calendar: ${result.eventId}');
} else {
  print('Sync failed: ${result.error}');
}
```

**AVRAI Integration:**
- Generates knot signature for calendar event verification
- Embeds quantum state in calendar event metadata
- Uses string evolution for optimal time predictions
- Propagates calendar sync patterns to AI2AI mesh for learning

---

#### `syncCalendarToReservations`

Syncs calendar events back to reservations (stubbed - `add_2_calendar` package limitations).

**Method Signature:**
```dart
Future<List<CalendarSyncResult>> syncCalendarToReservations({
  required String userId,
  DateTime? startDate,
  DateTime? endDate,
})
```

**Note:** Currently stubbed due to `add_2_calendar` package limitations. Users must manually remove calendar events.

---

#### `getOptimalTimeSuggestions`

Gets optimal time suggestions for a reservation based on calendar availability and compatibility.

**Method Signature:**
```dart
Future<List<OptimalTimeSuggestion>> getOptimalTimeSuggestions({
  required String userId,
  required ReservationType type,
  required String targetId,
  required DateTime startDate,
  required DateTime endDate,
})
```

**Returns:**
- `Future<List<OptimalTimeSuggestion>>`: List of optimal time suggestions

**Status:** Placeholder implementation - full implementation pending

---

#### `detectConflicts`

Detects calendar conflicts for a reservation time.

**Method Signature:**
```dart
Future<List<CalendarConflict>> detectConflicts({
  required String userId,
  required DateTime reservationTime,
  required Duration duration,
})
```

**Returns:**
- `Future<List<CalendarConflict>>`: List of detected conflicts

**Status:** Placeholder implementation - full implementation pending

---

### ReservationRecurrenceService

Manages recurring reservation series and instances. Enables users to create reservations that repeat on a schedule (daily, weekly, monthly, custom).

**Phase:** 10.3 - Recurring Reservations  
**Status:** ✅ Complete

#### `createRecurringSeries`

Creates a series of recurring reservations from a base template.

**Method Signature:**
```dart
Future<RecurrenceOperationResult> createRecurringSeries({
  required String userId,
  required Reservation baseReservation,
  required RecurrencePattern pattern,
})
```

**Parameters:**
- `userId` (required): User ID (converted to agentId internally)
- `baseReservation` (required): Base reservation template
- `pattern` (required): Recurrence pattern (daily, weekly, monthly, custom)

**RecurrencePattern:**
```dart
class RecurrencePattern {
  final RecurrencePatternType type; // daily, weekly, monthly, custom
  final int interval; // Interval (e.g., every 2 weeks = interval: 2)
  final List<int>? daysOfWeek; // Days of week (0=Sunday, 6=Saturday) for weekly
  final int? dayOfMonth; // Day of month (1-31) for monthly
  final DateTime? endDate; // End date (optional)
  final int? maxOccurrences; // Max occurrences (optional)
}
```

**Returns:**
- `Future<RecurrenceOperationResult>`: Result with created reservation IDs

**RecurrenceOperationResult:**
```dart
class RecurrenceOperationResult {
  final bool success;
  final String? seriesId; // Recurring series ID
  final List<String> reservationIds; // Created reservation IDs
  final String? error;
  final int instanceCount; // Number of instances created
}
```

**Example:**
```dart
// Create weekly recurring reservation (every Friday)
final pattern = RecurrencePattern(
  type: RecurrencePatternType.weekly,
  interval: 1,
  daysOfWeek: [5], // Friday
  maxOccurrences: 10, // 10 occurrences
);

final result = await recurrenceService.createRecurringSeries(
  userId: 'user-123',
  baseReservation: baseReservation,
  pattern: pattern,
);

if (result.success) {
  print('Created ${result.instanceCount} recurring reservations');
  print('Series ID: ${result.seriesId}');
}
```

**AVRAI Integration:**
- Generates knot signature for recurring series
- Creates quantum state for recurring pattern
- Uses string evolution to predict optimal recurrence times
- Creates fabric for group recurring reservations
- Tracks recurring patterns in worldsheet for temporal analysis
- Propagates recurring patterns to AI2AI mesh for learning

---

#### `pauseRecurringSeries`

Pauses a recurring reservation series (prevents future instances from being created).

**Method Signature:**
```dart
Future<RecurrenceOperationResult> pauseRecurringSeries({
  required String seriesId,
})
```

**Status:** Placeholder implementation

---

#### `resumeRecurringSeries`

Resumes a paused recurring reservation series.

**Method Signature:**
```dart
Future<RecurrenceOperationResult> resumeRecurringSeries({
  required String seriesId,
})
```

**Status:** Placeholder implementation

---

#### `cancelRecurringSeries`

Cancels a recurring reservation series and all future instances.

**Method Signature:**
```dart
Future<RecurrenceOperationResult> cancelRecurringSeries({
  required String seriesId,
  bool cancelExistingInstances = false, // Whether to cancel existing reservations
})
```

**Status:** Placeholder implementation

---

### ReservationSharingService

Manages sharing and transferring reservations between users. Enables users to share reservations with others (read-only or full access) or transfer ownership.

**Phase:** 10.4 - Reservation Sharing & Transfer  
**Status:** ✅ Complete

#### `shareReservation`

Shares a reservation with another user.

**Method Signature:**
```dart
Future<SharingOperationResult> shareReservation({
  required String reservationId,
  required String ownerUserId,
  required String sharedWithUserId,
  required SharingPermission permission,
})
```

**Parameters:**
- `reservationId` (required): Reservation ID to share
- `ownerUserId` (required): Owner's user ID
- `sharedWithUserId` (required): User ID to share with
- `permission` (required): Permission level (`readOnly` or `fullAccess`)

**SharingPermission:**
```dart
enum SharingPermission {
  readOnly, // Can view reservation details only
  fullAccess, // Can modify, cancel, etc.
}
```

**Returns:**
- `Future<SharingOperationResult>`: Result with sharing status

**SharingOperationResult:**
```dart
class SharingOperationResult {
  final bool success;
  final SharedReservation? sharedReservation;
  final String? error;
}
```

**Example:**
```dart
// Share reservation with read-only access
final result = await sharingService.shareReservation(
  reservationId: 'reservation-123',
  ownerUserId: 'user-123',
  sharedWithUserId: 'user-456',
  permission: SharingPermission.readOnly,
);

if (result.success) {
  print('Reservation shared successfully');
}
```

**AVRAI Integration:**
- Verifies knot signature for sharing authorization
- Preserves quantum state during sharing
- Predicts compatibility between owner and shared user
- Creates fabric for group shared reservations
- Tracks sharing patterns in worldsheet
- Propagates sharing patterns to AI2AI mesh for learning

---

#### `transferReservation`

Transfers reservation ownership to another user (irreversible).

**Method Signature:**
```dart
Future<TransferOperationResult> transferReservation({
  required String reservationId,
  required String fromUserId,
  required String toUserId,
})
```

**Parameters:**
- `reservationId` (required): Reservation ID to transfer
- `fromUserId` (required): Current owner's user ID
- `toUserId` (required): New owner's user ID

**Returns:**
- `Future<TransferOperationResult>`: Result with transfer status

**TransferOperationResult:**
```dart
class TransferOperationResult {
  final bool success;
  final Reservation? transferredReservation;
  final String? error;
  final double? predictedCompatibility; // Compatibility prediction (0.0-1.0)
}
```

**Example:**
```dart
// Transfer reservation ownership
final result = await sharingService.transferReservation(
  reservationId: 'reservation-123',
  fromUserId: 'user-123',
  toUserId: 'user-456',
);

if (result.success) {
  print('Reservation transferred successfully');
  print('Predicted compatibility: ${result.predictedCompatibility}');
}
```

**Warning:** Transfer is irreversible. The original owner loses all access.

**AVRAI Integration:**
- Verifies knot signature for transfer authorization
- Preserves quantum state during transfer
- Predicts compatibility between old and new owner
- Tracks transfer patterns in worldsheet
- Propagates transfer patterns to AI2AI mesh for learning

---

#### `getSharedReservations`

Gets all reservations shared with a user.

**Method Signature:**
```dart
Future<List<SharedReservation>> getSharedReservations({
  required String userId,
})
```

**Returns:**
- `Future<List<SharedReservation>>`: List of shared reservations

**Status:** Placeholder implementation

---

#### `revokeSharing`

Revokes sharing access for a shared reservation.

**Method Signature:**
```dart
Future<SharingOperationResult> revokeSharing({
  required String reservationId,
  required String ownerUserId,
  required String sharedWithUserId,
})
```

**Status:** Placeholder implementation

---

## Data Models

### Reservation

Core reservation model with all reservation data.

**Properties:**
```dart
class Reservation {
  final String id; // Unique reservation ID
  final String agentId; // User's agentId (privacy-protected, not userId)
  final Map<String, dynamic>? userData; // Optional user data (only if user consents)
  final ReservationType type; // spot, business, or event
  final String targetId; // Spot ID, Business ID, or Event ID
  final DateTime reservationTime; // Date and time of reservation
  final int partySize; // Number of people
  final int ticketCount; // Number of tickets
  final String? specialRequests; // Special requests or notes
  final ReservationStatus status; // pending, confirmed, cancelled, completed, noShow
  final double? ticketPrice; // Price per ticket (if paid)
  final double? totalPrice; // Total price (ticketPrice * ticketCount)
  final double? spotsFee; // SPOTS platform fee (10% of ticket fee)
  final double? depositAmount; // Deposit amount (if applicable)
  final String? seatId; // Seat ID if seating chart used
  final String? paymentId; // Payment ID if paid reservation
  final CancellationPolicy cancellationPolicy; // Cancellation policy
  final int modificationCount; // Number of modifications (max 3)
  final DateTime? lastModifiedAt; // Last modification time
  final AtomicTimestamp atomicTimestamp; // Atomic timestamp for ordering
  final QuantumEntityState? quantumState; // Reservation quantum state
  final Map<String, dynamic> metadata; // Additional metadata (JSONB)
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### ReservationType

Enum for reservation types.

```dart
enum ReservationType {
  spot,      // Reservation at a spot (restaurant, bar, venue)
  business,  // Reservation with a business account
  event,     // Reservation for an event
}
```

### ReservationStatus

Enum for reservation statuses.

```dart
enum ReservationStatus {
  pending,    // Awaiting confirmation
  confirmed,  // Confirmed by business/spot
  cancelled,  // Cancelled (by user or business)
  completed,  // Reservation fulfilled
  noShow,     // User didn't show up
}
```

### CancellationPolicy

Cancellation policy configuration.

```dart
class CancellationPolicy {
  final int hoursBefore; // Hours before reservation that cancellation is allowed
  final bool fullRefund; // Whether full refund is available
  final bool partialRefund; // Whether partial refund is available
  final double? refundPercentage; // Refund percentage (0.0 to 1.0) if partial
  final bool hasCancellationFee; // Whether cancellation fee applies
  final double? cancellationFee; // Cancellation fee amount (if applicable)
}
```

### AvailabilityResult

Result from availability check.

```dart
class AvailabilityResult {
  final bool isAvailable; // Whether reservation is available
  final String? reason; // Reason if not available
  final int? availableCapacity; // Available capacity (if applicable)
  final bool waitlistAvailable; // Whether waitlist is available
}
```

### RateLimitCheckResult

Result from rate limit check.

```dart
class RateLimitCheckResult {
  final bool allowed; // Whether request is allowed
  final String? reason; // Reason if not allowed
  final int? remaining; // Remaining requests in current window
  final DateTime? resetAt; // When rate limit resets
  final int? retryAfter; // Retry after (seconds)
}
```

### WaitlistEntry

Waitlist entry model.

```dart
class WaitlistEntry {
  final String id; // Entry ID
  final String agentId; // User's agentId (privacy-protected)
  final ReservationType type;
  final String targetId;
  final DateTime reservationTime;
  final int ticketCount;
  final AtomicTimestamp entryTimestamp; // Used for position ordering
  final int? position; // Position in waitlist (1-based)
  final WaitlistStatus status; // waiting, promoted, expired, cancelled
  final DateTime? promotedAt; // When entry was promoted
  final String? reservationId; // Reservation ID if promoted
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## Error Handling

### Error Strategy

All services follow a consistent error handling strategy:

1. **Graceful Degradation**: Optional services (payment, analytics, notifications) degrade gracefully if unavailable
2. **Explicit Errors**: Critical operations (payment, reservation creation) throw exceptions on failure
3. **Logging**: All errors are logged with context using `developer.log()`
4. **User-Friendly Messages**: Errors include user-friendly messages when possible

### Common Errors

**Reservation Creation Errors:**
- `Exception('Payment processing failed')`: Payment service failed
- `Exception('Reservation validation failed')`: Invalid reservation data
- `Exception('Insufficient capacity')`: Not enough capacity available

**Rate Limiting Errors:**
- `RateLimitCheckResult.denied()`: Rate limit exceeded (includes reason and retry time)

**Availability Errors:**
- `AvailabilityResult.unavailable()`: Not available (includes reason and waitlist availability)

**Update/Cancel Errors:**
- `Exception('Reservation not found')`: Reservation doesn't exist
- `Exception('Reservation cannot be modified')`: Modification limit exceeded or too close to time
- `Exception('Cancellation not allowed')`: Cancellation policy prevents cancellation

### Error Handling Examples

```dart
// Handle reservation creation errors
try {
  final reservation = await reservationService.createReservation(...);
  // Success
} on Exception catch (e) {
  // Handle error
  if (e.toString().contains('Payment')) {
    // Show payment error message
  } else if (e.toString().contains('capacity')) {
    // Show capacity error, offer waitlist
  } else {
    // Show generic error
  }
}

// Handle rate limiting
final rateLimit = await rateLimitService.checkRateLimit(...);
if (!rateLimit.allowed) {
  // Show rate limit error with retry time
  showError('${rateLimit.reason}. Retry after ${rateLimit.retryAfter} seconds.');
}

// Handle availability
final availability = await availabilityService.checkAvailability(...);
if (!availability.isAvailable) {
  // Show unavailability message
  if (availability.waitlistAvailable) {
    // Offer waitlist option
  }
}
```

---

## Integration Patterns

### Complete Reservation Creation Flow

Example of complete reservation creation with all checks:

```dart
Future<Reservation?> createReservationWithChecks({
  required String userId,
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime,
  required int partySize,
  int? ticketCount,
  double? ticketPrice,
}) async {
  // Step 1: Check rate limit
  final rateLimit = await rateLimitService.checkRateLimit(
    userId: userId,
    type: type,
    targetId: targetId,
  );
  if (!rateLimit.allowed) {
    throw Exception(rateLimit.reason ?? 'Rate limit exceeded');
  }

  // Step 2: Check availability
  final availability = await availabilityService.checkAvailability(
    type: type,
    targetId: targetId,
    reservationTime: reservationTime,
    partySize: partySize,
    ticketCount: ticketCount,
  );
  if (!availability.isAvailable) {
    // Check if waitlist available
    if (availability.waitlistAvailable) {
      // Add to waitlist instead
      final waitlistEntry = await waitlistService.addToWaitlist(
        userId: userId,
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        ticketCount: ticketCount ?? partySize,
      );
      throw WaitlistException('Added to waitlist: Position ${waitlistEntry.position}');
    } else {
      throw Exception(availability.reason ?? 'Not available');
    }
  }

  // Step 3: Reserve capacity (prevents overbooking)
  final reserved = await availabilityService.reserveCapacity(
    type: type,
    targetId: targetId,
    reservationTime: reservationTime,
    ticketCount: ticketCount ?? partySize,
    reservationId: 'pending-${Uuid().v4()}', // Temporary ID
  );
  if (!reserved) {
    throw Exception('Failed to reserve capacity');
  }

  // Step 4: Create reservation
  try {
    final reservation = await reservationService.createReservation(
      userId: userId,
      type: type,
      targetId: targetId,
      reservationTime: reservationTime,
      partySize: partySize,
      ticketCount: ticketCount,
      ticketPrice: ticketPrice,
    );

    // Step 5: Record for rate limiting
    await rateLimitService.recordReservation(
      userId: userId,
      type: type,
      targetId: targetId,
    );

    // Step 6: Schedule reminders
    await notificationService.scheduleReminders(reservation);

    return reservation;
  } catch (e) {
    // If reservation creation fails, release reserved capacity
    await availabilityService.releaseCapacity(
      type: type,
      targetId: targetId,
      reservationTime: reservationTime,
      ticketCount: ticketCount ?? partySize,
      reservationId: 'pending-${Uuid().v4()}',
    );
    rethrow;
  }
}
```

### Waitlist Promotion Flow

Example of processing waitlist when capacity becomes available:

```dart
Future<void> handleCapacityAvailable({
  required ReservationType type,
  required String targetId,
  required DateTime reservationTime,
  required int availableCapacity,
}) async {
  // Step 1: Process waitlist
  final promoted = await waitlistService.processWaitlist(
    type: type,
    targetId: targetId,
    reservationTime: reservationTime,
    availableCapacity: availableCapacity,
  );

  // Step 2: Create reservations for promoted entries
  for (final entry in promoted) {
    try {
      // Get userId from entry metadata or agentId lookup
      final userId = await agentIdService.getUserIdFromAgentId(entry.agentId);
      
      final reservation = await reservationService.createReservation(
        userId: userId,
        type: entry.type,
        targetId: entry.targetId,
        reservationTime: entry.reservationTime,
        partySize: entry.ticketCount,
        ticketCount: entry.ticketCount,
      );

      // Step 3: Update entry with reservation ID
      final updatedEntry = entry.copyWith(
        status: WaitlistStatus.promoted,
        promotedAt: DateTime.now(),
        reservationId: reservation.id,
      );
      await waitlistService.updateWaitlistEntry(updatedEntry);

      // Step 4: Send promotion notification
      await notificationService.sendPromotionNotice(entry, reservation);
    } catch (e) {
      developer.log('Failed to create reservation for promoted entry: $e');
      // Continue with next entry
    }
  }
}
```

### Cancellation with Refund Flow

Example of cancelling a reservation with refund processing:

```dart
Future<Reservation> cancelReservationWithRefund({
  required String reservationId,
  required String reason,
}) async {
  // Step 1: Get reservation
  final reservation = await reservationService.getReservationById(reservationId);
  if (reservation == null) {
    throw Exception('Reservation not found');
  }

  // Step 2: Cancel reservation (applies cancellation policy)
  final cancelled = await reservationService.cancelReservation(
    reservationId: reservationId,
    reason: reason,
  );

  // Step 3: Release capacity
  await availabilityService.releaseCapacity(
    type: cancelled.type,
    targetId: cancelled.targetId,
    reservationTime: cancelled.reservationTime,
    ticketCount: cancelled.ticketCount,
    reservationId: cancelled.id,
  );

  // Step 4: Process refund (if applicable, handled by ReservationService)
  // Refund processing is automatic if cancellation policy allows it

  // Step 5: Send cancellation notice
  await notificationService.sendCancellationNotice(cancelled);

  return cancelled;
}
```

---

## Best Practices

### 1. Always Check Rate Limits First

```dart
// ✅ GOOD: Check rate limit before creating reservation
final rateLimit = await rateLimitService.checkRateLimit(...);
if (!rateLimit.allowed) {
  // Show error, don't proceed
  return;
}
final reservation = await reservationService.createReservation(...);

// ❌ BAD: Create reservation first, then check rate limit
final reservation = await reservationService.createReservation(...);
final rateLimit = await rateLimitService.checkRateLimit(...); // Too late
```

### 2. Check Availability Before Creating

```dart
// ✅ GOOD: Check availability first
final availability = await availabilityService.checkAvailability(...);
if (!availability.isAvailable) {
  if (availability.waitlistAvailable) {
    // Offer waitlist
  } else {
    // Show error
  }
  return;
}
final reservation = await reservationService.createReservation(...);

// ❌ BAD: Create reservation, then check availability
final reservation = await reservationService.createReservation(...);
// Might fail if unavailable, wastes resources
```

### 3. Handle Payment Errors Gracefully

```dart
// ✅ GOOD: Handle payment errors explicitly
try {
  final reservation = await reservationService.createReservation(
    ticketPrice: 25.0, // Paid reservation
    ...other params
  );
} on Exception catch (e) {
  if (e.toString().contains('Payment')) {
    // Show payment error, allow retry
    showPaymentError('Payment failed. Please try again.');
  } else {
    // Show generic error
    showError('Failed to create reservation.');
  }
}
```

### 4. Use Offline-First Patterns

```dart
// ✅ GOOD: Works offline, syncs when online
final reservations = await reservationService.getUserReservations(
  userId: userId,
);
// Returns local data immediately, merges with cloud if online

// ❌ BAD: Assume online availability
if (!supabaseService.isAvailable) {
  throw Exception('Offline - cannot get reservations');
}
```

### 5. Respect Privacy Architecture

```dart
// ✅ GOOD: Services handle agentId conversion internally
final reservation = await reservationService.createReservation(
  userId: 'user-123', // User ID
  ...other params
);
// Service converts to agentId internally

// ❌ BAD: Try to use agentId directly
final reservation = await reservationService.createReservation(
  agentId: 'agent-456', // Wrong - should use userId
  ...other params
);
```

---

## Summary

The Reservation System API provides:

- ✅ **Complete CRUD operations** for reservations
- ✅ **Availability checking** to prevent overbooking
- ✅ **Rate limiting** to prevent abuse
- ✅ **Waitlist management** for full capacity
- ✅ **Payment processing** for paid reservations
- ✅ **Analytics** for users and businesses
- ✅ **Notifications** for confirmations, reminders, cancellations
- ✅ **Offline-first** operation
- ✅ **Privacy by design** (agentId system)
- ✅ **Quantum integration** (automatic quantum state creation)
- ✅ **Knot theory integration** (fabric creation for groups)

All services are designed to work together seamlessly while maintaining privacy, offline-first operation, and graceful degradation.

---

**Next Steps:**
- See [Architecture Documentation](./ARCHITECTURE.md) for system architecture
- See [Developer Guide](./DEVELOPER_GUIDE.md) for implementation details
- See [User Guide](./USER_GUIDE.md) for user-facing features
- See [Business Guide](./BUSINESS_GUIDE.md) for business features
