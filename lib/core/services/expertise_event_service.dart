import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/geographic_scope_service.dart';
import 'package:spots/core/services/cross_locality_connection_service.dart'
    show
        CrossLocalityConnectionService,
        ConnectedLocality;
import 'package:spots/core/services/community_event_service.dart';

/// Expertise Event Service
/// OUR_GUTS.md: "Pins unlock new features, like event hosting"
/// Manages expert-led events (tours, workshops, tastings, etc.)
class ExpertiseEventService {
  static const String _logName = 'ExpertiseEventService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final GeographicScopeService _geographicScopeService;
  final CrossLocalityConnectionService _crossLocalityService;
  final CommunityEventService _communityEventService;

  // Performance optimization: In-memory event cache for O(1) lookups
  // In production, this would be replaced with database queries with indexes
  final Map<String, ExpertiseEvent> _eventCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTTL = Duration(minutes: 5); // Cache events for 5 minutes
  static const int _maxCacheSize = 1000; // Limit cache size to prevent memory issues

  ExpertiseEventService({
    GeographicScopeService? geographicScopeService,
    CrossLocalityConnectionService? crossLocalityService,
    CommunityEventService? communityEventService,
  })  : _geographicScopeService =
            geographicScopeService ?? GeographicScopeService(),
        _crossLocalityService =
            crossLocalityService ?? CrossLocalityConnectionService(),
        _communityEventService =
            communityEventService ?? CommunityEventService();

  /// Create a new expertise event
  /// Requires user to have Local level or higher expertise
  Future<ExpertiseEvent> createEvent({
    required UnifiedUser host,
    required String title,
    required String description,
    required String category,
    required ExpertiseEventType eventType,
    required DateTime startTime,
    required DateTime endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    int maxAttendees = 20,
    double? price,
    bool isPublic = true,
  }) async {
    try {
      _logger.info('Creating expertise event: $title', tag: _logName);

      // Verify host can host events (Local level or higher)
      if (!host.canHostEvents()) {
        throw Exception('Host must have Local level or higher expertise to host events');
      }

      // Verify host has expertise in category
      if (!host.hasExpertiseIn(category)) {
        throw Exception('Host must have expertise in $category');
      }

      // Validate geographic scope if location is provided
      if (location != null && location.isNotEmpty) {
        try {
          // Extract locality from location string
          // Location format: "Locality, City, State, Country" or "Locality, City"
          final locality = location.split(',').first.trim();
          
          _geographicScopeService.validateEventLocation(
            userId: host.id,
            user: host,
            category: category,
            eventLocality: locality,
          );
        } catch (e) {
          // Re-throw with more context if it's a geographic scope error
          if (e is Exception) {
            _logger.warning(
              'Geographic scope validation failed: ${e.toString()}',
              tag: _logName,
            );
            rethrow;
          }
          // If it's not an Exception, wrap it
          throw Exception('Geographic scope validation failed: ${e.toString()}');
        }
      }

      final event = ExpertiseEvent(
        id: _generateEventId(),
        title: title,
        description: description,
        category: category,
        eventType: eventType,
        host: host,
        startTime: startTime,
        endTime: endTime,
        spots: spots ?? [],
        location: location,
        latitude: latitude,
        longitude: longitude,
        maxAttendees: maxAttendees,
        price: price,
        isPaid: price != null && price > 0,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: EventStatus.upcoming,
      );

      // In production, save to database
      await _saveEvent(event);

      _logger.info('Created event: ${event.id}', tag: _logName);
      return event;
    } catch (e) {
      _logger.error('Error creating event', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Copy & Repeat: Duplicate an event for easy re-hosting
  /// OUR_GUTS.md: "Make hosting incredibly easy"
  /// Philosophy: One-click to host the same event again
  Future<ExpertiseEvent> duplicateEvent({
    required ExpertiseEvent originalEvent,
    DateTime? newStartTime,
    bool autoSuggestTime = true,
  }) async {
    try {
      _logger.info('Duplicating event: ${originalEvent.id}', tag: _logName);
      
      // Auto-suggest next weekend if no time specified
      DateTime startTime = newStartTime ?? _suggestNextWeekend();
      
      // Calculate end time based on original duration
      final duration = originalEvent.endTime.difference(originalEvent.startTime);
      final endTime = startTime.add(duration);
      
      // Create new event with same settings
      final duplicatedEvent = ExpertiseEvent(
        id: _generateEventId(),
        title: originalEvent.title,
        description: originalEvent.description,
        category: originalEvent.category,
        eventType: originalEvent.eventType,
        host: originalEvent.host,
        startTime: startTime,
        endTime: endTime,
        spots: originalEvent.spots,
        location: originalEvent.location,
        latitude: originalEvent.latitude,
        longitude: originalEvent.longitude,
        maxAttendees: originalEvent.maxAttendees,
        price: originalEvent.price,
        isPaid: originalEvent.isPaid,
        isPublic: originalEvent.isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: EventStatus.upcoming,
        attendeeIds: [], // Reset attendees
        attendeeCount: 0,
      );
      
      await _saveEvent(duplicatedEvent);
      
      _logger.info('Duplicated event: ${duplicatedEvent.id}', tag: _logName);
      return duplicatedEvent;
    } catch (e) {
      _logger.error('Error duplicating event', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Suggest next weekend date for events
  DateTime _suggestNextWeekend() {
    final now = DateTime.now();
    var saturday = now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
    if (saturday.isBefore(now)) {
      saturday = saturday.add(const Duration(days: 7));
    }
    return DateTime(saturday.year, saturday.month, saturday.day, 10, 0);
  }

  /// Register for an event
  Future<void> registerForEvent(ExpertiseEvent event, UnifiedUser user) async {
    try {
      _logger.info('User ${user.id} registering for event ${event.id}', tag: _logName);

      if (!event.canUserAttend(user.id)) {
        throw Exception('User cannot attend this event');
      }

      final updated = event.copyWith(
        attendeeIds: [...event.attendeeIds, user.id],
        attendeeCount: event.attendeeCount + 1,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('User registered for event', tag: _logName);
    } catch (e) {
      _logger.error('Error registering for event', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Cancel event registration
  Future<void> cancelRegistration(ExpertiseEvent event, UnifiedUser user) async {
    try {
      if (!event.attendeeIds.contains(user.id)) {
        throw Exception('User is not registered for this event');
      }

      final updated = event.copyWith(
        attendeeIds: event.attendeeIds.where((id) => id != user.id).toList(),
        attendeeCount: event.attendeeCount - 1,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('User cancelled registration', tag: _logName);
    } catch (e) {
      _logger.error('Error cancelling registration', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get events hosted by an expert
  Future<List<ExpertiseEvent>> getEventsByHost(UnifiedUser host) async {
    try {
      final allEvents = await _getAllEvents();
      return allEvents
          .where((event) => event.host.id == host.id)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _logger.error('Error getting events by host', error: e, tag: _logName);
      return [];
    }
  }

  /// Get events user is attending
  Future<List<ExpertiseEvent>> getEventsByAttendee(UnifiedUser user) async {
    try {
      final allEvents = await _getAllEvents();
      return allEvents
          .where((event) => event.attendeeIds.contains(user.id))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _logger.error('Error getting events by attendee', error: e, tag: _logName);
      return [];
    }
  }

  /// Get event by ID
  /// 
  /// Fetches a single event by its unique identifier.
  /// 
  /// **Parameters:**
  /// - `eventId`: Unique event identifier
  /// 
  /// **Returns:**
  /// - `ExpertiseEvent?`: The event if found, `null` if not found
  /// 
  /// **Note:**
  /// - Currently uses `_getAllEvents()` for filtering (same as workaround)
  /// - In production, replace with direct database query by ID for better performance
  /// 
  /// **Usage:**
  /// ```dart
  /// final event = await eventService.getEventById('event-123');
  /// if (event != null) {
  ///   // Event found, display details
  /// } else {
  ///   // Event not found
  /// }
  /// ```
  /// Get event by ID
  /// 
  /// Performance optimization: Uses direct cache lookup (O(1)) instead of
  /// filtering all events (O(n)). Falls back to database query if not in cache.
  Future<ExpertiseEvent?> getEventById(String eventId) async {
    try {
      _logger.info('Getting event by ID: $eventId', tag: _logName);
      
      // Performance optimization: Check cache first (O(1) lookup)
      if (_eventCache.containsKey(eventId)) {
        final cachedTimestamp = _cacheTimestamps[eventId];
        if (cachedTimestamp != null && 
            DateTime.now().difference(cachedTimestamp) < _cacheTTL) {
          _logger.debug('Event found in cache: $eventId', tag: _logName);
          return _eventCache[eventId];
        } else {
          // Cache expired, remove it
          _eventCache.remove(eventId);
          _cacheTimestamps.remove(eventId);
        }
      }
      
      // Not in cache or expired, query database directly by ID
      // In production: SELECT * FROM events WHERE id = $eventId
      // For now, fall back to _getAllEvents() but log warning
      _logger.warn(
        'Event not in cache, querying all events (performance impact). '
        'In production, implement direct database query by ID.',
        tag: _logName,
      );
      
      final allEvents = await _getAllEvents();
      try {
        final event = allEvents.firstWhere(
          (event) => event.id == eventId,
        );
        
        // Cache the event for future lookups
        _cacheEvent(event);
        
        return event;
      } catch (e) {
        // Event not found - return null (not an error condition)
        _logger.info('Event not found: $eventId', tag: _logName);
        return null;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error getting event by ID: $eventId',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return null;
    }
  }

  /// Search events
  /// 
  /// **Local Expert Priority:**
  /// - Local experts hosting in their locality rank higher than city experts
  /// - Priority: Local expert > City expert (when hosting in locality)
  /// - Ensures local experts are visible in their locality
  /// 
  /// **Community Events Integration:**
  /// - Community events are included in search results
  /// - Community events can be filtered separately if needed
  /// - Community events appear alongside expert events
  Future<List<ExpertiseEvent>> searchEvents({
    String? category,
    String? location,
    ExpertiseEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int maxResults = 20,
    bool includeCommunityEvents = true,
  }) async {
    try {
      final allEvents = await _getAllEvents();
      
      // Get community events if included
      List<CommunityEvent> communityEvents = [];
      if (includeCommunityEvents) {
        try {
          communityEvents = await _communityEventService.getCommunityEvents(
            category: category,
            location: location,
            eventType: eventType,
            startDate: startDate,
            endDate: endDate,
            maxResults: maxResults,
          );
        } catch (e) {
          _logger.warning(
            'Error getting community events for search: ${e.toString()}',
            tag: _logName,
          );
          // Continue without community events if there's an error
        }
      }
      
      // Combine expert events and community events
      // CommunityEvent extends ExpertiseEvent, so they're compatible
      final allCombinedEvents = <ExpertiseEvent>[
        ...allEvents,
        ...communityEvents, // CommunityEvent extends ExpertiseEvent
      ];
      
      // Filter events
      final filteredEvents = allCombinedEvents.where((event) {
        if (category != null && event.category != category) return false;
        if (location != null && event.location != null) {
          if (!event.location!.toLowerCase().contains(location.toLowerCase())) {
            return false;
          }
        }
        if (eventType != null && event.eventType != eventType) return false;
        if (startDate != null && event.startTime.isBefore(startDate)) return false;
        if (endDate != null && event.endTime.isAfter(endDate)) return false;
        if (event.status != EventStatus.upcoming) return false;
        return true;
      }).toList();

      // Extract target locality from location parameter
      String? targetLocality;
      if (location != null) {
        targetLocality = location.split(',').first.trim();
      }

      // Sort with local expert priority
      filteredEvents.sort((a, b) {
        // Calculate local expert priority boost for each event
        final priorityA = _calculateLocalExpertPriority(
          event: a,
          targetLocality: targetLocality,
        );
        final priorityB = _calculateLocalExpertPriority(
          event: b,
          targetLocality: targetLocality,
        );

        // Primary sort: Local expert priority (higher priority = first)
        final priorityComparison = priorityB.compareTo(priorityA);
        if (priorityComparison != 0) {
          return priorityComparison;
        }

        // Secondary sort: Start time (earlier events first)
        return a.startTime.compareTo(b.startTime);
      });

      return filteredEvents.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error searching events', error: e, tag: _logName);
      return [];
    }
  }

  /// Calculate local expert priority boost
  /// 
  /// **Rules:**
  /// - Local expert hosting in their locality: 1.0 (highest priority)
  /// - City expert hosting in locality: 0.5 (lower priority)
  /// - Other cases: 0.0 (no boost)
  /// 
  /// **Returns:**
  /// Priority boost (0.0 to 1.0) - higher means higher priority in rankings
  double _calculateLocalExpertPriority({
    required ExpertiseEvent event,
    String? targetLocality,
  }) {
    if (targetLocality == null) {
      return 0.0; // No locality specified, no priority boost
    }

    final host = event.host;
    final eventLocality = _extractLocality(event.location);

    // Check if event is in target locality
    if (eventLocality == null ||
        eventLocality.toLowerCase() != targetLocality.toLowerCase()) {
      return 0.0; // Event not in target locality, no priority boost
    }

    // Check if host is local expert in this category
    final category = event.category;
    final hostLevel = host.getExpertiseLevel(category);

    if (hostLevel == null) {
      return 0.0; // No expertise in category, no priority boost
    }

    // Check if host is local level
    if (hostLevel == ExpertiseLevel.local) {
      // Verify host is in the same locality
      final hostLocality = _extractLocality(host.location);
      if (hostLocality != null &&
          hostLocality.toLowerCase() == targetLocality.toLowerCase()) {
        return 1.0; // Local expert hosting in their locality - highest priority
      }
    }

    // City expert hosting in locality gets lower priority
    if (hostLevel == ExpertiseLevel.city) {
      return 0.5; // City expert - lower priority than local expert
    }

    // Other levels get no priority boost
    return 0.0;
  }

  /// Extract locality from location string
  /// Location format: "Locality, City, State, Country" or "Locality, City"
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  /// Get upcoming events in a category
  Future<List<ExpertiseEvent>> getUpcomingEventsInCategory(
    String category, {
    int maxResults = 10,
  }) async {
    return searchEvents(
      category: category,
      maxResults: maxResults,
    );
  }

  /// Search events including connected localities
  /// 
  /// **Cross-Locality Integration:**
  /// - Includes events from connected localities
  /// - Applies connection strength to ranking
  /// - Shows events from connected localities in search results
  /// 
  /// **What Doors Does This Open?**
  /// - Discovery Doors: Users discover events in connected localities
  /// - Exploration Doors: Users can explore neighboring localities
  /// - Connection Doors: Bring likeminded individuals around the locality into the locality
  Future<List<ExpertiseEvent>> searchEventsWithConnectedLocalities({
    required UnifiedUser user,
    String? category,
    String? location,
    ExpertiseEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int maxResults = 20,
    bool includeConnectedLocalities = true,
  }) async {
    try {
      // Extract target locality from location parameter
      String? targetLocality;
      if (location != null) {
        targetLocality = location.split(',').first.trim();
      }

      // Get base search results
      final baseEvents = await searchEvents(
        category: category,
        location: location,
        eventType: eventType,
        startDate: startDate,
        endDate: endDate,
        maxResults: maxResults,
      );

      if (!includeConnectedLocalities || targetLocality == null) {
        return baseEvents;
      }

      // Get connected localities
      final connectedLocalities = await _crossLocalityService.getConnectedLocalities(
        user: user,
        locality: targetLocality,
      );

      // Get events from connected localities
      final connectedEvents = <ExpertiseEvent>[];
      for (final connectedLocality in connectedLocalities) {
        final localityEvents = await searchEvents(
          category: category,
          location: connectedLocality.locality,
          eventType: eventType,
          startDate: startDate,
          endDate: endDate,
          maxResults: 5, // Limit events per connected locality
        );

        // Add connection strength metadata to events (for ranking)
        for (final event in localityEvents) {
          connectedEvents.add(event);
        }
      }

      // Combine base events and connected locality events
      final allEvents = <ExpertiseEvent>[...baseEvents, ...connectedEvents];

      // Remove duplicates (by event ID)
      final uniqueEvents = <String, ExpertiseEvent>{};
      for (final event in allEvents) {
        uniqueEvents[event.id] = event;
      }

      // Sort with local expert priority and connection strength
      final sortedEvents = uniqueEvents.values.toList();
      sortedEvents.sort((a, b) {
        // Calculate local expert priority
        final priorityA = _calculateLocalExpertPriority(
          event: a,
          targetLocality: targetLocality,
        );
        final priorityB = _calculateLocalExpertPriority(
          event: b,
          targetLocality: targetLocality,
        );

        // Primary sort: Local expert priority
        final priorityComparison = priorityB.compareTo(priorityA);
        if (priorityComparison != 0) {
          return priorityComparison;
        }

        // Secondary sort: Connection strength (if from connected locality)
        final connectionA = _getConnectionStrength(
          event: a,
          targetLocality: targetLocality,
          connectedLocalities: connectedLocalities,
        );
        final connectionB = _getConnectionStrength(
          event: b,
          targetLocality: targetLocality,
          connectedLocalities: connectedLocalities,
        );

        final connectionComparison = connectionB.compareTo(connectionA);
        if (connectionComparison != 0) {
          return connectionComparison;
        }

        // Tertiary sort: Start time
        return a.startTime.compareTo(b.startTime);
      });

      return sortedEvents.take(maxResults).toList();
    } catch (e) {
      _logger.error(
        'Error searching events with connected localities',
        error: e,
        tag: _logName,
      );
      // Fallback to regular search
      return searchEvents(
        category: category,
        location: location,
        eventType: eventType,
        startDate: startDate,
        endDate: endDate,
        maxResults: maxResults,
      );
    }
  }

  /// Get connection strength for an event from connected localities
  double _getConnectionStrength({
    required ExpertiseEvent event,
    required String? targetLocality,
    required List<ConnectedLocality> connectedLocalities,
  }) {
    if (targetLocality == null) return 0.0;

    final eventLocality = _extractLocality(event.location);
    if (eventLocality == null) return 0.0;

    // Find matching connected locality
    for (final connected in connectedLocalities) {
      if (connected.locality.toLowerCase() == eventLocality.toLowerCase()) {
        return connected.connectionStrength;
      }
    }

    return 0.0; // Not in connected localities
  }

  /// Update event status
  Future<void> updateEventStatus(
    ExpertiseEvent event,
    EventStatus status,
  ) async {
    try {
      final updated = event.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Updated event status: ${event.id}', tag: _logName);
    } catch (e) {
      _logger.error('Error updating event status', error: e, tag: _logName);
      rethrow;
    }
  }

  // Private helper methods

  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveEvent(ExpertiseEvent event) async {
    // In production, save to database
    // Performance optimization: Update cache when event is saved
    _cacheEvent(event);
  }

  Future<List<ExpertiseEvent>> _getAllEvents() async {
    // In production, query database
    // Performance optimization: Return cached events if available
    // This is a workaround until database integration
    _cleanExpiredCache();
    return _eventCache.values.toList();
  }

  /// Performance optimization: Cache event for O(1) lookups
  void _cacheEvent(ExpertiseEvent event) {
    // Enforce cache size limit to prevent memory issues
    if (_eventCache.length >= _maxCacheSize) {
      _evictOldestCacheEntry();
    }
    
    _eventCache[event.id] = event;
    _cacheTimestamps[event.id] = DateTime.now();
  }

  /// Remove expired cache entries
  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheTTL) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _eventCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      _logger.debug('Cleaned ${expiredKeys.length} expired cache entries', tag: _logName);
    }
  }

  /// Evict oldest cache entry when cache is full (LRU-style eviction)
  void _evictOldestCacheEntry() {
    if (_cacheTimestamps.isEmpty) return;
    
    // Find oldest entry
    String? oldestKey;
    DateTime? oldestTime;
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (oldestTime == null || timestamp.isBefore(oldestTime!)) {
        oldestTime = timestamp;
        oldestKey = key;
      }
    });
    
    if (oldestKey != null) {
      _eventCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
      _logger.debug('Evicted oldest cache entry: $oldestKey', tag: _logName);
    }
  }
}

