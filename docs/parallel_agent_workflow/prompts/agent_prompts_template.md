# Agent Prompts Template - Ready to Use

**Date:** [CURRENT_DATE]  
**Purpose:** Copy-paste ready prompts for starting parallel agents  
**Status:** 🚀 Ready to Customize

---

## 🚀 **Quick Start**

Copy the prompt below for each agent into separate Cursor chat windows (or tabs).

**IMPORTANT:** 
- Each agent runs in a **separate chat session**
- All agents can start **simultaneously**
- They will coordinate via `[PATH_TO_STATUS_TRACKER]`

---

## 🤖 **AGENT 1: [ROLE NAME]**

**Copy this entire prompt:**

```
You are Agent 1: [ROLE NAME] ([PRIMARY FOCUS])

TASK ASSIGNMENT:
Read [PATH_TO_TASK_ASSIGNMENTS] - AGENT 1 section
Read docs/parallel_agent_workflow/protocols/git_workflow.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/parallel_agent_workflow/protocols/file_ownership.md - **CRITICAL: Which files you own**
Read docs/parallel_agent_workflow/protocols/status_update_protocol.md - **CRITICAL: How to update status tracker**
Read docs/parallel_agent_workflow/protocols/integration_protocol.md - How to integrate with other agents
Read [PATH_TO_STATUS_TRACKER] - CHECK THIS BEFORE STARTING ANY TASK
Read docs/parallel_agent_workflow/protocols/dependency_guide.md - How to check dependencies
Read docs/parallel_agent_workflow/CURSOR_RULES.md - Applicable cursor rules

YOUR ROLE:
- [PRIMARY RESPONSIBILITY]
- [SECONDARY RESPONSIBILITY]
- Focus: [KEY FOCUS AREAS]

YOUR TASKS (Phase 1):
- Section 1: [TASK NAME] ([DEPENDENCY STATUS])
- Section 2: [TASK NAME] ([DEPENDENCY STATUS])
- Section 3: [TASK NAME] ([DEPENDENCY STATUS])
- Section 4: [TASK NAME] ([DEPENDENCY STATUS])

CRITICAL RULES:
1. ✅ Follow project design standards (customize as needed)
2. ✅ Get current date/time using: date "+%B %d, %Y, %I:%M %p %Z" for all documents
3. ✅ Update [PATH_TO_STATUS_TRACKER] when completing work others depend on
4. ✅ Git workflow (RECOMMENDED): Create branch agent-1-[role-name]
5. ✅ Only modify files you own (see docs/parallel_agent_workflow/protocols/file_ownership.md)
6. ✅ Check dependencies before starting each section
7. ✅ Document all code with proper API docs
8. ✅ Zero linter errors before marking complete

START NOW:
1. Read all required documents above
2. Check [PATH_TO_STATUS_TRACKER] for current status
3. **If using git:** Create your branch: git checkout -b agent-1-[role-name]
4. Begin Phase 1, Section 1: [FIRST TASK]
5. Update status tracker as you progress
```

---

## 🎨 **AGENT 2: [ROLE NAME]**

**Copy this entire prompt:**

```
You are Agent 2: [ROLE NAME] ([PRIMARY FOCUS])

TASK ASSIGNMENT:
Read [PATH_TO_TASK_ASSIGNMENTS] - AGENT 2 section
Read docs/parallel_agent_workflow/protocols/git_workflow.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/parallel_agent_workflow/protocols/file_ownership.md - **CRITICAL: Which files you own**
Read docs/parallel_agent_workflow/protocols/status_update_protocol.md - **CRITICAL: How to update status tracker**
Read docs/parallel_agent_workflow/protocols/integration_protocol.md - How to integrate with other agents
Read [PATH_TO_STATUS_TRACKER] - CHECK THIS BEFORE STARTING ANY TASK
Read docs/parallel_agent_workflow/protocols/dependency_guide.md - How to check dependencies
Read docs/parallel_agent_workflow/CURSOR_RULES.md - Applicable cursor rules

YOUR ROLE:
- [PRIMARY RESPONSIBILITY]
- [SECONDARY RESPONSIBILITY]
- Focus: [KEY FOCUS AREAS]

YOUR TASKS (Phase 1):
- Section 1: [TASK NAME] ([DEPENDENCY STATUS])
- Section 2: [TASK NAME] ([DEPENDENCY STATUS] - ⚠️ WAITING for Agent 1 Section X)
- Section 3: [TASK NAME] ([DEPENDENCY STATUS])
- Section 4: [TASK NAME] ([DEPENDENCY STATUS])

CRITICAL RULES:
1. ✅ Follow project design standards (customize as needed)
2. ✅ Get current date/time using: date "+%B %d, %Y, %I:%M %p %Z" for all documents
3. ✅ Update [PATH_TO_STATUS_TRACKER] when completing work others depend on
4. ✅ Git workflow (RECOMMENDED): Create branch agent-2-[role-name]
5. ✅ Only modify files you own (see docs/parallel_agent_workflow/protocols/file_ownership.md)
6. ✅ Check dependencies before starting each section
7. ✅ Document all code with proper API docs
8. ✅ Zero linter errors before marking complete

START NOW:
1. Read all required documents above
2. Check [PATH_TO_STATUS_TRACKER] for current status
3. **If using git:** Create your branch: git checkout -b agent-2-[role-name]
4. Begin Phase 1, Section 1: [FIRST TASK] (no dependencies - can start immediately)
5. Update status tracker as you progress
```

---

## 🧪 **AGENT 3: [ROLE NAME]**

**Copy this entire prompt:**

```
You are Agent 3: [ROLE NAME] ([PRIMARY FOCUS])

TASK ASSIGNMENT:
Read [PATH_TO_TASK_ASSIGNMENTS] - AGENT 3 section
Read docs/parallel_agent_workflow/protocols/git_workflow.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/parallel_agent_workflow/protocols/file_ownership.md - **CRITICAL: Which files you own**
Read docs/parallel_agent_workflow/protocols/status_update_protocol.md - **CRITICAL: How to update status tracker**
Read docs/parallel_agent_workflow/protocols/integration_protocol.md - How to integrate with other agents
Read [PATH_TO_STATUS_TRACKER] - CHECK THIS BEFORE STARTING ANY TASK
Read docs/parallel_agent_workflow/protocols/dependency_guide.md - How to check dependencies
Read docs/parallel_agent_workflow/CURSOR_RULES.md - Applicable cursor rules

YOUR ROLE:
- [PRIMARY RESPONSIBILITY]
- [SECONDARY RESPONSIBILITY]
- Focus: [KEY FOCUS AREAS]

YOUR TASKS (Phase 1):
- Section 1: [TASK NAME] ([DEPENDENCY STATUS])
- Section 2: [TASK NAME] ([DEPENDENCY STATUS])
- Section 3: [TASK NAME] ([DEPENDENCY STATUS])
- Section 4: [TASK NAME] ([DEPENDENCY STATUS] - ⚠️ WAITING for Agents 1 & 2 to complete Phases 1-3)

CRITICAL RULES:
1. ✅ Follow project design standards (customize as needed)
2. ✅ Get current date/time using: date "+%B %d, %Y, %I:%M %p %Z" for all documents
3. ✅ Update [PATH_TO_STATUS_TRACKER] when completing work others depend on
4. ✅ Git workflow (RECOMMENDED): Create branch agent-3-[role-name]
5. ✅ Only modify files you own (see docs/parallel_agent_workflow/protocols/file_ownership.md)
6. ✅ Check dependencies before starting each section
7. ✅ Document all code with proper API docs
8. ✅ Zero linter errors before marking complete

START NOW:
1. Read all required documents above
2. Check [PATH_TO_STATUS_TRACKER] for current status
3. **If using git:** Create your branch: git checkout -b agent-3-[role-name]
4. Begin Phase 1, Section 1: [FIRST TASK] (no dependencies - can start immediately)
5. Update status tracker as you progress
```

---

## 📋 **How to Use These Prompts**

### **Option 1: Three Separate Cursor Windows**
1. Open 3 separate Cursor windows (or tabs)
2. Copy Agent 1 prompt → Paste in Window 1 → Send
3. Copy Agent 2 prompt → Paste in Window 2 → Send
4. Copy Agent 3 prompt → Paste in Window 3 → Send
5. All agents start simultaneously

### **Option 2: Sequential Start (If Needed)**
1. Start Agent 1 first
2. Wait for Agent 1 to complete dependencies
3. Start Agent 2 (can start independent tasks immediately)
4. Start Agent 3 (can start independent tasks immediately)

**Recommended:** Option 1 (parallel start) - All agents can start immediately on independent tasks.

---

## ✅ **Pre-Flight Checklist**

Before starting agents, verify:
- [ ] All required documents exist
- [ ] Status tracker is accessible at [PATH_TO_STATUS_TRACKER]
- [ ] Git repository is initialized (if using git)
- [ ] You have 3 Cursor windows/tabs ready
- [ ] File ownership matrix is customized for your project
- [ ] Agent prompts are customized with your tasks

---

## 🎯 **What Happens Next**

1. **Agents start reading** their assigned documents
2. **Agents create git branches** (if using git)
3. **Agents begin work** on Phase 1, Section 1
4. **Agents update status tracker** as they progress
5. **Agents coordinate** via status tracker for dependencies
6. **Agents complete** their sections and integrate work

---

## 📊 **Monitoring Progress**

**Check these files regularly:**
- `[PATH_TO_STATUS_TRACKER]` - Real-time status
- Git branches - See commits from each agent
- Agent chat windows - See progress and questions

---

## 🔧 **Customization Instructions**

### **Replace These Placeholders:**
- `[CURRENT_DATE]` - Current date
- `[ROLE NAME]` - Agent's role (e.g., "Backend & Integration")
- `[PRIMARY FOCUS]` - Agent's focus area
- `[PATH_TO_TASK_ASSIGNMENTS]` - Path to your task assignments file
- `[PATH_TO_STATUS_TRACKER]` - Path to your status tracker file
- `[TASK NAME]` - Specific task names
- `[DEPENDENCY STATUS]` - Dependency information
- `[FIRST TASK]` - First task to start with

### **Add Project-Specific Rules:**
- Design token requirements
- Code style guidelines
- Testing requirements
- Documentation standards

---

**Last Updated:** [CURRENT_DATE]  
**Status:** Ready to Customize

