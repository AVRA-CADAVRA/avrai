# Git Workflow for Parallel Agents

**Date:** November 22, 2025, 8:40 PM CST  
**Purpose:** Git workflow to prevent conflicts when multiple agents work in parallel  
**Status:** 🟢 Active

---

## 🎯 **Branch Strategy**

### **Each Agent Gets Their Own Branch:**
- **Agent 1:** `agent-1-payment-backend`
- **Agent 2:** `agent-2-event-ui`
- **Agent 3:** `agent-3-expertise-testing`

### **Workflow:**
1. Each agent works on their own branch
2. Regular commits to their branch
3. Merge to `main` (or integration branch) after section completion
4. Pull latest before merging

---

## 📋 **Git Commands for Each Agent**

### **Agent 1 Setup:**
```bash
# Create and switch to agent branch
git checkout -b agent-1-payment-backend
git push -u origin agent-1-payment-backend
```

### **Agent 2 Setup:**
```bash
# Create and switch to agent branch
git checkout -b agent-2-event-ui
git push -u origin agent-2-event-ui
```

### **Agent 3 Setup:**
```bash
# Create and switch to agent branch
git checkout -b agent-3-expertise-testing
git push -u origin agent-3-expertise-testing
```

---

## 🔄 **Daily Git Workflow**

### **Before Starting Work:**
```bash
# Pull latest changes from main
git checkout main
git pull origin main

# Switch to your branch
git checkout agent-X-[your-branch]

# Merge latest main into your branch
git merge main
```

### **During Work:**
```bash
# Regular commits (after each section)
git add [your-files]
git commit -m "[AGENT-X] Phase Y Section Z - [Description]"
git push origin agent-X-[your-branch]
```

### **After Completing a Section:**
```bash
# Ensure you have latest main
git checkout main
git pull origin main

# Switch back to your branch
git checkout agent-X-[your-branch]

# Merge main into your branch (resolve conflicts if any)
git merge main

# Push your work
git push origin agent-X-[your-branch]

# Create merge request to main (or merge if approved)
```

---

## ⚠️ **Conflict Resolution**

### **If Merge Conflicts Occur:**

1. **Don't panic** - conflicts are normal
2. **Read conflict markers:**
   ```
   <<<<<<< HEAD
   Your changes
   =======
   Their changes
   >>>>>>> main
   ```

3. **Resolve conflicts:**
   - Keep your changes if they're correct
   - Keep their changes if they're correct
   - Merge both if needed
   - Remove conflict markers

4. **Test after resolving:**
   ```bash
   # After resolving conflicts
   git add [resolved-files]
   git commit -m "[AGENT-X] Resolved merge conflicts"
   git push origin agent-X-[your-branch]
   ```

---

## 🚨 **Shared File Coordination**

### **Files That Multiple Agents Might Touch:**

**`pubspec.yaml`** - Package dependencies
- **Rule:** Agent 1 adds Stripe first, then Agent 2/3 check before adding packages
- **Process:** 
  1. Check if package already added
  2. If not, add your package
  3. If conflict, coordinate with other agents

**`lib/core/models/`** - Shared models
- **Rule:** Each agent owns their models, but check for conflicts
- **Process:**
  1. Check if model already exists
  2. If exists, use it; don't recreate
  3. If conflict, coordinate

**`lib/core/services/`** - Shared services
- **Rule:** Each agent owns their services
- **Process:**
  1. Check if service already exists
  2. If exists, extend it; don't replace
  3. If conflict, coordinate

---

## 📝 **Commit Message Format**

### **Standard Format:**
```
[AGENT-X] Phase Y Section Z - [Brief Description]

- Files: [list of files]
- Dependencies: [if others depend on this]
- Status: [Complete/In Progress]
```

### **Examples:**
```
[AGENT-1] Phase 1 Section 2 - Payment Models Complete

- Files: lib/core/models/payment.dart, payment_intent.dart, revenue_split.dart
- Dependencies: Agent 2 needs this for Payment UI
- Status: Complete - Ready for Agent 2
```

```
[AGENT-2] Phase 1 Section 1 - Event Discovery UI Complete

- Files: lib/presentation/pages/events/events_browse_page.dart, event_details_page.dart
- Dependencies: None
- Status: Complete
```

---

## ✅ **Pre-Commit Checklist**

Before committing:
- [ ] Code follows design tokens (AppColors/AppTheme)
- [ ] Zero linter errors
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Status tracker updated (if completing work others depend on)
- [ ] No merge conflicts with main

---

## 🔄 **Integration Workflow**

### **When Agents Need to Integrate:**

1. **Agent 1 completes Section 2 (Payment Models):**
   ```bash
   # Commit and push
   git add lib/core/models/payment*.dart
   git commit -m "[AGENT-1] Phase 1 Section 2 - Payment Models Complete"
   git push origin agent-1-payment-backend
   
   # Update status tracker
   # Merge to main (or create PR)
   ```

2. **Agent 2 needs Payment Models:**
   ```bash
   # Pull latest main (has Agent 1's models)
   git checkout main
   git pull origin main
   
   # Merge into your branch
   git checkout agent-2-event-ui
   git merge main
   
   # Now you can use Payment models
   ```

---

## 🚨 **Critical Rules**

1. **Never force push** - Always pull first
2. **Always test after merge** - Don't assume it works
3. **Coordinate shared files** - Check before modifying
4. **Update status tracker** - When completing work others depend on
5. **Regular commits** - Don't wait until end of phase

---

**Last Updated:** November 22, 2025, 8:40 PM CST  
**Status:** Ready for Use

