import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/models/visit.dart';
import 'package:spots/core/services/logger.dart';

/// Multi-Path Expertise Service
/// 
/// Calculates expertise scores for all 6 paths to expertise.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise through multiple paths
/// - Recognizes different types of expertise
/// - Supports diverse ways to become an expert
/// 
/// **Path Weights:**
/// - Exploration (40%): Visits, reviews, check-ins
/// - Credentials (25%): Degrees, certifications
/// - Influence (20%): Followers, shares, lists
/// - Professional (25%): Proof of work
/// - Community (15%): Contributions, endorsements
/// - Local (varies): Locality-based expertise
class MultiPathExpertiseService {
  static const String _logName = 'MultiPathExpertiseService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  /// Calculate exploration expertise (40% weight)
  /// 
  /// Based on visits, reviews, check-ins, dwell time, quality scores.
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// - `visits`: List of visits in category
  /// 
  /// **Returns:**
  /// ExplorationExpertise with calculated score
  Future<ExplorationExpertise> calculateExplorationExpertise({
    required String userId,
    required String category,
    required List<Visit> visits,
  }) async {
    try {
      _logger.info(
        'Calculating exploration expertise: user=$userId, category=$category',
        tag: _logName,
      );

      if (visits.isEmpty) {
        return _createEmptyExplorationExpertise(userId, category);
      }

      // Calculate metrics
      final uniqueLocations = visits.map((v) => v.locationId).toSet().length;
      final repeatVisits = visits.length - uniqueLocations;
      final reviewsGiven = visits.where((v) => v.reviewId != null).length;
      final ratings = visits.where((v) => v.rating != null).map((v) => v.rating!).toList();
      final averageRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      final qualityScores = visits.map((v) => v.qualityScore).toList();
      final averageQualityScore = qualityScores.isEmpty
          ? 0.0
          : qualityScores.reduce((a, b) => a + b) / qualityScores.length;

      final highQualityVisits = visits.where((v) => v.qualityScore >= 1.0).length;

      final totalDwellTime = visits
          .where((v) => v.dwellTime != null)
          .map((v) => v.dwellTime!)
          .fold<Duration>(
            Duration.zero,
            (sum, duration) => sum + duration,
          );

      final sortedVisits = visits.toList()
        ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));
      final firstVisit = sortedVisits.first.checkInTime;
      final lastVisit = sortedVisits.last.checkInTime;

      // Calculate score (0.0 to 1.0)
      final score = _calculateExplorationScore(
        totalVisits: visits.length,
        uniqueLocations: uniqueLocations,
        reviewsGiven: reviewsGiven,
        averageRating: averageRating,
        averageQualityScore: averageQualityScore,
        highQualityVisits: highQualityVisits,
      );

      return ExplorationExpertise(
        id: _generateId(),
        userId: userId,
        category: category,
        totalVisits: visits.length,
        uniqueLocations: uniqueLocations,
        repeatVisits: repeatVisits,
        reviewsGiven: reviewsGiven,
        averageRating: averageRating,
        averageQualityScore: averageQualityScore,
        highQualityVisits: highQualityVisits,
        totalDwellTime: totalDwellTime,
        firstVisit: firstVisit,
        lastVisit: lastVisit,
        score: score,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error calculating exploration expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate credential expertise (25% weight)
  /// 
  /// Based on degrees, certifications, published work, awards.
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// - `degrees`: List of education credentials
  /// - `certifications`: List of certification credentials
  /// - `publishedWork`: List of published work
  /// - `awards`: List of awards
  /// - `yearsOfExperience`: Years of industry experience
  /// 
  /// **Returns:**
  /// CredentialExpertise with calculated score
  Future<CredentialExpertise> calculateCredentialExpertise({
    required String userId,
    required String category,
    List<EducationCredential> degrees = const [],
    List<CertificationCredential> certifications = const [],
    List<PublishedWork> publishedWork = const [],
    List<Award> awards = const [],
    int yearsOfExperience = 0,
    bool isVerified = false,
  }) async {
    try {
      _logger.info(
        'Calculating credential expertise: user=$userId, category=$category',
        tag: _logName,
      );

      // Calculate score (0.0 to 1.0)
      final score = _calculateCredentialScore(
        degrees: degrees,
        certifications: certifications,
        publishedWork: publishedWork,
        awards: awards,
        yearsOfExperience: yearsOfExperience,
        isVerified: isVerified,
      );

      return CredentialExpertise(
        id: _generateId(),
        userId: userId,
        category: category,
        degrees: degrees,
        certifications: certifications,
        yearsOfExperience: yearsOfExperience,
        publishedWork: publishedWork,
        awards: awards,
        isVerified: isVerified,
        verifiedAt: isVerified ? DateTime.now() : null,
        score: score,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error calculating credential expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate influence expertise (20% weight)
  /// 
  /// Based on followers, list saves/shares, external platform influence.
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// - `spotsFollowers`: SPOTS platform followers
  /// - `listSaves`: List saves
  /// - `listShares`: List shares
  /// - `curatedLists`: Number of curated lists
  /// - `externalPlatforms`: External platform influence
  /// 
  /// **Returns:**
  /// InfluenceExpertise with calculated score
  Future<InfluenceExpertise> calculateInfluenceExpertise({
    required String userId,
    required String category,
    int spotsFollowers = 0,
    int listSaves = 0,
    int listShares = 0,
    int curatedLists = 0,
    List<ExternalPlatformInfluence> externalPlatforms = const [],
  }) async {
    try {
      _logger.info(
        'Calculating influence expertise: user=$userId, category=$category',
        tag: _logName,
      );

      // Calculate external platform influence
      final externalInfluence = externalPlatforms
          .map((p) => _calculateExternalPlatformScore(p))
          .fold<double>(0.0, (sum, score) => sum + score);

      // Calculate list engagement
      final listEngagement = listSaves + listShares;

      // Calculate popular lists (lists with high engagement)
      final popularLists = curatedLists > 0 && listEngagement > 100
          ? (curatedLists * 0.5).ceil()
          : 0;

      // Calculate score (0.0 to 1.0) - normalized logarithmically
      final score = _calculateInfluenceScore(
        spotsFollowers: spotsFollowers,
        listSaves: listSaves,
        listShares: listShares,
        listEngagement: listEngagement,
        curatedLists: curatedLists,
        externalInfluence: externalInfluence,
      );

      return InfluenceExpertise(
        id: _generateId(),
        userId: userId,
        category: category,
        spotsFollowers: spotsFollowers,
        listSaves: listSaves,
        listShares: listShares,
        listEngagement: listEngagement,
        externalPlatforms: externalPlatforms,
        curatedLists: curatedLists,
        popularLists: popularLists,
        score: score,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error calculating influence expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate professional expertise (25% weight)
  /// 
  /// Based on professional roles, proof of work, peer endorsements.
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// - `roles`: List of professional roles
  /// - `proofOfWork`: List of proof of work
  /// - `peerEndorsements`: List of peer endorsements
  /// 
  /// **Returns:**
  /// ProfessionalExpertise with calculated score
  Future<ProfessionalExpertise> calculateProfessionalExpertise({
    required String userId,
    required String category,
    List<ProfessionalRole> roles = const [],
    List<ProofOfWork> proofOfWork = const [],
    List<PeerEndorsement> peerEndorsements = const [],
    bool isVerified = false,
  }) async {
    try {
      _logger.info(
        'Calculating professional expertise: user=$userId, category=$category',
        tag: _logName,
      );

      // Calculate score (0.0 to 1.0)
      final score = _calculateProfessionalScore(
        roles: roles,
        proofOfWork: proofOfWork,
        peerEndorsements: peerEndorsements,
        isVerified: isVerified,
      );

      return ProfessionalExpertise(
        id: _generateId(),
        userId: userId,
        category: category,
        roles: roles,
        proofOfWork: proofOfWork,
        peerEndorsements: peerEndorsements,
        isVerified: isVerified,
        verifiedAt: isVerified ? DateTime.now() : null,
        score: score,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error calculating professional expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate community expertise (15% weight)
  /// 
  /// Based on questions answered, list curation, events hosted, endorsements.
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// - `questionsAnswered`: Questions answered
  /// - `curatedLists`: Number of curated lists
  /// - `eventsHosted`: Number of events hosted
  /// - `averageEventRating`: Average event rating
  /// - `peerEndorsements`: Number of peer endorsements
  /// - `communityContributions`: Community contributions
  /// 
  /// **Returns:**
  /// CommunityExpertise with calculated score
  Future<CommunityExpertise> calculateCommunityExpertise({
    required String userId,
    required String category,
    int questionsAnswered = 0,
    int curatedLists = 0,
    int eventsHosted = 0,
    double averageEventRating = 0.0,
    int peerEndorsements = 0,
    int communityContributions = 0,
  }) async {
    try {
      _logger.info(
        'Calculating community expertise: user=$userId, category=$category',
        tag: _logName,
      );

      // Calculate popular lists (lists with high engagement)
      final popularLists = curatedLists > 0 ? (curatedLists * 0.3).ceil() : 0;

      // Calculate score (0.0 to 1.0)
      final score = _calculateCommunityScore(
        questionsAnswered: questionsAnswered,
        curatedLists: curatedLists,
        eventsHosted: eventsHosted,
        averageEventRating: averageEventRating,
        peerEndorsements: peerEndorsements,
        communityContributions: communityContributions,
      );

      return CommunityExpertise(
        id: _generateId(),
        userId: userId,
        category: category,
        questionsAnswered: questionsAnswered,
        curatedLists: curatedLists,
        popularLists: popularLists,
        eventsHosted: eventsHosted,
        averageEventRating: averageEventRating,
        peerEndorsements: peerEndorsements,
        communityContributions: communityContributions,
        score: score,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error calculating community expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate local expertise (varies by locality)
  /// 
  /// Based on local visits, time in location, continuous residency.
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// - `locality`: Locality (e.g., "Brooklyn", "Manhattan")
  /// - `neighborhood`: Neighborhood (optional)
  /// - `localVisits`: List of local visits
  /// - `firstLocalVisit`: First local visit date
  /// - `continuousResidency`: Continuous residency duration
  /// 
  /// **Returns:**
  /// LocalExpertise with calculated score
  Future<LocalExpertise> calculateLocalExpertise({
    required String userId,
    required String category,
    required String locality,
    String? neighborhood,
    required List<Visit> localVisits,
    required DateTime firstLocalVisit,
    Duration? continuousResidency,
  }) async {
    try {
      _logger.info(
        'Calculating local expertise: user=$userId, category=$category, locality=$locality',
        tag: _logName,
      );

      if (localVisits.isEmpty) {
        return _createEmptyLocalExpertise(userId, category, locality, neighborhood);
      }

      final uniqueLocalLocations =
          localVisits.map((v) => v.locationId).toSet().length;
      final ratings = localVisits
          .where((v) => v.rating != null)
          .map((v) => v.rating!)
          .toList();
      final averageLocalRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      final timeInLocation = DateTime.now().difference(firstLocalVisit);
      final sortedVisits = localVisits.toList()
        ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));
      final lastLocalVisit = sortedVisits.last.checkInTime;

      // Check for Golden Local Expert (25+ years residency)
      final isGoldenLocalExpert = continuousResidency != null &&
          continuousResidency.inDays >= (25 * 365);

      // Calculate score (0.0 to 1.0)
      final score = _calculateLocalScore(
        localVisits: localVisits.length,
        uniqueLocalLocations: uniqueLocalLocations,
        averageLocalRating: averageLocalRating,
        timeInLocation: timeInLocation,
        continuousResidency: continuousResidency,
        isGoldenLocalExpert: isGoldenLocalExpert,
      );

      return LocalExpertise(
        id: _generateId(),
        userId: userId,
        category: category,
        locality: locality,
        neighborhood: neighborhood,
        localVisits: localVisits.length,
        uniqueLocalLocations: uniqueLocalLocations,
        averageLocalRating: averageLocalRating,
        timeInLocation: timeInLocation,
        firstLocalVisit: firstLocalVisit,
        lastLocalVisit: lastLocalVisit,
        continuousResidency: continuousResidency,
        isGoldenLocalExpert: isGoldenLocalExpert,
        score: score,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error calculating local expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  // Score calculation helpers

  double _calculateExplorationScore({
    required int totalVisits,
    required int uniqueLocations,
    required int reviewsGiven,
    required double averageRating,
    required double averageQualityScore,
    required int highQualityVisits,
  }) {
    // Normalize metrics to 0-1 scale
    final visitScore = (totalVisits / 50.0).clamp(0.0, 1.0); // Target: 50 visits
    final locationScore = (uniqueLocations / 20.0).clamp(0.0, 1.0); // Target: 20 locations
    final reviewScore = (reviewsGiven / 30.0).clamp(0.0, 1.0); // Target: 30 reviews
    final ratingScore = averageRating / 5.0; // Normalize 0-5 to 0-1
    final qualityScore = averageQualityScore / 1.5; // Normalize 0-1.5 to 0-1
    final highQualityScore = (highQualityVisits / 10.0).clamp(0.0, 1.0); // Target: 10 high-quality visits

    // Weighted combination
    return (visitScore * 0.25) +
        (locationScore * 0.20) +
        (reviewScore * 0.20) +
        (ratingScore * 0.15) +
        (qualityScore * 0.15) +
        (highQualityScore * 0.05);
  }

  double _calculateCredentialScore({
    required List<EducationCredential> degrees,
    required List<CertificationCredential> certifications,
    required List<PublishedWork> publishedWork,
    required List<Award> awards,
    required int yearsOfExperience,
    required bool isVerified,
  }) {
    double score = 0.0;

    // Degrees (0.3 weight)
    if (degrees.isNotEmpty) {
      score += 0.3;
      if (degrees.any((d) => d.degree.toLowerCase().contains('phd'))) {
        score += 0.1; // Bonus for PhD
      }
    }

    // Certifications (0.25 weight)
    if (certifications.isNotEmpty) {
      score += 0.25;
    }

    // Published work (0.2 weight)
    if (publishedWork.isNotEmpty) {
      score += 0.2;
    }

    // Awards (0.15 weight)
    if (awards.isNotEmpty) {
      score += 0.15;
    }

    // Experience (0.1 weight)
    if (yearsOfExperience >= 5) {
      score += 0.1;
    } else if (yearsOfExperience >= 2) {
      score += 0.05;
    }

    // Verification bonus
    if (isVerified) {
      score += 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateInfluenceScore({
    required int spotsFollowers,
    required int listSaves,
    required int listShares,
    required int listEngagement,
    required int curatedLists,
    required double externalInfluence,
  }) {
    // Logarithmic normalization for followers (prevents skewing)
    final followerScore = (spotsFollowers > 0)
        ? (1.0 - (1.0 / (1.0 + spotsFollowers / 1000.0))).clamp(0.0, 1.0)
        : 0.0;

    // List engagement (normalized)
    final engagementScore = (listEngagement / 1000.0).clamp(0.0, 1.0);

    // Curated lists
    final listScore = (curatedLists / 10.0).clamp(0.0, 1.0);

    // External influence (normalized)
    final externalScore = (externalInfluence / 5.0).clamp(0.0, 1.0);

    // Weighted combination
    return (followerScore * 0.3) +
        (engagementScore * 0.3) +
        (listScore * 0.2) +
        (externalScore * 0.2);
  }

  double _calculateProfessionalScore({
    required List<ProfessionalRole> roles,
    required List<ProofOfWork> proofOfWork,
    required List<PeerEndorsement> peerEndorsements,
    required bool isVerified,
  }) {
    double score = 0.0;

    // Professional roles (0.4 weight)
    if (roles.isNotEmpty) {
      score += 0.4;
      if (roles.any((r) => r.isCurrent)) {
        score += 0.1; // Bonus for current role
      }
    }

    // Proof of work (0.3 weight)
    if (proofOfWork.isNotEmpty) {
      score += 0.3;
    }

    // Peer endorsements (0.2 weight)
    if (peerEndorsements.length >= 5) {
      score += 0.2;
    } else if (peerEndorsements.isNotEmpty) {
      score += 0.1;
    }

    // Verification bonus
    if (isVerified) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateCommunityScore({
    required int questionsAnswered,
    required int curatedLists,
    required int eventsHosted,
    required double averageEventRating,
    required int peerEndorsements,
    required int communityContributions,
  }) {
    // Normalize metrics
    final questionsScore = (questionsAnswered / 50.0).clamp(0.0, 1.0);
    final listsScore = (curatedLists / 10.0).clamp(0.0, 1.0);
    final eventsScore = (eventsHosted / 5.0).clamp(0.0, 1.0);
    final ratingScore = averageEventRating / 5.0;
    final endorsementsScore = (peerEndorsements / 10.0).clamp(0.0, 1.0);
    final contributionsScore = (communityContributions / 20.0).clamp(0.0, 1.0);

    // Weighted combination
    return (questionsScore * 0.2) +
        (listsScore * 0.2) +
        (eventsScore * 0.2) +
        (ratingScore * 0.15) +
        (endorsementsScore * 0.15) +
        (contributionsScore * 0.1);
  }

  double _calculateLocalScore({
    required int localVisits,
    required int uniqueLocalLocations,
    required double averageLocalRating,
    required Duration timeInLocation,
    Duration? continuousResidency,
    required bool isGoldenLocalExpert,
  }) {
    // Normalize metrics
    final visitScore = (localVisits / 30.0).clamp(0.0, 1.0);
    final locationScore = (uniqueLocalLocations / 15.0).clamp(0.0, 1.0);
    final ratingScore = averageLocalRating / 5.0;
    final timeScore = (timeInLocation.inDays / 365.0).clamp(0.0, 1.0); // 1 year = 1.0

    // Golden Local Expert bonus
    final goldenBonus = isGoldenLocalExpert ? 0.2 : 0.0;

    // Weighted combination
    return (visitScore * 0.3) +
        (locationScore * 0.25) +
        (ratingScore * 0.2) +
        (timeScore * 0.25) +
        goldenBonus;
  }

  double _calculateExternalPlatformScore(ExternalPlatformInfluence platform) {
    // Normalize followers logarithmically
    final followerScore = (platform.followers > 0)
        ? (1.0 - (1.0 / (1.0 + platform.followers / 100000.0))).clamp(0.0, 1.0)
        : 0.0;

    // Engagement rate
    final engagementScore = platform.engagementRate;

    // Verification bonus
    final verificationBonus = platform.verified ? 0.1 : 0.0;

    return (followerScore * 0.6) + (engagementScore * 0.3) + verificationBonus;
  }

  // Helper methods

  ExplorationExpertise _createEmptyExplorationExpertise(
    String userId,
    String category,
  ) {
    final now = DateTime.now();
    return ExplorationExpertise(
      id: _generateId(),
      userId: userId,
      category: category,
      totalVisits: 0,
      uniqueLocations: 0,
      repeatVisits: 0,
      reviewsGiven: 0,
      averageRating: 0.0,
      averageQualityScore: 0.0,
      highQualityVisits: 0,
      totalDwellTime: Duration.zero,
      firstVisit: now,
      lastVisit: now,
      score: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  LocalExpertise _createEmptyLocalExpertise(
    String userId,
    String category,
    String locality,
    String? neighborhood,
  ) {
    final now = DateTime.now();
    return LocalExpertise(
      id: _generateId(),
      userId: userId,
      category: category,
      locality: locality,
      neighborhood: neighborhood,
      localVisits: 0,
      uniqueLocalLocations: 0,
      averageLocalRating: 0.0,
      timeInLocation: Duration.zero,
      firstLocalVisit: now,
      lastLocalVisit: now,
      score: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _generateId() {
    return 'expertise-${DateTime.now().millisecondsSinceEpoch}';
  }
}

