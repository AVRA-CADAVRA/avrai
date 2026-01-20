---
name: geographic-services-patterns
description: Guides geographic services patterns: locality agents, geofence planning, location-based features, geographic hierarchy. Use when implementing location-based features, geofencing, or geographic services.
---

# Geographic Services Patterns

## Geographic Hierarchy

```
Locality → City → State → National → Global → Universal
```

## Locality Agents

```dart
/// Locality Agent Service
/// 
/// Manages locality-specific AI agents
class LocalityAgentService {
  /// Get locality agent for location
  Future<LocalityAgent> getLocalityAgent({
    required double latitude,
    required double longitude,
  }) async {
    // Determine locality from coordinates
    final locality = await _geoHierarchyService.getLocality(
      latitude: latitude,
      longitude: longitude,
    );
    
    // Get or create locality agent
    return await _localityAgentRepository.getOrCreateAgent(locality);
  }
}
```

## Geofence Planning

```dart
/// Geofence Planner
/// 
/// Plans geofences for locality agents
class GeofencePlanner {
  /// Create geofence for locality
  Future<Geofence> createLocalityGeofence(Locality locality) async {
    // Get locality boundaries
    final boundaries = await _geoHierarchyService.getLocalityBoundaries(locality);
    
    // Create geofence
    return Geofence(
      id: locality.id,
      name: locality.name,
      boundaries: boundaries,
      type: GeofenceType.locality,
    );
  }
  
  /// Register geofence with OS
  Future<void> registerGeofence(Geofence geofence) async {
    await _osGeofenceRegistrar.register(
      geofence: geofence,
      onEnter: _onGeofenceEnter,
      onExit: _onGeofenceExit,
    );
  }
}
```

## Location-Based Features

```dart
/// Geographic Scope Service
/// 
/// Determines geographic scope for features
class GeographicScopeService {
  /// Get geographic scope for user
  Future<GeographicScope> getScope({
    required double latitude,
    required double longitude,
  }) async {
    // Determine locality
    final locality = await _getLocality(latitude, longitude);
    
    // Determine if large city (has neighborhoods)
    final isLargeCity = await _largeCityDetectionService.isLargeCity(locality.city);
    
    // Determine neighborhood (if applicable)
    String? neighborhood;
    if (isLargeCity) {
      neighborhood = await _neighborhoodService.getNeighborhood(
        latitude: latitude,
        longitude: longitude,
      );
    }
    
    return GeographicScope(
      locality: locality,
      city: locality.city,
      state: locality.state,
      neighborhood: neighborhood,
    );
  }
}
```

## Reference

- `lib/core/services/geo_hierarchy_service.dart`
- `lib/core/services/locality_agents/locality_agent_engine.dart`
- `lib/core/services/locality_agents/locality_geofence_planner.dart`
