import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/brand/sponsorship_card.dart';
import 'package:spots/presentation/pages/brand/brand_discovery_page.dart';
import 'package:get_it/get_it.dart';

/// Sponsorship Management Page
/// 
/// View and manage active, pending, and completed sponsorships.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class SponsorshipManagementPage extends StatefulWidget {
  const SponsorshipManagementPage({super.key});

  @override
  State<SponsorshipManagementPage> createState() => _SponsorshipManagementPageState();
}

class _SponsorshipManagementPageState extends State<SponsorshipManagementPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // TODO: Get services when available (Agent 1, Week 11)
  // final _sponsorshipService = GetIt.instance<SponsorshipService>();
  // final _productTrackingService = GetIt.instance<ProductTrackingService>();
  final _eventService = GetIt.instance<ExpertiseEventService>();
  
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
  
  @override
  void dispose() {
    _tabController.dispose();
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
  
  Future<void> _loadSponsorships() async {
    if (_currentBrand == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Get sponsorships when service available
      // final sponsorships = await _sponsorshipService.getSponsorshipsForBrand(
      //   _currentBrand!.id,
      // );
      // 
      // // Load product tracking for product/hybrid sponsorships
      // final productSponsorships = sponsorships.where((s) => 
      //   s.type == SponsorshipType.product || s.type == SponsorshipType.hybrid
      // ).toList();
      // 
      // final trackingMap = <String, ProductTracking>{};
      // for (final sponsorship in productSponsorships) {
      //   final tracking = await _productTrackingService.getTrackingForSponsorship(
      //     sponsorship.id,
      //   );
      //   if (tracking != null) {
      //     trackingMap[sponsorship.id] = tracking;
      //   }
      // }
      
      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));
      final mockSponsorships = _createMockSponsorships();
      
      setState(() {
        _activeSponsorships = mockSponsorships.where((s) => 
          s.status == SponsorshipStatus.active ||
          s.status == SponsorshipStatus.locked ||
          s.status == SponsorshipStatus.approved
        ).toList();
        
        _pendingSponsorships = mockSponsorships.where((s) => 
          s.status == SponsorshipStatus.pending ||
          s.status == SponsorshipStatus.proposed ||
          s.status == SponsorshipStatus.negotiating
        ).toList();
        
        _completedSponsorships = mockSponsorships.where((s) => 
          s.status == SponsorshipStatus.completed ||
          s.status == SponsorshipStatus.cancelled
        ).toList();
        
        _productTrackingMap = {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sponsorships: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  List<Sponsorship> _createMockSponsorships() {
    return [
      Sponsorship(
        id: 'sponsor-1',
        eventId: 'event-1',
        brandId: _currentBrand?.id ?? 'brand-1',
        type: SponsorshipType.hybrid,
        contributionAmount: 1000.0,
        productValue: 500.0,
        status: SponsorshipStatus.active,
        revenueSharePercentage: 15.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
    ];
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
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
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
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No sponsorships',
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createNewSponsorship,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Discover Events'),
          ),
        ],
      ),
    );
  }
  
  void _createNewSponsorship() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BrandDiscoveryPage(),
      ),
    );
  }
  
  void _viewSponsorshipDetails(Sponsorship sponsorship) {
    // Navigate to sponsorship details page
    // Would show full sponsorship details, event info, etc.
  }
  
  void _manageSponsorship(Sponsorship sponsorship) {
    // Navigate to sponsorship management/edit page
    // Would allow editing sponsorship terms, viewing product tracking, etc.
  }
}

