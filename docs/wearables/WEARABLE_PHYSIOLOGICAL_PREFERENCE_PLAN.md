# Wearable & Physiological Data Integration Plan

**Date:** December 9, 2025  
**Status:** 🟢 Active  
**Priority:** HIGH  
**Timeline:** 2-3 weeks  
**Purpose:** Enable wearables (watches, heart rate monitors) to influence user preferences based on physiological data (excitement, calmness, etc.)

---

## 🎯 Executive Summary

**Goal:** Integrate wearable devices (smartwatches, fitness trackers, heart rate monitors, **AR glasses with eye tracking**) to capture physiological and behavioral data that influences user preferences in real-time. When a user gets excited (elevated heart rate, pupil dilation), feels calm (lower heart rate, steady gaze), or shows interest (gaze patterns, attention duration), the AI learns from these authentic signals to better understand which doors (spots, events, communities) truly resonate with the user.

**Philosophy Alignment:**
- **Doors, not badges:** Physiological and eye tracking data helps identify which doors truly resonate
- **Real-world enhancement:** Wearables and AR glasses enhance the real-world experience, not replace it
- **Always learning with you:** AI learns from your body's and eyes' authentic responses
- **Privacy-first:** All health and eye tracking data stays on-device, user controls everything

---

## 🚪 The Philosophy: Physiological & Visual Doors

### **What This Means**

**Every physiological and visual response is a door:**
- Elevated heart rate at a coffee shop → This door excites you
- Calm heart rate at a park → This door brings you peace
- Increased activity at an event → This door energizes you
- Steady pulse at a library → This door centers you
- **Gaze fixated on a spot's sign → This door catches your attention**
- **Pupil dilation when viewing a spot → This door interests you**
- **Extended attention on an event → This door resonates with you**
- **Eye movement patterns exploring a venue → This door engages you**

**SPOTS learns from your body's and eyes' authentic responses:**
- Not what you say you like
- Not what algorithms predict
- But what your body and eyes actually respond to

**The AI becomes a better key:**
- Shows you doors that match your physiological and visual state
- Suggests calm spots when you're stressed (body + eyes show stress)
- Suggests exciting spots when you're energized (body + eyes show interest)
- Learns which doors lead to which states
- **Understands what you're actually looking at and how you respond**

---

## 📊 Current State Analysis

### **Existing Systems**

✅ **Preference Learning System**
- `UserPreferences` model (`lib/core/models/user_preferences.dart`)
- `PreferenceLearningEngine` (`lib/core/ml/preference_learning.dart`)
- `UserPreferenceLearningService` (`lib/core/services/user_preference_learning_service.dart`)
- `FeedbackProcessor` (`lib/core/ml/feedback_processor.dart`)

✅ **Data Collection Infrastructure**
- `ComprehensiveDataCollector` (`lib/core/ai/comprehensive_data_collector.dart`)
- `ContinuousLearningSystem` (`lib/core/ai/continuous_learning_system.dart`)
- Data sources: user_actions, location_data, weather_conditions, time_patterns, etc.

✅ **Personality Learning System**
- `PersonalityLearning` with 12 dimensions
- Contextual personality layers
- Evolution timeline preservation

### **Missing Components**

❌ **Health/Wearable Integration**
- No health sensor packages in `pubspec.yaml`
- No physiological data models
- No health data collection service
- No preference mapping from physiological signals
- **No AR glasses integration**
- **No eye tracking support**
- **No gaze pattern analysis**

---

## 🏗️ Architecture Design

### **1. Data Flow**

```
Wearable Devices
├─ Smartwatch/HR Monitor (Heart Rate, HRV, Activity)
├─ Fitness Tracker (Steps, Activity, Sleep)
└─ AR Glasses (Eye Tracking, Gaze Patterns, Pupil Dilation)
    ↓
Platform APIs
├─ Health Connect/HealthKit (Health Data)
└─ ARKit/ARCore + Eye Tracking APIs (Visual Data)
    ↓
WearableDataCollector Service
    ↓
PhysiologicalSignalProcessor
├─ Process Health Data (HR, HRV, Activity)
└─ Process Eye Tracking Data (Gaze, Attention, Interest)
    ↓
PreferenceLearningEngine (Extended)
    ↓
UserPreferences (Updated)
    ↓
Recommendation Engine (Uses Updated Preferences)
```

### **2. Component Architecture**

#### **A. Health Sensor Integration Layer**
- **Android:** Health Connect API (`health` package)
- **iOS:** HealthKit (`health` package)
- **Web:** Limited (no native health APIs)

#### **A.1 AR Glasses & Eye Tracking Integration Layer**
- **iOS:** ARKit with Eye Tracking (`arkit_flutter` package)
- **Android:** ARCore with Eye Tracking (`arcore_flutter_plugin` + custom eye tracking)
- **Cross-platform:** `flutter_arcore` or `google_ar` packages
- **Eye Tracking:** Platform-specific APIs (ARKit Eye Tracking, ARCore Eye Tracking)

#### **B. Physiological & Visual Data Models**
- `PhysiologicalData` - Raw sensor data (HR, HRV, activity, etc.)
- `EyeTrackingData` - Raw eye tracking data (gaze, pupil, attention)
- `PhysiologicalSignal` - Processed signal (excitement, calmness, stress, etc.)
- `VisualInterestSignal` - Processed visual interest (attention, engagement, curiosity)
- `PhysiologicalContext` - Contextual state (location, activity, time, what user is looking at)

#### **C. Preference Mapping Engine**
- Maps physiological signals to preference adjustments
- Context-aware (same signal = different meaning in different contexts)
- Privacy-preserving (on-device processing)

#### **D. Integration Points**
- Extend `ComprehensiveDataCollector` to include physiological data
- Extend `PreferenceLearningEngine` to process physiological signals
- Extend `UserPreferences` model to include physiological influence weights

---

## 🎯 Target Wearables & Devices

### **Primary Targets (Phase 1-2)**

#### **1. Smartwatches & Fitness Trackers**
- **Apple Watch** (Series 4+)
  - Heart rate, HRV, activity, sleep
  - HealthKit integration
  - Most common wearable
  
- **Fitbit** (Versa, Sense, Charge series, **Sense 3 Pro**)
  - Heart rate, activity, sleep, stress
  - **Sense 3 Pro:** Upgraded EDA sensor for stress detection
  - Fitbit API integration
  
- **Garmin** (Forerunner, Venu, Fenix series, **Forerunner 55s**)
  - Heart rate, HRV, activity, stress
  - **Forerunner 55s:** Research-grade stress monitoring
  - Garmin Health API
  
- **Samsung Galaxy Watch**
  - Heart rate, activity, sleep
  - Samsung Health integration
  
- **Google Pixel Watch**
  - Heart rate, activity, sleep
  - Health Connect integration
  
- **Xiaomi Mi Band / Amazfit** series
  - Heart rate, activity, sleep
  - Affordable, high market share
  - Health Connect integration
  
- **Huawei Watch** series
  - Heart rate, HRV, activity, sleep
  - Huawei Health integration
  
- **OnePlus Watch**
  - Heart rate, activity, sleep
  - Health Connect integration
  
- **Fossil / Skagen** smartwatches
  - Wear OS devices
  - Heart rate, activity, sleep
  - Health Connect integration
  
- **TicWatch** (Mobvoi)
  - Wear OS devices
  - Heart rate, activity, sleep
  - Health Connect integration
  
- **Withings** smartwatches
  - Heart rate, HRV, activity, sleep
  - Health Connect / HealthKit integration
  
- **Whoop** (fitness tracker)
  - Heart rate, HRV, sleep, recovery metrics
  - Subscription-based
  - API available
  
- **Coros** (sports watches)
  - Heart rate, activity, GPS
  - Long battery life
  - Sports-focused
  
- **Suunto** (sports watches)
  - Heart rate, activity, GPS
  - Outdoor/sports focus
  - Health Connect integration

#### **2. Dedicated Heart Rate Monitors**
- **Polar H10** (chest strap)
- **Garmin HRM** (chest strap)
- **Wahoo Tickr** (chest strap)
- More accurate HR/HRV data

#### **2.1 Advanced Biometric Devices**
- **BioButton** (wearable patch)
  - Continuous vital signs tracking
  - Body temperature monitoring
  - Early infection detection
  - AI-driven sensor
  
- **E-Textiles** (smart clothing)
  - Embedded sensors in clothing
  - Sweat analysis (glucose, lactate, cortisol)
  - Continuous biomarker monitoring
  - Less invasive than blood tests

#### **3. Smart Rings (24/7 Comfortable Tracking)**
- **Oura Ring** (Gen 3 & Gen 4)
  - Heart rate, HRV, blood oxygen, sleep quality
  - 24/7 tracking, comfortable design
  - API available
  - High user adoption
  
- **Acer FreeSense Ring**
  - Heart rate, HRV, blood oxygen, sleep
  - No subscription required
  - Titanium design
  
- **VIV Ring**
  - Heart rate, stress levels, sleep cycles
  - AI-powered sleep aid sounds
  - Biometric analysis
  
- **Ultrahuman Ring**
  - Heart rate, HRV, sleep, activity
  - Metabolic health tracking
  
- **Circular Ring**
  - Heart rate, HRV, sleep, activity
  - Stress tracking

#### **4. AR Glasses with Eye Tracking (Phase 3)**
- **Apple Vision Pro**
  - Eye tracking (gaze, attention, pupil dilation)
  - ARKit Eye Tracking API
  - Hand tracking
  
- **Meta Quest Pro / Quest 3 / Quest 3S**
  - Eye tracking (gaze, attention)
  - Hand tracking
  - Standalone VR capabilities
  
- **Ray-Ban Meta Glasses**
  - AI-powered smart glasses
  - Integrated cameras
  - Content streaming
  - Growing consumer market
  
- **Warby Parker + Google Glasses** (2026)
  - AI-powered smart glasses
  - Android XR platform
  - Gemini AI integration
  - In-lens displays for navigation
  
- **Google Glass Enterprise Edition 2**
  - Basic eye tracking
  - Limited consumer availability
  
- **Snap Spectacles** (future)
  - AR capabilities
  - Potential eye tracking
  
- **Rokid Max / XREAL Air**
  - AR glasses
  - Limited eye tracking support
  
- **HTC Vive XR Elite**
  - Mixed reality headset
  - Standalone device
  - VR/MR capabilities
  
- **Play For Dream MR Headset** (March 2025)
  - Android-based spatial computer
  - Tobii XR5 eye tracking
  - Dynamic foveated rendering

### **Data Available by Device**

| Device Type | Heart Rate | HRV | Activity | Sleep | Stress | Eye Tracking | Gaze Patterns |
|-------------|------------|-----|----------|-------|--------|--------------|---------------|
| **Smartwatches** |
| Apple Watch | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| Fitbit (Sense 3 Pro) | ✅ | ✅ | ✅ | ✅ | ✅* | ❌ | ❌ |
| Garmin (Forerunner 55s) | ✅ | ✅ | ✅ | ✅ | ✅* | ❌ | ❌ |
| Samsung Galaxy Watch | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| Google Pixel Watch | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| Xiaomi/Amazfit | ✅ | ⚠️ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Whoop | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| **HR Monitors** |
| Polar H10 | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Garmin HRM | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Wahoo Tickr | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Smart Rings** |
| Oura Ring | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| Acer FreeSense | ✅ | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| VIV Ring | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **AR Glasses** |
| Apple Vision Pro | ⚠️** | ⚠️** | ⚠️** | ⚠️** | ❌ | ✅ | ✅ |
| Meta Quest Pro/3 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Ray-Ban Meta | ❌ | ❌ | ⚠️ | ❌ | ❌ | ⚠️ | ⚠️ |
| Warby Parker + Google | ❌ | ❌ | ⚠️ | ❌ | ❌ | ✅ | ✅ |

*Advanced stress detection (EDA sensor)  
**Can access health data from paired Apple Watch

---

## 📊 Wearable Priority Tiers

### **Tier 1: High Priority (Phase 1-2)**
**Most common, best API support, highest user adoption:**
- Apple Watch (Series 4+)
- Fitbit (especially Sense 3 Pro for stress detection)
- Garmin (especially Forerunner 55s for stress monitoring)
- Samsung Galaxy Watch
- Google Pixel Watch
- Oura Ring (smart ring leader, API available)

### **Tier 2: Medium Priority (Phase 2-3)**
**Growing market, good API support:**
- Xiaomi/Amazfit (high market share, affordable)
- Whoop (recovery metrics, API available)
- Ray-Ban Meta Glasses (growing consumer AR market)
- Meta Quest Pro/3/3S (VR with eye tracking)
- VIV Ring, Acer FreeSense Ring (smart ring alternatives)

### **Tier 3: Future Consideration (Phase 3+)**
**Emerging technology, specialized use cases:**
- Warby Parker + Google Glasses (2026 release)
- HTC Vive XR Elite (mixed reality)
- Play For Dream MR Headset (advanced eye tracking)
- BioButton (wearable patch for temperature/stress)
- E-Textiles (smart clothing for biomarker monitoring)
- Huawei Watch, OnePlus Watch, Fossil/Skagen, TicWatch, Withings
- Coros, Suunto (specialized sports watches)

---

## 👁️ AR Glasses & Eye Tracking Integration

### **Why Eye Tracking Matters**

**Eye tracking provides the missing piece:**
- **What you're looking at:** Know which spots/events catch your eye
- **Attention patterns:** How long you look = interest level
- **Pupil dilation:** Physiological response to interest/excitement
- **Gaze patterns:** How you explore a space reveals preferences
- **Contextual understanding:** What you're looking at when physiological signals occur

**Example:**
- User's heart rate elevates → Is it from excitement or stress?
- **Eye tracking shows:** User is fixated on a coffee shop sign → **Excitement!**
- **Eye tracking shows:** User is looking around anxiously → **Stress!**

### **Eye Tracking Data Models**

**New File:** `lib/core/models/eye_tracking_data.dart`

```dart
/// Raw eye tracking data from AR glasses
class EyeTrackingData {
  /// Gaze point in screen/world coordinates
  final GazePoint? gazePoint;
  
  /// Pupil diameter (mm) - indicates interest/excitement
  final double? pupilDiameter;
  
  /// Left and right eye positions
  final EyePosition? leftEye;
  final EyePosition? rightEye;
  
  /// Blink detection
  final bool isBlinking;
  final double? blinkDuration;
  
  /// Head pose (orientation)
  final HeadPose? headPose;
  
  /// Timestamp
  final DateTime timestamp;
  
  /// Device ID
  final String? deviceId;
  
  /// Metadata
  final Map<String, dynamic> metadata;
}

/// Gaze point (where user is looking)
class GazePoint {
  final double x;  // Screen/world X coordinate
  final double y;  // Screen/world Y coordinate
  final double z;  // Depth (if available)
  final double confidence;  // 0.0-1.0
}

/// Eye position
class EyePosition {
  final double x, y, z;  // 3D position
  final double confidence;
}

/// Head pose
class HeadPose {
  final double yaw;    // Left/right rotation
  final double pitch;  // Up/down rotation
  final double roll;   // Tilt rotation
}

/// Processed visual interest signal
class VisualInterestSignal {
  final InterestType type;  // attention, curiosity, engagement, disinterest
  final double intensity;   // 0.0-1.0
  final double confidence; // 0.0-1.0
  final EyeTrackingData sourceData;
  final DateTime timestamp;
  final VisualContext? context;
  
  /// What the user is looking at (if detected)
  final String? targetSpotId;
  final String? targetEventId;
  final String? targetElement;  // "sign", "menu", "entrance", etc.
}

enum InterestType {
  attention,      // Fixated gaze, sustained attention
  curiosity,      // Exploring gaze, scanning pattern
  engagement,     // Active looking, pupil dilation
  disinterest,    // Quick glance, no fixation
  stress,         // Rapid eye movement, avoiding gaze
  focus,          // Concentrated attention, steady gaze
}

/// Visual context (what user is looking at)
class VisualContext {
  final Location? location;
  final String? spotId;
  final String? eventId;
  final String? visualElement;  // What they're looking at
  final DateTime timeOfDay;
  final Map<String, dynamic> metadata;
}
```

### **Eye Tracking Processing Logic**

**Interest Detection:**
- **Attention:** Gaze fixated > 2 seconds on a spot/event
- **Curiosity:** Gaze scanning pattern, exploring multiple elements
- **Engagement:** Pupil dilation + sustained attention
- **Disinterest:** Quick glance < 0.5 seconds, no return
- **Stress:** Rapid eye movement, avoiding direct gaze
- **Focus:** Concentrated attention, minimal eye movement

**Pupil Dilation Analysis:**
- **Baseline:** Learn user's baseline pupil size
- **Interest:** Pupil dilation > 10% from baseline → Interest/excitement
- **Stress:** Pupil dilation + rapid movement → Stress/anxiety
- **Calm:** Stable pupil size + steady gaze → Calmness

**Gaze Pattern Analysis:**
- **Exploration pattern:** Scanning multiple spots → Curious, exploring
- **Fixation pattern:** Focused on one spot → Strong interest
- **Avoidance pattern:** Looking away from spots → Disinterest/stress

---

## 🔍 Gap Analysis

### **Identified Gaps**

#### **1. Missing Wearable Specifications** ✅ **FIXED**
- **Gap:** Plan didn't specify which wearables are targeted
- **Fix:** Added comprehensive list of target devices (Apple Watch, Fitbit, Garmin, etc.)

#### **2. AR Glasses Not Included** ✅ **FIXED**
- **Gap:** Plan didn't consider AR glasses as a wearable
- **Fix:** Added AR glasses integration (Apple Vision Pro, Meta Quest Pro, etc.)

#### **3. Eye Tracking Missing** ✅ **FIXED**
- **Gap:** Plan didn't include eye tracking data
- **Fix:** Added eye tracking models, processing, and integration

#### **4. Visual Interest Signals Missing** ✅ **FIXED**
- **Gap:** Plan only considered physiological signals, not visual interest
- **Fix:** Added `VisualInterestSignal` and `InterestType` enum

#### **5. Contextual Understanding Gap** ✅ **FIXED**
- **Gap:** Plan didn't connect "what user is looking at" with physiological signals
- **Fix:** Added `VisualContext` to link gaze data with spots/events

#### **6. AR Packages Not Specified** ⚠️ **TO ADD**
- **Gap:** Need to specify AR packages for Flutter
- **Fix:** Add AR packages to Phase 1 (see below)

#### **7. Eye Tracking API Integration** ⚠️ **TO ADD**
- **Gap:** Need to specify how to access eye tracking APIs
- **Fix:** Add platform-specific eye tracking integration (see below)

### **Additional Considerations**

#### **Smart Rings Advantages**
- **24/7 Comfort:** More comfortable than watches for sleep tracking
- **Continuous Data:** Never removed, better sleep/HRV data
- **Discrete:** Less obtrusive than watches
- **Growing Market:** Increasing adoption (Oura Ring leading)

#### **Advanced Stress Detection**
- **EDA Sensors:** Fitbit Sense 3 Pro, Garmin Forerunner 55s
- **Recovery Metrics:** Whoop provides detailed recovery data
- **Temperature Monitoring:** BioButton, E-Textiles
- **Cortisol Detection:** E-Textiles (sweat analysis)

#### **Battery Impact**
- Eye tracking is power-intensive
- Need adaptive sampling (reduce frequency when battery low)
- Consider processing only when AR glasses are active
- Smart rings have better battery life than watches

#### **Privacy Concerns**
- Eye tracking data is highly sensitive
- Must process entirely on-device
- User must explicitly opt-in
- Clear privacy controls
- Smart rings collect intimate health data (sleep, HRV)

#### **Platform Limitations**
- Eye tracking APIs vary by platform
- Not all AR glasses support eye tracking
- Need graceful degradation
- Some devices require proprietary APIs (Oura, Whoop)

---

## 📦 Implementation Plan

### **Phase 1: Foundation (3-4 days)**

#### **1.1 Add Health Sensor Packages**

**Files to Modify:**
- `pubspec.yaml`

**Packages to Add:**
```yaml
dependencies:
  # Health/Wearable Integration
  health: ^10.1.0  # Cross-platform health data (Android Health Connect, iOS HealthKit)
  
  # AR Glasses & Eye Tracking Integration
  arkit_flutter: ^0.5.0  # ARKit for iOS (Apple Vision Pro eye tracking)
  arcore_flutter_plugin: ^1.0.0  # ARCore for Android
  # OR alternative:
  # google_ar: ^1.0.0  # Google AR (cross-platform)
  
  # Eye Tracking (if available as separate package)
  # Note: Eye tracking may be part of ARKit/ARCore APIs
```

**Platform Permissions:**
- **Android:** 
  - `AndroidManifest.xml` - Health Connect permissions
  - ARCore permissions (camera, location)
- **iOS:** 
  - `Info.plist` - HealthKit permissions
  - ARKit permissions (camera, location)
  - Eye tracking permissions (ARKit Eye Tracking)

**Action Items:**
- [ ] Add `health` package to `pubspec.yaml`
- [ ] Add AR packages (`arkit_flutter`, `arcore_flutter_plugin`) to `pubspec.yaml`
- [ ] Update `android/app/src/main/AndroidManifest.xml` with Health Connect + ARCore permissions
- [ ] Update `ios/Runner/Info.plist` with HealthKit + ARKit + Eye Tracking permissions
- [ ] Run `flutter pub get`

---

#### **1.2 Create Physiological Data Models**

**New File:** `lib/core/models/physiological_data.dart`

**Models:**
```dart
/// Raw physiological data from wearable sensors
class PhysiologicalData {
  final double? heartRate;           // BPM
  final double? heartRateVariability; // ms
  final double? stressLevel;        // 0.0-1.0
  final double? activityLevel;      // 0.0-1.0
  final double? sleepQuality;       // 0.0-1.0
  final DateTime timestamp;
  final String? deviceId;
  final Map<String, dynamic> metadata;
}

/// Raw eye tracking data from AR glasses
class EyeTrackingData {
  final GazePoint? gazePoint;
  final double? pupilDiameter;      // mm - indicates interest
  final EyePosition? leftEye;
  final EyePosition? rightEye;
  final bool isBlinking;
  final double? blinkDuration;
  final HeadPose? headPose;
  final DateTime timestamp;
  final String? deviceId;
  final Map<String, dynamic> metadata;
}

/// Processed physiological signal (excitement, calmness, etc.)
class PhysiologicalSignal {
  final SignalType type;           // excitement, calmness, stress, energy, etc.
  final double intensity;          // 0.0-1.0
  final double confidence;           // 0.0-1.0
  final PhysiologicalData sourceData;
  final DateTime timestamp;
  final PhysiologicalContext? context;
}

/// Processed visual interest signal (from eye tracking)
class VisualInterestSignal {
  final InterestType type;  // attention, curiosity, engagement, etc.
  final double intensity;   // 0.0-1.0
  final double confidence;  // 0.0-1.0
  final EyeTrackingData sourceData;
  final DateTime timestamp;
  final VisualContext? context;
  final String? targetSpotId;    // What user is looking at
  final String? targetEventId;
  final String? targetElement;    // "sign", "menu", "entrance", etc.
}

enum SignalType {
  excitement,    // Elevated heart rate, high activity
  calmness,      // Lower heart rate, steady pattern
  stress,        // High HRV variability, elevated baseline
  energy,       // High activity, sustained heart rate
  relaxation,   // Low heart rate, low activity
  focus,         // Steady heart rate, moderate activity
}

enum InterestType {
  attention,      // Fixated gaze, sustained attention
  curiosity,      // Exploring gaze, scanning pattern
  engagement,     // Active looking, pupil dilation
  disinterest,    // Quick glance, no fixation
  stress,         // Rapid eye movement, avoiding gaze
  focus,          // Concentrated attention, steady gaze
}

/// Contextual information for physiological signals
class PhysiologicalContext {
  final Location? location;
  final String? activity;           // walking, sitting, exercising, etc.
  final DateTime timeOfDay;
  final String? spotId;             // If at a spot
  final String? eventId;              // If at an event
  final Map<String, dynamic> metadata;
}

/// Visual context (what user is looking at)
class VisualContext {
  final Location? location;
  final String? spotId;
  final String? eventId;
  final String? visualElement;  // What they're looking at
  final DateTime timeOfDay;
  final Map<String, dynamic> metadata;
}

// Supporting models for eye tracking
class GazePoint {
  final double x, y, z;
  final double confidence;
}

class EyePosition {
  final double x, y, z;
  final double confidence;
}

class HeadPose {
  final double yaw, pitch, roll;
}
```

**Action Items:**
- [ ] Create `lib/core/models/physiological_data.dart`
- [ ] Create `lib/core/models/eye_tracking_data.dart`
- [ ] Implement all models with JSON serialization
- [ ] Add Equatable support for comparison
- [ ] Create tests for models

---

#### **1.3 Create Wearable Data Collection Service**

**New File:** `lib/core/services/wearable_data_collector_service.dart`

**Service Interface:**
```dart
/// Service for collecting physiological and eye tracking data from wearable devices
class WearableDataCollectorService {
  // Health Data Methods
  /// Check if health data is available
  Future<bool> isHealthDataAvailable();
  
  /// Request health permissions
  Future<bool> requestHealthPermissions();
  
  /// Get current heart rate
  Future<double?> getCurrentHeartRate();
  
  /// Get heart rate history (last N minutes)
  Future<List<PhysiologicalData>> getHeartRateHistory({
    required Duration duration,
  });
  
  /// Stream real-time physiological data
  Stream<PhysiologicalData> streamPhysiologicalData({
    Duration interval = const Duration(seconds: 5),
  });
  
  /// Get physiological context (location, activity, etc.)
  Future<PhysiologicalContext> getCurrentContext();
  
  // Eye Tracking Methods (AR Glasses)
  /// Check if eye tracking is available
  Future<bool> isEyeTrackingAvailable();
  
  /// Request eye tracking permissions
  Future<bool> requestEyeTrackingPermissions();
  
  /// Get current eye tracking data
  Future<EyeTrackingData?> getCurrentEyeTrackingData();
  
  /// Stream real-time eye tracking data
  Stream<EyeTrackingData> streamEyeTrackingData({
    Duration interval = const Duration(milliseconds: 100),  // Higher frequency for eye tracking
  });
  
  /// Get visual context (what user is looking at)
  Future<VisualContext> getCurrentVisualContext();
  
  /// Detect what spot/event user is looking at (using gaze point + location)
  Future<String?> detectGazeTarget({
    required GazePoint gazePoint,
    required Location userLocation,
  });
}
```

**Implementation Strategy:**
- Use `health` package for cross-platform health data access
- Use ARKit/ARCore for eye tracking (platform-specific)
- Handle platform-specific differences (Android Health Connect vs iOS HealthKit)
- Handle platform-specific AR differences (ARKit vs ARCore)
- Implement offline-first (cache data locally)
- Privacy: All processing on-device
- **Eye tracking:** Higher frequency sampling (100ms) but adaptive based on battery

**Action Items:**
- [ ] Create `lib/core/services/wearable_data_collector_service.dart`
- [ ] Implement platform-specific health data access
- [ ] Implement platform-specific eye tracking access (ARKit/ARCore)
- [ ] Add permission handling (health + eye tracking)
- [ ] Implement data streaming (physiological + eye tracking)
- [ ] Add gaze target detection (what user is looking at)
- [ ] Add error handling and logging
- [ ] Create tests

---

### **Phase 2: Signal Processing (2-3 days)**

#### **2.1 Create Physiological Signal Processor**

**New File:** `lib/core/services/physiological_signal_processor.dart`

**Processor Interface:**
```dart
/// Processes raw physiological and eye tracking data into meaningful signals
class PhysiologicalSignalProcessor {
  // Physiological Signal Processing
  /// Process raw physiological data into signals
  Future<List<PhysiologicalSignal>> processPhysiologicalData(
    List<PhysiologicalData> data,
    PhysiologicalContext? context,
  );
  
  /// Detect excitement signal (elevated HR, high activity)
  PhysiologicalSignal? detectExcitement(
    PhysiologicalData data,
    PhysiologicalContext? context,
  );
  
  /// Detect calmness signal (lower HR, steady pattern)
  PhysiologicalSignal? detectCalmness(
    PhysiologicalData data,
    PhysiologicalContext? context,
  );
  
  /// Detect stress signal (high HRV variability)
  PhysiologicalSignal? detectStress(
    PhysiologicalData data,
    PhysiologicalContext? context,
  );
  
  /// Calculate signal intensity (0.0-1.0)
  double calculateIntensity(
    PhysiologicalData data,
    SignalType type,
  );
  
  /// Calculate signal confidence (0.0-1.0)
  double calculateConfidence(
    PhysiologicalData data,
    SignalType type,
  );
  
  // Eye Tracking Signal Processing
  /// Process raw eye tracking data into visual interest signals
  Future<List<VisualInterestSignal>> processEyeTrackingData(
    List<EyeTrackingData> data,
    VisualContext? context,
  );
  
  /// Detect attention signal (fixated gaze, sustained attention)
  VisualInterestSignal? detectAttention(
    EyeTrackingData data,
    VisualContext? context,
  );
  
  /// Detect curiosity signal (exploring gaze, scanning pattern)
  VisualInterestSignal? detectCuriosity(
    EyeTrackingData data,
    VisualContext? context,
  );
  
  /// Detect engagement signal (pupil dilation + sustained attention)
  VisualInterestSignal? detectEngagement(
    EyeTrackingData data,
    VisualContext? context,
  );
  
  /// Detect disinterest signal (quick glance, no fixation)
  VisualInterestSignal? detectDisinterest(
    EyeTrackingData data,
    VisualContext? context,
  );
  
  /// Calculate visual interest intensity (0.0-1.0)
  double calculateVisualIntensity(
    EyeTrackingData data,
    InterestType type,
  );
  
  /// Calculate visual interest confidence (0.0-1.0)
  double calculateVisualConfidence(
    EyeTrackingData data,
    InterestType type,
  );
  
  // Combined Processing (Physiological + Visual)
  /// Process combined physiological and visual data for richer signals
  Future<List<CombinedSignal>> processCombinedData({
    required List<PhysiologicalData> physiologicalData,
    required List<EyeTrackingData> eyeTrackingData,
    required PhysiologicalContext? physiologicalContext,
    required VisualContext? visualContext,
  });
}
```

**Processing Logic:**

**Physiological Signals:**
- **Excitement:** HR > baseline + 20%, activity > 0.7
- **Calmness:** HR < baseline + 10%, HRV stable, activity < 0.3
- **Stress:** HRV variability high, HR elevated but not from activity
- **Energy:** Sustained elevated HR with activity
- **Relaxation:** Low HR, low activity, stable pattern
- **Focus:** Steady HR, moderate activity, low variability

**Visual Interest Signals:**
- **Attention:** Gaze fixated > 2 seconds on a spot/event
- **Curiosity:** Gaze scanning pattern, exploring multiple elements
- **Engagement:** Pupil dilation > 10% from baseline + sustained attention
- **Disinterest:** Quick glance < 0.5 seconds, no return
- **Stress:** Rapid eye movement, avoiding direct gaze
- **Focus:** Concentrated attention, minimal eye movement

**Combined Signals (Physiological + Visual):**
- **Excitement + Attention:** Elevated HR + fixated gaze → Strong interest in spot
- **Calmness + Focus:** Low HR + steady gaze → Peaceful engagement
- **Stress + Avoidance:** High HRV + avoiding gaze → Stressful situation
- **Energy + Curiosity:** Elevated HR + exploring gaze → Energetic exploration

**Baseline Calculation:**
- Learn user's baseline heart rate over time
- Adjust for context (resting vs active)
- Account for time of day, activity level

**Action Items:**
- [ ] Create `lib/core/services/physiological_signal_processor.dart`
- [ ] Implement physiological signal detection algorithms
- [ ] Implement eye tracking signal detection algorithms
- [ ] Implement combined signal processing (physiological + visual)
- [ ] Add baseline learning logic (HR, pupil size)
- [ ] Implement context-aware processing
- [ ] Add confidence calculation
- [ ] Create tests

---

#### **2.2 Extend Comprehensive Data Collector**

**File to Modify:** `lib/core/ai/comprehensive_data_collector.dart`

**Changes:**
- Add `_collectPhysiologicalData()` method
- Add `_collectEyeTrackingData()` method
- Add `PhysiologicalData` and `EyeTrackingData` to `ComprehensiveData` model
- Integrate with `WearableDataCollectorService`

**Action Items:**
- [ ] Add `_collectPhysiologicalData()` method
- [ ] Add `_collectEyeTrackingData()` method
- [ ] Extend `ComprehensiveData` model to include physiological + eye tracking data
- [ ] Integrate with `WearableDataCollectorService`
- [ ] Update `ContinuousLearningSystem` to include physiological + visual data sources

---

### **Phase 3: Preference Integration (3-4 days)**

#### **3.1 Extend UserPreferences Model**

**File to Modify:** `lib/core/models/user_preferences.dart`

**New Fields:**
```dart
class UserPreferences extends Equatable {
  // ... existing fields ...
  
  /// Physiological influence weights (signal type -> weight 0.0-1.0)
  /// Higher weight = physiological signals have more influence
  final Map<SignalType, double> physiologicalInfluenceWeights;
  
  /// Visual interest influence weights (interest type -> weight 0.0-1.0)
  /// Higher weight = eye tracking signals have more influence
  final Map<InterestType, double> visualInterestInfluenceWeights;
  
  /// Physiological baseline (for context-aware processing)
  final PhysiologicalBaseline? physiologicalBaseline;
  
  /// Visual baseline (pupil size, gaze patterns)
  final VisualBaseline? visualBaseline;
  
  /// Last physiological signal timestamp
  final DateTime? lastPhysiologicalSignalTime;
  
  /// Last visual interest signal timestamp
  final DateTime? lastVisualInterestSignalTime;
}
```

**Action Items:**
- [ ] Add physiological fields to `UserPreferences`
- [ ] Update JSON serialization
- [ ] Update `copyWith` method
- [ ] Create `PhysiologicalBaseline` model
- [ ] Update tests

---

#### **3.2 Extend Preference Learning Engine**

**File to Modify:** `lib/core/ml/preference_learning.dart`

**New Methods:**
```dart
class PreferenceLearningEngine {
  /// Learn preferences from physiological signals
  Future<UserPreferences> learnFromPhysiologicalSignals({
    required User user,
    required List<PhysiologicalSignal> signals,
    required List<Spot> associatedSpots,
  });
  
  /// Learn preferences from visual interest signals (eye tracking)
  Future<UserPreferences> learnFromVisualInterestSignals({
    required User user,
    required List<VisualInterestSignal> signals,
    required List<Spot> associatedSpots,
  });
  
  /// Learn preferences from combined signals (physiological + visual)
  Future<UserPreferences> learnFromCombinedSignals({
    required User user,
    required List<PhysiologicalSignal> physiologicalSignals,
    required List<VisualInterestSignal> visualSignals,
    required List<Spot> associatedSpots,
  });
  
  /// Adjust preferences based on excitement signal
  UserPreferences adjustForExcitement({
    required UserPreferences current,
    required PhysiologicalSignal signal,
    required Spot? spot,
  });
  
  /// Adjust preferences based on calmness signal
  UserPreferences adjustForCalmness({
    required UserPreferences current,
    required PhysiologicalSignal signal,
    required Spot? spot,
  });
  
  /// Adjust preferences based on visual attention signal
  UserPreferences adjustForAttention({
    required UserPreferences current,
    required VisualInterestSignal signal,
    required Spot? spot,
  });
  
  /// Adjust preferences based on visual engagement signal
  UserPreferences adjustForEngagement({
    required UserPreferences current,
    required VisualInterestSignal signal,
    required Spot? spot,
  });
  
  /// Calculate preference adjustment weight
  double calculateAdjustmentWeight({
    required PhysiologicalSignal signal,
    required UserPreferences current,
  });
  
  /// Calculate visual preference adjustment weight
  double calculateVisualAdjustmentWeight({
    required VisualInterestSignal signal,
    required UserPreferences current,
  });
}
```

**Learning Logic:**

**Physiological Signals:**
- **Excitement at a spot:** Increase preference for similar spots
- **Calmness at a spot:** Increase preference for similar calm spots
- **Stress at a spot:** Decrease preference for similar spots
- **Context-aware:** Same signal = different meaning in different contexts

**Visual Interest Signals:**
- **Attention on a spot:** Increase preference for that spot (user looked at it)
- **Engagement with a spot:** Strong increase (pupil dilation + attention)
- **Curiosity about spots:** Increase preference for exploration
- **Disinterest in spots:** Decrease preference for similar spots
- **Context-aware:** What user is looking at matters (gaze target detection)

**Combined Signals (Most Powerful):**
- **Excitement + Attention:** Strongest signal - user is excited AND looking at spot
- **Calmness + Focus:** User is calm AND focused on spot
- **Stress + Avoidance:** User is stressed AND avoiding spot
- **Energy + Curiosity:** User is energetic AND exploring

**Action Items:**
- [ ] Add physiological learning methods
- [ ] Implement preference adjustment algorithms
- [ ] Add context-aware processing
- [ ] Integrate with `PhysiologicalSignalProcessor`
- [ ] Create tests

---

#### **3.3 Extend UserPreferenceLearningService**

**File to Modify:** `lib/core/services/user_preference_learning_service.dart`

**New Methods:**
```dart
class UserPreferenceLearningService {
  /// Learn preferences incorporating physiological data
  Future<UserPreferences> learnUserPreferencesWithPhysiological({
    required UnifiedUser user,
    List<PhysiologicalSignal>? physiologicalSignals,
  });
  
  /// Update preferences based on real-time physiological signals
  Future<UserPreferences> updatePreferencesFromPhysiologicalSignal({
    required UnifiedUser user,
    required PhysiologicalSignal signal,
    Spot? associatedSpot,
  });
}
```

**Action Items:**
- [ ] Add physiological learning methods
- [ ] Integrate with `WearableDataCollectorService`
- [ ] Integrate with `PhysiologicalSignalProcessor`
- [ ] Update existing learning methods to consider physiological data
- [ ] Create tests

---

### **Phase 4: Real-Time Integration (2-3 days)**

#### **4.1 Create Physiological Preference Manager**

**New File:** `lib/core/services/physiological_preference_manager.dart`

**Manager Interface:**
```dart
/// Manages real-time physiological data and preference updates
class PhysiologicalPreferenceManager {
  /// Start monitoring physiological data
  Future<void> startMonitoring();
  
  /// Stop monitoring physiological data
  Future<void> stopMonitoring();
  
  /// Stream of preference updates from physiological signals
  Stream<UserPreferences> streamPreferenceUpdates();
  
  /// Get current physiological state
  Future<PhysiologicalState> getCurrentState();
  
  /// Process signal and update preferences
  Future<void> processSignal(PhysiologicalSignal signal);
}
```

**Action Items:**
- [ ] Create `lib/core/services/physiological_preference_manager.dart`
- [ ] Implement real-time monitoring
- [ ] Integrate with all services
- [ ] Add preference update streaming
- [ ] Create tests

---

#### **4.2 Integrate with Recommendation Engine**

**Files to Modify:**
- Recommendation service files

**Changes:**
- Consider physiological state when generating recommendations
- Adjust recommendation scores based on current physiological state
- Show different doors based on user's current state

**Example:**
- User is stressed (high HRV variability) → Suggest calm spots (parks, libraries)
- User is excited (elevated HR) → Suggest energetic spots (events, active communities)
- User is calm (low HR) → Suggest similar calm spots

**Action Items:**
- [ ] Find recommendation service files
- [ ] Add physiological state consideration
- [ ] Update recommendation scoring
- [ ] Test recommendation changes

---

### **Phase 5: Privacy & Permissions (1-2 days)**

#### **5.1 Privacy Controls**

**New File:** `lib/presentation/pages/settings/wearable_settings_page.dart`

**Features:**
- Toggle physiological data collection on/off
- Control which signals are used
- View collected data
- Delete physiological data
- Export physiological data

**Action Items:**
- [ ] Create settings page
- [ ] Add privacy controls
- [ ] Implement data deletion
- [ ] Add data export
- [ ] Create tests

---

#### **5.2 Permission Handling**

**Files to Modify:**
- `lib/core/services/wearable_data_collector_service.dart`

**Features:**
- Request health permissions
- Handle permission denial gracefully
- Show permission rationale
- Re-request permissions if needed

**Action Items:**
- [ ] Implement permission requests
- [ ] Add permission denial handling
- [ ] Create permission UI
- [ ] Test permission flows

---

### **Phase 6: Testing & Documentation (2-3 days)**

#### **6.1 Unit Tests**

**Test Files:**
- `test/unit/models/physiological_data_test.dart`
- `test/unit/services/wearable_data_collector_service_test.dart`
- `test/unit/services/physiological_signal_processor_test.dart`
- `test/unit/services/physiological_preference_manager_test.dart`
- `test/unit/ml/preference_learning_physiological_test.dart`

**Action Items:**
- [ ] Create all test files
- [ ] Write comprehensive tests
- [ ] Achieve 90%+ coverage
- [ ] Fix any failures

---

#### **6.2 Integration Tests**

**Test Files:**
- `test/integration/wearable_integration_test.dart`

**Scenarios:**
- Full flow: Device → Collection → Processing → Preference Update → Recommendation
- Permission handling
- Offline functionality
- Error handling

**Action Items:**
- [ ] Create integration test
- [ ] Test full flow
- [ ] Test edge cases
- [ ] Test error scenarios

---

#### **6.3 Documentation**

**Documentation Files:**
- `docs/wearables/user_guide.md` - User-facing documentation
- `docs/wearables/developer_guide.md` - Developer guide
- Update `OUR_GUTS.md` if needed

**Action Items:**
- [ ] Create user documentation
- [ ] Create developer guide
- [ ] Update architecture docs
- [ ] Add code comments

---

## 🔒 Privacy & Security

### **Privacy Principles**

1. **On-Device Processing:** All physiological data processing happens on-device
2. **User Control:** User can enable/disable at any time
3. **Data Minimization:** Only collect what's needed
4. **No Cloud Sync:** Physiological data never leaves device (unless user explicitly exports)
5. **Transparent:** User can see what data is collected and how it's used

### **Security Measures**

1. **Encryption:** Encrypt physiological data at rest
2. **Access Control:** Only preference learning service can access
3. **Audit Logging:** Log all access to physiological data
4. **Permission Enforcement:** Strict permission checks

---

## 📊 Success Metrics

### **Technical Metrics**
- ✅ Health data collection working (Android & iOS)
- ✅ Signal processing accuracy > 80%
- ✅ Preference updates in real-time (< 5 second delay)
- ✅ Privacy controls functional
- ✅ Test coverage ≥ 90%

### **User Experience Metrics**
- **Doors Opened:** More accurate recommendations based on physiological state
- **User Satisfaction:** Users find spots that match their current state
- **Engagement:** Users engage more with spots that match their physiology

### **Philosophy Alignment**
- ✅ Helps identify which doors truly resonate (body's authentic response)
- ✅ Enhances real-world experience (better recommendations)
- ✅ Always learning with user (continuous improvement)
- ✅ Privacy-first (on-device, user-controlled)

---

## 🚨 Risks & Mitigations

### **Risk 1: Health Data Privacy Concerns**
**Mitigation:**
- Clear privacy controls
- On-device processing only
- Transparent data usage
- User can disable anytime

### **Risk 2: Inaccurate Signal Detection**
**Mitigation:**
- Confidence scores for all signals
- Baseline learning over time
- Context-aware processing
- User feedback loop

### **Risk 3: Battery Drain**
**Mitigation:**
- Configurable sampling interval
- Smart sampling (only when needed)
- Background processing optimization

### **Risk 4: Platform Differences**
**Mitigation:**
- Use cross-platform `health` package
- Graceful degradation (works without wearables)
- Platform-specific optimizations

---

## 🔗 Dependencies

### **External Dependencies**
- `health` package (Health Connect/HealthKit) - Primary integration
- **Oura Ring API** - For Oura Ring integration (if available)
- **Whoop API** - For Whoop integration (if available)
- **Fitbit API** - For advanced Fitbit features (EDA sensor)
- **Garmin Health API** - For Garmin devices
- Health permissions (platform-specific)
- AR packages (`arkit_flutter`, `arcore_flutter_plugin`) - For AR glasses

### **Internal Dependencies**
- `UserPreferences` model
- `PreferenceLearningEngine`
- `ComprehensiveDataCollector`
- `ContinuousLearningSystem`

### **No Blocking Dependencies**
- Can be implemented in parallel with other features
- Graceful degradation if health data unavailable

---

## 📅 Timeline

**Total: 3-4 weeks** (expanded to include AR glasses, eye tracking, smart rings, and advanced biometrics)

- **Phase 1:** Foundation (4-5 days) - Includes AR packages, eye tracking models, smart ring APIs
- **Phase 2:** Signal Processing (3-4 days) - Includes visual interest processing, stress detection (EDA)
- **Phase 3:** Preference Integration (4-5 days) - Includes visual interest learning, smart ring data
- **Phase 4:** Real-Time Integration (3-4 days) - Includes eye tracking streaming, multi-device support
- **Phase 5:** Privacy & Permissions (2-3 days) - Includes eye tracking privacy, smart ring data privacy
- **Phase 6:** Testing & Documentation (3-4 days) - Includes eye tracking tests, multi-device testing

**Note:** Smart rings and advanced biometrics can be added incrementally after core smartwatch integration is complete.

---

## 🎯 Next Steps

1. **Review this plan** with team
2. **Get user approval** for health data collection
3. **Start Phase 1:** Add health packages and create models
4. **Iterate:** Build and test incrementally

---

## 📚 Related Documentation

- **Philosophy:** `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- **Preference Learning:** `lib/core/ml/preference_learning.dart`
- **Data Collection:** `lib/core/ai/comprehensive_data_collector.dart`
- **Continuous Learning:** `lib/core/ai/continuous_learning_system.dart`

---

---

## 🗺️ **AR NAVIGATION & RESERVATION INTEGRATION (Future Work)**

### **Overview**

**Date Added:** January 6, 2026  
**Status:** 📋 **PLANNED FOR FUTURE IMPLEMENTATION**  
**Purpose:** AR lenses and directions to exact spots using spot's check-in configuration, with privacy-preserved architecture through AI2AI system and VPN

### **Concept: AR Navigation to Reservation Spots**

**Integration Point:**
- Spot's `check_in_config` provides exact coordinates for AR navigation
- Reservations reference spot's check-in config (single source of truth)
- AR lenses can display directions to exact check-in location
- Privacy preserved through agentId, location obfuscation, and VPN

### **Architecture:**

**1. Spot's Check-In Config → AR Navigation:**
```dart
// Spot has exact check-in coordinates
class Spot {
  final Map<String, dynamic>? checkInConfig; // {
    //   "check_in_spot": {
    //     "latitude": 40.7128,  // EXACT coordinates
    //     "longitude": -74.0060,
    //     "accuracy_threshold_meters": 5.0
    //   }
    // }
}

// AR Navigation Service uses spot's exact coordinates
class ARNavigationService {
  Future<ARNavigationRoute> getRouteToSpot({
    required Reservation reservation,
    required String agentId, // Privacy-preserved (not userId)
    required double currentLatitude,
    required double currentLongitude,
  }) async {
    // Get spot's exact check-in coordinates
    final spot = await _getSpot(reservation.targetId);
    final checkInConfig = spot.checkInConfig;
    final targetLat = checkInConfig['check_in_spot']['latitude'];
    final targetLng = checkInConfig['check_in_spot']['longitude'];
    
    // Calculate route using exact coordinates (LOCAL calculation)
    final route = await _calculateRoute(
      from: (currentLatitude, currentLongitude),
      to: (targetLat, targetLng),
      agentId: agentId, // Privacy-preserved identifier
    );
    
    return route;
  }
}
```

**2. Privacy Layers:**

**Layer 1: AgentId (Not UserId)**
- AR navigation uses `agentId` (privacy-preserved identifier)
- Never uses `userId` for routing or navigation
- `agentId` cannot be linked back to personal information

**Layer 2: Local Calculation (On-Device)**
- Route calculation happens on-device (no server calls)
- Exact coordinates stay on device (never transmitted)
- AR rendering happens locally (no cloud processing)

**Layer 3: AI2AI Mesh (Obfuscated Location)**
- If routing needs mesh assistance, location is obfuscated:
  ```dart
  // LocationObfuscationService obfuscates to city-level
  final obfuscatedLocation = await _locationObfuscationService.obfuscateLocation(
    locationString: userLocation,
    userId: userId, // Only for home location check
    isAdmin: false,
  );
  // Result: City-level only (~1km precision), not exact coordinates
  ```

**Layer 4: VPN Integration (Additional Privacy)**
- VPN encrypts all network traffic
- Hides IP address from external services
- Works with existing VPN/Proxy plans

**3. AR Lens Integration:**

```dart
// AR Lens Service
class ARLensService {
  Future<AROverlay> showNavigationToSpot({
    required Reservation reservation,
    required String agentId,
    required ARCamera camera,
  }) async {
    // Get spot's exact check-in coordinates (from check_in_config)
    final spot = await _getSpot(reservation.targetId);
    final checkInConfig = spot.checkInConfig;
    final targetLat = checkInConfig['check_in_spot']['latitude'];
    final targetLng = checkInConfig['check_in_spot']['longitude'];
    
    // Get user's current location (LOCAL, never transmitted)
    final currentLocation = await _getCurrentLocation(); // On-device GPS
    
    // Calculate route (LOCAL calculation)
    final route = await _calculateRouteLocally(
      from: currentLocation,
      to: (targetLat, targetLng),
      agentId: agentId, // Privacy-preserved
    );
    
    // Render AR overlay (LOCAL rendering)
    return AROverlay(
      route: route,
      targetSpot: spot,
      // All rendering happens on-device
      // No location data transmitted
    );
  }
}
```

### **Privacy Guarantees:**

**✅ Exact Coordinates Stay Local:**
- Spot's `check_in_config` coordinates used only on-device
- Never transmitted to server or AI2AI mesh
- AR rendering happens locally

**✅ AgentId for Routing:**
- Navigation uses `agentId` (not `userId`)
- Cannot be linked back to personal information
- Privacy-preserved identifier

**✅ AI2AI Mesh (If Needed):**
- Location obfuscated to city-level (~1km precision)
- Differential privacy noise added
- Home location never shared

**✅ VPN Layer:**
- All network traffic encrypted
- IP address hidden
- Additional privacy protection

### **Implementation Flow:**

```
User Opens AR Navigation
    ↓
Get Spot's check_in_config (exact coordinates)
    ↓
Get User's Current Location (LOCAL GPS, on-device)
    ↓
Calculate Route (LOCAL calculation, on-device)
    ↓
Render AR Overlay (LOCAL rendering, on-device)
    ↓
[Optional] AI2AI Mesh Assistance
    ├─ Obfuscate location to city-level
    ├─ Use agentId (not userId)
    ├─ Route through VPN
    └─ Get routing hints (not exact route)
    ↓
Display AR Directions (LOCAL, on-device)
```

### **Integration Points:**

- ✅ **Spot's `check_in_config`:** Provides exact coordinates for navigation
- ✅ **AgentId System:** Privacy-preserved routing identifier
- ✅ **LocationObfuscationService:** Obfuscates location for mesh (if needed)
- ✅ **VPN/Proxy Plans:** Additional privacy layer
- ✅ **AR Glasses Support:** Existing plans for Apple Vision Pro, Meta Quest, etc.
- ✅ **Reservation System:** Phase 15 integration with spot check-in config

### **Future Implementation Requirements:**

1. **AR Navigation Service:**
   - `ARNavigationService` - Route calculation using spot's check-in config
   - `ARLensService` - AR overlay rendering
   - Local route calculation (on-device)
   - AR rendering (on-device)

2. **Privacy Integration:**
   - AgentId-based routing (not userId)
   - Location obfuscation for mesh assistance
   - VPN integration for network traffic
   - Local processing (no server calls)

3. **AR Glasses Integration:**
   - ARKit/ARCore for AR rendering
   - Eye tracking for gaze-based navigation
   - Hand tracking for interaction
   - Spatial mapping for accurate positioning

4. **Reservation Integration:**
   - Use spot's `check_in_config` for exact coordinates
   - Link to reservation system (Phase 15)
   - Show reservation context in AR overlay
   - Privacy-preserved check-in integration

### **Benefits:**

**For Users:**
- ✅ **Seamless Navigation:** AR directions to exact check-in location
- ✅ **Privacy-Preserved:** Exact coordinates stay local, agentId for routing
- ✅ **Offline Support:** Local route calculation works offline
- ✅ **Visual Guidance:** AR overlay shows exact path to spot

**For System:**
- ✅ **Single Source of Truth:** Uses spot's `check_in_config` (no duplicate storage)
- ✅ **Privacy-First:** Multiple privacy layers (agentId, obfuscation, VPN)
- ✅ **Performance:** Local processing (fast, no network latency)
- ✅ **Consistency:** Same check-in config used for navigation and check-in

### **Related Documentation:**
- **Reservation System:** `docs/plans/reservations/RESERVATION_SYSTEM_IMPLEMENTATION_PLAN.md`
- **Spots System:** `docs/plans/spots/SPOTS_SYSTEM_COMPREHENSIVE_ORGANIZATION.md`
- **Privacy Architecture:** `docs/security/SECURITY_ARCHITECTURE.md`
- **VPN/Proxy Plans:** `docs/plans/white_label/WHITE_LABEL_VPN_PROXY_PLAN.md`

---

**Status:** 🟢 Active - Ready for Implementation  
**Last Updated:** January 6, 2026 (AR Navigation Integration Added)  
**Next Review:** After Phase 1 completion
