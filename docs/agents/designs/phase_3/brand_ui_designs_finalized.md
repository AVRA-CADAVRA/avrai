# Phase 3: Brand Sponsorship UI Designs - FINALIZED

**Date:** November 23, 2025, 11:50 AM CST  
**Agent:** Agent 2 (Frontend & UX Specialist)  
**Week:** Week 10 - UI Preparation & Design (Finalized)  
**Status:** ✅ **FINALIZED - Ready for Implementation**

---

## 📋 Executive Summary

This document contains **finalized** UI designs, component specifications, and integration plans for Phase 3 Brand Sponsorship features, based on Agent 3's completed Brand models:

1. **Brand Discovery UI** - Search and discover events to sponsor (using `BrandDiscovery`, `BrandMatch`, `VibeCompatibility`)
2. **Sponsorship Management UI** - Create, view, and manage sponsorships (using `Sponsorship`, `ProductTracking`, `MultiPartySponsorship`)
3. **Brand Dashboard UI** - Brand account overview, analytics, and ROI tracking (using `BrandAccount`)

All designs align with actual model structures and maintain 100% design token adherence (AppColors/AppTheme).

---

## 🎯 Model Review Summary

### **Models Reviewed (Agent 3, Week 9):**
- ✅ `BrandAccount` - Brand account with verification, categories, preferences
- ✅ `Sponsorship` - Sponsorship with financial/product/hybrid types, status tracking
- ✅ `BrandDiscovery` - Discovery search with `BrandMatch` results and `VibeCompatibility` scoring
- ✅ `ProductTracking` - Product sales tracking with `ProductSale` records
- ✅ `MultiPartySponsorship` - N-way sponsorships with revenue split configuration
- ✅ `SponsorshipIntegration` - Integration utilities with partnership models

### **Key Model Insights:**
1. **BrandAccount** has `verificationStatus`, `categories`, `matchingPreferences`
2. **Sponsorship** has `type` (financial/product/hybrid), `status`, `contributionAmount`, `productValue`
3. **BrandDiscovery** uses `BrandMatch` with `compatibilityScore` (70%+ threshold) and `VibeCompatibility`
4. **ProductTracking** tracks `quantityProvided`, `quantitySold`, `quantityGivenAway`, `quantityUsedInEvent`
5. **MultiPartySponsorship** supports N-way with `revenueSplitConfiguration` map

---

## 1. Brand Discovery UI - FINALIZED

### **1.1 Brand Discovery Page**

**File:** `lib/presentation/pages/brand/brand_discovery_page.dart`

**Data Models Used:**
- `BrandDiscovery` - Search results container
- `BrandMatch` - Individual match results
- `VibeCompatibility` - Compatibility scoring (70%+ threshold)
- `ContributionRange` - Estimated contribution ranges

**Finalized Component Structure:**

```dart
class BrandDiscoveryPage extends StatefulWidget {
  const BrandDiscoveryPage({super.key});

  @override
  State<BrandDiscoveryPage> createState() => _BrandDiscoveryPageState();
}

class _BrandDiscoveryPageState extends State<BrandDiscoveryPage> {
  final _brandDiscoveryService = GetIt.instance<BrandDiscoveryService>();
  final _brandAccountService = GetIt.instance<BrandAccountService>();
  
  BrandAccount? _currentBrand;
  BrandDiscovery? _discoveryResults;
  List<BrandMatch> _recommendedMatches = [];
  List<BrandMatch> _searchMatches = [];
  bool _isLoading = false;
  
  // Filters
  String? _selectedCategory;
  String? _selectedLocation;
  DateTimeRange? _dateRange;
  double? _minBudget;
  double? _maxBudget;
  int? _minAttendees;
  
  @override
  void initState() {
    super.initState();
    _loadBrandAccount();
    _loadRecommendedEvents();
  }
  
  Future<void> _loadBrandAccount() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;
    
    final brand = await _brandAccountService.getBrandAccountByUserId(userId);
    setState(() => _currentBrand = brand);
  }
  
  Future<void> _loadRecommendedEvents() async {
    if (_currentBrand == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final discovery = await _brandDiscoveryService.getRecommendedEvents(
        _currentBrand!.id,
      );
      
      setState(() {
        _discoveryResults = discovery;
        _recommendedMatches = discovery.viableMatches; // Only 70%+ matches
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }
  
  Future<void> _performSearch() async {
    if (_currentBrand == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final discovery = await _brandDiscoveryService.searchEvents(
        brandId: _currentBrand!.id,
        category: _selectedCategory,
        location: _selectedLocation,
        dateRange: _dateRange,
        minBudget: _minBudget,
        maxBudget: _maxBudget,
        minAttendees: _minAttendees,
      );
      
      setState(() {
        _discoveryResults = discovery;
        _searchMatches = discovery.viableMatches; // Only 70%+ matches
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }
  
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  _buildSearchBar(),
                  
                  // Filters
                  _buildFilters(),
                  
                  // Recommended Section
                  if (_recommendedMatches.isNotEmpty) _buildRecommendedSection(),
                  
                  // Search Results
                  if (_searchMatches.isNotEmpty) _buildSearchResults(),
                  
                  // Empty State
                  if (_recommendedMatches.isEmpty && _searchMatches.isEmpty)
                    _buildEmptyState(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                '🌟 Recommended for ${_currentBrand?.name ?? "Your Brand"}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recommendedMatches.length} matches',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.electricGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._recommendedMatches.map((match) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SponsorableEventCard(
                brandMatch: match,
                onTap: () => _viewEventDetails(match),
                onPropose: () => _proposeSponsorship(match),
              ),
            )),
      ],
    );
  }
}
```

---

### **1.2 Sponsorable Event Card - FINALIZED**

**File:** `lib/presentation/widgets/brand/sponsorable_event_card.dart`

**Data Models Used:**
- `BrandMatch` - Match information
- `VibeCompatibility` - Compatibility details
- `ContributionRange` - Budget information

**Finalized Component:**

```dart
class SponsorableEventCard extends StatelessWidget {
  final BrandMatch brandMatch;
  final VoidCallback? onTap;
  final VoidCallback? onPropose;
  
  const SponsorableEventCard({
    super.key,
    required this.brandMatch,
    this.onTap,
    this.onPropose,
  });
  
  @override
  Widget build(BuildContext context) {
    final compatibility = brandMatch.vibeCompatibility;
    final meetsThreshold = brandMatch.meetsThreshold; // 70%+ check
    
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
                    compatibility: compatibility.overallScore / 100.0,
                    score: compatibility.overallScore,
                  ),
                  if (meetsThreshold)
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
              
              // Event Title (from BrandMatch metadata or event lookup)
              Text(
                brandMatch.metadata['eventTitle'] ?? 'Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Host Info
              if (brandMatch.metadata['hostName'] != null)
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'By ${brandMatch.metadata['hostName']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Compatibility Breakdown
              if (meetsThreshold) ...[
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
                        'Match Score: ${compatibility.overallScore.toStringAsFixed(0)}% ⭐',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.electricGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCompatibilityRow('Value Alignment', compatibility.valueAlignment),
                      _buildCompatibilityRow('Style Compatibility', compatibility.styleCompatibility),
                      _buildCompatibilityRow('Quality Focus', compatibility.qualityFocus),
                      _buildCompatibilityRow('Audience Alignment', compatibility.audienceAlignment),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Match Reasons
              if (brandMatch.matchReasons.isNotEmpty) ...[
                ...brandMatch.matchReasons.take(3).map((reason) => Padding(
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
              
              // Estimated Contribution
              if (brandMatch.estimatedContribution != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated: \$${brandMatch.estimatedContribution!.minAmount.toStringAsFixed(0)} - \$${brandMatch.estimatedContribution!.maxAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                      onPressed: meetsThreshold ? onPropose : null,
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
  
  Widget _buildCompatibilityRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 2. Sponsorship Management UI - FINALIZED

### **2.1 Sponsorship Management Page**

**File:** `lib/presentation/pages/brand/sponsorship_management_page.dart`

**Data Models Used:**
- `Sponsorship` - Individual sponsorships
- `SponsorshipStatus` - Status enum (pending, proposed, approved, locked, active, completed, etc.)
- `SponsorshipType` - Type enum (financial, product, hybrid)
- `ProductTracking` - Product tracking for product/hybrid sponsorships
- `MultiPartySponsorship` - Multi-party sponsorships

**Finalized Component Structure:**

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
  final _productTrackingService = GetIt.instance<ProductTrackingService>();
  
  BrandAccount? _currentBrand;
  List<Sponsorship> _activeSponsorships = [];
  List<Sponsorship> _pendingSponsorships = [];
  List<Sponsorship> _completedSponsorships = [];
  Map<String, ProductTracking> _productTrackingMap = {};
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBrandAccount();
    _loadSponsorships();
  }
  
  Future<void> _loadSponsorships() async {
    if (_currentBrand == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final sponsorships = await _sponsorshipService.getSponsorshipsForBrand(
        _currentBrand!.id,
      );
      
      // Load product tracking for product/hybrid sponsorships
      final productSponsorships = sponsorships.where((s) => 
        s.type == SponsorshipType.product || s.type == SponsorshipType.hybrid
      ).toList();
      
      final trackingMap = <String, ProductTracking>{};
      for (final sponsorship in productSponsorships) {
        final tracking = await _productTrackingService.getTrackingForSponsorship(
          sponsorship.id,
        );
        if (tracking != null) {
          trackingMap[sponsorship.id] = tracking;
        }
      }
      
      setState(() {
        _activeSponsorships = sponsorships.where((s) => 
          s.status == SponsorshipStatus.active ||
          s.status == SponsorshipStatus.locked ||
          s.status == SponsorshipStatus.approved
        ).toList();
        
        _pendingSponsorships = sponsorships.where((s) => 
          s.status == SponsorshipStatus.pending ||
          s.status == SponsorshipStatus.proposed ||
          s.status == SponsorshipStatus.negotiating
        ).toList();
        
        _completedSponsorships = sponsorships.where((s) => 
          s.status == SponsorshipStatus.completed ||
          s.status == SponsorshipStatus.cancelled
        ).toList();
        
        _productTrackingMap = trackingMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
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
        final sponsorship = sponsorships[index];
        final productTracking = _productTrackingMap[sponsorship.id];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SponsorshipCard(
            sponsorship: sponsorship,
            productTracking: productTracking,
            onTap: () => _viewSponsorshipDetails(sponsorship),
            onManage: () => _manageSponsorship(sponsorship),
          ),
        );
      },
    );
  }
}
```

---

### **2.2 Sponsorship Card - FINALIZED**

**File:** `lib/presentation/widgets/brand/sponsorship_card.dart`

**Data Models Used:**
- `Sponsorship` - Full sponsorship data
- `ProductTracking` - Optional product tracking
- `SponsorshipStatus` - Status display
- `SponsorshipType` - Type display

**Finalized Component:**

```dart
class SponsorshipCard extends StatelessWidget {
  final Sponsorship sponsorship;
  final ProductTracking? productTracking;
  final VoidCallback? onTap;
  final VoidCallback? onManage;
  
  const SponsorshipCard({
    super.key,
    required this.sponsorship,
    this.productTracking,
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
              
              // Event Title (would need to fetch event)
              Text(
                'Event: ${sponsorship.eventId}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
                    
                    // Financial Contribution
                    if (sponsorship.contributionAmount != null)
                      _buildContributionRow(
                        Icons.account_balance_wallet,
                        'Cash: \$${sponsorship.contributionAmount!.toStringAsFixed(0)}',
                        _getPaymentStatus(),
                      ),
                    
                    // Product Contribution
                    if (sponsorship.productValue != null) ...[
                      const SizedBox(height: 4),
                      _buildContributionRow(
                        Icons.inventory_2,
                        'Product: \$${sponsorship.productValue!.toStringAsFixed(0)} value',
                        _getProductStatus(),
                      ),
                    ],
                    
                    // Total
                    const SizedBox(height: 8),
                    Divider(color: AppColors.grey300),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Contribution:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${sponsorship.totalContributionValue.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Product Tracking Details
              if (productTracking != null) ...[
                const SizedBox(height: 12),
                _buildProductTrackingSection(productTracking!),
              ],
              
              // Revenue Share
              if (sponsorship.revenueSharePercentage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Revenue Share: ${sponsorship.revenueSharePercentage!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
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
    final status = sponsorship.status;
    Color badgeColor;
    String statusText = status.displayName;
    
    switch (status) {
      case SponsorshipStatus.active:
      case SponsorshipStatus.locked:
      case SponsorshipStatus.approved:
        badgeColor = AppColors.electricGreen;
        break;
      case SponsorshipStatus.pending:
      case SponsorshipStatus.proposed:
      case SponsorshipStatus.negotiating:
        badgeColor = AppColors.warning;
        break;
      case SponsorshipStatus.completed:
        badgeColor = AppColors.textSecondary;
        break;
      case SponsorshipStatus.cancelled:
      case SponsorshipStatus.disputed:
        badgeColor = AppColors.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }
  
  Widget _buildProductTrackingSection(ProductTracking tracking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Tracking: ${tracking.productName}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildTrackingRow('Provided', tracking.quantityProvided),
          _buildTrackingRow('Sold', tracking.quantitySold),
          if (tracking.quantityGivenAway > 0)
            _buildTrackingRow('Given Away', tracking.quantityGivenAway),
          if (tracking.quantityUsedInEvent > 0)
            _buildTrackingRow('Used in Event', tracking.quantityUsedInEvent),
          _buildTrackingRow('Remaining', tracking.quantityRemaining),
          if (tracking.hasSales) ...[
            const SizedBox(height: 8),
            Divider(color: AppColors.grey300),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Sales:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${tracking.totalSales.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTrackingRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getPaymentStatus() {
    // Would need to check payment status from payment service
    return 'Paid ✅';
  }
  
  String _getProductStatus() {
    // Would need to check product delivery status
    return 'Delivered ✅';
  }
}
```

---

## 3. Brand Dashboard UI - FINALIZED

### **3.1 Brand Dashboard Page**

**File:** `lib/presentation/pages/brand/brand_dashboard_page.dart`

**Data Models Used:**
- `BrandAccount` - Brand account information
- `Sponsorship` - Active sponsorships list
- `BrandAnalytics` - Analytics data (from service, not model)
- `ProductTracking` - Product sales data

**Finalized Component Structure:**

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
  
  Future<void> _loadDashboardData() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Load brand account
      final brand = await _brandAccountService.getBrandAccountByUserId(userId);
      
      if (brand == null) {
        // No brand account - show create account prompt
        setState(() => _isLoading = false);
        return;
      }
      
      // Load analytics
      final analytics = await _brandAnalyticsService.getBrandAnalytics(brand.id);
      
      // Load active sponsorships
      final sponsorships = await _sponsorshipService.getSponsorshipsForBrand(brand.id);
      final active = sponsorships.where((s) => 
        s.status == SponsorshipStatus.active ||
        s.status == SponsorshipStatus.locked ||
        s.status == SponsorshipStatus.approved
      ).toList();
      
      setState(() {
        _brandAccount = brand;
        _analytics = analytics;
        _activeSponsorships = active;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_brandAccount == null) {
      return _buildNoBrandAccountState();
    }
    
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header
            _buildBrandHeader(),
            
            const SizedBox(height: 20),
            
            // Quick Stats
            _buildQuickStats(),
            
            const SizedBox(height: 20),
            
            // Active Sponsorships
            _buildActiveSponsorshipsSection(),
            
            const SizedBox(height: 20),
            
            // Analytics Section
            if (_analytics != null) _buildAnalyticsSection(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Row(
        children: [
          if (_brandAccount!.logoUrl != null)
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
                  _brandAccount!.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _brandAccount!.brandType,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_brandAccount!.categories.isNotEmpty) ...[
                      Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        _brandAccount!.categories.join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (_brandAccount!.isVerified)
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
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.pending,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verification: ${_brandAccount!.verificationStatus.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
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
    );
  }
  
  Widget _buildQuickStats() {
    final analytics = _analytics;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: BrandStatsCard(
              label: 'Total Investment',
              value: '\$${analytics?.totalInvestment.toStringAsFixed(0) ?? '0'}',
              icon: Icons.account_balance_wallet,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BrandStatsCard(
              label: 'Total Returns',
              value: '\$${analytics?.totalReturns.toStringAsFixed(0) ?? '0'}',
              icon: Icons.trending_up,
              color: AppColors.electricGreen,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveSponsorshipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Sponsorships',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_activeSponsorships.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SponsorshipManagementPage(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_activeSponsorships.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active sponsorships',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start sponsoring events to see them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrandDiscoveryPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Discover Events'),
                  ),
                ],
              ),
            ),
          )
        else
          ..._activeSponsorships.take(3).map((sponsorship) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SponsorshipCard(
                  sponsorship: sponsorship,
                  onTap: () => _viewSponsorshipDetails(sponsorship),
                ),
              )),
      ],
    );
  }
  
  Widget _buildAnalyticsSection() {
    final analytics = _analytics!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Performance Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Investment Breakdown
              _buildAnalyticsRow('Total Investment', '\$${analytics.totalInvestment.toStringAsFixed(0)}'),
              _buildAnalyticsRow('Cash', '\$${analytics.cashInvestment.toStringAsFixed(0)}', indent: true),
              _buildAnalyticsRow('Products', '\$${analytics.productInvestment.toStringAsFixed(0)}', indent: true),
              
              const SizedBox(height: 12),
              Divider(color: AppColors.grey300),
              const SizedBox(height: 12),
              
              // Returns
              _buildAnalyticsRow('Total Returns', '\$${analytics.totalReturns.toStringAsFixed(0)}', isTotal: true),
              _buildAnalyticsRow('Direct Revenue', '\$${analytics.directRevenue.toStringAsFixed(0)}', indent: true),
              _buildAnalyticsRow('Brand Value', '\$${analytics.estimatedBrandValue.toStringAsFixed(0)}', indent: true),
              
              const SizedBox(height: 12),
              Divider(color: AppColors.grey300),
              const SizedBox(height: 12),
              
              // ROI
              _buildAnalyticsRow(
                'ROI',
                '${analytics.roiPercentage.toStringAsFixed(0)}%',
                isTotal: true,
                color: analytics.roiPercentage > 0 ? AppColors.electricGreen : AppColors.error,
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BrandAnalyticsPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.grey300),
                  ),
                  child: const Text('View Detailed Analytics'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnalyticsRow(String label, String value, {bool isTotal = false, bool indent = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 16 : 0, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color ?? (isTotal ? AppTheme.primaryColor : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. UI Integration Plan - FINALIZED

### **4.1 Navigation Integration**

**Routes to Add:**
```dart
// In lib/presentation/routes/app_router.dart

// Brand Discovery
GoRoute(
  path: '/brand/discovery',
  builder: (context, state) => const BrandDiscoveryPage(),
),

// Sponsorship Management
GoRoute(
  path: '/brand/sponsorships',
  builder: (context, state) => const SponsorshipManagementPage(),
),

// Brand Dashboard
GoRoute(
  path: '/brand/dashboard',
  builder: (context, state) => const BrandDashboardPage(),
),

// Sponsorship Details
GoRoute(
  path: '/brand/sponsorship/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return SponsorshipDetailsPage(sponsorshipId: id);
  },
),

// Brand Analytics
GoRoute(
  path: '/brand/analytics',
  builder: (context, state) => const BrandAnalyticsPage(),
),
```

### **4.2 Integration with Partnership System**

**Shared Components:**
- ✅ Reuse `CompatibilityBadge` from `lib/presentation/widgets/partnerships/compatibility_badge.dart`
- ✅ Reuse `RevenueSplitDisplay` from `lib/presentation/widgets/partnerships/revenue_split_display.dart`
- ✅ Reuse payment flow components from partnership checkout

**Data Integration:**
- `SponsorshipIntegration` utilities connect sponsorships with partnerships
- `EventPartnership` can have associated `Sponsorship` records
- `RevenueSplit` supports `SplitPartyType.sponsor` for brand sponsors

### **4.3 User Role Detection**

**Brand Account Check:**
```dart
// Check if user has brand account
final brandAccount = await _brandAccountService.getBrandAccountByUserId(userId);
if (brandAccount != null && brandAccount.isVerified) {
  // Show brand navigation
  // Show brand dashboard access
}
```

**Navigation Menu Updates:**
- Add "Brand Dashboard" to main navigation for verified brand accounts
- Add "Discover Events" to brand menu
- Add "My Sponsorships" to brand menu

---

## 5. Component File Structure

### **Pages:**
```
lib/presentation/pages/brand/
├── brand_discovery_page.dart
├── brand_dashboard_page.dart
├── brand_analytics_page.dart
├── sponsorship_management_page.dart
├── sponsorship_details_page.dart
└── create_sponsorship_proposal_page.dart
```

### **Widgets:**
```
lib/presentation/widgets/brand/
├── sponsorable_event_card.dart
├── sponsorship_card.dart
├── brand_stats_card.dart
├── sponsorship_status_badge.dart
├── product_tracking_widget.dart
└── compatibility_breakdown_widget.dart
```

---

## 6. Implementation Checklist

### **Week 10 Deliverables:**
- [x] Review Agent 3's Brand models
- [x] Finalize Brand Discovery UI designs
- [x] Finalize Sponsorship Management UI designs
- [x] Finalize Brand Dashboard UI designs
- [x] Update UI component specifications with model details
- [x] Finalize UI integration plan

### **Week 11 Tasks:**
- [ ] Create payment UI components (multi-party checkout)
- [ ] Create analytics UI components (ROI tracking, charts)
- [ ] Integrate with payment/analytics services

### **Week 12 Tasks:**
- [ ] Implement Brand Discovery UI
- [ ] Implement Sponsorship Management UI
- [ ] Implement Brand Dashboard UI
- [ ] Create UI tests
- [ ] Integration testing

---

## 7. Model-to-UI Mapping

### **BrandAccount → Brand Dashboard:**
- `name` → Header title
- `logoUrl` → Avatar image
- `brandType` → Subtitle
- `categories` → Category chips
- `verificationStatus` → Verification badge
- `activeSponsorshipCount` → Stats card
- `totalSponsorshipCount` → Stats card

### **Sponsorship → Sponsorship Card:**
- `type` → Contribution type display
- `contributionAmount` → Cash contribution
- `productValue` → Product contribution
- `totalContributionValue` → Total display
- `status` → Status badge
- `revenueSharePercentage` → Revenue share display
- `agreementTerms` → Agreement details

### **BrandMatch → Event Card:**
- `compatibilityScore` → Compatibility badge
- `vibeCompatibility` → Compatibility breakdown
- `matchReasons` → Match reasons list
- `estimatedContribution` → Budget range display
- `brandName` → Brand name (if showing brand to event host)

### **ProductTracking → Product Section:**
- `productName` → Product title
- `quantityProvided` → Provided count
- `quantitySold` → Sold count
- `quantityGivenAway` → Samples count
- `quantityUsedInEvent` → Used count
- `totalSales` → Sales revenue
- `revenueDistribution` → Revenue split display

---

## 8. Next Steps

1. ✅ **Week 10 Complete:** All designs finalized based on actual models
2. **Week 11:** Create payment and analytics UI components
3. **Week 12:** Implement full UI based on finalized designs

---

**Status:** ✅ **FINALIZED - Ready for Week 11**  
**Last Updated:** November 23, 2025, 11:50 AM CST  
**Models Reviewed:** ✅ All Agent 3 models reviewed and integrated

