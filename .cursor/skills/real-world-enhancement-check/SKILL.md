---
name: real-world-enhancement-check
description: Validates technology enhances real world experience, doesn't replace it. Use when implementing features, reviewing UX, or ensuring technology serves life rather than replaces it.
---

# Real-World Enhancement Check

## Core Principle

**SPOTS is about enhancing the real world experience, not replacing it with online systems.**

## Validation Criteria

### ✅ Enhances Real World
- Technology enhances real-world experiences
- Features lead to in-person interactions
- App usage leads to life experiences
- AI guides users to real places, real people

### ❌ Replaces Real World
- Technology replaces real-world engagement
- Gamification replaces authentic experiences
- App usage becomes the goal (not life enhancement)
- Virtual experiences replace in-person

## What Technology Should Do

**From finding new places to meeting people, to making new friends, to networking, to enjoying events—SPOTS enhances your life.**

### Technology as Enhancement
- AI serves to make real-world experiences richer
- Technology guides users to real places, real people
- App facilitates connections that happen in person
- Features enhance actual life experiences

### No Gamification Replacement
- Don't gamify experiences to replace authentic engagement
- Don't create virtual rewards that replace real achievements
- Don't build engagement loops that keep users in app
- Don't replace real-world interactions with digital ones

### No Usage Capitalization
- Don't monetize time in app
- Enhance time in the world
- Features serve life, not metrics
- Success = doors opened in real world, not app engagement

## Examples

### ✅ GOOD: Real-World Enhancement
```dart
/// Event Discovery Service
/// 
/// Enhances real-world: Users discover events → attend in person
class EventDiscoveryService {
  Future<List<Event>> discoverEvents(User user) async {
    // Discovers real-world events at real places
    // Users attend these events in person
    // Technology enhances, doesn't replace
  }
}
```

### ❌ BAD: Replaces Real World
```dart
/// Virtual Experience Service
/// 
/// Replaces real-world with virtual experiences
class VirtualExperienceService {
  Future<void> createVirtualEvent() async {
    // Creates virtual events that replace in-person experiences
    // Users stay in app instead of going to real places
    // Violates real-world enhancement principle
  }
}
```

## Checklist

- [ ] Does this feature lead to in-person experiences?
- [ ] Does this enhance real-world life (not replace it)?
- [ ] Does this avoid gamification that replaces engagement?
- [ ] Does this avoid capitalizing on app usage time?
- [ ] Does this use technology for right reasons?
- [ ] Does this open doors to real places, real people, real events?

## Reference

- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- Real World Enhancement section
