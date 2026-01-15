import 'dart:developer' as developer;
import 'package:sembast/sembast.dart';
import 'package:avrai/core/models/list.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/models/user.dart';
import 'package:avrai/data/datasources/local/sembast_database.dart';

class SembastSeeder {
  static Future<void> seedDatabase() async {
    try {
      // Use batch operations for better performance
      final db = await SembastDatabase.database;

      // Batch all operations
      await db.transaction((txn) async {
        await _seedUsersBatch(txn);
        await _seedSpotsBatch(txn);
        await _seedListsBatch(txn);
      });

      developer.log('Database seeded successfully', name: 'SembastSeeder');
    } catch (e) {
      developer.log('Error seeding database: $e', name: 'SembastSeeder');
    }
  }

  static Future<void> _seedUsersBatch(DatabaseClient db) async {
    final store = SembastDatabase.usersStore;

    final now = DateTime.now();
    final demoUser = User(
      id: 'demo-user-1',
      email: 'demo@avrai.app',
      name: 'Demo User',
      displayName: 'Demo User',
      role: UserRole.user,
      createdAt: now,
      updatedAt: now,
      isOnline: true,
    );

    // Add expertiseMap to make demo user an expert in everything
    final userJson = demoUser.toJson();
    final allCategories = [
      'Coffee',
      'Restaurants',
      'Bars',
      'Pastry',
      'Wine',
      'Cocktails',
      'Food',
      'Dining',
      'Retail',
      'Shopping',
      'Hospitality',
      'Service',
      'Art',
      'Music',
      'Outdoor',
      'Fitness',
      'Books',
      'Tech',
      'Wellness',
      'Travel',
      'Parks',
      'Bookstores',
      'Museums',
      'Theaters',
      'Live Music',
      'Sports',
      'Shopping',
      'Fashion',
      'Vintage',
      'Markets',
      'Food Trucks',
      'Bakeries',
      'Ice Cream',
      'Wine Bars',
      'Craft Beer',
      'Vegan/Vegetarian',
      'Pizza',
      'Sushi',
      'BBQ',
      'Mexican',
      'Italian',
      'Thai',
      'Indian',
      'Mediterranean',
      'Korean',
      'Hiking Trails',
      'Beaches',
      'Gardens',
      'Botanical Gardens',
      'Nature Reserves',
      'Camping',
      'Fishing',
      'Kayaking',
      'Biking Trails',
      'Bird Watching',
      'Stargazing',
      'Picnic Spots',
      'Waterfalls',
      'Scenic Views',
    ];

    final expertiseMap = <String, String>{};
    for (final category in allCategories) {
      expertiseMap[category] = 'universal'; // Highest expertise level
    }

    userJson['expertiseMap'] = expertiseMap;

    await store.record(demoUser.id).put(db, userJson);
  }

  static Future<void> _seedSpotsBatch(DatabaseClient db) async {
    final store = SembastDatabase.spotsStore;

    final now = DateTime.now();
    final spots = [
      Spot(
        id: 'spot-1',
        name: 'Central Park',
        description: 'Iconic urban park in Manhattan',
        latitude: 40.7829,
        longitude: -73.9654,
        category: 'Parks',
        rating: 4.8,
        createdBy: 'demo-user-1',
        createdAt: now,
        updatedAt: now,
        address: '123 Central Park West, New York, NY',
        tags: ['park', 'nature', 'recreation'],
      ),
      Spot(
        id: 'spot-2',
        name: 'Brooklyn Bridge Park',
        description: 'Waterfront park with amazing views',
        latitude: 40.7021,
        longitude: -73.9969,
        category: 'Parks',
        rating: 4.6,
        createdBy: 'demo-user-1',
        createdAt: now,
        updatedAt: now,
        address: '334 Furman St, Brooklyn, NY',
        tags: ['park', 'waterfront', 'views'],
      ),
      Spot(
        id: 'spot-3',
        name: 'Chelsea Market',
        description: 'Food hall and shopping destination',
        latitude: 40.7421,
        longitude: -74.0060,
        category: 'Food & Dining',
        rating: 4.4,
        createdBy: 'demo-user-1',
        createdAt: now,
        updatedAt: now,
        address: '820 Washington St, New York, NY',
        tags: ['food', 'shopping', 'market'],
      ),
    ];

    for (final spot in spots) {
      await store.record(spot.id).put(db, spot.toJson());
    }
  }

  static Future<void> _seedListsBatch(DatabaseClient db) async {
    final store = SembastDatabase.listsStore;

    final now = DateTime.now();
    final lists = [
      SpotList(
        id: 'list-1',
        title: 'Best Parks in NYC',
        description: 'My favorite parks to visit',
        spots: [],
        createdAt: now,
        updatedAt: now,
        category: 'Parks',
        isPublic: true,
        spotIds: ['spot-1', 'spot-2'],
        respectCount: 5,
      ),
      SpotList(
        id: 'list-2',
        title: 'Food Adventures',
        description: 'Amazing places to eat',
        spots: [],
        createdAt: now,
        updatedAt: now,
        category: 'Food & Dining',
        isPublic: true,
        spotIds: ['spot-3'],
        respectCount: 3,
      ),
    ];

    for (final list in lists) {
      await store.record(list.id).put(db, list.toJson());
    }
  }
}
