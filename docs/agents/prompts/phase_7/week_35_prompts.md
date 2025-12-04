# Phase 7 Agent Prompts - Feature Matrix Completion (Week 35)

**Date:** November 25, 2025, 3:30 PM CST  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Week 35 (LLM Full Integration - UI Integration)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_35_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`** - Detailed implementation plan (Section 1.3)
6. ✅ **`docs/plans/phase_1_3/PHASE_1_3_LLM_INTEGRATION_ASSESSMENT.md`** - LLM integration assessment
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_35_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Week 35 Overview**

**Focus:** LLM Full Integration - UI Integration Completion  
**Duration:** 5 days  
**Priority:** 🔴 CRITICAL  
**Note:** Final integration tasks for LLM Full Integration (Section 1.3)

**What Doors Does This Open?**
- **Visual Feedback Doors:** Users see thinking indicators during AI processing (transparency)
- **Success Feedback Doors:** Users get clear success messages after actions (confirmation)
- **Offline Awareness Doors:** Users know when they're offline (informed decisions)
- **Streaming Doors:** Users see real-time response streaming (engaging UX) - Optional
- **Integration Doors:** All LLM features fully integrated into app flow (complete experience)

**Philosophy Alignment:**
- Thinking indicators show users what the AI is doing (transparency, not magic)
- Success feedback confirms actions completed (doors for confidence)
- Offline indicators help users understand connectivity (doors for awareness)
- Real-time streaming makes AI feel responsive (doors for engagement)

**Current Status:**
- ✅ Tasks 1-5: COMPLETE (Enhanced LLM Context, Personality-Driven Responses, AI2AI Insights, Vibe Compatibility, UI Components)
- ✅ Task 8: COMPLETE (Action Execution Integration)
- ⏳ Task 6: IN PROGRESS (UI Integration - Wire widgets to LLM calls)
- ⭕ Task 7: OPTIONAL (Real SSE Streaming - enhancement)

**Dependencies:**
- ✅ Phase 6 (Local Expert System Redesign) COMPLETE
- ✅ Week 33 (Action Execution UI & Integration) COMPLETE
- ✅ Week 34 (Device Discovery UI) COMPLETE (already implemented)
- ✅ LLM Service with personality/vibe/AI2AI context COMPLETE
- ✅ UI Components Created (AIThinkingIndicator, ActionSuccessWidget, OfflineIndicatorWidget)

---

## 🤖 **Agent 1: Backend & Integration Specialist**

### **Your Context**

You are working on **Phase 7, Week 35: LLM Full Integration - UI Integration Completion**.

**Your Focus:** Optional Real SSE Streaming Enhancement (Task 7)

**Note:** This is an **optional enhancement**. If time is limited or you prefer to focus on Task 6 support, that's fine. The core requirement is Task 6 (UI Integration) which Agent 2 handles.

### **Your Tasks**

**Task 7: Real SSE Streaming (Optional Enhancement)**

1. **Update Supabase Edge Function for SSE**
   - Location: `supabase/functions/llm-chat/index.ts`
   - Add Server-Sent Events (SSE) support
   - Implement SSE response format
   - Maintain backward compatibility with non-streaming requests
   - Handle connection recovery logic
   - Test with long responses

2. **Update LLM Service for Real SSE**
   - Location: `lib/core/services/llm_service.dart`
   - Add `chatStreamSSE()` method (replaces simulated streaming)
   - Handle SSE connection errors and reconnection
   - Parse SSE format correctly
   - Test streaming with various response lengths

3. **Error Handling & Recovery**
   - Handle SSE connection drops gracefully
   - Implement automatic reconnection logic
   - Provide fallback to non-streaming if SSE fails
   - Add timeout handling for long-running streams

### **Deliverables**

- [ ] Updated Edge Function with SSE support
- [ ] Updated LLM Service with SSE client
- [ ] Connection recovery logic
- [ ] Error handling and fallbacks
- [ ] Tests for SSE streaming
- [ ] Documentation of SSE implementation

### **Success Criteria**

- [ ] Real SSE streaming working end-to-end
- [ ] Fallback to non-streaming on failure
- [ ] Connection recovery on drop
- [ ] Zero linter errors
- [ ] Backward compatibility maintained

### **Resources**

- Task Assignments: `docs/agents/tasks/phase_7/week_35_task_assignments.md`
- LLM Service: `lib/core/services/llm_service.dart`
- Edge Function: `supabase/functions/llm-chat/index.ts`
- Current Streaming: `lib/core/services/llm_service.dart` (simulated streaming)

---

## 🎨 **Agent 2: Frontend & UX Specialist**

### **Your Context**

You are working on **Phase 7, Week 35: LLM Full Integration - UI Integration Completion**.

**Your Focus:** UI Integration - Wire Widgets to LLM Calls (Task 6) - **REQUIRED**

This is the **core requirement** for Week 35. All UI widgets exist and are tested - they just need to be wired into the main app flow.

### **Your Tasks**

**Task 6: UI Integration (Required)**

#### **Day 1-2: Wire AIThinkingIndicator**
1. **Integrate into AICommandProcessor**
   - Location: `lib/presentation/widgets/common/ai_command_processor.dart`
   - Show `AIThinkingIndicator` during `LLMService.chat()` or `chatStream()` processing
   - Show indicator during action intent parsing
   - Show indicator during action execution
   - Hide indicator when response/action completes or fails
   - Widget exists at: `lib/presentation/widgets/common/ai_thinking_indicator.dart`

2. **Update processCommand() Method**
   - Wrap LLM calls with thinking indicator show/hide
   - Handle async operations correctly
   - Ensure indicator shows for all LLM operations
   - Test with various command types

#### **Day 3: Wire ActionSuccessWidget**
1. **Integrate into Action Execution**
   - Show `ActionSuccessWidget` after successful action execution
   - Display success message from ActionResult
   - Include undo option if action supports undo
   - Auto-dismiss after timeout or user dismissal
   - Widget exists at: `lib/presentation/widgets/common/action_success_widget.dart`

2. **Update Action Execution Flow**
   - Wire success widget to `_executeActionWithUI()` method
   - Show success feedback after action completes
   - Handle undo callback if user taps undo
   - Test with all action types

#### **Day 4: Wire OfflineIndicatorWidget**
1. **Integrate into App Layout**
   - Add `OfflineIndicatorWidget` to main app scaffold
   - Show indicator when device is offline
   - Hide indicator when device is online
   - Position at top of screen
   - Widget exists at: `lib/presentation/widgets/common/offline_indicator_widget.dart`

2. **Connectivity Detection**
   - Monitor connectivity status changes
   - Update indicator in real-time
   - Handle both WiFi and mobile data
   - Show appropriate offline messaging

#### **Day 5: Integration Testing & Polish**
1. **Test Complete Integration Flow**
   - Test thinking indicator during LLM calls
   - Test success widget after actions
   - Test offline indicator behavior
   - Test all widgets working together
   - Verify no UI conflicts

2. **UI/UX Polish**
   - Ensure smooth transitions
   - Verify 100% AppColors/AppTheme adherence (NO direct Colors.* usage)
   - Test on different screen sizes
   - Verify accessibility
   - Zero linter errors

### **Deliverables**

- [ ] AIThinkingIndicator wired to LLM calls
- [ ] ActionSuccessWidget wired to action execution
- [ ] OfflineIndicatorWidget integrated into app layout
- [ ] All widgets working together smoothly
- [ ] Zero linter errors
- [ ] 100% design token compliance
- [ ] Integration tested end-to-end

### **Success Criteria**

- [ ] Thinking indicator shows during all LLM operations
- [ ] Success widget shows after successful actions
- [ ] Offline indicator shows/hides based on connectivity
- [ ] All widgets integrated into main app flow
- [ ] Zero linter errors
- [ ] 100% AppColors/AppTheme adherence
- [ ] Responsive and accessible

### **Resources**

- Task Assignments: `docs/agents/tasks/phase_7/week_35_task_assignments.md`
- AICommandProcessor: `lib/presentation/widgets/common/ai_command_processor.dart`
- Widgets:
  - `lib/presentation/widgets/common/ai_thinking_indicator.dart`
  - `lib/presentation/widgets/common/action_success_widget.dart`
  - `lib/presentation/widgets/common/offline_indicator_widget.dart`
- LLM Service: `lib/core/services/llm_service.dart`

---

## 🧪 **Agent 3: Models & Testing Specialist**

### **Your Context**

You are working on **Phase 7, Week 35: LLM Full Integration - UI Integration Completion**.

**Your Focus:** Tests for UI Integration, SSE Streaming Tests (if implemented)

### **Your Tasks**

#### **Day 1-2: UI Integration Tests**
1. **Test AIThinkingIndicator Integration**
   - Verify indicator shows during LLM calls
   - Verify indicator hides after completion
   - Test indicator during action parsing
   - Test indicator during action execution
   - Test error handling

2. **Test ActionSuccessWidget Integration**
   - Verify widget shows after successful actions
   - Verify undo option appears for undoable actions
   - Test widget dismissal
   - Test undo callback functionality

3. **Test OfflineIndicatorWidget Integration**
   - Verify indicator shows when offline
   - Verify indicator hides when online
   - Test connectivity change detection
   - Test widget positioning

#### **Day 3: Integration Tests**
1. **End-to-End Integration Tests**
   - Test complete flow: LLM call → thinking indicator → response → action → success widget
   - Test offline flow: offline indicator → offline handling
   - Test error flow: thinking indicator → error → error dialog
   - Test all widgets working together without conflicts

#### **Day 4-5: SSE Streaming Tests (if Agent 1 implements)**
1. **Test Real SSE Streaming**
   - Test SSE connection establishment
   - Test streaming response parsing
   - Test connection recovery on drop
   - Test fallback to non-streaming on failure
   - Test with long responses
   - Test timeout handling

2. **Documentation**
   - Document UI integration flow
   - Document SSE implementation (if completed)
   - Create completion report
   - Update test coverage reports

### **Deliverables**

- [ ] Tests for AIThinkingIndicator integration
- [ ] Tests for ActionSuccessWidget integration
- [ ] Tests for OfflineIndicatorWidget integration
- [ ] End-to-end integration tests
- [ ] SSE streaming tests (if implemented)
- [ ] Test coverage report
- [ ] Completion report

### **Success Criteria**

- [ ] All integration tests passing
- [ ] >90% test coverage for integration points
- [ ] SSE tests passing (if implemented)
- [ ] Zero linter errors
- [ ] Comprehensive test documentation

### **Resources**

- Task Assignments: `docs/agents/tasks/phase_7/week_35_task_assignments.md`
- Testing Protocol: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Existing Widget Tests:
  - `test/widget/widgets/common/ai_thinking_indicator_test.dart`
  - `test/widget/widgets/common/action_success_widget_test.dart`
  - `test/widget/widgets/common/offline_indicator_widget_test.dart`
- Integration Test Examples: `test/integration/action_execution_integration_test.dart`

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
- ✅ Personality learning integration

### **Documentation Requirements**
- ✅ Update status tracker: `docs/agents/status/status_tracker.md`
- ✅ Create completion report: `docs/agents/reports/agent_X/phase_7/week_35_*.md`
- ✅ Document all code changes
- ✅ Follow refactoring protocol: `docs/agents/REFACTORING_PROTOCOL.md`

### **Status Updates**
- ✅ Mark tasks as complete in status tracker
- ✅ Update "Current Section" and "Status" fields
- ✅ Update "Ready For Others" field when dependencies are met
- ✅ Note any blockers or issues

---

## 🎯 **Completion Criteria**

### **Week 35 is Complete When:**
- ✅ Task 6 (UI Integration) is complete - **REQUIRED**
- ✅ All widgets wired to LLM calls
- ✅ All integration tests passing
- ✅ Zero linter errors
- ✅ Completion reports created
- ✅ Status tracker updated
- ⭕ Task 7 (SSE Streaming) is optional - complete if time allows

### **Doors Opened:**
- ✅ Visual feedback during AI processing
- ✅ Success confirmation after actions
- ✅ Offline awareness
- ✅ Real-time streaming (if implemented)

---

## 📝 **Notes**

- **Priority:** Task 6 (UI Integration) is **REQUIRED**, Task 7 (SSE Streaming) is **OPTIONAL**
- **Current State:** All backend work complete, UI components exist and are tested
- **Estimated Effort:** 5 days (Task 6) + 1-2 days optional (Task 7)
- **Production Readiness:** Task 6 completion brings LLM integration to 100%

---

**Last Updated:** November 25, 2025, 3:30 PM CST  
**Status:** 🎯 Ready to Use

