# Phase 7 Agent Prompts - Feature Matrix Completion (Week 37)

**Date:** November 27, 2025, 12:12 AM CST  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Week 37 (AI Self-Improvement Visibility - Integration & Polish)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_37_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`** - Detailed implementation plan (Section 2.2)
6. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_SECTION_2_2_COMPLETE.md`** - Widget completion report
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_37_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Week 37 Overview**

**Focus:** AI Self-Improvement Visibility - Integration & Polish  
**Duration:** 5 days  
**Priority:** 🟡 HIGH (Medium Priority UI/UX)  
**Note:** UI widgets are already complete - this week focuses on page creation, route integration, and production polish

**What Doors Does This Open?**
- **Transparency Doors:** Users can see how their AI is improving
- **Trust Doors:** Visible improvement builds user confidence
- **Education Doors:** Users learn about AI capabilities
- **Engagement Doors:** Interesting to watch AI evolve
- **Accuracy Doors:** Users see measurable improvements in recommendation quality

**Philosophy Alignment:**
- Transparent AI evolution (users see improvements)
- Trust-building (visible progress)
- Educational (explains AI capabilities)
- User-centric (shows user-specific improvements)

**Current Status:**
- ✅ All 4 widgets complete and functional
- ✅ Widgets wired to AIImprovementTrackingService
- ✅ Backend services exist (AISelfImprovementSystem, AIImprovementTrackingService)
- ⏳ Dedicated page needed (similar to FederatedLearningPage)
- ⏳ Route integration needed
- ⏳ Link needed in profile page
- ⏳ Linter cleanup needed
- ⏳ End-to-end testing needed

**Dependencies:**
- ✅ Week 33 (Action Execution UI) COMPLETE
- ✅ Week 34 (Device Discovery UI) COMPLETE
- ✅ Week 35 (LLM Full Integration) COMPLETE
- ✅ Week 36 (Federated Learning UI) COMPLETE
- ✅ AI Improvement widgets complete
- ✅ AIImprovementTrackingService exists

---

## 🤖 **Agent 1: Backend & Integration Specialist**

### **Your Context**

You are working on **Phase 7, Week 37: AI Self-Improvement Visibility - Integration & Polish**.

**Your Focus:** Page Creation & Backend Integration

**Current State:** All 4 widgets exist and are functional. They're already wired to AIImprovementTrackingService. You need to create a dedicated page (similar to FederatedLearningPage) and integrate it into the app.

### **Your Tasks**

**Day 1-2: Create AI Improvement Page**

1. **Create AI Improvement Page**
   - Location: `lib/presentation/pages/settings/ai_improvement_page.dart`
   - Model after `FederatedLearningPage` (see `lib/presentation/pages/settings/federated_learning_page.dart`)
   - Combine all 4 widgets into single page:
     - `AIImprovementSection` (main metrics)
     - `AIImprovementProgressWidget` (progress charts)
     - `AIImprovementTimelineWidget` (history timeline)
     - `AIImprovementImpactWidget` (impact explanation)
   - Add page header with title and description
   - Organize widgets in logical sections with section headers
   - Add proper spacing and layout
   - Use AppColors/AppTheme (100% design token compliance)
   - Get userId from AuthBloc (similar to other pages)

2. **Wire Backend Services**
   - Ensure AIImprovementTrackingService is initialized
   - Pass userId to all widgets (from AuthBloc)
   - Pass trackingService instance to all widgets
   - Test service initialization and data flow
   - Add error handling for service failures
   - Add loading states during initialization

**Day 3: Add Route & Navigation**

1. **Add Route to AppRouter**
   - Location: `lib/presentation/routes/app_router.dart`
   - Add route `/ai-improvement` (similar to `/federated-learning`)
   - Point route to `AIImprovementPage`
   - Test navigation flow

2. **Add Link to Profile Page**
   - Location: `lib/presentation/pages/profile/profile_page.dart`
   - Add "AI Improvement" link (similar to "Federated Learning" link)
   - Add appropriate icon (Icons.trending_up or similar)
   - Test navigation from profile to AI improvement page

**Day 4-5: Error Handling & Loading States**

1. **Error Handling**
   - Add error handling for service initialization failures
   - Add error handling for data fetch failures
   - Display user-friendly error messages
   - Add retry mechanisms where appropriate

2. **Loading States**
   - Ensure all widgets show loading states
   - Add page-level loading indicator during initialization
   - Test loading states with slow network/backend

### **Key Files to Reference**

- `lib/presentation/pages/settings/federated_learning_page.dart` - Page structure example
- `lib/presentation/widgets/settings/ai_improvement_section.dart` - Main metrics widget
- `lib/presentation/widgets/settings/ai_improvement_progress_widget.dart` - Progress widget
- `lib/presentation/widgets/settings/ai_improvement_timeline_widget.dart` - Timeline widget
- `lib/presentation/widgets/settings/ai_improvement_impact_widget.dart` - Impact widget
- `lib/core/services/ai_improvement_tracking_service.dart` - Backend service

### **Success Criteria**

- ✅ AI Improvement page created and integrated
- ✅ Route added to app_router.dart
- ✅ Link added to profile_page.dart
- ✅ All widgets wired to backend services
- ✅ Error handling implemented
- ✅ Loading states implemented
- ✅ Zero linter errors

### **Deliverables**

- `lib/presentation/pages/settings/ai_improvement_page.dart` (new file)
- Modified `lib/presentation/routes/app_router.dart`
- Modified `lib/presentation/pages/profile/profile_page.dart`
- Completion report: `docs/agents/reports/agent_1/phase_7/week_37_completion_report.md`

---

## 🎨 **Agent 2: Frontend & UX Specialist**

### **Your Context**

You are working on **Phase 7, Week 37: AI Self-Improvement Visibility - Integration & Polish**.

**Your Focus:** UI/UX Polish & Integration Verification

**Current State:** All widgets exist and are functional. They need linter cleanup, design token verification, and integration testing.

### **Your Tasks**

**Day 1-2: UI/UX Polish**

1. **Fix Linter Warnings**
   - Check all AI improvement widget files for linter errors:
     - `lib/presentation/widgets/settings/ai_improvement_section.dart`
     - `lib/presentation/widgets/settings/ai_improvement_progress_widget.dart`
     - `lib/presentation/widgets/settings/ai_improvement_timeline_widget.dart`
     - `lib/presentation/widgets/settings/ai_improvement_impact_widget.dart`
   - Fix any unused imports
   - Fix any deprecated methods (replace `withOpacity()` with `withValues(alpha:)`)
   - Ensure zero linter errors

2. **Design Token Compliance**
   - Verify 100% AppColors/AppTheme usage (NO direct Colors.*)
   - Check all widgets for design token compliance
   - Fix any direct Colors.* usage
   - This is **NON-NEGOTIABLE** per user memory

3. **Accessibility**
   - Add Semantics widgets where needed
   - Verify screen reader support
   - Test with accessibility tools

**Day 3: Integration Verification**

1. **Page Integration**
   - Verify all 4 widgets display correctly on page (after Agent 1 creates page)
   - Test responsive design (different screen sizes)
   - Verify scrolling behavior
   - Test navigation flow

2. **User Experience Testing**
   - Test complete user journey (profile → AI improvement page)
   - Verify data loads correctly
   - Test real-time updates (metrics stream)
   - Verify all interactive elements work
   - Test empty states
   - Test error states

**Day 4-5: Performance & Polish**

1. **Performance Optimization**
   - Review widget performance
   - Ensure proper const usage
   - Optimize rebuilds
   - Test with large datasets

2. **Visual Polish**
   - Verify consistent spacing
   - Check typography consistency
   - Verify color usage
   - Test dark mode (if applicable)

### **Key Files to Reference**

- `lib/presentation/pages/settings/federated_learning_page.dart` - Page structure example
- `lib/presentation/widgets/settings/ai_improvement_section.dart` - Main metrics widget
- `lib/presentation/widgets/settings/ai_improvement_progress_widget.dart` - Progress widget
- `lib/presentation/widgets/settings/ai_improvement_timeline_widget.dart` - Timeline widget
- `lib/presentation/widgets/settings/ai_improvement_impact_widget.dart` - Impact widget

### **Success Criteria**

- ✅ All linter warnings fixed
- ✅ 100% design token compliance
- ✅ Accessibility support added
- ✅ Page integration verified
- ✅ User experience tested
- ✅ Performance optimized
- ✅ Zero linter errors

### **Deliverables**

- Modified widget files (linter fixes, polish)
- Completion report: `docs/agents/reports/agent_2/phase_7/week_37_completion_report.md`

---

## 🧪 **Agent 3: Models & Testing Specialist**

### **Your Context**

You are working on **Phase 7, Week 37: AI Self-Improvement Visibility - Integration & Polish**.

**Your Focus:** Integration Tests & End-to-End Tests

**Current State:** Widgets exist and are functional. Backend services exist. Need comprehensive testing.

### **Your Tasks**

**Day 1-2: Backend Integration Tests**

1. **AIImprovementTrackingService Tests**
   - Location: `test/services/ai_improvement_tracking_service_test.dart`
   - Test service initialization
   - Test getCurrentMetrics() method
   - Test getAccuracyMetrics() method
   - Test getProgressHistory() method
   - Test getTimeline() method
   - Test metrics stream
   - Test error handling

2. **Widget-Backend Integration Tests**
   - Test AIImprovementSection widget calls to service
   - Test AIImprovementProgressWidget widget calls to service
   - Test AIImprovementTimelineWidget widget calls to service
   - Test AIImprovementImpactWidget widget calls to service
   - Test error handling in widgets
   - Test loading states in widgets

**Day 3: End-to-End Tests**

1. **Page Navigation Tests**
   - Test navigation from profile to AI improvement page
   - Test route configuration
   - Test back navigation

2. **Complete User Flow Tests**
   - Test page loads with authenticated user
   - Test all widgets display data
   - Test real-time updates
   - Test error scenarios
   - Test loading states
   - Test empty states

**Day 4-5: Test Coverage & Documentation**

1. **Test Coverage**
   - Ensure >80% test coverage for new page
   - Ensure >80% test coverage for service integration
   - Document test coverage

2. **Documentation**
   - Update completion report
   - Document any issues found
   - Document test results

### **Key Files to Reference**

- `test/widget/widgets/settings/ai_improvement_section_test.dart` - Existing widget tests
- `test/widget/widgets/settings/ai_improvement_progress_widget_test.dart` - Existing widget tests
- `test/widget/widgets/settings/ai_improvement_timeline_widget_test.dart` - Existing widget tests
- `test/widget/widgets/settings/ai_improvement_impact_widget_test.dart` - Existing widget tests
- `lib/core/services/ai_improvement_tracking_service.dart` - Service to test
- `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md` - Testing workflow

### **Success Criteria**

- ✅ Backend integration tests created
- ✅ End-to-end tests created
- ✅ Test coverage >80%
- ✅ All tests passing
- ✅ Documentation complete

### **Deliverables**

- `test/pages/settings/ai_improvement_page_test.dart` (new file)
- `test/integration/ai_improvement_integration_test.dart` (new file)
- Modified service tests (if needed)
- Completion report: `docs/agents/reports/agent_3/phase_7/week_37_completion_report.md`

---

## 📋 **Common Requirements for All Agents**

### **Code Quality Standards**

- ✅ **Zero linter errors** - Non-negotiable
- ✅ **100% design token compliance** - Use AppColors/AppTheme, NO direct Colors.*
- ✅ **Proper error handling** - User-friendly error messages
- ✅ **Loading states** - Show loading indicators during data fetch
- ✅ **Offline handling** - Graceful degradation when backend unavailable

### **Architecture Alignment**

- ✅ **Offline-first** - Use local storage where possible
- ✅ **Privacy-preserving** - Data stays on device
- ✅ **Error handling** - Graceful degradation
- ✅ **Real-time updates** - Use streams where appropriate

### **Documentation Requirements**

- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` with your progress
- ✅ **Completion Report:** Create in `docs/agents/reports/agent_X/phase_7/week_37_*.md`
- ✅ **Code Comments:** Add clear comments explaining complex logic

### **Testing Requirements**

- ✅ **Unit tests** - Test individual components
- ✅ **Integration tests** - Test component interactions
- ✅ **End-to-end tests** - Test complete user flows
- ✅ **Test coverage** - >80% coverage

---

## 🚀 **Doors Opened**

- ✅ **Transparency Doors:** Users can see how their AI is improving
- ✅ **Trust Doors:** Visible improvement builds user confidence
- ✅ **Education Doors:** Users learn about AI capabilities
- ✅ **Engagement Doors:** Interesting to watch AI evolve
- ✅ **Accuracy Doors:** Users see measurable improvements in recommendation quality

---

## 📝 **Notes**

- All widgets already exist and are functional
- Widgets are already wired to AIImprovementTrackingService
- Focus is on page creation, route integration, and polish
- Similar pattern to Federated Learning page (Week 36)
- Follow the same structure and patterns as Week 36

---

**Status:** 🎯 **READY TO USE**  
**Next:** Agents start work on Week 37 tasks

