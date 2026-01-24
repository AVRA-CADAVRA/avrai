# macOS LLM & Maps Testing Guide

**Quick reference for testing LLM integration and Maps functionality**

---

## 🧪 Testing LLM Integration

### **Option 1: Manual Testing (Recommended for First Run)**

#### **Step 1: Build and Run App**

```bash
cd /Users/reisgordon/AVRAI

# Build with manifest public key (required for model download)
flutter run -d macos \
  --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=HULfUDT5xMorF+UT8kawyNx+CYKbrP22C8MTwhv5Nas=
```

#### **Step 2: Enable Offline LLM**

1. Launch the app
2. Go to **Settings** → **On-Device AI**
3. Toggle **Offline LLM** to **ON**
4. Wait for model download (~3.7GB, 5-15 minutes depending on connection)

#### **Step 3: Test Llama (General Conversation)**

Try these queries in the AI chat:
- "Tell me about coffee culture in San Francisco"
- "Help me plan a weekend in New York"
- "What are some good restaurants?"

**Expected:** Responses generated locally (check logs for "Model loaded" messages)

#### **Step 4: Test BERT-SQuAD (Dataset Questions)**

Try these queries (should use BERT-SQuAD):
- "What's the address of Blue Bottle Coffee?"
- "What is my exploration eagerness score?"
- "What spots are in my coffee list?"
- "How many people have respected this spot?"

**Expected:** Precise answers extracted from AVRAI dataset

#### **Step 5: Verify Offline Mode**

1. Disable Wi-Fi/network
2. Try AI chat - should still work (using local models)
3. Verify no network errors

---

### **Option 2: Automated Integration Tests**

#### **Run LLM Service Tests**

```bash
# Unit tests for LLM service
flutter test test/unit/services/llm_service_test.dart

# Integration tests for LLM
flutter test test/integration/ai/
```

#### **Run BERT-SQuAD Tests**

```bash
# BERT-SQuAD backend tests
flutter test test/unit/services/bert_squad/

# Query classifier tests
flutter test test/unit/services/bert_squad/query_classifier_test.dart
```

---

## 🗺️ Testing Maps Functionality

### **Option 1: Manual Testing (Recommended)**

#### **Step 1: Run App**

```bash
cd /Users/reisgordon/AVRAI
flutter run -d macos
```

#### **Step 2: Navigate to Map**

1. Open the app
2. Navigate to **Map** tab/page
3. Verify map loads (should use flutter_map on macOS)

#### **Step 3: Test Map Features**

**Basic Map Operations:**
- [ ] Map loads without errors
- [ ] Pan/zoom works smoothly
- [ ] Map centers on user location (if permission granted)
- [ ] Map type selection works (if available)

**Boundaries:**
- [ ] Spot boundaries render correctly
- [ ] List boundaries display properly
- [ ] Boundary colors match theme

**Markers:**
- [ ] Spot markers appear on map
- [ ] Markers are clickable
- [ ] Marker info windows display correctly

**Geohash Overlays:**
- [ ] Geohash boundaries render (if enabled)
- [ ] Overlays update when zooming

**Lists Integration:**
- [ ] Selecting a list filters map markers
- [ ] List boundaries highlight correctly
- [ ] Switching lists updates map view

---

### **Option 2: Automated Tests**

#### **Run All Maps Tests**

```bash
# Unit tests (22 tests)
flutter test test/unit/models/map_boundary_test.dart
flutter test test/unit/widgets/map/map_boundary_converter_test.dart
flutter test test/unit/widgets/map/map_platform_detection_test.dart

# Widget tests (9 tests)
flutter test test/widget/widgets/map/

# Integration tests (21 tests)
flutter test test/integration/maps/
```

#### **Run Specific Map Test Suites**

```bash
# Boundary rendering tests
flutter test test/integration/maps/map_boundary_rendering_test.dart

# Geohash overlay tests
flutter test test/integration/maps/map_geohash_overlays_test.dart

# Platform selection tests
flutter test test/integration/maps/map_platform_selection_test.dart
```

**Expected:** All 52 maps tests should pass ✅

---

## 🔍 Debugging Tips

### **LLM Debugging**

**Check Model Download:**
```bash
# Check app logs for download progress
# Look for: "Model downloaded successfully" or "Model activation failed"
```

**Check Model Loading:**
```bash
# In app logs, look for:
# - "BERT-SQuAD model loaded" (for BERT)
# - "Model loaded" (for Llama)
# - "Model activation failed" (errors)
```

**Verify Manifest Endpoint:**
```bash
curl https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/local-llm-manifest | python3 -m json.tool
```

**Check Model Files:**
```bash
# BERT-SQuAD (should exist)
ls -lh ~/AVRAI/models/macos/BERTSQUADFP16.mlmodel

# Llama (downloaded by app)
ls -lh ~/Library/Application\ Support/AVRAI/models/
```

### **Maps Debugging**

**Check Platform Detection:**
```bash
# macOS should use flutter_map
# Check logs for: "Using flutter_map on macOS"
```

**Verify Map Widget Loading:**
```bash
# Check logs for map initialization errors
# Look for: "MapView initialized" or "Map load failed"
```

**Test Map Boundaries:**
```bash
# Create a test spot with boundaries
# Verify boundaries render correctly on map
```

---

## 📊 Test Results Summary

### **LLM Tests:**
- ✅ BERT-SQuAD backend: Ready (local file)
- ✅ Llama backend: Ready (Supabase download configured)
- ✅ Query routing: Automatic (BERT for dataset, Llama for general)

### **Maps Tests:**
- ✅ Unit tests: 22/22 passing
- ✅ Widget tests: 9/9 passing
- ✅ Integration tests: 21/21 passing
- ✅ **Total: 52/52 passing (100%)**

---

## 🚀 Quick Test Commands

### **Run Everything:**

```bash
cd /Users/reisgordon/AVRAI

# Run all maps tests
flutter test test/unit/models/map_boundary_test.dart \
  test/unit/widgets/map/ \
  test/integration/maps/

# Run LLM tests
flutter test test/unit/services/llm_service_test.dart \
  test/unit/services/bert_squad/ \
  test/integration/ai/

# Run app with LLM enabled
flutter run -d macos \
  --dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=HULfUDT5xMorF+UT8kawyNx+CYKbrP22C8MTwhv5Nas=
```

---

## ✅ Testing Checklist

### **LLM Integration:**
- [ ] App builds with manifest public key
- [ ] Offline LLM toggle appears in settings
- [ ] Model downloads successfully from Supabase
- [ ] Llama generates responses for general queries
- [ ] BERT-SQuAD answers dataset questions
- [ ] Offline mode works (no network required)
- [ ] Query routing works (BERT vs Llama)

### **Maps Integration:**
- [ ] Map page loads without errors
- [ ] Map renders correctly (flutter_map on macOS)
- [ ] Spot markers appear on map
- [ ] Boundaries render correctly
- [ ] List selection filters map
- [ ] Pan/zoom works smoothly
- [ ] All 52 automated tests pass

---

## 🐛 Common Issues

### **LLM Issues:**

**"Model not found"**
- Check BERT-SQuAD file exists: `~/AVRAI/models/macos/BERTSQUADFP16.mlmodel`
- Check Llama download completed in app logs

**"Manifest endpoint returns empty"**
- Verify all three Supabase secrets are set
- Check manifest endpoint URL is correct

**"Model download fails"**
- Check Supabase Storage bucket permissions
- Verify public URL is accessible
- Check file size matches (3.7GB)

### **Maps Issues:**

**"Map doesn't load"**
- Check platform detection (macOS should use flutter_map)
- Verify map widget is initialized
- Check for network errors (if using online tiles)

**"Boundaries don't render"**
- Verify boundary data is valid
- Check boundary converter tests pass
- Verify map type supports boundaries

---

## 📚 Additional Resources

- **LLM Setup:** `docs/macos_llm_integration/COMPLETE_SETUP_STEPS.md`
- **Maps Tests:** `docs/plans/maps_system_test_suite/IMPLEMENTATION_COMPLETE.md`
- **Integration Tests:** `scripts/README_INTEGRATION_TESTING.md`
