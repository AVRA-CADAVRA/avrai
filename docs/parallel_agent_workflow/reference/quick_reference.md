# Quick Reference Guide - Parallel Agent Workflow

**Date:** November 25, 2025  
**Purpose:** Quick lookup guide for common tasks and questions  
**Status:** ✅ Ready to Use

---

## 🚀 **Quick Start Commands**

### **Git Setup (Each Agent):**
```bash
# Create your branch
git checkout -b agent-1-[role-name]

# Daily workflow - before starting work
git checkout main
git pull origin main
git checkout agent-1-[role-name]
git merge main

# Commit your work
git add [your-files]
git commit -m "[AGENT-1] Phase 1 Section 1 - [Description]"
git push origin agent-1-[role-name]
```

---

## 📋 **Status Tracker Update**

### **When Completing Work Others Depend On:**
1. Read latest status tracker: `git pull origin main`
2. Update your section:
   ```
   **Completed Sections:**
   - Section 1 - [Name] ✅ COMPLETE
   ```
3. Update dependency map:
   ```
   **Status:** ✅ READY
   ```
4. Commit immediately:
   ```bash
   git add [status_tracker.md]
   git commit -m "[AGENT-1] Updated status tracker - Section 1 complete"
   git push origin agent-1-[role-name]
   ```

---

## 🔍 **Dependency Checking**

### **Before Starting Any Task:**
1. Read status tracker
2. Check "Dependency Map" for your dependencies
3. Check "Completed Work" - is dependency listed?
4. If NOT listed → You're blocked, wait
5. If listed → Dependency ready, proceed

### **Quick Check:**
```bash
# Read status tracker
cat [PATH_TO_STATUS_TRACKER]

# Look for:
# - Your dependencies in "Dependency Map"
# - Dependency status (⏳ Waiting or ✅ READY)
# - Completed work in "Completed Sections"
```

---

## 📁 **File Ownership**

### **Before Creating/Modifying Files:**
1. Check `docs/parallel_agent_workflow/protocols/file_ownership.md`
2. Verify file is in your ownership list
3. If shared file, coordinate with other agents
4. If owned by others, read-only access only

### **Ownership Rules:**
- ✅ You can CREATE/MODIFY files you own
- ✅ You can READ files owned by others
- ❌ You CANNOT MODIFY files owned by others
- ⚠️ Shared files require coordination

---

## 🔄 **Integration Points**

### **When Integrating with Other Agents:**

1. **Check Status Tracker:**
   - Is dependency marked complete?
   - Is dependency in "Completed Work"?

2. **Pull Latest Main:**
   ```bash
   git checkout main
   git pull origin main
   git checkout agent-1-[role-name]
   git merge main
   ```

3. **Use Other Agent's Work:**
   - Import their models/services
   - Use dependency injection (if applicable)
   - Test integration

4. **Update Status Tracker:**
   - Mark integration complete
   - Update dependency map if needed

---

## 🚨 **Common Issues & Solutions**

### **Issue: Git Merge Conflict**
**Solution:**
1. Read conflict markers
2. Keep your changes if correct
3. Keep their changes if correct
4. Merge both if needed
5. Remove conflict markers
6. Test after resolving

### **Issue: Status Tracker Conflict**
**Solution:**
1. Pull latest: `git pull origin main`
2. Read latest status tracker
3. Merge your changes with latest
4. Update again
5. Commit

### **Issue: File Ownership Confusion**
**Solution:**
1. Check `docs/parallel_agent_workflow/protocols/file_ownership.md`
2. Verify file ownership
3. If shared, coordinate with other agents
4. If owned by others, use read-only access

### **Issue: Dependency Blocking**
**Solution:**
1. Check status tracker regularly
2. Wait for dependency to be marked complete
3. When ready, proceed immediately
4. Update status tracker when unblocked

---

## ✅ **Checklists**

### **Before Starting Work:**
- [ ] Pulled latest main
- [ ] Checked status tracker
- [ ] Verified dependencies are ready
- [ ] Checked file ownership
- [ ] Switched to your branch

### **Before Committing:**
- [ ] Code follows project standards
- [ ] Zero linter errors
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Status tracker updated (if needed)

### **When Completing Dependencies:**
- [ ] Work is complete and tested
- [ ] Status tracker updated
- [ ] Dependency map updated
- [ ] Blocked tasks updated (if applicable)
- [ ] Committed and pushed

---

## 📞 **Quick Contacts**

### **Protocols:**
- Git Workflow: `docs/parallel_agent_workflow/protocols/git_workflow.md`
- File Ownership: `docs/parallel_agent_workflow/protocols/file_ownership.md`
- Integration: `docs/parallel_agent_workflow/protocols/integration_protocol.md`
- Status Updates: `docs/parallel_agent_workflow/protocols/status_update_protocol.md`
- Dependencies: `docs/parallel_agent_workflow/protocols/dependency_guide.md`

### **Guides:**
- Parallel Start: `docs/parallel_agent_workflow/guides/parallel_start_guide.md`
- Parallel Work: `docs/parallel_agent_workflow/guides/parallel_work_guide.md`
- Risks: `docs/parallel_agent_workflow/guides/risks_and_mitigation.md`

---

## 🎯 **Status Symbols**

- 🟢 Complete
- 🟡 In Progress
- 🔴 Blocked
- ⏳ Waiting
- ✅ Ready
- ❌ Not Ready

---

## 📝 **Commit Message Format**

```
[AGENT-X] Phase Y Section Z - [Brief Description]

- Files: [list of files]
- Dependencies: [if others depend on this]
- Status: [Complete/In Progress]
```

---

**Last Updated:** November 25, 2025  
**Status:** Ready to Use

