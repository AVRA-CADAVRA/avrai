# Locality Value Analysis System

**Created:** November 24, 2025  
**Status:** 📋 Documentation  
**Purpose:** Document the locality value analysis system for dynamic local expert qualification

---

## 🎯 **Overview**

The locality value analysis system analyzes what users interact with most in each locality to determine locality-specific values and preferences. This enables dynamic thresholds that adapt to what each locality actually values, allowing local experts to qualify based on what their community cares about.

---

## 🎓 **Philosophy**

**Local experts shouldn't have to expand past their locality to be qualified.** They can be experts in their neighborhood without needing city-wide expertise. Thresholds adapt to what the locality actually values.

### **Key Principle**

**What users interact with most in each locality should take precedence in determining thresholds.**

**Example:**
- In Greenpoint, users interact heavily with coffee lists and events
- Coffee expertise threshold might be **lower** (easier to achieve) because it's what the community values
- In same locality, users don't interact much with art galleries
- Art gallery expertise threshold might be **higher** (harder to achieve) because it's less valued by the community

---

## 📊 **What This Tracks**

The system tracks all user activities in each locality:

1. **Events Hosted** - Frequency, success rate, engagement
2. **Lists Created** - Popularity, respects, active engagement
3. **Reviews Written** - Quality, peer endorsements, community value
4. **Event Attendance** - Engagement, return rate, community participation
5. **Professional Background** - Credentials, experience, verification
6. **Positive Activity Trends** - Category + locality engagement over time

---

## 🔧 **How This Works**

### **1. Activity Tracking**

The system records all user activities in each locality:

```dart
await valueService.recordActivity(
  locality: 'Greenpoint',
  activityType: 'events_hosted',
  category: 'Coffee',
  engagement: 1.0,
);
```

### **2. Value Analysis**

The system analyzes activities to determine what the locality values:

```dart
final valueData = await valueService.analyzeLocalityValues('Greenpoint');
```

**Analysis Process:**
- Counts all activities by type in the locality
- Calculates engagement levels
- Determines activity frequency
- Normalizes weights to sum to 1.0

### **3. Activity Weights**

The system calculates weights for different activities:

```dart
final weights = await valueService.getActivityWeights('Greenpoint');
// Returns: {
//   'events_hosted': 0.30,
//   'lists_created': 0.25,
//   'reviews_written': 0.20,
//   'event_attendance': 0.15,
//   'professional_background': 0.10,
//   'positive_trends': 0.0,
// }
```

**Weight Interpretation:**
- **High weight (≥0.25):** Activity is highly valued by locality → Lower threshold
- **Medium weight (0.15-0.25):** Activity is moderately valued → Standard threshold
- **Low weight (<0.15):** Activity is less valued → Higher threshold

### **4. Category Preferences**

The system tracks category-specific preferences:

```dart
final preferences = await valueService.getCategoryPreferences(
  'Greenpoint',
  'Coffee',
);
```

**Category-Specific Analysis:**
- Tracks activities by category within locality
- Calculates category-specific weights
- Enables category-specific threshold adjustments

---

## 📋 **Qualification Factors**

Users become local experts when they meet these factors (adjusted by locality values):

1. **Lists that others follow** (locality-focused)
   - Popular lists in the locality
   - Active respects and engagement
   - Community recognition

2. **Event attendance and hosting**
   - Successful event hosting
   - Regular event attendance
   - Community engagement through events

3. **Professional background**
   - Credentials and experience
   - Verification status
   - Proof of work

4. **Peer-reviewed reviews**
   - Reviews with peer endorsements
   - Quality contributions
   - Community trust

5. **Positive activity trends**
   - Consistent engagement with category + locality
   - Quality contributions over time
   - Growing community involvement

---

## 🔄 **Dynamic Updates**

The system updates dynamically as locality behavior changes:

1. **Activity Recording:** New activities are recorded in real-time
2. **Value Recalculation:** Locality values are recalculated periodically
3. **Threshold Adjustment:** Thresholds adjust based on updated values
4. **Qualification Re-evaluation:** User qualifications are re-evaluated with new thresholds

**Update Frequency:**
- **Real-time:** Activity recording
- **Daily:** Value analysis recalculation
- **Weekly:** Threshold adjustment
- **On-demand:** Qualification re-evaluation

---

## 🧪 **Testing**

### **Test Infrastructure**

- **Test Helpers:** `IntegrationTestHelpers.createTestLocalityValue()` - Creates locality value for testing
- **Test Fixtures:** `IntegrationTestFixtures.localityValueFixture()` - Pre-configured locality value scenario
- **Integration Tests:** `locality_value_integration_test.dart` - Tests locality value analysis

### **Test Coverage**

- ✅ Locality value analysis logic
- ✅ Activity weight calculation
- ✅ Category preferences
- ✅ Activity recording and updates
- ✅ Dynamic threshold integration

---

## 📊 **Examples**

### **Example 1: Coffee-Focused Locality**

```dart
// Greenpoint values coffee events highly
final value = LocalityValue(
  locality: 'Greenpoint',
  activityWeights: {
    'events_hosted': 0.35, // High weight
    'lists_created': 0.25,
    'reviews_written': 0.20,
    'event_attendance': 0.15,
    'professional_background': 0.05,
    'positive_trends': 0.0,
  },
);

// Coffee expertise threshold is LOWER (easier to achieve)
// Because locality values events highly
```

### **Example 2: Art Gallery Locality**

```dart
// Locality doesn't value art galleries as much
final value = LocalityValue(
  locality: 'Greenpoint',
  activityWeights: {
    'events_hosted': 0.10, // Low weight for art
    'lists_created': 0.15,
    'reviews_written': 0.30, // High weight (reviews matter more)
    'event_attendance': 0.20,
    'professional_background': 0.20,
    'positive_trends': 0.05,
  },
);

// Art gallery expertise threshold is HIGHER (harder to achieve)
// Because locality values art events less
```

### **Example 3: Qualification Progress**

```dart
final qualification = LocalExpertQualification(
  userId: 'user-123',
  category: 'Coffee',
  locality: 'Greenpoint',
  progress: QualificationProgress(
    visits: 5,
    ratings: 3,
    avgRating: 4.5,
    communityEngagement: 1,
    listCuration: 1,
    eventHosting: 0,
  ),
  factors: QualificationFactors(
    listsWithFollowers: 2,
    hasPositiveTrends: true,
  ),
);

// Progress: 67% (4 of 6 thresholds met)
// Remaining: 2 visits, 1 rating, 1 community engagement, 1 event hosting
```

---

## 🚨 **Important Notes**

1. **Locality-Specific:** Values are calculated per locality, not globally
2. **Category-Specific:** Preferences can vary by category within same locality
3. **Dynamic:** Values update as community behavior changes
4. **Normalized:** Activity weights always sum to 1.0
5. **Cached:** Values are cached for performance, updated periodically

---

## 📚 **Related Documentation**

- **Dynamic Thresholds:** `docs/plans/expertise_system/DYNAMIC_THRESHOLD_CALCULATION.md`
- **Geographic Hierarchy:** `docs/plans/expertise_system/GEOGRAPHIC_HIERARCHY_SYSTEM.md`
- **Requirements:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
- **Implementation Plan:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`

---

**Last Updated:** November 24, 2025  
**Status:** Active Documentation

