---
name: completion-report-generation
description: Guides completion report generation: what was done, what's next, blockers, progress tracking, Master Plan updates. Use when completing phases, sections, or features.
---

# Completion Report Generation

## Report Structure

```markdown
# Phase X.Y.Z Completion Report

**Date:** [Date]
**Agent:** [Agent Name]
**Status:** ✅ Complete

## What Was Done

### Completed Tasks
- [x] Task 1
- [x] Task 2
- [x] Task 3

### Implementation Summary
[Brief summary of what was implemented]

### Key Deliverables
- Deliverable 1: [Description]
- Deliverable 2: [Description]

## What's Next

### Next Phase/Section
- Next task 1
- Next task 2

### Dependencies Satisfied
- Dependency 1 (satisfies Phase X.Y)
- Dependency 2 (enables Phase X.Z)

## Blockers (if any)

None / [List blockers]

## Master Plan Updates

- Updated Phase X.Y status to Complete
- Updated dependencies in Master Plan
- Next phase can now proceed

## Testing

- [x] Unit tests written and passing
- [x] Integration tests written and passing
- [x] Coverage requirements met

## Documentation

- [x] Code documented
- [x] API documentation updated
- [x] Progress documents updated
```

## Master Plan Update Pattern

```markdown
## Master Plan Updates

1. **Status Update:**
   - Phase X.Y.Z: Complete → ✅

2. **Dependencies:**
   - Phase X.Y.Z completion enables Phase X.Y.Z+1

3. **Next Steps:**
   - Proceed to Phase X.Y.Z+1
```

## Progress Tracking

Update progress documents:
- `docs/agents/status/status_tracker.md` - Update phase status
- `docs/plans/[phase]/progress.md` - Update detailed progress
- `docs/plans/[phase]/status.md` - Update current status

## Reference

- `docs/agents/reports/` - Completion report examples
