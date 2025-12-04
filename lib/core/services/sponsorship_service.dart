import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Sponsorship Service
/// 
/// Core service for managing brand sponsorships for events.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to brand partnerships
/// - Enables multi-party event funding
/// - Supports diverse contribution types
/// - Creates pathways for brand collaboration
/// 
/// **Sponsorship Workflow:**
/// 1. Discovery - AI suggests compatible brands (70%+ vibe match only)
/// 2. Proposal - Brand proposes sponsorship with contribution type
/// 3. Negotiation - Terms discussion (can counter-propose)
/// 4. Agreement - ALL parties must approve and LOCK before event starts
/// 5. Execution - Event happens
/// 6. Payment - Automatic revenue distribution (2 days after event)
/// 7. Feedback - Performance tracking and analytics
class SponsorshipService {
  static const String _logName = 'SponsorshipService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService _eventService;
  final PartnershipService _partnershipService; // Read-only
  final BusinessService _businessService; // Read-only
  
  // In-memory storage for sponsorships (in production, use database)
  final Map<String, Sponsorship> _sponsorships = {};
  
  // In-memory storage for brand accounts (in production, use database)
  // This would normally come from a BrandService, but for now we'll store here
  final Map<String, BrandAccount> _brandAccounts = {};
  
  SponsorshipService({
    required ExpertiseEventService eventService,
    required PartnershipService partnershipService,
    required BusinessService businessService,
  }) : _eventService = eventService,
       _partnershipService = partnershipService,
       _businessService = businessService;
  
  /// Create a new sponsorship for an event
  /// 
  /// **Flow:**
  /// 1. Validate event exists
  /// 2. Validate brand account exists and is verified
  /// 3. Check sponsorship eligibility
  /// 4. Calculate vibe compatibility (must be 70%+)
  /// 5. Create Sponsorship record
  /// 6. Return sponsorship
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID for the sponsorship
  /// - `brandId`: Brand ID providing sponsorship
  /// - `type`: Sponsorship type (financial, product, hybrid)
  /// - `contributionAmount`: Financial contribution amount (if financial/hybrid)
  /// - `productValue`: Product contribution value (if product/hybrid)
  /// - `agreementTerms`: Agreement terms (optional)
  /// - `vibeCompatibilityScore`: Pre-calculated compatibility (optional)
  /// 
  /// **Returns:**
  /// Sponsorship with status `pending` or `proposed`
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  /// - `Exception` if brand not found
  /// - `Exception` if brand not verified
  /// - `Exception` if sponsorship not eligible
  /// - `Exception` if compatibility < 70%
  Future<Sponsorship> createSponsorship({
    required String eventId,
    required String brandId,
    required SponsorshipType type,
    double? contributionAmount,
    double? productValue,
    Map<String, dynamic>? agreementTerms,
    double? vibeCompatibilityScore,
  }) async {
    try {
      _logger.info('Creating sponsorship: event=$eventId, brand=$brandId, type=${type.name}', tag: _logName);
      
      // Step 1: Validate event exists
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Step 2: Validate brand account exists and is verified
      final brand = await getBrandById(brandId);
      if (brand == null) {
        throw Exception('Brand account not found: $brandId');
      }
      
      if (!brand.isVerified) {
        throw Exception('Brand account not verified: $brandId');
      }
      
      // Step 3: Validate sponsorship type and values
      if (type == SponsorshipType.financial && contributionAmount == null) {
        throw Exception('Financial sponsorship requires contributionAmount');
      }
      if (type == SponsorshipType.product && productValue == null) {
        throw Exception('Product sponsorship requires productValue');
      }
      if (type == SponsorshipType.hybrid && (contributionAmount == null || productValue == null)) {
        throw Exception('Hybrid sponsorship requires both contributionAmount and productValue');
      }
      
      // Step 4: Check sponsorship eligibility
      final isEligible = await checkSponsorshipEligibility(
        eventId: eventId,
        brandId: brandId,
      );
      if (!isEligible) {
        throw Exception('Sponsorship not eligible');
      }
      
      // Step 5: Calculate vibe compatibility (if not provided)
      double compatibility = vibeCompatibilityScore ?? 0.0;
      if (compatibility == 0.0) {
        compatibility = await calculateCompatibility(
          eventId: eventId,
          brandId: brandId,
        );
      }
      
      // Step 6: Validate compatibility threshold (70%+)
      if (compatibility < 0.70) {
        throw Exception('Compatibility below 70% threshold: ${(compatibility * 100).toStringAsFixed(1)}%');
      }
      
      // Step 7: Create sponsorship
      final sponsorship = Sponsorship(
        id: _generateSponsorshipId(),
        eventId: eventId,
        brandId: brandId,
        type: type,
        contributionAmount: contributionAmount,
        productValue: productValue,
        status: SponsorshipStatus.proposed,
        agreementTerms: agreementTerms,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Step 8: Save sponsorship
      await _saveSponsorship(sponsorship);
      
      _logger.info('Created sponsorship: ${sponsorship.id}', tag: _logName);
      return sponsorship;
    } catch (e) {
      _logger.error('Error creating sponsorship', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get all sponsorships for an event
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// List of Sponsorship records
  Future<List<Sponsorship>> getSponsorshipsForEvent(String eventId) async {
    try {
      _logger.info('Getting sponsorships for event: $eventId', tag: _logName);
      
      final allSponsorships = await _getAllSponsorships();
      return allSponsorships
          .where((s) => s.eventId == eventId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting sponsorships for event', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get sponsorship by ID
  /// 
  /// **Parameters:**
  /// - `sponsorshipId`: Sponsorship ID
  /// 
  /// **Returns:**
  /// Sponsorship if found, null otherwise
  Future<Sponsorship?> getSponsorshipById(String sponsorshipId) async {
    try {
      _logger.info('Getting sponsorship by ID: $sponsorshipId', tag: _logName);
      
      final allSponsorships = await _getAllSponsorships();
      try {
        return allSponsorships.firstWhere(
          (s) => s.id == sponsorshipId,
        );
      } catch (e) {
        _logger.info('Sponsorship not found: $sponsorshipId', tag: _logName);
        return null;
      }
    } catch (e) {
      _logger.error('Error getting sponsorship by ID', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Update sponsorship status
  /// 
  /// **Flow:**
  /// 1. Get sponsorship by ID
  /// 2. Validate status transition
  /// 3. Update sponsorship status
  /// 4. If status is `approved`, check if can be locked
  /// 5. Return updated sponsorship
  /// 
  /// **Parameters:**
  /// - `sponsorshipId`: Sponsorship ID
  /// - `status`: New sponsorship status
  /// 
  /// **Returns:**
  /// Updated Sponsorship
  /// 
  /// **Throws:**
  /// - `Exception` if sponsorship not found
  /// - `Exception` if status transition is invalid
  Future<Sponsorship> updateSponsorshipStatus({
    required String sponsorshipId,
    required SponsorshipStatus status,
  }) async {
    try {
      _logger.info('Updating sponsorship status: $sponsorshipId -> ${status.name}', tag: _logName);
      
      final sponsorship = await getSponsorshipById(sponsorshipId);
      if (sponsorship == null) {
        throw Exception('Sponsorship not found: $sponsorshipId');
      }
      
      // Validate status transition
      if (!_isValidStatusTransition(sponsorship.status, status)) {
        throw Exception('Invalid status transition: ${sponsorship.status.name} -> ${status.name}');
      }
      
      // Update sponsorship
      final updated = sponsorship.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      
      // If status is `approved`, check if event is ready to lock
      if (status == SponsorshipStatus.approved) {
        // Check if event and all partnerships/sponsorships are approved
        final canLock = await _canLockEvent(sponsorship.eventId);
        if (canLock) {
          // Lock all sponsorships for this event
          final allSponsorships = await getSponsorshipsForEvent(sponsorship.eventId);
          for (final sp in allSponsorships) {
            if (sp.status == SponsorshipStatus.approved && !sp.isLocked) {
              await _saveSponsorship(sp.copyWith(
                status: SponsorshipStatus.locked,
                updatedAt: DateTime.now(),
              ));
            }
          }
          // Update this sponsorship to locked
          final locked = updated.copyWith(
            status: SponsorshipStatus.locked,
            updatedAt: DateTime.now(),
          );
          await _saveSponsorship(locked);
          _logger.info('Sponsorship locked: $sponsorshipId', tag: _logName);
          return locked;
        }
      }
      
      await _saveSponsorship(updated);
      _logger.info('Updated sponsorship status: $sponsorshipId', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating sponsorship status', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Check sponsorship eligibility
  /// 
  /// **Flow:**
  /// 1. Check event exists and is upcoming
  /// 2. Check brand is verified
  /// 3. Check compatibility (70%+)
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `brandId`: Brand ID
  /// 
  /// **Returns:**
  /// true if eligible, false otherwise
  Future<bool> checkSponsorshipEligibility({
    required String eventId,
    required String brandId,
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
      
      // Step 3: Check brand exists and is verified
      final brand = await getBrandById(brandId);
      if (brand == null) {
        _logger.info('Brand not found: $brandId', tag: _logName);
        return false;
      }
      
      if (!brand.isVerified) {
        _logger.info('Brand not verified: $brandId', tag: _logName);
        return false;
      }
      
      // Step 4: Check compatibility (70%+)
      final compatibility = await calculateCompatibility(
        eventId: eventId,
        brandId: brandId,
      );
      if (compatibility < 0.70) {
        _logger.info('Compatibility below 70% threshold: ${(compatibility * 100).toStringAsFixed(1)}%', tag: _logName);
        return false;
      }
      
      return true;
    } catch (e) {
      _logger.error('Error checking sponsorship eligibility', error: e, tag: _logName);
      return false;
    }
  }
  
  /// Calculate compatibility between brand and event
  /// 
  /// **Flow:**
  /// 1. Get brand account data
  /// 2. Get event data
  /// 3. Calculate compatibility score (0.0 to 1.0)
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `brandId`: Brand ID
  /// 
  /// **Returns:**
  /// Compatibility score (0.0 to 1.0)
  /// 
  /// **Note:**
  /// This is a simplified implementation. In production, this would:
  /// - Use sophisticated matching algorithm
  /// - Consider brand categories and event categories
  /// - Consider brand preferences and event details
  /// - Consider brand history and event history
  Future<double> calculateCompatibility({
    required String eventId,
    required String brandId,
  }) async {
    try {
      _logger.info('Calculating compatibility: event=$eventId, brand=$brandId', tag: _logName);
      
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        return 0.0;
      }
      
      final brand = await getBrandById(brandId);
      if (brand == null) {
        return 0.0;
      }
      
      // TODO: In production, integrate with sophisticated matching algorithm
      // For now, return a placeholder compatibility score
      // This should use:
      // - Brand categories vs event categories
      // - Brand preferences vs event details
      // - Brand history vs event history
      // - Similar vibe matching to PartnershipMatchingService
      
      // Placeholder: Return 0.75 (75% compatibility) for now
      // This ensures sponsorships can be created for testing
      // In production, replace with actual compatibility calculation
      return 0.75;
    } catch (e) {
      _logger.error('Error calculating compatibility', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  /// Get brand by ID (helper method)
  /// 
  /// **Note:** In production, this would come from BrandService
  Future<BrandAccount?> getBrandById(String brandId) async {
    try {
      return _brandAccounts[brandId];
    } catch (e) {
      _logger.error('Error getting brand by ID', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Register brand account (helper method for testing)
  /// 
  /// **Note:** In production, this would be handled by BrandService
  Future<void> registerBrand(BrandAccount brand) async {
    try {
      _brandAccounts[brand.id] = brand;
      _logger.info('Registered brand: ${brand.id}', tag: _logName);
    } catch (e) {
      _logger.error('Error registering brand', error: e, tag: _logName);
      rethrow;
    }
  }
  
  // Private helper methods
  
  String _generateSponsorshipId() {
    return 'sponsorship_${_uuid.v4()}';
  }
  
  Future<void> _saveSponsorship(Sponsorship sponsorship) async {
    // In production, save to database
    _sponsorships[sponsorship.id] = sponsorship;
  }
  
  Future<List<Sponsorship>> _getAllSponsorships() async {
    // In production, query database
    return _sponsorships.values.toList();
  }
  
  /// Check if event can be locked (all partnerships and sponsorships approved)
  Future<bool> _canLockEvent(String eventId) async {
    try {
      // Check all partnerships are approved
      final partnerships = await _partnershipService.getPartnershipsForEvent(eventId);
      for (final partnership in partnerships) {
        if (!partnership.isApproved && !partnership.isLocked) {
          return false;
        }
      }
      
      // Check all sponsorships are approved
      final sponsorships = await getSponsorshipsForEvent(eventId);
      for (final sponsorship in sponsorships) {
        if (!sponsorship.isApproved && !sponsorship.isLocked) {
          return false;
        }
      }
      
      // Check event hasn't started
      final event = await _eventService.getEventById(eventId);
      if (event == null || event.hasStarted) {
        return false;
      }
      
      return true;
    } catch (e) {
      _logger.error('Error checking if event can be locked', error: e, tag: _logName);
      return false;
    }
  }
  
  /// Validate status transition
  bool _isValidStatusTransition(SponsorshipStatus current, SponsorshipStatus next) {
    // Define valid transitions
    switch (current) {
      case SponsorshipStatus.pending:
        return next == SponsorshipStatus.proposed || 
               next == SponsorshipStatus.cancelled;
      case SponsorshipStatus.proposed:
        return next == SponsorshipStatus.negotiating ||
               next == SponsorshipStatus.approved ||
               next == SponsorshipStatus.cancelled;
      case SponsorshipStatus.negotiating:
        return next == SponsorshipStatus.approved ||
               next == SponsorshipStatus.cancelled;
      case SponsorshipStatus.approved:
        return next == SponsorshipStatus.locked ||
               next == SponsorshipStatus.cancelled;
      case SponsorshipStatus.locked:
        return next == SponsorshipStatus.active ||
               next == SponsorshipStatus.cancelled;
      case SponsorshipStatus.active:
        return next == SponsorshipStatus.completed ||
               next == SponsorshipStatus.disputed;
      case SponsorshipStatus.completed:
        return false; // Terminal state
      case SponsorshipStatus.cancelled:
        return false; // Terminal state
      case SponsorshipStatus.disputed:
        return next == SponsorshipStatus.cancelled ||
               next == SponsorshipStatus.completed;
    }
  }
}

