import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/logger.dart';

/// Expertise Recognition Service
/// OUR_GUTS.md: Recognition, not competition
/// Manages community recognition and appreciation
class ExpertiseRecognitionService {
  static const String _logName = 'ExpertiseRecognitionService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Recognize an expert
  /// Community members can recognize experts for their contributions
  Future<void> recognizeExpert({
    required UnifiedUser expert,
    required UnifiedUser recognizer,
    required String reason,
    required RecognitionType type,
  }) async {
    try {
      _logger.info('Recognizing expert: ${expert.id}', tag: _logName);

      // Verify recognizer is not recognizing themselves
      if (expert.id == recognizer.id) {
        throw Exception('Cannot recognize yourself');
      }

      final recognition = ExpertRecognition(
        id: _generateRecognitionId(),
        expert: expert,
        recognizer: recognizer,
        reason: reason,
        type: type,
        createdAt: DateTime.now(),
      );

      await _saveRecognition(recognition);
      _logger.info('Expert recognized: ${expert.id}', tag: _logName);
    } catch (e) {
      _logger.error('Error recognizing expert', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get recognitions for an expert
  Future<List<ExpertRecognition>> getRecognitionsForExpert(UnifiedUser expert) async {
    try {
      final allRecognitions = await _getAllRecognitions();
      return allRecognitions
          .where((r) => r.expert.id == expert.id)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting recognitions', error: e, tag: _logName);
      return [];
    }
  }

  /// Get featured experts
  /// Experts with high recognition
  Future<List<FeaturedExpert>> getFeaturedExperts({
    String? category,
    int maxResults = 10,
  }) async {
    try {
      final allRecognitions = await _getAllRecognitions();
      
      // Group by expert
      final expertRecognitions = <String, List<ExpertRecognition>>{};
      for (final recognition in allRecognitions) {
        expertRecognitions.putIfAbsent(recognition.expert.id, () => []).add(recognition);
      }

      // Calculate recognition scores
      final featured = <FeaturedExpert>[];
      for (final entry in expertRecognitions.entries) {
        final expert = entry.value.first.expert;
        
        // Filter by category if specified
        if (category != null && !expert.hasExpertiseIn(category)) {
          continue;
        }

        final recognitionCount = entry.value.length;
        final recentCount = entry.value
            .where((r) => r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30))))
            .length;

        featured.add(FeaturedExpert(
          expert: expert,
          recognitionCount: recognitionCount,
          recentRecognitionCount: recentCount,
          recognitionScore: _calculateRecognitionScore(entry.value),
        ));
      }

      // Sort by recognition score
      featured.sort((a, b) => b.recognitionScore.compareTo(a.recognitionScore));

      return featured.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error getting featured experts', error: e, tag: _logName);
      return [];
    }
  }

  /// Get expert spotlight
  /// Weekly/monthly featured expert
  Future<ExpertSpotlight?> getExpertSpotlight({String? category}) async {
    try {
      final featured = await getFeaturedExperts(category: category, maxResults: 1);
      if (featured.isEmpty) return null;

      final expert = featured.first;
      final recognitions = await getRecognitionsForExpert(expert.expert);

      return ExpertSpotlight(
        expert: expert.expert,
        recognitionCount: expert.recognitionCount,
        recentRecognitionCount: expert.recentRecognitionCount,
        topRecognitions: recognitions.take(3).toList(),
        spotlightReason: _generateSpotlightReason(expert, recognitions),
        featuredAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error getting expert spotlight', error: e, tag: _logName);
      return null;
    }
  }

  /// Get community appreciation
  /// Show appreciation for expert contributions
  Future<List<CommunityAppreciation>> getCommunityAppreciation(UnifiedUser expert) async {
    try {
      final recognitions = await getRecognitionsForExpert(expert);
      
      return recognitions.map((recognition) {
        return CommunityAppreciation(
          from: recognition.recognizer,
          reason: recognition.reason,
          type: recognition.type,
          createdAt: recognition.createdAt,
        );
      }).toList();
    } catch (e) {
      _logger.error('Error getting community appreciation', error: e, tag: _logName);
      return [];
    }
  }

  // Private helper methods

  double _calculateRecognitionScore(List<ExpertRecognition> recognitions) {
    double score = 0.0;

    for (final recognition in recognitions) {
      // Base score by type
      switch (recognition.type) {
        case RecognitionType.helpful:
          score += 1.0;
          break;
        case RecognitionType.inspiring:
          score += 1.5;
          break;
        case RecognitionType.exceptional:
          score += 2.0;
          break;
      }

      // Recency bonus
      final daysAgo = DateTime.now().difference(recognition.createdAt).inDays;
      if (daysAgo < 7) {
        score += 0.5;
      } else if (daysAgo < 30) {
        score += 0.2;
      }
    }

    return score;
  }

  String _generateSpotlightReason(FeaturedExpert expert, List<ExpertRecognition> recognitions) {
    if (recognitions.isEmpty) {
      return 'Recognized for exceptional contributions';
    }

    final topReason = recognitions.first.reason;
    return 'Featured for: $topReason';
  }

  String _generateRecognitionId() {
    return 'recognition_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveRecognition(ExpertRecognition recognition) async {
    // In production, save to database
  }

  Future<List<ExpertRecognition>> _getAllRecognitions() async {
    // In production, query database
    return [];
  }
}

/// Expert Recognition
class ExpertRecognition {
  final String id;
  final UnifiedUser expert;
  final UnifiedUser recognizer;
  final String reason;
  final RecognitionType type;
  final DateTime createdAt;

  const ExpertRecognition({
    required this.id,
    required this.expert,
    required this.recognizer,
    required this.reason,
    required this.type,
    required this.createdAt,
  });
}

/// Recognition Type
enum RecognitionType {
  helpful,      // Helpful contributions
  inspiring,    // Inspiring others
  exceptional,  // Exceptional expertise
}

/// Featured Expert
class FeaturedExpert {
  final UnifiedUser expert;
  final int recognitionCount;
  final int recentRecognitionCount;
  final double recognitionScore;

  const FeaturedExpert({
    required this.expert,
    required this.recognitionCount,
    required this.recentRecognitionCount,
    required this.recognitionScore,
  });
}

/// Expert Spotlight
class ExpertSpotlight {
  final UnifiedUser expert;
  final int recognitionCount;
  final int recentRecognitionCount;
  final List<ExpertRecognition> topRecognitions;
  final String spotlightReason;
  final DateTime featuredAt;

  const ExpertSpotlight({
    required this.expert,
    required this.recognitionCount,
    required this.recentRecognitionCount,
    required this.topRecognitions,
    required this.spotlightReason,
    required this.featuredAt,
  });
}

/// Community Appreciation
class CommunityAppreciation {
  final UnifiedUser from;
  final String reason;
  final RecognitionType type;
  final DateTime createdAt;

  const CommunityAppreciation({
    required this.from,
    required this.reason,
    required this.type,
    required this.createdAt,
  });
}

