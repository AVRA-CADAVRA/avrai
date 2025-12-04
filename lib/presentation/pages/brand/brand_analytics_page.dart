import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/brand/roi_chart_widget.dart';
import 'package:spots/presentation/widgets/brand/performance_metrics_widget.dart';
import 'package:spots/presentation/widgets/brand/brand_exposure_widget.dart';

/// Brand Analytics Page
/// 
/// Comprehensive analytics dashboard for brand sponsorships.
/// Shows ROI, performance metrics, brand exposure, and event performance.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
/// 
/// **Features:**
/// - ROI overview and trends
/// - Performance metrics
/// - Brand exposure analytics
/// - Event performance tracking
/// - Export capabilities
class BrandAnalyticsPage extends StatefulWidget {
  const BrandAnalyticsPage({super.key});

  @override
  State<BrandAnalyticsPage> createState() => _BrandAnalyticsPageState();
}

class _BrandAnalyticsPageState extends State<BrandAnalyticsPage> {
  // TODO: Get services when available (Agent 1, Week 11)
  // final _brandAnalyticsService = GetIt.instance<BrandAnalyticsService>();
  // final _brandAccountService = GetIt.instance<BrandAccountService>();
  
  BrandAccount? _brandAccount;
  BrandAnalytics? _analytics;
  bool _isLoading = true;
  String? _selectedTimeRange = 'Q4 2025'; // Default to current quarter
  
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }
  
  Future<void> _loadAnalytics() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    final userId = authState.user.id;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Integrate with services when available (Agent 1, Week 11)
      // final brand = await _brandAccountService.getBrandAccountByUserId(userId);
      // if (brand == null) return;
      // 
      // final analytics = await _brandAnalyticsService.getBrandAnalytics(
      //   brand.id,
      //   timeRange: _selectedTimeRange,
      // );
      
      // For now, use mock data
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        // _brandAccount = brand;
        _analytics = _createMockAnalytics();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }
  
  BrandAnalytics _createMockAnalytics() {
    return BrandAnalytics(
      totalInvestment: 3200.0,
      cashInvestment: 2000.0,
      productInvestment: 1200.0,
      totalReturns: 1847.0,
      directRevenue: 1847.0,
      estimatedBrandValue: 12400.0,
      roiPercentage: 387.0,
      topPerformingEvents: const [
        EventPerformance(
          eventId: 'event-1',
          eventName: 'Farm-to-Table Dinner',
          roiPercentage: 410.0,
          totalReturns: 450.0,
        ),
        EventPerformance(
          eventId: 'event-2',
          eventName: 'Italian Night',
          roiPercentage: 385.0,
          totalReturns: 320.0,
        ),
      ],
      exposureMetrics: const BrandExposureMetrics(
        totalReach: 340000,
        totalImpressions: 450000,
        productSampling: 187,
        emailSignups: 94,
        websiteVisits: 412,
      ),
      performanceMetrics: const PerformanceMetrics(
        totalEvents: 12,
        activeSponsorships: 3,
        averageROI: 387.0,
        totalBrandValue: 12400.0,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Brand Analytics',
            style: TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_analytics == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Brand Analytics',
            style: TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No analytics data available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start sponsoring events to see analytics',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Brand Analytics',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportAnalytics();
              } else if (value == 'refresh') {
                _loadAnalytics();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Selector
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: Row(
                children: [
                  Text(
                    'Time Range:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedTimeRange,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Q4 2025', child: Text('Q4 2025')),
                        DropdownMenuItem(value: 'Q3 2025', child: Text('Q3 2025')),
                        DropdownMenuItem(value: '2025', child: Text('2025')),
                        DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedTimeRange = value);
                          _loadAnalytics();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ROI Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '📊 ROI Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Investment Breakdown
                      _buildAnalyticsRow('Total Investment', '\$${_analytics!.totalInvestment.toStringAsFixed(0)}', isTotal: true),
                      _buildAnalyticsRow('Cash', '\$${_analytics!.cashInvestment.toStringAsFixed(0)}', indent: true),
                      _buildAnalyticsRow('Products', '\$${_analytics!.productInvestment.toStringAsFixed(0)}', indent: true),
                      
                      const SizedBox(height: 12),
                      Divider(color: AppColors.grey300),
                      const SizedBox(height: 12),
                      
                      // Returns
                      _buildAnalyticsRow('Total Returns', '\$${_analytics!.totalReturns.toStringAsFixed(0)}', isTotal: true),
                      _buildAnalyticsRow('Direct Revenue', '\$${_analytics!.directRevenue.toStringAsFixed(0)}', indent: true),
                      _buildAnalyticsRow('Brand Value', '\$${_analytics!.estimatedBrandValue.toStringAsFixed(0)}', indent: true),
                      
                      const SizedBox(height: 12),
                      Divider(color: AppColors.grey300),
                      const SizedBox(height: 12),
                      
                      // ROI
                      _buildAnalyticsRow(
                        'ROI',
                        '${_analytics!.roiPercentage.toStringAsFixed(0)}%',
                        isTotal: true,
                        color: _analytics!.roiPercentage > 0 ? AppColors.electricGreen : AppColors.error,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ROI Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ROICartWidget(
                analytics: _analytics!,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Performance Metrics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PerformanceMetricsWidget(
                analytics: _analytics!,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Brand Exposure
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BrandExposureWidget(
                analytics: _analytics!,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Top Performing Events
            if (_analytics!.topPerformingEvents.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '🏆 Top Performing Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._analytics!.topPerformingEvents.take(5).map((event) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          event.eventName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'ROI: ${event.roiPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          '\$${event.totalReturns.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricGreen,
                          ),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
            ],
            
            const SizedBox(height: 32),
          ],
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
  
  Future<void> _exportAnalytics() async {
    // Export analytics report
    // Would integrate with export service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting analytics report...'),
      ),
    );
  }
}

/// Brand Analytics Model (from service)
/// This would be provided by BrandAnalyticsService
class BrandAnalytics {
  final double totalInvestment;
  final double cashInvestment;
  final double productInvestment;
  final double totalReturns;
  final double directRevenue;
  final double estimatedBrandValue;
  final double roiPercentage;
  final List<EventPerformance> topPerformingEvents;
  final BrandExposureMetrics exposureMetrics;
  final PerformanceMetrics performanceMetrics;
  
  const BrandAnalytics({
    required this.totalInvestment,
    required this.cashInvestment,
    required this.productInvestment,
    required this.totalReturns,
    required this.directRevenue,
    required this.estimatedBrandValue,
    required this.roiPercentage,
    required this.topPerformingEvents,
    required this.exposureMetrics,
    required this.performanceMetrics,
  });
}

class EventPerformance {
  final String eventId;
  final String eventName;
  final double roiPercentage;
  final double totalReturns;
  
  const EventPerformance({
    required this.eventId,
    required this.eventName,
    required this.roiPercentage,
    required this.totalReturns,
  });
}

class BrandExposureMetrics {
  final int totalReach;
  final int totalImpressions;
  final int productSampling;
  final int emailSignups;
  final int websiteVisits;
  
  const BrandExposureMetrics({
    required this.totalReach,
    required this.totalImpressions,
    required this.productSampling,
    required this.emailSignups,
    required this.websiteVisits,
  });
}

class PerformanceMetrics {
  final int totalEvents;
  final int activeSponsorships;
  final double averageROI;
  final double totalBrandValue;
  
  const PerformanceMetrics({
    required this.totalEvents,
    required this.activeSponsorships,
    required this.averageROI,
    required this.totalBrandValue,
  });
}

