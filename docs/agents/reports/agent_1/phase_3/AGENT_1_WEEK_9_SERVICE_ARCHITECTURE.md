# Agent 1 Week 9: Brand Sponsorship Service Architecture Plan

**Date:** November 23, 2025  
**Agent:** Agent 1 - Backend & Integration Specialist  
**Phase:** Phase 3 - Advanced Features (Brand Sponsorship)  
**Week:** Week 9 - Brand Sponsorship Foundation (Service Architecture)  
**Status:** ✅ **COMPLETE**

---

## 🎯 Overview

This document outlines the service architecture for Brand Sponsorship services, including design patterns, service responsibilities, and implementation structure.

---

## 🏗️ Service Architecture Overview

### **Core Services (Week 10)**

1. **SponsorshipService** (~450 lines)
   - Sponsorship management (CRUD)
   - Sponsorship status transitions
   - Eligibility checking
   - Integration with Partnership system

2. **BrandDiscoveryService** (~350 lines)
   - Brand search functionality
   - Event search for brands
   - Vibe-based matching algorithm
   - Compatibility scoring
   - Sponsorship suggestions

3. **ProductTrackingService** (~400 lines)
   - Product contribution tracking
   - Product sales tracking
   - Revenue attribution
   - Inventory management
   - Sales reports

### **Extended Services (Week 11)**

4. **RevenueSplitService Extension** (~200 lines added)
   - N-way brand revenue splits
   - Product sales revenue splits
   - Hybrid sponsorship splits

5. **ProductSalesService** (~300 lines)
   - Product sales processing
   - Sales tracking at events
   - Revenue calculation
   - Sales reports

6. **BrandAnalyticsService** (~350 lines)
   - ROI tracking for brands
   - Performance metrics
   - Brand exposure analytics
   - Event performance tracking

---

## 📐 Service Design Patterns

### **Pattern 1: Service Structure**

All services follow the existing pattern from PartnershipService:

```dart
class SponsorshipService {
  static const String _logName = 'SponsorshipService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  // Dependencies (read-only)
  final ExpertiseEventService _eventService;
  final PartnershipService _partnershipService;
  final BusinessService _businessService;
  
  // In-memory storage (in production, use database)
  final Map<String, Sponsorship> _sponsorships = {};
  
  PartnershipService({
    required ExpertiseEventService eventService,
    required PartnershipService partnershipService,
    required BusinessService businessService,
  }) : _eventService = eventService,
       _partnershipService = partnershipService,
       _businessService = businessService;
}
```

### **Pattern 2: CRUD Operations**

Standard CRUD pattern:

```dart
// Create
Future<Sponsorship> createSponsorship({...}) async {...}

// Read
Future<Sponsorship?> getSponsorshipById(String id) async {...}
Future<List<Sponsorship>> getSponsorshipsForEvent(String eventId) async {...}

// Update
Future<Sponsorship> updateSponsorshipStatus({...}) async {...}

// Delete (soft delete via status)
Future<void> cancelSponsorship(String id) async {...}
```

### **Pattern 3: Status Management**

Status transition pattern (similar to PartnershipService):

```dart
enum SponsorshipStatus {
  pending,    // Initial state
  proposed,   // Proposal sent
  negotiating, // Under negotiation
  approved,   // Approved by all parties
  locked,     // Locked before event
  active,     // Event active
  completed,  // Event completed
  cancelled,  // Cancelled
}

// Status transitions
bool _isValidStatusTransition(SponsorshipStatus from, SponsorshipStatus to) {
  // Define valid transitions
}
```

### **Pattern 4: Validation Pattern**

Consistent validation pattern:

```dart
Future<bool> checkSponsorshipEligibility({
  required String eventId,
  required String brandId,
}) async {
  // 1. Validate event exists
  final event = await _eventService.getEventById(eventId);
  if (event == null) return false;
  
  // 2. Validate brand exists and is verified
  // (BrandAccount validation - to be implemented)
  
  // 3. Check event status
  if (event.status != EventStatus.published) return false;
  
  // 4. Check compatibility (70%+ threshold)
  final compatibility = await calculateCompatibility(...);
  if (compatibility < 0.70) return false;
  
  return true;
}
```

---

## 🔧 Service Responsibilities

### **1. SponsorshipService**

**Responsibilities:**
- Create sponsorships
- Manage sponsorship lifecycle
- Check sponsorship eligibility
- Update sponsorship status
- Integrate with Partnership system

**Key Methods:**
```dart
// Core operations
Future<Sponsorship> createSponsorship({
  required String eventId,
  required String brandId,
  required SponsorshipType type,
  double? contributionAmount,
  double? productValue,
  Map<String, dynamic>? agreementTerms,
}) async {...}

Future<List<Sponsorship>> getSponsorshipsForEvent(String eventId) async {...}

Future<Sponsorship> updateSponsorshipStatus({
  required String sponsorshipId,
  required SponsorshipStatus status,
}) async {...}

// Eligibility and validation
Future<bool> checkSponsorshipEligibility({
  required String eventId,
  required String brandId,
}) async {...}

Future<double> calculateCompatibility({
  required String eventId,
  required String brandId,
}) async {...}
```

**Dependencies:**
- `ExpertiseEventService` (read-only) - Event validation
- `PartnershipService` (read-only) - Partnership checking
- `BusinessService` (read-only) - Business validation
- `BrandAccount` model - Brand data

---

### **2. BrandDiscoveryService**

**Responsibilities:**
- Brand search for events
- Event search for brands
- Vibe-based matching
- Compatibility scoring
- Sponsorship suggestions

**Key Methods:**
```dart
// Brand search for events
Future<List<BrandMatch>> findBrandsForEvent({
  required String eventId,
  Map<String, dynamic>? searchCriteria,
  double minCompatibility = 0.70,
}) async {...}

// Event search for brands
Future<List<EventMatch>> findEventsForBrand({
  required String brandId,
  Map<String, dynamic>? searchCriteria,
  double minCompatibility = 0.70,
}) async {...}

// Vibe matching
Future<double> calculateBrandEventCompatibility({
  required String brandId,
  required String eventId,
}) async {...}

// Sponsorship suggestions
Future<List<SponsorshipSuggestion>> getSponsorshipSuggestions({
  required String eventId,
}) async {...}
```

**Dependencies:**
- `ExpertiseEventService` (read-only) - Event data
- `BrandAccount` model - Brand data
- PartnershipMatchingService (reference) - Vibe matching algorithm

---

### **3. ProductTrackingService**

**Responsibilities:**
- Track product contributions
- Track product sales
- Calculate revenue attribution
- Manage inventory
- Generate sales reports

**Key Methods:**
```dart
// Product contribution
Future<ProductTracking> recordProductContribution({
  required String sponsorshipId,
  required String productName,
  required int quantityProvided,
  required double unitPrice,
  String? sku,
  String? description,
}) async {...}

// Product sales
Future<void> recordProductSale({
  required String productTrackingId,
  required int quantity,
  required double unitPrice,
  required String saleId,
}) async {...}

// Revenue attribution
Future<Map<String, double>> calculateRevenueAttribution({
  required String productTrackingId,
}) async {...}

// Inventory management
Future<ProductTracking> updateProductQuantity({
  required String productTrackingId,
  int? quantitySold,
  int? quantityGivenAway,
  int? quantityUsedInEvent,
}) async {...}

// Reports
Future<ProductSalesReport> generateSalesReport({
  required String sponsorshipId,
  DateTime? startDate,
  DateTime? endDate,
}) async {...}
```

**Dependencies:**
- `SponsorshipService` - Link to sponsorships
- `PaymentService` - Track sales revenue
- `RevenueSplitService` - Revenue attribution

---

### **4. RevenueSplitService Extension (Week 11)**

**New Responsibilities:**
- N-way brand revenue splits (3+ parties)
- Product sales revenue splits
- Hybrid sponsorship splits (cash + product)

**Extended Methods:**
```dart
// N-way brand split
Future<RevenueSplit> calculateNWayBrandSplit({
  required String eventId,
  required double totalAmount,
  required List<SplitParty> parties, // Includes brands
}) async {...}

// Product sales split
Future<RevenueSplit> calculateProductSalesSplit({
  required String productTrackingId,
  required double totalSales,
}) async {...}

// Hybrid split (cash + product)
Future<Map<String, RevenueSplit>> calculateHybridSplit({
  required String eventId,
  required double cashAmount,
  required double productSalesAmount,
  required List<SplitParty> parties,
}) async {...}
```

---

### **5. ProductSalesService (Week 11)**

**Responsibilities:**
- Process product sales at events
- Track product sales revenue
- Calculate product revenue splits
- Generate sales reports

**Key Methods:**
```dart
// Process sale
Future<ProductSale> processProductSale({
  required String productTrackingId,
  required int quantity,
  required String buyerId,
  required PaymentMethod paymentMethod,
}) async {...}

// Calculate revenue
Future<double> calculateProductRevenue({
  required String sponsorshipId,
  DateTime? startDate,
  DateTime? endDate,
}) async {...}

// Generate reports
Future<ProductSalesReport> generateEventSalesReport({
  required String eventId,
}) async {...}
```

**Dependencies:**
- `ProductTrackingService` - Product inventory
- `PaymentService` - Sales processing
- `RevenueSplitService` - Revenue splits

---

### **6. BrandAnalyticsService (Week 11)**

**Responsibilities:**
- Track ROI for brands
- Calculate performance metrics
- Analyze brand exposure
- Track event performance

**Key Methods:**
```dart
// ROI tracking
Future<BrandROI> calculateBrandROI({
  required String brandId,
  DateTime? startDate,
  DateTime? endDate,
}) async {...}

// Performance metrics
Future<BrandPerformance> getBrandPerformance({
  required String brandId,
}) async {...}

// Exposure analytics
Future<BrandExposure> analyzeBrandExposure({
  required String brandId,
  required String eventId,
}) async {...}

// Event performance
Future<EventPerformance> getEventPerformance({
  required String eventId,
}) async {...}
```

**Dependencies:**
- `SponsorshipService` - Sponsorship data
- `ProductTrackingService` - Product sales data
- `PaymentService` - Revenue data

---

## 🔗 Service Integration Points

### **Integration Matrix**

| Service | ExpertiseEventService | PartnershipService | BusinessService | PaymentService | RevenueSplitService |
|---------|----------------------|-------------------|-----------------|----------------|---------------------|
| SponsorshipService | Read-only | Read-only | Read-only | - | - |
| BrandDiscoveryService | Read-only | - | - | - | - |
| ProductTrackingService | - | - | - | Read-only | Read-only |
| ProductSalesService | - | - | - | Write | Read-only |
| BrandAnalyticsService | Read-only | Read-only | - | Read-only | Read-only |

### **Integration Flow**

```
1. Event Created (ExpertiseEventService)
   ↓
2. Partnership Created (PartnershipService) [optional]
   ↓
3. Brand Discovery (BrandDiscoveryService)
   ↓
4. Sponsorship Created (SponsorshipService)
   ↓
5. Product Contribution (ProductTrackingService) [if product sponsorship]
   ↓
6. Revenue Split Calculated (RevenueSplitService) [includes brands]
   ↓
7. Event Happens
   ↓
8. Product Sales (ProductSalesService) [if products sold]
   ↓
9. Payment Distribution (PaymentService)
   ↓
10. Analytics (BrandAnalyticsService)
```

---

## 📊 Data Flow

### **Sponsorship Creation Flow**

```
1. User/Brand initiates sponsorship
   ↓
2. SponsorshipService.validateEvent()
   ↓
3. SponsorshipService.checkEligibility()
   ↓
4. BrandDiscoveryService.calculateCompatibility()
   ↓
5. SponsorshipService.createSponsorship()
   ↓
6. Link to event and partnerships
   ↓
7. Return sponsorship
```

### **Product Sales Flow**

```
1. Product sold at event
   ↓
2. ProductSalesService.processProductSale()
   ↓
3. ProductTrackingService.recordProductSale()
   ↓
4. ProductTrackingService.calculateRevenueAttribution()
   ↓
5. RevenueSplitService.calculateProductSalesSplit()
   ↓
6. PaymentService.distributeRevenue()
```

### **Revenue Distribution Flow**

```
1. Event completed
   ↓
2. RevenueSplitService.calculateNWayBrandSplit()
   ├─ Calculate platform fee (10%)
   ├─ Calculate processing fee (~3%)
   ├─ Calculate remaining amount
   └─ Distribute to parties (user + business + brands)
   ↓
3. PaymentService.distributeRevenue()
   ↓
4. PayoutService.schedulePayouts() (2 days after event)
```

---

## ✅ Implementation Checklist

### **Week 10:**
- [ ] Create SponsorshipService
  - [ ] CRUD operations
  - [ ] Status management
  - [ ] Eligibility checking
  - [ ] Integration with PartnershipService
- [ ] Create BrandDiscoveryService
  - [ ] Brand search for events
  - [ ] Event search for brands
  - [ ] Vibe matching algorithm
  - [ ] Compatibility scoring
- [ ] Create ProductTrackingService
  - [ ] Product contribution tracking
  - [ ] Product sales tracking
  - [ ] Revenue attribution
  - [ ] Inventory management

### **Week 11:**
- [ ] Extend RevenueSplitService
  - [ ] N-way brand splits
  - [ ] Product sales splits
  - [ ] Hybrid splits
- [ ] Create ProductSalesService
  - [ ] Sales processing
  - [ ] Revenue calculation
  - [ ] Sales reports
- [ ] Create BrandAnalyticsService
  - [ ] ROI tracking
  - [ ] Performance metrics
  - [ ] Exposure analytics

### **Week 12:**
- [ ] Integration testing
- [ ] End-to-end testing
- [ ] Performance testing
- [ ] Bug fixes
- [ ] Documentation

---

## 🎯 Quality Standards

- ✅ Zero linter errors
- ✅ 100% design token adherence (where applicable)
- ✅ Follow existing service patterns
- ✅ All services have tests
- ✅ Vibe matching uses 70%+ threshold
- ✅ N-way splits work correctly
- ✅ Product tracking works correctly
- ✅ Integration with existing services works

---

**Last Updated:** November 23, 2025  
**Status:** ✅ **COMPLETE**  
**Next:** Week 10 - Brand Sponsorship Services Implementation

