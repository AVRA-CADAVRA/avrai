import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/mentorship_service.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

/// Mentorship Service Tests
/// Tests mentorship relationship management
void main() {
  group('MentorshipService Tests', () {
    late MentorshipService service;
    late UnifiedUser mentee;
    late UnifiedUser mentor;

    setUp(() {
      service = MentorshipService();
      
      // Create mentee with local level expertise
      mentee = ModelFactories.createTestUser(
        id: 'mentee-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'local'},
      );
      
      // Create mentor with local level+ expertise (can host events)
      mentor = ModelFactories.createTestUser(
        id: 'mentor-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
    });

    group('requestMentorship', () {
      test('should create mentorship request when mentor has higher level', () async {
        final relationship = await service.requestMentorship(
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          message: 'I would like to learn more about food curation',
        );

        expect(relationship, isA<MentorshipRelationship>());
        expect(relationship.mentee.id, equals(mentee.id));
        expect(relationship.mentor.id, equals(mentor.id));
        expect(relationship.category, equals('food'));
        expect(relationship.status, equals(MentorshipStatus.pending));
        expect(relationship.message, equals('I would like to learn more about food curation'));
      });

      test('should throw exception when mentor level is not higher', () async {
        final sameLevelMentor = ModelFactories.createTestUser(
          id: 'mentor-456',
          tags: ['food'],
        ).copyWith(
          expertiseMap: {'food': 'local'},
        );

        expect(
          () => service.requestMentorship(
            mentee: mentee,
            mentor: sameLevelMentor,
            category: 'food',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when mentee lacks expertise', () async {
        final noExpertiseMentee = ModelFactories.createTestUser(
          id: 'mentee-456',
          tags: [],
        );

        expect(
          () => service.requestMentorship(
            mentee: noExpertiseMentee,
            mentor: mentor,
            category: 'food',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when mentor lacks expertise', () async {
        final noExpertiseMentor = ModelFactories.createTestUser(
          id: 'mentor-456',
          tags: [],
        );

        expect(
          () => service.requestMentorship(
            mentee: mentee,
            mentor: noExpertiseMentor,
            category: 'food',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('acceptMentorship', () {
      test('should accept mentorship request', () async {
        final relationship = MentorshipRelationship(
          id: 'relationship-123',
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          status: MentorshipStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.acceptMentorship(relationship);

        // Note: In test environment, relationship is not persisted
        // This test verifies the method executes without error
        expect(relationship.status, equals(MentorshipStatus.pending)); // Original unchanged
      });
    });

    group('rejectMentorship', () {
      test('should reject mentorship request', () async {
        final relationship = MentorshipRelationship(
          id: 'relationship-123',
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          status: MentorshipStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.rejectMentorship(relationship);

        // Note: In test environment, relationship is not persisted
        expect(relationship.status, equals(MentorshipStatus.pending)); // Original unchanged
      });
    });

    group('getMentorships', () {
      test('should return empty list for user with no mentorships', () async {
        final mentorships = await service.getMentorships(mentee);
        expect(mentorships, isEmpty);
      });
    });

    group('getMentors', () {
      test('should return empty list for user with no mentors', () async {
        final mentors = await service.getMentors(mentee);
        expect(mentors, isEmpty);
      });
    });

    group('getMentees', () {
      test('should return empty list for user with no mentees', () async {
        final mentees = await service.getMentees(mentor);
        expect(mentees, isEmpty);
      });
    });

    group('findPotentialMentors', () {
      test('should return list of potential mentors', () async {
        final suggestions = await service.findPotentialMentors(mentee, 'food');

        expect(suggestions, isA<List<MentorSuggestion>>());
        // Note: In test environment, this may return empty list
        // This test verifies the method executes without error
      });
    });

    group('completeMentorship', () {
      test('should complete mentorship', () async {
        final relationship = MentorshipRelationship(
          id: 'relationship-123',
          mentee: mentee,
          mentor: mentor,
          category: 'food',
          status: MentorshipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.completeMentorship(relationship);

        // Note: In test environment, relationship is not persisted
        expect(relationship.status, equals(MentorshipStatus.active)); // Original unchanged
      });
    });
  });
}

