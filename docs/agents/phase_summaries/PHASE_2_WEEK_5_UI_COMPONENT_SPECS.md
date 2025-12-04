# Phase 2, Week 5: UI Component Specifications

**Date:** November 23, 2025  
**Agent:** Agent 2 (Frontend & UX Specialist)  
**Status:** 📋 Specifications Complete  
**Purpose:** Detailed component specifications for Partnership and Business UI components

---

## 🎯 Overview

This document provides detailed specifications for reusable UI components needed for Partnership and Business UIs. All components must:
- ✅ Use AppColors/AppTheme (100% adherence)
- ✅ Follow existing component patterns
- ✅ Be accessible and responsive
- ✅ Include proper error/loading states

---

## 🤝 Partnership Components

### **1. PartnershipCard Widget**

**File:** `lib/presentation/widgets/partnerships/partnership_card.dart`

**Purpose:** Display partnership information in list views

**Props:**
```dart
class PartnershipCard extends StatelessWidget {
  final EventPartnership partnership;
  final VoidCallback? onTap;
  final VoidCallback? onManage;
  final bool showActions;
}
```

**Design:**
- **Card:** White background, rounded 12px, elevation 1
- **Layout:** Horizontal layout with business info on left, actions on right
- **Business Info:** Name, categories, compatibility badge
- **Event Info:** Event name, date, ticket count
- **Revenue Info:** Split percentage, estimated earnings
- **Actions:** "View Details" and "Manage" buttons (if showActions = true)

**Visual:**
```
┌─────────────────────────────────────┐
│ ☕ Third Coast Coffee               │
│    Coffee, Food                      │
│    95% compatibility ✓              │
│                                     │
│ Coffee Tasting Tour                 │
│ Dec 15, 2025 • 20 tickets          │
│ Revenue: 50/50 split                │
│                                     │
│              [View] [Manage]        │
└─────────────────────────────────────┘
```

**States:**
- **Default:** Normal display
- **Loading:** Show skeleton loader
- **Error:** Show error message with retry

**Colors:**
- Background: `AppColors.surface`
- Text Primary: `AppColors.textPrimary`
- Text Secondary: `AppColors.textSecondary`
- Compatibility Badge: `AppColors.electricGreen` (if 70%+), `AppColors.warning` (if below)

---

### **2. RevenueSplitDisplay Widget**

**File:** `lib/presentation/widgets/partnerships/revenue_split_display.dart`

**Purpose:** Display transparent revenue breakdown for partnerships

**Props:**
```dart
class RevenueSplitDisplay extends StatelessWidget {
  final double totalRevenue;
  final RevenueSplit split;
  final int ticketCount;
  final double ticketPrice;
  final bool showDetails; // Show fee breakdown
}
```

**Design:**
- **Card:** White background, rounded 12px
- **Layout:** Vertical list of revenue items
- **Items:** Total, Platform Fee, Processing Fee, Partner Splits
- **Highlight:** Partner earnings highlighted with green
- **Details Toggle:** Expandable section for fee details

**Visual:**
```
┌─────────────────────────────────────┐
│ Revenue Breakdown                    │
│                                     │
│ Total Revenue: $500.00              │
│ (20 tickets × $25)                  │
│                                     │
│ Platform Fee (10%): $50.00         │
│ Processing Fee (~3%): $15.00        │
│ ────────────────────────────────    │
│ Net Revenue: $435.00                │
│                                     │
│ Your Share (50%): $217.50           │
│ Partner Share (50%): $217.50        │
└─────────────────────────────────────┘
```

**Calculation:**
- Platform Fee: `totalRevenue * 0.10`
- Processing Fee: `(totalRevenue * 0.029) + (ticketCount * 0.30)`
- Net Revenue: `totalRevenue - platformFee - processingFee`
- Partner Shares: Based on split percentages

**Colors:**
- Total: `AppColors.textPrimary` (bold)
- Fees: `AppColors.textSecondary`
- Partner Earnings: `AppColors.electricGreen` (bold)

---

### **3. CompatibilityBadge Widget**

**File:** `lib/presentation/widgets/partnerships/compatibility_badge.dart`

**Purpose:** Display vibe compatibility score between user and business

**Props:**
```dart
class CompatibilityBadge extends StatelessWidget {
  final double compatibility; // 0.0 to 1.0
  final bool showLabel;
  final BadgeSize size; // small, medium, large
}
```

**Design:**
- **Badge:** Rounded pill shape
- **Color:** Green if 70%+, yellow if below
- **Icon:** Checkmark if 70%+, warning if below
- **Text:** Percentage with optional label

**Visual:**
```
Small:  [95% ✓]
Medium: [95% Compatibility ✓]
Large:  [95% Vibe Match ✓]
```

**States:**
- **High (70%+):** Green background (`AppColors.electricGreen` with 0.1 opacity), green text, checkmark icon
- **Low (<70%):** Yellow background (`AppColors.warning` with 0.1 opacity), warning text, warning icon

**Sizes:**
- **Small:** Padding 4px horizontal, 2px vertical, font size 10
- **Medium:** Padding 8px horizontal, 4px vertical, font size 12
- **Large:** Padding 12px horizontal, 6px vertical, font size 14

---

### **4. PartnershipRequestCard Widget**

**File:** `lib/presentation/widgets/partnerships/partnership_request_card.dart`

**Purpose:** Display partnership proposal with quick actions

**Props:**
```dart
class PartnershipRequestCard extends StatelessWidget {
  final PartnershipProposal proposal;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onView;
}
```

**Design:**
- **Card:** White background, rounded 12px, elevation 1
- **Header:** Proposer name, compatibility badge, timestamp
- **Event Preview:** Event name, date, basic details
- **Quick Actions:** View, Accept, Decline buttons
- **Status Badge:** "Pending" badge

**Visual:**
```
┌─────────────────────────────────────┐
│ Sarah Johnson                       │
│ 95% compatibility ✓                 │
│ 2 hours ago                          │
│                                     │
│ Coffee Tasting Tour                 │
│ Dec 15, 2025 • 20 tickets • $25     │
│                                     │
│ [View] [Accept] [Decline]          │
└─────────────────────────────────────┘
```

**Actions:**
- **View:** Navigate to full proposal page
- **Accept:** Show confirmation dialog, then accept
- **Decline:** Show confirmation dialog, then decline

**Colors:**
- Status Badge: `AppColors.warning` (pending)
- Accept Button: `AppTheme.primaryColor`
- Decline Button: `AppColors.error` (outlined)

---

### **5. PartnershipProposalForm Widget**

**File:** `lib/presentation/widgets/partnerships/partnership_proposal_form.dart`

**Purpose:** Form for creating partnership proposals

**Props:**
```dart
class PartnershipProposalForm extends StatefulWidget {
  final BusinessAccount business;
  final ExpertiseEvent? event; // Optional pre-filled event
  final Function(PartnershipProposal) onSubmit;
  final VoidCallback? onCancel;
}
```

**Design:**
- **Form:** Multi-section form with validation
- **Sections:** Partnership Type, Revenue Split, Responsibilities, Custom Terms
- **Revenue Split:** Slider or input fields for percentages
- **Validation:** Ensure percentages sum to 100%, required fields

**Visual:**
```
┌─────────────────────────────────────┐
│ Partnership Proposal                 │
│                                     │
│ Partner: Third Coast Coffee         │
│ Compatibility: 95% ✓                │
│                                     │
│ Partnership Type:                   │
│ ○ Co-Host                           │
│ ● Venue Provider                    │
│ ○ Sponsorship                       │
│                                     │
│ Revenue Split:                      │
│ Expert: [50%] Business: [50%]       │
│ [━━━━━━━━━━━━━━━━━━━━━━━━━━━━]     │
│                                     │
│ Responsibilities:                   │
│ ☑ Provide venue                     │
│ ☑ Marketing support                 │
│ ☐ Equipment                         │
│                                     │
│ Custom Terms:                       │
│ [Text area...]                      │
│                                     │
│ [Cancel] [Send Proposal]            │
└─────────────────────────────────────┘
```

**Validation:**
- Partnership type required
- Revenue split must sum to 100%
- At least one responsibility selected
- Custom terms optional

**Colors:**
- Form fields: `AppColors.grey100` background
- Validation errors: `AppColors.error`
- Submit button: `AppTheme.primaryColor`

---

## 🏢 Business Components

### **6. BusinessStatsCard Widget**

**File:** `lib/presentation/widgets/business/business_stats_card.dart`

**Purpose:** Display business statistics (events, earnings)

**Props:**
```dart
class BusinessStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
}
```

**Design:**
- **Card:** White background, rounded 12px, elevation 1
- **Layout:** Icon on left, label and value on right
- **Value:** Large, bold number
- **Label:** Smaller text below value
- **Interactive:** Optional tap action

**Visual:**
```
┌─────────────────────┐
│ 📅                  │
│                     │
│       5             │
│   Events            │
└─────────────────────┘
```

**Variants:**
- **Events:** Calendar icon, count
- **Earnings:** Dollar icon, amount
- **Partnerships:** Handshake icon, count
- **Pending Requests:** Bell icon, count

**Colors:**
- Icon: `AppTheme.primaryColor`
- Value: `AppColors.textPrimary` (bold, large)
- Label: `AppColors.textSecondary`

---

### **7. PartnershipRequestList Widget**

**File:** `lib/presentation/widgets/business/partnership_request_list.dart`

**Purpose:** List of partnership requests for business dashboard

**Props:**
```dart
class PartnershipRequestList extends StatelessWidget {
  final List<PartnershipProposal> requests;
  final Function(PartnershipProposal) onAccept;
  final Function(PartnershipProposal) onDecline;
  final Function(PartnershipProposal) onView;
  final bool isLoading;
}
```

**Design:**
- **List:** Vertical scrollable list
- **Items:** PartnershipRequestCard components
- **Empty State:** Message with "Find Partners" CTA
- **Loading State:** Skeleton loaders

**Visual:**
```
Partnership Requests (2)

[PartnershipRequestCard 1]
[PartnershipRequestCard 2]

Empty State:
┌─────────────────────────────────────┐
│ No partnership requests yet         │
│                                     │
│ Start creating events to receive    │
│ partnership proposals.               │
│                                     │
│ [Create Event]                      │
└─────────────────────────────────────┘
```

**States:**
- **Loading:** Show 3 skeleton cards
- **Empty:** Show empty state message
- **Populated:** Show list of requests

---

### **8. EarningsSummaryWidget Widget**

**File:** `lib/presentation/widgets/business/earnings_summary_widget.dart`

**Purpose:** Display earnings summary with payout information

**Props:**
```dart
class EarningsSummaryWidget extends StatelessWidget {
  final double totalEarned;
  final double pendingPayout;
  final DateTime? nextPayoutDate;
  final VoidCallback? onViewAll;
}
```

**Design:**
- **Card:** White background, rounded 12px
- **Layout:** Three sections (Total, Pending, Next Payout)
- **Values:** Large, bold numbers
- **Action:** "View All Earnings" button

**Visual:**
```
┌─────────────────────────────────────┐
│ Earnings Summary                    │
│                                     │
│ Total Earned: $2,450.00            │
│ Pending Payout: $217.50            │
│ Next Payout: Dec 17, 2025          │
│                                     │
│ [View All Earnings]                 │
└─────────────────────────────────────┘
```

**Colors:**
- Total: `AppColors.textPrimary` (bold)
- Pending: `AppColors.warning` (if > 0)
- Next Payout: `AppColors.textSecondary`

---

## 🎨 Common Patterns

### **Form Input Pattern**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Hint',
    filled: true,
    fillColor: AppColors.grey100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  style: TextStyle(color: AppColors.textPrimary),
)
```

### **Card Pattern**
```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: // Content
  ),
)
```

### **Button Pattern**
```dart
// Primary
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryColor,
    foregroundColor: AppColors.white,
    padding: EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('Button'),
)

// Outlined
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    side: BorderSide(color: AppColors.grey300),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('Button'),
)
```

### **Status Badge Pattern**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: statusColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: statusColor.withOpacity(0.3),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: statusColor),
      SizedBox(width: 4),
      Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
)
```

---

## ✅ Component Checklist

- [x] PartnershipCard specified
- [x] RevenueSplitDisplay specified
- [x] CompatibilityBadge specified
- [x] PartnershipRequestCard specified
- [x] PartnershipProposalForm specified
- [x] BusinessStatsCard specified
- [x] PartnershipRequestList specified
- [x] EarningsSummaryWidget specified
- [x] Common patterns documented
- [x] Design tokens verified (100% adherence)

---

**Status:** ✅ Specifications Complete  
**Next Steps:** Implementation (Week 6-8)  
**Dependencies:** Agent 3's models (Week 5) - components will use these models

