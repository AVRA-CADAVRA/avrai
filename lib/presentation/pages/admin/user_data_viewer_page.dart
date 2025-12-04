import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/pages/admin/user_detail_page.dart';
import 'package:intl/intl.dart';

/// User Data Viewer Page
/// Real-time viewing of user data
class UserDataViewerPage extends StatefulWidget {
  final AdminGodModeService? godModeService;
  
  const UserDataViewerPage({
    super.key,
    this.godModeService,
  });

  @override
  State<UserDataViewerPage> createState() => _UserDataViewerPageState();
}

class _UserDataViewerPageState extends State<UserDataViewerPage> {
  final _searchController = TextEditingController();
  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers() async {
    if (widget.godModeService == null) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await widget.godModeService!.searchUsers(
        query: _searchController.text.trim().isEmpty 
            ? null 
            : _searchController.text.trim(),
      );
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by User ID or AI Signature...',
                    helperText: 'Privacy: Only IDs shown, no personal data',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _searchUsers(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearching ? null : _searchUsers,
                child: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Search'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: AppColors.grey500,
                      const SizedBox(height: 16),
                      Text(
                        'Search for users to view their data',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey500
                            ),
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
                                'Privacy: User IDs, AI Signatures, and location data (vibe indicators) are visible. No personal data (name, email, phone, home address) is displayed.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.grey700,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.electricGreen.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: AppColors.electricGreen),
                      ),
                      title: Text(
                        'User ID: ${result.userId.substring(0, 12)}...',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Signature: ${result.aiSignature.substring(0, 12)}...'),
                          Text(
                            'Created: ${DateFormat('MMM d, y').format(result.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: result.isActive
                          ? const Icon(Icons.check_circle, color: AppColors.electricGreen)
                          : const Icon(Icons.cancel, color: AppColors.grey500,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailPage(
                              userId: result.userId,
                              godModeService: widget.godModeService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

