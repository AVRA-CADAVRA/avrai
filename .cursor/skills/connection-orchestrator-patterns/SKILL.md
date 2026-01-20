---
name: connection-orchestrator-patterns
description: Guides connection orchestration patterns: Personality AI Layer routing, compatibility scoring, connection prioritization. Use when implementing AI2AI connections, device communication, or connection management.
---

# Connection Orchestrator Patterns

## Core Principle

**All device connections route through Personality AI Layer, NOT direct peer-to-peer.**

## Connection Orchestration Flow

```
Device Discovery → Extract Personality → Calculate Compatibility → Route Through AI Layer → Establish Connection
```

## Implementation Pattern

```dart
/// Connection Orchestrator
/// 
/// Routes all device interactions through Personality AI Layer
class ConnectionOrchestrator {
  final PersonalityLearningAI _personalityAI;
  final DeviceDiscoveryService _discoveryService;
  
  /// Establish AI2AI connection (routed through Personality AI Layer)
  Future<void> connectToDevice(DiscoveredDevice device) async {
    // Step 1: Extract anonymized personality data
    final personalityData = await _personalityAI.extractAnonymizedData(device);
    
    // Step 2: Calculate compatibility through Personality AI Layer
    final compatibility = await _personalityAI.calculateCompatibility(
      localPersonality: await _personalityAI.getLocalPersonality(),
      remotePersonality: personalityData,
    );
    
    // Step 3: Route connection through Personality AI Layer
    await _personalityAI.establishConnection(
      device: device,
      compatibility: compatibility,
    );
  }
}
```

## Compatibility Scoring

```dart
/// Calculate compatibility score between personalities
Future<double> calculateCompatibility({
  required AnonymizedPersonalityData localPersonality,
  required AnonymizedPersonalityData remotePersonality,
}) async {
  // Calculate compatibility using 12-dimensional personality spectrum
  final compatibility = await _personalityAI.calculatePersonalityCompatibility(
    localDimensions: localPersonality.dimensions,
    remoteDimensions: remotePersonality.dimensions,
  );
  
  return compatibility; // 0.0 to 1.0
}
```

## Connection Prioritization

```dart
/// Prioritize connections based on compatibility
Future<List<ConnectionCandidate>> prioritizeConnections(
  List<DiscoveredDevice> devices,
) async {
  final candidates = <ConnectionCandidate>[];
  
  for (final device in devices) {
    final personalityData = await extractPersonalityData(device);
    if (personalityData == null) continue;
    
    final compatibility = await calculateCompatibility(
      localPersonality: await getLocalPersonality(),
      remotePersonality: personalityData,
    );
    
    candidates.add(ConnectionCandidate(
      device: device,
      compatibility: compatibility,
    ));
  }
  
  // Sort by compatibility (highest first)
  candidates.sort((a, b) => b.compatibility.compareTo(a.compatibility));
  
  return candidates;
}
```

## Reference

- `lib/core/ai2ai/connection_orchestrator.dart`
- `docs/ai2ai/02_architecture/ARCHITECTURE_LAYERS.md`
