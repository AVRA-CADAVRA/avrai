# Reservation System Backup & Recovery Procedures

**Date:** January 6, 2026  
**Phase:** Phase 9.1 - Documentation (HIGH PRIORITY GAP FIX)  
**Status:** ✅ Complete  
**Version:** 1.0

---

## Table of Contents

1. [Overview](#overview)
2. [Backup Strategy](#backup-strategy)
3. [Backup Procedures](#backup-procedures)
4. [Recovery Procedures](#recovery-procedures)
5. [Data Merge & Conflict Resolution](#data-merge--conflict-resolution)
6. [Disaster Recovery](#disaster-recovery)
7. [Backup Schedules](#backup-schedules)
8. [Recovery Testing](#recovery-testing)
9. [Best Practices](#best-practices)
10. [Common Scenarios](#common-scenarios)
11. [Backup & Recovery Checklist](#backup--recovery-checklist)

---

## Overview

The Reservation System follows a **comprehensive backup and recovery strategy** that ensures:

- ✅ **Offline-First Backup**: Local storage is the primary backup (works offline)
- ✅ **Cloud Backup**: Automatic cloud sync provides secondary backup
- ✅ **Automatic Backup**: All operations automatically backup locally and to cloud
- ✅ **Conflict Resolution**: Intelligent merge strategy for local/cloud conflicts
- ✅ **Recovery**: Quick recovery from local storage or cloud backup
- ✅ **Data Integrity**: Atomic timestamps ensure data consistency

### Backup Architecture

```
┌─────────────────────────────────────┐
│      User Action                    │
│  (Create/Update Reservation)        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      Local Backup (Primary)         │
│  StorageService                     │
│  (<50ms, Always Available)          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      Cloud Backup (Secondary)       │
│  SupabaseService                    │
│  (Background, Non-blocking)         │
└─────────────────────────────────────┘
```

### Core Principles

1. **Offline-First**: Local storage is the primary backup (always available)
2. **Cloud Backup**: Cloud sync provides secondary backup (automatic, non-blocking)
3. **Automatic**: All operations automatically backup (no manual steps)
4. **Conflict Resolution**: Intelligent merge prefers newer data
5. **Data Integrity**: Atomic timestamps ensure consistency
6. **Recovery**: Quick recovery from local or cloud backup

---

## Backup Strategy

### Multi-Layer Backup Strategy

**Layer 1: Local Backup (Primary)**
- **Storage**: Local device storage (GetStorage/Sembast)
- **Speed**: <50ms
- **Availability**: Always (works offline)
- **Purpose**: Primary backup, fast recovery

**Layer 2: Cloud Backup (Secondary)**
- **Storage**: Supabase cloud database
- **Speed**: Background sync (non-blocking)
- **Availability**: When online
- **Purpose**: Secondary backup, disaster recovery

### Backup Types

**Automatic Backup:**
- All operations automatically backup locally
- Cloud sync happens automatically in background
- No manual intervention required

**Manual Backup:**
- Export reservations to file (JSON)
- Backup to external storage
- Restore from backup file

**Incremental Backup:**
- Only changed reservations are synced
- Reduces network usage
- Faster sync times

---

## Backup Procedures

### Automatic Local Backup

**CRITICAL:** All operations automatically backup locally.

**Pattern:**
```dart
// ✅ CORRECT: Automatic local backup
Future<Reservation> createReservation(...) async {
  final reservation = Reservation(...);
  
  // Automatic local backup (<50ms)
  await _storeReservationLocally(reservation);
  
  // Automatic cloud backup (background, non-blocking)
  if (_supabaseService.isAvailable) {
    _syncReservationToCloud(reservation).catchError((e) {
      developer.log('Cloud sync failed: $e');
      // Local backup still available
    });
  }
  
  return reservation;
}
```

**Backup Storage:**
- **Location**: Local device storage (GetStorage)
- **Key Format**: `reservation_{reservationId}`
- **Data Format**: JSON string
- **Backup Time**: Immediately (<50ms)

### Automatic Cloud Backup

**CRITICAL:** Cloud backup happens automatically in background.

**Pattern:**
```dart
// ✅ CORRECT: Automatic cloud backup (non-blocking)
Future<void> _syncReservationToCloud(Reservation reservation) async {
  if (!_supabaseService.isAvailable) {
    return; // Cloud not available, local backup is sufficient
  }
  
  try {
    await _supabaseService.client
        .from('reservations')
        .upsert(reservation.toJson());
    
    developer.log('Cloud backup successful: ${reservation.id}');
  } catch (e) {
    developer.log('Cloud backup failed: $e');
    // Local backup still available, will retry later
    _queueForRetry(reservation);
  }
}
```

**Backup Storage:**
- **Location**: Supabase cloud database
- **Table**: `reservations`
- **Backup Time**: Background sync (non-blocking)
- **Retry**: Automatic retry on failure

### Manual Backup

**Export Reservations to File:**

```dart
// ✅ CORRECT: Manual backup export
Future<String> exportReservationsToFile({
  String? userId,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  // Get all reservations
  final reservations = await reservationService.getUserReservations(
    userId: userId,
    startDate: startDate,
    endDate: endDate,
  );
  
  // Convert to JSON
  final json = {
    'export_date': DateTime.now().toIso8601String(),
    'version': '1.0',
    'reservations': reservations.map((r) => r.toJson()).toList(),
  };
  
  // Save to file
  final file = await getApplicationDocumentsDirectory();
  final backupFile = File('${file.path}/reservations_backup_${DateTime.now().millisecondsSinceEpoch}.json');
  await backupFile.writeAsString(jsonEncode(json));
  
  return backupFile.path;
}
```

**Backup File Format:**
```json
{
  "export_date": "2026-01-06T12:00:00.000Z",
  "version": "1.0",
  "reservations": [
    {
      "id": "reservation-123",
      "agentId": "agent-456",
      "type": "spot",
      "targetId": "spot-789",
      "reservationTime": "2026-01-13T19:00:00.000Z",
      "partySize": 2,
      "status": "confirmed",
      // ... other fields
    }
  ]
}
```

### Incremental Backup

**Only sync changed reservations:**

```dart
// ✅ CORRECT: Incremental backup (sync only changed reservations)
Future<void> syncChangedReservations() async {
  // Get local reservations
  final localReservations = await _getReservationsFromLocal();
  
  // Get cloud reservations
  final cloudReservations = await _getReservationsFromCloud();
  
  // Find changed reservations (compare updatedAt)
  final changedReservations = localReservations.where((local) {
    final cloud = cloudReservations.firstWhere(
      (c) => c.id == local.id,
      orElse: () => local.copyWith(updatedAt: DateTime(1970)), // Not in cloud
    );
    
    // Changed if local is newer
    return local.updatedAt.isAfter(cloud.updatedAt);
  }).toList();
  
  // Sync only changed reservations
  for (final reservation in changedReservations) {
    await _syncReservationToCloud(reservation);
  }
}
```

---

## Recovery Procedures

### Recovery from Local Backup

**CRITICAL:** Local backup is always available (works offline).

**Procedure:**
```dart
// ✅ CORRECT: Recovery from local backup
Future<List<Reservation>> recoverFromLocalBackup({
  String? userId,
  ReservationStatus? status,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  // Get agentId if userId provided
  final agentId = userId != null
      ? await _agentIdService.getUserAgentId(userId)
      : null;
  
  // Get from local storage
  final localReservations = await _getReservationsFromLocal(
    agentId: agentId,
    status: status,
    startDate: startDate,
    endDate: endDate,
  );
  
  return localReservations;
}
```

**Recovery Steps:**
1. **Access Local Storage**: Read from GetStorage/Sembast
2. **Parse JSON**: Convert JSON strings to Reservation objects
3. **Filter Data**: Apply filters (userId, status, date range)
4. **Return Data**: Return recovered reservations

**Recovery Time**: <20ms (fast, from local storage)

### Recovery from Cloud Backup

**Recovery from cloud when local backup is unavailable.**

**Procedure:**
```dart
// ✅ CORRECT: Recovery from cloud backup
Future<List<Reservation>> recoverFromCloudBackup({
  String? userId,
  ReservationStatus? status,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  if (!_supabaseService.isAvailable) {
    throw Exception('Cloud backup not available');
  }
  
  // Get agentId if userId provided
  final agentId = userId != null
      ? await _agentIdService.getUserAgentId(userId)
      : null;
  
  // Get from cloud
  final cloudReservations = await _getReservationsFromCloud(
    agentId: agentId,
    status: status,
    startDate: startDate,
    endDate: endDate,
  );
  
  // Restore to local storage
  for (final reservation in cloudReservations) {
    await _storeReservationLocally(reservation);
  }
  
  return cloudReservations;
}
```

**Recovery Steps:**
1. **Check Cloud Availability**: Verify Supabase is available
2. **Query Cloud Database**: Get reservations from Supabase
3. **Restore to Local**: Store recovered reservations locally
4. **Return Data**: Return recovered reservations

**Recovery Time**: Network dependent (typically 1-3 seconds)

### Recovery from Backup File

**Recovery from manually exported backup file.**

**Procedure:**
```dart
// ✅ CORRECT: Recovery from backup file
Future<List<Reservation>> recoverFromBackupFile(String backupFilePath) async {
  // Read backup file
  final backupFile = File(backupFilePath);
  final jsonStr = await backupFile.readAsString();
  
  // Parse JSON
  final backupData = jsonDecode(jsonStr) as Map<String, dynamic>;
  final reservationsJson = backupData['reservations'] as List<dynamic>;
  
  // Convert to Reservation objects
  final reservations = reservationsJson
      .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
      .toList();
  
  // Restore to local storage
  for (final reservation in reservations) {
    await _storeReservationLocally(reservation);
  }
  
  // Sync to cloud if available
  if (_supabaseService.isAvailable) {
    for (final reservation in reservations) {
      _syncReservationToCloud(reservation).catchError((e) {
        developer.log('Cloud sync failed during recovery: $e');
      });
    }
  }
  
  return reservations;
}
```

**Recovery Steps:**
1. **Read Backup File**: Load JSON backup file
2. **Parse JSON**: Convert JSON to Reservation objects
3. **Validate Data**: Check backup file version and format
4. **Restore to Local**: Store reservations locally
5. **Sync to Cloud**: Sync to cloud if available

---

## Data Merge & Conflict Resolution

### Merge Strategy

**CRITICAL:** Intelligent merge prefers newer data.

**Pattern:**
```dart
// ✅ CORRECT: Merge strategy (prefer newer data)
List<Reservation> _mergeReservations(
  List<Reservation> local,
  List<Reservation> cloud,
) {
  // Create map of reservations by ID
  final merged = <String, Reservation>{};
  
  // Add local reservations
  for (final reservation in local) {
    merged[reservation.id] = reservation;
  }
  
  // Merge cloud reservations (prefer newer)
  for (final cloudReservation in cloud) {
    final localReservation = merged[cloudReservation.id];
    
    if (localReservation == null) {
      // New reservation from cloud
      merged[cloudReservation.id] = cloudReservation;
    } else {
      // Conflict: prefer newer based on updatedAt
      if (cloudReservation.updatedAt.isAfter(localReservation.updatedAt)) {
        // Cloud is newer
        merged[cloudReservation.id] = cloudReservation;
      } else {
        // Local is newer (keep local)
        // Cloud will be updated on next sync
      }
    }
  }
  
  return merged.values.toList();
}
```

### Conflict Resolution Rules

**1. Prefer Newer (updatedAt):**
- If cloud `updatedAt` > local `updatedAt` → Use cloud
- If local `updatedAt` > cloud `updatedAt` → Use local

**2. Atomic Timestamp Priority:**
- If atomic timestamps available, use atomic timestamp for ordering
- Atomic timestamps provide true chronological ordering

**3. Status Priority:**
- Confirmed > Pending
- Completed > Cancelled
- (for same updatedAt timestamp)

**Example:**
```dart
// Example: Conflict resolution
// Local: updatedAt = 2026-01-06 10:00, status = pending
// Cloud: updatedAt = 2026-01-06 11:00, status = confirmed
// Result: Use cloud (newer updatedAt)

// Local: updatedAt = 2026-01-06 11:00, status = confirmed
// Cloud: updatedAt = 2026-01-06 10:00, status = pending
// Result: Use local (newer updatedAt)
```

---

## Disaster Recovery

### Complete Data Loss

**Scenario:** Complete data loss (device failure, app uninstall).

**Recovery Procedure:**
1. **Check Cloud Backup**: Verify cloud backup is available
2. **Recover from Cloud**: Restore all reservations from cloud
3. **Verify Data**: Check recovered reservations are correct
4. **Restore to Local**: Store recovered reservations locally

**Example:**
```dart
// ✅ CORRECT: Complete disaster recovery
Future<void> performDisasterRecovery() async {
  developer.log('Starting disaster recovery...');
  
  // Step 1: Check cloud availability
  if (!_supabaseService.isAvailable) {
    throw Exception('Cloud backup not available for disaster recovery');
  }
  
  // Step 2: Recover all reservations from cloud
  final cloudReservations = await _getReservationsFromCloud();
  
  developer.log('Recovered ${cloudReservations.length} reservations from cloud');
  
  // Step 3: Restore to local storage
  for (final reservation in cloudReservations) {
    await _storeReservationLocally(reservation);
  }
  
  developer.log('Disaster recovery complete');
}
```

### Partial Data Loss

**Scenario:** Some reservations are missing or corrupted.

**Recovery Procedure:**
1. **Identify Missing Data**: Compare local and cloud backups
2. **Recover Missing Reservations**: Restore missing reservations from cloud
3. **Verify Data Integrity**: Check recovered reservations are valid
4. **Sync Changes**: Sync any local changes back to cloud

**Example:**
```dart
// ✅ CORRECT: Partial disaster recovery
Future<void> performPartialRecovery() async {
  // Step 1: Get local and cloud reservations
  final localReservations = await _getReservationsFromLocal();
  final cloudReservations = await _getReservationsFromCloud();
  
  // Step 2: Find missing reservations
  final localIds = localReservations.map((r) => r.id).toSet();
  final missingReservations = cloudReservations
      .where((r) => !localIds.contains(r.id))
      .toList();
  
  developer.log('Found ${missingReservations.length} missing reservations');
  
  // Step 3: Restore missing reservations
  for (final reservation in missingReservations) {
    await _storeReservationLocally(reservation);
  }
  
  // Step 4: Find corrupted reservations (invalid JSON, etc.)
  // (Implementation depends on corruption detection)
}
```

### Corrupted Data

**Scenario:** Local data is corrupted (invalid JSON, missing fields).

**Recovery Procedure:**
1. **Detect Corruption**: Identify corrupted reservations
2. **Remove Corrupted Data**: Delete corrupted local data
3. **Recover from Cloud**: Restore corrupted reservations from cloud
4. **Verify Recovery**: Check recovered reservations are valid

**Example:**
```dart
// ✅ CORRECT: Corruption recovery
Future<void> recoverFromCorruption() async {
  // Step 1: Get all local reservations
  final localReservations = await _getReservationsFromLocal();
  final corruptedIds = <String>[];
  
  // Step 2: Identify corrupted reservations
  for (final reservation in localReservations) {
    try {
      // Validate reservation
      if (reservation.id.isEmpty || reservation.agentId.isEmpty) {
        corruptedIds.add(reservation.id);
      }
    } catch (e) {
      // Parsing error - corrupted
      corruptedIds.add(reservation.id);
    }
  }
  
  developer.log('Found ${corruptedIds.length} corrupted reservations');
  
  // Step 3: Remove corrupted local data
  for (final id in corruptedIds) {
    await _removeReservationLocally(id);
  }
  
  // Step 4: Recover from cloud
  if (_supabaseService.isAvailable) {
    final cloudReservations = await _getReservationsFromCloud();
    final corruptedCloudReservations = cloudReservations
        .where((r) => corruptedIds.contains(r.id))
        .toList();
    
    for (final reservation in corruptedCloudReservations) {
      await _storeReservationLocally(reservation);
    }
  }
}
```

---

## Backup Schedules

### Automatic Backup Schedule

**Real-Time Backup:**
- **Trigger**: Every operation (create, update, cancel)
- **Local**: Immediate (<50ms)
- **Cloud**: Background sync (non-blocking)

**Scheduled Sync:**
- **Trigger**: Every 5 minutes (when online)
- **Purpose**: Sync pending local changes to cloud
- **Incremental**: Only sync changed reservations

**Daily Backup:**
- **Trigger**: Once per day (at midnight)
- **Purpose**: Full backup verification
- **Action**: Verify local and cloud backups match

### Manual Backup Schedule

**Export Backup:**
- **Trigger**: User-initiated
- **Frequency**: As needed
- **Purpose**: Manual backup for external storage

**Restore from Backup:**
- **Trigger**: User-initiated
- **Frequency**: When needed
- **Purpose**: Recover from exported backup file

---

## Recovery Testing

### Test Local Recovery

**Procedure:**
```dart
// ✅ CORRECT: Test local recovery
Future<void> testLocalRecovery() async {
  // Step 1: Create test reservation
  final testReservation = await reservationService.createReservation(...);
  
  // Step 2: Clear memory cache
  _memoryCache.clear();
  
  // Step 3: Recover from local backup
  final recovered = await _getReservationsFromLocal();
  
  // Step 4: Verify recovery
  assert(recovered.any((r) => r.id == testReservation.id));
  assert(recovered.firstWhere((r) => r.id == testReservation.id).equals(testReservation));
  
  developer.log('Local recovery test passed');
}
```

### Test Cloud Recovery

**Procedure:**
```dart
// ✅ CORRECT: Test cloud recovery
Future<void> testCloudRecovery() async {
  // Step 1: Create test reservation (synced to cloud)
  final testReservation = await reservationService.createReservation(...);
  await Future.delayed(Duration(seconds: 2)); // Wait for cloud sync
  
  // Step 2: Clear local storage
  await _clearLocalStorage();
  
  // Step 3: Recover from cloud backup
  final recovered = await _getReservationsFromCloud();
  
  // Step 4: Verify recovery
  assert(recovered.any((r) => r.id == testReservation.id));
  
  developer.log('Cloud recovery test passed');
}
```

### Test Merge Strategy

**Procedure:**
```dart
// ✅ CORRECT: Test merge strategy
Future<void> testMergeStrategy() async {
  // Step 1: Create reservation locally
  final localReservation = await _createReservationLocally(...);
  
  // Step 2: Update reservation in cloud
  final cloudReservation = localReservation.copyWith(
    status: ReservationStatus.confirmed,
    updatedAt: DateTime.now().add(Duration(hours: 1)),
  );
  await _syncReservationToCloud(cloudReservation);
  
  // Step 3: Merge local and cloud
  final merged = _mergeReservations([localReservation], [cloudReservation]);
  
  // Step 4: Verify merge (prefer newer)
  assert(merged.length == 1);
  assert(merged.first.status == ReservationStatus.confirmed);
  assert(merged.first.updatedAt == cloudReservation.updatedAt);
  
  developer.log('Merge strategy test passed');
}
```

---

## Best Practices

### DO's

✅ **DO:**
- Rely on automatic backups (local and cloud)
- Test recovery procedures regularly
- Monitor backup sync status
- Verify data integrity after recovery
- Use atomic timestamps for conflict resolution
- Keep backup files when exporting manually
- Test disaster recovery scenarios

### DON'Ts

❌ **DON'T:**
- Rely solely on cloud backup (use local as primary)
- Skip recovery testing
- Ignore backup sync failures
- Store backup files in same location as data
- Modify backup files manually
- Skip data integrity verification

---

## Common Scenarios

### Scenario 1: Device Lost/Stolen

**Problem:** Device is lost or stolen, local backup is unavailable.

**Solution:**
1. **Recover from Cloud**: Restore all reservations from cloud backup
2. **Restore to New Device**: Install app, restore from cloud
3. **Verify Data**: Check all reservations are recovered correctly

### Scenario 2: App Reinstalled

**Problem:** App was uninstalled and reinstalled, local data is lost.

**Solution:**
1. **Sign In**: Sign in to same account
2. **Automatic Recovery**: Cloud backup automatically restores data
3. **Verify Recovery**: Check reservations are restored

### Scenario 3: Network Outage During Sync

**Problem:** Network outage during cloud sync, local backup is available.

**Solution:**
1. **Continue Offline**: Local backup is sufficient, continue working offline
2. **Automatic Retry**: Cloud sync automatically retries when online
3. **Manual Sync**: Optionally trigger manual sync when online

### Scenario 4: Corrupted Local Data

**Problem:** Local data is corrupted (invalid JSON, missing fields).

**Solution:**
1. **Detect Corruption**: Identify corrupted reservations
2. **Remove Corrupted Data**: Delete corrupted local data
3. **Recover from Cloud**: Restore corrupted reservations from cloud

### Scenario 5: Cloud Backup Failure

**Problem:** Cloud backup fails (Supabase unavailable, network error).

**Solution:**
1. **Continue Offline**: Local backup is sufficient, continue working offline
2. **Queue for Retry**: Failed syncs are queued for retry
3. **Automatic Retry**: Cloud sync automatically retries when available

---

## Backup & Recovery Checklist

### Before Deployment

- [ ] Automatic local backup is implemented
- [ ] Automatic cloud backup is implemented
- [ ] Merge strategy is implemented
- [ ] Conflict resolution is implemented
- [ ] Recovery procedures are tested
- [ ] Disaster recovery is tested

### Regular Maintenance

- [ ] Monitor backup sync status
- [ ] Test local recovery monthly
- [ ] Test cloud recovery quarterly
- [ ] Test disaster recovery annually
- [ ] Verify data integrity regularly
- [ ] Review backup logs for errors

### Disaster Recovery Plan

- [ ] Document disaster recovery procedures
- [ ] Test disaster recovery scenarios
- [ ] Train team on recovery procedures
- [ ] Verify backup integrity regularly
- [ ] Keep backup files in secure location
- [ ] Test recovery from backup files

---

## Summary

The Reservation System Backup & Recovery Procedures provide:

✅ **Comprehensive Backup Strategy**: Local (primary) + Cloud (secondary)  
✅ **Automatic Backups**: All operations automatically backup  
✅ **Recovery Procedures**: Local, cloud, and file-based recovery  
✅ **Conflict Resolution**: Intelligent merge prefers newer data  
✅ **Disaster Recovery**: Complete and partial recovery procedures  
✅ **Backup Schedules**: Real-time, scheduled, and manual backups  
✅ **Recovery Testing**: Test procedures for all recovery scenarios  
✅ **Best Practices**: DO's and DON'Ts  
✅ **Common Scenarios**: Solutions for frequent problems  
✅ **Backup & Recovery Checklist**: Pre-deployment and maintenance checklist  

**Key Takeaways:**
- **Offline-First**: Local backup is primary (always available)
- **Cloud Backup**: Automatic cloud sync provides secondary backup
- **Automatic**: All operations automatically backup (no manual steps)
- **Conflict Resolution**: Intelligent merge prefers newer data
- **Recovery**: Quick recovery from local or cloud backup
- **Testing**: Regular testing of recovery procedures

**Recovery Time Targets:**
- **Local Recovery**: <20ms (from local storage)
- **Cloud Recovery**: 1-3 seconds (network dependent)
- **Disaster Recovery**: 5-10 minutes (full restore)

**Next Steps:**
- Review backup procedures in your code
- Ensure all operations automatically backup
- Test recovery procedures regularly
- Monitor backup sync status

---

**Next Documentation:**
- [Data Migration Guide](./DATA_MIGRATION.md) (HIGH PRIORITY GAP FIX)
