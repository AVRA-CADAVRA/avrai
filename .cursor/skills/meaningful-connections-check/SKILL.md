---
name: meaningful-connections-check
description: Ensures features support meaningful connections, not gamification or engagement metrics. Use when implementing features, reviewing UX, or validating that features serve meaningful connections.
---

# Meaningful Connections Check

## Core Principle

**Meaningful connections is THE core philosophy (after "Opening Doors").**

The entire purpose of SPOTS is to **open doors for meaningful connections**.

## What Makes Connections Meaningful

1. **Meaningful connections exist**
2. **People can find meaningful connections more easily**
3. **People can find meaningful connections truthfully**

## Validation Criteria

### ✅ Supports Meaningful Connections
- Opens doors to real people, real communities, real places
- Enables authentic relationships (not superficial)
- Helps users find their people (not just matches)
- Leads to real-world experiences
- Enhances real-world life (not digital engagement)

### ❌ Does NOT Support Meaningful Connections
- Focuses on engagement metrics (time in app, notifications)
- Gamifies connections (points, badges, streaks)
- Creates superficial interactions (swipes, likes without depth)
- Replaces real-world with digital experiences
- Monopolizes user attention for ad revenue

## SPOTS as Skeleton Key

SPOTS opens doors to:
- **Meaning** - What gives our lives purpose
- **Fulfillment** - What makes us feel complete
- **Happiness** - What brings us joy

## Real-World Enhancement

**Technology enhances the real world experience, doesn't replace it.**

- You find a coffee shop → **You go there in person**
- You discover an event → **You attend it in real life**
- You meet someone through AI2AI → **You connect with them face-to-face**
- You network through SPOTS → **You build relationships in the real world**

## Checklist

- [ ] Does this feature help users find meaningful connections?
- [ ] Does this enhance real-world experiences (not replace them)?
- [ ] Does this avoid gamification that replaces authentic engagement?
- [ ] Does this avoid capitalizing on app usage?
- [ ] Does this use technology for the right reasons?
- [ ] Does this lead to real places, real people, real communities?
- [ ] Does this open doors to meaning, fulfillment, happiness?

## Anti-Patterns

**❌ Engagement Optimization:**
```dart
// BAD: Optimizes for time in app
class EngagementTracker {
  void trackTimeSpent() {
    // Tracks how long user stays in app
    // Violates meaningful connections principle
  }
}
```

**✅ Door Opening:**
```dart
// GOOD: Opens doors to meaningful connections
class CommunityDiscoveryService {
  Future<List<Event>> discoverEvents(User user) async {
    // Discovers events at user's favorite spots
    // Opens doors to communities
    // Leads to real-world experiences
  }
}
```

## Reference

- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- Core Purpose: Meaningful Connections section
