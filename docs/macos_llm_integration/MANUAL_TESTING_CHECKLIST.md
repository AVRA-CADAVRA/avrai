# Manual Testing Checklist - LLM & Maps

**Use this checklist while testing the app. I'll monitor logs in real-time.**

---

## 🧪 LLM Testing

### **Step 1: Enable Offline LLM**

1. **Launch the app** (should be running now)
2. **Navigate to Settings:**
   - Look for "Settings" or gear icon
   - Find "On-Device AI" or "Offline LLM" section
3. **Toggle ON:**
   - Enable "Offline LLM" toggle
   - **Watch logs for:**
     - "Model download started"
     - "Downloading from Supabase"
     - Progress updates

**Expected Log Messages:**
```
✅ Model download started
📥 Downloading from: https://nfzlwgbvezwwrutqpedy.supabase.co/...
📊 Download progress: X%
✅ Model downloaded successfully
✅ Model activated
```

**If you see errors:**
- "Model not found in manifest" → Check Supabase secrets
- "Download failed" → Check network connection
- "SHA-256 mismatch" → Model file corrupted

---

### **Step 2: Test Llama (General Conversation)**

1. **Open AI Chat** (wherever chat interface is)
2. **Try these queries:**
   - "Tell me about coffee culture in San Francisco"
   - "Help me plan a weekend in New York"
   - "What are some good restaurants?"

**Watch logs for:**
```
✅ Model loaded
🧠 Generating response with Llama
📝 Response generated
```

**Expected:**
- Responses generated locally (no network required)
- Responses are coherent and relevant
- No errors in logs

---

### **Step 3: Test BERT-SQuAD (Dataset Questions)**

1. **Try dataset-specific queries:**
   - "What's the address of Blue Bottle Coffee?"
   - "What is my exploration eagerness score?"
   - "What spots are in my coffee list?"
   - "How many people have respected this spot?"

**Watch logs for:**
```
✅ BERT-SQuAD model loaded
🔍 Query classified as dataset question
📊 Building AVRAI context
✅ Answer extracted from context
```

**Expected:**
- Precise answers from your AVRAI data
- Faster responses (BERT is smaller)
- Answers match your actual data

---

### **Step 4: Test Offline Mode**

1. **Disable Wi-Fi/Network** (or turn on airplane mode)
2. **Try AI chat again:**
   - Should still work with local models
   - No network errors

**Watch logs for:**
```
⚠️ Network unavailable
✅ Using local LLM backend
🧠 Generating response (offline)
```

**Expected:**
- Chat works without network
- No "network error" messages
- Responses still generated

---

## 🗺️ Maps Testing

### **Step 1: Navigate to Map**

1. **Open Map tab/page**
2. **Watch logs for:**
   ```
   ✅ MapView initialized
   🗺️ Using flutter_map on macOS
   📍 Map centered on location
   ```

**Expected:**
- Map loads without errors
- Map renders correctly
- No crashes

---

### **Step 2: Test Map Features**

**Basic Operations:**
- [ ] Pan map (drag)
- [ ] Zoom in/out (pinch or scroll)
- [ ] Map responds smoothly

**Markers:**
- [ ] Spot markers appear on map
- [ ] Click marker → Info window opens
- [ ] Info displays correctly

**Boundaries:**
- [ ] Spot boundaries render (if available)
- [ ] List boundaries display (if available)
- [ ] Boundaries match theme colors

**List Filtering:**
- [ ] Select a list → Map filters markers
- [ ] Switch lists → Map updates
- [ ] Clear selection → All markers show

**Watch logs for:**
```
✅ Map markers loaded: X spots
✅ Boundaries rendered
✅ List filter applied
```

---

### **Step 3: Test Map Integration**

**With Spots:**
- [ ] Create/view a spot → Appears on map
- [ ] Edit spot location → Map updates
- [ ] Delete spot → Removed from map

**With Lists:**
- [ ] Create list → Can filter map by it
- [ ] Add spots to list → Map updates
- [ ] Remove spots → Map updates

---

## 🐛 What to Report

**If you see errors, note:**
1. **What you were doing** (e.g., "Trying to enable Offline LLM")
2. **Error message** (from logs or screen)
3. **When it happened** (immediately, after X seconds, etc.)

**Common Issues to Watch For:**

**LLM:**
- Model download fails
- Model doesn't load after download
- Chat doesn't work offline
- BERT-SQuAD doesn't answer dataset questions
- Responses are slow or hang

**Maps:**
- Map doesn't load
- Markers don't appear
- Boundaries don't render
- List filtering doesn't work
- Map crashes or freezes

---

## 📊 Success Criteria

**LLM:**
- ✅ Model downloads successfully (~3.7GB)
- ✅ Llama generates responses for general queries
- ✅ BERT-SQuAD answers dataset questions
- ✅ Works offline (no network required)

**Maps:**
- ✅ Map loads and renders
- ✅ Markers appear correctly
- ✅ Boundaries display (if data available)
- ✅ List filtering works
- ✅ Pan/zoom is smooth

---

## 🚀 Ready to Start

**The app should be launching now. I'm monitoring logs in real-time.**

**Tell me:**
1. When the app opens
2. What you're testing
3. Any issues you encounter

**I'll watch the logs and help debug any problems!**
