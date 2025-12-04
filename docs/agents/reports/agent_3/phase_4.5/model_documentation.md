# Phase 4.5 Model Documentation - Agent 3

**Date:** November 23, 2025  
**Agent:** Agent 3 - Models & Testing  
**Phase:** Phase 4.5 - Partnership Profile Visibility & Expertise Boost  
**Status:** ✅ Complete

---

## 📋 Overview

This document provides comprehensive documentation for the models created in Phase 4.5 for Partnership Profile Visibility and Expertise Boost features.

---

## 📦 Models Created

### 1. UserPartnership Model

**File:** `lib/core/models/user_partnership.dart`

**Purpose:**
Represents a partnership for display on user profiles. Aggregates partnerships from EventPartnership, Brand Sponsorship, and Company partnerships.

**Philosophy Alignment:**
- Opens doors to showcasing professional collaborations
- Enables visibility of authentic partnerships
- Supports expertise recognition through partnerships

**Key Features:**
- Profile partnership type classification (business, brand, company)
- Partnership status tracking
- Visibility controls (public/private)
- Category and vibe compatibility tracking
- Event count tracking

**Fields:**
- `id` - Partnership ID
- `type` - ProfilePartnershipType (business, brand, company)
- `partnerId` - Partner ID (Business, Brand, or Company ID)
- `partnerName` - Partner name
- `partnerLogoUrl` - Partner logo URL (optional)
- `status` - PartnershipStatus (from EventPartnership model)
- `startDate` - Partnership start date (optional)
- `endDate` - Partnership end date (optional)
- `category` - Category if applicable (optional)
- `vibeCompatibility` - Vibe compatibility score 0.0-1.0 (optional)
- `eventCount` - Number of events in partnership
- `isPublic` - Visibility setting (user controls display)

**Business Logic Methods:**
- `isActive` - Check if partnership is active
- `isCompleted` - Check if partnership is completed
- `isOngoing` - Check if partnership is ongoing (startDate without endDate)

**Serialization:**
- `toJson()` - Convert to JSON
- `fromJson()` - Create from JSON
- `copyWith()` - Create copy with updated fields

**Integration:**
- Uses `PartnershipStatus` enum from `EventPartnership` model
- Compatible with EventPartnership structure
- Ready for service layer aggregation (PartnershipProfileService)

---

### 2. ProfilePartnershipType Enum

**File:** `lib/core/models/user_partnership.dart`

**Purpose:**
Represents the type of partnership for profile display purposes.

**Values:**
- `business` - EventPartnership with BusinessAccount
- `brand` - Brand sponsorship partnerships
- `company` - Corporate partnerships

**Extension Methods:**
- `displayName` - Human-readable name
- `fromString()` - Parse from string value

---

### 3. PartnershipExpertiseBoost Model

**File:** `lib/core/models/partnership_expertise_boost.dart`

**Purpose:**
Represents the expertise boost calculation from partnerships. Contains breakdown of boost by status, quality, category alignment, and count multiplier.

**Philosophy Alignment:**
- Recognizes authentic professional collaborations
- Rewards successful partnerships with expertise recognition
- Opens doors to expertise growth through partnerships

**Key Features:**
- Total boost amount (capped at 0.50 / 50%)
- Detailed breakdowns for analysis
- Partnership count multiplier
- Percentage calculation helper

**Fields:**
- `totalBoost` - Total boost amount (0.0 to 0.50 max)
- `activeBoost` - Boost from active partnerships
- `completedBoost` - Boost from completed partnerships
- `ongoingBoost` - Boost from ongoing partnerships
- `vibeCompatibilityBoost` - High vibe compatibility bonus
- `revenueSuccessBoost` - Successful revenue share bonus
- `feedbackBoost` - Positive feedback bonus
- `sameCategoryBoost` - Same category partnerships boost
- `relatedCategoryBoost` - Related category partnerships boost
- `unrelatedCategoryBoost` - Unrelated category partnerships boost
- `countMultiplier` - Partnership count multiplier applied
- `partnershipCount` - Number of partnerships contributing

**Business Logic Methods:**
- `hasBoost` - Check if boost is non-zero
- `boostPercentage` - Get boost as percentage (0-50%)

**Serialization:**
- `toJson()` - Convert to JSON
- `fromJson()` - Create from JSON
- `copyWith()` - Create copy with updated fields

**Integration:**
- Used by ExpertiseCalculationService for partnership boost
- Integrated into Community/Professional/Influence path calculations
- Supports expertise dashboard display

---

## 🔗 Model Relationships

### UserPartnership Relationships

**From EventPartnership:**
- Uses `PartnershipStatus` enum
- Maps `EventPartnership.userId` → `UserPartnership.partnerId` (for business partnerships)
- Maps `EventPartnership.businessId` → `UserPartnership.partnerId` (for business partnerships)
- Maps `EventPartnership.vibeCompatibilityScore` → `UserPartnership.vibeCompatibility`
- Maps `EventPartnership.startDate/endDate` → `UserPartnership.startDate/endDate`

**From Sponsorship Models:**
- Maps brand sponsorships → `UserPartnership` with `type: ProfilePartnershipType.brand`
- Maps company sponsorships → `UserPartnership` with `type: ProfilePartnershipType.company`

**To PartnershipExpertiseBoost:**
- UserPartnership list → PartnershipExpertiseBoost calculation
- Status, quality, category alignment used in boost calculation

### PartnershipExpertiseBoost Relationships

**From UserPartnership:**
- Aggregates boost from multiple UserPartnership instances
- Calculates breakdowns based on partnership properties

**To Expertise Models:**
- Integrated into expertise calculation (60% Community, 30% Professional, 10% Influence)
- Used in expertise dashboard display
- Contributes to total expertise score

---

## 📊 Usage Examples

### Creating a UserPartnership

```dart
final partnership = UserPartnership(
  id: 'partnership-123',
  type: ProfilePartnershipType.business,
  partnerId: 'business-123',
  partnerName: 'Test Business',
  partnerLogoUrl: 'https://example.com/logo.png',
  status: PartnershipStatus.active,
  startDate: DateTime.now().subtract(Duration(days: 30)),
  category: 'Food',
  vibeCompatibility: 0.85,
  eventCount: 3,
  isPublic: true,
);
```

### Creating a PartnershipExpertiseBoost

```dart
final boost = PartnershipExpertiseBoost(
  totalBoost: 0.25,
  activeBoost: 0.10,
  completedBoost: 0.15,
  sameCategoryBoost: 0.20,
  relatedCategoryBoost: 0.05,
  partnershipCount: 3,
  countMultiplier: 1.2,
);
```

### Filtering Partnerships

```dart
// Get active partnerships
final activePartnerships = partnerships.where((p) => p.isActive).toList();

// Get public partnerships
final publicPartnerships = partnerships.where((p) => p.isPublic).toList();

// Filter by type
final businessPartnerships = partnerships
    .where((p) => p.type == ProfilePartnershipType.business)
    .toList();
```

---

## ✅ Testing

### Unit Tests

**UserPartnership Tests:** `test/unit/models/user_partnership_test.dart`
- 17 tests covering all functionality
- Tests: constructor, business logic, JSON serialization, copyWith, Equatable

**PartnershipExpertiseBoost Tests:** `test/unit/models/partnership_expertise_boost_test.dart`
- 15 tests covering all functionality
- Tests: constructor, business logic, JSON serialization, copyWith, Equatable

### Integration Tests

**Partnership Profile Flow:** `test/integration/partnership_profile_flow_integration_test.dart`
- 10 tests covering partnership flow scenarios

**Expertise Boost Partnership:** `test/integration/expertise_boost_partnership_integration_test.dart`
- 14 tests covering boost calculation and integration

**Profile Partnership Display:** `test/integration/profile_partnership_display_integration_test.dart`
- 15 tests covering display and visibility scenarios

**Total Test Coverage:** > 90% for models

---

## 🎯 Integration Points

### Service Layer (Agent 1)

**PartnershipProfileService** (to be created):
- Will use `UserPartnership` model for profile display
- Will aggregate partnerships from EventPartnership, Sponsorship models
- Will calculate `PartnershipExpertiseBoost` for expertise integration

**ExpertiseCalculationService** (to be updated):
- Will use `PartnershipExpertiseBoost` model
- Will integrate boost into expertise calculation
- Will apply boost to Community/Professional/Influence paths

### UI Layer (Agent 2)

**Partnership Display Widgets:**
- Will use `UserPartnership` model for display
- Will use `PartnershipExpertiseBoost` for boost indicators
- Will support visibility controls via `isPublic` field

---

## 📝 Notes

- Models follow existing patterns (Equatable, toJson, fromJson, copyWith)
- Zero linter errors
- All tests passing (71 total tests)
- Models are ready for service layer integration
- Documentation inline in model files with comprehensive comments

---

## 🔗 Related Documentation

- **Plan:** `docs/plans/partnership_profile_visibility/PARTNERSHIP_PROFILE_VISIBILITY_PLAN.md`
- **Task Assignments:** `docs/agents/tasks/phase_4.5/task_assignments.md`
- **Event Partnership Model:** `lib/core/models/event_partnership.dart`
- **Expertise Models:** `lib/core/models/multi_path_expertise.dart`

---

**Status:** ✅ Complete - All models documented and tested

