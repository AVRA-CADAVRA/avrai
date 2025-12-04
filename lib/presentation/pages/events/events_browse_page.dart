import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/expertise/expertise_event_widget.dart';
import 'package:spots/presentation/widgets/events/community_event_widget.dart';
import 'package:spots/presentation/pages/events/event_details_page.dart';
import 'package:spots/presentation/widgets/events/event_scope_tab_widget.dart';
import 'package:spots/core/services/event_matching_service.dart';
import 'package:spots/core/services/cross_locality_connection_service.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/club_service.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/models/user.dart' as user_model;

/// Event Discovery UI - Browse/Search Page
/// Agent 2: Event Discovery & Hosting UI (Phase 1, Section 1)
/// Phase 6, Week 26-27: Events Page Organization & User Preference Learning
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Tab-based event organization by geographic scope (Community, Locality, City, State, Nation, Globe, Universe, Clubs/Communities)
/// - List view of events
/// - Search by title, category, location
/// - Filters: category, location, date, price
/// - Scope-based filtering (geographic scope from tabs)
/// - Event sorting by matching score (EventMatchingService)
/// - Cross-locality event discovery (CrossLocalityConnectionService)
/// - Pull-to-refresh
/// - Integration with ExpertiseEventService, EventMatchingService, CrossLocalityConnectionService
/// 
/// **Week 26-27 Updates:**
/// - Added EventScopeTabWidget for geographic scope filtering
/// - Integrated EventMatchingService for event sorting
/// - Integrated CrossLocalityConnectionService for connected locality events
/// - Added cross-locality event indicators
/// - Prepared integration points for EventRecommendationService (when available)
class EventsBrowsePage extends StatefulWidget {
  const EventsBrowsePage({super.key});

  @override
  State<EventsBrowsePage> createState() => _EventsBrowsePageState();
}

class _EventsBrowsePageState extends State<EventsBrowsePage> {
  final ExpertiseEventService _eventService = ExpertiseEventService();
  // TODO: Replace with CommunityEventService when Agent 1 creates it
  // final CommunityEventService _communityEventService = CommunityEventService();
  final EventMatchingService _matchingService = EventMatchingService();
  final CrossLocalityConnectionService _connectionService = CrossLocalityConnectionService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ExpertiseEvent> _events = [];
  List<ExpertiseEvent> _communityEvents = []; // Community events (non-expert events)
  List<ExpertiseEvent> _filteredEvents = [];
  bool _isLoading = false;
  String? _error;
  
  // Scope filter (from tabs)
  EventScope _selectedScope = EventScope.locality;
  
  // Cross-locality events tracking
  Set<String> _crossLocalityEventIds = {};
  
  // Filters
  String? _selectedCategory;
  String? _selectedLocation;
  String? _selectedDateFilter; // "all", "upcoming", "this_week", "this_month"
  String? _selectedPriceFilter; // "all", "free", "paid"
  ExpertiseEventType? _selectedEventType;
  
  // Available categories (from service or hardcoded for now)
  final List<String> _categories = [
    'Coffee',
    'Bookstores',
    'Restaurants',
    'Bars',
    'Parks',
    'Museums',
    'Music',
    'Art',
    'Sports',
    'Other',
  ];
  
  // Date filter options
  final Map<String, String> _dateFilters = {
    'all': 'All Events',
    'upcoming': 'Upcoming',
    'this_week': 'This Week',
    'this_month': 'This Month',
  };
  
  // Price filter options
  final Map<String, String> _priceFilters = {
    'all': 'All',
    'free': 'Free',
    'paid': 'Paid',
  };
  
  // Event types
  final List<ExpertiseEventType> _eventTypes = ExpertiseEventType.values;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current user for service integrations
      final currentUser = context.read<AuthBloc>().state;
      final user = currentUser is Authenticated ? currentUser.user : null;
      
      // Load events based on scope
      var events = <ExpertiseEvent>[];
      var communityEvents = <ExpertiseEvent>[];
      
      // Load events based on scope
      if (_selectedScope == EventScope.community) {
        // TODO: Replace with CommunityEventService.getCommunityEvents() when Agent 1 creates it
        // For now, filter from regular events by checking if event is community event
        // Once CommunityEventService exists, use:
        // communityEvents = await _communityEventService.getCommunityEvents(
        //   category: _selectedCategory,
        //   location: _selectedLocation,
        //   eventType: _selectedEventType,
        //   startDate: _getStartDateFilter(),
        //   maxResults: 50,
        // );
        // Placeholder: Load regular events and filter later
        final allEvents = await _eventService.searchEvents(
          category: _selectedCategory,
          location: _selectedLocation,
          eventType: _selectedEventType,
          startDate: _getStartDateFilter(),
          maxResults: 50,
        );
        // TODO: Filter by isCommunityEvent flag when CommunityEvent model exists
        // For now, assume free events with no price are community events
        communityEvents = allEvents.where((e) => !e.isPaid && (e.price == null || e.price == 0.0)).toList();
        events = communityEvents;
      } else if (_selectedScope == EventScope.clubsCommunities) {
        // Load club/community events
        // Get user's clubs and communities, then filter events
        if (user != null) {
          final clubService = ClubService();
          final communityService = CommunityService();
          final unifiedUser = _convertUserToUnifiedUser(user);
          
          // Get clubs/communities by category (limited approach - in production would have getByMember method)
          // For now, load all events and filter by checking membership
          final allEvents = await _eventService.searchEvents(
            category: _selectedCategory,
            location: _selectedLocation,
            eventType: _selectedEventType,
            startDate: _getStartDateFilter(),
            maxResults: 100,
          );
          
          // Filter events that belong to clubs/communities where user is a member
          // This is a simplified approach - in production would cache club/community memberships
          final filteredEvents = <ExpertiseEvent>[];
          for (final event in allEvents) {
            // Check if event belongs to a club where user is member
            try {
              final clubsByCategory = await clubService.getClubsByCategory(event.category);
              final userClubs = clubsByCategory.where((club) => club.isMember(unifiedUser.id) && club.eventIds.contains(event.id)).toList();
              if (userClubs.isNotEmpty) {
                filteredEvents.add(event);
                continue;
              }
            } catch (e) {
              // Ignore errors
            }
            
            // Check if event belongs to a community where user is member
            try {
              final communitiesByCategory = await communityService.getCommunitiesByCategory(event.category);
              final userCommunities = communitiesByCategory.where((community) => community.isMember(unifiedUser.id) && community.eventIds.contains(event.id)).toList();
              if (userCommunities.isNotEmpty) {
                filteredEvents.add(event);
              }
            } catch (e) {
              // Ignore errors
            }
          }
          
          events = filteredEvents;
        } else {
          events = [];
        }
      } else {
        // Load expert events for other scopes
        events = await _eventService.searchEvents(
          category: _selectedCategory,
          location: _selectedLocation,
          eventType: _selectedEventType,
          startDate: _getStartDateFilter(),
          maxResults: 50,
        );
      }
      
      // Integrate with CrossLocalityConnectionService for locality scope
      if (user != null && _selectedScope == EventScope.locality) {
        // Convert User to UnifiedUser for service compatibility
        final unifiedUser = _convertUserToUnifiedUser(user);
        final userLocality = unifiedUser.location != null ? _extractLocality(unifiedUser.location!) : null;
        if (userLocality != null) {
          final connectedLocalities = await _connectionService.getConnectedLocalities(
            user: unifiedUser,
            locality: userLocality,
          );
          
          // Get events from connected localities
          final connectedLocalityNames = connectedLocalities
              .map((c) => c.locality)
              .toSet();
          
          // Load additional events from connected localities
          for (final connectedLocality in connectedLocalityNames) {
            try {
              final connectedEvents = await _eventService.searchEvents(
                location: connectedLocality,
                maxResults: 10,
              );
              events.addAll(connectedEvents);
            } catch (e) {
              // Ignore errors for connected localities
            }
          }
          
          // Track cross-locality events
          _crossLocalityEventIds = connectedLocalityNames
              .expand((locality) => events
                  .where((e) => _extractLocality(e.location)?.toLowerCase() == 
                      locality.toLowerCase())
                  .map((e) => e.id))
              .toSet();
        }
      }
      
      // Sort events by matching score (if user available)
      if (user != null) {
        final unifiedUser = _convertUserToUnifiedUser(user);
        events = await _sortEventsByMatchingScore(events, unifiedUser);
      }
      
      // TODO: Integrate with EventRecommendationService when available (Agent 1 Week 27)
      // - Use getPersonalizedRecommendations() for each tab
      // - Use getRecommendationsForScope() for scope-specific recommendations
      // - Balance familiar preferences with exploration
      
      setState(() {
        _events = events;
        _communityEvents = communityEvents;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  /// Sort events by matching score using EventMatchingService
  /// Convert User to UnifiedUser for service compatibility
  UnifiedUser _convertUserToUnifiedUser(user_model.User user) {
    final now = DateTime.now();
    return UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      photoUrl: null, // User model doesn't have photoUrl
      location: null, // User model doesn't have location - would need to get from profile
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
      hasCompletedOnboarding: true,
      hasReceivedStarterLists: false,
      expertise: null,
      locations: null,
      hostedEventsCount: null,
      differentSpotsCount: null,
      tags: const [],
      expertiseMap: const {},
      friends: const [],
      curatedLists: user.curatedLists,
      collaboratedLists: user.collaboratedLists,
      followedLists: user.followedLists,
      primaryRole: UserRole.follower, // Default role - UserRole from unified_user.dart
      isAgeVerified: false, // User model doesn't have isAgeVerified - would need to get from profile
      ageVerificationDate: null,
    );
  }

  Future<List<ExpertiseEvent>> _sortEventsByMatchingScore(
    List<ExpertiseEvent> events,
    UnifiedUser user,
  ) async {
    try {
      // Calculate matching scores for each event
      final eventScores = <String, double>{};
      
      for (final event in events) {
        try {
          final eventLocality = _extractLocality(event.location) ?? '';
          final score = await _matchingService.calculateMatchingScore(
            expert: event.host,
            user: user,
            category: event.category,
            locality: eventLocality,
          );
          eventScores[event.id] = score;
        } catch (e) {
          // If matching fails, use default score
          eventScores[event.id] = 0.0;
        }
      }
      
      // Sort by matching score (highest first)
      events.sort((a, b) {
        final scoreA = eventScores[a.id] ?? 0.0;
        final scoreB = eventScores[b.id] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });
      
      return events;
    } catch (e) {
      // If sorting fails, return original list
      return events;
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<ExpertiseEvent>.from(_events);
    
    // Apply scope filter (geographic scope from tabs)
    filtered = _filterByScope(filtered);
    
    // Apply search text filter
    final searchText = _searchController.text.toLowerCase().trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((event) {
        final titleMatch = event.title.toLowerCase().contains(searchText);
        final categoryMatch = event.category.toLowerCase().contains(searchText);
        final locationMatch = event.location?.toLowerCase().contains(searchText) ?? false;
        return titleMatch || categoryMatch || locationMatch;
      }).toList();
    }
    
    // Apply price filter
    if (_selectedPriceFilter == 'free') {
      filtered = filtered.where((e) => !e.isPaid).toList();
    } else if (_selectedPriceFilter == 'paid') {
      filtered = filtered.where((e) => e.isPaid).toList();
    }
    
    // Apply date filter
    if (_selectedDateFilter != null && _selectedDateFilter != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((event) {
        if (_selectedDateFilter == 'upcoming') {
          return event.startTime.isAfter(now);
        } else if (_selectedDateFilter == 'this_week') {
          final weekEnd = now.add(const Duration(days: 7));
          return event.startTime.isAfter(now) && event.startTime.isBefore(weekEnd);
        } else if (_selectedDateFilter == 'this_month') {
          final monthEnd = DateTime(now.year, now.month + 1, 1);
          return event.startTime.isAfter(now) && event.startTime.isBefore(monthEnd);
        }
        return true;
      }).toList();
    }
    
    setState(() {
      _filteredEvents = filtered;
    });
  }

  /// Filter events by geographic scope
  List<ExpertiseEvent> _filterByScope(List<ExpertiseEvent> events) {
    // Get current user location
    final currentUser = context.read<AuthBloc>().state;
    final user = currentUser is Authenticated ? currentUser.user : null;
    final unifiedUser = user != null ? _convertUserToUnifiedUser(user) : null;
    final userLocation = unifiedUser?.location;

    if (userLocation == null && _selectedScope != EventScope.universe) {
      // If no user location and not universe scope, return empty
      // (or could show all events - depends on UX decision)
      return events;
    }

    switch (_selectedScope) {
      case EventScope.community:
        // Community events (non-expert events)
        // Return only community events
        return _communityEvents;

      case EventScope.locality:
        // Events in user's locality (including connected localities)
        if (userLocation == null) return [];
        final userLocality = _extractLocality(userLocation);
        if (userLocality == null) return [];
        return events.where((event) {
          if (event.location == null) return false;
          final eventLocality = _extractLocality(event.location!);
          final isInUserLocality = eventLocality?.toLowerCase() == userLocality.toLowerCase();
          // Also include cross-locality events
          final isCrossLocality = _crossLocalityEventIds.contains(event.id);
          return isInUserLocality || isCrossLocality;
        }).toList();

      case EventScope.city:
        // Events in user's city
        if (userLocation == null) return [];
        final userCity = _extractCity(userLocation);
        if (userCity == null) return [];
        return events.where((event) {
          if (event.location == null) return false;
          final eventCity = _extractCity(event.location!);
          return eventCity?.toLowerCase() == userCity.toLowerCase();
        }).toList();

      case EventScope.state:
        // Events in user's state
        if (userLocation == null) return [];
        final userState = _extractState(userLocation);
        if (userState == null) return [];
        return events.where((event) {
          if (event.location == null) return false;
          final eventState = _extractState(event.location!);
          return eventState?.toLowerCase() == userState.toLowerCase();
        }).toList();

      case EventScope.nation:
        // Events in user's nation
        if (userLocation == null) return [];
        final userNation = _extractNation(userLocation);
        if (userNation == null) return [];
        return events.where((event) {
          if (event.location == null) return false;
          final eventNation = _extractNation(event.location!);
          return eventNation?.toLowerCase() == userNation.toLowerCase();
        }).toList();

      case EventScope.globe:
        // All events worldwide (no geographic restriction)
        return events;

      case EventScope.universe:
        // All events (no restrictions)
        return events;

      case EventScope.clubsCommunities:
        // Events from clubs/communities user is part of
        // TODO: Replace with CommunityService and ClubService when Agent 1 creates them
        // For now, return all events (will be filtered by club/community membership later)
        // Future implementation:
        // 1. Get user's clubs/communities from ClubService.getClubsByMember() and CommunityService.getCommunitiesByMember()
        // 2. Get events from those clubs/communities
        // 3. Filter events by club/community membership
        return events;
    }
  }

  /// Extract locality from location string
  /// Location format: "Locality, City, State, Country"
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    return parts.isNotEmpty ? parts[0] : null;
  }

  /// Extract city from location string
  String? _extractCity(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    return parts.length >= 2 ? parts[1] : null;
  }

  /// Extract state from location string
  String? _extractState(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    return parts.length >= 3 ? parts[2] : null;
  }

  /// Extract nation from location string
  String? _extractNation(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    return parts.length >= 4 ? parts[3] : null;
  }

  /// Handle scope tab change
  void _onScopeChanged(EventScope scope) {
    setState(() {
      _selectedScope = scope;
    });
    _applyFilters();
  }

  DateTime? _getStartDateFilter() {
    if (_selectedDateFilter == null || _selectedDateFilter == 'all') {
      return null;
    }
    
    final now = DateTime.now();
    if (_selectedDateFilter == 'upcoming') {
      return now;
    } else if (_selectedDateFilter == 'this_week') {
      return now;
    } else if (_selectedDateFilter == 'this_month') {
      return now;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: AppColors.electricGreen,
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            
            // Scope Tabs
            EventScopeTabWidget(
              initialScope: _selectedScope,
              onTabChanged: _onScopeChanged,
            ),
            
            // Filters
            _buildFilters(),
            
            // Event List
            Expanded(
              child: _buildEventList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search events...',
          hintStyle: TextStyle(color: AppColors.textHint),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        style: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Category Filter
            _buildFilterChip(
              label: _selectedCategory ?? 'All Categories',
              onTap: () => _showCategoryFilter(),
            ),
            const SizedBox(width: 8),
            
            // Location Filter
            _buildFilterChip(
              label: _selectedLocation ?? 'All Locations',
              onTap: () => _showLocationFilter(),
            ),
            const SizedBox(width: 8),
            
            // Date Filter
            _buildFilterChip(
              label: _dateFilters[_selectedDateFilter] ?? _dateFilters['all']!,
              onTap: () => _showDateFilter(),
            ),
            const SizedBox(width: 8),
            
            // Price Filter
            _buildFilterChip(
              label: _priceFilters[_selectedPriceFilter] ?? _priceFilters['all']!,
              onTap: () => _showPriceFilter(),
            ),
            const SizedBox(width: 8),
            
            // Clear Filters
            if (_hasActiveFilters())
              _buildFilterChip(
                label: 'Clear',
                onTap: () => _clearFilters(),
                isClear: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
    bool isClear = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isClear ? AppColors.error.withValues(alpha: 0.1) : AppColors.grey200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isClear 
                ? AppColors.error 
                : (_selectedCategory != null || _selectedLocation != null || 
                    _selectedDateFilter != null || _selectedPriceFilter != null)
                    ? AppTheme.primaryColor
                    : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isClear 
                ? AppColors.error 
                : (_selectedCategory != null || _selectedLocation != null || 
                    _selectedDateFilter != null || _selectedPriceFilter != null)
                    ? AppTheme.primaryColor
                    : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _selectedLocation != null ||
        _selectedDateFilter != null ||
        _selectedPriceFilter != null;
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Categories'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _loadEvents();
                    Navigator.pop(context);
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedCategory == null 
                        ? AppTheme.primaryColor 
                        : AppColors.textPrimary,
                  ),
                ),
                ..._categories.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                      _loadEvents();
                      Navigator.pop(context);
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _selectedCategory == category 
                          ? AppTheme.primaryColor 
                          : AppColors.textPrimary,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationFilter() {
    // For now, show a simple text input
    // In production, this would use location services
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Filter by Location',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter location...',
            hintStyle: TextStyle(color: AppColors.textHint),
          ),
          style: TextStyle(color: AppColors.textPrimary),
          onSubmitted: (value) {
            setState(() {
              _selectedLocation = value.isEmpty ? null : value;
            });
            _loadEvents();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedLocation = null;
              });
              _loadEvents();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._dateFilters.entries.map((entry) {
              return ListTile(
                title: Text(
                  entry.value,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                selected: _selectedDateFilter == entry.key,
                onTap: () {
                  setState(() {
                    _selectedDateFilter = entry.key;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Price',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._priceFilters.entries.map((entry) {
              return ListTile(
                title: Text(
                  entry.value,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                selected: _selectedPriceFilter == entry.key,
                onTap: () {
                  setState(() {
                    _selectedPriceFilter = entry.key;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedLocation = null;
      _selectedDateFilter = null;
      _selectedPriceFilter = null;
      _selectedEventType = null;
      _searchController.clear();
    });
    _loadEvents();
  }

  Widget _buildEventList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters() || _searchController.text.isNotEmpty
                  ? 'Try adjusting your filters'
                  : 'Check back later for new events',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Get current user from AuthBloc
    final currentUser = context.read<AuthBloc>().state;
    final user = currentUser is Authenticated ? currentUser.user : null;
    final unifiedUser = user != null ? _convertUserToUnifiedUser(user) : null;
    
    // Use CommunityEventWidget for community scope, ExpertiseEventWidget for others
    final isCommunityScope = _selectedScope == EventScope.community;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        final isCrossLocality = _crossLocalityEventIds.contains(event.id);
        
        return Column(
          children: [
            // Cross-locality indicator (optional badge)
            if (isCrossLocality && _selectedScope == EventScope.locality)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nearby locality',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // Use CommunityEventWidget for community events, ExpertiseEventWidget for expert events
            if (isCommunityScope)
              CommunityEventWidget(
                event: event,
                currentUser: unifiedUser,
                // TODO: Get upgrade eligibility from CommunityEvent when Agent 1 creates it
                isEligibleForUpgrade: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
              )
            else
              ExpertiseEventWidget(
                event: event,
                currentUser: unifiedUser,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

