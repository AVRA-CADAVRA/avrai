import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/club.dart';
import 'package:spots/core/models/club_hierarchy.dart';
import 'package:spots/core/services/club_service.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/pages/events/create_community_event_page.dart';
import 'package:spots/presentation/widgets/clubs/expertise_coverage_widget.dart';
import 'package:spots/presentation/widgets/clubs/expansion_timeline_widget.dart';
import 'package:spots/presentation/widgets/golden_expert_indicator.dart';
import 'package:spots/presentation/widgets/boundaries/border_visualization_widget.dart';
import 'package:spots/presentation/widgets/boundaries/border_management_widget.dart';

/// Club Page
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 29)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required - NO direct Colors.* usage)
/// 
/// Features:
/// - Display club information (name, description, leaders, admins, members, events, metrics)
/// - Club actions (join/leave, view members, view events, create event, manage members/roles)
/// - Organizational structure display (hierarchy, roles, permissions)
/// - Philosophy: Show doors (clubs) that users can open
class ClubPage extends StatefulWidget {
  /// Club ID (will be replaced with Club model when available)
  final String clubId;

  const ClubPage({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  final ClubService _clubService = ClubService();
  final CommunityService _communityService = CommunityService();
  
  bool _isLoading = true;
  bool _isMember = false;
  bool _isLeader = false;
  bool _isAdmin = false;
  bool _isJoining = false;
  String? _error;
  Club? _club;
  ClubRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  Future<void> _loadClub() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final club = await _clubService.getClubById(widget.clubId);
      
      if (club == null) {
        setState(() {
          _error = 'Club not found';
          _isLoading = false;
        });
        return;
      }
      
      // Check if user is member/leader/admin
      final authState = context.read<AuthBloc>().state;
      bool isMember = false;
      bool isLeader = false;
      bool isAdmin = false;
      ClubRole? userRole;
      
      if (authState is Authenticated) {
        final userId = authState.user.id;
        isMember = club.isMember(userId);
        isLeader = _clubService.isLeader(club, userId);
        isAdmin = _clubService.isAdmin(club, userId);
        userRole = _clubService.getMemberRole(club, userId);
      }

      setState(() {
        _club = club;
        _isMember = isMember;
        _isLeader = isLeader;
        _isAdmin = isAdmin;
        _userRole = userRole;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load club: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinClub() async {
    if (_club == null) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to join clubs'),
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
      // Use CommunityService to add member (Club extends Community)
      await _communityService.addMember(_club!, authState.user.id);
      
      // Reload club to get updated data
      await _loadClub();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully joined club!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to join club: $e';
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

  Future<void> _leaveClub() async {
    if (_club == null) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      // Use CommunityService to remove member (Club extends Community)
      await _communityService.removeMember(_club!, authState.user.id);
      
      // Reload club to get updated data
      await _loadClub();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Left club'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to leave club: $e';
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
    // TODO: Navigate to club events page when created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Club events page coming soon'),
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

  void _manageMembers() {
    // TODO: Navigate to member management page when created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Member management page coming soon'),
      ),
    );
  }

  bool _hasPermission(String permission) {
    if (_club == null) return false;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return false;
    
    return _clubService.hasPermission(_club!, authState.user.id, permission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _club?.name ?? 'Club',
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (_isLeader || _isAdmin)
            Semantics(
              label: 'Manage club settings',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _manageMembers,
                tooltip: 'Manage Club',
              ),
            ),
        ],
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
                    'Loading club...',
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
                          label: 'Error loading club',
                          child: Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load club',
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
                          onPressed: _loadClub,
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
                  onRefresh: _loadClub,
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
                                
                                // Organizational Structure Section
                                _buildOrganizationalStructureSection(),
                                
                                // Information Section
                                _buildInformationSection(),
                                
                                // Metrics Section
                                _buildMetricsSection(),
                                
                                // Expertise Coverage Section (prepared for Week 30)
                                if (_club != null && (_club!.originalLocality.isNotEmpty || _club!.currentLocalities.isNotEmpty))
                                  _buildExpertiseCoverageSection(),
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
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _club?.name ?? 'Club',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Text(
                  'CLUB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (_club?.description != null && _club!.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _club!.description!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (_userRole != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Your Role: ${_userRole!.getDisplayName()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
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
              label: _isMember ? 'Leave club' : 'Join club',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _isJoining
                    ? null
                    : (_isMember ? _leaveClub : _joinClub),
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
              label: 'View club members',
              button: true,
              child: OutlinedButton.icon(
                onPressed: _viewMembers,
                icon: const Icon(Icons.people),
                label: Text('Members (${_club?.memberCount ?? 0})'),
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

  Widget _buildOrganizationalStructureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizational Structure',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_club != null) ...[
            if (_club!.leaders.isNotEmpty)
              _buildRoleSection(
                title: 'Leaders',
                memberIds: _club!.leaders,
                icon: Icons.star,
                color: AppTheme.primaryColor,
              ),
            if (_club!.adminTeam.isNotEmpty) ...[
              if (_club!.leaders.isNotEmpty) const SizedBox(height: 12),
              _buildRoleSection(
                title: 'Admins',
                memberIds: _club!.adminTeam,
                icon: Icons.admin_panel_settings,
                color: AppColors.textSecondary,
              ),
            ],
            if (_club!.memberCount > 0) ...[
              const SizedBox(height: 12),
              _buildRoleSection(
                title: 'Members',
                memberIds: _club!.memberIds.take(10).toList(), // Show first 10
                icon: Icons.people,
                color: AppColors.textSecondary,
                showCount: true,
                totalCount: _club!.memberCount,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRoleSection({
    required String title,
    required List<String> memberIds,
    required IconData icon,
    required Color color,
    bool showCount = false,
    int? totalCount,
  }) {
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (showCount && totalCount != null) ...[
                const SizedBox(width: 8),
                Text(
                  '($totalCount)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (memberIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: memberIds.take(10).map((memberId) {
                // TODO: Load member names from user service
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'User ${memberId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else
            Text(
              'No $title',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
            value: '${_club?.eventCount ?? 0} events',
            onTap: _viewEvents,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.people,
            title: 'Members',
            value: '${_club?.memberCount ?? 0} members',
            onTap: _viewMembers,
          ),
          if (_isMember && _hasPermission('canCreateEvents')) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.add_circle,
              title: 'Create Event',
              value: 'Host a club event',
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
                  title: 'Maturity',
                  value: '${((_club?.organizationalMaturity ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Stability',
                  value: '${((_club?.leadershipStability ?? 0.0) * 100).toStringAsFixed(0)}%',
                  icon: Icons.verified,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            title: 'Engagement',
            value: '${((_club?.engagementScore ?? 0.0) * 100).toStringAsFixed(0)}%',
            icon: Icons.favorite,
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

  Widget _buildExpertiseCoverageSection() {
    if (_club == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expertise Coverage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ExpertiseCoverageWidget(
            originalLocality: _club!.originalLocality,
            currentLocalities: _club!.currentLocalities,
            coverageData: _club!.coveragePercentage,
            // TODO: Add localityCoverage when GeographicExpansionService is available
            localityCoverage: const {},
          ),
          const SizedBox(height: 24),
          // Expansion Timeline
          ExpansionTimelineWidget(
            originalLocality: _club!.originalLocality,
            // TODO: Add expansion history when GeographicExpansionService is available
            expansionHistory: const [],
            coverageMilestones: const [],
            eventsByLocality: const {},
            commutePatterns: const {},
            coverageOverTime: const {},
          ),
          const SizedBox(height: 24),
          // Border Visualization (Week 32 - Neighborhood Boundaries)
          if (_club!.originalLocality.isNotEmpty || _club!.currentLocalities.isNotEmpty)
            _buildBorderVisualizationSection(),
          const SizedBox(height: 24),
          // Leader Expertise Display
          if (_club!.leaders.isNotEmpty) _buildLeaderExpertiseSection(),
        ],
      ),
    );
  }

  Widget _buildBorderVisualizationSection() {
    if (_club == null) return const SizedBox.shrink();
    
    // Get city from locality (simplified - in production, extract from locality data)
    final city = _club!.originalLocality.isNotEmpty 
        ? _extractCityFromLocality(_club!.originalLocality)
        : 'New York'; // Default
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neighborhood Boundaries',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'View boundaries between localities to understand community connections',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Border Visualization Widget
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BorderVisualizationWidget(
              city: city,
              locality: _club!.originalLocality.isNotEmpty 
                  ? _club!.originalLocality 
                  : null,
              showSoftBorderSpots: true,
              showRefinementIndicators: true,
              onBorderTapped: (locality1, locality2) {
                // Show border management dialog
                _showBorderManagementDialog(context, locality1, locality2, city);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _extractCityFromLocality(String locality) {
    // Simplified extraction - in production, use geographic hierarchy service
    // For now, return common cities based on locality patterns
    final lowerLocality = locality.toLowerCase();
    if (lowerLocality.contains('brooklyn') || 
        lowerLocality.contains('manhattan') ||
        lowerLocality.contains('queens') ||
        lowerLocality.contains('bronx')) {
      return 'New York';
    }
    if (lowerLocality.contains('hollywood') ||
        lowerLocality.contains('santa monica') ||
        lowerLocality.contains('venice')) {
      return 'Los Angeles';
    }
    if (lowerLocality.contains('loop') ||
        lowerLocality.contains('river north') ||
        lowerLocality.contains('wicker park')) {
      return 'Chicago';
    }
    return 'New York'; // Default
  }

  void _showBorderManagementDialog(
    BuildContext context,
    String locality1,
    String locality2,
    String city,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Border: $locality1 / $locality2',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Border Management Widget
              Expanded(
                child: BorderManagementWidget(
                  locality1: locality1,
                  locality2: locality2,
                  city: city,
                  showRefinementHistory: true,
                  showSoftBorderSpots: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderExpertiseSection() {
    if (_club == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leader Expertise',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._club!.leaders.map((leaderId) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLeaderExpertiseCard(leaderId: leaderId),
          );
        }),
      ],
    );
  }

  Widget _buildLeaderExpertiseCard({required String leaderId}) {
    // TODO: Load leader expertise from ClubService when available
    // TODO: Check if leader is golden expert using GoldenExpertAIInfluenceService
    // For now, show placeholder with golden expert indicator support
    final isGoldenExpert = false; // TODO: Check golden expert status
    final locality = _club?.originalLocality; // TODO: Get leader's locality
    
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Leader ${leaderId.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isGoldenExpert && locality != null) ...[
                          const SizedBox(width: 8),
                          GoldenExpertIndicator(
                            userId: leaderId,
                            locality: locality,
                            displayStyle: GoldenExpertDisplayStyle.badge,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expertise gained through club expansion',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TODO: Show actual expertise levels when available
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Expertise in ${_club!.currentLocalities.length} locality(ies)',
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
      ),
    );
  }
}

