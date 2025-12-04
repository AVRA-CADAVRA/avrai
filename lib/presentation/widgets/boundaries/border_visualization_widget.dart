import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' show BitmapDescriptor;
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/presentation/widgets/common/standard_error_widget.dart';
import 'package:spots/presentation/widgets/common/standard_loading_widget.dart';

/// Border Visualization Widget
/// 
/// Displays neighborhood boundaries on a map with hard and soft borders.
/// Shows doors (boundary visualization) that users can understand.
/// 
/// **Philosophy:** Make neighborhood boundaries visible and accessible.
/// Display hard/soft borders clearly to help users understand community connections.
class BorderVisualizationWidget extends StatefulWidget {
  /// Google Maps controller (required for Google Maps integration)
  final gmap.GoogleMapController? mapController;
  
  /// Locality to display boundaries for (optional - shows all if null)
  final String? locality;
  
  /// City to load boundaries for (required)
  final String city;
  
  /// Whether to show soft border spots
  final bool showSoftBorderSpots;
  
  /// Whether to show refinement indicators
  final bool showRefinementIndicators;
  
  /// Callback when a border is tapped
  final void Function(String locality1, String locality2)? onBorderTapped;
  
  /// Callback when a soft border spot is tapped
  final void Function(String spotId)? onSoftBorderSpotTapped;
  
  /// Height of the widget
  final double? height;
  
  /// Width of the widget
  final double? width;

  const BorderVisualizationWidget({
    super.key,
    this.mapController,
    this.locality,
    required this.city,
    this.showSoftBorderSpots = true,
    this.showRefinementIndicators = true,
    this.onBorderTapped,
    this.onSoftBorderSpotTapped,
    this.height,
    this.width,
  });

  @override
  State<BorderVisualizationWidget> createState() => _BorderVisualizationWidgetState();
}

class _BorderVisualizationWidgetState
    extends State<BorderVisualizationWidget> {
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  bool _isLoading = true;
  String? _error;
  List<BoundaryPolyline> _hardBorders = [];
  List<BoundaryPolyline> _softBorders = [];
  List<SoftBorderSpot> _softBorderSpots = [];
  Map<String, bool> _refinedBorders = {};

  @override
  void initState() {
    super.initState();
    _loadBoundaries();
  }

  Future<void> _loadBoundaries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual NeighborhoodBoundaryService when available
      // For now, use mock data to demonstrate the UI
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock boundary data
      _hardBorders = _getMockHardBorders();
      _softBorders = _getMockSoftBorders();
      _softBorderSpots = _getMockSoftBorderSpots();
      _refinedBorders = _getMockRefinedBorders();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.error('Error loading boundaries: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load boundaries';
      });
    }
  }

  List<BoundaryPolyline> _getMockHardBorders() {
    // Mock hard borders (well-defined boundaries)
    // In production, this will come from NeighborhoodBoundaryService
    return [
      BoundaryPolyline(
        id: 'hard-1',
        locality1: 'NoHo',
        locality2: 'SoHo',
        coordinates: [
          const gmap.LatLng(40.7280, -73.9940),
          const gmap.LatLng(40.7280, -73.9900),
          const gmap.LatLng(40.7250, -73.9900),
          const gmap.LatLng(40.7250, -73.9940),
        ],
        isRefined: false,
      ),
    ];
  }

  List<BoundaryPolyline> _getMockSoftBorders() {
    // Mock soft borders (blended areas)
    // In production, this will come from NeighborhoodBoundaryService
    return [
      BoundaryPolyline(
        id: 'soft-1',
        locality1: 'Nolita',
        locality2: 'East Village',
        coordinates: [
          const gmap.LatLng(40.7220, -73.9920),
          const gmap.LatLng(40.7220, -73.9880),
          const gmap.LatLng(40.7200, -73.9880),
          const gmap.LatLng(40.7200, -73.9920),
        ],
        isRefined: true,
      ),
    ];
  }

  List<SoftBorderSpot> _getMockSoftBorderSpots() {
    // Mock soft border spots
    // In production, this will come from NeighborhoodBoundaryService
    return [
      SoftBorderSpot(
        spotId: 'spot-1',
        name: 'Cafe Example',
        position: const gmap.LatLng(40.7210, -73.9900),
        locality1: 'Nolita',
        locality2: 'East Village',
      ),
    ];
  }

  Map<String, bool> _getMockRefinedBorders() {
    // Mock refined borders
    // In production, this will come from NeighborhoodBoundaryService
    return {
      'soft-1': true,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_hardBorders.isEmpty && _softBorders.isEmpty) {
      return _buildEmptyState();
    }

    return _buildBoundaryOverlay();
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: StandardLoadingWidget.container(
        message: 'Loading boundaries...',
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StandardErrorWidget(
            message: _error ?? 'Error loading boundaries',
            onRetry: _loadBoundaries,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      width: widget.width,
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
              color: AppColors.grey400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No boundaries available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoundaryOverlay() {
    // This widget provides boundary data to be overlaid on a map
    // The actual map rendering is handled by the parent (MapView)
    // This widget provides the polylines and markers to add to the map
    
    return Container(
      height: widget.height,
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          _buildLegend(),
          const SizedBox(height: 8),
          // Boundary info
          Expanded(
            child: _buildBoundaryInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            'Hard Border',
            AppTheme.primaryColor,
            isDashed: false,
          ),
          _buildLegendItem(
            'Soft Border',
            AppColors.grey600,
            isDashed: true,
          ),
          if (widget.showSoftBorderSpots)
            _buildLegendItem(
              'Soft Spot',
              AppColors.warning,
              isDashed: false,
              isSpot: true,
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color, {
    bool isDashed = false,
    bool isSpot = false,
  }) {
    return Row(
      children: [
        if (isSpot)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              border: isDashed
                  ? Border.all(
                      color: color,
                      width: 1,
                      style: BorderStyle.solid,
                    )
                  : null,
            ),
            child: isDashed
                ? CustomPaint(
                    painter: DashedLinePainter(color: color),
                  )
                : null,
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBoundaryInfo() {
    return ListView(
      children: [
        if (_hardBorders.isNotEmpty) ...[
          const Text(
            'Hard Borders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._hardBorders.map((border) => _buildBoundaryCard(border, isHard: true)),
          const SizedBox(height: 16),
        ],
        if (_softBorders.isNotEmpty) ...[
          const Text(
            'Soft Borders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._softBorders.map((border) => _buildBoundaryCard(border, isHard: false)),
        ],
      ],
    );
  }

  Widget _buildBoundaryCard(BoundaryPolyline border, {required bool isHard}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isHard ? Icons.border_clear : Icons.border_color,
          color: isHard ? AppTheme.primaryColor : AppColors.grey600,
        ),
        title: Text(
          '${border.locality1} / ${border.locality2}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          isHard ? 'Well-defined boundary' : 'Blended area',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: widget.showRefinementIndicators && border.isRefined
            ? Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 20,
              )
            : null,
        onTap: widget.onBorderTapped != null
            ? () => widget.onBorderTapped!(border.locality1, border.locality2)
            : null,
      ),
    );
  }

  /// Get polylines for Google Maps
  /// This method should be called by the parent MapView to add boundaries to the map
  Set<gmap.Polyline> getPolylines() {
    final polylines = <gmap.Polyline>{};

    // Add hard borders (solid lines)
    for (final border in _hardBorders) {
      polylines.add(
        gmap.Polyline(
          polylineId: gmap.PolylineId(border.id),
          points: border.coordinates,
          color: AppTheme.primaryColor,
          width: 3,
          patterns: [],
        ),
      );
    }

    // Add soft borders (dashed lines)
    for (final border in _softBorders) {
      polylines.add(
        gmap.Polyline(
          polylineId: gmap.PolylineId(border.id),
          points: border.coordinates,
          color: AppColors.grey600,
          width: 2,
          patterns: [
            gmap.PatternItem.dash(10),
            gmap.PatternItem.gap(5),
          ],
        ),
      );
    }

    return polylines;
  }

  /// Get markers for soft border spots
  /// This method should be called by the parent MapView to add soft border spot markers
  Set<gmap.Marker> getSoftBorderSpotMarkers() {
    if (!widget.showSoftBorderSpots) {
      return {};
    }

    final markers = <gmap.Marker>{};

    for (final spot in _softBorderSpots) {
      markers.add(
        gmap.Marker(
          markerId: gmap.MarkerId('soft-spot-${spot.spotId}'),
          position: spot.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
          infoWindow: gmap.InfoWindow(
            title: spot.name,
            snippet: 'Shared: ${spot.locality1} / ${spot.locality2}',
          ),
          onTap: widget.onSoftBorderSpotTapped != null
              ? () => widget.onSoftBorderSpotTapped!(spot.spotId)
              : null,
        ),
      );
    }

    return markers;
  }
}

/// Boundary polyline data model
class BoundaryPolyline {
  final String id;
  final String locality1;
  final String locality2;
  final List<gmap.LatLng> coordinates;
  final bool isRefined;

  BoundaryPolyline({
    required this.id,
    required this.locality1,
    required this.locality2,
    required this.coordinates,
    this.isRefined = false,
  });
}

/// Soft border spot data model
class SoftBorderSpot {
  final String spotId;
  final String name;
  final gmap.LatLng position;
  final String locality1;
  final String locality2;

  SoftBorderSpot({
    required this.spotId,
    required this.name,
    required this.position,
    required this.locality1,
    required this.locality2,
  });
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

