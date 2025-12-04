import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/logger.dart';

/// Partnership Matching Service
/// 
/// Vibe-based partnership matching and suggestions.
/// 
/// **Philosophy Alignment:**
/// - Only suggests partnerships with 70%+ compatibility
/// - Reduces spam and mismatches
/// - Higher acceptance rates
/// - Both parties can still decline (but rarely need to)
/// 
/// **Responsibilities:**
/// - Vibe-based matching algorithm
/// - Compatibility scoring
/// - Partnership suggestions
class PartnershipMatchingService {
  static const String _logName = 'PartnershipMatchingService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final PartnershipService _partnershipService;
  final BusinessService _businessService;
  final ExpertiseEventService _eventService;
  
  PartnershipMatchingService({
    required PartnershipService partnershipService,
    required BusinessService businessService,
    required ExpertiseEventService eventService,
  }) : _partnershipService = partnershipService,
       _businessService = businessService,
       _eventService = eventService;
  
  /// Find matching partners for an event
  /// 
  /// **Flow:**
  /// 1. Get event details
  /// 2. Get user personality/vibe data
  /// 3. Find businesses in same category/location
  /// 4. Calculate compatibility for each business
  /// 5. Filter by minCompatibility (70%+)
  /// 6. Return suggestions sorted by compatibility
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  /// - `minCompatibility`: Minimum compatibility threshold (default: 0.70 = 70%)
  /// 
  /// **Returns:**
  /// List of PartnershipSuggestion sorted by compatibility (highest first)
  Future<List<PartnershipSuggestion>> findMatchingPartners({
    required String userId,
    required String eventId,
    double minCompatibility = 0.70, // 70% threshold
  }) async {
    try {
      _logger.info('Finding matching partners: user=$userId, event=$eventId', tag: _logName);
      
      // Step 1: Get event details
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        _logger.info('Event not found: $eventId', tag: _logName);
        return [];
      }
      
      // Step 2: Find businesses in same category/location
      final businesses = await _businessService.findBusinesses(
        category: event.category,
        location: event.location,
        verifiedOnly: true, // Only verified businesses
        maxResults: 50, // Get more candidates for filtering
      );
      
      // Step 3: Calculate compatibility for each business
      final suggestions = <PartnershipSuggestion>[];
      
      for (final business in businesses) {
        // Check if business is eligible
        final isEligible = await _businessService.checkBusinessEligibility(business.id);
        if (!isEligible) {
          continue;
        }
        
        // Calculate compatibility
        final compatibility = await calculateCompatibility(
          userId: userId,
          businessId: business.id,
        );
        
        // Filter by minCompatibility (70%+)
        if (compatibility >= minCompatibility) {
          suggestions.add(PartnershipSuggestion(
            businessId: business.id,
            business: business,
            compatibility: compatibility,
            eventId: eventId,
            reason: _getCompatibilityReason(compatibility),
          ));
        }
      }
      
      // Step 4: Sort by compatibility (highest first)
      suggestions.sort((a, b) => b.compatibility.compareTo(a.compatibility));
      
      _logger.info('Found ${suggestions.length} matching partners (>=${(minCompatibility * 100).toStringAsFixed(0)}% compatibility)', tag: _logName);
      return suggestions;
    } catch (e) {
      _logger.error('Error finding matching partners', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Calculate compatibility score between user and business
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
  /// **Compatibility Formula:**
  /// ```
  /// compatibility = (
  ///   valueAlignment * 0.25 +
  ///   qualityFocus * 0.25 +
  ///   communityOrientation * 0.20 +
  ///   eventStyleMatch * 0.20 +
  ///   authenticityMatch * 0.10
  /// )
  /// ```
  Future<double> calculateCompatibility({
    required String userId,
    required String businessId,
  }) async {
    try {
      _logger.info('Calculating compatibility: user=$userId, business=$businessId', tag: _logName);
      
      // Use PartnershipService to calculate compatibility
      // This delegates to the actual vibe calculation
      final compatibility = await _partnershipService.calculateVibeCompatibility(
        userId: userId,
        businessId: businessId,
      );
      
      return compatibility;
    } catch (e) {
      _logger.error('Error calculating compatibility', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  /// Get partnership suggestions for an event
  /// 
  /// **Flow:**
  /// 1. Get event details
  /// 2. Get event host (user)
  /// 3. Find matching partners
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// List of PartnershipSuggestion
  Future<List<PartnershipSuggestion>> getSuggestions({
    required String eventId,
  }) async {
    try {
      _logger.info('Getting partnership suggestions for event: $eventId', tag: _logName);
      
      // Get event details
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        _logger.info('Event not found: $eventId', tag: _logName);
        return [];
      }
      
      // Get event host (user)
      final userId = event.host.id;
      
      // Find matching partners
      return await findMatchingPartners(
        userId: userId,
        eventId: eventId,
      );
    } catch (e) {
      _logger.error('Error getting suggestions', error: e, tag: _logName);
      return [];
    }
  }
  
  // Private helper methods
  
  String _getCompatibilityReason(double compatibility) {
    if (compatibility >= 0.90) {
      return 'Excellent match - High compatibility';
    } else if (compatibility >= 0.80) {
      return 'Great match - Strong compatibility';
    } else if (compatibility >= 0.70) {
      return 'Good match - Compatible partnership';
    } else {
      return 'Moderate match';
    }
  }
}

/// Partnership Suggestion
/// 
/// Represents a suggested partnership match.
class PartnershipSuggestion {
  final String businessId;
  final BusinessAccount? business;
  final double compatibility; // 0.0 to 1.0
  final String eventId;
  final String reason; // Why this is a good match
  
  PartnershipSuggestion({
    required this.businessId,
    this.business,
    required this.compatibility,
    required this.eventId,
    required this.reason,
  });
  
  /// Get compatibility percentage
  int get compatibilityPercentage => (compatibility * 100).round();
  
  /// Check if suggestion meets minimum threshold (70%+)
  bool get meetsThreshold => compatibility >= 0.70;
  
  @override
  String toString() {
    return 'PartnershipSuggestion(business: $businessId, compatibility: ${compatibilityPercentage}%, reason: $reason)';
  }
}

