# Phase 3: Brand Sponsorship UI Designs & Specifications

**Date:** November 23, 2025  
**Agent:** Agent 2 (Frontend & UX Specialist)  
**Week:** Week 9 - UI Design & Preparation  
**Status:** 🎨 Design Complete

---

## 📋 Executive Summary

This document contains UI mockups, component specifications, and integration plans for Phase 3 Brand Sponsorship features:

1. **Brand Discovery UI** - Search and discover events to sponsor
2. **Sponsorship Management UI** - Create, view, and manage sponsorships
3. **Brand Dashboard UI** - Brand account overview, analytics, and ROI tracking

All designs follow existing partnership UI patterns and maintain 100% design token adherence (AppColors/AppTheme).

---

## 🎨 Design Principles

### **Design Token Adherence (100% Required)**
- ✅ **ALWAYS** use `AppColors` or `AppTheme`
- ❌ **NEVER** use direct `Colors.*`
- Follow existing partnership UI patterns
- Maintain consistency with Phase 2 UI

### **Key Design Patterns from Existing UI:**
- **Page Structure:** Scaffold → AppBar → Body (SingleChildScrollView)
- **Card Components:** Rounded corners (12px), elevation 1, padding 16px
- **Color Usage:** AppColors.textPrimary, AppColors.textSecondary, AppTheme.primaryColor
- **Status Badges:** Colored containers with opacity backgrounds
- **Button Styles:** ElevatedButton (primary), OutlinedButton (secondary)
- **Spacing:** Consistent 8px, 12px, 16px, 20px padding/margins

---

## 1. Brand Discovery UI

### **1.1 Brand Discovery Page - Main Search**

**File:** `lib/presentation/pages/brand/brand_discovery_page.dart`

**Purpose:** Allow brands to search for events to sponsor with vibe-based matching.

**Mockup:**
```
┌─────────────────────────────────────────────────────────────┐
│  🔍 Discover Events to Sponsor                    [Profile] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Find events that align with your brand                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🔍 Search events, categories, locations...          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Filters:                                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 📍 Location: [Brooklyn ▼]                            │   │
│  │ 📅 Date: [Next 30 Days ▼]                           │   │
│  │ 🏷️  Category: [Food & Dining ▼]                     │   │
│  │ 👥 Attendees: [20] ─────○────── [100]               │   │
│  │ 💰 Budget: [$100] ───○───────── [$5,000]           │   │
│  │ 📱 Influencer: [10K+ followers]                     │   │
│  │                                                       │   │
│  │ [Clear Filters] [Apply Filters]                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  🌟 Recommended for Your Brand (5)                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⭐ 98% Match                                          │   │
│  │                                                       │   │
│  │ 🍽️ Farm-to-Table Dinner Experience                   │   │
│  │ By @foodie_sarah (52K followers)                     │   │
│  │                                                       │   │
│  │ 📍 The Garden Restaurant, Brooklyn                   │   │
│  │ 📅 Dec 15, 2025 • 7:00 PM                            │   │
│  │ 👥 25 attendees • $75/ticket                          │   │
│  │                                                       │   │
│  │ 🎯 Seeking: Product Sponsor (Olive Oil)             │   │
│  │ 💰 Budget: $500-1,000 or product                      │   │
│  │                                                       │   │
│  │ Match Score: 98% ⭐                                   │   │
│  │ • Your product fits perfectly                         │   │
│  │ • Audience demographic match                          │   │
│  │ • Host's content aligns with brand                   │   │
│  │                                                       │   │
│  │ [View Details] [Propose Sponsorship]                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⭐ 87% Match                                          │   │
│  │ ... (more event cards)                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Component Specifications:**

```dart
class BrandDiscoveryPage extends StatefulWidget {
  const BrandDiscoveryPage({super.key});

  @override
  State<BrandDiscoveryPage> createState() => _BrandDiscoveryPageState();
}

class _BrandDiscoveryPageState extends State<BrandDiscoveryPage> {
  // State management
  String _searchQuery = '';
  BrandDiscoveryFilters _filters = BrandDiscoveryFilters();
  List<SponsorableEvent> _recommendedEvents = [];
  List<SponsorableEvent> _searchResults = [];
  bool _isLoading = false;
  
  // Services
  final _brandDiscoveryService = GetIt.instance<BrandDiscoveryService>();
  final _brandAccountService = GetIt.instance<BrandAccountService>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Discover Events to Sponsor',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            
            // Filters
            _buildFilters(),
            
            // Recommended Events
            _buildRecommendedSection(),
            
            // Search Results
            if (_searchQuery.isNotEmpty) _buildSearchResults(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search events, categories, locations...',
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.grey100,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _performSearch();
        },
      ),
    );
  }
  
  Widget _buildFilters() {
    return ExpansionTile(
      title: Text('Filters', style: TextStyle(color: AppColors.textPrimary)),
      children: [
        // Location filter
        _buildLocationFilter(),
        // Date range filter
        _buildDateFilter(),
        // Category filter
        _buildCategoryFilter(),
        // Attendee range filter
        _buildAttendeeFilter(),
        // Budget range filter
        _buildBudgetFilter(),
        // Influencer size filter
        _buildInfluencerFilter(),
        
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '🌟 Recommended for Your Brand',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ..._recommendedEvents.map((event) => 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SponsorableEventCard(
              event: event,
              onTap: () => _viewEventDetails(event),
              onPropose: () => _proposeSponsorship(event),
            ),
          ),
        ),
      ],
    );
  }
}
```

**Key Features:**
- Search bar for event discovery
- Advanced filters (location, date, category, attendees, budget, influencer size)
- AI-powered recommendations (70%+ vibe match)
- Compatibility score display
- Quick action buttons (View Details, Propose Sponsorship)

---

### **1.2 Sponsorable Event Card Component**

**File:** `lib/presentation/widgets/brand/sponsorable_event_card.dart`

**Purpose:** Display event information with sponsorship opportunities and compatibility score.

**Mockup:**
```
┌─────────────────────────────────────────────────────┐
│  ⭐ 98% Match                                        │
│                                                      │
│  🍽️ Farm-to-Table Dinner Experience                 │
│  By @foodie_sarah (52K followers)                    │
│                                                      │
│  📍 The Garden Restaurant, Brooklyn                  │
│  📅 Dec 15, 2025 • 7:00 PM                          │
│  👥 25 attendees • $75/ticket                        │
│                                                      │
│  🎯 Seeking: Product Sponsor (Olive Oil)            │
│  💰 Budget: $500-1,000 or product                    │
│                                                      │
│  Match Score: 98% ⭐                                 │
│  • Your product fits perfectly                      │
│  • Audience demographic match                       │
│  • Host's content aligns with brand                 │
│                                                      │
│  [View Details] [Propose Sponsorship]               │
└─────────────────────────────────────────────────────┘
```

**Component Specifications:**

```dart
class SponsorableEventCard extends StatelessWidget {
  final SponsorableEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onPropose;
  
  const SponsorableEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onPropose,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compatibility Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CompatibilityBadge(
                    compatibility: event.vibeCompatibility,
                  ),
                  if (event.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.electricGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 16, color: AppColors.electricGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.electricGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Event Title
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Host Info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'By ${event.hostName} (${event.hostFollowers}K followers)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Event Details
              _buildEventDetail(Icons.location_on, event.location),
              const SizedBox(height: 4),
              _buildEventDetail(Icons.calendar_today, _formatDate(event.date)),
              const SizedBox(height: 4),
              _buildEventDetail(Icons.people, '${event.attendeeCount} attendees • \$${event.ticketPrice}/ticket'),
              
              const SizedBox(height: 12),
              
              // Sponsorship Opportunity
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Seeking: ${event.sponsorshipType}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Budget: ${event.budgetRange}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Compatibility Details
              if (event.vibeCompatibility >= 0.70) ...[
                Text(
                  'Match Score: ${(event.vibeCompatibility * 100).toStringAsFixed(0)}% ⭐',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.electricGreen,
                  ),
                ),
                const SizedBox(height: 4),
                ...event.compatibilityReasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.electricGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.grey300),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPropose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Propose Sponsorship'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEventDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }
}
```

---

### **1.3 Event Details for Brands**

**File:** `lib/presentation/pages/brand/sponsorable_event_details_page.dart`

**Purpose:** Detailed view of an event with full sponsorship information.

**Key Sections:**
- Event overview
- Host profile
- Audience demographics
- Sponsorship opportunities
- Expected ROI
- Compatibility breakdown
- Propose sponsorship CTA

---

## 2. Sponsorship Management UI

### **2.1 Sponsorship Management Page**

**File:** `lib/presentation/pages/brand/sponsorship_management_page.dart`

**Purpose:** View, create, and manage sponsorship proposals and agreements.

**Mockup:**
```
┌─────────────────────────────────────────────────────────────┐
│  🤝 Sponsorship Management                      [Profile]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Active] [Pending] [Completed]                            │
│                                                             │
│  Active Sponsorships (3)                                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ✅ Confirmed                                        │   │
│  │                                                      │   │
│  │ 🍽️ Farm-to-Table Dinner (Dec 20)                   │   │
│  │                                                      │   │
│  │ Your Contribution:                                  │   │
│  │ ├─ Cash: $300 (Paid ✅)                             │   │
│  │ └─ Product: 20 bottles (Shipped ✅)                 │   │
│  │                                                      │   │
│  │ Expected Returns:                                    │   │
│  │ ├─ Revenue: ~$225                                   │   │
│  │ ├─ Reach: 52K                                       │   │
│  │ └─ Samples: 25 people                              │   │
│  │                                                      │   │
│  │ [View Event] [Track Products]                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⏳ Pending Approval                                  │   │
│  │ ... (pending sponsorship card)                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [➕ Create New Sponsorship Proposal]                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Component Specifications:**

```dart
class SponsorshipManagementPage extends StatefulWidget {
  const SponsorshipManagementPage({super.key});

  @override
  State<SponsorshipManagementPage> createState() => _SponsorshipManagementPageState();
}

class _SponsorshipManagementPageState extends State<SponsorshipManagementPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _sponsorshipService = GetIt.instance<SponsorshipService>();
  
  List<Sponsorship> _activeSponsorships = [];
  List<Sponsorship> _pendingSponsorships = [];
  List<Sponsorship> _completedSponsorships = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSponsorships();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sponsorship Management',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSponsorshipsList(_activeSponsorships),
                _buildSponsorshipsList(_pendingSponsorships),
                _buildSponsorshipsList(_completedSponsorships),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewSponsorship,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Sponsorship'),
      ),
    );
  }
  
  Widget _buildSponsorshipsList(List<Sponsorship> sponsorships) {
    if (sponsorships.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sponsorships.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SponsorshipCard(
            sponsorship: sponsorships[index],
            onTap: () => _viewSponsorshipDetails(sponsorships[index]),
            onManage: () => _manageSponsorship(sponsorships[index]),
          ),
        );
      },
    );
  }
}
```

---

### **2.2 Sponsorship Card Component**

**File:** `lib/presentation/widgets/brand/sponsorship_card.dart`

**Purpose:** Display sponsorship information in list views.

**Component Specifications:**

```dart
class SponsorshipCard extends StatelessWidget {
  final Sponsorship sponsorship;
  final VoidCallback? onTap;
  final VoidCallback? onManage;
  
  const SponsorshipCard({
    super.key,
    required this.sponsorship,
    this.onTap,
    this.onManage,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              _buildStatusBadge(),
              
              const SizedBox(height: 12),
              
              // Event Title
              Text(
                sponsorship.event.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Event Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(sponsorship.event.startTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Contribution Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Contribution:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (sponsorship.cashContribution != null)
                      _buildContributionRow(
                        Icons.account_balance_wallet,
                        'Cash: \$${sponsorship.cashContribution!.amount.toStringAsFixed(0)}',
                        sponsorship.cashContribution!.status,
                      ),
                    if (sponsorship.productContribution != null) ...[
                      const SizedBox(height: 4),
                      _buildContributionRow(
                        Icons.inventory_2,
                        'Product: ${sponsorship.productContribution!.quantity} ${sponsorship.productContribution!.productName}',
                        sponsorship.productContribution!.status,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Expected Returns
              if (sponsorship.status == SponsorshipStatus.confirmed ||
                  sponsorship.status == SponsorshipStatus.active) ...[
                Text(
                  'Expected Returns:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReturnRow(Icons.account_balance_wallet, 'Revenue: ~\$${sponsorship.expectedRevenue.toStringAsFixed(0)}'),
                _buildReturnRow(Icons.people, 'Reach: ${sponsorship.expectedReach}K'),
                _buildReturnRow(Icons.shopping_bag, 'Samples: ${sponsorship.expectedSamples} people'),
                const SizedBox(height: 12),
              ],
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.grey300),
                      ),
                      child: const Text('View Event'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onManage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Manage'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge() {
    // Similar to PartnershipCard status badge
    // Uses AppColors based on status
  }
  
  Widget _buildContributionRow(IconData icon, String text, ContributionStatus status) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _buildStatusIcon(status),
      ],
    );
  }
  
  Widget _buildReturnRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### **2.3 Create Sponsorship Proposal Page**

**File:** `lib/presentation/pages/brand/create_sponsorship_proposal_page.dart`

**Purpose:** Create a new sponsorship proposal for an event.

**Key Sections:**
- Event selection/search
- Contribution type selection (Financial, Product, Hybrid)
- Contribution details form
- Sponsorship tier selection
- Branding preferences
- Message to hosts
- Review and submit

---

## 3. Brand Dashboard UI

### **3.1 Brand Dashboard Page**

**File:** `lib/presentation/pages/brand/brand_dashboard_page.dart`

**Purpose:** Brand account overview with active sponsorships, analytics, and ROI tracking.

**Mockup:**
```
┌─────────────────────────────────────────────────────────────┐
│  💼 Brand Dashboard                              [Settings] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Premium Olive Oil Company                                  │
│  [Logo]                                                     │
│  ✅ Verified Brand                                          │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │ Total Investment      │  │ Total Returns       │        │
│  │ $3,200                │  │ $1,847              │        │
│  └──────────────────────┘  └──────────────────────┘        │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────┐        │
│  │ Active Sponsorships  │  │ ROI                 │        │
│  │ 3                     │  │ 387%                │        │
│  └──────────────────────┘  └──────────────────────┘        │
│                                                             │
│  [Active Sponsorships] [Analytics] [ROI Tracking]          │
│                                                             │
│  Active Sponsorships (3)                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ... (sponsorship cards)                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  📊 Q4 2025 Performance                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Total Investment: $3,200                            │   │
│  │ ├─ Cash: $2,000                                     │   │
│  │ └─ Products: $1,200 (cost)                          │   │
│  │                                                      │   │
│  │ Returns:                                            │   │
│  │ ├─ Direct Revenue: $1,847                           │   │
│  │ ├─ Brand Reach: 340K impressions                   │   │
│  │ ├─ Product Sampling: 187 people                     │   │
│  │ └─ Estimated Brand Value: $12,400                   │   │
│  │                                                      │   │
│  │ ROI: 387% (direct) / 1,200%+ (total)               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Component Specifications:**

```dart
class BrandDashboardPage extends StatefulWidget {
  const BrandDashboardPage({super.key});

  @override
  State<BrandDashboardPage> createState() => _BrandDashboardPageState();
}

class _BrandDashboardPageState extends State<BrandDashboardPage> {
  final _brandAccountService = GetIt.instance<BrandAccountService>();
  final _brandAnalyticsService = GetIt.instance<BrandAnalyticsService>();
  final _sponsorshipService = GetIt.instance<SponsorshipService>();
  
  BrandAccount? _brandAccount;
  BrandAnalytics? _analytics;
  List<Sponsorship> _activeSponsorships = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Brand Dashboard',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Header
                  _buildBrandHeader(),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Stats
                  _buildQuickStats(),
                  
                  const SizedBox(height: 20),
                  
                  // Tab Navigation
                  _buildTabNavigation(),
                  
                  // Tab Content
                  _buildTabContent(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_brandAccount?.logoUrl != null)
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(_brandAccount!.logoUrl!),
                )
              else
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.business,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _brandAccount?.name ?? 'Brand Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_brandAccount?.isVerified ?? false)
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.electricGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Brand',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.electricGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: BrandStatsCard(
              label: 'Total Investment',
              value: '\$${_analytics?.totalInvestment.toStringAsFixed(0) ?? '0'}',
              icon: Icons.account_balance_wallet,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BrandStatsCard(
              label: 'Total Returns',
              value: '\$${_analytics?.totalReturns.toStringAsFixed(0) ?? '0'}',
              icon: Icons.trending_up,
              color: AppColors.electricGreen,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabNavigation() {
    // Tab bar for Active Sponsorships, Analytics, ROI Tracking
    // Similar to PartnershipManagementPage tabs
  }
  
  Widget _buildTabContent() {
    // Content based on selected tab
    // Active Sponsorships list
    // Analytics dashboard
    // ROI tracking charts
  }
}
```

---

### **3.2 Brand Analytics Dashboard**

**File:** `lib/presentation/pages/brand/brand_analytics_page.dart`

**Purpose:** Detailed analytics and performance metrics for brand sponsorships.

**Key Sections:**
- Performance overview
- ROI breakdown
- Brand exposure metrics
- Event performance tracking
- Top performing events
- Export reports

---

### **3.3 ROI Tracking Dashboard**

**File:** `lib/presentation/pages/brand/roi_tracking_page.dart`

**Purpose:** Detailed ROI tracking and financial analysis.

**Key Sections:**
- Investment vs. returns
- Revenue attribution
- Brand value estimation
- Campaign performance
- Time-based trends
- Comparison charts

---

## 4. UI Component Specifications

### **4.1 Shared Components**

#### **CompatibilityBadge**
- **File:** `lib/presentation/widgets/brand/compatibility_badge.dart`
- **Purpose:** Display vibe compatibility score (70%+ threshold)
- **Design:** Colored badge with percentage and star icon
- **Colors:** Green for 70%+, yellow for 60-70%, grey for <60%

#### **BrandStatsCard**
- **File:** `lib/presentation/widgets/brand/brand_stats_card.dart`
- **Purpose:** Display key metrics in dashboard
- **Design:** Card with icon, label, and value
- **Pattern:** Similar to BusinessStatsCard

#### **SponsorshipStatusBadge**
- **File:** `lib/presentation/widgets/brand/sponsorship_status_badge.dart`
- **Purpose:** Display sponsorship status
- **Design:** Colored badge with status text
- **Statuses:** Confirmed, Pending, Active, Completed, Cancelled

---

## 5. UI Integration Plan

### **5.1 Navigation Integration**

**Add to App Router:**
```dart
// In lib/presentation/routes/app_router.dart

GoRoute(
  path: '/brand/discovery',
  builder: (context, state) => const BrandDiscoveryPage(),
),

GoRoute(
  path: '/brand/sponsorships',
  builder: (context, state) => const SponsorshipManagementPage(),
),

GoRoute(
  path: '/brand/dashboard',
  builder: (context, state) => const BrandDashboardPage(),
),

GoRoute(
  path: '/brand/sponsorship/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return SponsorshipDetailsPage(sponsorshipId: id);
  },
),
```

### **5.2 Integration with Partnership System**

**Shared Components:**
- Reuse `CompatibilityBadge` from partnerships
- Reuse `RevenueSplitDisplay` for sponsorship revenue
- Reuse payment flow components

**Data Integration:**
- Brand models extend partnership models
- Sponsorship service integrates with partnership service
- Revenue split service handles N-way brand sponsorships

### **5.3 User Role Detection**

**Brand Account Detection:**
```dart
// Check if user has brand account
final brandAccount = await _brandAccountService.getBrandAccount(userId);
if (brandAccount != null) {
  // Show brand navigation
  // Show brand dashboard access
}
```

**Navigation Menu:**
- Add "Brand Dashboard" to main navigation for brand accounts
- Add "Discover Events" to brand menu
- Add "My Sponsorships" to brand menu

---

## 6. Design Token Usage Reference

### **Colors:**
```dart
// Backgrounds
backgroundColor: AppColors.background
backgroundColor: AppColors.surface
backgroundColor: AppColors.grey100

// Text
color: AppColors.textPrimary
color: AppColors.textSecondary
color: AppColors.textHint

// Accents
color: AppTheme.primaryColor
color: AppColors.electricGreen

// Status
color: AppColors.electricGreen  // Success/Active
color: AppColors.warning         // Pending
color: AppColors.error           // Cancelled/Error
```

### **Typography:**
```dart
// Headings
fontSize: 24, fontWeight: FontWeight.bold
fontSize: 20, fontWeight: FontWeight.bold
fontSize: 18, fontWeight: FontWeight.bold

// Body
fontSize: 16, fontWeight: FontWeight.normal
fontSize: 14, fontWeight: FontWeight.normal
fontSize: 12, fontWeight: FontWeight.normal
```

### **Spacing:**
```dart
// Padding/Margins
padding: EdgeInsets.all(20)      // Page padding
padding: EdgeInsets.all(16)      // Card padding
padding: EdgeInsets.all(12)      // Section padding
padding: EdgeInsets.all(8)       // Small spacing

// Gaps
SizedBox(height: 20)             // Section gap
SizedBox(height: 12)            // Medium gap
SizedBox(height: 8)              // Small gap
```

---

## 7. Implementation Checklist

### **Week 9 Deliverables:**
- [x] Brand Discovery UI mockups
- [x] Sponsorship Management UI mockups
- [x] Brand Dashboard UI mockups
- [x] UI component specifications
- [x] UI integration plan

### **Week 10 Tasks:**
- [ ] Review Agent 3's Brand models
- [ ] Finalize UI designs based on models
- [ ] Create detailed component specifications
- [ ] Plan UI integration with partnership system

### **Week 11 Tasks:**
- [ ] Create payment UI components
- [ ] Create analytics UI components
- [ ] Integrate with payment/analytics services

### **Week 12 Tasks:**
- [ ] Implement Brand Discovery UI
- [ ] Implement Sponsorship Management UI
- [ ] Implement Brand Dashboard UI
- [ ] Create UI tests
- [ ] Integration testing

---

## 8. Next Steps

1. **Review with Agent 3:** Ensure UI designs align with Brand models
2. **Review with Agent 1:** Ensure UI integrates with services
3. **Finalize Designs:** Make adjustments based on model/service review
4. **Begin Implementation:** Start with Brand Discovery UI (Week 12)

---

**Status:** ✅ Design Complete  
**Next:** Review with Agent 3 (Brand models) and Agent 1 (Services)  
**Last Updated:** November 23, 2025

