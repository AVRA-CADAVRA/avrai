# Partnership Profile Visibility & Expertise Boost Plan

**Created:** November 23, 2025  
**Status:** 🎯 Ready for Implementation  
**Priority:** P1 HIGH VALUE  
**Philosophy Alignment:** "Doors, not badges" - Partnerships open doors to collaboration and expertise recognition

---

## 🎯 **Overview**

This plan enables users to showcase their partnerships (brand, company, business) on their profiles, and integrates partnerships into the expertise calculation system to boost expertise based on successful partnerships.

**What Doors Does This Open?**
- **Visibility:** Users can showcase their professional collaborations and partnerships
- **Recognition:** Successful partnerships boost expertise, recognizing collaborative contributions
- **Discovery:** Other users can see who partners with whom, opening doors to new connections
- **Credibility:** Partnership visibility builds trust and demonstrates real-world collaboration

**When Are Users Ready?**
- After they've completed partnerships (active or completed status)
- After partnership systems are live and functioning
- Users can opt-in to display partnerships on their profiles

**Is This Being a Good Key?**
- Yes - Shows authentic professional relationships, not gamification
- Recognizes real collaborations and successful partnerships
- Helps users discover potential partners through profile visibility

**Is the AI Learning?**
- AI can learn which partnerships lead to expertise growth
- Can identify successful partnership patterns
- Can suggest partnerships based on profile compatibility

---

## 📋 **Requirements**

### **1. Profile Partnership Visibility**

**Display Partnerships on User Profiles:**
- Show all active partnerships (Event, Brand, Company)
- Display completed partnerships (optional, user-controlled)
- Show partnership types (Business, Brand, Company)
- Display partner names/logos
- Show partnership date range (start/end)
- Link to partnership details/events

**Partnership Types to Display:**
1. **Business Partnerships** (`EventPartnership` - User + Business)
2. **Brand Partnerships** (Sponsorship partnerships with brands)
3. **Company Partnerships** (Corporate sponsorships/partnerships)

**Visibility Controls:**
- User can control which partnerships to display
- Privacy settings for partnership visibility
- Option to show all, active only, or none

### **2. Expertise Boost from Partnerships**

**How Partnerships Boost Expertise:**
- Active partnerships contribute to expertise calculation
- Completed partnerships (successful) provide expertise boost
- Partnership quality matters (vibe compatibility, success rate)
- Category alignment (partnerships in same category as expertise)

**Expertise Boost Factors:**
1. **Partnership Status:**
   - Active partnerships: +0.05 per active partnership (max +0.15)
   - Completed successful: +0.10 per completed partnership (max +0.30)
   - Ongoing partnerships: +0.08 per ongoing partnership (max +0.24)

2. **Partnership Quality:**
   - High vibe compatibility (80%+): +0.02 bonus
   - Successful revenue share: +0.03 bonus
   - Positive partnership feedback: +0.02 bonus

3. **Category Alignment:**
   - Partnerships in same category as expertise: Full boost
   - Related categories: 50% boost
   - Unrelated categories: 25% boost

4. **Partnership Count:**
   - 1-2 partnerships: Base boost
   - 3-5 partnerships: 1.2x multiplier
   - 6+ partnerships: 1.5x multiplier

**Expertise Path Integration:**
- Partnerships boost **Community Path** expertise (most aligned)
- Also boost **Professional Path** (business relationships)
- Minor boost to **Influence Path** (social proof)

---

## 🔧 **Implementation**

### **Phase 1: Service Layer (Backend)**

#### **1.1: Partnership Profile Service**
**File:** `lib/core/services/partnership_profile_service.dart`

**Methods:**
- `getUserPartnerships(String userId)` - Get all partnerships for user
- `getActivePartnerships(String userId)` - Get active partnerships only
- `getCompletedPartnerships(String userId)` - Get completed partnerships
- `getPartnershipsByType(String userId, PartnershipType type)` - Filter by type
- `getPartnershipExpertiseBoost(String userId, String category)` - Calculate expertise boost

**Partnership Types:**
```dart
enum ProfilePartnershipType {
  business,  // EventPartnership with BusinessAccount
  brand,     // Brand sponsorship partnerships
  company,   // Corporate partnerships
}

class UserPartnership {
  final String id;
  final ProfilePartnershipType type;
  final String partnerId; // Business ID, Brand ID, or Company ID
  final String partnerName;
  final String? partnerLogoUrl;
  final PartnershipStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category; // Category if applicable
  final double? vibeCompatibility;
  final int eventCount; // Number of events in partnership
  final bool isPublic; // User visibility setting
}
```

#### **1.2: Expertise Calculation Integration**
**File:** `lib/core/services/expertise_calculation_service.dart` (update existing)

**Add Partnership Boost:**
- Integrate partnership boost into `calculateExpertise()` method
- Add partnership boost to Community Path calculation
- Add partnership boost to Professional Path calculation
- Add partnership boost to total score calculation

**New Method:**
```dart
Future<PartnershipExpertiseBoost> calculatePartnershipBoost({
  required String userId,
  required String category,
}) async {
  // Get all active and completed partnerships
  // Calculate boost based on:
  // - Partnership status
  // - Quality (vibe compatibility, success)
  // - Category alignment
  // - Partnership count
  // Return boost amount (0.0 to 0.50 max)
}
```

### **Phase 2: UI Components**

#### **2.1: Partnership Display Widget**
**File:** `lib/presentation/widgets/profile/partnership_display_widget.dart`

**Features:**
- Display list of partnerships (active + completed)
- Show partnership cards with partner logo/name
- Filter by partnership type
- Toggle visibility controls
- Link to partnership details

**UI Components:**
- `PartnershipCard` - Individual partnership card
- `PartnershipListWidget` - List of partnerships
- `PartnershipVisibilityToggle` - Privacy controls

#### **2.2: Profile Page Integration**
**File:** `lib/presentation/pages/profile/profile_page.dart` (update existing)

**Add Partnership Section:**
- Add partnerships section below user info card
- Show active partnerships prominently
- Show expertise boost indicator (if partnerships contribute)
- Link to full partnerships view

**Layout:**
```
Profile Page:
├─ User Info Card
├─ Expertise Pins (existing)
├─ Partnerships Section (NEW)
│  ├─ Active Partnerships (3 max preview)
│  ├─ "View All Partnerships" link
│  └─ Expertise Boost Indicator
└─ Settings Section
```

#### **2.3: Partnerships Detail Page**
**File:** `lib/presentation/pages/profile/partnerships_page.dart`

**Features:**
- Full list of all partnerships
- Filter by type (Business, Brand, Company)
- Filter by status (Active, Completed, All)
- Partnership detail cards
- Expertise boost breakdown
- Visibility/privacy controls

### **Phase 3: Expertise Boost UI**

#### **3.1: Expertise Boost Indicator**
**File:** `lib/presentation/widgets/expertise/partnership_expertise_boost_widget.dart`

**Display:**
- Show partnership contribution to expertise
- Visual indicator (e.g., "+X% from partnerships")
- Breakdown of partnership boost by category
- Link to partnerships page

#### **3.2: Expertise Dashboard Integration**
**File:** `lib/presentation/pages/expertise/expertise_dashboard_page.dart` (update existing)

**Add:**
- Partnership boost section
- Show how partnerships contribute to expertise
- Partnership breakdown by category
- Partnership quality metrics

---

## 📊 **Expertise Boost Calculation Details**

### **Formula:**

```dart
double calculatePartnershipBoost({
  required List<UserPartnership> partnerships,
  required String category,
}) {
  double totalBoost = 0.0;
  
  for (final partnership in partnerships) {
    // Status boost
    double statusBoost = 0.0;
    if (partnership.status == PartnershipStatus.active) {
      statusBoost = 0.05;
    } else if (partnership.status == PartnershipStatus.completed && 
               partnership.wasSuccessful) {
      statusBoost = 0.10;
    } else if (partnership.status == PartnershipStatus.ongoing) {
      statusBoost = 0.08;
    }
    
    // Quality boost
    double qualityBoost = 0.0;
    if (partnership.vibeCompatibility != null && 
        partnership.vibeCompatibility! >= 0.8) {
      qualityBoost += 0.02;
    }
    if (partnership.hasSuccessfulRevenue) {
      qualityBoost += 0.03;
    }
    if (partnership.averageFeedback >= 4.0) {
      qualityBoost += 0.02;
    }
    
    // Category alignment
    double alignmentMultiplier = 1.0;
    if (partnership.category == category) {
      alignmentMultiplier = 1.0; // Full boost
    } else if (_isRelatedCategory(partnership.category, category)) {
      alignmentMultiplier = 0.5; // 50% boost
    } else {
      alignmentMultiplier = 0.25; // 25% boost
    }
    
    double partnershipBoost = (statusBoost + qualityBoost) * alignmentMultiplier;
    totalBoost += partnershipBoost;
  }
  
  // Apply count multiplier
  int partnershipCount = partnerships.length;
  double countMultiplier = 1.0;
  if (partnershipCount >= 6) {
    countMultiplier = 1.5;
  } else if (partnershipCount >= 3) {
    countMultiplier = 1.2;
  }
  
  totalBoost *= countMultiplier;
  
  // Cap at 0.50 (50% max boost)
  return totalBoost.clamp(0.0, 0.50);
}
```

### **Integration into Expertise Calculation:**

The partnership boost is added to:
1. **Community Path Score** (primary): 60% of partnership boost
2. **Professional Path Score** (secondary): 30% of partnership boost
3. **Influence Path Score** (minor): 10% of partnership boost

---

## 🎨 **UI/UX Design**

### **Partnership Card Design:**

```
┌─────────────────────────────────────┐
│ [Partner Logo]  Partner Name        │
│                                     │
│ Type: Business Partnership          │
│ Status: Active • Started: Jan 2024  │
│ Events: 3 successful                │
│                                     │
│ [View Details] [Hide]               │
└─────────────────────────────────────┘
```

### **Profile Page Partnership Section:**

```
┌─────────────────────────────────────┐
│ Partnerships                        │
│                                     │
│ ┌────────┐ ┌────────┐ ┌────────┐   │
│ │Part. 1 │ │Part. 2 │ │Part. 3 │   │
│ └────────┘ └────────┘ └────────┘   │
│                                     │
│ +2 active partnerships              │
│ +15% expertise boost from           │
│   partnerships                      │
│                                     │
│ [View All Partnerships →]           │
└─────────────────────────────────────┘
```

---

## 🔄 **Integration Points**

### **Existing Services to Update:**
1. `ExpertiseCalculationService` - Add partnership boost calculation
2. `MultiPathExpertiseService` - Integrate partnership boost into paths
3. `PartnershipService` - Add profile visibility methods

### **Existing UI to Update:**
1. `ProfilePage` - Add partnerships section
2. `ExpertiseDashboardPage` - Add partnership boost display
3. `ExpertiseDisplayWidget` - Show partnership boost indicator

---

## 📝 **Deliverables**

### **Backend:**
- ✅ `PartnershipProfileService` - Get and filter user partnerships
- ✅ Partnership expertise boost calculation
- ✅ Expertise calculation service integration
- ✅ Partnership visibility/privacy controls

### **Frontend:**
- ✅ `PartnershipDisplayWidget` - Display partnerships
- ✅ `PartnershipCard` - Individual partnership card
- ✅ Profile page partnerships section
- ✅ Partnerships detail page
- ✅ Partnership expertise boost indicator
- ✅ Expertise dashboard partnership boost section

### **Testing:**
- ✅ Unit tests for partnership boost calculation
- ✅ Unit tests for partnership profile service
- ✅ Widget tests for partnership display
- ✅ Integration tests for profile display

---

## 🚪 **Doors Opened**

**What doors does this help users open?**
1. **Recognition:** Partnerships boost expertise, recognizing collaborative contributions
2. **Visibility:** Showcase professional relationships and collaborations
3. **Discovery:** Users can discover potential partners through profiles
4. **Credibility:** Partnership visibility builds trust and demonstrates real-world collaboration
5. **Growth:** Incentivizes successful partnerships through expertise recognition

**When are users ready for these doors?**
- After completing at least one partnership
- Partnership systems are live and functioning
- Users opt-in to display partnerships

**Is this being a good key?**
- Yes - Recognizes authentic professional relationships
- Not gamification - based on real partnerships
- Helps users find partners through visibility
- Rewards successful collaboration

**Is the AI learning?**
- AI learns which partnerships lead to expertise growth
- Can identify successful partnership patterns
- Can suggest partnerships based on profile compatibility

---

## 📚 **References**

- **Event Partnership Plan:** `docs/plans/event_partnership/EVENT_PARTNERSHIP_MONETIZATION_PLAN.md`
- **Brand Sponsorship Plan:** `docs/plans/brand_sponsorship/BRAND_DISCOVERY_SPONSORSHIP_PLAN.md`
- **Expertise System:** `docs/plans/dynamic_expertise/DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md`
- **User Journey:** `docs/USER_TO_EXPERT_JOURNEY.md`

---

**Status:** 🎯 Ready for Master Plan Integration  
**Priority:** P1 HIGH VALUE  
**Estimated Timeline:** 1 week

