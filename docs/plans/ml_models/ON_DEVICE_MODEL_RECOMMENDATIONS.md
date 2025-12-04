# On-Device ML Model Recommendations for SPOTS

**Date:** January 2025  
**Purpose:** Hybrid on-device/cloud AI architecture for offline-first recommendations and matching  
**Status:** Research & Recommendations

---

## 🎯 **SPOTS USE CASES REQUIRING MODELS**

Based on current features and activity:

1. **Spot Recommendations** - Location-based, personalized spot suggestions
2. **User Matching** - Personality-based compatibility matching (AI2AI)
3. **List Recommendations** - Suggest relevant lists based on user interests
4. **Personality Prediction** - Predict user behavior and next actions
5. **Preference Learning** - Learn and adapt to user preferences over time
6. **Social Discovery** - Match users with similar interests/locations
7. **Event Recommendations** - Suggest events based on personality and location

---

## 📦 **RECOMMENDED MODEL SOURCES**

### **1. Hugging Face ONNX Models**
**URL:** https://huggingface.co/models?library=onnx

**Why:**
- Largest collection of pre-trained ONNX models
- Easy to download and integrate
- Many models optimized for mobile
- Active community and documentation

**Key Models to Explore:**
- Search: "recommendation", "embedding", "sentence-transformers", "collaborative-filtering"

### **2. ONNX Model Zoo**
**URL:** https://github.com/onnx/models

**Why:**
- Official ONNX model repository
- Production-ready models
- Well-documented
- Optimized for ONNX Runtime

**Categories:**
- Vision, NLP, Speech, Recommendation Systems

### **3. Sentence Transformers (ONNX)**
**URL:** https://www.sbert.net/docs/sentence_transformer/onnx.html

**Why:**
- Lightweight embedding models
- Perfect for semantic matching
- Mobile-optimized versions available
- Great for personality/spot matching

### **4. TensorFlow Lite Model Hub**
**URL:** https://www.tensorflow.org/lite/models

**Why:**
- Mobile-first models
- Optimized for Android/iOS
- Can convert to ONNX if needed
- Pre-trained recommendation models

---

## 🤖 **SPECIFIC MODEL RECOMMENDATIONS**

### **A. Embedding Models (For Matching & Similarity)**

#### **1. all-MiniLM-L6-v2 (ONNX)**
- **Size:** ~23MB
- **Use Case:** Text/description embeddings for spot matching
- **Why:** Lightweight, fast, good quality
- **Source:** Hugging Face (`sentence-transformers/all-MiniLM-L6-v2`)
- **Key Aspect:** Semantic similarity for spots, lists, user descriptions

#### **2. all-mpnet-base-v2 (ONNX)**
- **Size:** ~420MB (larger but better quality)
- **Use Case:** High-quality embeddings when device allows
- **Why:** Better accuracy, still mobile-friendly
- **Source:** Hugging Face (`sentence-transformers/all-mpnet-base-v2`)
- **Key Aspect:** Use for cloud fallback or high-end devices

#### **3. MobileBERT (ONNX)**
- **Size:** ~25MB
- **Use Case:** Mobile-optimized BERT for text understanding
- **Why:** Designed specifically for mobile devices
- **Source:** Hugging Face (`google/mobilebert-uncased`)
- **Key Aspect:** Understanding user queries and spot descriptions

### **B. Recommendation Models**

#### **4. Neural Collaborative Filtering (NCF)**
- **Size:** ~5-50MB (depends on user/item count)
- **Use Case:** Spot recommendations based on user interactions
- **Why:** Industry-standard for recommendations
- **Source:** Custom training or ONNX conversion from PyTorch
- **Key Aspect:** Collaborative filtering for spot recommendations
- **Training Data Needed:** User-spot interaction history

#### **5. Matrix Factorization (LightFM)**
- **Size:** ~10-30MB
- **Use Case:** Hybrid recommendations (content + collaborative)
- **Why:** Handles cold-start problem (new users/spots)
- **Source:** Convert from LightFM library to ONNX
- **Key Aspect:** Works with sparse data, good for new users

#### **6. Wide & Deep Model (ONNX)**
- **Size:** ~20-100MB
- **Use Case:** Complex recommendation with multiple features
- **Why:** Combines memorization (wide) and generalization (deep)
- **Source:** TensorFlow Model Garden → ONNX conversion
- **Key Aspect:** Handles location, time, personality, preferences together

### **C. Personality & Behavior Prediction**

#### **7. Lightweight LSTM/GRU (ONNX)**
- **Size:** ~5-20MB
- **Use Case:** Sequence prediction (next action, behavior patterns)
- **Why:** Good for time-series prediction
- **Source:** Custom training or ONNX conversion
- **Key Aspect:** Predict user's next action based on history
- **Training Data Needed:** User action sequences

#### **8. Multi-Layer Perceptron (MLP) for Classification**
- **Size:** ~1-10MB
- **Use Case:** Personality dimension prediction, preference classification
- **Why:** Simple, fast, works well for structured data
- **Source:** Custom training (you already have script)
- **Key Aspect:** Predict personality dimensions from behavior

### **D. Location-Based Models**

#### **9. Geospatial Embedding Model**
- **Size:** ~10-30MB
- **Use Case:** Location similarity, geographic clustering
- **Why:** Understands spatial relationships
- **Source:** Custom training on location data
- **Key Aspect:** Match users/spots by geographic patterns

---

## 🔑 **KEY ASPECTS MODELS MUST HAVE**

### **1. Size Constraints**
- **Primary Model:** <50MB (for fast loading)
- **Secondary Models:** <100MB each
- **Total On-Device:** <200MB recommended
- **Why:** Fast app startup, reasonable download size

### **2. Inference Speed**
- **Target:** <100ms per inference on mid-range devices
- **Critical Path:** <50ms (recommendations, matching)
- **Why:** Real-time user experience, no lag

### **3. Accuracy Requirements**
- **Recommendations:** >70% relevance (user accepts recommendation)
- **Matching:** >75% compatibility score accuracy
- **Predictions:** >65% next-action accuracy
- **Why:** Good enough to be useful, perfect is not required

### **4. Offline Capability**
- **Must Work:** Without internet connection
- **Data Requirements:** Use cached user data, local spot database
- **Fallback:** Graceful degradation when data insufficient
- **Why:** Core SPOTS philosophy - offline-first

### **5. Privacy & Security**
- **On-Device Processing:** Sensitive data never leaves device
- **No Personal Data:** Models work with anonymized features
- **Local Learning:** Adapt to user without sharing data
- **Why:** SPOTS privacy principles

### **6. Hybrid Architecture Support**
- **On-Device:** Fast, offline, privacy-preserving
- **Cloud Fallback:** Complex queries, latest data, advanced features
- **Seamless Switching:** User doesn't notice difference
- **Why:** Best of both worlds

### **7. Model Update Mechanism**
- **Federated Learning:** Update from user interactions
- **Incremental Updates:** Small model deltas, not full retrain
- **Version Control:** Rollback if new model performs worse
- **Why:** Continuous improvement without breaking changes

---

## 🏗️ **RECOMMENDED MODEL ARCHITECTURE**

### **Primary On-Device Models (Offline)**

1. **Embedding Model** (all-MiniLM-L6-v2 ONNX)
   - Purpose: Text/description embeddings
   - Size: ~23MB
   - Use: Spot matching, list matching, user similarity

2. **Recommendation Model** (Custom NCF or LightFM → ONNX)
   - Purpose: Spot recommendations
   - Size: ~20-50MB
   - Use: Personalized spot suggestions
   - Training: User-spot interaction data

3. **Personality Prediction Model** (Custom MLP → ONNX)
   - Purpose: Predict personality dimensions from behavior
   - Size: ~5-10MB
   - Use: Personality learning, behavior prediction
   - Training: User behavior → personality dimension mapping

4. **Sequence Prediction Model** (LSTM/GRU → ONNX)
   - Purpose: Predict next actions
   - Size: ~10-20MB
   - Use: "What will user do next?" predictions
   - Training: User action sequences

### **Cloud Models (Online Fallback)**

1. **Advanced Embedding Model** (all-mpnet-base-v2)
   - Purpose: Higher quality embeddings when online
   - Use: Complex queries, better matching

2. **Large Language Model** (OpenAI/Gemini/Anthropic)
   - Purpose: Natural language understanding, complex reasoning
   - Use: User queries, list generation, explanations

3. **Global Recommendation Model**
   - Purpose: Federated learning aggregated model
   - Use: Better recommendations using network-wide patterns

---

## 📊 **MODEL SELECTION MATRIX**

| Use Case | On-Device Model | Cloud Fallback | Priority |
|----------|----------------|----------------|----------|
| Spot Recommendations | NCF/LightFM (20-50MB) | Global NCF + LLM | **HIGH** |
| User Matching | all-MiniLM embeddings (23MB) | all-mpnet-base-v2 | **HIGH** |
| Personality Prediction | Custom MLP (5-10MB) | LLM analysis | **MEDIUM** |
| Next Action Prediction | LSTM/GRU (10-20MB) | LLM + Analytics | **MEDIUM** |
| List Recommendations | Embedding similarity (23MB) | LLM generation | **LOW** |
| Text Understanding | MobileBERT (25MB) | Full LLM | **LOW** |

---

## 🚀 **IMPLEMENTATION PRIORITY**

### **Phase 1: Core Recommendations (MVP)**
1. **Embedding Model** (all-MiniLM-L6-v2 ONNX)
   - Download from Hugging Face
   - Integrate with spot matching
   - Test offline functionality

2. **Simple Recommendation Model** (Matrix Factorization)
   - Train on user-spot interactions
   - Convert to ONNX
   - Deploy on-device

### **Phase 2: Enhanced Matching**
3. **Personality Prediction Model**
   - Train MLP on behavior → personality data
   - Convert to ONNX
   - Use for AI2AI matching

### **Phase 3: Advanced Features**
4. **Sequence Prediction Model**
   - Train LSTM on action sequences
   - Convert to ONNX
   - Predict next actions

5. **Cloud LLM Integration**
   - Set up OpenAI/Gemini API
   - Implement hybrid fallback
   - Test seamless switching

---

## 📚 **TRAINING DATA REQUIREMENTS**

### **For Recommendation Model:**
- User-spot interactions (visits, respects, lists)
- User preferences (categories, locations)
- Spot features (category, location, tags)
- **Minimum:** 10,000 interactions, 1,000 users, 500 spots

### **For Personality Prediction:**
- User behavior sequences
- Personality dimension labels (from PersonalityLearning)
- **Minimum:** 5,000 users with personality profiles

### **For Sequence Prediction:**
- User action sequences (time-ordered)
- Action types and contexts
- **Minimum:** 10,000 sequences, 1,000 users

---

## 🔧 **MODEL OPTIMIZATION TECHNIQUES**

### **1. Quantization**
- Convert FP32 → INT8
- **Benefit:** 4x smaller, 2-4x faster
- **Trade-off:** Slight accuracy loss (<5%)

### **2. Pruning**
- Remove unimportant neurons
- **Benefit:** Smaller model, faster inference
- **Trade-off:** Need retraining

### **3. Knowledge Distillation**
- Train small model from large model
- **Benefit:** Small size, good accuracy
- **Trade-off:** Requires large teacher model

### **4. Model Compression**
- ONNX Runtime optimizations
- **Benefit:** Faster inference
- **Trade-off:** None (post-processing)

---

## 🎯 **SUCCESS METRICS**

### **Model Performance:**
- **Inference Time:** <100ms (95th percentile)
- **Model Size:** <200MB total
- **Accuracy:** >70% recommendation acceptance
- **Offline Uptime:** >95% (works without internet)

### **User Experience:**
- **Response Time:** <500ms end-to-end
- **Battery Impact:** <5% additional drain
- **App Size Increase:** <300MB total
- **User Satisfaction:** >80% find recommendations useful

---

## 📖 **RESOURCES & NEXT STEPS**

### **Immediate Actions:**
1. **Download all-MiniLM-L6-v2 ONNX** from Hugging Face
2. **Test embedding model** with spot descriptions
3. **Collect training data** for recommendation model
4. **Set up model training pipeline** (PyTorch → ONNX)

### **Research Further:**
- Hugging Face ONNX models: https://huggingface.co/models?library=onnx
- ONNX Model Zoo: https://github.com/onnx/models
- Sentence Transformers: https://www.sbert.net/
- ONNX Runtime optimization: https://onnxruntime.ai/docs/

### **Tools Needed:**
- **Model Conversion:** `torch.onnx.export()` or `onnx` Python package
- **Model Optimization:** ONNX Runtime optimization tools
- **Testing:** ONNX Runtime inference testing
- **Deployment:** Flutter ONNX Runtime plugin (already have)

---

## 💡 **KEY INSIGHTS**

1. **Start Simple:** Begin with embedding model (all-MiniLM) - it's ready to use
2. **Train Custom:** Recommendation models need your data - plan for training pipeline
3. **Hybrid is Key:** On-device for speed/privacy, cloud for complexity
4. **Size Matters:** Keep models <50MB each for good UX
5. **Offline First:** All models must work without internet
6. **Iterate:** Start with one model, add more as needed

---

**Last Updated:** January 2025  
**Status:** Ready for Implementation Planning

