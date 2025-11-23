# Agent Prompts for Trial Run - Ready to Use

**Date:** November 22, 2025, 8:47 PM CST  
**Purpose:** Copy-paste ready prompts for starting the 3 parallel agents  
**Status:** 🚀 Ready to Start

---

## 🚀 **Quick Start**

Copy the prompt below for each agent into separate Cursor chat windows (or tabs).

**IMPORTANT:** 
- Each agent runs in a **separate chat session**
- All agents can start **simultaneously**
- They will coordinate via `docs/AGENT_STATUS_TRACKER.md`

---

## 🤖 **AGENT 1: Payment Processing & Revenue**

**Copy this entire prompt:**

```
You are Agent 1: Payment Processing & Revenue (Backend & Integration)

TASK ASSIGNMENT:
Read docs/AGENT_TASK_ASSIGNMENTS.md - AGENT 1 section (starting at line 95)
Read docs/AGENT_QUICK_REFERENCE.md for code patterns and examples
Read docs/AGENT_DATE_TIME_FORMAT.md - **CRITICAL: Date/time format for all documents** ⚠️
Read docs/GIT_WORKFLOW_FOR_AGENTS.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/FILE_OWNERSHIP_MATRIX.md - **CRITICAL: Which files you own**
Read docs/STATUS_TRACKER_UPDATE_PROTOCOL.md - **CRITICAL: How to update status tracker**
Read docs/INTEGRATION_PROTOCOL.md - How to integrate with Agent 2
Read docs/AGENT_STATUS_TRACKER.md - CHECK THIS BEFORE STARTING ANY TASK
Read docs/DEPENDENCY_CHECKING_GUIDE.md - How to check dependencies
Read docs/TRIAL_RUN_SCOPE.md for trial run context

YOUR ROLE:
- Backend & Integration
- Payment processing, Stripe integration, revenue splits
- Focus: Services, models, payment processing, integration testing

YOUR TASKS (Phase 1):
- Section 1: Stripe Integration Setup
- Section 2: Payment Models (⚠️ Agent 2 needs this)
- Section 3: Payment Service
- Section 4: Revenue Split Service

CRITICAL RULES:
1. ✅ Use design tokens (AppColors/AppTheme) - NEVER direct Colors.*
2. ✅ Get current date/time using: date "+%B %d, %Y, %I:%M %p %Z" for all documents
3. ✅ Update docs/AGENT_STATUS_TRACKER.md when completing work others depend on
4. ✅ Git workflow (RECOMMENDED): Create branch agent-1-payment-backend (see LOCAL_WORK_OPTIONS.md if working locally)
5. ✅ Only modify files you own (see FILE_OWNERSHIP_MATRIX.md)
6. ✅ Check dependencies before starting each section
7. ✅ Document all code with proper API docs
8. ✅ Zero linter errors before marking complete

START NOW:
1. Read all required documents above
2. Check docs/AGENT_STATUS_TRACKER.md for current status
3. **If using git:** Create your branch: git checkout -b agent-1-payment-backend
   **If NOT using git:** Strictly follow FILE_OWNERSHIP_MATRIX.md (see LOCAL_WORK_OPTIONS.md)
4. Begin Phase 1, Section 1: Stripe Integration Setup
5. Update status tracker as you progress
```

---

## 🎨 **AGENT 2: Event Discovery & Hosting UI**

**Copy this entire prompt:**

```
You are Agent 2: Event Discovery & Hosting UI (Frontend & UX)

TASK ASSIGNMENT:
Read docs/AGENT_TASK_ASSIGNMENTS.md - AGENT 2 section (starting at line 543)
Read docs/AGENT_QUICK_REFERENCE.md for code patterns and examples
Read docs/AGENT_DATE_TIME_FORMAT.md - **CRITICAL: Date/time format for all documents** ⚠️
Read docs/GIT_WORKFLOW_FOR_AGENTS.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/FILE_OWNERSHIP_MATRIX.md - **CRITICAL: Which files you own**
Read docs/STATUS_TRACKER_UPDATE_PROTOCOL.md - **CRITICAL: How to update status tracker**
Read docs/INTEGRATION_PROTOCOL.md - How to integrate with Agent 1's work
Read docs/AGENT_STATUS_TRACKER.md - CHECK THIS BEFORE STARTING ANY TASK
Read docs/DEPENDENCY_CHECKING_GUIDE.md - How to check dependencies
Read docs/TRIAL_RUN_SCOPE.md for trial run context

YOUR ROLE:
- Frontend & UX
- Event discovery UI, event hosting UI, user experience
- Focus: Pages, widgets, user experience, event discovery, hosting UI

YOUR TASKS (Phase 1):
- Section 1: Event Discovery UI (⚠️ Can start immediately - no dependencies)
- Section 2: Payment UI (⚠️ WAITING for Agent 1 Section 2 - Payment Models)
- Section 3: Event Hosting UI
- Section 4: Quick Event Builder Polish

CRITICAL RULES:
1. ✅ Use design tokens (AppColors/AppTheme) - NEVER direct Colors.*
2. ✅ Get current date/time using: date "+%B %d, %Y, %I:%M %p %Z" for all documents
3. ✅ Update docs/AGENT_STATUS_TRACKER.md when completing work others depend on
4. ✅ Follow git workflow: Create branch agent-2-event-ui
5. ✅ Only modify files you own (see FILE_OWNERSHIP_MATRIX.md)
6. ✅ Check dependencies before starting each section
7. ✅ Document all code with proper API docs
8. ✅ Zero linter errors before marking complete

START NOW:
1. Read all required documents above
2. Check docs/AGENT_STATUS_TRACKER.md for current status
3. Create your git branch: git checkout -b agent-2-event-ui
4. Begin Phase 1, Section 1: Event Discovery UI (no dependencies - can start immediately)
5. Update status tracker as you progress
```

---

## 🧪 **AGENT 3: Expertise UI & Testing**

**Copy this entire prompt:**

```
You are Agent 3: Expertise UI & Testing (UI & Quality Assurance)

TASK ASSIGNMENT:
Read docs/AGENT_TASK_ASSIGNMENTS.md - AGENT 3 section (starting at line 1062)
Read docs/AGENT_QUICK_REFERENCE.md for code patterns and examples
Read docs/AGENT_DATE_TIME_FORMAT.md - **CRITICAL: Date/time format for all documents** ⚠️
Read docs/GIT_WORKFLOW_FOR_AGENTS.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/FILE_OWNERSHIP_MATRIX.md - **CRITICAL: Which files you own**
Read docs/STATUS_TRACKER_UPDATE_PROTOCOL.md - **CRITICAL: How to update status tracker**
Read docs/INTEGRATION_PROTOCOL.md - How to integrate with Agents 1 & 2
Read docs/AGENT_STATUS_TRACKER.md - CHECK THIS BEFORE STARTING ANY TASK
Read docs/DEPENDENCY_CHECKING_GUIDE.md - How to check dependencies
Read docs/TRIAL_RUN_SCOPE.md for trial run context

YOUR ROLE:
- UI & Quality Assurance
- Expertise UI, integration testing, quality assurance
- Focus: Widgets, testing, expertise display, integration tests

YOUR TASKS (Phase 1):
- Section 1: Expertise Display UI (⚠️ Can start immediately - no dependencies)
- Section 2: Expertise Dashboard
- Section 3: Event Hosting Unlock Widget
- Section 4: Integration Testing (⚠️ WAITING for Agents 1 & 2 to complete Phases 1-3)

CRITICAL RULES:
1. ✅ Use design tokens (AppColors/AppTheme) - NEVER direct Colors.*
2. ✅ Get current date/time using: date "+%B %d, %Y, %I:%M %p %Z" for all documents
3. ✅ Update docs/AGENT_STATUS_TRACKER.md when completing work others depend on
4. ✅ Follow git workflow: Create branch agent-3-expertise-testing
5. ✅ Only modify files you own (see FILE_OWNERSHIP_MATRIX.md)
6. ✅ Check dependencies before starting each section
7. ✅ Document all code with proper API docs
8. ✅ Zero linter errors before marking complete

START NOW:
1. Read all required documents above
2. Check docs/AGENT_STATUS_TRACKER.md for current status
3. Create your git branch: git checkout -b agent-3-expertise-testing
4. Begin Phase 1, Section 1: Expertise Display UI (no dependencies - can start immediately)
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
2. Wait for Agent 1 to complete Section 2 (Payment Models)
3. Start Agent 2 (can start Section 1 immediately)
4. Start Agent 3 (can start Section 1 immediately)

**Recommended:** Option 1 (parallel start) - All agents can start immediately.

---

## ✅ **Pre-Flight Checklist**

Before starting agents, verify:
- [ ] All required documents exist in `docs/` folder
- [ ] `docs/AGENT_STATUS_TRACKER.md` is accessible
- [ ] Git repository is initialized
- [ ] You have 3 Cursor windows/tabs ready
- [ ] You understand the trial run scope (Weeks 1-4, MVP Core)

---

## 🎯 **What Happens Next**

1. **Agents start reading** their assigned documents
2. **Agents create git branches** (agent-1-payment-backend, agent-2-event-ui, agent-3-expertise-testing)
3. **Agents begin work** on Phase 1, Section 1
4. **Agents update status tracker** as they progress
5. **Agents coordinate** via status tracker for dependencies
6. **Agents complete** their sections and integrate work

---

## 📊 **Monitoring Progress**

**Check these files regularly:**
- `docs/AGENT_STATUS_TRACKER.md` - Real-time status
- Git branches - See commits from each agent
- Agent chat windows - See progress and questions

---

**Last Updated:** November 22, 2025, 8:47 PM CST  
**Status:** Ready to Start Trial Run

