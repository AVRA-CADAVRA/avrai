# Agent 1 Week 5: Partnership Model Integration Design

**Date:** November 23, 2025  
**Agent:** Agent 1 - Backend & Integration Specialist  
**Phase:** Phase 2, Week 5 - Event Partnership Foundation (Models Integration)  
**Status:** 🟢 In Progress

---

## 📋 Executive Summary

This document outlines the integration design for Partnership models with existing Event and Payment models. It defines integration points, service architecture, and requirements for Week 6 implementation.

**Key Integration Points:**
- `ExpertiseEvent` ↔ `EventPartnership` (one-to-many)
- `Payment` ↔ `RevenueSplit` (extend for N-way splits)
- `BusinessAccount` ↔ `EventPartnership` (many-to-many)
- `PaymentService` ↔ Partnership revenue distribution

---

## 🔍 Existing Models Review

### **Event Models**

#### `ExpertiseEvent` (`lib/core/models/expertise_event.dart`)
**Current Structure:**
- Single host (`UnifiedUser host`)
- Basic payment support (`price`, `isPaid`)
- No partnership support
- No multi-party revenue splits

**Integration Points:**
- ✅ Can be extended with partnership reference
- ✅ Needs `partnershipId` field (optional, nullable)
- ✅ Needs `isPartnershipEvent` flag
- ✅ Needs `partners` list (for display)

**Current Limitations:**
- Only supports single-host events
- Revenue split only to single host
- No business partner support

### **Payment Models**

#### `Payment` (`lib/core/models/payment.dart`)
**Current Structure:**
- Single event reference (`eventId`)
- Single user reference (`userId`)
- Basic payment tracking
- Stripe integration ready

**Integration Points:**
- ✅ Can support partnership payments
- ✅ Needs `partnershipId` field (optional)
- ✅ Needs `splitPartyId` field (which partner receives this payment)

#### `RevenueSplit` (`lib/core/models/revenue_split.dart`)
**Current Structure:**
- Single host payout (`hostPayout`)
- Platform fee (10%)
- Processing fee (~3%)
- **LIMITATION:** Only supports single-host splits

**Integration Points:**
- ⚠️ **NEEDS EXTENSION** for N-way splits
- Needs `splitParties` list (Map<String, double> - partyId → percentage)
- Needs `locked` flag (pre-event agreement locking)
- Needs `partnershipId` reference

**Required Changes:**
```dart
// Current (single-host):
final double hostPayout;

// Extended (N-way):
final Map<String, double> splitParties; // partyId → percentage
final Map<String, double> splitAmounts; // partyId → dollar amount
final bool isLocked; // Pre-event agreement locked
final String? partnershipId; // Reference to partnership
```

#### `PaymentIntent` (`lib/core/models/payment_intent.dart`)
**Current Structure:**
- Stripe payment intent tracking
- Single event/user reference

**Integration Points:**
- ✅ Can support partnership payments
- ✅ No changes needed (works for any payment)

### **Business Models**

#### `BusinessAccount` (`lib/core/models/business_account.dart`)
**Current Structure:**
- Business information
- Verification status
- Expert connection preferences
- **NO partnership tracking**

**Integration Points:**
- ✅ Can be used as partnership partner
- ✅ Needs `partnershipIds` list (optional, for tracking)
- ✅ Already has verification support

#### `BusinessVerification` (`lib/core/models/business_verification.dart`)
**Current Structure:**
- Verification status tracking
- Document management
- Review workflow

**Integration Points:**
- ✅ Already supports partnership eligibility checks
- ✅ No changes needed

---

## 🔗 Partnership Model Integration Points

### **Expected Models from Agent 3 (Week 5)**

#### `EventPartnership` (Expected)
**Integration Requirements:**
```dart
class EventPartnership {
  final String id;
  final String eventId; // → ExpertiseEvent
  final List<PartnershipParty> parties; // User + Business
  final PartnershipStatus status;
  final PartnershipAgreement agreement;
  final String? revenueSplitId; // → RevenueSplit (extended)
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Integration Points:**
1. **Event Reference:** `eventId` → `ExpertiseEvent.id`
2. **Revenue Split:** `revenueSplitId` → `RevenueSplit.id` (extended)
3. **Parties:** `List<PartnershipParty>` contains:
   - `userId` (expert) → `UnifiedUser.id`
   - `businessId` (business) → `BusinessAccount.id`

#### `RevenueSplit` (Extension Required)
**Current Model:** Single-host only  
**Required Extension:** N-way splits

**Integration Points:**
1. **Partnership Reference:** `partnershipId` → `EventPartnership.id`
2. **N-way Splits:** `Map<String, double> splitParties` (partyId → percentage)
3. **Locking:** `isLocked` flag for pre-event agreement
4. **Amounts:** `Map<String, double> splitAmounts` (partyId → dollar amount)

#### `PartnershipEvent` (Expected)
**Integration Requirements:**
```dart
class PartnershipEvent {
  // Extends ExpertiseEvent
  final String partnershipId; // → EventPartnership
  final String revenueSplitId; // → RevenueSplit (extended)
  // Partnership-specific fields
}
```

**Integration Points:**
1. **Inheritance:** Extends `ExpertiseEvent`
2. **Partnership:** `partnershipId` → `EventPartnership.id`
3. **Revenue:** `revenueSplitId` → `RevenueSplit.id`

---

## 🏗️ Service Layer Architecture

### **Service Dependencies**

```
PaymentService (existing)
    ↓
    ├─→ ExpertiseEventService (existing)
    ├─→ PartnershipService (NEW - Week 6)
    ├─→ RevenueSplitService (NEW - Week 6)
    └─→ BusinessService (NEW - Week 6)

ExpertiseEventService (existing)
    ↓
    ├─→ PartnershipService (NEW - Week 6)
    └─→ BusinessService (NEW - Week 6)
```

### **New Services (Week 6)**

#### `PartnershipService`
**Responsibilities:**
- Create partnerships
- Find partnerships for events
- Update partnership status
- Check partnership eligibility
- Vibe matching (70%+ compatibility)

**Integration Points:**
- Uses `ExpertiseEventService` (read-only) for event validation
- Uses `BusinessService` for business validation
- Creates `EventPartnership` records
- Updates `ExpertiseEvent` with partnership reference

**Key Methods:**
```dart
class PartnershipService {
  // Create partnership
  Future<EventPartnership> createPartnership({
    required String eventId,
    required String userId,
    required String businessId,
    required PartnershipAgreement agreement,
  });
  
  // Find partnerships for event
  Future<List<EventPartnership>> getPartnershipsForEvent(String eventId);
  
  // Update partnership status
  Future<EventPartnership> updatePartnershipStatus(
    String partnershipId,
    PartnershipStatus status,
  );
  
  // Check partnership eligibility
  Future<bool> checkPartnershipEligibility({
    required String userId,
    required String businessId,
    required String eventId,
  });
  
  // Vibe matching (70%+ compatibility)
  Future<double> calculateVibeCompatibility({
    required String userId,
    required String businessId,
  });
}
```

#### `BusinessService`
**Responsibilities:**
- Create business accounts
- Verify businesses
- Update business info
- Find businesses
- Check business eligibility

**Integration Points:**
- Uses `BusinessAccount` model (existing)
- Uses `BusinessVerification` model (existing)
- Integrates with `PartnershipService` for eligibility checks

**Key Methods:**
```dart
class BusinessService {
  // Create business account
  Future<BusinessAccount> createBusinessAccount({
    required String name,
    required String email,
    required String businessType,
    // ... other fields
  });
  
  // Verify business
  Future<BusinessVerification> verifyBusiness({
    required String businessId,
    required VerificationDocuments documents,
  });
  
  // Update business info
  Future<BusinessAccount> updateBusinessInfo({
    required String businessId,
    // ... update fields
  });
  
  // Find businesses
  Future<List<BusinessAccount>> findBusinesses({
    String? category,
    String? location,
    bool verifiedOnly = false,
  });
  
  // Check business eligibility
  Future<bool> checkBusinessEligibility(String businessId);
}
```

#### `PartnershipMatchingService`
**Responsibilities:**
- Vibe-based matching algorithm
- Compatibility scoring
- Partnership suggestions

**Integration Points:**
- Uses `PartnershipService` for partnership creation
- Uses personality/vibe data for matching
- 70%+ compatibility threshold

**Key Methods:**
```dart
class PartnershipMatchingService {
  // Vibe-based matching
  Future<List<PartnershipSuggestion>> findMatchingPartners({
    required String userId,
    required String eventId,
    double minCompatibility = 0.70, // 70% threshold
  });
  
  // Calculate compatibility score
  Future<double> calculateCompatibility({
    required String userId,
    required String businessId,
  });
  
  // Get partnership suggestions
  Future<List<PartnershipSuggestion>> getSuggestions({
    required String eventId,
  });
}
```

#### `RevenueSplitService` (Week 7)
**Responsibilities:**
- Calculate N-way splits
- Lock splits (pre-event)
- Distribute payments
- Track earnings

**Integration Points:**
- Extends `RevenueSplit` model (N-way support)
- Uses `PaymentService` for payment distribution
- Uses `PartnershipService` for partnership data

---

## 📐 Integration Architecture

### **Data Flow: Partnership Creation**

```
1. User creates event (ExpertiseEvent)
   ↓
2. User proposes partnership (PartnershipService.createPartnership)
   ↓
3. Business receives proposal
   ↓
4. Business accepts/declines (PartnershipService.updatePartnershipStatus)
   ↓
5. If accepted:
   - Create RevenueSplit (N-way, locked)
   - Update ExpertiseEvent with partnershipId
   - Lock agreement (pre-event)
   ↓
6. Event goes live (ExpertiseEventService)
   ↓
7. Payments processed (PaymentService)
   ↓
8. Revenue distributed (RevenueSplitService - Week 7)
```

### **Data Flow: Payment Processing (Partnership Event)**

```
1. User purchases ticket (PaymentService.purchaseEventTicket)
   ↓
2. Check if event has partnership (ExpertiseEvent.partnershipId)
   ↓
3. If partnership exists:
   - Get RevenueSplit (extended, N-way)
   - Calculate splits per party
   - Create payment records per party
   ↓
4. Distribute revenue (RevenueSplitService - Week 7)
   - Platform fee: 10%
   - Processing fee: ~3%
   - Split remaining among parties
```

### **Model Relationships**

```
ExpertiseEvent (existing)
    ├─→ partnershipId (optional) → EventPartnership
    └─→ isPartnershipEvent (bool)

EventPartnership (NEW - Agent 3)
    ├─→ eventId → ExpertiseEvent
    ├─→ parties → [PartnershipParty]
    │   ├─→ userId → UnifiedUser
    │   └─→ businessId → BusinessAccount
    └─→ revenueSplitId → RevenueSplit (extended)

RevenueSplit (EXTEND - Agent 1 Week 7)
    ├─→ partnershipId (optional) → EventPartnership
    ├─→ splitParties (Map<String, double>) // N-way percentages
    ├─→ splitAmounts (Map<String, double>) // N-way amounts
    └─→ isLocked (bool) // Pre-event agreement

Payment (existing)
    ├─→ eventId → ExpertiseEvent
    ├─→ partnershipId (optional) → EventPartnership
    └─→ splitPartyId (optional) → Which party receives this

BusinessAccount (existing)
    └─→ partnershipIds (optional) → [EventPartnership.id]
```

---

## 🔧 Integration Requirements

### **Model Extensions Required**

#### 1. `ExpertiseEvent` Extension
**File:** `lib/core/models/expertise_event.dart`

**Required Fields:**
```dart
class ExpertiseEvent {
  // ... existing fields ...
  
  // Partnership support
  final String? partnershipId; // Reference to EventPartnership
  final bool isPartnershipEvent; // Flag for partnership events
  final List<String> partnerIds; // For quick lookup (userId, businessId)
}
```

**Integration Notes:**
- `partnershipId` is nullable (backward compatible)
- `isPartnershipEvent` defaults to `false`
- `partnerIds` is optional list for display purposes

#### 2. `RevenueSplit` Extension
**File:** `lib/core/models/revenue_split.dart`

**Required Fields:**
```dart
class RevenueSplit {
  // ... existing fields ...
  
  // N-way split support
  final String? partnershipId; // Reference to EventPartnership
  final Map<String, double> splitParties; // partyId → percentage
  final Map<String, double> splitAmounts; // partyId → dollar amount
  final bool isLocked; // Pre-event agreement locked
}
```

**Integration Notes:**
- Maintain backward compatibility (single-host still works)
- `splitParties` and `splitAmounts` are empty for single-host events
- `isLocked` prevents changes after event starts

#### 3. `Payment` Extension
**File:** `lib/core/models/payment.dart`

**Required Fields:**
```dart
class Payment {
  // ... existing fields ...
  
  // Partnership support
  final String? partnershipId; // Reference to EventPartnership
  final String? splitPartyId; // Which party receives this payment
}
```

**Integration Notes:**
- Both fields are nullable (backward compatible)
- `splitPartyId` identifies which partner receives the payment

#### 4. `BusinessAccount` Extension
**File:** `lib/core/models/business_account.dart`

**Required Fields:**
```dart
class BusinessAccount {
  // ... existing fields ...
  
  // Partnership tracking
  final List<String> partnershipIds; // References to EventPartnership
}
```

**Integration Notes:**
- Optional list for tracking partnerships
- Can be empty (backward compatible)

### **Service Integration Requirements**

#### 1. `PaymentService` Integration
**File:** `lib/core/services/payment_service.dart`

**Required Changes:**
- Check for partnership when processing payments
- Calculate N-way revenue splits if partnership exists
- Create payment records per party
- Support partnership payment distribution

**Key Methods to Add:**
```dart
// Check if event has partnership
Future<bool> hasPartnership(String eventId);

// Calculate N-way revenue split
Future<RevenueSplit> calculatePartnershipRevenueSplit({
  required String eventId,
  required double totalAmount,
  required int ticketsSold,
});

// Distribute payment to partners
Future<void> distributePartnershipPayment({
  required String paymentId,
  required String partnershipId,
});
```

#### 2. `ExpertiseEventService` Integration
**File:** `lib/core/services/expertise_event_service.dart`

**Required Changes:**
- Support partnership event creation
- Update event with partnership reference
- Validate partnership before event goes live

**Key Methods to Add:**
```dart
// Create partnership event
Future<ExpertiseEvent> createPartnershipEvent({
  required UnifiedUser host,
  required String partnershipId,
  // ... other event fields
});

// Update event with partnership
Future<ExpertiseEvent> addPartnershipToEvent({
  required String eventId,
  required String partnershipId,
});
```

---

## 📋 Integration Checklist

### **Week 5 (Current) - Model Integration Design**
- [x] Review existing Event models
- [x] Review existing Payment models
- [x] Review existing Business models
- [x] Design Partnership model integration points
- [x] Document integration requirements
- [x] Create service layer architecture plan

### **Week 6 - Service Implementation**
- [ ] Wait for Agent 3's Partnership models
- [ ] Review Agent 3's models
- [ ] Create `PartnershipService`
- [ ] Create `BusinessService`
- [ ] Create `PartnershipMatchingService`
- [ ] Integrate with existing `ExpertiseEventService`
- [ ] Create service tests

### **Week 7 - Payment Integration**
- [ ] Extend `RevenueSplit` model (N-way splits)
- [ ] Extend `PaymentService` for multi-party payments
- [ ] Create `RevenueSplitService`
- [ ] Create `PayoutService`
- [ ] Integrate with existing Payment service
- [ ] Create service tests

---

## 🚨 Critical Integration Points

### **1. Backward Compatibility**
**Requirement:** All existing single-host events must continue to work.

**Solution:**
- All partnership fields are optional/nullable
- Default values maintain single-host behavior
- Services check for partnership before using partnership logic

### **2. Pre-Event Agreement Locking**
**Requirement:** Revenue splits must be locked before event starts.

**Solution:**
- `RevenueSplit.isLocked` flag
- Lock when all parties approve partnership
- Prevent event from going live until agreement is locked
- No changes allowed after lock

### **3. N-way Revenue Split Calculation**
**Requirement:** Support 2-party to N-party revenue splits.

**Solution:**
- `RevenueSplit.splitParties` (Map<String, double>) - percentages
- `RevenueSplit.splitAmounts` (Map<String, double>) - dollar amounts
- Validation: percentages must sum to 100%
- Platform fee (10%) and processing fee (~3%) calculated first
- Remaining amount split among parties

### **4. Vibe Matching (70%+ Threshold)**
**Requirement:** Only suggest partnerships with 70%+ compatibility.

**Solution:**
- `PartnershipMatchingService` calculates compatibility
- Only returns suggestions with compatibility >= 0.70
- Both parties can still decline (but rarely need to)

---

## 📊 Service Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Partnership Flow                     │
└─────────────────────────────────────────────────────────┘

ExpertiseEventService (existing)
    │
    ├─→ createEvent() → ExpertiseEvent
    │
    └─→ createPartnershipEvent() → ExpertiseEvent + EventPartnership

PartnershipService (NEW - Week 6)
    │
    ├─→ createPartnership() → EventPartnership
    ├─→ getPartnershipsForEvent() → List<EventPartnership>
    ├─→ updatePartnershipStatus() → EventPartnership
    ├─→ checkPartnershipEligibility() → bool
    └─→ calculateVibeCompatibility() → double

PartnershipMatchingService (NEW - Week 6)
    │
    ├─→ findMatchingPartners() → List<PartnershipSuggestion>
    ├─→ calculateCompatibility() → double
    └─→ getSuggestions() → List<PartnershipSuggestion>

BusinessService (NEW - Week 6)
    │
    ├─→ createBusinessAccount() → BusinessAccount
    ├─→ verifyBusiness() → BusinessVerification
    ├─→ updateBusinessInfo() → BusinessAccount
    ├─→ findBusinesses() → List<BusinessAccount>
    └─→ checkBusinessEligibility() → bool

PaymentService (existing - EXTEND Week 7)
    │
    ├─→ purchaseEventTicket() → PaymentResult
    ├─→ hasPartnership() → bool
    ├─→ calculatePartnershipRevenueSplit() → RevenueSplit
    └─→ distributePartnershipPayment() → void

RevenueSplitService (NEW - Week 7)
    │
    ├─→ calculateNWaySplit() → RevenueSplit
    ├─→ lockSplit() → RevenueSplit
    ├─→ distributePayments() → void
    └─→ trackEarnings() → EarningsReport
```

---

## ✅ Acceptance Criteria

### **Model Integration**
- [x] Integration points identified
- [x] Backward compatibility maintained
- [x] Extension requirements documented

### **Service Architecture**
- [x] Service dependencies mapped
- [x] Service responsibilities defined
- [x] Integration flow documented

### **Integration Requirements**
- [x] Model extensions specified
- [x] Service changes documented
- [x] Critical integration points identified

---

## 📝 Next Steps

1. **Wait for Agent 3's Models (Week 5)**
   - Review `EventPartnership` model
   - Review `PartnershipEvent` model
   - Verify integration points match design

2. **Week 6: Service Implementation**
   - Create `PartnershipService`
   - Create `BusinessService`
   - Create `PartnershipMatchingService`
   - Integrate with existing services

3. **Week 7: Payment Integration**
   - Extend `RevenueSplit` for N-way splits
   - Extend `PaymentService` for multi-party payments
   - Create `RevenueSplitService`
   - Create `PayoutService`

---

**Last Updated:** November 23, 2025  
**Status:** ✅ Integration Design Complete - Ready for Agent 3's Models

