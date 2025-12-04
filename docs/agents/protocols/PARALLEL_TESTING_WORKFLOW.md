# Parallel Testing Workflow Protocol

**Date:** November 24, 2025  
**Purpose:** Define the workflow for parallel work between implementation agents (Agent 1) and testing agents (Agent 3)  
**Status:** 🎯 **ACTIVE PROTOCOL**

---

## 🎯 **Overview**

This protocol enables **true parallel work** between implementation and testing agents using a **Test-Driven Development (TDD)** approach. Tests are written based on specifications first, then verified against actual implementation.

---

## 📊 **Workflow Model**

### **Visual Workflow Diagram**

```
┌─────────────────────────────────────────────────────────────────┐
│                    WEEK START (Day 1)                            │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐        │
│  │   AGENT 1 (Backend)   │      │  AGENT 3 (Testing)   │        │
│  │                       │      │                      │        │
│  │  Reads:               │      │  Reads:              │        │
│  │  • Task assignments   │      │  • Task assignments  │        │
│  │  • Implementation plan│      │  • Implementation    │        │
│  │  • Requirements docs   │      │    plan              │        │
│  │                       │      │  • Requirements docs │        │
│  └──────────────────────┘      └──────────────────────┘        │
│           │                              │                        │
│           │                              │                        │
│           ▼                              ▼                        │
│  ┌──────────────────────┐      ┌──────────────────────┐        │
│  │  Starts Implementation│      │  Starts Test Writing  │        │
│  │  (Days 1-3)           │      │  (Days 1-3)          │        │
│  │                       │      │                      │        │
│  │  • Creates service    │      │  • Creates models     │        │
│  │  • Implements logic   │      │  • Writes tests      │        │
│  │  • Follows spec       │      │    based on spec      │        │
│  │                       │      │  • Tests serve as    │        │
│  │                       │      │    specification     │        │
│  └──────────────────────┘      └──────────────────────┘        │
│           │                              │                        │
│           │                              │                        │
│           │         PARALLEL WORK        │                        │
│           │         (No waiting)        │                        │
│           │                              │                        │
└───────────┼──────────────────────────────┼────────────────────────┘
            │                              │
            │                              │
            ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              AGENT 1 COMPLETES (Day 3-4)                        │
│                                                                   │
│  ┌──────────────────────┐                                       │
│  │  Implementation Done │                                       │
│  │  • Service created   │                                       │
│  │  • Logic implemented │                                       │
│  │  • Code committed    │                                       │
│  └──────────────────────┘                                       │
│           │                                                      │
│           │  Signals completion                                 │
│           │  (Status tracker, completion report)                 │
│           │                                                      │
└───────────┼──────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│         AGENT 3 VERIFICATION PHASE (Day 4-5)                   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Step 1: Review Implementation                            │   │
│  │  • Read actual service code                               │   │
│  │  • Compare with test expectations                         │   │
│  │  • Identify any differences                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│           │                                                      │
│           ▼                                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Step 2: Run Tests                                        │   │
│  │  • Execute test suite                                      │   │
│  │  • Check which tests pass                                  │   │
│  │  • Identify which tests fail                                │   │
│  └──────────────────────────────────────────────────────────┘   │
│           │                                                      │
│           ▼                                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Step 3: Update Tests (if needed)                        │   │
│  │  • Update tests to match implementation                   │   │
│  │  • OR: Update implementation if tests reveal issues        │   │
│  │  • Ensure all tests pass                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│           │                                                      │
│           ▼                                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Step 4: Final Verification                                │   │
│  │  • All tests pass                                          │   │
│  │  • Test coverage > 90%                                    │   │
│  │  • Documentation complete                                  │   │
│  │  • Mark complete in status tracker                         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 🔄 **Detailed Step-by-Step Protocol**

### **Phase 1: Parallel Work (Days 1-3)**

#### **Agent 1 (Backend/Implementation):**
1. **Read Specifications**
   - Task assignments document
   - Implementation plan
   - Requirements documentation
   - Existing codebase patterns

2. **Start Implementation**
   - Create service file
   - Implement methods based on spec
   - Follow existing patterns
   - Add comprehensive error handling

3. **Work Independently**
   - **DO NOT** wait for tests
   - **DO** follow specifications closely
   - **DO** document as you go

#### **Agent 3 (Testing):**
1. **Read Specifications**
   - Same task assignments document
   - Same implementation plan
   - Same requirements documentation
   - Existing test patterns

2. **Start Test Writing**
   - Create test file
   - Write tests based on specifications
   - Use existing test patterns
   - Mock dependencies appropriately

3. **Work Independently**
   - **DO NOT** wait for implementation
   - **DO** write tests as specification
   - **DO** document test expectations

---

### **Phase 2: Implementation Completion (Day 3-4)**

#### **Agent 1 Actions:**
1. **Complete Implementation**
   - All methods implemented
   - Zero linter errors
   - Code follows patterns
   - Documentation added

2. **Signal Completion**
   - Update status tracker: "Implementation complete"
   - Create completion report
   - Commit code
   - Notify (via status tracker)

---

### **Phase 3: Test Verification (Day 4-5)**

#### **Agent 3 Actions:**

**Step 1: Review Implementation**
```dart
// Agent 3 reads actual implementation
// Example: lib/core/services/event_matching_service.dart

// Compare with test expectations:
// - Method signatures match?
// - Return types match?
// - Behavior matches spec?
```

**Step 2: Run Tests**
```bash
# Execute test suite
flutter test test/unit/services/event_matching_service_test.dart

# Expected outcomes:
# ✅ Some tests pass (implementation matches spec)
# ⚠️ Some tests fail (implementation differs from spec)
```

**Step 3: Update Tests (if needed)**
```dart
// Scenario A: Implementation matches spec
// ✅ Tests pass - No changes needed

// Scenario B: Implementation differs (but is correct)
// Update tests to match actual implementation:
test('should calculate matching score', () async {
  // Update test to match actual method signature/behavior
  final score = await service.calculateMatchingScore(
    expert: expert,
    user: user,
    category: 'food',
    locality: 'San Francisco',
  );
  expect(score, isA<double>());
  expect(score, greaterThanOrEqualTo(0.0));
  expect(score, lessThanOrEqualTo(1.0));
});

// Scenario C: Implementation has issues
// Report to Agent 1 or fix if minor
```

**Step 4: Final Verification**
- ✅ All tests pass
- ✅ Test coverage > 90%
- ✅ Documentation complete
- ✅ Update status tracker: "Testing complete"

---

## 📋 **Coordination Points**

### **Shared Resources:**
1. **Task Assignments Document**
   - Single source of truth for requirements
   - Both agents read same document
   - Updates tracked in status tracker

2. **Status Tracker**
   - Agent 1 marks: "Implementation complete"
   - Agent 3 marks: "Testing in progress" → "Testing complete"
   - Both can see each other's progress

3. **Implementation Plan**
   - Detailed requirements
   - Method signatures (if specified)
   - Expected behavior

### **Communication Protocol:**
1. **No Direct Communication Needed**
   - Status tracker is communication channel
   - Completion reports document decisions
   - Code is self-documenting

2. **If Issues Arise:**
   - Agent 3 documents in completion report
   - Agent 1 reviews and fixes (if needed)
   - Or: Agent 3 updates tests (if implementation is correct)

---

## ✅ **Success Criteria**

### **Phase 1 Success (Parallel Work):**
- ✅ Agent 1: Implementation started, following spec
- ✅ Agent 3: Tests written, based on spec
- ✅ Both working independently, no blocking

### **Phase 2 Success (Implementation Complete):**
- ✅ Agent 1: Code complete, zero errors, documented
- ✅ Status tracker updated
- ✅ Completion report created

### **Phase 3 Success (Testing Complete):**
- ✅ Agent 3: All tests pass
- ✅ Test coverage > 90%
- ✅ Tests match actual implementation
- ✅ Documentation complete

---

## 🎯 **Key Principles**

### **1. Tests as Specification**
- Tests define expected behavior
- Agent 1 can reference tests to understand requirements
- Tests serve dual purpose: spec + verification

### **2. No Waiting**
- Agent 3 does NOT wait for Agent 1
- Both work in parallel from Day 1
- Maximum efficiency

### **3. Verification, Not Waiting**
- Agent 3 verifies tests after implementation
- Updates tests if implementation differs (and is correct)
- Updates implementation if tests reveal issues

### **4. Specification-Based**
- Both agents read same specifications
- Tests written from spec, not from code
- Implementation follows spec

---

## 📝 **Example: Week 26 EventMatchingService**

### **Day 1-3: Parallel Work**

**Agent 1:**
```dart
// Creates: lib/core/services/event_matching_service.dart
class EventMatchingService {
  Future<double> calculateMatchingScore({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String category,
    required String locality,
  }) async {
    // Implementation based on spec
  }
}
```

**Agent 3:**
```dart
// Creates: test/unit/services/event_matching_service_test.dart
test('should calculate matching score', () async {
  // Test written based on spec (not waiting for implementation)
  final score = await service.calculateMatchingScore(
    expert: expert,
    user: user,
    category: 'food',
    locality: 'San Francisco',
  );
  expect(score, isA<double>());
  expect(score, greaterThanOrEqualTo(0.0));
  expect(score, lessThanOrEqualTo(1.0));
});
```

### **Day 4: Agent 1 Completes**
- ✅ Implementation done
- ✅ Status tracker: "Implementation complete"
- ✅ Completion report created

### **Day 5: Agent 3 Verifies**
1. **Review:** Reads `event_matching_service.dart`
2. **Run:** `flutter test test/unit/services/event_matching_service_test.dart`
3. **Result:** Tests pass (implementation matches spec) ✅
4. **Final:** Update status tracker, create completion report

---

## ⚠️ **Common Scenarios**

### **Scenario 1: Tests Pass Immediately**
- ✅ Implementation matches spec perfectly
- ✅ No test updates needed
- ✅ Fastest path to completion

### **Scenario 2: Tests Fail, Implementation Correct**
- ⚠️ Implementation differs from spec (but is correct)
- ✅ Agent 3 updates tests to match implementation
- ✅ Document why tests were updated

### **Scenario 3: Tests Reveal Issues**
- ⚠️ Tests fail, revealing implementation issues
- ✅ Agent 3 documents in completion report
- ✅ Agent 1 fixes implementation (if needed)
- ✅ Or: Agent 3 fixes if minor

### **Scenario 4: Spec Ambiguity**
- ⚠️ Spec is unclear
- ✅ Agent 3 writes tests based on best interpretation
- ✅ Agent 1 implements based on best interpretation
- ✅ Both document decisions in completion reports
- ✅ If mismatch: Coordinate via status tracker/completion reports

---

## 🔧 **Tools & Resources**

### **For Agent 1 (Implementation):**
- Task assignments document
- Implementation plan
- Requirements documentation
- Existing service patterns
- Status tracker (update progress)

### **For Agent 3 (Testing):**
- Same task assignments document
- Same implementation plan
- Same requirements documentation
- Existing test patterns
- Test templates (if available)
- Status tracker (update progress)

---

## 📊 **Timeline Example**

### **Week 26: EventMatchingService**

| Day | Agent 1 (Backend) | Agent 3 (Testing) |
|-----|-------------------|-------------------|
| **Day 1** | Start implementation | Start test writing |
| **Day 2** | Continue implementation | Continue test writing |
| **Day 3** | Complete implementation | Complete test writing |
| **Day 4** | ✅ Mark complete | Review implementation |
| **Day 5** | - | Run tests, verify, update if needed |

**Total Time:** 5 days (3 days parallel + 2 days verification)

---

## ✅ **Checklist**

### **Agent 1 (Before Starting):**
- [ ] Read task assignments
- [ ] Read implementation plan
- [ ] Understand requirements
- [ ] Review existing patterns

### **Agent 3 (Before Starting):**
- [ ] Read task assignments
- [ ] Read implementation plan
- [ ] Understand requirements
- [ ] Review existing test patterns

### **Agent 1 (During Work):**
- [ ] Follow specifications
- [ ] Write clean, documented code
- [ ] Update status tracker
- [ ] Create completion report

### **Agent 3 (During Work):**
- [ ] Write tests based on spec
- [ ] Use existing test patterns
- [ ] Document test expectations
- [ ] Update status tracker

### **Agent 3 (After Agent 1 Completes):**
- [ ] Review actual implementation
- [ ] Run test suite
- [ ] Update tests if needed
- [ ] Verify all tests pass
- [ ] Check test coverage
- [ ] Create completion report

---

## 🎯 **Summary**

**The Protocol:**
1. **Both agents start Day 1** (parallel work)
2. **Agent 1 implements** based on spec
3. **Agent 3 writes tests** based on spec
4. **Agent 1 completes** and signals completion
5. **Agent 3 verifies** tests against implementation
6. **Agent 3 updates** tests if needed
7. **Both mark complete** when done

**Key Benefit:** Maximum parallelization with minimal coordination overhead.

---

**Last Updated:** November 24, 2025  
**Status:** 🎯 Active Protocol

