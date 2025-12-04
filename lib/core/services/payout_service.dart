import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Payout Service
/// 
/// Manages payout scheduling and tracking.
/// 
/// **Philosophy Alignment:**
/// - Enables transparent revenue distribution
/// - Supports automatic payout scheduling
/// - Tracks earnings for all parties
/// 
/// **Responsibilities:**
/// - Schedule payouts
/// - Track earnings
/// - Generate payout reports
class PayoutService {
  static const String _logName = 'PayoutService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final RevenueSplitService _revenueSplitService;
  
  // In-memory storage for payouts (in production, use database)
  final Map<String, Payout> _payouts = {};
  
  PayoutService({
    required RevenueSplitService revenueSplitService,
  }) : _revenueSplitService = revenueSplitService;
  
  /// Schedule a payout for a party
  /// 
  /// **Flow:**
  /// 1. Create payout record
  /// 2. Schedule payout (2 days after event)
  /// 3. Save payout record
  /// 
  /// **Parameters:**
  /// - `partyId`: Party ID (userId, businessId, etc.)
  /// - `amount`: Payout amount in dollars
  /// - `eventId`: Event ID
  /// - `scheduledDate`: Scheduled payout date (2 days after event)
  /// 
  /// **Returns:**
  /// Payout record
  Future<Payout> schedulePayout({
    required String partyId,
    required double amount,
    required String eventId,
    required DateTime scheduledDate,
  }) async {
    try {
      _logger.info('Scheduling payout: party=$partyId, amount=\$${amount.toStringAsFixed(2)}, date=$scheduledDate', tag: _logName);
      
      // Create payout record
      final payout = Payout(
        id: _generatePayoutId(),
        partyId: partyId,
        amount: amount,
        eventId: eventId,
        status: PayoutStatus.scheduled,
        scheduledDate: scheduledDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save payout
      await _savePayout(payout);
      
      _logger.info('Scheduled payout: ${payout.id}', tag: _logName);
      return payout;
    } catch (e) {
      _logger.error('Error scheduling payout', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Track earnings for a party
  /// 
  /// **Flow:**
  /// 1. Query payouts for party
  /// 2. Calculate total earnings
  /// 3. Generate earnings report
  /// 
  /// **Parameters:**
  /// - `partyId`: Party ID
  /// - `startDate`: Start date for earnings period
  /// - `endDate`: End date for earnings period
  /// 
  /// **Returns:**
  /// EarningsReport with total earnings and breakdown
  Future<EarningsReport> trackEarnings({
    required String partyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Tracking earnings: party=$partyId', tag: _logName);
      
      // Get all payouts for party
      final allPayouts = await _getAllPayouts();
      var payouts = allPayouts.where((p) => p.partyId == partyId).toList();
      
      // Filter by date range
      if (startDate != null) {
        payouts = payouts.where((p) => p.scheduledDate.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        payouts = payouts.where((p) => p.scheduledDate.isBefore(endDate)).toList();
      }
      
      // Calculate totals
      double totalEarnings = 0.0;
      double totalPaid = 0.0;
      double totalPending = 0.0;
      
      for (final payout in payouts) {
        totalEarnings += payout.amount;
        
        if (payout.status == PayoutStatus.completed) {
          totalPaid += payout.amount;
        } else if (payout.status == PayoutStatus.scheduled || 
                   payout.status == PayoutStatus.processing) {
          totalPending += payout.amount;
        }
      }
      
      // Generate earnings report
      final report = EarningsReport(
        partyId: partyId,
        totalEarnings: totalEarnings,
        totalPaid: totalPaid,
        totalPending: totalPending,
        payoutCount: payouts.length,
        payouts: payouts,
        startDate: startDate,
        endDate: endDate,
        generatedAt: DateTime.now(),
      );
      
      _logger.info('Earnings report: total=\$${totalEarnings.toStringAsFixed(2)}, paid=\$${totalPaid.toStringAsFixed(2)}, pending=\$${totalPending.toStringAsFixed(2)}', tag: _logName);
      return report;
    } catch (e) {
      _logger.error('Error tracking earnings', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Update payout status
  /// 
  /// **Parameters:**
  /// - `payoutId`: Payout ID
  /// - `status`: New payout status
  /// 
  /// **Returns:**
  /// Updated Payout
  Future<Payout> updatePayoutStatus({
    required String payoutId,
    required PayoutStatus status,
  }) async {
    try {
      _logger.info('Updating payout status: $payoutId -> ${status.name}', tag: _logName);
      
      final payout = await getPayout(payoutId);
      if (payout == null) {
        throw Exception('Payout not found: $payoutId');
      }
      
      final updated = payout.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        completedAt: status == PayoutStatus.completed ? DateTime.now() : payout.completedAt,
      );
      
      await _savePayout(updated);
      return updated;
    } catch (e) {
      _logger.error('Error updating payout status', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get payout by ID
  /// 
  /// **Parameters:**
  /// - `payoutId`: Payout ID
  /// 
  /// **Returns:**
  /// Payout if found, null otherwise
  Future<Payout?> getPayout(String payoutId) async {
    try {
      final allPayouts = await _getAllPayouts();
      try {
        return allPayouts.firstWhere(
          (p) => p.id == payoutId,
        );
      } catch (e) {
        return null;
      }
    } catch (e) {
      _logger.error('Error getting payout', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Get payouts for a party
  /// 
  /// **Parameters:**
  /// - `partyId`: Party ID
  /// 
  /// **Returns:**
  /// List of Payout records
  Future<List<Payout>> getPayoutsForParty(String partyId) async {
    try {
      final allPayouts = await _getAllPayouts();
      return allPayouts
          .where((p) => p.partyId == partyId)
          .toList()
        ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    } catch (e) {
      _logger.error('Error getting payouts for party', error: e, tag: _logName);
      return [];
    }
  }
  
  // Private helper methods
  
  String _generatePayoutId() {
    return 'payout_${_uuid.v4()}';
  }
  
  Future<void> _savePayout(Payout payout) async {
    // In production, save to database
    _payouts[payout.id] = payout;
  }
  
  Future<List<Payout>> _getAllPayouts() async {
    // In production, query database
    return _payouts.values.toList();
  }
}

/// Payout Model
/// Represents a scheduled payout to a party
class Payout {
  final String id;
  final String partyId; // userId, businessId, etc.
  final double amount;
  final String eventId;
  final PayoutStatus status;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? stripeTransferId; // Stripe Connect transfer ID
  final Map<String, dynamic> metadata;

  const Payout({
    required this.id,
    required this.partyId,
    required this.amount,
    required this.eventId,
    required this.status,
    required this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.stripeTransferId,
    this.metadata = const {},
  });

  Payout copyWith({
    String? id,
    String? partyId,
    double? amount,
    String? eventId,
    PayoutStatus? status,
    DateTime? scheduledDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? stripeTransferId,
    Map<String, dynamic>? metadata,
  }) {
    return Payout(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      amount: amount ?? this.amount,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      stripeTransferId: stripeTransferId ?? this.stripeTransferId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partyId': partyId,
      'amount': amount,
      'eventId': eventId,
      'status': status.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'stripeTransferId': stripeTransferId,
      'metadata': metadata,
    };
  }

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      partyId: json['partyId'] as String,
      amount: (json['amount'] as num).toDouble(),
      eventId: json['eventId'] as String,
      status: PayoutStatusExtension.fromString(json['status'] as String? ?? 'scheduled'),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      stripeTransferId: json['stripeTransferId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Payout Status
enum PayoutStatus {
  scheduled,   // Scheduled for future payout
  processing,  // Currently processing
  completed,   // Payout completed
  failed,      // Payout failed
  cancelled,   // Payout cancelled
}

extension PayoutStatusExtension on PayoutStatus {
  String get displayName {
    switch (this) {
      case PayoutStatus.scheduled:
        return 'Scheduled';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PayoutStatus fromString(String? value) {
    if (value == null) return PayoutStatus.scheduled;
    switch (value.toLowerCase()) {
      case 'scheduled':
        return PayoutStatus.scheduled;
      case 'processing':
        return PayoutStatus.processing;
      case 'completed':
        return PayoutStatus.completed;
      case 'failed':
        return PayoutStatus.failed;
      case 'cancelled':
        return PayoutStatus.cancelled;
      default:
        return PayoutStatus.scheduled;
    }
  }
}

/// Earnings Report
/// Represents earnings tracking for a party
class EarningsReport {
  final String partyId;
  final double totalEarnings;
  final double totalPaid;
  final double totalPending;
  final int payoutCount;
  final List<Payout> payouts;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime generatedAt;

  const EarningsReport({
    required this.partyId,
    required this.totalEarnings,
    required this.totalPaid,
    required this.totalPending,
    required this.payoutCount,
    required this.payouts,
    this.startDate,
    this.endDate,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'partyId': partyId,
      'totalEarnings': totalEarnings,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'payoutCount': payoutCount,
      'payouts': payouts.map((p) => p.toJson()).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
