import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/expertise_matching_service.dart';

/// Mentorship Service
/// Manages mentorship relationships between experts
class MentorshipService {
  static const String _logName = 'MentorshipService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final ExpertiseMatchingService _matchingService = ExpertiseMatchingService();

  /// Request mentorship
  /// Mentee requests mentorship from a mentor
  Future<MentorshipRelationship> requestMentorship({
    required UnifiedUser mentee,
    required UnifiedUser mentor,
    required String category,
    String? message,
  }) async {
    try {
      _logger.info('Mentorship request: ${mentee.id} -> ${mentor.id}', tag: _logName);

      // Verify mentor is higher level
      final menteeLevel = mentee.getExpertiseLevel(category);
      final mentorLevel = mentor.getExpertiseLevel(category);

      if (menteeLevel == null || mentorLevel == null) {
        throw Exception('Both users must have expertise in $category');
      }

      if (!mentorLevel.isHigherThan(menteeLevel)) {
        throw Exception('Mentor must have higher expertise level');
      }

      // Check if relationship already exists
      final existing = await _getMentorshipRelationship(mentee.id, mentor.id, category);
      if (existing != null) {
        throw Exception('Mentorship relationship already exists');
      }

      final relationship = MentorshipRelationship(
        id: _generateRelationshipId(),
        mentee: mentee,
        mentor: mentor,
        category: category,
        status: MentorshipStatus.pending,
        message: message,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _saveRelationship(relationship);
      _logger.info('Mentorship request created: ${relationship.id}', tag: _logName);
      return relationship;
    } catch (e) {
      _logger.error('Error requesting mentorship', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Accept mentorship request
  Future<void> acceptMentorship(MentorshipRelationship relationship) async {
    try {
      final updated = relationship.copyWith(
        status: MentorshipStatus.active,
        updatedAt: DateTime.now(),
      );

      await _saveRelationship(updated);
      _logger.info('Mentorship accepted: ${relationship.id}', tag: _logName);
    } catch (e) {
      _logger.error('Error accepting mentorship', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Reject mentorship request
  Future<void> rejectMentorship(MentorshipRelationship relationship) async {
    try {
      final updated = relationship.copyWith(
        status: MentorshipStatus.rejected,
        updatedAt: DateTime.now(),
      );

      await _saveRelationship(updated);
      _logger.info('Mentorship rejected: ${relationship.id}', tag: _logName);
    } catch (e) {
      _logger.error('Error rejecting mentorship', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get mentorship relationships for a user
  Future<List<MentorshipRelationship>> getMentorships(UnifiedUser user) async {
    try {
      final allRelationships = await _getAllRelationships();
      return allRelationships
          .where((r) => r.mentee.id == user.id || r.mentor.id == user.id)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      _logger.error('Error getting mentorships', error: e, tag: _logName);
      return [];
    }
  }

  /// Get mentors for a user
  Future<List<MentorshipRelationship>> getMentors(UnifiedUser user) async {
    final relationships = await getMentorships(user);
    return relationships
        .where((r) => r.mentee.id == user.id && r.status == MentorshipStatus.active)
        .toList();
  }

  /// Get mentees for a user
  Future<List<MentorshipRelationship>> getMentees(UnifiedUser user) async {
    final relationships = await getMentorships(user);
    return relationships
        .where((r) => r.mentor.id == user.id && r.status == MentorshipStatus.active)
        .toList();
  }

  /// Find potential mentors
  Future<List<MentorSuggestion>> findPotentialMentors(
    UnifiedUser mentee,
    String category,
  ) async {
    try {
      final matches = await _matchingService.findMentors(mentee, category);
      
      return matches.map((match) {
        return MentorSuggestion(
          mentor: match.user,
          category: category,
          matchScore: match.matchScore,
          reason: match.matchReason,
        );
      }).toList();
    } catch (e) {
      _logger.error('Error finding potential mentors', error: e, tag: _logName);
      return [];
    }
  }

  /// Complete mentorship
  Future<void> completeMentorship(MentorshipRelationship relationship) async {
    try {
      final updated = relationship.copyWith(
        status: MentorshipStatus.completed,
        updatedAt: DateTime.now(),
      );

      await _saveRelationship(updated);
      _logger.info('Mentorship completed: ${relationship.id}', tag: _logName);
    } catch (e) {
      _logger.error('Error completing mentorship', error: e, tag: _logName);
      rethrow;
    }
  }

  // Private helper methods

  String _generateRelationshipId() {
    return 'mentorship_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveRelationship(MentorshipRelationship relationship) async {
    // In production, save to database
  }

  Future<MentorshipRelationship?> _getMentorshipRelationship(
    String menteeId,
    String mentorId,
    String category,
  ) async {
    final allRelationships = await _getAllRelationships();
    return allRelationships.firstWhere(
      (r) => r.mentee.id == menteeId &&
            r.mentor.id == mentorId &&
            r.category == category,
      orElse: () => throw StateError('Not found'),
    );
  }

  Future<List<MentorshipRelationship>> _getAllRelationships() async {
    // In production, query database
    return [];
  }
}

/// Mentorship Relationship
class MentorshipRelationship {
  final String id;
  final UnifiedUser mentee;
  final UnifiedUser mentor;
  final String category;
  final MentorshipStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MentorshipRelationship({
    required this.id,
    required this.mentee,
    required this.mentor,
    required this.category,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  MentorshipRelationship copyWith({
    String? id,
    UnifiedUser? mentee,
    UnifiedUser? mentor,
    String? category,
    MentorshipStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MentorshipRelationship(
      id: id ?? this.id,
      mentee: mentee ?? this.mentee,
      mentor: mentor ?? this.mentor,
      category: category ?? this.category,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Mentorship Status
enum MentorshipStatus {
  pending,
  active,
  completed,
  rejected,
}

/// Mentor Suggestion
class MentorSuggestion {
  final UnifiedUser mentor;
  final String category;
  final double matchScore;
  final String reason;

  const MentorSuggestion({
    required this.mentor,
    required this.category,
    required this.matchScore,
    required this.reason,
  });
}

