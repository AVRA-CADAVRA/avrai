# Spots System Comprehensive Organization

**Date:** January 6, 2026  
**Status:** 📋 **COMPREHENSIVE ORGANIZATION DOCUMENT**  
**Purpose:** Complete organization of all spots-related architecture, features, and integrations discussed in conversation  
**Scope:** Everything from spot creation to AI2AI mesh integration

---

## 📋 **Table of Contents**

1. [Spot Creation & Population](#1-spot-creation--population)
2. [Spot Data Architecture & Schema](#2-spot-data-architecture--schema)
3. [Exact Spot Check-In System](#3-exact-spot-check-in-system)
4. [Spot Recognition & Geofencing](#4-spot-recognition--geofencing)
5. [Quantum & Knot Theory Integration](#5-quantum--knot-theory-integration)
6. [AI2AI Mesh Integration](#6-ai2ai-mesh-integration)
7. [Business Spot Management](#7-business-spot-management)
8. [Review & Feedback System](#8-review--feedback-system)
9. [Complete Data Flow Architecture](#9-complete-data-flow-architecture)
10. [Database Schema Summary](#10-database-schema-summary)

---

## 1. **Spot Creation & Population**

### **1.1 Spot Creation Methods**

**Three Primary Creation Methods:**

1. **User-Created Spots**
   - Users can optionally create spots (e.g., "best place to watch clouds", "favorite waterfall")
   - Not required - spots have baseline population from Google Places API
   - Created via `CreateSpotPage` → `SpotsBloc` → `CreateSpotUseCase` → `SpotsRepository`
   - Stored with `createdBy: user_id`, `creatorType: 'user'`

2. **AI-Created Spots**
   - AI can create spots via `ActionExecutor.executeCreateSpot()`
   - Creates spots from `CreateSpotIntent`
   - Uses same repository flow as user-created spots

3. **Google Places API Population**
   - Baseline population from Google Places API
   - `GooglePlacesDataSource` / `GooglePlacesDataSourceNew` fetch external places
   - Converted to AVRAI `Spot` model with:
     - `id: 'google_${place_id}'`
     - `createdBy: 'google_places_api'`
     - `creatorType: 'google_places'`
     - `metadata.isExternal: true`
   - Synced via `GooglePlacesSyncService` which merges community data with Google data

### **1.2 Spot Creation Flow**

```
User/AI/Google Creates Spot
    ↓
CreateSpotPage / ActionExecutor / GooglePlacesDataSource
    ↓
SpotsBloc (CreateSpot event)
    ↓
CreateSpotUseCase
    ↓
SpotsRepository.createSpot()
    ↓
SpotsLocalDataSource (Sembast - offline-first)
    ↓
SpotsRemoteDataSource (Supabase - sync when online)
```

### **1.3 Google Places Integration**

**Hybrid Search Architecture:**
- `HybridSearchRepository` searches community-first, then external
- Priority: Community spots > Google Places spots
- Community spots always rank higher in search results
- Google Places spots marked as `isExternal: true` in metadata

**Sync Service:**
- `GooglePlacesSyncService.syncSpot()` merges Google Place details into existing spots
- Prioritizes existing community data
- Enriches missing fields (address, phone, website, image, tags, rating if higher)

---

## 2. **Spot Data Architecture & Schema**

### **2.1 Core Spot Model**

**Current Spot Model Fields:**
```dart
class Spot {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final double rating;
  final String createdBy; // User ID or BusinessAccount ID or 'google_places_api'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? address;
  final String? phoneNumber;
  final String? website;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  
  // Google Places integration
  final String? googlePlaceId;
  final DateTime? googlePlaceIdSyncedAt;
}
```

### **2.2 Enhanced Spot Model (Proposed)**

**Additional Fields for Complete Integration:**
```dart
class Spot {
  // ... existing fields ...
  
  // Ownership/Claiming
  final SpotCreatorType creatorType; // user, business, community, google_places
  final String? businessAccountId; // If created/claimed by business
  final SpotClaimStatus? claimStatus; // null, pending, verified, rejected
  final BusinessVerification? businessVerification; // Verification for claimed spots
  
  // Geographic Context
  final String? geohash; // Geohash at precision 7 (~153m)
  final String? geohash3; // Geohash at precision 3 (city-level)
  final String? cityCode; // From geo_hierarchy_service
  final String? localityCode; // From geo_hierarchy_service
  final List<double>? localityVector12; // 12-dimensional locality personality vector
  
  // Quantum & Knot Integration
  final Map<String, dynamic>? quantumStateCache; // Cached quantum state
  final Map<String, dynamic>? knotRepresentation; // Knot representation
  
  // Check-In Configuration
  final Map<String, dynamic>? checkInConfig; // Exact check-in spot configuration
  
  // Review/Feedback Integration
  final double? averageRating; // Calculated from reviews
  final int reviewCount; // Number of reviews
  final List<String> recentReviewIds; // Recent review IDs for quick access
  
  // Learning Integration
  final Map<String, dynamic> learningMetadata; // For AI2AI mesh learning
  final DateTime? lastLearningUpdate; // When spot was last updated from mesh
}
```

### **2.3 Geohashing Integration**

**GeohashService Integration:**
- `GeohashService.encode()` converts lat/lon to geohash at specified precision
- Precision 7 (~153m) for spot-level geohashing
- Precision 3 for city-level geohashing
- `GeohashService.neighbors()` returns 8 adjacent geohash prefixes for locality agent smoothing

**Geographic Hierarchy Integration:**
- `GeoHierarchyService` provides canonical geographic hierarchy
- `lookupCityCode()` and `lookupLocalityCode()` for spot location
- `public.geo_localities_v1` table stores city_code and locality_code
- Spots can be associated with localities via `NeighborhoodBoundaryService`

### **2.4 Vectorless Schema Consideration**

**Current Schema:**
- Uses PostGIS for spatial indexing: `location geometry(Point, 4326)`
- Generated column: `ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)`

**Proposed Hybrid Schema:**
- Keep PostGIS for precise spatial queries
- Add `geohash` and `geohash3` columns for faster locality lookups
- Add `city_code` and `locality_code` for geographic hierarchy
- Add `locality_vector12 JSONB` for locality personality vectors
- No pgvector extension needed (vectorless approach for compatibility)

**Benefits:**
- PostGIS for precise spatial queries (distance, within radius, etc.)
- Geohash for fast locality context lookups
- JSONB for locality vectors (scalar compatibility, no embeddings)
- Faster locality agent queries

---

## 3. **Exact Spot Check-In System**

### **3.1 Check-In Configuration**

**check_in_config JSONB Structure:**
```json
{
  "enabled": true,
  "check_in_spot": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "accuracy_threshold_meters": 5.0,
    "location_accuracy_required_meters": 10.0,
    "environment": "indoor" | "outdoor",
    "beacon_id": "optional-beacon-uuid",
    "wifi_fingerprint": {
      "ssids": ["restaurant-wifi"],
      "bssids": ["aa:bb:cc:dd:ee:ff"]
    }
  },
  "check_in_methods": ["exact_coordinate", "beacon", "wifi", "qr_code"],
  "time_window_minutes": 15,
  "require_manual_confirmation": false
}
```

### **3.2 Multi-Layered Check-In Process**

**ExactSpotCheckInService Flow:**
```
checkInAtExactSpot()
    ↓
├─ _tryExactCoordinateCheckIn()
│  └─ GPS accuracy validation (within threshold)
│
├─ _tryBeaconCheckIn() (if beacon_id provided)
│  └─ Bluetooth beacon proximity
│
├─ _tryWiFiCheckIn() (if wifi_fingerprint provided)
│  └─ WiFi SSID/BSSID matching
│
└─ _tryGeohashCheckIn() (fallback)
   └─ High-precision geohash (precision 9, ~19m)
```

### **3.3 Check-In Methods**

1. **Exact Coordinate Check-In**
   - Uses `Geolocator.getCurrentPosition()` for GPS
   - Validates accuracy within `accuracy_threshold_meters`
   - Validates location accuracy within `location_accuracy_required_meters`
   - Calculates distance to check-in spot
   - Success if within threshold

2. **Bluetooth Beacon Check-In**
   - Scans for Bluetooth beacon with `beacon_id`
   - Validates proximity via RSSI
   - Works indoors where GPS is unreliable

3. **WiFi Fingerprint Check-In**
   - Matches WiFi SSIDs and BSSIDs
   - Validates against `wifi_fingerprint` configuration
   - Works indoors for precise location

4. **Geohash Check-In (Fallback)**
   - Uses `GeohashService.encode()` at precision 9 (~19m)
   - Validates geohash match with check-in spot geohash
   - Time window validation (within `time_window_minutes`)

5. **QR Code Check-In**
   - Generates QR code with reservation/check-in data
   - Scans QR code for verification
   - Validates QR code signature

### **3.4 Reservation System Integration**

**ReservationCheckInService:**
- `generateCheckInQRCode()` - Creates QR code for check-in
- `verifyQRCode()` - Validates QR code signature
- `checkInViaGeohash()` - Geohash-based check-in
- `findReservationsByGeohash()` - Finds reservations by geohash

**Reservation Schema:**
- `public.reservations` table with `agent_id`, `user_data JSONB`, `target_id`, `reservation_time`, `status`
- Dual identity system: `agent_id` (privacy-preserved) vs `user_data` (optional, user-consented)
- No direct check-in coordinates on reservation (uses spot's `check_in_config`)

---

## 4. **Spot Recognition & Geofencing**

### **4.1 Automatic Check-In Service**

**AutomaticCheckInService:**
- `handleGeofenceTrigger()` - Creates `Visit` records from geofence entry
- `handleBluetoothTrigger()` - Creates `Visit` records from Bluetooth ai2ai detection
- `checkOut()` - Completes visit, calculates dwell time and quality score
- Uses `AtomicClockService` for precise timing

**Visit Model:**
```dart
class Visit {
  final String id;
  final String userId;
  final String locationId; // Spot ID
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final Duration? dwellTime;
  final double qualityScore;
  final bool isAutomatic;
  final GeofencingData? geofencingData;
  final BluetoothData? bluetoothData;
  final String? reviewId;
  final double? rating;
  final bool isRepeatVisit;
  final int visitNumber;
}
```

### **4.2 Geofencing Integration**

**Geofence Configuration:**
- Default radius: 50m
- Triggers automatic check-in when user enters geofence
- Creates `Visit` record with `isAutomatic: true`
- Uses `GeofencingData` for location accuracy

**Bluetooth ai2ai Detection:**
- Detects nearby devices via Bluetooth
- Establishes ai2ai connection
- Exchanges personality profiles
- Creates `Visit` record with `BluetoothData`

### **4.3 Locality Agent Integration**

**LocalityAgentIngestionServiceV1:**
- `ingestVisit()` - Processes visit and updates locality agent
- Uses `GeohashService.encode()` to create `LocalityAgentKeyV1`
- Calls `_propagateLocalityAgentUpdateThroughMesh()` after updating local delta

**LocalityAgentEngine:**
- `inferVector12()` - Infers 12-dimensional locality personality vector
- Uses `GeohashService.neighbors()` for neighbor smoothing
- Incorporates mesh neighbors from `LocalityAgentMeshCache`
- Updates locality vector based on visit patterns

**LocalityAgentKeyV1:**
- `geohashPrefix` - Geohash at precision 7
- `cityCode` - City code from geographic hierarchy
- `precision` - Geohash precision level

---

## 5. **Quantum & Knot Theory Integration**

### **5.1 Quantum Matching Integration**

**QuantumMatchingController:**
- `_convertSpotToQuantumState()` - Converts `Spot` to `QuantumEntityState`
- Includes `LocationQuantumState` for spot location
- Combines quantum fidelity, location, timing, and knot compatibility
- Returns `MatchingResult` with compatibility score

**LocationQuantumState:**
```dart
class LocationQuantumState {
  final double latitudeState;
  final double longitudeState;
  final String locationType;
  final double accessibilityScore;
  final double vibeLocationMatch;
  
  // Inner product for location compatibility
  double innerProduct(LocationQuantumState other) {
    // Gaussian wavefunction overlap calculation
  }
}
```

**Spot Quantum State Creation:**
- Spot → `QuantumEntityState` with `LocationQuantumState`
- Incorporates locality personality vector (`localityVector12`)
- Includes business context if spot is claimed by business
- Cached in `quantumStateCache` for performance

### **5.2 Knot Theory Integration**

**EntityKnot for Spots:**
- All entities in ai2ai system have knot representations
- `K_place` (spot) knot includes location context
- `EntityKnot` encapsulates `PersonalityKnot` for any `EntityType` (person, event, place, company)
- Includes metadata like lat/lon in knot representation

**CrossEntityCompatibilityService:**
- Calculates topological compatibility between entities
- Includes spot compatibility with users, events, businesses
- Uses knot weave compatibility for group matching

**Knot Evolution String Service:**
- Tracks spot visit patterns over time
- Detects recurring visit patterns
- Predicts future visit likelihood

**Knot Fabric Service:**
- Creates fabric for group visits to spots
- Tracks group compatibility at spots
- Weaves multiple entity knots together

### **5.3 Quantum-Enhanced Check-In**

**QuantumExactSpotCheckInService:**
- Validates geometric distance (GPS accuracy)
- Validates quantum location compatibility (`userLocationState.locationCompatibility(checkInLocationState)`)
- Validates knot accessibility (`calculateKnotAccessibility()`)
- Validates locality geohash matching
- Combines all factors for check-in validation

---

## 6. **AI2AI Mesh Integration**

### **6.1 Mesh Message Types**

**Three Primary Message Types:**

1. **locality_agent_update**
   - Triggered by: Spot recognition, geofence entry, visit completion
   - Contains: Locality agent delta (12-dim vector change)
   - Propagated via: `VibeConnectionOrchestrator.forwardLocalityAgentUpdate()`
   - Stored in: `LocalityAgentMeshCache`

2. **learning_insight**
   - Triggered by: Quantum matching, knot compatibility, review submission
   - Contains: AI2AILearningInsight with dimension insights
   - Propagated via: `QuantumMatchingAILearningService.learnFromMatch()`
   - Shared via: `QuantumEntanglementService.shareEntanglementInsightsViaMesh()`

3. **check_in_outcome**
   - Triggered by: Successful check-in, visit completion
   - Contains: Check-in outcome data, visit quality, learning insights
   - Propagated via: `ExactSpotCheckInMeshService`
   - Used for: Learning from successful/failed check-ins

### **6.2 Mesh Propagation Services**

**SpotRecognitionMeshService:**
- Calculates delta (spot's vibe influence on locality personality)
- Propagates as `locality_agent_update` message
- Shares quantum insights if spot matches user
- Updates locality agent from spot recognition

**LocalityGeofenceMeshService:**
- Handles geofence entries
- Calls `_localityAgentEngine.updateFromVisit()`
- Calls `_propagateLocalityAgentUpdateThroughMesh()`
- `getLocalityVectorWithMesh()` shows how `inferVector12()` incorporates `meshNeighbors`

**QuantumKnotMeshService:**
- Shares quantum matching insights through mesh
- Uses `_quantumMatchingAILearningService.learnFromMatch()`
- Uses `_entanglementService.shareEntanglementInsightsViaMesh()`
- Propagates knot compatibility insights

**ExactSpotCheckInMeshService:**
- Integrates check-in outcomes with mesh propagation
- After successful check-in:
  - Updates locality agent (`_localityAgentEngine.updateFromVisit()`)
  - Propagates update (`_propagateLocalityAgentUpdateThroughMesh()`)
  - Shares check-in outcome as learning insight through mesh

### **6.3 Mesh Caching & Learning**

**LocalityAgentMeshCache:**
- `storeMeshUpdate()` - Saves deltas from `locality_agent_update` messages
- `getNeighborMeshUpdates()` - Retrieves cached deltas for neighbor smoothing
- Used by `LocalityAgentEngine.inferVector12()` for neighbor smoothing

**ConnectionOrchestrator:**
- `forwardLocalityAgentUpdate()` - Propagates `locality_agent_update` messages
- `_handleIncomingLocalityAgentUpdate()` - Receives and stores updates
- `_maybeForwardLocalityAgentUpdateGossip()` - Forwards updates with adaptive hop limits
- Uses Signal Protocol encryption for privacy

**Adaptive Mesh Networking:**
- Adaptive hop policy based on message type and scope
- `locality_agent_update`: Scope 'locality', TTL 24 hours
- `learning_insight`: Scope 'network', TTL 7 days
- `check_in_outcome`: Scope 'locality', TTL 12 hours

---

## 7. **Business Spot Management**

### **7.1 Business Spot Creation**

**BusinessSpotCreationService:**
- `createBusinessSpot()` - Creates spot as business
- Requires: Business must be verified (`BusinessVerificationService.isBusinessVerified()`)
- Creates geohash and locality context
- Gets locality vector12 from `LocalityAgentEngine`
- Creates spot with `creatorType: 'business'`, `businessAccountId: business.id`
- Creates quantum state and knot representation
- Propagates spot creation through mesh

**Business Spot Creation Flow:**
```
BusinessSpotCreationService.createBusinessSpot()
    ↓
Verify business is verified
    ↓
Create geohash and locality context
    ↓
Get locality vector12
    ↓
Create spot (with business context)
    ↓
Create quantum state and knot representation
    ↓
Propagate through mesh
```

### **7.2 Business Spot Claiming**

**BusinessSpotClaimingService:**
- `claimSpot()` - Claims existing spot for business
- Requires: Business must be verified
- Verifies truthfulness of claim via `TruthfulnessVerificationService`
- Creates `SpotClaim` record with `claimStatus: 'pending'`
- Auto-verifies if truthfulness score >= 0.95
- Manual review if truthfulness score < 0.95

**Truthfulness Verification:**
- `verifySpotClaim()` - Verifies truthfulness of claim
- Factors:
  - Address matching (40% weight)
  - Name matching (30% weight)
  - Location proximity (20% weight)
  - Evidence quality (10% weight)
  - Business verification status (bonus)
- Returns `TruthfulnessResult` with score and factors
- Threshold: 0.75 for truthfulness

**SpotClaimEvidence:**
```dart
class SpotClaimEvidence {
  final String? businessLicenseUrl;
  final String? proofOfAddressUrl;
  final String? googleBusinessProfileUrl;
  final String? websiteUrl;
  final List<String>? socialMediaUrls;
  final String? notes;
  final List<String>? locationPhotos;
}
```

**Claim Flow:**
```
Business submits claim
    ↓
Truthfulness verification
    ↓
If score >= 0.95 → Auto-verify
If score < 0.95 → Manual review
    ↓
Update spot with business ownership
    ↓
Propagate claim through mesh
```

### **7.3 Spot Ownership Hierarchy**

```
Spot Ownership:
├─ Created By:
│  ├─ User (createdBy: user_id, creatorType: 'user')
│  ├─ Business (createdBy: business_id, creatorType: 'business')
│  ├─ Community (createdBy: community_id, creatorType: 'community')
│  └─ Google Places (createdBy: 'google_places_api', creatorType: 'google_places')
│
└─ Claimed By:
   ├─ No Claim (claimStatus: null)
   ├─ Pending Claim (claimStatus: 'pending', businessAccountId: business_id)
   ├─ Verified Claim (claimStatus: 'verified', businessAccountId: business_id)
   └─ Rejected Claim (claimStatus: 'rejected', businessAccountId: business_id)
```

---

## 8. **Review & Feedback System**

### **8.1 Visit Completion → Review Prompt**

**VisitCompletionService:**
- `handleLocationExit()` - Handles user leaving location
- Flow:
  1. Check out from visit (`AutomaticCheckInService.checkOut()`)
  2. Update locality agents (mesh propagation)
  3. Determine if review should be prompted
  4. Schedule review prompt (5 min delay)
  5. Learn from visit (quantum matching insights)

**Review Prompt Logic:**
- Don't prompt if:
  - Visit too short (< 5 minutes)
  - Already reviewed this visit
  - Reviewed recently (within 30 days)
- Prompt if:
  - Visit >= 5 minutes
  - Not yet reviewed
  - Not reviewed recently

**ReviewPromptService:**
- `scheduleReviewPrompt()` - Schedules deferred notification
- Stores prompt in local storage
- Schedules local notification (5 min delay)
- `showReviewPrompt()` - Shows review page when notification tapped

### **8.2 Review Submission**

**SpotReviewService:**
- `submitReview()` - Submits review for spot
- Creates `SpotReview` record
- Updates spot ratings (`_updateSpotRatings()`)
- Updates visit with review (`_updateVisitWithReview()`)
- Learns from review (`_learnFromReview()`)
- Updates locality agent if positive review (`_updateLocalityAgentFromReview()`)
- Propagates review through mesh (`_propagateReviewViaMesh()`)

**SpotReview Model:**
```dart
class SpotReview {
  final String id;
  final String spotId;
  final String userId;
  final String? visitId;
  final double rating; // 1.0 to 5.0
  final String? reviewText;
  final Map<String, double>? categoryRatings; // {food: 4.5, service: 4.0}
  final bool? wouldRecommend;
  final DateTime submittedAt;
}
```

### **8.3 Learning from Reviews**

**ReviewLearningIntegration:**
- `extractInsightsFromReview()` - Extracts learning insights from review
- Maps category ratings to SPOTS dimensions
- Calculates dimension adjustments from ratings
- Creates `AI2AILearningInsight` with dimension insights
- Propagates through mesh for federated learning

**Learning Quality:**
- Calculated from review depth (text length, category ratings, etc.)
- Higher quality reviews contribute more to learning
- Positive reviews (rating >= 4.0) update locality agents

---

## 9. **Complete Data Flow Architecture**

### **9.1 Spot Creation Flow**

```
SPOT CREATION
   ├─ User creates → createdBy: user_id, creatorType: 'user'
   ├─ Business creates → createdBy: business_id, creatorType: 'business'
   ├─ Google Places → createdBy: 'google_places_api', creatorType: 'google_places'
   └─ Community → createdBy: community_id, creatorType: 'community'
   
   ↓
   
Create geohash and locality context
   ↓
Get locality vector12
   ↓
Create quantum state and knot representation
   ↓
Save to database (offline-first)
   ↓
Propagate through mesh (if online)
```

### **9.2 Spot Claiming Flow**

```
SPOT CLAIMING (Business)
   ├─ Business submits claim → claimStatus: 'pending'
   ├─ Truthfulness verification → truthfulness_score calculated
   ├─ Auto-verify (if score >= 0.95) → claimStatus: 'verified'
   └─ Manual review (if score < 0.95) → Admin reviews → claimStatus: 'verified'/'rejected'
   
   ↓
   
Update spot with business ownership
   ↓
Propagate claim through mesh
```

### **9.3 Visit Completion Flow**

```
VISIT COMPLETION
   ├─ User leaves location → checkout triggered
   ├─ Review prompt scheduled (5 min delay)
   ├─ User submits review → review saved
   └─ Learning propagated through mesh
   
   ↓
   
Update locality agents
   ↓
Extract learning insights
   ↓
Propagate through mesh
```

### **9.4 Quantum/Knot Integration Flow**

```
QUANTUM/KNOT INTEGRATION
   ├─ Spot → QuantumEntityState (with business context if claimed)
   ├─ Spot → EntityKnot (with business knot if claimed)
   └─ Business → EntityKnot (merged with spot knot if claimed)
   
   ↓
   
Calculate compatibility
   ↓
Share insights through mesh
```

### **9.5 Mesh Propagation Flow**

```
MESH PROPAGATION
   ├─ Spot creation → Mesh message
   ├─ Spot claim → Mesh message
   ├─ Review submission → Mesh message (learning insights)
   └─ Locality agent updates → Mesh message
   
   ↓
   
Encrypted, anonymized propagation
   ↓
Stored in LocalityAgentMeshCache
   ↓
Used for neighbor smoothing
   ↓
Federated learning
```

---

## 10. **Database Schema Summary**

### **10.1 Enhanced Spots Table**

```sql
-- Enhanced spots table
ALTER TABLE spots ADD COLUMN IF NOT EXISTS
  creator_type TEXT CHECK (creator_type IN ('user', 'business', 'community', 'google_places')),
  business_account_id UUID REFERENCES business_accounts(id),
  claim_status TEXT CHECK (claim_status IN ('pending', 'verified', 'rejected')),
  business_verification_id UUID REFERENCES business_verifications(id),
  geohash TEXT,
  geohash3 TEXT,
  city_code TEXT,
  locality_code TEXT,
  locality_vector12 JSONB,
  quantum_state_cache JSONB,
  knot_representation JSONB,
  check_in_config JSONB,
  average_rating DOUBLE PRECISION,
  review_count INTEGER DEFAULT 0,
  recent_review_ids UUID[],
  learning_metadata JSONB,
  last_learning_update TIMESTAMPTZ;

-- Keep existing PostGIS spatial index
-- location geometry(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED
```

### **10.2 Spot Claims Table**

```sql
-- Spot claims table (for claiming existing spots)
CREATE TABLE IF NOT EXISTS spot_claims (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  spot_id UUID REFERENCES spots(id) ON DELETE CASCADE,
  business_account_id UUID REFERENCES business_accounts(id) ON DELETE CASCADE,
  claim_status TEXT NOT NULL CHECK (claim_status IN ('pending', 'verified', 'rejected')),
  verification_id UUID REFERENCES business_verifications(id),
  truthfulness_score DOUBLE PRECISION, -- AVRAI truthfulness verification score
  evidence JSONB, -- SpotClaimEvidence
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES users(id), -- Admin who verified
  rejection_reason TEXT,
  metadata JSONB,
  UNIQUE(spot_id, business_account_id) -- One claim per business per spot
);
```

### **10.3 Spot Reviews Table**

```sql
-- Spot reviews table (for visit feedback)
CREATE TABLE IF NOT EXISTS spot_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  spot_id UUID REFERENCES spots(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  visit_id UUID, -- Reference to visit that triggered review
  rating DOUBLE PRECISION NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
  review_text TEXT,
  category_ratings JSONB, -- {food: 4.5, service: 4.0, atmosphere: 5.0}
  would_recommend BOOLEAN,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB,
  UNIQUE(spot_id, user_id, visit_id) -- One review per visit
);

-- Index for spot ratings
CREATE INDEX IF NOT EXISTS idx_spot_reviews_spot_id ON spot_reviews(spot_id);
CREATE INDEX IF NOT EXISTS idx_spot_reviews_user_id ON spot_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_spot_reviews_rating ON spot_reviews(rating);
```

### **10.4 Indexes for Performance**

```sql
-- Geohash indexes for locality lookups
CREATE INDEX IF NOT EXISTS idx_spots_geohash ON spots(geohash);
CREATE INDEX IF NOT EXISTS idx_spots_geohash3 ON spots(geohash3);
CREATE INDEX IF NOT EXISTS idx_spots_city_code ON spots(city_code);
CREATE INDEX IF NOT EXISTS idx_spots_locality_code ON spots(locality_code);

-- Business account indexes
CREATE INDEX IF NOT EXISTS idx_spots_business_account_id ON spots(business_account_id);
CREATE INDEX IF NOT EXISTS idx_spots_claim_status ON spots(claim_status);

-- Creator type index
CREATE INDEX IF NOT EXISTS idx_spots_creator_type ON spots(creator_type);

-- Review indexes
CREATE INDEX IF NOT EXISTS idx_spots_average_rating ON spots(average_rating);
CREATE INDEX IF NOT EXISTS idx_spots_review_count ON spots(review_count);
```

---

## 11. **Implementation Services Summary**

### **11.1 Core Services**

1. **SpotCreationService** - Handles all spot creation methods
2. **BusinessSpotCreationService** - Business-specific spot creation
3. **BusinessSpotClaimingService** - Business spot claiming with truthfulness verification
4. **TruthfulnessVerificationService** - Verifies business spot claims
5. **ExactSpotCheckInService** - Multi-layered exact spot check-in
6. **VisitCompletionService** - Handles location exit and review prompts
7. **ReviewPromptService** - Schedules and shows review prompts
8. **SpotReviewService** - Handles review submission and learning
9. **SpotRecognitionMeshService** - Propagates spot recognition through mesh
10. **LocalityGeofenceMeshService** - Handles geofence entries and mesh propagation
11. **QuantumKnotMeshService** - Shares quantum/knot insights through mesh
12. **ExactSpotCheckInMeshService** - Integrates check-in outcomes with mesh

### **11.2 Integration Points**

- **GeohashService** - Geohash encoding/decoding
- **GeoHierarchyService** - Geographic hierarchy lookups
- **LocalityAgentEngine** - Locality personality vector inference
- **LocalityAgentIngestionServiceV1** - Visit ingestion and locality updates
- **QuantumMatchingController** - Quantum compatibility calculation
- **QuantumMatchingAILearningService** - Learning propagation
- **QuantumEntanglementService** - Quantum entanglement sharing
- **ConnectionOrchestrator** - AI2AI mesh message forwarding
- **LocalityAgentMeshCache** - Mesh update caching
- **AutomaticCheckInService** - Automatic check-in handling

---

## 12. **Key Design Decisions**

### **12.1 Offline-First Architecture**

- All spot data stored locally (Sembast) for offline access
- Syncs with remote (Supabase) when online
- Google Places data cached locally for offline use
- Mesh messages queued for offline propagation

### **12.2 Community-First Priority**

- Community-created spots always rank higher than Google Places spots
- Community data prioritized over external data
- User-created spots preserved even if Google Places has similar data

### **12.3 Privacy-Preserving Design**

- Uses `agentId` for internal tracking (not `userId`)
- Optional `user_data` for business requirements (user-consented)
- Signal Protocol encryption for mesh messages
- Anonymized mesh propagation

### **12.4 Truthfulness Verification**

- Multi-factor verification (address, name, location, evidence)
- Weighted scoring system
- Auto-verify high-confidence claims (>= 0.95)
- Manual review for lower-confidence claims

### **12.5 Learning Integration**

- Reviews feed into AI2AI mesh learning
- Locality agents learn from visit patterns
- Quantum matching learns from successful matches
- Federated learning across mesh network

---

## 13. **Future Enhancements**

### **13.1 Planned Features**

1. **Baseline Google Places Population** - Automatic population of spots from Google Places API
2. **Enhanced Truthfulness Verification** - Machine learning-based verification
3. **Advanced Review Analytics** - Sentiment analysis, category insights
4. **Spot Recommendations** - AI-powered spot recommendations based on reviews
5. **Business Dashboard** - Business analytics for claimed spots

### **13.2 Integration Opportunities**

1. **Event Integration** - Spots as event venues
2. **Reservation Integration** - Spots with reservation systems
3. **Payment Integration** - Spots with payment processing
4. **Social Integration** - Share spots on social media
5. **Calendar Integration** - Add spots to calendar

---

## 14. **References**

### **14.1 Related Plans**

- `docs/plans/reservations/RESERVATION_SYSTEM_IMPLEMENTATION_PLAN.md` - Reservation system with exact check-in
- `docs/plans/general_docs/SPOTS_DATABASE_VS_GOOGLE_MAPS.md` - Hybrid architecture decision
- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - Core philosophy

### **14.2 Code References**

- `lib/core/models/spot.dart` - Spot model
- `lib/core/models/visit.dart` - Visit model
- `lib/core/models/business_account.dart` - Business account model
- `lib/core/models/business_verification.dart` - Business verification model
- `lib/core/services/geohash_service.dart` - Geohash service
- `lib/core/services/locality_agents/locality_agent_engine.dart` - Locality agent engine
- `lib/core/controllers/quantum_matching_controller.dart` - Quantum matching controller
- `lib/core/services/automatic_check_in_service.dart` - Automatic check-in service

---

**Last Updated:** January 6, 2026  
**Status:** 📋 Comprehensive Organization Complete  
**Next Steps:** Implementation of services and database migrations
