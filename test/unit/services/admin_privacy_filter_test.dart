import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/admin_privacy_filter.dart';
import '../../helpers/platform_channel_helper.dart';

/// Admin Privacy Filter Tests
/// Tests privacy filtering for admin access
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  // Removed: Property assignment tests
  // Admin privacy filter tests focus on business logic (privacy filtering rules), not property assignment

  group('AdminPrivacyFilter', () {
    group('filterPersonalData', () {
      test(
          'should filter out personal data keys, handle case-insensitive key matching, or handle empty map',
          () {
        // Test business logic: basic personal data filtering
        final data1 = {
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '123-456-7890',
          'user_id': 'user-123',
          'ai_signature': 'ai-sig-123',
        };
        final filtered1 = AdminPrivacyFilter.filterPersonalData(data1);
        expect(filtered1.containsKey('name'), isFalse);
        expect(filtered1.containsKey('email'), isFalse);
        expect(filtered1.containsKey('phone'), isFalse);
        expect(filtered1.containsKey('user_id'), isTrue);
        expect(filtered1.containsKey('ai_signature'), isTrue);

        final data2 = {
          'NAME': 'John Doe',
          'Email': 'john@example.com',
          'PHONE': '123-456-7890',
          'User_ID': 'user-123',
        };
        final filtered2 = AdminPrivacyFilter.filterPersonalData(data2);
        expect(filtered2.containsKey('NAME'), isFalse);
        expect(filtered2.containsKey('Email'), isFalse);
        expect(filtered2.containsKey('PHONE'), isFalse);
        expect(filtered2.containsKey('User_ID'), isTrue);

        final data3 = <String, dynamic>{};
        final filtered3 = AdminPrivacyFilter.filterPersonalData(data3);
        expect(filtered3, isEmpty);
      });

      test(
          'should allow AI-related data, allow location data (vibe indicator), or preserve allowed keys',
          () {
        // Test business logic: allowed data preservation
        final data1 = {
          'ai_signature': 'sig-123',
          'ai_connections': ['conn-1', 'conn-2'],
          'ai_status': 'active',
        };
        final filtered1 = AdminPrivacyFilter.filterPersonalData(data1);
        expect(filtered1.containsKey('ai_signature'), isTrue);
        expect(filtered1.containsKey('ai_connections'), isTrue);
        expect(filtered1.containsKey('ai_status'), isTrue);

        final data2 = {
          'current_location': 'San Francisco',
          'visited_locations': ['SF', 'NYC'],
          'location_history': ['NYC'],
          'vibe_location': 'SF',
        };
        final filtered2 = AdminPrivacyFilter.filterPersonalData(data2);
        expect(filtered2.containsKey('current_location'), isTrue);
        expect(filtered2.containsKey('visited_locations'), isTrue);
        expect(filtered2.containsKey('location_history'), isTrue);
        expect(filtered2.containsKey('vibe_location'), isTrue);

        final data3 = <String, dynamic>{
          'user_id': 'user-123',
          'ai_signature': 'sig-123',
          'ai_connections': ['conn1'],
          'connection_id': 'conn-123',
          'ai_status': 'active',
          'ai_activity': 'learning',
          'current_location': 'SF',
          'visited_locations': ['SF'],
          'location_history': ['NYC'],
          'vibe_location': 'SF',
          'spot_locations': ['spot1'],
        };
        final filtered3 = AdminPrivacyFilter.filterPersonalData(data3);
        expect(filtered3.containsKey('user_id'), isTrue);
        expect(filtered3.containsKey('ai_signature'), isTrue);
        expect(filtered3.containsKey('ai_connections'), isTrue);
        expect(filtered3.containsKey('connection_id'), isTrue);
        expect(filtered3.containsKey('ai_status'), isTrue);
        expect(filtered3.containsKey('ai_activity'), isTrue);
        expect(filtered3.containsKey('current_location'), isTrue);
        expect(filtered3.containsKey('visited_locations'), isTrue);
        expect(filtered3.containsKey('location_history'), isTrue);
        expect(filtered3.containsKey('vibe_location'), isTrue);
        expect(filtered3.containsKey('spot_locations'), isTrue);
      });

      test('should filter out home address or filter contact information', () {
        // Test business logic: address and contact filtering
        final data1 = {
          'home_address': '123 Main St',
          'homeaddress': '456 Oak Ave',
          'residential_address': '789 Pine Rd',
          'personal_address': '321 Elm St',
          'visited_locations': ['SF', 'NYC'],
        };
        final filtered1 = AdminPrivacyFilter.filterPersonalData(data1);
        expect(filtered1.containsKey('home_address'), isFalse);
        expect(filtered1.containsKey('homeaddress'), isFalse);
        expect(filtered1.containsKey('residential_address'), isFalse);
        expect(filtered1.containsKey('personal_address'), isFalse);
        expect(filtered1.containsKey('visited_locations'), isTrue);

        final data2 = {
          'contact': {
            'phone': '123-456-7890',
            'email': 'test@example.com',
          },
          'ai_status': 'active',
        };
        final filtered2 = AdminPrivacyFilter.filterPersonalData(data2);
        expect(filtered2.containsKey('contact'), isFalse);
        expect(filtered2.containsKey('ai_status'), isTrue);
      });

      test(
          'should filter nested maps recursively, filter displayname and username',
          () {
        // Test business logic: recursive filtering and username/displayname filtering
        final data1 = {
          'user_data': {
            'name': 'John Doe',
            'email': 'john@example.com',
            'ai_signature': 'sig-123',
          },
          'profile': {
            'displayname': 'John',
            'username': 'johndoe',
          },
        };
        final filtered1 = AdminPrivacyFilter.filterPersonalData(data1);
        if (filtered1.containsKey('user_data')) {
          final userData = filtered1['user_data'] as Map<String, dynamic>;
          expect(userData.containsKey('name'), isFalse);
          expect(userData.containsKey('email'), isFalse);
          expect(userData.containsKey('ai_signature'), isTrue);
        }
        expect(filtered1.containsKey('profile'), isFalse);

        final data2 = {
          'displayname': 'John Doe',
          'username': 'johndoe',
          'user_id': 'user-123',
        };
        final filtered2 = AdminPrivacyFilter.filterPersonalData(data2);
        expect(filtered2.containsKey('displayname'), isFalse);
        expect(filtered2.containsKey('username'), isFalse);
        expect(filtered2.containsKey('user_id'), isTrue);
      });
    });
  });
}
