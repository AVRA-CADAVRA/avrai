# Agent 1 Week 5: Service Layer Architecture Plan

**Date:** November 23, 2025  
**Agent:** Agent 1 - Backend & Integration Specialist  
**Phase:** Phase 2, Week 5 - Event Partnership Foundation (Models Integration)  
**Status:** 🟢 In Progress

---

## 📋 Executive Summary

This document outlines the service layer architecture for Partnership services. It defines service responsibilities, dependencies, interfaces, and implementation patterns for Week 6.

**Services to Create (Week 6):**
1. `PartnershipService` - Core partnership management
2. `BusinessService` - Business account management
3. `PartnershipMatchingService` - Vibe-based matching

**Services to Extend (Week 7):**
1. `PaymentService` - Multi-party payment processing
2. `RevenueSplitService` - N-way revenue split calculation
3. `PayoutService` - Payout scheduling and tracking

---

## 🏗️ Service Architecture Overview

### **Service Hierarchy**

```
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                            │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│  PartnershipService  │  ← Core partnership management
└──────────────────────┘
         │
         ├─→ Uses: ExpertiseEventService (read-only)
         ├─→ Uses: BusinessService
         └─→ Creates: EventPartnership

┌──────────────────────┐
│   BusinessService    │  ← Business account management
└──────────────────────┘
         │
         ├─→ Uses: BusinessAccount (model)
         ├─→ Uses: BusinessVerification (model)
         └─→ Creates: BusinessAccount, BusinessVerification

┌──────────────────────────────┐
│ PartnershipMatchingService   │  ← Vibe-based matching
└──────────────────────────────┘
         │
         ├─→ Uses: PartnershipService
         ├─→ Uses: Personality/Vibe data
         └─→ Returns: PartnershipSuggestion

┌──────────────────────┐
│   PaymentService     │  ← Payment processing (EXTEND Week 7)
└──────────────────────┘
         │
         ├─→ Uses: PartnershipService (read-only)
         ├─→ Uses: RevenueSplitService (Week 7)
         └─→ Processes: Partnership payments

┌──────────────────────┐
│ RevenueSplitService  │  ← N-way revenue splits (Week 7)
└──────────────────────┘
         │
         ├─→ Uses: PartnershipService (read-only)
         ├─→ Uses: PaymentService
         └─→ Calculates: N-way splits

┌──────────────────────┐
│    PayoutService     │  ← Payout scheduling (Week 7)
└──────────────────────┘
         │
         ├─→ Uses: RevenueSplitService
         ├─→ Uses: PaymentService
         └─→ Schedules: Payouts
```

---

## 🔧 Service 1: PartnershipService

### **Purpose**
Core service for managing event partnerships between users and businesses.

### **Responsibilities**
- Create partnerships
- Find partnerships for events
- Update partnership status
- Check partnership eligibility
- Vibe matching (70%+ compatibility)

### **Dependencies**
```dart
class PartnershipService {
  final ExpertiseEventService _eventService; // Read-only
  final BusinessService _businessService;
  final AppLogger _logger;
  
  PartnershipService({
    required ExpertiseEventService eventService,
    required BusinessService businessService,
  });
}
```

### **Key Methods**

#### `createPartnership`
**Purpose:** Create a new partnership for an event.

**Signature:**
```dart
Future<EventPartnership> createPartnership({
  required String eventId,
  required String userId,
  required String businessId,
  required PartnershipAgreement agreement,
}) async;
```

**Flow:**
1. Validate event exists (`_eventService.getEventById`)
2. Validate business exists (`_businessService.getBusinessById`)
3. Check partnership eligibility
4. Calculate vibe compatibility (must be 70%+)
5. Create `EventPartnership` record
6. Update `ExpertiseEvent` with partnership reference
7. Return partnership

**Error Handling:**
- Event not found → `Exception('Event not found')`
- Business not found → `Exception('Business not found')`
- Not eligible → `Exception('Partnership not eligible')`
- Compatibility < 70% → `Exception('Compatibility below 70% threshold')`

#### `getPartnershipsForEvent`
**Purpose:** Get all partnerships for an event.

**Signature:**
```dart
Future<List<EventPartnership>> getPartnershipsForEvent(String eventId) async;
```

**Flow:**
1. Query partnerships by `eventId`
2. Return list of partnerships

#### `updatePartnershipStatus`
**Purpose:** Update partnership status (proposed → active → completed).

**Signature:**
```dart
Future<EventPartnership> updatePartnershipStatus({
  required String partnershipId,
  required PartnershipStatus status,
}) async;
```

**Flow:**
1. Get partnership by ID
2. Validate status transition
3. Update partnership status
4. If status is `active` and all parties approved:
   - Lock revenue split (pre-event)
   - Update event status
5. Return updated partnership

#### `checkPartnershipEligibility`
**Purpose:** Check if a partnership is eligible.

**Signature:**
```dart
Future<bool> checkPartnershipEligibility({
  required String userId,
  required String businessId,
  required String eventId,
}) async;
```

**Flow:**
1. Check user has City-level expertise
2. Check business is verified
3. Check event exists and is upcoming
4. Check no existing partnership for this event
5. Return eligibility result

#### `calculateVibeCompatibility`
**Purpose:** Calculate vibe compatibility between user and business.

**Signature:**
```dart
Future<double> calculateVibeCompatibility({
  required String userId,
  required String businessId,
}) async;
```

**Flow:**
1. Get user personality/vibe data
2. Get business preferences/vibe data
3. Calculate compatibility score (0.0 to 1.0)
4. Return score

**Compatibility Factors:**
- Value alignment
- Quality focus
- Community orientation
- Event style preferences
- Authenticity vs. commercial focus

**Threshold:** 70% (0.70) minimum for suggestions

---

## 🔧 Service 2: BusinessService

### **Purpose**
Manage business accounts and verification.

### **Responsibilities**
- Create business accounts
- Verify businesses
- Update business info
- Find businesses
- Check business eligibility

### **Dependencies**
```dart
class BusinessService {
  final AppLogger _logger;
  
  BusinessService();
}
```

### **Key Methods**

#### `createBusinessAccount`
**Purpose:** Create a new business account.

**Signature:**
```dart
Future<BusinessAccount> createBusinessAccount({
  required String name,
  required String email,
  required String businessType,
  required String createdBy, // User ID
  String? description,
  String? website,
  String? location,
  String? phone,
  List<String>? categories,
}) async;
```

**Flow:**
1. Validate business data
2. Create `BusinessAccount` record
3. Return business account

#### `verifyBusiness`
**Purpose:** Verify a business account.

**Signature:**
```dart
Future<BusinessVerification> verifyBusiness({
  required String businessId,
  required VerificationDocuments documents,
}) async;
```

**Flow:**
1. Get business account
2. Create `BusinessVerification` record
3. Submit for review (status: `pending`)
4. Return verification record

#### `updateBusinessInfo`
**Purpose:** Update business account information.

**Signature:**
```dart
Future<BusinessAccount> updateBusinessInfo({
  required String businessId,
  String? name,
  String? description,
  String? website,
  String? location,
  String? phone,
  List<String>? categories,
}) async;
```

**Flow:**
1. Get business account
2. Update fields
3. Save updated business
4. Return updated business

#### `findBusinesses`
**Purpose:** Find businesses by filters.

**Signature:**
```dart
Future<List<BusinessAccount>> findBusinesses({
  String? category,
  String? location,
  bool verifiedOnly = false,
  int maxResults = 20,
}) async;
```

**Flow:**
1. Query businesses by filters
2. Filter by verification status if `verifiedOnly`
3. Return list of businesses

#### `checkBusinessEligibility`
**Purpose:** Check if business is eligible for partnerships.

**Signature:**
```dart
Future<bool> checkBusinessEligibility(String businessId) async;
```

**Flow:**
1. Get business account
2. Check verification status (must be `verified`)
3. Check business is active
4. Return eligibility result

---

## 🔧 Service 3: PartnershipMatchingService

### **Purpose**
Vibe-based partnership matching and suggestions.

### **Responsibilities**
- Vibe-based matching algorithm
- Compatibility scoring
- Partnership suggestions

### **Dependencies**
```dart
class PartnershipMatchingService {
  final PartnershipService _partnershipService;
  final AppLogger _logger;
  
  PartnershipMatchingService({
    required PartnershipService partnershipService,
  });
}
```

### **Key Methods**

#### `findMatchingPartners`
**Purpose:** Find matching partners for an event.

**Signature:**
```dart
Future<List<PartnershipSuggestion>> findMatchingPartners({
  required String userId,
  required String eventId,
  double minCompatibility = 0.70, // 70% threshold
}) async;
```

**Flow:**
1. Get event details
2. Get user personality/vibe data
3. Find businesses in same category/location
4. Calculate compatibility for each business
5. Filter by `minCompatibility` (70%+)
6. Return suggestions sorted by compatibility

#### `calculateCompatibility`
**Purpose:** Calculate compatibility score between user and business.

**Signature:**
```dart
Future<double> calculateCompatibility({
  required String userId,
  required String businessId,
}) async;
```

**Flow:**
1. Get user personality/vibe data
2. Get business preferences/vibe data
3. Calculate compatibility score (0.0 to 1.0)
4. Return score

**Compatibility Formula:**
```
compatibility = (
  valueAlignment * 0.25 +
  qualityFocus * 0.25 +
  communityOrientation * 0.20 +
  eventStyleMatch * 0.20 +
  authenticityMatch * 0.10
)
```

#### `getSuggestions`
**Purpose:** Get partnership suggestions for an event.

**Signature:**
```dart
Future<List<PartnershipSuggestion>> getSuggestions({
  required String eventId,
}) async;
```

**Flow:**
1. Get event details
2. Get event host (user)
3. Find matching partners (`findMatchingPartners`)
4. Return suggestions

---

## 🔧 Service 4: PaymentService Extension (Week 7)

### **Purpose**
Extend existing `PaymentService` for multi-party payment processing.

### **New Methods**

#### `hasPartnership`
**Purpose:** Check if event has a partnership.

**Signature:**
```dart
Future<bool> hasPartnership(String eventId) async;
```

**Flow:**
1. Get event by ID
2. Check if `partnershipId` is not null
3. Return result

#### `calculatePartnershipRevenueSplit`
**Purpose:** Calculate N-way revenue split for partnership event.

**Signature:**
```dart
Future<RevenueSplit> calculatePartnershipRevenueSplit({
  required String eventId,
  required double totalAmount,
  required int ticketsSold,
}) async;
```

**Flow:**
1. Get event partnership
2. Get revenue split (N-way)
3. Calculate platform fee (10%)
4. Calculate processing fee (~3%)
5. Calculate remaining amount
6. Split remaining among parties (per agreement)
7. Return revenue split

#### `distributePartnershipPayment`
**Purpose:** Distribute payment to partnership parties.

**Signature:**
```dart
Future<void> distributePartnershipPayment({
  required String paymentId,
  required String partnershipId,
}) async;
```

**Flow:**
1. Get payment record
2. Get partnership
3. Get revenue split (N-way)
4. Calculate amounts per party
5. Create payout records per party
6. Schedule payouts (2 days after event)

---

## 🔧 Service 5: RevenueSplitService (Week 7)

### **Purpose**
Calculate and manage N-way revenue splits.

### **Responsibilities**
- Calculate N-way splits
- Lock splits (pre-event)
- Distribute payments
- Track earnings

### **Key Methods**

#### `calculateNWaySplit`
**Purpose:** Calculate N-way revenue split.

**Signature:**
```dart
Future<RevenueSplit> calculateNWaySplit({
  required String partnershipId,
  required double totalAmount,
  required int ticketsSold,
  required Map<String, double> splitPercentages, // partyId → percentage
}) async;
```

**Flow:**
1. Validate percentages sum to 100%
2. Calculate platform fee (10%)
3. Calculate processing fee (~3%)
4. Calculate remaining amount
5. Calculate amount per party
6. Create `RevenueSplit` (extended, N-way)
7. Return revenue split

#### `lockSplit`
**Purpose:** Lock revenue split (pre-event agreement).

**Signature:**
```dart
Future<RevenueSplit> lockSplit(String revenueSplitId) async;
```

**Flow:**
1. Get revenue split
2. Set `isLocked = true`
3. Save revenue split
4. Return locked revenue split

#### `distributePayments`
**Purpose:** Distribute payments to parties.

**Signature:**
```dart
Future<void> distributePayments({
  required String revenueSplitId,
  required double totalAmount,
}) async;
```

**Flow:**
1. Get revenue split (must be locked)
2. Calculate amounts per party
3. Create payout records
4. Schedule payouts (2 days after event)

---

## 🔧 Service 6: PayoutService (Week 7)

### **Purpose**
Schedule and track payouts.

### **Responsibilities**
- Schedule payouts
- Track earnings
- Generate payout reports

### **Key Methods**

#### `schedulePayout`
**Purpose:** Schedule a payout for a party.

**Signature:**
```dart
Future<Payout> schedulePayout({
  required String partyId,
  required double amount,
  required String eventId,
  required DateTime scheduledDate, // 2 days after event
}) async;
```

**Flow:**
1. Create payout record
2. Schedule payout (2 days after event)
3. Return payout record

#### `trackEarnings`
**Purpose:** Track earnings for a party.

**Signature:**
```dart
Future<EarningsReport> trackEarnings({
  required String partyId,
  DateTime? startDate,
  DateTime? endDate,
}) async;
```

**Flow:**
1. Query payouts for party
2. Calculate total earnings
3. Generate earnings report
4. Return report

---

## 📐 Service Integration Patterns

### **Pattern 1: Service Dependency Injection**
```dart
// Services are injected via constructor
class PartnershipService {
  final ExpertiseEventService _eventService;
  final BusinessService _businessService;
  
  PartnershipService({
    required ExpertiseEventService eventService,
    required BusinessService businessService,
  }) : _eventService = eventService,
       _businessService = businessService;
}
```

### **Pattern 2: Read-Only Service Access**
```dart
// Services only read from other services (no modifications)
class PartnershipService {
  // Read-only access to ExpertiseEventService
  Future<ExpertiseEvent?> _getEvent(String eventId) async {
    return await _eventService.getEventById(eventId);
  }
}
```

### **Pattern 3: Error Handling**
```dart
// Consistent error handling across services
try {
  // Service operation
} catch (e) {
  _logger.error('Operation failed', error: e, tag: _logName);
  rethrow; // Or return error result
}
```

### **Pattern 4: Logging**
```dart
// Consistent logging pattern
static const String _logName = 'PartnershipService';
final AppLogger _logger = const AppLogger(
  defaultTag: 'SPOTS',
  minimumLevel: LogLevel.debug,
);

_logger.info('Operation started', tag: _logName);
_logger.error('Operation failed', error: e, tag: _logName);
```

---

## ✅ Service Architecture Checklist

### **Week 6: Core Services**
- [ ] Create `PartnershipService`
  - [ ] `createPartnership`
  - [ ] `getPartnershipsForEvent`
  - [ ] `updatePartnershipStatus`
  - [ ] `checkPartnershipEligibility`
  - [ ] `calculateVibeCompatibility`
- [ ] Create `BusinessService`
  - [ ] `createBusinessAccount`
  - [ ] `verifyBusiness`
  - [ ] `updateBusinessInfo`
  - [ ] `findBusinesses`
  - [ ] `checkBusinessEligibility`
- [ ] Create `PartnershipMatchingService`
  - [ ] `findMatchingPartners`
  - [ ] `calculateCompatibility`
  - [ ] `getSuggestions`
- [ ] Integrate with existing `ExpertiseEventService`
- [ ] Create service tests

### **Week 7: Payment Services**
- [ ] Extend `PaymentService`
  - [ ] `hasPartnership`
  - [ ] `calculatePartnershipRevenueSplit`
  - [ ] `distributePartnershipPayment`
- [ ] Create `RevenueSplitService`
  - [ ] `calculateNWaySplit`
  - [ ] `lockSplit`
  - [ ] `distributePayments`
- [ ] Create `PayoutService`
  - [ ] `schedulePayout`
  - [ ] `trackEarnings`
- [ ] Create service tests

---

## 📝 Implementation Notes

### **Service Initialization**
Services should be initialized in dependency injection container:
```dart
// In injection_container.dart
final businessService = BusinessService();
final partnershipService = PartnershipService(
  eventService: expertiseEventService,
  businessService: businessService,
);
final partnershipMatchingService = PartnershipMatchingService(
  partnershipService: partnershipService,
);
```

### **Service Testing**
All services should have comprehensive tests:
- Unit tests for each method
- Integration tests for service interactions
- Mock dependencies for isolated testing

### **Error Handling**
All services should:
- Log errors consistently
- Return meaningful error messages
- Handle edge cases gracefully
- Validate inputs before processing

---

**Last Updated:** November 23, 2025  
**Status:** ✅ Service Architecture Complete - Ready for Week 6 Implementation

