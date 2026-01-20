---
name: event-system-implementation
description: Guides event system implementation: creation, ticketing, partnerships, sponsorships, check-in, analytics. Use when implementing events, event management, or event-related features.
---

# Event System Implementation

## Core Components

### Event Service
Core event management (create, update, delete, retrieve).

### Event Ticketing Service
Manages tickets, pricing, sales.

### Event Partnership Service
Handles multi-party partnerships and revenue splits.

### Event Check-In Service
Manages event attendance and check-in.

## Event Creation Pattern

```dart
/// Create event
Future<Event> createEvent({
  required String hostId,
  required String businessId,
  required EventDetails details,
}) async {
  // Validate host has expertise
  final expertise = await _expertiseService.getExpertise(
    userId: hostId,
    category: details.category,
  );
  
  if (expertise.level < ExpertiseLevel.localExpert) {
    throw EventException('Host must be local expert to create events');
  }
  
  // Create event
  final event = Event(
    id: generateId(),
    hostId: hostId,
    businessId: businessId,
    title: details.title,
    description: details.description,
    category: details.category,
    eventTime: details.eventTime,
    capacity: details.capacity,
    ticketPrice: details.ticketPrice,
    status: EventStatus.scheduled,
    createdAt: DateTime.now(),
  );
  
  // Save event
  await _eventService.saveEvent(event);
  
  // Create quantum state for matching
  final quantumState = await _quantumService.createEventQuantumState(event);
  await _eventService.updateQuantumState(event.id, quantumState);
  
  return event;
}
```

## Event Ticketing

```dart
/// Sell event tickets
Future<TicketSaleResult> sellTickets({
  required String eventId,
  required int ticketCount,
  required PaymentMethod paymentMethod,
}) async {
  final event = await _eventService.getEvent(eventId);
  
  // Check availability
  final availability = await _reservationService.checkAvailability(
    eventId: eventId,
    ticketCount: ticketCount,
  );
  
  if (!availability.hasCapacity) {
    return TicketSaleResult.failure('Not enough tickets available');
  }
  
  // Calculate total (includes platform fee)
  final subtotal = event.ticketPrice * ticketCount;
  final platformFee = subtotal * 0.10;
  final total = subtotal + platformFee;
  
  // Process payment
  final paymentResult = await _paymentService.processPayment(
    amount: total,
    paymentMethod: paymentMethod,
  );
  
  if (paymentResult.isSuccess) {
    // Create reservation
    final reservation = await _reservationService.createReservation(
      eventId: eventId,
      ticketCount: ticketCount,
      paymentIntentId: paymentResult.transactionId,
    );
    
    return TicketSaleResult.success(reservation);
  } else {
    return TicketSaleResult.failure(paymentResult.error);
  }
}
```

## Event Partnerships

```dart
/// Add partner to event
Future<Partnership> addEventPartner({
  required String eventId,
  required String partnerId,
  required double revenuePercentage,
}) async {
  final event = await _eventService.getEvent(eventId);
  
  // Calculate compatibility (70%+ required)
  final compatibility = await _partnershipService.calculateCompatibility(
    userId: partnerId,
    businessId: event.businessId,
    event: event,
  );
  
  if (compatibility < 0.70) {
    throw PartnershipException('Compatibility below 70% threshold');
  }
  
  // Create partnership
  final partnership = await _partnershipService.createPartnership(
    eventId: eventId,
    partnerId: partnerId,
    revenuePercentage: revenuePercentage,
  );
  
  // Lock revenue split before event starts
  await _partnershipService.lockRevenueSplits(eventId);
  
  return partnership;
}
```

## Event Check-In

```dart
/// Check in to event
Future<CheckInResult> checkInToEvent({
  required String reservationId,
  required String checkInCode,
}) async {
  final reservation = await _reservationService.getReservation(reservationId);
  final event = await _eventService.getEvent(reservation.targetId);
  
  // Verify check-in code
  if (checkInCode != event.checkInCode) {
    return CheckInResult.failure('Invalid check-in code');
  }
  
  // Check reservation status
  if (reservation.status != ReservationStatus.confirmed) {
    return CheckInResult.failure('Reservation not confirmed');
  }
  
  // Perform check-in
  await _checkInService.checkIn(reservationId);
  
  // Update reservation status
  await _reservationService.updateStatus(
    reservationId: reservationId,
    status: ReservationStatus.checkedIn,
  );
  
  return CheckInResult.success();
}
```

## Reference

- `lib/core/services/expertise_event_service.dart`
- `lib/core/services/reservation_service.dart`
- `docs/plans/monetization_business_expertise/`
