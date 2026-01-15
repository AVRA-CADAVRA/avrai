// Group Formation Page
//
// UI for group formation with proximity detection and manual friend selection
// Part of Phase 19.18: Quantum Group Matching System
// Section GM.5: Group Formation UI
//
// **Features:**
// - Nearby users discovery (proximity-based)
// - Manual friend selection
// - Selected members list
// - Group formation with validation

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/blocs/group_matching_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/services/group_formation_service.dart';
import 'package:go_router/go_router.dart';

/// Group Formation Page
///
/// Allows users to form groups via:
/// - Proximity detection (nearby SPOTS users)
/// - Manual friend selection
/// - Hybrid approach (both)
class GroupFormationPage extends StatefulWidget {
  const GroupFormationPage({super.key});

  @override
  State<GroupFormationPage> createState() => _GroupFormationPageState();
}

class _GroupFormationPageState extends State<GroupFormationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Group'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Nearby', icon: Icon(Icons.location_on)),
            Tab(text: 'Friends', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const Center(
              child: Text('Please sign in to form groups'),
            );
          }

          final currentUser = authState.user;
          final currentUserId = currentUser.id;

          return BlocConsumer<GroupMatchingBloc, GroupMatchingState>(
            listener: (context, state) {
              if (state is GroupFormed) {
                // Navigate to group results page
                context.go('/group/results/${state.session.sessionId}');
              } else if (state is GroupMatchingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              // Initialize if needed
              if (state is GroupMatchingInitial) {
                context.read<GroupMatchingBloc>().add(
                      StartGroupFormation(currentUserId: currentUserId),
                    );
              }

              if (state is GroupMatchingLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (state is GroupFormationInProgress) {
                return Column(
                  children: [
                    // Selected Members Section
                    _buildSelectedMembersSection(context, state),

                    // Tab View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Nearby Users Tab
                          _buildNearbyUsersTab(context, state, currentUserId),

                          // Friends Tab
                          _buildFriendsTab(context, state, currentUserId),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (state is GroupMatchingError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<GroupMatchingBloc>().add(
                                StartGroupFormation(
                                    currentUserId: currentUserId),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return const Center(child: Text('Unknown state'));
            },
          );
        },
      ),
    );
  }

  /// Build selected members section
  Widget _buildSelectedMembersSection(
    BuildContext context,
    GroupFormationInProgress state,
  ) {
    final selectedCount = state.totalSelectedMembers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Members ($selectedCount)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (selectedCount >= 2)
                ElevatedButton.icon(
                  onPressed: () {
                    // Form group and proceed to matching
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      context.read<GroupMatchingBloc>().add(
                            FormGroup(
                              currentUserId: authState.user.id,
                              nearbyUsers: state.nearbyUsers
                                  .where((u) => state.selectedMemberAgentIds
                                      .contains(u.agentId))
                                  .toList(),
                              friendAgentIds: state.selectedMemberAgentIds
                                  .where(
                                      (id) => state.friendAgentIds.contains(id))
                                  .toList(),
                            ),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Find Spots'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedCount == 1)
            Text(
              'Add at least one more member to form a group',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else if (selectedCount > 1)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Current user (always included)
                _buildMemberChip(
                  context,
                  label: 'You',
                  isCurrentUser: true,
                ),
                // Selected members
                ...state.selectedMemberAgentIds.map(
                  (agentId) {
                    // Try to find display name from nearby users or friends
                    final nearbyUser = state.nearbyUsers.firstWhere(
                      (u) => u.agentId == agentId,
                      orElse: () => state.nearbyUsers.first,
                    );
                    final displayName = nearbyUser.deviceName;

                    return _buildMemberChip(
                      context,
                      label: displayName,
                      agentId: agentId,
                      onRemove: () {
                        context.read<GroupMatchingBloc>().add(
                              RemoveMember(agentId: agentId),
                            );
                      },
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build member chip
  Widget _buildMemberChip(
    BuildContext context, {
    required String label,
    String? agentId,
    bool isCurrentUser = false,
    VoidCallback? onRemove,
  }) {
    return Chip(
      label: Text(label),
      avatar: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: Icon(
          isCurrentUser ? Icons.person : Icons.person_outline,
          size: 18,
          color: AppColors.primary,
        ),
      ),
      deleteIcon: isCurrentUser
          ? null
          : Icon(
              Icons.close,
              size: 18,
              color: AppColors.textSecondary,
            ),
      onDeleted: isCurrentUser ? null : onRemove,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }

  /// Build nearby users tab
  Widget _buildNearbyUsersTab(
    BuildContext context,
    GroupFormationInProgress state,
    String currentUserId,
  ) {
    final nearbyUsers = state.nearbyUsers;
    final selectedAgentIds = state.selectedMemberAgentIds;

    if (nearbyUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No nearby users found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure Bluetooth is enabled and other users have avrai open',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<GroupMatchingBloc>().add(
                      DiscoverNearbyUsers(currentUserId: currentUserId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GroupMatchingBloc>().add(
              DiscoverNearbyUsers(currentUserId: currentUserId),
            );
        // Wait a bit for the state to update
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: nearbyUsers.length,
        itemBuilder: (context, index) {
          final user = nearbyUsers[index];
          final isSelected = selectedAgentIds.contains(user.agentId);

          return _buildUserCard(
            context,
            user: user,
            isSelected: isSelected,
            onTap: () {
              if (isSelected) {
                context.read<GroupMatchingBloc>().add(
                      RemoveMember(agentId: user.agentId),
                    );
              } else {
                context.read<GroupMatchingBloc>().add(
                      AddNearbyUser(user: user),
                    );
              }
            },
            showCompatibility: true,
          );
        },
      ),
    );
  }

  /// Build friends tab
  Widget _buildFriendsTab(
    BuildContext context,
    GroupFormationInProgress state,
    String currentUserId,
  ) {
    final friendAgentIds = state.friendAgentIds;
    final selectedAgentIds = state.selectedMemberAgentIds;

    // Filter friends by search query
    final filteredFriends = friendAgentIds.where((agentId) {
      if (_searchQuery.isEmpty) return true;
      // For now, just check if agentId contains query (in real app, would use display names)
      return agentId.toLowerCase().contains(_searchQuery);
    }).toList();

    if (friendAgentIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No friends found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with friends through social media to see them here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<GroupMatchingBloc>().add(
                      LoadFriendsList(currentUserId: currentUserId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search friends...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Friends list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredFriends.length,
            itemBuilder: (context, index) {
              final agentId = filteredFriends[index];
              final isSelected = selectedAgentIds.contains(agentId);

              return _buildFriendCard(
                context,
                agentId: agentId,
                isSelected: isSelected,
                onTap: () {
                  if (isSelected) {
                    context.read<GroupMatchingBloc>().add(
                          RemoveMember(agentId: agentId),
                        );
                  } else {
                    context.read<GroupMatchingBloc>().add(
                          AddFriend(friendAgentId: agentId),
                        );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build user card (for nearby users)
  Widget _buildUserCard(
    BuildContext context, {
    required DiscoveredUser user,
    required bool isSelected,
    required VoidCallback onTap,
    bool showCompatibility = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.grey300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.deviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (showCompatibility &&
                        user.compatibilityScore != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(user.compatibilityScore! * 100).toStringAsFixed(0)}% match',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                    if (user.signalStrength != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_alt,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nearby',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Selection indicator
              Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected ? AppColors.primary : AppColors.grey400,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build friend card
  Widget _buildFriendCard(
    BuildContext context, {
    required String agentId,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.grey300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Friend info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Friend', // TODO: Get actual friend name from agentId
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${agentId.substring(0, 8)}...', // Truncated agentId for privacy
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected ? AppColors.primary : AppColors.grey400,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
