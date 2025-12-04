# Brand Sponsorship Model Relationships

**Date:** November 23, 2025  
**Agent:** Agent 3 - Models & Testing  
**Phase:** Phase 3, Week 10 - Model Integration & Testing  
**Status:** ✅ Complete

---

## 📋 Overview

This document describes the relationships between Brand Sponsorship models and existing Partnership models. It provides a comprehensive guide to how models integrate and work together.

---

## 🔗 Model Relationship Diagram

```
EventPartnership
    │
    ├──→ Sponsorship (1-to-many)
    │       │
    │       ├──→ BrandAccount (many-to-1)
    │       ├──→ ProductTracking (1-to-many)
    │       └──→ RevenueSplit (via brandId in parties)
    │
    ├──→ MultiPartySponsorship (1-to-1)
    │       │
    │       ├──→ Multiple BrandAccounts (many-to-many)
    │       └──→ RevenueSplit (N-way configuration)
    │
    └──→ BrandDiscovery (1-to-1)
            │
            └──→ BrandMatch (1-to-many)
                    └──→ BrandAccount (reference)
```

---

## 🔄 Core Relationships

### **1. EventPartnership ↔ Sponsorship**

**Relationship Type:** One-to-Many  
**Link Field:** `eventId`

**Description:**
- An `EventPartnership` can have multiple `Sponsorship` records
- Each `Sponsorship` references the same `eventId` as the partnership
- Sponsorships are additional brand contributions to the partnership event

**Usage:**
```dart
// Check if partnership has sponsorships
final hasSponsors = partnership.hasSponsorships([sponsorship1, sponsorship2]);

// Get all sponsorships for a partnership
final eventSponsorships = partnership.getSponsorships([sponsorship1, sponsorship2]);

// Get total sponsorship value
final totalValue = partnership.getTotalSponsorshipValue([sponsorship1, sponsorship2]);
```

**Integration Methods:**
- `EventPartnership.hasSponsorships(List<Sponsorship>)`
- `EventPartnership.getSponsorships(List<Sponsorship>)`
- `EventPartnership.getTotalSponsorshipValue(List<Sponsorship>)`

---

### **2. Sponsorship ↔ BrandAccount**

**Relationship Type:** Many-to-One  
**Link Field:** `brandId` (in Sponsorship) → `id` (in BrandAccount)

**Description:**
- Multiple `Sponsorship` records can reference the same `BrandAccount`
- Each `Sponsorship` has a `brandId` that links to a `BrandAccount.id`
- Brand must be verified (`BrandVerificationStatus.verified`) to sponsor events

**Usage:**
```dart
// Get brand for a sponsorship
final brand = brands.firstWhere((b) => b.id == sponsorship.brandId);

// Check if brand can sponsor
if (brand.isVerified && brand.canSponsor) {
  // Brand can create sponsorship
}
```

**Validation:**
- `BrandAccount.isVerified` must be `true`
- `BrandAccount.canSponsor` must be `true`

---

### **3. Sponsorship ↔ ProductTracking**

**Relationship Type:** One-to-Many  
**Link Field:** `sponsorshipId` (in ProductTracking) → `id` (in Sponsorship)

**Description:**
- A `Sponsorship` can have multiple `ProductTracking` records
- Each `ProductTracking` references the `Sponsorship.id` via `sponsorshipId`
- Used for product/in-kind sponsorships to track sales and inventory

**Usage:**
```dart
// Get product tracking for a sponsorship
final tracking = SponsorshipIntegration.getProductTrackingForSponsorship(
  sponsorship,
  productTrackingList,
);

// Get total product sales
final totalSales = SponsorshipIntegration.getTotalProductSalesForSponsorship(
  sponsorship,
  productTrackingList,
);
```

**Integration Methods:**
- `SponsorshipIntegration.getProductTrackingForSponsorship()`
- `SponsorshipIntegration.getTotalProductSalesForSponsorship()`

---

### **4. Sponsorship ↔ RevenueSplit**

**Relationship Type:** Many-to-Many (via SplitParty)  
**Link Field:** `brandId` (in Sponsorship) → `partyId` (in SplitParty)

**Description:**
- `Sponsorship` records can be included in `RevenueSplit` calculations
- Brands appear as `SplitParty` with `type: SplitPartyType.sponsor`
- The `partyId` in `SplitParty` matches the `brandId` in `Sponsorship`

**Usage:**
```dart
// Check if revenue split includes sponsorships
final includesSponsors = SponsorshipIntegration.revenueSplitIncludesSponsorships(
  revenueSplit,
  [sponsorship1, sponsorship2],
);

// Create revenue split with sponsor
final revenueSplit = RevenueSplit.nWay(
  id: 'split-123',
  eventId: 'event-456',
  totalAmount: 1000.00,
  ticketsSold: 20,
  parties: [
    SplitParty(
      partyId: sponsorship.brandId,
      type: SplitPartyType.sponsor,
      percentage: 20.0,
    ),
    // ... other parties
  ],
);
```

**Integration Methods:**
- `SponsorshipIntegration.revenueSplitIncludesSponsorships()`

---

### **5. EventPartnership ↔ MultiPartySponsorship**

**Relationship Type:** One-to-One  
**Link Field:** `eventId`

**Description:**
- An `EventPartnership` can have one `MultiPartySponsorship` record
- The `MultiPartySponsorship` references the same `eventId`
- Supports N-way brand partnerships (multiple brands per event)

**Usage:**
```dart
// Get brand IDs from multi-party sponsorship
final brandIds = SponsorshipIntegration.getBrandIdsFromMultiParty(multiParty);

// Check if individual sponsorship is part of multi-party
final isPartOf = SponsorshipIntegration.isPartOfMultiParty(
  sponsorship,
  multiParty,
);

// Get total contribution value
final totalValue = SponsorshipIntegration.getMultiPartyTotalValue(multiParty);
```

**Integration Methods:**
- `SponsorshipIntegration.getBrandIdsFromMultiParty()`
- `SponsorshipIntegration.isPartOfMultiParty()`
- `SponsorshipIntegration.getMultiPartyTotalValue()`

---

### **6. EventPartnership ↔ BrandDiscovery**

**Relationship Type:** One-to-One  
**Link Field:** `eventId`

**Description:**
- An `EventPartnership` can have one `BrandDiscovery` record
- The `BrandDiscovery` references the same `eventId`
- Used to find and match brands for sponsorship opportunities

**Usage:**
```dart
// Get discovery for an event
final discovery = SponsorshipIntegration.getDiscoveryForEvent(
  eventId,
  discoveries,
);

// Get viable brand matches (70%+ compatibility)
final viableMatches = SponsorshipIntegration.getViableBrandMatches(
  eventId,
  discoveries,
);

// Check if discovery has matches
final hasMatches = SponsorshipIntegration.hasDiscoveryMatches(
  eventId,
  discoveries,
);
```

**Integration Methods:**
- `SponsorshipIntegration.getDiscoveryForEvent()`
- `SponsorshipIntegration.getViableBrandMatches()`
- `SponsorshipIntegration.hasDiscoveryMatches()`

---

### **7. BrandDiscovery ↔ BrandMatch ↔ BrandAccount**

**Relationship Type:** One-to-Many-to-One  
**Link Fields:** `brandId` (in BrandMatch) → `id` (in BrandAccount)

**Description:**
- A `BrandDiscovery` contains multiple `BrandMatch` records
- Each `BrandMatch` references a `BrandAccount` via `brandId`
- Only matches with 70%+ compatibility are considered viable

**Usage:**
```dart
// Get viable matches from discovery
final viableMatches = discovery.viableMatches;

// Filter matches above threshold
final highMatches = discovery.matchingResults
    .where((m) => m.compatibilityScore >= 70.0)
    .toList();

// Get brand for a match
final brand = brands.firstWhere((b) => b.id == match.brandId);
```

**Validation:**
- `BrandMatch.meetsThreshold` must be `true` (70%+)
- `VibeCompatibility.meetsThreshold` must be `true`

---

## 🔧 Integration Utilities

### **SponsorshipIntegration Class**

The `SponsorshipIntegration` class provides static helper methods for working with sponsorship models:

**Partnership Integration:**
- `hasSponsorships()` - Check if partnership has sponsorships
- `getSponsorshipsForPartnership()` - Get all sponsorships for a partnership
- `getTotalSponsorshipValue()` - Calculate total sponsorship value

**Multi-Party Integration:**
- `getBrandIdsFromMultiParty()` - Extract brand IDs from multi-party sponsorship
- `isPartOfMultiParty()` - Check if sponsorship is part of multi-party
- `getMultiPartyTotalValue()` - Get total contribution value

**Revenue Split Integration:**
- `revenueSplitIncludesSponsorships()` - Check if revenue split includes sponsorships

**Product Tracking Integration:**
- `getProductTrackingForSponsorship()` - Get product tracking for a sponsorship
- `getTotalProductSalesForSponsorship()` - Calculate total product sales

**Brand Discovery Integration:**
- `getDiscoveryForEvent()` - Get brand discovery for an event
- `getViableBrandMatches()` - Get viable brand matches (70%+)
- `hasDiscoveryMatches()` - Check if discovery has viable matches

**Brand Integration:**
- `getBrandsFromSponsorships()` - Get brand accounts from sponsorships
- `getBrandIdsFromSponsorships()` - Extract brand IDs from sponsorships

**Status Queries:**
- `getActiveSponsorshipsCount()` - Count active sponsorships for an event
- `getApprovedSponsorshipsCount()` - Count approved sponsorships for an event

---

## 📊 Extension Methods

### **EventPartnershipSponsorshipExtension**

Extension methods added to `EventPartnership` for sponsorship integration:

```dart
// Check if partnership has sponsorships
bool hasSponsorships(List<Sponsorship> sponsorships)

// Get associated sponsorships
List<Sponsorship> getSponsorships(List<Sponsorship> sponsorships)

// Get total sponsorship value
double getTotalSponsorshipValue(List<Sponsorship> sponsorships)
```

---

## ✅ Relationship Validation

### **Required Validations:**

1. **Sponsorship → EventPartnership:**
   - `sponsorship.eventId` must match `partnership.eventId`
   - Sponsorship must be approved before event starts

2. **Sponsorship → BrandAccount:**
   - `sponsorship.brandId` must exist in `BrandAccount` collection
   - `BrandAccount.isVerified` must be `true`

3. **ProductTracking → Sponsorship:**
   - `productTracking.sponsorshipId` must match `sponsorship.id`
   - Sponsorship type must be `product` or `hybrid`

4. **MultiPartySponsorship:**
   - `revenueSplitConfiguration` must sum to 100%
   - All `brandIds` must reference valid `BrandAccount` records

5. **BrandDiscovery:**
   - `discovery.eventId` must match `partnership.eventId`
   - Only matches with 70%+ compatibility are viable

---

## 🧪 Testing

All model relationships are tested in:
- `test/integration/sponsorship_model_integration_test.dart`

**Test Coverage:**
- ✅ Sponsorship with Event Partnership
- ✅ Multi-Party Sponsorship Integration
- ✅ Product Tracking with Sponsorship
- ✅ Brand Discovery with Partnership Events
- ✅ Revenue Split with Sponsorships
- ✅ Model Relationship Verification

---

## 📝 Usage Examples

### **Example 1: Get All Sponsorships for an Event**

```dart
final partnership = getPartnership(eventId);
final allSponsorships = getAllSponsorships();
final eventSponsorships = partnership.getSponsorships(allSponsorships);
final totalValue = partnership.getTotalSponsorshipValue(allSponsorships);
```

### **Example 2: Create Multi-Party Sponsorship**

```dart
final multiParty = MultiPartySponsorship(
  id: 'multi-sponsor-123',
  eventId: partnership.eventId,
  brandIds: ['brand-1', 'brand-2', 'brand-3'],
  revenueSplitConfiguration: {
    'brand-1': 40.0,
    'brand-2': 35.0,
    'brand-3': 25.0,
  },
  agreementStatus: MultiPartyAgreementStatus.approved,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

### **Example 3: Track Product Sales**

```dart
final sponsorship = getSponsorship(sponsorshipId);
final productTracking = ProductTracking(
  id: 'product-track-123',
  sponsorshipId: sponsorship.id,
  productName: 'Premium Olive Oil',
  quantityProvided: 20,
  quantitySold: 15,
  unitPrice: 25.00,
  totalSales: 375.00,
  platformFee: 37.50,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

---

## 🎯 Philosophy Alignment

All model relationships align with SPOTS philosophy:

- **Opens doors** to brand partnerships
- **Enables** multi-party event ecosystems
- **Supports** transparent revenue sharing
- **Creates pathways** for brand collaboration

---

**Status:** ✅ Complete - All relationships documented and tested  
**Last Updated:** November 23, 2025, 11:53 AM CST

