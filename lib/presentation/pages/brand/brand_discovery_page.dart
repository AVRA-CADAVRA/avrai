import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/brand_discovery.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/brand/sponsorable_event_card.dart';
import 'package:spots/presentation/pages/brand/sponsorship_checkout_page.dart';
import 'package:get_it/get_it.dart';

/// Brand Discovery Page
/// 
/// Allows brands to search and discover events to sponsor.
/// Shows recommended events based on vibe matching (70%+ compatibility).
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class BrandDiscoveryPage extends StatefulWidget {
  const BrandDiscoveryPage({super.key});

  @override
  State<BrandDiscoveryPage> createState() => _BrandDiscoveryPageState();
}

class _BrandDiscoveryPageState extends State<BrandDiscoveryPage> {
  final _eventService = GetIt.instance<ExpertiseEventService>();
  // TODO: Get services when available (Agent 1, Week 11)
  // final _brandDiscoveryService = GetIt.instance<BrandDiscoveryService>();
  // final _brandAccountService = GetIt.instance<BrandAccountService>();
  
  BrandAccount? _currentBrand;
  List<BrandMatch> _recommendedMatches = [];
  List<BrandMatch> _searchMatches = [];
  bool _isLoading = false;
  
  // Search and filters
  final _searchController = TextEditingController();
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
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBrandAccount() async {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;
    
    // TODO: Get brand account when service available
    // final brand = await _brandAccountService.getBrandAccountByUserId(userId);
    // setState(() => _currentBrand = brand);
    
    // Mock brand for now
    setState(() {
      _currentBrand = BrandAccount(
        id: 'brand-mock-1',
        name: 'Premium Olive Oil Co.',
        brandType: 'Food & Beverage',
        categories: ['Gourmet', 'Premium Products'],
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }
  
  Future<void> _loadRecommendedEvents() async {
    if (_currentBrand == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Get recommended events when service available
      // final discovery = await _brandDiscoveryService.getRecommendedEvents(
      //   _currentBrand!.id,
      // );
      // setState(() {
      //   _recommendedMatches = discovery.viableMatches;
      //   _isLoading = false;
      // });
      
      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _recommendedMatches = _createMockMatches();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Future<void> _performSearch() async {
    if (_currentBrand == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Search events when service available
      // final discovery = await _brandDiscoveryService.searchEvents(
      //   brandId: _currentBrand!.id,
      //   category: _selectedCategory,
      //   location: _selectedLocation,
      //   dateRange: _dateRange,
      //   minBudget: _minBudget,
      //   maxBudget: _maxBudget,
      //   minAttendees: _minAttendees,
      // );
      // setState(() {
      //   _searchMatches = discovery.viableMatches;
      //   _isLoading = false;
      // });
      
      // Mock search results
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _searchMatches = _createMockMatches();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching events: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  List<BrandMatch> _createMockMatches() {
    return [
      BrandMatch(
        brandId: _currentBrand?.id ?? 'brand-1',
        brandName: _currentBrand?.name ?? 'Brand',
        compatibilityScore: 87.5,
        vibeCompatibility: const VibeCompatibility(
          overallScore: 87.5,
          valueAlignment: 90.0,
          styleCompatibility: 85.0,
          qualityFocus: 88.0,
          audienceAlignment: 87.0,
        ),
        matchReasons: [
          'Strong value alignment with premium products',
          'Target audience matches event attendees',
          'High quality focus aligns with event standards',
        ],
        brandType: 'Food & Beverage',
        brandCategories: ['Gourmet', 'Premium Products'],
        estimatedContribution: const ContributionRange(
          minAmount: 500.0,
          maxAmount: 1500.0,
          preferredAmount: 1000.0,
        ),
        metadata: {
          'eventTitle': 'Farm-to-Table Dinner Experience',
          'hostName': 'Chef Maria',
          'eventId': 'event-mock-1',
        },
      ),
    ];
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
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search events by name, category, or location...',
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }
  
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showFilterDialog(),
              icon: Icon(Icons.filter_list, size: 18, color: AppColors.textSecondary),
              label: Text(
                'Filters',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.grey300),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Search'),
          ),
        ],
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
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
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
  
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Search Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ..._searchMatches.map((match) => Padding(
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
  
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showFilterDialog() async {
    // Filter dialog implementation
    // Would show category, location, date range, budget, attendees filters
  }
  
  void _viewEventDetails(BrandMatch match) {
    // Navigate to event details page
    final eventId = match.metadata['eventId'] as String?;
    if (eventId != null) {
      // Navigator.push(...)
    }
  }
  
  void _proposeSponsorship(BrandMatch match) {
    final eventId = match.metadata['eventId'] as String?;
    if (eventId != null) {
      // Load event and navigate to sponsorship checkout
      _eventService.getEventById(eventId).then((event) {
        if (event != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SponsorshipCheckoutPage(
                event: event,
              ),
            ),
          );
        }
      });
    }
  }
}

