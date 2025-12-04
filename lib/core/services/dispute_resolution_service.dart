import 'package:spots/core/models/dispute.dart';
import 'package:spots/core/models/dispute_type.dart';
import 'package:spots/core/models/dispute_status.dart';
import 'package:spots/core/models/refund_policy.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/refund_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Dispute Resolution Service
/// 
/// Handles dispute submission, review, and resolution.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to fair dispute resolution
/// - Enables trust through transparent processes
/// - Supports user protection and conflict resolution
/// 
/// **Responsibilities:**
/// - Submit disputes
/// - Auto-assign to admins
/// - Attempt automated resolution
/// - Manual resolution workflow
/// 
/// **Usage:**
/// ```dart
/// final disputeService = DisputeResolutionService(
///   eventService,
///   refundService,
/// );
/// 
/// final dispute = await disputeService.submitDispute(
///   eventId: 'event-123',
///   reporterId: 'user-456',
///   reportedId: 'user-789',
///   type: DisputeType.refundDisagreement,
///   description: 'Refund amount incorrect',
/// );
/// ```
class DisputeResolutionService {
  static const String _logName = 'DisputeResolutionService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService _eventService;
  final RefundService? _refundService;
  
  // In-memory storage for disputes (in production, use database)
  final Map<String, Dispute> _disputes = {};
  
  DisputeResolutionService({
    required ExpertiseEventService eventService,
    RefundService? refundService,
  }) : _eventService = eventService,
       _refundService = refundService;
  
  /// Submit a dispute
  /// 
  /// **Flow:**
  /// 1. Create dispute record
  /// 2. Auto-assign to admin based on type
  /// 3. Notify both parties
  /// 4. Attempt automated resolution (if applicable)
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `reporterId`: User ID reporting the dispute
  /// - `reportedId`: User ID being reported
  /// - `type`: Dispute type
  /// - `description`: Description of the dispute
  /// - `evidenceUrls`: Optional evidence (photos, screenshots)
  /// 
  /// **Returns:**
  /// Created dispute record
  Future<Dispute> submitDispute({
    required String eventId,
    required String reporterId,
    required String reportedId,
    required DisputeType type,
    required String description,
    List<String>? evidenceUrls,
  }) async {
    try {
      _logger.info('Submitting dispute: event=$eventId, type=$type', tag: _logName);
      
      // Step 1: Create dispute record
      final dispute = Dispute(
        id: 'dispute_${_uuid.v4()}',
        eventId: eventId,
        reporterId: reporterId,
        reportedId: reportedId,
        type: type,
        description: description,
        evidenceUrls: evidenceUrls ?? [],
        createdAt: DateTime.now(),
        status: DisputeStatus.pending,
      );
      
      await _saveDispute(dispute);
      
      // Step 2: Auto-assign to admin
      await _autoAssignDispute(dispute);
      
      // Step 3: Notify both parties
      await _notifyDisputeSubmitted(dispute);
      
      // Step 4: Attempt automated resolution
      final autoResolved = await attemptAutomatedResolution(dispute.id);
      if (autoResolved != null) {
        _logger.info('Dispute auto-resolved: ${dispute.id}', tag: _logName);
        return autoResolved;
      }
      
      _logger.info('Dispute submitted: ${dispute.id}', tag: _logName);
      
      return dispute;
    } catch (e) {
      _logger.error('Error submitting dispute', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Admin reviews dispute
  /// 
  /// **Parameters:**
  /// - `disputeId`: Dispute ID
  /// - `adminId`: Admin user ID
  /// 
  /// **Returns:**
  /// Updated dispute record
  Future<Dispute> reviewDispute({
    required String disputeId,
    required String adminId,
  }) async {
    try {
      final dispute = await _getDispute(disputeId);
      if (dispute == null) {
        throw Exception('Dispute not found: $disputeId');
      }
      
      final updated = dispute.copyWith(
        status: DisputeStatus.inReview,
        assignedAdminId: adminId,
        assignedAt: DateTime.now(),
      );
      
      await _saveDispute(updated);
      
      // Request information from both parties
      await _requestDisputeInformation(updated);
      
      _logger.info('Dispute under review: $disputeId by admin $adminId', tag: _logName);
      
      return updated;
    } catch (e) {
      _logger.error('Error reviewing dispute', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Attempt automated resolution
  /// 
  /// **Flow:**
  /// 1. Check if dispute can be auto-resolved
  /// 2. Apply resolution logic
  /// 3. Update dispute status
  /// 
  /// **Parameters:**
  /// - `disputeId`: Dispute ID
  /// 
  /// **Returns:**
  /// Resolved dispute if auto-resolved, null otherwise
  Future<Dispute?> attemptAutomatedResolution(String disputeId) async {
    try {
      final dispute = await _getDispute(disputeId);
      if (dispute == null) {
        return null;
      }
      
      // Simple cases can be auto-resolved
      if (dispute.type == DisputeType.cancellation || dispute.type == DisputeType.payment) {
        final event = await _eventService.getEventById(dispute.eventId);
        if (event == null) {
          return null;
        }
        
        final timeUntilEvent = event.startTime.difference(DateTime.now());
        final hoursUntilEvent = timeUntilEvent.inHours.toDouble();
        final policy = RefundPolicy.standard();
        
        // If dispute aligns with policy, auto-resolve
        final refundPercentage = policy.calculateRefundPercentage(
          hoursUntilEvent: hoursUntilEvent,
          isForceMajeure: false,
        );
        
        final resolution = 'Refund calculated according to policy: ${refundPercentage.toStringAsFixed(0)}% refund based on ${hoursUntilEvent.toStringAsFixed(0)} hours until event.';
        
        final resolved = dispute.copyWith(
          status: DisputeStatus.resolved,
          resolution: resolution,
          resolvedAt: DateTime.now(),
          resolutionDetails: {
            'refundPercentage': refundPercentage,
            'hoursUntilEvent': hoursUntilEvent,
            'autoResolved': true,
          },
        );
        
        await _saveDispute(resolved);
        
        return resolved;
      }
      
      return null; // Needs manual review
    } catch (e) {
      _logger.error('Error attempting automated resolution', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Manual resolution by admin
  /// 
  /// **Flow:**
  /// 1. Update dispute with resolution
  /// 2. Execute resolution (refund if needed)
  /// 3. Notify both parties
  /// 
  /// **Parameters:**
  /// - `disputeId`: Dispute ID
  /// - `adminId`: Admin user ID
  /// - `resolution`: Resolution description
  /// - `refundAmount`: Optional refund amount
  /// - `resolutionDetails`: Optional additional details
  /// 
  /// **Returns:**
  /// Resolved dispute record
  Future<Dispute> resolveDispute({
    required String disputeId,
    required String adminId,
    required String resolution,
    double? refundAmount,
    Map<String, dynamic>? resolutionDetails,
  }) async {
    try {
      final dispute = await _getDispute(disputeId);
      if (dispute == null) {
        throw Exception('Dispute not found: $disputeId');
      }
      
      // Update dispute
      final resolved = dispute.copyWith(
        status: DisputeStatus.resolved,
        resolution: resolution,
        adminNotes: 'Resolved by $adminId',
        refundAmount: refundAmount,
        resolutionDetails: resolutionDetails,
        resolvedAt: DateTime.now(),
      );
      
      await _saveDispute(resolved);
      
      // Execute resolution (refund if needed)
      if (refundAmount != null && refundAmount > 0 && _refundService != null) {
        // TODO: Get payment ID from dispute metadata
        // For now, log that refund should be processed
        _logger.info('Refund should be processed: amount=\$${refundAmount.toStringAsFixed(2)}', tag: _logName);
      }
      
      // Notify both parties
      await _notifyDisputeResolved(resolved);
      
      _logger.info('Dispute resolved: $disputeId by admin $adminId', tag: _logName);
      
      return resolved;
    } catch (e) {
      _logger.error('Error resolving dispute', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get dispute by ID
  Future<Dispute?> getDispute(String disputeId) async {
    try {
      return _disputes[disputeId];
    } catch (e) {
      _logger.error('Error getting dispute', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Get disputes for an event
  Future<List<Dispute>> getDisputesForEvent(String eventId) async {
    try {
      return _disputes.values
          .where((d) => d.eventId == eventId)
          .toList();
    } catch (e) {
      _logger.error('Error getting disputes for event', error: e, tag: _logName);
      return [];
    }
  }
  
  // Private helper methods
  
  Future<void> _saveDispute(Dispute dispute) async {
    // In production, save to database
    _disputes[dispute.id] = dispute;
  }
  
  Future<Dispute?> _getDispute(String disputeId) async {
    return _disputes[disputeId];
  }
  
  Future<void> _autoAssignDispute(Dispute dispute) async {
    // In production, assign to admin based on type, workload, etc.
    _logger.info('Auto-assigning dispute ${dispute.id} to admin', tag: _logName);
    // TODO: Implement admin assignment logic
  }
  
  Future<void> _notifyDisputeSubmitted(Dispute dispute) async {
    // In production, send notifications to both parties
    _logger.info('Notifying parties of dispute submission: ${dispute.id}', tag: _logName);
    // TODO: Implement notification system
  }
  
  Future<void> _requestDisputeInformation(Dispute dispute) async {
    // In production, request information from both parties
    _logger.info('Requesting information for dispute: ${dispute.id}', tag: _logName);
    // TODO: Implement information request system
  }
  
  Future<void> _notifyDisputeResolved(Dispute dispute) async {
    // In production, send notifications to both parties
    _logger.info('Notifying parties of dispute resolution: ${dispute.id}', tag: _logName);
    // TODO: Implement notification system
  }
}

