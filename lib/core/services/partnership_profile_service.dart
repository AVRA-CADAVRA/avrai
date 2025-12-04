import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/partnership_expertise_boost.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/logger.dart';

/// Partnership Profile Service
/// 
/// Service for managing partnership visibility on user profiles and calculating
/// expertise boosts from partnerships.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to showcasing professional collaborations
/// - Enables visibility of authentic partnerships
/// - Supports expertise recognition through partnerships
/// 
/// **Responsibilities:**
/// - Get user partnerships (all, active, completed, by type)
/// - Calculate partnership expertise boost
/// - Integrate with PartnershipService, SponsorshipService, BusinessService (read-only)
/// - Support privacy/visibility controls
class PartnershipProfileService {
  static const String _logName = 'PartnershipProfileService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final PartnershipService _partnershipService;
  final SponsorshipService _sponsorshipService;
  final BusinessService _businessService;
  final ExpertiseEventService _eventService;

  PartnershipProfileService({
    required PartnershipService partnershipService,
    required SponsorshipService sponsorshipService,
    required BusinessService businessService,
    required ExpertiseEventService eventService,
  })  : _partnershipService = partnershipService,
        _sponsorshipService = sponsorshipService,
        _businessService = businessService,
        _eventService = eventService;

  /// Get all partnerships for a user
  /// 
  /// **Flow:**
  /// 1. Get all EventPartnerships for user
  /// 2. Get all Sponsorships for user's events
  /// 3. Convert to UserPartnership models
  /// 4. Apply privacy/visibility filters
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// List of UserPartnership records
  Future<List<UserPartnership>> getUserPartnerships(String userId) async {
    try {
      _logger.info('Getting all partnerships for user: $userId', tag: _logName);

      final partnerships = <UserPartnership>[];

      // Get business partnerships (EventPartnership)
      final businessPartnerships = await _getBusinessPartnerships(userId);
      partnerships.addAll(businessPartnerships);

      // Get brand partnerships (Sponsorship)
      final brandPartnerships = await _getBrandPartnerships(userId);
      partnerships.addAll(brandPartnerships);

      // Get company partnerships (future: corporate sponsorships)
      // For now, company partnerships are empty
      // final companyPartnerships = await _getCompanyPartnerships(userId);
      // partnerships.addAll(companyPartnerships);

      _logger.info(
        'Found ${partnerships.length} partnerships for user: $userId',
        tag: _logName,
      );

      return partnerships;
    } catch (e) {
      _logger.error('Error getting user partnerships', error: e, tag: _logName);
      return [];
    }
  }

  /// Get active partnerships only
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// List of active UserPartnership records
  Future<List<UserPartnership>> getActivePartnerships(String userId) async {
    try {
      _logger.info('Getting active partnerships for user: $userId', tag: _logName);

      final allPartnerships = await getUserPartnerships(userId);
      final active = allPartnerships
          .where((p) => p.isActive)
          .toList()
        ..sort((a, b) {
          // Sort by start date (most recent first)
          if (a.startDate != null && b.startDate != null) {
            return b.startDate!.compareTo(a.startDate!);
          }
          return 0;
        });

      _logger.info(
        'Found ${active.length} active partnerships for user: $userId',
        tag: _logName,
      );

      return active;
    } catch (e) {
      _logger.error(
        'Error getting active partnerships',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get completed partnerships only
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// 
  /// **Returns:**
  /// List of completed UserPartnership records
  Future<List<UserPartnership>> getCompletedPartnerships(String userId) async {
    try {
      _logger.info(
        'Getting completed partnerships for user: $userId',
        tag: _logName,
      );

      final allPartnerships = await getUserPartnerships(userId);
      final completed = allPartnerships
          .where((p) => p.isCompleted)
          .toList()
        ..sort((a, b) {
          // Sort by end date (most recent first)
          if (a.endDate != null && b.endDate != null) {
            return b.endDate!.compareTo(a.endDate!);
          }
          return 0;
        });

      _logger.info(
        'Found ${completed.length} completed partnerships for user: $userId',
        tag: _logName,
      );

      return completed;
    } catch (e) {
      _logger.error(
        'Error getting completed partnerships',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get partnerships by type
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `type`: Partnership type (business, brand, company)
  /// 
  /// **Returns:**
  /// List of UserPartnership records of specified type
  Future<List<UserPartnership>> getPartnershipsByType(
    String userId,
    ProfilePartnershipType type,
  ) async {
    try {
      _logger.info(
        'Getting partnerships by type for user: $userId, type: ${type.name}',
        tag: _logName,
      );

      final allPartnerships = await getUserPartnerships(userId);
      final filtered = allPartnerships
          .where((p) => p.type == type)
          .toList()
        ..sort((a, b) {
          // Sort by start date (most recent first)
          if (a.startDate != null && b.startDate != null) {
            return b.startDate!.compareTo(a.startDate!);
          }
          return 0;
        });

      _logger.info(
        'Found ${filtered.length} partnerships of type ${type.name} for user: $userId',
        tag: _logName,
      );

      return filtered;
    } catch (e) {
      _logger.error(
        'Error getting partnerships by type',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Calculate partnership expertise boost for a category
  /// 
  /// **Flow:**
  /// 1. Get all partnerships for user
  /// 2. Filter by category alignment
  /// 3. Calculate status boost
  /// 4. Calculate quality boost
  /// 5. Apply category alignment multiplier
  /// 6. Apply count multiplier
  /// 7. Cap at 0.50 (50% max)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category to calculate boost for
  /// 
  /// **Returns:**
  /// PartnershipExpertiseBoost with breakdown
  Future<PartnershipExpertiseBoost> getPartnershipExpertiseBoost(
    String userId,
    String category,
  ) async {
    try {
      _logger.info(
        'Calculating partnership expertise boost: user=$userId, category=$category',
        tag: _logName,
      );

      final allPartnerships = await getUserPartnerships(userId);

      // Initialize boost tracking
      double activeBoost = 0.0;
      double completedBoost = 0.0;
      double ongoingBoost = 0.0;
      double vibeCompatibilityBoost = 0.0;
      double revenueSuccessBoost = 0.0;
      double feedbackBoost = 0.0;
      double sameCategoryBoost = 0.0;
      double relatedCategoryBoost = 0.0;
      double unrelatedCategoryBoost = 0.0;

      // Calculate boost for each partnership
      for (final partnership in allPartnerships) {
        // Status boost
        double statusBoost = 0.0;
        if (partnership.status == PartnershipStatus.active) {
          statusBoost = 0.05;
          activeBoost += 0.05;
        } else if (partnership.status == PartnershipStatus.completed) {
          statusBoost = 0.10;
          completedBoost += 0.10;
        } else if (partnership.isOngoing) {
          statusBoost = 0.08;
          ongoingBoost += 0.08;
        }

        // Quality boost
        double qualityBoost = 0.0;
        if (partnership.vibeCompatibility != null &&
            partnership.vibeCompatibility! >= 0.8) {
          qualityBoost += 0.02;
          vibeCompatibilityBoost += 0.02;
        }

        // Revenue success and feedback boost
        // Note: These would need to be calculated from partnership data
        // For now, we'll use placeholder logic
        // In production, check revenue split success and feedback ratings
        // revenueSuccessBoost += 0.03; // If partnership had successful revenue
        // feedbackBoost += 0.02; // If partnership had positive feedback

        // Category alignment
        double alignmentMultiplier = 1.0;
        if (partnership.category == category) {
          alignmentMultiplier = 1.0; // Same category: 100%
          sameCategoryBoost += (statusBoost + qualityBoost);
        } else if (_isRelatedCategory(partnership.category, category)) {
          alignmentMultiplier = 0.5; // Related category: 50%
          relatedCategoryBoost += (statusBoost + qualityBoost) * 0.5;
        } else if (partnership.category != null) {
          alignmentMultiplier = 0.25; // Unrelated category: 25%
          unrelatedCategoryBoost += (statusBoost + qualityBoost) * 0.25;
        } else {
          // No category specified - treat as unrelated
          alignmentMultiplier = 0.25;
          unrelatedCategoryBoost += (statusBoost + qualityBoost) * 0.25;
        }
      }

      // Calculate total boost before multiplier
      double totalBoost = sameCategoryBoost +
          relatedCategoryBoost +
          unrelatedCategoryBoost;

      // Apply count multiplier
      int partnershipCount = allPartnerships.length;
      double countMultiplier = 1.0;
      if (partnershipCount >= 6) {
        countMultiplier = 1.5;
      } else if (partnershipCount >= 3) {
        countMultiplier = 1.2;
      }

      totalBoost *= countMultiplier;

      // Cap at 0.50 (50% max boost)
      totalBoost = totalBoost.clamp(0.0, 0.50);

      final boost = PartnershipExpertiseBoost(
        totalBoost: totalBoost,
        activeBoost: activeBoost,
        completedBoost: completedBoost,
        ongoingBoost: ongoingBoost,
        vibeCompatibilityBoost: vibeCompatibilityBoost,
        revenueSuccessBoost: revenueSuccessBoost,
        feedbackBoost: feedbackBoost,
        sameCategoryBoost: sameCategoryBoost,
        relatedCategoryBoost: relatedCategoryBoost,
        unrelatedCategoryBoost: unrelatedCategoryBoost,
        countMultiplier: countMultiplier,
        partnershipCount: partnershipCount,
      );

      _logger.info(
        'Partnership expertise boost calculated: ${(totalBoost * 100).toStringAsFixed(1)}%',
        tag: _logName,
      );

      return boost;
    } catch (e) {
      _logger.error(
        'Error calculating partnership expertise boost',
        error: e,
        tag: _logName,
      );
      return const PartnershipExpertiseBoost(totalBoost: 0.0);
    }
  }

  // Private helper methods

  /// Get business partnerships (EventPartnership)
  Future<List<UserPartnership>> _getBusinessPartnerships(String userId) async {
    try {
      final partnerships = <UserPartnership>[];

      // Get all partnerships from PartnershipService
      // Note: PartnershipService doesn't have getUserPartnerships method,
      // so we need to get all partnerships and filter by userId
      // In production, this would be a direct database query
      final allEventPartnerships = await _getAllEventPartnershipsForUser(userId);

      for (final eventPartnership in allEventPartnerships) {
        // Get business details
        final business = await _businessService.getBusinessById(
          eventPartnership.businessId,
        );

        if (business == null) continue;

        // Get event to determine category
        final event = await _eventService.getEventById(eventPartnership.eventId);
        final category = event?.category;

        // Count events in this partnership
        final eventCount = eventPartnership.eventIds.length > 0
            ? eventPartnership.eventIds.length
            : (eventPartnership.eventId.isNotEmpty ? 1 : 0);

        final userPartnership = UserPartnership(
          id: eventPartnership.id,
          type: ProfilePartnershipType.business,
          partnerId: eventPartnership.businessId,
          partnerName: business.name,
          partnerLogoUrl: business.logoUrl,
          status: eventPartnership.status,
          startDate: eventPartnership.startDate,
          endDate: eventPartnership.endDate,
          category: category,
          vibeCompatibility: eventPartnership.vibeCompatibilityScore,
          eventCount: eventCount,
          isPublic: true, // Default to public, user can change later
        );

        partnerships.add(userPartnership);
      }

      return partnerships;
    } catch (e) {
      _logger.error(
        'Error getting business partnerships',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get brand partnerships (Sponsorship)
  Future<List<UserPartnership>> _getBrandPartnerships(String userId) async {
    try {
      final partnerships = <UserPartnership>[];

      // Get user's events
      // Note: In production, this would be more efficient
      final userEvents = await _getUserEvents(userId);

      for (final event in userEvents) {
        // Get sponsorships for this event
        final sponsorships = await _sponsorshipService.getSponsorshipsForEvent(
          event.id,
        );

        for (final sponsorship in sponsorships) {
          // Get brand details
          final brand = await _sponsorshipService.getBrandById(
            sponsorship.brandId,
          );

          if (brand == null) continue;

          // Only include active, locked, or completed sponsorships
          if (sponsorship.status != SponsorshipStatus.active &&
              sponsorship.status != SponsorshipStatus.locked &&
              sponsorship.status != SponsorshipStatus.completed) {
            continue;
          }

          // Map sponsorship status to partnership status
          PartnershipStatus partnershipStatus;
          if (sponsorship.status == SponsorshipStatus.active ||
              sponsorship.status == SponsorshipStatus.locked) {
            partnershipStatus = PartnershipStatus.active;
          } else if (sponsorship.status == SponsorshipStatus.completed) {
            partnershipStatus = PartnershipStatus.completed;
          } else {
            continue; // Skip other statuses
          }

          final userPartnership = UserPartnership(
            id: sponsorship.id,
            type: ProfilePartnershipType.brand,
            partnerId: sponsorship.brandId,
            partnerName: brand.name,
            partnerLogoUrl: brand.logoUrl,
            status: partnershipStatus,
            startDate: sponsorship.createdAt,
            endDate: null, // Sponsorships don't have end dates yet
            category: event.category,
            vibeCompatibility: null, // Sponsorships don't have vibe compatibility yet
            eventCount: 1, // One event per sponsorship
            isPublic: true, // Default to public
          );

          partnerships.add(userPartnership);
        }
      }

      return partnerships;
    } catch (e) {
      _logger.error(
        'Error getting brand partnerships',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get all EventPartnerships for a user
  /// 
  /// Note: This is a workaround since PartnershipService doesn't have
  /// getUserPartnerships method. In production, this would be a direct query.
  Future<List<EventPartnership>> _getAllEventPartnershipsForUser(
    String userId,
  ) async {
    try {
      // Get user's events
      final userEvents = await _getUserEvents(userId);

      final allPartnerships = <EventPartnership>[];

      // Get partnerships for each event
      for (final event in userEvents) {
        final partnerships = await _partnershipService.getPartnershipsForEvent(
          event.id,
        );

        // Filter by userId (user must be the partner)
        for (final partnership in partnerships) {
          if (partnership.userId == userId) {
            allPartnerships.add(partnership);
          }
        }
      }

      return allPartnerships;
    } catch (e) {
      _logger.error(
        'Error getting event partnerships for user',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get user's events
  /// 
  /// Note: This creates a minimal UnifiedUser from userId.
  /// In production, this would get UnifiedUser from UserService.
  Future<List<ExpertiseEvent>> _getUserEvents(String userId) async {
    try {
      // Create minimal UnifiedUser for getEventsByHost
      // In production, this would come from UserService
      final user = UnifiedUser(
        id: userId,
        email: '$userId@spots.local', // Placeholder email
        displayName: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
      );

      return await _eventService.getEventsByHost(user);
    } catch (e) {
      _logger.error('Error getting user events', error: e, tag: _logName);
      return [];
    }
  }

  /// Check if two categories are related
  /// 
  /// **Logic:**
  /// - Same category: 100% alignment
  /// - Related categories: 50% alignment (share common words or are in related list)
  /// - Unrelated: 25% alignment
  bool _isRelatedCategory(String? category1, String? category2) {
    if (category1 == null || category2 == null) {
      return false;
    }

    if (category1.toLowerCase() == category2.toLowerCase()) {
      return false; // Same category, not "related"
    }

    // Check if categories share common words
    final words1 = category1.toLowerCase().split(RegExp(r'[\s\-_]+'));
    final words2 = category2.toLowerCase().split(RegExp(r'[\s\-_]+'));

    final commonWords = words1.where((w) => words2.contains(w)).toList();
    if (commonWords.isNotEmpty) {
      return true;
    }

    // Check predefined related categories
    // In production, this would be a more sophisticated matching system
    final relatedCategories = {
      'coffee': ['cafe', 'restaurant', 'food'],
      'restaurant': ['food', 'dining', 'cafe'],
      'bar': ['nightlife', 'entertainment', 'restaurant'],
      'music': ['entertainment', 'nightlife', 'events'],
      'art': ['culture', 'gallery', 'museum'],
      'fitness': ['health', 'wellness', 'sports'],
      'sports': ['fitness', 'health', 'recreation'],
    };

    final cat1Lower = category1.toLowerCase();
    final cat2Lower = category2.toLowerCase();

    for (final entry in relatedCategories.entries) {
      if (entry.key == cat1Lower && entry.value.contains(cat2Lower)) {
        return true;
      }
      if (entry.key == cat2Lower && entry.value.contains(cat1Lower)) {
        return true;
      }
    }

    return false;
  }
}

