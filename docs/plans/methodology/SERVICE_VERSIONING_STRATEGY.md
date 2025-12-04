# Service Versioning Strategy

**Created:** November 27, 2025  
**Status:** 🎯 **Active Strategy Document**  
**Purpose:** Prevent service conflicts when multiple phases modify the same services

---

## 🎯 **OVERVIEW**

This document defines how services are versioned, locked, and modified across Master Plan phases to prevent conflicts and breaking changes.

---

## 📋 **SERVICE LOCKING STRATEGY**

### **Service Lock States**

**🔒 LOCKED:**
- Service API cannot change (backward compatible changes only)
- Service interface is frozen
- Only bug fixes allowed, no new features
- Breaking changes NOT allowed

**🔓 UNLOCKED:**
- Service can be modified
- Breaking changes allowed (with migration path)
- New features can be added
- API changes allowed

### **Service Locking Matrix**

| Service | Phase 7 | Phase 7.3 (Security) | Phase 8 | Phase 9 | Phase 10 | Lock Status |
|---------|---------|----------------------|---------|---------|----------|-------------|
| `PaymentService` | 🔒 Locked | 🔒 Locked | 🔓 Unlocked | 🔒 Locked | 🔒 Locked | **Locked** (Phases 7, 7.3, 9, 10) |
| `BusinessService` | 🔒 Locked | 🔒 Locked | 🔓 Unlocked | 🔒 Locked | 🔒 Locked | **Locked** (Phases 7, 7.3, 9, 10) |
| `ExpertiseEventService` | 🔒 Locked | 🔒 Locked | 🔓 Unlocked | 🔒 Locked | 🔒 Locked | **Locked** (Phases 7, 7.3, 9, 10) |
| `PersonalityProfile` | 🔒 Locked | 🔒 **MODIFYING** | 🔒 Locked | 🔒 Locked | 🔒 Locked | **Locked** (Phase 7.3 modifying) |
| `PersonalityLearning` | 🔒 Locked | 🔒 Locked | 🔓 Unlocked | 🔒 Locked | 🔒 Locked | **Locked** (Phases 7, 7.3, 9, 10) |
| `RefundService` | 🔓 Unlocked | 🔓 Unlocked | 🔓 Unlocked | 🔒 Locked | 🔒 Locked | **Locked** (Phase 9) |
| `RevenueSplitService` | 🔒 Locked | 🔒 Locked | 🔓 Unlocked | 🔒 Locked | 🔒 Locked | **Locked** (Phases 7, 9) |
| `StripeService` | 🔒 Locked | 🔒 Locked | 🔓 Unlocked | 🔒 Locked | 🔒 Locked | **Locked** (Phases 7, 9, 10) |
| `StorageService` | 🔒 Locked | 🔒 Locked | 🔒 Locked | 🔒 Locked | 🔒 Locked | **Always Locked** (Core service) |
| `SupabaseService` | 🔒 Locked | 🔒 Locked | 🔒 Locked | 🔒 Locked | 🔒 Locked | **Always Locked** (Core service) |
| `AtomicClockService` | 🔓 Unlocked | 🔓 Unlocked | 🔓 Unlocked | 🔒 **CREATING** | 🔒 Locked | **Locked** (Phase 9 creating) |
| `ReservationService` | 🔓 Unlocked | 🔓 Unlocked | 🔓 Unlocked | 🔒 **CREATING** | 🔒 Locked | **Locked** (Phase 9 creating) |

### **Locking Rules**

1. **Service is LOCKED if:**
   - Any active phase uses it
   - Any dependent phase is in progress
   - Service is core infrastructure (StorageService, SupabaseService)

2. **Service is UNLOCKED if:**
   - No active phases use it
   - All dependent phases are complete
   - Service is new (being created)

3. **Service can be MODIFIED if:**
   - It's the phase's primary service (e.g., Phase 7.3 modifies PersonalityProfile)
   - All dependent phases are notified
   - Migration path provided

---

## 🔄 **SERVICE VERSIONING SYSTEM**

### **Version Numbering**

**Format:** `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes (requires migration)
- **MINOR:** New features (backward compatible)
- **PATCH:** Bug fixes (backward compatible)

### **Version History**

| Service | Current Version | Next Version | Breaking Changes | Migration Required |
|---------|----------------|--------------|------------------|-------------------|
| `PaymentService` | 1.0.0 | 1.1.0 | No | No |
| `BusinessService` | 1.0.0 | 1.1.0 | No | No |
| `PersonalityProfile` | 1.0.0 | 2.0.0 | **YES** (userId → agentId) | **YES** (Phase 7.3) |
| `PersonalityLearning` | 1.0.0 | 1.1.0 | No | No |
| `AtomicClockService` | N/A | 1.0.0 | N/A | N/A (New service) |
| `ReservationService` | N/A | 1.0.0 | N/A | N/A (New service) |

### **Version Compatibility**

- **v1.0.0 → v1.1.0:** ✅ Compatible (minor version)
- **v1.0.0 → v2.0.0:** ❌ Breaking (major version, requires migration)
- **v1.0.0 → v1.0.1:** ✅ Compatible (patch version)

---

## 📝 **SERVICE INTERFACE CONTRACTS**

### **Contract Requirements**

Each service MUST have:
1. **Public API documentation**
2. **Input/output specifications**
3. **Error handling documentation**
4. **Side effects documentation**
5. **Version number**

### **Example: PaymentService Contract**

```dart
/// PaymentService v1.0.0
/// 
/// Public API Contract:
/// - createPayment(): Creates payment intent
/// - processPayment(): Processes payment
/// - refundPayment(): Refunds payment
/// 
/// Breaking Changes:
/// - v1.0.0 → v2.0.0: userId → agentId (Phase 7.3)
/// 
/// Dependencies:
/// - StripeService v1.0.0
/// - RevenueSplitService v1.0.0
/// 
/// Locked During:
/// - Phase 7 (payment features)
/// - Phase 7.3 (security changes)
/// - Phase 9 (reservation payments)
/// - Phase 10 (test suite)
```

---

## 🚫 **BREAKING CHANGE PROTOCOL**

### **When Breaking Changes Are ALLOWED:**

1. **Service is UNLOCKED** (not in use by active phases)
2. **All dependent phases are complete**
3. **Migration path provided**
4. **Version number incremented (MAJOR)**
5. **Dependent services notified**

### **When Breaking Changes Are NOT ALLOWED:**

1. **Service is LOCKED** (in use by active phase)
2. **Dependent phase is in progress**
3. **No migration path available**
4. **Would break existing integrations**

### **Breaking Change Process:**

1. **Announce breaking change** (2 phases ahead)
2. **Create migration guide**
3. **Update service version** (MAJOR increment)
4. **Notify all dependent services**
5. **Provide backward compatibility** (if possible)
6. **Remove old API** (after 2 phases)

---

## 🔗 **SERVICE DEPENDENCY GRAPH**

### **Dependency Chains**

```
PaymentService
  ├─→ StripeService
  └─→ RevenueSplitService

BusinessService
  ├─→ StorageService
  └─→ SupabaseService

ExpertiseEventService
  ├─→ StorageService
  └─→ SupabaseService

ReservationService (Phase 9)
  ├─→ PaymentService
  ├─→ BusinessService
  ├─→ ExpertiseEventService
  ├─→ AtomicClockService
  ├─→ StorageService
  └─→ SupabaseService

PersonalityProfile (Phase 7.3)
  ├─→ AgentMappingService (Phase 7.3)
  └─→ StorageService
```

### **Dependency Rules**

1. **Core services** (StorageService, SupabaseService) have no dependencies
2. **Business services** depend on core services
3. **Feature services** depend on business services
4. **New services** (Phase 9) depend on existing services

---

## ✅ **INTEGRATION TESTING REQUIREMENTS**

### **When to Test Service Integrations:**

1. **After each phase that modifies services**
   - Phase 7.3 modifies PersonalityProfile → Test all integrations
   - Phase 9 creates ReservationService → Test all integrations

2. **Before phases that depend on services**
   - Phase 9 depends on PaymentService → Test PaymentService integration
   - Phase 9 depends on BusinessService → Test BusinessService integration

3. **Continuous integration tests**
   - Run integration tests on every commit
   - Test service contracts
   - Test breaking changes

### **Integration Test Coverage:**

- ✅ Service-to-service communication
- ✅ Service API contracts
- ✅ Error handling
- ✅ Data flow
- ✅ Performance

---

## 📊 **SERVICE STATUS TRACKING**

### **Service Status Matrix**

| Service | Status | Version | Locked By | Next Modification |
|---------|--------|---------|-----------|-------------------|
| `PaymentService` | 🔒 Locked | 1.0.0 | Phase 7, 9, 10 | After Phase 10 |
| `BusinessService` | 🔒 Locked | 1.0.0 | Phase 7, 9, 10 | After Phase 10 |
| `PersonalityProfile` | 🔒 Modifying | 1.0.0 → 2.0.0 | Phase 7.3 | Phase 7.3 (userId → agentId) |
| `AtomicClockService` | 🔒 Creating | N/A → 1.0.0 | Phase 9 | Phase 9 (new service) |
| `ReservationService` | 🔒 Creating | N/A → 1.0.0 | Phase 9 | Phase 9 (new service) |

---

## 🎯 **IMPLEMENTATION GUIDELINES**

### **For Phase Implementers:**

1. **Check service locking status** before modifying services
2. **Use service interfaces** (not direct implementations)
3. **Test service integrations** after modifications
4. **Document breaking changes** if any
5. **Notify dependent services** of changes

### **For Service Creators:**

1. **Define service interface** first
2. **Document service contract** completely
3. **Version service** from start (v1.0.0)
4. **Test service integrations** before release
5. **Lock service** during dependent phases

---

## 📝 **NEXT STEPS**

1. ✅ **Service locking matrix created**
2. ✅ **Service versioning system defined**
3. ✅ **Service dependency graph created**
4. ⏳ **Update Master Plan** with service locking information
5. ⏳ **Create service interface contracts** for all services
6. ⏳ **Add integration testing** to Phase 10

---

**Last Updated:** November 27, 2025  
**Status:** 🎯 **Active Strategy - Ready for Implementation**

