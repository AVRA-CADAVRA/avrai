---
name: plan-discovery-workflow
description: Guides plan discovery workflow: glob search, recency filtering, relevance assessment, priority reading. Use when starting new tasks, finding related plans, or gathering context.
---

# Plan Discovery Workflow

## Purpose

Discover and filter all relevant plans before starting implementation.

## Discovery Steps

### Step 1: Search for Plans
```bash
# Search all plans
glob_file_search('**/*plan*.md')
glob_file_search('docs/plans/**/*.md')

# Search by topic
glob_file_search('**/*[topic]*plan*.md')
glob_file_search('**/*[topic]*.md')
```

### Step 2: Filter by Recency
- Check file modification dates
- Prioritize recently updated plans
- Check Master Plan Tracker for active plans

### Step 3: Assess Relevance
- Read plan summaries
- Check plan scope and goals
- Verify alignment with current task

### Step 4: Read High-Priority Plans
- Read most recent relevant plans first
- Read Master Plan for execution order
- Read related implementation plans

## Master Plan Integration

Always check Master Plan:
- Execution order
- Dependencies
- Tier assignments
- Integration points

## Plan Types to Discover

1. **Master Plan** - `docs/MASTER_PLAN.md`
2. **Master Plan Tracker** - `docs/MASTER_PLAN_TRACKER.md`
3. **Phase Plans** - `docs/plans/[phase]/`
4. **Feature Plans** - `docs/plans/[feature]/`
5. **Implementation Plans** - `docs/plans/[feature]/[FEATURE]_PLAN.md`

## Reference

- `docs/MASTER_PLAN.md` - Master Plan execution index
- `docs/MASTER_PLAN_TRACKER.md` - All plans registry
