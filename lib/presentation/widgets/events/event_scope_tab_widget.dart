import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Event Scope Tab Widget
/// 
/// Provides tab-based filtering for events by geographic scope:
/// - Community (non-expert events)
/// - Locality (neighborhood-level)
/// - City
/// - State
/// - Nation
/// - Globe (worldwide)
/// - Universe (all events)
/// - Clubs/Communities
/// 
/// **Design:** Uses AppColors/AppTheme (100% adherence required)
/// **Pattern:** Follows existing tab implementations (e.g., my_events_page.dart)
class EventScopeTabWidget extends StatefulWidget {
  /// Callback when tab changes
  final ValueChanged<EventScope> onTabChanged;

  /// Initial selected scope
  final EventScope? initialScope;

  const EventScopeTabWidget({
    super.key,
    required this.onTabChanged,
    this.initialScope,
  });

  @override
  State<EventScopeTabWidget> createState() => _EventScopeTabWidgetState();
}

class _EventScopeTabWidgetState extends State<EventScopeTabWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventScope _selectedScope;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope ?? EventScope.locality;
    _tabController = TabController(
      length: EventScope.values.length,
      vsync: this,
      initialIndex: EventScope.values.indexOf(_selectedScope),
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final newScope = EventScope.values[_tabController.index];
      if (newScope != _selectedScope) {
        setState(() {
          _selectedScope = newScope;
        });
        widget.onTabChanged(newScope);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 2,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: EventScope.values.map((scope) {
          return Tab(
            text: scope.displayName,
            icon: Icon(scope.icon),
          );
        }).toList(),
      ),
    );
  }
}

/// Event Scope Enum
/// Represents the geographic scope for event filtering
enum EventScope {
  community,
  locality,
  city,
  state,
  nation,
  globe,
  universe,
  clubsCommunities;

  /// Display name for the scope
  String get displayName {
    switch (this) {
      case EventScope.community:
        return 'Community';
      case EventScope.locality:
        return 'Locality';
      case EventScope.city:
        return 'City';
      case EventScope.state:
        return 'State';
      case EventScope.nation:
        return 'Nation';
      case EventScope.globe:
        return 'Globe';
      case EventScope.universe:
        return 'Universe';
      case EventScope.clubsCommunities:
        return 'Clubs';
    }
  }

  /// Icon for the scope
  IconData get icon {
    switch (this) {
      case EventScope.community:
        return Icons.people;
      case EventScope.locality:
        return Icons.location_on;
      case EventScope.city:
        return Icons.location_city;
      case EventScope.state:
        return Icons.map;
      case EventScope.nation:
        return Icons.public;
      case EventScope.globe:
        return Icons.language;
      case EventScope.universe:
        return Icons.explore;
      case EventScope.clubsCommunities:
        return Icons.group;
    }
  }

  /// Description for the scope
  String get description {
    switch (this) {
      case EventScope.community:
        return 'Community-organized events';
      case EventScope.locality:
        return 'Events in your neighborhood';
      case EventScope.city:
        return 'Events in your city';
      case EventScope.state:
        return 'Events in your state/region';
      case EventScope.nation:
        return 'Events in your country';
      case EventScope.globe:
        return 'Events worldwide';
      case EventScope.universe:
        return 'All events (no restrictions)';
      case EventScope.clubsCommunities:
        return 'Events from your clubs/communities';
    }
  }
}

