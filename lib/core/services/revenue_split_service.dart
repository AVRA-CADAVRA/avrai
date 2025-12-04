import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/product_tracking_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Revenue Split Service
/// 
/// Manages N-way revenue splits for partnerships.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to multi-party partnerships
/// - Enables transparent revenue sharing
/// - Supports pre-event agreement locking
/// 
/// **Responsibilities:**
/// - Calculate N-way splits
/// - Lock splits (pre-event)
/// - Distribute payments
/// - Track earnings
class RevenueSplitService {
  static const String _logName = 'RevenueSplitService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final PartnershipService _partnershipService;
  final SponsorshipService? _sponsorshipService; // Optional for brand splits
  final ProductTrackingService? _productTrackingService; // Optional for product splits
  
  // In-memory storage for revenue splits (in production, use database)
  final Map<String, RevenueSplit> _revenueSplits = {};
  
  RevenueSplitService({
    required PartnershipService partnershipService,
    SponsorshipService? sponsorshipService,
    ProductTrackingService? productTrackingService,
  }) : _partnershipService = partnershipService,
       _sponsorshipService = sponsorshipService,
       _productTrackingService = productTrackingService;
  
  /// Calculate N-way revenue split for partnerships
  /// 
  /// **Flow:**
  /// 1. Validate percentages sum to 100%
  /// 2. Calculate platform fee (10%)
  /// 3. Calculate processing fee (~3%)
  /// 4. Calculate remaining amount
  /// 5. Calculate amount per party
  /// 6. Create RevenueSplit (N-way)
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `partnershipId`: Partnership ID (if part of partnership)
  /// - `totalAmount`: Total revenue in dollars
  /// - `ticketsSold`: Number of tickets sold
  /// - `parties`: List of split parties with percentages
  /// 
  /// **Returns:**
  /// RevenueSplit with N-way distribution
  /// 
  /// **Throws:**
  /// - `Exception` if percentages don't sum to 100%
  /// - `Exception` if parties list is empty
  Future<RevenueSplit> calculateNWaySplit({
    required String eventId,
    String? partnershipId,
    required double totalAmount,
    required int ticketsSold,
    required List<SplitParty> parties,
  }) async {
    try {
      _logger.info('Calculating N-way split: event=$eventId, parties=${parties.length}', tag: _logName);
      
      // Step 1: Validate parties list
      if (parties.isEmpty) {
        throw Exception('Parties list cannot be empty');
      }
      
      // Step 2: Validate percentages sum to 100%
      final totalPercentage = parties.fold<double>(
        0.0,
        (sum, party) => sum + party.percentage,
      );
      
      if ((totalPercentage - 100.0).abs() > 0.01) {
        throw Exception('Percentages must sum to 100%. Current sum: ${totalPercentage.toStringAsFixed(2)}%');
      }
      
      // Step 3: Calculate N-way split using factory method
      final revenueSplit = RevenueSplit.nWay(
        id: _generateSplitId(),
        eventId: eventId,
        partnershipId: partnershipId,
        totalAmount: totalAmount,
        ticketsSold: ticketsSold,
        parties: parties,
      );
      
      // Step 4: Validate split is correct
      if (!revenueSplit.isValid) {
        throw Exception('Revenue split calculation is invalid');
      }
      
      // Step 5: Save revenue split
      await _saveRevenueSplit(revenueSplit);
      
      _logger.info('Calculated N-way split: ${revenueSplit.id}', tag: _logName);
      return revenueSplit;
    } catch (e) {
      _logger.error('Error calculating N-way split', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Calculate revenue split from partnership
  /// 
  /// **Flow:**
  /// 1. Get partnership
  /// 2. Extract split parties from partnership agreement
  /// 3. Calculate N-way split
  /// 
  /// **Parameters:**
  /// - `partnershipId`: Partnership ID
  /// - `totalAmount`: Total revenue in dollars
  /// - `ticketsSold`: Number of tickets sold
  /// 
  /// **Returns:**
  /// RevenueSplit with N-way distribution
  Future<RevenueSplit> calculateFromPartnership({
    required String partnershipId,
    required double totalAmount,
    required int ticketsSold,
  }) async {
    try {
      _logger.info('Calculating split from partnership: $partnershipId', tag: _logName);
      
      // Get partnership
      final partnership = await _partnershipService.getPartnershipById(partnershipId);
      if (partnership == null) {
        throw Exception('Partnership not found: $partnershipId');
      }
      
      // Extract split parties from partnership agreement
      // For now, create default 50/50 split (user/business)
      // In production, this would come from PartnershipAgreement
      final parties = [
        SplitParty(
          partyId: partnership.userId,
          type: SplitPartyType.user,
          percentage: 50.0,
          name: 'User',
        ),
        SplitParty(
          partyId: partnership.businessId,
          type: SplitPartyType.business,
          percentage: 50.0,
          name: 'Business',
        ),
      ];
      
      // Calculate N-way split
      return await calculateNWaySplit(
        eventId: partnership.eventId,
        partnershipId: partnershipId,
        totalAmount: totalAmount,
        ticketsSold: ticketsSold,
        parties: parties,
      );
    } catch (e) {
      _logger.error('Error calculating split from partnership', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Lock revenue split (pre-event agreement)
  /// 
  /// **CRITICAL:** Splits must be locked before event starts.
  /// Once locked, splits cannot be modified.
  /// 
  /// **Flow:**
  /// 1. Get revenue split
  /// 2. Validate split is not already locked
  /// 3. Validate split is valid
  /// 4. Lock the split
  /// 5. Save locked split
  /// 
  /// **Parameters:**
  /// - `revenueSplitId`: Revenue split ID
  /// - `lockedBy`: User ID who locked the split
  /// 
  /// **Returns:**
  /// Locked RevenueSplit
  /// 
  /// **Throws:**
  /// - `Exception` if split not found
  /// - `StateError` if split already locked
  /// - `Exception` if split is invalid
  Future<RevenueSplit> lockSplit({
    required String revenueSplitId,
    required String lockedBy,
  }) async {
    try {
      _logger.info('Locking revenue split: $revenueSplitId', tag: _logName);
      
      // Get revenue split
      final revenueSplit = await getRevenueSplit(revenueSplitId);
      if (revenueSplit == null) {
        throw Exception('Revenue split not found: $revenueSplitId');
      }
      
      // Validate split is not already locked
      if (revenueSplit.isLocked) {
        throw StateError('Revenue split is already locked');
      }
      
      // Validate split is valid
      if (!revenueSplit.isValid) {
        throw Exception('Cannot lock invalid revenue split');
      }
      
      // Lock the split
      final locked = revenueSplit.lock(lockedBy: lockedBy);
      
      // Save locked split
      await _saveRevenueSplit(locked);
      
      _logger.info('Locked revenue split: $revenueSplitId', tag: _logName);
      return locked;
    } catch (e) {
      _logger.error('Error locking revenue split', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Distribute payments to parties
  /// 
  /// **Flow:**
  /// 1. Get revenue split (must be locked)
  /// 2. Calculate amounts per party
  /// 3. Create payout records per party
  /// 4. Schedule payouts (2 days after event)
  /// 
  /// **Parameters:**
  /// - `revenueSplitId`: Revenue split ID
  /// - `eventEndTime`: Event end time (for payout scheduling)
  /// 
  /// **Returns:**
  /// List of payout amounts per party
  /// 
  /// **Throws:**
  /// - `Exception` if split not found
  /// - `StateError` if split not locked
  Future<Map<String, double>> distributePayments({
    required String revenueSplitId,
    required DateTime eventEndTime,
  }) async {
    try {
      _logger.info('Distributing payments: $revenueSplitId', tag: _logName);
      
      // Get revenue split
      final revenueSplit = await getRevenueSplit(revenueSplitId);
      if (revenueSplit == null) {
        throw Exception('Revenue split not found: $revenueSplitId');
      }
      
      // Validate split is locked
      if (!revenueSplit.isLocked) {
        throw StateError('Revenue split must be locked before distributing payments');
      }
      
      // Calculate amounts per party
      final payoutAmounts = <String, double>{};
      
      if (revenueSplit.parties.isNotEmpty) {
        // N-way split: distribute to parties
        for (final party in revenueSplit.parties) {
          final amount = party.amount ?? 0.0;
          payoutAmounts[party.partyId] = amount;
        }
      } else if (revenueSplit.hostPayout != null) {
        // Solo event: distribute to host
        // In production, get host ID from event
        payoutAmounts['host'] = revenueSplit.hostPayout!;
      }
      
      // Schedule payouts (2 days after event)
      final payoutDate = eventEndTime.add(const Duration(days: 2));
      _logger.info('Payouts scheduled for: $payoutDate', tag: _logName);
      
      // In production, create Payout records here
      // For now, just return the amounts
      
      _logger.info('Distributed payments: ${payoutAmounts.length} parties', tag: _logName);
      return payoutAmounts;
    } catch (e) {
      _logger.error('Error distributing payments', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Track earnings for a party
  /// 
  /// **Parameters:**
  /// - `partyId`: Party ID (userId, businessId, etc.)
  /// - `startDate`: Start date for earnings period
  /// - `endDate`: End date for earnings period
  /// 
  /// **Returns:**
  /// Total earnings for the party
  Future<double> trackEarnings({
    required String partyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Tracking earnings: party=$partyId', tag: _logName);
      
      final allSplits = await _getAllRevenueSplits();
      
      double totalEarnings = 0.0;
      
      for (final split in allSplits) {
        // Filter by date range
        if (startDate != null && split.calculatedAt.isBefore(startDate)) {
          continue;
        }
        if (endDate != null && split.calculatedAt.isAfter(endDate)) {
          continue;
        }
        
        // Find party in split
        if (split.parties.isNotEmpty) {
          final party = split.parties.firstWhere(
            (p) => p.partyId == partyId,
            orElse: () => SplitParty(
              partyId: '',
              type: SplitPartyType.user,
              percentage: 0.0,
            ),
          );
          
          if (party.partyId == partyId && party.amount != null) {
            totalEarnings += party.amount!;
          }
        } else if (split.hostPayout != null) {
          // Solo event: check if party is the host
          // In production, check against event host ID
          // For now, skip solo events
        }
      }
      
      _logger.info('Total earnings for $partyId: \$${totalEarnings.toStringAsFixed(2)}', tag: _logName);
      return totalEarnings;
    } catch (e) {
      _logger.error('Error tracking earnings', error: e, tag: _logName);
      return 0.0;
    }
  }
  
  /// Get revenue split by ID
  /// 
  /// **Parameters:**
  /// - `revenueSplitId`: Revenue split ID
  /// 
  /// **Returns:**
  /// RevenueSplit if found, null otherwise
  Future<RevenueSplit?> getRevenueSplit(String revenueSplitId) async {
    try {
      final allSplits = await _getAllRevenueSplits();
      try {
        return allSplits.firstWhere(
          (split) => split.id == revenueSplitId,
        );
      } catch (e) {
        return null;
      }
    } catch (e) {
      _logger.error('Error getting revenue split', error: e, tag: _logName);
      return null;
    }
  }
  
  /// Get revenue splits for an event
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// List of RevenueSplit records
  Future<List<RevenueSplit>> getRevenueSplitsForEvent(String eventId) async {
    try {
      final allSplits = await _getAllRevenueSplits();
      return allSplits
          .where((split) => split.eventId == eventId)
          .toList();
    } catch (e) {
      _logger.error('Error getting revenue splits for event', error: e, tag: _logName);
      return [];
    }
  }
  
  // Private helper methods
  
  String _generateSplitId() {
    return 'split_${_uuid.v4()}';
  }
  
  Future<void> _saveRevenueSplit(RevenueSplit revenueSplit) async {
    // In production, save to database
    _revenueSplits[revenueSplit.id] = revenueSplit;
  }
  
  Future<List<RevenueSplit>> _getAllRevenueSplits() async {
    // In production, query database
    return _revenueSplits.values.toList();
  }
  
  /// Calculate N-way brand revenue split for sponsorships
  /// 
  /// **Flow:**
  /// 1. Get all sponsorships for event
  /// 2. Get partnership for event (if exists)
  /// 3. Build parties list (user + business + brands)
  /// 4. Calculate N-way split
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `totalAmount`: Total revenue in dollars
  /// - `ticketsSold`: Number of tickets sold
  /// - `brandPercentages`: Map of brandId -> percentage (optional, if not provided will use equal split)
  /// 
  /// **Returns:**
  /// RevenueSplit with N-way distribution including brands
  /// 
  /// **Throws:**
  /// - `Exception` if sponsorships not found
  /// - `Exception` if percentages don't sum to 100%
  Future<RevenueSplit> calculateNWayBrandSplit({
    required String eventId,
    required double totalAmount,
    required int ticketsSold,
    Map<String, double>? brandPercentages,
  }) async {
    try {
      _logger.info('Calculating N-way brand split: event=$eventId', tag: _logName);
      
      if (_sponsorshipService == null) {
        throw Exception('SponsorshipService not available for brand splits');
      }
      
      // Step 1: Get all sponsorships for event
      final sponsorships = await _sponsorshipService!.getSponsorshipsForEvent(eventId);
      
      // Step 2: Get partnership for event (if exists)
      final partnerships = await _partnershipService.getPartnershipsForEvent(eventId);
      
      // Step 3: Build parties list
      final parties = <SplitParty>[];
      
      // Add partnership parties (user + business)
      for (final partnership in partnerships) {
        if (partnership.revenueSplit != null) {
          // Use existing split percentages from partnership
          for (final party in partnership.revenueSplit!.parties) {
            parties.add(party);
          }
        } else {
          // Default 50/50 split (to be negotiated)
          parties.add(SplitParty(
            partyId: partnership.userId,
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'User',
          ));
          parties.add(SplitParty(
            partyId: partnership.businessId,
            type: SplitPartyType.business,
            percentage: 50.0,
            name: 'Business',
          ));
        }
      }
      
      // Step 4: Add brand parties
      if (sponsorships.isNotEmpty) {
        final totalBrandPercentage = brandPercentages?.values.fold<double>(0.0, (sum, p) => sum + p) ?? 0.0;
        
        if (brandPercentages == null || totalBrandPercentage == 0.0) {
          // Equal split among brands (remaining percentage after partnership)
          final partnershipPercentage = parties.fold<double>(0.0, (sum, p) => sum + p.percentage);
          final remainingPercentage = 100.0 - partnershipPercentage;
          
          if (remainingPercentage > 0 && sponsorships.isNotEmpty) {
            final perBrandPercentage = remainingPercentage / sponsorships.length;
            for (final sponsorship in sponsorships) {
              parties.add(SplitParty(
                partyId: sponsorship.brandId,
                type: SplitPartyType.sponsor,
                percentage: perBrandPercentage,
                name: 'Brand',
              ));
            }
          }
        } else {
          // Use provided percentages
          for (final sponsorship in sponsorships) {
            final percentage = brandPercentages[sponsorship.brandId] ?? 0.0;
            if (percentage > 0) {
              parties.add(SplitParty(
                partyId: sponsorship.brandId,
                type: SplitPartyType.sponsor,
                percentage: percentage,
                name: 'Brand',
              ));
            }
          }
        }
      }
      
      // Step 5: Validate percentages sum to 100%
      final totalPercentage = parties.fold<double>(0.0, (sum, party) => sum + party.percentage);
      if ((totalPercentage - 100.0).abs() > 0.01) {
        throw Exception('Percentages must sum to 100%. Current sum: ${totalPercentage.toStringAsFixed(2)}%');
      }
      
      // Step 6: Calculate N-way split
      return await calculateNWaySplit(
        eventId: eventId,
        partnershipId: partnerships.isNotEmpty ? partnerships.first.id : null,
        totalAmount: totalAmount,
        ticketsSold: ticketsSold,
        parties: parties,
      );
    } catch (e) {
      _logger.error('Error calculating N-way brand split', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Calculate product sales revenue split
  /// 
  /// **Flow:**
  /// 1. Get product tracking records for sponsorship
  /// 2. Calculate total product sales revenue
  /// 3. Calculate platform fee (10%)
  /// 4. Calculate processing fee (~3%)
  /// 5. Distribute remaining revenue to sponsors (product contributors)
  /// 
  /// **Parameters:**
  /// - `productTrackingId`: Product tracking ID
  /// - `totalSales`: Total product sales revenue
  /// 
  /// **Returns:**
  /// RevenueSplit for product sales
  Future<RevenueSplit> calculateProductSalesSplit({
    required String productTrackingId,
    required double totalSales,
  }) async {
    try {
      _logger.info('Calculating product sales split: tracking=$productTrackingId', tag: _logName);
      
      if (_productTrackingService == null || _sponsorshipService == null) {
        throw Exception('ProductTrackingService and SponsorshipService required for product sales splits');
      }
      
      // Step 1: Get product tracking record
      final tracking = await _productTrackingService!.getProductTrackingById(productTrackingId);
      if (tracking == null) {
        throw Exception('Product tracking not found: $productTrackingId');
      }
      
      // Step 2: Get sponsorship
      final sponsorship = await _sponsorshipService!.getSponsorshipById(tracking.sponsorshipId);
      if (sponsorship == null) {
        throw Exception('Sponsorship not found: ${tracking.sponsorshipId}');
      }
      
      // Step 3: Calculate fees
      const platformFeePercentage = 0.10; // 10%
      const processingFeePercentage = 0.029; // 2.9%
      const processingFeeFixed = 0.30; // $0.30 per transaction
      
      final platformFee = totalSales * platformFeePercentage;
      final processingFee = (totalSales * processingFeePercentage) + processingFeeFixed;
      final netRevenue = totalSales - platformFee - processingFee;
      
      // Step 4: Create split party for brand (product contributor)
      final parties = [
        SplitParty(
          partyId: sponsorship.brandId,
          type: SplitPartyType.sponsor,
          percentage: 100.0, // 100% of product sales go to sponsor (can be adjusted)
          amount: netRevenue,
          name: 'Brand',
        ),
      ];
      
      // Step 5: Calculate split
      final revenueSplit = RevenueSplit.nWay(
        id: _generateSplitId(),
        eventId: sponsorship.eventId,
        partnershipId: null,
        totalAmount: totalSales,
        ticketsSold: tracking.quantitySold,
        parties: parties,
        calculatedAt: DateTime.now(),
      );
      
      // Step 6: Save revenue split
      await _saveRevenueSplit(revenueSplit);
      
      _logger.info('Calculated product sales split: ${revenueSplit.id}', tag: _logName);
      return revenueSplit;
    } catch (e) {
      _logger.error('Error calculating product sales split', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Calculate hybrid sponsorship split (cash + product)
  /// 
  /// **Flow:**
  /// 1. Calculate cash split (from financial contribution)
  /// 2. Calculate product sales split (from product sales)
  /// 3. Combine both splits
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `cashAmount`: Cash contribution amount
  /// - `productSalesAmount`: Product sales amount
  /// - `ticketsSold`: Number of tickets sold
  /// - `parties`: List of split parties with percentages
  /// 
  /// **Returns:**
  /// Map with 'cash' and 'product' RevenueSplit records
  Future<Map<String, RevenueSplit>> calculateHybridSplit({
    required String eventId,
    required double cashAmount,
    required double productSalesAmount,
    required int ticketsSold,
    required List<SplitParty> parties,
  }) async {
    try {
      _logger.info('Calculating hybrid split: event=$eventId, cash=\$${cashAmount.toStringAsFixed(2)}, product=\$${productSalesAmount.toStringAsFixed(2)}', tag: _logName);
      
      // Step 1: Calculate cash split
      final cashSplit = await calculateNWaySplit(
        eventId: eventId,
        totalAmount: cashAmount,
        ticketsSold: ticketsSold,
        parties: parties,
      );
      
      // Step 2: Calculate product sales split (100% to product sponsors)
      final productParties = parties.where((p) => p.type == SplitPartyType.sponsor).toList();
      double productSplitPercentage = 100.0;
      
      if (productParties.isEmpty) {
        // If no sponsor parties, distribute equally among all parties
        final perPartyPercentage = 100.0 / parties.length;
        productParties.addAll(parties.map((p) => p.copyWith(percentage: perPartyPercentage)));
      }
      
      final productSplit = await calculateNWaySplit(
        eventId: eventId,
        totalAmount: productSalesAmount,
        ticketsSold: ticketsSold,
        parties: productParties,
      );
      
      _logger.info('Calculated hybrid split: cash=${cashSplit.id}, product=${productSplit.id}', tag: _logName);
      return {
        'cash': cashSplit,
        'product': productSplit,
      };
    } catch (e) {
      _logger.error('Error calculating hybrid split', error: e, tag: _logName);
      rethrow;
    }
  }
}

