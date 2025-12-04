/// Action History Page
/// 
/// Part of Feature Matrix Phase 7, Week 33: Action Execution UI & Integration
/// 
/// Displays the history of executed actions with:
/// - List of all actions (most recent first)
/// - Action details (intent, result, timestamp)
/// - Undo functionality for successful actions
/// - Visual indicators for success/failure/undone status
/// - Filtering by action type
/// - Filtering by date range
/// - Search by action description
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:spots/core/ai/action_history_entry.dart' as entry;
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/core/services/action_history_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/widgets/actions/action_history_item_widget.dart';

/// Page that displays action execution history
/// 
/// Shows a scrollable list of all actions executed by the AI,
/// with the ability to undo successful actions.
class ActionHistoryPage extends StatefulWidget {
  final ActionHistoryService service;
  final String? userId; // Optional: filter by user ID

  const ActionHistoryPage({
    super.key,
    required this.service,
    this.userId,
  });

  @override
  State<ActionHistoryPage> createState() => _ActionHistoryPageState();
}

class _ActionHistoryPageState extends State<ActionHistoryPage> {
  List<entry.ActionHistoryEntry> _allHistory = [];
  List<entry.ActionHistoryEntry> _filteredHistory = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedActionType;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await widget.service.getHistory();

    if (mounted) {
      setState(() {
        // Filter by userId if provided
        _allHistory = widget.userId != null
            ? history.where((e) => e.userId == widget.userId).toList()
            : history;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<entry.ActionHistoryEntry>.from(_allHistory);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        final subtitle = _getSubtitleForEntry(e).toLowerCase();
        final title = _getTitleForIntent(e.intent.type).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return subtitle.contains(query) || title.contains(query);
      }).toList();
    }

    // Filter by action type
    if (_selectedActionType != null && _selectedActionType!.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.intent.type == _selectedActionType;
      }).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      filtered = filtered.where((e) {
        return e.timestamp.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            e.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      _filteredHistory = filtered;
    });
  }

  Future<void> _handleUndo(entry.ActionHistoryEntry entry) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.undo, color: AppColors.electricGreen),
            SizedBox(width: 8),
            Text('Undo Action'),
          ],
        ),
        content: Text(
          'Are you sure you want to undo this action? This cannot be reversed.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.black,
            ),
            child: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await widget.service.undoAction(entry.id);
      
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.electricGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
        _loadHistory(); // Refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action History'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.electricGreen,
              ),
            )
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _filteredHistory.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search actions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
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
                borderSide: BorderSide(color: AppColors.electricGreen, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Action type filter
                      FilterChip(
                        label: Text(_selectedActionType ?? 'All Types'),
                        selected: _selectedActionType != null,
                        onSelected: (selected) {
                          if (selected) {
                            _showActionTypeFilter();
                          } else {
                            setState(() {
                              _selectedActionType = null;
                            });
                            _applyFilters();
                          }
                        },
                        selectedColor: AppColors.electricGreen.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.electricGreen,
                      ),
                      const SizedBox(width: 8),
                      // Date range filter
                      FilterChip(
                        label: Text(
                          _selectedDateRange != null
                              ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                              : 'All Dates',
                        ),
                        selected: _selectedDateRange != null,
                        onSelected: (selected) {
                          if (selected) {
                            _showDateRangePicker();
                          } else {
                            setState(() {
                              _selectedDateRange = null;
                            });
                            _applyFilters();
                          }
                        },
                        selectedColor: AppColors.electricGreen.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.electricGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActionTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter by Action Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Types'),
              onTap: () {
                setState(() {
                  _selectedActionType = null;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Create Spot'),
              onTap: () {
                setState(() {
                  _selectedActionType = 'create_spot';
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Create List'),
              onTap: () {
                setState(() {
                  _selectedActionType = 'create_list';
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Add Spot to List'),
              onTap: () {
                setState(() {
                  _selectedActionType = 'add_spot_to_list';
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now;

    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _selectedDateRange,
    );

    if (range != null) {
      setState(() {
        _selectedDateRange = range;
      });
      _applyFilters();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No action history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actions executed by AI will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _filteredHistory[index];
        return ActionHistoryItemWidget(
          entry: entry,
          onUndo: entry.canUndo && !entry.isUndone
              ? () => _handleUndo(entry)
              : null,
        );
      },
    );
  }

  String _getTitleForIntent(String intentType) {
    switch (intentType) {
      case 'create_spot':
        return 'Create Spot';
      case 'create_list':
        return 'Create List';
      case 'add_spot_to_list':
        return 'Add Spot to List';
      default:
        return 'Unknown Action';
    }
  }

  String _getSubtitleForEntry(entry.ActionHistoryEntry entry) {
    final intent = entry.intent;
    
    if (intent.type == 'create_spot') {
      if (intent is CreateSpotIntent) {
        return intent.name;
      }
      return 'Create a new spot';
    } else if (intent.type == 'create_list') {
      if (intent is CreateListIntent) {
        return intent.title;
      }
      return 'Create a new list';
    } else if (intent.type == 'add_spot_to_list') {
      if (intent is AddSpotToListIntent) {
        final spotName = intent.metadata['spotName'] as String? ?? 'Spot';
        final listName = intent.metadata['listName'] as String? ?? 'List';
        return 'Added $spotName to $listName';
      }
      return 'Add spot to list';
    }
    
    return 'Action details';
  }
}

