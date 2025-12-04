# Parallel Agent Work Guide - Trial Run (Weeks 1-4)

**Date:** November 22, 2025, 8:40 PM CST  
**Purpose:** Complete guide for running 3 agents in parallel on MVP Core  
**Status:** 🚀 Ready to Start

---

## 🚀 **HOW TO START THE TRIAL RUN (3 Simple Steps)**

### **Step 1: Open 3 Cursor Windows/Tabs**
Open 3 separate Cursor windows (or use tabs) - one for each agent.

### **Step 2: Copy & Paste Agent Prompts**
Copy the agent prompt below and paste into each Cursor window:
- **Window 1:** Agent 1 prompt (Payment Backend)
- **Window 2:** Agent 2 prompt (Event UI)
- **Window 3:** Agent 3 prompt (Expertise UI & Testing)

### **Step 3: Let Them Work**
Agents will start working immediately in parallel. They'll coordinate automatically on Day 2 and Week 4.

**That's it!** The agents will work independently and coordinate as needed.

---

## 🎯 **Quick Start - How to Begin Trial Run**

---

## 🤖 **AGENT 1: Payment Processing & Revenue**

### **Copy This Prompt:**

```
You are Agent 1: Payment Processing & Revenue (Backend & Integration)

TASK ASSIGNMENT:
Read docs/agents/tasks/trial_run/task_assignments.md - AGENT 1 section (starting at line 95)
Read docs/agents/reference/quick_reference.md for code patterns and examples
Read docs/agents/reference/date_time_format.md - **CRITICAL: Date/time format for all documents** ⚠️
Read docs/agents/protocols/git_workflow.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/agents/protocols/file_ownership.md - **CRITICAL: Which files you own**
Read docs/agents/status/update_protocol.md - **CRITICAL: How to update status tracker**
Read docs/agents/protocols/integration_protocol.md - How to integrate with Agent 2
Read docs/agents/status/status_tracker.md - CHECK THIS BEFORE STARTING ANY TASK
Read docs/agents/status/dependency_guide.md - How to check dependencies
Read docs/TRIAL_RUN_SCOPE.md for trial run context

YOUR ROLE:
- Backend & Integration
- Payment processing, Stripe integration, revenue splits
- Focus: Services, models, payment processing, integration testing

PHASE 1 TASKS (Start Immediately):
- Section 1: Stripe Integration Setup
- Section 2: Payment Models - ⚠️ UPDATE STATUS TRACKER WHEN COMPLETE (Agent 2 needs this)
- Section 3: Payment Service Implementation
- Section 4: Basic Revenue Split Calculation

DEPENDENCY CHECKING:
- BEFORE starting any task: Check docs/agents/status/status_tracker.md
- WHEN completing Section 2: Update status tracker immediately (Agent 2 is waiting)
- WHEN completing any work others depend on: Update status tracker

CRITICAL RULES:
- ✅ ALWAYS use AppColors/AppTheme (NO Colors.*)
- ✅ Follow existing service patterns (see ExpertiseEventService)
- ✅ Use dependency injection (GetIt)
- ✅ Models must be immutable (all fields final)
- ✅ Zero linter errors before completion

COORDINATION:
- When Section 2 complete: Update docs/agents/status/status_tracker.md immediately
- Check status tracker before starting each section
- Coordinate with Agent 3 for integration testing in Phase 4

Follow the task exactly as written in docs/agents/tasks/trial_run/task_assignments.md. Start with Phase 1, Section 1.
```

---

## 🎨 **AGENT 2: Event Discovery & Hosting UI**

### **Copy This Prompt:**

```
You are Agent 2: Event Discovery & Hosting UI (Frontend & UX)

TASK ASSIGNMENT:
Read docs/agents/tasks/trial_run/task_assignments.md - AGENT 2 section (starting at line 543)
Read docs/agents/reference/quick_reference.md for code patterns and examples
Read docs/agents/reference/date_time_format.md - **CRITICAL: Date/time format for all documents** ⚠️
Read docs/agents/protocols/git_workflow.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/agents/protocols/file_ownership.md - **CRITICAL: Which files you own**
Read docs/agents/status/update_protocol.md - **CRITICAL: How to update status tracker**
Read docs/agents/protocols/integration_protocol.md - How to integrate with Agent 1's work
Read docs/agents/status/status_tracker.md - CHECK THIS BEFORE STARTING ANY TASK
Read docs/agents/status/dependency_guide.md - How to check dependencies
Read docs/TRIAL_RUN_SCOPE.md for trial run context

YOUR ROLE:
- Frontend & UX
- Event discovery UI, event hosting UI, user experience
- Focus: Pages, widgets, user experience, event discovery, hosting UI

PHASE 1 TASKS (Start Immediately):
- Section 1: Event Discovery UI (Early Start) - NO DEPENDENCIES
  - Event Browse/Search Page
  - Event Details Page
  - "My Events" Page
  - Replace "Coming Soon" placeholder
- Section 2: Payment UI - ⚠️ CHECK STATUS TRACKER - Wait for Agent 1 Section 2

DEPENDENCY CHECKING:
- BEFORE starting Payment UI (Section 2): Check docs/agents/status/status_tracker.md
- Look for "Agent 1 Completed Sections" - is Section 2 (Payment Models) listed?
- If NOT listed: You're blocked, continue with Event Discovery UI
- If listed: Dependency ready, proceed with Payment UI
- WHEN blocked: Add yourself to "Blocked Tasks" in status tracker

CRITICAL RULES:
- ✅ ALWAYS use AppColors/AppTheme (NO Colors.*) - 100% adherence required
- ✅ Follow existing page/widget patterns
- ✅ Use dependency injection (GetIt) for services
- ✅ Integrate with existing ExpertiseEventService
- ✅ Zero linter errors before completion

COORDINATION:
- Can start Event Discovery UI immediately (no dependencies)
- Check status tracker before starting Payment UI (Section 2)
- If Agent 1 Section 2 not ready: Continue with Event Discovery UI
- Update status tracker when completing work
- Coordinate with Agent 3 for integration testing in Phase 4

Follow the task exactly as written in docs/agents/tasks/trial_run/task_assignments.md. Start with Phase 1, Section 1 (Event Discovery UI).
```

---

## 🧪 **AGENT 3: Expertise UI & Testing**

### **Copy This Prompt:**

```
You are Agent 3: Expertise UI & Testing (Frontend & Quality Assurance)

TASK ASSIGNMENT:
Read docs/agents/tasks/trial_run/task_assignments.md - AGENT 3 section (starting at line 1062)
Read docs/agents/reference/quick_reference.md for code patterns and examples
Read docs/agents/reference/date_time_format.md - **CRITICAL: Date/time format for all documents** ⚠️
Read docs/agents/protocols/git_workflow.md - **CRITICAL: Git workflow to prevent conflicts**
Read docs/agents/protocols/file_ownership.md - **CRITICAL: Which files you own**
Read docs/agents/status/update_protocol.md - **CRITICAL: How to update status tracker**
Read docs/agents/protocols/integration_protocol.md - How to integrate with Agents 1 & 2
Read docs/agents/status/status_tracker.md - CHECK THIS BEFORE STARTING ANY TASK
Read docs/agents/status/dependency_guide.md - How to check dependencies
Read docs/TRIAL_RUN_SCOPE.md for trial run context

YOUR ROLE:
- Frontend & Quality Assurance
- Expertise UI, integration testing, quality assurance
- Focus: Widgets, testing, quality assurance

PHASE 1 TASKS (Start Immediately):
- Section 1: Review Expertise System
- Section 2: Expertise Display Widget
- Section 3: Expertise Dashboard Page

DEPENDENCY CHECKING:
- BEFORE starting Integration Testing (Phase 4): Check status tracker
- Look for "Phase Completion Status" - are Phases 1-3 complete?
- If NOT complete: Wait, continue with other work
- If complete: Proceed with Integration Testing
- WHEN blocked: Add yourself to "Blocked Tasks" in status tracker

CRITICAL RULES:
- ✅ ALWAYS use AppColors/AppTheme (NO Colors.*) - 100% adherence required
- ✅ Follow existing widget patterns
- ✅ Use dependency injection (GetIt) for services
- ✅ Integrate with existing ExpertiseService
- ✅ Zero linter errors before completion

COORDINATION:
- Work completely independently Phases 1-3
- Check status tracker before Phase 4 (Integration Testing)
- Coordinate with Agents 1 & 2 for integration testing in Phase 4
- Update status tracker when completing work

Follow the task exactly as written in docs/agents/tasks/trial_run/task_assignments.md. Start with Phase 1, Section 1.
```

---

## 📋 **Trial Run Overview**

### **What You're Building:**
**Weeks 1-4: MVP Core Functionality**

This enables users to:
- ✅ Discover events (browse, search, view details)
- ✅ Create and host events (simple creation form, templates)
- ✅ Pay for events (Stripe integration, revenue splits)
- ✅ Attend events (registration, "My Events" page)
- ✅ See expertise progress (display, dashboard, unlock indicator)

### **Timeline:**
- **Week 1:** Payment Processing Foundation + Event Discovery UI + Expertise UI
- **Week 2:** Event Discovery UI (continue) + Backend Improvements + Expertise Unlock
- **Week 3:** Event Hosting UI + Service Improvements + Test Planning
- **Week 4:** Integration Testing + UI Polish + Bug Fixes

### **Success Criteria:**
- All MVP features work end-to-end
- Zero linter errors
- 100% design token adherence
- Integration tests pass
- No critical bugs

---

## 🔄 **Dependency Checking & Communication**

### **⚠️ CRITICAL: Always Check Dependencies**

**Before starting ANY task:**
1. Read `docs/agents/status/status_tracker.md`
2. Check "Dependency Map" - what do you depend on?
3. Check "Completed Work" - is dependency ready?
4. Check "Blocked Tasks" - are you blocked?

**When completing work others depend on:**
1. Update `docs/agents/status/status_tracker.md` immediately
2. Move to "Completed Work" section
3. Update "Dependency Map" - mark as ready
4. Remove from "Blocked Tasks" if it unblocks others

**See:** `docs/agents/status/dependency_guide.md` for detailed instructions

---

## 🔄 **Coordination Protocol**

### **Dependency Check Points:**

**Phase 1, Section 1:**
- All agents start independently
- Agent 1: Payment backend (Section 1)
- Agent 2: Event Discovery UI (Section 1)
- Agent 3: Expertise UI (Section 1)
- ✅ All check status tracker before starting

**Phase 1, Section 2:**
- ⚠️ **DEPENDENCY CHECK:** Agent 2 checks status tracker for Agent 1 Section 2
- If Agent 1 Section 2 complete: Agent 2 can start Payment UI
- If not complete: Agent 2 continues Event Discovery UI
- Agent 1: Updates status tracker when Section 2 complete
- Agent 3: Continues independently

**Phase 1, Sections 3-4:**
- All agents continue their work
- Check status tracker before each section
- Update status tracker when completing work

**Phase 2-3:**
- All agents continue independently
- Check status tracker regularly
- Update status tracker when completing work

**Phase 4:**
- ⚠️ **DEPENDENCY CHECK:** Agent 3 checks status tracker - are Phases 1-3 complete?
- If complete: Agent 3 coordinates integration testing
- All agents fix bugs together
- Final integration and polish

---

## 📚 **Key Documents Reference**

### **All Agents Must Read:**
1. `docs/agents/tasks/trial_run/task_assignments.md` - Your specific task assignments
2. `docs/agents/reference/quick_reference.md` - Code patterns and examples
3. `docs/agents/reference/date_time_format.md` - **CRITICAL** - Date/time format for all documents ⚠️
4. `docs/agents/status/status_tracker.md` - **CHECK THIS BEFORE EVERY TASK** ⚠️
5. `docs/agents/status/dependency_guide.md` - How to check dependencies ⚠️
6. `docs/agents/protocols/git_workflow.md` - **READ THIS FIRST** - Git workflow to prevent conflicts ⚠️
7. `docs/agents/protocols/file_ownership.md` - **READ THIS FIRST** - Which files you own ⚠️
8. `docs/agents/status/update_protocol.md` - How to update status tracker safely ⚠️
9. `docs/agents/protocols/integration_protocol.md` - How to integrate with other agents' work ⚠️
10. `docs/TRIAL_RUN_SCOPE.md` - Trial run context and success criteria
11. `docs/MASTER_PLAN.md` - Overall Master Plan context
12. `docs/MVP_CRITICAL_ANALYSIS.md` - MVP requirements

### **Architecture & Standards:**
- `.cursorrules` - Project rules and standards
- `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md` - Development methodology
- `docs/plans/philosophy_implementation/DOORS.md` - Philosophy alignment

---

## ✅ **Quality Checklist (All Agents)**

Before marking any task complete:

- [ ] Code uses `AppColors`/`AppTheme` (NO `Colors.*`)
- [ ] Services use dependency injection (GetIt)
- [ ] Models are immutable (all fields `final`)
- [ ] Error handling implemented
- [ ] Zero linter errors
- [ ] Follows existing code patterns
- [ ] Integration with existing services works
- [ ] Documentation complete

---

## 🚨 **Critical Rules (All Agents)**

### **1. Design Tokens (100% Adherence):**
```dart
// ✅ CORRECT
color: AppTheme.primaryColor
backgroundColor: AppColors.background

// ❌ WRONG
color: Colors.blue
backgroundColor: Colors.white
```

### **2. Architecture:**
- ai2ai only (never p2p)
- Offline-first (handle offline gracefully)
- Self-improving (where applicable)

### **3. Code Standards:**
- Zero linter errors
- Full integration (users can access features)
- Tests written (where applicable)
- Documentation complete

---

## 📊 **Progress Tracking**

### **Update Daily:**
- Mark completed tasks in `docs/agents/tasks/trial_run/task_assignments.md`
- Update `docs/MASTER_PLAN.md` progress section
- Document any blockers or issues

### **Week 1 Progress:**
- Agent 1: Payment Processing Foundation
- Agent 2: Event Discovery UI
- Agent 3: Expertise UI

### **Week 2 Progress:**
- Agent 1: Backend Improvements
- Agent 2: Event Discovery UI (complete) + Payment UI
- Agent 3: Expertise Unlock Indicator

### **Week 3 Progress:**
- Agent 1: Service Improvements
- Agent 2: Event Hosting UI
- Agent 3: Test Planning

### **Week 4 Progress:**
- Agent 1: Integration Testing Support
- Agent 2: UI Polish
- Agent 3: Integration Testing + Bug Fixes

---

## 🎯 **Success Metrics**

### **Week 1 Success:**
- ✅ Payment backend complete (Agent 1)
- ✅ Payment models shared (Agent 1 → Agent 2)
- ✅ Event Discovery UI started (Agent 2)
- ✅ Expertise UI started (Agent 3)

### **Week 2 Success:**
- ✅ Event Discovery UI complete (Agent 2)
- ✅ Backend integration ready (Agent 1)
- ✅ Expertise UI complete (Agent 3)

### **Week 3 Success:**
- ✅ Event Hosting UI complete (Agent 2)
- ✅ Integration prep complete (Agent 1)
- ✅ Test plan complete (Agent 3)

### **Week 4 Success:**
- ✅ Integration tests complete (Agent 3)
- ✅ All bugs fixed (all agents)
- ✅ MVP fully functional (all agents)

---

## 🔧 **Troubleshooting**

### **If Agent 1 is Blocked:**
- Check Stripe integration setup
- Verify package dependencies
- Review existing service patterns

### **If Agent 2 is Blocked:**
- Check existing ExpertiseEventService
- Review existing page/widget patterns
- Verify design token usage

### **If Agent 3 is Blocked:**
- Check existing ExpertiseService
- Review existing widget patterns
- Verify design token usage

### **If Coordination Issues:**
- Check daily sync points
- Verify model sharing (Agent 1 → Agent 2)
- Ensure integration points are clear

---

## 📝 **Daily Workflow**

### **For Each Agent:**

1. **Morning:**
   - Read your task for the day
   - Check coordination points (if Day 2 or Week 4)
   - Review code patterns if needed

2. **During Work:**
   - Follow task instructions exactly
   - Reference quick guide for patterns
   - Update progress as you complete tasks

3. **End of Day:**
   - Update progress in Master Plan
   - Share models/services if needed (Agent 1)
   - Document any blockers

4. **Coordination:**
   - Day 2: Agent 1 shares payment models
   - Week 4: Agent 3 coordinates integration testing
   - Daily: Progress updates

---

## 🚀 **Getting Started - Step by Step**

### **Step 1: Prepare**
- [ ] Read `docs/TRIAL_RUN_SCOPE.md` for context
- [ ] Read `docs/agents/reference/quick_reference.md` for patterns
- [ ] Open 3 Cursor windows/tabs

### **Step 2: Start Agent 1**
- Copy Agent 1 prompt above
- Paste into Cursor window 1
- Agent 1 starts payment backend work

### **Step 3: Start Agent 2**
- Copy Agent 2 prompt above
- Paste into Cursor window 2
- Agent 2 starts Event Discovery UI work

### **Step 4: Start Agent 3**
- Copy Agent 3 prompt above
- Paste into Cursor window 3
- Agent 3 starts Expertise UI work

### **Step 5: Monitor Progress**
- Check progress daily
- Coordinate on Day 2 (payment models)
- Coordinate in Week 4 (integration testing)

### **Step 6: Week 4 Evaluation**
- Review success criteria
- Evaluate trial run success
- Decide on continuation

---

## 📞 **When to Ask for Help**

Ask for clarification if:
- ❓ Unclear which existing service to use
- ❓ Unclear file location
- ❓ Existing code conflicts with requirements
- ❓ Design token usage is unclear
- ❓ Integration point is unclear

**Don't guess - ask for clarification!**

---

## 🎉 **After Trial Run**

### **If Successful:**
- Continue with Phase 2 (Weeks 5-8)
- Use same 3-agent structure
- Apply lessons learned
- Extend task assignments

### **If Issues Found:**
- Address issues before continuing
- Adjust agent assignments if needed
- Improve documentation if needed
- Refine coordination process if needed

---

**Last Updated:** November 22, 2025  
**Status:** Ready to Start Trial Run

