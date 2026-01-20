---
name: expertise-system-implementation
description: Guides expertise system implementation: multi-path recognition, hierarchy (local → city → state → national), golden experts, visit quality. Use when implementing expertise calculations, expert recognition, or expertise-based features.
---

# Expertise System Implementation

## Core Principle

Users can become experts through multiple paths. Expertise is recognized at different geographic levels.

## Multi-Path Expertise

### Six Paths to Expertise
1. **Exploration (40%)** - Visits, reviews, check-ins, dwell time
2. **Credentials (25%)** - Degrees, certifications, published work
3. **Influence (20%)** - Followers, shares, list curation (logarithmic normalization)
4. **Professional (25%)** - Proof of work, roles, peer endorsements
5. **Community (15%)** - Questions answered, events hosted, contributions
6. **Local (varies)** - Locality-based expertise with golden expert bonus

## Weighted Calculation

```dart
/// Calculate weighted expertise score
double calculateExpertiseScore({
  required double explorationScore,
  required double credentialsScore,
  required double influenceScore,
  required double professionalScore,
  required double communityScore,
  required double localScore,
}) {
  return (explorationScore * 0.40) +
         (credentialsScore * 0.25) +
         (influenceScore * 0.20) +
         (professionalScore * 0.25) +
         (communityScore * 0.15) +
         (localScore * localWeight);
}
```

## Geographic Hierarchy

### Hierarchy Levels
```
Local → City → State → National → Global → Universal
```

### Local Expertise
```dart
/// Calculate local expertise
Future<LocalExpertise> calculateLocalExpertise({
  required String userId,
  required String locality,
}) async {
  // Calculate expertise at locality level
  final visits = await _getVisitsInLocality(userId, locality);
  final contributions = await _getContributionsInLocality(userId, locality);
  
  return LocalExpertise(
    locality: locality,
    score: _calculateLocalScore(visits, contributions),
    goldenExpert: await _checkGoldenExpert(userId, locality),
  );
}
```

## Dynamic Thresholds

```dart
/// Get effective requirements (adjusted for phase + saturation)
ThresholdValues getEffectiveRequirements({
  required ExpertiseRequirements requirements,
  required PlatformPhase platformPhase,
  required SaturationMetrics saturationMetrics,
}) {
  // Get phase multiplier
  final phaseMultiplier = platformPhase.getCategoryMultiplier(requirements.category);
  
  // Get saturation multiplier
  final saturationMultiplier = saturationMetrics.getSaturationMultiplier();
  
  // Calculate total multiplier
  final totalMultiplier = phaseMultiplier * saturationMultiplier;
  
  // Apply multiplier to thresholds
  return requirements.thresholdValues.applyMultiplier(totalMultiplier);
}
```

## Reference

- `lib/core/services/expertise_calculation_service.dart`
- `lib/core/services/multi_path_expertise_service.dart`
- `docs/patents/category_3_expertise_economic_systems/01_multi_path_dynamic_expertise/`
