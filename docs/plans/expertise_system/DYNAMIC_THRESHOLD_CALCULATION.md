# Dynamic Threshold Calculation

**Created:** November 24, 2025  
**Status:** 📋 Documentation  
**Purpose:** Document the dynamic threshold calculation system for local expert qualification

---

## 🎯 **Overview**

The dynamic threshold calculation system calculates locality-specific thresholds for local expert qualification. Thresholds adapt to what each locality actually values, enabling lower thresholds for activities valued by the locality and higher thresholds for activities less valued by the locality.

---

## 🎓 **Philosophy**

**Local experts shouldn't have to expand past their locality to be qualified.** Thresholds ebb and flow based on locality data, adapting to what the community actually values.

### **Key Principle**

**Thresholds adapt to locality values:**
- **Activities valued by locality** (high weight) → **Lower threshold** (easier to achieve)
- **Activities less valued by locality** (low weight) → **Higher threshold** (harder to achieve)

---

## 🔧 **How This Works**

### **1. Base Thresholds**

The system starts with base thresholds from `ExpertiseRequirements`:

```dart
const baseThresholds = ThresholdValues(
  minVisits: 10,
  minRatings: 5,
  minAvgRating: 4.0,
  minTimeInCategory: Duration(days: 30),
  minCommunityEngagement: 3,
  minListCuration: 2,
  minEventHosting: 1,
);
```

### **2. Locality Value Analysis**

The system gets activity weights from `LocalityValueAnalysisService`:

```dart
final activityWeights = await localityValueService.getCategoryPreferences(
  locality: 'Greenpoint',
  category: 'Coffee',
);
// Returns: {
//   'events_hosted': 0.35,  // High weight
//   'lists_created': 0.25,
//   'reviews_written': 0.20,
//   'event_attendance': 0.15,
//   'professional_background': 0.05,
//   'positive_trends': 0.0,
// }
```

### **3. Threshold Adjustment**

The system applies locality-specific adjustments:

```dart
final adjustedThresholds = await thresholdService.calculateLocalThreshold(
  locality: 'Greenpoint',
  category: 'Coffee',
  baseThresholds: baseThresholds,
);
```

**Adjustment Logic:**
- **High weight (≥0.3):** 0.7x multiplier (30% reduction)
- **Medium-high weight (0.25-0.3):** 0.85x multiplier (15% reduction)
- **Medium weight (0.2-0.25):** 1.0x multiplier (no change)
- **Medium-low weight (0.1-0.2):** 1.15x multiplier (15% increase)
- **Low weight (<0.1):** 1.3x multiplier (30% increase)

### **4. Component-Specific Adjustments**

Each threshold component is adjusted based on its corresponding activity:

- **`minVisits`** → Based on `event_attendance` weight
- **`minRatings`** → Based on `reviews_written` weight
- **`minEventHosting`** → Based on `events_hosted` weight
- **`minListCuration`** → Based on `lists_created` weight
- **`minCommunityEngagement`** → Based on `positive_trends` weight
- **`minAvgRating`** → No adjustment (quality doesn't change)
- **`minTimeInCategory`** → No adjustment (time doesn't change)

---

## 📊 **Adjustment Formula**

### **Activity Adjustment Calculation**

```dart
double calculateActivityAdjustment(double activityWeight) {
  if (activityWeight >= 0.3) {
    return 0.7;  // 30% reduction (easier)
  } else if (activityWeight >= 0.25) {
    return 0.85; // 15% reduction
  } else if (activityWeight >= 0.2) {
    return 1.0;  // No change
  } else if (activityWeight >= 0.1) {
    return 1.15; // 15% increase
  } else {
    return 1.3; // 30% increase (harder)
  }
}
```

### **Threshold Adjustment**

```dart
ThresholdValues applyLocalityAdjustments({
  required ThresholdValues baseThresholds,
  required Map<String, double> activityWeights,
}) {
  final visitsAdjustment = calculateActivityAdjustment(
    activityWeights['event_attendance'] ?? 0.167,
  );
  final ratingsAdjustment = calculateActivityAdjustment(
    activityWeights['reviews_written'] ?? 0.167,
  );
  // ... etc for each component

  return ThresholdValues(
    minVisits: (baseThresholds.minVisits * visitsAdjustment).ceil(),
    minRatings: (baseThresholds.minRatings * ratingsAdjustment).ceil(),
    minAvgRating: baseThresholds.minAvgRating, // No change
    minTimeInCategory: baseThresholds.minTimeInCategory, // No change
    // ... etc
  );
}
```

---

## 📋 **Examples**

### **Example 1: Coffee-Focused Locality (Lower Thresholds)**

**Base Thresholds:**
```dart
minVisits: 10
minRatings: 5
minEventHosting: 1
```

**Locality Values Events Highly:**
```dart
activityWeights: {
  'events_hosted': 0.35,  // High weight
  'event_attendance': 0.30, // High weight
  'reviews_written': 0.20,
  // ...
}
```

**Adjusted Thresholds:**
```dart
minVisits: 7        // 30% reduction (10 * 0.7)
minRatings: 5       // No change (0.20 weight = 1.0x)
minEventHosting: 1  // 30% reduction (1 * 0.7 = 0.7, ceil = 1)
```

**Result:** Easier to qualify as local expert in coffee (locality values coffee events)

### **Example 2: Art Gallery Locality (Higher Thresholds)**

**Base Thresholds:**
```dart
minVisits: 10
minRatings: 5
minEventHosting: 1
```

**Locality Values Art Events Less:**
```dart
activityWeights: {
  'events_hosted': 0.10,  // Low weight
  'event_attendance': 0.08, // Low weight
  'reviews_written': 0.30, // High weight (reviews matter more)
  // ...
}
```

**Adjusted Thresholds:**
```dart
minVisits: 13       // 30% increase (10 * 1.3)
minRatings: 4       // 20% reduction (5 * 0.85 = 4.25, ceil = 5, but reviews valued highly)
minEventHosting: 2  // 30% increase (1 * 1.3 = 1.3, ceil = 2)
```

**Result:** Harder to qualify as local expert in art galleries (locality values art events less)

### **Example 3: Balanced Locality (Standard Thresholds)**

**Base Thresholds:**
```dart
minVisits: 10
minRatings: 5
```

**Locality Has Balanced Values:**
```dart
activityWeights: {
  'events_hosted': 0.20,  // Medium weight
  'event_attendance': 0.20, // Medium weight
  'reviews_written': 0.20,
  // ...
}
```

**Adjusted Thresholds:**
```dart
minVisits: 10       // No change (1.0x multiplier)
minRatings: 5       // No change (1.0x multiplier)
```

**Result:** Standard thresholds (locality has balanced values)

---

## 🔄 **Threshold Ebb and Flow**

Thresholds update dynamically as locality behavior changes:

1. **New Activity:** User hosts coffee event in Greenpoint
2. **Value Update:** Locality value analysis updates `events_hosted` weight
3. **Threshold Recalculation:** Dynamic threshold service recalculates thresholds
4. **Qualification Update:** User qualifications are re-evaluated with new thresholds

**Example Flow:**
- **Week 1:** Greenpoint has low event hosting activity → High threshold (1.3x)
- **Week 4:** Community starts hosting more events → Weight increases to 0.25
- **Week 8:** Event hosting becomes highly valued (0.35 weight) → Threshold lowers to 0.7x
- **Result:** Easier to qualify as local expert (community values events)

---

## 🧪 **Testing**

### **Test Infrastructure**

- **Test Helpers:** `IntegrationTestHelpers.createTestQualification()` - Creates qualification for testing
- **Test Fixtures:** `IntegrationTestFixtures.thresholdValuesFixture()` - Pre-configured threshold scenario
- **Integration Tests:** `dynamic_threshold_integration_test.dart` - Tests threshold calculation

### **Test Coverage**

- ✅ Dynamic threshold calculation
- ✅ Activity adjustment logic
- ✅ Component-specific adjustments
- ✅ Locality multiplier calculation
- ✅ Integration with LocalityValueAnalysisService

---

## 🚨 **Important Notes**

1. **Adjustment Range:** 0.7x to 1.3x multiplier (30% reduction to 30% increase)
2. **Quality/Time Don't Scale:** `minAvgRating` and `minTimeInCategory` don't adjust (quality/time are absolute)
3. **Category-Specific:** Thresholds are calculated per category within locality
4. **Dynamic Updates:** Thresholds update as locality values change
5. **Backward Compatible:** Base thresholds remain valid if locality analysis unavailable

---

## 📚 **Related Documentation**

- **Locality Value Analysis:** `docs/plans/expertise_system/LOCALITY_VALUE_ANALYSIS_SYSTEM.md`
- **Geographic Hierarchy:** `docs/plans/expertise_system/GEOGRAPHIC_HIERARCHY_SYSTEM.md`
- **Requirements:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
- **Implementation Plan:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`

---

**Last Updated:** November 24, 2025  
**Status:** Active Documentation

