// Reservation Waitlist Service
//
// Phase 15: Reservation System Implementation
// Section 15.1.9: Reservation Waitlist Service
// CRITICAL: Enables waitlist for sold-out events/spots
//
// Purpose: Manage waitlist for sold-out events/spots

import 'dart:developer' as developer;
import 'dart:convert';

import 'package:avrai/core/models/reservation.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/reservation_notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';

/// Waitlist status
enum WaitlistStatus {
  /// Waiting for spot to open
  waiting,

  /// Promoted (spot available, user has limited time to claim)
  promoted,

  /// Expired (promotion not claimed in time)
  expired,

  /// Cancelled by user
  cancelled,
}

/// Waitlist entry for sold-out events/spots
///
/// **CRITICAL:** Uses agentId (not userId) for privacy-protected internal tracking
class WaitlistEntry {
  /// Unique waitlist entry ID
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

  /// Atomic timestamp for waitlist entry (CRITICAL: Used for position ordering)
  final AtomicTimestamp entryTimestamp;

  /// Waitlist status
  final WaitlistStatus status;

  /// Waitlist position (null if not yet processed)
  final int? position;

  /// Promoted at (if promoted)
  final DateTime? promotedAt;

  /// Expires at (if promoted, user has limited time to claim)
  final DateTime? expiresAt;

  /// Created at
  final DateTime createdAt;

  /// Updated at
  final DateTime updatedAt;

  const WaitlistEntry({
    required this.id,
    required this.agentId,
    required this.type,
    required this.targetId,
    required this.reservationTime,
    required this.ticketCount,
    required this.entryTimestamp,
    required this.status,
    this.position,
    this.promotedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  WaitlistEntry copyWith({
    String? id,
    String? agentId,
    ReservationType? type,
    String? targetId,
    DateTime? reservationTime,
    int? ticketCount,
    AtomicTimestamp? entryTimestamp,
    WaitlistStatus? status,
    int? position,
    DateTime? promotedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaitlistEntry(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      reservationTime: reservationTime ?? this.reservationTime,
      ticketCount: ticketCount ?? this.ticketCount,
      entryTimestamp: entryTimestamp ?? this.entryTimestamp,
      status: status ?? this.status,
      position: position ?? this.position,
      promotedAt: promotedAt ?? this.promotedAt,
      expiresAt: expiresAt ?? this.expiresAt,
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
      'entryTimestamp': entryTimestamp.toJson(),
      'status': status.name,
      'position': position,
      'promotedAt': promotedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      type: ReservationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => ReservationType.spot,
      ),
      targetId: json['targetId'] as String,
      reservationTime: DateTime.parse(json['reservationTime'] as String),
      ticketCount: json['ticketCount'] as int,
      entryTimestamp: AtomicTimestamp.fromJson(
        json['entryTimestamp'] as Map<String, dynamic>,
      ),
      status: WaitlistStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => WaitlistStatus.waiting,
      ),
      position: json['position'] as int?,
      promotedAt: json['promotedAt'] != null
          ? DateTime.parse(json['promotedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Reservation Waitlist Service
///
/// **CRITICAL:** Enables waitlist for sold-out events/spots with atomic timestamp ordering
///
/// **Offline-First Strategy:**
/// - Add to waitlist locally (<50ms)
/// - Get atomic timestamp from AtomicClockService
/// - Notify when spot becomes available
/// - Sort by atomic timestamp (true first-come-first-served)
/// - Sync waitlist when online
class ReservationWaitlistService {
  static const String _logName = 'ReservationWaitlistService';
  static const String _storageKeyPrefix = 'waitlist_';
  // ignore: unused_field - Reserved for future cloud sync implementation
  static const String _supabaseTable = 'waitlist_entries';
  static const Duration _promotionExpiryDuration = Duration(hours: 2);

  final AtomicClockService _atomicClock;
  final AgentIdService _agentIdService;
  final StorageService _storageService;
  final SupabaseService _supabaseService;
  final ReservationNotificationService? _notificationService;
  final Uuid _uuid = const Uuid();

  ReservationWaitlistService({
    required AtomicClockService atomicClock,
    required AgentIdService agentIdService,
    required StorageService storageService,
    required SupabaseService supabaseService,
    ReservationNotificationService? notificationService,
  })  : _atomicClock = atomicClock,
        _agentIdService = agentIdService,
        _storageService = storageService,
        _supabaseService = supabaseService,
        _notificationService = notificationService ??
            (GetIt.instance.isRegistered<ReservationNotificationService>()
                ? GetIt.instance<ReservationNotificationService>()
                : null);

  /// Add to waitlist
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected tracking
  ///
  /// **Offline-First:**
  /// - Adds locally immediately (<50ms)
  /// - Gets atomic timestamp for waitlist entry
  /// - Returns waitlist entry with position (optimistic)
  /// - Syncs to cloud when online
  Future<WaitlistEntry> addToWaitlist({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int ticketCount,
  }) async {
    developer.log(
      'Adding to waitlist: type=$type, targetId=$targetId, time=$reservationTime, tickets=$ticketCount',
      name: _logName,
    );

    try {
      // Get agentId for privacy-protected internal tracking
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get atomic timestamp for waitlist entry (CRITICAL: Used for position ordering)
      final entryTimestamp = await _atomicClock.getTicketPurchaseTimestamp();

      // Create waitlist entry
      final entry = WaitlistEntry(
        id: _uuid.v4(),
        agentId: agentId, // CRITICAL: Uses agentId, not userId
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        ticketCount: ticketCount,
        entryTimestamp: entryTimestamp,
        status: WaitlistStatus.waiting,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store locally first (offline-first)
      await _storeWaitlistEntry(entry);

      // Calculate position (based on atomic timestamp)
      final position = await _calculatePosition(entry);
      if (position != null) {
        final updated = entry.copyWith(position: position);
        await _storeWaitlistEntry(updated);
      }

      // Sync to cloud when online
      if (_supabaseService.isAvailable) {
        try {
          await _syncWaitlistEntryToCloud(entry);
        } catch (e) {
          developer.log(
            'Failed to sync waitlist entry to cloud (will retry later): $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Added to waitlist: ${entry.id}, position=$position',
        name: _logName,
      );

      return entry;
    } catch (e, stackTrace) {
      developer.log(
        'Error adding to waitlist: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get waitlist position by entry ID
  ///
  /// **CRITICAL:** Uses agentId (not userId)
  Future<int?> getWaitlistPosition({
    required String userId, // Will be converted to agentId internally
    required String waitlistEntryId,
  }) async {
    try {
      // Get agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get waitlist entry
      final entry = await _getWaitlistEntryById(waitlistEntryId);
      if (entry == null) {
        return null;
      }

      // Verify agentId matches (privacy protection)
      if (entry.agentId != agentId) {
        developer.log(
          '⚠️ Waitlist entry agentId mismatch (privacy protection)',
          name: _logName,
        );
        return null;
      }

      // Always recalculate position (positions are dynamic and change when other entries are promoted)
      // This ensures accurate position even after promotions/expirations
      return await _calculatePosition(entry);
    } catch (e) {
      developer.log(
        'Error getting waitlist position: $e',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Find waitlist position by target parameters
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected tracking
  ///
  /// **Purpose:** Find if user is already on waitlist for specific target/time
  Future<int?> findWaitlistPosition({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
  }) async {
    try {
      // Get agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get all waitlist entries for this target/time
      final entries = await _getWaitlistEntries(
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        status: WaitlistStatus.waiting,
      );

      // Find entry matching this user's agentId
      try {
        final userEntry = entries.firstWhere(
          (e) => e.agentId == agentId,
        );

        // If position is set, return it
        if (userEntry.position != null) {
          return userEntry.position;
        }

        // Otherwise, calculate position from waitlist
        return await _calculatePosition(userEntry);
      } catch (e) {
        // User not on waitlist (no entry found)
        return null;
      }
    } catch (e) {
      developer.log(
        'Error finding waitlist position: $e',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Promote waitlist entries when spots open
  ///
  /// **Flow:**
  /// 1. Get all waiting entries for target/time
  /// 2. Sort by atomic timestamp (first-come-first-served)
  /// 3. Promote entries up to available capacity
  /// 4. Send notifications to promoted users
  Future<List<WaitlistEntry>> promoteWaitlistEntries({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
    required int availableCapacity,
  }) async {
    developer.log(
      'Promoting waitlist entries: type=$type, targetId=$targetId, time=$reservationTime, available=$availableCapacity',
      name: _logName,
    );

    try {
      // Get all waiting entries
      final entries = await _getWaitlistEntries(
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        status: WaitlistStatus.waiting,
      );

      // Sort by atomic timestamp (first-come-first-served)
      entries.sort((a, b) {
        final aTime = a.entryTimestamp.serverTime;
        final bTime = b.entryTimestamp.serverTime;
        return aTime.compareTo(bTime);
      });

      // Promote entries up to available capacity
      final promoted = <WaitlistEntry>[];
      int remainingCapacity = availableCapacity;

      for (final entry in entries) {
        if (remainingCapacity <= 0) {
          break;
        }

        if (entry.ticketCount <= remainingCapacity) {
          // Promote entry
          final expiresAt = DateTime.now().add(_promotionExpiryDuration);
          final updated = entry.copyWith(
            status: WaitlistStatus.promoted,
            promotedAt: DateTime.now(),
            expiresAt: expiresAt,
            updatedAt: DateTime.now(),
          );

          await _storeWaitlistEntry(updated);
          promoted.add(updated);

          // Send notification
          if (_notificationService != null) {
            try {
              // TODO(Phase 15.1.9): Create temporary reservation for notification
              // For now, just log
              developer.log(
                '⏳ Sending waitlist promotion notification (TODO: implement)',
                name: _logName,
              );
            } catch (e) {
              developer.log(
                'Error sending promotion notification: $e',
                name: _logName,
              );
            }
          }

          remainingCapacity -= entry.ticketCount;
        }
      }

      developer.log(
        '✅ Promoted ${promoted.length} waitlist entries',
        name: _logName,
      );

      return promoted;
    } catch (e, stackTrace) {
      developer.log(
        'Error promoting waitlist entries: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Check for expired promotions
  ///
  /// **Flow:**
  /// 1. Get all promoted entries
  /// 2. Check if promotion expired (past expiresAt)
  /// 3. Mark as expired if past expiry time
  /// 4. Move next entry in waitlist to promoted
  Future<List<WaitlistEntry>> checkExpiredPromotions({
    required ReservationType type,
    required String targetId,
    required DateTime reservationTime,
  }) async {
    developer.log(
      'Checking expired promotions: type=$type, targetId=$targetId, time=$reservationTime',
      name: _logName,
    );

    try {
      // Get all promoted entries
      final entries = await _getWaitlistEntries(
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        status: WaitlistStatus.promoted,
      );

      final now = DateTime.now();
      final expired = <WaitlistEntry>[];

      for (final entry in entries) {
        if (entry.expiresAt != null && entry.expiresAt!.isBefore(now)) {
          // Mark as expired
          final updated = entry.copyWith(
            status: WaitlistStatus.expired,
            updatedAt: DateTime.now(),
          );

          await _storeWaitlistEntry(updated);
          expired.add(updated);
        }
      }

      if (expired.isNotEmpty) {
        developer.log(
          '✅ Marked ${expired.length} promotions as expired',
          name: _logName,
        );

        // TODO(Phase 15.1.9): Implement automatic promotion of next entry
        // For now, just log
        developer.log(
          '⏳ Auto-promotion of next entry (TODO: implement)',
          name: _logName,
        );
      }

      return expired;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking expired promotions: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // --- Private Helper Methods ---

  /// Store waitlist entry locally
  Future<void> _storeWaitlistEntry(WaitlistEntry entry) async {
    final key = '$_storageKeyPrefix${entry.id}';
    await _storageService.setString(key, jsonEncode(entry.toJson()));
  }

  /// Get waitlist entry by ID
  Future<WaitlistEntry?> _getWaitlistEntryById(String id) async {
    final key = '$_storageKeyPrefix$id';
    final jsonStr = _storageService.getString(key);
    if (jsonStr == null) return null;
    return WaitlistEntry.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  /// Get waitlist entries
  Future<List<WaitlistEntry>> _getWaitlistEntries({
    ReservationType? type,
    String? targetId,
    DateTime? reservationTime,
    WaitlistStatus? status,
  }) async {
    try {
      final allKeys = _storageService.getKeys();
      final waitlistKeys =
          allKeys.where((key) => key.startsWith(_storageKeyPrefix)).toList();

      final entries = <WaitlistEntry>[];

      for (final key in waitlistKeys) {
        try {
          final jsonStr = _storageService.getString(key);
          if (jsonStr == null) continue;

          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final entry = WaitlistEntry.fromJson(json);

          // Filter by type if provided
          if (type != null && entry.type != type) continue;

          // Filter by targetId if provided
          if (targetId != null && entry.targetId != targetId) continue;

          // Filter by reservationTime if provided (within 1 hour window)
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
            'Error parsing waitlist entry from local storage: $e',
            name: _logName,
          );
          // Continue with next entry
        }
      }

      return entries;
    } catch (e) {
      developer.log(
        'Error getting waitlist entries from local storage: $e',
        name: _logName,
        error: e,
      );
      return [];
    }
  }

  /// Calculate position in waitlist
  Future<int?> _calculatePosition(WaitlistEntry entry) async {
    final entries = await _getWaitlistEntries(
      type: entry.type,
      targetId: entry.targetId,
      reservationTime: entry.reservationTime,
      status: WaitlistStatus.waiting,
    );

    // Sort by atomic timestamp
    entries.sort((a, b) {
      final aTime = a.entryTimestamp.serverTime;
      final bTime = b.entryTimestamp.serverTime;
      return aTime.compareTo(bTime);
    });

    // Find position
    final position = entries.indexWhere((e) => e.id == entry.id);
    return position >= 0 ? position + 1 : null;
  }

  /// Sync waitlist entry to cloud
  Future<void> _syncWaitlistEntryToCloud(WaitlistEntry entry) async {
    // TODO(Phase 15.1.9): Implement cloud sync
    developer.log(
      '⏳ Cloud sync for waitlist entry ${entry.id} (TODO: implement)',
      name: _logName,
    );
  }
}
