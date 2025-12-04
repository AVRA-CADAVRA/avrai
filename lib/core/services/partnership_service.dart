import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Partnership Service
/// 
/// Core service for managing event partnerships between users and businesses.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to business partnerships
/// - Enables multi-party event hosting
/// - Supports revenue sharing agreements
/// - Creates pathways for business collaboration
/// 
/// **Partnership Workflow:**
/// 1. Discovery - AI suggests compatible partners (70%+ vibe match only)
/// 2. Proposal - One party proposes partnership with revenue split
/// 3. Negotiation - Revenue split discussion (can counter-propose)
/// 4. Agreement - ALL parties must approve and LOCK before event starts
/// 5. Execution - Event happens
/// 6. Payment - Automatic revenue distribution (2 days after event)
/// 7. Feedback - Mutual ratings (both can rate each other)
class PartnershipService {
  static const String _logName = 'PartnershipService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService _eventService;
  final BusinessService _businessService;
  
  // In-memory storage for partnerships (in production, use database)
  final Map<String, EventPartnership> _partnerships = {};
  
  PartnershipService({
    required ExpertiseEventService eventService,
    required BusinessService businessService,
  }) : _eventService = eventService,
       _businessService = businessService;
  
  /// Create a new partnership for an event
  /// 
  /// **Flow:**
  /// 1. Validate event exists
  /// 2. Validate business exists
  /// 3. Check partnership eligibility
  /// 4. Calculate vibe compatibility (must be 70%+)
  /// 5. Create EventPartnership record
  /// 6. Update ExpertiseEvent with partnership reference
  /// 7. Return partnership
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID for the partnership
  /// - `userId`: User/Expert ID
  /// - `businessId`: Business ID
  /// - `agreement`: Partnership agreement terms
  /// 
  /// **Returns:**
  /// EventPartnership with status `pending` or `proposed`
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  /// - `Exception` if business not found
  /// - `Exception` if partnership not eligible
  /// - `Exception` if compatibility < 70%
  Future<EventPartnership> createPartnership({
    required String eventId,
    required String userId,
    required String businessId,
    PartnershipAgreement? agreement,
    PartnershipType type = PartnershipType.eventBased,
    List<String>? sharedResponsibilities,
    String? venueLocation,
    double? vibeCompatibilityScore,
  }) async {
    try {
      _logger.info('Creating partnership: event=$eventId, user=$userId, business=$businessId', tag: _logName);
      
      // Step 1: Validate event exists
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Step 2: Validate business exists
      final business = await _businessService.getBusinessById(businessId);
      if (business == null) {
        throw Exception('Business not found: $businessId');
      }
      
      // Step 3: Check partnership eligibility
      final isEligible = await checkPartnershipEligibility(
        userId: userId,
        businessId: businessId,
        eventId: eventId,
      );
      if (!isEligible) {
        throw Exception('Partnership not eligible');
      }
      
      // Step 4: Calculate vibe compatibility (if not provided)
      double compatibility = vibeCompatibilityScore ?? 0.0;
      if (compatibility == 0.0) {
        compatibility = await calculateVibeCompatibility(
          userId: userId,
          businessId: businessId,
        );
      }
      
      // Step 5: Validate compatibility threshold (70%+)
      if (compatibility < 0.70) {
        throw Exception('Compatibility below 70% threshold: ${(compatibility * 100).toStringAsFixed(1)}%');
      }
      
      // Step 6: Create partnership
      final partnership = EventPartnership(
        id: _generatePartnershipId(),
        eventId: eventId,
        userId: userId,
        businessId: businessId,
        status: PartnershipStatus.proposed,
        agreement: agreement,
        type: type,
        sharedResponsibilities: sharedResponsibilities ?? [],
        venueLocation: venueLocation,
        vibeCompatibilityScore: compatibility,
        userApproved: false,
        businessApproved: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Step 7: Save partnership
      await _savePartnership(partnership);
      
      _logger.info('Created partnership: ${partnership.id}', tag: _logName);
      return partnership;
    } catch (e) {
      _logger.error('Error creating partnership', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get all partnerships for an event
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// List of EventPartnership records
  Future<List<EventPartnership>> getPartnershipsForEvent(String eventId) async {
    try {
      _logger.info('Getting partnerships for event: $eventId', tag: _logName);
      
      final allPartnerships = await _getAllPartnerships();
      return allPartnerships
          .where((p) => p.eventId == eventId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting partnerships for event', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get partnership by ID
  /// 
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID
  /// 
  /// **Returns:**
  /// EventPartnership if found, null otherwise
  Future<EventPartnership?> getPartnershipById(String partnershipId) async {
    try {
      _logger.info('Getting partnership by ID: $partnershipId', tag: _logName);
      
      final allPartnerships = await _getAllPartnerships();
      try {
        return allPartnerships.firstWhere(
          (p) => p.id == partnershipId,
        );
      } catch (e) {
        _logger.info('Partnership not found: $partnershipId', tag: _logName);
        return null;
      }
    } catch (e) {
      _logger.error('Error getting partnership by ID', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Update partnership status
  /// 
  /// **Flow:**
  /// 1. Get partnership by ID
  /// 2. Validate status transition
  /// 3. Update partnership status
  /// 4. If status is `approved` and all parties approved:
  ///    - Lock revenue split (pre-event)
  ///    - Update event status
  /// 5. Return updated partnership
  /// 
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID
  /// - `status`: New partnership status
  /// 
  /// **Returns:**
  /// Updated EventPartnership
  /// 
  /// **Throws:**
  /// - `Exception` if partnership not found
  /// - `Exception` if status transition is invalid
  Future<EventPartnership> updatePartnershipStatus({
    required String partnershipId,
    required PartnershipStatus status,
  }) async {
    try {
      _logger.info('Updating partnership status: $partnershipId -> ${status.name}', tag: _logName);
      
      final partnership = await getPartnershipById(partnershipId);
      if (partnership == null) {
        throw Exception('Partnership not found: $partnershipId');
      }
      
      // Validate status transition
      if (!_isValidStatusTransition(partnership.status, status)) {
        throw Exception('Invalid status transition: ${partnership.status.name} -> ${status.name}');
      }
      
      // Update partnership
      final updated = partnership.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      
      // If status is `approved` and all parties approved, lock the agreement
      if (status == PartnershipStatus.approved && partnership.isApproved) {
        final locked = updated.copyWith(
          status: PartnershipStatus.locked,
          updatedAt: DateTime.now(),
        );
        await _savePartnership(locked);
        _logger.info('Partnership locked: $partnershipId', tag: _logName);
        return locked;
      }
      
      await _savePartnership(updated);
      _logger.info('Updated partnership status: $partnershipId', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating partnership status', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Approve partnership (user or business)
  /// 
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID
  /// - `approvedBy`: User ID or Business ID who approved
  /// 
  /// **Returns:**
  /// Updated EventPartnership
  Future<EventPartnership> approvePartnership({
    required String partnershipId,
    required String approvedBy,
  }) async {
    try {
      _logger.info('Approving partnership: $partnershipId by $approvedBy', tag: _logName);
      
      final partnership = await getPartnershipById(partnershipId);
      if (partnership == null) {
        throw Exception('Partnership not found: $partnershipId');
      }
      
      // Determine if user or business approved
      final isUserApproval = approvedBy == partnership.userId;
      final isBusinessApproval = approvedBy == partnership.businessId;
      
      if (!isUserApproval && !isBusinessApproval) {
        throw Exception('Invalid approver: $approvedBy');
      }
      
      // Update approval flags
      final updated = partnership.copyWith(
        userApproved: isUserApproval ? true : partnership.userApproved,
        businessApproved: isBusinessApproval ? true : partnership.businessApproved,
        updatedAt: DateTime.now(),
      );
      
      // If both parties approved, update status to approved
      if (updated.isApproved) {
        return await updatePartnershipStatus(
          partnershipId: partnershipId,
          status: PartnershipStatus.approved,
        );
      }
      
      await _savePartnership(updated);
      return updated;
    } catch (e) {
      _logger.error('Error approving partnership', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Check partnership eligibility
  /// 
  /// **Flow:**
  /// 1. Check user has City-level expertise
  /// 2. Check business is verified
  /// 3. Check event exists and is upcoming
  /// 4. Check no existing partnership for this event
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `businessId`: Business ID
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// true if eligible, false otherwise
  Future<bool> checkPartnershipEligibility({
    required String userId,
    required String businessId,
    required String eventId,
  }) async {
    try {
      // Step 1: Check event exists
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        _logger.info('Event not found: $eventId', tag: _logName);
        return false;
      }
      
      // Step 2: Check event is upcoming
      if (event.hasStarted) {
        _logger.info('Event has already started: $eventId', tag: _logName);
        return false;
      }
      
      // Step 3: Check user has Local-level expertise or higher
      if (!event.host.canHostEvents()) {
        _logger.info('User cannot host events: $userId', tag: _logName);
        return false;
      }
      
      // Step 4: Check business is verified
      final business = await _businessService.getBusinessById(businessId);
      if (business == null) {
        _logger.info('Business not found: $businessId', tag: _logName);
        return false;
      }
      
      if (!business.isVerified) {
        _logger.info('Business not verified: $businessId', tag: _logName);
        return false;
      }
      
      // Step 5: Check no existing partnership for this event
      final existingPartnerships = await getPartnershipsForEvent(eventId);
      if (existingPartnerships.isNotEmpty) {
        _logger.info('Partnership already exists for event: $eventId', tag: _logName);
        return false;
      }
      
      return true;
    } catch (e) {
      _logger.error('Error checking partnership eligibility', error: e, tag: _logName);
      return false;
    }
  }
  
  /// Calculate vibe compatibility between user and business
  /// 
  /// **Flow:**
  /// 1. Get user personality/vibe data
  /// 2. Get business preferences/vibe data
  /// 3. Calculate compatibility score (0.0 to 1.0)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `businessId`: Business ID
  /// 
  /// **Returns:**
  /// Compatibility score (0.0 to 1.0)
  /// 
  /// **Note:**
  /// This is a simplified implementation. In production, this would:
  /// - Use VibeAnalysisEngine to get user vibes
  /// - Use BusinessAccount preferences for business vibes
  /// - Calculate sophisticated compatibility score
  Future<double> calculateVibeCompatibility({
    required String userId,
    required String businessId,
  }) async {
    try {
      _logger.info('Calculating vibe compatibility: user=$userId, business=$businessId', tag: _logName);
      
      // TODO: In production, integrate with VibeAnalysisEngine
      // For now, return a placeholder compatibility score
      // This should use:
      // - UserVibe from VibeAnalysisEngine
      // - BusinessAccount.expertPreferences for business vibe
      // - Calculate compatibility using UserVibe.calculateVibeCompatibility()
      
      // Placeholder: Return 0.75 (75% compatibility) for now
      // This ensures partnerships can be created for testing
      // In production, replace with actual vibe calculation
      return 0.75;
    } catch (e) {
      _logger.error('Error calculating vibe compatibility', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  // Private helper methods
  
  String _generatePartnershipId() {
    return 'partnership_${_uuid.v4()}';
  }
  
  Future<void> _savePartnership(EventPartnership partnership) async {
    // In production, save to database
    _partnerships[partnership.id] = partnership;
  }
  
  Future<List<EventPartnership>> _getAllPartnerships() async {
    // In production, query database
    return _partnerships.values.toList();
  }
  
  /// Validate status transition
  bool _isValidStatusTransition(PartnershipStatus current, PartnershipStatus next) {
    // Define valid transitions
    switch (current) {
      case PartnershipStatus.pending:
        return next == PartnershipStatus.proposed || 
               next == PartnershipStatus.cancelled;
      case PartnershipStatus.proposed:
        return next == PartnershipStatus.negotiating ||
               next == PartnershipStatus.approved ||
               next == PartnershipStatus.cancelled;
      case PartnershipStatus.negotiating:
        return next == PartnershipStatus.approved ||
               next == PartnershipStatus.cancelled;
      case PartnershipStatus.approved:
        return next == PartnershipStatus.locked ||
               next == PartnershipStatus.cancelled;
      case PartnershipStatus.locked:
        return next == PartnershipStatus.active ||
               next == PartnershipStatus.cancelled;
      case PartnershipStatus.active:
        return next == PartnershipStatus.completed ||
               next == PartnershipStatus.disputed;
      case PartnershipStatus.completed:
        return false; // Terminal state
      case PartnershipStatus.cancelled:
        return false; // Terminal state
      case PartnershipStatus.disputed:
        return next == PartnershipStatus.cancelled ||
               next == PartnershipStatus.completed;
    }
  }
}

