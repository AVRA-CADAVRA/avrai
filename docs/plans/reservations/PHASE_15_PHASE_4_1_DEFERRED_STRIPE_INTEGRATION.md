# Phase 4.1: Stripe API Integration - Deferred

**Date:** January 7, 2026  
**Status:** ⏳ **DEFERRED** - Requires backend API support  
**Priority:** P1 - Required for production payments/refunds, but functional with mocks for development

---

## 🔴 **Critical Issue: Stripe API Integration**

### **Problem Statement:**

Phase 4.1 deliverables include payment and refund processing, but real Stripe API calls require:
1. **Backend API support** - Stripe secret key must be kept server-side (never exposed to client)
2. **Payment intent creation** - Requires backend API endpoint to create payment intents
3. **Refund processing** - Requires backend API endpoint to process refunds
4. **Payment confirmation** - Client-side confirmation works, but intent creation must be server-side

### **What's Currently Working (Mock Implementation):**

#### **1. Payment Processing (Mock)**
- **Current status:** `PaymentService.processReservationPayment()` creates **mock payment intents** (line 393-416)
- **Status:** ✅ Functional - All payment logic works, just uses mock payment intent IDs
- **Location:** `lib/core/services/payment_service.dart`
- **What works:**
  - Fee calculation (10% platform fee for paid events)
  - Payment record creation
  - Payment metadata tracking
  - Payment history
- **What's missing:**
  - Real Stripe payment intent creation (requires backend API)
  - Real payment processing (requires Stripe secret key server-side)

#### **2. Refund Processing (Mock)**
- **Current status:** `StripeService.processRefund()` returns **mock refund IDs** (line 210-214)
- **Status:** ✅ Functional - All refund logic works, just uses mock refund IDs
- **Location:** `lib/core/services/stripe_service.dart`
- **What works:**
  - Refund eligibility checking (via `ReservationCancellationPolicyService`)
  - Refund amount calculation
  - Refund metadata tracking
  - Refund distribution records
- **What's missing:**
  - Real Stripe refund processing (requires backend API)
  - Real refund processing (requires Stripe secret key server-side)

#### **3. Stripe Service (Placeholder)**
- **Current status:** `StripeService.createPaymentIntent()` throws `UnimplementedError` (line 110-113)
- **Current status:** `StripeService.processRefund()` returns mock refund ID (line 212)
- **Status:** ⚠️ Partially functional - Client-side confirmation works, but intent creation/refunds need backend
- **Location:** `lib/core/services/stripe_service.dart`
- **What works:**
  - Stripe initialization (publishable key setup)
  - Payment confirmation (client-side with `Stripe.instance.confirmPayment()`)
  - Error handling
- **What's missing:**
  - Payment intent creation (requires backend API - line 97-113)
  - Refund processing (requires backend API - line 197-214)

---

## 📋 **What Needs to Be Implemented (When Backend is Ready):**

### **1. Backend API Endpoints**

#### **Payment Intent Creation**
- **Endpoint:** `POST /api/payment-intents`
- **Request:**
  ```json
  {
    "amount": 2500,  // in cents
    "currency": "usd",
    "metadata": {
      "reservationId": "res_123",
      "type": "reservation",
      "reservationType": "event"
    }
  }
  ```
- **Response:**
  ```json
  {
    "clientSecret": "pi_xxx_secret_xxx",
    "paymentIntentId": "pi_xxx"
  }
  ```
- **Implementation:** Backend creates Stripe payment intent using secret key, returns client secret

#### **Refund Processing**
- **Endpoint:** `POST /api/refunds`
- **Request:**
  ```json
  {
    "paymentIntentId": "pi_xxx",
    "amount": 2500,  // in cents (optional, full refund if not provided)
    "reason": "Cancellation: res_123"
  }
  ```
- **Response:**
  ```json
  {
    "refundId": "re_xxx",
    "status": "succeeded"
  }
  ```
- **Implementation:** Backend processes Stripe refund using secret key, returns refund ID

### **2. Client-Side Service Updates**

#### **StripeService.createPaymentIntent()**
- **Current:** Throws `UnimplementedError` (line 110-113)
- **Required:** Call backend API to create payment intent
- **Example:**
  ```dart
  Future<String> createPaymentIntent({
    required int amount,
    String currency = 'usd',
    Map<String, String>? metadata,
  }) async {
    // TODO: Replace with backend API call
    final response = await http.post(
      Uri.parse('$backendUrl/api/payment-intents'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'metadata': metadata,
      }),
    );
    final data = jsonDecode(response.body);
    return data['clientSecret'];
  }
  ```

#### **StripeService.processRefund()**
- **Current:** Returns mock refund ID (line 212)
- **Required:** Call backend API to process refund
- **Example:**
  ```dart
  Future<String> processRefund({
    required String paymentIntentId,
    int? amount,
    String? reason,
  }) async {
    // TODO: Replace with backend API call
    final response = await http.post(
      Uri.parse('$backendUrl/api/refunds'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paymentIntentId': paymentIntentId,
        'amount': amount,
        'reason': reason,
      }),
    );
    final data = jsonDecode(response.body);
    return data['refundId'];
  }
  ```

---

## ✅ **What's Already Complete (Functional with Mocks):**

### **Payment Integration:**
- ✅ Payment fee calculation (10% platform fee for paid events)
- ✅ Payment record creation and storage
- ✅ Payment metadata tracking
- ✅ Payment history
- ✅ Free/paid reservation flow
- ✅ Deposit handling (structure in place)

### **Refund Integration:**
- ✅ Refund eligibility checking (`ReservationCancellationPolicyService`)
- ✅ Refund amount calculation
- ✅ Refund processing flow (`RefundService.processRefund()`)
- ✅ Refund distribution records
- ✅ Refund metadata tracking
- ✅ Integration with cancellation flow (`ReservationService.cancelReservation()`)

### **Service Architecture:**
- ✅ `PaymentService` - Payment processing logic (mock Stripe calls)
- ✅ `RefundService` - Refund processing logic (mock Stripe calls)
- ✅ `StripeService` - Stripe API wrapper (mock implementations)
- ✅ `ReservationCancellationPolicyService` - Policy checking
- ✅ Service integration (DI, error handling, graceful degradation)

### **Testing:**
- ✅ Unit tests for payment processing (with mocks)
- ✅ Unit tests for refund processing (with mocks)
- ✅ Integration tests for cancellation flow
- ✅ All tests passing with mock Stripe calls

---

## 🔄 **Flow (Current vs. Future):**

### **Current Flow (Mock):**
```
User creates paid reservation
    ↓
PaymentService.processReservationPayment()
    ↓
Calculate fees (10% platform fee) ✅ DONE
    ↓
Create mock payment intent (UUID-based ID) ✅ DONE (mock)
    ↓
Create payment record ✅ DONE
    ↓
Reservation confirmed ✅ DONE

User cancels reservation
    ↓
ReservationService.cancelReservation()
    ↓
Check cancellation policy ✅ DONE
    ↓
Calculate refund amount ✅ DONE
    ↓
RefundService.processRefund()
    ↓
StripeService.processRefund() → Returns mock refund ID ✅ DONE (mock)
    ↓
Create refund distribution record ✅ DONE
    ↓
Update reservation metadata ✅ DONE
```

### **Future Flow (Real Stripe):**
```
User creates paid reservation
    ↓
PaymentService.processReservationPayment()
    ↓
Calculate fees (10% platform fee) ✅ DONE
    ↓
Backend API: Create Stripe payment intent ⏳ NEEDED
    ↓
Create payment record ✅ DONE
    ↓
Client: Confirm payment with Stripe ✅ DONE (client-side)
    ↓
Reservation confirmed ✅ DONE

User cancels reservation
    ↓
ReservationService.cancelReservation()
    ↓
Check cancellation policy ✅ DONE
    ↓
Calculate refund amount ✅ DONE
    ↓
RefundService.processRefund()
    ↓
Backend API: Process Stripe refund ⏳ NEEDED
    ↓
Create refund distribution record ✅ DONE
    ↓
Update reservation metadata ✅ DONE
```

---

## 📝 **Design Decisions Made:**

1. **Mock vs. Real Stripe:**
   - ✅ **Decision:** Use mocks for development, real Stripe when backend is ready
   - **Rationale:** Allows development/testing without backend, all logic is ready
   - **Location:** `StripeService.processRefund()` returns mock ID (line 212)

2. **Backend API Requirements:**
   - ✅ **Decision:** All Stripe secret key operations must be server-side
   - **Rationale:** Security - secret key must never be exposed to client
   - **Location:** `StripeService` TODOs for backend API calls (lines 97, 197)

3. **Client-Side Confirmation:**
   - ✅ **Decision:** Keep client-side payment confirmation (Stripe SDK)
   - **Rationale:** Stripe SDK handles payment method collection securely
   - **Location:** `StripeService.confirmPayment()` works (line 132-163)

4. **Error Handling:**
   - ✅ **Decision:** Graceful degradation - cancellation proceeds even if refund fails
   - **Rationale:** User experience - cancellation should work even if refund processing fails
   - **Location:** `ReservationService.cancelReservation()` try-catch around refund (line 1154-1200)

---

## 🚧 **Blockers:**

1. **Backend API Not Ready:**
   - Stripe payment intent creation endpoint needed
   - Stripe refund processing endpoint needed
   - Backend must have Stripe secret key configured

2. **Stripe Account Setup:**
   - Production Stripe account needed
   - Test mode vs. production mode configuration
   - Webhook endpoints for payment status updates (optional but recommended)

---

## 🎯 **When to Implement:**

- ✅ **Ready now:** All client-side logic is complete and tested
- ⏳ **Waiting on:** Backend API endpoints for Stripe integration
- ⏳ **Recommended:** Implement when:
  - Backend API is ready
  - Stripe account is configured
  - Testing with real payments is needed
  - Production deployment is planned

---

## 📚 **References:**

- **StripeService:** `lib/core/services/stripe_service.dart`
- **PaymentService:** `lib/core/services/payment_service.dart`
- **RefundService:** `lib/core/services/refund_service.dart`
- **ReservationService:** `lib/core/services/reservation_service.dart`
- **Payment Holds Deferral:** `PHASE_15_PHASE_4_1_DEFERRED_PAYMENT_HOLDS.md`

---

**Last Updated:** January 7, 2026  
**Status:** Stripe Integration Deferred ⏳
