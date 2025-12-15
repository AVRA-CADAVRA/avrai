import 'dart:developer' as developer;
// Cleaned up stale imports; this service does not depend on those modules directly

/// AI-powered list generation service for SPOTS
/// Creates personalized list suggestions based on user preferences and AI analysis
class AIListGeneratorService {
  static const String _logName = 'AIListGeneratorService';
  
  // List categories and their associated preferences
  static const Map<String, List<String>> _categoryPreferences = {
    'Food & Drink': [
      'Coffee & Tea',
      'Bars & Pubs',
      'Fine Dining',
      'Casual Restaurants',
      'Food Trucks',
      'Bakeries',
      'Ice Cream',
      'Wine Bars',
      'Craft Beer',
      'Cocktail Bars',
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
    ],
    'Activities': [
      'Live Music',
      'Theaters',
      'Sports & Fitness',
      'Shopping',
      'Bookstores',
      'Libraries',
      'Cinemas',
      'Bowling',
      'Escape Rooms',
      'Arcades',
      'Spas & Wellness',
      'Yoga Studios',
      'Rock Climbing',
      'Dance Classes',
      'Art Classes',
      'Cooking Classes',
      'Photography',
      'Gaming',
      'Board Games',
      'Karaoke',
    ],
    'Outdoor & Nature': [
      'Hiking Trails',
      'Beaches',
      'Parks',
      'Gardens',
      'Botanical Gardens',
      'Nature Reserves',
      'Camping',
      'Fishing',
      'Kayaking',
      'Biking Trails',
      'Rock Climbing',
      'Bird Watching',
      'Stargazing',
      'Picnic Spots',
      'Waterfalls',
      'Scenic Views',
      'Wildlife',
      'Farms',
      'Vineyards',
      'Orchards',
    ],
  };

  /// Generates personalized list suggestions based on user preferences and age
  static Future<List<String>> generatePersonalizedLists({
    required String userName,
    int? age,
    required String? homebase,
    required List<String> favoritePlaces,
    required Map<String, List<String>> preferences,
  }) async {
    try {
      // #region agent log
      developer.log('Generating personalized lists for user: $userName', name: _logName);
      // #endregion
      
      // Validate and enhance preferences using category preferences
      final validatedPreferences = _validateAndEnhancePreferences(preferences);
      
      // #region agent log
      developer.log('Validated preferences: ${validatedPreferences.keys.length} categories, ${validatedPreferences.values.fold(0, (sum, prefs) => sum + prefs.length)} total preferences', name: _logName);
      // #endregion
      
      final suggestions = <String>[];
      
      // Generate location-aware suggestions
      if (homebase != null && homebase.isNotEmpty) {
        suggestions.addAll(_generateLocationBasedSuggestions(homebase, validatedPreferences));
      }
      
      // Generate preference-based suggestions
      suggestions.addAll(_generatePreferenceBasedSuggestions(validatedPreferences));
      
      // Generate personality-based suggestions
      suggestions.addAll(await _generatePersonalityBasedSuggestions(userName, validatedPreferences));
      
      // Generate AI-enhanced suggestions
      suggestions.addAll(_generateAIEnhancedSuggestions(homebase));
      
      // Generate favorite places inspired suggestions
      if (favoritePlaces.isNotEmpty) {
        suggestions.addAll(_generateFavoritePlacesSuggestions(favoritePlaces, homebase));
      }
      
      // Generate age-appropriate suggestions
      if (age != null) {
        suggestions.addAll(_generateAgeAppropriateSuggestions(age, homebase, validatedPreferences));
      }
      
      // Generate professional networking suggestions (for college students and professionals)
      if (age != null && age >= 18) {
        suggestions.addAll(_generateProfessionalNetworkingSuggestions(age, homebase, validatedPreferences));
      }
      
      // Filter out age-inappropriate suggestions
      final ageFilteredSuggestions = age != null 
          ? _filterAgeInappropriateSuggestions(suggestions, age)
          : suggestions;
      
      // Remove duplicates and prioritize based on age
      final uniqueSuggestions = ageFilteredSuggestions.toSet().toList();
      
      // For adults (26-64), prioritize professional networking but include some nightlife
      List<String> prioritizedSuggestions;
      if (age != null && age >= 26 && age < 65) {
        // Separate professional and social suggestions
        final professional = uniqueSuggestions.where((s) => 
          s.toLowerCase().contains('professional') ||
          s.toLowerCase().contains('career') ||
          s.toLowerCase().contains('networking') ||
          s.toLowerCase().contains('business') ||
          s.toLowerCase().contains('industry')
        ).toList();
        final social = uniqueSuggestions.where((s) => 
          s.toLowerCase().contains('nightlife') ||
          s.toLowerCase().contains('social') ||
          s.toLowerCase().contains('scene')
        ).toList();
        final other = uniqueSuggestions.where((s) => 
          !professional.contains(s) && !social.contains(s)
        ).toList();
        
        // Prioritize: 60% professional, 20% social, 20% other
        prioritizedSuggestions = [
          ...professional.take(5),
          ...social.take(1),
          ...other.take(2),
        ];
      } else {
        prioritizedSuggestions = uniqueSuggestions;
      }
      
      final finalSuggestions = prioritizedSuggestions.take(8).toList();
      
      // #region agent log
      developer.log('Generated ${finalSuggestions.length} personalized lists (age: ${age ?? 'not provided'})', name: _logName);
      // #endregion
      return finalSuggestions;
    } catch (e) {
      // #region agent log
      developer.log('Error generating personalized lists: $e', name: _logName);
      // #endregion
      return _getFallbackSuggestions(userName);
    }
  }
  
  /// Validates and enhances preferences using category preferences
  /// Filters out invalid preferences and ensures all preferences are from known categories
  static Map<String, List<String>> _validateAndEnhancePreferences(
    Map<String, List<String>> preferences,
  ) {
    final validated = <String, List<String>>{};
    
    // Iterate through known categories
    for (final category in _categoryPreferences.keys) {
      final categoryPrefs = preferences[category];
      if (categoryPrefs != null && categoryPrefs.isNotEmpty) {
        // Filter preferences to only include valid ones from _categoryPreferences
        final validPrefs = categoryPrefs.where((pref) {
          return _categoryPreferences[category]!.contains(pref);
        }).toList();
        
        if (validPrefs.isNotEmpty) {
          validated[category] = validPrefs;
        }
      }
    }
    
    // #region agent log
    developer.log('Preference validation: ${preferences.length} input categories, ${validated.length} validated categories', name: _logName);
    // #endregion
    
    return validated;
  }

  /// Generates location-based list suggestions
  static List<String> _generateLocationBasedSuggestions(
    String homebase,
    Map<String, List<String>> preferences,
  ) {
    final suggestions = <String>[];
    
    // Food & Drink preferences
    if (preferences.containsKey('Food & Drink')) {
      final foodPrefs = preferences['Food & Drink']!;
      for (final pref in foodPrefs) {
        switch (pref) {
          case 'Coffee & Tea':
            suggestions.add('Coffee & Tea Spots Near $homebase');
            suggestions.add('Hidden Cafes in $homebase');
            break;
          case 'Bars & Pubs':
            suggestions.add('Best Bars in $homebase');
            suggestions.add('Craft Beer Spots in $homebase');
            break;
          case 'Fine Dining':
            suggestions.add('Fine Dining in $homebase');
            suggestions.add('Date Night Restaurants');
            break;
          case 'Food Trucks':
            suggestions.add('Food Truck Hotspots in $homebase');
            suggestions.add('Street Food in $homebase');
            break;
          case 'Vegan/Vegetarian':
            suggestions.add('Vegan & Vegetarian Spots in $homebase');
            suggestions.add('Plant-Based Dining');
            break;
        }
      }
    }
    
    // Activities preferences
    if (preferences.containsKey('Activities')) {
      final activityPrefs = preferences['Activities']!;
      for (final pref in activityPrefs) {
        switch (pref) {
          case 'Live Music':
            suggestions.add('Live Music Venues in $homebase');
            suggestions.add('Jazz & Blues Spots');
            break;
          case 'Theaters':
            suggestions.add('Theater & Performance Venues');
            suggestions.add('Cultural Spots in $homebase');
            break;
          case 'Sports & Fitness':
            suggestions.add('Gyms & Fitness Centers in $homebase');
            suggestions.add('Sports Venues');
            break;
          case 'Shopping':
            suggestions.add('Shopping Districts in $homebase');
            suggestions.add('Local Boutiques');
            break;
          case 'Bookstores':
            suggestions.add('Independent Bookstores in $homebase');
            suggestions.add('Reading Spots');
            break;
        }
      }
    }
    
    // Outdoor & Nature preferences
    if (preferences.containsKey('Outdoor & Nature')) {
      final outdoorPrefs = preferences['Outdoor & Nature']!;
      for (final pref in outdoorPrefs) {
        switch (pref) {
          case 'Hiking Trails':
            suggestions.add('Hiking Trails Near $homebase');
            suggestions.add('Outdoor Adventures');
            break;
          case 'Beaches':
            suggestions.add('Beach Spots Near $homebase');
            suggestions.add('Waterfront Locations');
            break;
          case 'Parks':
            suggestions.add('Parks & Green Spaces in $homebase');
            suggestions.add('Picnic Spots');
            break;
        }
      }
    }
    
    return suggestions;
  }

  /// Generates preference-based list suggestions
  static List<String> _generatePreferenceBasedSuggestions(
    Map<String, List<String>> preferences,
  ) {
    final suggestions = <String>[];
    
    // Count preferences to determine user's interests
    final foodCount = preferences['Food & Drink']?.length ?? 0;
    final activityCount = preferences['Activities']?.length ?? 0;
    final outdoorCount = preferences['Outdoor & Nature']?.length ?? 0;
    
    // Generate suggestions based on preference intensity
    if (foodCount > 3) {
      suggestions.add('Foodie Adventures');
      suggestions.add('Culinary Discoveries');
    }
    
    if (activityCount > 3) {
      suggestions.add('Entertainment Hotspots');
      suggestions.add('Activity Centers');
    }
    
    if (outdoorCount > 3) {
      suggestions.add('Nature Escapes');
      suggestions.add('Outdoor Adventures');
    }
    
    // Mixed preferences
    if (foodCount > 0 && activityCount > 0) {
      suggestions.add('Social Dining Spots');
    }
    
    if (outdoorCount > 0 && foodCount > 0) {
      suggestions.add('Outdoor Dining');
    }
    
    return suggestions;
  }

  /// Generates personality-based suggestions using AI systems
  static Future<List<String>> _generatePersonalityBasedSuggestions(
    String userName,
    Map<String, List<String>> preferences,
  ) async {
    try {
      final suggestions = <String>[];
      
      // Analyze preferences to determine personality traits
      final hasManyFoodPrefs = (preferences['Food & Drink']?.length ?? 0) > 2;
      final hasManyActivityPrefs = (preferences['Activities']?.length ?? 0) > 2;
      final hasManyOutdoorPrefs = (preferences['Outdoor & Nature']?.length ?? 0) > 2;
      
      // Generate personality-based suggestions
      if (hasManyFoodPrefs) {
        suggestions.add('$userName\'s Food Adventures');
        suggestions.add('Culinary Explorer');
      }
      
      if (hasManyActivityPrefs) {
        suggestions.add('$userName\'s Entertainment Guide');
        suggestions.add('Activity Seeker');
      }
      
      if (hasManyOutdoorPrefs) {
        suggestions.add('$userName\'s Nature Trails');
        suggestions.add('Outdoor Enthusiast');
      }
      
      // Balanced personality
      if (hasManyFoodPrefs && hasManyActivityPrefs && hasManyOutdoorPrefs) {
        suggestions.add('$userName\'s Balanced Lifestyle');
        suggestions.add('Versatile Explorer');
      }
      
      return suggestions;
    } catch (e) {
      developer.log('Error generating personality-based suggestions: $e', name: _logName);
      return [];
    }
  }

  /// Generates AI-enhanced suggestions
  static List<String> _generateAIEnhancedSuggestions(String? homebase) {
    final suggestions = <String>[];
    
    if (homebase != null && homebase.isNotEmpty) {
      suggestions.addAll([
        'AI-Curated Local Gems in $homebase',
        'Community-Recommended Spots',
        'Trending in $homebase',
        'Hidden Treasures',
        'Local Expert Picks',
        'Insider Secrets',
        'Off-the-Beaten-Path',
        'Local Favorites',
      ]);
    } else {
      suggestions.addAll([
        'AI-Curated Local Gems',
        'Community-Recommended Spots',
        'Trending in Your Area',
        'Hidden Treasures',
        'Local Expert Picks',
        'Insider Secrets',
        'Off-the-Beaten-Path',
        'Local Favorites',
      ]);
    }
    
    return suggestions;
  }

  /// Generates suggestions based on favorite places
  static List<String> _generateFavoritePlacesSuggestions(
    List<String> favoritePlaces,
    String? homebase,
  ) {
    final suggestions = <String>[];
    
    // Analyze favorite places to generate relevant suggestions
    final hasInternationalPlaces = favoritePlaces.any((place) =>
        place.toLowerCase().contains('paris') ||
        place.toLowerCase().contains('tokyo') ||
        place.toLowerCase().contains('london') ||
        place.toLowerCase().contains('barcelona'));
    
    final hasNaturePlaces = favoritePlaces.any((place) =>
        place.toLowerCase().contains('park') ||
        place.toLowerCase().contains('beach') ||
        place.toLowerCase().contains('mountain') ||
        place.toLowerCase().contains('forest'));
    
    final hasUrbanPlaces = favoritePlaces.any((place) =>
        place.toLowerCase().contains('city') ||
        place.toLowerCase().contains('downtown') ||
        place.toLowerCase().contains('district'));
    
    // Generate suggestions based on favorite place types
    if (hasInternationalPlaces) {
      suggestions.add('International Vibes');
      suggestions.add('Global Flavors');
    }
    
    if (hasNaturePlaces) {
      suggestions.add('Nature Retreats');
      suggestions.add('Peaceful Escapes');
    }
    
    if (hasUrbanPlaces) {
      suggestions.add('Urban Adventures');
      suggestions.add('City Life');
    }
    
    // Mixed preferences
    if (hasInternationalPlaces && hasNaturePlaces) {
      suggestions.add('Cultural Nature Spots');
    }
    
    if (hasUrbanPlaces && hasNaturePlaces) {
      suggestions.add('Urban Nature Oases');
    }
    
    return suggestions;
  }

  /// Generates age-appropriate suggestions based on age group
  static List<String> _generateAgeAppropriateSuggestions(
    int age,
    String? homebase,
    Map<String, List<String>> preferences,
  ) {
    final suggestions = <String>[];
    final location = homebase ?? 'your area';
    
    // Age group categorization
    if (age < 13) {
      // Under 13: Family-friendly, educational, safe activities
      suggestions.add('Family Fun in $location');
      suggestions.add('Kid-Friendly Adventures');
      suggestions.add('Safe Play Spaces');
      suggestions.add('Educational Spots');
    } else if (age < 18) {
      // Teen (13-17): Social, fun, age-appropriate
      suggestions.add('Teen Hangout Spots in $location');
      suggestions.add('After School Adventures');
      suggestions.add('Teen-Friendly Activities');
      suggestions.add('Social Gathering Places');
    } else if (age < 26) {
      // Young Adult (18-25): Nightlife, social, exploration, professional networking
      suggestions.add('Nightlife in $location');
      suggestions.add('Young Adult Hotspots');
      suggestions.add('Social Scene');
      suggestions.add('College Hangouts');
      // Professional networking for college students
      suggestions.add('Professional Networking Spots');
      suggestions.add('Career Connection Places');
      suggestions.add('Industry Meetup Locations');
    } else if (age < 65) {
      // Adult (26-64): Professional networking primary, but also nightlife/social (less frequent)
      suggestions.add('Professional Networking Spots');
      suggestions.add('Career Development Venues');
      suggestions.add('Industry Networking Locations');
      suggestions.add('Business Casual Hangouts');
      suggestions.add('Refined Experiences in $location');
      suggestions.add('Adult Social Scene');
      suggestions.add('Quality Time Spots');
      // Include nightlife/social but less frequently than young adults
      suggestions.add('Upscale Nightlife in $location');
      suggestions.add('Professional Social Scene');
    } else {
      // Senior (65+): Accessible, comfortable, community-focused
      suggestions.add('Senior-Friendly Spots in $location');
      suggestions.add('Accessible Adventures');
      suggestions.add('Community Gathering Places');
      suggestions.add('Comfortable Hangouts');
    }
    
    return suggestions;
  }

  /// Generates professional networking suggestions for career-focused users
  static List<String> _generateProfessionalNetworkingSuggestions(
    int age,
    String? homebase,
    Map<String, List<String>> preferences,
  ) {
    final suggestions = <String>[];
    final location = homebase ?? 'your area';
    
    // Professional networking spots for career development
    suggestions.add('Professional Networking Spots in $location');
    suggestions.add('Career Connection Venues');
    suggestions.add('Industry Meetup Locations');
    suggestions.add('Business Casual Hangouts');
    
    // School/business integration for college students (18-25)
    if (age >= 18 && age < 26) {
      suggestions.add('College Career Networking Spots');
      suggestions.add('Student-Professional Mixers');
      suggestions.add('Campus-Industry Connection Places');
      suggestions.add('Find Your Professional Home');
      suggestions.add('School-Business Networking Venues');
    }
    
    // Industry-specific networking (if preferences indicate career interests)
    final hasProfessionalPrefs = preferences.values.any((prefs) => 
      prefs.any((pref) => pref.toLowerCase().contains('professional') ||
                        pref.toLowerCase().contains('networking') ||
                        pref.toLowerCase().contains('business')));
    
    if (hasProfessionalPrefs) {
      suggestions.add('Industry-Specific Networking Spots');
      suggestions.add('Professional Development Venues');
      suggestions.add('Career Growth Locations');
    }
    
    // Business integration suggestions
    suggestions.add('Business-Friendly Spots');
    suggestions.add('Professional Lunch Spots');
    suggestions.add('After-Work Networking Venues');
    suggestions.add('Industry Event Locations');
    
    return suggestions;
  }

  /// Filters out age-inappropriate suggestions
  static List<String> _filterAgeInappropriateSuggestions(
    List<String> suggestions,
    int age,
  ) {
    // Keywords that indicate 18+ content
    const adultKeywords = [
      'bar',
      'pub',
      'nightclub',
      'lounge',
      'wine',
      'cocktail',
      'brewery',
      'alcohol',
      'drinking',
      'nightlife',
      'adult',
    ];
    
    // Filter out 18+ content for users under 18
    if (age < 18) {
      return suggestions.where((suggestion) {
        final lower = suggestion.toLowerCase();
        return !adultKeywords.any((keyword) => lower.contains(keyword));
      }).toList();
    }
    
    // For 18+, return all suggestions
    return suggestions;
  }

  /// Fallback suggestions when AI generation fails
  static List<String> _getFallbackSuggestions(String userName) {
    return [
      '$userName\'s Chill Spots',
      '$userName\'s Fun Spots',
      '$userName\'s Recommended Spots',
      'Hidden Gems',
      'Local Favorites',
      'Weekend Adventures',
      'Community Picks',
      'Trending Spots',
    ];
  }
} 