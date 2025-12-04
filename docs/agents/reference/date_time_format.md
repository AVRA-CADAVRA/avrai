# Agent Date & Time Format Requirements

**Date:** November 22, 2025, 8:47 PM CST  
**Purpose:** Standardize date/time format for all documents created by agents  
**Status:** 🟢 Mandatory

---

## 🚨 **CRITICAL: All Documents Must Include Date & Time**

**Every document created by an agent MUST include:**
- Date in the header
- Time in the header
- Format: `November 22, 2025, 8:47 PM CST`

---

## 📋 **Required Format**

### **Standard Format:**
```
**Date:** [Month] [Day], [Year], [Hour]:[Minute] [AM/PM] [TimeZone]
```

### **Example:**
```
**Date:** November 22, 2025, 8:47 PM CST
```

### **How to Get Current Date/Time:**
```bash
date "+%B %d, %Y, %I:%M %p %Z"
```

**Output:** `November 22, 2025, 08:47 PM CST`

---

## ✅ **Where to Include Date/Time**

### **1. Document Headers**
Every document must start with:
```markdown
# Document Title

**Date:** November 22, 2025, 8:47 PM CST
**Purpose:** [Brief description]
**Status:** [Status]
```

### **2. Reports**
All reports must include:
```markdown
**Date:** November 22, 2025, 8:47 PM CST
**Last Updated:** November 22, 2025, 8:47 PM CST
```

### **3. Status Updates**
When updating status tracker:
```markdown
**Last Updated:** November 22, 2025, 8:47 PM CST
```

---

## 🔧 **Implementation**

### **Before Creating Any Document:**

1. **Get current date/time:**
   ```bash
   date "+%B %d, %Y, %I:%M %p %Z"
   ```

2. **Use in document header:**
   ```markdown
   **Date:** [paste output here]
   ```

3. **For updates, also include:**
   ```markdown
   **Last Updated:** [paste output here]
   ```

---

## 📝 **Examples**

### **Example 1: New Document**
```markdown
# Payment Service Implementation

**Date:** November 22, 2025, 8:47 PM CST
**Purpose:** Payment service implementation details
**Status:** 🟢 Complete
```

### **Example 2: Status Update**
```markdown
### **Agent 1: Payment Processing & Revenue**
**Current Phase:** Phase 1
**Current Section:** Section 2 - Payment Models
**Status:** 🟢 Complete
**Last Updated:** November 22, 2025, 8:47 PM CST
```

### **Example 3: Progress Report**
```markdown
# Phase 1 Section 2 Progress Report

**Date:** November 22, 2025, 8:47 PM CST
**Agent:** Agent 1
**Status:** Complete
```

---

## ⚠️ **Common Mistakes to Avoid**

### **❌ Wrong:**
- `Date: November 22, 2025` (missing time)
- `Date: 11/22/2025` (wrong format)
- `Date: Nov 22, 2025` (abbreviated month)
- `Date: November 22, 2025 at 8:47 PM` (missing timezone)

### **✅ Correct:**
- `Date: November 22, 2025, 8:47 PM CST`

---

## 🎯 **Checklist**

Before submitting any document:
- [ ] Date included in header
- [ ] Time included in header
- [ ] Timezone included (CST, EST, etc.)
- [ ] Format matches: `November 22, 2025, 8:47 PM CST`
- [ ] Used `date` command to get current time
- [ ] Updated "Last Updated" if modifying existing doc

---

**Last Updated:** November 22, 2025, 8:47 PM CST  
**Status:** Mandatory for All Agents

