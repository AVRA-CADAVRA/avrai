# Phase 7 Agent Prompts - Feature Matrix Completion (Week 36)

**Date:** November 26, 2025, 11:48 PM CST  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Week 36 (Federated Learning UI - Backend Integration & Polish)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_36_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`** - Detailed implementation plan (Section 2.1)
6. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_SECTION_2_1_COMPLETE.md`** - Widget completion report
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_36_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Week 36 Overview**

**Focus:** Federated Learning UI - Backend Integration & Polish  
**Duration:** 5 days  
**Priority:** 🟡 HIGH (Medium Priority UI/UX)  
**Note:** UI widgets are already complete - this week focuses on backend integration and production readiness

**What Doors Does This Open?**
- **Privacy Doors:** Users understand and control their participation in privacy-preserving AI training
- **Transparency Doors:** Users see active learning rounds and their participation status
- **Privacy Metrics Doors:** Users see personalized privacy protection metrics
- **History Doors:** Users see their contribution history to AI improvement
- **Education Doors:** Users learn about federated learning and its benefits

**Philosophy Alignment:**
- Privacy-preserving AI training (data never leaves device)
- Transparent participation (users see what's happening)
- User control (opt-in/opt-out)
- Educational (explains how it works)

**Current Status:**
- ✅ All 4 widgets complete and functional
- ✅ FederatedLearningPage exists and is routed
- ✅ Link exists in profile/settings page
- ⏳ Backend integration needed (currently using mock data)
- ⏳ Linter cleanup needed
- ⏳ End-to-end testing needed

**Dependencies:**
- ✅ Week 33 (Action Execution UI) COMPLETE
- ✅ Week 34 (Device Discovery UI) COMPLETE
- ✅ Week 35 (LLM Full Integration) COMPLETE
- ✅ Federated Learning UI widgets complete
- ✅ FederatedLearningSystem backend exists

---

## 🤖 **Agent 1: Backend & Integration Specialist**

### **Your Context**

You are working on **Phase 7, Week 36: Federated Learning UI - Backend Integration & Polish**.

**Your Focus:** Backend Service Integration

**Current State:** UI widgets exist and work with mock data. Backend services (FederatedLearningSystem, NetworkAnalytics) exist but aren't wired to widgets yet.

### **Your Tasks**

**Day 1-2: Wire FederatedLearningSystem**

1. **Review FederatedLearningSystem API**
   - Location: `lib/core/p2p/federated_learning.dart`
   - Document available methods (getActiveRounds, getParticipationHistory, etc.)
   - Identify methods needed by widgets
   - Check data models and return types

2. **Wire Learning Round Status Widget**
   - Location: `lib/presentation/widgets/settings/federated_learning_status_widget.dart`
   - Replace mock data with real `FederatedLearningSystem.getActiveRounds()`
   - Handle loading states
   - Handle error states
   - Update UI when rounds change

3. **Wire Participation History Widget**
   - Location: `lib/presentation/widgets/settings/federated_participation_history_widget.dart`
   - Replace mock data with real `FederatedLearningSystem.getParticipationHistory()`
   - Handle loading states
   - Handle error states
   - Update history when user participates

**Day 3: Wire NetworkAnalytics for Privacy Metrics**

1. **Review NetworkAnalytics API**
   - Review NetworkAnalytics service
   - Document privacy metrics methods
   - Identify user-specific metrics needed

2. **Wire Privacy Metrics Widget**
   - Location: `lib/presentation/widgets/settings/privacy_metrics_widget.dart`
   - Replace mock data with NetworkAnalytics calls
   - Display user-specific anonymization levels
   - Display user-specific data protection metrics
   - Handle loading/error states

**Day 4-5: Integration Testing & Error Handling**

1. **Add Error Handling**
   - Graceful fallback when backend unavailable
   - User-friendly error messages
   - Retry mechanisms where appropriate
   - Offline handling

2. **Integration Testing**
   - Test with real backend services
   - Verify all widgets work with backend data
   - Test opt-in/opt-out flow
   - Test participation flow
   - Verify data persistence

### **Deliverables**

- [ ] FederatedLearningSystem wired to widgets
- [ ] NetworkAnalytics wired to privacy metrics widget
- [ ] Loading states implemented
- [ ] Error handling implemented
- [ ] Integration tested
- [ ] Zero linter errors

### **Success Criteria**

- [ ] All widgets use real backend data (no mocks)
- [ ] Loading states show during data fetch
- [ ] Error states display user-friendly messages
- [ ] Offline handling works correctly
- [ ] Integration tests passing

### **Resources**

- Task Assignments: `docs/agents/tasks/phase_7/week_36_task_assignments.md`
- Backend Service: `lib/core/p2p/federated_learning.dart`
- Widgets:
  - `lib/presentation/widgets/settings/federated_learning_status_widget.dart`
  - `lib/presentation/widgets/settings/federated_participation_history_widget.dart`
  - `lib/presentation/widgets/settings/privacy_metrics_widget.dart`

---

## 🎨 **Agent 2: Frontend & UX Specialist**

### **Your Context**

You are working on **Phase 7, Week 36: Federated Learning UI - Backend Integration & Polish**.

**Your Focus:** UI Polish & Integration Verification

**Current State:** Widgets are complete but may have linter warnings and need polish.

### **Your Tasks**

**Day 1-2: Code Cleanup**

1. **Fix Linter Warnings**
   - Remove unused imports (`app_theme.dart` if not needed)
   - Replace deprecated `withOpacity()` with `withValues(alpha:)`
   - Fix any other linter warnings
   - Location: All federated learning widget files

2. **Code Optimization**
   - Review widget performance
   - Optimize rebuilds (use const where possible)
   - Review state management
   - Ensure proper widget lifecycle

**Day 3: Integration Verification**

1. **Verify Page Integration**
   - Verify FederatedLearningPage renders correctly
   - Verify route works from profile page
   - Verify all widgets display properly
   - Test navigation flow

2. **UI/UX Polish**
   - Verify 100% AppColors/AppTheme adherence (NO direct Colors.* usage)
   - Check responsive design (mobile, tablet, desktop)
   - Verify accessibility (Semantics)
   - Test with different screen sizes
   - Verify loading states display correctly
   - Verify error states display correctly

**Day 4-5: User Experience Testing**

1. **Test User Flows**
   - Test opt-in/opt-out toggle
   - Test participation in learning rounds
   - Test viewing participation history
   - Test viewing privacy metrics
   - Verify persistence works correctly

2. **Documentation**
   - Verify widget documentation is complete
   - Update integration documentation
   - Document backend integration points

### **Deliverables**

- [ ] Zero linter errors
- [ ] Deprecated methods replaced
- [ ] Unused imports removed
- [ ] 100% design token compliance
- [ ] Responsive design verified
- [ ] Accessibility verified
- [ ] User flows tested

### **Success Criteria**

- [ ] Zero linter errors
- [ ] 100% AppColors/AppTheme adherence
- [ ] Responsive on all screen sizes
- [ ] Accessible (screen readers work)
- [ ] All user flows work smoothly

### **Resources**

- Task Assignments: `docs/agents/tasks/phase_7/week_36_task_assignments.md`
- Widget Files:
  - `lib/presentation/widgets/settings/federated_learning_settings_section.dart`
  - `lib/presentation/widgets/settings/federated_learning_status_widget.dart`
  - `lib/presentation/widgets/settings/privacy_metrics_widget.dart`
  - `lib/presentation/widgets/settings/federated_participation_history_widget.dart`
  - `lib/presentation/pages/settings/federated_learning_page.dart`

---

## 🧪 **Agent 3: Models & Testing Specialist**

### **Your Context**

You are working on **Phase 7, Week 36: Federated Learning UI - Backend Integration & Polish**.

**Your Focus:** End-to-End Tests & Backend Integration Tests

**Current State:** Widget tests exist, but integration tests with backend are needed.

### **Your Tasks**

**Day 1-2: Backend Integration Tests**

1. **Test FederatedLearningSystem Integration**
   - Test widget calls to FederatedLearningSystem
   - Test active rounds retrieval
   - Test participation history retrieval
   - Test error handling
   - Test loading states

2. **Test NetworkAnalytics Integration**
   - Test privacy metrics retrieval
   - Test user-specific metrics
   - Test error handling

**Day 3: End-to-End Tests**

1. **Test Complete User Flows**
   - Test navigation from profile to federated learning page
   - Test opt-in/opt-out toggle and persistence
   - Test joining/leaving learning rounds
   - Test viewing all sections
   - Test error scenarios

2. **Integration Tests**
   - Test widgets with real backend services
   - Test loading states
   - Test error states
   - Test offline handling

**Day 4-5: Test Coverage & Documentation**

1. **Update Test Coverage**
   - Ensure all widgets have tests
   - Add integration tests for backend calls
   - Add error handling tests
   - Verify test coverage >80%

2. **Documentation**
   - Create completion report
   - Document backend integration
   - Document test coverage
   - Update feature matrix status

### **Deliverables**

- [ ] Backend integration tests
- [ ] End-to-end tests
- [ ] Error handling tests
- [ ] Test coverage report
- [ ] Completion report

### **Success Criteria**

- [ ] All integration tests passing
- [ ] End-to-end tests passing
- [ ] >80% test coverage
- [ ] Zero linter errors
- [ ] Comprehensive test documentation

### **Resources**

- Task Assignments: `docs/agents/tasks/phase_7/week_36_task_assignments.md`
- Testing Protocol: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Existing Widget Tests:
  - `test/widget/widgets/settings/federated_learning_settings_section_test.dart`
  - `test/widget/widgets/settings/federated_learning_status_widget_test.dart`
  - `test/widget/widgets/settings/privacy_metrics_widget_test.dart`
  - `test/widget/widgets/settings/federated_participation_history_widget_test.dart`

---

## 📋 **Common Requirements (All Agents)**

### **Code Quality Standards**
- ✅ Zero linter errors before completion
- ✅ Follow existing code patterns
- ✅ Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
- ✅ Write comprehensive tests
- ✅ Document all changes

### **Design Token Compliance (MANDATORY)**
- ✅ **ALWAYS use `AppColors` or `AppTheme`** for colors
- ❌ **NEVER use direct `Colors.*`** (will be flagged)
- ✅ This is non-negotiable per user requirement

### **Architecture Alignment**
- ✅ System is **ai2ai only** (never p2p)
- ✅ All features work offline-first
- ✅ AIs always self-improving
- ✅ Privacy-preserving design

### **Documentation Requirements**
- ✅ Update status tracker: `docs/agents/status/status_tracker.md`
- ✅ Create completion report: `docs/agents/reports/agent_X/phase_7/week_36_*.md`
- ✅ Document all code changes
- ✅ Follow refactoring protocol: `docs/agents/REFACTORING_PROTOCOL.md`

### **Status Updates**
- ✅ Mark tasks as complete in status tracker
- ✅ Update "Current Section" and "Status" fields
- ✅ Update "Ready For Others" field when dependencies are met
- ✅ Note any blockers or issues

---

## 🎯 **Completion Criteria**

### **Week 36 is Complete When:**
- ✅ All widgets wired to backend services (no mock data)
- ✅ Loading states implemented
- ✅ Error handling implemented
- ✅ Zero linter errors
- ✅ 100% design token compliance
- ✅ End-to-end tests passing
- ✅ Integration tests passing
- ✅ Completion reports created
- ✅ Status tracker updated

### **Doors Opened:**
- ✅ Privacy-preserving AI training participation
- ✅ Transparent learning round visibility
- ✅ Privacy metrics transparency
- ✅ Participation history visibility
- ✅ Educational content about federated learning

---

## 📝 **Notes**

- **Priority:** Medium Priority UI/UX (HIGH priority within Phase 7)
- **Current State:** UI widgets complete, backend integration needed
- **Estimated Effort:** 5 days
- **Production Readiness:** This week makes Federated Learning UI production-ready

---

**Last Updated:** November 26, 2025, 11:48 PM CST  
**Status:** 🎯 Ready to Use

