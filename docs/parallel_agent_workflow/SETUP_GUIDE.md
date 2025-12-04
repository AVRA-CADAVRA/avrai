# Setup Guide - Parallel Agent Workflow

**Date:** November 25, 2025, 09:54 AM CST  
**Purpose:** Step-by-step setup instructions for replicating this workflow  
**Status:** ✅ Complete

---

## 🎯 **Overview**

This guide walks you through setting up the parallel agent workflow in your project. Follow these steps in order.

---

## 📋 **Step 1: Copy the Workflow Folder**

### **Option A: Copy Entire Folder**
```bash
# From your project root
cp -r [SOURCE]/docs/parallel_agent_workflow docs/parallel_agent_workflow
```

### **Option B: Manual Copy**
1. Create folder: `docs/parallel_agent_workflow/`
2. Copy all subfolders: `protocols/`, `guides/`, `prompts/`, `templates/`, `reference/`
3. Copy all files: `README.md`, `CURSOR_RULES.md`, `SETUP_GUIDE.md`

---

## 📋 **Step 2: Customize Status Tracker**

1. **Copy the template:**
   ```bash
   cp docs/parallel_agent_workflow/templates/status_tracker_template.md docs/status_tracker.md
   ```

2. **Edit `docs/status_tracker.md`:**
   - Replace `[ROLE NAME]` with your agent roles
   - Replace `[TASK NAME]` with your specific tasks
   - Replace `[DEPENDENCY NAME]` with your dependencies
   - Update coordination points for your workflow

3. **Save the file** - This will be your central status tracker

---

## 📋 **Step 3: Customize File Ownership**

1. **Edit `docs/parallel_agent_workflow/protocols/file_ownership.md`:**
   - Update file paths to match your project structure
   - Define which files each agent owns
   - Identify shared files that need coordination
   - Add project-specific ownership rules

2. **Save the file**

---

## 📋 **Step 4: Customize Agent Prompts**

1. **Edit `docs/parallel_agent_workflow/prompts/agent_prompts_template.md`:**
   - Replace `[ROLE NAME]` with your agent roles
   - Replace `[PRIMARY FOCUS]` with focus areas
   - Replace `[PATH_TO_TASK_ASSIGNMENTS]` with your task file path
   - Replace `[PATH_TO_STATUS_TRACKER]` with your status tracker path
   - Replace `[TASK NAME]` with your specific tasks
   - Add project-specific rules (design tokens, code standards, etc.)

2. **Save the file** - This will be your agent prompts

---

## 📋 **Step 5: Update Git Workflow (If Needed)**

1. **Edit `docs/parallel_agent_workflow/protocols/git_workflow.md`:**
   - Update branch names if different from `agent-1-[role]`
   - Update main branch name if different from `main`
   - Add project-specific git rules if needed

2. **Save the file**

---

## 📋 **Step 6: Update Integration Protocol (If Needed)**

1. **Edit `docs/parallel_agent_workflow/protocols/integration_protocol.md`:**
   - Update integration points for your project
   - Add project-specific integration examples
   - Update API documentation requirements if needed

2. **Save the file**

---

## 📋 **Step 7: Add Cursor Rules (Optional)**

1. **Read `docs/parallel_agent_workflow/CURSOR_RULES.md`**
2. **Identify applicable rules** for your project
3. **Add to your `.cursorrules` file:**
   - Copy relevant sections
   - Customize project-specific rules
   - Test with one agent first

---

## 📋 **Step 8: Create Task Assignments**

1. **Create your task assignments file:**
   ```bash
   # Example location
   docs/tasks/agent_task_assignments.md
   ```

2. **Structure it like this:**
   ```markdown
   # Agent Task Assignments
   
   ## AGENT 1: [ROLE NAME]
   - Section 1: [TASK]
   - Section 2: [TASK]
   ...
   
   ## AGENT 2: [ROLE NAME]
   - Section 1: [TASK]
   - Section 2: [TASK]
   ...
   
   ## AGENT 3: [ROLE NAME]
   - Section 1: [TASK]
   - Section 2: [TASK]
   ...
   ```

3. **Update agent prompts** to reference this file

---

## 📋 **Step 9: Initialize Git (If Not Already Done)**

```bash
# If git not initialized
git init

# Create main branch
git checkout -b main

# Make initial commit
git add .
git commit -m "Initial commit - Parallel agent workflow setup"
```

---

## 📋 **Step 10: Test Setup**

### **Test with One Agent First:**

1. **Open one Cursor window**
2. **Copy Agent 1 prompt** from your customized prompts file
3. **Paste and send** to the agent
4. **Verify:**
   - Agent reads all required documents
   - Agent creates git branch correctly
   - Agent checks status tracker
   - Agent starts work correctly

### **If Test Passes:**
- Proceed with all 3 agents
- Follow `docs/parallel_agent_workflow/guides/parallel_start_guide.md`

### **If Test Fails:**
- Check error messages
- Verify all paths are correct
- Verify all files exist
- Fix issues and retest

---

## ✅ **Setup Checklist**

Before starting parallel agents:

- [ ] Workflow folder copied to project
- [ ] Status tracker created and customized
- [ ] File ownership matrix customized
- [ ] Agent prompts customized
- [ ] Git workflow updated (if needed)
- [ ] Integration protocol updated (if needed)
- [ ] Task assignments created
- [ ] Git repository initialized
- [ ] Cursor rules added (optional)
- [ ] Tested with one agent

---

## 🚀 **Ready to Start**

Once all checklist items are complete:

1. **Open 3 Cursor windows/tabs**
2. **Copy agent prompts** from your customized prompts file
3. **Paste each prompt** into a separate window
4. **Send prompts** to start agents
5. **Monitor progress** via status tracker

---

## 🔧 **Troubleshooting**

### **Issue: Agent Can't Find Files**
**Solution:**
- Verify all paths in prompts are correct
- Check file locations match your project structure
- Use absolute paths if relative paths don't work

### **Issue: Git Branch Creation Fails**
**Solution:**
- Verify git is initialized
- Check branch naming conventions
- Ensure you're not already on that branch

### **Issue: Status Tracker Not Found**
**Solution:**
- Verify status tracker path in prompts
- Check file exists at specified path
- Verify file permissions

### **Issue: File Ownership Conflicts**
**Solution:**
- Review file ownership matrix
- Verify all files are assigned to agents
- Check for shared files that need coordination

---

## 📞 **Next Steps**

After setup is complete:

1. **Read** `docs/parallel_agent_workflow/README.md` for overview
2. **Read** `docs/parallel_agent_workflow/guides/parallel_start_guide.md` for starting agents
3. **Read** `docs/parallel_agent_workflow/guides/parallel_work_guide.md` for complete workflow
4. **Start** your first parallel agent session!

---

**Last Updated:** November 25, 2025, 09:54 AM CST  
**Status:** Complete - Ready for Use

