---
name: ai2ai-protocol-implementation
description: Guides AI2AI protocol implementation: personality learning, anonymous communication, AI2AI-only (never p2p), Personality AI Layer routing. Use when implementing AI2AI features, network protocols, or device communication.
---

# AI2AI Protocol Implementation

## Core Principles

**✅ AI2AI ONLY** - Never peer-to-peer (p2p)
**✅ All device interactions through Personality AI Layer**
**✅ Anonymous communication** - No personal identifiers
**✅ Privacy-preserving** - Anonymized data exchange
**✅ Offline-first** - Works without internet

## Architecture Layers

### Layer 1: Physical Infrastructure Layer
- WiFi/Bluetooth for device discovery
- Network protocols for data transmission
- Platform-specific (iOS/Android/Web)

### Layer 2: Personality AI Layer (Intelligence Router)
- Routes all device interactions
- Personality learning AI intermediary
- Compatibility scoring
- Connection orchestration

## AI2AI Flow

```
Device A → Personality AI Layer → Personality AI Layer → Device B
         (Anonymized)              (Anonymized)
```

**NOT:**
```
Device A → Direct P2P Connection → Device B (❌ FORBIDDEN)
```

## Implementation Pattern

```dart
/// AI2AI Connection Service
/// 
/// All device connections route through Personality AI Layer.
/// Never establishes direct peer-to-peer connections.
class AI2AIConnectionService {
  final PersonalityLearningAI _personalityAI;
  final DeviceDiscoveryService _discoveryService;
  
  /// Establish AI2AI connection (routed through Personality AI Layer)
  Future<void> connectToDevice(Device device) async {
    // Step 1: Discover device
    final discoveredDevice = await _discoveryService.discover(device.id);
    
    // Step 2: Extract anonymized personality data
    final personalityData = _personalityAI.extractAnonymizedData();
    
    // Step 3: Calculate compatibility through Personality AI Layer
    final compatibility = await _personalityAI.calculateCompatibility(
      localPersonality: personalityData,
      remotePersonality: discoveredDevice.personalityData,
    );
    
    // Step 4: Route connection through Personality AI Layer
    await _personalityAI.establishConnection(
      device: discoveredDevice,
      compatibility: compatibility,
    );
  }
}
```

## Personality AI Layer Routing

All device interactions must route through Personality AI Layer:

```dart
/// Connection Orchestrator
/// 
/// Routes all device interactions through Personality AI Layer.
class ConnectionOrchestrator {
  final PersonalityLearningAI _personalityAI;
  
  /// Route message through Personality AI Layer
  Future<void> sendMessage(Device device, Message message) async {
    // Anonymize message through Personality AI Layer
    final anonymized = await _personalityAI.anonymizeMessage(message);
    
    // Route through Personality AI Layer
    await _personalityAI.routeMessage(device, anonymized);
    
    // NEVER send direct peer-to-peer
  }
}
```

## Anonymous Communication

All data exchange must be anonymized:

```dart
/// Extract anonymized personality data for AI2AI exchange
PersonalityData extractAnonymizedPersonality() {
  return PersonalityData(
    // Anonymized personality dimensions (no personal identifiers)
    dimensions: _user.personality.dimensions,
    // NO user ID, email, name, or other PII
  );
}
```

## Learning Methods

AI2AI supports three learning modes:

1. **Personal Learning** - On-device, offline
2. **AI2AI Learning** - Peer-to-peer, offline (routed through Personality AI)
3. **Cloud Learning** - Network intelligence, optional

## Platform Support

- **Android:** BLE + WiFi Direct
- **iOS:** Multipeer Connectivity + mDNS
- **Web:** WebRTC + WebSocket

## Reference

- `docs/ai2ai/02_architecture/ARCHITECTURE_LAYERS.md`
- `lib/core/ai2ai/connection_orchestrator.dart`
- `lib/core/services/ai2ai_learning_service.dart`
