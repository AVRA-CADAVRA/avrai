---
name: documentation-refactoring-protocol
description: Enforces documentation refactoring protocol: phase folders, status tracker updates, proper file placement, naming conventions. Use when creating documentation, organizing docs, or updating documentation structure.
---

# Documentation Refactoring Protocol

## Mandatory Protocol

**ALL agents MUST follow the Documentation Refactoring Protocol when creating or organizing documentation.**

## Folder Structure

### Phase-Specific Docs
```
docs/agents/
├── prompts/[phase]/          # Phase-specific prompts
├── tasks/[phase]/            # Phase-specific tasks
└── reports/agent_X/[phase]/  # Agent reports by phase
```

### Shared Docs
```
docs/agents/
├── status/
│   └── status_tracker.md     # SINGLE file for all phases
├── protocols/                 # Shared protocols
└── reference/                 # Shared references
```

## Critical Rules

### ✅ DO
- Create phase folders in `prompts/` and `tasks/`
- Update SINGLE status tracker (`status/status_tracker.md`) with new phase sections
- Organize reports by agent first, then phase
- Place shared docs in `status/`, `protocols/`, `reference/`

### ❌ DO NOT
- Create files in `docs/` root (e.g., `docs/PHASE_3_TASKS.md`)
- Create phase-specific status trackers (use single file)
- Create phase-specific protocols (use shared protocols)
- Mix phase-specific and shared docs

## File Placement Rules

### Phase-Specific
- `docs/agents/prompts/[phase]/` - Prompts for specific phase
- `docs/agents/tasks/[phase]/` - Tasks for specific phase
- `docs/agents/reports/agent_X/[phase]/` - Reports by agent and phase

### Shared
- `docs/agents/status/status_tracker.md` - Status for all phases
- `docs/agents/protocols/` - Protocols shared across phases
- `docs/agents/reference/` - Reference docs shared across phases

## Status Tracker Updates

**Use SINGLE status tracker file:**

```markdown
# Status Tracker

## Phase 1: MVP Core Functionality
- [ ] Task 1
- [x] Task 2

## Phase 2: Post-MVP Enhancements
- [ ] Task 1
```

**❌ DON'T create:** `status/phase_1_status.md`, `status/phase_2_status.md`

## Reference

- `docs/agents/REFACTORING_PROTOCOL.md` - Complete protocol documentation
