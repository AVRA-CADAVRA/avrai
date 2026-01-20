---
name: business-partnership-patterns
description: Guides business partnership implementation: multi-party events, revenue sharing, vibe matching, pre-event agreements. Use when implementing partnerships, event collaborations, or revenue sharing features.
---

# Business Partnership Patterns

## Core Components

### Partnership Matching Service
Matches users with businesses based on compatibility.

### Partnership Service
Manages partnership agreements and revenue splits.

### Revenue Split Calculator
Calculates revenue sharing for multi-party events.

## Partnership Matching

```dart
/// Calculate compatibility between user and business
Future<double> calculateCompatibility({
  required String userId,
  required String businessId,
  ExpertiseEvent? event,
}) async {
  // Try quantum matching first (if enabled)
  if (_quantumIntegrationService != null && event != null) {
    final quantumResult = await _quantumIntegrationService!
        .calculateUserBusinessCompatibility(
      user: await _getUser(userId),
      business: await _getBusiness(businessId),
      event: event,
    );
    
    if (quantumResult != null) {
      // Hybrid approach: 70% quantum, 30% classical
      final classicalCompatibility = await _calculateClassicalCompatibility(
        userId: userId,
        businessId: businessId,
      );
      
      final hybridScore = 0.7 * quantumResult.compatibility +
                          0.3 * classicalCompatibility;
      
      return hybridScore.clamp(0.0, 1.0);
    }
  }
  
  // Fall back to classical vibe-based matching
  return await _calculateClassicalCompatibility(
    userId: userId,
    businessId: businessId,
  );
}
```

## Multi-Party Events

```dart
/// Create multi-party event partnership
Future<Partnership> createMultiPartyPartnership({
  required Event event,
  required List<Partner> partners,
  required RevenueSplitAgreement agreement,
}) async {
  // Validate 70%+ compatibility requirement
  for (final partner in partners) {
    final compatibility = await calculateCompatibility(
      userId: partner.userId,
      businessId: event.businessId,
      event: event,
    );
    
    if (compatibility < 0.70) {
      throw PartnershipException(
        'Compatibility below 70% threshold: ${compatibility.toStringAsFixed(2)}',
      );
    }
  }
  
  // Create partnership with pre-event agreement
  final partnership = Partnership(
    id: generateId(),
    eventId: event.id,
    partners: partners,
    revenueSplit: agreement,
    status: PartnershipStatus.active,
    createdAt: DateTime.now(),
  );
  
  // Lock revenue splits before event starts
  await _partnershipService.lockRevenueSplits(partnership);
  
  return partnership;
}
```

## Revenue Split Calculation

```dart
/// Calculate revenue split for multi-party partnership
Future<RevenueSplit> calculateRevenueSplit({
  required Partnership partnership,
  required double totalRevenue,
}) async {
  final splits = <RevenueShare>[];
  
  // Split among partners based on agreement
  for (final partner in partnership.partners) {
    final shareAmount = totalRevenue * partner.revenuePercentage;
    splits.add(RevenueShare(
      partnerId: partner.id,
      amount: shareAmount,
      percentage: partner.revenuePercentage,
    ));
  }
  
  // Platform fee (10%)
  final platformFee = totalRevenue * 0.10;
  splits.add(RevenueShare(
    partnerId: 'platform',
    amount: platformFee,
    percentage: 0.10,
  ));
  
  return RevenueSplit(
    totalRevenue: totalRevenue,
    platformFee: platformFee,
    partnerSplits: splits,
  );
}
```

## Vibe Matching

```dart
/// Calculate vibe-based compatibility (classical method)
Future<double> calculateClassicalCompatibility({
  required String userId,
  required String businessId,
}) async {
  final user = await _getUser(userId);
  final business = await _getBusiness(businessId);
  
  // Calculate compatibility factors
  final valueAlignment = _calculateValueAlignment(user.vibe, business.vibe);
  final qualityFocus = _calculateQualityFocus(user.vibe, business.vibe);
  final communityOrientation = _calculateCommunityOrientation(user.vibe, business.vibe);
  final eventStyleMatch = _calculateEventStyleMatch(user.preferences, business.eventStyle);
  final authenticityMatch = _calculateAuthenticityMatch(user.vibe, business.vibe);
  
  // Weighted combination
  final compatibility = (
    valueAlignment * 0.25 +
    qualityFocus * 0.25 +
    communityOrientation * 0.20 +
    eventStyleMatch * 0.20 +
    authenticityMatch * 0.10
  );
  
  return compatibility.clamp(0.0, 1.0);
}
```

## Reference

- `lib/core/services/partnership_matching_service.dart`
- `lib/core/services/business_expert_matching_service.dart`
- `docs/plans/monetization_business_expertise/`
