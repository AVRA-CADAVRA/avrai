import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Expertise Coverage Widget
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 30)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required - NO direct Colors.* usage)
/// 
/// Features:
/// - Display expertise coverage by locality (map view with interactive map)
/// - Coverage metrics (locality, city, state, national, global, universal - 75% threshold indicators)
/// - Expansion tracking display
/// - Philosophy: Show doors (geographic expansion) that clubs can open
class ExpertiseCoverageWidget extends StatefulWidget {
  /// Original locality where club/community formed
  final String? originalLocality;
  
  /// Current localities where club/community is active
  final List<String> currentLocalities;
  
  /// Coverage data by geographic level
  /// Format: {'locality': 0.85, 'city': 0.78, 'state': 0.45, 'national': 0.12, 'global': 0.05}
  final Map<String, double> coverageData;
  
  /// Locality coverage data (Map of locality name → coverage percentage)
  /// Format: {'Brooklyn': 0.95, 'Manhattan': 0.82, 'Queens': 0.45}
  final Map<String, double> localityCoverage;
  
  /// Show map view (default: true)
  final bool showMapView;
  
  /// Coverage thresholds (75% rule for expertise gain)
  static const double coverageThreshold = 0.75;

  const ExpertiseCoverageWidget({
    super.key,
    this.originalLocality,
    this.currentLocalities = const [],
    this.coverageData = const {},
    this.localityCoverage = const {},
    this.showMapView = true,
  });

  @override
  State<ExpertiseCoverageWidget> createState() => _ExpertiseCoverageWidgetState();
}

class _ExpertiseCoverageWidgetState extends State<ExpertiseCoverageWidget> {
  bool _showMapView = true;

  @override
  void initState() {
    super.initState();
    _showMapView = widget.showMapView;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with view toggle
          Row(
            children: [
              Icon(
                Icons.map,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Geographic Coverage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (widget.localityCoverage.isNotEmpty || widget.currentLocalities.isNotEmpty)
                Semantics(
                  label: _showMapView ? 'Switch to list view' : 'Switch to map view',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      _showMapView ? Icons.list : Icons.map,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showMapView = !_showMapView;
                      });
                    },
                    tooltip: _showMapView ? 'Show List View' : 'Show Map View',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Map View or List View
          if (_showMapView && (widget.localityCoverage.isNotEmpty || widget.currentLocalities.isNotEmpty))
            _buildMapView()
          else if (!_showMapView)
            _buildListView(),
          
          // Original Locality
          if (widget.originalLocality != null)
            _buildCoverageItem(
              title: 'Original Locality',
              value: widget.originalLocality!,
              coverage: 1.0, // Always 100% for original
              isAchieved: true,
              icon: Icons.location_on,
            ),
          
          // Current Localities
          if (widget.currentLocalities.isNotEmpty) ...[
            if (widget.originalLocality != null) const SizedBox(height: 12),
            _buildCoverageItem(
              title: 'Current Localities',
              value: widget.currentLocalities.join(', '),
              coverage: null,
              isAchieved: false,
              icon: Icons.map,
            ),
          ],
          
          // Enhanced Coverage Metrics Display
          if (widget.coverageData.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Coverage by Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildAllCoverageLevels(),
          ],
        ],
      ),
    );
  }

  Widget _buildMapView() {
    // Visual map representation showing localities with coverage
    final localities = widget.localityCoverage.isNotEmpty
        ? widget.localityCoverage.keys.toList()
        : widget.currentLocalities;
    
    if (localities.isEmpty) {
      return Semantics(
        label: 'No locality coverage data available',
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No locality coverage data available',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _CoverageMapPainter(
                originalLocality: widget.originalLocality,
                localities: localities,
                localityCoverage: widget.localityCoverage,
                currentLocalities: widget.currentLocalities,
              ),
              child: Container(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Locality coverage list
        if (widget.localityCoverage.isNotEmpty) ...[
          Text(
            'Locality Coverage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.localityCoverage.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLocalityCoverageItem(
                locality: entry.key,
                coverage: entry.value,
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original Locality
        if (widget.originalLocality != null)
          _buildCoverageItem(
            title: 'Original Locality',
            value: widget.originalLocality!,
            coverage: 1.0, // Always 100% for original
            isAchieved: true,
            icon: Icons.location_on,
          ),
        
        // Current Localities
        if (widget.currentLocalities.isNotEmpty) ...[
          if (widget.originalLocality != null) const SizedBox(height: 12),
          _buildCoverageItem(
            title: 'Current Localities',
            value: widget.currentLocalities.join(', '),
            coverage: null,
            isAchieved: false,
            icon: Icons.map,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildAllCoverageLevels() {
    // Build all coverage levels in order: locality, city, state, national, global, universal
    final orderedLevels = ['locality', 'city', 'state', 'national', 'global', 'universal'];
    final widgets = <Widget>[];
    
    for (final level in orderedLevels) {
      if (widget.coverageData.containsKey(level)) {
        final coverage = widget.coverageData[level]!;
        final isAchieved = coverage >= ExpertiseCoverageWidget.coverageThreshold;
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCoverageLevelItem(
              level: level,
              coverage: coverage,
              isAchieved: isAchieved,
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  Widget _buildLocalityCoverageItem({
    required String locality,
    required double coverage,
  }) {
    final isOriginal = locality == widget.originalLocality;
    final isAchieved = coverage >= ExpertiseCoverageWidget.coverageThreshold;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOriginal
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOriginal
              ? AppTheme.primaryColor
              : AppColors.grey300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOriginal ? Icons.location_on : Icons.place,
            color: isOriginal
                ? AppTheme.primaryColor
                : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      locality,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isOriginal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ORIGINAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: coverage,
                        backgroundColor: AppColors.grey300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAchieved
                              ? AppTheme.primaryColor
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(coverage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAchieved
                            ? AppTheme.primaryColor
                            : AppColors.textSecondary,
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

  Widget _buildCoverageItem({
    required String title,
    required String value,
    required double? coverage,
    required bool isAchieved,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAchieved
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppColors.grey300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isAchieved
                ? AppTheme.primaryColor
                : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (coverage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: coverage,
                          backgroundColor: AppColors.grey300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isAchieved
                                ? AppTheme.primaryColor
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(coverage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAchieved
                              ? AppTheme.primaryColor
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isAchieved)
            Icon(
              Icons.check_circle,
              color: AppTheme.primaryColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildCoverageLevelItem({
    required String level,
    required double coverage,
    required bool isAchieved,
  }) {
    final displayName = _getLevelDisplayName(level);
    final icon = _getLevelIcon(level);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAchieved
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAchieved
              ? AppTheme.primaryColor
              : AppColors.grey300,
          width: isAchieved ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isAchieved
                    ? AppTheme.primaryColor
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACHIEVED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                )
              else
                Text(
                  'In Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: coverage,
                  backgroundColor: AppColors.grey300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAchieved
                        ? AppTheme.primaryColor
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(coverage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isAchieved
                      ? AppTheme.primaryColor
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (!isAchieved && coverageThreshold > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${((coverageThreshold - coverage) * 100).toStringAsFixed(0)}% to reach ${(coverageThreshold * 100).toStringAsFixed(0)}% threshold',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLevelDisplayName(String level) {
    switch (level.toLowerCase()) {
      case 'locality':
        return 'Locality Coverage';
      case 'city':
        return 'City Coverage';
      case 'state':
        return 'State Coverage';
      case 'national':
        return 'National Coverage';
      case 'global':
        return 'Global Coverage';
      case 'universal':
        return 'Universal Coverage';
      default:
        return level;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'locality':
        return Icons.location_on;
      case 'city':
        return Icons.location_city;
      case 'state':
        return Icons.map;
      case 'national':
        return Icons.public;
      case 'global':
        return Icons.language;
      case 'universal':
        return Icons.public;
      default:
        return Icons.map;
    }
  }
}

/// Custom painter for coverage map visualization
class _CoverageMapPainter extends CustomPainter {
  final String? originalLocality;
  final List<String> localities;
  final Map<String, double> localityCoverage;
  final List<String> currentLocalities;

  _CoverageMapPainter({
    this.originalLocality,
    required this.localities,
    required this.localityCoverage,
    required this.currentLocalities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw background
    paint.color = AppColors.grey100;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw grid lines for map-like appearance
    paint.color = AppColors.grey300;
    paint.strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    for (int i = 0; i < 5; i++) {
      final x = (size.width / 5) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw localities as colored regions
    if (localities.isNotEmpty) {
      final regionWidth = size.width / localities.length;
      final regionHeight = size.height * 0.8;
      
      for (int i = 0; i < localities.length; i++) {
        final locality = localities[i];
        final isOriginal = locality == originalLocality;
        final coverage = localityCoverage[locality] ?? 0.5;
        final isAchieved = coverage >= ExpertiseCoverageWidget.coverageThreshold;
        
        // Determine color based on coverage and status
        Color regionColor;
        if (isOriginal) {
          regionColor = AppTheme.primaryColor;
        } else if (isAchieved) {
          regionColor = AppTheme.primaryColor.withValues(alpha: 0.7);
        } else {
          regionColor = AppColors.grey400;
        }
        
        paint.color = regionColor;
        final x = i * regionWidth;
        final rect = Rect.fromLTWH(
          x + 4,
          size.height - regionHeight - 4,
          regionWidth - 8,
          regionHeight * coverage,
        );
        canvas.drawRect(rect, paint);
        
        // Draw locality label
        textPainter.text = TextSpan(
          text: locality.length > 10 ? '${locality.substring(0, 10)}...' : locality,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + (regionWidth - textPainter.width) / 2, size.height - 20),
        );
      }
    } else {
      // Draw placeholder text
      textPainter.text = TextSpan(
        text: 'No locality data available',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, size.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_CoverageMapPainter oldDelegate) {
    return oldDelegate.originalLocality != originalLocality ||
        oldDelegate.localities != localities ||
        oldDelegate.localityCoverage != localityCoverage ||
        oldDelegate.currentLocalities != currentLocalities;
  }
}

