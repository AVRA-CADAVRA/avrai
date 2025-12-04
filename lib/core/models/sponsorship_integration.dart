import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/multi_party_sponsorship.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/models/brand_discovery.dart';

/// Sponsorship Integration Utilities
/// 
/// Provides helper methods and extensions for integrating sponsorship models
/// with existing partnership models.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to integrated brand partnerships
/// - Enables seamless model integration
/// - Supports multi-party event ecosystems
/// - Creates pathways for unified partnership management
/// 
/// **Usage:**
/// ```dart
/// // Check if partnership has sponsorships
/// final hasSponsors = partnership.hasSponsorships([sponsorship1, sponsorship2]);
/// 
/// // Get total sponsorship value for an event
/// final totalValue = getTotalSponsorshipValue([sponsorship1, sponsorship2]);
/// ```
class SponsorshipIntegration {
  /// Check if an event partnership has associated sponsorships
  static bool hasSponsorships(
    EventPartnership partnership,
    List<Sponsorship> sponsorships,
  ) {
    return sponsorships.any((s) => s.eventId == partnership.eventId);
  }

  /// Get all sponsorships for an event partnership
  static List<Sponsorship> getSponsorshipsForPartnership(
    EventPartnership partnership,
    List<Sponsorship> sponsorships,
  ) {
    return sponsorships
        .where((s) => s.eventId == partnership.eventId)
        .toList();
  }

  /// Get total sponsorship contribution value for an event
  static double getTotalSponsorshipValue(List<Sponsorship> sponsorships) {
    return sponsorships.fold<double>(
      0.0,
      (sum, sponsorship) => sum + sponsorship.totalContributionValue,
    );
  }

  /// Get total sponsorship value for a multi-party sponsorship
  static double getMultiPartyTotalValue(
    MultiPartySponsorship multiParty,
  ) {
    return multiParty.totalContributionValue;
  }

  /// Check if revenue split includes sponsorships
  static bool revenueSplitIncludesSponsorships(
    RevenueSplit revenueSplit,
    List<Sponsorship> sponsorships,
  ) {
    // Check if any split party is a sponsor
    return revenueSplit.parties.any((party) {
      return sponsorships.any((sponsorship) =>
          sponsorship.brandId == party.partyId &&
          sponsorship.eventId == revenueSplit.eventId);
    });
  }

  /// Get all brand IDs from sponsorships
  static List<String> getBrandIdsFromSponsorships(
    List<Sponsorship> sponsorships,
  ) {
    return sponsorships.map((s) => s.brandId).toList();
  }

  /// Get all brand IDs from multi-party sponsorship
  static List<String> getBrandIdsFromMultiParty(
    MultiPartySponsorship multiParty,
  ) {
    return multiParty.brandIds;
  }

  /// Check if sponsorship is part of multi-party sponsorship
  static bool isPartOfMultiParty(
    Sponsorship sponsorship,
    MultiPartySponsorship multiParty,
  ) {
    return multiParty.eventId == sponsorship.eventId &&
        multiParty.brandIds.contains(sponsorship.brandId);
  }

  /// Get active sponsorships count for an event
  static int getActiveSponsorshipsCount(
    String eventId,
    List<Sponsorship> sponsorships,
  ) {
    return sponsorships
        .where((s) =>
            s.eventId == eventId && s.status == SponsorshipStatus.active)
        .length;
  }

  /// Get approved sponsorships count for an event
  static int getApprovedSponsorshipsCount(
    String eventId,
    List<Sponsorship> sponsorships,
  ) {
    return sponsorships
        .where((s) =>
            s.eventId == eventId && s.isApproved)
        .length;
  }

  /// Get all brands from sponsorships
  static List<BrandAccount> getBrandsFromSponsorships(
    List<Sponsorship> sponsorships,
    List<BrandAccount> brands,
  ) {
    final brandIds = getBrandIdsFromSponsorships(sponsorships);
    return brands.where((brand) => brandIds.contains(brand.id)).toList();
  }

  /// Get product tracking for a sponsorship
  static List<ProductTracking> getProductTrackingForSponsorship(
    Sponsorship sponsorship,
    List<ProductTracking> productTracking,
  ) {
    return productTracking
        .where((pt) => pt.sponsorshipId == sponsorship.id)
        .toList();
  }

  /// Get total product sales value for a sponsorship
  static double getTotalProductSalesForSponsorship(
    Sponsorship sponsorship,
    List<ProductTracking> productTracking,
  ) {
    final tracking = getProductTrackingForSponsorship(
      sponsorship,
      productTracking,
    );
    return tracking.fold<double>(
      0.0,
      (sum, pt) => sum + pt.totalSales,
    );
  }

  /// Check if brand discovery has matches for event
  static bool hasDiscoveryMatches(
    String eventId,
    List<BrandDiscovery> discoveries,
  ) {
    return discoveries.any((d) =>
        d.eventId == eventId && d.hasViableMatches);
  }

  /// Get brand discovery for an event
  static BrandDiscovery? getDiscoveryForEvent(
    String eventId,
    List<BrandDiscovery> discoveries,
  ) {
    try {
      return discoveries.firstWhere((d) => d.eventId == eventId);
    } catch (e) {
      return null;
    }
  }

  /// Get all viable brand matches for an event
  static List<BrandMatch> getViableBrandMatches(
    String eventId,
    List<BrandDiscovery> discoveries,
  ) {
    final discovery = getDiscoveryForEvent(eventId, discoveries);
    if (discovery == null) return [];
    return discovery.viableMatches;
  }
}

/// Extension methods for EventPartnership to work with sponsorships
extension EventPartnershipSponsorshipExtension on EventPartnership {
  /// Check if this partnership has associated sponsorships
  bool hasSponsorships(List<Sponsorship> sponsorships) {
    return SponsorshipIntegration.hasSponsorships(this, sponsorships);
  }

  /// Get associated sponsorships
  List<Sponsorship> getSponsorships(List<Sponsorship> sponsorships) {
    return SponsorshipIntegration.getSponsorshipsForPartnership(
      this,
      sponsorships,
    );
  }

  /// Get total sponsorship value for this partnership's event
  double getTotalSponsorshipValue(List<Sponsorship> sponsorships) {
    final eventSponsorships = getSponsorships(sponsorships);
    return SponsorshipIntegration.getTotalSponsorshipValue(eventSponsorships);
  }
}

