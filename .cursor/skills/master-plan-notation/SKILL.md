---
name: master-plan-notation
description: Enforces Master Plan notation format (Phase.Section.Subsection X.Y.Z). Use when referencing phases, sections, documenting progress, or updating status trackers.
---

# Master Plan Notation

## Mandatory Format

**✅ ALWAYS use Phase.Section.Subsection (X.Y.Z) format**

### Format Examples
- `Phase 8, Section 3, Subsection 2` - Full format
- `8.3.2` - Shorthand format
- `8.3` - Section only (Phase 8, Section 3)
- `8` - Phase only (Phase 8)

### Valid Notations
```
Phase 1, Section 1, Subsection 1 = 1.1.1
Phase 8, Section 3 = 8.3
Phase 14 = 14
```

## Rules

**❌ NEVER use:**
- "Week" terminology
- "Day" terminology
- Mixed formats (e.g., "Phase 8, Week 3")

**✅ ALWAYS use:**
- "Phase X, Section Y, Subsection Z"
- Shorthand: "X.Y.Z"
- Section-only: "X.Y" when referring to entire section

## Where to Use

This format applies to:
- Master Plan references
- Status tracker updates
- Task assignments
- Agent prompts
- Completion reports
- All documentation
- Code comments referencing phases
- TODO comments

## Examples

**✅ GOOD:**
```markdown
## Phase 8.3.2 Completion

Completed Phase 8, Section 3, Subsection 2 (8.3.2).

### Next Steps
Proceeding to Phase 8, Section 4 (8.4).
```

```dart
// TODO(Phase 8.3.2): Implement feature X
// Completed in Phase 8.3.2
```

**❌ BAD:**
```markdown
## Week 3 Completion

Completed week 3 of Phase 8.
```

## Reference

- `docs/MASTER_PLAN.md` - Master Plan document
- Notation System section in Master Plan

## Consistency

**MANDATORY:** Never mix old and new formats. Use only Phase.Section.Subsection format consistently throughout all documentation and code.
