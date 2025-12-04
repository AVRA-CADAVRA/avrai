# Phase 2, Week 5: UI Design & Preparation - Design Mockups & Specifications

**Date:** November 23, 2025  
**Agent:** Agent 2 (Frontend & UX Specialist)  
**Status:** 🎨 Design Complete  
**Purpose:** UI mockups and specifications for Partnership and Business UIs

---

## 🎯 Overview

This document contains detailed UI mockups and specifications for:
1. **Partnership UI** - Proposal, Acceptance, Management
2. **Business UI** - Account Setup, Verification (enhancement), Dashboard
3. **Integration Points** - How these UIs integrate with event creation

**Design Principles:**
- ✅ 100% design token adherence (AppColors/AppTheme)
- ✅ Follow existing UI patterns from Phase 1
- ✅ Modern, beautiful, accessible design
- ✅ Consistent with event creation UI patterns

---

## 📐 Design System Reference

### **Color Palette (AppColors)**
- **Primary:** `AppColors.electricGreen` (#00FF66)
- **Background:** `AppColors.background` (white)
- **Surface:** `AppColors.surface` (white)
- **Text Primary:** `AppColors.textPrimary` (#121212)
- **Text Secondary:** `AppColors.textSecondary` (grey600)
- **Text Hint:** `AppColors.textHint` (grey400)
- **Error:** `AppColors.error` (#FF4D4D)
- **Warning:** `AppColors.warning` (#FFC107)
- **Success:** `AppColors.electricGreen`

### **Common UI Patterns (From Existing Code)**
- **Cards:** Rounded corners (12px), elevation 1, white background
- **Forms:** Filled inputs with `AppColors.grey100`, rounded borders (12px)
- **Buttons:** Primary uses `AppTheme.primaryColor`, rounded (12px), padding 16px vertical
- **AppBar:** `AppTheme.primaryColor` background, white text
- **Status Indicators:** Colored backgrounds with opacity (0.1), borders with opacity (0.3)

---

## 🤝 Partnership UI Mockups

### **1. Partnership Proposal UI**

**Purpose:** Allow users to propose partnerships with businesses for events

**File:** `lib/presentation/pages/partnerships/partnership_proposal_page.dart`

**Layout:**
```
┌─────────────────────────────────────┐
│ ← Back    Partnership Proposal       │
├─────────────────────────────────────┤
│                                     │
│  Find a Business Partner            │
│  Partner with businesses to host     │
│  events together                     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔍 Search businesses...      │   │
│  └─────────────────────────────┘   │
│                                     │
│  Suggested Partners (Vibe Match)   │
│  ┌─────────────────────────────┐   │
│  │ ☕ Third Coast Coffee        │   │
│  │    95% compatibility         │   │
│  │    Coffee, Food              │   │
│  │    [View Profile] [Propose]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🍕 Tony's Pizza             │   │
│  │    87% compatibility         │   │
│  │    Food, Dining              │   │
│  │    [View Profile] [Propose]   │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Key Components:**
1. **Search Bar** - Search businesses by name, category, location
2. **Vibe Compatibility Badge** - Shows compatibility percentage (70%+ required)
3. **Business Card** - Name, categories, compatibility score, action buttons
4. **Proposal Form** (Modal/Drawer) - Partnership terms, revenue split, responsibilities

**Proposal Form Details:**
```
┌─────────────────────────────────────┐
│ Partnership Proposal                │
│                                     │
│ Partner: Third Coast Coffee         │
│ Compatibility: 95% ✓                │
│                                     │
│ Partnership Type:                   │
│ ○ Co-Host (Equal partners)          │
│ ● Venue Provider (Business venue)   │
│ ○ Sponsorship                       │
│                                     │
│ Revenue Split:                      │
│ [Expert: 50%] [Business: 50%]      │
│ (Adjustable slider)                 │
│                                     │
│ Responsibilities:                   │
│ ☑ Provide venue                     │
│ ☑ Marketing support                 │
│ ☐ Equipment                         │
│                                     │
│ Custom Terms (Optional):            │
│ [Text area]                         │
│                                     │
│ [Cancel] [Send Proposal]            │
└─────────────────────────────────────┘
```

**Design Specifications:**
- **Search Bar:** Follows existing search pattern (rounded, filled, grey100 background)
- **Business Cards:** Card component with padding 16px, rounded 12px
- **Compatibility Badge:** Green background (electricGreen with 0.1 opacity) if 70%+, warning color if below
- **Proposal Form:** Modal bottom sheet or full page (depending on complexity)
- **Revenue Split Slider:** Custom slider showing percentages, updates in real-time

---

### **2. Partnership Acceptance UI**

**Purpose:** Allow businesses to view, accept, or decline partnership proposals

**File:** `lib/presentation/pages/partnerships/partnership_acceptance_page.dart`

**Layout:**
```
┌─────────────────────────────────────┐
│ ← Back    Partnership Proposal       │
├─────────────────────────────────────┤
│                                     │
│  Partnership Proposal               │
│  from Sarah Johnson                 │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Event: Coffee Tasting Tour   │   │
│  │ Date: Dec 15, 2025          │   │
│  │ Location: Your Venue        │   │
│  │ Max Attendees: 20           │   │
│  │ Price: $25/ticket           │   │
│  └─────────────────────────────┘   │
│                                     │
│  Partnership Details:              │
│  ┌─────────────────────────────┐   │
│  │ Type: Venue Provider         │   │
│  │ Revenue Split: 50/50        │   │
│  │                             │   │
│  │ Responsibilities:           │   │
│  │ • Provide venue             │   │
│  │ • Marketing support          │   │
│  │                             │   │
│  │ Custom Terms:               │   │
│  │ "We'll handle setup, you    │   │
│  │  provide the space"         │   │
│  └─────────────────────────────┘   │
│                                     │
│  Estimated Revenue (20 tickets):   │
│  ┌─────────────────────────────┐   │
│  │ Total: $500                 │   │
│  │ Platform Fee (10%): $50     │   │
│  │ Processing (~3%): $15        │   │
│  │ ────────────────────────    │   │
│  │ Your Share (50%): $217.50   │   │
│  │ Expert Share (50%): $217.50  │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Decline] [Accept Partnership]    │
└─────────────────────────────────────┘
```

**Key Components:**
1. **Proposal Header** - Shows proposer name, compatibility score
2. **Event Preview Card** - Event details from proposal
3. **Partnership Terms Card** - Type, split, responsibilities
4. **Revenue Breakdown** - Transparent fee calculation
5. **Action Buttons** - Decline (outlined), Accept (primary)

**Design Specifications:**
- **Proposal Header:** Card with status indicator (pending badge)
- **Revenue Breakdown:** Card with clear fee breakdown, uses AppColors for emphasis
- **Action Buttons:** Full-width, primary button for accept, outlined for decline
- **Status Indicators:** Color-coded (green for good compatibility, warning for low)

---

### **3. Partnership Management UI**

**Purpose:** View and manage active partnerships

**File:** `lib/presentation/pages/partnerships/partnership_management_page.dart`

**Layout:**
```
┌─────────────────────────────────────┐
│ My Partnerships                     │
├─────────────────────────────────────┤
│                                     │
│  [Active] [Pending] [Completed]    │
│                                     │
│  Active Partnerships (2)           │
│  ┌─────────────────────────────┐   │
│  │ ☕ Third Coast Coffee        │   │
│  │    Coffee Tasting Tour       │   │
│  │    Dec 15, 2025 • 20 tickets │   │
│  │    Revenue: 50/50 split      │   │
│  │    [View Details] [Manage]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🍕 Tony's Pizza             │   │
│  │    Pizza Making Workshop     │   │
│  │    Dec 20, 2025 • 15 tickets │   │
│  │    Revenue: 60/40 split      │   │
│  │    [View Details] [Manage]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  [+ New Partnership]                │
└─────────────────────────────────────┘
```

**Key Components:**
1. **Tab Navigation** - Active, Pending, Completed partnerships
2. **Partnership Cards** - Business name, event, date, revenue split
3. **Quick Actions** - View details, manage partnership
4. **New Partnership Button** - FAB or button to create new proposal

**Partnership Details View:**
```
┌─────────────────────────────────────┐
│ ← Back    Partnership Details       │
├─────────────────────────────────────┤
│                                     │
│  Third Coast Coffee                 │
│  Partnership Status: Active ✓      │
│                                     │
│  Events (2)                         │
│  ┌─────────────────────────────┐   │
│  │ Coffee Tasting Tour          │   │
│  │ Dec 15, 2025 • $500 revenue │   │
│  │ Your share: $217.50          │   │
│  └─────────────────────────────┘   │
│                                     │
│  Revenue Summary                    │
│  ┌─────────────────────────────┐   │
│  │ Total Earned: $435.00       │   │
│  │ Pending Payout: $217.50     │   │
│  │ Next Payout: Dec 17, 2025   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Partnership Terms                  │
│  [View Agreement] [Edit Terms]     │
│                                     │
│  [End Partnership]                 │
└─────────────────────────────────────┘
```

**Design Specifications:**
- **Tab Navigation:** Follows existing tab pattern (bottom tabs or top tabs)
- **Partnership Cards:** List view with cards, similar to event cards
- **Details View:** Full page with sections (Events, Revenue, Terms)
- **Status Badges:** Color-coded (green for active, yellow for pending, grey for completed)

---

## 🏢 Business UI Mockups

### **1. Business Account Setup UI**

**Purpose:** Create and configure business accounts

**File:** `lib/presentation/pages/business/business_setup_page.dart`

**Note:** This exists as `business_account_creation_page.dart` - enhance with Stripe Connect setup

**Enhanced Layout:**
```
┌─────────────────────────────────────┐
│ ← Back    Business Account Setup    │
├─────────────────────────────────────┤
│                                     │
│  Step 1 of 3: Basic Information    │
│  [████░░░░░░] 33%                   │
│                                     │
│  Business Name *                    │
│  [Third Coast Coffee____________]   │
│                                     │
│  Business Type *                    │
│  [Restaurant ▼]                     │
│                                     │
│  Categories *                       │
│  [Coffee] [Food] [+ Add]            │
│                                     │
│  Location *                         │
│  [123 Main St, Austin, TX_______]   │
│                                     │
│  Phone                              │
│  [(512) 555-0123________________]   │
│                                     │
│  Website                            │
│  [https://thirdcoast.com_________]   │
│                                     │
│  Description                        │
│  [Text area...]                     │
│                                     │
│  [Back] [Continue to Step 2]       │
└─────────────────────────────────────┘
```

**Step 2: Stripe Connect Setup**
```
┌─────────────────────────────────────┐
│ Step 2 of 3: Payment Setup          │
│ [████████░░] 66%                    │
│                                     │
│  Connect Stripe Account             │
│                                     │
│  To receive payments from events,   │
│  you need to connect a Stripe       │
│  account. This is secure and        │
│  required for payouts.              │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Connect Stripe Account]    │   │
│  │ Opens Stripe Connect flow   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ✓ Account Connected                │
│  Connected to: ***@example.com      │
│  [Disconnect] [Update]              │
│                                     │
│  [Back] [Continue to Step 3]        │
└─────────────────────────────────────┘
```

**Step 3: Verification (Optional)**
```
┌─────────────────────────────────────┐
│ Step 3 of 3: Verification           │
│ [████████████] 100%                  │
│                                     │
│  Verify Your Business               │
│                                     │
│  Verification helps build trust     │
│  with users and experts. You can    │
│  skip this step and verify later.   │
│                                     │
│  [Skip for Now] [Start Verification]│
│                                     │
│  [Back] [Complete Setup]            │
└─────────────────────────────────────┘
```

**Design Specifications:**
- **Multi-step Form:** Progress indicator at top, step navigation
- **Form Fields:** Follow existing form patterns (filled inputs, rounded borders)
- **Stripe Connect:** Button opens Stripe Connect flow, shows connection status
- **Skip Options:** Allow skipping verification (can do later)

---

### **2. Business Verification UI (Enhancement)**

**Purpose:** Enhanced version of existing verification widget

**File:** `lib/presentation/pages/business/business_verification_page.dart`

**Note:** Widget exists - create full page version with enhanced features

**Enhanced Layout:**
```
┌─────────────────────────────────────┐
│ ← Back    Business Verification    │
├─────────────────────────────────────┤
│                                     │
│  Verification Status: Pending       │
│  [Progress: 60%]                    │
│                                     │
│  Quick Verification                 │
│  ┌─────────────────────────────┐   │
│  │ We can verify automatically │   │
│  │ using your website.          │   │
│  │                             │   │
│  │ [Try Automatic Verification]│   │
│  └─────────────────────────────┘   │
│                                     │
│  Manual Verification                │
│                                     │
│  Business Information               │
│  [Legal Name, Tax ID, Address...]   │
│                                     │
│  Verification Documents             │
│  ┌─────────────────────────────┐   │
│  │ Business License            │   │
│  │ [Upload] [View] ✓          │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Tax ID Document             │   │
│  │ [Upload] [View]             │   │
│  └─────────────────────────────┘   │
│                                     │
│  Verification History               │
│  ┌─────────────────────────────┐   │
│  │ Dec 1, 2025: Submitted       │   │
│  │ Dec 2, 2025: In Review       │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Submit for Verification]          │
└─────────────────────────────────────┘
```

**Design Specifications:**
- **Status Header:** Enhanced with progress indicator
- **Document Upload:** Card-based upload with preview/remove options
- **Verification History:** Timeline view of verification status changes
- **Auto-verification:** Prominent card for automatic verification option

---

### **3. Business Dashboard UI**

**Purpose:** Business account overview, partnerships, earnings

**File:** `lib/presentation/pages/business/business_dashboard_page.dart`

**Layout:**
```
┌─────────────────────────────────────┐
│ Business Dashboard                  │
├─────────────────────────────────────┤
│                                     │
│  Third Coast Coffee                 │
│  ✓ Verified Business                │
│                                     │
│  Quick Stats                        │
│  ┌──────────┬──────────┐           │
│  │ Events   │ Earnings │           │
│  │    5     │  $2,450  │           │
│  └──────────┴──────────┘           │
│                                     │
│  Partnership Requests (2)           │
│  ┌─────────────────────────────┐   │
│  │ Sarah J. - Coffee Tour      │   │
│  │ 95% compatibility            │   │
│  │ [View] [Accept] [Decline]    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Active Partnerships (3)            │
│  ┌─────────────────────────────┐   │
│  │ Coffee Tasting Tour          │   │
│  │ Dec 15 • $217.50 earned      │   │
│  │ [View Details]               │   │
│  └─────────────────────────────┘   │
│                                     │
│  Recent Earnings                    │
│  ┌─────────────────────────────┐   │
│  │ Dec 10: $435.00             │   │
│  │ Dec 5: $217.50              │   │
│  │ [View All Earnings]          │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Manage Account] [View Analytics]  │
└─────────────────────────────────────┘
```

**Key Components:**
1. **Business Header** - Name, verification status
2. **Quick Stats Cards** - Events count, total earnings
3. **Partnership Requests** - Pending proposals with quick actions
4. **Active Partnerships** - List of current partnerships
5. **Recent Earnings** - Earnings history with payout status
6. **Action Buttons** - Account management, analytics

**Design Specifications:**
- **Stats Cards:** Grid layout (2 columns), card design with large numbers
- **Partnership Requests:** Cards with compatibility badges, action buttons
- **Earnings List:** Simple list with dates and amounts
- **Navigation:** Bottom navigation or drawer for business features

---

## 🔗 UI Integration Plan

### **Integration with Event Creation**

**Where Partnerships Fit:**
1. **Event Creation Flow Enhancement:**
   - Add "Create with Partner" option in `create_event_page.dart`
   - Add partnership selection step in `quick_event_builder_page.dart`
   - Show partnership info in `event_review_page.dart`

**Integration Points:**

#### **1. Event Creation Page Enhancement**
```dart
// In create_event_page.dart, add:
- Partnership toggle: "Create with Business Partner"
- If enabled, show partner selection/search
- Pre-fill venue if partner provides venue
- Show revenue split configuration
```

#### **2. Quick Event Builder Enhancement**
```dart
// In quick_event_builder_page.dart, add:
- Step 0.5: "Partner Selection" (optional)
- If partner selected, auto-fill venue and some details
- Show partnership terms in review step
```

#### **3. Event Review Page Enhancement**
```dart
// In event_review_page.dart, add:
- Show partnership details if event has partner
- Show revenue split breakdown
- Show partner responsibilities
```

### **Navigation Flow**

```
Event Creation
    ↓
[Optional: Add Partner]
    ↓
Partnership Proposal Page
    ↓
Business Accepts/Declines
    ↓
Event Created with Partnership
    ↓
Event Review (shows partnership)
    ↓
Event Published
```

### **Entry Points**

1. **From Event Creation:**
   - "Create with Partner" button in create event form
   - Partnership step in quick builder

2. **From Business Dashboard:**
   - "New Partnership" button
   - Partnership requests section

3. **From Profile/Settings:**
   - "My Partnerships" link
   - "Business Account" link (if user has business)

---

## 📋 Component Specifications

### **Reusable Components to Create**

1. **PartnershipCard Widget**
   - Displays partnership info
   - Shows compatibility score
   - Action buttons
   - File: `lib/presentation/widgets/partnerships/partnership_card.dart`

2. **RevenueSplitDisplay Widget**
   - Shows revenue breakdown
   - Platform fees, processing fees
   - Partner splits
   - File: `lib/presentation/widgets/partnerships/revenue_split_display.dart`

3. **CompatibilityBadge Widget**
   - Shows vibe compatibility percentage
   - Color-coded (green 70%+, yellow below)
   - File: `lib/presentation/widgets/partnerships/compatibility_badge.dart`

4. **BusinessStatsCard Widget**
   - Displays business statistics
   - Events count, earnings
   - File: `lib/presentation/widgets/business/business_stats_card.dart`

5. **PartnershipRequestCard Widget**
   - Shows partnership proposal
   - Quick accept/decline actions
   - File: `lib/presentation/widgets/partnerships/partnership_request_card.dart`

---

## ✅ Design Checklist

- [x] Partnership Proposal UI designed
- [x] Partnership Acceptance UI designed
- [x] Partnership Management UI designed
- [x] Business Account Setup UI enhanced
- [x] Business Verification UI enhanced
- [x] Business Dashboard UI designed
- [x] Integration points identified
- [x] Component specifications created
- [x] Navigation flow mapped
- [x] Design tokens verified (100% adherence)

---

## 🎨 Design Notes

1. **Consistency:** All UIs follow existing Phase 1 patterns
2. **Accessibility:** All components use semantic colors, proper contrast
3. **Responsiveness:** Designs work on mobile (primary) and tablet
4. **Loading States:** All async operations show loading indicators
5. **Error Handling:** Error states use AppColors.error with clear messages
6. **Empty States:** Empty lists show helpful messages and CTAs

---

**Status:** ✅ Design Complete  
**Next Steps:** Implementation (Week 6-8)  
**Dependencies:** Agent 3's models (Week 5) - can finalize after models are ready

