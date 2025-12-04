# Large City Detection Logic

**Created:** November 24, 2025  
**Status:** 📋 Documentation  
**Purpose:** Document the large city detection logic for neighborhood-level localities

---

## 🎯 **Overview**

Large diverse cities (Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos, etc.) have neighborhoods that are vastly different in thought, atmosphere, idea, and identity. The system detects these cities and treats their neighborhoods as separate localities to preserve neighborhood identity.

---

## 🏙️ **Problem Statement**

### **The Challenge**

In large cities, neighborhoods can be as distinct as separate cities:
- Different cultures, communities, and atmospheres
- Different values and preferences
- Different identities and character
- Users from one neighborhood may feel like "locals" in another, but they're still distinct

### **Example: Brooklyn**

- **Greenpoint:** Polish community, industrial history, waterfront
- **DUMBO:** Tech hub, art galleries, waterfront views
- **Sunset Park:** Diverse immigrant communities, industrial
- **Bath Beach:** Residential, family-oriented

These are **different localities** with distinct character, even though they're all in Brooklyn.

---

## ✅ **Solution: Neighborhood-Level Localities**

### **Approach**

Neighborhoods in large cities are treated as **separate localities**:
- Each neighborhood can have its own local experts
- Local experts can host events in their neighborhood only
- City experts can host in all neighborhoods in their city
- Users can explore neighboring neighborhoods while maintaining neighborhood identity

### **Benefits**

1. **Preserves Neighborhood Identity:** Each neighborhood maintains its unique character
2. **Promotes Small Events:** Neighborhood-level events are valued
3. **Enables Exploration:** Users can explore neighboring neighborhoods
4. **Community Building:** Neighborhood-level community building is enabled

---

## 🔍 **Detection Criteria**

The system recognizes "large and diverse" cities based on:

### **1. Geographic Size**

Cities with large geographic area (e.g., Houston is huge with many towns inside):
- **Threshold:** Cities with area > 500 km²
- **Examples:** Houston, Los Angeles, Chicago

### **2. Population Size**

Cities with large population:
- **Threshold:** Cities with population > 2,000,000
- **Examples:** New York City, Los Angeles, Chicago, Tokyo

### **3. Well-Documented Neighborhoods**

Cities with well-documented neighborhoods backed by geography and population data:
- **Criteria:** Neighborhoods with:
  - Clear geographic boundaries
  - Distinct cultural/community identity
  - Documented in geographic databases (Google Maps, etc.)
  - Population data available
- **Examples:** Brooklyn (Greenpoint, DUMBO, Sunset Park, etc.), LA (Hollywood, Santa Monica, etc.)

### **Combined Criteria**

A city is considered "large and diverse" if it meets **at least 2 of the 3 criteria** above.

---

## 📋 **Known Large Cities**

The system recognizes these large cities (initial list):

### **United States**
- **Brooklyn, NY** - Neighborhoods: Greenpoint, DUMBO, Sunset Park, Bath Beach, etc.
- **Los Angeles, CA** - Neighborhoods: Hollywood, Santa Monica, Venice, etc.
- **Chicago, IL** - Neighborhoods: Wicker Park, Lincoln Park, etc.
- **Houston, TX** - Large geographic area with many neighborhoods

### **International**
- **Tokyo, Japan** - Multiple distinct neighborhoods/wards
- **Seoul, South Korea** - Multiple districts with distinct character
- **Paris, France** - Arrondissements with distinct character
- **Madrid, Spain** - Multiple neighborhoods with distinct identity
- **Lagos, Nigeria** - Large city with distinct neighborhoods

---

## 🔧 **Implementation**

### **Models**

1. **`LargeCity`** - Represents a large diverse city
   - Stores: name, state, country, population, geographic size, neighborhoods
   - Tracks: detected vs manually added, neighborhood locality IDs

2. **`Locality`** - Represents a neighborhood locality
   - Stores: `isNeighborhood: true`, `parentCity: "Brooklyn"`
   - Example: Greenpoint locality with `parentCity: "Brooklyn"`

### **Services** (Created by Agent 1)

1. **`LargeCityDetectionService`** - Detects and manages large cities
   - `isLargeCity(String cityName)` - Detect if city is large and diverse
   - `getNeighborhoods(String cityName)` - Get neighborhoods for large city
   - `isNeighborhoodLocality(String locality)` - Check if locality is a neighborhood
   - `getParentCity(String locality)` - Get parent city for neighborhood locality

### **Detection Logic**

```dart
bool isLargeCity(String cityName) {
  // Check geographic size
  final geographicSize = getGeographicSize(cityName);
  final isLargeGeographically = geographicSize > 500.0; // km²

  // Check population
  final population = getPopulation(cityName);
  final isLargePopulation = population > 2000000;

  // Check documented neighborhoods
  final neighborhoods = getDocumentedNeighborhoods(cityName);
  final hasWellDocumentedNeighborhoods = neighborhoods.length >= 3;

  // City is large if it meets at least 2 of 3 criteria
  int criteriaMet = 0;
  if (isLargeGeographically) criteriaMet++;
  if (isLargePopulation) criteriaMet++;
  if (hasWellDocumentedNeighborhoods) criteriaMet++;

  return criteriaMet >= 2;
}
```

---

## 🧪 **Testing**

### **Test Infrastructure**

- **Test Helpers:** `IntegrationTestHelpers.createTestLargeCity()` - Creates large city for testing
- **Test Fixtures:** `IntegrationTestFixtures.largeCityFixture()` - Pre-configured large city scenario
- **Integration Tests:** Tests large city detection and neighborhood handling

### **Test Coverage**

- ✅ Large city detection logic
- ✅ Neighborhood locality creation
- ✅ Parent city relationships
- ✅ Geographic scope validation for neighborhoods

---

## 📊 **Examples**

### **Example 1: Brooklyn Detection**

```dart
// Brooklyn is detected as large city
final city = LargeCity(
  name: 'Brooklyn',
  state: 'New York',
  population: 2736074,
  geographicSizeKm2: 251.0,
  neighborhoods: [
    'locality-greenpoint',
    'locality-dumbo',
    'locality-sunset-park',
    'locality-bath-beach',
  ],
  isDetected: true,
);

expect(city.hasNeighborhoods, isTrue);
expect(city.neighborhoodCount, equals(4));
```

### **Example 2: Neighborhood Locality**

```dart
// Greenpoint is a neighborhood in Brooklyn
final locality = Locality(
  name: 'Greenpoint',
  city: 'Brooklyn',
  isNeighborhood: true,
  parentCity: 'Brooklyn',
);

expect(locality.isNeighborhood, isTrue);
expect(locality.isInLargeCity, isTrue);
expect(locality.parentCity, equals('Brooklyn'));
```

### **Example 3: City Expert in Large City**

```dart
// City expert in Brooklyn can host in all neighborhoods
final scope = GeographicScope(
  userId: 'user-456',
  level: ExpertiseLevel.city,
  city: 'Brooklyn',
  allowedLocalities: [
    'Greenpoint',
    'DUMBO',
    'Sunset Park',
    'Bath Beach',
  ],
);

// ✅ Can host in any neighborhood in Brooklyn
expect(scope.canHostInLocality('Greenpoint'), isTrue);
expect(scope.canHostInLocality('DUMBO'), isTrue);
```

---

## 🚨 **Important Notes**

1. **Neighborhood Identity:** Neighborhoods in large cities maintain their distinct identity
2. **Exploration:** Users can explore neighboring neighborhoods while maintaining neighborhood character
3. **Local Experts:** Neighborhood-level local experts can host in their neighborhood only
4. **City Experts:** City experts can host in all neighborhoods in their city
5. **Detection:** System automatically detects large cities, but can also be manually configured

---

## 📚 **Related Documentation**

- **Geographic Hierarchy:** `docs/plans/expertise_system/GEOGRAPHIC_HIERARCHY_SYSTEM.md`
- **Requirements:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_REDESIGN.md`
- **Implementation Plan:** `docs/plans/expertise_system/LOCAL_EXPERT_SYSTEM_IMPLEMENTATION_PLAN.md`

---

**Last Updated:** November 24, 2025  
**Status:** Active Documentation

