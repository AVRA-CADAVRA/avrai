# Phase 2, Week 5: UI Integration Plan

**Date:** November 23, 2025  
**Agent:** Agent 2 (Frontend & UX Specialist)  
**Status:** 📋 Integration Plan Complete  
**Purpose:** Detailed plan for integrating Partnership and Business UIs with existing event creation flow

---

## 🎯 Overview

This document outlines how Partnership and Business UIs integrate with:
1. **Event Creation Flow** - Where partnerships fit in
2. **Navigation Structure** - How users access these features
3. **Data Flow** - How data moves between components
4. **Service Integration** - Backend service connections

---

## 🔗 Integration Points

### **1. Event Creation Integration**

#### **A. Create Event Page Enhancement**

**File:** `lib/presentation/pages/events/create_event_page.dart`

**Changes:**
1. Add partnership toggle/option
2. Add partner selection step (if enabled)
3. Show partnership info in form
4. Pass partnership data to review page

**Implementation:**
```dart
// Add to _CreateEventPageState:
bool _createWithPartner = false;
BusinessAccount? _selectedPartner;
RevenueSplit? _revenueSplit;

// Add UI element:
SwitchListTile(
  title: Text('Create with Business Partner'),
  subtitle: Text('Partner with a business to co-host'),
  value: _createWithPartner,
  onChanged: (value) {
    setState(() {
      _createWithPartner = value;
      if (value) {
        // Navigate to partner selection
        _selectPartner();
      } else {
        _selectedPartner = null;
        _revenueSplit = null;
      }
    });
  },
  activeColor: AppTheme.primaryColor,
),

// If partner selected, show partner info:
if (_selectedPartner != null)
  _buildPartnerInfoCard(_selectedPartner!),
```

**Partner Selection Flow:**
```dart
Future<void> _selectPartner() async {
  final partner = await Navigator.push<BusinessAccount>(
    context,
    MaterialPageRoute(
      builder: (context) => PartnershipProposalPage(
        eventData: _getEventData(), // Pre-fill event data
      ),
    ),
  );
  
  if (partner != null) {
    setState(() {
      _selectedPartner = partner;
      // Default 50/50 split
      _revenueSplit = RevenueSplit(
        expertPercentage: 0.5,
        businessPercentage: 0.5,
      );
    });
  }
}
```

---

#### **B. Quick Event Builder Enhancement**

**File:** `lib/presentation/pages/events/quick_event_builder_page.dart`

**Changes:**
1. Add optional "Partner Selection" step (Step 0.5)
2. Auto-fill venue if partner provides venue
3. Show partnership terms in review step

**Implementation:**
```dart
// Add to _QuickEventBuilderPageState:
BusinessAccount? _selectedPartner;
int _currentStep = 0; // Start at 0, partner selection is 0.5

// Modify step flow:
Widget _buildCurrentStep() {
  if (_currentStep == 0.5) {
    return _buildPartnerSelection();
  }
  // ... existing steps
}

Widget _buildPartnerSelection() {
  return PartnershipSelectionStep(
    onPartnerSelected: (partner) {
      setState(() {
        _selectedPartner = partner;
        // Auto-fill venue if partner has location
        if (partner.location != null) {
          _locationController.text = partner.location!;
        }
        _currentStep = 1; // Move to date/time selection
      });
    },
    onSkip: () {
      setState(() {
        _selectedPartner = null;
        _currentStep = 1;
      });
    },
  );
}

// In review step, show partnership info:
if (_selectedPartner != null)
  _buildPartnershipReviewCard(_selectedPartner!),
```

---

#### **C. Event Review Page Enhancement**

**File:** `lib/presentation/pages/events/event_review_page.dart`

**Changes:**
1. Show partnership details if event has partner
2. Show revenue split breakdown
3. Show partner responsibilities

**Implementation:**
```dart
// Add to EventReviewPage props:
final BusinessAccount? partner;
final RevenueSplit? revenueSplit;

// In build method, add partnership section:
if (partner != null) ...[
  const SizedBox(height: 16),
  _buildPartnershipSection(partner, revenueSplit),
],

Widget _buildPartnershipSection(BusinessAccount partner, RevenueSplit? split) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Partnership',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('Partner: ${partner.name}'),
          if (split != null) ...[
            SizedBox(height: 8),
            RevenueSplitDisplay(
              totalRevenue: widget.price != null 
                ? widget.price! * widget.maxAttendees 
                : 0,
              split: split,
              ticketCount: widget.maxAttendees,
              ticketPrice: widget.price ?? 0,
            ),
          ],
        ],
      ),
    ),
  );
}
```

---

### **2. Navigation Integration**

#### **A. Add Routes**

**File:** `lib/presentation/routes/app_router.dart` (or wherever routes are defined)

**New Routes:**
```dart
// Partnership routes
GoRoute(
  path: '/partnerships',
  builder: (context, state) => PartnershipManagementPage(),
),
GoRoute(
  path: '/partnerships/propose',
  builder: (context, state) => PartnershipProposalPage(),
),
GoRoute(
  path: '/partnerships/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return PartnershipDetailsPage(partnershipId: id);
  },
),
GoRoute(
  path: '/partnerships/accept/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return PartnershipAcceptancePage(proposalId: id);
  },
),

// Business routes
GoRoute(
  path: '/business',
  builder: (context, state) => BusinessDashboardPage(),
),
GoRoute(
  path: '/business/setup',
  builder: (context, state) => BusinessSetupPage(),
),
GoRoute(
  path: '/business/verification',
  builder: (context, state) => BusinessVerificationPage(),
),
```

---

#### **B. Add Navigation Links**

**File:** `lib/presentation/pages/profile/profile_page.dart`

**Add to profile menu:**
```dart
// In profile page, add menu items:
if (user.hasBusinessAccount()) ...[
  ListTile(
    leading: Icon(Icons.business),
    title: Text('Business Dashboard'),
    onTap: () => Navigator.pushNamed(context, '/business'),
  ),
],
ListTile(
  leading: Icon(Icons.handshake),
  title: Text('My Partnerships'),
  onTap: () => Navigator.pushNamed(context, '/partnerships'),
),
```

**File:** `lib/presentation/pages/events/my_events_page.dart`

**Add to events page:**
```dart
// In "Hosting" tab, add partnership option:
FloatingActionButton(
  onPressed: () {
    Navigator.pushNamed(context, '/partnerships/propose');
  },
  child: Icon(Icons.handshake),
  tooltip: 'New Partnership',
),
```

---

### **3. Data Flow**

#### **A. Partnership Proposal Flow**

```
User creates event
    ↓
User enables "Create with Partner"
    ↓
Navigate to PartnershipProposalPage
    ↓
User searches/selects business
    ↓
User fills proposal form (type, split, terms)
    ↓
Submit proposal → PartnershipService.createProposal()
    ↓
Business receives notification
    ↓
Business views proposal in dashboard
    ↓
Business accepts/declines
    ↓
If accepted: Event created with partnership
    ↓
Event appears in both user's and business's event lists
```

#### **B. Business Dashboard Flow**

```
Business logs in
    ↓
Navigate to BusinessDashboardPage
    ↓
Load partnership requests → PartnershipService.getRequests()
    ↓
Display requests in list
    ↓
Business clicks request
    ↓
Navigate to PartnershipAcceptancePage
    ↓
Business reviews proposal
    ↓
Business accepts/declines
    ↓
If accepted: PartnershipService.acceptProposal()
    ↓
Event created with partnership
    ↓
Both parties notified
```

---

### **4. Service Integration**

#### **A. Partnership Service Integration**

**File:** `lib/core/services/partnership_service.dart` (Agent 1 will create)

**UI Integration Points:**
```dart
// In PartnershipProposalPage:
final _partnershipService = PartnershipService();

Future<void> _submitProposal() async {
  final proposal = await _partnershipService.createProposal(
    businessId: _selectedBusiness.id,
    expertId: _currentUser.id,
    eventData: _eventData,
    partnershipType: _selectedType,
    revenueSplit: _revenueSplit,
    responsibilities: _selectedResponsibilities,
    customTerms: _customTerms,
  );
  
  // Navigate back or show success
}

// In PartnershipAcceptancePage:
Future<void> _acceptProposal() async {
  final partnership = await _partnershipService.acceptProposal(
    proposalId: _proposal.id,
  );
  
  // Navigate to event or partnership details
}

// In PartnershipManagementPage:
Future<List<EventPartnership>> _loadPartnerships() async {
  return await _partnershipService.getPartnerships(
    userId: _currentUser.id,
    status: _selectedStatus,
  );
}
```

#### **B. Business Service Integration**

**File:** `lib/core/services/business_service.dart` (Agent 1 will create)

**UI Integration Points:**
```dart
// In BusinessSetupPage:
final _businessService = BusinessService();

Future<void> _completeSetup() async {
  final business = await _businessService.createBusinessAccount(
    name: _nameController.text,
    businessType: _selectedType,
    location: _locationController.text,
    // ... other fields
  );
  
  // Navigate to Stripe Connect or verification
}

// In BusinessDashboardPage:
Future<List<PartnershipProposal>> _loadRequests() async {
  return await _businessService.getPartnershipRequests(
    businessId: _business.id,
  );
}
```

---

## 📱 User Flows

### **Flow 1: User Creates Event with Partner**

```
1. User opens Create Event page
2. User toggles "Create with Partner"
3. User navigates to Partnership Proposal page
4. User searches for business
5. User selects business (95% compatibility)
6. User fills proposal form:
   - Type: Venue Provider
   - Split: 50/50
   - Responsibilities: Provide venue, Marketing
7. User submits proposal
8. User returns to Create Event page
9. Partner info pre-filled (venue, etc.)
10. User completes event details
11. User reviews event (shows partnership)
12. User publishes event
13. Business receives partnership request
14. Business accepts
15. Event created with partnership
```

### **Flow 2: Business Manages Partnerships**

```
1. Business opens Business Dashboard
2. Business sees partnership requests (2 pending)
3. Business clicks on request
4. Business views proposal details
5. Business reviews revenue breakdown
6. Business accepts partnership
7. Business returns to dashboard
8. Partnership appears in "Active Partnerships"
9. Business can view partnership details
10. Business can see earnings from partnership
```

### **Flow 3: User Manages Partnerships**

```
1. User opens Profile page
2. User taps "My Partnerships"
3. User sees active partnerships list
4. User clicks on partnership
5. User views partnership details:
   - Events under partnership
   - Revenue earned
   - Partner info
6. User can manage partnership terms
7. User can end partnership (if needed)
```

---

## 🔄 State Management

### **Recommended Approach:**
- Use existing state management (BLoC, Provider, or GetIt)
- Create BLoCs for:
  - `PartnershipBloc` - Partnership state management
  - `BusinessBloc` - Business state management

### **State Classes:**
```dart
// Partnership States
abstract class PartnershipState {}
class PartnershipInitial extends PartnershipState {}
class PartnershipLoading extends PartnershipState {}
class PartnershipLoaded extends PartnershipState {
  final List<EventPartnership> partnerships;
}
class PartnershipError extends PartnershipState {
  final String message;
}

// Business States
abstract class BusinessState {}
class BusinessInitial extends BusinessState {}
class BusinessLoading extends BusinessState {}
class BusinessLoaded extends BusinessState {
  final BusinessAccount business;
  final List<PartnershipProposal> requests;
}
class BusinessError extends BusinessState {
  final String message;
}
```

---

## ✅ Integration Checklist

- [x] Event creation integration points identified
- [x] Navigation routes planned
- [x] Data flow mapped
- [x] Service integration points identified
- [x] User flows documented
- [x] State management approach defined
- [x] Component integration points specified

---

## 🚨 Important Notes

1. **Dependencies:**
   - Agent 1's services must be ready before UI implementation
   - Agent 3's models must be ready for component props

2. **Backward Compatibility:**
   - Event creation must work without partnerships (existing flow)
   - Partnerships are optional enhancement

3. **Error Handling:**
   - All service calls must have error handling
   - Show user-friendly error messages
   - Provide retry options

4. **Loading States:**
   - Show loading indicators for all async operations
   - Use skeleton loaders for lists

5. **Testing:**
   - Test with and without partnerships
   - Test error scenarios
   - Test navigation flows

---

**Status:** ✅ Integration Plan Complete  
**Next Steps:** Implementation (Week 6-8)  
**Dependencies:** 
- Agent 1's services (Week 6-7)
- Agent 3's models (Week 5)

