---
name: status-query-handling
description: Guides status query handling protocol: find all related documents (plan, progress, status, complete), synthesize comprehensive answer. Use when user asks about status, progress, or completion.
---

# Status Query Handling

## Trigger Phrases

When user says:
- "where are we with [topic]"
- "what's the status of [topic]"
- "how far along is [topic]"
- "what's complete in [topic]"
- "show me progress on [topic]"
- "update me on [topic]"

## Mandatory Protocol

**⚠️ CRITICAL: Read ALL related documents, not just one.**

## Search Strategy

Find ALL related documents:

```bash
# Search for all document types
glob_file_search('**/*[topic]*.md')
glob_file_search('**/*[topic]*plan*.md')
glob_file_search('**/*[topic]*complete*.md')
glob_file_search('**/*[topic]*progress*.md')
glob_file_search('**/*[topic]*status*.md')
glob_file_search('**/*[topic]*summary*.md')
glob_file_search('**/*[topic]*COMPLETE*.md')
glob_file_search('**/*[topic]*PROGRESS*.md')
```

## Document Types to Find

1. **Plan Documents**
   - `*_plan.md`
   - `*PLAN.md`
   - `*plan*.md`

2. **Completion Documents**
   - `*complete*.md`
   - `*COMPLETE*.md`
   - `*_complete.md`

3. **Progress Documents**
   - `*progress*.md`
   - `*PROGRESS*.md`
   - `*_progress.md`

4. **Status Documents**
   - `*status*.md`
   - `*STATUS*.md`
   - `*_status.md`
   - `*update*.md`

5. **Summary Documents**
   - `*summary*.md`
   - `*SUMMARY*.md`
   - `*_summary.md`

## Workflow

```
User asks: "Where are we with [topic]?"
    ↓
Step 1: Search ALL document types (5 min)
├─ Search by filename patterns
├─ Search by content (grep)
└─ Find plan, complete, progress, status, summary
    ↓
Step 2: Read ALL found documents (15-20 min)
├─ Read plan document
├─ Read completion document
├─ Read progress document
├─ Read status document
└─ Read summary document (if exists)
    ↓
Step 3: Synthesize comprehensive answer (10 min)
├─ What's planned
├─ What's complete
├─ What's in progress
├─ What's blocked
└─ What's next
```

## Synthesis Pattern

```markdown
## Status: [Topic]

### What's Planned
[From plan document]

### What's Complete
[From completion document]

### What's In Progress
[From progress/status documents]

### Blockers
[From blockers/status documents]

### What's Next
[From plan/status documents]
```

## Reference

- `docs/plans/methodology/START_HERE_NEW_TASK.md` - Status query protocol
- `.cursorrules` - Status Query Triggers section
