import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:flutter_map/flutter_map.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/map/map_boundary.dart';

/// Converts unified MapBoundary data to map-specific types.
///
/// This allows boundary rendering to work on both Google Maps and flutter_map
/// by converting from the unified data model to the appropriate map type.
class MapBoundaryConverter {
  /// Convert MapBoundary to Google Maps Polyline
  static gmap.Polyline toGoogleMapsPolyline(MapBoundary boundary) {
    if (boundary.type != MapBoundaryType.polyline) {
      throw ArgumentError('Boundary must be a polyline type');
    }

    final color = _parseColor(boundary.strokeColor, boundary.opacity);

    return gmap.Polyline(
      polylineId: gmap.PolylineId(boundary.id),
      points: boundary.outerRing
          .map((p) => gmap.LatLng(p.latitude, p.longitude))
          .toList(growable: false),
      width: boundary.strokeWidth.round(),
      color: color,
    );
  }

  /// Convert MapBoundary to Google Maps Polygon
  static gmap.Polygon toGoogleMapsPolygon(MapBoundary boundary) {
    if (boundary.type != MapBoundaryType.polygon) {
      throw ArgumentError('Boundary must be a polygon type');
    }

    final strokeColor = _parseColor(boundary.strokeColor, boundary.opacity);
    final fillColor = boundary.fillColor != null
        ? _parseColor(boundary.fillColor!, boundary.opacity)
        : strokeColor;

    return gmap.Polygon(
      polygonId: gmap.PolygonId(boundary.id),
      points: boundary.outerRing
          .map((p) => gmap.LatLng(p.latitude, p.longitude))
          .toList(growable: false),
      holes: boundary.holes
          .map((hole) => hole
              .map((p) => gmap.LatLng(p.latitude, p.longitude))
              .toList(growable: false))
          .toList(growable: false),
      strokeWidth: boundary.strokeWidth.round(),
      strokeColor: strokeColor,
      fillColor: fillColor,
    );
  }

  /// Convert MapBoundary to flutter_map Polyline
  static Polyline toFlutterMapPolyline(MapBoundary boundary) {
    if (boundary.type != MapBoundaryType.polyline) {
      throw ArgumentError('Boundary must be a polyline type');
    }

    final color = _parseColor(boundary.strokeColor, boundary.opacity);

    return Polyline(
      points: boundary.outerRing,
      strokeWidth: boundary.strokeWidth,
      color: color,
    );
  }

  /// Convert MapBoundary to flutter_map Polygon
  static Polygon toFlutterMapPolygon(MapBoundary boundary) {
    if (boundary.type != MapBoundaryType.polygon) {
      throw ArgumentError('Boundary must be a polygon type');
    }

    final strokeColor = _parseColor(boundary.strokeColor, boundary.opacity);
    final fillColor = boundary.fillColor != null
        ? _parseColor(boundary.fillColor!, boundary.opacity)
        : strokeColor;

    return Polygon(
      points: boundary.outerRing,
      holePointsList: boundary.holes.isNotEmpty ? boundary.holes : null,
      borderStrokeWidth: boundary.strokeWidth,
      borderColor: strokeColor,
      color: fillColor,
    );
  }

  /// Parse color string to Color object with opacity
  ///
  /// Supports:
  /// - Hex colors: 'FF0000' (6 or 8 digits, without #)
  /// - AppTheme colors: 'primary', 'secondary', 'error'
  static Color _parseColor(String colorString, double opacity) {
    // Handle hex colors (6 or 8 digits, without #)
    if (colorString.length == 6 || colorString.length == 8) {
      try {
        final value = int.parse(colorString, radix: 16);
        if (colorString.length == 6) {
          // RGB - add alpha, then apply opacity
          final color = Color(value | 0xFF000000);
          return color.withValues(alpha: opacity);
        } else {
          // ARGB - use existing alpha, then apply opacity
          final color = Color(value);
          return color.withValues(alpha: color.a * opacity);
        }
      } catch (e) {
        // Invalid hex, fall through to named colors
      }
    }

    // Handle AppTheme colors
    switch (colorString.toLowerCase()) {
      case 'primary':
        return AppTheme.primaryColor.withValues(alpha: opacity);
      case 'secondary':
        return AppColors.secondary.withValues(alpha: opacity);
      case 'error':
        return AppColors.error.withValues(alpha: opacity);
      default:
        // Fallback to black
        return Colors.black.withValues(alpha: opacity);
    }
  }
}
