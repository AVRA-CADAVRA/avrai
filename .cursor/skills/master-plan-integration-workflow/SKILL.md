---
name: master-plan-integration-workflow
description: Guides Master Plan integration workflow: plan creation, tracker updates, dependency analysis, execution sequence insertion. Use when adding new features to Master Plan or integrating plans into execution sequence.
---

# Master Plan Integration Workflow

## When to Use

**Trigger:** When user says "I want to add [feature]" or "I want to implement [feature]"

**Action Required:** Follow automated workflow to integrate into Master Plan

## Workflow Steps

### Step 1: Create Comprehensive Plan Document

**⚠️ MANDATORY: Before creating plan, read:**
- `docs/plans/philosophy_implementation/DOORS.md`
- `OUR_GUTS.md`
- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`

**Create plan with:**
- Complete implementation details
- Phases, timelines, requirements
- Technical specifications
- Dependencies identified
- **Doors questions answered** (What doors? When ready? Good key? Learning?)
- **Methodology compliance** verified

### Step 2: Create Plan Folder Structure

```bash
docs/plans/[feature_name]/
├── [FEATURE_NAME]_PLAN.md    # Main plan document
├── progress.md                # Detailed progress tracking
├── status.md                  # Current status
├── blockers.md                # Blockers/dependencies
└── working_status.md          # What's being worked on now
```

### Step 3: Initialize Supporting Docs

**progress.md:**
```markdown
# Progress Tracking

## Completed
- [ ] Item 1

## In Progress
- [ ] Item 2

## Upcoming
- [ ] Item 3
```

**status.md:**
```markdown
# Status

**Current Status:** Unassigned
**Last Updated:** [Date]
**Blockers:** None
```

### Step 4: Add to Master Plan Tracker

Update `docs/MASTER_PLAN_TRACKER.md`:

```markdown
### [Feature Name]

**Date:** [Today's Date]
**Status:** Unassigned (for new plans in Master Plan)
**Priority:** CRITICAL / HIGH / MEDIUM / LOW
**Timeline:** [Estimated duration]
**File Path:** `docs/plans/[feature_name]/[FEATURE_NAME]_PLAN.md`
**Dependencies:** [List dependencies]
**Dependents:** [List what depends on this]
```

### Step 5: Analyze for Master Plan Integration

**Determine dependencies:**
- What does this feature need?
- What features depend on this?
- Check Master Plan for dependency conflicts

**Determine tier:**
- **Tier 0:** Blocks many others → must complete first
- **Tier 1:** Independent → can run in parallel
- **Tier 2:** Dependent → can run in parallel once deps satisfied
- **Tier 3:** Advanced → last tier

### Step 6: Insert into Master Plan

Update `docs/MASTER_PLAN.md` execution index:

```markdown
| Phase X | Feature Name | Tier Y | [`plans/[feature]/PLAN.md`](./plans/[feature]/PLAN.md) | Dependencies |
```

**Insert in appropriate position:**
- Respect dependency order
- Consider tier for parallel execution
- Place after dependencies
- Before dependents

### Step 7: Update Status Tracker

Update `docs/agents/status/status_tracker.md`:

```markdown
## Phase X: Feature Name

**Status:** Planned
**Tier:** Y
**Dependencies:** [List]
**Progress:** 0%
```

## Master Plan Notation

**Use Phase.Section.Subsection (X.Y.Z) format:**

- `Phase 8, Section 3, Subsection 2` - Full format
- `8.3.2` - Shorthand
- `8.3` - Section only

**❌ NEVER use "Week" or "Day" terminology**

## Philosophy Validation

**Answer doors questions:**
- What doors? - What doors does this feature open?
- When ready? - When are users ready for these doors?
- Good key? - Is this being a good key?
- Learning? - Does this enable learning?

**Verify architecture:**
- ai2ai only (never p2p)
- offline-first
- self-improving

## Checklist

- [ ] Read philosophy documents
- [ ] Read methodology documents
- [ ] Created comprehensive plan document
- [ ] Created plan folder structure
- [ ] Initialized supporting docs
- [ ] Added to Master Plan Tracker
- [ ] Analyzed dependencies
- [ ] Determined tier
- [ ] Inserted into Master Plan
- [ ] Updated status tracker
- [ ] Answered doors questions
- [ ] Verified architecture alignment
- [ ] Used correct notation (X.Y.Z)

## Reference

- `docs/MASTER_PLAN.md` - Master Plan execution index
- `docs/MASTER_PLAN_TRACKER.md` - Master Plan Tracker
- `.cursorrules_master_plan` - Master Plan cursor rules
- `docs/plans/methodology/MASTER_PLAN_INTEGRATION_GUIDE.md` - Integration guide
