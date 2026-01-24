import 'package:latlong2/latlong.dart';

/// Unified boundary data model that works with both Google Maps and flutter_map.
///
/// This allows boundary rendering to be map-agnostic, converting to
/// map-specific types only when rendering.
class MapBoundary {
  /// Unique identifier for this boundary
  final String id;

  /// Boundary type: polyline or polygon
  final MapBoundaryType type;

  /// Coordinates for the boundary
  /// - For polylines: single list of points
  /// - For polygons: first list is outer ring, subsequent lists are holes
  final List<List<LatLng>> coordinates;

  /// Stroke width
  final double strokeWidth;

  /// Stroke color (as hex or color name)
  final String strokeColor;

  /// Fill color (for polygons only, as hex or color name)
  final String? fillColor;

  /// Opacity (0.0 to 1.0)
  final double opacity;

  const MapBoundary({
    required this.id,
    required this.type,
    required this.coordinates,
    this.strokeWidth = 2.0,
    this.strokeColor = '#000000',
    this.fillColor,
    this.opacity = 1.0,
  });

  /// Create a polyline boundary
  factory MapBoundary.polyline({
    required String id,
    required List<LatLng> points,
    double strokeWidth = 2.0,
    String strokeColor = '#000000',
    double opacity = 1.0,
  }) {
    return MapBoundary(
      id: id,
      type: MapBoundaryType.polyline,
      coordinates: [points],
      strokeWidth: strokeWidth,
      strokeColor: strokeColor,
      fillColor: null,
      opacity: opacity,
    );
  }

  /// Create a polygon boundary
  factory MapBoundary.polygon({
    required String id,
    required List<LatLng> outerRing,
    List<List<LatLng>>? holes,
    double strokeWidth = 2.0,
    String strokeColor = '#000000',
    String? fillColor,
    double opacity = 1.0,
  }) {
    return MapBoundary(
      id: id,
      type: MapBoundaryType.polygon,
      coordinates: [outerRing, ...?holes],
      strokeWidth: strokeWidth,
      strokeColor: strokeColor,
      fillColor: fillColor,
      opacity: opacity,
    );
  }

  /// Get outer ring (first coordinate list)
  List<LatLng> get outerRing => coordinates.isNotEmpty ? coordinates.first : [];

  /// Get holes (all coordinate lists after the first)
  List<List<LatLng>> get holes =>
      coordinates.length > 1 ? coordinates.sublist(1) : [];
}

/// Type of boundary
enum MapBoundaryType {
  /// Polyline (open path)
  polyline,

  /// Polygon (closed shape, can have holes)
  polygon,
}
