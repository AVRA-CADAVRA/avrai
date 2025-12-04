# Payment-Event Integration Guide

**Date:** November 22, 2025, 09:28 PM CST  
**Purpose:** Document integration between payment processing and event registration  
**Status:** ✅ Complete

---

## 🎯 **Overview**

This guide documents how payment processing integrates with event registration in SPOTS. The integration is handled by `PaymentEventService`, which coordinates between `PaymentService` and `ExpertiseEventService`.

---

## 📋 **Architecture**

### **Services Involved:**

1. **PaymentService** (Agent 1)
   - Handles Stripe payment processing
   - Creates payment intents
   - Calculates revenue splits

2. **ExpertiseEventService** (Agent 2)
   - Manages event registration
   - Updates attendee counts
   - Validates event capacity

3. **PaymentEventService** (Agent 1) - **Bridge Service**
   - Coordinates payment + registration flow
   - Handles paid vs free events
   - Ensures payment succeeds before registration

---

## 🔄 **Integration Flow**

### **For Paid Events:**

```
1. User clicks "Purchase Ticket"
   ↓
2. PaymentEventService.processEventPayment()
   ↓
3. PaymentService.purchaseEventTicket()
   - Validates event exists
   - Validates capacity
   - Creates Stripe payment intent
   - Calculates revenue split
   ↓
4. Payment Success?
   ├─ YES → ExpertiseEventService.registerForEvent()
   │         - Updates attendee count
   │         - Adds user to attendee list
   └─ NO → Return error (no registration)
```

### **For Free Events:**

```
1. User clicks "Register"
   ↓
2. PaymentEventService.processEventPayment()
   ↓
3. ExpertiseEventService.registerForEvent()
   - No payment required
   - Direct registration
```

---

## 💻 **Usage Examples**

### **Example 1: Paid Event Registration**

```dart
import 'package:spots/core/services/payment_event_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:get_it/get_it.dart';

// Get services via dependency injection
final paymentEventService = GetIt.instance<PaymentEventService>();
final eventService = GetIt.instance<ExpertiseEventService>();

// Get event and user
final event = await eventService.getEventById('event-123');
final user = GetIt.instance<UnifiedUser>(); // Current user

// Process payment and registration
final result = await paymentEventService.processEventPayment(
  event: event!,
  user: user,
  quantity: 1,
);

if (result.isSuccess) {
  // Payment and registration successful
  print('Registered! Payment: ${result.payment?.id}');
  print('Revenue split: ${result.revenueSplit?.hostPayout}');
} else {
  // Payment or registration failed
  print('Error: ${result.errorMessage}');
}
```

### **Example 2: Free Event Registration**

```dart
// Same code works for free events
final result = await paymentEventService.processEventPayment(
  event: freeEvent,
  user: user,
);

// For free events:
// - result.payment will be null
// - result.registered will be true if successful
// - No payment processing occurs
```

### **Example 3: Handling Payment Success but Registration Failure**

```dart
final result = await paymentEventService.processEventPayment(
  event: event,
  user: user,
);

if (!result.isSuccess) {
  if (result.errorCode == 'REGISTRATION_FAILED_AFTER_PAYMENT') {
    // CRITICAL: Payment succeeded but registration failed
    // User paid but not registered - needs manual intervention
    // In production, trigger refund or support ticket
    showErrorDialog(
      'Payment processed but registration failed. '
      'Please contact support with payment ID: ${result.payment?.id}'
    );
  } else {
    // Payment failed - no charge occurred
    showErrorDialog(result.errorMessage ?? 'Payment failed');
  }
}
```

---

## 📦 **API Reference**

### **PaymentEventService**

#### **processEventPayment()**

```dart
Future<PaymentEventResult> processEventPayment({
  required ExpertiseEvent event,
  required UnifiedUser user,
  int quantity = 1,
}) async
```

**Parameters:**
- `event`: Event to register for
- `user`: User registering
- `quantity`: Number of tickets (default: 1)

**Returns:**
- `PaymentEventResult` with payment and registration status

**Behavior:**
- **Free events:** Registers directly (no payment)
- **Paid events:** Processes payment first, then registers on success

**Error Handling:**
- Returns `PaymentEventResult.failure()` on errors
- Includes error message and error code
- Payment failures prevent registration

---

### **PaymentEventResult**

```dart
class PaymentEventResult {
  final bool isSuccess;
  final Payment? payment;        // Payment record (if paid event)
  final ExpertiseEvent? event;   // Updated event (with new attendee count)
  final bool registered;          // Whether user was registered
  final RevenueSplit? revenueSplit; // Revenue split (if paid event)
  final String? errorMessage;     // Error message (if failed)
  final String? errorCode;        // Error code (if failed)
}
```

**Success Cases:**
- `isSuccess: true`
- `registered: true`
- `payment: Payment?` (null for free events, Payment for paid events)
- `event: ExpertiseEvent` (updated with new attendee)

**Failure Cases:**
- `isSuccess: false`
- `registered: false` (or true if payment succeeded but registration failed)
- `errorMessage: String` (describes the error)
- `errorCode: String` (for programmatic handling)

---

## ⚠️ **Critical Scenarios**

### **Scenario 1: Payment Succeeds, Registration Fails**

**Problem:** User paid but not registered for event.

**Error Code:** `REGISTRATION_FAILED_AFTER_PAYMENT`

**Handling:**
- Payment was successful (user charged)
- Registration failed (user not added to event)
- **Action Required:** Manual intervention or automatic refund

**In Production:**
- Trigger refund automatically
- Or create support ticket
- Log for monitoring

### **Scenario 2: Event Full During Payment**

**Problem:** Event reached capacity between payment start and completion.

**Handling:**
- PaymentService validates capacity before payment
- If capacity exceeded, payment fails with `INSUFFICIENT_CAPACITY`
- User not charged, not registered

### **Scenario 3: Payment Fails**

**Problem:** Payment processing fails (network, card declined, etc.).

**Handling:**
- Registration does NOT occur
- User not charged
- Error returned to UI for user to retry

---

## 🔗 **Integration with Agent 2**

### **For Agent 2 (Event UI):**

**Recommended Usage:**
```dart
// In event_details_page.dart or checkout_page.dart
final paymentEventService = GetIt.instance<PaymentEventService>();

// Process payment and registration
final result = await paymentEventService.processEventPayment(
  event: event,
  user: currentUser,
  quantity: selectedQuantity,
);

if (result.isSuccess && result.registered) {
  // Navigate to success page
  Navigator.push(context, PaymentSuccessPage(event: result.event!));
} else {
  // Show error
  showErrorSnackBar(result.errorMessage ?? 'Registration failed');
}
```

**Benefits:**
- Single method call handles both payment and registration
- No need to coordinate between PaymentService and ExpertiseEventService
- Handles all edge cases automatically

---

## 🧪 **Testing**

### **Unit Tests:**
- `test/unit/services/payment_event_service_test.dart`
- Tests free event registration
- Tests paid event flow (with mocks)
- Tests capacity limits

### **Integration Tests:**
- See `docs/INTEGRATION_TEST_PLAN.md` (Week 3)
- End-to-end payment + registration flow
- Error scenarios

---

## 📝 **Future Enhancements**

### **Phase 5 (Weeks 15-20):**
- Refund functionality (`refundEventPayment()`)
- Payment status tracking in events
- Automatic refunds for registration failures
- Payment history for hosts

### **Potential Agent 2 Enhancements:**
- Add `registerForEventWithPayment()` to ExpertiseEventService
- Accept optional `Payment` parameter in `registerForEvent()`
- This would simplify the bridge service

---

## ✅ **Checklist for Integration**

Before using PaymentEventService:

- [ ] PaymentService is initialized
- [ ] ExpertiseEventService is available
- [ ] Event model has `price`, `isPaid`, `maxAttendees` fields
- [ ] User model is available
- [ ] Error handling is implemented in UI
- [ ] Success/failure flows are tested

---

**Last Updated:** November 22, 2025, 09:28 PM CST  
**Status:** Ready for Agent 2 Integration

