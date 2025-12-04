# Phase 7 Agent Prompts - Feature Matrix Completion (Section 41 / 7.4.3)

**Date:** November 30, 2025, 12:05 PM CST  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Section 41 (7.4.3) (Backend Completion - Placeholder Methods & Incomplete Implementations)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_41_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`** - Detailed implementation plan
6. ✅ **`docs/plans/ai2ai_system/AI2AI_SYSTEM_STATUS.md`** - AI2AI system status
7. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_41_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Section 41 (7.4.3) Overview**

**Focus:** Backend Completion - Placeholder Methods & Incomplete Implementations  
**Duration:** 5 days  
**Priority:** 🟡 HIGH (Backend Completion)  
**Note:** Complete remaining backend placeholder methods that return empty lists, null values, or hardcoded placeholders. Implement real logic for database queries, service integrations, and analysis methods.

**What Doors Does This Open?**
- **Complete Backend Doors:** All placeholder methods have real implementations
- **Database Integration Doors:** Services can query real data
- **Service Integration Doors:** Services properly integrate with dependencies
- **Production Readiness Doors:** Backend is closer to production-ready
- **Testing Doors:** Comprehensive test coverage for backend methods

**Philosophy Alignment:**
- Complete implementations (no placeholders)
- Real data integration (database queries)
- Service integration (proper dependencies)
- Production readiness (fully functional backend)

**Current Status:**
- ⚠️ Many methods return empty lists/null/placeholders
- ⚠️ Database queries not implemented
- ⚠️ Service dependencies not integrated
- ⚠️ Analysis methods return hardcoded values
- ✅ Core services exist and are functional
- ✅ Models and data structures are defined

**Dependencies:**
- ✅ Section 33 (Action Execution UI) COMPLETE
- ✅ Section 34 (Device Discovery UI) COMPLETE
- ✅ Section 35 (LLM Full Integration) COMPLETE
- ✅ Section 36 (Federated Learning UI) COMPLETE
- ✅ Section 37 (AI Self-Improvement Visibility) COMPLETE
- ✅ Section 38 (AI2AI Learning Methods UI) COMPLETE
- ✅ Section 39 (Continuous Learning UI) COMPLETE
- ✅ Section 40 (Advanced Analytics UI) COMPLETE
- ✅ Core services exist and are functional

---

## 🔧 **Agent 1: Backend & Integration Specialist**

### **Your Context**

You are working on **Phase 7, Section 41 (7.4.3): Backend Completion - Placeholder Methods & Incomplete Implementations**.

**Your Focus:** Complete Placeholder Methods in Core Services

**Current State:** Many backend methods return empty lists, null values, or hardcoded placeholders. You need to:
1. Review and identify placeholder methods
2. Implement real logic for database queries
3. Integrate service dependencies
4. Complete analysis methods

### **Your Tasks**

**Day 1-2: AI2AI Learning Placeholder Methods**

1. **Review AI2AI Learning Methods**
   - Review `lib/core/ai/ai2ai_learning.dart`
   - Check methods: `_extractDimensionInsights()`, `_extractPreferenceInsights()`, `_extractExperienceInsights()`, `_identifyOptimalLearningPartners()`, `_generateLearningTopics()`, `_recommendDevelopmentAreas()`
   - **IMPORTANT:** Some of these methods may already be implemented. Verify first by reading the code.
   - If already implemented, document in completion report
   - If not implemented, implement real logic

2. **Complete Remaining Placeholder Methods (if any)**
   - For each method that needs implementation:
     - Extract insights from chat messages using keyword matching and pattern analysis
     - Identify optimal learning partners based on personality compatibility
     - Generate learning topics based on weak dimensions and learning patterns
     - Recommend development areas based on personality gaps
   - Follow existing code patterns in the file
   - Add proper error handling and logging

**Day 3: Tax Compliance Service Placeholders**

1. **Complete `_getUserEarnings()` Method**
   - Review `lib/core/services/tax_compliance_service.dart`
   - Integrate with PaymentService (inject dependency if needed)
   - Query payments for user in tax year
   - Filter successful payments
   - Sum payment amounts
   - Return total earnings
   - Add error handling and logging

2. **Complete `_getUsersWithEarningsAbove600()` Method**
   - Query database for users with earnings >= $600
   - Use efficient query (aggregate if possible)
   - Return list of user IDs
   - Add error handling and logging

**Day 4: Geographic Scope Service Placeholders**

1. **Complete Geographic Query Methods**
   - Review `lib/core/services/geographic_scope_service.dart`
   - Complete methods:
     - `_getLocalitiesInCity()` - Query localities in a city (use LargeCityService for large cities)
     - `_getCitiesInState()` - Query cities in a state
     - `_getLocalitiesInState()` - Query localities in a state
     - `_getCitiesInNation()` - Query cities in a nation
     - `_getLocalitiesInNation()` - Query localities in a nation
   - Integrate with database or location service
   - Use Supabase client or service layer for queries
   - Add error handling and logging

**Day 5: Expert Recommendations Service Placeholders**

1. **Complete Expert Recommendations Methods**
   - Review `lib/core/services/expert_recommendations_service.dart`
   - Complete methods:
     - `_getExpertSpotsForCategory()` - Query expert's lists and reviews, filter by category
     - `_getExpertCuratedListsForCategory()` - Query lists curated by expert, filter by category
     - `_getTopExpertSpots()` - Query top-rated spots in category
     - `_getLocalExpertiseForUser()` - Integrate with MultiPathExpertiseService, query LocalExpertise
   - Integrate with appropriate services
   - Add error handling and logging

### **Key Files to Reference**

- `lib/core/ai/ai2ai_learning.dart` - AI2AI learning service
- `lib/core/services/tax_compliance_service.dart` - Tax compliance service
- `lib/core/services/geographic_scope_service.dart` - Geographic scope service
- `lib/core/services/expert_recommendations_service.dart` - Expert recommendations service
- `lib/core/services/payment_service.dart` - Payment service (dependency)
- `lib/core/services/multi_path_expertise_service.dart` - Multi-path expertise service (dependency)
- `lib/core/services/large_city_detection_service.dart` - Large city service (dependency)

### **Success Criteria**

- ✅ All placeholder methods reviewed
- ✅ Remaining placeholders completed with real implementations
- ✅ Database queries integrated where needed
- ✅ Service dependencies properly integrated
- ⚠️ Zero linter errors (some minor warnings may remain)

### **Deliverables**

- Modified service files with completed placeholder methods
- Completion report: `docs/agents/reports/agent_1/phase_7/week_41_completion_report.md`

---

## 🎨 **Agent 2: Frontend & UX Specialist**

### **Your Context**

You are working on **Phase 7, Section 41 (7.4.3): Backend Completion - Placeholder Methods & Incomplete Implementations**.

**Your Focus:** Verify No Frontend Impact

**Current State:** This is a backend-only section. You need to verify that backend changes don't break existing UI.

### **Your Tasks**

**Day 1-5: No Frontend Work Required**

1. **Verify No Frontend Impact**
   - Review completed backend methods from Agent 1
   - Verify no UI changes needed
   - Test existing UI to ensure no regressions
   - Document any UI implications (if any)

**Note:** This is a backend-only section. Your main task is to verify that backend changes don't break existing UI, but no new UI work is required.

### **Success Criteria**

- ✅ No UI regressions
- ✅ Existing UI continues to work with completed backend methods

### **Deliverables**

- Verification report: `docs/agents/reports/agent_2/phase_7/week_41_completion_report.md`

---

## 🧪 **Agent 3: Models & Testing Specialist**

### **Your Context**

You are working on **Phase 7, Section 41 (7.4.3): Backend Completion - Placeholder Methods & Incomplete Implementations**.

**Your Focus:** Create Tests for Completed Backend Methods

**Current State:** Backend methods are being completed. You need to create comprehensive tests for all completed methods.

### **Your Tasks**

**Day 1-2: Test AI2AI Learning Methods**

1. **Create Tests for AI2AI Learning Methods**
   - Create test file: `test/services/ai2ai_learning_placeholder_methods_test.dart`
   - Test all completed methods:
     - `_extractDimensionInsights()` - Test with various message types
     - `_extractPreferenceInsights()` - Test with preference indicators
     - `_extractExperienceInsights()` - Test with experience keywords
     - `_identifyOptimalLearningPartners()` - Test with various personalities
     - `_generateLearningTopics()` - Test with weak dimensions
     - `_recommendDevelopmentAreas()` - Test with personality gaps
   - Test edge cases (empty messages, null values, missing data)
   - Test with various input combinations

**Day 3: Test Tax Compliance Methods**

1. **Create Tests for Tax Compliance Methods**
   - Create test file: `test/services/tax_compliance_placeholder_methods_test.dart`
   - Test `_getUserEarnings()` method:
     - Test with various user IDs and years
     - Test with successful payments
     - Test with no payments
     - Test with zero earnings
   - Test `_getUsersWithEarningsAbove600()` method:
     - Test with various years
     - Test with users above/below threshold
     - Test with no users

**Day 4: Test Geographic Scope Methods**

1. **Create Tests for Geographic Scope Methods**
   - Create test file: `test/services/geographic_scope_placeholder_methods_test.dart`
   - Test all geographic query methods:
     - `_getLocalitiesInCity()` - Test with various cities (including large cities)
     - `_getCitiesInState()` - Test with various states
     - `_getLocalitiesInState()` - Test with various states
     - `_getCitiesInNation()` - Test with various nations
     - `_getLocalitiesInNation()` - Test with various nations
   - Test edge cases (unknown cities, empty states, invalid locations)

**Day 5: Test Expert Recommendations Methods**

1. **Create Tests for Expert Recommendations Methods**
   - Create test file: `test/services/expert_recommendations_placeholder_methods_test.dart`
   - Test all expert recommendation methods:
     - `_getExpertSpotsForCategory()` - Test with various experts and categories
     - `_getExpertCuratedListsForCategory()` - Test with various experts and categories
     - `_getTopExpertSpots()` - Test with various categories
     - `_getLocalExpertiseForUser()` - Test with various users and categories
   - Test edge cases (no experts, empty categories, missing expertise)

### **Key Files to Reference**

- `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md` - Testing workflow protocol
- Existing test files for similar services
- Service implementation files for understanding expected behavior

### **Success Criteria**

- ✅ Tests created for all completed methods
- ✅ Test coverage >80% for new implementations
- ✅ All tests passing
- ✅ Edge cases covered
- ✅ Test documentation complete

### **Deliverables**

- Test files for all completed methods
- Completion report: `docs/agents/reports/agent_3/phase_7/week_41_completion_report.md`

---

## 📚 **General Guidelines for All Agents**

### **Code Quality Standards**

- ✅ **Zero linter errors** (mandatory)
- ✅ **Comprehensive error handling** (all async operations, database queries)
- ✅ **Proper logging** (use developer.log or service logger)
- ✅ **Service dependency injection** (don't create services directly)
- ✅ **Database query efficiency** (use proper queries, avoid N+1)

### **Implementation Patterns**

- ✅ **Follow existing code patterns** in each service
- ✅ **Use service layer** for database queries (don't query directly)
- ✅ **Inject dependencies** (use constructor injection or GetIt)
- ✅ **Add error handling** (try-catch blocks, proper error messages)
- ✅ **Add logging** (log important operations, errors, warnings)

### **Testing Requirements**

- ✅ **Agent 3:** Create comprehensive tests for all completed methods
- ✅ **Test coverage:** >80% for all new code
- ✅ **All tests must pass** before completion
- ✅ **Follow parallel testing workflow** protocol

### **Documentation Requirements**

- ✅ **Completion reports:** Required for all agents
- ✅ **Status tracker updates:** Update `docs/agents/status/status_tracker.md`
- ✅ **Follow refactoring protocol:** `docs/agents/REFACTORING_PROTOCOL.md`

---

## ✅ **Section 41 (7.4.3) Completion Checklist**

### **Agent 1:**
- [ ] AI2AI learning methods reviewed and completed (if needed)
- [ ] Tax compliance methods completed
- [ ] Geographic scope methods completed
- [ ] Expert recommendations methods completed
- [ ] Database queries integrated
- [ ] Service dependencies integrated
- [ ] Zero linter errors
- [ ] Completion report created

### **Agent 2:**
- [ ] Backend changes reviewed
- [ ] UI regressions checked
- [ ] Existing UI verified working
- [ ] Verification report created

### **Agent 3:**
- [ ] AI2AI learning tests created
- [ ] Tax compliance tests created
- [ ] Geographic scope tests created
- [ ] Expert recommendations tests created
- [ ] Test coverage >80%
- [ ] All tests passing
- [ ] Test documentation complete
- [ ] Completion report created

---

**Status:** 🎯 **READY TO USE**  
**Next:** Agents start work on Section 41 (7.4.3) tasks

