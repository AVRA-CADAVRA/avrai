import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/pages/admin/club_detail_page.dart';
import 'package:intl/intl.dart';

/// Clubs/Communities Viewer Page
/// View clubs and communities with member AI agent information
class ClubsCommunitiesViewerPage extends StatefulWidget {
  final AdminGodModeService? godModeService;
  
  const ClubsCommunitiesViewerPage({
    super.key,
    this.godModeService,
  });

  @override
  State<ClubsCommunitiesViewerPage> createState() => _ClubsCommunitiesViewerPageState();
}

class _ClubsCommunitiesViewerPageState extends State<ClubsCommunitiesViewerPage> {
  List<ClubCommunityData> _clubsCommunities = [];
  List<ClubCommunityData> _filteredClubsCommunities = [];
  bool _isLoading = true;
  
  // Filter state
  final TextEditingController _memberFilterController = TextEditingController();
  bool _showOnlyWithFollowing = false;
  int _minFollowers = 1;
  String? _selectedCategory;
  
  // Following data
  Map<String, int> _usersWithFollowing = {};

  @override
  void initState() {
    super.initState();
    _loadClubsCommunities();
    _loadUsersWithFollowing();
    _memberFilterController.addListener(_applyFilters);
  }
  
  @override
  void dispose() {
    _memberFilterController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsersWithFollowing() async {
    if (widget.godModeService == null) return;
    
    try {
      final usersWithFollowing = await widget.godModeService!.getUsersWithFollowing(
        minFollowers: _minFollowers,
      );
      setState(() {
        _usersWithFollowing = usersWithFollowing;
      });
    } catch (e) {
      // Silently fail - filtering will just not work
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredClubsCommunities = _clubsCommunities.where((item) {
        // Category filter
        if (_selectedCategory != null && item.category != _selectedCategory) {
          return false;
        }
        
        // Member filter (search by member ID or AI signature)
        if (_memberFilterController.text.isNotEmpty) {
          final searchTerm = _memberFilterController.text.toLowerCase();
          final hasMatchingMember = item.memberAIAgents.keys.any((memberId) {
            final aiSignature = item.memberAIAgents[memberId]?['ai_signature']?.toString().toLowerCase();
            return memberId.toLowerCase().contains(searchTerm) ||
                   (aiSignature != null && aiSignature.contains(searchTerm));
          });
          if (!hasMatchingMember) {
            return false;
          }
        }
        
        // Following filter
        if (_showOnlyWithFollowing) {
          final hasMemberWithFollowing = item.memberAIAgents.keys.any((memberId) {
            return _usersWithFollowing.containsKey(memberId);
          });
          if (!hasMemberWithFollowing) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  Future<void> _loadClubsCommunities() async {
    if (widget.godModeService == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await widget.godModeService!.getAllClubsAndCommunities();
      setState(() {
        _clubsCommunities = data;
        _filteredClubsCommunities = data;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clubs/communities: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Clubs & Communities',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadClubsCommunities,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.privacy_tip, color: AppColors.electricGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Privacy: AI Signatures and location data (vibe indicators) are visible. No personal data (name, email, phone, home address) is displayed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey700,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Filters
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              
              // Member search
              TextField(
                controller: _memberFilterController,
                decoration: InputDecoration(
                  hintText: 'Search by member ID or AI signature...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _memberFilterController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _memberFilterController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Following filter
              Row(
                children: [
                  Checkbox(
                    value: _showOnlyWithFollowing,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyWithFollowing = value ?? false;
                      });
                      _applyFilters();
                    },
                  ),
                  Expanded(
                    child: Text('Only show clubs/communities with members who have a following'),
                  ),
                ],
              ),
              
              // Category filter
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ..._clubsCommunities.map((item) => item.category).toSet().map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredClubsCommunities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group,
                            size: 64,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No clubs or communities found',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.grey500,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadClubsCommunities,
                      child: ListView.builder(
                        itemCount: _filteredClubsCommunities.length,
                        itemBuilder: (context, index) {
                          final item = _filteredClubsCommunities[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item.isClub
                                    ? AppColors.grey600.withValues(alpha: 0.2)
                                    : AppColors.electricGreen.withValues(alpha: 0.2),
                                child: Icon(
                                  item.isClub ? Icons.group : Icons.people,
                                  color: item.isClub ? AppColors.grey600 : AppColors.electricGreen,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.description != null)
                                    Text(
                                      item.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          item.isClub ? 'Club' : 'Community',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          item.category,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.memberCount} members • ${item.eventCount} events',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (item.lastEventAt != null)
                                    Text(
                                      'Last event: ${DateFormat('MMM d, y').format(item.lastEventAt!)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClubDetailPage(
                                      clubCommunityId: item.id,
                                      godModeService: widget.godModeService,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

