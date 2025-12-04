# Parallel Agent Documentation - Folder Organization

**Date:** November 23, 2025  
**Purpose:** Complete index and organization guide for all parallel agent documentation  
**Status:** 🎯 Active

---

## 📁 **Folder Structure Overview**

All parallel agent documentation is organized in this `docs/agents/` folder with clear hierarchy:

```
docs/agents/
├── README.md                    # This file - folder organization guide
│
├── prompts/                     # Ready-to-use agent prompts
│   ├── README.md               # Prompt organization guide
│   ├── trial_run/              # Phase 1 (Weeks 1-4) prompts
│   └── phase_2/                # Phase 2 (Weeks 5-8) prompts
│
├── tasks/                       # Task assignments and specifications
│   ├── README.md               # Task assignment guide
│   ├── trial_run/              # Phase 1 task assignments
│   └── phase_2/                # Phase 2 task assignments
│
├── status/                      # Status tracking and dependencies
│   ├── README.md               # Status tracking guide
│   ├── status_tracker.md       # Main status tracker (live document)
│   ├── dependency_guide.md     # How to check dependencies
│   └── update_protocol.md      # How to update status tracker
│
├── protocols/                   # Workflows and protocols
│   ├── README.md               # Protocol organization guide
│   ├── integration_protocol.md # How agents integrate work
│   ├── git_workflow.md         # Git workflow for parallel work
│   └── file_ownership.md       # File ownership matrix
│
├── reference/                   # Quick reference guides
│   ├── README.md               # Reference guide index
│   ├── quick_reference.md      # Code patterns and examples
│   └── date_time_format.md     # Date/time format standards
│
├── reports/                     # Completion reports and summaries
│   ├── README.md               # Report organization guide
│   ├── agent_1/                # Agent 1 completion reports
│   ├── agent_2/                # Agent 2 completion reports
│   └── agent_3/                # Agent 3 completion reports
│
└── guides/                      # Comprehensive guides and summaries
    ├── README.md               # Guide index
    ├── parallel_work_guide.md  # Complete parallel work guide
    ├── system_summary.md       # Agent system overview
    └── start_guide.md          # How to start parallel work
│
├── trial_run_summaries/        # Trial Run (Phase 1) high-level summaries
│   └── README.md
│
├── phase_summaries/            # Phase summaries (Phase 2+)
│   └── README.md
│
├── REFACTORING_PROTOCOL.md     # ⚠️ MANDATORY: Protocol for Phase 3+
├── MIGRATION_SUMMARY.md        # Migration documentation
└── guides/                      # Comprehensive guides
    ├── PHASE_3_PREPARATION.md  # Step-by-step Phase 3 setup guide
    ├── ORGANIZATION_COMPLETE.md # Organization completion status
    └── PHASE_3_PROTOCOL_VERIFICATION.md # Protocol verification
```

---

## 🎯 **Document Hierarchy for Agents**

### **Level 1: Getting Started**
When an agent starts working, they should read (in order):

1. **`guides/start_guide.md`** - How to start parallel agent work
2. **`guides/system_summary.md`** - Complete system overview
3. **`status/README.md`** - How status tracking works

### **Level 2: Understanding Your Role**
After understanding the system:

1. **`tasks/trial_run/` or `tasks/phase_2/`** - Your specific task assignments
2. **`reference/quick_reference.md`** - Code patterns and examples
3. **`protocols/integration_protocol.md`** - How to integrate with other agents

### **Level 3: Daily Work**
During daily work:

1. **`status/status_tracker.md`** - Check before starting ANY task
2. **`status/dependency_guide.md`** - How to check dependencies
3. **`protocols/git_workflow.md`** - Git workflow
4. **`protocols/file_ownership.md`** - Which files you own

### **Level 4: Reference**
When you need quick answers:

1. **`reference/quick_reference.md`** - Code patterns
2. **`reference/date_time_format.md`** - Date/time format
3. **`protocols/`** - All protocols for reference

---

## 📋 **Quick Access Guide**

### **"I'm starting a new agent task"**
→ Read `guides/start_guide.md`

### **"What are my tasks?"**
→ Read `tasks/[phase]/agent_X.md` or main task assignment file

### **"Am I blocked? Can I start?"**
→ Check `status/status_tracker.md`

### **"How do I check dependencies?"**
→ Read `status/dependency_guide.md`

### **"How do I update the status tracker?"**
→ Read `status/update_protocol.md`

### **"How do I integrate with other agents?"**
→ Read `protocols/integration_protocol.md`

### **"What code patterns should I use?"**
→ Read `reference/quick_reference.md`

### **"What's the git workflow?"**
→ Read `protocols/git_workflow.md`

### **"Which files do I own?"**
→ Read `protocols/file_ownership.md`

### **"I need a ready-to-use prompt"**
→ Check `prompts/[phase]/agent_X.md`

### **"Where are completion reports?"**
→ Check `reports/agent_X/`

---

## 🔄 **Document Completion Hierarchy**

Agents working in parallel must understand this hierarchy for document completion:

### **Tier 1: Critical Path Documents (Update First)**
These documents block other agents or coordinate work:
1. **`status/status_tracker.md`** - Always update when completing work others depend on
2. **`protocols/`** files - When changing workflows
3. **`tasks/`** files - When clarifying or updating tasks

### **Tier 2: Integration Documents (Update When Integrating)**
Update these when integrating work with other agents:
1. **`protocols/integration_protocol.md`** - When integration points change
2. **`reference/quick_reference.md`** - When adding new code patterns
3. **`tasks/`** - When tasks are complete

### **Tier 3: Reporting Documents (Update When Completing Work)**
Update these when completing sections:
1. **`reports/agent_X/`** - When completing a section/phase
2. **`guides/`** - When system changes significantly

### **Tier 4: Reference Documents (Update As Needed)**
These are updated less frequently:
1. **`reference/`** - When adding new patterns or standards
2. **`guides/`** - When process changes

---

## 🎯 **File Naming Conventions**

### **Status Files:**
- `status_tracker.md` - Main status tracker (singular, definitive)
- `dependency_guide.md` - How to check dependencies
- `update_protocol.md` - How to update status

### **Task Files:**
- `agent_X_tasks.md` - Agent X task assignments
- `phase_Y_tasks.md` - Phase Y task assignments

### **Report Files:**
- `agent_X_[section]_complete.md` - Completion report
- `agent_X_week_Y_completion.md` - Week completion
- `agent_X_[section]_summary.md` - Section summary

### **Protocol Files:**
- `[topic]_protocol.md` - Protocol for [topic]
- `[topic]_workflow.md` - Workflow for [topic]

### **Reference Files:**
- `quick_reference.md` - Quick reference guide
- `[topic]_reference.md` - Reference for [topic]

---

## ✅ **Agent Workflow Checklist**

Before starting any task:
- [ ] Read `guides/start_guide.md`
- [ ] Read your task assignments in `tasks/`
- [ ] Check `status/status_tracker.md` for dependencies
- [ ] Read `reference/quick_reference.md` for code patterns

During work:
- [ ] Follow `protocols/git_workflow.md`
- [ ] Check `status/status_tracker.md` regularly
- [ ] Update `status/status_tracker.md` when completing work others depend on
- [ ] Follow `protocols/file_ownership.md` for file ownership

After completing work:
- [ ] Update `status/status_tracker.md`
- [ ] Create completion report in `reports/agent_X/`
- [ ] Update integration documentation if needed

---

## 🚨 **MANDATORY: Refactoring Protocol for Phase 3+**

**ALL agents working on Phase 3 and beyond MUST follow the refactoring protocol:**

- **Read:** `docs/agents/REFACTORING_PROTOCOL.md` - **CRITICAL**
- **Follow:** Folder structure exactly as specified
- **Verify:** All documentation follows protocol before starting

**Key Rules:**
- ✅ Create phase folders: `prompts/phase_3/`, `tasks/phase_3/`
- ✅ Update SINGLE status tracker (don't create new ones)
- ✅ Organize reports by agent then phase: `reports/agent_X/phase_3/`
- ❌ DO NOT create files in `docs/` root
- ❌ DO NOT create phase-specific status trackers

---

## 📞 **Questions?**

- **"Where do I find X?"** → Check this README first
- **"Where do I put X?"** → Follow folder structure above
- **"Which document is most important?"** → See Document Hierarchy section
- **"What should I read first?"** → See Level 1: Getting Started
- **"How do I create Phase 3+ docs?"** → Read `REFACTORING_PROTOCOL.md`

---

**Last Updated:** November 23, 2025  
**Maintainer:** Parallel Agent System  
**Protocol:** See `REFACTORING_PROTOCOL.md` for Phase 3+ requirements

