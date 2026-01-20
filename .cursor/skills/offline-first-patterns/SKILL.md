---
name: offline-first-patterns
description: Enforces offline-first architecture patterns: Sembast database, local-first data sources, sync strategies, offline indicator. Use when implementing features, designing data flow, or ensuring offline functionality.
---

# Offline-First Patterns

## Core Principle

**All features must work offline.** Online features are enhancements, not requirements.

## Architecture Pattern

### Local-First Data Flow
```
User Action → Local Database → UI Update
              ↓ (background)
           Sync to Remote (when online)
```

**NOT:**
```
User Action → Remote API → UI Update (❌ Requires internet)
```

## Data Sources Pattern

### Local Data Source (Primary)
```dart
/// Local data source (Sembast database)
class SpotsLocalDataSource {
  final Database _database;
  
  Future<List<Spot>> getSpots() async {
    // Read from local database
    final store = stringMapStoreFactory.store('spots');
    final records = await store.find(_database);
    return records.map((record) => Spot.fromJson(record.value)).toList();
  }
  
  Future<void> saveSpot(Spot spot) async {
    // Save to local database
    final store = stringMapStoreFactory.store('spots');
    await store.record(spot.id).put(_database, spot.toJson());
  }
}
```

### Remote Data Source (Optional Enhancement)
```dart
/// Remote data source (optional sync)
class SpotsRemoteDataSource {
  Future<List<Spot>> getSpots() async {
    // Fetch from remote API (only when online)
    // Returns empty list if offline
  }
  
  Future<void> syncSpots(List<Spot> spots) async {
    // Sync to remote (background, when online)
  }
}
```

### Repository Pattern (Combines Both)
```dart
/// Repository: Local-first, remote sync
class SpotsRepositoryImpl implements SpotsRepository {
  final SpotsLocalDataSource _localDataSource;
  final SpotsRemoteDataSource? _remoteDataSource;
  
  @override
  Future<List<Spot>> getSpots() async {
    // Always read from local first (works offline)
    final localSpots = await _localDataSource.getSpots();
    
    // Sync from remote in background (if online)
    if (_remoteDataSource != null) {
      _syncInBackground();
    }
    
    return localSpots;
  }
  
  void _syncInBackground() async {
    try {
      final remoteSpots = await _remoteDataSource!.getSpots();
      // Update local database with remote data
      for (final spot in remoteSpots) {
        await _localDataSource.saveSpot(spot);
      }
    } catch (e) {
      // Silently fail - offline mode
    }
  }
}
```

## Sembast Database

### Initialization
```dart
/// Initialize Sembast database (offline-first storage)
class SembastDatabase {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Get application documents directory
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'spots.db');
    
    // Open database
    _database = await databaseFactoryIo.openDatabase(dbPath);
    return _database!;
  }
}
```

### Storage Service Pattern
```dart
/// Storage service using Sembast (offline-first)
class StorageService {
  final Database _database;
  
  Future<void> saveSpot(Spot spot) async {
    // Save to local database (always works)
    final store = stringMapStoreFactory.store('spots');
    await store.record(spot.id).put(_database, spot.toJson());
    
    // Queue for remote sync (if online)
    await _queueForSync(spot);
  }
  
  Future<Spot?> getSpot(String id) async {
    // Read from local database (always works)
    final store = stringMapStoreFactory.store('spots');
    final record = await store.record(id).get(_database);
    
    if (record == null) return null;
    return Spot.fromJson(record);
  }
}
```

## Offline Indicator

Show user when offline:

```dart
/// Offline indicator widget
class OfflineIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final isOnline = snapshot.data != ConnectivityResult.none;
        
        if (!isOnline) {
          return Container(
            color: AppColors.warning,
            child: Text(
              'Offline mode - changes will sync when online',
              style: TextStyle(color: AppColors.white),
            ),
          );
        }
        
        return SizedBox.shrink();
      },
    );
  }
}
```

## Sync Strategy

### Background Sync
```dart
/// Background sync service
class SyncService {
  final Database _database;
  final RemoteDataSource _remoteDataSource;
  
  Future<void> syncInBackground() async {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      return; // No sync if offline
    }
    
    // Sync pending changes
    await _syncPendingChanges();
    
    // Pull latest from remote
    await _pullLatestData();
  }
  
  Future<void> _syncPendingChanges() async {
    final pendingChanges = await _getPendingChanges();
    for (final change in pendingChanges) {
      try {
        await _remoteDataSource.syncChange(change);
        await _markSynced(change.id);
      } catch (e) {
        // Keep in queue for retry
      }
    }
  }
}
```

## Offline-First Checklist

- [ ] Feature works without internet connection
- [ ] Data stored locally (Sembast database)
- [ ] UI updates immediately (no waiting for network)
- [ ] Remote sync happens in background (when online)
- [ ] Offline indicator shown when disconnected
- [ ] Pending changes queued for sync
- [ ] Error handling for offline scenarios
- [ ] No blocking network calls in UI thread

## Reference

- `lib/data/datasources/local/sembast_database.dart` - Sembast database implementation
- `lib/data/datasources/local/` - Local data sources
- `lib/core/services/storage_service.dart` - Storage service pattern
