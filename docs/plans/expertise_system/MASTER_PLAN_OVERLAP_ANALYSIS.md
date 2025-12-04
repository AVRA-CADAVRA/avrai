# Master Plan Overlap Analysis - Local Expert System

**Created:** November 23, 2025  
**Status:** 📋 Analysis Document  
**Purpose:** Identify overlaps between Local Expert System Plan and existing Master Plan features

---

## 🔍 **Overlap Summary**

### **✅ OVERLAP FOUND: Dynamic Expertise System**

**Status:** ⚠️ **SIGNIFICANT OVERLAP** - Requires coordination

**Existing Implementation (Master Plan):**
- **Dynamic Expertise Thresholds Plan** - ✅ **COMPLETE** (Weeks 6-8, 14)
- **Status:** Fully implemented and tested
- **Key Features:**
  - Multi-path expertise calculation (Exploration, Credentials, Influence, Professional, Community)
  - Dynamic thresholds (scaling with platform growth)
  - **Locality-based expertise** (geographic scopes)
  - Professional expertise recognition
  - Saturation algorithm
  - Automatic check-ins

**Local Expert System Plan:**
- **Status:** 📋 Awaiting Approval
- **Key Changes:**
  - **Change event hosting requirement from City level → Local level**
  - Add new geographic hierarchy (Local < City < State < National < Global < Universal)
  - Expand locality system (currently has basic locality, wants full hierarchy)
  - Add community events (non-experts can host)
  - Add clubs/communities system
  - Add Golden expert AI influence
  - Add reputation/matching system
  - Update business-expert matching (vibe-first)

---

## 📊 **Detailed Overlap Analysis**

### **1. Geographic/Locality Expertise**

**Overlap Level:** 🔴 **HIGH OVERLAP** - Requires careful integration

**Dynamic Expertise (Existing):**
- ✅ Has `GeographicScope` model (neighborhood, borough, city, metro, state, region, national)
- ✅ Has `LocalityAnalyzer` service
- ✅ Calculates expertise per location
- ✅ **BUT:** Still uses "City level" as event hosting requirement (line 51 in plan)
- ✅ **BUT:** Geographic scopes exist but hierarchy not fully enforced

**Local Expert System (New):**
- 🔄 Wants to change event hosting from City → Local level
- 🔄 Wants to enforce geographic hierarchy (Local < City < State < National < Global < Universal)
- 🔄 Wants to add "Local Expert" as new level (currently not in hierarchy)
- 🔄 Wants dynamic locality-specific thresholds
- 🔄 Wants soft/hard neighborhood borders

**Integration Required:**
- ✅ Can build on existing `GeographicScope` model
- ✅ Can extend `LocalityAnalyzer` service
- ⚠️ **MUST UPDATE:** Change City level requirement to Local level
- ⚠️ **MUST ADD:** Local level to expertise hierarchy
- ⚠️ **MUST ENFORCE:** Geographic hierarchy in event hosting validation

---

### **2. Expertise Calculation & Thresholds**

**Overlap Level:** 🟡 **MEDIUM OVERLAP** - Extension, not replacement

**Dynamic Expertise (Existing):**
- ✅ Multi-path expertise calculation (5 paths: Exploration, Credentials, Influence, Professional, Community)
- ✅ Dynamic thresholds (scaling with platform phase)
- ✅ Category-specific requirements
- ✅ Saturation algorithm

**Local Expert System (New):**
- 🔄 Wants **locality-specific** thresholds (not just category-specific)
- 🔄 Wants lower thresholds for Local experts (vs City experts)
- 🔄 Wants dynamic thresholds based on locality values (what community cares about)
- 🔄 Wants thresholds that "ebb and flow" based on user behavior

**Integration Required:**
- ✅ Can extend existing `ExpertiseCalculationService`
- ✅ Can extend existing `DynamicExpertiseThresholds`
- ⚠️ **MUST ADD:** Locality-specific threshold calculation
- ⚠️ **MUST ADD:** Local expert threshold logic (lower than City)

---

### **3. Business-Expert Matching**

**Overlap Level:** 🟡 **MEDIUM OVERLAP** - Enhancement, not replacement

**Existing (Master Plan):**
- ✅ `BusinessExpertMatchingService` exists
- ✅ `PartnershipMatchingService` has vibe matching (70%+ compatibility)
- ✅ Brand Sponsorship uses vibe matching
- ⚠️ **BUT:** Business-Expert Matching may not fully integrate vibe matching yet
- ⚠️ **BUT:** May filter by `minExpertLevel` (could exclude local experts)

**Local Expert System (New):**
- 🔄 Wants vibe-first matching (50% weight for vibe, 30% expertise, 20% location)
- 🔄 Wants to remove level-based filtering (include local experts)
- 🔄 Wants location as preference boost, not filter
- 🔄 Wants AI prompts to emphasize vibe over level

**Integration Required:**
- ✅ Can integrate existing `PartnershipMatchingService` vibe calculation
- ⚠️ **MUST UPDATE:** Remove level-based filtering from `BusinessExpertMatchingService`
- ⚠️ **MUST ADD:** Vibe-first scoring algorithm
- ⚠️ **MUST UPDATE:** AI prompts to emphasize vibe

---

### **4. Event Hosting Requirements**

**Overlap Level:** 🔴 **HIGH OVERLAP** - Direct conflict

**Dynamic Expertise (Existing):**
- ✅ Uses "City level" as event hosting requirement
- ✅ `UnifiedUser.canHostEvents()` checks `level.index >= ExpertiseLevel.city.index`
- ✅ `ExpertisePin.unlocksEventHosting()` checks City level
- ✅ Multiple services check for City level

**Local Expert System (New):**
- 🔄 Wants to change event hosting requirement to **Local level**
- 🔄 Wants Local experts to be able to host events
- 🔄 Wants geographic scope enforcement (local experts in locality only)

**Integration Required:**
- ⚠️ **MUST UPDATE:** All City level checks → Local level
- ⚠️ **MUST UPDATE:** All services, models, UI components
- ⚠️ **MUST UPDATE:** All tests (134 "City level" references in 28 test files)
- ⚠️ **MUST UPDATE:** All documentation
- ⚠️ **MUST ADD:** Geographic scope validation (local experts can only host in their locality)

---

### **5. New Features (No Overlap)**

**Local Expert System (New - No Overlap):**
- ✅ **Community Events** - Non-experts can host public events (completely new)
- ✅ **Clubs/Communities** - Events can become communities → clubs (completely new)
- ✅ **Expertise Expansion** - 75% coverage rule for geographic expansion (completely new)
- ✅ **Golden Expert AI Influence** - Weighted influence on neighborhood character (completely new)
- ✅ **Reputation/Matching System** - Locality-specific matching signals (completely new)
- ✅ **Neighborhood Boundaries** - Soft/hard borders, dynamic refinement (completely new)

**These are completely new features with no overlap.**

---

## 🎯 **Integration Strategy**

### **Phase 0: Update Existing System (CRITICAL)**

**This phase is MANDATORY and addresses the overlap:**

1. **Update Dynamic Expertise System:**
   - Change City level → Local level for event hosting
   - Add Local level to expertise hierarchy
   - Update all services, models, UI, tests, documentation

2. **Extend Geographic System:**
   - Build on existing `GeographicScope` model
   - Extend `LocalityAnalyzer` service
   - Add hierarchy enforcement

3. **Update Business-Expert Matching:**
   - Integrate vibe matching (use existing `PartnershipMatchingService`)
   - Remove level-based filtering
   - Add vibe-first scoring

**Timeline:** 1.5 weeks (Phase 0 in Local Expert System Plan)

---

### **Phase 1+: New Features (No Overlap)**

**These phases add completely new features:**

- Phase 1: Core Local Expert System (geographic hierarchy enforcement)
- Phase 1.5: Business-Expert Matching Updates (vibe-first)
- Phase 2: Event Discovery & Matching (reputation system)
- Phase 3: Community Events & Clubs (new feature)
- Phase 4: UI/UX & Golden Expert (new feature)
- Phase 5: Neighborhood Boundaries (new feature)

**Timeline:** 8-12 weeks (Phases 1-5 in Local Expert System Plan)

---

## ⚠️ **Critical Dependencies**

### **MUST Complete Before New Features:**

1. **Phase 0 Updates (1.5 weeks):**
   - ✅ Update all City level → Local level references
   - ✅ Update all services, models, UI, tests
   - ✅ Update documentation
   - ✅ Extend geographic system
   - ✅ Update business-expert matching

2. **Then Proceed with New Features:**
   - Phase 1: Core Local Expert System
   - Phase 1.5: Business-Expert Matching (vibe-first)
   - Phase 2-5: New features

---

## 📋 **Recommendations**

### **1. Integration Approach:**
- ✅ **Build on existing Dynamic Expertise System** (don't replace)
- ✅ **Extend geographic scopes** (don't recreate)
- ✅ **Update event hosting requirement** (City → Local)
- ✅ **Integrate vibe matching** (use existing service)

### **2. Master Plan Integration:**
- ✅ **Add Local Expert System Plan to Master Plan** (after Phase 0 updates)
- ✅ **Mark Dynamic Expertise as "Extended"** (not replaced)
- ✅ **Coordinate Phase 0 with existing Dynamic Expertise** (ensure compatibility)

### **3. Risk Mitigation:**
- ⚠️ **Phase 0 is CRITICAL** - Must update existing system correctly
- ⚠️ **Test coverage** - 134 "City level" references need updating
- ⚠️ **Backward compatibility** - Existing users with City level expertise
- ⚠️ **Documentation** - All expertise docs need updating

---

## ✅ **Conclusion**

**Overlap Status:** ⚠️ **SIGNIFICANT OVERLAP** with Dynamic Expertise System

**Key Findings:**
1. ✅ Dynamic Expertise System is complete and working
2. ⚠️ Local Expert System wants to **extend and update** it (not replace)
3. ⚠️ **Phase 0 is CRITICAL** - Must update existing system first
4. ✅ New features (Phases 1-5) have no overlap

**Recommendation:**
- ✅ **Proceed with Local Expert System Plan**
- ✅ **Complete Phase 0 first** (update existing system)
- ✅ **Then proceed with new features** (Phases 1-5)
- ✅ **Coordinate with Dynamic Expertise** (ensure compatibility)

**Master Plan Integration:**
- ✅ Add Local Expert System Plan to Master Plan
- ✅ Mark as "Extends Dynamic Expertise System"
- ✅ Place after Phase 0 updates complete

---

**Last Updated:** November 23, 2025  
**Status:** Ready for Master Plan integration

