# Master Plan System - Requirements & Specifications

**Created:** November 21, 2025  
**Status:** 📋 Requirements Document  
**Purpose:** Complete specification for Master Plan system creation  
**Next Step:** Reorganize existing plans → Create Master Plan → Create Cursor Rule

---

## 🎯 **Core Concept**

### **The Problem:**
- Multiple independent plans in Master Plan Tracker
- No clear execution order
- Plans can overlap or conflict
- Sequential execution wastes time (Feature A finishes, then Feature B starts)
- No optimization for parallel work

### **The Solution:**
- **Single Master Plan** = The ONLY execution plan actively followed
- All other plans become **reference guides** (still updated, but Master Plan is the source of truth)
- Master Plan **optimizes execution** by batching common work phases
- **Catch-up prioritization** enables parallel work
- **Automated workflow** for new features

---

## 📐 **Master Plan Structure**

### **Multi-Dimensional Ordering**

The Master Plan must combine ALL of these factors:

1. **Phases** (1, 2, 3...)
   - Sequential phases within a feature
   - Example: DB models → Service → UI → Tests

2. **Priorities** (P0, P1, P2...)
   - Critical features first
   - P0 = Blocking, must do immediately
   - P1 = High importance
   - P2 = Medium importance

3. **Dependencies** (A before B)
   - Feature A must complete before Feature B can start
   - Dependency graph analysis
   - Example: Event system before monetization

4. **Feature Areas** (monetization, expertise, events...)
   - Logical grouping
   - Related features can be batched
   - Example: All DB model work together

5. **Timeline** (estimated duration)
   - How long each phase takes
   - Used for scheduling
   - Used for catch-up calculations

**Result:** One optimized execution sequence that considers all factors.

---

## 🔄 **Catch-Up Prioritization Logic**

### **The Principle:**

> "If Feature A has already started work, and Feature B is coming in, then Feature B takes priority so that Feature A and Feature B will finish at the same time."

### **The Algorithm:**

**When new feature arrives:**

1. **Check Master Plan state**
   - What features are currently active?
   - What phase is each active feature in?
   - What's the next scheduled phase for each?

2. **Determine catch-up opportunity**
   - Can new feature catch up to active feature's current phase?
   - Calculate: What phases does new feature need to complete to reach active feature's phase?
   - If catch-up is possible → proceed with catch-up logic

3. **Execute catch-up prioritization**
   - **PAUSE** active feature(s) at current phase
   - **PRIORITIZE** new feature to catch up
   - Schedule new feature's catch-up phases (DB models, Service, etc.)
   - Active feature waits (no work scheduled)

4. **Resume in parallel**
   - Once new feature catches up to active feature's phase
   - Both features work on same phase together
   - Continue in parallel for remaining phases
   - They finish at the same time

### **Example Walkthrough:**

**Scenario:**
- Week 2: Feature A (Service layer) — 100% complete
- Feature B arrives: needs DB models → Service → UI → Tests

**Catch-up execution:**
```
Week 2: Feature A (Service 100%) ✅, Feature B added to plan

Week 3: Feature A (PAUSED) + Feature B (DB models) 
        → Feature B catching up, Feature A waits

Week 4: Feature A (PAUSED) + Feature B (Service)
        → Feature B catching up, Feature A waits

Week 5: Feature A & B (UI) 
        → NOW PARALLEL! Both at same phase 🎉

Week 6: Feature A & B (Tests)
        → PARALLEL! Both finish together 🎉

Total: 6 weeks (parallelized after catch-up)
```

**Without catch-up:**
- Feature A finishes completely (Weeks 1-4)
- Then Feature B starts (Weeks 5-8)
- Total: 8 weeks sequential ❌

**With catch-up:**
- Feature A pauses, Feature B catches up (Weeks 3-4)
- Both work in parallel (Weeks 5-6)
- Total: 6 weeks, both finish together ✅

### **Benefits:**
- ✅ Features finish together (better for integration)
- ✅ More parallel work (better resource utilization)
- ✅ Faster overall timeline
- ✅ New feature doesn't wait for old feature to finish

---

## 📁 **Folder Organization System**

### **Current Structure:**
```
docs/
  OPERATIONS_COMPLIANCE_PLAN.md
  BRAND_DISCOVERY_SPONSORSHIP_PLAN.md
  DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md
  ...
  MASTER_PLAN_TRACKER.md
```

### **New Structure:**
```
docs/
  plans/
    operations_compliance/
      OPERATIONS_COMPLIANCE_PLAN.md (main plan document)
      progress.md (detailed progress tracking)
      status.md (current status)
      blockers.md (blockers/dependencies)
      working_status.md (what's being worked on now)
    brand_sponsorship/
      BRAND_DISCOVERY_SPONSORSHIP_PLAN.md
      progress.md
      status.md
      blockers.md
      working_status.md
    dynamic_expertise/
      DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md
      progress.md
      status.md
      blockers.md
      working_status.md
    ...
  MASTER_PLAN.md (single execution sequence)
  MASTER_PLAN_TRACKER.md (registry of all plans)
```

### **Supporting Documents:**

Each plan folder contains:

1. **`[PLAN_NAME]_PLAN.md`** - Main plan document
   - Full implementation details
   - Phases, timelines, requirements
   - Technical specifications

2. **`progress.md`** - Detailed progress tracking
   - What's been completed
   - What's in progress
   - What's next
   - Percent complete per phase

3. **`status.md`** - Current status
   - Overall status (Active, In Progress, Complete, Paused)
   - Current phase
   - Last updated timestamp
   - Next milestone

4. **`blockers.md`** - Blockers and dependencies
   - What's blocking progress
   - What dependencies are needed
   - External blockers
   - Internal blockers

5. **`working_status.md`** - What's being worked on now
   - Current tasks
   - Who's working on what
   - Active work items
   - Daily/weekly updates

### **Benefits:**
- ✅ All related docs in one place
- ✅ Easy to find everything for a plan
- ✅ Clear separation of concerns
- ✅ Master Plan can reference plan folders easily

---

## 📊 **Status Tracking**

### **Master Plan Level:**
- **Brief overview** only
- Overall progress (% complete)
- Key milestones
- Current phase
- Active features
- Blockers summary

### **Individual Plan Level:**
- **Detailed tracking** in plan folders
- Progress per phase
- Detailed status
- Specific blockers
- Working status updates

**Principle:** Master Plan = high-level view, Plan folders = detailed view

---

## 🤖 **Automated Workflow for New Features**

### **Trigger:**
User says: "I want to add [feature]" or "I want to implement [feature]"

### **Automated Process:**

1. **Create comprehensive plan document**
   - Full implementation details
   - Phases, timelines, requirements
   - Technical specifications
   - Dependencies identified

2. **Create plan folder structure**
   - Create `docs/plans/[feature_name]/` folder
   - Move plan document to folder
   - Create supporting docs (progress.md, status.md, blockers.md, working_status.md)
   - Initialize with default content

3. **Add to Master Plan Tracker**
   - Add entry to tracker
   - Include: Name, Date, Status, File Path, Priority, Timeline
   - Mark as "Active" or appropriate status

4. **Analyze for Master Plan integration**
   - Determine dependencies (what it needs)
   - Determine priority (how critical)
   - Determine feature area (where it fits)
   - Determine timeline (how long)
   - Check for catch-up opportunities

5. **Insert into Master Plan at optimal position**
   - If catch-up opportunity exists → use catch-up logic
   - If no catch-up → insert based on dependencies/priority/timeline
   - Update Master Plan execution sequence
   - Ensure optimal parallelization

6. **Update references**
   - Update Master Plan Tracker
   - Update any cross-references
   - Notify user of integration

### **Key Requirements:**
- ✅ All steps automated
- ✅ No manual integration needed
- ✅ Optimal position always determined
- ✅ Catch-up logic applied when beneficial

---

## 📝 **Cursor Rule Requirements**

### **Rule Name:** `MASTER_PLAN_SYSTEM`

### **Rule Behavior:**

**When user says "I want to add [feature]" or "I want to implement [feature]":**

1. **STOP** - Don't create plan in old location
2. **Create comprehensive plan document** with full implementation details
3. **Create plan folder** at `docs/plans/[feature_name]/`
4. **Move plan document** to folder
5. **Create supporting docs** (progress.md, status.md, blockers.md, working_status.md)
6. **Add to Master Plan Tracker** with all required fields
7. **Analyze for Master Plan integration** (dependencies, priority, feature area, timeline)
8. **Check for catch-up opportunities** (active features, phase alignment)
9. **Insert into Master Plan** at optimal position (using catch-up logic if applicable)
10. **Update Master Plan execution sequence**
11. **Notify user** of integration and position

**When user asks about status or progress:**

1. **Check Master Plan** for high-level overview
2. **Check individual plan folders** for detailed progress
3. **Synthesize** comprehensive answer

**When user wants to work on something:**

1. **Check Master Plan** for current execution sequence
2. **Follow Master Plan order** (it's optimized)
3. **Update plan folder** working_status.md as work progresses
4. **Update Master Plan** progress as phases complete

### **Rule Enforcement:**
- ✅ Master Plan is THE execution plan
- ✅ All new features go through automated workflow
- ✅ Catch-up logic always applied when beneficial
- ✅ No manual plan integration needed

---

## 🔗 **Master Plan Tracker Updates**

### **Current Role:**
- Registry of all plans
- Status tracking
- Reference guide

### **New Role:**
- Still registry of all plans
- Still status tracking
- **But:** Plans marked as "Active" = in Master Plan
- Plans marked as "Reference" = guides only (not in Master Plan)
- Plans marked as "Complete" = done, kept for reference

### **Status Meanings:**
- 🟢 **Active** - In Master Plan, being executed
- 🟡 **In Progress** - Currently being worked on
- ✅ **Complete** - Finished, kept for reference
- ⏸️ **Paused** - Temporarily halted
- 📋 **Reference** - Guide only, not in Master Plan
- ❌ **Deprecated** - No longer relevant

---

## 📋 **Implementation Order**

### **Step 1: Reorganize Existing Plans** (Current Step)
- Read Master Plan Tracker
- Identify all active plans
- Create folder structure for each plan
- Move plan documents to folders
- Create supporting docs (progress.md, status.md, blockers.md, working_status.md)
- Find and move related documentation
- Update cross-references
- Update Master Plan Tracker with new paths

### **Step 2: Create Master Plan**
- Analyze all active plans
- Identify common phases (DB models, Service, UI, Tests, etc.)
- Determine dependencies
- Determine priorities
- Apply catch-up logic where applicable
- Create optimized execution sequence
- Include brief status tracking
- Reference plan folders for details

### **Step 3: Create Cursor Rule**
- Write rule specification
- Implement automated workflow
- Test with example feature
- Document rule behavior
- Add to cursor rules

---

## ✅ **Success Criteria**

### **Master Plan System is Complete When:**

1. ✅ All existing plans reorganized into folders
2. ✅ Master Plan created with optimized execution sequence
3. ✅ Catch-up logic implemented and working
4. ✅ Cursor rule created and enforced
5. ✅ New features automatically integrate
6. ✅ Master Plan is the single source of truth
7. ✅ Individual plans remain as detailed guides
8. ✅ Status tracking works at both levels

---

## 🎯 **Key Principles**

1. **Master Plan = Execution Plan**
   - The ONLY plan actively followed
   - Optimized for parallel work
   - Batches common phases

2. **Individual Plans = Reference Guides**
   - Still updated independently
   - Detailed implementation specs
   - Organized in folders

3. **Catch-Up = Priority for New Features**
   - New features pause active features
   - New features catch up to active phase
   - Then work in parallel
   - Finish together

4. **Automation = No Manual Work**
   - New features auto-integrate
   - Optimal position always determined
   - Catch-up logic always applied

5. **Organization = Easy Navigation**
   - Plans in folders
   - Supporting docs together
   - Clear structure

---

## 📚 **Related Documents**

- **Master Plan Tracker:** `docs/MASTER_PLAN_TRACKER.md`
- **Session Start Protocol:** `docs/START_HERE_NEW_TASK.md`
- **Development Methodology:** `docs/DEVELOPMENT_METHODOLOGY.md`

---

## 🔄 **Next Steps**

1. ✅ **Requirements documented** (this document)
2. ✅ **Reorganize existing plans** (COMPLETE - all plans in folders)
3. ✅ **Create Master Plan** (COMPLETE - optimized execution sequence created)
4. ✅ **Create Cursor Rule** (COMPLETE - automated workflow implemented)

**Status:** ✅ **Master Plan System Complete**

---

**Last Updated:** November 21, 2025  
**Status:** 📋 Requirements Complete - Ready for Implementation  
**Next Action:** Reorganize existing plans into folder system

