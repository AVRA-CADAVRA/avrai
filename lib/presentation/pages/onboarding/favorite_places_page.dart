import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

class FavoritePlacesPage extends StatefulWidget {
  final List<String> favoritePlaces;
  final Function(List<String>) onPlacesChanged;
  final String? userHomebase; // Add user's homebase for smart suggestions
  final VoidCallback? onDismissSnackBars; // Callback to dismiss SnackBars

  const FavoritePlacesPage({
    super.key,
    required this.favoritePlaces,
    required this.onPlacesChanged,
    this.userHomebase,
    this.onDismissSnackBars,
  });

  @override
  State<FavoritePlacesPage> createState() => _FavoritePlacesPageState();
}

class _FavoritePlacesPageState extends State<FavoritePlacesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedPlaces = [];
  List<String> _suggestions = [];
  List<String> _allPlaces = [];
  String? _currentRegion;
  String? _currentCity;

  // State for auto-expanding categories during search
  Set<String> _expandedRegions = {};
  Map<String, Set<String>> _expandedCities = {};

  // Method to dismiss any active SnackBars
  void dismissSnackBars() {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  // Vibe-based categorization with progressive drill-down
  final Map<String, Map<String, List<String>>> _vibeCategories = {
    'New York Area': {
      'Brooklyn': [
        'Brooklyn',
        'Park Slope',
        'Williamsburg',
        'Bushwick',
        'Crown Heights',
        'Greenpoint',
        'DUMBO',
        'Prospect Heights',
        'Carroll Gardens'
      ],
      'Manhattan': [
        'Manhattan',
        'East Village',
        'West Village',
        'SoHo',
        'Lower East Side',
        'Chelsea',
        'Upper West Side',
        'Harlem',
        'Washington Heights'
      ],
      'Queens': [
        'Queens',
        'Astoria',
        'Long Island City',
        'Forest Hills',
        'Jackson Heights'
      ],
      'The Bronx': ['The Bronx', 'Riverdale', 'Mott Haven', 'Pelham Bay'],
      'Staten Island': ['Staten Island', 'St. George', 'Tottenville'],
    },
    'Los Angeles Area': {
      'Los Angeles': [
        'Los Angeles',
        'Venice Beach',
        'Marina del Rey',
        'Playa del Rey'
      ],
      'Silver Lake': ['Silver Lake', 'Echo Park', 'Los Feliz'],
      'Westside': ['Westside', 'Santa Monica', 'Brentwood', 'Westwood'],
      'Downtown': ['Downtown LA', 'Arts District', 'Little Tokyo', 'Chinatown'],
      'Hollywood': ['Hollywood', 'West Hollywood', 'Beverly Hills'],
    },
    'San Francisco Area': {
      'San Francisco': [
        'San Francisco',
        'Mission District',
        'Valencia Corridor',
        'Dolores Park'
      ],
      'North Beach': ['North Beach', 'Fisherman\'s Wharf', 'Telegraph Hill'],
      'Marina': ['Marina District', 'Cow Hollow', 'Pacific Heights'],
      'Haight-Ashbury': ['Haight-Ashbury', 'Cole Valley', 'Upper Haight'],
      'SOMA': ['SOMA', 'South Beach', 'Rincon Hill'],
    },
    'Chicago Area': {
      'Chicago': ['Chicago', 'Wicker Park', 'Lincoln Park', 'Lakeview'],
      'West Loop': ['West Loop', 'Fulton Market', 'Ukrainian Village'],
      'South Side': ['South Side', 'Hyde Park', 'Pilsen'],
      'North Side': ['North Side', 'Andersonville', 'Edgewater'],
    },
    'Miami Area': {
      'Miami': ['Miami', 'South Beach', 'Wynwood', 'Brickell'],
      'Miami Beach': ['Miami Beach', 'North Beach', 'Mid-Beach'],
      'Coral Gables': ['Coral Gables', 'Coconut Grove'],
    },
    'Austin Area': {
      'Austin': ['Austin', 'East Austin', 'South Congress', 'Downtown'],
      'West Austin': ['West Austin', 'Clarksville', 'Tarrytown'],
    },
    'Seattle Area': {
      'Seattle': ['Seattle', 'Capitol Hill', 'Fremont', 'Ballard'],
      'Downtown': ['Downtown Seattle', 'Belltown', 'Pioneer Square'],
    },
    'Portland Area': {
      'Portland': ['Portland', 'Pearl District', 'Alberta Arts', 'Hawthorne'],
      'East Portland': ['East Portland', 'Division', 'Woodstock'],
    },
    'Denver Area': {
      'Denver': ['Denver', 'RiNo', 'LoDo', 'Highland'],
      'Boulder': ['Boulder', 'Pearl Street', 'University Hill'],
    },
    'Nashville Area': {
      'Nashville': ['Nashville', 'East Nashville', 'Germantown', 'The Gulch'],
      'Downtown': ['Downtown Nashville', 'Broadway', 'SoBro'],
    },
    'Europe': {
      'Paris': [
        'Le Marais',
        'Montmartre',
        'Saint-Germain',
        'Canal Saint-Martin'
      ],
      'London': ['Shoreditch', 'Camden', 'Notting Hill', 'Soho'],
      'Barcelona': ['Gothic Quarter', 'El Born', 'Gracia', 'Barceloneta'],
      'Amsterdam': ['Jordaan', 'De Pijp', 'Oud-West', 'Centrum'],
    },
    'Asia': {
      'Tokyo': ['Shibuya', 'Harajuku', 'Shinjuku', 'Ginza'],
      'Seoul': ['Hongdae', 'Gangnam', 'Itaewon', 'Myeongdong'],
      'Bangkok': ['Sukhumvit', 'Silom', 'Chinatown', 'Thonglor'],
      'Singapore': ['Tiong Bahru', 'Kampong Glam', 'Chinatown', 'Little India'],
    },
  };

  // Smart suggestions based on user's homebase
  List<String> _getSmartSuggestions() {
    if (widget.userHomebase == null) {
      return _getDefaultSuggestions();
    }

    // Find vibe-similar places based on user's homebase
    List<String> suggestions = [];

    // Extract city/area from homebase
    String homebase = widget.userHomebase!.toLowerCase();

    if (homebase.contains('brooklyn') ||
        homebase.contains('manhattan') ||
        homebase.contains('nyc')) {
      suggestions.addAll(_vibeCategories['New York Area']!
          .values
          .expand((neighborhoods) => neighborhoods));
    } else if (homebase.contains('los angeles') || homebase.contains('la')) {
      suggestions.addAll(_vibeCategories['Los Angeles Area']!
          .values
          .expand((neighborhoods) => neighborhoods));
    } else if (homebase.contains('san francisco') || homebase.contains('sf')) {
      suggestions.addAll(_vibeCategories['San Francisco Area']!
          .values
          .expand((neighborhoods) => neighborhoods));
    } else {
      // Default to a mix of popular places
      suggestions.addAll(_getDefaultSuggestions());
    }

    return suggestions;
  }

  List<String> _getDefaultSuggestions() {
    return [
      'Park Slope, Brooklyn',
      'Williamsburg, Brooklyn',
      'East Village, Manhattan',
      'Mission District, San Francisco',
      'Venice Beach, Los Angeles',
      'Shoreditch, London',
      'Le Marais, Paris',
      'Shibuya, Tokyo',
      'Hongdae, Seoul',
      'Tiong Bahru, Singapore'
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedPlaces = List.from(widget.favoritePlaces);
    _suggestions = _getSmartSuggestions();
    _allPlaces = _vibeCategories.values
        .expand((cities) => cities.values)
        .expand((neighborhoods) => neighborhoods)
        .toList();
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
            'What matches your vibe?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select places that match your aesthetic and lifestyle preferences.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 24),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for places that match your vibe...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions = _getSmartSuggestions();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 24),

          // Selected places - Smaller and adaptive
          if (_selectedPlaces.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Selected (${_selectedPlaces.length}):',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPlaces.clear();
                    });
                    widget.onPlacesChanged(_selectedPlaces);
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 60),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedPlaces.length,
                itemBuilder: (context, index) {
                  final place = _selectedPlaces[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        place,
                        style: const TextStyle(fontSize: 11),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _removePlace(place),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      deleteIconColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Search results and vibe categories
          Expanded(
            child: Column(
              children: [
                // Show search results if there's a search query
                if (_searchController.text.isNotEmpty) ...[
                  Text(
                    'Search Results',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: _buildSearchResults(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Always show vibe categories
                Expanded(
                  child: _buildVibeCategories(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeCategories() {
    return ListView.builder(
      itemCount: _vibeCategories.length,
      itemBuilder: (context, index) {
        final region = _vibeCategories.keys.elementAt(index);
        final cities = _vibeCategories[region]!;
        final isRegionExpanded = _expandedRegions.contains(region);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            initiallyExpanded: isRegionExpanded,
            title: Row(
              children: [
                Icon(
                  _getRegionIcon(region),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    region,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_getSelectedCountForRegion(region) > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getSelectedCountForRegion(region)}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            children: cities.entries.map((cityEntry) {
              final city = cityEntry.key;
              final neighborhoods = cityEntry.value;
              final isCityExpanded =
                  _expandedCities[region]?.contains(city) ?? false;

              return ExpansionTile(
                initiallyExpanded: isCityExpanded,
                title: Text(city),
                children: neighborhoods.map((neighborhood) {
                  final fullName = '$neighborhood, $city';
                  final isSelected = _selectedPlaces.contains(fullName);

                  return ListTile(
                    title: Text(neighborhood),
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.location_on_outlined,
                      color:
                          isSelected ? AppTheme.primaryColor : AppColors.grey600,
                      size: 20,
                    ),
                    onTap: () {
                      if (isSelected) {
                        _removePlace(fullName);
                      } else {
                        _addPlace(fullName);
                      }
                    },
                    tileColor: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : null,
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        final isSelected = _selectedPlaces.contains(place);

        return ListTile(
          leading: Icon(
            isSelected ? Icons.check_circle : Icons.location_on_outlined,
            color: isSelected ? AppTheme.primaryColor : AppColors.grey600,
          ),
          title: Text(place),
          trailing: isSelected
              ? Icon(
                  Icons.remove_circle_outline,
                  color: AppTheme.errorColor,
                )
              : null,
          onTap: () {
            if (isSelected) {
              _removePlace(place);
            } else {
              _addPlace(place);
            }
          },
          tileColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  IconData _getRegionIcon(String region) {
    switch (region) {
      case 'New York Area':
        return Icons.location_city;
      case 'Los Angeles Area':
        return Icons.wb_sunny;
      case 'San Francisco Area':
        return Icons.location_city;
      case 'Europe':
        return Icons.flight;
      case 'Asia':
        return Icons.temple_buddhist;
      default:
        return Icons.location_on;
    }
  }

  int _getSelectedCountForRegion(String region) {
    final cities = _vibeCategories[region]!;
    int count = 0;
    for (final city in cities.keys) {
      for (final neighborhood in cities[city]!) {
        final fullName = '$neighborhood, $city';
        if (_selectedPlaces.contains(fullName)) {
          count++;
        }
      }
    }
    return count;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _suggestions = _getSmartSuggestions();
        // Reset expanded categories when search is cleared
        _expandedRegions.clear();
        _expandedCities.clear();
      } else {
        // First, search within existing places
        List<String> existingMatches = _allPlaces
            .where((place) => place.toLowerCase().contains(query.toLowerCase()))
            .toList();

        // If no exact matches, allow free text entry
        if (existingMatches.isEmpty && query.trim().isNotEmpty) {
          existingMatches = [query.trim()];
        }

        _suggestions = existingMatches;

        // Auto-expand categories that contain matching places
        _autoExpandMatchingCategories(query.toLowerCase());
      }
    });
  }

  void _autoExpandMatchingCategories(String query) {
    _expandedRegions.clear();
    _expandedCities.clear();

    // Search through all regions and cities for matches
    for (final region in _vibeCategories.keys) {
      final cities = _vibeCategories[region]!;
      bool regionHasMatch = false;

      for (final city in cities.keys) {
        final neighborhoods = cities[city]!;
        bool cityHasMatch = false;

        // Check if any neighborhood in this city matches the query
        for (final neighborhood in neighborhoods) {
          if (neighborhood.toLowerCase().contains(query) ||
              city.toLowerCase().contains(query) ||
              region.toLowerCase().contains(query)) {
            cityHasMatch = true;
            regionHasMatch = true;
            break;
          }
        }

        // If city has matches, expand it
        if (cityHasMatch) {
          _expandedCities[region] ??= {};
          _expandedCities[region]!.add(city);
        }
      }

      // If region has matches, expand it
      if (regionHasMatch) {
        _expandedRegions.add(region);
      }
    }
  }

  void _addPlace(String place) {
    if (!_selectedPlaces.contains(place)) {
      if (mounted) {
        setState(() {
          _selectedPlaces.add(place);
        });
        widget.onPlacesChanged(_selectedPlaces);

        // Show vibe-similar suggestions after adding a place
        _showVibeSuggestions(place);
      }
    }
  }

  void _removePlace(String place) {
    if (mounted) {
      setState(() {
        _selectedPlaces.remove(place);
      });
      widget.onPlacesChanged(_selectedPlaces);
    }
  }

  void _showVibeSuggestions(String selectedPlace) {
    // Get vibe-similar places based on the selected location
    List<String> vibeSuggestions = _getVibeSuggestions(selectedPlace);

    if (vibeSuggestions.isNotEmpty) {
      // Show a snackbar with vibe suggestions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Similar vibe places:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: vibeSuggestions.map((suggestion) => 
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _addPlace(suggestion);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: AppTheme.primaryColor),
                  )
                ).toList(),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
    }
  }

  List<String> _getVibeSuggestions(String place) {
    // Vibe matching logic based on the selected place
    String placeLower = place.toLowerCase();
    List<String> suggestions = [];

    // European cities vibe matching
    if (placeLower.contains('paris') || placeLower.contains('france')) {
      suggestions.addAll([
        'Milan, Italy',
        'Barcelona, Spain',
        'Amsterdam, Netherlands',
        'Berlin, Germany',
        'Vienna, Austria',
        'Prague, Czech Republic',
        'Rome, Italy',
        'Florence, Italy',
        'Venice, Italy'
      ]);
    } else if (placeLower.contains('london') ||
        placeLower.contains('uk') ||
        placeLower.contains('england')) {
      suggestions.addAll([
        'Edinburgh, Scotland',
        'Dublin, Ireland',
        'Manchester, UK',
        'Bristol, UK',
        'Brighton, UK',
        'Oxford, UK'
      ]);
    } else if (placeLower.contains('barcelona') ||
        placeLower.contains('spain')) {
      suggestions.addAll([
        'Madrid, Spain',
        'Valencia, Spain',
        'Seville, Spain',
        'Lisbon, Portugal',
        'Porto, Portugal',
        'Milan, Italy'
      ]);
    } else if (placeLower.contains('amsterdam') ||
        placeLower.contains('netherlands')) {
      suggestions.addAll([
        'Rotterdam, Netherlands',
        'Utrecht, Netherlands',
        'The Hague, Netherlands',
        'Copenhagen, Denmark',
        'Stockholm, Sweden',
        'Oslo, Norway'
      ]);
    }
    // Asian cities vibe matching
    else if (placeLower.contains('tokyo') || placeLower.contains('japan')) {
      suggestions.addAll([
        'Kyoto, Japan',
        'Osaka, Japan',
        'Seoul, South Korea',
        'Busan, South Korea',
        'Taipei, Taiwan',
        'Hong Kong'
      ]);
    } else if (placeLower.contains('seoul') || placeLower.contains('korea')) {
      suggestions.addAll([
        'Busan, South Korea',
        'Tokyo, Japan',
        'Kyoto, Japan',
        'Taipei, Taiwan',
        'Hong Kong',
        'Singapore'
      ]);
    } else if (placeLower.contains('bangkok') ||
        placeLower.contains('thailand')) {
      suggestions.addAll([
        'Chiang Mai, Thailand',
        'Phuket, Thailand',
        'Ho Chi Minh City, Vietnam',
        'Hanoi, Vietnam',
        'Singapore',
        'Kuala Lumpur, Malaysia'
      ]);
    }
    // US cities vibe matching
    else if (placeLower.contains('new york') ||
        placeLower.contains('nyc') ||
        placeLower.contains('brooklyn') ||
        placeLower.contains('manhattan')) {
      suggestions.addAll([
        'Los Angeles, CA',
        'San Francisco, CA',
        'Chicago, IL',
        'Boston, MA',
        'Philadelphia, PA',
        'Washington, DC'
      ]);
    } else if (placeLower.contains('los angeles') ||
        placeLower.contains('la')) {
      suggestions.addAll([
        'San Francisco, CA',
        'San Diego, CA',
        'Palm Springs, CA',
        'Las Vegas, NV',
        'Phoenix, AZ',
        'Miami, FL'
      ]);
    } else if (placeLower.contains('san francisco') ||
        placeLower.contains('sf')) {
      suggestions.addAll([
        'Oakland, CA',
        'Berkeley, CA',
        'San Jose, CA',
        'Portland, OR',
        'Seattle, WA',
        'Austin, TX'
      ]);
    } else if (placeLower.contains('miami') || placeLower.contains('florida')) {
      suggestions.addAll([
        'Orlando, FL',
        'Tampa, FL',
        'Fort Lauderdale, FL',
        'Key West, FL',
        'New Orleans, LA',
        'Nashville, TN'
      ]);
    }
    // Add more vibe matching patterns as needed

    // Filter out places that are already selected
    suggestions = suggestions
        .where((suggestion) => !_selectedPlaces.contains(suggestion))
        .toList();

    // Limit to 6 suggestions
    if (suggestions.length > 6) {
      suggestions = suggestions.take(6).toList();
    }

    return suggestions;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
