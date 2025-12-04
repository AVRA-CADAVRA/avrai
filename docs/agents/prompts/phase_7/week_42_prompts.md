# Phase 7 Agent Prompts - Feature Matrix Completion (Section 42 / 7.4.4)

**Date:** November 30, 2025, 1:51 PM CST  
**Purpose:** Ready-to-use prompts for agents working on Phase 7, Section 42 (7.4.4) (Integration Improvements - Service Integration Patterns & System Optimization)  
**Status:** 🎯 **READY TO USE**

---

## 🚨 **CRITICAL: Before Starting**

**All agents MUST read these documents BEFORE starting:**

1. ✅ **`docs/agents/REFACTORING_PROTOCOL.md`** - **MANDATORY** - Documentation organization protocol
2. ✅ **`docs/agents/tasks/phase_7/week_42_task_assignments.md`** - **MANDATORY** - Detailed task assignments
3. ✅ **`docs/plans/philosophy_implementation/DOORS.md`** - **MANDATORY** - Core philosophy
4. ✅ **`docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`** - **MANDATORY** - Philosophy alignment
5. ✅ **`docs/plans/feature_matrix/FEATURE_MATRIX_COMPLETION_PLAN.md`** - Detailed implementation plan
6. ✅ **`docs/plans/methodology/SERVICE_VERSIONING_STRATEGY.md`** - Service versioning strategy
7. ✅ **`docs/MASTER_PLAN_RISK_ANALYSIS.md`** - Service dependency risks
8. ✅ **`docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md`** - Testing workflow (Agent 3)

**Protocol Requirements:**
- ✅ **Status Tracker:** Update `docs/agents/status/status_tracker.md` (SINGLE FILE - shared across all phases)
- ✅ **Reports:** Create in `docs/agents/reports/agent_X/phase_7/week_42_*.md` (organized by agent, then phase)
- ✅ **Reference Guides:** Use `docs/agents/reference/quick_reference.md` (shared across all phases)

---

## 🎯 **Section 42 (7.4.4) Overview**

**Focus:** Integration Improvements - Service Integration Patterns & System Optimization  
**Duration:** 5 days  
**Priority:** 🟡 HIGH (Integration Improvements)  
**Note:** Improve service integration patterns, standardize error handling, optimize performance, and improve cross-service communication. This section focuses on improving how services work together, not creating new features.

**What Doors Does This Open?**
- **Consistency Doors:** Standardized patterns make codebase easier to maintain
- **Performance Doors:** Optimized services provide faster responses
- **Reliability Doors:** Consistent error handling improves system reliability
- **Maintainability Doors:** Standardized patterns reduce technical debt
- **Testing Doors:** Integration tests ensure services work together correctly

**Philosophy Alignment:**
- Consistent patterns (standardized service integration)
- Performance optimization (faster, more efficient)
- Reliability (consistent error handling)
- Maintainability (reduced technical debt)

**Current Status:**
- ⚠️ Service dependency injection patterns inconsistent
- ⚠️ Error handling patterns vary across services
- ⚠️ Performance bottlenecks may exist
- ⚠️ Cross-service communication needs improvement
- ✅ Core services exist and are functional
- ✅ Section 41 (Backend Completion) COMPLETE

**Dependencies:**
- ✅ Section 33-41 COMPLETE
- ✅ Core services exist and are functional
- ✅ Service dependencies are available

---

## 🔧 **Agent 1: Backend & Integration Specialist**

### **Your Context**

You are working on **Phase 7, Section 42 (7.4.4): Integration Improvements - Service Integration Patterns & System Optimization**.

**Your Focus:** Service Integration Patterns & Performance Optimization

**Current State:** Services work but have inconsistent patterns. You need to:
1. Standardize service dependency injection patterns
2. Improve error handling consistency
3. Optimize performance bottlenecks
4. Improve cross-service communication

### **Your Tasks**

**Day 1-2: Service Integration Pattern Standardization**

1. **Review Service Dependency Injection Patterns**
   - Review all services in `lib/core/services/`
   - Identify patterns:
     - Constructor injection (preferred)
     - GetIt.instance (acceptable but less testable)
     - Direct instantiation (needs improvement)
   - Document current patterns
   - Create standardization plan

2. **Standardize Service Dependency Injection**
   - Update services to use consistent dependency injection pattern
   - Prefer constructor injection over GetIt.instance where possible
   - Ensure services are testable (mockable dependencies)
   - Document service dependencies clearly
   - Maintain backward compatibility where possible

**Day 3: Error Handling Consistency**

1. **Review Error Handling Patterns**
   - Review error handling across all services
   - Identify inconsistent patterns:
     - Error types used
     - Error messages
     - Error logging
     - Error recovery
   - Document current patterns

2. **Standardize Error Handling**
   - Create consistent error handling pattern
   - Standardize error messages (user-friendly, actionable)
   - Ensure all services use try-catch with proper logging
   - Add error recovery mechanisms where appropriate
   - Use AppLogger consistently

**Day 4: Performance Optimization**

1. **Identify Performance Bottlenecks**
   - Review service methods for inefficient queries
   - Identify N+1 query patterns
   - Identify memory leaks or excessive memory usage
   - Review database query patterns
   - Use performance monitoring tools if available

2. **Optimize Performance**
   - Optimize database queries (batch queries, indexes)
   - Reduce N+1 query patterns
   - Add caching where appropriate (be careful with cache invalidation)
   - Optimize memory usage (remove unnecessary data retention)
   - Add performance logging/monitoring

**Day 5: Service Communication Improvements**

1. **Improve Cross-Service Communication**
   - Review service-to-service communication patterns
   - Ensure services use proper interfaces
   - Add service communication error handling
   - Document service dependencies and communication patterns
   - Ensure services handle missing dependencies gracefully

### **Key Files to Reference**

- All service files in `lib/core/services/`
- `docs/plans/methodology/SERVICE_VERSIONING_STRATEGY.md` - Service versioning strategy
- `docs/MASTER_PLAN_RISK_ANALYSIS.md` - Service dependency risks

### **Success Criteria**

- ✅ Service dependency injection standardized
- ✅ Error handling consistent across services
- ✅ Performance bottlenecks identified and optimized
- ✅ Service communication patterns improved
- ⚠️ Zero linter errors (some minor warnings may remain)

### **Deliverables**

- Modified service files (standardized patterns)
- Performance optimization improvements
- Error handling improvements
- Documentation of service patterns
- Completion report: `docs/agents/reports/agent_1/phase_7/week_42_completion_report.md`

---

## 🎨 **Agent 2: Frontend & UX Specialist**

### **Your Context**

You are working on **Phase 7, Section 42 (7.4.4): Integration Improvements - Service Integration Patterns & System Optimization**.

**Your Focus:** UI Integration Improvements & Error Handling Consistency

**Current State:** UI components work but have inconsistent patterns. You need to:
1. Standardize UI error handling
2. Standardize loading states
3. Optimize UI performance

### **Your Tasks**

**Day 1-2: UI Error Handling Consistency**

1. **Review UI Error Handling Patterns**
   - Review error handling in all UI components
   - Identify inconsistent patterns:
     - Error message formats
     - Error state displays
     - Retry mechanisms
   - Document current patterns

2. **Standardize UI Error Handling**
   - Create consistent error message format
   - Standardize error state widgets
   - Ensure all async operations have error handling
   - Add retry mechanisms where appropriate
   - Use AppColors/AppTheme (100% design token compliance)

**Day 3: Loading State Consistency**

1. **Review Loading State Patterns**
   - Review loading states across all UI components
   - Identify inconsistent patterns:
     - Loading indicators
     - Loading messages
     - Loading placement
   - Document current patterns

2. **Standardize Loading States**
   - Create consistent loading indicator pattern
   - Standardize loading messages
   - Ensure all async operations show loading states
   - Use AppColors/AppTheme

**Day 4-5: UI Performance Optimization**

1. **Identify UI Performance Issues**
   - Review widget rebuild patterns
   - Identify unnecessary rebuilds
   - Review list rendering performance
   - Review image loading and caching

2. **Optimize UI Performance**
   - Add const constructors where possible
   - Use RepaintBoundary for complex widgets
   - Optimize list rendering (ListView.builder, itemExtent)
   - Optimize image loading and caching
   - Add performance monitoring

### **Key Files to Reference**

- UI components with error handling
- UI components with loading states
- Performance-critical widgets

### **Success Criteria**

- ✅ Error handling consistent across UI
- ✅ Loading states consistent across UI
- ✅ UI performance optimized
- ✅ Zero linter errors
- ✅ 100% design token compliance

### **Deliverables**

- Modified UI components (standardized patterns)
- Performance optimizations
- Completion report: `docs/agents/reports/agent_2/phase_7/week_42_completion_report.md`

---

## 🧪 **Agent 3: Models & Testing Specialist**

### **Your Context**

You are working on **Phase 7, Section 42 (7.4.4): Integration Improvements - Service Integration Patterns & System Optimization**.

**Your Focus:** Integration Tests & Performance Tests

**Current State:** Services work but integration between services needs testing. You need to:
1. Create integration tests for service-to-service communication
2. Create performance tests
3. Create error handling tests

### **Your Tasks**

**Day 1-2: Integration Tests**

1. **Create Service Integration Tests**
   - Create test file: `test/integration/service_integration_test.dart`
   - Test service-to-service communication
   - Test service dependency injection
   - Test error propagation between services
   - Test service communication error handling

2. **Create Cross-Service Integration Tests**
   - Test PaymentService → TaxComplianceService integration
   - Test GeographicScopeService → LargeCityService integration
   - Test ExpertRecommendationsService → MultiPathExpertiseService integration
   - Test other critical service integrations

**Day 3: Performance Tests**

1. **Create Performance Tests**
   - Create test file: `test/performance/service_performance_test.dart`
   - Test service method performance (response times)
   - Test database query performance
   - Test memory usage patterns
   - Test concurrent service calls

**Day 4-5: Error Handling Tests**

1. **Create Error Handling Tests**
   - Create test file: `test/integration/error_handling_integration_test.dart`
   - Test error propagation
   - Test error recovery mechanisms
   - Test error message consistency
   - Test error state handling

### **Key Files to Reference**

- `docs/agents/protocols/PARALLEL_TESTING_WORKFLOW.md` - Testing workflow protocol
- Existing integration test files
- Service implementation files

### **Success Criteria**

- ✅ Integration tests created
- ✅ Performance tests created
- ✅ Error handling tests created
- ✅ Test coverage >80% for integration points
- ✅ All tests passing

### **Deliverables**

- Test files (integration, performance, error handling)
- Completion report: `docs/agents/reports/agent_3/phase_7/week_42_completion_report.md`

---

## 📚 **General Guidelines for All Agents**

### **Code Quality Standards**

- ✅ **Zero linter errors** (mandatory)
- ✅ **100% design token compliance** (AppColors/AppTheme only - NO direct Colors.*)
- ✅ **Comprehensive error handling** (all async operations)
- ✅ **Proper logging** (use AppLogger or developer.log)
- ✅ **Performance optimization** (efficient queries, minimal memory usage)

### **Standardization Principles**

- ✅ **Consistency over perfection** - Standardize existing patterns, don't rewrite everything
- ✅ **Backward compatibility** - Maintain existing functionality while improving patterns
- ✅ **Documentation** - Document all pattern changes
- ✅ **Testing** - Ensure all changes are testable

### **Testing Requirements**

- ✅ **Agent 3:** Create comprehensive tests for integration points
- ✅ **Test coverage:** >80% for integration points
- ✅ **All tests must pass** before completion
- ✅ **Follow parallel testing workflow** protocol

### **Documentation Requirements**

- ✅ **Completion reports:** Required for all agents
- ✅ **Status tracker updates:** Update `docs/agents/status/status_tracker.md`
- ✅ **Follow refactoring protocol:** `docs/agents/REFACTORING_PROTOCOL.md`

---

## ✅ **Section 42 (7.4.4) Completion Checklist**

### **Agent 1:**
- [ ] Service dependency injection standardized
- [ ] Error handling consistent across services
- [ ] Performance bottlenecks identified and optimized
- [ ] Service communication patterns improved
- [ ] Zero linter errors
- [ ] Completion report created

### **Agent 2:**
- [ ] Error handling consistent across UI
- [ ] Loading states consistent across UI
- [ ] UI performance optimized
- [ ] 100% design token compliance verified
- [ ] Zero linter errors
- [ ] Completion report created

### **Agent 3:**
- [ ] Integration tests created
- [ ] Performance tests created
- [ ] Error handling tests created
- [ ] Test coverage >80%
- [ ] All tests passing
- [ ] Test documentation complete
- [ ] Completion report created

---

**Status:** 🎯 **READY TO USE**  
**Next:** Agents start work on Section 42 (7.4.4) tasks

