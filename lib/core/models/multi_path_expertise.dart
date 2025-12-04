import 'package:equatable/equatable.dart';

/// Multi-Path Expertise Models
/// 
/// Represents expertise achieved through different paths.
/// Each path has a different weight in the overall expertise calculation.
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

/// Exploration Expertise (40% weight)
/// Expertise gained through visiting places and exploring
class ExplorationExpertise extends Equatable {
  final String id;
  final String userId;
  final String category;
  
  /// Visit-based metrics
  final int totalVisits;
  final int uniqueLocations;
  final int repeatVisits;
  final int reviewsGiven;
  final double averageRating;
  
  /// Quality metrics
  final double averageQualityScore;
  final int highQualityVisits; // Visits with quality score >= 1.0
  
  /// Time-based metrics
  final Duration totalDwellTime;
  final DateTime firstVisit;
  final DateTime lastVisit;
  
  /// Calculated score (0.0 to 1.0)
  final double score;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const ExplorationExpertise({
    required this.id,
    required this.userId,
    required this.category,
    required this.totalVisits,
    required this.uniqueLocations,
    required this.repeatVisits,
    required this.reviewsGiven,
    required this.averageRating,
    required this.averageQualityScore,
    required this.highQualityVisits,
    required this.totalDwellTime,
    required this.firstVisit,
    required this.lastVisit,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'totalVisits': totalVisits,
      'uniqueLocations': uniqueLocations,
      'repeatVisits': repeatVisits,
      'reviewsGiven': reviewsGiven,
      'averageRating': averageRating,
      'averageQualityScore': averageQualityScore,
      'highQualityVisits': highQualityVisits,
      'totalDwellTime': totalDwellTime.inMinutes,
      'firstVisit': firstVisit.toIso8601String(),
      'lastVisit': lastVisit.toIso8601String(),
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ExplorationExpertise.fromJson(Map<String, dynamic> json) {
    return ExplorationExpertise(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      totalVisits: json['totalVisits'] as int,
      uniqueLocations: json['uniqueLocations'] as int,
      repeatVisits: json['repeatVisits'] as int,
      reviewsGiven: json['reviewsGiven'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      averageQualityScore: (json['averageQualityScore'] as num).toDouble(),
      highQualityVisits: json['highQualityVisits'] as int,
      totalDwellTime: Duration(minutes: json['totalDwellTime'] as int? ?? 0),
      firstVisit: DateTime.parse(json['firstVisit'] as String),
      lastVisit: DateTime.parse(json['lastVisit'] as String),
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        totalVisits,
        uniqueLocations,
        repeatVisits,
        reviewsGiven,
        averageRating,
        averageQualityScore,
        highQualityVisits,
        totalDwellTime,
        firstVisit,
        lastVisit,
        score,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Credential Expertise (25% weight)
/// Expertise gained through formal education and certifications
class CredentialExpertise extends Equatable {
  final String id;
  final String userId;
  final String category;
  
  /// Education
  final List<EducationCredential> degrees;
  
  /// Certifications
  final List<CertificationCredential> certifications;
  
  /// Industry experience
  final int yearsOfExperience;
  
  /// Published work
  final List<PublishedWork> publishedWork;
  
  /// Awards and recognition
  final List<Award> awards;
  
  /// Verification status
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  
  /// Calculated score (0.0 to 1.0)
  final double score;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const CredentialExpertise({
    required this.id,
    required this.userId,
    required this.category,
    this.degrees = const [],
    this.certifications = const [],
    this.yearsOfExperience = 0,
    this.publishedWork = const [],
    this.awards = const [],
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'degrees': degrees.map((d) => d.toJson()).toList(),
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'yearsOfExperience': yearsOfExperience,
      'publishedWork': publishedWork.map((p) => p.toJson()).toList(),
      'awards': awards.map((a) => a.toJson()).toList(),
      'isVerified': isVerified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory CredentialExpertise.fromJson(Map<String, dynamic> json) {
    return CredentialExpertise(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      degrees: (json['degrees'] as List?)
          ?.map((d) => EducationCredential.fromJson(d as Map<String, dynamic>))
          .toList() ??
          [],
      certifications: (json['certifications'] as List?)
          ?.map((c) =>
              CertificationCredential.fromJson(c as Map<String, dynamic>))
          .toList() ??
          [],
      yearsOfExperience: json['yearsOfExperience'] as int? ?? 0,
      publishedWork: (json['publishedWork'] as List?)
          ?.map((p) => PublishedWork.fromJson(p as Map<String, dynamic>))
          .toList() ??
          [],
      awards: (json['awards'] as List?)
          ?.map((a) => Award.fromJson(a as Map<String, dynamic>))
          .toList() ??
          [],
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      verifiedBy: json['verifiedBy'] as String?,
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        degrees,
        certifications,
        yearsOfExperience,
        publishedWork,
        awards,
        isVerified,
        verifiedAt,
        verifiedBy,
        score,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Influence Expertise (20% weight)
/// Expertise gained through social influence and platform engagement
class InfluenceExpertise extends Equatable {
  final String id;
  final String userId;
  final String category;
  
  /// SPOTS platform influence
  final int spotsFollowers; // Followers interested in category
  final int listSaves; // List saves
  final int listShares; // List shares
  final int listEngagement; // Total engagement on lists
  
  /// External platform influence
  final List<ExternalPlatformInfluence> externalPlatforms;
  
  /// List curation
  final int curatedLists;
  final int popularLists; // Lists with high engagement
  
  /// Calculated score (0.0 to 1.0) - normalized logarithmically
  final double score;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const InfluenceExpertise({
    required this.id,
    required this.userId,
    required this.category,
    this.spotsFollowers = 0,
    this.listSaves = 0,
    this.listShares = 0,
    this.listEngagement = 0,
    this.externalPlatforms = const [],
    this.curatedLists = 0,
    this.popularLists = 0,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'spotsFollowers': spotsFollowers,
      'listSaves': listSaves,
      'listShares': listShares,
      'listEngagement': listEngagement,
      'externalPlatforms':
          externalPlatforms.map((e) => e.toJson()).toList(),
      'curatedLists': curatedLists,
      'popularLists': popularLists,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory InfluenceExpertise.fromJson(Map<String, dynamic> json) {
    return InfluenceExpertise(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      spotsFollowers: json['spotsFollowers'] as int? ?? 0,
      listSaves: json['listSaves'] as int? ?? 0,
      listShares: json['listShares'] as int? ?? 0,
      listEngagement: json['listEngagement'] as int? ?? 0,
      externalPlatforms: (json['externalPlatforms'] as List?)
          ?.map((e) => ExternalPlatformInfluence.fromJson(
              e as Map<String, dynamic>))
          .toList() ??
          [],
      curatedLists: json['curatedLists'] as int? ?? 0,
      popularLists: json['popularLists'] as int? ?? 0,
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        spotsFollowers,
        listSaves,
        listShares,
        listEngagement,
        externalPlatforms,
        curatedLists,
        popularLists,
        score,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Professional Expertise (25% weight)
/// Expertise gained through professional work and proof of work
class ProfessionalExpertise extends Equatable {
  final String id;
  final String userId;
  final String category;
  
  /// Professional roles
  final List<ProfessionalRole> roles;
  
  /// Proof of work
  final List<ProofOfWork> proofOfWork;
  
  /// Peer endorsements
  final List<PeerEndorsement> peerEndorsements;
  
  /// Verification status
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  
  /// Calculated score (0.0 to 1.0)
  final double score;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const ProfessionalExpertise({
    required this.id,
    required this.userId,
    required this.category,
    this.roles = const [],
    this.proofOfWork = const [],
    this.peerEndorsements = const [],
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'roles': roles.map((r) => r.toJson()).toList(),
      'proofOfWork': proofOfWork.map((p) => p.toJson()).toList(),
      'peerEndorsements':
          peerEndorsements.map((e) => e.toJson()).toList(),
      'isVerified': isVerified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ProfessionalExpertise.fromJson(Map<String, dynamic> json) {
    return ProfessionalExpertise(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      roles: (json['roles'] as List?)
          ?.map((r) => ProfessionalRole.fromJson(r as Map<String, dynamic>))
          .toList() ??
          [],
      proofOfWork: (json['proofOfWork'] as List?)
          ?.map((p) => ProofOfWork.fromJson(p as Map<String, dynamic>))
          .toList() ??
          [],
      peerEndorsements: (json['peerEndorsements'] as List?)
          ?.map((e) => PeerEndorsement.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      verifiedBy: json['verifiedBy'] as String?,
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        roles,
        proofOfWork,
        peerEndorsements,
        isVerified,
        verifiedAt,
        verifiedBy,
        score,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Community Expertise (15% weight)
/// Expertise gained through community contributions
class CommunityExpertise extends Equatable {
  final String id;
  final String userId;
  final String category;
  
  /// Questions answered
  final int questionsAnswered;
  
  /// List curation
  final int curatedLists;
  final int popularLists; // Lists with high engagement
  
  /// Events hosted
  final int eventsHosted;
  final double averageEventRating;
  
  /// Peer endorsements
  final int peerEndorsements;
  
  /// Community contributions
  final int communityContributions; // Guides, tips, etc.
  
  /// Calculated score (0.0 to 1.0)
  final double score;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const CommunityExpertise({
    required this.id,
    required this.userId,
    required this.category,
    this.questionsAnswered = 0,
    this.curatedLists = 0,
    this.popularLists = 0,
    this.eventsHosted = 0,
    this.averageEventRating = 0.0,
    this.peerEndorsements = 0,
    this.communityContributions = 0,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'questionsAnswered': questionsAnswered,
      'curatedLists': curatedLists,
      'popularLists': popularLists,
      'eventsHosted': eventsHosted,
      'averageEventRating': averageEventRating,
      'peerEndorsements': peerEndorsements,
      'communityContributions': communityContributions,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory CommunityExpertise.fromJson(Map<String, dynamic> json) {
    return CommunityExpertise(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      questionsAnswered: json['questionsAnswered'] as int? ?? 0,
      curatedLists: json['curatedLists'] as int? ?? 0,
      popularLists: json['popularLists'] as int? ?? 0,
      eventsHosted: json['eventsHosted'] as int? ?? 0,
      averageEventRating:
          (json['averageEventRating'] as num?)?.toDouble() ?? 0.0,
      peerEndorsements: json['peerEndorsements'] as int? ?? 0,
      communityContributions: json['communityContributions'] as int? ?? 0,
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        questionsAnswered,
        curatedLists,
        popularLists,
        eventsHosted,
        averageEventRating,
        peerEndorsements,
        communityContributions,
        score,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Local Expertise (varies by locality)
/// Expertise gained through deep local knowledge
class LocalExpertise extends Equatable {
  final String id;
  final String userId;
  final String category;
  
  /// Geographic scope
  final String locality; // e.g., "Brooklyn", "Manhattan", "Austin"
  final String? neighborhood; // e.g., "Williamsburg", "Park Slope"
  
  /// Local visit metrics
  final int localVisits;
  final int uniqueLocalLocations;
  final double averageLocalRating;
  
  /// Time in location
  final Duration timeInLocation;
  final DateTime firstLocalVisit;
  final DateTime lastLocalVisit;
  
  /// Continuous residency (for Golden Local Expert)
  final Duration? continuousResidency;
  final bool isGoldenLocalExpert; // 25+ years
  
  /// Calculated score (0.0 to 1.0)
  final double score;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const LocalExpertise({
    required this.id,
    required this.userId,
    required this.category,
    required this.locality,
    this.neighborhood,
    required this.localVisits,
    required this.uniqueLocalLocations,
    required this.averageLocalRating,
    required this.timeInLocation,
    required this.firstLocalVisit,
    required this.lastLocalVisit,
    this.continuousResidency,
    this.isGoldenLocalExpert = false,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'locality': locality,
      'neighborhood': neighborhood,
      'localVisits': localVisits,
      'uniqueLocalLocations': uniqueLocalLocations,
      'averageLocalRating': averageLocalRating,
      'timeInLocation': timeInLocation.inDays,
      'firstLocalVisit': firstLocalVisit.toIso8601String(),
      'lastLocalVisit': lastLocalVisit.toIso8601String(),
      'continuousResidency': continuousResidency?.inDays,
      'isGoldenLocalExpert': isGoldenLocalExpert,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory LocalExpertise.fromJson(Map<String, dynamic> json) {
    return LocalExpertise(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      locality: json['locality'] as String,
      neighborhood: json['neighborhood'] as String?,
      localVisits: json['localVisits'] as int,
      uniqueLocalLocations: json['uniqueLocalLocations'] as int,
      averageLocalRating: (json['averageLocalRating'] as num).toDouble(),
      timeInLocation: Duration(days: json['timeInLocation'] as int? ?? 0),
      firstLocalVisit: DateTime.parse(json['firstLocalVisit'] as String),
      lastLocalVisit: DateTime.parse(json['lastLocalVisit'] as String),
      continuousResidency: json['continuousResidency'] != null
          ? Duration(days: json['continuousResidency'] as int)
          : null,
      isGoldenLocalExpert: json['isGoldenLocalExpert'] as bool? ?? false,
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        locality,
        neighborhood,
        localVisits,
        uniqueLocalLocations,
        averageLocalRating,
        timeInLocation,
        firstLocalVisit,
        lastLocalVisit,
        continuousResidency,
        isGoldenLocalExpert,
        score,
        createdAt,
        updatedAt,
        metadata,
      ];
}

// Supporting models for multi-path expertise

/// Education Credential
class EducationCredential extends Equatable {
  final String degree; // e.g., "BA", "MS", "PhD"
  final String field; // e.g., "Culinary Arts", "Food Science"
  final String institution;
  final int year;
  final bool isVerified;
  final String? verificationUrl;

  const EducationCredential({
    required this.degree,
    required this.field,
    required this.institution,
    required this.year,
    this.isVerified = false,
    this.verificationUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'field': field,
      'institution': institution,
      'year': year,
      'isVerified': isVerified,
      'verificationUrl': verificationUrl,
    };
  }

  factory EducationCredential.fromJson(Map<String, dynamic> json) {
    return EducationCredential(
      degree: json['degree'] as String,
      field: json['field'] as String,
      institution: json['institution'] as String,
      year: json['year'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationUrl: json['verificationUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        degree,
        field,
        institution,
        year,
        isVerified,
        verificationUrl,
      ];
}

/// Certification Credential
class CertificationCredential extends Equatable {
  final String name; // e.g., "Q Grader", "Sommelier"
  final String issuer;
  final DateTime issuedDate;
  final DateTime? expirationDate;
  final bool isVerified;
  final String? verificationUrl;

  const CertificationCredential({
    required this.name,
    required this.issuer,
    required this.issuedDate,
    this.expirationDate,
    this.isVerified = false,
    this.verificationUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'issuedDate': issuedDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'isVerified': isVerified,
      'verificationUrl': verificationUrl,
    };
  }

  factory CertificationCredential.fromJson(Map<String, dynamic> json) {
    return CertificationCredential(
      name: json['name'] as String,
      issuer: json['issuer'] as String,
      issuedDate: DateTime.parse(json['issuedDate'] as String),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationUrl: json['verificationUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        name,
        issuer,
        issuedDate,
        expirationDate,
        isVerified,
        verificationUrl,
      ];
}

/// Published Work
class PublishedWork extends Equatable {
  final String title;
  final String type; // "article", "book", "research_paper"
  final String? publication;
  final DateTime publishedDate;
  final String? url;
  final bool isVerified;

  const PublishedWork({
    required this.title,
    required this.type,
    this.publication,
    required this.publishedDate,
    this.url,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'publication': publication,
      'publishedDate': publishedDate.toIso8601String(),
      'url': url,
      'isVerified': isVerified,
    };
  }

  factory PublishedWork.fromJson(Map<String, dynamic> json) {
    return PublishedWork(
      title: json['title'] as String,
      type: json['type'] as String,
      publication: json['publication'] as String?,
      publishedDate: DateTime.parse(json['publishedDate'] as String),
      url: json['url'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        title,
        type,
        publication,
        publishedDate,
        url,
        isVerified,
      ];
}

/// Award
class Award extends Equatable {
  final String name;
  final String issuer;
  final DateTime awardedDate;
  final String? description;
  final bool isVerified;
  final String? verificationUrl;

  const Award({
    required this.name,
    required this.issuer,
    required this.awardedDate,
    this.description,
    this.isVerified = false,
    this.verificationUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'awardedDate': awardedDate.toIso8601String(),
      'description': description,
      'isVerified': isVerified,
      'verificationUrl': verificationUrl,
    };
  }

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
      name: json['name'] as String,
      issuer: json['issuer'] as String,
      awardedDate: DateTime.parse(json['awardedDate'] as String),
      description: json['description'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationUrl: json['verificationUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        name,
        issuer,
        awardedDate,
        description,
        isVerified,
        verificationUrl,
      ];
}

/// External Platform Influence
class ExternalPlatformInfluence extends Equatable {
  final String platform; // "instagram", "tiktok", "youtube", "yelp", "blog"
  final String handle;
  final int followers;
  final String category;
  final bool verified;
  final double engagementRate;
  final List<String> proofUrls;

  const ExternalPlatformInfluence({
    required this.platform,
    required this.handle,
    required this.followers,
    required this.category,
    this.verified = false,
    this.engagementRate = 0.0,
    this.proofUrls = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'handle': handle,
      'followers': followers,
      'category': category,
      'verified': verified,
      'engagementRate': engagementRate,
      'proofUrls': proofUrls,
    };
  }

  factory ExternalPlatformInfluence.fromJson(Map<String, dynamic> json) {
    return ExternalPlatformInfluence(
      platform: json['platform'] as String,
      handle: json['handle'] as String,
      followers: json['followers'] as int,
      category: json['category'] as String,
      verified: json['verified'] as bool? ?? false,
      engagementRate: (json['engagementRate'] as num?)?.toDouble() ?? 0.0,
      proofUrls: List<String>.from(json['proofUrls'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        platform,
        handle,
        followers,
        category,
        verified,
        engagementRate,
        proofUrls,
      ];
}

/// Professional Role
class ProfessionalRole extends Equatable {
  final String role; // e.g., "Chef", "Writer", "Professor"
  final String? title; // e.g., "Head Chef", "Food Critic"
  final String? employer;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final bool isVerified;
  final String? verificationUrl;

  const ProfessionalRole({
    required this.role,
    this.title,
    this.employer,
    required this.startDate,
    this.endDate,
    this.isCurrent = true,
    this.isVerified = false,
    this.verificationUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'title': title,
      'employer': employer,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
      'isVerified': isVerified,
      'verificationUrl': verificationUrl,
    };
  }

  factory ProfessionalRole.fromJson(Map<String, dynamic> json) {
    return ProfessionalRole(
      role: json['role'] as String,
      title: json['title'] as String?,
      employer: json['employer'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isCurrent: json['isCurrent'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationUrl: json['verificationUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        role,
        title,
        employer,
        startDate,
        endDate,
        isCurrent,
        isVerified,
        verificationUrl,
      ];
}

/// Proof of Work
class ProofOfWork extends Equatable {
  final String type; // "linkedin", "employer_letter", "license", "portfolio"
  final String? url;
  final String? description;
  final bool isVerified;
  final DateTime? verifiedAt;

  const ProofOfWork({
    required this.type,
    this.url,
    this.description,
    this.isVerified = false,
    this.verifiedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'description': description,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  factory ProofOfWork.fromJson(Map<String, dynamic> json) {
    return ProofOfWork(
      type: json['type'] as String,
      url: json['url'] as String?,
      description: json['description'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [type, url, description, isVerified, verifiedAt];
}

/// Peer Endorsement
class PeerEndorsement extends Equatable {
  final String endorserId; // User ID of endorser
  final String? endorserName;
  final String category;
  final String? comment;
  final DateTime endorsedAt;
  final bool isVerified;

  const PeerEndorsement({
    required this.endorserId,
    this.endorserName,
    required this.category,
    this.comment,
    required this.endorsedAt,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'endorserId': endorserId,
      'endorserName': endorserName,
      'category': category,
      'comment': comment,
      'endorsedAt': endorsedAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  factory PeerEndorsement.fromJson(Map<String, dynamic> json) {
    return PeerEndorsement(
      endorserId: json['endorserId'] as String,
      endorserName: json['endorserName'] as String?,
      category: json['category'] as String,
      comment: json['comment'] as String?,
      endorsedAt: DateTime.parse(json['endorsedAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        endorserId,
        endorserName,
        category,
        comment,
        endorsedAt,
        isVerified,
      ];
}

