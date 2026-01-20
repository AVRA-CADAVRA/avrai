---
name: reservation-system-patterns
description: Guides reservation system patterns: quantum states, availability calculation, check-in services, payment integration. Use when implementing reservations, availability management, or reservation workflows.
---

# Reservation System Patterns

## Core Components

### Reservation Quantum Service
Creates quantum states for reservations and calculates compatibility.

### Reservation Availability Service
Manages availability, capacity, and booking conflicts.

### Reservation Service
Core reservation management (create, update, cancel).

### Check-In Service
Handles reservation check-in and verification.

## Reservation Creation Pattern

```dart
/// Create reservation with quantum state
Future<Reservation> createReservation({
  required String userId,
  required String eventId,
  required DateTime reservationTime,
  required int ticketCount,
}) async {
  // Step 1: Check availability
  final availability = await _availabilityService.checkAvailability(
    eventId: eventId,
    requestedTime: reservationTime,
    ticketCount: ticketCount,
  );
  
  if (!availability.hasCapacity) {
    throw ReservationException('Not enough capacity');
  }
  
  // Step 2: Create quantum state
  final quantumState = await _quantumService.createReservationQuantumState(
    userId: userId,
    eventId: eventId,
    reservationTime: reservationTime,
  );
  
  // Step 3: Calculate compatibility
  final compatibility = await _quantumService.calculateReservationCompatibility(
    reservationState: quantumState,
    idealState: await _getIdealEventState(eventId),
  );
  
  // Step 4: Create reservation
  final reservation = Reservation(
    id: generateId(),
    agentId: await _getAgentId(userId),
    type: ReservationType.event,
    targetId: eventId,
    reservationTime: reservationTime,
    ticketCount: ticketCount,
    quantumState: quantumState,
    atomicTimestamp: await _atomicClock.getAtomicTimestamp(),
  );
  
  // Step 5: Save reservation
  await _reservationService.saveReservation(reservation);
  
  return reservation;
}
```

## Availability Calculation

```dart
/// Check availability for event
Future<AvailabilityResult> checkAvailability({
  required String eventId,
  required DateTime requestedTime,
  required int ticketCount,
}) async {
  final event = await _eventService.getEvent(eventId);
  
  // Get existing reservations
  final existingReservations = await _reservationService.getReservationsForEvent(
    eventId: eventId,
    timeWindow: _getTimeWindow(requestedTime),
  );
  
  // Calculate available capacity
  final reservedTickets = existingReservations
      .where((r) => r.status == ReservationStatus.confirmed)
      .fold(0, (sum, r) => sum + r.ticketCount);
  
  final availableTickets = event.capacity - reservedTickets;
  final hasCapacity = availableTickets >= ticketCount;
  
  return AvailabilityResult(
    hasCapacity: hasCapacity,
    availableTickets: availableTickets,
    totalCapacity: event.capacity,
    reservedTickets: reservedTickets,
  );
}
```

## Quantum State Integration

```dart
/// Create reservation quantum state
Future<QuantumEntityState> createReservationQuantumState({
  required String userId,
  required String eventId,
  required DateTime reservationTime,
}) async {
  // Create full quantum entanglement state:
  // |ψ_reservation⟩ = |ψ_user⟩ ⊗ |ψ_event⟩ ⊗ |ψ_location⟩ ⊗ |ψ_timing⟩
  
  final userState = await _quantumService.getUserQuantumState(userId);
  final eventState = await _quantumService.getEventQuantumState(eventId);
  final locationState = await _quantumService.getLocationQuantumState(eventId);
  final timingState = await _quantumService.createTimingQuantumState(reservationTime);
  
  // Entangle all states
  return await _quantumService.entangleStates([
    userState,
    eventState,
    locationState,
    timingState,
  ]);
}
```

## Reference

- `lib/core/services/reservation_service.dart`
- `lib/core/services/reservation_quantum_service.dart`
- `lib/core/services/reservation_availability_service.dart`
- `docs/plans/reservations/`
