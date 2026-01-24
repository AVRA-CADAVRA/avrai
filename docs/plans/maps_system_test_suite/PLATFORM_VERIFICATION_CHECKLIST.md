# Maps System Test Suite - Platform Verification Checklist

**Date:** January 2025  
**Status:** ⏳ **Pending Platform Verification**  
**Purpose:** Verify all maps system tests pass on Android, iOS, and macOS platforms

---

## 🎯 **Overview**

This checklist provides step-by-step instructions for verifying the maps system test suite on each platform. All tests pass in the development environment, but platform-specific verification ensures:

- Correct map type selection on each platform
- Google Maps SDK works correctly on Android (and iOS when enabled)
- flutter_map works correctly on macOS and iOS fallback
- All features (boundaries, geohashes, markers) work on each platform

---

## 📱 **Android Platform Verification**

### **Prerequisites:**
- [ ] Android emulator or physical device connected
- [ ] Google Maps API key configured for Android
- [ ] Flutter Android build tools installed

### **Verification Steps:**

1. **Run Unit Tests:**
   ```bash
   flutter test test/unit/models/map_boundary_test.dart
   flutter test test/unit/widgets/map/map_boundary_converter_test.dart
   flutter test test/unit/widgets/map/map_platform_detection_test.dart
   ```
   - [ ] All unit tests pass (22 tests)

2. **Run Widget Tests:**
   ```bash
   flutter test test/widget/widgets/map/
   ```
   - [ ] All widget tests pass (9 tests)

3. **Run Integration Tests:**
   ```bash
   flutter test test/integration/maps/
   ```
   - [ ] All integration tests pass (21 tests)

4. **Platform-Specific Verification:**
   ```bash
   flutter test test/integration/maps/map_platform_selection_test.dart --dart-define=ENABLE_IOS_GOOGLE_MAPS=false
   ```
   - [ ] Android-specific test passes (should use Google Maps)
   - [ ] MapView loads Google Maps widget correctly
   - [ ] Boundaries render correctly on Google Maps
   - [ ] Geohash overlays render correctly on Google Maps

5. **Manual Testing:**
   - [ ] Launch app on Android device/emulator
   - [ ] Navigate to Map tab
   - [ ] Verify Google Maps loads (not flutter_map)
   - [ ] Verify boundaries display correctly
   - [ ] Verify geohash overlays display correctly
   - [ ] Verify map loads immediately without flashing

### **Expected Results:**
- ✅ All 52 tests pass
- ✅ Google Maps is used (not flutter_map)
- ✅ All features work correctly
- ✅ Map loads immediately without flashing

---

## 🍎 **iOS Platform Verification**

### **Prerequisites:**
- [ ] iOS Simulator or physical device available
- [ ] Xcode installed and configured
- [ ] Flutter iOS build tools installed

### **Verification Steps - iOS with flutter_map (Default):**

1. **Run All Tests (Default - flutter_map):**
   ```bash
   flutter test test/unit/models/map_boundary_test.dart
   flutter test test/unit/widgets/map/
   flutter test test/integration/maps/
   ```
   - [ ] All tests pass (52 tests)

2. **Platform-Specific Verification:**
   ```bash
   flutter test test/integration/maps/map_platform_selection_test.dart
   ```
   - [ ] iOS-specific test passes (should use flutter_map by default)
   - [ ] MapView loads flutter_map widget correctly
   - [ ] Boundaries render correctly on flutter_map
   - [ ] Geohash overlays render correctly on flutter_map

3. **Manual Testing (flutter_map):**
   - [ ] Launch app on iOS Simulator/device
   - [ ] Navigate to Map tab
   - [ ] Verify flutter_map loads (not Google Maps)
   - [ ] Verify boundaries display correctly
   - [ ] Verify geohash overlays display correctly
   - [ ] Verify map loads immediately without flashing

### **Verification Steps - iOS with Google Maps (When Enabled):**

1. **Run Tests with Google Maps Enabled:**
   ```bash
   flutter test test/integration/maps/map_platform_selection_test.dart --dart-define=ENABLE_IOS_GOOGLE_MAPS=true
   ```
   - [ ] iOS-specific test passes (should use Google Maps when enabled)
   - [ ] MapView loads Google Maps widget correctly
   - [ ] Boundaries render correctly on Google Maps
   - [ ] Geohash overlays render correctly on Google Maps

2. **Manual Testing (Google Maps):**
   - [ ] Build app with `ENABLE_IOS_GOOGLE_MAPS=true`
   - [ ] Launch app on iOS Simulator/device
   - [ ] Navigate to Map tab
   - [ ] Verify Google Maps loads (not flutter_map)
   - [ ] Verify boundaries display correctly
   - [ ] Verify geohash overlays display correctly
   - [ ] Verify map loads immediately without flashing

### **Expected Results:**
- ✅ All 52 tests pass
- ✅ flutter_map used by default (when `ENABLE_IOS_GOOGLE_MAPS` not set)
- ✅ Google Maps used when `ENABLE_IOS_GOOGLE_MAPS=true`
- ✅ All features work correctly on both map types
- ✅ Map loads immediately without flashing

---

## 💻 **macOS Platform Verification**

### **Prerequisites:**
- [ ] macOS development machine
- [ ] Xcode installed and configured
- [ ] Flutter macOS build tools installed

### **Verification Steps:**

1. **Run Unit Tests:**
   ```bash
   flutter test test/unit/models/map_boundary_test.dart
   flutter test test/unit/widgets/map/map_boundary_converter_test.dart
   flutter test test/unit/widgets/map/map_platform_detection_test.dart
   ```
   - [ ] All unit tests pass (22 tests)

2. **Run Widget Tests:**
   ```bash
   flutter test test/widget/widgets/map/
   ```
   - [ ] All widget tests pass (9 tests)

3. **Run Integration Tests:**
   ```bash
   flutter test test/integration/maps/
   ```
   - [ ] All integration tests pass (21 tests)

4. **Platform-Specific Verification:**
   ```bash
   flutter test test/integration/maps/map_platform_selection_test.dart
   ```
   - [ ] macOS-specific test passes (should use flutter_map)
   - [ ] MapView loads flutter_map widget correctly
   - [ ] Boundaries render correctly on flutter_map
   - [ ] Geohash overlays render correctly on flutter_map

5. **Manual Testing:**
   - [ ] Launch app on macOS
   - [ ] Navigate to Map tab
   - [ ] Verify flutter_map loads (not Google Maps)
   - [ ] Verify boundaries display correctly
   - [ ] Verify geohash overlays display correctly
   - [ ] Verify map loads immediately without flashing

### **Expected Results:**
- ✅ All 52 tests pass
- ✅ flutter_map is used (Google Maps not supported on macOS)
- ✅ All features work correctly
- ✅ Map loads immediately without flashing

---

## 🔍 **Common Verification Points**

For all platforms, verify:

### **Map Type Selection:**
- [ ] Correct map type loads based on platform
- [ ] Map type is determined immediately (no flashing)
- [ ] Map type doesn't change during widget lifecycle

### **Boundary Rendering:**
- [ ] Locality polygons render correctly
- [ ] City geohash3 tiles render correctly
- [ ] Neighborhood boundaries render correctly
- [ ] Boundary priority hierarchy works (locality > city > geohash)

### **Geohash Overlays:**
- [ ] Geohash boundaries generate correctly (center + 8 neighbors)
- [ ] Geohash overlays render correctly on map
- [ ] Geohash encoding/decoding works correctly

### **Error Handling:**
- [ ] Service errors handled gracefully
- [ ] Missing data handled gracefully
- [ ] Invalid boundaries handled gracefully

### **Performance:**
- [ ] Map loads immediately on app opening
- [ ] No flashing or switching between map types
- [ ] Smooth rendering of boundaries and overlays

---

## 📊 **Verification Results Template**

### **Android:**
- Date: ___________
- Tester: ___________
- Device/Emulator: ___________
- Unit Tests: [ ] Pass [ ] Fail
- Widget Tests: [ ] Pass [ ] Fail
- Integration Tests: [ ] Pass [ ] Fail
- Manual Testing: [ ] Pass [ ] Fail
- Notes: ___________

### **iOS (flutter_map):**
- Date: ___________
- Tester: ___________
- Device/Simulator: ___________
- Unit Tests: [ ] Pass [ ] Fail
- Widget Tests: [ ] Pass [ ] Fail
- Integration Tests: [ ] Pass [ ] Fail
- Manual Testing: [ ] Pass [ ] Fail
- Notes: ___________

### **iOS (Google Maps):**
- Date: ___________
- Tester: ___________
- Device/Simulator: ___________
- Unit Tests: [ ] Pass [ ] Fail
- Widget Tests: [ ] Pass [ ] Fail
- Integration Tests: [ ] Pass [ ] Fail
- Manual Testing: [ ] Pass [ ] Fail
- Notes: ___________

### **macOS:**
- Date: ___________
- Tester: ___________
- Unit Tests: [ ] Pass [ ] Fail
- Widget Tests: [ ] Pass [ ] Fail
- Integration Tests: [ ] Pass [ ] Fail
- Manual Testing: [ ] Pass [ ] Fail
- Notes: ___________

---

## 🐛 **Troubleshooting**

### **Tests Fail on Platform:**
1. Check platform-specific dependencies are installed
2. Verify API keys are configured correctly
3. Check platform-specific build configuration
4. Review test output for platform-specific errors

### **Map Type Incorrect:**
1. Verify platform detection logic
2. Check `ENABLE_IOS_GOOGLE_MAPS` environment variable (iOS)
3. Verify map type caching in `initState()`

### **Boundaries Not Rendering:**
1. Check boundary data is available
2. Verify boundary conversion logic
3. Check map-specific rendering code

### **Geohash Overlays Not Rendering:**
1. Verify geohash service is working
2. Check geohash encoding/decoding
3. Verify overlay conversion logic

---

## ✅ **Completion Criteria**

Platform verification is complete when:

- [ ] All tests pass on Android
- [ ] All tests pass on iOS (both flutter_map and Google Maps)
- [ ] All tests pass on macOS
- [ ] Manual testing confirms correct behavior on all platforms
- [ ] All features work correctly on each platform
- [ ] Map loads immediately without flashing on all platforms

---

**Status:** ⏳ **Ready for Platform Verification**
