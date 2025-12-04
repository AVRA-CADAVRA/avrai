# User to Expert Journey - Complete Guide

**Date:** November 23, 2025  
**Purpose:** Complete documentation of how users progress from regular user to expert and how features unlock  
**Status:** 📚 Complete Reference

---

## 🎯 **Overview**

The SPOTS app uses an **integrated expertise system** - expertise is not a separate tab, but rather **features unlock throughout the app** as users earn expertise levels. This document explains the complete journey and navigation structure.

---

## 📱 **Navigation Structure**

### **Main Bottom Tab Navigation**

The app has **3 main tabs** at the bottom:

1. **Map Tab** - Map view of spots
2. **Spots Tab** - List view of spots and lists
3. **Explore Tab** - Social/community features with **3 sub-tabs:**
   - **Users** - Browse users and their lists
   - **AI** - AI personality interactions
   - **Events** - Event discovery and hosting

### **Key Point: No Separate "Expertise" Tab**

Expertise is **integrated throughout the app**, not isolated to one tab:
- Expertise pins shown on user profiles
- Expertise progress visible in various contexts
- Unlock indicators appear where features become available
- Expertise dashboard accessible via profile/settings

---

## 🎓 **Expertise Levels & Progression**

### **6 Expertise Levels**

```
Local (🏘️)     → Unlocks event hosting
City (🏙️)      → Expanded event hosting scope
Regional (🗺️)  → Unlocks expert validation
National (🌎)  → Unlocks expert curation
Global (🌍)    → Unlocks community leadership
Universal (✨)  → Highest level
```

### **Requirements for Each Level**

**Current System (Basic):**
- **Local:** 1-2 respected lists OR 10+ thoughtful reviews (unlocks event hosting)
- **City:** 3-5 respected lists OR 25+ thoughtful reviews
- **Regional:** 6-10 respected lists OR 50+ thoughtful reviews
- **National:** 11-20 respected lists OR 100+ thoughtful reviews
- **Global:** 21+ respected lists OR 200+ thoughtful reviews + high community trust (0.8+)

**Future System (Dynamic - Phase 2+):**
- Requirements scale with platform growth
- Category-specific thresholds (popular categories harder)
- Multi-path expertise (visits, credentials, influence, community)
- **Locality-specific thresholds** - Thresholds adapt to what your locality values
  - Activities valued by your locality → Lower threshold (easier to achieve)
  - Activities less valued by your locality → Higher threshold (harder to achieve)
  - Example: If your locality values coffee events highly, coffee expertise threshold is lower

---

## 🚪 **Feature Unlocks by Level**

### **What Unlocks When**

| Level | Unlocked Features |
|-------|-------------------|
| **Local** | ✅ **Event Hosting** - Can create and host events in your locality |
| **City** | Expanded event hosting (can host in all localities in your city) |
| **Regional** | ✅ **Expert Validation** - Can validate spots as expert |
| **National** | ✅ **Expert Curation** - Can curate expert lists |
| **Global** | ✅ **Community Leadership** - Advanced community features |

### **Feature Details**

#### **Local Level: Event Hosting**
- **Unlocks:** Ability to create and host events in your locality
- **Requirements:** Local level+ expertise in category
- **Where:** Event creation form checks expertise before allowing hosting
- **UI:** `EventHostingUnlockWidget` shows unlock status/progress
- **Access:** Explore tab → Events sub-tab → Create Event
- **Note:** City level experts can host events in all localities within their city

#### **Regional Level: Expert Validation**
- **Unlocks:** Can validate spots as an expert
- **Requirements:** Regional level+ expertise in category
- **Where:** Spot detail pages show "Validate as Expert" option
- **Impact:** Expert-validated spots get special badge

#### **National Level: Expert Curation**
- **Unlocks:** Can create expert-curated lists
- **Requirements:** National level+ expertise
- **Where:** List creation allows expert curation option

#### **Global Level: Community Leadership**
- **Unlocks:** Advanced community features, mentorship programs
- **Requirements:** Global level+ expertise
- **Future Features:** Community moderation, expert mentoring

---

## 🔄 **User Journey: From New User to Expert**

### **Stage 1: New User (Local Level)**

**What They Can Do:**
- ✅ Browse spots and lists
- ✅ Discover events (can attend)
- ✅ Create lists
- ✅ Write reviews
- ✅ Build expertise through contributions

**Navigation:**
- **Map Tab** → Browse spots on map
- **Spots Tab** → Browse lists and spots
- **Explore Tab** → Browse users, AI, events
- **Profile** → View settings, basic info

**Where Expertise Shows:**
- Profile shows "No Expertise Yet" or "Local Level" status
- Lists/reviews contribute to expertise
- Progress tracked in background

---

### **Stage 2: Active Contributor (Local → City Progress)**

**What Changes:**
- ✅ Can see expertise progress
- ✅ Unlock indicator shows progress to City level
- ✅ See requirements to unlock event hosting
- ✅ Continue contributing to earn City level

**Navigation:**
- **Profile** → Access Expertise Dashboard (if available)
- **Event Creation** → See unlock widget showing progress
- **Explore Tab → Events** → See "Unlock Event Hosting" indicator

**Key UI Elements:**
- `EventHostingUnlockWidget` - Shows progress to unlock
- `ExpertiseProgressWidget` - Shows contribution breakdown
- `ExpertiseDisplayWidget` - Shows current expertise pins

---

### **Stage 3: Local Level Expert (Event Hosting Unlocked)**

**What Unlocks:**
- ✅ **Event Hosting** - Can create and host events in your locality
- ✅ Event creation form becomes accessible
- ✅ Can host tours, workshops, tastings
- ✅ Can earn revenue from paid events

**Navigation:**
- **Explore Tab → Events** → "Create Event" button now available
- **Profile** → Expertise Dashboard shows City level pins
- **Event Creation Flow:**
  1. Explore Tab → Events sub-tab
  2. Click "Create Event" or "+" button
  3. Fill event creation form
  4. Select category (must match expertise)
  5. Publish event

**Features Available:**
- Create free events
- Create paid events (integrated with payment system)
- Set event capacity
- Choose spots for event route
- Manage event attendees

**Where Expertise Shows:**
- Expertise pins visible on profile
- Expert badge on hosted events
- Expertise level shown to potential attendees

---

### **Stage 4: Regional+ Expert (Advanced Features)**

**What Unlocks:**
- ✅ **Expert Validation** (Regional)
- ✅ **Expert Curation** (National)
- ✅ **Community Leadership** (Global)

**Navigation:**
- **Spot Detail Pages** → "Validate as Expert" option
- **List Creation** → "Expert Curated List" option
- **Community Features** → Advanced moderation/leadership options

---

## 📍 **Where Expertise Appears in the App**

### **1. Profile Page / Settings**
- **Location:** Profile icon → Profile page
- **Current State:** 
  - ⚠️ **Expertise Dashboard link NOT yet added to Profile page**
  - Needs to be added to settings menu
- **Should Show:** 
  - Expertise pins gallery
  - Expertise dashboard link
  - Current expertise levels
  - Progress indicators

### **2. Explore Tab → Events**
- **Location:** Bottom nav → Explore → Events sub-tab
- **Shows:**
  - Event hosting unlock widget
  - Progress to unlock event hosting
  - "Create Event" button (when unlocked)

### **3. Event Creation Flow**
- **Location:** Explore → Events → Create Event
- **Shows:**
  - Expertise verification
  - Category selection (filtered by expertise)
  - Event hosting unlock check

### **4. Expertise Dashboard (Dedicated Page)**
- **Location:** ⚠️ **Currently NOT linked in UI - needs to be added to Profile page**
- **Code Location:** `lib/presentation/pages/expertise/expertise_dashboard_page.dart`
- **Route:** Needs to be added to `app_router.dart`
- **Should Be Accessible Via:** Profile page → Settings → "Expertise Dashboard"
- **Shows:**
  - Complete expertise profile
  - All categories with expertise
  - Progress to next level
  - Unlocked features list
  - Contribution breakdown

### **5. Spot Cards & Lists**
- **Location:** Throughout app (Map, Spots, Lists)
- **Shows:**
  - Expert validation badges (if spot validated)
  - Expertise pins on user profiles
  - Expert-curated list indicators

### **6. User Profiles**
- **Location:** Explore → Users, or any user profile view
- **Shows:**
  - User's expertise pins
  - Expertise levels by category
  - Expert status indicators

---

## 🔓 **How Features Unlock (The "Doors" System)**

Based on **OUR_GUTS.md** philosophy: **"Doors, not badges"**

### **The Unlock System**

**Not Gamified:**
- ❌ No points/XP system
- ❌ No achievement badges
- ❌ No competitive leaderboards

**Authentic Recognition:**
- ✅ Features unlock through real contributions
- ✅ Progress visible but not pressured
- ✅ Recognition from community trust
- ✅ Features serve community, not ego

### **Unlock Indicators**

**Event Hosting Unlock Widget:**
```dart
EventHostingUnlockWidget(
  user: currentUser,
  onUnlockTap: () => navigateToCreateEvent(),
  onProgressTap: () => navigateToExpertiseDashboard(),
)
```

**Shows:**
- ✅ **Unlocked State:** "You can host events! 🎉" with animation
- ⏳ **Locked State:** Progress bar + "X more contributions to unlock"
- 📊 **Progress Details:** Contribution breakdown

### **Feature Access Control**

**Event Hosting:**
```dart
if (user.canHostEvents()) {
  // Show "Create Event" button
} else {
  // Show unlock widget with progress
}
```

**Expert Validation:**
```dart
if (user.canPerformExpertValidation() && 
    user.hasExpertiseIn(spot.category)) {
  // Show "Validate as Expert" button
}
```

---

## 🎯 **Progression Paths**

### **Path 1: Exploration (Visits + Reviews)**
- Create lists of spots
- Write thoughtful reviews
- Visit spots (automatic check-ins)
- Build community trust through quality contributions

### **Path 2: Credentials (Future - Phase 2+)**
- Upload educational credentials
- Professional certifications
- Published work
- Professional experience verification

### **Path 3: Influence (Future - Phase 2+)**
- Social proof from other platforms
- Follower count (with verification)
- Cross-platform expertise

### **Path 4: Community (Future - Phase 2+)**
- Helping other users
- List curation
- Community engagement
- Mentorship activities

---

## 📋 **Documentation References**

### **Core Documentation:**
- **Expertise System:** `docs/plans/dynamic_expertise/EXPERTISE_IMPLEMENTATION_SUMMARY.md`
- **Dynamic Thresholds:** `docs/plans/dynamic_expertise/DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md`
- **Locality Value Analysis:** `docs/plans/expertise_system/LOCALITY_VALUE_ANALYSIS_SYSTEM.md`
- **Dynamic Threshold Calculation:** `docs/plans/expertise_system/DYNAMIC_THRESHOLD_CALCULATION.md`
- **Geographic Hierarchy:** `docs/plans/expertise_system/GEOGRAPHIC_HIERARCHY_SYSTEM.md`
- **Unlock Philosophy:** `OUR_GUTS.md` - "Pins, not badges"

### **Code References:**
- **Expertise Levels:** `lib/core/models/expertise_level.dart`
- **Expertise Service:** `lib/core/services/expertise_service.dart`
- **Unlock Widget:** `lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart`
- **Dashboard:** `lib/presentation/pages/expertise/expertise_dashboard_page.dart`

### **UI Components:**
- **Expertise Display:** `lib/presentation/widgets/expertise/expertise_display_widget.dart`
- **Progress Widget:** `lib/presentation/widgets/expertise/expertise_progress_widget.dart`
- **Pin Widget:** `lib/presentation/widgets/expertise/expertise_pin_widget.dart`

---

## 🔍 **Finding Your Expertise Status**

### **How to Check Your Expertise:**

1. **Via Profile:**
   - Tap profile icon (top-left in Explore tab)
   - Navigate to Profile/Settings
   - Look for "Expertise Dashboard" option

2. **Via Event Creation:**
   - Go to Explore Tab → Events
   - Look for event hosting unlock widget
   - Shows current level and progress

3. **Via Expertise Dashboard (if linked):**
   - Profile → Expertise Dashboard
   - Complete breakdown of all categories
   - Progress to next level for each category

### **Where Expertise Is Visible:**
- ✅ User profiles (yours and others)
- ✅ Spot detail pages (expert validations)
- ✅ Event listings (host expertise shown)
- ✅ List cards (expert-curated lists)
- ✅ Search results (expert indicators)

---

## ❓ **Frequently Asked Questions**

### **Q: Is there a separate "Expert" tab?**
**A:** No. Expertise is integrated throughout the app. Features unlock as you progress, appearing in the relevant sections (Events, Spots, Lists, etc.).

### **Q: How do I access the Expertise Dashboard?**
**A:** Currently accessible via code navigation. Should be added to Profile/Settings menu for easy access.

### **Q: What's the fastest way to become an expert?**
**A:** Create quality lists and write thoughtful reviews in a specific category. Build community trust through authentic contributions.

### **Q: Do I need to grind levels to unlock features?**
**A:** No grinding - expertise comes from authentic contributions. Progress is visible but not pressured. The system recognizes quality, not quantity.

### **Q: Can I see what I need to unlock event hosting?**
**A:** Yes! The `EventHostingUnlockWidget` shows your progress and exactly what you need (e.g., "3 more respected lists" or "12 more thoughtful reviews").

### **Q: What happens when I reach Local level?**
**A:** Event hosting unlocks! You'll see an unlock animation and can immediately start creating events in your locality. The unlock widget changes to show "You can host events!"

### **Q: How do locality-specific thresholds work?**
**A:** Thresholds adapt to what your locality values. If your locality values coffee events highly, the coffee expertise threshold is lower (easier to achieve). If your locality values art galleries less, the art expertise threshold is higher (harder to achieve). This means you can become a local expert based on what your community actually cares about.

### **Q: Do I need city-wide expertise to be a local expert?**
**A:** No! Local experts don't need to expand past their locality to be qualified. You can be an expert in your neighborhood without needing city-wide expertise. Thresholds adapt to what your locality values.

### **Q: What happens when I reach Local level?**
**A:** Event hosting unlocks! You'll see an unlock animation and can immediately start creating events in your locality. The unlock widget changes to show "You can host events!"

### **Q: How do locality-specific thresholds work?**
**A:** Thresholds adapt to what your locality values. If your locality values coffee events highly, the coffee expertise threshold is lower (easier to achieve). If your locality values art galleries less, the art expertise threshold is higher (harder to achieve). This means you can become a local expert based on what your community actually cares about.

### **Q: Do I need city-wide expertise to be a local expert?**
**A:** No! Local experts don't need to expand past their locality to be qualified. You can be an expert in your neighborhood without needing city-wide expertise. Thresholds adapt to what your locality values.

---

## 🎯 **Summary**

**Navigation Structure:**
- **Main Tabs:** Map, Spots, Explore (with Users/AI/Events sub-tabs)
- **No Separate Expertise Tab** - Expertise integrated throughout
- **Expertise Dashboard** - Accessible via profile (needs UI integration)

**User Journey:**
1. **New User** → Start at Local level, can create lists/reviews
2. **Contributor** → Build expertise, see progress to Local expert qualification
3. **Local Expert** → Event hosting unlocks (can host in your locality)
4. **City Expert** → Expanded event hosting (can host in all localities in your city)
5. **Regional+ Expert** → Advanced features unlock

**Feature Unlocks:**
- **Local:** Event hosting (in your locality)
- **City:** Expanded event hosting (all localities in your city)
- **Regional:** Expert validation
- **National:** Expert curation
- **Global:** Community leadership

**Local Expert Qualification:**
- Thresholds adapt to what your locality values
- Activities valued by your locality → Lower threshold (easier)
- Activities less valued by your locality → Higher threshold (harder)
- You can qualify as local expert based on what your community cares about

**Philosophy:**
- "Doors, not badges" - Features unlock through authentic contributions
- No gamification - Recognition, not competition
- Progress visible but not pressured

---

**Last Updated:** November 23, 2025  
**Related Docs:** See "Documentation References" section above

