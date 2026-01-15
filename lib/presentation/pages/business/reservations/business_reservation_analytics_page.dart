/// Business Reservation Analytics Page
///
/// Phase 7.2: Business Reservation Analytics
/// Enhanced with Full Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
///
/// Comprehensive analytics dashboard for business reservations including:
/// - Volume and peak times
/// - No-show and cancellation rates
/// - Revenue tracking
/// - Customer retention
/// - Rate limit usage
/// - Waitlist metrics
/// - Capacity utilization
/// - Knot string evolution patterns (business patterns)
/// - Fabric stability analytics (group reservations)
/// - Worldsheet evolution tracking (temporal patterns)
/// - Quantum compatibility trends
/// - AI2AI mesh learning insights
///
/// Uses AppColors/AppTheme for 100% design token compliance.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/services/business_reservation_analytics_service.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:fl_chart/fl_chart.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart'
    show TrendType;

/// Business Reservation Analytics Page
class BusinessReservationAnalyticsPage extends StatefulWidget {
  final String businessId;
  final ReservationType type;

  const BusinessReservationAnalyticsPage({
    super.key,
    required this.businessId,
    required this.type,
  });

  @override
  State<BusinessReservationAnalyticsPage> createState() =>
      _BusinessReservationAnalyticsPageState();
}

class _BusinessReservationAnalyticsPageState
    extends State<BusinessReservationAnalyticsPage> {
  late final BusinessReservationAnalyticsService _analyticsService;
  BusinessReservationAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _analyticsService = di.sl<BusinessReservationAnalyticsService>();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics = await _analyticsService.getBusinessAnalytics(
        businessId: widget.businessId,
        type: widget.type,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reservation Analytics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _analytics == null
                  ? _buildEmptyState()
                  : _buildAnalyticsContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No reservation data available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your reservation analytics will appear here once you receive reservations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Volume Patterns
          _buildSectionTitle('Reservation Volume'),
          const SizedBox(height: 8),
          _buildVolumePatterns(),
          const SizedBox(height: 24),

          // Peak Times
          if (_analytics!.peakHours.isNotEmpty ||
              _analytics!.peakDays.isNotEmpty) ...[
            _buildSectionTitle('Peak Times'),
            const SizedBox(height: 8),
            _buildPeakTimes(),
            const SizedBox(height: 24),
          ],

          // Revenue Metrics
          if (_analytics!.totalRevenue > 0) ...[
            _buildSectionTitle('Revenue'),
            const SizedBox(height: 8),
            _buildRevenueMetrics(),
            const SizedBox(height: 24),
          ],

          // Rates (Cancellation, No-show, Completion)
          _buildSectionTitle('Reservation Rates'),
          const SizedBox(height: 8),
          _buildRatesSection(),
          const SizedBox(height: 24),

          // Customer Retention
          _buildSectionTitle('Customer Retention'),
          const SizedBox(height: 8),
          _buildCustomerRetention(),
          const SizedBox(height: 24),

          // Rate Limit Usage Metrics (Phase 7.2 Enhancement)
          if (_analytics!.rateLimitMetrics != null) ...[
            _buildSectionTitle('Rate Limit Usage'),
            const SizedBox(height: 8),
            _buildRateLimitMetrics(),
            const SizedBox(height: 24),
          ],

          // Waitlist Metrics (Phase 7.2 Enhancement)
          if (_analytics!.waitlistMetrics != null) ...[
            _buildSectionTitle('Waitlist Metrics'),
            const SizedBox(height: 8),
            _buildWaitlistMetrics(),
            const SizedBox(height: 24),
          ],

          // Capacity Utilization Metrics (Phase 7.2 Enhancement)
          if (_analytics!.capacityMetrics != null) ...[
            _buildSectionTitle('Capacity Utilization'),
            const SizedBox(height: 8),
            _buildCapacityMetrics(),
            const SizedBox(height: 24),
          ],

          // Knot String Evolution Patterns (Phase 7.2 Enhancement)
          if (_analytics!.stringEvolutionPatterns != null) ...[
            _buildSectionTitle('Recurring Patterns (Knot String Evolution)'),
            const SizedBox(height: 8),
            _buildStringEvolutionPatterns(),
            const SizedBox(height: 24),
          ],

          // Fabric Stability Analytics (Phase 7.2 Enhancement)
          if (_analytics!.fabricStabilityAnalytics != null) ...[
            _buildSectionTitle('Group Compatibility (Fabric Stability)'),
            const SizedBox(height: 8),
            _buildFabricStabilityAnalytics(),
            const SizedBox(height: 24),
          ],

          // Worldsheet Evolution Analytics (Phase 7.2 Enhancement)
          if (_analytics!.worldsheetEvolutionAnalytics != null) ...[
            _buildSectionTitle('Temporal Evolution (4D Worldsheets)'),
            const SizedBox(height: 8),
            _buildWorldsheetEvolutionAnalytics(),
            const SizedBox(height: 24),
          ],

          // Quantum Compatibility Trends (Phase 7.2 Enhancement)
          if (_analytics!.quantumCompatibilityTrends != null) ...[
            _buildSectionTitle('Quantum Compatibility Trends'),
            const SizedBox(height: 8),
            _buildQuantumCompatibilityTrends(),
            const SizedBox(height: 24),
          ],

          // AI2AI Learning Insights (Phase 7.2 Enhancement)
          if (_analytics!.ai2aiLearningInsights != null) ...[
            _buildSectionTitle('AI2AI Mesh Learning Insights'),
            const SizedBox(height: 8),
            _buildAI2AILearningInsights(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total',
            value: '${_analytics!.totalReservations}',
            icon: Icons.event,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Completed',
            value: '${_analytics!.completedReservations}',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Revenue',
            value: '\$${_analytics!.totalRevenue.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildVolumePatterns() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hour distribution chart
            if (_analytics!.volumeByHour.isNotEmpty) ...[
              const Text(
                'Hour Distribution',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildHourDistributionChart(),
              ),
              const SizedBox(height: 16),
            ],
            // Day distribution chart
            if (_analytics!.volumeByDay.isNotEmpty) ...[
              const Text(
                'Day Distribution',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildDayDistributionChart(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHourDistributionChart() {
    final hourData = _analytics!.volumeByHour;
    final maxCount = hourData.values.isEmpty
        ? 1
        : hourData.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount.toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 4 == 0) {
                  return Text('$hour:00', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (hour) {
          final count = hourData[hour] ?? 0;
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: AppTheme.primaryColor,
                width: 12,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDayDistributionChart() {
    final dayData = _analytics!.volumeByDay;
    final maxCount = dayData.values.isEmpty
        ? 1
        : dayData.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount.toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (day >= 1 && day <= 7) {
                  return Text(dayNames[day - 1], style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            final day = index + 1;
            final count = dayData[day] ?? 0;
            return BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: AppTheme.primaryColor,
                  width: 20,
                ),
              ],
            );
          }).toList(),
      ),
    );
  }

  Widget _buildPeakTimes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_analytics!.peakHours.isNotEmpty) ...[
              const Text(
                'Peak Hours',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _analytics!.peakHours.map((hour) {
                  return Chip(
                    label: Text('$hour:00'),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (_analytics!.peakDays.isNotEmpty) ...[
              const Text(
                'Peak Days',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _analytics!.peakDays.map((day) {
                  final dayNames = [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ];
                  return Chip(
                    label: Text(dayNames[day - 1]),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Total Revenue',
              '\$${_analytics!.totalRevenue.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Average Revenue per Reservation',
              '\$${_analytics!.averageRevenuePerReservation.toStringAsFixed(2)}',
            ),
            if (_analytics!.revenueByMonth.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Revenue by Month',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildRevenueByMonthChart(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByMonthChart() {
    final revenueData = _analytics!.revenueByMonth;
    final maxRevenue = revenueData.values.isEmpty
        ? 1.0
        : revenueData.values.reduce((a, b) => a > b ? a : b);

    final sortedEntries = revenueData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedEntries.length) {
                  final monthKey = sortedEntries[index].key;
                  // Format: YYYY-MM
                  final parts = monthKey.split('-');
                  if (parts.length == 2) {
                    return Text(
                      '${parts[0]}-${parts[1]}',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return Text(monthKey, style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedEntries.length, (index) {
          final entry = sortedEntries[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: AppColors.success,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Completion Rate',
              '${(_analytics!.completionRate * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Cancellation Rate',
              '${(_analytics!.cancellationRate * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'No-Show Rate',
              '${(_analytics!.noShowRate * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRetention() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Customer Retention Rate',
              '${(_analytics!.customerRetentionRate * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Repeat Customers',
              '${_analytics!.repeatCustomers}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateLimitMetrics() {
    final metrics = _analytics!.rateLimitMetrics!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('Total Checks', '${metrics.totalChecks}'),
            const SizedBox(height: 12),
            _buildStatItem('Rate Limit Hits', '${metrics.rateLimitHits}'),
            const SizedBox(height: 12),
            _buildStatItem(
              'Hit Rate',
              '${(metrics.hitRate * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Average Requests per Hour',
              metrics.averageRequestsPerHour.toStringAsFixed(1),
            ),
            if (metrics.peakUsageHours.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Peak Usage Hours',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metrics.peakUsageHours.map((hour) {
                  return Chip(
                    label: Text('$hour:00'),
                    backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaitlistMetrics() {
    final metrics = _analytics!.waitlistMetrics!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('Total Waitlist Joins', '${metrics.totalJoins}'),
            const SizedBox(height: 12),
            _buildStatItem(
              'Total Conversions',
              '${metrics.totalConversions}',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Conversion Rate',
              '${(metrics.conversionRate * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Average Wait Time',
              '${metrics.averageWaitTime.toStringAsFixed(1)} hours',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Longest Wait Time',
              '${metrics.longestWaitTime.toStringAsFixed(1)} hours',
            ),
            if (metrics.conversionsByDay.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Conversions by Day',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...metrics.conversionsByDay.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityMetrics() {
    final metrics = _analytics!.capacityMetrics!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Average Utilization',
              '${(metrics.averageUtilization * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Peak Utilization',
              '${(metrics.peakUtilization * 100).toStringAsFixed(1)}%',
            ),
            if (metrics.peakUtilizationHours.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Peak Utilization Hours',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metrics.peakUtilizationHours.map((hour) {
                  return Chip(
                    label: Text('$hour:00'),
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (metrics.underutilizedHours.isNotEmpty) ...[
              const Text(
                'Underutilized Hours',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metrics.underutilizedHours.map((hour) {
                  return Chip(
                    label: Text('$hour:00'),
                    backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
            if (metrics.utilizationByHour.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Utilization by Hour',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildUtilizationByHourChart(metrics.utilizationByHour),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUtilizationByHourChart(Map<int, double> utilizationByHour) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: true),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 4 == 0) {
                  return Text('$hour:00', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: utilizationByHour.entries
                .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                .toList(),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStringEvolutionPatterns() {
    final patterns = _analytics!.stringEvolutionPatterns!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patterns.recurringPatterns.isNotEmpty) ...[
              const Text(
                'Recurring Patterns',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...patterns.recurringPatterns.map((pattern) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.repeat, color: AppTheme.primaryColor),
                  title: Text(
                    '${pattern.patternType.toUpperCase()} pattern',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: pattern.nextOccurrence != null
                      ? Text('Next: ${_formatDateTime(pattern.nextOccurrence!)}')
                      : null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(pattern.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (patterns.cycles.isNotEmpty) ...[
              const Text(
                'Evolution Cycles',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...patterns.cycles.map((cycle) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.repeat, color: AppTheme.primaryColor),
                  title: Text(
                    '${cycle.period.inDays} day cycle',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${_formatDateTime(cycle.startTime)} - ${_formatDateTime(cycle.endTime)}',
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (patterns.trends.isNotEmpty) ...[
              const Text(
                'Evolution Trends',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...patterns.trends.map((trend) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    trend.type == TrendType.increasing
                        ? Icons.trending_up
                        : trend.type == TrendType.decreasing
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: trend.type == TrendType.increasing
                        ? AppColors.success
                        : trend.type == TrendType.decreasing
                            ? AppColors.error
                            : AppColors.textSecondary,
                  ),
                  title: Text(
                    trend.type == TrendType.increasing
                        ? 'Increasing'
                        : trend.type == TrendType.decreasing
                            ? 'Decreasing'
                            : 'Stable',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Magnitude: ${trend.magnitude.toStringAsFixed(2)}',
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (patterns.predictedVolumes.isNotEmpty) ...[
              const Text(
                'Predicted Future Volumes',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...patterns.predictedVolumes.map((prediction) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  title: Text(
                    '${prediction.predictedReservations} reservations',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_formatDateTime(prediction.predictedTime)),
                  trailing: Text(
                    '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFabricStabilityAnalytics() {
    final fabric = _analytics!.fabricStabilityAnalytics!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Average Fabric Stability',
              '${(fabric.averageStability * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Group Success Rate',
              '${(fabric.groupSuccessRate * 100).toStringAsFixed(1)}%',
            ),
            if (fabric.mostStableGroups.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Most Stable Groups',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...fabric.mostStableGroups.map((group) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.group, color: AppTheme.primaryColor),
                  title: Text(
                    '${group.userIds.length} members',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${group.reservationCount} reservations'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(group.stability * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorldsheetEvolutionAnalytics() {
    final worldsheet = _analytics!.worldsheetEvolutionAnalytics!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (worldsheet.evolutionHistory.isNotEmpty) ...[
              const Text(
                'Evolution History',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildEvolutionHistoryChart(worldsheet.evolutionHistory),
              ),
              const SizedBox(height: 16),
            ],
            if (worldsheet.predictions.isNotEmpty) ...[
              const Text(
                'Future Predictions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...worldsheet.predictions.map((prediction) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                  title: Text(
                    _formatDateTime(prediction.predictedTime),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Predicted stability: ${(prediction.predictedStability * 100).toStringAsFixed(1)}%',
                  ),
                  trailing: Text(
                    '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (worldsheet.stabilityTrends.isNotEmpty) ...[
              const Text(
                'Stability Trends',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...worldsheet.stabilityTrends.map((trend) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    trend.trend == TrendType.increasing
                        ? Icons.trending_up
                        : trend.trend == TrendType.decreasing
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: trend.trend == TrendType.increasing
                        ? AppColors.success
                        : trend.trend == TrendType.decreasing
                            ? AppColors.error
                            : AppColors.textSecondary,
                  ),
                  title: Text(
                    '${_formatDateTime(trend.startTime)} - ${_formatDateTime(trend.endTime)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Change: ${(trend.stabilityChange * 100).toStringAsFixed(1)}%',
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionHistoryChart(
    List<WorldsheetEvolutionPoint> history,
  ) {
    final spots = history
        .map((point) => FlSpot(
              point.timestamp.millisecondsSinceEpoch.toDouble(),
              point.evolutionScore,
            ))
        .toList();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: true),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantumCompatibilityTrends() {
    final quantum = _analytics!.quantumCompatibilityTrends!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem(
              'Average Compatibility',
              '${(quantum.averageCompatibility * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Compatibility Trend',
              quantum.compatibilityTrend == TrendType.increasing
                  ? 'Increasing'
                  : quantum.compatibilityTrend == TrendType.decreasing
                      ? 'Decreasing'
                      : 'Stable',
            ),
            if (quantum.compatibilityHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Compatibility History',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildCompatibilityHistoryChart(quantum.compatibilityHistory),
              ),
              const SizedBox(height: 16),
            ],
            if (quantum.highCompatibilityPeriods.isNotEmpty) ...[
              const Text(
                'High Compatibility Periods',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...quantum.highCompatibilityPeriods.map((period) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.star, color: AppColors.warning),
                  title: Text(
                    '${_formatDateTime(period.startTime)} - ${_formatDateTime(period.endTime)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${period.reservationCount} reservations'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(period.averageCompatibility * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityHistoryChart(
    List<CompatibilityTrendPoint> history,
  ) {
    final spots = history
        .map((point) => FlSpot(
              point.timestamp.millisecondsSinceEpoch.toDouble(),
              point.compatibility,
            ))
        .toList();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(enabled: true),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAI2AILearningInsights() {
    final ai2ai = _analytics!.ai2aiLearningInsights!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('Total Insights', '${ai2ai.totalInsights}'),
            const SizedBox(height: 12),
            _buildStatItem(
              'Average Learning Quality',
              '${(ai2ai.averageLearningQuality * 100).toStringAsFixed(1)}%',
            ),
            if (ai2ai.improvedDimensions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Improved Dimensions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ai2ai.improvedDimensions.map((dimension) {
                  return Chip(
                    label: Text(dimension),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Mesh Propagation Stats',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildStatItem(
              'Insights Received',
              '${ai2ai.propagationStats.insightsReceived}',
            ),
            const SizedBox(height: 8),
            _buildStatItem(
              'Insights Shared',
              '${ai2ai.propagationStats.insightsShared}',
            ),
            const SizedBox(height: 8),
            _buildStatItem(
              'Average Hop Count',
              ai2ai.propagationStats.averageHopCount.toStringAsFixed(1),
            ),
            if (ai2ai.businessInsights.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Business Insights',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...ai2ai.businessInsights.map((insight) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.lightbulb, color: AppTheme.primaryColor),
                  title: Text(
                    insight.insightType,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(insight.description),
                  trailing: Text(
                    '${(insight.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(dateTime.weekday)} at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialStartDate = _startDate ?? now.subtract(const Duration(days: 30));
    final initialEndDate = _endDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStartDate,
        end: initialEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }
}
