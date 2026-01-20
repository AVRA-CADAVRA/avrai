---
name: ai2ai-learning-service
description: Guides AI2AI learning service implementation: personality spectrum, compatibility calculations, learning methods, anonymous data exchange. Use when implementing AI2AI learning, personality evolution, or peer learning features.
---

# AI2AI Learning Service

## Core Purpose

AI2AI learning enables personality learning through anonymized peer interactions.

## Learning Methods

### 1. Personal Learning (On-Device)
- Learn which doors user opens
- Track visits, preferences, patterns
- Personal AI learns user's authentic self

### 2. AI2AI Learning (Peer-to-Peer)
- Learn from compatible personalities
- Exchange anonymized insights
- Discover patterns through network

### 3. Cloud Learning (Optional)
- Aggregate network patterns
- Enhance with collective wisdom
- Optional enhancement, not required

## Implementation Pattern

```dart
/// AI2AI Learning Service
/// 
/// Enables personality learning through AI2AI connections
class AI2AILearningService {
  final PersonalityLearning _personalityLearning;
  final PrivacyProtection _privacyProtection;
  
  /// Learn from AI2AI connection
  Future<void> learnFromConnection({
    required DiscoveredDevice device,
    required AnonymizedPersonalityData remotePersonality,
    required double compatibility,
    required LearningOutcome outcome,
  }) async {
    // Extract anonymized insights (no personal data)
    final insights = await _extractAnonymizedInsights(
      remotePersonality: remotePersonality,
      compatibility: compatibility,
      outcome: outcome,
    );
    
    // Learn from insights (anonymized only)
    await _personalityLearning.learnFromInsights(insights);
  }
  
  /// Extract anonymized insights from connection
  Future<AnonymizedInsights> _extractAnonymizedInsights({
    required AnonymizedPersonalityData remotePersonality,
    required double compatibility,
    required LearningOutcome outcome,
  }) async {
    // Extract insights without personal identifiers
    return AnonymizedInsights(
      compatibleDimensions: _findCompatibleDimensions(remotePersonality),
      learningPatterns: _extractLearningPatterns(outcome),
      // NO user IDs, emails, or other PII
    );
  }
}
```

## Personality Evolution

```dart
/// Evolve personality based on AI2AI learning
Future<PersonalityProfile> evolvePersonality({
  required String userId,
  required List<AnonymizedInsights> insights,
}) async {
  final currentPersonality = await _personalityLearning.getCurrentPersonality(userId);
  
  // Evolve personality with resistance to homogenization
  final evolvedPersonality = await _personalityLearning.evolveWithResistance(
    currentPersonality: currentPersonality,
    insights: insights,
    maxDrift: 0.30, // Max 30% drift from baseline
  );
  
  return evolvedPersonality;
}
```

## Reference

- `lib/core/services/ai2ai_learning_service.dart`
- `docs/ai2ai/01_philosophy/CORE_PHILOSOPHY.md`
