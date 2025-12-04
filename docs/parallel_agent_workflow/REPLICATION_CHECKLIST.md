# Replication Checklist - Parallel Agent Workflow

**Date:** November 25, 2025, 09:54 AM CST  
**Purpose:** Checklist for replicating this workflow in another project  
**Status:** ✅ Complete

---

## ✅ **Pre-Replication Checklist**

Before copying this folder to another project:

- [ ] Review all files in this folder
- [ ] Understand the workflow structure
- [ ] Identify customization points
- [ ] Plan your agent roles and tasks

---

## 📋 **Replication Steps**

### **Step 1: Copy Folder**
- [ ] Copy entire `parallel_agent_workflow/` folder to target project
- [ ] Verify all subfolders copied: `protocols/`, `guides/`, `prompts/`, `templates/`, `reference/`
- [ ] Verify all files copied: `README.md`, `SETUP_GUIDE.md`, `CURSOR_RULES.md`

### **Step 2: Customize Status Tracker**
- [ ] Copy `templates/status_tracker_template.md` to your status tracker location
- [ ] Replace `[ROLE NAME]` placeholders with your agent roles
- [ ] Replace `[TASK NAME]` placeholders with your tasks
- [ ] Replace `[DEPENDENCY NAME]` placeholders with your dependencies
- [ ] Update coordination points for your workflow
- [ ] Save customized status tracker

### **Step 3: Customize File Ownership**
- [ ] Edit `protocols/file_ownership.md`
- [ ] Update file paths to match your project structure
- [ ] Define which files each agent owns
- [ ] Identify shared files
- [ ] Add project-specific ownership rules
- [ ] Save file

### **Step 4: Customize Agent Prompts**
- [ ] Edit `prompts/agent_prompts_template.md`
- [ ] Replace `[ROLE NAME]` with your agent roles
- [ ] Replace `[PRIMARY FOCUS]` with focus areas
- [ ] Replace `[PATH_TO_TASK_ASSIGNMENTS]` with your task file path
- [ ] Replace `[PATH_TO_STATUS_TRACKER]` with your status tracker path
- [ ] Replace `[TASK NAME]` with your specific tasks
- [ ] Add project-specific rules
- [ ] Save file

### **Step 5: Create Task Assignments**
- [ ] Create task assignments file
- [ ] Define tasks for Agent 1
- [ ] Define tasks for Agent 2
- [ ] Define tasks for Agent 3
- [ ] Identify dependencies between tasks
- [ ] Save file

### **Step 6: Update Git Workflow (If Needed)**
- [ ] Review `protocols/git_workflow.md`
- [ ] Update branch names if different
- [ ] Update main branch name if different
- [ ] Add project-specific git rules if needed
- [ ] Save file

### **Step 7: Update Integration Protocol (If Needed)**
- [ ] Review `protocols/integration_protocol.md`
- [ ] Update integration points for your project
- [ ] Add project-specific integration examples
- [ ] Update API documentation requirements if needed
- [ ] Save file

### **Step 8: Add Cursor Rules (Optional)**
- [ ] Read `CURSOR_RULES.md`
- [ ] Identify applicable rules for your project
- [ ] Add to your `.cursorrules` file
- [ ] Customize project-specific rules
- [ ] Test with one agent first

### **Step 9: Initialize Git (If Not Already Done)**
- [ ] Verify git repository exists
- [ ] Create main branch if needed
- [ ] Make initial commit if needed

### **Step 10: Test Setup**
- [ ] Test with one agent first
- [ ] Verify agent reads all required documents
- [ ] Verify agent creates git branch correctly
- [ ] Verify agent checks status tracker
- [ ] Verify agent starts work correctly
- [ ] Fix any issues found
- [ ] Retest if needed

---

## ✅ **Post-Replication Checklist**

After replication is complete:

- [ ] All files customized for your project
- [ ] Status tracker created and accessible
- [ ] File ownership matrix matches your project
- [ ] Agent prompts ready to use
- [ ] Task assignments created
- [ ] Git workflow configured
- [ ] Integration protocol updated
- [ ] Cursor rules added (if applicable)
- [ ] Tested with one agent
- [ ] Ready to start parallel agents

---

## 🚀 **Ready to Start**

Once all checklist items are complete:

1. **Open 3 Cursor windows/tabs**
2. **Copy agent prompts** from your customized prompts file
3. **Paste each prompt** into a separate window
4. **Send prompts** to start agents
5. **Monitor progress** via status tracker

---

## 📞 **Support Documents**

If you need help:

- **Setup:** See `SETUP_GUIDE.md`
- **Overview:** See `README.md`
- **Quick Reference:** See `reference/quick_reference.md`
- **Starting Agents:** See `guides/parallel_start_guide.md`
- **Complete Workflow:** See `guides/parallel_work_guide.md`
- **Troubleshooting:** See `guides/risks_and_mitigation.md`

---

**Last Updated:** November 25, 2025, 09:54 AM CST  
**Status:** Complete - Ready for Replication

