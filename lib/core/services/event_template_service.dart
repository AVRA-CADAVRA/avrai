import 'dart:developer' as developer;
import 'package:spots/core/models/event_template.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';

/// OUR_GUTS.md: "The key opens doors to events"
/// Easy Event Hosting - Phase 1: Event Template Service
/// Philosophy: Make hosting "incredibly easy" - one-tap event creation
class EventTemplateService {
  static const String _logName = 'EventTemplateService';
  
  // Cache of all templates
  final Map<String, EventTemplate> _templates = {};
  final Map<String, TemplateCategory> _categories = {};
  
  EventTemplateService() {
    _initializeDefaultTemplates();
  }
  
  /// Get all available templates
  List<EventTemplate> getAllTemplates() {
    return _templates.values.toList();
  }
  
  /// Get template by ID
  EventTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }
  
  /// Get templates by category
  List<EventTemplate> getTemplatesByCategory(String category) {
    return _templates.values
        .where((t) => t.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
  
  /// Get templates by event type
  List<EventTemplate> getTemplatesByType(ExpertiseEventType type) {
    return _templates.values.where((t) => t.eventType == type).toList();
  }
  
  /// Get templates for businesses only
  /// OUR_GUTS.md: "Businesses vetted by admins"
  List<EventTemplate> getBusinessTemplates() {
    return _templates.values
        .where((t) => t.metadata['businessOnly'] == true)
        .toList();
  }
  
  /// Get templates for experts (non-business)
  List<EventTemplate> getExpertTemplates() {
    return _templates.values
        .where((t) => t.metadata['businessOnly'] != true)
        .toList();
  }
  
  /// Search templates by keyword
  List<EventTemplate> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return _templates.values.where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
          t.category.toLowerCase().contains(lowerQuery) ||
          t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  /// Get template categories
  List<TemplateCategory> getCategories() {
    return _categories.values.toList();
  }
  
  /// Create event from template
  /// Philosophy: Pre-fill everything, user just adjusts date/time
  ExpertiseEvent createEventFromTemplate({
    required EventTemplate template,
    required UnifiedUser host,
    required DateTime startTime,
    List<Spot>? selectedSpots,
    String? customTitle,
    String? customDescription,
    int? customMaxAttendees,
    double? customPrice,
  }) {
    developer.log(
      'Creating event from template: ${template.name}',
      name: _logName,
    );
    
    final endTime = template.getEstimatedEndTime(startTime);
    
    final hostName = host.displayName ?? 'Host';
    final title = customTitle ?? template.generateTitle(hostName);
    
    final description = customDescription ?? template.generateDescription(
      hostName: hostName,
      location: selectedSpots?.isNotEmpty == true ? selectedSpots!.first.name : null,
      spotCount: selectedSpots?.length ?? template.recommendedSpotCount,
    );
    
    return ExpertiseEvent(
      id: _generateEventId(),
      title: title,
      description: description,
      category: template.category,
      eventType: template.eventType,
      host: host,
      startTime: startTime,
      endTime: endTime,
      spots: selectedSpots ?? [],
      maxAttendees: customMaxAttendees ?? template.defaultMaxAttendees,
      price: customPrice ?? template.suggestedPrice,
      isPaid: (customPrice ?? template.suggestedPrice ?? 0) > 0,
      isPublic: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: EventStatus.upcoming,
    );
  }
  
  // ========================================================================
  // DEFAULT TEMPLATES
  // 10 pre-built templates for common event types
  // ========================================================================
  
  void _initializeDefaultTemplates() {
    // 1. Coffee Tasting Tour
    _addTemplate(EventTemplate(
      id: 'coffee_tasting_tour',
      name: 'Coffee Tasting Tour',
      category: 'Coffee',
      eventType: ExpertiseEventType.tour,
      icon: '☕',
      descriptionTemplate: 
          'Join {hostName} for a guided tour of {location}\'s best coffee shops. '
          'We\'ll visit {spotCount} carefully selected spots, taste different brewing methods, '
          'and discuss coffee culture. Perfect for coffee enthusiasts and newcomers alike!',
      defaultDuration: const Duration(hours: 2),
      defaultMaxAttendees: 15,
      suggestedPrice: 25.0,
      suggestedSpotTypes: ['coffee_shop', 'roastery', 'cafe'],
      recommendedSpotCount: 3,
      tags: ['beginner-friendly', 'indoor', 'educational'],
    ));
    
    // 2. Bookstore Walk
    _addTemplate(EventTemplate(
      id: 'bookstore_walk',
      name: 'Bookstore Walk',
      category: 'Books',
      eventType: ExpertiseEventType.walk,
      icon: '📚',
      descriptionTemplate: 
          'Explore {location}\'s literary treasures with {hostName}! '
          'We\'ll visit {spotCount} unique bookstores, from rare book shops to cozy independents. '
          'Discover hidden literary gems and share book recommendations with fellow readers.',
      defaultDuration: const Duration(hours: 2, minutes: 30),
      defaultMaxAttendees: 20,
      suggestedPrice: null, // Free
      suggestedSpotTypes: ['bookstore', 'library', 'reading_room'],
      recommendedSpotCount: 4,
      tags: ['beginner-friendly', 'indoor', 'free', 'cultural'],
    ));
    
    // 3. Bar Crawl
    _addTemplate(EventTemplate(
      id: 'bar_crawl',
      name: 'Bar Crawl',
      category: 'Nightlife',
      eventType: ExpertiseEventType.tour,
      icon: '🍻',
      descriptionTemplate: 
          'Experience {location}\'s best bars with {hostName}! '
          'We\'ll visit {spotCount} carefully curated spots, from craft cocktail bars to local dives. '
          'Meet new people, try signature drinks, and discover your new favorite hangout.',
      defaultDuration: const Duration(hours: 3),
      defaultMaxAttendees: 25,
      suggestedPrice: 30.0,
      suggestedSpotTypes: ['bar', 'pub', 'cocktail_bar', 'brewery'],
      recommendedSpotCount: 5,
      tags: ['21+', 'nightlife', 'social'],
    ));
    
    // 4. Food Tour
    _addTemplate(EventTemplate(
      id: 'food_tour',
      name: 'Culinary Tour',
      category: 'Food',
      eventType: ExpertiseEventType.tasting,
      icon: '🍽️',
      descriptionTemplate: 
          'Taste your way through {location} with {hostName}! '
          'This culinary journey features {spotCount} must-try spots, from hole-in-the-wall gems to local favorites. '
          'Come hungry and leave with a full stomach and new appreciation for local cuisine.',
      defaultDuration: const Duration(hours: 3),
      defaultMaxAttendees: 15,
      suggestedPrice: 50.0,
      suggestedSpotTypes: ['restaurant', 'food_truck', 'market', 'bakery'],
      recommendedSpotCount: 5,
      tags: ['food-inclusive', 'cultural', 'beginner-friendly'],
    ));
    
    // 5. Trivia Night
    _addTemplate(EventTemplate(
      id: 'trivia_night',
      name: 'Trivia Night',
      category: 'Social',
      eventType: ExpertiseEventType.meetup,
      icon: '🎯',
      descriptionTemplate: 
          'Test your knowledge at {hostName}\'s trivia night! '
          'Join fellow trivia enthusiasts for an evening of friendly competition. '
          'Form teams, answer questions, and win prizes. All skill levels welcome!',
      defaultDuration: const Duration(hours: 2),
      defaultMaxAttendees: 50,
      suggestedPrice: null, // Free (venue may have drink minimum)
      suggestedSpotTypes: ['bar', 'pub', 'restaurant'],
      recommendedSpotCount: 1,
      tags: ['indoor', 'social', 'free', 'beginner-friendly'],
    ));
    
    // 6. Museum Day
    _addTemplate(EventTemplate(
      id: 'museum_tour',
      name: 'Museum Tour',
      category: 'Art',
      eventType: ExpertiseEventType.tour,
      icon: '🎨',
      descriptionTemplate: 
          'Explore {location}\'s cultural treasures with {hostName}! '
          'We\'ll visit {spotCount} fascinating museums, from contemporary art to natural history. '
          'Guided discussions and plenty of time to explore. Art lovers and curious minds welcome!',
      defaultDuration: const Duration(hours: 4),
      defaultMaxAttendees: 15,
      suggestedPrice: 40.0,
      suggestedSpotTypes: ['museum', 'gallery', 'exhibition'],
      recommendedSpotCount: 2,
      tags: ['indoor', 'cultural', 'educational'],
    ));
    
    // 7. Concert/Live Music 🎵
    _addTemplate(EventTemplate(
      id: 'concert_meetup',
      name: 'Concert Meetup',
      category: 'Music',
      eventType: ExpertiseEventType.meetup,
      icon: '🎵',
      descriptionTemplate: 
          'Experience live music with {hostName} and fellow music lovers! '
          'We\'ll meet before the show for drinks and head to the venue together. '
          'Great way to enjoy concerts with a group and make new friends who share your musical taste.',
      defaultDuration: const Duration(hours: 3),
      defaultMaxAttendees: 20,
      suggestedPrice: 35.0, // Plus ticket cost
      suggestedSpotTypes: ['music_venue', 'concert_hall', 'bar'],
      recommendedSpotCount: 1,
      tags: ['nightlife', 'social', 'music'],
      metadata: {
        'note': 'Price does not include concert ticket',
        'vibeTracking': ['energy_preference', 'crowd_tolerance', 'value_orientation'],
      },
    ));
    
    // 8. Art Gallery Opening 🎨
    _addTemplate(EventTemplate(
      id: 'gallery_opening',
      name: 'Gallery Opening',
      category: 'Art',
      eventType: ExpertiseEventType.meetup,
      icon: '🖼️',
      descriptionTemplate: 
          'Join {hostName} for an art gallery opening in {location}! '
          'Experience new exhibitions, meet artists, and mingle with art enthusiasts. '
          'This is a great opportunity to discover local talent and expand your art knowledge.',
      defaultDuration: const Duration(hours: 2),
      defaultMaxAttendees: 30,
      suggestedPrice: null, // Free
      suggestedSpotTypes: ['gallery', 'art_studio', 'exhibition_space'],
      recommendedSpotCount: 1,
      tags: ['indoor', 'cultural', 'free', 'social'],
      metadata: {
        'vibeTracking': ['value_orientation', 'crowd_tolerance', 'authenticity_preference'],
      },
    ));
    
    // 9. Sports Watch Party ⚽
    _addTemplate(EventTemplate(
      id: 'sports_watch_party',
      name: 'Game Watch Party',
      category: 'Sports',
      eventType: ExpertiseEventType.meetup,
      icon: '⚽',
      descriptionTemplate: 
          'Watch the big game with {hostName} and fellow fans! '
          'We\'ll gather at a great sports bar with big screens and good vibes. '
          'Cheer together, enjoy food and drinks, and share the excitement of game day!',
      defaultDuration: const Duration(hours: 3),
      defaultMaxAttendees: 40,
      suggestedPrice: null, // Free (venue minimum)
      suggestedSpotTypes: ['sports_bar', 'pub', 'restaurant'],
      recommendedSpotCount: 1,
      tags: ['indoor', 'social', 'free', 'casual'],
      metadata: {
        'vibeTracking': ['energy_preference', 'crowd_tolerance', 'community_orientation'],
      },
    ));
    
    // 10. Coffee Brewing Workshop
    _addTemplate(EventTemplate(
      id: 'coffee_workshop',
      name: 'Coffee Brewing Workshop',
      category: 'Coffee',
      eventType: ExpertiseEventType.workshop,
      icon: '☕',
      descriptionTemplate: 
          'Learn the art of coffee brewing with {hostName}! '
          'This hands-on workshop covers different brewing methods, bean selection, and tasting techniques. '
          'Leave with new skills and confidence to brew amazing coffee at home.',
      defaultDuration: const Duration(hours: 2),
      defaultMaxAttendees: 12,
      suggestedPrice: 35.0,
      suggestedSpotTypes: ['coffee_shop', 'roastery', 'workshop_space'],
      recommendedSpotCount: 1,
      tags: ['indoor', 'educational', 'hands-on', 'beginner-friendly'],
    ));
    
    // ========================================================================
    // BUSINESS EVENT TEMPLATES (Admin-Vetted Businesses Only)
    // ========================================================================
    
    // 11. Grand Opening 🎉
    _addTemplate(EventTemplate(
      id: 'grand_opening',
      name: 'Grand Opening',
      category: 'Business',
      eventType: ExpertiseEventType.meetup,
      icon: '🎉',
      descriptionTemplate: 
          'Celebrate the grand opening of {hostName}! '
          'Join us for special offers, giveaways, and be among the first to experience what we have to offer. '
          'Meet the team, explore our space, and enjoy exclusive opening day deals!',
      defaultDuration: const Duration(hours: 4),
      defaultMaxAttendees: 100,
      suggestedPrice: null, // Free
      suggestedSpotTypes: ['business'],
      recommendedSpotCount: 1,
      tags: ['free', 'business', 'celebration', 'special-event'],
      metadata: {'businessOnly': true},
    ));
    
    // 12. Happy Hour Special 🍸
    _addTemplate(EventTemplate(
      id: 'happy_hour',
      name: 'Happy Hour Special',
      category: 'Business',
      eventType: ExpertiseEventType.meetup,
      icon: '🍸',
      descriptionTemplate: 
          'Join {hostName} for happy hour! '
          'Enjoy special pricing on drinks and appetizers, great vibes, and the perfect way to unwind. '
          'Bring friends and make new ones at our weekly happy hour.',
      defaultDuration: const Duration(hours: 2),
      defaultMaxAttendees: 50,
      suggestedPrice: null, // Free entry
      suggestedSpotTypes: ['bar', 'restaurant', 'brewery'],
      recommendedSpotCount: 1,
      tags: ['free', 'business', 'social', 'recurring'],
      metadata: {'businessOnly': true},
    ));
    
    // 13. Flash Sale Event 💰
    _addTemplate(EventTemplate(
      id: 'flash_sale',
      name: 'Flash Sale',
      category: 'Business',
      eventType: ExpertiseEventType.meetup,
      icon: '💰',
      descriptionTemplate: 
          '{hostName} is hosting a flash sale! '
          'Limited time, exclusive deals on select items. First come, first served! '
          'Don\'t miss out on these incredible savings.',
      defaultDuration: const Duration(hours: 3),
      defaultMaxAttendees: 200,
      suggestedPrice: null,
      suggestedSpotTypes: ['business', 'store', 'shop'],
      recommendedSpotCount: 1,
      tags: ['free', 'business', 'sale', 'limited-time'],
      metadata: {'businessOnly': true},
    ));
    
    // 14. Live Music Night 🎸
    _addTemplate(EventTemplate(
      id: 'live_music_business',
      name: 'Live Music Night',
      category: 'Business',
      eventType: ExpertiseEventType.meetup,
      icon: '🎸',
      descriptionTemplate: 
          'Live music at {hostName}! '
          'Join us for an evening of great tunes, food, and drinks. '
          'Featuring local artists and a vibrant atmosphere. Reserve your spot!',
      defaultDuration: const Duration(hours: 3),
      defaultMaxAttendees: 80,
      suggestedPrice: 10.0, // Cover charge
      suggestedSpotTypes: ['bar', 'restaurant', 'music_venue'],
      recommendedSpotCount: 1,
      tags: ['business', 'music', 'nightlife', 'entertainment'],
      metadata: {
        'businessOnly': true,
        'vibeTracking': ['energy_preference', 'crowd_tolerance', 'value_orientation'],
      },
    ));
    
    // 15. Tasting Event 🍷
    _addTemplate(EventTemplate(
      id: 'business_tasting',
      name: 'Tasting Event',
      category: 'Business',
      eventType: ExpertiseEventType.tasting,
      icon: '🍷',
      descriptionTemplate: 
          'Experience a curated tasting at {hostName}! '
          'Sample our finest selections with expert guidance. '
          'Learn about flavors, pairings, and what makes each offering special.',
      defaultDuration: const Duration(hours: 2),
      defaultMaxAttendees: 25,
      suggestedPrice: 40.0,
      suggestedSpotTypes: ['winery', 'brewery', 'restaurant', 'specialty_shop'],
      recommendedSpotCount: 1,
      tags: ['business', 'tasting', 'educational', 'premium'],
      metadata: {'businessOnly': true},
    ));
    
    // Initialize categories
    _initializeCategories();
    
    developer.log(
      'Initialized ${_templates.length} default templates',
      name: _logName,
    );
  }
  
  void _initializeCategories() {
    _categories['coffee'] = const TemplateCategory(
      id: 'coffee',
      name: 'Coffee & Tea',
      icon: '☕',
      templateIds: ['coffee_tasting_tour', 'coffee_workshop'],
    );
    
    _categories['food'] = const TemplateCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: '🍽️',
      templateIds: ['food_tour'],
    );
    
    _categories['nightlife'] = const TemplateCategory(
      id: 'nightlife',
      name: 'Nightlife & Bars',
      icon: '🍻',
      templateIds: ['bar_crawl'],
    );
    
    _categories['culture'] = const TemplateCategory(
      id: 'culture',
      name: 'Arts & Culture',
      icon: '🎨',
      templateIds: ['museum_tour', 'bookstore_walk', 'gallery_opening'],
    );
    
    _categories['music'] = const TemplateCategory(
      id: 'music',
      name: 'Music & Entertainment',
      icon: '🎵',
      templateIds: ['concert_meetup'],
    );
    
    _categories['social'] = const TemplateCategory(
      id: 'social',
      name: 'Social & Meetups',
      icon: '👥',
      templateIds: ['trivia_night', 'sports_watch_party'],
    );
    
    _categories['business'] = const TemplateCategory(
      id: 'business',
      name: 'Business Events',
      icon: '🏢',
      templateIds: [
        'grand_opening',
        'happy_hour',
        'flash_sale',
        'live_music_business',
        'business_tasting',
      ],
    );
  }
  
  void _addTemplate(EventTemplate template) {
    _templates[template.id] = template;
  }
  
  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}';
  }
}

