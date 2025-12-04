import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/community.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/pages/events/create_community_event_page.dart';
import 'package:spots/presentation/widgets/clubs/expertise_coverage_widget.dart';
import 'package:spots/presentation/widgets/clubs/expansion_timeline_widget.dart';

/// Community Page
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 29)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required - NO direct Colors.* usage)
/// 
/// Features:
/// - Display community information (name, description, founder, members, events, metrics)
/// - Community actions (join/leave, view members, view events, create event)
/// - Philosophy: Show doors (communities) that users can open
class CommunityPage extends StatefulWidget {
  /// Community ID (will be replaced with Community model when available)
  final String communityId;

  const CommunityPage({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final CommunityService _communityService = CommunityService();
  
  bool _isLoading = true;
  bool _isMember = false;
  bool _isJoining = false;
  String? _error;
  Community? _community;

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final community = await _communityService.getCommunityById(widget.communityId);
      
      if (community == null) {
        setState(() {
          _error = 'Community not found';
          _isLoading = false;
        });
        return;
      }
      
      // Check if user is member
      final authState = context.read<AuthBloc>().state;
      bool isMember = false;
      if (authState is Authenticated) {
        isMember = _communityService.isMember(community, authState.user.id);
      }

      setState(() {
        _community = community;
        _isMember = isMember;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load community: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinCommunity() async {
    if (_community == null) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to join communities'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      await _communityService.addMember(_community!, authState.user.id);
      
      // Reload community to get updated data
      await _loadCommunity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully joined community!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to join community: $e';
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveCommunity() async {
    if (_community == null) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      await _communityService.removeMember(_community!, authState.user.id);
      
      // Reload community to get updated data
      await _loadCommunity();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Left community'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to leave community: $e';
        _isJoining = false;
      });
    }
  }

  void _viewMembers() {
    // TODO: Navigate to members page when created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Members page coming soon'),
      ),
    );
  }

  void _viewEvents() {
    // TODO: Navigate to community events page when created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Community events page coming soon'),
      ),
    );
  }

  void _createEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCommunityEventPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _community?.name ?? 'Community',
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading community...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: 'Error loading community',
                          child: Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load community',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadCommunity,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCommunity,
                  color: AppTheme.primaryColor,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth > 600;
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideScreen ? 24.0 : 0.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Section
                                _buildHeaderSection(),
                                
                                // Actions Section
                                _buildActionsSection(),
                                
                                // Information Section
                                _buildInformationSection(),
                                
                                // Metrics Section
                                _buildMetricsSection(),
                                
                                // Geographic Section
                                if (_community != null && (_community!.originalLocality.isNotEmpty || _community!.currentLocalities.isNotEmpty))
                                  _buildGeographicSection(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildHeaderSection() {
    if (_community == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _community!.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_community!.description != null && _community!.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _community!.description!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Founded by ${_community!.founderId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // TODO: Check if founder is golden expert using GoldenExpertAIInfluenceService
                    // if (isFounderGoldenExpert) ...[
                    //   const SizedBox(width: 8),
                    //   GoldenExpertIndicator(
                    //     userId: _community!.founderId,
                    //     locality: _community!.originalLocality.isNotEmpty
                    //         ? _community!.originalLocality
                    //         : null,
                    //     displayStyle: GoldenExpertDisplayStyle.badge,
                    //     size: 16,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: _isMember ? 'Leave community' : 'Join community',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _isJoining
                    ? null
                    : (_isMember ? _leaveCommunity : _joinCommunity),
                icon: _isJoining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Icon(_isMember ? Icons.exit_to_app : Icons.person_add),
                label: Text(_isJoining
                    ? (_isMember ? 'Leaving...' : 'Joining...')
                    : (_isMember ? 'Leave' : 'Join')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMember
                      ? AppColors.grey200
                      : AppTheme.primaryColor,
                  foregroundColor: _isMember
                      ? AppColors.textPrimary
                      : AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: 'View community members',
              button: true,
              child: OutlinedButton.icon(
                onPressed: _viewMembers,
                icon: const Icon(Icons.people),
                label: Text('Members (${_community?.memberCount ?? 0})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.event,
            title: 'Events',
            value: '${_community?.eventCount ?? 0} events',
            onTap: _viewEvents,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.people,
            title: 'Members',
            value: '${_community?.memberCount ?? 0} members',
            onTap: _viewMembers,
          ),
          if (_isMember) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.add_circle,
              title: 'Create Event',
              value: 'Host a community event',
              onTap: _createEvent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: '$title: $value',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Engagement',
                  value: '${((_community?.engagementScore ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Diversity',
                  value: '${((_community?.diversityScore ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.diversity_3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            title: 'Activity Level',
            value: _community?.getActivityLevelDisplayName().toUpperCase() ?? 'ACTIVE',
            icon: Icons.activity,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeographicSection() {
    if (_community == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geographic Coverage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Expertise Coverage Widget (with expansion tracking)
          ExpertiseCoverageWidget(
            originalLocality: _community!.originalLocality,
            currentLocalities: _community!.currentLocalities,
            // TODO: Add coverageData when GeographicExpansionService is available
            coverageData: const {},
            localityCoverage: const {},
          ),
          const SizedBox(height: 24),
          // Expansion Timeline
          ExpansionTimelineWidget(
            originalLocality: _community!.originalLocality,
            // TODO: Add expansion history when GeographicExpansionService is available
            expansionHistory: const [],
            coverageMilestones: const [],
            eventsByLocality: const {},
            commutePatterns: const {},
            coverageOverTime: const {},
          ),
          const SizedBox(height: 24),
          // Expansion Progress Summary
          _buildExpansionProgressSummary(),
        ],
      ),
    );
  }

  Widget _buildExpansionProgressSummary() {
    if (_community == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Expansion Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationCard(
            icon: Icons.location_on,
            title: 'Original Locality',
            value: _community!.originalLocality,
          ),
          if (_community!.currentLocalities.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildLocationCard(
              icon: Icons.map,
              title: 'Current Localities',
              value: _community!.currentLocalities.join(', '),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active in ${_community!.currentLocalities.length} locality(ies)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

