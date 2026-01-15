# Phase 4.1: Payment Holds & Queue Processing - Deferred

**Date:** January 7, 2026  
**Status:** ⏳ **DEFERRED** - Requires design decisions and backend API support  
**Priority:** P1 - Critical for limited-seat events, but complex implementation

---

## 🔴 **Critical Issue: Payment Holds & Queue Processing**

### **Problem Statement:**

Phase 4.1 deliverables include payment hold mechanism for limited seats, but this requires:
1. **Detection logic** - How to determine if reservation has limited seats
2. **Backend API support** - Stripe payment intents with `capture_method: manual` require backend API
3. **Queue integration** - Integration between `ReservationService`, `PaymentService`, and `ReservationTicketQueueService`
4. **Queue processing logic** - When/how to process queue and capture payments

### **What's Missing:**

#### **1. Limited Seats Detection Logic**
- **Question:** How to determine if reservation has limited seats?
  - **Events:** Check `event.maxAttendees > 0` and `availableCapacity < ticketCount`?
  - **Spots/Businesses:** Always unlimited, or check business capacity settings?
  - **Decision needed:** Should ALL event reservations use holds, or only when capacity is limited?
- **Current status:** `ReservationService.createReservation()` processes payment immediately (no detection)
- **Required:** Logic to detect limited seats and route to queue flow vs. direct payment flow

#### **2. Payment Intent with Manual Capture**
- **Current status:** `PaymentService.processReservationPayment()` creates mock payment intents (TODO: backend API)
- **Required:** Backend API to create Stripe payment intents with `capture_method: manual`
- **Required:** `PaymentService` method to create payment intent with manual capture (not currently supported)
- **Required:** `PaymentService` method to capture payment intent later (when tickets allocated)

#### **3. Queue Integration**
- **Current status:** `ReservationTicketQueueService` exists but NOT integrated with `ReservationService.createReservation()`
- **Required:** Route limited-seat paid reservations through queue
- **Required:** Link payment intent to queue entry
- **Required:** Process queue when online and capture payments only if allocated

#### **4. Queue Processing Logic**
- **Current status:** `ReservationTicketQueueService.processTicketQueue()` exists but payment capture not integrated
- **Required:** Background/periodic queue processing
- **Required:** Payment capture on successful allocation
- **Required:** Payment hold release on failed allocation
- **Required:** Refund processing for failed allocations (if already charged)

---

## 📋 **Design Questions That Need Resolution:**

1. **Limited Seats Detection:**
   - Should ALL event reservations use payment holds, or only when `availableCapacity < ticketCount` at creation time?
   - Should spots/businesses with capacity limits also use payment holds?
   - How to detect capacity limits for spots/businesses? (Business capacity model not yet implemented)

2. **Payment Hold Scope:**
   - Is this ONLY for events with `maxAttendees > 0`, or also for spots/businesses?
   - Should free reservations (no payment) still use queue for limited seats?

3. **Manual Capture API:**
   - Does backend API support `capture_method: manual`?
   - When will backend API be available?
   - What's the API contract for creating payment intents with manual capture?

4. **Queue Processing Timing:**
   - When should queue be processed? (On app start? Periodically? On sync?)
   - Should queue processing be automatic or manual?
   - How to handle queue processing failures?

5. **Payment History:**
   - What exactly is "payment history"?
   - Helper method to get payment for reservation?
   - UI feature to view payment history?
   - Both?

---

## 🔄 **Flow (For Limited Seats/Tickets):**

```
User creates reservation (limited seats)
    ↓
Get atomic timestamp (AtomicClockService) ✅ DONE
    ↓
Check if business requires fee ✅ DONE
    ├─ Free → Queue ticket request with atomic timestamp ⏳ MISSING: Queue integration
    └─ Paid → Create payment intent (HOLD, not charged) ⏳ MISSING: Manual capture API
        ├─ Ticket price * ticket count ✅ DONE
        ├─ Deposit (if required) ✅ DONE (parameter exists)
        ├─ Platform fee (10% of ticket fee) ✅ DONE
        └─ Platform deposit fee (10% of deposit) ✅ DONE
    ↓
Queue ticket request with atomic timestamp ⏳ MISSING: Queue integration
    ↓
Show confirmation (optimistic UI) ⏳ MISSING: Queue confirmation
    ↓
When online → Process queue (sort by atomic timestamp) ⏳ MISSING: Queue processing
    ↓
Check if tickets available for this position ⏳ MISSING: Allocation logic
    ├─ YES → Allocate tickets, charge payment (capture intent) ⏳ MISSING: Capture API
    └─ NO → Release payment hold, refund if already charged, notify user ⏳ MISSING: Hold release
```

---

## 📊 **Current Status:**

### **✅ Completed:**
- Payment integration (basic flow)
- Free/paid reservation flow
- SPOTS fee calculation (10%)
- Multiple tickets support
- Deposit amount parameter (accepted in PaymentService)
- Integration tests (free/paid flows)

### **⏳ Deferred (This Document):**
- Payment hold mechanism (for limited seats)
- Atomic timestamp integration (for queue ordering) - *Note: Atomic timestamps are used, but queue routing not integrated*
- Queue-based payment processing (charge only if allocated)
- Payment hold release (if allocation fails)

### **⏳ Incomplete (But Not Deferred):**
- Deposit handling tests
- Refund handling (integration with cancelReservation)
- Payment history (need clarification on requirements)

---

## 🎯 **When to Return:**

**Return to this when:**
1. Backend API supports `capture_method: manual` for payment intents
2. Design decisions made on limited seats detection
3. Queue processing timing/strategy decided
4. Ready to implement limited-seat event reservation flow

**Prerequisites:**
- Backend API contract for manual capture
- Clear detection logic for limited seats
- Queue processing strategy defined
- Test environment for queue/payment integration

---

## 🔗 **Related Documents:**

- `docs/plans/reservations/RESERVATION_SYSTEM_IMPLEMENTATION_PLAN.md` - Phase 4.1 section (lines 1928-2036)
- `docs/plans/reservations/RESERVATION_SYSTEM_IMPLEMENTATION_PLAN.md` - Phase 1.3 Ticket Queue Service (lines 1227-1333)
- `lib/core/services/reservation_ticket_queue_service.dart` - Queue service exists
- `lib/core/services/payment_service.dart` - Payment service (needs manual capture support)
- `lib/core/services/reservation_service.dart` - Reservation service (needs queue routing)

---

## 📝 **Implementation Notes:**

**Key Files to Modify When Resuming:**
- `lib/core/services/payment_service.dart` - Add manual capture methods
- `lib/core/services/reservation_service.dart` - Add queue routing logic
- `lib/core/services/reservation_ticket_queue_service.dart` - Add payment integration
- Backend API - Add manual capture endpoint

**Key Design Decisions Needed:**
- Limited seats detection logic
- Queue processing timing/strategy
- Payment capture timing
- Failed allocation handling
