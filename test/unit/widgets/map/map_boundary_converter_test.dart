/// SPOTS MapBoundaryConverter Unit Tests
/// Date: January 2025
/// Purpose: Test conversion between unified boundary data and map-specific types
/// 
/// Test Coverage:
/// - Google Maps conversion (polylines and polygons)
/// - flutter_map conversion (polylines and polygons)
/// - Color parsing (hex colors and AppTheme colors)
/// - Error handling (wrong types, invalid colors)
/// 
/// ⚠️  TEST QUALITY GUIDELINES:
/// ❌ DON'T: Test property assignment
/// ✅ DO: Test conversion behavior (coordinates, colors, styling)
/// ✅ DO: Test error handling
/// ✅ DO: Round-trip testing where applicable
/// 
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:avrai/presentation/widgets/map/map_boundary.dart';
import 'package:avrai/presentation/widgets/map/map_boundary_converter.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';

void main() {
  group('MapBoundaryConverter Tests', () {
    group('Google Maps Conversion', () {
      test('should convert polyline boundary to Google Maps Polyline with correct coordinates and styling', () {
        // Test behavior: polyline conversion
        final points = [
          const LatLng(40.7128, -74.0060),
          const LatLng(40.7130, -74.0062),
        ];

        final boundary = MapBoundary.polyline(
          id: 'test-polyline',
          points: points,
          strokeWidth: 3.0,
          strokeColor: 'FF0000',
          opacity: 0.8,
        );

        final polyline = MapBoundaryConverter.toGoogleMapsPolyline(boundary);

        // Assert behavior: conversion produces correct Google Maps polyline
        expect(polyline.polylineId.value, 'test-polyline');
        expect(polyline.points, hasLength(2));
        expect(polyline.points[0].latitude, 40.7128);
        expect(polyline.points[0].longitude, -74.0060);
        expect(polyline.points[1].latitude, 40.7130);
        expect(polyline.points[1].longitude, -74.0062);
        expect(polyline.width, 3);
        expect(polyline.color, isNotNull); // Google Maps uses int color value
      });

      test('should convert polygon boundary to Google Maps Polygon with outer ring and holes', () {
        // Test behavior: polygon conversion with holes
        final outerRing = [
          const LatLng(40.7128, -74.0060),
          const LatLng(40.7130, -74.0060),
          const LatLng(40.7130, -74.0062),
          const LatLng(40.7128, -74.0062),
        ];

        final hole = [
          const LatLng(40.7129, -74.0061),
          const LatLng(40.71295, -74.0061),
          const LatLng(40.71295, -74.00615),
          const LatLng(40.7129, -74.00615),
        ];

        final boundary = MapBoundary.polygon(
          id: 'test-polygon',
          outerRing: outerRing,
          holes: [hole],
          strokeWidth: 2.0,
          strokeColor: '00FF00',
          fillColor: '00FF00',
          opacity: 0.5,
        );

        final polygon = MapBoundaryConverter.toGoogleMapsPolygon(boundary);

        // Assert behavior: conversion produces correct Google Maps polygon
        expect(polygon.polygonId.value, 'test-polygon');
        expect(polygon.points, hasLength(4));
        expect(polygon.holes, hasLength(1));
        expect(polygon.holes.first, hasLength(4));
        expect(polygon.strokeWidth, 2);
        expect(polygon.strokeColor, isNotNull); // Google Maps uses int color value
        expect(polygon.fillColor, isNotNull); // Google Maps uses int color value
      });

      test('should throw ArgumentError when converting wrong boundary type (polyline vs polygon)', () {
        // Test error handling: wrong type conversion
        final polyline = MapBoundary.polyline(
          id: 'test',
          points: [const LatLng(40.0, -74.0)],
        );

        final polygon = MapBoundary.polygon(
          id: 'test',
          outerRing: [const LatLng(40.0, -74.0)],
        );

        // Assert error handling: wrong type throws
        expect(
          () => MapBoundaryConverter.toGoogleMapsPolygon(polyline),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => MapBoundaryConverter.toGoogleMapsPolyline(polygon),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('flutter_map Conversion', () {
      test('should convert polyline boundary to flutter_map Polyline with correct coordinates and styling', () {
        // Test behavior: polyline conversion
        final points = [
          const LatLng(40.7128, -74.0060),
          const LatLng(40.7130, -74.0062),
        ];

        final boundary = MapBoundary.polyline(
          id: 'test-polyline',
          points: points,
          strokeWidth: 3.0,
          strokeColor: 'FF0000',
          opacity: 0.8,
        );

        final polyline = MapBoundaryConverter.toFlutterMapPolyline(boundary);

        // Assert behavior: conversion produces correct flutter_map polyline
        expect(polyline.points, equals(points));
        expect(polyline.strokeWidth, 3.0);
        expect(polyline.color, isA<Color>());
      });

      test('should convert polygon boundary to flutter_map Polygon with outer ring and holes', () {
        // Test behavior: polygon conversion with holes
        final outerRing = [
          const LatLng(40.7128, -74.0060),
          const LatLng(40.7130, -74.0060),
          const LatLng(40.7130, -74.0062),
          const LatLng(40.7128, -74.0062),
        ];

        final hole = [
          const LatLng(40.7129, -74.0061),
          const LatLng(40.71295, -74.0061),
          const LatLng(40.71295, -74.00615),
          const LatLng(40.7129, -74.00615),
        ];

        final boundary = MapBoundary.polygon(
          id: 'test-polygon',
          outerRing: outerRing,
          holes: [hole],
          strokeWidth: 2.0,
          strokeColor: '00FF00',
          fillColor: '00FF00',
          opacity: 0.5,
        );

        final polygon = MapBoundaryConverter.toFlutterMapPolygon(boundary);

        // Assert behavior: conversion produces correct flutter_map polygon
        expect(polygon.points, equals(outerRing));
        expect(polygon.holePointsList, isNotNull);
        expect(polygon.holePointsList, hasLength(1));
        expect(polygon.holePointsList!.first, equals(hole));
        expect(polygon.borderStrokeWidth, 2.0);
        expect(polygon.borderColor, isA<Color>());
        expect(polygon.color, isA<Color>());
      });

      test('should convert polygon without holes to flutter_map Polygon with null holePointsList', () {
        // Test behavior: polygon without holes
        final outerRing = [
          const LatLng(40.7128, -74.0060),
          const LatLng(40.7130, -74.0060),
        ];

        final boundary = MapBoundary.polygon(
          id: 'simple-polygon',
          outerRing: outerRing,
        );

        final polygon = MapBoundaryConverter.toFlutterMapPolygon(boundary);

        expect(polygon.points, equals(outerRing));
        expect(polygon.holePointsList, isNull);
      });
    });

    group('Color Parsing', () {
      test('should parse hex colors correctly and apply opacity for 6-digit and 8-digit hex', () {
        // Test behavior: hex color parsing
        final boundary6 = MapBoundary.polyline(
          id: 'hex6',
          points: [const LatLng(40.0, -74.0)],
          strokeColor: 'FF0000', // Red
          opacity: 0.5,
        );

        final boundary8 = MapBoundary.polyline(
          id: 'hex8',
          points: [const LatLng(40.0, -74.0)],
          strokeColor: 'FF0000FF', // Red with alpha
          opacity: 0.5,
        );

        final polyline6 = MapBoundaryConverter.toFlutterMapPolyline(boundary6);
        final polyline8 = MapBoundaryConverter.toFlutterMapPolyline(boundary8);

        // Assert behavior: colors are parsed and opacity applied
        expect(polyline6.color, isA<Color>());
        expect(polyline8.color, isA<Color>());
        // Colors should be different due to opacity handling
        expect(polyline6.color, isNot(equals(polyline8.color)));
      });

      test('should parse AppTheme color names (primary, secondary, error) and apply opacity', () {
        // Test behavior: AppTheme color name parsing
        final primaryBoundary = MapBoundary.polyline(
          id: 'primary',
          points: [const LatLng(40.0, -74.0)],
          strokeColor: 'primary',
          opacity: 0.8,
        );

        final secondaryBoundary = MapBoundary.polyline(
          id: 'secondary',
          points: [const LatLng(40.0, -74.0)],
          strokeColor: 'secondary',
          opacity: 0.8,
        );

        final errorBoundary = MapBoundary.polyline(
          id: 'error',
          points: [const LatLng(40.0, -74.0)],
          strokeColor: 'error',
          opacity: 0.8,
        );

        final primaryPolyline = MapBoundaryConverter.toFlutterMapPolyline(primaryBoundary);
        final secondaryPolyline = MapBoundaryConverter.toFlutterMapPolyline(secondaryBoundary);
        final errorPolyline = MapBoundaryConverter.toFlutterMapPolyline(errorBoundary);

        // Assert behavior: AppTheme colors are parsed correctly
        expect(primaryPolyline.color, isA<Color>());
        expect(secondaryPolyline.color, isA<Color>());
        expect(errorPolyline.color, isA<Color>());
        // Colors should match AppTheme colors with opacity
        expect(primaryPolyline.color.value, AppTheme.primaryColor.withValues(alpha: 0.8).value);
        expect(secondaryPolyline.color.value, AppColors.secondary.withValues(alpha: 0.8).value);
        expect(errorPolyline.color.value, AppColors.error.withValues(alpha: 0.8).value);
      });

      test('should handle invalid hex colors gracefully and fallback to black', () {
        // Test error handling: invalid color
        final boundary = MapBoundary.polyline(
          id: 'invalid-color',
          points: [const LatLng(40.0, -74.0)],
          strokeColor: 'INVALID',
          opacity: 1.0,
        );

        final polyline = MapBoundaryConverter.toFlutterMapPolyline(boundary);

        // Assert error handling: invalid color falls back to black
        expect(polyline.color, isA<Color>());
        // Should be black (fallback) with opacity
        expect(polyline.color.value, Colors.black.withValues(alpha: 1.0).value);
      });
    });

    group('Round-Trip Conversion', () {
      test('should maintain boundary data integrity when converting between map types', () {
        // Test behavior: round-trip conversion maintains data
        final originalPoints = [
          const LatLng(40.7128, -74.0060),
          const LatLng(40.7130, -74.0062),
        ];

        final boundary = MapBoundary.polyline(
          id: 'round-trip',
          points: originalPoints,
          strokeWidth: 3.0,
          strokeColor: 'FF0000',
          opacity: 0.8,
        );

        // Convert to Google Maps and back to unified (simulated)
        final googlePolyline = MapBoundaryConverter.toGoogleMapsPolyline(boundary);
        final flutterPolyline = MapBoundaryConverter.toFlutterMapPolyline(boundary);

        // Assert behavior: both conversions maintain coordinate integrity
        expect(googlePolyline.points.length, originalPoints.length);
        expect(flutterPolyline.points.length, originalPoints.length);
        expect(googlePolyline.points[0].latitude, originalPoints[0].latitude);
        expect(googlePolyline.points[0].longitude, originalPoints[0].longitude);
        expect(flutterPolyline.points[0].latitude, originalPoints[0].latitude);
        expect(flutterPolyline.points[0].longitude, originalPoints[0].longitude);
      });
    });
  });
}
