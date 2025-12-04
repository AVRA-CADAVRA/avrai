import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

class BaselineListsPage extends StatefulWidget {
  final List<String> baselineLists;
  final Function(List<String>) onBaselineListsChanged;
  final String? userName;
  final Map<String, List<String>>? userPreferences;
  final List<String>? userFavoritePlaces;

  const BaselineListsPage({
    super.key,
    required this.baselineLists,
    required this.onBaselineListsChanged,
    this.userName,
    this.userPreferences,
    this.userFavoritePlaces,
  });

  @override
  State<BaselineListsPage> createState() => _BaselineListsPageState();
}

class _BaselineListsPageState extends State<BaselineListsPage>
    with TickerProviderStateMixin {
  List<String> _generatedLists = [];
  bool _isLoading = true;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    // Show immediate suggestions and let background agent handle AI optimization
    _startLoading();
  }

  void _startLoading() async {
    _loadingController.repeat();

    // Quick loading for immediate feedback
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _loadingController.stop();
      _generateQuickSuggestions();
    }
  }

  void _generateQuickSuggestions() {
    final userName = widget.userName ?? 'User';
    final homebase = widget.userPreferences?['homebase'] as String?;
    final favoritePlaces = widget.userFavoritePlaces ?? [];
    final preferences = widget.userPreferences ?? {};

    // Generate quick, smart suggestions based on available data
    final suggestions = <String>[];
    
    // Add location-aware suggestions if homebase is available
    if (homebase != null && homebase.isNotEmpty) {
      suggestions.addAll([
        'Hidden Gems in $homebase',
        'Local Favorites in $homebase',
        'Weekend Adventures in $homebase',
      ]);
    } else {
      suggestions.addAll([
        'Hidden Gems',
        'Local Favorites',
        'Weekend Adventures',
      ]);
    }

    // Add preference-based suggestions
    if (preferences.containsKey('Food & Drink')) {
      suggestions.add('Coffee & Tea Spots');
      suggestions.add('Best Restaurants');
    }
    
    if (preferences.containsKey('Activities')) {
      suggestions.add('Entertainment Hotspots');
      suggestions.add('Activity Centers');
    }
    
    if (preferences.containsKey('Outdoor & Nature')) {
      suggestions.add('Outdoor Adventures');
      suggestions.add('Nature Escapes');
    }

    // Add AI-enhanced suggestions (background agent will optimize these)
    suggestions.addAll([
      'AI-Curated Local Gems',
      'Community-Recommended Spots',
      'Trending in Your Area',
    ]);

    // Add personality-based suggestions
    if (favoritePlaces.isNotEmpty) {
      suggestions.add('Places Like Your Favorites');
    }

    // Remove duplicates and limit to top suggestions
    final uniqueSuggestions = suggestions.toSet().take(8).toList();

    setState(() {
      _generatedLists = uniqueSuggestions;
    });
    widget.onBaselineListsChanged(_generatedLists);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) ...[
            // Loading state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AI Processing Animation
                    AnimatedBuilder(
                      animation: _loadingAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: AppColors.white,
                            size: 40,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Creating your personalized lists...',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We\'re setting up smart lists based on your preferences. The background AI will continue optimizing these for you.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.grey600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can start exploring immediately!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey500,
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Progress dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Results state
            Text(
              'Your Smart Lists',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ve created these lists based on your preferences. The background AI will continue optimizing them for you.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 24),

            // Lists intro
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Lists!',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lists help you organize and discover amazing spots. The background AI will continuously improve your suggestions.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Generated lists
            Expanded(
              child: ListView.builder(
                itemCount: _generatedLists.length,
                itemBuilder: (context, index) {
                  final listName = _generatedLists[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          _getListIcon(listName),
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        listName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _getListDescription(listName),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      tileColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getListIcon(String listName) {
    final lowerName = listName.toLowerCase();
    
    if (lowerName.contains('coffee') || lowerName.contains('cafe')) {
      return Icons.coffee;
    } else if (lowerName.contains('bar') || lowerName.contains('pub') || lowerName.contains('beer')) {
      return Icons.local_bar;
    } else if (lowerName.contains('restaurant') || lowerName.contains('dining') || lowerName.contains('food')) {
      return Icons.restaurant;
    } else if (lowerName.contains('music') || lowerName.contains('jazz')) {
      return Icons.music_note;
    } else if (lowerName.contains('theater') || lowerName.contains('cultural')) {
      return Icons.theater_comedy;
    } else if (lowerName.contains('fitness') || lowerName.contains('gym') || lowerName.contains('sports')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('shopping') || lowerName.contains('boutique')) {
      return Icons.shopping_bag;
    } else if (lowerName.contains('bookstore') || lowerName.contains('reading')) {
      return Icons.book;
    } else if (lowerName.contains('hiking') || lowerName.contains('outdoor') || lowerName.contains('adventure')) {
      return Icons.hiking;
    } else if (lowerName.contains('beach') || lowerName.contains('waterfront')) {
      return Icons.beach_access;
    } else if (lowerName.contains('park') || lowerName.contains('green')) {
      return Icons.park;
    } else if (lowerName.contains('ai') || lowerName.contains('curated')) {
      return Icons.psychology;
    } else if (lowerName.contains('community') || lowerName.contains('trending')) {
      return Icons.people;
    } else if (lowerName.contains('hidden') || lowerName.contains('secret')) {
      return Icons.explore;
    } else if (lowerName.contains('local') || lowerName.contains('favorite')) {
      return Icons.favorite;
    } else if (lowerName.contains('chill')) {
      return Icons.coffee;
    } else if (lowerName.contains('fun')) {
      return Icons.sports_soccer;
    } else if (lowerName.contains('recommended')) {
      return Icons.star;
    } else {
      return Icons.list;
    }
  }

  String _getListDescription(String listName) {
    final lowerName = listName.toLowerCase();
    
    if (lowerName.contains('coffee') || lowerName.contains('cafe')) {
      return 'Perfect coffee spots and cozy cafes';
    } else if (lowerName.contains('bar') || lowerName.contains('pub') || lowerName.contains('beer')) {
      return 'Best bars and craft beer destinations';
    } else if (lowerName.contains('restaurant') || lowerName.contains('dining')) {
      return 'Top-rated restaurants and dining experiences';
    } else if (lowerName.contains('music') || lowerName.contains('jazz')) {
      return 'Live music venues and entertainment spots';
    } else if (lowerName.contains('theater') || lowerName.contains('cultural')) {
      return 'Cultural venues and performance spaces';
    } else if (lowerName.contains('fitness') || lowerName.contains('gym')) {
      return 'Fitness centers and sports facilities';
    } else if (lowerName.contains('shopping') || lowerName.contains('boutique')) {
      return 'Shopping districts and unique boutiques';
    } else if (lowerName.contains('bookstore') || lowerName.contains('reading')) {
      return 'Independent bookstores and reading spots';
    } else if (lowerName.contains('hiking') || lowerName.contains('outdoor')) {
      return 'Hiking trails and outdoor adventures';
    } else if (lowerName.contains('beach') || lowerName.contains('waterfront')) {
      return 'Beach spots and waterfront locations';
    } else if (lowerName.contains('park') || lowerName.contains('green')) {
      return 'Parks and green spaces';
    } else if (lowerName.contains('ai') || lowerName.contains('curated')) {
      return 'AI-curated local gems and hidden treasures';
    } else if (lowerName.contains('community') || lowerName.contains('trending')) {
      return 'Community-recommended and trending spots';
    } else if (lowerName.contains('hidden') || lowerName.contains('secret')) {
      return 'Hidden gems and insider secrets';
    } else if (lowerName.contains('local') || lowerName.contains('favorite')) {
      return 'Local favorites and must-visit spots';
    } else if (lowerName.contains('chill')) {
      return 'Relaxing and chill spots';
    } else if (lowerName.contains('fun')) {
      return 'Fun and exciting places';
    } else if (lowerName.contains('recommended')) {
      return 'Highly recommended spots';
    } else {
      return 'Personalized for you';
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }
}
