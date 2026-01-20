---
name: quantum-matching-algorithms
description: Guides quantum matching implementation: state calculations, compatibility formulas, quantum entanglement matching patterns. Use when implementing matching algorithms, compatibility calculations, or quantum state operations.
---

# Quantum Matching Algorithms

## Core Principle

Quantum matching uses quantum state inner products to calculate compatibility between entities (users, spots, events).

## Quantum State Representation

### Create Quantum State
```dart
/// Create quantum state from personality dimensions
QuantumState createPersonalityQuantumState(PersonalityProfile profile) {
  // Convert 12-dimensional personality to quantum state
  final dimensions = profile.dimensions;
  
  return QuantumState(
    // Quantum state vector from dimensions
    vector: _dimensionsToQuantumVector(dimensions),
    // Normalize to unit vector
    normalized: true,
  );
}
```

### Quantum State Inner Product
```dart
/// Calculate quantum inner product (fidelity)
double calculateQuantumFidelity(
  QuantumState stateA,
  QuantumState stateB,
) {
  // Inner product: <stateA | stateB>
  final innerProduct = _quantumInnerProduct(stateA, stateB);
  
  // Fidelity: |<stateA | stateB>|²
  final fidelity = (innerProduct.abs() * innerProduct.abs());
  
  return fidelity.clamp(0.0, 1.0);
}
```

## Compatibility Calculation

### Basic Quantum Compatibility
```dart
/// Calculate quantum compatibility between two entities
double calculateQuantumCompatibility(
  PersonalityProfile profileA,
  PersonalityProfile profileB,
) {
  // Create quantum states
  final stateA = createPersonalityQuantumState(profileA);
  final stateB = createPersonalityQuantumState(profileB);
  
  // Calculate fidelity
  final fidelity = calculateQuantumFidelity(stateA, stateB);
  
  return fidelity;
}
```

### Enhanced Quantum Compatibility
```dart
/// Enhanced quantum compatibility with multiple factors
double calculateEnhancedQuantumCompatibility({
  required PersonalityProfile profileA,
  required PersonalityProfile profileB,
  double archetypeWeight = 0.25,
  double valueWeight = 0.25,
  double quantumWeight = 0.50,
}) {
  // 1. Quantum dimension compatibility (50%)
  final quantumCompat = calculateQuantumCompatibility(profileA, profileB);
  
  // 2. Archetype compatibility (25%)
  final archetypeCompat = _calculateArchetypeCompatibility(
    profileA.archetype,
    profileB.archetype,
  );
  
  // 3. Value alignment (25%)
  final valueAlignment = _calculateValueAlignment(
    profileA.dimensions,
    profileB.dimensions,
  );
  
  // Combined compatibility
  final compatibility = (
    quantumWeight * quantumCompat +
    archetypeWeight * archetypeCompat +
    valueWeight * valueAlignment
  );
  
  return compatibility.clamp(0.0, 1.0);
}
```

## Hybrid Compatibility (Core + Modifiers)

```dart
/// Hybrid compatibility: Core factors (geometric mean) + Modifiers (weighted average)
double calculateHybridCompatibility({
  required double quantumFidelity,
  required double locationCompatibility,
  required double timingCompatibility,
  double? knotCompatibility,
}) {
  // Core factors: Geometric mean (catches critical failures)
  final coreFactors = <double>[quantumFidelity];
  if (knotCompatibility != null) {
    coreFactors.add(knotCompatibility);
  }
  final coreScore = _geometricMean(coreFactors);
  
  // Modifiers: Weighted average (enhance good matches)
  final modifierScore = (
    0.6 * locationCompatibility +
    0.4 * timingCompatibility
  );
  
  // Hybrid combination: core * modifiers
  final compatibility = coreScore * modifierScore;
  
  return compatibility.clamp(0.0, 1.0);
}

double _geometricMean(List<double> values) {
  if (values.isEmpty) return 0.0;
  if (values.any((v) => v <= 0.0)) {
    return 0.0; // Geometric mean requires all positive
  }
  
  final product = values.reduce((a, b) => a * b);
  final mean = pow(product, 1.0 / values.length);
  return mean;
}
```

## Multi-Entity Matching

### User-to-Targets Fidelity
```dart
/// Calculate compatibility between user and multiple targets
double calculateUserToTargetsFidelity({
  required QuantumEntityState userState,
  required List<QuantumEntityState> allStates,
}) {
  final userVector = _quantumEntityStateToVector(userState);
  var total = 0.0;
  var count = 0;
  
  for (final state in allStates) {
    if (state.entityType == QuantumEntityType.user) {
      continue; // Skip user's own state
    }
    
    final targetVector = _quantumEntityStateToVector(state);
    total += _cosineSimilarity(userVector, targetVector);
    count++;
  }
  
  if (count == 0) return 0.5; // Neutral fallback
  return (total / count).clamp(0.0, 1.0);
}
```

## Location Quantum State

### Location Compatibility
```dart
/// Calculate location compatibility using quantum states
double calculateLocationCompatibility({
  required Location locationA,
  required Location locationB,
}) {
  // Create location quantum states
  final stateA = _createLocationQuantumState(
    latitude: locationA.latitude,
    longitude: locationA.longitude,
    type: locationA.type,
    accessibility: locationA.accessibility,
    vibe: locationA.vibe,
  );
  
  final stateB = _createLocationQuantumState(
    latitude: locationB.latitude,
    longitude: locationB.longitude,
    type: locationB.type,
    accessibility: locationB.accessibility,
    vibe: locationB.vibe,
  );
  
  // Calculate compatibility
  final compatibility = abs(_innerProduct(stateA, stateB)) * 
                       abs(_innerProduct(stateA, stateB));
  
  return compatibility.clamp(0.0, 1.0);
}
```

## Quantum Matching Service Pattern

```dart
/// Quantum matching service
class QuantumMatchingService {
  /// Calculate compatibility between user and event
  Future<double> calculateUserEventCompatibility({
    required User user,
    required Event event,
  }) async {
    // Create quantum states
    final userState = createPersonalityQuantumState(user.personality);
    final eventState = createEventQuantumState(event);
    
    // Calculate quantum fidelity
    final quantumFidelity = calculateQuantumFidelity(userState, eventState);
    
    // Calculate location compatibility
    final locationCompat = calculateLocationCompatibility(
      locationA: user.location,
      locationB: event.location,
    );
    
    // Calculate timing compatibility
    final timingCompat = _calculateTimingCompatibility(
      user.preferences,
      event.timing,
    );
    
    // Hybrid compatibility
    return calculateHybridCompatibility(
      quantumFidelity: quantumFidelity,
      locationCompatibility: locationCompat,
      timingCompatibility: timingCompat,
    );
  }
}
```

## Reference

- `lib/core/controllers/quantum_matching_controller.dart` - Quantum matching controller
- `lib/core/services/quantum/quantum_matching_integration_service.dart` - Integration service
- `packages/avrai_quantum/` - Quantum calculation packages
