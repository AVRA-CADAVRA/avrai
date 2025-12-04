import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

class FriendsRespectPage extends StatefulWidget {
  final List<String> respectedLists;
  final Function(List<String>) onRespectedListsChanged;

  const FriendsRespectPage({
    super.key,
    required this.respectedLists,
    required this.onRespectedListsChanged,
  });

  @override
  State<FriendsRespectPage> createState() => _FriendsRespectPageState();
}

class _FriendsRespectPageState extends State<FriendsRespectPage> {
  List<String> _selectedLists = [];
  Map<String, int> _respectCounts = {};

  // Enhanced mock data with user profiles
  final List<Map<String, dynamic>> _localPublicLists = [
    {
      'name': 'Brooklyn Coffee Crawl',
      'creator': 'Sarah M.',
      'spots': 12,
      'respects': 127,
      'category': 'Food & Drink',
      'location': 'Brooklyn, NY',
      'userProfile': {
        'expertise': 'coffee expert',
        'locations': ['Brooklyn', 'Zambia'],
        'hostedEventsCount': 14,
        'differentSpotsCount': 3,
      },
    },
    {
      'name': 'Hidden Gems in Williamsburg',
      'creator': 'Mike T.',
      'spots': 8,
      'respects': 89,
      'category': 'Culture & Arts',
      'location': 'Brooklyn, NY',
      'userProfile': {
        'expertise': 'street art enthusiast',
        'locations': ['Williamsburg', 'Bushwick'],
        'hostedEventsCount': 8,
        'differentSpotsCount': 5,
      },
    },
    {
      'name': 'Best Sunset Spots',
      'creator': 'Emma L.',
      'spots': 15,
      'respects': 203,
      'category': 'Outdoor & Nature',
      'location': 'Manhattan, NY',
      'userProfile': {
        'expertise': 'photography lover',
        'locations': ['Manhattan', 'Brooklyn'],
        'hostedEventsCount': 22,
        'differentSpotsCount': 7,
      },
    },
    {
      'name': 'Vintage Shopping Guide',
      'creator': 'Alex K.',
      'spots': 6,
      'respects': 156,
      'category': 'Activities',
      'location': 'Brooklyn, NY',
      'userProfile': {
        'expertise': 'vintage curator',
        'locations': ['Brooklyn', 'Manhattan'],
        'hostedEventsCount': 12,
        'differentSpotsCount': 4,
      },
    },
    {
      'name': 'Cozy Reading Nooks',
      'creator': 'David R.',
      'spots': 10,
      'respects': 94,
      'category': 'Culture & Arts',
      'location': 'Manhattan, NY',
      'userProfile': {
        'expertise': 'bookworm',
        'locations': ['Manhattan'],
        'hostedEventsCount': 6,
        'differentSpotsCount': 2,
      },
    },
    {
      'name': 'Late Night Food Spots',
      'creator': 'Lisa P.',
      'spots': 9,
      'respects': 178,
      'category': 'Food & Drink',
      'location': 'Brooklyn, NY',
      'userProfile': {
        'expertise': 'foodie',
        'locations': ['Brooklyn', 'Manhattan'],
        'hostedEventsCount': 18,
        'differentSpotsCount': 6,
      },
    },
    {
      'name': 'Street Art Tour',
      'creator': 'Carlos M.',
      'spots': 14,
      'respects': 245,
      'category': 'Culture & Arts',
      'location': 'Brooklyn, NY',
      'userProfile': {
        'expertise': 'street art guide',
        'locations': ['Brooklyn', 'Manhattan'],
        'hostedEventsCount': 31,
        'differentSpotsCount': 8,
      },
    },
    {
      'name': 'Dog-Friendly Parks',
      'creator': 'Jenny W.',
      'spots': 7,
      'respects': 112,
      'category': 'Outdoor & Nature',
      'location': 'Brooklyn, NY',
      'userProfile': {
        'expertise': 'dog lover',
        'locations': ['Brooklyn', 'Manhattan'],
        'hostedEventsCount': 9,
        'differentSpotsCount': 3,
      },
    },
    {
      'name': 'Jazz & Blues Venues',
      'creator': 'Marcus J.',
      'spots': 11,
      'respects': 167,
      'category': 'Entertainment',
      'location': 'Manhattan, NY',
      'userProfile': {
        'expertise': 'jazz musician',
        'locations': ['Manhattan', 'Brooklyn'],
        'hostedEventsCount': 25,
        'differentSpotsCount': 4,
      },
    },
    {
      'name': 'Weekend Brunch Spots',
      'creator': 'Rachel S.',
      'spots': 13,
      'respects': 189,
      'category': 'Food & Drink',
      'location': 'Brooklyn, NY',
      'userProfile': {
        'expertise': 'brunch connoisseur',
        'locations': ['Brooklyn', 'Manhattan', 'Queens'],
        'hostedEventsCount': 16,
        'differentSpotsCount': 5,
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedLists = List.from(widget.respectedLists);

    // Initialize respect counts from the mock data
    for (var list in _localPublicLists) {
      _respectCounts[list['name'] as String] = list['respects'] as int;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Connect & Discover',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Respect lists created by people in your local area. These lists will appear in your spots page after onboarding.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 24),

          // Local lists section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Local Public Lists',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (_selectedLists.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedLists.clear();
                          });
                          widget.onRespectedListsChanged(_selectedLists);
                        },
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lists created by people in your area',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
                const SizedBox(height: 16),

                // Lists
                Expanded(
                  child: ListView.builder(
                    itemCount: _localPublicLists.length,
                    itemBuilder: (context, index) {
                      final list = _localPublicLists[index];
                      final listName = list['name'] as String;
                      final isSelected = _selectedLists.contains(listName);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            // Main list tile - for viewing details
                            ListTile(
                              onTap: () => _showListDetails(list),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  _getCategoryIcon(list['category'] as String),
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                listName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  // User profile info
                                  _buildUserProfileInfo(list),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 12,
                                        color: AppColors.grey600,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          list['location'] as String,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${list['spots']} spots',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Respect button
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedLists.remove(listName);
                                        } else {
                                          _selectedLists.add(listName);
                                        }
                                      });
                                      widget.onRespectedListsChanged(
                                          _selectedLists);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : AppColors.grey200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.add,
                                        size: 14,
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.grey700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // View details arrow
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: AppColors.grey400,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileInfo(Map<String, dynamic> list) {
    final userProfile = list['userProfile'] as Map<String, dynamic>;
    final creatorName = list['creator'] as String;
    final expertise = userProfile['expertise'] as String;
    final locations = userProfile['locations'] as List<String>;
    final hostedEventsCount = userProfile['hostedEventsCount'] as int;
    final differentSpotsCount = userProfile['differentSpotsCount'] as int;

      return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$expertise in ${locations.join(', ')}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 1),
          Text(
            'Hosted $hostedEventsCount events at $differentSpotsCount spots',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.grey600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _showListDetails(Map<String, dynamic> list) {
    // Mock spots data for the list
    List<Map<String, dynamic>> spots =
        _getMockSpotsForList(list['name'] as String);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
          builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      _getCategoryIcon(list['category'] as String),
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list['name'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'by ${list['creator']} • ${list['spots']} spots • ${list['respects']} respects',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Spots list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: spots.length,
                itemBuilder: (context, index) {
                  final spot = spots[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          _getSpotIcon(spot['category'] as String),
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        spot['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        spot['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.grey400,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMockSpotsForList(String listName) {
    // Mock spots data based on list name - matching the exact spot counts
    switch (listName) {
      case 'Brooklyn Coffee Crawl': // 12 spots
        return [
          {
            'name': 'Blue Bottle Coffee',
            'description': 'Artisanal coffee with a minimalist vibe',
            'category': 'Food & Drink'
          },
          {
            'name': 'Devoción',
            'description': 'Colombian coffee in a beautiful space',
            'category': 'Food & Drink'
          },
          {
            'name': 'Sey Coffee',
            'description': 'Light-roasted specialty coffee',
            'category': 'Food & Drink'
          },
          {
            'name': 'Variety Coffee',
            'description': 'Cozy neighborhood coffee shop',
            'category': 'Food & Drink'
          },
          {
            'name': 'Partners Coffee',
            'description': 'Local roaster with great pastries',
            'category': 'Food & Drink'
          },
          {
            'name': 'Toby\'s Estate',
            'description': 'Australian-style coffee shop',
            'category': 'Food & Drink'
          },
          {
            'name': 'Brooklyn Roasting Company',
            'description': 'Industrial-chic coffee spot',
            'category': 'Food & Drink'
          },
          {
            'name': 'Cafe Grumpy',
            'description': 'Brooklyn-born coffee chain',
            'category': 'Food & Drink'
          },
          {
            'name': 'Stumptown Coffee',
            'description': 'Portland-style coffee experience',
            'category': 'Food & Drink'
          },
          {
            'name': 'Joe Coffee',
            'description': 'Classic NYC coffee shop',
            'category': 'Food & Drink'
          },
          {
            'name': 'La Colombe',
            'description': 'Philadelphia-based coffee roaster',
            'category': 'Food & Drink'
          },
          {
            'name': 'Gregorys Coffee',
            'description': 'Modern coffee shop with great vibes',
            'category': 'Food & Drink'
          },
        ];
      case 'Hidden Gems in Williamsburg': // 8 spots
        return [
          {
            'name': 'Domino Park',
            'description': 'Waterfront park with great views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Brooklyn Flea',
            'description': 'Vintage and artisanal market',
            'category': 'Activities'
          },
          {
            'name': 'McCarren Park',
            'description': 'Large park with sports facilities',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Bedford Avenue',
            'description': 'Main shopping and dining street',
            'category': 'Activities'
          },
          {
            'name': 'East River State Park',
            'description': 'Hidden waterfront gem',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Bushwick Inlet Park',
            'description': 'Peaceful green space',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'N 6th Street',
            'description': 'Trendy shopping district',
            'category': 'Activities'
          },
          {
            'name': 'Berry Street',
            'description': 'Local favorite dining street',
            'category': 'Food & Drink'
          },
        ];
      case 'Best Sunset Spots': // 15 spots
        return [
          {
            'name': 'Brooklyn Bridge Park',
            'description': 'Iconic NYC skyline views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'DUMBO Waterfront',
            'description': 'Perfect sunset photography spot',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'High Line Park',
            'description': 'Elevated park with city views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Central Park',
            'description': 'Classic NYC sunset location',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Battery Park',
            'description': 'Harbor views and Statue of Liberty',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Riverside Park',
            'description': 'Hudson River sunset views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Fort Tryon Park',
            'description': 'Elevated views of the Hudson',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Prospect Park',
            'description': 'Brooklyn\'s answer to Central Park',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Brooklyn Heights Promenade',
            'description': 'Famous skyline vista',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Governors Island',
            'description': 'Island escape with harbor views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Gantry Plaza State Park',
            'description': 'Queens waterfront views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Astoria Park',
            'description': 'East River sunset spot',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Rockaway Beach',
            'description': 'Ocean sunset views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Pelham Bay Park',
            'description': 'Bronx waterfront views',
            'category': 'Outdoor & Nature'
          },
          {
            'name': 'Van Cortlandt Park',
            'description': 'Northern Bronx green space',
            'category': 'Outdoor & Nature'
          },
        ];
      default:
        return [
          {
            'name': 'Sample Spot 1',
            'description': 'A great place to visit',
            'category': 'Activities'
          },
          {
            'name': 'Sample Spot 2',
            'description': 'Another amazing location',
            'category': 'Food & Drink'
          },
          {
            'name': 'Sample Spot 3',
            'description': 'Worth checking out',
            'category': 'Culture & Arts'
          },
        ];
    }
  }

  IconData _getSpotIcon(String category) {
    switch (category) {
      case 'Food & Drink':
        return Icons.restaurant;
      case 'Activities':
        return Icons.sports_soccer;
      case 'Outdoor & Nature':
        return Icons.nature;
      case 'Culture & Arts':
        return Icons.museum;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.place;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
        return Icons.restaurant;
      case 'culture & arts':
        return Icons.palette;
      case 'outdoor & nature':
        return Icons.nature;
      case 'activities':
        return Icons.sports_esports;
      case 'entertainment':
        return Icons.music_note;
      default:
        return Icons.place;
    }
  }
}
