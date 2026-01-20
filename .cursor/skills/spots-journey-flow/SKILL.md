---
name: spots-journey-flow
description: Ensures features support Spots → Community → Life journey flow. Use when implementing features, reviewing UX flows, or validating that features enable the complete user journey.
---

# SPOTS Journey Flow

## Core Journey

Every feature must support the journey:
```
Find YOUR Spots (Doors)
      ↓
Those spots have communities
      ↓
Those communities have events  
      ↓
You find YOUR people
      ↓
You find YOUR life
```

## Journey Stages

### Stage 1: Find Your Spots
**What:** Users discover meaningful places
**Features:** Spot discovery, search, recommendations

### Stage 2: Spots Have Communities
**What:** Spots reveal communities that gather there
**Features:** Community discovery, spot-community linking

### Stage 3: Communities Have Events
**What:** Communities host events at spots
**Features:** Event discovery, event creation, event attendance

### Stage 4: Find Your People
**What:** Users find meaningful connections through spots/communities/events
**Features:** AI2AI connections, personality matching, community membership

### Stage 5: Find Your Life
**What:** Users build life through meaningful connections
**Features:** Personal growth tracking, journey visualization, life enrichment

## Feature Validation

For every feature, ask:

- [ ] Does this help users find spots?
- [ ] Does this reveal communities at spots?
- [ ] Does this enable events at spots/communities?
- [ ] Does this help users find their people?
- [ ] Does this contribute to finding life?

## Examples

### ✅ GOOD: Supports Journey
```dart
/// Event Discovery Service
/// 
/// Supports journey: Spots → Communities → Events → People → Life
class EventDiscoveryService {
  /// Discover events at user's favorite spots (Stage 1 → Stage 3)
  Future<List<Event>> discoverEventsAtSpots(List<Spot> favoriteSpots) async {
    // Finds events at spots user loves
    // Connects Stage 1 (Spots) to Stage 3 (Events)
  }
  
  /// Discover events from communities user is part of (Stage 2 → Stage 3)
  Future<List<Event>> discoverEventsFromCommunities(List<Community> communities) async {
    // Finds events from communities user belongs to
    // Connects Stage 2 (Communities) to Stage 3 (Events)
  }
}
```

### ❌ BAD: Doesn't Support Journey
```dart
/// Generic Recommendation Service
/// 
/// Just recommends things, doesn't support journey
class GenericRecommendationService {
  Future<List<Item>> getRecommendations() async {
    // Doesn't connect to spots, communities, or events
    // Doesn't support journey flow
  }
}
```

## Reference

- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- Journey: Spots → Community → Life section
