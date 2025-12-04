import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:intl/intl.dart';

/// Club/Community Detail Page
/// View detailed information about a club/community and its members with AI agents
class ClubDetailPage extends StatefulWidget {
  final String clubCommunityId;
  final AdminGodModeService? godModeService;
  
  const ClubDetailPage({
    super.key,
    required this.clubCommunityId,
    this.godModeService,
  });

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  ClubCommunityData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubCommunity();
  }

  Future<void> _loadClubCommunity() async {
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
      final data = await widget.godModeService!.getClubOrCommunityById(
        widget.clubCommunityId,
      );
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading club/community: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_data?.name ?? 'Club/Community Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClubCommunity,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.grey500),
                      const SizedBox(height: 16),
                      Text(
                        'Club/Community not found',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey500,
                            ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: _data!.isClub
                                        ? AppColors.grey600.withValues(alpha: 0.2)
                                        : AppColors.electricGreen.withValues(alpha: 0.2),
                                    child: Icon(
                                      _data!.isClub ? Icons.group : Icons.people,
                                      color: _data!.isClub ? AppColors.grey600 : AppColors.electricGreen,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _data!.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                _data!.isClub ? 'Club' : 'Community',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            const SizedBox(width: 8),
                                            Chip(
                                              label: Text(
                                                _data!.category,
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_data!.description != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _data!.description!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildStatChip(
                                    Icons.people,
                                    '${_data!.memberCount}',
                                    'Members',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatChip(
                                    Icons.event,
                                    '${_data!.eventCount}',
                                    'Events',
                                  ),
                                ],
                              ),
                              if (_data!.lastEventAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Last event: ${DateFormat('MMM d, y').format(_data!.lastEventAt!)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey500
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Leaders/Admins Section (for clubs)
                      if (_data!.isClub && _data!.leaders != null && _data!.leaders!.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leaders',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _data!.leaders!.map((leaderId) {
                                    final aiAgent = _data!.memberAIAgents[leaderId];
                                    return Chip(
                                      avatar: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.grey600.withValues(alpha: 0.2),
                                        child: const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      label: Text(
                                        aiAgent?['ai_signature']?.toString().substring(0, 12) ?? leaderId.substring(0, 12),
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      if (_data!.isClub && _data!.adminTeam != null && _data!.adminTeam!.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Team',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _data!.adminTeam!.map((adminId) {
                                    final aiAgent = _data!.memberAIAgents[adminId];
                                    return Chip(
                                      avatar: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.electricGreen.withValues(alpha: 0.2),
                                        child: const Icon(
                                          Icons.admin_panel_settings,
                                          size: 14,
                                          color: AppColors.electricGreen,
                                        ),
                                      ),
                                      label: Text(
                                        aiAgent?['ai_signature']?.toString().substring(0, 12) ?? adminId.substring(0, 12),
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Members with AI Agents Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Members & AI Agents',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_data!.memberAIAgents.length} members',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.grey500
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
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
                                        'AI agent data only. No personal information (name, email, phone, home address) is displayed.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.grey700,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._data!.memberAIAgents.entries.map((entry) {
                                final memberId = entry.key;
                                final aiAgent = entry.value;
                                final isLeader = _data!.leaders?.contains(memberId) ?? false;
                                final isAdmin = _data!.adminTeam?.contains(memberId) ?? false;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: AppColors.grey500.withValues(alpha: 0.05),
                                  child: ExpansionTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isLeader
                                          ? AppColors.grey600.withValues(alpha: 0.2)
                                          : isAdmin
                                              ? AppColors.electricGreen.withValues(alpha: 0.2)
                                              : AppColors.grey500.withValues(alpha: 0.2),
                                      child: Icon(
                                        isLeader
                                            ? Icons.star
                                            : isAdmin
                                                ? Icons.admin_panel_settings
                                                : Icons.person,
                                        color: isLeader
                                            ? AppColors.grey600
                                            : isAdmin
                                                ? AppColors.electricGreen
                                                : AppColors.grey500,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Member: ${memberId.substring(0, 12)}...',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'AI Signature: ${aiAgent['ai_signature']?.toString().substring(0, 16) ?? 'N/A'}...',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildAIAgentInfo('AI Signature', aiAgent['ai_signature']?.toString() ?? 'N/A'),
                                            _buildAIAgentInfo('User ID', memberId),
                                            _buildAIAgentInfo('AI Status', aiAgent['ai_status']?.toString() ?? 'N/A'),
                                            _buildAIAgentInfo('AI Activity', aiAgent['ai_activity']?.toString() ?? 'N/A'),
                                            _buildAIAgentInfo('AI Connections', '${aiAgent['ai_connections'] ?? 0}'),
                                            if (isLeader)
                                              Chip(
                                                label: const Text('Leader'),
                                                avatar: const Icon(Icons.star, size: 16),
                                              ),
                                            if (isAdmin)
                                              Chip(
                                                label: const Text('Admin'),
                                                avatar: const Icon(Icons.admin_panel_settings, size: 16),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildAIAgentInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

