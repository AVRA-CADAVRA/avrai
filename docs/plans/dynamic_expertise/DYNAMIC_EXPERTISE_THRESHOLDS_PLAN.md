# Dynamic Expertise Thresholds - Scaling Quality System

**Created:** November 21, 2025  
**Status:** 🎯 Ready for Implementation  
**Priority:** HIGH  
**Philosophy Alignment:** "Trust Through Earned Authority"

---

## 🎯 Core Principle

> **As the platform grows, becoming an "expert" should become harder to prevent oversaturation and maintain trust.**

**The Problem:**
- Early on: Need experts to bootstrap the platform
- Later: Too many "experts" dilutes trust and quality
- Risk: Everyone becomes an "expert" → Nobody trusts expertise

**The Solution:**
- **Dynamic thresholds** that increase as the platform scales
- **Category-specific** requirements (popular categories harder)
- **Quality-focused** progression (not just time-based)
- **Transparent** to users (they can see what's required)

---

## 📊 Dynamic Threshold System

### **Phase-Based Scaling**

```dart
enum PlatformPhase {
  bootstrap,     // First 1,000 users
  growth,        // 1K - 10K users
  scale,         // 10K - 100K users
  mature,        // 100K+ users
}

class DynamicExpertiseThresholds {
  /// Current platform phase determines base thresholds
  static PlatformPhase getCurrentPhase() {
    final totalUsers = _getTotalUserCount();
    
    if (totalUsers < 1000) return PlatformPhase.bootstrap;
    if (totalUsers < 10000) return PlatformPhase.growth;
    if (totalUsers < 100000) return PlatformPhase.scale;
    return PlatformPhase.mature;
  }
  
  /// Base requirements for Local-level (event hosting ability) - City level provides expanded hosting scope
  static ExpertiseRequirements getCityLevelRequirements(
    String category,
    PlatformPhase phase,
  ) {
    // Base thresholds by phase
    final baseRequirements = {
      PlatformPhase.bootstrap: ExpertiseRequirements(
        minVisits: 10,
        minRatings: 5,
        minAvgRating: 4.0,
        minTimeInCategory: Duration(days: 30),
        minReviewQuality: 3.5,
        minCommunityEngagement: 5,
      ),
      PlatformPhase.growth: ExpertiseRequirements(
        minVisits: 20,
        minRatings: 10,
        minAvgRating: 4.2,
        minTimeInCategory: Duration(days: 60),
        minReviewQuality: 4.0,
        minCommunityEngagement: 10,
      ),
      PlatformPhase.scale: ExpertiseRequirements(
        minVisits: 35,
        minRatings: 20,
        minAvgRating: 4.3,
        minTimeInCategory: Duration(days: 90),
        minReviewQuality: 4.2,
        minCommunityEngagement: 20,
      ),
      PlatformPhase.mature: ExpertiseRequirements(
        minVisits: 50,
        minRatings: 35,
        minAvgRating: 4.5,
        minTimeInCategory: Duration(days: 120),
        minReviewQuality: 4.5,
        minCommunityEngagement: 35,
      ),
    };
    
    // Apply category saturation multiplier
    final saturation = _getCategorySaturation(category);
    return _applyMultiplier(baseRequirements[phase]!, saturation);
  }
}
```

---

## 🚶 Automatic Location-Based Check-ins

### **Passive Visit Tracking (No Phone Required)**

**The Rule:**
> Users don't need to manually check in. System automatically detects visits using background location + Bluetooth proximity.

```dart
class AutomaticVisitDetection {
  /// Passively track visits using ai2ai network
  Future<void> detectVisit(
    String userId,
    Location userLocation,
  ) async {
    // 1. Check if user near any spots (geofencing)
    final nearbySpots = await _getSpotsByProximity(
      userLocation,
      radiusMeters: 50, // Within 50m
    );
    
    if (nearbySpots.isEmpty) return;
    
    // 2. Check Bluetooth signals (offline ai2ai)
    final spotSignals = await _detectSpotBeacons(nearbySpots);
    
    // 3. Dwell time detection (must stay 5+ minutes)
    final dwellTime = await _calculateDwellTime(userId, nearbySpots);
    
    // 4. Auto-record visit if criteria met
    for (final spot in nearbySpots) {
      if (spotSignals.contains(spot.id) && dwellTime[spot.id] >= 5) {
        await _recordVisit(
          userId: userId,
          spotId: spot.id,
          timestamp: DateTime.now(),
          dwellTime: dwellTime[spot.id]!,
          automatic: true, // Flag as auto-detected
        );
        
        // Prompt for optional review later
        await _scheduleReviewPrompt(userId, spot.id, delay: Duration(hours: 2));
      }
    }
  }
  
  /// Visit quality (longer dwell = higher quality)
  double calculateVisitQuality(Duration dwellTime) {
    // 5 min = 0.5, 15 min = 0.8, 30+ min = 1.0
    return (dwellTime.inMinutes / 30).clamp(0.5, 1.0);
  }
}

class Visit {
  final String id;
  final String userId;
  final String spotId;
  final DateTime timestamp;
  final Duration dwellTime;
  final bool automatic;        // Auto-detected vs manual check-in
  final double qualityScore;   // Based on dwell time
  final bool reviewGiven;      // Did user review after?
}
```

**Benefits:**
- ✅ No friction (users don't need to do anything)
- ✅ Accurate (offline ai2ai proximity detection)
- ✅ Quality-aware (dwell time matters)
- ✅ Review prompts (encourage engagement)
- ✅ Works offline (Bluetooth-based)

---

## 🎓 Multiple Paths to Expertise

### **Not Just Visits - Four Paths to Expert Status**

**The Rule:**
> Users can become experts through visits, credentials, social proof, or community engagement. System weighs all factors.

```dart
enum ExpertisePath {
  exploration,    // Traditional: visits + ratings
  credentials,    // Education: degrees, certifications
  influence,      // Social proof: followers, other platforms
  community,      // Engagement: helping others, list curation
}

class MultiPathExpertiseSystem {
  /// Calculate expertise from ALL paths
  Future<ExpertiseScore> calculateExpertise(
    String userId,
    String category,
  ) async {
    final scores = await Future.wait([
      _calculateExplorationScore(userId, category),
      _calculateCredentialScore(userId, category),
      _calculateInfluenceScore(userId, category),
      _calculateCommunityScore(userId, category),
    ]);
    
    // Weighted combination (no single path required)
    return ExpertiseScore(
      exploration: scores[0],   // 40% weight
      credentials: scores[1],   // 25% weight
      influence: scores[2],     // 20% weight
      community: scores[3],     // 15% weight
      total: _calculateWeightedScore(scores),
      pathsUsed: _getActivePaths(scores),
    );
  }
  
  /// Path 1: Exploration (Visits + Ratings)
  Future<PathScore> _calculateExplorationScore(
    String userId,
    String category,
  ) async {
    final visits = await _getUserVisits(userId, category);
    final ratings = await _getUserRatings(userId, category);
    
    return PathScore(
      path: ExpertisePath.exploration,
      progress: _normalizeVisitProgress(visits, ratings),
      quality: _calculateVisitQuality(visits, ratings),
      weight: 0.40,
    );
  }
  
  /// Path 2: Credentials (Degrees, Certifications, Professional Work)
  Future<PathScore> _calculateCredentialScore(
    String userId,
    String category,
  ) async {
    final credentials = await _getUserCredentials(userId);
    final professional = await _getProfessionalExperience(userId);
    
    double score = 0.0;
    
    // Academic credentials
    for (final credential in credentials) {
      // University degree in field
      if (credential.type == CredentialType.degree) {
        score += _matchDegreeToCategory(credential, category);
      }
      
      // Professional certification
      if (credential.type == CredentialType.certification) {
        score += _matchCertificationToCategory(credential, category);
      }
      
      // Published work / Research
      if (credential.type == CredentialType.publication) {
        score += _matchPublicationToCategory(credential, category);
      }
    }
    
    // Professional experience (NEW)
    for (final work in professional) {
      if (_matchProfessionToCategory(work, category)) {
        score += _calculateProfessionalScore(work);
      }
    }
    
    return PathScore(
      path: ExpertisePath.credentials,
      progress: score.clamp(0.0, 1.0),
      quality: _verifyCredentialAuthenticity(credentials, professional),
      weight: 0.25,
    );
  }
  
  /// NEW: Calculate score for professional work
  double _calculateProfessionalScore(ProfessionalExperience work) {
    double score = 0.0;
    
    // Base score by role prestige
    score += _getRolePrestige(work.role);
    
    // Tenure bonus (longer = more expert)
    final yearsExperience = DateTime.now().difference(work.startDate).inDays / 365;
    score += (yearsExperience / 10).clamp(0.0, 0.3); // Max 0.3 for 10+ years
    
    // Verification bonus
    if (work.verified) score += 0.2;
    
    // Proof of work quality
    if (work.portfolioLinks?.isNotEmpty ?? false) score += 0.15;
    if (work.awards?.isNotEmpty ?? false) score += 0.15;
    if (work.mediaFeatures?.isNotEmpty ?? false) score += 0.10;
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Match profession to category
  bool _matchProfessionToCategory(ProfessionalExperience work, String category) {
    // Direct matches
    final directMatches = {
      ProfessionalRole.chef: ['Food', 'Restaurants', 'Culinary', 'Dining'],
      ProfessionalRole.headChef: ['Food', 'Restaurants', 'Culinary', 'Dining'],
      ProfessionalRole.sousChef: ['Food', 'Restaurants', 'Culinary'],
      ProfessionalRole.barista: ['Coffee', 'Cafes'],
      ProfessionalRole.sommelier: ['Wine', 'Bars', 'Restaurants'],
      ProfessionalRole.bartender: ['Bars', 'Nightlife', 'Cocktails'],
      
      ProfessionalRole.writer: ['Books', 'Literature', 'Media'],
      ProfessionalRole.journalist: ['Media', 'News', 'Culture'],
      ProfessionalRole.artCritic: ['Art', 'Galleries', 'Museums'],
      ProfessionalRole.foodCritic: ['Food', 'Restaurants', 'Dining'],
      ProfessionalRole.musicCritic: ['Music', 'Concerts', 'Nightlife'],
      
      ProfessionalRole.teacher: ['Education', work.specialization ?? ''],
      ProfessionalRole.professor: ['Education', work.specialization ?? ''],
      ProfessionalRole.coach: ['Sports', 'Fitness', work.specialization ?? ''],
      ProfessionalRole.mentor: [work.specialization ?? ''],
      
      ProfessionalRole.consultant: [work.specialization ?? ''],
      ProfessionalRole.advisor: [work.specialization ?? ''],
      
      ProfessionalRole.curator: ['Art', 'Museums', 'Galleries'],
      ProfessionalRole.gallerist: ['Art', 'Galleries'],
      ProfessionalRole.museumDirector: ['Art', 'Museums', 'Culture'],
      
      ProfessionalRole.nurse: ['Healthcare', 'Wellness'],
      ProfessionalRole.doctor: ['Healthcare', 'Medical', 'Wellness'],
      ProfessionalRole.therapist: ['Healthcare', 'Wellness', 'Mental Health'],
      ProfessionalRole.nutritionist: ['Food', 'Health', 'Wellness'],
    };
    
    final relevantCategories = directMatches[work.role] ?? [];
    return relevantCategories.any((cat) => 
      category.toLowerCase().contains(cat.toLowerCase()) ||
      cat.toLowerCase().contains(category.toLowerCase())
    );
  }
  
  /// Role prestige scoring
  double _getRolePrestige(ProfessionalRole role) {
    const prestigeScores = {
      // Culinary (high prestige)
      ProfessionalRole.headChef: 0.9,
      ProfessionalRole.executiveChef: 1.0,
      ProfessionalRole.sousChef: 0.7,
      ProfessionalRole.chef: 0.6,
      ProfessionalRole.barista: 0.4,
      ProfessionalRole.sommelier: 0.8,
      ProfessionalRole.bartender: 0.5,
      
      // Writing & Media
      ProfessionalRole.writer: 0.6,
      ProfessionalRole.journalist: 0.7,
      ProfessionalRole.artCritic: 0.8,
      ProfessionalRole.foodCritic: 0.8,
      ProfessionalRole.musicCritic: 0.8,
      ProfessionalRole.author: 0.9,
      
      // Education
      ProfessionalRole.professor: 1.0,
      ProfessionalRole.teacher: 0.7,
      ProfessionalRole.instructor: 0.6,
      ProfessionalRole.coach: 0.6,
      ProfessionalRole.mentor: 0.5,
      
      // Consulting
      ProfessionalRole.consultant: 0.7,
      ProfessionalRole.advisor: 0.8,
      ProfessionalRole.specialist: 0.7,
      
      // Arts & Culture
      ProfessionalRole.curator: 0.8,
      ProfessionalRole.gallerist: 0.7,
      ProfessionalRole.museumDirector: 1.0,
      ProfessionalRole.artist: 0.6,
      
      // Healthcare
      ProfessionalRole.doctor: 1.0,
      ProfessionalRole.nurse: 0.7,
      ProfessionalRole.therapist: 0.8,
      ProfessionalRole.nutritionist: 0.7,
    };
    
    return prestigeScores[role] ?? 0.5;
  }
  
  /// Path 3: Influence (Social Proof)
  Future<PathScore> _calculateInfluenceScore(
    String userId,
    String category,
  ) async {
    final influence = await _getUserInfluence(userId, category);
    
    double score = 0.0;
    
    // SPOTS followers in category
    score += _normalizeFollowers(influence.spotsFollowers);
    
    // External platform influence (Instagram, TikTok, YouTube)
    for (final platform in influence.externalPlatforms) {
      if (_isCategoryRelevant(platform, category)) {
        score += _normalizeExternalInfluence(platform);
      }
    }
    
    // List engagement (others saving/sharing user's lists)
    score += _normalizeListEngagement(influence.listShares, influence.listSaves);
    
    return PathScore(
      path: ExpertisePath.influence,
      progress: score.clamp(0.0, 1.0),
      quality: _verifyInfluenceAuthenticity(influence),
      weight: 0.20,
    );
  }
  
  /// Path 4: Community Engagement
  Future<PathScore> _calculateCommunityScore(
    String userId,
    String category,
  ) async {
    final engagement = await _getCommunityEngagement(userId, category);
    
    return PathScore(
      path: ExpertisePath.community,
      progress: _normalizeCommunityMetrics(
        questionsAnswered: engagement.helpfulAnswers,
        curatedLists: engagement.qualityLists,
        eventsHosted: engagement.eventsHosted,
        peerEndorsements: engagement.endorsements,
      ),
      quality: _calculateEngagementQuality(engagement),
      weight: 0.15,
    );
  }
}

class Credential {
  final String id;
  final CredentialType type;
  final String institution;
  final String fieldOfStudy;
  final DateTime dateObtained;
  final bool verified;         // Admin or third-party verified
  final String? verificationProof; // Photo, link to registry, etc.
}

enum CredentialType {
  degree,           // BA, BS, MA, MS, PhD
  certification,    // Professional cert (sommelier, barista, etc.)
  publication,      // Published research, articles, books
  industry,         // Work experience proof
  award,            // Industry awards, recognition
}

/// NEW: Professional experience tracking
class ProfessionalExperience {
  final String id;
  final ProfessionalRole role;
  final String workplace;        // "Alinea", "The New York Times"
  final String? specialization;  // "Italian Cuisine", "Art History"
  final DateTime startDate;
  final DateTime? endDate;       // null = currently employed
  final String? location;        // "Chicago, IL"
  
  // Verification
  final bool verified;
  final VerificationMethod verificationMethod;
  final String? verificationProof;
  
  // Proof of work
  final List<String>? portfolioLinks;  // Articles, photos, menus
  final List<String>? awards;          // "Michelin Star", "James Beard"
  final List<String>? mediaFeatures;   // "Featured in NY Times"
  final List<String>? testimonials;    // From employers, clients
  
  // Computed
  Duration get tenure => (endDate ?? DateTime.now()).difference(startDate);
  bool get isCurrent => endDate == null;
}

enum ProfessionalRole {
  // Culinary
  chef,
  sousChef,
  headChef,
  executiveChef,
  pastryChef,
  barista,
  sommelier,
  bartender,
  
  // Writing & Media
  writer,
  journalist,
  author,
  editor,
  critic,
  artCritic,
  foodCritic,
  musicCritic,
  
  // Education
  teacher,
  professor,
  instructor,
  lecturer,
  coach,
  mentor,
  tutor,
  
  // Consulting & Advisory
  consultant,
  advisor,
  specialist,
  analyst,
  
  // Arts & Culture
  curator,
  gallerist,
  museumDirector,
  artist,
  designer,
  
  // Healthcare
  doctor,
  nurse,
  therapist,
  counselor,
  nutritionist,
  
  // Other
  other,
}

enum VerificationMethod {
  linkedInProfile,     // Cross-reference with LinkedIn
  employerLetter,      // Letter from employer
  payStub,             // Proof of employment
  businessLicense,     // For self-employed
  portfolioReview,     // Admin reviews portfolio
  thirdPartyService,   // Services like Checkr, TrustID
  peerEndorsement,     // Other verified professionals
}

class ExternalPlatformInfluence {
  final String platform;      // "instagram", "tiktok", "youtube"
  final String handle;
  final int followers;
  final String category;      // Their niche
  final bool verified;        // Platform verification badge
  final double engagementRate;
  final List<String> proofUrls; // Links to verify
}
```

---

## 📊 Advanced Saturation Algorithm

### **Sophisticated Multi-Factor Saturation Model**

**The Problem with Simple Ratio:**
> Just counting experts / users doesn't account for quality, demand, utilization, or growth dynamics.

**Better Formula - Six Factors:**

```dart
class AdvancedSaturationAnalyzer {
  /// Sophisticated saturation calculation
  Future<SaturationMetrics> analyzeCategorySaturation(
    String category,
  ) async {
    // Factor 1: Supply Ratio (basic expert count)
    final supplyRatio = await _calculateSupplyRatio(category);
    
    // Factor 2: Quality Distribution (are experts actually good?)
    final qualityDist = await _analyzeExpertQuality(category);
    
    // Factor 3: Utilization Rate (are experts being used?)
    final utilization = await _calculateExpertUtilization(category);
    
    // Factor 4: Demand Signal (do users want more experts?)
    final demand = await _analyzeDemandSignal(category);
    
    // Factor 5: Growth Velocity (rate of expert creation)
    final growth = await _analyzeGrowthVelocity(category);
    
    // Factor 6: Geographic Distribution (clustered or spread?)
    final distribution = await _analyzeGeographicDistribution(category);
    
    // Combine into saturation score
    final saturation = _calculateSaturationScore(
      supplyRatio: supplyRatio,
      qualityDist: qualityDist,
      utilization: utilization,
      demand: demand,
      growth: growth,
      distribution: distribution,
    );
    
    return SaturationMetrics(
      category: category,
      saturationScore: saturation.score,
      multiplier: saturation.multiplier,
      factors: saturation.factorBreakdown,
      recommendation: saturation.recommendation,
    );
  }
  
  /// Factor 1: Supply Ratio (expert count vs users)
  Future<double> _calculateSupplyRatio(String category) async {
    final stats = await _getCategoryStats(category);
    final expertRatio = stats.experts / stats.totalUsers;
    
    // Ideal: 1-3 experts per 100 users
    final idealRatio = 0.02;
    final deviation = (expertRatio - idealRatio).abs();
    
    // Score: 0.0 (perfect) to 1.0 (highly saturated)
    return (deviation / idealRatio).clamp(0.0, 1.0);
  }
  
  /// Factor 2: Quality Distribution
  Future<double> _analyzeExpertQuality(String category) async {
    final experts = await _getExpertsInCategory(category);
    
    // Analyze quality distribution
    final qualityScores = experts.map((e) => e.qualityScore).toList();
    final avgQuality = _average(qualityScores);
    final qualityStdDev = _standardDeviation(qualityScores);
    
    // Good: High average, low variance
    // Bad: Low average or high variance (inconsistent quality)
    
    final qualityFactor = avgQuality * (1.0 - qualityStdDev);
    
    // If quality is poor, category needs BETTER experts, not more
    // If quality is good but saturated, increase barriers
    return qualityFactor;
  }
  
  /// Factor 3: Utilization Rate
  Future<double> _calculateExpertUtilization(String category) async {
    final experts = await _getExpertsInCategory(category);
    
    int activeExperts = 0;
    int totalExpertCapacity = 0;
    int actualUsage = 0;
    
    for (final expert in experts) {
      final usage = await _getExpertUsageMetrics(expert.id, category);
      
      // Active = has followers, hosts events, gets engagement
      if (usage.isActive) activeExperts++;
      
      // Capacity = could host X events/month
      totalExpertCapacity += usage.potentialCapacity;
      
      // Actual usage
      actualUsage += usage.actualActivity;
    }
    
    final utilizationRate = actualUsage / totalExpertCapacity;
    
    // Low utilization = too many experts (saturated)
    // High utilization = experts in demand (need more)
    return utilizationRate;
  }
  
  /// Factor 4: Demand Signal
  Future<double> _analyzeDemandSignal(String category) async {
    final signals = await _getDemandSignals(category);
    
    // Positive demand signals:
    final positiveSignals = [
      signals.expertSearches,          // Users searching for experts
      signals.eventWaitlists,          // Events filling up quickly
      signals.followRequestsToExperts, // Users following experts
      signals.listSubscriptions,       // Users subscribing to expert lists
    ];
    
    // Negative demand signals:
    final negativeSignals = [
      signals.expertUnfollows,         // Users unfollowing
      signals.eventCancellations,      // Events not filling
      signals.lowEventRatings,         // Poor event experiences
    ];
    
    final demandScore = 
      _sum(positiveSignals) / (_sum(positiveSignals) + _sum(negativeSignals));
    
    return demandScore;
  }
  
  /// Factor 5: Growth Velocity
  Future<double> _analyzeGrowthVelocity(String category) async {
    final history = await _getExpertCountHistory(category);
    
    // Calculate rate of new experts per month
    final recentGrowth = _calculateGrowthRate(
      history,
      period: Duration(days: 30),
    );
    
    final historicalGrowth = _calculateGrowthRate(
      history,
      period: Duration(days: 90),
    );
    
    // Accelerating growth = getting saturated
    // Stable growth = healthy
    // Declining growth = room for more
    final acceleration = recentGrowth / historicalGrowth;
    
    return acceleration;
  }
  
  /// Factor 6: Geographic Distribution
  Future<double> _analyzeGeographicDistribution(String category) async {
    final experts = await _getExpertsInCategory(category);
    final locations = experts.map((e) => e.primaryLocation).toList();
    
    // Calculate clustering coefficient
    final clustering = _calculateSpatialClustering(locations);
    
    // High clustering = concentrated in few areas (need more elsewhere)
    // Low clustering = well distributed (may be saturated everywhere)
    return clustering;
  }
  
  /// Combine all factors into saturation multiplier
  SaturationScore _calculateSaturationScore({
    required double supplyRatio,
    required double qualityDist,
    required double utilization,
    required double demand,
    required double growth,
    required double distribution,
  }) {
    // Weighted formula
    final saturationScore = (
      supplyRatio * 0.25 +          // 25% - basic expert count
      (1 - qualityDist) * 0.20 +    // 20% - quality (inverted)
      (1 - utilization) * 0.20 +    // 20% - utilization (inverted)
      (1 - demand) * 0.15 +         // 15% - demand (inverted)
      (growth - 1.0).abs() * 0.10 + // 10% - growth stability
      distribution * 0.10           // 10% - geographic clustering
    ).clamp(0.0, 1.0);
    
    // Convert to multiplier (1.0x - 3.0x)
    final multiplier = 1.0 + (saturationScore * 2.0);
    
    // Generate recommendation
    final recommendation = _generateRecommendation(
      saturationScore,
      supplyRatio,
      qualityDist,
      utilization,
      demand,
    );
    
    return SaturationScore(
      score: saturationScore,
      multiplier: multiplier,
      factorBreakdown: {
        'supplyRatio': supplyRatio,
        'qualityDist': qualityDist,
        'utilization': utilization,
        'demand': demand,
        'growth': growth,
        'distribution': distribution,
      },
      recommendation: recommendation,
    );
  }
  
  /// Smart recommendations based on analysis
  String _generateRecommendation(
    double saturation,
    double supplyRatio,
    double qualityDist,
    double utilization,
    double demand,
  ) {
    if (saturation < 0.3) {
      return 'HEALTHY - Maintain current requirements';
    }
    
    if (saturation >= 0.3 && saturation < 0.6) {
      if (qualityDist < 0.7) {
        return 'MODERATE - Increase quality requirements, not quantity';
      }
      if (utilization < 0.5) {
        return 'MODERATE - Too many inactive experts, increase barriers';
      }
      return 'MODERATE - Gradually increase requirements';
    }
    
    if (saturation >= 0.6 && saturation < 0.8) {
      if (demand > 0.7) {
        return 'HIGH - Saturated but high demand, focus on quality';
      }
      return 'HIGH - Significantly increase requirements';
    }
    
    // saturation >= 0.8
    if (qualityDist < 0.6) {
      return 'CRITICAL - Pause new experts, focus on quality improvement';
    }
    return 'CRITICAL - Maximum requirements, very selective';
  }
}

class SaturationMetrics {
  final String category;
  final double saturationScore;    // 0.0-1.0
  final double multiplier;          // 1.0x-3.0x
  final Map<String, double> factors;
  final String recommendation;
}
```

---

## 📊 Example: Coffee Category Deep Analysis

```
Coffee Category Saturation Analysis:

Factor 1: Supply Ratio
├─ Total users: 5,000
├─ Current experts: 180
├─ Ratio: 3.6% (above ideal 2%)
└─ Score: 0.45 (moderate oversupply)

Factor 2: Quality Distribution
├─ Expert quality scores: [4.2, 4.5, 4.8, 3.9, 4.1, ...]
├─ Average quality: 4.3 / 5.0
├─ Standard deviation: 0.6 (moderate variance)
└─ Score: 0.72 (good overall quality)

Factor 3: Utilization Rate
├─ Active experts: 142 / 180 (79%)
├─ Events hosted/month: 85
├─ Potential capacity: 150 events/month
├─ Utilization: 57%
└─ Score: 0.57 (moderate underutilization)

Factor 4: Demand Signal
├─ Expert searches: 420/month ↑
├─ Event wait lists: 23 events (27%)
├─ Follow requests: 890/month ↑
├─ Unfollows: 45/month
└─ Score: 0.81 (strong demand)

Factor 5: Growth Velocity
├─ New experts last 30 days: 12
├─ New experts last 90 days: 28
├─ Growth rate: 1.29x (accelerating)
└─ Score: 0.29 (healthy acceleration)

Factor 6: Geographic Distribution
├─ Clustering coefficient: 0.42
├─ NYC: 45 experts (25%)
├─ SF: 32 experts (18%)
├─ Other: 103 experts (57%)
└─ Score: 0.42 (moderate clustering)

═══════════════════════════════════════

COMBINED SATURATION SCORE: 0.52
├─ Supply: 0.45 × 25% = 0.11
├─ Quality: 0.28 × 20% = 0.06 (inverted)
├─ Utilization: 0.43 × 20% = 0.09 (inverted)
├─ Demand: 0.19 × 15% = 0.03 (inverted)
├─ Growth: 0.29 × 10% = 0.03
└─ Distribution: 0.42 × 10% = 0.04

MULTIPLIER: 1.0 + (0.52 × 2.0) = 2.04x

RECOMMENDATION: MODERATE
Action: Increase quality requirements, not just quantity.
  - Strong demand suggests value in experts
  - Good quality but some variance
  - Utilization could be better
  - Focus on activating inactive experts
  - Raise quality bar slightly (2.04x multiplier)
```

---

## 🌍 Locality-Based Expertise

### **Geographic Specificity of Expertise**

**The Problem:**
> Someone who knows Brooklyn coffee deeply isn't an expert on Manhattan coffee. Sheer quantity doesn't matter if it's not in the right place.

**The Solution:**
> Expertise is scoped to geographic areas. You can be a City-level expert in Brooklyn coffee without knowing all of NYC.

```dart
class LocalizedExpertise {
  final String userId;
  final String category;
  final ExpertiseLevel level;
  
  // Geographic scope (NEW)
  final List<GeographicScope> scopes;
  final GeographicScope primaryScope;
  
  /// Can host events in these areas
  List<String> get hostingLocations => 
    scopes.where((s) => s.level >= ExpertiseLevel.city).map((s) => s.location).toList();
}

class GeographicScope {
  final String location;        // "Brooklyn", "Manhattan", "Chicago"
  final ScopeType type;          // neighborhood, borough, city, state
  final ExpertiseLevel level;    // Level achieved in this area
  final int visitCount;          // Visits in this area
  final double qualityScore;     // Quality of engagement here
  final DateTime firstVisit;
  final DateTime lastVisit;
  
  /// Concentration score (visits in area / total visits)
  double get concentration => visitCount / totalUserVisits;
}

enum ScopeType {
  neighborhood,   // "Williamsburg"
  borough,        // "Brooklyn"
  city,           // "New York City"
  metro,          // "Greater NYC Area"
  state,          // "New York State"
  region,         // "Northeast"
  national,       // "United States"
}
```

### **How Locality Works:**

#### **1. Automatic Geographic Analysis**

```dart
class LocalityAnalyzer {
  /// Analyze user's geographic expertise distribution
  Future<List<GeographicScope>> analyzeUserLocality(
    String userId,
    String category,
  ) async {
    final visits = await _getUserVisits(userId, category);
    
    // Group visits by location
    final locationGroups = _groupByLocation(visits);
    
    final scopes = <GeographicScope>[];
    
    for (final location in locationGroups.keys) {
      final locationVisits = locationGroups[location]!;
      
      // Calculate expertise level for this location
      final localLevel = await _calculateLocalExpertiseLevel(
        userId,
        category,
        location,
        locationVisits,
      );
      
      scopes.add(GeographicScope(
        location: location,
        type: _determineScopeType(location),
        level: localLevel,
        visitCount: locationVisits.length,
        qualityScore: _calculateQualityScore(locationVisits),
        firstVisit: locationVisits.first.timestamp,
        lastVisit: locationVisits.last.timestamp,
      ));
    }
    
    return scopes..sort((a, b) => b.visitCount.compareTo(a.visitCount));
  }
  
  /// Calculate expertise level for specific location
  Future<ExpertiseLevel> _calculateLocalExpertiseLevel(
    String userId,
    String category,
    String location,
    List<Visit> visits,
  ) async {
    // Get requirements for this location
    final requirements = await _getLocalRequirements(category, location);
    
    // Check if user meets requirements
    final meetsVisits = visits.length >= requirements.minVisits;
    final qualityScore = _calculateQualityScore(visits);
    final meetsQuality = qualityScore >= requirements.minQualityScore;
    
    // Check other paths (credentials, influence, community) in this location
    final otherPaths = await _checkOtherPathsInLocation(
      userId,
      category,
      location,
    );
    
    // Combined score
    final totalScore = _combineScores(
      visits: visits.length,
      quality: qualityScore,
      otherPaths: otherPaths,
    );
    
    return _scoreToLevel(totalScore);
  }
}
```

#### **2. Local Expert Designation**

**Examples:**

```
Sarah's Coffee Expertise:

Brooklyn:
├─ Visits: 42 (80% of her total)
├─ Quality: 4.6★ average
├─ Reviews: 32
├─ Events hosted: 5 (all in Brooklyn)
├─ Level: City-level ✅
└─ CAN HOST EVENTS in Brooklyn

Manhattan:
├─ Visits: 8 (15% of her total)
├─ Quality: 4.4★ average
├─ Reviews: 5
├─ Level: Enthusiast
└─ CANNOT host events in Manhattan yet

Queens:
├─ Visits: 2 (4% of her total)
├─ Reviews: 1
├─ Level: Novice
└─ CANNOT host events in Queens

Sarah's Profile Shows:
"Coffee Expert in Brooklyn 🎯"
"Can host events in: Brooklyn"
```

**Mike's Italian Food Expertise:**

```
Chicago (Lincoln Park):
├─ Visits: 28 (highly concentrated)
├─ Professional: Chef at local Italian restaurant (verified) ✅
├─ Level: City-level ✅
└─ CAN HOST EVENTS in Lincoln Park

Chicago (Other neighborhoods):
├─ Visits: 12 (spread across neighborhoods)
├─ Level: Knowledgeable
└─ CANNOT host events yet

Mike's Profile Shows:
"Italian Food Expert in Lincoln Park, Chicago 🍝"
"Can host events in: Lincoln Park"
```

#### **3. Event Hosting Based on Locality**

```dart
class LocalEventHostingService {
  /// Check if user can host event at location
  Future<bool> canHostEventAtLocation(
    String userId,
    String category,
    String location,
  ) async {
    // Get user's geographic scopes
    final scopes = await _getUserGeographicScopes(userId, category);
    
    // Check if user has City-level expertise in this location
    final localScope = scopes.firstWhere(
      (s) => _isLocationWithinScope(location, s),
      orElse: () => null,
    );
    
    if (localScope == null) return false;
    if (localScope.level < ExpertiseLevel.city) return false;
    
    // Additional check: recent activity in area
    final recentActivity = await _hasRecentActivity(
      userId,
      location,
      Duration(days: 90), // Must have visited in last 90 days
    );
    
    return recentActivity;
  }
  
  /// Suggest hosting locations for user
  Future<List<String>> getRecommendedHostingLocations(
    String userId,
    String category,
  ) async {
    final scopes = await _getUserGeographicScopes(userId, category);
    
    return scopes
      .where((s) => s.level >= ExpertiseLevel.city)
      .where((s) => _hasRecentActivity(userId, s.location, Duration(days: 90)))
      .map((s) => s.location)
      .toList();
  }
}
```

#### **4. Local Saturation Analysis**

**Analyze saturation per geographic area:**

```dart
class LocalSaturationAnalyzer {
  /// Analyze saturation for specific location
  Future<SaturationMetrics> analyzeLocalSaturation(
    String category,
    String location,
  ) async {
    // Get experts with City-level in this specific location
    final localExperts = await _getExpertsInLocation(category, location);
    
    // Get total users interested in category in this location
    final localUsers = await _getUsersInLocation(category, location);
    
    // Apply same six-factor model but scoped to location
    return _calculateSaturationScore(
      supplyRatio: localExperts.length / localUsers.length,
      qualityDist: _analyzeLocalQuality(localExperts),
      utilization: _analyzeLocalUtilization(localExperts, location),
      demand: _analyzeLocalDemand(category, location),
      growth: _analyzeLocalGrowth(category, location),
      distribution: 0.0, // Not applicable at local level
    );
  }
  
  /// Example: Brooklyn vs Manhattan coffee saturation
  Future<Map<String, SaturationMetrics>> analyzeByNeighborhood(
    String category,
    String city,
  ) async {
    final neighborhoods = await _getNeighborhoods(city);
    final results = <String, SaturationMetrics>{};
    
    for (final neighborhood in neighborhoods) {
      results[neighborhood] = await analyzeLocalSaturation(category, neighborhood);
    }
    
    return results;
  }
}
```

**Example Output:**

```
NYC Coffee Expertise Saturation by Borough:

Brooklyn:
├─ Local experts: 45
├─ Local users: 1,200
├─ Ratio: 3.8%
├─ Saturation: 0.58 (moderate-high)
├─ Multiplier: 2.16x
└─ Recommendation: "Increase requirements"

Manhattan:
├─ Local experts: 68
├─ Local users: 2,500
├─ Ratio: 2.7%
├─ Saturation: 0.42 (moderate)
├─ Multiplier: 1.84x
└─ Recommendation: "Gradually increase requirements"

Queens:
├─ Local experts: 12
├─ Local users: 800
├─ Ratio: 1.5%
├─ Saturation: 0.25 (healthy)
├─ Multiplier: 1.50x
└─ Recommendation: "Maintain current requirements"

Bronx:
├─ Local experts: 4
├─ Local users: 400
├─ Ratio: 1.0%
├─ Saturation: 0.15 (need more)
├─ Multiplier: 1.30x
└─ Recommendation: "Encourage new experts"
```

#### **5. Progressive Geographic Expansion**

**Users naturally expand their territory:**

```
Sarah's Coffee Journey:

Month 1-3: Williamsburg (Brooklyn)
├─ Focus: One neighborhood
├─ Visits: 25 spots
└─ Status: Knowledgeable in Williamsburg

Month 4-6: Brooklyn-wide
├─ Expanded to: Park Slope, Dumbo, Greenpoint
├─ Total visits: 45 spots across Brooklyn
├─ Events hosted: 3 (all in Brooklyn)
└─ Status: City-level in Brooklyn ✅

Month 7-9: Starting Manhattan
├─ Visits: 8 spots in Manhattan
├─ Still City-level in Brooklyn
└─ Status: Enthusiast in Manhattan

Month 10-12: Multi-borough
├─ Brooklyn: City-level (maintained)
├─ Manhattan: Expert level (growing)
├─ Can host in: Brooklyn only
└─ Working toward: Manhattan hosting rights
```

---

## 🏅 Golden Local Expert - Long-Term Resident Designation

### **The Ultimate Local Authority**

**The Recognition:**
> 25+ continuous years living in the same neighborhood/area = Golden Local Expert

**Why This Matters:**
- Long-term residents have **irreplaceable historical knowledge**
- They've seen businesses come and go
- They know the community deeply
- They understand what works and what doesn't
- They are the **keepers of local culture**

```dart
class GoldenLocalExpert {
  final String userId;
  final String location;          // "Williamsburg, Brooklyn"
  final Duration residency;       // Must be 25+ years
  final DateTime moveInDate;
  final DateTime? moveOutDate;    // Must be null (still living there)
  
  // Proof of residency (REQUIRED)
  final List<ResidencyProof> proofDocuments;
  final bool verified;
  
  // Special privileges
  final List<GoldenExpertPrivilege> privileges;
  
  // Recognition
  final DateTime designationDate;
  final String badge;              // "Golden Local Expert" badge
  
  /// Must be continuous and current
  bool get qualifies => 
    residency >= Duration(days: 25 * 365) && 
    moveOutDate == null &&
    verified;
}

enum GoldenExpertPrivilege {
  curateEvents,           // Can suggest/approve events for area
  advisoryBoard,          // Part of neighborhood advisory board
  eventPriority,          // Events prioritized in local discovery
  verifyLocalBusiness,    // Can help verify local businesses
  historicalContext,      // Can provide historical insights
  communityGuide,         // Designated community guide
}

class ResidencyProof {
  final ResidencyProofType type;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String location;
  final String documentUrl;       // Photo/scan of proof
  final bool verified;
}

enum ResidencyProofType {
  utilityBills,           // 25+ years of bills
  leaseAgreements,        // Rental history
  propertyDeed,           // Home ownership records
  taxRecords,             // Property tax records
  voterRegistration,      // Voting address history
  schoolRecords,          // Children's school records
  employmentRecords,      // Employer address history
  driversLicense,         // License address history
  communityAffidavit,     // 3+ long-term residents attest
}
```

### **Verification Process:**

**Step 1: User Claims Golden Status**
```
User in system for 5+ years submits claim:
├─ "I've lived in Williamsburg for 30 years"
├─ Uploads proof documents
└─ System initiates verification
```

**Step 2: Document Review**
```
Accepted proof (need 3+ pieces spanning 25 years):
├─ Property deed (if homeowner)
├─ 25 years of utility bills
├─ Voter registration records
├─ Driver's license history
├─ Tax records
├─ School records (if applicable)
└─ Community member attestations (3+ other verified residents)
```

**Step 3: Community Validation**
```
System checks:
├─ Do other verified users know this person?
├─ Are there local businesses that recognize them?
├─ Is there community consensus?
└─ Admin final review
```

**Step 4: Golden Designation Granted**
```
✅ Golden Local Expert badge awarded
├─ Profile shows: "Local Expert - 30 years in Williamsburg"
├─ Special golden badge icon
├─ Advisory privileges activated
└─ Community notification
```

---

## 🎯 Golden Expert Powers & Responsibilities

### **Power 1: Event Curation & Advisory**

**What They Can Do:**
```dart
class EventCurationService {
  /// Golden experts can review and advise on local events
  Future<EventCurationAdvice> reviewEventProposal(
    String goldenExpertId,
    String eventId,
  ) async {
    final expert = await _getGoldenExpert(goldenExpertId);
    final event = await _getEvent(eventId);
    
    // Check if event is in their area
    if (!_isInExpertArea(event.location, expert.location)) {
      throw Exception('Event must be in expert\'s area');
    }
    
    // Golden expert provides feedback
    return EventCurationAdvice(
      expertId: goldenExpertId,
      eventId: eventId,
      recommendation: expert.recommendation,
      reasoning: expert.reasoning,
      suggestions: expert.suggestions,
      historicalContext: expert.historicalContext,
      communityFit: expert.communityFitScore,
    );
  }
}

class EventCurationAdvice {
  final String expertId;
  final String eventId;
  final CurationRecommendation recommendation;
  final String reasoning;
  final List<String> suggestions;
  final String? historicalContext;
  final double communityFitScore;  // 0-1, how well event fits area
}

enum CurationRecommendation {
  stronglyRecommend,   // "This is perfect for our neighborhood"
  recommend,           // "Good fit, some suggestions"
  neutral,             // "No strong opinion"
  concerns,            // "Some concerns about fit"
  notRecommended,      // "Doesn't fit our community"
}
```

**Example:**

```
Event Proposal: "Loud Electronic Music Festival in Residential Block"

Golden Expert Review:
├─ Recommendation: Not Recommended
├─ Reasoning: "I've lived here 30 years. This is a quiet 
│   residential area with many families and elderly residents.
│   Past late-night events caused community friction. Better
│   suited for the industrial area 3 blocks south."
│
├─ Suggestions:
│   • Move to industrial zone (Wythe Ave)
│   • Keep volume moderate
│   • End by 10 PM if in residential
│   • Notify residents in advance
│
├─ Historical Context: "In 1998, we had a similar event that 
│   resulted in 20+ noise complaints and damaged community
│   relations for years. Let's learn from that."
│
└─ Community Fit Score: 0.2 / 1.0 (poor fit)

Result: Event host sees feedback, decides to either:
├─ Adjust event (move location, change format)
├─ Proceed anyway (but with community warning)
└─ Cancel and rethink
```

**Good Event Example:**

```
Event Proposal: "Neighborhood Coffee Meet-Up at Local Cafe"

Golden Expert Review:
├─ Recommendation: Strongly Recommend
├─ Reasoning: "Perfect! This cafe has been here 40 years,
│   family-owned, heart of the community. Weekend mornings
│   are ideal timing when families are out."
│
├─ Suggestions:
│   • Mention the cafe's history in event description
│   • Coordinate with Maria (owner) - she's been here 35 years
│   • Could tie it to neighborhood history walk afterward
│
├─ Historical Context: "This cafe was founded by Maria's
│   parents. It's survived 3 recessions and gentrification
│   waves. Supporting it supports our community's roots."
│
└─ Community Fit Score: 0.95 / 1.0 (excellent fit)

Result: Event promoted with golden expert endorsement
```

---

### **Power 2: Neighborhood Advisory Board**

**Automatic Inclusion:**
```dart
class NeighborhoodAdvisoryBoard {
  final String neighborhood;
  final List<GoldenLocalExpert> members;
  
  /// Golden experts automatically join their neighborhood board
  Future<void> addGoldenExpert(GoldenLocalExpert expert) async {
    final board = await _getOrCreateBoard(expert.location);
    
    board.members.add(expert);
    
    // Notify community
    await _notifyCommunity(
      expert.location,
      '${expert.name} (${expert.residency.inYears} year resident) '
      'joined the neighborhood advisory board'
    );
  }
  
  /// Board votes on major community changes
  Future<BoardVote> voteOnProposal(
    String boardId,
    CommunityProposal proposal,
  ) async {
    // Examples of proposals:
    // - Major event series
    // - Business verification standards
    // - Community guidelines
    // - Event type restrictions
  }
}
```

**Board Responsibilities:**
- Review event trends in the area
- Provide feedback on community guidelines
- Help verify local businesses
- Resolve disputes about event appropriateness
- Preserve neighborhood character
- Welcome newcomers while honoring history

---

### **Power 3: Priority Event Visibility**

**Events curated/approved by golden experts get boosted:**

```dart
class EventDiscoveryService {
  /// Golden expert endorsement boosts event visibility
  Future<List<Event>> getLocalEvents(String location) async {
    final events = await _getEventsInLocation(location);
    
    // Sort by relevance
    events.sort((a, b) {
      double scoreA = _calculateRelevanceScore(a);
      double scoreB = _calculateRelevanceScore(b);
      
      // Golden expert boost
      if (a.goldenExpertEndorsed) scoreA *= 1.5;
      if (b.goldenExpertEndorsed) scoreB *= 1.5;
      
      return scoreB.compareTo(scoreA);
    });
    
    return events;
  }
}
```

**UI Display:**

```
┌────────────────────────────────────────────┐
│  Coffee Walk Through Williamsburg          │
│  by @sarah_coffee                          │
├────────────────────────────────────────────┤
│                                            │
│  🏅 Endorsed by Golden Local Expert        │
│  Maria Rodriguez (32 years in Williamsburg)│
│                                            │
│  "Sarah's tour perfectly captures our      │
│   neighborhood's coffee culture. She knows │
│   the history and the owners. Highly       │
│   recommend!" - Maria                      │
│                                            │
│  📅 Saturday, Dec 2 • 10 AM                │
│  👥 12/15 spots filled                     │
│                                            │
│  [View Details] [Register]                 │
│                                            │
└────────────────────────────────────────────┘
```

---

### **Power 4: Community Guide Designation**

**Golden experts appear in discovery:**

```
User exploring Williamsburg for first time:

┌────────────────────────────────────────────┐
│  🏅 Golden Local Experts in Williamsburg   │
├────────────────────────────────────────────┤
│                                            │
│  Maria Rodriguez                           │
│  🏅 32 years in Williamsburg               │
│  "Coffee shops, family-owned spots"        │
│  [Follow] [Ask Question]                   │
│                                            │
│  James Chen                                │
│  🏅 28 years in Williamsburg               │
│  "Art galleries, music venues, history"    │
│  [Follow] [Ask Question]                   │
│                                            │
│  Sophie Williams                           │
│  🏅 40 years in Williamsburg               │
│  "Italian restaurants, hidden gems"        │
│  [Follow] [Ask Question]                   │
│                                            │
│  💡 These long-term residents know the     │
│     area's history and culture deeply.     │
│                                            │
└────────────────────────────────────────────┘
```

---

## 📊 Golden Expert Examples

### **Example 1: Maria Rodriguez**

```
Maria Rodriguez
🏅 Golden Local Expert - Williamsburg, Brooklyn

Residency:
├─ Living in Williamsburg: 32 years (1992-present)
├─ Property owner: 456 Bedford Ave (since 1995)
├─ Business owner: Maria's Cafe (28 years)
└─ Raised 3 children in neighborhood

Verification:
├─ Property deed (verified) ✅
├─ Business license (28 years) ✅
├─ Voter registration (continuous) ✅
├─ Community attestations (12 residents) ✅
└─ Status: Verified Golden Expert ✅

Advisory Activities:
├─ Events reviewed: 47
├─ Strong recommendations: 31
├─ Concerns raised: 8 (all addressed)
├─ Community impact: 4.9 / 5.0
└─ Trusted by 890 community members

Specializations:
├─ Coffee shops (owned one for 28 years)
├─ Family-friendly spots
├─ Neighborhood history
└─ Community events

Profile Quote:
"I've watched Williamsburg transform over 32 years.
While change is inevitable, I'm here to help preserve
what makes our neighborhood special and ensure new
events respect our community's character."
```

### **Example 2: James Chen**

```
James Chen
🏅 Golden Local Expert - Lincoln Park, Chicago

Residency:
├─ Living in Lincoln Park: 28 years (1996-present)
├─ Homeowner: Same house since 1998
├─ Children attended local schools (20+ years)
└─ Former neighborhood association president

Verification:
├─ Property tax records (26 years) ✅
├─ School records (children, 1998-2018) ✅
├─ Voter registration (continuous) ✅
├─ Community attestations (8 residents) ✅
└─ Status: Verified Golden Expert ✅

Advisory Focus:
├─ Art & culture events
├─ Music venues (knows history of all)
├─ Restaurant changes over decades
└─ Development impact assessment

Notable Contributions:
├─ Helped verify 15 historic businesses
├─ Provided context for 60+ events
├─ Resolved 3 community disputes
└─ Mentored 12 new event hosts

Historical Knowledge:
"I remember when this area had 3 jazz clubs,
now there's 1. Let's not lose the last one.
Events here should honor that musical heritage."
```

---

## 🎖️ Expertise Hierarchy (Updated)

```
Expertise Levels (Updated):

Novice (0-0.20)
├─ Just starting
└─ Exploring category

Enthusiast (0.21-0.39)
├─ Active engagement
└─ Growing knowledge

Knowledgeable (0.40-0.49)
├─ Solid understanding
└─ Can contribute

Expert (0.50-0.59)
├─ Deep knowledge
└─ Recognized by community

City (0.60-0.74) ⭐
├─ Can host events
└─ Trusted local authority

🏅 Golden Local Expert (Special)
├─ 25+ years continuous residency ✅
├─ Community advisory role
├─ Event curation powers
├─ Lifetime designation
└─ Highest local authority

State (0.75-0.89)
├─ Regional authority
└─ Multi-city expertise

National (0.90+)
├─ National recognition
└─ Industry authority
```

**Key Notes:**
- Golden is **separate** from the score ladder
- Golden = Lifetime achievement for residency
- Golden experts can have ANY expertise score
- They might not visit many spots, but they **know the area**
- Combines with other expertise types

---

## 🎯 Golden Expert + Other Expertise

**Combinations:**

```
Golden Local Expert + Low Exploration:
├─ 30 years residency ✅
├─ 8 spot visits logged
├─ Exploration score: 0.30
└─ Role: Advisory, historical context, community fit

Result: Can review events, provide context,
but cannot host events (needs City-level 0.60)

Golden Local Expert + Professional:
├─ 28 years residency ✅
├─ Restaurant owner (verified)
├─ 15 spot visits
├─ Professional score: 0.85
├─ Total expertise: 0.62 ✅
└─ Role: Can host AND advise

Result: Perfect combination - both authority types

Golden Local Expert + High Exploration:
├─ 32 years residency ✅
├─ 55 spot visits
├─ Active reviewer (4.7★ avg)
├─ Total expertise: 0.78 ✅
└─ Role: Ultimate local authority

Result: The ideal - deep residency + active exploration
```

---

## 🎖️ Progressive Expertise Levels

### **From Novice → Expert (Scalable)**

```dart
enum ExpertiseLevel {
  novice,       // Just joined, exploring
  enthusiast,   // Active in category
  knowledgeable, // Solid understanding
  expert,       // Can mentor others
  city,         // Can host events (current threshold)
  state,        // Regional authority
  national,     // National authority
  global,       // Global authority
}

class ExpertiseProgression {
  /// Requirements scale with platform phase AND category saturation
  Map<ExpertiseLevel, ExpertiseRequirements> getRequirements(
    String category,
    PlatformPhase phase,
  ) {
    final saturation = _getCategorySaturation(category);
    final baseReqs = _getBaseRequirements(phase);
    
    return {
      ExpertiseLevel.novice: ExpertiseRequirements(
        minVisits: 0,
        minRatings: 0,
        minAvgRating: 0,
        minTimeInCategory: Duration.zero,
      ),
      
      ExpertiseLevel.enthusiast: ExpertiseRequirements(
        minVisits: (5 * saturation).ceil(),
        minRatings: (3 * saturation).ceil(),
        minAvgRating: 3.5,
        minTimeInCategory: Duration(days: 14),
      ),
      
      ExpertiseLevel.knowledgeable: ExpertiseRequirements(
        minVisits: (10 * saturation).ceil(),
        minRatings: (7 * saturation).ceil(),
        minAvgRating: 4.0,
        minTimeInCategory: Duration(days: 30),
      ),
      
      ExpertiseLevel.expert: ExpertiseRequirements(
        minVisits: (20 * saturation).ceil(),
        minRatings: (12 * saturation).ceil(),
        minAvgRating: 4.2,
        minTimeInCategory: Duration(days: 60),
        minCommunityEngagement: (8 * saturation).ceil(),
      ),
      
      // Local level = Can host events (City level = Expanded hosting scope)
      ExpertiseLevel.city: _getCityRequirements(baseReqs, saturation),
      
      // Higher levels for future
      ExpertiseLevel.state: _getStateRequirements(baseReqs, saturation),
      ExpertiseLevel.national: _getNationalRequirements(baseReqs, saturation),
      ExpertiseLevel.global: _getGlobalRequirements(baseReqs, saturation),
    };
  }
  
  /// Get current requirements for user to reach City level
  Future<ExpertiseGap> getGapToEventHosting(
    String userId,
    String category,
  ) async {
    final phase = DynamicExpertiseThresholds.getCurrentPhase();
    final requirements = getCityLevelRequirements(category, phase);
    final current = await _getUserProgress(userId, category);
    
    return ExpertiseGap(
      currentLevel: current.level,
      targetLevel: ExpertiseLevel.city,
      requirements: requirements,
      currentProgress: current,
      gaps: {
        'visits': requirements.minVisits - current.visits,
        'ratings': requirements.minRatings - current.ratings,
        'avgRating': requirements.minAvgRating - current.avgRating,
        'time': requirements.minTimeInCategory - current.timeInCategory,
      },
      estimatedTimeToReach: _calculateEstimatedTime(current, requirements),
    );
  }
}
```

---

## 📱 User-Facing Transparency

### **Progress Tracker UI**

**Show users exactly what they need:**

```
┌────────────────────────────────────────────────────┐
│  Your Coffee Expertise Progress                    │
├────────────────────────────────────────────────────┤
│                                                    │
│  Current Level: ⭐⭐⭐ Expert                       │
│  Next Level: 🎯 City (Can Host Events!)           │
│                                                    │
│  Progress to Event Hosting:                        │
│                                                    │
│  Visits:          [████████████░░] 35/50           │
│  Ratings Given:   [████████████░░] 20/35           │
│  Avg Rating:      [██████████████] 4.5/4.5 ✅      │
│  Time Active:     [██████████░░░] 90/120 days     │
│  Review Quality:  [████████████░░] 4.3/4.5         │
│  Engagement:      [████████████░░] 22/35 points    │
│                                                    │
│  📊 Overall: 73% Complete                          │
│  ⏱️  Estimated: 30 days at current pace            │
│                                                    │
│  ⚠️  Note: Requirements increase as platform grows │
│     Current phase: Growth (10K users)              │
│     Coffee saturation: Medium (1.5x multiplier)    │
│                                                    │
│  💡 Tips to reach City level faster:               │
│  • Write 3 more quality reviews (high detail)      │
│  • Visit 15 more coffee spots                      │
│  • Engage with community (comment, help others)    │
│                                                    │
│  [View Detailed Breakdown] [Find Spots to Visit]   │
│                                                    │
└────────────────────────────────────────────────────┘
```

### **Historical Context UI**

**Show how thresholds have changed:**

```
┌────────────────────────────────────────────────────┐
│  Coffee Expertise Requirements History             │
├────────────────────────────────────────────────────┤
│                                                    │
│  📅 January 2025 (Bootstrap Phase)                 │
│  To reach City level: 10 visits, 5 ratings         │
│  ✅ You: Reached City level Feb 2025               │
│                                                    │
│  📅 June 2025 (Growth Phase)                       │
│  New requirement: 20 visits, 10 ratings            │
│  📌 Your City status: Grandfathered ✅             │
│                                                    │
│  📅 November 2025 (Current - Growth Phase)         │
│  Current requirement: 35 visits, 20 ratings        │
│  Coffee saturation: 1.5x (popular category)        │
│  Actual requirement: 50+ visits, 35 ratings        │
│                                                    │
│  💡 As an early City-level expert, you maintain    │
│     your status. New users must meet current       │
│     requirements to reach your level.              │
│                                                    │
│  This ensures expertise remains meaningful as      │
│  the platform grows. Quality over quantity!        │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## 🛡️ Grandfathering Policy

### **Early Experts Keep Their Status**

**The Rule:**
> If you earned City-level when requirements were lower, you keep it. But to reach State or higher, you must meet current standards.

```dart
class ExpertiseGrandfathering {
  /// Check if user's expertise was earned under old requirements
  Future<bool> isGrandfathered(
    String userId,
    String category,
    ExpertiseLevel level,
  ) async {
    final achievement = await _getExpertiseAchievement(
      userId,
      category,
      level,
    );
    
    if (achievement == null) return false;
    
    // Get requirements at time of achievement
    final oldRequirements = await _getHistoricalRequirements(
      category,
      achievement.achievedAt,
    );
    
    // Get current requirements
    final currentRequirements = await _getCurrentRequirements(category);
    
    // If current requirements are higher and user met old ones
    final wasEasier = oldRequirements.isLessThan(currentRequirements);
    final metOldRequirements = achievement.meetsRequirements(oldRequirements);
    
    return wasEasier && metOldRequirements;
  }
  
  /// User keeps their level, but must meet current requirements to advance
  Future<bool> canAdvanceToNextLevel(
    String userId,
    String category,
    ExpertiseLevel targetLevel,
  ) async {
    // Must meet CURRENT requirements to advance
    // No grandfathering for new levels
    final currentRequirements = await _getCurrentRequirements(
      category,
      targetLevel,
    );
    
    final userProgress = await _getUserProgress(userId, category);
    
    return userProgress.meetsRequirements(currentRequirements);
  }
}
```

**Example:**

```
Sarah earned City-level in February 2025:
├─ Requirements then: 10 visits, 5 ratings
├─ She met them: 15 visits, 8 ratings ✅
└─ Status: City-level expert

November 2025 (now):
├─ New requirements: 50 visits, 35 ratings
├─ Sarah's status: Still City-level ✅ (grandfathered)
├─ New users must: Meet 50/35 requirements
└─ Sarah to reach State: Must meet current State requirements

This is fair:
✅ Sarah earned her status legitimately
✅ Her status remains valuable (not everyone can get it now)
✅ New users know requirements are rigorous
✅ Trust in "expert" title maintained
```

---

## 🎯 Quality Over Time Metrics

### **Not Just Quantity - Quality Matters More**

```dart
class ExpertiseQualityMetrics {
  /// Calculate quality score (more important than quantity)
  Future<double> calculateQualityScore(
    String userId,
    String category,
  ) {
    final metrics = await _getUserMetrics(userId, category);
    
    return QualityScore(
      // Rating quality (40% weight)
      avgRatingGiven: metrics.avgRating,          // 4.5/5.0
      reviewDepth: metrics.avgReviewLength,       // Detailed reviews
      reviewHelpfulness: metrics.helpfulVotes,    // Others found useful
      
      // Engagement quality (30% weight)
      communityHelp: metrics.questionsAnswered,   // Helping others
      constructiveFeedback: metrics.feedbackScore, // Constructive criticism
      eventQuality: metrics.avgEventRating,       // If hosting events
      
      // Consistency (20% weight)
      activityConsistency: metrics.activitySpread, // Regular, not sporadic
      categoryFocus: metrics.categoryDedication,  // Deep vs. shallow
      
      // Reputation (10% weight)
      peerEndorsements: metrics.endorsements,     // Other experts vouch
      flaggedContent: metrics.flagCount,          // Low = good
    ).calculate();
  }
  
  /// Require minimum quality threshold
  static const double MINIMUM_QUALITY_SCORE = 0.70; // 70%
  
  /// Even if quantity requirements met, quality must pass
  bool meetsExpertiseRequirements(
    UserProgress progress,
    ExpertiseRequirements requirements,
  ) {
    final quantityMet = progress.meetsQuantityRequirements(requirements);
    final qualityScore = calculateQualityScore(progress.userId, progress.category);
    final qualityMet = qualityScore >= MINIMUM_QUALITY_SCORE;
    
    // BOTH must be true
    return quantityMet && qualityMet;
  }
}
```

---

## 📊 Admin Dashboard - Threshold Management

### **Monitor and Adjust Thresholds**

```
┌────────────────────────────────────────────────────┐
│  Expertise Threshold Management                    │
├────────────────────────────────────────────────────┤
│                                                    │
│  Platform Phase: Growth (8,742 users)              │
│  Next phase: Scale (at 10,000 users)               │
│                                                    │
│  Category Saturation Analysis:                     │
│                                                    │
│  🔴 Over-saturated (>3% experts):                  │
│  ├─ Coffee: 4.2% experts (210/5,000)               │
│  │   Current multiplier: 2.1x                      │
│  │   Recommendation: Increase to 2.5x              │
│  │                                                  │
│  └─ Pizza: 3.8% experts (95/2,500)                 │
│      Current multiplier: 1.9x                      │
│      Status: Balanced                              │
│                                                    │
│  🟡 Balanced (1.5-3% experts):                     │
│  ├─ Wine: 2.1% experts                             │
│  ├─ Books: 1.8% experts                            │
│  └─ Art: 2.5% experts                              │
│                                                    │
│  🟢 Under-saturated (<1.5% experts):               │
│  ├─ Tea Blending: 0.8% experts (2/250)             │
│  │   Current multiplier: 1.0x                      │
│  │   Recommendation: Keep low to encourage         │
│  │                                                  │
│  └─ Rare Books: 0.3% experts (1/300)               │
│      Status: Needs experts                         │
│                                                    │
│  Pending Level-Ups:                                │
│  ├─ 47 users approaching City level                │
│  ├─ 12 users approaching State level               │
│  └─ Est. next month: +15 new City experts          │
│                                                    │
│  [Adjust Thresholds] [View Trends] [Export Data]   │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## 🎯 Success Metrics

### **Platform Health Indicators:**

```dart
class ExpertiseSystemHealth {
  /// Track if the system is working
  Future<HealthReport> generateHealthReport() async {
    return HealthReport(
      // Expert ratio should stay 1-3% per category
      avgExpertRatio: 2.1,      // ✅ Target: 2%
      
      // Quality should increase over time
      avgExpertQuality: 4.4,    // ✅ Target: 4.0+
      
      // Event quality from expert-hosted events
      avgEventRating: 4.6,      // ✅ Target: 4.5+
      
      // User trust in experts
      expertTrustScore: 0.82,   // ✅ Target: 0.75+
      
      // Progression is achievable
      avgTimeToCity: 120,       // ✅ Target: 90-180 days
      
      // No gaming the system
      suspiciousProgressions: 2, // ✅ Target: <5
    );
  }
}
```

---

## 🚀 Implementation Phases

### **Phase 1: Dynamic Thresholds (1 week)**
- Implement phase-based scaling
- Category saturation analysis
- Database schema for historical requirements

### **Phase 2: Quality Metrics (1 week)**
- Quality score calculation
- Combined quantity + quality requirements
- Fraud detection for gaming system

### **Phase 3: User Transparency (1 week)**
- Progress tracker UI
- Historical context display
- Estimated time to level up

### **Phase 4: Grandfathering System (3 days)**
- Track when expertise earned
- Grandfather early experts
- Current requirements for advancement

### **Phase 5: Admin Tools (3 days)**
- Saturation dashboard
- Threshold adjustment interface
- Health monitoring

**Total: 3.5 weeks**

---

## 💡 Philosophy Alignment

### **"Trust Through Earned Authority"**

✅ **Early adopters rewarded** - Easy to become expert at first (bootstrap)  
✅ **Quality maintained** - Harder as platform grows (prevent dilution)  
✅ **Transparency** - Users see requirements and why they change  
✅ **Fairness** - Grandfathering protects early contributors  
✅ **Dynamic** - System adapts to prevent oversaturation  

### **"Always Learning With You"**

✅ **Progressive system** - Clear path from novice → expert  
✅ **Feedback-driven** - Quality metrics guide improvement  
✅ **Community-focused** - Helping others matters  

### **"Authenticity Over Algorithms"**

✅ **Real expertise** - Can't game with fake activity  
✅ **Quality over quantity** - 70% quality score required  
✅ **Peer validation** - Other experts can endorse  

---

## ✅ Summary

**The Problem:** 
- Everyone becoming an "expert" dilutes trust
- Need experts early, but too many later hurts quality

**The Solution:**
- Dynamic thresholds that increase with platform growth
- Category-specific requirements (popular = harder)
- Quality metrics (not just quantity)
- Grandfathering for early adopters
- Full transparency to users

**Key Numbers:**
- Target: 1-3% of category users should be City-level
- Quality threshold: 70% score minimum
- Saturation multiplier: 1.0x - 3.0x depending on category
- Grandfathering: Keep earned status, but current requirements to advance

**Status:** 🟢 Ready for implementation  
**Timeline:** 3.5 weeks  
**Dependencies:** Expertise system (exists), personality dimensions (exists)

---

**This ensures "expert" means something valuable and trustworthy, forever.** 🎖️✨

---

**Last Updated:** November 21, 2025  
**Related Plans:**
- Event Partnership & Monetization Plan (experts host events)
- Brand Discovery & Sponsorship Plan (vibe matching)
- Expand Personality Dimensions Plan (vibe calculations)

