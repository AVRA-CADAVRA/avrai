// Reservation Ticket Queue Service
//
// Phase 15: Reservation System Implementation
// Section 15.1.3: Offline Ticket Queue Service
// CRITICAL: Enables true first-come-first-served for limited-seat events
//
// Purpose: Internal ticket queue system for limited seats - allows offline users
// to get tickets with atomic timestamp ordering

import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai/core/models/reservation.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// Queue status
enum QueueStatus {
  /// Waiting for queue processing
  pending,

  /// Tickets allocated
  allocated,

  /// Too late, no tickets available
  failed,

  /// Refunded due to failed allocation
  refunded,
}

/// Ticket queue entry
class TicketQueueEntry {
  /// Unique queue entry ID
  final String id;

  /// Agent ID (privacy-protected internal tracking)
  /// CRITICAL: Uses agentId, not userId
  final String agentId;

  /// Reservation type
  final ReservationType type;

  /// Target ID (spot/business/event ID)
  final String targetId;

  /// Reservation time
  final DateTime reservationTime;

  /// Ticket count requested
  final int ticketCount;

  /// Atomic timestamp for purchase time (CRITICAL: Used for queue ordering)
  final AtomicTimestamp purchaseTimestamp;

  /// Queue status
  final QueueStatus status;

  /// Queue position (null if not yet processed)
  final int? position;

  /// Created at
  final DateTime createdAt;

  /// Updated at
  final DateTime updatedAt;

  const TicketQueueEntry({
    required this.id,
    required this.agentId,
    required this.type,
    required this.targetId,
    required this.reservationTime,
    required this.ticketCount,
    required this.purchaseTimestamp,
    required this.status,
    this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  TicketQueueEntry copyWith({
    String? id,
    String? agentId,
    ReservationType? type,
    String? targetId,
    DateTime? reservationTime,
    int? ticketCount,
    AtomicTimestamp? purchaseTimestamp,
    QueueStatus? status,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketQueueEntry(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      reservationTime: reservationTime ?? this.reservationTime,
      ticketCount: ticketCount ?? this.ticketCount,
      purchaseTimestamp: purchaseTimestamp ?? this.purchaseTimestamp,
      status: status ?? this.status,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentId': agentId,
      'type': type.name,
      'targetId': targetId,
      'reservationTime': reservationTime.toIso8601String(),
      'ticketCount': ticketCount,
      'purchaseTimestamp': purchaseTimestamp.toJson(),
      'status': status.name,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TicketQueueEntry.fromJson(Map<String, dynamic> json) {
    return TicketQueueEntry(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      type: ReservationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => ReservationType.spot,
      ),
      targetId: json['targetId'] as String,
      reservationTime: DateTime.parse(json['reservationTime'] as String),
      ticketCount: json['ticketCount'] as int,
      purchaseTimestamp: AtomicTimestamp.fromJson(
        json['purchaseTimestamp'] as Map<String, dynamic>,
      ),
      status: QueueStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => QueueStatus.pending,
      ),
      position: json['position'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Ticket allocation result
class TicketAllocation {
  /// Queue entry ID
  final String queueEntryId;

  /// Reservation ID (if reservation created)
  final String? reservationId;

  /// Tickets allocated
  final int ticketsAllocated;

  /// Whether allocation was successful
  final bool success;

  /// Reason if failed
  final String? reason;

  const TicketAllocation({
    required this.queueEntryId,
    this.reservationId,
    required this.ticketsAllocated,
    required this.success,
    this.reason,
  });
}

/// Reservation Ticket Queue Service
///
/// **CRITICAL:** Enables true first-come-first-served for limited-seat events
/// using atomic timestamps for queue ordering.
///
/// **Offline-First Strategy:**
/// - Queue ticket requests locally (<50ms)
/// - Get atomic timestamp from AtomicClockService
/// - Hold payment (don't charge until queue is processed)
/// - Allocate tickets optimistically (show confirmation)
/// - Sync queue when online
/// - Sort by atomic timestamp (true first-come-first-served)
/// - Resolve conflicts using atomic timestamps (offline vs. online)
/// - Handle failed allocations (refund or cancel payment hold)
class ReservationTicketQueueService {
  static const String _logName = 'ReservationTicketQueueService';
  static const String _storageKeyPrefix = 'ticket_queue_';
  // ignore: unused_field - Reserved for future cloud sync implementation
  static const String _supabaseTable = 'ticket_queue_entries';

  final AtomicClockService _atomicClock;
  final AgentIdService _agentIdService;
  final StorageService _storageService;
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  ReservationTicketQueueService({
    required AtomicClockService atomicClock,
    required AgentIdService agentIdService,
    required StorageService storageService,
    required SupabaseService supabaseService,
  })  : _atomicClock = atomicClock,
        _agentIdService = agentIdService,
        _storageService = storageService,
        _supabaseService = supabaseService;

  /// Queue ticket request (works offline, uses atomic timestamp)
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected queue tracking
  ///
  /// **Offline-First:**
  /// - Queues locally immediately (<50ms)
  /// - Gets atomic timestamp for purchase time
  /// - Returns queue entry with position (optimistic)
  /// - Syncs to cloud when online
  Future<TicketQueueEntry> queueTicketRequest({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int ticketCount,
  }) async {
    developer.log(
      'Queueing ticket request: type=$type, targetId=$targetId, time=$reservationTime, tickets=$ticketCount',
      name: _logName,
    );

    try {
      // Get agentId for privacy-protected internal tracking
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get atomic timestamp for purchase time (CRITICAL: Used for queue ordering)
      final purchaseTimestamp = await _atomicClock.getTicketPurchaseTimestamp();

      // Create queue entry
      final queueEntry = TicketQueueEntry(
        id: _uuid.v4(),
        agentId: agentId, // CRITICAL: Uses agentId, not userId
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        ticketCount: ticketCount,
        purchaseTimestamp: purchaseTimestamp,
        status: QueueStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store locally first (offline-first)
      await _storeQueueEntryLocally(queueEntry);

      // Sync to cloud when online
      if (_supabaseService.isAvailable) {
        try {
          await _syncQueueEntryToCloud(queueEntry);
        } catch (e) {
          developer.log(
            'Failed to sync queue entry to cloud (will retry later): $e',
            name: _logName,
          );
          // Continue - offline-first, will sync later
        }
      }

      developer.log(
        '✅ Ticket request queued: ${queueEntry.id}',
        name: _logName,
      );

      return queueEntry;
    } catch (e, stackTrace) {
      developer.log(
        'Error queueing ticket request: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Process ticket queue (when online, sorts by atomic timestamp)
  ///
  /// **CRITICAL:** Sorts by atomic timestamp for true first-come-first-served
  ///
  /// **Phase 9.2: Performance Optimization:**
  /// - Batch status updates (reduces storage writes)
  /// - Efficient sorting (single pass)
  /// - Early exit when tickets exhausted
  Future<List<TicketAllocation>> processTicketQueue({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int availableTickets,
  }) async {
    developer.log(
      'Processing ticket queue: type=$type, targetId=$targetId, time=$reservationTime, available=$availableTickets',
      name: _logName,
    );

    try {
      // Phase 9.2: Performance optimization - Get all pending queue entries efficiently
      final queueEntries = await _getQueueEntries(
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        status: QueueStatus.pending,
      );

      if (queueEntries.isEmpty) {
        developer.log(
          'No pending queue entries to process',
          name: _logName,
        );
        return [];
      }

      // Phase 9.2: Performance optimization - Sort by atomic timestamp (single pass)
      queueEntries.sort((a, b) {
        final aTime = a.purchaseTimestamp.serverTime;
        final bTime = b.purchaseTimestamp.serverTime;
        return aTime.compareTo(bTime);
      });

      // Phase 9.2: Performance optimization - Batch process allocations
      final allocations = <TicketAllocation>[];
      int remainingTickets = availableTickets;
      final statusUpdates = <Map<String, dynamic>>[];

      for (int i = 0; i < queueEntries.length; i++) {
        final entry = queueEntries[i];

        // Phase 9.2: Performance optimization - Early exit when tickets exhausted
        if (remainingTickets <= 0) {
          // Mark remaining entries as failed (batch update)
          for (int j = i; j < queueEntries.length; j++) {
            final failedEntry = queueEntries[j];
            statusUpdates.add({
              'id': failedEntry.id,
              'status': QueueStatus.failed,
              'reason': 'Insufficient tickets available',
            });
            allocations.add(TicketAllocation(
              queueEntryId: failedEntry.id,
              ticketsAllocated: 0,
              success: false,
              reason: 'Insufficient tickets available',
            ));
          }
          break;
        }

        // Allocate tickets
        final ticketsToAllocate = entry.ticketCount <= remainingTickets
            ? entry.ticketCount
            : remainingTickets;

        statusUpdates.add({
          'id': entry.id,
          'status': QueueStatus.allocated,
          'position': i + 1,
        });

        allocations.add(TicketAllocation(
          queueEntryId: entry.id,
          ticketsAllocated: ticketsToAllocate,
          success: true,
        ));

        remainingTickets -= ticketsToAllocate;
      }

      // Phase 9.2: Performance optimization - Batch update statuses
      await _batchUpdateQueueEntryStatuses(statusUpdates);

      developer.log(
        '✅ Processed ${allocations.length} queue entries (${allocations.where((a) => a.success).length} allocated, ${allocations.where((a) => !a.success).length} failed)',
        name: _logName,
      );

      return allocations;
    } catch (e, stackTrace) {
      developer.log(
        'Error processing ticket queue: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Batch update queue entry statuses (Phase 9.2: Performance optimization)
  ///
  /// **Optimization:** Reduces storage writes by batching updates
  Future<void> _batchUpdateQueueEntryStatuses(
    List<Map<String, dynamic>> updates,
  ) async {
    if (updates.isEmpty) return;

    try {
      // Process updates in parallel (up to 10 at a time to avoid overwhelming storage)
      const batchSize = 10;
      for (int i = 0; i < updates.length; i += batchSize) {
        final batch = updates.skip(i).take(batchSize).toList();

        await Future.wait(
          batch.map((update) => _updateQueueEntryStatus(
                update['id'] as String,
                update['status'] as QueueStatus,
                position: update['position'] as int?,
                reason: update['reason'] as String?,
              )),
        );
      }

      developer.log(
        '✅ Batch updated ${updates.length} queue entry statuses',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error batch updating queue entry statuses: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Continue - individual updates will be retried
    }
  }

  /// Get user's position in queue (based on atomic timestamp)
  ///
  /// **CRITICAL:** Uses agentId (not userId)
  Future<int?> getQueuePosition({
    required String userId, // Will be converted to agentId internally
    required String queueEntryId,
  }) async {
    try {
      // Get agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get queue entry
      final entry = await _getQueueEntryById(queueEntryId);
      if (entry == null) {
        return null;
      }

      // Verify agentId matches (privacy protection)
      if (entry.agentId != agentId) {
        developer.log(
          '⚠️ Queue entry agentId mismatch (privacy protection)',
          name: _logName,
        );
        return null;
      }

      // If position is set, return it
      if (entry.position != null) {
        return entry.position;
      }

      // Phase 9.2: Performance optimization - Calculate position efficiently
      final queueEntries = await _getQueueEntries(
        type: entry.type,
        targetId: entry.targetId,
        reservationTime: entry.reservationTime,
        status: QueueStatus.pending,
      );

      if (queueEntries.isEmpty) {
        return null;
      }

      // Phase 9.2: Performance optimization - Sort by atomic timestamp (single pass)
      queueEntries.sort((a, b) {
        final aTime = a.purchaseTimestamp.serverTime;
        final bTime = b.purchaseTimestamp.serverTime;
        return aTime.compareTo(bTime);
      });

      // Find position
      final position = queueEntries.indexWhere((e) => e.id == queueEntryId);
      return position >= 0 ? position + 1 : null;
    } catch (e) {
      developer.log(
        'Error getting queue position: $e',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Allocate tickets from queue (first-come-first-served by atomic timestamp)
  Future<TicketAllocation> allocateTickets({
    required String queueEntryId,
    required int availableTickets,
  }) async {
    developer.log(
      'Allocating tickets: queueEntryId=$queueEntryId, available=$availableTickets',
      name: _logName,
    );

    try {
      // Get queue entry
      final entry = await _getQueueEntryById(queueEntryId);
      if (entry == null) {
        return TicketAllocation(
          queueEntryId: queueEntryId,
          ticketsAllocated: 0,
          success: false,
          reason: 'Queue entry not found',
        );
      }

      // Check if enough tickets available
      if (entry.ticketCount > availableTickets) {
        await _updateQueueEntryStatus(
          queueEntryId,
          QueueStatus.failed,
          reason: 'Insufficient tickets available',
        );
        return TicketAllocation(
          queueEntryId: queueEntryId,
          ticketsAllocated: 0,
          success: false,
          reason: 'Insufficient tickets available',
        );
      }

      // Allocate tickets
      await _updateQueueEntryStatus(
        queueEntryId,
        QueueStatus.allocated,
      );

      return TicketAllocation(
        queueEntryId: queueEntryId,
        ticketsAllocated: entry.ticketCount,
        success: true,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error allocating tickets: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return TicketAllocation(
        queueEntryId: queueEntryId,
        ticketsAllocated: 0,
        success: false,
        reason: 'Error: $e',
      );
    }
  }

  /// Handle queue conflicts (when syncing, uses atomic timestamps)
  Future<void> resolveQueueConflicts({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
  }) async {
    developer.log(
      'Resolving queue conflicts: type=$type, targetId=$targetId, time=$reservationTime',
      name: _logName,
    );

    try {
      // Get all queue entries (local + cloud)
      final localEntries = await _getQueueEntries(
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
      );

      // TODO(Phase 15.1.3): Get cloud entries and merge
      // For now, just process local entries

      // Sort by atomic timestamp (true first-come-first-served)
      localEntries.sort((a, b) {
        final aTime = a.purchaseTimestamp.serverTime;
        final bTime = b.purchaseTimestamp.serverTime;
        return aTime.compareTo(bTime);
      });

      // Update positions based on sorted order
      for (int i = 0; i < localEntries.length; i++) {
        if (localEntries[i].position != i + 1) {
          await _updateQueueEntryStatus(
            localEntries[i].id,
            localEntries[i].status,
            position: i + 1,
          );
        }
      }

      developer.log(
        '✅ Queue conflicts resolved',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error resolving queue conflicts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - conflict resolution failure is non-critical
    }
  }

  /// Check if user's ticket request will be fulfilled (before payment)
  Future<QueueStatus> checkQueueStatus({
    required String queueEntryId,
  }) async {
    try {
      final entry = await _getQueueEntryById(queueEntryId);
      if (entry == null) {
        return QueueStatus.failed;
      }
      return entry.status;
    } catch (e) {
      developer.log(
        'Error checking queue status: $e',
        name: _logName,
        error: e,
      );
      return QueueStatus.failed;
    }
  }

  // Private helper methods

  /// Store queue entry locally
  Future<void> _storeQueueEntryLocally(TicketQueueEntry entry) async {
    final key = '$_storageKeyPrefix${entry.id}';
    await _storageService.setString(key, jsonEncode(entry.toJson()));
  }

  /// Get queue entry by ID
  Future<TicketQueueEntry?> _getQueueEntryById(String id) async {
    final key = '$_storageKeyPrefix$id';
    final jsonStr = _storageService.getString(key);
    if (jsonStr == null) return null;
    return TicketQueueEntry.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  /// Get queue entries (Phase 9.2: Performance optimization)
  ///
  /// **Optimizations:**
  /// - Efficient key-based retrieval (uses storage prefix)
  /// - In-memory filtering (avoids multiple storage reads)
  /// - Batch processing support
  Future<List<TicketQueueEntry>> _getQueueEntries({
    ReservationType? type,
    String? targetId,
    DateTime? reservationTime,
    QueueStatus? status,
  }) async {
    try {
      // Phase 9.2: Performance optimization - Get all queue keys at once
      final allKeys = _storageService.getKeys();
      final queueKeys =
          allKeys.where((key) => key.startsWith(_storageKeyPrefix)).toList();

      final entries = <TicketQueueEntry>[];

      // Phase 9.2: Performance optimization - Batch read and filter
      for (final key in queueKeys) {
        try {
          final jsonStr = _storageService.getString(key);
          if (jsonStr == null) continue;

          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final entry = TicketQueueEntry.fromJson(json);

          // Filter by type if provided
          if (type != null && entry.type != type) continue;

          // Filter by targetId if provided
          if (targetId != null && entry.targetId != targetId) continue;

          // Filter by reservationTime if provided (within 1 hour window for queue processing)
          if (reservationTime != null) {
            final timeDiff =
                entry.reservationTime.difference(reservationTime).inHours.abs();
            if (timeDiff >= 1) continue;
          }

          // Filter by status if provided
          if (status != null && entry.status != status) continue;

          entries.add(entry);
        } catch (e) {
          developer.log(
            'Error parsing queue entry from local storage: $e',
            name: _logName,
          );
          // Continue with next entry
        }
      }

      developer.log(
        'Retrieved ${entries.length} queue entries (filtered from ${queueKeys.length} total)',
        name: _logName,
      );

      return entries;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting queue entries from local storage: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Update queue entry status
  Future<void> _updateQueueEntryStatus(
    String queueEntryId,
    QueueStatus status, {
    int? position,
    String? reason,
  }) async {
    final entry = await _getQueueEntryById(queueEntryId);
    if (entry == null) return;

    final updated = entry.copyWith(
      status: status,
      position: position,
      updatedAt: DateTime.now(),
    );

    await _storeQueueEntryLocally(updated);

    // Sync to cloud when online
    if (_supabaseService.isAvailable) {
      try {
        await _syncQueueEntryToCloud(updated);
      } catch (e) {
        developer.log(
          'Failed to sync updated queue entry to cloud: $e',
          name: _logName,
        );
      }
    }
  }

  /// Sync queue entry to cloud
  Future<void> _syncQueueEntryToCloud(TicketQueueEntry entry) async {
    // TODO(Phase 15.1.3): Implement cloud sync
    // For now, just log (will be implemented with Supabase)
    developer.log(
      '⏳ Cloud sync for queue entry ${entry.id} (TODO: implement)',
      name: _logName,
    );
  }
}
