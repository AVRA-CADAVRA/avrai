# Phase 7 Section 51-52 (7.6.1-2): Remaining Fixes - Agent Prompts

**Date:** December 2, 2025, 4:12 PM CST  
**Phase:** Phase 7 - Feature Matrix Completion  
**Section:** Section 51-52 (7.6.1-2) - Comprehensive Testing & Production Readiness (Remaining Fixes)  
**Status:** 🎯 **READY TO START**  
**Priority:** 🔴 CRITICAL

---

## 🎯 **Overview**

This document contains ready-to-use prompts for agents working on the remaining fixes for Section 51-52. The analysis phase is complete, and agents should now focus on implementing the fixes identified in the completion status report.

**Reference:** 
- Task Assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Completion Status: `docs/agents/reports/SECTION_51_52_COMPLETION_STATUS.md`

---

## 🤖 **Agent 2: Frontend & UX Specialist**

### **Prompt 1: Design Token Compliance (CRITICAL - Priority 1)**

```
You are Agent 2 (Frontend & UX Specialist) working on Phase 7, Section 51-52 remaining fixes.

**CRITICAL TASK: Design Token Compliance**

**Current Status:**
- 194 files using `Colors.*` directly instead of `AppColors.*` or `AppTheme.*`
- Target: 100% compliance (AppColors/AppTheme only)
- This is a CRITICAL requirement per project rules (100% adherence required)

**Your Task:**
1. Identify all files using `Colors.*` directly (exclude `Colors.transparent` which is acceptable)
2. Systematically replace all `Colors.*` usage with `AppColors.*` or `AppTheme.*`
3. Add proper imports: `import 'package:spots/core/theme/colors.dart';`
4. Fix edge cases manually
5. Verify 100% compliance

**Color Replacement Mapping:**
- `Colors.white` → `AppColors.white`
- `Colors.black` → `AppColors.black`
- `Colors.grey` / `Colors.gray` → `AppColors.grey500` (or appropriate shade)
- `Colors.red` → `AppColors.error`
- `Colors.green` → `AppColors.electricGreen`
- `Colors.blue` → `AppColors.electricGreen` (or appropriate)
- `Colors.orange` → `AppColors.warning`
- `Colors.purple` → `AppColors.grey600` (or appropriate)
- `Colors.grey[XXX]` → `AppColors.greyXXX`
- `Colors.grey.shadeXXX` → `AppColors.greyXXX`
- `Colors.transparent` → Keep as-is (acceptable)

**Deliverables:**
- All files fixed (194 files or actual count)
- 100% design token compliance achieved
- Verification report
- No linter errors related to color usage

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Design token compliance summary: `docs/agents/reports/agent_2/phase_7/design_token_compliance_fix_summary.md`
- UI production readiness: `docs/agents/reports/agent_2/phase_7/ui_production_readiness_checklist.md`

**Critical Rules:**
- ✅ ALWAYS use `AppColors.*` or `AppTheme.*`
- ❌ NEVER use direct `Colors.*` (except `Colors.transparent`)
- ✅ Verify all imports are present
- ✅ Fix any duplicate imports

Start by identifying all files with `Colors.*` usage, then systematically fix them.
```

### **Prompt 2: Widget Test Compilation Errors (Priority 2)**

```
You are Agent 2 (Frontend & UX Specialist) working on Phase 7, Section 51-52 remaining fixes.

**TASK: Fix Widget Test Compilation Errors**

**Current Status:**
- Fixed 28+ test files already
- Remaining compilation errors need fixing
- Compilation errors blocking accurate coverage measurement

**Your Task:**
1. Run widget tests to identify all remaining compilation errors
2. Fix import path issues
3. Fix missing imports (e.g., `CircularProgressIndicator`)
4. Fix any deprecated API usage
5. Verify all tests compile
6. Run all widget tests and fix any runtime errors

**Deliverables:**
- All widget tests compile successfully
- Compilation error fix report
- Test execution results

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Completion report: `docs/agents/reports/agent_2/phase_7/week_51_52_completion_report.md`

Start by running the widget tests and identifying all compilation errors, then fix them systematically.
```

### **Prompt 3: Missing Widget Tests (Priority 3)**

```
You are Agent 2 (Frontend & UX Specialist) working on Phase 7, Section 51-52 remaining fixes.

**TASK: Create Missing Widget Tests**

**Current Status:**
- Widget test coverage: ~60% (Target: 80%+)
- Missing tests for:
  - Brand widgets: 8 widgets (no tests)
  - Event widgets: 7 widgets (no tests)
  - Payment widget: 1 widget (CRITICAL, no tests)
  - Common widgets: 6 widgets (partial coverage)

**Your Task:**
1. Identify all 8 brand widgets and create test files
2. Identify all 7 event widgets and create test files
3. Identify payment widget and create comprehensive test file (CRITICAL)
4. Enhance tests for 6 common widgets with partial coverage
5. Test UI interactions, state management, error states, loading states

**Test Requirements:**
- Test UI interactions
- Test state management
- Test error states
- Test loading states
- Test user input handling
- Test responsive design

**Deliverables:**
- 16 new widget test files (8 Brand + 7 Event + 1 Payment)
- Enhanced tests for 6 common widgets
- All new tests passing
- Widget test coverage report (80%+ target)

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Widget test coverage analysis: `docs/agents/reports/agent_2/phase_7/widget_test_coverage_analysis.md`

Start by identifying all missing widgets, then create comprehensive test files for each.
```

### **Prompt 4: Accessibility Testing (Priority 4)**

```
You are Agent 2 (Frontend & UX Specialist) working on Phase 7, Section 51-52 remaining fixes.

**TASK: Comprehensive Accessibility Testing**

**Current Status:**
- Accessibility audit report complete
- Comprehensive testing needed
- Target: WCAG 2.1 AA compliance

**Your Task:**
1. **Screen Reader Testing:**
   - Test all major user flows with screen reader
   - Verify semantic labels are present
   - Verify focus indicators work

2. **Keyboard Navigation Testing:**
   - Test tab order is logical
   - Test all interactive elements are keyboard accessible
   - Test keyboard shortcuts

3. **Color Contrast Testing:**
   - Verify all text meets WCAG 2.1 AA contrast ratios (4.5:1 for normal text, 3:1 for large text)
   - Verify interactive elements meet contrast requirements

4. **Touch Target Size Testing:**
   - Verify all interactive elements are at least 44x44pt
   - Test on various screen sizes

5. **Fix All Accessibility Issues:**
   - Fix all identified issues
   - Verify fixes with testing
   - Create accessibility compliance report

**Deliverables:**
- Accessibility testing report
- Accessibility compliance report (WCAG 2.1 AA)
- All accessibility issues fixed
- Verification of fixes

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Accessibility audit report: `docs/agents/reports/agent_2/phase_7/accessibility_audit_report.md`

Start by testing each accessibility requirement systematically, document issues, then fix them.
```

### **Prompt 5: Final UI Polish (Priority 5)**

```
You are Agent 2 (Frontend & UX Specialist) working on Phase 7, Section 51-52 remaining fixes.

**TASK: Final UI Polish**

**Current Status:**
- UI production readiness: 71% (Target: 90%+)
- Design token compliance and accessibility fixes should be complete first

**Your Task:**
1. **Final UI Checks:**
   - Verify all UI components are consistent
   - Check for visual regressions
   - Verify animations are smooth
   - Check responsive design on all devices
   - Verify error messages are user-friendly
   - Verify loading states are clear

2. **Design Consistency:**
   - Verify all components use design tokens correctly
   - Verify spacing is consistent
   - Verify typography is consistent
   - Verify color usage is consistent

3. **Performance:**
   - Check UI performance
   - Verify no unnecessary rebuilds
   - Verify images are optimized

**Deliverables:**
- Final UI polish complete
- UI production readiness score 90%+
- Visual regression test results
- Performance report

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- UI production readiness checklist: `docs/agents/reports/agent_2/phase_7/ui_production_readiness_checklist.md`

Start by reviewing the production readiness checklist, then systematically address each item.
```

---

## 🤖 **Agent 3: Models & Testing Specialist**

### **Prompt 1: Test Pass Rate Improvement (Priority 1)**

```
You are Agent 3 (Models & Testing Specialist) working on Phase 7, Section 51-52 remaining fixes.

**TASK: Improve Test Pass Rate**

**Current Status:**
- Test pass rate: 82.2% (Target: 99%+)
- Total failures: 558 tests
  - Platform channel issues: 542 failures (97.1%)
  - Compilation errors: 7 failures (1.3%)
  - Test logic failures: 9 failures (1.6%)

**Your Task:**
1. **Analyze Test Failures:**
   - Review test failure report
   - Categorize failures by type
   - Identify root causes

2. **Fix Platform Channel Issues:**
   - Review platform channel test setup
   - Fix test environment configuration
   - Add proper mocking for platform channels
   - Update test helpers if needed

3. **Fix Compilation Errors:**
   - Fix remaining 7 compilation errors
   - Verify all tests compile

4. **Fix Test Logic Failures:**
   - Review 9 test logic failures
   - Fix test assertions
   - Fix test setup if needed

5. **Re-run Tests:**
   - Run full test suite
   - Verify pass rate meets target (99%+)
   - Document improvements

**Deliverables:**
- Test failure analysis report
- All platform channel issues fixed
- All compilation errors fixed
- All test logic failures fixed
- Test pass rate 99%+ achieved
- Updated test execution report

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Test execution report: `docs/agents/reports/agent_3/phase_7/week_51_52_test_execution_report.md`
- Test results analysis: `docs/agents/reports/agent_3/phase_7/week_51_52_test_results_analysis.md`

Start by analyzing the test failures, then systematically fix each category.
```

### **Prompt 2: Test Coverage Improvement (Priority 2)**

```
You are Agent 3 (Models & Testing Specialist) working on Phase 7, Section 51-52 remaining fixes.

**TASK: Improve Test Coverage**

**Current Status:**
- Test coverage: 52.95% (Target: 90%+)
- Coverage below target, need more tests

**Your Task:**
1. **Coverage Gap Analysis:**
   - Review coverage report
   - Identify files with low coverage
   - Prioritize critical paths
   - Create coverage gap report

2. **Create Additional Tests:**
   - Focus on critical paths first
   - Create unit tests for uncovered services
   - Create unit tests for uncovered models
   - Create unit tests for uncovered repositories
   - Create integration tests for uncovered flows
   - Verify all new tests pass

3. **Coverage Validation:**
   - Run test coverage analysis
   - Verify coverage meets target (90%+)
   - Document coverage improvements
   - Create final coverage report

**Deliverables:**
- Coverage gap analysis report
- Additional tests created (number TBD based on gaps)
- Test coverage 90%+ achieved
- Final coverage validation report

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Test coverage validation: `docs/agents/reports/agent_3/phase_7/week_51_52_test_coverage_validation_report.md`

Start by analyzing coverage gaps, then systematically create tests for uncovered critical paths.
```

### **Prompt 3: Final Test Validation (Priority 3)**

```
You are Agent 3 (Models & Testing Specialist) working on Phase 7, Section 51-52 remaining fixes.

**TASK: Final Test Validation**

**Current Status:**
- Test pass rate and coverage improvements should be complete

**Your Task:**
1. **Final Test Execution:**
   - Run full test suite
   - Verify all tests pass (99%+ pass rate)
   - Verify coverage meets target (90%+)
   - Document final results

2. **Production Readiness Validation:**
   - Review production readiness checklist
   - Verify all test-related criteria met
   - Update production readiness documentation if needed

**Deliverables:**
- Final test execution report
- Production readiness validation report
- Test validation complete

**References:**
- Task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
- Production readiness documentation: `docs/agents/reports/agent_3/phase_7/week_51_52_production_readiness_documentation.md`

Start by running the final test suite, then validate production readiness criteria.
```

---

## 📋 **General Instructions for All Agents**

### **Before Starting:**
1. ✅ Read the task assignments: `docs/agents/tasks/phase_7/week_51_52_remaining_fixes_task_assignments.md`
2. ✅ Read the completion status: `docs/agents/reports/SECTION_51_52_COMPLETION_STATUS.md`
3. ✅ Review relevant completion reports for your agent
4. ✅ Understand the remaining work and priorities

### **During Work:**
1. ✅ Follow the SPOTS philosophy (read `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`)
2. ✅ Follow design token requirements (100% AppColors/AppTheme adherence)
3. ✅ Fix any linter errors you encounter
4. ✅ Test your changes thoroughly
5. ✅ Update documentation as needed

### **After Completion:**
1. ✅ Create completion report in: `docs/agents/reports/agent_X/phase_7/week_51_52_remaining_fixes_completion_report.md`
2. ✅ Update status tracker: `docs/agents/status/status_tracker.md`
3. ✅ Verify all deliverables are complete
4. ✅ Document any exceptions or remaining work

---

**Status:** 🎯 **READY TO USE**  
**Priority:** 🔴 **CRITICAL**  
**Timeline:** 7 days (3 phases as outlined in task assignments)

