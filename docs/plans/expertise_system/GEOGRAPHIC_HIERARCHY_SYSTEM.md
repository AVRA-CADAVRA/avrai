# Geographic Hierarchy System

**Created:** November 24, 2025  
**Status:** 📋 Documentation  
**Purpose:** Document the geographic hierarchy system for local expert event hosting

---

## 🎯 **Overview**

The geographic hierarchy system enforces event hosting scope based on a user's expertise level. This ensures that local experts can host events in their locality, city experts can host in all localities in their city, and higher-level experts have broader hosting capabilities.

---

## 📍 **Geographic Hierarchy**

The hierarchy follows this structure:

```
Universal Expert
  └─ Can host in: Anywhere in the universe

Global Expert
  └─ Can host in: Anywhere globally

National Expert
  └─ Can host in: All states, cities, and localities in their nation

Regional Expert
  └─ Can host in: All cities and localities in their region/state

City Expert (e.g., NYC Expert)
  └─ Can host in: All localities/boroughs in their city (all 5 boroughs for NYC)
  └─ Can choose to host for specific locality, type of user, etc. (as long as in their city)

Local Expert (e.g., Brooklyn Local Expert)
  └─ Can host in: Only their locality (Brooklyn only, NOT Manhattan)
  └─ Can host ALL types of events in their locality (including house parties)
```

---

## 🔒 **Enforcement Rules**

### **Local Experts**

- ✅ **Can host:** Events in their locality only
- ❌ **Cannot host:** Events in other localities or cities
- **Example:** A Greenpoint local expert can host in Greenpoint, but NOT in DUMBO or Manhattan

### **City Experts**

- ✅ **Can host:** Events in all localities within their city
- ❌ **Cannot host:** Events in other cities
- **Example:** A Brooklyn city expert can host in Greenpoint, DUMBO, Sunset Park, etc., but NOT in Manhattan

### **Regional Experts**

- ✅ **Can host:** Events in all cities and localities in their region/state
- **Example:** A New York regional expert can host in Brooklyn, Manhattan, Queens, etc.

### **National Experts**

- ✅ **Can host:** Events in all states, cities, and localities in their nation
- **Example:** A USA national expert can host in New York, Texas, California, etc.

### **Global/Universal Experts**

- ✅ **Can host:** Events anywhere globally/universally

---

## 🏙️ **Large City Handling**

### **Problem**

Large cities (Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos, etc.) have neighborhoods that are vastly different in thought, atmosphere, idea, and identity.

### **Solution**

Neighborhoods in these cities are treated as **separate localities** to preserve neighborhood identity.

### **Detection Criteria**

The system recognizes "large and diverse" cities based on:

1. **Geographic size** (e.g., Houston is huge with many towns inside)
2. **Population size**
3. **Well-documented neighborhoods** backed by geography and population data

### **Example: Brooklyn**

- Greenpoint, Bath Beach, Sunset Park, DUMBO are **different localities**
- A user in Greenpoint can attend a Bath Beach event and feel like a "local"
- This preserves neighborhood identity and diversity
- Promotes value of small events
- Allows exploration between neighborhoods while maintaining their unique character

### **Example Scenario**

- User from Sunset Park enjoys mahjong
- Mahjong event hosted in DUMBO
- User can feel like a local going to a local event, even if it's not in their locality

---

## 🔧 **Implementation**

### **Models**

1. **`GeographicScope`** - Represents a user's event hosting scope
   - Stores user ID, expertise level, location data
   - Provides methods: `canHostInLocality()`, `canHostInCity()`, `getHostableLocalities()`, `getHostableCities()`

2. **`Locality`** - Represents a geographic locality (neighborhood, borough, district, etc.)
   - Stores locality name, city, state, country, coordinates
   - Supports neighborhood localities in large cities

3. **`LargeCity`** - Represents a large diverse city
   - Stores city name, population, geographic size, neighborhoods
   - Tracks detected vs manually added cities

### **Services** (Created by Agent 1)

1. **`GeographicScopeService`** - Validates event hosting scope
   - `canHostInLocality(String userId, String locality)` - Check if user can host in locality
   - `canHostInCity(String userId, String city)` - Check if user can host in city
   - `getHostingScope(String userId)` - Get all localities/cities user can host in
   - `validateEventLocation(String userId, String eventLocality)` - Validate event location for user

2. **`LargeCityDetectionService`** - Detects and manages large cities
   - `isLargeCity(String cityName)` - Detect if city is large and diverse
   - `getNeighborhoods(String cityName)` - Get neighborhoods for large city
   - `isNeighborhoodLocality(String locality)` - Check if locality is a neighborhood
   - `getParentCity(String locality)` - Get parent city for neighborhood locality

### **Integration**

- **`ExpertiseEventService.createEvent()`** - Uses `GeographicScopeService` to validate event location before creation
- **`UnifiedUser`** - Provides expertise level and location data for scope calculation

---

## 🧪 **Testing**

### **Test Infrastructure**

- **Test Helpers:** `IntegrationTestHelpers` provides helpers for creating geographic scopes, localities, and large cities
- **Test Fixtures:** `IntegrationTestFixtures` provides pre-configured test scenarios
- **Integration Tests:** `geographic_scope_integration_test.dart` tests geographic scope validation

### **Test Coverage**

- ✅ Local expert scope validation
- ✅ City expert scope validation
- ✅ Regional+ expert scope validation
- ✅ Geographic hierarchy enforcement
- ✅ Large city detection
- ✅ Event creation with geographic scope validation

---

## 📊 **Examples**

### **Example 1: Local Expert**

```dart
// User is a local expert in Greenpoint
final scope = GeographicScope(
  userId: 'user-123',
  level: ExpertiseLevel.local,
  locality: 'Greenpoint',
  city: 'Brooklyn',
  allowedLocalities: ['Greenpoint'],
);

// ✅ Can host in Greenpoint
expect(scope.canHostInLocality('Greenpoint'), isTrue);

// ❌ Cannot host in DUMBO
expect(scope.canHostInLocality('DUMBO'), isFalse);
```

### **Example 2: City Expert**

```dart
// User is a city expert in Brooklyn
final scope = GeographicScope(
  userId: 'user-456',
  level: ExpertiseLevel.city,
  city: 'Brooklyn',
  allowedLocalities: ['Greenpoint', 'DUMBO', 'Sunset Park'],
);

// ✅ Can host in any locality in Brooklyn
expect(scope.canHostInLocality('Greenpoint'), isTrue);
expect(scope.canHostInLocality('DUMBO'), isTrue);

// ❌ Cannot host in Manhattan
expect(scope.canHostInLocality('Manhattan'), isFalse);
```

### **Example 3: Regional Expert**

```dart
// User is a regional expert in New York
final scope = GeographicScope(
  userId: 'user-789',
  level: ExpertiseLevel.regional,
  state: 'New York',
);

// ✅ Can host anywhere in New York
expect(scope.canHostInLocality('Greenpoint'), isTrue);
expect(scope.canHostInLocality('Manhattan'), isTrue);
expect(scope.canHostInCity('Brooklyn'), isTrue);
expect(scope.canHostInCity('Manhattan'), isTrue);
```

---

## 🚨 **Important Notes**

1. **Strict Hierarchy:** The system enforces strict hierarchy - local experts cannot host outside their locality
2. **Large Cities:** Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos should be detected and neighborhoods treated as separate localities
3. **Backward Compatibility:** All existing events and users should continue to work
4. **Validation:** Geographic scope validation happens before event creation in `ExpertiseEventService.createEvent()`

---

## 📚 **Related Documentation**

- **Requirements:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
- **Implementation Plan:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`
- **Large City Detection:** `docs/plans/expertise_system/LARGE_CITY_DETECTION.md`

---

**Last Updated:** November 24, 2025  
**Status:** Active Documentation

