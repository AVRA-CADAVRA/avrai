# Database Migration Ordering Sequence

**Created:** November 27, 2025  
**Status:** 🎯 **Active Migration Guide**  
**Purpose:** Define migration sequence to prevent database conflicts

---

## 🎯 **OVERVIEW**

This document defines the correct order for all database migrations across Master Plan phases to prevent conflicts, data loss, and deployment failures.

---

## 📋 **MIGRATION INVENTORY**

### **Phase 7.3 (Security Implementation) Migrations**

| Migration | Purpose | Dependencies | Breaking Changes |
|-----------|---------|--------------|------------------|
| `001_user_agent_mappings` | Create user-agent mapping table | None | No |
| `002_migrate_existing_users` | Generate agent IDs for existing users | 001 | No |
| `003_personality_profile_agent_id` | Update PersonalityProfile (userId → agentId) | 002 | **YES** |
| `004_anonymous_user` | Create AnonymousUser table | 001 | No |
| `005_encrypted_fields` | Add encrypted fields to tables | 003 | No |
| `006_rls_policies_update` | Update RLS policies for agentId | 003 | No |

### **Phase 9 (Reservation System) Migrations**

| Migration | Purpose | Dependencies | Breaking Changes |
|-----------|---------|--------------|------------------|
| `007_reservations` | Create reservations table | 002 (agentId) | No |
| `008_reservation_tickets` | Create reservation_tickets table | 007 | No |
| `009_reservation_user_data` | Create reservation_user_data table (for optional user data sharing) | 007 | No |
| `010_cancellation_policies` | Create cancellation_policies table | 007 | No |
| `011_seating_charts` | Create seating_charts table | 007 | No |
| `012_reservation_indexes` | Create indexes for reservations | 007-011 | No |

### **Phase 8 (Model Deployment) Migrations**

| Migration | Purpose | Dependencies | Breaking Changes |
|-----------|---------|--------------|------------------|
| `013_model_registry` | Create model registry table | None | No |
| `014_model_versions` | Create model versions table | 013 | No |
| `015_model_metrics` | Create model metrics table | 013 | No |

### **Existing Event System Migrations (Update Required)**

| Migration | Purpose | Dependencies | Breaking Changes |
|-----------|---------|--------------|------------------|
| `016_expertise_event_agent_id` | Update ExpertiseEvent (attendeeIds → attendeeAgentIds) | 002 | **YES** |
| `017_expertise_event_user_data` | Add attendeeUserData to ExpertiseEvent | 016 | No |
| `018_community_event_agent_id` | Update CommunityEvent (inherits from ExpertiseEvent) | 016 | **YES** |

---

## 🔗 **MIGRATION DEPENDENCY GRAPH**

```
001_user_agent_mappings (Phase 7.3)
  ↓
002_migrate_existing_users (Phase 7.3)
  ↓
003_personality_profile_agent_id (Phase 7.3) [BREAKING]
  ├─→ 004_anonymous_user (Phase 7.3)
  ├─→ 005_encrypted_fields (Phase 7.3)
  ├─→ 006_rls_policies_update (Phase 7.3)
  ├─→ 007_reservations (Phase 9) [MUST USE agentId]
  ├─→ 016_expertise_event_agent_id (Event System) [BREAKING]
  └─→ 018_community_event_agent_id (Event System) [BREAKING]

007_reservations (Phase 9)
  ├─→ 008_reservation_tickets (Phase 9)
  ├─→ 009_reservation_user_data (Phase 9)
  ├─→ 010_cancellation_policies (Phase 9)
  ├─→ 011_seating_charts (Phase 9)
  └─→ 012_reservation_indexes (Phase 9)

016_expertise_event_agent_id (Event System)
  ├─→ 017_expertise_event_user_data (Event System)
  └─→ 018_community_event_agent_id (Event System)

013_model_registry (Phase 8)
  ├─→ 014_model_versions (Phase 8)
  └─→ 015_model_metrics (Phase 8)
```

---

## 📅 **MIGRATION SEQUENCE**

### **Phase 1: Foundation (Phase 7.3 - Security)**

**Order:**
1. `001_user_agent_mappings` - Create mapping table (foundation)
2. `002_migrate_existing_users` - Generate agent IDs for existing users
3. `003_personality_profile_agent_id` - Update PersonalityProfile (BREAKING)
4. `004_anonymous_user` - Create AnonymousUser table
5. `005_encrypted_fields` - Add encrypted fields
6. `006_rls_policies_update` - Update RLS policies

**Timeline:** Weeks 39-46 (Phase 7.3)

**Critical:** Must complete before Phase 9 starts

---

### **Phase 2: Event System Updates (After Phase 7.3)**

**Order:**
7. `016_expertise_event_agent_id` - Update ExpertiseEvent (BREAKING)
8. `017_expertise_event_user_data` - Add attendeeUserData
9. `018_community_event_agent_id` - Update CommunityEvent (BREAKING)

**Timeline:** After Phase 7.3 completes, before Phase 9 starts

**Critical:** Event system must use agentId before reservations use events

---

### **Phase 3: Reservation System (Phase 9)**

**Order:**
10. `007_reservations` - Create reservations table (uses agentId)
11. `008_reservation_tickets` - Create reservation_tickets table
12. `009_reservation_user_data` - Create reservation_user_data table
13. `010_cancellation_policies` - Create cancellation_policies table
14. `011_seating_charts` - Create seating_charts table
15. `012_reservation_indexes` - Create indexes

**Timeline:** Weeks 1-15 (Phase 9)

**Critical:** Must use agentId (not userId) from start

---

### **Phase 4: Model Deployment (Phase 8)**

**Order:**
16. `013_model_registry` - Create model registry table
17. `014_model_versions` - Create model versions table
18. `015_model_metrics` - Create model metrics table

**Timeline:** Months 1-18 (Phase 8)

**Note:** Can run in parallel with Phase 9 (no conflicts)

---

## ⚠️ **CRITICAL MIGRATION RULES**

### **Rule 1: agentId Foundation First**
- **MUST complete:** `001_user_agent_mappings` and `002_migrate_existing_users` before any other migrations
- **Reason:** All subsequent migrations depend on agentId existing

### **Rule 2: PersonalityProfile Update Before Event Updates**
- **MUST complete:** `003_personality_profile_agent_id` before `016_expertise_event_agent_id`
- **Reason:** Event system may reference PersonalityProfile

### **Rule 3: Event Updates Before Reservations**
- **MUST complete:** `016_expertise_event_agent_id` before `007_reservations`
- **Reason:** Reservations reference events, events must use agentId

### **Rule 4: Reservations Use agentId from Start**
- **MUST use:** agentId (not userId) in `007_reservations` migration
- **Reason:** Prevents migration conflicts, ensures privacy

### **Rule 5: No Parallel Conflicting Migrations**
- **CANNOT run:** Migrations that modify same tables simultaneously
- **Example:** Cannot run `003_personality_profile_agent_id` and `016_expertise_event_agent_id` simultaneously if they conflict

---

## 🔄 **MIGRATION ROLLBACK PROCEDURES**

### **Rollback Strategy**

**For each migration:**
1. **Define rollback SQL** - Reverse migration changes
2. **Define rollback conditions** - When rollback is safe
3. **Define rollback testing** - Test rollback procedure
4. **Define data preservation** - Preserve data during rollback

### **Rollback Examples**

**Migration 003 (PersonalityProfile userId → agentId):**
```sql
-- Rollback: Revert agentId → userId
ALTER TABLE personality_profiles 
  RENAME COLUMN agent_id TO user_id;

-- Restore data from backup (if needed)
```

**Migration 007 (Reservations table):**
```sql
-- Rollback: Drop reservations table
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS reservation_tickets CASCADE;
DROP TABLE IF EXISTS reservation_user_data CASCADE;
```

### **Rollback Rules**

1. **Test rollback** before running migration
2. **Backup data** before migration
3. **Document rollback** procedure
4. **Verify data integrity** after rollback

---

## 🧪 **MIGRATION TESTING STRATEGY**

### **Testing Phases**

1. **Development Testing:**
   - Test migration on development database
   - Test rollback procedure
   - Verify data integrity

2. **Staging Testing:**
   - Test migration on staging database
   - Test with production-like data
   - Test performance impact

3. **Production Testing:**
   - Test migration on production database (during maintenance window)
   - Monitor performance
   - Verify data integrity

### **Testing Checklist**

- [ ] Migration runs successfully
- [ ] Rollback procedure works
- [ ] Data integrity maintained
- [ ] Performance acceptable
- [ ] No breaking changes (or migration path provided)
- [ ] All dependent services work
- [ ] Integration tests pass

---

## 🔒 **MIGRATION LOCKING MECHANISM**

### **Lock States**

**🔒 LOCKED:**
- Migration is running → No other migrations can run
- Migration is in testing → No conflicting migrations can start
- Migration failed → Must be fixed before retry

**🔓 UNLOCKED:**
- Migration is complete → Next migration can start
- Migration is rolled back → Can be retried after fix

### **Locking Rules**

1. **Sequential migrations** (with dependencies) must run in order
2. **Parallel migrations** (no dependencies) can run simultaneously
3. **Conflicting migrations** (same tables) cannot run simultaneously
4. **Failed migrations** must be fixed before retry

---

## 📊 **MIGRATION STATUS TRACKING**

### **Migration Status Matrix**

| Migration | Phase | Status | Dependencies | Blocking |
|-----------|-------|--------|--------------|----------|
| `001_user_agent_mappings` | 7.3 | ⏳ Pending | None | None |
| `002_migrate_existing_users` | 7.3 | ⏳ Pending | 001 | None |
| `003_personality_profile_agent_id` | 7.3 | ⏳ Pending | 002 | 016, 007 |
| `007_reservations` | 9 | ⏳ Pending | 002, 016 | None |
| `016_expertise_event_agent_id` | Event System | ⏳ Pending | 003 | 007 |

---

## 🎯 **IMPLEMENTATION GUIDELINES**

### **For Migration Creators:**

1. **Check dependencies** before creating migration
2. **Use agentId** (not userId) for new tables
3. **Test migration** on development database
4. **Document rollback** procedure
5. **Update this document** with new migration

### **For Migration Executors:**

1. **Check migration sequence** before running
2. **Verify dependencies** are complete
3. **Backup data** before migration
4. **Test rollback** procedure
5. **Monitor performance** during migration

---

## 📝 **NEXT STEPS**

1. ✅ **Migration inventory created**
2. ✅ **Migration dependency graph created**
3. ✅ **Migration sequence defined**
4. ⏳ **Create rollback procedures** for each migration
5. ⏳ **Create migration testing scripts**
6. ⏳ **Update Master Plan** with migration sequence

---

**Last Updated:** November 27, 2025  
**Status:** 🎯 **Active Migration Guide - Ready for Implementation**

**Critical:** Phase 7.3 migrations MUST complete before Phase 9 starts. Phase 9 MUST use agentId from start.

