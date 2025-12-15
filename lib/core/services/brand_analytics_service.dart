import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/product_sales_service.dart';
import 'package:spots/core/services/revenue_split_service.dart';
import 'package:spots/core/services/logger.dart';

/// Brand Analytics Service
///
/// Service for tracking brand ROI, performance metrics, and analytics.
///
/// **Philosophy Alignment:**
/// - Opens doors to brand insights
/// - Enables performance tracking
/// - Supports data-driven decisions
/// - Creates pathways for brand success
///
/// **Responsibilities:**
/// - ROI tracking for brands
/// - Performance metrics
/// - Brand exposure analytics
/// - Event performance tracking
class BrandAnalyticsService {
  static const String _logName = 'BrandAnalyticsService';
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  final SponsorshipService _sponsorshipService;
  final ProductTrackingService _productTrackingService;
  final ProductSalesService _productSalesService;
  final RevenueSplitService _revenueSplitService;

  BrandAnalyticsService({
    required SponsorshipService sponsorshipService,
    required ProductTrackingService productTrackingService,
    required ProductSalesService productSalesService,
    required RevenueSplitService revenueSplitService,
  })  : _sponsorshipService = sponsorshipService,
        _productTrackingService = productTrackingService,
        _productSalesService = productSalesService,
        _revenueSplitService = revenueSplitService;

  /// Calculate brand ROI
  ///
  /// **Flow:**
  /// 1. Get all sponsorships for brand
  /// 2. Calculate total investment (contributions)
  /// 3. Calculate total revenue (from revenue splits)
  /// 4. Calculate ROI = ((Revenue - Investment) / Investment) * 100
  ///
  /// **Parameters:**
  /// - `brandId`: Brand ID
  /// - `startDate`: Start date (optional)
  /// - `endDate`: End date (optional)
  ///
  /// **Returns:**
  /// BrandROI with investment, revenue, and ROI percentage
  Future<BrandROI> calculateBrandROI({
    required String brandId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // #region agent log
      _logger.info(
          'Calculating brand ROI: brand=$brandId, startDate=$startDate, endDate=$endDate',
          tag: _logName);
      // #endregion

      // Step 1: Get all sponsorships for brand (filtered by date)
      // Calculate investment from sponsorship contribution amounts
      double totalInvestment = await _calculateBrandInvestment(
        brandId: brandId,
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate revenue (from revenue splits)
      double totalRevenue = await _calculateBrandRevenue(
        brandId: brandId,
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate product revenue from product sales
      double totalProductRevenue = 0.0;
      try {
        final sponsorships =
            await _sponsorshipService.getSponsorshipsForBrand(brandId);
        for (final sponsorship in sponsorships) {
          // Filter by date if provided
          if (startDate != null && sponsorship.createdAt.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && sponsorship.createdAt.isAfter(endDate)) {
            continue;
          }

          if (sponsorship.type == SponsorshipType.product ||
              sponsorship.type == SponsorshipType.hybrid) {
            try {
              final productRevenue =
                  await _productSalesService.calculateProductRevenue(
                sponsorshipId: sponsorship.id,
                startDate: startDate,
                endDate: endDate,
              );
              totalProductRevenue += productRevenue;
            } catch (e) {
              // #region agent log
              _logger.warn(
                  'Error calculating product revenue for sponsorship ${sponsorship.id}: $e',
                  tag: _logName);
              // #endregion
            }
          }
        }
      } catch (e) {
        // #region agent log
        _logger.warn('Error calculating product revenue: $e', tag: _logName);
        // #endregion
      }

      // Total revenue includes both revenue splits and product sales
      final combinedRevenue = totalRevenue + totalProductRevenue;

      // Calculate ROI
      double roiPercentage = 0.0;
      if (totalInvestment > 0) {
        roiPercentage =
            ((combinedRevenue - totalInvestment) / totalInvestment) * 100;
      }

      final roi = BrandROI(
        brandId: brandId,
        totalInvestment: totalInvestment,
        totalRevenue: combinedRevenue,
        netProfit: combinedRevenue - totalInvestment,
        roiPercentage: roiPercentage,
        startDate: startDate,
        endDate: endDate,
        calculatedAt: DateTime.now(),
      );

      // #region agent log
      _logger.info(
          'Brand ROI for $brandId: investment=$totalInvestment, revenue=$combinedRevenue (revenueSplits=$totalRevenue, productSales=$totalProductRevenue), netProfit=${roi.netProfit}, roiPercentage=${roiPercentage.toStringAsFixed(2)}%',
          tag: _logName);
      // #endregion
      return roi;
    } catch (e) {
      // #region agent log
      _logger.error('Error calculating brand ROI', error: e, tag: _logName);
      // #endregion
      rethrow;
    }
  }

  /// Get brand performance metrics
  ///
  /// **Flow:**
  /// 1. Get brand statistics
  /// 2. Calculate metrics
  /// 3. Return performance metrics
  ///
  /// **Parameters:**
  /// - `brandId`: Brand ID
  ///
  /// **Returns:**
  /// BrandPerformance with metrics
  Future<BrandPerformance> getBrandPerformance({
    required String brandId,
  }) async {
    try {
      // #region agent log
      _logger.info('Getting brand performance: brand=$brandId', tag: _logName);
      // #endregion

      // Get all sponsorships for brand
      final sponsorships =
          await _sponsorshipService.getSponsorshipsForBrand(brandId);

      // Calculate active vs total sponsorships
      final activeSponsorships = sponsorships
          .where((s) => s.status == SponsorshipStatus.active)
          .length;
      final totalSponsorships = sponsorships.length;

      // Calculate total investment
      double totalInvestment = 0.0;
      for (final sponsorship in sponsorships) {
        totalInvestment += sponsorship.contributionAmount ?? 0.0;
        if (sponsorship.type == SponsorshipType.hybrid ||
            sponsorship.type == SponsorshipType.product) {
          totalInvestment += sponsorship.productValue ?? 0.0;
        }
      }

      // Calculate total revenue from revenue splits
      final totalRevenue =
          await _revenueSplitService.trackEarnings(partyId: brandId);

      // Calculate product revenue from product sales
      double totalProductRevenue = 0.0;
      for (final sponsorship in sponsorships) {
        if (sponsorship.type == SponsorshipType.product ||
            sponsorship.type == SponsorshipType.hybrid) {
          try {
            final productRevenue =
                await _productSalesService.calculateProductRevenue(
              sponsorshipId: sponsorship.id,
            );
            totalProductRevenue += productRevenue;
          } catch (e) {
            // #region agent log
            _logger.warn(
                'Error calculating product revenue for sponsorship ${sponsorship.id}: $e',
                tag: _logName);
            // #endregion
          }
        }
      }

      // Total revenue includes both revenue splits and product sales
      final combinedRevenue = totalRevenue + totalProductRevenue;

      // Calculate average ROI
      double averageROI = 0.0;
      if (totalInvestment > 0) {
        averageROI =
            ((combinedRevenue - totalInvestment) / totalInvestment) * 100;
      }

      // Count successful events (events with sponsorships)
      final eventIds = sponsorships.map((s) => s.eventId).toSet();
      final totalEvents = eventIds.length;
      final successfulEvents =
          totalEvents; // All events with sponsorships are considered successful

      final performance = BrandPerformance(
        brandId: brandId,
        activeSponsorships: activeSponsorships,
        totalSponsorships: totalSponsorships,
        totalInvestment: totalInvestment,
        totalRevenue: combinedRevenue,
        averageROI: averageROI,
        successfulEvents: successfulEvents,
        totalEvents: totalEvents,
        calculatedAt: DateTime.now(),
      );

      // #region agent log
      _logger.info(
          'Brand performance for $brandId calculated: activeSponsorships=$activeSponsorships, totalSponsorships=$totalSponsorships, totalInvestment=$totalInvestment, totalRevenue=$combinedRevenue, averageROI=${averageROI.toStringAsFixed(2)}%',
          tag: _logName);
      // #endregion
      return performance;
    } catch (e) {
      // #region agent log
      _logger.error('Error getting brand performance', error: e, tag: _logName);
      // #endregion
      rethrow;
    }
  }

  /// Analyze brand exposure
  ///
  /// **Flow:**
  /// 1. Get event details
  /// 2. Calculate exposure metrics
  /// 3. Return exposure analytics
  ///
  /// **Parameters:**
  /// - `brandId`: Brand ID
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// BrandExposure with exposure metrics
  Future<BrandExposure> analyzeBrandExposure({
    required String brandId,
    required String eventId,
  }) async {
    try {
      // #region agent log
      _logger.info('Analyzing brand exposure: brand=$brandId, event=$eventId',
          tag: _logName);
      // #endregion

      // Get sponsorships for this brand and event
      final sponsorships =
          await _sponsorshipService.getSponsorshipsForEvent(eventId);
      final brandSponsorships =
          sponsorships.where((s) => s.brandId == brandId).toList();

      if (brandSponsorships.isEmpty) {
        // #region agent log
        _logger.warn(
            'No sponsorships found for brand $brandId at event $eventId',
            tag: _logName);
        // #endregion
        return BrandExposure(
          brandId: brandId,
          eventId: eventId,
          estimatedReach: 0,
          productSales: 0,
          socialMediaMentions: 0,
          brandVisibilityScore: 0.0,
          calculatedAt: DateTime.now(),
        );
      }

      // Calculate product sales from product tracking
      int totalProductSales = 0;
      double productSalesValue = 0.0;

      for (final sponsorship in brandSponsorships) {
        if (sponsorship.type == SponsorshipType.product ||
            sponsorship.type == SponsorshipType.hybrid) {
          try {
            // Get product tracking for this sponsorship
            final productTrackingList = await _productTrackingService
                .getProductTrackingForSponsorship(sponsorship.id);

            for (final tracking in productTrackingList) {
              totalProductSales += tracking.quantitySold;
              productSalesValue += tracking.totalSales;
            }
          } catch (e) {
            // #region agent log
            _logger.warn(
                'Error getting product tracking for sponsorship ${sponsorship.id}: $e',
                tag: _logName);
            // #endregion
          }
        }
      }

      // Calculate estimated reach (based on sponsorship value and product sales)
      // Higher sponsorship value and product sales = higher reach
      double totalSponsorshipValue = 0.0;
      for (final sponsorship in brandSponsorships) {
        totalSponsorshipValue += sponsorship.totalContributionValue;
      }

      // Estimate reach: sponsorship value * 10 (rough estimate of attendees per dollar)
      final estimatedReach = (totalSponsorshipValue * 10).round();

      // Calculate brand visibility score (0-100)
      // Based on: sponsorship value, product sales, and number of sponsorships
      double visibilityScore = 0.0;
      if (totalSponsorshipValue > 0) {
        // Base score from sponsorship value (0-50 points)
        visibilityScore += (totalSponsorshipValue / 1000).clamp(0.0, 50.0);
      }
      if (productSalesValue > 0) {
        // Score from product sales (0-30 points)
        visibilityScore += (productSalesValue / 500).clamp(0.0, 30.0);
      }
      if (brandSponsorships.length > 0) {
        // Score from number of sponsorships (0-20 points)
        visibilityScore += (brandSponsorships.length * 5).clamp(0.0, 20.0);
      }

      final exposure = BrandExposure(
        brandId: brandId,
        eventId: eventId,
        estimatedReach: estimatedReach,
        productSales: totalProductSales,
        socialMediaMentions:
            0, // TODO: Integrate with social media tracking when available
        brandVisibilityScore: visibilityScore.clamp(0.0, 100.0),
        calculatedAt: DateTime.now(),
      );

      // #region agent log
      _logger.info(
          'Brand exposure analyzed for $brandId at $eventId: estimatedReach=$estimatedReach, productSales=$totalProductSales, productSalesValue=$productSalesValue, visibilityScore=${exposure.brandVisibilityScore.toStringAsFixed(2)}',
          tag: _logName);
      // #endregion
      return exposure;
    } catch (e) {
      // #region agent log
      _logger.error('Error analyzing brand exposure', error: e, tag: _logName);
      // #endregion
      rethrow;
    }
  }

  /// Get event performance
  ///
  /// **Flow:**
  /// 1. Get event details
  /// 2. Get sponsorships for event
  /// 3. Calculate performance metrics
  /// 4. Return performance
  ///
  /// **Parameters:**
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// EventPerformance with metrics
  Future<EventPerformance> getEventPerformance({
    required String eventId,
  }) async {
    try {
      // #region agent log
      _logger.info('Getting event performance: event=$eventId', tag: _logName);
      // #endregion

      // Get sponsorships for event
      final sponsorships =
          await _sponsorshipService.getSponsorshipsForEvent(eventId);

      // Calculate performance metrics
      double totalSponsorshipValue = 0.0;
      int productContributionCount = 0;
      double totalProductSalesValue = 0.0;

      for (final sponsorship in sponsorships) {
        totalSponsorshipValue += sponsorship.totalContributionValue;

        if (sponsorship.type == SponsorshipType.product ||
            sponsorship.type == SponsorshipType.hybrid) {
          productContributionCount++;

          // Get product sales value for this sponsorship
          try {
            final productRevenue =
                await _productSalesService.calculateProductRevenue(
              sponsorshipId: sponsorship.id,
            );
            totalProductSalesValue += productRevenue;
          } catch (e) {
            // #region agent log
            _logger.warn(
                'Error calculating product revenue for sponsorship ${sponsorship.id}: $e',
                tag: _logName);
            // #endregion
          }
        }
      }

      final performance = EventPerformance(
        eventId: eventId,
        totalSponsorships: sponsorships.length,
        totalSponsorshipValue: totalSponsorshipValue +
            totalProductSalesValue, // Include product sales in total value
        productContributions: productContributionCount,
        financialContributions: sponsorships
            .where((s) =>
                s.type == SponsorshipType.financial ||
                s.type == SponsorshipType.hybrid)
            .length,
        calculatedAt: DateTime.now(),
      );

      // #region agent log
      _logger.info(
          'Event performance for $eventId calculated: totalSponsorships=${sponsorships.length}, totalSponsorshipValue=$totalSponsorshipValue, productSalesValue=$totalProductSalesValue, productContributions=$productContributionCount',
          tag: _logName);
      // #endregion
      return performance;
    } catch (e) {
      // #region agent log
      _logger.error('Error getting event performance', error: e, tag: _logName);
      // #endregion
      rethrow;
    }
  }

  // Private helper methods

  Future<double> _calculateBrandInvestment({
    required String brandId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Calculate investment from sponsorship contribution amounts
    try {
      final sponsorships =
          await _sponsorshipService.getSponsorshipsForBrand(brandId);

      double totalInvestment = 0.0;
      for (final sponsorship in sponsorships) {
        // Filter by date if provided
        if (startDate != null && sponsorship.createdAt.isBefore(startDate)) {
          continue;
        }
        if (endDate != null && sponsorship.createdAt.isAfter(endDate)) {
          continue;
        }

        // Sum contribution amounts (financial + product value for hybrid)
        totalInvestment += sponsorship.contributionAmount ?? 0.0;
        if (sponsorship.type == SponsorshipType.hybrid ||
            sponsorship.type == SponsorshipType.product) {
          totalInvestment += sponsorship.productValue ?? 0.0;
        }
      }

      return totalInvestment;
    } catch (e) {
      _logger.error('Error calculating brand investment',
          error: e, tag: _logName);
      return 0.0;
    }
  }

  Future<double> _calculateBrandRevenue({
    required String brandId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Calculate revenue from revenue splits where brand is a party
    // Use RevenueSplitService to track earnings for the brand
    return await _revenueSplitService.trackEarnings(
      partyId: brandId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// Brand ROI
///
/// Represents ROI calculation for a brand.
class BrandROI {
  final String brandId;
  final double totalInvestment;
  final double totalRevenue;
  final double netProfit;
  final double roiPercentage;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime calculatedAt;

  const BrandROI({
    required this.brandId,
    required this.totalInvestment,
    required this.totalRevenue,
    required this.netProfit,
    required this.roiPercentage,
    this.startDate,
    this.endDate,
    required this.calculatedAt,
  });
}

/// Brand Performance
///
/// Represents performance metrics for a brand.
class BrandPerformance {
  final String brandId;
  final int activeSponsorships;
  final int totalSponsorships;
  final double totalInvestment;
  final double totalRevenue;
  final double averageROI;
  final int successfulEvents;
  final int totalEvents;
  final DateTime calculatedAt;

  const BrandPerformance({
    required this.brandId,
    required this.activeSponsorships,
    required this.totalSponsorships,
    required this.totalInvestment,
    required this.totalRevenue,
    required this.averageROI,
    required this.successfulEvents,
    required this.totalEvents,
    required this.calculatedAt,
  });
}

/// Brand Exposure
///
/// Represents brand exposure analytics for an event.
class BrandExposure {
  final String brandId;
  final String eventId;
  final int estimatedReach;
  final int productSales;
  final int socialMediaMentions;
  final double brandVisibilityScore;
  final DateTime calculatedAt;

  const BrandExposure({
    required this.brandId,
    required this.eventId,
    required this.estimatedReach,
    required this.productSales,
    required this.socialMediaMentions,
    required this.brandVisibilityScore,
    required this.calculatedAt,
  });
}

/// Event Performance
///
/// Represents performance metrics for an event.
class EventPerformance {
  final String eventId;
  final int totalSponsorships;
  final double totalSponsorshipValue;
  final int productContributions;
  final int financialContributions;
  final DateTime calculatedAt;

  const EventPerformance({
    required this.eventId,
    required this.totalSponsorships,
    required this.totalSponsorshipValue,
    required this.productContributions,
    required this.financialContributions,
    required this.calculatedAt,
  });
}
