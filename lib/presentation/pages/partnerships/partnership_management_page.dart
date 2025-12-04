import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/partnerships/partnership_card.dart';
import 'package:spots/presentation/widgets/partnerships/compatibility_badge.dart';
import 'package:get_it/get_it.dart';

/// Partnership Management Page
/// 
/// View and manage active, pending, and completed partnerships.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipManagementPage extends StatefulWidget {
  const PartnershipManagementPage({super.key});

  @override
  State<PartnershipManagementPage> createState() => _PartnershipManagementPageState();
}

class _PartnershipManagementPageState extends State<PartnershipManagementPage> with SingleTickerProviderStateMixin {
  final _partnershipService = GetIt.instance<PartnershipService>();
  final _eventService = GetIt.instance<ExpertiseEventService>();
  
  late TabController _tabController;
  bool _isLoading = false;
  List<EventPartnership> _allPartnerships = [];
  Map<String, ExpertiseEvent> _events = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPartnerships();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerships() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in');
      }

      // Get all partnerships for the user
      // Note: In production, this would be a service method like getUserPartnerships()
      // For now, we'll get partnerships by event and filter by userId
      final allPartnerships = <EventPartnership>[];
      final eventIds = <String>{};

      // Get partnerships for user's events
      // This is a simplified approach - in production, there would be a direct method
      for (final partnership in await _getAllUserPartnerships(authState.user.id)) {
        allPartnerships.add(partnership);
        eventIds.add(partnership.eventId);
      }

      // Load events
      final events = <String, ExpertiseEvent>{};
      for (final eventId in eventIds) {
        final event = await _eventService.getEventById(eventId);
        if (event != null) {
          events[eventId] = event;
        }
      }

      setState(() {
        _allPartnerships = allPartnerships;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading partnerships: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Helper method to get all partnerships for a user
  // In production, this would be a service method like getUserPartnerships()
  // For now, we'll use a workaround by getting partnerships for events the user hosts
  Future<List<EventPartnership>> _getAllUserPartnerships(String userId) async {
    try {
      // Get user's events first
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        return [];
      }
      
      // Create UnifiedUser for getEventsByHost
      final user = UnifiedUser(
        id: userId,
        email: authState.user.email,
        displayName: authState.user.displayName ?? authState.user.name,
        createdAt: authState.user.createdAt,
        updatedAt: authState.user.updatedAt,
        isOnline: authState.user.isOnline ?? false,
      );
      
      final userEvents = await _eventService.getEventsByHost(user);
      final allPartnerships = <EventPartnership>[];
      
      // Get partnerships for each event
      for (final event in userEvents) {
        final partnerships = await _partnershipService.getPartnershipsForEvent(event.id);
        allPartnerships.addAll(partnerships);
      }
      
      return allPartnerships;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  List<EventPartnership> _getPartnershipsByStatus(PartnershipStatus status) {
    return _allPartnerships.where((p) => p.status == status).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<EventPartnership> _getActivePartnerships() {
    return _allPartnerships.where((p) => 
      p.status == PartnershipStatus.active ||
      p.status == PartnershipStatus.locked ||
      p.status == PartnershipStatus.approved
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<EventPartnership> _getPendingPartnerships() {
    return _allPartnerships.where((p) => 
      p.status == PartnershipStatus.pending ||
      p.status == PartnershipStatus.proposed ||
      p.status == PartnershipStatus.negotiating
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<EventPartnership> _getCompletedPartnerships() {
    return _allPartnerships.where((p) => 
      p.status == PartnershipStatus.completed ||
      p.status == PartnershipStatus.cancelled
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _viewPartnershipDetails(EventPartnership partnership) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnershipDetailsPage(partnership: partnership),
      ),
    );
  }

  void _managePartnership(EventPartnership partnership) {
    // Show management options
    showModalBottomSheet(
      context: context,
      builder: (context) => PartnershipManagementSheet(
        partnership: partnership,
        onUpdate: () {
          Navigator.pop(context);
          _loadPartnerships();
        },
        onCancel: () {
          Navigator.pop(context);
          _loadPartnerships();
        },
      ),
    );
  }

  void _createNewPartnership() {
    // Navigate to event selection or directly to proposal page
    // For now, show a message - in production, would navigate to event selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select an event first, then propose a partnership'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Partnerships',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPartnershipsList(_getActivePartnerships(), 'Active'),
                _buildPartnershipsList(_getPendingPartnerships(), 'Pending'),
                _buildPartnershipsList(_getCompletedPartnerships(), 'Completed'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPartnership,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Partnership'),
      ),
    );
  }

  Widget _buildPartnershipsList(List<EventPartnership> partnerships, String statusLabel) {
    if (partnerships.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $statusLabel.toLowerCase() partnerships',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a partnership to get started',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: partnerships.length,
      itemBuilder: (context, index) {
        final partnership = partnerships[index];
        final event = _events[partnership.eventId];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PartnershipCard(
            partnership: partnership,
            event: event,
            onTap: () => _viewPartnershipDetails(partnership),
            onManage: () => _managePartnership(partnership),
            showActions: true,
          ),
        );
      },
    );
  }
}

/// Partnership Details Page
/// 
/// Shows detailed information about a partnership.
class PartnershipDetailsPage extends StatelessWidget {
  final EventPartnership partnership;

  const PartnershipDetailsPage({
    super.key,
    required this.partnership,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Partnership Details',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: partnership.business?.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  partnership.business!.logoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.business,
                                color: AppTheme.primaryColor,
                                size: 32,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partnership.business?.name ?? 'Business',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (partnership.vibeCompatibilityScore != null) ...[
                              const SizedBox(height: 8),
                              CompatibilityBadge(
                                compatibility: partnership.vibeCompatibilityScore!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partnership Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        partnership.status.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Agreement Terms
              if (partnership.agreement != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partnership Terms',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (partnership.agreement!.terms['revenueSplit'] != null) ...[
                          Text(
                            'Revenue Split: ${partnership.agreement!.terms['revenueSplit']['userPercentage'].toStringAsFixed(0)}% / ${partnership.agreement!.terms['revenueSplit']['businessPercentage'].toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (partnership.sharedResponsibilities.isNotEmpty) ...[
                          Text(
                            'Responsibilities:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...partnership.sharedResponsibilities.map((resp) => Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.check, size: 16, color: AppColors.electricGreen),
                                    const SizedBox(width: 8),
                                    Text(
                                      resp,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Partnership Management Sheet
/// 
/// Bottom sheet for managing partnerships.
class PartnershipManagementSheet extends StatelessWidget {
  final EventPartnership partnership;
  final VoidCallback onUpdate;
  final VoidCallback onCancel;

  const PartnershipManagementSheet({
    super.key,
    required this.partnership,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Partnership',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.edit, color: AppTheme.primaryColor),
            title: const Text('Update Agreement'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to update agreement page
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel, color: AppColors.error),
            title: const Text('Cancel Partnership'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Partnership?'),
                  content: const Text('Are you sure you want to cancel this partnership?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Yes, Cancel'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                onCancel();
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

