# Cursor Rules Setup & Consistency Guide

**Purpose:** Ensure cursor rules are followed consistently across all machines and sessions

---

## ✅ Current Status

Your cursor rules files are:
- ✅ **Tracked in Git:** All `.cursorrules*` files are committed
- ✅ **In Repository Root:** Properly located for Cursor to auto-detect
- ✅ **Committed to GitHub:** Will sync across all machines

**Files:**
- `.cursorrules` - Main development protocol
- `.cursorrules_master_plan` - Master plan system rules
- `.cursorrules_plan_tracker` - Plan tracker rules

---

## 🔧 How Cursor Rules Work

### Automatic Detection

Cursor automatically detects and applies `.cursorrules` files when:
1. **File is in project root** (✅ yours are)
2. **File starts with `.cursorrules`** (✅ yours do)
3. **File is readable** (✅ they are)

### Multiple Rules Files

Cursor will read **ALL** `.cursorrules*` files in the root directory:
- `.cursorrules` - Main rules
- `.cursorrules_master_plan` - Additional rules
- `.cursorrules_plan_tracker` - Additional rules

**All files are combined** - Cursor reads them all together.

---

## 🚀 Ensuring Consistency

### 1. **Keep Rules in Git** ✅ (Already Done)

Your rules are committed, so they'll sync automatically:

```bash
# On any machine, after cloning:
git clone https://github.com/reis-ship-it/SPOTS.git
cd SPOTS
# Rules are automatically available!
```

### 2. **Verify Rules Are Active**

**Check if Cursor sees your rules:**
- Open Cursor
- Start a new chat
- Ask: "What are the cursor rules for this project?"
- The AI should reference your `.cursorrules` content

**Or test with a trigger:**
- Say: "I want to implement a new feature"
- The AI should follow the protocol from `.cursorrules` (read START_HERE_NEW_TASK.md, etc.)

### 3. **Force Refresh Rules** (If Needed)

If rules aren't being picked up:

1. **Restart Cursor:**
   - Close Cursor completely
   - Reopen the project
   - Rules should reload

2. **Check File Location:**
   ```bash
   # Rules must be in project root
   ls -la .cursorrules*
   ```

3. **Verify File Format:**
   - Files should be plain text (not binary)
   - No special encoding required
   - Markdown format is fine

### 4. **Explicitly Reference Rules** (Optional)

In your prompts, you can explicitly reference rules:

```
"Follow the cursor rules in .cursorrules"
"Read .cursorrules before starting"
"Check .cursorrules_master_plan for master plan workflow"
```

---

## 📋 Best Practices

### ✅ DO:

1. **Keep rules in git** - So they sync across machines
2. **Update rules in git** - Commit changes so they propagate
3. **Test rules work** - Verify AI follows them
4. **Document rule changes** - Note why rules changed
5. **Keep rules organized** - Use multiple files for clarity

### ❌ DON'T:

1. **Don't ignore rules in .gitignore** - They need to be in git
2. **Don't put rules in subdirectories** - Must be in root
3. **Don't rename files** - Cursor looks for `.cursorrules*`
4. **Don't use binary formats** - Plain text only

---

## 🔍 Troubleshooting

### Rules Not Being Followed?

1. **Check file location:**
   ```bash
   pwd  # Should be project root
   ls .cursorrules*  # Should show your files
   ```

2. **Check file is readable:**
   ```bash
   cat .cursorrules | head -20  # Should show content
   ```

3. **Check git status:**
   ```bash
   git status .cursorrules*  # Should show "nothing to commit"
   ```

4. **Restart Cursor:**
   - Close completely
   - Reopen project
   - Start new chat

### Rules Not Syncing?

1. **Verify they're committed:**
   ```bash
   git log --oneline .cursorrules
   ```

2. **Push to GitHub:**
   ```bash
   git push origin main
   ```

3. **Pull on other machine:**
   ```bash
   git pull origin main
   ```

---

## 📝 Adding New Rules

### When to Add Rules:

- New development patterns
- New mandatory protocols
- Project-specific standards
- Team conventions

### How to Add:

1. **Edit existing file** (if related):
   ```bash
   # Edit main rules
   code .cursorrules
   ```

2. **Or create new file** (if separate concern):
   ```bash
   # Create new rules file
   touch .cursorrules_[topic]
   ```

3. **Commit changes:**
   ```bash
   git add .cursorrules*
   git commit -m "docs: Update cursor rules for [topic]"
   git push origin main
   ```

---

## 🎯 Verification Checklist

Use this checklist to verify rules are working:

- [ ] Rules files exist in project root
- [ ] Rules files are tracked in git
- [ ] Rules files are committed and pushed
- [ ] Cursor can see rules (test with trigger phrase)
- [ ] AI follows protocol (test with "implement feature")
- [ ] Rules sync across machines (test on laptop)

---

## 🔗 Related Documentation

- **Main Rules:** `.cursorrules`
- **Master Plan Rules:** `.cursorrules_master_plan`
- **Plan Tracker Rules:** `.cursorrules_plan_tracker`
- **Parallel Agent Rules:** `docs/parallel_agent_workflow/CURSOR_RULES.md`

---

## 💡 Pro Tips

1. **Version Control Rules:**
   - Commit rule changes with descriptive messages
   - Review rule changes in PRs
   - Document why rules changed

2. **Test Rules Regularly:**
   - Start new chats to verify rules load
   - Test trigger phrases
   - Verify AI follows protocols

3. **Keep Rules Organized:**
   - Use multiple files for different concerns
   - Keep main rules in `.cursorrules`
   - Use `.cursorrules_[topic]` for specific areas

4. **Document Rule Purpose:**
   - Add comments explaining why rules exist
   - Reference related documentation
   - Link to examples

---

**Last Updated:** December 2025  
**Status:** ✅ Rules are properly configured and tracked in git

