# Phase 2, Week 6: UI Preparation & Design (Finalization)

**Date:** November 23, 2025  
**Agent:** Agent 2 (Frontend & UX Specialist)  
**Status:** ✅ **COMPLETE**  
**Week:** Week 6 of Phase 2

---

## 🎯 Executive Summary

Week 6 UI Preparation & Design finalization is **complete**. All Partnership and Business UI designs have been finalized based on Agent 3's actual model structures. Component specifications updated with real model references, and integration plan aligned with actual data structures.

---

## ✅ Model Review Complete

### **Partnership Models Reviewed:**

1. **EventPartnership** ✅
   - **Key Fields:**
     - `id`, `eventId`, `userId`, `businessId`
     - `status` (PartnershipStatus enum: pending, proposed, negotiating, approved, locked, active, completed, cancelled, disputed)
     - `type` (PartnershipType enum: eventBased, ongoing, exclusive)
     - `agreement` (PartnershipAgreement with flexible terms)
     - `revenueSplit` (RevenueSplit reference)
     - `sharedResponsibilities` (List<String>)
     - `vibeCompatibilityScore` (double? - 70%+ required)
     - `userApproved`, `businessApproved` (bool)
     - Helper methods: `isApproved`, `isLocked`, `canBeModified`, `isActive`, `isCompleted`

2. **RevenueSplit** ✅
   - **Key Fields:**
     - `totalAmount`, `platformFee` (10%), `processingFee` (~3%)
     - `parties` (List<SplitParty> for N-way splits)
     - `isLocked` (pre-event locking - CRITICAL)
     - `ticketsSold`
     - Factory methods: `calculate()` for solo, `nWay()` for partnerships
     - Helper methods: `isValid`, `canBeModified`, `lock()`

3. **PartnershipEvent** ✅
   - **Key Fields:**
     - Extends `ExpertiseEvent`
     - `partnershipId`, `partnership`
     - `revenueSplitId`, `revenueSplit`
     - `isPartnershipEvent`, `partnerIds`, `partnerCount`
     - Helper methods: `hasPartnership`, `hasRevenueSplit`, `isRevenueSplitLocked`

### **Business Models Reviewed:**

1. **BusinessAccount** ✅
   - **Key Fields:**
     - `id`, `name`, `email`, `description`
     - `businessType`, `categories`
     - `location`, `phone`, `website`, `logoUrl`
     - `verification` (BusinessVerification)
     - `stripeConnectAccountId` (for payouts)
     - `connectedExpertIds`, `pendingConnectionIds`
     - `expertPreferences`, `patronPreferences`

2. **BusinessVerification** ✅
   - **Key Fields:**
     - `status` (VerificationStatus enum: pending, inReview, verified, rejected, expired)
     - `method` (VerificationMethod enum: automatic, manual, document, hybrid)
     - Document URLs: `businessLicenseUrl`, `taxIdDocumentUrl`, `proofOfAddressUrl`
     - Business details: `legalBusinessName`, `taxId`, `businessAddress`
     - Helper methods: `isComplete`, `isPending`, `isRejected`, `progress` (0.0-1.0)

---

## 🎨 Finalized UI Designs

### **Design Updates Based on Models:**

#### **1. Partnership Status Handling**
- **Status Badges:** Support all 9 PartnershipStatus values
- **Status Colors:**
  - `pending`, `proposed` → `AppColors.warning` (yellow)
  - `negotiating` → `AppColors.textSecondary` (grey)
  - `approved` → `AppColors.electricGreen` (green)
  - `locked`, `active` → `AppColors.electricGreen` (green, bold)
  - `completed` → `AppColors.textSecondary` (grey)
  - `cancelled`, `disputed` → `AppColors.error` (red)

#### **2. Revenue Split Display**
- **Support N-way splits:** Display all parties from `RevenueSplit.parties`
- **Show SplitParty details:** Type (user/business/sponsor), percentage, amount
- **Lock status:** Show locked indicator if `isLocked = true`
- **Calculation display:** Use `RevenueSplit.splitAmount` for net revenue

#### **3. Partnership Type Selection**
- **Radio buttons:** Event-Based, Ongoing, Exclusive
- **Default:** Event-Based (most common)
- **Ongoing:** Show `expectedEventCount` field
- **Exclusive:** Show warning about exclusivity

#### **4. Agreement Terms**
- **Flexible structure:** Use `PartnershipAgreement.terms` (Map<String, dynamic>)
- **Custom terms:** Use `customArrangementDetails` field
- **Version tracking:** Display `termsVersion` if available

#### **5. Vibe Compatibility**
- **Display:** Show `vibeCompatibilityScore` as percentage
- **Threshold:** Only show suggestions if 70%+ (per model requirement)
- **Badge:** Green if 70%+, yellow if below

#### **6. Business Verification Status**
- **Status display:** Support all 5 VerificationStatus values
- **Progress indicator:** Use `verification.progress` (0.0-1.0)
- **Method display:** Show verification method (automatic/manual/document/hybrid)
- **Document preview:** Show uploaded documents with preview/remove

---

## 📋 Updated Component Specifications

### **Component Props Updated with Actual Models:**

#### **1. PartnershipCard Widget**
```dart
class PartnershipCard extends StatelessWidget {
  final EventPartnership partnership; // Actual model
  final VoidCallback? onTap;
  final VoidCallback? onManage;
  final bool showActions;
  
  // Display:
  // - partnership.business?.name
  // - partnership.status (with status badge)
  // - partnership.vibeCompatibilityScore (if available)
  // - partnership.revenueSplit (if available)
  // - partnership.eventIds.length (event count)
}
```

#### **2. RevenueSplitDisplay Widget**
```dart
class RevenueSplitDisplay extends StatelessWidget {
  final RevenueSplit split; // Actual model
  final bool showDetails;
  
  // Display:
  // - split.totalAmount
  // - split.platformFee (10%)
  // - split.processingFee (~3%)
  // - split.splitAmount (net after fees)
  // - split.parties (N-way distribution)
  // - split.isLocked (lock indicator)
  // - split.ticketsSold
}
```

#### **3. PartnershipProposalForm Widget**
```dart
class PartnershipProposalForm extends StatefulWidget {
  final BusinessAccount business; // Actual model
  final ExpertiseEvent? event;
  final Function(EventPartnership) onSubmit; // Returns actual model
  
  // Form fields map to EventPartnership:
  // - PartnershipType (radio buttons)
  // - RevenueSplit (slider/inputs)
  // - sharedResponsibilities (checkboxes)
  // - customArrangementDetails (text area)
  // - expectedEventCount (if ongoing)
}
```

#### **4. PartnershipAcceptancePage**
```dart
class PartnershipAcceptancePage extends StatelessWidget {
  final EventPartnership proposal; // Actual model
  
  // Display:
  // - proposal.user (expert info)
  // - proposal.business (business info)
  // - proposal.type
  // - proposal.agreement?.terms
  // - proposal.revenueSplit (with RevenueSplitDisplay)
  // - proposal.vibeCompatibilityScore
  // - proposal.sharedResponsibilities
  
  // Actions:
  // - Accept: Set businessApproved = true
  // - Decline: Set status = cancelled
  // - Counter-propose: Set status = negotiating
}
```

#### **5. BusinessVerificationWidget (Enhanced)**
```dart
class BusinessVerificationWidget extends StatefulWidget {
  final BusinessAccount business; // Actual model
  final BusinessVerification? verification; // Actual model
  
  // Display:
  // - verification.status (with status badge)
  // - verification.progress (progress bar)
  // - verification.method (verification method)
  // - verification.businessLicenseUrl (document preview)
  // - verification.taxIdDocumentUrl (document preview)
  // - verification.legalBusinessName, taxId, businessAddress
  
  // States:
  // - isComplete: Show verified content
  // - isPending: Show pending content with progress
  // - isRejected: Show rejection reason + resubmit form
}
```

---

## 🔗 Updated Integration Plan

### **Model-Based Integration Points:**

#### **1. Event Creation with Partnership**
```dart
// In create_event_page.dart:
EventPartnership? _partnership;

// When user selects partner:
_partnership = EventPartnership(
  id: generateId(),
  eventId: _eventId, // Will be set after event creation
  userId: _currentUser.id,
  businessId: _selectedBusiness.id,
  status: PartnershipStatus.proposed,
  type: _selectedPartnershipType,
  sharedResponsibilities: _selectedResponsibilities,
  revenueSplit: _revenueSplit,
  vibeCompatibilityScore: _compatibilityScore,
  userApproved: true,
  businessApproved: false,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// After event creation:
final partnership = _partnership!.copyWith(
  eventId: createdEvent.id,
);
await partnershipService.createProposal(partnership);
```

#### **2. Revenue Split Calculation**
```dart
// Use RevenueSplit factory methods:
final revenueSplit = RevenueSplit.nWay(
  id: generateId(),
  eventId: event.id,
  partnershipId: partnership.id,
  totalAmount: totalRevenue,
  ticketsSold: ticketCount,
  parties: [
    SplitParty(
      partyId: userId,
      type: SplitPartyType.user,
      percentage: expertPercentage,
      name: user.displayName,
    ),
    SplitParty(
      partyId: businessId,
      type: SplitPartyType.business,
      percentage: businessPercentage,
      name: business.name,
    ),
  ],
);

// Lock before event:
final lockedSplit = revenueSplit.lock(lockedBy: userId);
```

#### **3. Partnership Status Updates**
```dart
// Accept partnership:
partnership = partnership.copyWith(
  businessApproved: true,
  status: PartnershipStatus.approved,
  updatedAt: DateTime.now(),
);

// Lock before event:
partnership = partnership.copyWith(
  status: PartnershipStatus.locked,
  termsAgreedAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

---

## 📊 Model-to-UI Mapping

### **EventPartnership → UI Components:**

| Model Field | UI Component | Display Format |
|-------------|--------------|----------------|
| `status` | StatusBadge | Color-coded badge with icon |
| `type` | RadioButtonGroup | Event-Based/Ongoing/Exclusive |
| `vibeCompatibilityScore` | CompatibilityBadge | Percentage with color (70%+ green) |
| `revenueSplit` | RevenueSplitDisplay | Breakdown with parties |
| `sharedResponsibilities` | CheckboxList | List of responsibilities |
| `agreement?.terms` | TermsDisplay | Formatted terms map |
| `userApproved`, `businessApproved` | ApprovalIndicator | Checkmarks for each party |
| `eventIds` | EventCountBadge | Number of events |

### **RevenueSplit → UI Components:**

| Model Field | UI Component | Display Format |
|-------------|--------------|----------------|
| `totalAmount` | AmountDisplay | Currency format |
| `platformFee` | FeeRow | Percentage + amount |
| `processingFee` | FeeRow | Percentage + amount |
| `splitAmount` | NetRevenueDisplay | Highlighted amount |
| `parties` | SplitPartyList | List with percentages + amounts |
| `isLocked` | LockIndicator | Lock icon + "Locked" badge |
| `ticketsSold` | TicketCountBadge | Number of tickets |

### **BusinessAccount → UI Components:**

| Model Field | UI Component | Display Format |
|-------------|--------------|----------------|
| `name` | BusinessNameHeader | Large, bold |
| `categories` | CategoryChips | Chip list |
| `verification?.status` | VerificationBadge | Status with icon |
| `stripeConnectAccountId` | StripeStatusIndicator | Connected/Not connected |
| `location` | LocationDisplay | Address with icon |
| `website` | WebsiteLink | Clickable link |

### **BusinessVerification → UI Components:**

| Model Field | UI Component | Display Format |
|-------------|--------------|----------------|
| `status` | StatusHeader | Large status card |
| `progress` | ProgressBar | 0-100% progress |
| `method` | MethodBadge | Verification method |
| `businessLicenseUrl` | DocumentPreview | Preview + remove |
| `legalBusinessName` | FormField | Text input |
| `taxId` | FormField | Text input |

---

## ✅ Finalization Checklist

- [x] Review EventPartnership model structure
- [x] Review RevenueSplit model structure
- [x] Review PartnershipEvent model structure
- [x] Review BusinessAccount model structure
- [x] Review BusinessVerification model structure
- [x] Update Partnership UI designs with actual model fields
- [x] Update Business UI designs with actual model fields
- [x] Update component specifications with actual model types
- [x] Update integration plan with actual model references
- [x] Map model fields to UI components
- [x] Document status enum handling
- [x] Document revenue split calculation display
- [x] Document partnership workflow states

---

## 🎯 Key Design Decisions

### **1. Partnership Status Flow**
```
pending → proposed → negotiating → approved → locked → active → completed
   ↓         ↓            ↓
cancelled  cancelled   cancelled
```

**UI Implications:**
- Show status badge that reflects current state
- Enable/disable actions based on `canBeModified`
- Show lock indicator when `isLocked = true`
- Prevent modifications after lock

### **2. Revenue Split Locking**
- **Critical:** Must lock before event starts
- **UI:** Show prominent warning if not locked
- **Action:** "Lock Revenue Split" button (disabled after lock)
- **Display:** Lock icon + timestamp when locked

### **3. Vibe Compatibility Threshold**
- **Requirement:** Only show suggestions if 70%+
- **UI:** Filter businesses in search results
- **Display:** Show compatibility score prominently
- **Badge:** Green if 70%+, yellow if below (but still show)

### **4. N-way Revenue Splits**
- **Support:** Display all parties from `RevenueSplit.parties`
- **Layout:** List or grid of party cards
- **Each party:** Type badge, percentage, calculated amount
- **Validation:** Ensure percentages sum to 100%

### **5. Business Verification Progress**
- **Display:** Progress bar using `verification.progress`
- **States:** Show different UI for pending/inReview/verified/rejected
- **Documents:** Preview uploaded documents
- **Auto-verification:** Prominent option if website available

---

## 📚 Updated Documentation

1. **`PHASE_2_WEEK_5_UI_DESIGNS.md`** - Original designs (still valid)
2. **`PHASE_2_WEEK_5_UI_COMPONENT_SPECS.md`** - Original specs (still valid)
3. **`PHASE_2_WEEK_5_UI_INTEGRATION_PLAN.md`** - Original plan (still valid)
4. **`PHASE_2_WEEK_6_UI_FINALIZATION.md`** - This document (model-based updates)

---

## 🚀 Ready for Implementation

**Week 6 UI Finalization is complete. All designs are:**
- ✅ Based on actual model structures
- ✅ Aligned with model fields and enums
- ✅ Ready for Week 7-8 implementation
- ✅ Documented with model references

**Next Steps:**
- Week 7: Payment UI, Revenue Display UI (can start implementation)
- Week 8: Full Partnership and Business UI implementation

---

**Status:** ✅ **COMPLETE**  
**Next Phase:** Week 7 - Payment UI, Revenue Display UI  
**Dependencies:** Agent 1's services (Week 6-7) - can start UI work with mock data

