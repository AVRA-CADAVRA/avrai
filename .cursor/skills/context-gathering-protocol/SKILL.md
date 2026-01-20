---
name: context-gathering-protocol
description: Enforces 40-minute context gathering protocol for implementation tasks. Use when starting new tasks, implementing features, or beginning development work.
---

# Context Gathering Protocol

## Mandatory for Implementation Tasks

**Before writing ANY code, spend 40 minutes on context gathering.**

**Time Investment:** 40 minutes  
**Time Saved:** 50-90% (hours to days)  
**Proven ROI:** Multiple 99% time savings in actual implementations

## Trigger Phrases

Read `docs/plans/methodology/START_HERE_NEW_TASK.md` when user says:
- "implement [feature]"
- "create [component]"
- "build [feature]"
- "add [functionality]"
- "start [task]"
- "proceed with [phase]"
- "continue with [feature]"
- "let's do [task]"
- "work on [feature]"

## Mandatory Protocol Steps

1. **Read entry point document:**
   ```
   read_file('docs/plans/methodology/START_HERE_NEW_TASK.md')
   ```

2. **Read philosophy documents (MANDATORY):**
   - `docs/plans/philosophy_implementation/DOORS.md`
   - `OUR_GUTS.md`
   - `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
   - `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`

3. **Check Master Plan:**
   - Read `docs/MASTER_PLAN.md` for execution sequence
   - Check `docs/MASTER_PLAN_TRACKER.md` for all plans

4. **Discover ALL related plans:**
   ```bash
   glob_file_search('**/*[topic]*.md')
   glob_file_search('**/*[topic]*plan*.md')
   ```

5. **Read high-priority related plans**

6. **Search existing implementations:**
   - Look for similar features
   - Check for existing patterns
   - Review related code

7. **Answer doors questions:**
   - What doors? (What does this open?)
   - When ready? (When are users ready?)
   - Good key? (Is this being a good key?)
   - Learning? (Does this enable learning?)

8. **Create TODO list**

9. **Communicate plan to user**

10. **Get user approval**

11. **Begin implementation** (following methodology and philosophy)

## Status Query Protocol

When user asks about status/progress, search for **ALL** related documents:

```bash
glob_file_search('**/*[topic]*.md')
glob_file_search('**/*[topic]*plan*.md')
glob_file_search('**/*[topic]*complete*.md')
glob_file_search('**/*[topic]*progress*.md')
glob_file_search('**/*[topic]*status*.md')
glob_file_search('**/*[topic]*summary*.md')
```

Read ALL found documents, then synthesize comprehensive answer.

## Key Documentation

- **Entry Point:** `docs/plans/methodology/START_HERE_NEW_TASK.md`
- **Quick Reference:** `docs/plans/methodology/SESSION_START_CHECKLIST.md`
- **Full Methodology:** `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`
- **Master Plan:** `docs/MASTER_PLAN.md`
- **Master Plan Tracker:** `docs/MASTER_PLAN_TRACKER.md`

## Critical Warning

**DO NOT skip context gathering to "save time" - it costs more later.**

The 40-minute investment saves hours to days of implementation time.

## Checklist

Before starting implementation:
- [ ] Read START_HERE_NEW_TASK.md
- [ ] Read DOORS.md
- [ ] Read OUR_GUTS.md
- [ ] Read SPOTS Philosophy
- [ ] Read Development Methodology
- [ ] Check Master Plan
- [ ] Check Master Plan Tracker
- [ ] Discover ALL relevant plans
- [ ] Filter by recency + relevance
- [ ] Read high-priority plans
- [ ] Search existing implementations
- [ ] Answer doors questions
- [ ] Create TODO list
- [ ] Communicate plan
- [ ] Get user approval

**If ANY checkbox is unchecked, DO NOT START CODING.**
