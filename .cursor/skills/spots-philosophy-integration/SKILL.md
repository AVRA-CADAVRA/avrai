---
name: spots-philosophy-integration
description: Ensures all code aligns with SPOTS core philosophy: "Doors, not badges", meaningful connections, real-world enhancement. Use when implementing features, reviewing code, or making architectural decisions to validate philosophy alignment.
---

# SPOTS Philosophy Integration

## Core Principle

**All development must align with SPOTS philosophy.** This is non-negotiable.

## Key Philosophy Concepts

### The Core Truth
**"There is no secret to life. Just doors that haven't been opened yet."**

### Every Spot is a Door
- Door to experiences
- Door to communities  
- Door to people
- Door to meaning
- Door to more doors

### Meaningful Connections (Primary Purpose)
The entire purpose of SPOTS is to **open doors for meaningful connections**:
1. Meaningful connections exist
2. People can find meaningful connections more easily
3. People can find meaningful connections truthfully

### Real World Enhancement
- Technology enhances real-world experiences, doesn't replace them
- No gamification that replaces authentic engagement
- No capitalization on app usage—enhance life usage
- AI used for right reasons: better real-world experiences

## Validation Checklist

For every feature/implementation, ask:

- [ ] What doors does this help users open?
- [ ] When are users ready for these doors?
- [ ] Does this respect their door history (authenticity)?
- [ ] Does this adapt to their usage pattern?
- [ ] Is this being a good key?
- [ ] Does this enhance the real world experience (not replace it)?
- [ ] Is technology being used for the right reasons?

## Framing Requirements

**Not:** "recommendations" → **Instead:** "Doors"
**Not:** "matches" → **Instead:** "People who open similar doors"
**Not:** "features" → **Instead:** "Door opening mechanisms"
**Not:** "engagement" → **Instead:** "Doors opened"

## Architecture Alignment

- System is **ai2ai only** (never p2p)
- All device interactions through personality learning AI
- AIs must always be self-improving (individual, network, ecosystem)
- Offline-first architecture
- Privacy-preserving (anonymized data exchange)

## Reference Documents

- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - Core philosophy
- `docs/plans/philosophy_implementation/DOORS.md` - Doors conversation
- `OUR_GUTS.md` - Original philosophy (updated with doors)

## Examples

**✅ GOOD:**
```dart
// Opens doors to meaningful community connections
class CommunityEventService {
  // Service helps users discover events at their favorite spots
  // These events are doors to communities
}
```

**❌ BAD:**
```dart
// Gamified recommendation system
class RecommendationEngine {
  // Pushes generic suggestions to increase engagement metrics
  // No consideration for meaningful connections
}
```
