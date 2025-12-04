# Phase.Section.Subsection Format - Mandatory Standard

**Created:** November 28, 2025  
**Status:** 🎯 **MANDATORY FORMAT - ENFORCED BY CURSOR RULES**  
**Purpose:** Uniform metric system for all Master Plan work references

---

## 🚨 **MANDATORY FORMAT RULE**

**ALL work references MUST use Phase.Section.Subsection (X.Y.Z) format.**

**This is NON-NEGOTIABLE and enforced by cursor rules.**

---

## 📐 **Format Specification**

### **Structure:**
- **Phase X** - Major feature or milestone (e.g., Phase 1: MVP Core Functionality)
- **Section Y** - Work unit within a phase (e.g., Section 1: Payment Processing Foundation)
- **Subsection Z** - Specific task within a section (e.g., Subsection 1: Stripe Integration)

### **Shorthand Notation:**
- **Full format:** `Phase X, Section Y, Subsection Z`
- **Shorthand:** `X.Y.Z` (e.g., `1.1.1` = Phase 1, Section 1, Subsection 1)
- **Section only:** `X.Y` (e.g., `1.1` = Phase 1, Section 1)
- **Phase only:** `X` (e.g., `1` = Phase 1)

### **Examples:**
- `1.1` = Phase 1, Section 1 (Payment Processing Foundation)
- `1.2.5` = Phase 1, Section 2, Subsection 5 (My Events Page)
- `7.2.3` = Phase 7, Section 2, Subsection 3 (AI2AI Learning Methods UI)

---

## ❌ **FORBIDDEN TERMINOLOGY**

**NEVER use:**
- ❌ "Week" or "week" - Use "Section" instead
- ❌ "Day" or "day" - Use "Subsection" instead
- ❌ "Week X" - Use "Section X (Y.Z)" instead
- ❌ "Day Y" - Use "Subsection Y (X.Y.Z)" instead

**Examples of FORBIDDEN formats:**
- ❌ "Week 33" → ✅ "Section 33 (7.1.1)"
- ❌ "Day 5" → ✅ "Subsection 5 (1.2.5)"
- ❌ "Phase 7 Week 38" → ✅ "Phase 7 Section 38 (7.2.3)"

---

## ✅ **REQUIRED USAGE**

**This format MUST be used in:**
1. ✅ Master Plan (`docs/MASTER_PLAN.md`)
2. ✅ Status Tracker (`docs/agents/status/status_tracker.md`)
3. ✅ Task Assignments (`docs/agents/tasks/**/*.md`)
4. ✅ Agent Prompts (`docs/agents/prompts/**/*.md`)
5. ✅ Completion Reports (`docs/agents/reports/**/*.md`)
6. ✅ All documentation files
7. ✅ All planning documents
8. ✅ All references to work items

---

## 📋 **Format Examples**

### **In Master Plan:**
```markdown
#### **Section 33 (7.1.1): Action Execution UI & Integration**
```

### **In Status Tracker:**
```markdown
**Current Section:** Section 38 (7.2.3) - AI2AI Learning Methods UI
- Section 38 (7.2.3) - AI2AI Learning Methods UI Integration ✅ COMPLETE
```

### **In Task Assignments:**
```markdown
**Phase 7 Section 38 (7.2.3): AI2AI Learning Methods UI**
```

### **In Completion Reports:**
```markdown
**Section 38 (7.2.3) Completion Report**
```

---

## 🔍 **Verification Checklist**

Before submitting any work, verify:
- [ ] All "Week" references replaced with "Section"
- [ ] All "Day" references replaced with "Subsection"
- [ ] Shorthand notation (X.Y.Z) included in headers
- [ ] Format consistent throughout document
- [ ] No mixed old/new formats

---

## 📚 **Reference Documents**

- **Master Plan:** `docs/MASTER_PLAN.md` (Notation System section)
- **Cursor Rules:** `.cursorrules` (Master Plan Notation section)
- **This Document:** `docs/plans/methodology/PHASE_SECTION_SUBSECTION_FORMAT.md`

---

**Last Updated:** November 28, 2025  
**Status:** 🎯 **MANDATORY - ENFORCED**

