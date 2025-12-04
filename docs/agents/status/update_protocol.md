# Status Tracker Update Protocol

**Date:** November 22, 2025, 8:40 PM CST  
**Purpose:** Prevent conflicts when multiple agents update status tracker  
**Status:** 🟢 Active

---

## 🚨 **The Problem**

Multiple agents updating `docs/agents/status/status_tracker.md` simultaneously can cause:
- Lost updates (one overwrites the other)
- Conflicting information
- Dependency tracking errors
- Blocked tasks not properly tracked

---

## ✅ **Solution: Atomic Update Protocol**

### **Rule 1: Read First, Update Second**
**ALWAYS read the latest version before updating**

```bash
# Before updating
git pull origin main  # Get latest
# Read docs/agents/status/status_tracker.md
# Then update
```

### **Rule 2: Update Only Your Section**
**Each agent updates ONLY their own section**

- Agent 1: Updates "Agent 1" section only
- Agent 2: Updates "Agent 2" section only
- Agent 3: Updates "Agent 3" section only

### **Rule 3: One Update at a Time**
**Don't update multiple sections in one edit**

- Update your status
- Commit
- Then update "Completed Work" if needed
- Commit again

---

## 📋 **Update Process**

### **Step 1: Read Latest**
```bash
# Pull latest changes
git pull origin main

# Read status tracker
# Check current status
# Check if others updated
```

### **Step 2: Update Your Section**
```
Update ONLY your section:
- Current Phase/Section
- Status
- Blocked status
- Completed sections
```

### **Step 3: Update Completed Work (If Applicable)**
```
If you completed work others depend on:
- Move to "Completed Work" section
- Update "Dependency Map"
- Remove from "Blocked Tasks" if applicable
```

### **Step 4: Commit Immediately**
```bash
# Commit your update
git add docs/agents/status/status_tracker.md
git commit -m "[AGENT-X] Updated status tracker - Section Y complete"
git push origin agent-X-[your-branch]
```

---

## 🔄 **Update Sequence**

### **When Multiple Agents Need to Update:**

**Preferred Sequence:**
1. Agent 1 updates (completes Section 2)
2. Agent 2 reads update
3. Agent 2 updates (removes from blocked)
4. Agent 3 updates (if needed)

**If Conflict:**
1. Read latest version
2. Merge your changes with latest
3. Update again
4. Commit

---

## 📝 **Update Templates**

### **Template 1: Completing a Section**
```
### **Agent X Completed Sections:**
- Section 1 - [Name] ✅ COMPLETE
- Section 2 - [Name] ✅ COMPLETE  ← ADD THIS

**When Agent X completes Section Y:**
- ✅ Update this section: "Section Y - [Name] ✅ COMPLETE"
- ✅ Update "Dependency Map" if others depend on it
- ✅ Remove from "Blocked Tasks" if it unblocks others
```

### **Template 2: Updating Status**
```
### **Agent X: [Role]**
**Current Phase:** Phase Y
**Current Section:** Section Z - [Name]
**Status:** 🟢 Complete  ← UPDATE THIS
**Blocked:** ❌ No
**Waiting For:** None
**Ready For Others:** ✅ Section Y (if others need it)  ← UPDATE THIS
```

### **Template 3: Marking Dependency Ready**
```
### **Agent X → Agent Y:**
- **Dependency:** [Name] (Agent X Section Z)
- **Needed For:** [Name] (Agent Y Section W)
- **Status:** ✅ READY  ← UPDATE THIS
- **Check:** See "Agent X Completed Sections" below
```

---

## ⚠️ **Conflict Resolution**

### **If You Get a Merge Conflict:**

1. **Read the conflict:**
   ```
   <<<<<<< HEAD
   Your update
   =======
   Their update
   >>>>>>> main
   ```

2. **Merge both updates:**
   - Keep your status update
   - Keep their status update
   - Remove conflict markers

3. **Verify:**
   - Both agents' statuses are correct
   - No duplicate information
   - Dependency map is accurate

4. **Commit:**
   ```bash
   git add docs/agents/status/status_tracker.md
   git commit -m "[AGENT-X] Resolved status tracker conflict"
   git push origin agent-X-[your-branch]
   ```

---

## ✅ **Update Checklist**

Before updating status tracker:
- [ ] Pulled latest main
- [ ] Read current status
- [ ] Verified no conflicts
- [ ] Ready to update only your section

After updating:
- [ ] Updated only your section
- [ ] Updated "Completed Work" if applicable
- [ ] Updated "Dependency Map" if applicable
- [ ] Committed immediately
- [ ] Pushed to your branch

---

## 🎯 **Best Practices**

1. **Update frequently** - Don't wait until end of phase
2. **Update immediately** - When completing work others depend on
3. **Be specific** - Clear section names and status
4. **Don't overwrite** - Read before updating
5. **Commit quickly** - Don't leave updates uncommitted

---

**Last Updated:** November 22, 2025, 8:40 PM CST  
**Status:** Ready for Use

