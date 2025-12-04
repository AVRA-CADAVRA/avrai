# Phase 3 Preparation Guide - For Phase 3+ Agents

**Date:** November 23, 2025  
**Purpose:** Step-by-step guide for preparing Phase 3+ documentation following the refactoring protocol  
**Status:** 🎯 **READ THIS BEFORE STARTING PHASE 3**

---

## 🚨 **MANDATORY: Read First**

**Before creating ANY Phase 3 documentation, you MUST:**

1. ✅ Read `docs/agents/REFACTORING_PROTOCOL.md` - **CRITICAL**
2. ✅ Read `docs/agents/README.md` - Understand folder structure
3. ✅ Understand the folder hierarchy and naming conventions

---

## 📋 **Phase 3 Setup Checklist**

### **Step 1: Create Phase 3 Folders**

```bash
# Create phase-specific folders
mkdir -p docs/agents/prompts/phase_3
mkdir -p docs/agents/tasks/phase_3
mkdir -p docs/agents/reports/agent_1/phase_3
mkdir -p docs/agents/reports/agent_2/phase_3
mkdir -p docs/agents/reports/agent_3/phase_3
```

**Verify:**
- [ ] `docs/agents/prompts/phase_3/` exists
- [ ] `docs/agents/tasks/phase_3/` exists
- [ ] `docs/agents/reports/agent_X/phase_3/` exists for all agents

### **Step 2: Create Phase 3 Prompts File**

**Create:** `docs/agents/prompts/phase_3/prompts.md`

**Template:** Follow the structure in `docs/agents/prompts/phase_2/prompts.md`

**Must include:**
- [ ] Phase 3 overview
- [ ] Agent 1 prompt (all weeks/sections)
- [ ] Agent 2 prompt (all weeks/sections)
- [ ] Agent 3 prompt (all weeks/sections)
- [ ] Common instructions
- [ ] References to correct paths (see below)

**Required path references:**
- ✅ `docs/agents/tasks/phase_3/task_assignments.md`
- ✅ `docs/agents/status/status_tracker.md`
- ✅ `docs/agents/reference/quick_reference.md`
- ✅ `docs/agents/protocols/git_workflow.md`
- ✅ All other `docs/agents/...` paths

**❌ DO NOT use:**
- ❌ `docs/PHASE_3_TASKS.md`
- ❌ `docs/AGENT_STATUS_TRACKER.md`
- ❌ Old-style paths

### **Step 3: Create Phase 3 Tasks File**

**Create:** `docs/agents/tasks/phase_3/task_assignments.md`

**Template:** Follow the structure in `docs/agents/tasks/phase_2/task_assignments.md`

**Must include:**
- [ ] Phase 3 overview
- [ ] Agent assignments
- [ ] Week-by-week or section-by-section breakdown
- [ ] Task details for each agent
- [ ] Dependencies and coordination points
- [ ] Acceptance criteria

**Required path references:**
- ✅ `docs/agents/status/status_tracker.md`
- ✅ `docs/agents/protocols/integration_protocol.md`
- ✅ `docs/agents/reference/quick_reference.md`
- ✅ All other `docs/agents/...` paths

### **Step 4: Update Status Tracker**

**Update:** `docs/agents/status/status_tracker.md` (SINGLE FILE)

**Add Phase 3 section:**
```markdown
### **Phase 3: [Phase Name]**
**Status:** 🟢 Ready to Start
**Focus:** [Phase focus description]

**Agent 1:** [Role] - [Status]
**Agent 2:** [Role] - [Status]
**Agent 3:** [Role] - [Status]
```

**❌ DO NOT:**
- ❌ Create `docs/agents/status/status_tracker_phase_3.md`
- ❌ Create separate status tracker files

### **Step 5: Create Phase 3 Summary (Optional)**

**Create:** `docs/agents/phase_summaries/PHASE_3_START_SUMMARY.md` (optional)

**Template:** Follow `docs/agents/phase_summaries/PHASE_2_START_SUMMARY.md`

**Use for:** High-level summary only (not required)

---

## ✅ **Verification Checklist**

Before marking Phase 3 as ready to start:

- [ ] Phase 3 folders created in `prompts/`, `tasks/`, and `reports/agent_X/`
- [ ] `docs/agents/prompts/phase_3/prompts.md` created with correct structure
- [ ] `docs/agents/tasks/phase_3/task_assignments.md` created with correct structure
- [ ] Status tracker updated with Phase 3 section (single file)
- [ ] All path references use `docs/agents/...` format
- [ ] No old-style paths (`docs/PHASE_3_*.md`, `docs/AGENT_*.md`)
- [ ] All references point to correct locations
- [ ] Folder structure matches `REFACTORING_PROTOCOL.md` exactly

---

## 📝 **File Creation Templates**

### **Prompts File Template:**

```markdown
# Phase 3 Agent Prompts - [Phase Name]

**Date:** [Date]
**Purpose:** Ready-to-use prompts for Phase 3 agents
**Status:** 🎯 Ready for Phase 3

---

## 🤖 **Agent 1: [Role]**

### **Week [X] Prompt:**

```
You are Agent 1 working on Phase 3, Week [X]: [Task Description].

**Context:**
[Context]

**Your Tasks:**
[Tasks]

**Key Files to Review:**
- `docs/agents/tasks/phase_3/task_assignments.md` - Your detailed tasks
- `docs/agents/reference/quick_reference.md` - Code patterns
- `docs/agents/status/status_tracker.md` - Status tracking
```

[Continue for all agents and weeks]
```

### **Tasks File Template:**

```markdown
# Phase 3 Task Assignments - [Phase Name]

**Date:** [Date]
**Purpose:** Detailed task assignments for Phase 3
**Status:** 🎯 Ready for Phase 3

---

## 📋 **Agent Assignments**

[Agent assignments]

---

## 📅 **Week [X]: [Week Description]**

### **Agent 1: [Role]**

**Tasks:**
[Tasks]

**Deliverables:**
[Deliverables]

**Dependencies:**
[Dependencies]

[Continue for all agents and weeks]
```

---

## 🔄 **During Phase 3 Work**

### **Creating Reports:**

**Location:** `docs/agents/reports/agent_X/phase_3/`

**Naming:**
- `agent_X_week_Y_completion.md`
- `agent_X_section_Z_complete.md`
- `agent_X_[task]_summary.md`

### **Updating Status Tracker:**

**File:** `docs/agents/status/status_tracker.md` (single file)

**Update:** Add Phase 3 progress in the Phase 3 section

**❌ DO NOT:** Create separate status tracker files

---

## 📚 **Reference Documents**

- **Refactoring Protocol:** `docs/agents/REFACTORING_PROTOCOL.md` - **MUST READ**
- **Main Index:** `docs/agents/README.md`
- **Quick Start:** `docs/agents/QUICK_START.md`
- **Phase 2 Example:** `docs/agents/prompts/phase_2/prompts.md` - Use as template
- **Phase 2 Example:** `docs/agents/tasks/phase_2/task_assignments.md` - Use as template

---

## ✅ **Final Checklist**

Before starting Phase 3 work:

- [ ] Read `REFACTORING_PROTOCOL.md`
- [ ] Created all required folders
- [ ] Created prompts file with correct structure
- [ ] Created tasks file with correct structure
- [ ] Updated status tracker (single file)
- [ ] Verified all paths use `docs/agents/...` format
- [ ] No old-style paths or file locations
- [ ] Ready to begin Phase 3 work

---

**Last Updated:** November 23, 2025  
**For Phase 3+ Agents:** Follow this guide exactly

