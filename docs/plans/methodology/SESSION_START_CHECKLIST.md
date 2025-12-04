# 🚀 Session Start Checklist

> **⚠️ MANDATORY: Review this at the START of EVERY new chat/task**

---

## 🔍 Task Type Detection

**Determine task type first:**

### Implementation Task
User says: "implement", "create", "build", "add", "start"
→ Follow 7-step protocol below

### Status/Progress Query
User says: "where are we", "what's the status", "how far along", "what's complete"
→ **CRITICAL:** Read ALL related documents (not just one!)

**Status Query Protocol:**
```bash
# Find ALL documents about topic
glob_file_search('**/*[topic]*.md')
glob_file_search('**/*[topic]*complete*.md')
glob_file_search('**/*[topic]*progress*.md')

# Read ALL found documents, then synthesize answer
# Never answer from just one document!
```

See full protocol in: `START_HERE_NEW_TASK.md`

---

## Quick Reference Card

**Time Investment:** ~40 minutes  
**Time Saved:** Hours to days (50-90% reduction)  
**Full Methodology:** `docs/DEVELOPMENT_METHODOLOGY.md`

---

## The 7-Step Session Start Protocol

### ☑️ Step 1: Methodology Review (2 min)
```
✅ I have reviewed DEVELOPMENT_METHODOLOGY.md
✅ I understand systematic approach
✅ I will follow quality standards
```

### ☑️ Step 2: Understand Task (5 min)
- [ ] Read user request completely
- [ ] Identify primary goal  
- [ ] Note specific requirements
- [ ] Check if relates to existing plan

### ☑️ Step 3: Cross-Reference Plans (10-15 min) 🔍 **CRITICAL**

**A. Discover ALL Plans**
```bash
# Cast wide net - find EVERYTHING with "plan" in name
glob_file_search('**/*plan*.md')
glob_file_search('**/*PLAN*.md')
glob_file_search('**/*roadmap*.md')
glob_file_search('**/*strategy*.md')
glob_file_search('**/*transition*.md')
```

**B. Check Recency (How old are these plans?)**
```bash
# List by modification date
run_terminal_cmd('ls -lht docs/*plan*.md | head -20')

# Find recent plans (<7 days)
run_terminal_cmd('find docs -name "*plan*.md" -mtime -7')

# Categorize by age
Recent (<7 days)    → HIGH PRIORITY
Moderate (7-30 days) → MEDIUM PRIORITY  
Old (30-90 days)     → LOW PRIORITY
Historical (>90 days) → REFERENCE ONLY
```

**C. Check Relevance (Does plan relate to task?)**
```bash
# Search plan contents for task keywords
grep('task_keyword', path: 'docs/', output_mode: 'files_with_matches')
grep('related_concept', path: 'docs/')
grep('Phase X\.Y', path: 'docs/')

# Semantic search for complex topics
codebase_search('What plans discuss [topic]?', target_directories: ['docs/'])
```

**D. Apply Decision Matrix**
```
Recent + High Relevance     → READ THOROUGHLY (5 min each)
Recent + Medium Relevance   → SKIM (2 min each)
Old + High Relevance        → SKIM for context (2 min each)
Old + Low Relevance         → SKIP (unless referenced)
```

**E. Check for Conflicts**
```
Watch for:
⚠️ Same feature, different specs in multiple plans
⚠️ Contradictory requirements
⚠️ Timeline conflicts
⚠️ Different placement (Settings vs Profile)
⚠️ Priority mismatches
```

**F. Also Check:**
```bash
# Completion documents
glob_file_search('**/*COMPLETE*.md')

# Progress documents
glob_file_search('**/*PROGRESS*.md')
```

**F. Mock Data Replacement (When Service Available):**
If you encounter `// Mock data` or `// TODO: Load` comments:
- [ ] Identify mock data locations (`grep -r "// Mock data" lib/presentation/`)
- [ ] Verify service exists and is registered
- [ ] Follow protocol: `docs/plans/methodology/MOCK_DATA_REPLACEMENT_PROTOCOL.md`
- [ ] See quick reference in `DEVELOPMENT_METHODOLOGY.md` → Section 2.5

**Questions to answer:**
- Where does this fit in the overall plan?
- Which is the PRIMARY plan (most recent + relevant)?
- What phase/section is it part of?
- What's already complete in related areas?
- What patterns have been established?
- Are there any conflicts between plans?
- Is any plan deprecated/superseded?
- What are the dependencies?

### ☑️ Step 4: Search Existing Work (5 min)
```bash
# By feature name
glob_file_search('**/*feature_name*.dart')

# By concept
grep('class.*FeatureName')
codebase_search('How does similar feature work?')

# Check specific areas
list_dir('lib/presentation/widgets/settings/')
```

**What to find:**
- ✅ Complete implementations (integrate, don't rebuild)
- ⚠️ Partial implementations (complete them)
- ✅ Similar patterns (copy and adapt)
- ❌ Nothing (build from scratch)

### ☑️ Step 5: Assess Optimal Placement (5 min)
**Placement Decision Tree:**

```
UI Component (Widget):
├─ Shared? → lib/presentation/widgets/common/
└─ Feature-specific? → lib/presentation/widgets/[feature]/

Full Screen (Page):
└─ lib/presentation/pages/[feature_area]/

Service (Business Logic):
├─ Core → lib/core/services/
└─ Feature → lib/core/[feature]/

Model (Data):
├─ Core → lib/core/models/
└─ Feature → lib/core/[feature]/models/

Test:
└─ Mirror source structure in test/
```

### ☑️ Step 6: Create Implementation Plan (10 min)
```dart
todo_write(
  merge: false,
  todos: [
    {"id": "1", "status": "in_progress", "content": "Context gathering"},
    {"id": "2", "status": "pending", "content": "Component A"},
    {"id": "3", "status": "pending", "content": "Integration"},
    {"id": "4", "status": "pending", "content": "Testing"},
    {"id": "5", "status": "pending", "content": "Documentation"},
  ]
)
```

**Plan should include:**
- Specific, actionable tasks
- Logical order (dependencies first)
- Clear completion criteria
- Realistic timeline

### ☑️ Step 7: Communicate Plan (2 min)
**Template:**
```
📋 Task Analysis Complete

Context:
- Main Plan: [file] Phase [X.Y]
- Existing Work: [X/Y components found]
- Approach: [High-level strategy]

Implementation Plan:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Timeline:
- Estimated: [X hours/days]
- Original plan: [Y days]
- Time saved: [Z%]

Ready to proceed?
```

---

## Context Gathering Quick Reference

### Must Check (Every Time):

1. **ALL Plans (Intelligent Filtering)**
   ```bash
   # Discover all
   glob_file_search('**/*plan*.md')
   
   # Check recency
   ls -lht docs/*plan*.md
   
   # Check relevance
   grep('task_keyword', path: 'docs/')
   
   # Apply decision matrix: Recent + Relevant = READ
   ```

2. **Master Plan (Always Read)**
   - `docs/FEATURE_MATRIX_COMPLETION_PLAN.md`
   - Phase/section, status, dependencies

3. **Completion Documents**
   - `glob_file_search('**/*COMPLETE*.md')`
   - Patterns, lessons, what works

4. **Progress Documents**
   - `glob_file_search('**/*PROGRESS*.md')`
   - Current status, blockers

5. **Existing Code**
   - `glob_file_search('**/*feature*.dart')`
   - What exists, what's missing

6. **Backend Models**
   - `lib/core/**/*.dart`
   - Data structures, services available

7. **Integration Points**
   - `lib/presentation/routes/app_router.dart`
   - Where/how users access features

### Smart Filtering Criteria

**Recency:**
- <7 days = Current work (high priority)
- 7-30 days = Recent work (medium priority)
- 30-90 days = Older work (context only)
- >90 days = Historical (reference only)

**Relevance:**
- Exact keyword match = High
- Related concepts = Medium
- Different domain = Low/Skip

**Decision Matrix:**
```
           Recent    Moderate   Old
High       READ      READ       SKIM
Medium     SKIM      SKIM       SKIP
Low        SKIM      SKIP       SKIP
```

---

## Red Flags (Stop and Clarify)

🚨 **STOP if you encounter:**

- [ ] Can't find main plan document
- [ ] Task conflicts with existing plan
- [ ] Unclear where code should go
- [ ] Don't understand data models
- [ ] Can't determine dependencies

**Action:** Ask for clarification before proceeding

---

## Success Indicators

✅ **You're ready to proceed when:**

- [ ] You understand the task completely
- [ ] You've found and read relevant plans
- [ ] You've searched for existing work
- [ ] You know optimal code placement
- [ ] You have a detailed TODO list
- [ ] You've communicated your plan

---

## Common Discoveries (Real Examples)

### Discovery 1: Work Already Complete
```
Task: "Implement Phase 2.1 (11 days estimated)"
Found: All 4 widgets already exist
Result: Changed to integration task (1 hour)
Saved: 99% of estimated time
```

### Discovery 2: Partial Implementation
```
Task: "Add SSE streaming"
Found: Simulated streaming exists
Result: Enhance existing, don't rebuild
Saved: 50% of estimated time
```

### Discovery 3: Related Patterns
```
Task: "Create new settings widget"
Found: 8 existing settings widgets with pattern
Result: Follow established pattern
Saved: Design time + consistency issues
```

---

## Time Investment vs. ROI

| Activity | Time | Potential Savings |
|----------|------|-------------------|
| Skip context gathering | 0 min | **-50 to -500% efficiency** |
| Minimal context | 10 min | Save 20-40% time |
| Proper context gathering | 40 min | **Save 50-90% time** |
| Thorough context + planning | 60 min | **Save 80-99% time** |

**Real Data from SPOTS:**
- Phase 1 Integration: 40 min context → Saved 5 days (99% savings)
- Optional Enhancements: 30 min context → Saved 3 days (85% savings)
- Phase 2.1: 20 min context → Saved 11 days (99.5% savings)

---

## Remember

### The Golden Rule
**"40 minutes of context gathering saves 40 hours of implementation"**

### The Quality Standard
- Zero linter errors
- Zero compilation errors
- Full integration
- Complete documentation
- Production ready

### The Completion Criteria
Not done until:
- ✅ Code works
- ✅ Code is tested
- ✅ Code is integrated
- ✅ Users can access it
- ✅ It's documented

---

## Quick Links

- **Full Methodology:** `docs/DEVELOPMENT_METHODOLOGY.md`
- **Feature Matrix:** `docs/FEATURE_MATRIX_COMPLETION_PLAN.md`
- **Completion Docs:** `docs/*COMPLETE*.md`
- **Project Philosophy:** `OUR_GUTS.md`

---

**Last Updated:** November 21, 2025  
**Version:** 1.1  
**Status:** Active - Reference at start of every session

