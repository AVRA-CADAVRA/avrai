# Documentation Refactoring Protocol - For All Phases

**Date:** November 23, 2025  
**Purpose:** Mandatory protocol for organizing agent documentation across all phases  
**Status:** 🎯 **ACTIVE - MUST FOLLOW**

---

## 🎯 **Purpose**

This protocol ensures all parallel agent documentation follows a consistent, organized folder structure. **ALL agents working on Phase 3+ MUST follow this protocol exactly.**

---

## 📁 **Mandatory Folder Structure**

**ALL agent documentation MUST be organized under `docs/agents/` with this structure:**

```
docs/agents/
├── README.md                    # Main index (MANDATORY)
│
├── prompts/                     # Ready-to-use agent prompts
│   ├── trial_run/              # Phase 1 prompts (Weeks 1-4)
│   ├── phase_2/                # Phase 2 prompts (Weeks 5-8)
│   ├── phase_3/                # Phase 3 prompts (when created)
│   └── phase_N/                # Future phases
│
├── tasks/                       # Task assignments
│   ├── trial_run/              # Phase 1 tasks
│   ├── phase_2/                # Phase 2 tasks
│   ├── phase_3/                # Phase 3 tasks (when created)
│   └── phase_N/                # Future phases
│
├── status/                      # Status tracking (SINGLE FILE - SHARED)
│   ├── status_tracker.md       # Main status tracker (ONE file for all phases)
│   ├── dependency_guide.md     # How to check dependencies
│   └── update_protocol.md      # How to update status tracker
│
├── protocols/                   # Workflows and protocols (SHARED)
│   ├── integration_protocol.md
│   ├── git_workflow.md
│   └── file_ownership.md
│
├── reference/                   # Quick reference (SHARED)
│   ├── quick_reference.md
│   └── date_time_format.md
│
├── reports/                     # Completion reports (ORGANIZED BY AGENT)
│   ├── agent_1/
│   │   ├── trial_run/          # Phase 1 reports
│   │   ├── phase_2/            # Phase 2 reports
│   │   └── phase_3/            # Phase 3 reports (when created)
│   ├── agent_2/
│   └── agent_3/
│
└── guides/                      # Comprehensive guides (SHARED)
    ├── parallel_work_guide.md
    ├── system_summary.md
    └── start_guide.md
```

---

## 🚨 **CRITICAL RULES**

### **Rule 1: Phase-Based Organization**
- **Each phase gets its own folder** in `prompts/` and `tasks/`
- **Folder naming:** `trial_run/` for Phase 1, `phase_2/`, `phase_3/`, etc.
- **NO exceptions** - All phase-specific docs go in phase folders

### **Rule 2: Shared vs Phase-Specific**
- **SHARED (One file for all phases):**
  - `status/status_tracker.md` - Single file tracks all phases
  - `protocols/` - All protocols shared across phases
  - `reference/` - All reference guides shared
  - `guides/` - All guides shared

- **PHASE-SPECIFIC (Separate folder per phase):**
  - `prompts/[phase]/` - Prompts specific to that phase
  - `tasks/[phase]/` - Tasks specific to that phase
  - `reports/agent_X/[phase]/` - Reports organized by agent AND phase

### **Rule 3: Status Tracker is SINGLE FILE**
- **ONE file:** `status/status_tracker.md`
- **Contains:** All phases, all agents, all status
- **DO NOT create:** `status/status_tracker_phase_3.md` or similar
- **DO update:** The single status tracker with Phase 3 sections

### **Rule 4: Report Organization**
- **Reports organized by AGENT first, then PHASE:**
  - `reports/agent_1/phase_2/week_6_completion.md`
  - `reports/agent_2/trial_run/section_1_complete.md`
- **NOT organized by phase first** - agent takes precedence

---

## 📋 **Protocol for Creating Phase 3+ Documentation**

### **Step 1: Create Phase Folders**

```bash
# Create phase-specific folders
mkdir -p docs/agents/prompts/phase_3
mkdir -p docs/agents/tasks/phase_3
mkdir -p docs/agents/reports/agent_1/phase_3
mkdir -p docs/agents/reports/agent_2/phase_3
mkdir -p docs/agents/reports/agent_3/phase_3
```

### **Step 2: Create Phase Documentation**

**Required files for each new phase:**

1. **Prompts:**
   - `docs/agents/prompts/phase_3/prompts.md` - Ready-to-use prompts

2. **Tasks:**
   - `docs/agents/tasks/phase_3/task_assignments.md` - Task assignments

3. **Reports (Created as work progresses):**
   - `docs/agents/reports/agent_X/phase_3/[section]_complete.md`

### **Step 3: Update Shared Files**

**DO NOT create new shared files. Update existing ones:**

1. **Status Tracker:**
   - Add Phase 3 section to `docs/agents/status/status_tracker.md`
   - **DO NOT** create `status/status_tracker_phase_3.md`

2. **Guides (if needed):**
   - Update existing guides in `guides/`
   - **DO NOT** create phase-specific guides unless truly unique

3. **Protocols:**
   - Protocols in `protocols/` are shared across all phases
   - Update if needed, but don't create phase-specific versions

---

## ✅ **Checklist for Phase 3+ Agents**

**Before starting work, verify:**

- [ ] Phase folder created: `docs/agents/prompts/phase_3/`
- [ ] Phase folder created: `docs/agents/tasks/phase_3/`
- [ ] Phase folders created: `docs/agents/reports/agent_X/phase_3/`
- [ ] Phase prompts created: `docs/agents/prompts/phase_3/prompts.md`
- [ ] Phase tasks created: `docs/agents/tasks/phase_3/task_assignments.md`
- [ ] Status tracker updated with Phase 3 section (in existing file)
- [ ] All references point to `docs/agents/...` paths
- [ ] No old-style paths (`docs/AGENT_*.md` or `docs/PHASE_*.md`)

**During work:**

- [ ] Create reports in `reports/agent_X/phase_3/`
- [ ] Update status tracker (single file, add Phase 3 sections)
- [ ] Follow file naming conventions (see below)

**After completing work:**

- [ ] All reports in correct phase folders
- [ ] Status tracker updated with Phase 3 completion
- [ ] All documentation follows this protocol

---

## 📝 **File Naming Conventions**

### **Prompts:**
- Format: `prompts.md`
- Location: `docs/agents/prompts/[phase]/prompts.md`
- Example: `docs/agents/prompts/phase_3/prompts.md`

### **Tasks:**
- Format: `task_assignments.md`
- Location: `docs/agents/tasks/[phase]/task_assignments.md`
- Example: `docs/agents/tasks/phase_3/task_assignments.md`

### **Reports:**
- Format: `agent_X_[section]_complete.md` or `agent_X_week_Y_completion.md`
- Location: `docs/agents/reports/agent_X/[phase]/[filename].md`
- Examples:
  - `docs/agents/reports/agent_1/phase_3/week_9_completion.md`
  - `docs/agents/reports/agent_2/phase_3/section_1_complete.md`

### **Status Tracker:**
- Format: `status_tracker.md` (SINGLE FILE)
- Location: `docs/agents/status/status_tracker.md`
- **DO NOT create:** phase-specific status trackers

---

## 🚫 **DO NOT DO THESE**

### **❌ DO NOT:**
- Create files directly in `docs/` root (e.g., `docs/PHASE_3_TASKS.md`)
- Create phase-specific status trackers (e.g., `status/status_tracker_phase_3.md`)
- Create phase-specific protocols (e.g., `protocols/git_workflow_phase_3.md`)
- Create phase-specific reference guides (e.g., `reference/quick_reference_phase_3.md`)
- Mix phase documentation in wrong folders
- Use old path references (e.g., `docs/AGENT_STATUS_TRACKER.md`)

### **✅ DO:**
- Create phase folders in `prompts/` and `tasks/`
- Create phase subfolders in `reports/agent_X/`
- Update the SINGLE status tracker with new phase sections
- Use shared protocols, references, and guides
- Follow the folder structure exactly

---

## 📊 **Examples**

### **Example 1: Creating Phase 3 Documentation**

**✅ CORRECT:**
```
docs/agents/
├── prompts/
│   └── phase_3/
│       └── prompts.md                    ✅ Phase 3 prompts
├── tasks/
│   └── phase_3/
│       └── task_assignments.md           ✅ Phase 3 tasks
├── status/
│   └── status_tracker.md                 ✅ Updated with Phase 3 section
└── reports/
    ├── agent_1/
    │   └── phase_3/
    │       └── week_9_completion.md      ✅ Phase 3 report
```

**❌ WRONG:**
```
docs/
├── PHASE_3_TASKS.md                      ❌ Wrong location
├── PHASE_3_AGENT_PROMPTS.md              ❌ Wrong location
└── agents/
    └── status/
        └── status_tracker_phase_3.md     ❌ Should update existing file
```

### **Example 2: Status Tracker Updates**

**✅ CORRECT:**
```
docs/agents/status/status_tracker.md

### **Phase 3: [Phase Name]**
**Status:** 🟢 In Progress
**Agent 1:** Section 1 - [Status]
**Agent 2:** Section 1 - [Status]
**Agent 3:** Section 1 - [Status]
```

**❌ WRONG:**
```
docs/agents/status/
├── status_tracker.md                     ❌ Only has Phase 1-2
└── status_tracker_phase_3.md             ❌ Separate file created
```

---

## 🔄 **Migration Path for Existing Phase Documentation**

If you find phase documentation in wrong locations:

1. **Identify phase-specific docs** in `docs/` root
2. **Move to appropriate folders:**
   - Prompts → `docs/agents/prompts/[phase]/`
   - Tasks → `docs/agents/tasks/[phase]/`
   - Reports → `docs/agents/reports/agent_X/[phase]/`
3. **Update all references** in moved files
4. **Update status tracker** (single file) if needed

---

## 📚 **Reference Documents**

- **Main Index:** `docs/agents/README.md` - Start here
- **Quick Start:** `docs/agents/QUICK_START.md` - Quick reference
- **Migration Summary:** `docs/agents/MIGRATION_SUMMARY.md` - What changed
- **This Protocol:** `docs/agents/REFACTORING_PROTOCOL.md` - This document

---

## ✅ **Verification**

Before marking a phase as complete, verify:

- [ ] All phase documentation in correct folders
- [ ] Status tracker updated (single file)
- [ ] All reports organized by agent and phase
- [ ] No old-style paths or file locations
- [ ] All references updated to new paths
- [ ] Folder structure matches protocol exactly

---

**Last Updated:** November 23, 2025  
**Protocol Version:** 1.0  
**Status:** 🎯 **MANDATORY FOR ALL PHASES**

**All agents working on Phase 3+ MUST read and follow this protocol exactly.**

