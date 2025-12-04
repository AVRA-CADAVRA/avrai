import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';

class MapThemes {
  // Default SPOTS Blue Theme
  static const MapTheme spotsBlue = MapTheme(
    name: 'SPOTS Blue',
    primaryColor: Color(0xFF1E88E5),
    secondaryColor: Color(0xFF42A5F5),
    accentColor: Color(0xFF64B5F6),
    backgroundColor: Color(0xFFFAFAFA),
    surfaceColor: AppColors.white,
    textColor: Color(0xFF212121),
    waterColor: Color(0xFFE3F2FD),
    landColor: Color(0xFFF5F5F5),
    roadColor: Color(0xFFE0E0E0),
    buildingColor: Color(0xFFEEEEEE),
    tileServer: TileServer.openStreetMap,
  );

  // Dark Theme
  static const MapTheme dark = MapTheme(
    name: 'Dark',
    primaryColor: Color(0xFF1976D2),
    secondaryColor: Color(0xFF42A5F5),
    accentColor: Color(0xFF64B5F6),
    backgroundColor: Color(0xFF121212),
    surfaceColor: Color(0xFF1E1E1E),
    textColor: AppColors.white,
    waterColor: Color(0xFF0D47A1),
    landColor: Color(0xFF2C2C2C),
    roadColor: Color(0xFF424242),
    buildingColor: Color(0xFF3C3C3C),
    tileServer: TileServer.cartoDark,
  );

  // Nature Green Theme
  static const MapTheme nature = MapTheme(
    name: 'Nature',
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF66BB6A),
    accentColor: Color(0xFF81C784),
    backgroundColor: Color(0xFFF1F8E9),
    surfaceColor: AppColors.white,
    textColor: Color(0xFF2E7D32),
    waterColor: Color(0xFFE8F5E8),
    landColor: Color(0xFFF9FBE7),
    roadColor: Color(0xFFE8F5E8),
    buildingColor: Color(0xFFF1F8E9),
    tileServer: TileServer.cartoPositron,
  );

  // Sunset Orange Theme
  static const MapTheme sunset = MapTheme(
    name: 'Sunset',
    primaryColor: Color(0xFFFF5722),
    secondaryColor: Color(0xFFFF7043),
    accentColor: Color(0xFFFF8A65),
    backgroundColor: Color(0xFFFFF3E0),
    surfaceColor: AppColors.white,
    textColor: Color(0xFFD84315),
    waterColor: Color(0xFFFFE0B2),
    landColor: Color(0xFFFFF8E1),
    roadColor: Color(0xFFFFE0B2),
    buildingColor: Color(0xFFFFF3E0),
    tileServer: TileServer.stadiaAlidade,
  );

  // Purple Theme
  static const MapTheme purple = MapTheme(
    name: 'Purple',
    primaryColor: Color(0xFF9C27B0),
    secondaryColor: Color(0xFFBA68C8),
    accentColor: Color(0xFFCE93D8),
    backgroundColor: Color(0xFFF3E5F5),
    surfaceColor: AppColors.white,
    textColor: Color(0xFF6A1B9A),
    waterColor: Color(0xFFE1BEE7),
    landColor: Color(0xFFF8F4F9),
    roadColor: Color(0xFFE1BEE7),
    buildingColor: Color(0xFFF3E5F5),
    tileServer: TileServer.cartoVoyager,
  );

  // Minimalist Theme (aligned to global palette)
  static const MapTheme minimalist = MapTheme(
    name: 'Minimalist',
    primaryColor: AppColors.electricGreen,
    secondaryColor: AppColors.grey600,
    accentColor: AppColors.grey400,
    backgroundColor: AppColors.white,
    surfaceColor: AppColors.white,
    textColor: AppColors.textPrimary,
    waterColor: AppColors.grey100,
    landColor: AppColors.white,
    roadColor: AppColors.grey200,
    buildingColor: AppColors.grey50,
    tileServer: TileServer.cartoPositron,
  );

  // Satellite Theme
  static const MapTheme satellite = MapTheme(
    name: 'Satellite',
    primaryColor: Color(0xFF1976D2),
    secondaryColor: Color(0xFF42A5F5),
    accentColor: Color(0xFF64B5F6),
    backgroundColor: Color(0xFF121212),
    surfaceColor: Color(0xFF1E1E1E),
    textColor: AppColors.white,
    waterColor: Color(0xFF0D47A1),
    landColor: Color(0xFF2C2C2C),
    roadColor: Color(0xFF424242),
    buildingColor: Color(0xFF3C3C3C),
    tileServer: TileServer.esriSatellite,
  );

  // Terrain Theme
  static const MapTheme terrain = MapTheme(
    name: 'Terrain',
    primaryColor: Color(0xFF8D6E63),
    secondaryColor: Color(0xFFA1887F),
    accentColor: Color(0xFFBCAAA4),
    backgroundColor: Color(0xFFEFEBE9),
    surfaceColor: AppColors.white,
    textColor: Color(0xFF5D4037),
    waterColor: Color(0xFFE3F2FD),
    landColor: Color(0xFFF5F5F5),
    roadColor: Color(0xFFE0E0E0),
    buildingColor: Color(0xFFEEEEEE),
    tileServer: TileServer.esriTopo,
  );

  // Outdoors Theme
  static const MapTheme outdoors = MapTheme(
    name: 'Outdoors',
    primaryColor: Color(0xFF2E7D32),
    secondaryColor: Color(0xFF4CAF50),
    accentColor: Color(0xFF66BB6A),
    backgroundColor: Color(0xFFF1F8E9),
    surfaceColor: AppColors.white,
    textColor: Color(0xFF1B5E20),
    waterColor: Color(0xFFE8F5E8),
    landColor: Color(0xFFF9FBE7),
    roadColor: Color(0xFFE8F5E8),
    buildingColor: Color(0xFFF1F8E9),
    tileServer: TileServer.stadiaOutdoors,
  );

  // Street Theme
  static const MapTheme street = MapTheme(
    name: 'Street',
    primaryColor: Color(0xFF1976D2),
    secondaryColor: Color(0xFF42A5F5),
    accentColor: Color(0xFF64B5F6),
    backgroundColor: Color(0xFFFAFAFA),
    surfaceColor: AppColors.white,
    textColor: Color(0xFF0D47A1),
    waterColor: Color(0xFFE3F2FD),
    landColor: Color(0xFFF5F5F5),
    roadColor: Color(0xFFE0E0E0),
    buildingColor: Color(0xFFEEEEEE),
    tileServer: TileServer.esriStreet,
  );

  // All available themes
  static const List<MapTheme> allThemes = [
    spotsBlue,
    dark,
    nature,
    sunset,
    purple,
    minimalist,
    satellite,
    terrain,
    outdoors,
    street,
  ];
}

enum TileServer {
  openStreetMap,
  cartoPositron,
  cartoDark,
  cartoVoyager,
  stadiaAlidade,
  stadiaOutdoors,
  esriSatellite,
  esriTopo,
  esriStreet,
}

class MapTheme {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color waterColor;
  final Color landColor;
  final Color roadColor;
  final Color buildingColor;
  final TileServer tileServer;

  const MapTheme({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.waterColor,
    required this.landColor,
    required this.roadColor,
    required this.buildingColor,
    required this.tileServer,
  });

  // Get CSS filter for OpenStreetMap tiles
  String get cssFilter {
    // Convert colors to CSS filter values
    // This is a simplified approach - for more precise control,
    // you'd need to calculate specific filter values
    return 'brightness(0.9) contrast(1.1) saturate(1.2)';
  }

  // Get tile URL with custom styling
  String getTileUrl(int z, int x, int y) {
    switch (tileServer) {
      case TileServer.openStreetMap:
        return 'https://tile.openstreetmap.org/$z/$x/$y.png';
      case TileServer.cartoPositron:
        return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/$z/$x/$y.png';
      case TileServer.cartoDark:
        return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/$z/$x/$y.png';
      case TileServer.cartoVoyager:
        return 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/$z/$x/$y.png';
      case TileServer.stadiaAlidade:
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png';
      case TileServer.stadiaOutdoors:
        return 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png';
      case TileServer.esriSatellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case TileServer.esriTopo:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
      case TileServer.esriStreet:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  // Get subdomains for tile servers that need them
  List<String>? getSubdomains() {
    switch (tileServer) {
      case TileServer.cartoPositron:
      case TileServer.cartoDark:
      case TileServer.cartoVoyager:
        return ['a', 'b', 'c', 'd'];
      case TileServer.stadiaAlidade:
      case TileServer.stadiaOutdoors:
        return null; // Uses {r} for retina
      default:
        return null;
    }
  }

  // Get custom tile URL with styling (if available)
  String? getCustomTileUrl(int z, int x, int y) {
    // You could implement custom tile servers here
    // For example, Mapbox with custom styles
    return null;
  }

  // Get display name for tile server
  String get tileServerName {
    switch (tileServer) {
      case TileServer.openStreetMap:
        return 'OpenStreetMap';
      case TileServer.cartoPositron:
        return 'CartoDB Positron';
      case TileServer.cartoDark:
        return 'CartoDB Dark';
      case TileServer.cartoVoyager:
        return 'CartoDB Voyager';
      case TileServer.stadiaAlidade:
        return 'Stadia Alidade';
      case TileServer.stadiaOutdoors:
        return 'Stadia Outdoors';
      case TileServer.esriSatellite:
        return 'ESRI Satellite';
      case TileServer.esriTopo:
        return 'ESRI Topo';
      case TileServer.esriStreet:
        return 'ESRI Street';
    }
  }
}
