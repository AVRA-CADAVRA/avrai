# Trace Comparison Report: [Optimization Name]

**Date:** [YYYY-MM-DD]
**Baseline:** `traces/baseline/[baseline_filename].trace`
**Optimized:** `traces/optimizations/[optimized_filename].trace`
**Analyzed By:** [Name]

---

## Executive Summary

**Optimization:** [Brief description]

**Overall Impact:** ✅ Successful | ⚠️ Partial | ❌ Failed

**Key Improvements:**
- [Improvement 1]: [X]% improvement
- [Improvement 2]: [X]% improvement
- [Improvement 3]: [X]% improvement

---

## Metric Comparison

| Metric | Baseline | Optimized | Change | Improvement |
|--------|----------|-----------|--------|-------------|
| **Startup Time (TTFF)** | [X]ms | [X]ms | [±X]ms | [X]% |
| **Context Switches** | [X] | [X] | [±X] | [X]% |
| **Peak Thread Count** | [X] | [X] | [±X] | [X]% |
| **Peak Memory** | [X]MB | [X]MB | [±X]MB | [X]% |
| **Main Thread CPU** | [X]% | [X]% | [±X]% | [X]% |

---

## Detailed Analysis

### Startup Performance

**Before:**
- TTFF: [X]ms
- Initialization: [X]ms
- UI Render: [X]ms

**After:**
- TTFF: [X]ms
- Initialization: [X]ms
- UI Render: [X]ms

**Analysis:**
[Detailed analysis of changes]

**Impact:**
[User-perceived impact]

---

### Threading Performance

**Before:**
- Context switches: [X]
- Peak threads: [X]
- Thread creation rate: [X]/second

**After:**
- Context switches: [X]
- Peak threads: [X]
- Thread creation rate: [X]/second

**Analysis:**
[Detailed analysis of changes]

**Impact:**
[Battery/performance impact]

---

### Memory Performance

**Before:**
- Peak memory: [X]MB
- Growth rate: [X]MB/second
- Allocation rate: [X]/second

**After:**
- Peak memory: [X]MB
- Growth rate: [X]MB/second
- Allocation rate: [X]/second

**Analysis:**
[Detailed analysis of changes]

**Impact:**
[Memory footprint impact]

---

## Hot Functions Comparison

### Top 5 Functions (Before)

1. `[FunctionName]`: [X]% of total time
2. `[FunctionName]`: [X]% of total time
3. `[FunctionName]`: [X]% of total time
4. `[FunctionName]`: [X]% of total time
5. `[FunctionName]`: [X]% of total time

### Top 5 Functions (After)

1. `[FunctionName]`: [X]% of total time
2. `[FunctionName]`: [X]% of total time
3. `[FunctionName]`: [X]% of total time
4. `[FunctionName]`: [X]% of total time
5. `[FunctionName]`: [X]% of total time

**Changes:**
- [Function that improved]: [X]% → [X]% ([±X]%)
- [Function that worsened]: [X]% → [X]% ([±X]%)

---

## Visualizations

### Timeline Comparison
[Describe timeline differences, or link to images]

### Thread Activity Comparison
[Describe thread activity differences]

---

## Regression Analysis

### Metrics That Worsened
- [Metric]: [X]% worse - [Explanation]

### Metrics That Improved
- [Metric]: [X]% better - [Explanation]

### Metrics That Stayed Same
- [Metric]: No significant change

---

## Recommendations

### ✅ Should Keep
- [Optimization that worked well]

### ⚠️ Needs Adjustment
- [Optimization that needs refinement]

### ❌ Should Revert
- [Optimization that caused issues]

---

## Next Steps

- [ ] [Action item 1]
- [ ] [Action item 2]
- [ ] [Action item 3]

---

## Related

- **Optimization PR:** [Link]
- **Issue:** [Link]
- **Trace Index:** [Link to TRACE_INDEX.md]

---

## Notes

[Additional observations or context]
