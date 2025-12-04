# Cursor Rules Applicable to Parallel Agent Workflow

**Date:** November 25, 2025  
**Purpose:** Document all cursor rules that apply to parallel agent workflow  
**Status:** ✅ Complete

---

## 🎯 **Overview**

This document lists all cursor rules from `.cursorrules` that are relevant to running multiple agents in parallel. These rules should be included in your project's `.cursorrules` file or referenced by agents.

---

## 🚨 **MANDATORY: Session Start Protocol**

**At the start of EVERY new chat/task, agents MUST:**

1. **Read the entry point document:**
   ```
   read_file('docs/START_HERE_NEW_TASK.md')
   ```
   *(Or your project's equivalent entry point)*

2. **Determine task type:**
   - **Implementation task** (implement, create, build, add, start, proceed)
     → Follow context gathering protocol
   - **Status/progress query** (where are we, what's the status, how far along)
     → Find and read ALL related documents (plan + complete + progress + status)

3. **Follow the protocol before any code:**
   - Do NOT skip to implementation
   - Do NOT skip context gathering
   - The investment saves hours to days

---

## 📚 **Key Documentation Rules**

### **Entry Point Protocol:**
- Agents must read entry point document at start of EVERY task
- Must check Master Plan (or equivalent) for execution sequence
- Must check status tracker before starting work

### **Status Query Protocol:**
When user says any of these, read ALL related documents:
- "where are we with [topic]"
- "what's the status of [topic]"
- "how far along is [topic]"
- "what's complete in [topic]"
- "show me progress on [topic]"
- "update me on [topic]"

**Protocol:**
```bash
# ⚠️ CRITICAL: Never read just one document for status queries

# Find ALL related documents:
glob_file_search('**/*[topic]*.md')
glob_file_search('**/*[topic]*plan*.md')
glob_file_search('**/*[topic]*complete*.md')
glob_file_search('**/*[topic]*progress*.md')
glob_file_search('**/*[topic]*status*.md')
glob_file_search('**/*[topic]*summary*.md')

# Read ALL found documents, then synthesize comprehensive answer
```

---

## 📁 **Documentation Organization Protocol (MANDATORY)**

**ALL agents MUST follow the Documentation Protocol when creating or organizing documentation.**

### **Critical Rules:**
- ✅ **DO:** Create phase folders in `prompts/` and `tasks/`
- ✅ **DO:** Update SINGLE status tracker with new phase sections
- ✅ **DO:** Organize reports by agent first, then phase
- ❌ **DO NOT:** Create files in `docs/` root (e.g., `docs/PHASE_3_TASKS.md`)
- ❌ **DO NOT:** Create phase-specific status trackers (use single file)
- ❌ **DO NOT:** Create phase-specific protocols (use shared protocols)

### **When creating documentation:**
- Check if it's phase-specific or shared
- Place in correct folder per protocol
- Update status tracker (single file) if needed
- Follow file naming conventions

---

## 🎨 **Project-Specific Rules**

### **Design Tokens (100% Adherence Required)**
- ✅ ALWAYS use `AppColors` or `AppTheme` for colors
- ❌ NEVER use direct `Colors.*` (will be flagged)
- This is non-negotiable per user memory

### **Architecture**
- System is **ai2ai only** (never p2p)
- All device interactions through personality learning AI
- AIs must always be self-improving (individual, network, ecosystem)

### **Code Standards**
- Zero linter errors before completion
- Full integration (users can access features)
- Tests written
- Documentation complete

### **Philosophy**
- **CRITICAL:** Reference project philosophy documents
- **Core Principle:** "Doors, not badges" - Authentic contributions, not gamification
- Never delete unused code (may be setup for future)
- Auto-generated docs are NOT deletable
- All work must align with project philosophy

---

## 🚨 **Critical Warnings**

**STOP and clarify if:**
- [ ] Can't find main plan document
- [ ] Task conflicts with existing plan
- [ ] Multiple plans with contradictory specs
- [ ] Unclear where code should be placed
- [ ] Can't determine dependencies
- [ ] Found existing implementation but specs differ

**DO NOT proceed until clarified.**

---

## ✅ **Before Starting ANY Implementation**

**Confirm ALL of these (MANDATORY):**
- [ ] I have read entry point document (START_HERE_NEW_TASK.md or equivalent)
- [ ] I have read project philosophy documents - MANDATORY
- [ ] I have read Development Methodology - MANDATORY
- [ ] I have read Documentation Protocol - MANDATORY for documentation
- [ ] I have checked Master Plan (or equivalent) for execution sequence
- [ ] I have checked status tracker before starting work
- [ ] I have discovered ALL relevant plans
- [ ] I have filtered plans by recency + relevance
- [ ] I have read high-priority related plans
- [ ] I have checked for conflicts
- [ ] I have searched for existing implementations
- [ ] I understand the architecture
- [ ] I have created a TODO list
- [ ] I have communicated my plan to user
- [ ] User has approved the approach

**If ANY checkbox is unchecked, DO NOT START CODING.**

---

## ⚡ **Context Gathering is Mandatory**

**Time Investment:** 40 minutes  
**Time Saved:** 50-90% (hours to days)  
**Proven ROI:** Multiple 99% time savings in actual implementations

**DO NOT skip context gathering to "save time" - it costs more later.**

---

## 🎯 **The Golden Rule**

```
40 minutes of context gathering
saves
40 hours of implementation

ALWAYS invest the 40 minutes.
```

---

## 🔄 **Parallel Agent Specific Rules**

### **Status Tracker Protocol:**
- **ALWAYS check status tracker** before starting work with dependencies
- **ALWAYS update status tracker** when completing work others depend on
- **ALWAYS read latest** before updating (pull from git first)
- **ALWAYS update only your section** - don't modify others' sections

### **File Ownership Protocol:**
- **ALWAYS check file ownership** before creating/modifying files
- **ALWAYS respect ownership** - read-only for others' files
- **ALWAYS coordinate** before modifying shared files

### **Git Workflow Protocol:**
- **ALWAYS use your own branch** - never commit directly to main
- **ALWAYS pull latest main** before starting work
- **ALWAYS merge main into your branch** regularly
- **ALWAYS test after merge** - don't assume it works

### **Dependency Protocol:**
- **ALWAYS check dependencies** before starting work
- **ALWAYS wait if blocked** - don't proceed without dependencies
- **ALWAYS signal completion** immediately when others depend on your work

### **Integration Protocol:**
- **ALWAYS document APIs** when creating services others will use
- **ALWAYS test integration** before marking complete
- **ALWAYS coordinate** at integration points

---

## 📊 **Success Metrics (Proven)**

Following this protocol:
- Phase 1 Integration: 40 min → Saved 5 days (99%)
- Optional Enhancements: 30 min → Saved 3 days (85%)
- Phase 2.1: 20 min → Saved 11 days (99.5%)

**NOT following this protocol:**
- Risk duplicating existing work
- Risk wrong architecture/placement
- 2-10x longer implementation time

---

## 🎯 **How to Apply These Rules**

### **Option 1: Add to Your .cursorrules File**
Copy the relevant sections from this document into your project's `.cursorrules` file.

### **Option 2: Reference in Agent Prompts**
Include references to these rules in your agent prompts:
```
Read docs/parallel_agent_workflow/CURSOR_RULES.md - Applicable cursor rules
```

### **Option 3: Create Project-Specific Rules**
Adapt these rules for your project's specific needs and add to `.cursorrules`.

---

## 📝 **Rule Categories**

### **Mandatory Rules (Must Follow):**
1. Session Start Protocol
2. Documentation Organization Protocol
3. Status Tracker Protocol
4. File Ownership Protocol
5. Git Workflow Protocol
6. Dependency Protocol
7. Integration Protocol

### **Project-Specific Rules (Customize):**
1. Design Tokens
2. Architecture Rules
3. Code Standards
4. Philosophy Alignment

### **Best Practices (Recommended):**
1. Context Gathering
2. Status Query Protocol
3. Critical Warnings
4. Pre-Implementation Checklist

---

## 🔧 **Customization Guide**

### **For Your Project:**
1. **Identify applicable rules** - Which rules apply to your project?
2. **Customize project-specific rules** - Design tokens, architecture, etc.
3. **Add to .cursorrules** - Include in your project's cursor rules file
4. **Reference in agent prompts** - Make sure agents read these rules
5. **Test with one agent first** - Verify rules work before parallel execution

---

## ✅ **Checklist for Rule Application**

Before starting parallel agents:
- [ ] Read all applicable cursor rules
- [ ] Customize project-specific rules
- [ ] Add rules to `.cursorrules` file
- [ ] Include rule references in agent prompts
- [ ] Test rules with single agent first
- [ ] Verify all agents understand rules
- [ ] Document any project-specific adaptations

---

**Last Updated:** November 25, 2025  
**Status:** Complete - Ready for Use  
**Version:** 1.0

