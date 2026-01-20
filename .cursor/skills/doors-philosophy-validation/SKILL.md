---
name: doors-philosophy-validation
description: Validates that features align with "opening doors" concept, meaningful connections, user journey flow. Use when implementing features, reviewing code, or ensuring features serve the doors philosophy.
---

# Doors Philosophy Validation

## Core Validation Questions

For every feature, ask these questions:

1. **What doors?** - What doors does this feature help users open?
2. **When ready?** - When are users ready for these doors?
3. **Good key?** - Is this being a good key (does it unlock doors effectively)?
4. **Learning?** - Does this enable learning about which doors resonate?

## Doors Philosophy Principles

### Every Feature Must Open Doors
- Doors to experiences
- Doors to communities
- Doors to people
- Doors to meaning
- Doors to more doors

### SPOTS Shows Doors, Not Answers
- Not recommendations → **Doors**
- Not matches → **People who open similar doors**
- Not features → **Door opening mechanisms**
- Not engagement → **Doors opened**

## Validation Checklist

- [ ] What doors does this feature help users open?
- [ ] When are users ready for these doors?
- [ ] Does this respect their door history (authenticity)?
- [ ] Does this adapt to their usage pattern?
- [ ] Is this being a good key?
- [ ] Does this enhance the real world experience (not replace it)?
- [ ] Does this preserve authenticity?
- [ ] Does this work offline?
- [ ] Does this respect privacy?

## Examples

### ✅ GOOD: Door-Opening Feature
```dart
/// Event Discovery Service
/// 
/// Opens doors to community events at user's favorite spots.
/// Users discover events → attend events → find communities → find their people.
class EventDiscoveryService {
  // Helps users discover events (doors to communities)
  // Adapts to user's door history
  // Works offline
  // Respects privacy
}
```

### ❌ BAD: Not Door-Opening
```dart
/// Engagement Optimizer
/// 
/// Increases app usage and time in app.
class EngagementOptimizer {
  // Focuses on metrics, not doors
  // Doesn't open doors to meaningful connections
  // Violates "doors, not badges" philosophy
}
```

## Journey Flow Validation

Ensure features support the journey:
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

## Reference

- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/philosophy_implementation/DOORS.md`
