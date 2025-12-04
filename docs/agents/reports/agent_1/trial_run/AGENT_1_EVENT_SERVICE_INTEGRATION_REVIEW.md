# Agent 1: Event Service Integration Review

**Date:** November 22, 2025, 09:28 PM CST  
**Task:** Week 2, Task 2.1 - Review Event Service Integration  
**Status:** ✅ Complete

---

## 📋 **Review Summary**

### **ExpertiseEventService Review**

**File:** `lib/core/services/expertise_event_service.dart`

#### **1. registerForEvent() Method**
- ✅ **Exists:** Method is present at line 142
- ✅ **Signature:** `Future<void> registerForEvent(ExpertiseEvent event, UnifiedUser user)`
- ✅ **Functionality:**
  - Validates user can attend (`event.canUserAttend(user.id)`)
  - Updates attendee IDs and count
  - Saves updated event
  - Proper error handling

**Current Implementation:**
```dart
Future<void> registerForEvent(ExpertiseEvent event, UnifiedUser user) async {
  // Validates user can attend
  // Updates attendeeIds and attendeeCount
  // Saves event
}
```

#### **2. Payment Integration Points Needed**

**Current State:**
- `registerForEvent()` does NOT accept payment information
- Does NOT distinguish between paid and free events
- Does NOT track payment status for attendees

**Integration Requirements:**
1. **For Paid Events:**
   - Payment must be completed before registration
   - Payment status should be tracked
   - Registration should only happen after successful payment

2. **For Free Events:**
   - Registration can happen directly (current behavior)
   - No payment required

3. **Coordination Note:**
   - **Agent 1 CANNOT modify ExpertiseEventService** (Agent 2 owns it per FILE_OWNERSHIP_MATRIX)
   - **Solution:** Create `PaymentEventService` bridge service that:
     - Calls `PaymentService.purchaseEventTicket()` for paid events
     - Calls `ExpertiseEventService.registerForEvent()` after payment success
     - Handles the coordination between payment and registration

#### **3. ExpertiseEvent Model Review**

**File:** `lib/core/models/expertise_event.dart`

**Fields Verified:**
- ✅ `price` field exists (line 25: `final double? price;`)
- ✅ `isPaid` field exists (line 26: `final bool isPaid;`)
- ✅ `maxAttendees` field exists (line 18: `final int maxAttendees;`)
- ✅ `attendeeCount` field exists (line 17: `final int attendeeCount;`)
- ✅ `attendeeIds` field exists (line 16: `final List<String> attendeeIds;`)

**Model is ready for payment integration** - all required fields exist.

---

## 🔗 **Integration Approach**

### **Recommended Solution: PaymentEventService Bridge**

Since Agent 1 cannot modify `ExpertiseEventService` (Agent 2 owns it), create a bridge service:

**File:** `lib/core/services/payment_event_service.dart` (Agent 1 owns this)

**Purpose:**
- Coordinates between `PaymentService` and `ExpertiseEventService`
- Handles payment + registration flow for paid events
- Handles direct registration for free events

**Flow:**
1. **Paid Event:**
   - Call `PaymentService.purchaseEventTicket()`
   - On success: Call `ExpertiseEventService.registerForEvent()`
   - Track payment status

2. **Free Event:**
   - Call `ExpertiseEventService.registerForEvent()` directly
   - No payment required

---

## ✅ **Integration Requirements Documented**

### **For Agent 2 (Future Enhancement):**
- Consider adding `registerForEventWithPayment()` method to `ExpertiseEventService`
- Or: Accept optional `Payment` parameter in `registerForEvent()`
- This would simplify the bridge service

### **For Agent 1 (Current Implementation):**
- Create `PaymentEventService` bridge
- Handle payment + registration coordination
- Track payment status separately (in Payment model)

---

## 📝 **Integration Tests Needed**

1. **Test paid event registration:**
   - Payment succeeds → Registration succeeds
   - Payment fails → Registration does NOT happen

2. **Test free event registration:**
   - Registration succeeds without payment

3. **Test capacity limits:**
   - Event full → Payment/Registration fails appropriately

---

**Last Updated:** November 22, 2025, 09:28 PM CST  
**Status:** Review Complete - Ready for Task 2.2

