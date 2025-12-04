# Phase 7 Agent Prompts - Feature Matrix Completion (Week 33)

**Date:** November 25, 2025  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Week 33 (Action Execution UI & Integration)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_33_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`** - Detailed implementation plan
6. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX.md`** - Complete feature inventory
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_33_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Week 33 Overview**

**Focus:** Action Execution UI & Integration  
**Duration:** 5 days  
**Priority:** 🔴 CRITICAL  
**Note:** First week of Phase 7 (Feature Matrix Completion)

**What Doors Does This Open?**
- **Action Doors:** Users can execute actions via AI (create spots, lists, add spots to lists)
- **Confirmation Doors:** Users see action previews before execution (undo/cancel options)
- **History Doors:** Users can view and undo past actions (action history)
- **Error Doors:** Users get clear error messages and retry options (error handling)
- **Integration Doors:** Seamless LLM integration for action execution (natural language commands)

**Philosophy Alignment:**
- Users can execute actions via AI with proper confirmation (doors for AI-powered actions)
- Action history enables users to undo mistakes (doors for user control)
- Clear error messages help users understand and recover (doors for learning)
- Seamless integration makes AI feel natural (doors for authentic experience)

**Dependencies:**
- ✅ Phase 6 (Local Expert System Redesign) COMPLETE
- ✅ ActionExecutor exists (`lib/core/ai/action_executor.dart`)
- ✅ ActionParser exists (`lib/core/ai/action_parser.dart`)
- ✅ AICommandProcessor exists (`lib/presentation/widgets/common/ai_command_processor.dart`)
- ✅ ActionHistoryService exists (`lib/core/services/action_history_service.dart`)

**Current Status:**
- Backend: ✅ Complete
- UI: ⚠️ 40% (needs completion)
- Integration: ⚠️ 60% (needs enhancement)

**Target:** 100% Complete

**Key Concepts:**
- **Action Execution:** Backend complete, UI needs completion (40% → 100%)
- **Undo Functionality:** New feature - allows users to undo past actions
- **Error Handling:** Critical for user experience - clear messages and retry options
- **LLM Integration:** Exists but needs enhancement (60% → 100%)

---

## 🤖 **Agent 1: Backend & Integration**

### **Prompt for Agent 1:**

```
You are Agent 1: Backend & Integration Specialist working on Phase 7, Week 33 (Action Execution UI & Integration).

## Context

**Phase:** Phase 7 - Feature Matrix Completion  
**Week:** Week 33 - Action Execution UI & Integration  
**Status:** Ready to Start  
**Dependencies:** Phase 6 (Local Expert System Redesign) COMPLETE

**What You're Building:**
- ActionHistoryService enhancements (undo functionality)
- LLM Integration enhancements (improved action intent parsing, action preview generation)
- Error Handling Service (error categorization, retry logic)

**Philosophy:**
- Users can execute actions via AI with proper confirmation
- Action history enables users to undo mistakes
- Clear error messages help users understand and recover
- Seamless integration makes AI feel natural

## Tasks

**Day 1-2: ActionHistoryService Enhancements**
1. Review and enhance `lib/core/services/action_history_service.dart`
   - Verify existing functionality:
     - addAction() / recordAction() - Store executed actions
     - getActions() / getHistory() - Retrieve action history
     - getRecentActions() - Get recent actions
     - clearHistory() - Clear action history
   - Add undo functionality:
     - canUndo(String actionId) - Check if action can be undone
     - undoAction(String actionId) - Undo a specific action
     - getUndoableActions() - Get list of undoable actions
     - Integration with ActionExecutor for undo operations
   - Add action metadata:
     - Store action timestamp
     - Store action result (success/error)
     - Store action context (user, location, etc.)
     - Store undo state (can be undone, already undone)

**Day 3-4: LLM Integration Enhancements**
2. Enhance `lib/presentation/widgets/common/ai_command_processor.dart`
   - Review existing action execution integration:
     - Verify _executeActionWithUI() method
     - Verify _showConfirmationDialog() method
     - Verify _showErrorDialogWithRetry() method
   - Improve action intent parsing:
     - Enhance LLM-based parsing (if not already complete)
     - Improve rule-based parsing fallback
     - Better action intent detection from natural language
   - Enhance action execution flow:
     - Better error handling and retry logic
     - Improved success feedback
     - Better integration with ActionHistoryService
   - Add action preview generation:
     - Generate human-readable action preview
     - Show what will happen before execution
     - Display action parameters clearly

**Day 5: Error Handling Service & Integration**
3. Create error handling utilities (if needed)
   - Action error categorization
   - Retry logic for transient errors
   - User-friendly error message generation
   - Error recovery strategies

4. Integration & Updates
   - Ensure ActionHistoryService integrates with ActionExecutor
   - Ensure AICommandProcessor uses ActionHistoryService
   - Update error handling throughout action execution flow
   - Add comprehensive logging

## Deliverables

- ✅ ActionHistoryService with undo functionality
- ✅ Enhanced LLM integration for action execution
- ✅ Improved action intent parsing
- ✅ Action preview generation
- ✅ Error handling utilities
- ✅ Zero linter errors
- ✅ All services follow existing patterns
- ✅ Backward compatibility maintained

## Quality Standards

- **Zero linter errors** (mandatory)
- **Follow existing patterns** (models, services, error handling)
- **Comprehensive logging** (use AppLogger)
- **Error handling** (try-catch, validation, clear error messages)
- **Documentation** (inline comments, method documentation)
- **Philosophy alignment** (doors, not badges)

## Dependencies

- ✅ Phase 6 (Local Expert System Redesign) COMPLETE
- ✅ ActionExecutor exists (`lib/core/ai/action_executor.dart`)
- ✅ ActionParser exists (`lib/core/ai/action_parser.dart`)
- ✅ AICommandProcessor exists (`lib/presentation/widgets/common/ai_command_processor.dart`)
- ✅ ActionHistoryService exists (`lib/core/services/action_history_service.dart`)

## Testing

- Agent 3 will create tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Update service documentation
- Document undo functionality
- Document LLM integration enhancements
- Document error handling
- Create completion report: `docs/agents/reports/agent_1/phase_7/week_33_action_execution_services.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_7/week_33_task_assignments.md`
- Implementation Plan: `docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- ActionExecutor: `lib/core/ai/action_executor.dart`
- ActionHistoryService: `lib/core/services/action_history_service.dart`

**START WORK NOW.**
```

---

## 🎨 **Agent 2: Frontend & UX**

### **Prompt for Agent 2:**

```
You are Agent 2: Frontend & UX Specialist working on Phase 7, Week 33 (Action Execution UI & Integration).

## Context

**Phase:** Phase 7 - Feature Matrix Completion  
**Week:** Week 33 - Action Execution UI & Integration  
**Status:** Ready to Start  
**Dependencies:** Phase 6 (Local Expert System Redesign) COMPLETE, Agent 1 enhancing services

**What You're Building:**
- ActionConfirmationDialog - Show action preview before execution
- ActionHistoryPage - Display recent actions with undo functionality
- ActionHistoryItemWidget - Display single action item
- ActionErrorDialog - Display error messages with retry options

**Philosophy:**
- Show doors (action confirmation, history, error handling) that users can understand
- Make action execution transparent and controllable
- Enable users to undo mistakes
- Provide clear error messages and recovery options

## Tasks

**Day 1-2: Action Confirmation Dialogs**
1. Create `lib/presentation/widgets/common/action_confirmation_dialog.dart`
   - Show action preview before execution:
     - Display action type (create spot, create list, add spot to list)
     - Display action parameters (spot name, list name, etc.)
     - Show what will happen (human-readable description)
   - Add undo/cancel options:
     - "Confirm" button (executes action)
     - "Cancel" button (cancels action)
     - "Preview" button (shows more details if needed)
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Responsive design
   - Accessibility support

2. Integrate with AICommandProcessor
   - Update _showConfirmationDialog() to use new widget
   - Ensure dialog shows before action execution
   - Handle user confirmation/cancellation

**Day 3: Action History UI**
3. Create `lib/presentation/pages/actions/action_history_page.dart`
   - Display recent actions:
     - List of executed actions (chronological order)
     - Action type and description
     - Timestamp for each action
     - Success/error status indicator
   - Undo functionality:
     - "Undo" button for each undoable action
     - Visual indicator for undoable vs non-undoable actions
     - Confirmation dialog before undo
   - Filtering and search:
     - Filter by action type
     - Filter by date range
     - Search by action description
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Responsive design
   - Accessibility support

4. Create `lib/presentation/widgets/actions/action_history_item_widget.dart`
   - Display single action item
   - Show action details
   - Undo button (if undoable)
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)

**Day 4-5: Error Handling UI**
5. Create `lib/presentation/widgets/common/action_error_dialog.dart`
   - Action failure dialogs:
     - Display error message (user-friendly)
     - Show action that failed
     - Explain what went wrong
   - Retry mechanisms:
     - "Retry" button (retries the action)
     - "Cancel" button (cancels and returns)
     - "View Details" button (shows technical details if needed)
   - User-friendly error messages:
     - Translate technical errors to user-friendly messages
     - Provide actionable guidance
     - Suggest alternatives if action cannot be completed
   - Use AppColors/AppTheme (100% adherence - NO direct Colors.* usage)
   - Responsive design
   - Accessibility support

6. Integrate Error Handling UI
   - Update _showErrorDialogWithRetry() to use new widget
   - Ensure error dialogs show after action failures
   - Handle retry logic
   - Update AICommandProcessor to use new error dialog

7. Final Integration & Polish
   - Ensure all UI components work together
   - Test action execution flow end-to-end
   - Test error handling flow
   - Test action history flow
   - Loading states
   - Empty states
   - Responsive design improvements
   - Accessibility improvements

## Deliverables

- ✅ ActionConfirmationDialog created
- ✅ ActionHistoryPage created
- ✅ ActionHistoryItemWidget created
- ✅ ActionErrorDialog created
- ✅ All UI components integrated
- ✅ Zero linter errors
- ✅ 100% AppColors/AppTheme adherence (NO direct Colors.* usage)
- ✅ Responsive and accessible
- ✅ All integrations working

## Quality Standards

- **Zero linter errors** (mandatory)
- **100% AppColors/AppTheme adherence** (NO direct Colors.* usage - will be flagged)
- **Follow existing UI patterns** (pages, widgets, navigation)
- **Responsive design** (mobile, tablet, desktop)
- **Accessibility** (semantic labels, keyboard navigation)
- **Philosophy alignment** (show doors, not badges)

## Dependencies

- ✅ Phase 6 (Local Expert System Redesign) COMPLETE
- ⏳ Agent 1 enhancing ActionHistoryService and AICommandProcessor (work in parallel)
- ✅ ActionExecutor exists
- ✅ ActionParser exists
- ✅ AICommandProcessor exists

## Integration Points

- **ActionHistoryService:** Load action history, undo actions
- **AICommandProcessor:** Show confirmation dialogs, error dialogs
- **ActionExecutor:** Execute actions, handle results

## Testing

- Agent 3 will create widget tests based on specifications (TDD approach)
- Verify your implementation matches the test specifications
- Tests will be written in parallel with your implementation

## Documentation

- Document UI components
- Document integration points
- Create completion report: `docs/agents/reports/agent_2/phase_7/week_33_agent_2_completion.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_7/week_33_task_assignments.md`
- Implementation Plan: `docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Design Tokens: `lib/core/theme/colors.dart` and `lib/core/theme/app_theme.dart`
- AICommandProcessor: `lib/presentation/widgets/common/ai_command_processor.dart`

**START WORK NOW.**
```

---

## 🧪 **Agent 3: Models & Testing**

### **Prompt for Agent 3:**

```
You are Agent 3: Models & Testing Specialist working on Phase 7, Week 33 (Action Execution UI & Integration).

## Context

**Phase:** Phase 7 - Feature Matrix Completion  
**Week:** Week 33 - Action Execution UI & Integration  
**Status:** Ready to Start  
**Dependencies:** Phase 6 (Local Expert System Redesign) COMPLETE, Agent 1 and Agent 2 creating services/UI

**What You're Testing:**
- ActionHistoryService - Action storage, retrieval, undo functionality
- Action Confirmation Dialog - Action preview, confirm/cancel
- Action History UI - Display actions, undo functionality
- Error Handling UI - Error messages, retry functionality
- LLM Integration - Action intent parsing, action execution

**Philosophy:**
- Users can execute actions via AI with proper confirmation
- Action history enables users to undo mistakes
- Clear error messages help users understand and recover

## Testing Workflow (TDD Approach)

**Follow the parallel testing workflow protocol:**
- Read `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- Write tests based on specifications (before or in parallel with implementation)
- Tests serve as specifications for Agent 1 and Agent 2
- Verify implementation matches test specifications

## Tasks

**Day 1: Review Models**
1. Review Action Models (`lib/core/ai/action_models.dart`)
   - Verify ActionIntent models (CreateSpotIntent, CreateListIntent, AddSpotToListIntent)
   - Verify ActionResult model
   - Verify action types and parameters
   - Check if models support undo functionality
   - Create additional models if needed (e.g., ActionHistoryEntry)

**Day 2-5: Tests & Documentation**
2. Create `test/unit/services/action_history_service_test.dart`
   - Test action storage
   - Test action retrieval
   - Test undo functionality
   - Test action history filtering
   - Test error handling

3. Create `test/widget/common/action_confirmation_dialog_test.dart`
   - Test dialog display
   - Test action preview
   - Test confirm/cancel buttons
   - Test accessibility

4. Create `test/widget/pages/actions/action_history_page_test.dart`
   - Test action history display
   - Test undo functionality
   - Test filtering and search
   - Test accessibility

5. Create `test/widget/common/action_error_dialog_test.dart`
   - Test error dialog display
   - Test retry functionality
   - Test error message display
   - Test accessibility

6. Create Integration Tests
   - Test end-to-end action execution flow
   - Test action confirmation flow
   - Test action history flow
   - Test error handling flow
   - Test undo flow

7. Documentation
   - Document ActionHistoryService (undo functionality)
   - Document Action Confirmation Dialog
   - Document Action History UI
   - Document Error Handling UI
   - Document LLM integration enhancements
   - Update system documentation

## Deliverables

- ✅ ActionHistoryService tests created
- ✅ Action Confirmation Dialog tests created
- ✅ Action History UI tests created
- ✅ Error Handling UI tests created
- ✅ Integration tests created
- ✅ Documentation complete
- ✅ All tests pass
- ✅ Test coverage > 90%

## Quality Standards

- **Comprehensive test coverage** (>90%)
- **Test edge cases** (error handling, boundary conditions)
- **Clear test names** (describe what is being tested)
- **Test organization** (group related tests)
- **Documentation** (test documentation, system documentation)

## Testing Workflow

**Follow TDD approach:**
1. Write tests based on specifications (before or in parallel with implementation)
2. Tests serve as specifications for Agent 1 and Agent 2
3. Verify implementation matches test specifications
4. Update tests if needed based on actual implementation

**Reference:** `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`

## Dependencies

- ✅ Phase 6 (Local Expert System Redesign) COMPLETE
- ⏳ Agent 1 enhancing ActionHistoryService and AICommandProcessor (work in parallel)
- ⏳ Agent 2 creating UI components (work in parallel)
- ✅ ActionExecutor exists
- ✅ ActionParser exists

## Documentation

- Document all models and services
- Document undo functionality
- Document UI components
- Document error handling
- Update system documentation
- Create completion report: `docs/agents/reports/agent_3/phase_7/week_33_action_execution_tests_documentation.md`

## Status Updates

- Update `docs/agents/status/status_tracker.md` with your progress
- Mark tasks as complete when done
- Report blockers immediately

## Reference

- Task Assignments: `docs/agents/tasks/phase_7/week_33_task_assignments.md`
- Implementation Plan: `docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`
- Philosophy: `docs/plans/philosophy_implementation/DOORS.md`
- Testing Workflow: `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`
- ActionExecutor: `lib/core/ai/action_executor.dart`
- ActionHistoryService: `lib/core/services/action_history_service.dart`

**START WORK NOW.**
```

---

## 📋 **Quick Reference**

### **Files to Create:**

**Agent 1:**
- `lib/core/services/action_error_handler.dart` (if needed)

**Agent 2:**
- `lib/presentation/widgets/common/action_confirmation_dialog.dart`
- `lib/presentation/pages/actions/action_history_page.dart`
- `lib/presentation/widgets/actions/action_history_item_widget.dart`
- `lib/presentation/widgets/common/action_error_dialog.dart`

**Agent 3:**
- `test/unit/services/action_history_service_test.dart`
- `test/widget/common/action_confirmation_dialog_test.dart`
- `test/widget/pages/actions/action_history_page_test.dart`
- `test/widget/common/action_error_dialog_test.dart`
- `test/integration/action_execution_integration_test.dart`

### **Files to Modify:**

**Agent 1:**
- `lib/core/services/action_history_service.dart` (add undo functionality)
- `lib/presentation/widgets/common/ai_command_processor.dart` (enhance integration)

**Agent 2:**
- `lib/presentation/widgets/common/ai_command_processor.dart` (integrate new dialogs)

---

## 🎯 **Success Criteria**

- ✅ All services enhanced and tested
- ✅ All UI components created
- ✅ Zero linter errors
- ✅ Test coverage > 90%
- ✅ Documentation complete
- ✅ Integration working
- ✅ Action Execution UI: 40% → 100%
- ✅ Integration: 60% → 100%

---

**Last Updated:** November 25, 2025  
**Status:** 🎯 Ready to Use

