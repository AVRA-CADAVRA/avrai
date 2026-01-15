# Reservation System Developer Guide

**Date:** January 6, 2026  
**Phase:** Phase 9.1 - Documentation  
**Status:** ✅ Complete  
**Version:** 1.0

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Architecture Overview](#architecture-overview)
3. [Core Services & Patterns](#core-services--patterns)
4. [Implementation Patterns](#implementation-patterns)
5. [Dependency Injection](#dependency-injection)
6. [Error Handling](#error-handling)
7. [Testing Patterns](#testing-patterns)
8. [Code Organization](#code-organization)
9. [Best Practices](#best-practices)
10. [Common Development Tasks](#common-development-tasks)
11. [Troubleshooting](#troubleshooting)
12. [Reference](#reference)

---

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.0+ required
- **Dart SDK**: 3.0+ required
- **IDE**: VS Code or Android Studio recommended
- **Supabase Account**: For cloud sync (optional, offline-first works without it)
- **Stripe Account**: For payment processing (optional)

### Project Structure

```
lib/
├── core/
│   ├── models/
│   │   └── reservation.dart          # Reservation models
│   ├── services/
│   │   ├── reservation_service.dart  # Main reservation service
│   │   ├── reservation_availability_service.dart
│   │   ├── reservation_rate_limit_service.dart
│   │   ├── reservation_waitlist_service.dart
│   │   ├── reservation_analytics_service.dart
│   │   ├── business_reservation_analytics_service.dart
│   │   ├── reservation_notification_service.dart
│   │   ├── reservation_calendar_service.dart      # Phase 10.2: Calendar integration
│   │   ├── reservation_recurrence_service.dart     # Phase 10.3: Recurring reservations
│   │   └── reservation_sharing_service.dart       # Phase 10.4: Sharing & transfer
│   ├── controllers/
│   │   └── reservation_creation_controller.dart  # Workflow orchestration
│   └── theme/
│       ├── colors.dart               # AppColors (MANDATORY)
│       └── app_theme.dart            # AppTheme (MANDATORY)
├── presentation/
│   ├── pages/
│   │   └── reservations/
│   │       ├── create_reservation_page.dart
│   │       ├── reservation_detail_page.dart
│   │       └── my_reservations_page.dart
│   ├── widgets/
│   │   └── reservations/
│   │       ├── reservation_form_widget.dart
│   │       ├── reservation_card_widget.dart
│   │       └── time_slot_picker_widget.dart
│   └── blocs/
│       └── reservations/             # BLoC pattern (if using)
├── data/
│   ├── datasources/
│   │   ├── local/                    # Local storage (Sembast)
│   │   └── remote/                   # Cloud sync (Supabase)
│   └── repositories/
└── injection_container.dart          # Dependency injection (GetIt)
```

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd AVRAI
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase** (optional)
   - Create `.env` file with Supabase credentials
   - See `README.md` for Supabase setup

4. **Run the app**
   ```bash
   flutter run
   ```

---

## Architecture Overview

### Core Principles

The Reservation System follows these core principles:

1. **Offline-First**: All operations work offline, syncing when online
2. **Privacy by Design**: Uses `agentId` (not `userId`) for internal tracking
3. **Foundational Architecture**: AI2AI/knot/quantum integration from foundation (not added later)
4. **Single Source of Truth**: Reservations leverage spot data (no duplicate storage)
5. **Performance Optimization**: Uses cached geohash and quantum states from spots

### Architecture Layers

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Pages, Widgets, BLoCs)           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Controller Layer            │
│  (Workflow Orchestration)           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│          Service Layer              │
│  (Business Logic)                   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Repository Layer            │
│  (Data Access)                      │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│       Data Source Layer             │
│  (Local Storage, Cloud Sync)        │
└─────────────────────────────────────┘
```

### Service Dependencies

```
ReservationService
├── AtomicClockService (for queue ordering)
├── ReservationQuantumService (for quantum state)
├── AgentIdService (for privacy)
├── StorageService (for offline-first)
├── SupabaseService (for cloud sync)
├── PaymentService (optional, for paid reservations)
├── RefundService (optional, for refunds)
└── ReservationAnalyticsService (optional, for analytics)
```

### Foundational Integration

**CRITICAL:** AI2AI/knot/quantum integration is **built from foundation**, not added as enhancements.

**Implementation Flow:**
```
ReservationService.createReservation()
    ↓
├─ QuantumMatchingController.execute()
│  └─ Calculates compatibility (user ↔ spot)
│
├─ ReservationQuantumService.createReservationQuantumState()
│  └─ Creates reservation-specific quantum state
│
├─ KnotFabricService (if group, partySize > 1)
│  └─ Creates fabric immediately
│
└─ Reservation created with:
   ├─ targetId: spotId (CONNECTION PRESERVED)
   ├─ quantumState: from ReservationQuantumService
   └─ All knot/string/fabric data
```

See [Architecture Documentation](./ARCHITECTURE.md) for detailed architecture.

---

## Core Services & Patterns

### ReservationService

**Purpose:** Main service for reservation CRUD operations.

**Key Methods:**
- `createReservation()` - Creates a new reservation
- `getUserReservations()` - Gets user's reservations
- `getReservationsForTarget()` - Gets reservations for a spot/business/event
- `updateReservation()` - Updates an existing reservation
- `cancelReservation()` - Cancels a reservation

**Pattern:** Orchestrates multiple services (payment, quantum, analytics)

**Example:**
```dart
final reservationService = GetIt.instance<ReservationService>();

final reservation = await reservationService.createReservation(
  userId: 'user-123',
  type: ReservationType.spot,
  targetId: 'spot-456',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  partySize: 2,
  ticketPrice: 25.0,
);
```

### ReservationAvailabilityService

**Purpose:** Checks availability and manages capacity.

**Key Methods:**
- `checkAvailability()` - Checks if target is available
- `getCapacity()` - Gets current capacity
- `reserveCapacity()` - Reserves capacity atomically
- `releaseCapacity()` - Releases capacity

**Pattern:** Prevents overbooking with atomic capacity reservation

**Example:**
```dart
final availability = await availabilityService.checkAvailability(
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  partySize: 2,
);

if (availability.isAvailable) {
  // Proceed with reservation creation
}
```

### ReservationRateLimitService

**Purpose:** Enforces rate limiting to prevent abuse.

**Key Methods:**
- `checkRateLimit()` - Checks if user can create reservation
- `recordReservation()` - Records reservation for rate limiting

**Pattern:** Privacy-protected rate limiting (uses agentId)

**Example:**
```dart
final rateLimit = await rateLimitService.checkRateLimit(
  userId: 'user-123',
  type: ReservationType.spot,
  targetId: 'spot-456',
);

if (!rateLimit.allowed) {
  // Show rate limit error
}
```

### ReservationWaitlistService

**Purpose:** Manages waitlists when capacity is full.

**Key Methods:**
- `addToWaitlist()` - Adds user to waitlist
- `getWaitlistPosition()` - Gets waitlist position
- `processWaitlist()` - Processes waitlist when capacity available
- `removeFromWaitlist()` - Removes user from waitlist

**Pattern:** Offline-first waitlist with atomic timestamp ordering

**Example:**
```dart
final entry = await waitlistService.addToWaitlist(
  userId: 'user-123',
  type: ReservationType.event,
  targetId: 'event-789',
  reservationTime: DateTime.now().add(Duration(days: 7)),
  ticketCount: 2,
);

print('Waitlist position: ${entry.position}');
```

### ReservationCreationController

**Purpose:** Orchestrates complete reservation creation workflow.

**Key Methods:**
- `execute()` - Executes complete workflow

**Pattern:** Workflow orchestration coordinating multiple services

**Example:**
```dart
final controller = GetIt.instance<ReservationCreationController>();

final result = await controller.execute(
  ReservationCreationInput(
    userId: 'user-123',
    type: ReservationType.spot,
    targetId: 'spot-456',
    reservationTime: DateTime.now().add(Duration(days: 7)),
    partySize: 2,
  ),
);

if (result.success) {
  print('Reservation created: ${result.reservation?.id}');
} else {
  print('Error: ${result.error}');
}
```

**Workflow Steps:**
1. Validate input
2. Check availability
3. Check rate limits
4. Calculate compatibility (quantum matching)
5. Create quantum state
6. Create reservation
7. Process payment (if applicable)
8. Send notifications
9. Return result

See [API Documentation](./API.md) for detailed API reference.

---

### ReservationCalendarService

**Phase:** 10.2 - Calendar Integration  
**Purpose:** Integrates reservations with device calendar (iOS Calendar, Google Calendar).

**Key Methods:**
- `syncReservationToCalendar()` - Sync reservation to device calendar
- `syncCalendarToReservations()` - Sync calendar events back to reservations (stubbed)
- `getOptimalTimeSuggestions()` - Get optimal time suggestions (placeholder)
- `detectConflicts()` - Detect calendar conflicts (placeholder)

**Dependencies:**
- `ReservationService` - Core reservation operations
- `ReservationQuantumService` - Quantum state creation
- `AgentIdService` - Agent ID lookups
- Optional knot services for signature generation

**Example:**
```dart
final calendarService = GetIt.instance<ReservationCalendarService>();

final result = await calendarService.syncReservationToCalendar(
  reservationId: 'reservation-123',
);

if (result.success) {
  print('Synced to calendar: ${result.eventId}');
}
```

**AVRAI Integration:**
- Generates knot signature for calendar event verification
- Embeds quantum state in calendar event metadata
- Uses string evolution for optimal time predictions
- Propagates calendar sync patterns to AI2AI mesh

**Package:** `add_2_calendar: ^2.1.2`

**Note:** Calendar reading is limited by `add_2_calendar` package - users must manually remove calendar events.

---

### ReservationRecurrenceService

**Phase:** 10.3 - Recurring Reservations  
**Purpose:** Manages recurring reservation series and instances.

**Key Methods:**
- `createRecurringSeries()` - Create series of recurring reservations
- `pauseRecurringSeries()` - Pause a recurring series (placeholder)
- `resumeRecurringSeries()` - Resume a paused series (placeholder)
- `cancelRecurringSeries()` - Cancel a recurring series (placeholder)

**Dependencies:**
- `ReservationService` - Core reservation operations
- `ReservationQuantumService` - Quantum state creation
- `AgentIdService` - Agent ID lookups
- Optional knot services for series signatures

**RecurrencePattern:**
```dart
final pattern = RecurrencePattern(
  type: RecurrencePatternType.weekly,
  interval: 1,
  daysOfWeek: [5], // Friday
  maxOccurrences: 10,
);
```

**Example:**
```dart
final recurrenceService = GetIt.instance<ReservationRecurrenceService>();

final result = await recurrenceService.createRecurringSeries(
  userId: 'user-123',
  baseReservation: baseReservation,
  pattern: pattern,
);

if (result.success) {
  print('Created ${result.instanceCount} recurring reservations');
}
```

**AVRAI Integration:**
- Generates knot signature for recurring series
- Creates quantum state for recurring pattern
- Uses string evolution to predict optimal recurrence times
- Creates fabric for group recurring reservations
- Tracks recurring patterns in worldsheet for temporal analysis

---

### ReservationSharingService

**Phase:** 10.4 - Reservation Sharing & Transfer  
**Purpose:** Manages sharing and transferring reservations between users.

**Key Methods:**
- `shareReservation()` - Share reservation with another user
- `transferReservation()` - Transfer ownership to another user
- `getSharedReservations()` - Get all shared reservations (placeholder)
- `revokeSharing()` - Revoke sharing access (placeholder)

**Dependencies:**
- `ReservationService` - Core reservation operations
- `ReservationQuantumService` - Quantum state preservation
- `AgentIdService` - Agent ID lookups
- Optional knot services for signature verification

**SharingPermission:**
```dart
enum SharingPermission {
  readOnly,  // Can view reservation details only
  fullAccess, // Can modify, cancel, etc.
}
```

**Example - Sharing:**
```dart
final sharingService = GetIt.instance<ReservationSharingService>();

final result = await sharingService.shareReservation(
  reservationId: 'reservation-123',
  ownerUserId: 'user-123',
  sharedWithUserId: 'user-456',
  permission: SharingPermission.readOnly,
);
```

**Example - Transfer:**
```dart
final result = await sharingService.transferReservation(
  reservationId: 'reservation-123',
  fromUserId: 'user-123',
  toUserId: 'user-456',
);

if (result.success) {
  print('Transferred - Compatibility: ${result.predictedCompatibility}');
}
```

**AVRAI Integration:**
- Verifies knot signature for sharing/transfer authorization
- Preserves quantum state during sharing/transfer
- Predicts compatibility between users
- Creates fabric for group shared reservations
- Tracks sharing/transfer patterns in worldsheet

**Warning:** Transfer is irreversible - original owner loses all access.

---

## Implementation Patterns

### Privacy Pattern (agentId)

**CRITICAL:** All services use `agentId` (not `userId`) for privacy-protected internal tracking.

**Pattern:**
```dart
// ✅ CORRECT: Service accepts userId, converts internally
Future<Reservation> createReservation({
  required String userId, // User's ID (public)
  // ... other params
}) async {
  // Convert userId → agentId internally
  final agentId = await _agentIdService.getUserAgentId(userId);
  
  // Use agentId for all internal storage/tracking
  final reservation = Reservation(
    agentId: agentId, // CRITICAL: Uses agentId, not userId
    // ... other fields
  );
  
  return reservation;
}
```

**Why:**
- **Privacy**: agentId is privacy-protected, userId is public
- **Tracking**: Internal tracking uses agentId (not exposed to businesses)
- **Compliance**: Meets privacy requirements

### Offline-First Pattern

**CRITICAL:** All operations work offline, syncing when online.

**Pattern:**
```dart
// ✅ CORRECT: Offline-first storage
Future<void> createReservation(...) async {
  // 1. Store locally first (fast, <50ms)
  await _storeReservationLocally(reservation);
  
  // 2. Sync to cloud when online (non-blocking)
  if (_supabaseService.isAvailable) {
    try {
      await _syncReservationToCloud(reservation);
    } catch (e) {
      // Log error, but continue (offline-first)
      developer.log('Failed to sync: $e');
    }
  }
}
```

**Why:**
- **Performance**: Local storage is fast (<50ms)
- **Reliability**: Works offline (no network dependency)
- **User Experience**: No waiting for network requests

### Atomic Capacity Pattern

**CRITICAL:** Prevents overbooking with atomic capacity reservation.

**Pattern:**
```dart
// ✅ CORRECT: Reserve capacity atomically before creating reservation
final reserved = await availabilityService.reserveCapacity(
  type: type,
  targetId: targetId,
  reservationTime: reservationTime,
  ticketCount: ticketCount,
  reservationId: 'pending-${Uuid().v4()}',
);

if (reserved) {
  try {
    final reservation = await reservationService.createReservation(...);
    return reservation;
  } catch (e) {
    // Release capacity if reservation creation fails
    await availabilityService.releaseCapacity(...);
    rethrow;
  }
}
```

**Why:**
- **Prevents Overbooking**: Atomic reservation ensures capacity is reserved
- **Race Condition Safe**: Prevents multiple reservations from same capacity
- **Error Handling**: Releases capacity if reservation creation fails

### Error Handling Pattern

**CRITICAL:** Graceful degradation for optional services.

**Pattern:**
```dart
// ✅ CORRECT: Optional service with graceful degradation
Future<Reservation> createReservation(...) async {
  // Required services throw errors
  final agentId = await _agentIdService.getUserAgentId(userId);
  
  // Optional services degrade gracefully
  double? compatibilityScore;
  if (_quantumService != null) {
    try {
      compatibilityScore = await _quantumService.calculateCompatibility(...);
    } catch (e) {
      developer.log('Compatibility calculation failed: $e');
      // Continue without compatibility score
    }
  }
  
  // Required operations throw errors
  final reservation = Reservation(...);
  await _storeReservationLocally(reservation);
  
  // Optional operations degrade gracefully
  if (_supabaseService.isAvailable) {
    try {
      await _syncReservationToCloud(reservation);
    } catch (e) {
      developer.log('Cloud sync failed: $e');
      // Continue without cloud sync (will retry later)
    }
  }
  
  return reservation;
}
```

**Why:**
- **Required vs Optional**: Required services throw errors, optional services degrade gracefully
- **User Experience**: Users can still create reservations even if optional features fail
- **Resilience**: System continues working even if some features fail

### Logging Pattern

**CRITICAL:** Use `developer.log()` (not `print()` or `debugPrint()`).

**Pattern:**
```dart
// ✅ CORRECT: Use developer.log()
import 'dart:developer' as developer;

developer.log(
  'Creating reservation: type=$type, targetId=$targetId',
  name: 'ReservationService',
);

// ❌ WRONG: Don't use print() or debugPrint()
print('Creating reservation'); // Don't use
debugPrint('Creating reservation'); // Don't use
```

**Why:**
- **Logging Standards**: Mandatory per project rules
- **Production Ready**: developer.log() is production-ready
- **Consistent**: Consistent logging across codebase

### Design Token Pattern

**CRITICAL:** Use `AppColors`/`AppTheme` (not direct `Colors.*`).

**Pattern:**
```dart
// ✅ CORRECT: Use AppColors/AppTheme
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppTheme.textPrimary),
  ),
)

// ❌ WRONG: Don't use direct Colors.*
Container(
  color: Colors.blue, // Don't use
)
```

**Why:**
- **Design Consistency**: Ensures consistent design across app
- **Theme Support**: Supports light/dark themes
- **Maintainability**: Centralized design tokens

---

## Dependency Injection

### GetIt Setup

All services are registered in `injection_container.dart` using GetIt.

**Registration Pattern:**
```dart
// Register services
sl.registerLazySingleton<ReservationService>(() => ReservationService(
  atomicClock: sl<AtomicClockService>(),
  quantumService: sl<ReservationQuantumService>(),
  agentIdService: sl<AgentIdService>(),
  storageService: sl<StorageService>(),
  supabaseService: sl<SupabaseService>(),
  paymentService: sl<PaymentService>(), // Optional
));
```

### Service Injection

**In Services:**
```dart
class MyService {
  final ReservationService _reservationService;
  final ReservationAvailabilityService? _availabilityService;
  
  MyService({
    required ReservationService reservationService,
    ReservationAvailabilityService? availabilityService,
  })  : _reservationService = reservationService,
        _availabilityService = availabilityService;
}
```

**In Controllers:**
```dart
class MyController {
  final ReservationService _reservationService;
  
  MyController() : _reservationService = GetIt.instance<ReservationService>();
}
```

**In Widgets:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reservationService = GetIt.instance<ReservationService>();
    // Use service
  }
}
```

### Optional Services

**Pattern for Optional Services:**
```dart
// Register with null safety
final paymentService = sl.isRegistered<PaymentService>()
    ? sl<PaymentService>()
    : null;

// Use with null checks
if (_paymentService != null) {
  await _paymentService!.processPayment(...);
}
```

---

## Error Handling

### Error Strategy

1. **Required Operations**: Throw exceptions (must succeed)
2. **Optional Operations**: Log errors, continue gracefully (can fail)
3. **User-Facing Errors**: Provide user-friendly messages
4. **Developer Errors**: Log with context for debugging

### Error Handling Patterns

**Required Operations (Throw Errors):**
```dart
// ✅ CORRECT: Throw errors for required operations
Future<Reservation> createReservation(...) async {
  try {
    // Required: Must succeed
    final agentId = await _agentIdService.getUserAgentId(userId);
    final reservation = Reservation(...);
    await _storeReservationLocally(reservation);
    return reservation;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to create reservation: $e',
      name: _logName,
      error: e,
      stackTrace: stackTrace,
    );
    rethrow; // Re-throw for caller to handle
  }
}
```

**Optional Operations (Graceful Degradation):**
```dart
// ✅ CORRECT: Graceful degradation for optional operations
Future<void> createReservation(...) async {
  // Required operations
  final reservation = await _createReservation(...);
  
  // Optional: Analytics (can fail)
  if (_analyticsService != null) {
    try {
      await _analyticsService!.trackReservationCreated(...);
    } catch (e) {
      developer.log('Analytics tracking failed: $e');
      // Continue without analytics
    }
  }
  
  // Optional: Notifications (can fail)
  if (_notificationService != null) {
    try {
      await _notificationService!.sendConfirmation(reservation);
    } catch (e) {
      developer.log('Notification failed: $e');
      // Continue without notification
    }
  }
}
```

**User-Facing Errors:**
```dart
// ✅ CORRECT: Provide user-friendly error messages
try {
  final reservation = await reservationService.createReservation(...);
} on Exception catch (e) {
  String userMessage;
  if (e.toString().contains('Payment')) {
    userMessage = 'Payment failed. Please check your payment method.';
  } else if (e.toString().contains('capacity')) {
    userMessage = 'No capacity available. Would you like to join the waitlist?';
  } else {
    userMessage = 'Failed to create reservation. Please try again.';
  }
  showError(userMessage);
}
```

### Error Types

**Reservation Errors:**
- `Exception('Payment processing failed')` - Payment service failed
- `Exception('Reservation validation failed')` - Invalid reservation data
- `Exception('Insufficient capacity')` - Not enough capacity available

**Rate Limiting Errors:**
- `RateLimitCheckResult.denied()` - Rate limit exceeded (includes reason and retry time)

**Availability Errors:**
- `AvailabilityResult.unavailable()` - Not available (includes reason and waitlist availability)

---

## Testing Patterns

### Unit Tests

**Pattern:**
```dart
// ✅ CORRECT: Test service behavior
void main() {
  group('ReservationService', () {
    late ReservationService service;
    late MockStorageService mockStorage;
    late MockAgentIdService mockAgentId;
    
    setUp(() {
      mockStorage = MockStorageService();
      mockAgentId = MockAgentIdService();
      service = ReservationService(
        storageService: mockStorage,
        agentIdService: mockAgentId,
        // ... other dependencies
      );
    });
    
    test('should create reservation successfully', () async {
      // Arrange
      when(() => mockAgentId.getUserAgentId(any()))
          .thenAnswer((_) async => 'agent-123');
      when(() => mockStorage.save(any(), any()))
          .thenAnswer((_) async => {});
      
      // Act
      final reservation = await service.createReservation(
        userId: 'user-123',
        type: ReservationType.spot,
        targetId: 'spot-456',
        reservationTime: DateTime.now().add(Duration(days: 7)),
        partySize: 2,
      );
      
      // Assert
      expect(reservation, isNotNull);
      expect(reservation.agentId, equals('agent-123'));
      verify(() => mockStorage.save(any(), any())).called(1);
    });
  });
}
```

### Integration Tests

**Pattern:**
```dart
// ✅ CORRECT: Test integration between services
void main() {
  group('Reservation Integration', () {
    test('should create reservation with payment', () async {
      // Setup real services
      final reservationService = GetIt.instance<ReservationService>();
      final paymentService = GetIt.instance<PaymentService>();
      
      // Create reservation with payment
      final reservation = await reservationService.createReservation(
        userId: 'user-123',
        ticketPrice: 25.0,
        // ... other params
      );
      
      // Verify payment was processed
      expect(reservation.status, ReservationStatus.confirmed);
      expect(reservation.metadata['paymentId'], isNotNull);
    });
  });
}
```

See project test files for more examples.

---

## Code Organization

### File Naming

- **Services**: `reservation_service.dart`
- **Controllers**: `reservation_creation_controller.dart`
- **Models**: `reservation.dart`
- **Pages**: `create_reservation_page.dart`
- **Widgets**: `reservation_form_widget.dart`

### Directory Structure

```
lib/
├── core/
│   ├── models/              # Data models
│   ├── services/            # Business logic services
│   ├── controllers/         # Workflow orchestration
│   └── theme/               # Design tokens
├── presentation/
│   ├── pages/               # Full pages
│   ├── widgets/             # Reusable widgets
│   └── blocs/               # State management (if using BLoC)
├── data/
│   ├── datasources/         # Data sources (local/remote)
│   └── repositories/        # Repository implementations
└── injection_container.dart # Dependency injection
```

### Code Style

Follow **Flutter/Dart style guide**:
- **Naming**: `camelCase` for variables/methods, `PascalCase` for classes
- **Indentation**: 2 spaces
- **Line length**: 80 characters (soft limit)
- **Imports**: Grouped (dart, package, relative)

---

## Best Practices

### Service Design

✅ **DO:**
- Make services focused (single responsibility)
- Use dependency injection
- Handle errors gracefully
- Log operations with context
- Support offline-first

❌ **DON'T:**
- Mix concerns (business logic + UI)
- Use global state
- Swallow errors silently
- Use `print()` for logging
- Assume network availability

### Privacy & Security

✅ **DO:**
- Use `agentId` for internal tracking
- Accept `userId` in public APIs
- Validate all inputs
- Sanitize user data before sharing

❌ **DON'T:**
- Expose `agentId` to external systems
- Store sensitive data unencrypted
- Trust user input without validation
- Share user data without consent

### Performance

✅ **DO:**
- Store data locally first (offline-first)
- Sync to cloud asynchronously (non-blocking)
- Cache frequently accessed data
- Use lazy loading for large datasets

❌ **DON'T:**
- Block UI on network requests
- Fetch all data upfront
- Store unnecessary data
- Make synchronous network calls

### Testing

✅ **DO:**
- Write unit tests for services
- Write integration tests for workflows
- Test error handling
- Test offline scenarios

❌ **DON'T:**
- Skip tests for complex logic
- Test implementation details (test behavior)
- Ignore edge cases
- Test with mocks only (test with real services when possible)

---

## Common Development Tasks

### Adding a New Service

1. **Create service class**
   ```dart
   class MyNewService {
     static const String _logName = 'MyNewService';
     
     MyNewService({
       // Dependencies
     });
     
     Future<Result> doSomething() async {
       // Implementation
     }
   }
   ```

2. **Register in dependency injection**
   ```dart
   // In injection_container.dart
   sl.registerLazySingleton<MyNewService>(() => MyNewService(
     // Dependencies
   ));
   ```

3. **Write tests**
   ```dart
   // In test/
   group('MyNewService', () {
     test('should do something', () async {
       // Test implementation
     });
   });
   ```

### Adding a New Model

1. **Create model class**
   ```dart
   class MyModel extends Equatable {
     final String id;
     final String name;
     
     const MyModel({
       required this.id,
       required this.name,
     });
     
     @override
     List<Object?> get props => [id, name];
     
     Map<String, dynamic> toJson() {
       return {
         'id': id,
         'name': name,
       };
     }
     
     factory MyModel.fromJson(Map<String, dynamic> json) {
       return MyModel(
         id: json['id'] as String,
         name: json['name'] as String,
       );
     }
   }
   ```

2. **Add tests**
   ```dart
   test('should serialize and deserialize correctly', () {
     final model = MyModel(id: '1', name: 'Test');
     final json = model.toJson();
     final restored = MyModel.fromJson(json);
     expect(restored, equals(model));
   });
   ```

### Adding a New Page

1. **Create page class**
   ```dart
   class MyPage extends StatefulWidget {
     const MyPage({super.key});
     
     @override
     State<MyPage> createState() => _MyPageState();
   }
   
   class _MyPageState extends State<MyPage> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('My Page')),
         body: Container(),
       );
     }
   }
   ```

2. **Add routing**
   ```dart
   // In app_router.dart
   GoRoute(
     path: '/my-page',
     builder: (context, state) => MyPage(),
   ),
   ```

3. **Use AppColors/AppTheme**
   ```dart
   // ✅ CORRECT
   Container(
     color: AppColors.primary,
     child: Text('Hello', style: TextStyle(color: AppTheme.textPrimary)),
   )
   ```

### Integrating with Quantum Matching

1. **Use QuantumMatchingController**
   ```dart
   final quantumController = GetIt.instance<QuantumMatchingController>();
   
   final matchingResult = await quantumController.execute(
     MatchingInput(
       userId: userId,
       targetType: TargetType.spot,
       targetId: spotId,
     ),
   );
   
   final compatibilityScore = matchingResult.compatibilityScore;
   ```

2. **Create quantum state**
   ```dart
   final quantumService = GetIt.instance<ReservationQuantumService>();
   
   final quantumState = await quantumService.createReservationQuantumState(
     userId: userId,
     spotId: spotId,
     reservationTime: reservationTime,
   );
   ```

### Integrating with Knot Theory

1. **Create fabric for groups**
   ```dart
   if (partySize > 1) {
     final fabricService = GetIt.instance<KnotFabricService>();
     final fabric = await fabricService.createFabric(
       userIds: [userId1, userId2, userId3],
       spotId: spotId,
     );
   }
   ```

2. **Detect string evolution patterns**
   ```dart
   final stringService = GetIt.instance<KnotEvolutionStringService>();
   final patterns = await stringService.detectPatterns(userId);
   ```

---

## Troubleshooting

### Common Issues

#### "Service not registered"

**Problem:** `GetIt.instance<Service>()` throws error.

**Solution:**
1. Check if service is registered in `injection_container.dart`
2. Ensure dependency injection is initialized before use
3. Verify service dependencies are registered

#### "Offline mode not working"

**Problem:** Operations fail when offline.

**Solution:**
1. Verify `StorageService` is registered and working
2. Check that services use offline-first pattern (store locally first)
3. Ensure cloud sync is optional (doesn't block local operations)

#### "Privacy violation"

**Problem:** `userId` is exposed instead of `agentId`.

**Solution:**
1. Verify services convert `userId` → `agentId` internally
2. Check that only `agentId` is stored/used internally
3. Ensure `userId` is only in public APIs (not internal tracking)

#### "Design token violation"

**Problem:** Linter errors for using `Colors.*` directly.

**Solution:**
1. Replace `Colors.*` with `AppColors.*` or `AppTheme.*`
2. Import `colors.dart` and `app_theme.dart`
3. Check design token documentation

#### "Payment processing fails"

**Problem:** Payment service throws errors.

**Solution:**
1. Verify `PaymentService` is registered (optional service)
2. Check Stripe configuration
3. Verify payment service degrades gracefully (doesn't block reservation creation)

---

## Reference

### Documentation

- [Architecture Documentation](./ARCHITECTURE.md) - System architecture
- [API Documentation](./API.md) - API reference
- [User Guide](./USER_GUIDE.md) - User-facing features
- [Business Guide](./BUSINESS_GUIDE.md) - Business-facing features

### Code Examples

- **Service Implementation**: `lib/core/services/reservation_service.dart`
- **Controller Implementation**: `lib/core/controllers/reservation_creation_controller.dart`
- **Page Implementation**: `lib/presentation/pages/reservations/create_reservation_page.dart`
- **Widget Implementation**: `lib/presentation/widgets/reservations/reservation_form_widget.dart`

### External Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **GetIt Documentation**: https://pub.dev/packages/get_it
- **Supabase Documentation**: https://supabase.com/docs

### Project-Specific Rules

- **Design Tokens**: Use `AppColors`/`AppTheme` (MANDATORY)
- **Logging**: Use `developer.log()` (MANDATORY)
- **Privacy**: Use `agentId` for internal tracking (MANDATORY)
- **Offline-First**: All operations work offline (MANDATORY)

---

## Summary

The Reservation System Developer Guide provides:

✅ **Complete Setup Instructions**: Get started quickly  
✅ **Architecture Overview**: Understand the system design  
✅ **Implementation Patterns**: Learn best practices  
✅ **Common Tasks**: Step-by-step guides for common tasks  
✅ **Troubleshooting**: Solutions to common issues  
✅ **Reference**: Links to documentation and examples  

**Key Takeaways:**
- **Offline-First**: All operations work offline
- **Privacy by Design**: Uses agentId for internal tracking
- **Foundational Architecture**: AI2AI/knot/quantum integration from foundation
- **Design Tokens**: Use AppColors/AppTheme (MANDATORY)
- **Logging**: Use developer.log() (MANDATORY)

**Next Steps:**
- Review [Architecture Documentation](./ARCHITECTURE.md) for system design
- Review [API Documentation](./API.md) for API reference
- Start implementing your features using the patterns in this guide

---

**Happy Coding! 🚀**
