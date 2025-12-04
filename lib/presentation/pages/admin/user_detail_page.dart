import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:intl/intl.dart';

/// User Detail Page
/// Comprehensive view of a single user's data, progress, and predictions
class UserDetailPage extends StatefulWidget {
  final String userId;
  final AdminGodModeService? godModeService;
  
  const UserDetailPage({
    super.key,
    required this.userId,
    this.godModeService,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> with SingleTickerProviderStateMixin {
  UserProgressData? _progressData;
  UserPredictionsData? _predictionsData;
  UserDataSnapshot? _userSnapshot;
  bool _isLoading = true;
  late TabController _tabController;
  StreamSubscription<UserDataSnapshot>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _startRealTimeUpdates();
  }

  Future<void> _loadUserData() async {
    if (widget.godModeService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final progress = await widget.godModeService!.getUserProgress(widget.userId);
      final predictions = await widget.godModeService!.getUserPredictions(widget.userId);

      setState(() {
        _progressData = progress;
        _predictionsData = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startRealTimeUpdates() {
    if (widget.godModeService == null) return;

    _dataSubscription = widget.godModeService!.watchUserData(widget.userId).listen(
      (snapshot) {
        setState(() {
          _userSnapshot = snapshot;
        });
      },
      onError: (error) {
        debugPrint('Error in real-time user data stream: $error');
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${widget.userId.substring(0, 12)}...'),
            Text(
              'AI Data Only',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Data'),
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.psychology), text: 'Predictions'),
          ],
        ),
        actions: [
          if (_userSnapshot != null)
            Icon(
              _userSnapshot!.isOnline ? Icons.circle : Icons.circle_outlined,
              color: _userSnapshot!.isOnline ? AppColors.electricGreen : AppColors.grey500,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDataTab(),
                _buildProgressTab(),
                _buildPredictionsTab(),
              ],
            ),
    );
  }

  Widget _buildDataTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.person,
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
                                'User ID',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                widget.userId,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'monospace',
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Privacy: Location data shown (vibe indicator), no personal info',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.electricGreen,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_userSnapshot != null) ...[
                      const Divider(),
                      _buildInfoRow('Status', _userSnapshot!.isOnline ? 'Online' : 'Offline'),
                      _buildInfoRow('Last Active', _formatTime(_userSnapshot!.lastActive)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location Data Card (Vibe Indicators)
            if (_userSnapshot != null)
              _buildLocationDataCard(context),
            
            // Real-time Data Card
            if (_userSnapshot != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.update, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'AI-Related Data',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Show AI-related data only (location data shown separately)
                      ..._userSnapshot!.data.entries
                          .where((entry) {
                            final key = entry.key.toLowerCase();
                            // Filter out personal data
                            final forbidden = ['name', 'email', 'phone', 'personal'];
                            // Filter out home address specifically
                            final forbiddenLocation = ['home_address', 'homeaddress', 'residential_address'];
                            
                            // Exclude location data (shown in separate card)
                            if (key.contains('location') || 
                                key.contains('coordinates') ||
                                key.contains('latitude') ||
                                key.contains('longitude') ||
                                key.contains('visited') ||
                                key.contains('geographic')) {
                              return false; // Location shown separately
                            }
                            
                            // Allow location data
                            if (forbiddenLocation.any((f) => key.contains(f))) {
                              return false; // Home address forbidden
                            }
                            
                            // Filter out other personal data
                            return !forbidden.any((f) => key.contains(f));
                          })
                          .map((entry) => _buildInfoRow(entry.key, _formatDataValue(entry.value))),
                      if (_userSnapshot!.data.entries
                          .where((entry) {
                            final key = entry.key.toLowerCase();
                            final forbidden = ['name', 'email', 'phone', 'personal', 'location', 'coordinates', 'latitude', 'longitude', 'visited', 'geographic', 'home_address'];
                            return !forbidden.any((f) => key.contains(f));
                          })
                          .isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'No AI data available',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    if (_progressData == null) {
      return const Center(child: Text('No progress data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMetricRow('Total Contributions', '${_progressData!.totalContributions}'),
                    _buildMetricRow('Pins Earned', '${_progressData!.pinsEarned}'),
                    _buildMetricRow('Lists Created', '${_progressData!.listsCreated}'),
                    _buildMetricRow('Spots Added', '${_progressData!.spotsAdded}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Expertise Progress
            if (_progressData!.expertiseProgress.isNotEmpty) ...[
              Text(
                'Expertise Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ..._progressData!.expertiseProgress.map((progress) => 
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(progress.category),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress.progressPercentage / 100,
                          backgroundColor: AppColors.grey200,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress.getFormattedProgress(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Text(
                      progress.currentLevel.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (_predictionsData == null) {
      return const Center(child: Text('No predictions available'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Stage Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stage',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_predictionsData!.currentStage),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confidence: ${(_predictionsData!.confidence * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Timeframe: ${_formatDuration(_predictionsData!.timeframe)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Predicted Actions
            Text(
              'Predicted Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._predictionsData!.predictedActions.map((action) => 
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(action.action),
                  subtitle: Text(action.category),
                  trailing: Chip(
                    label: Text('${(action.probability * 100).toStringAsFixed(0)}%'),
                    backgroundColor: _getProbabilityColor(action.probability).withValues(alpha: 0.2),
                  ),
                ),
              )
            ),
            const SizedBox(height: 16),
            
            // Journey Path
            Text(
              'Journey Path',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._predictionsData!.journeyPath.map((step) => 
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(step.description),
                  subtitle: Text('Likelihood: ${(step.likelihood * 100).toStringAsFixed(1)}%'),
                  trailing: Text(_formatDuration(step.estimatedTime)),
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Color _getProbabilityColor(double probability) {
    if (probability >= 0.7) return AppColors.success;
    if (probability >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  String _formatTime(DateTime time) {
    return DateFormat('MMM d, y HH:mm:ss').format(time);
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  Widget _buildLocationDataCard(BuildContext context) {
    if (_userSnapshot == null) return const SizedBox.shrink();
    
    // Extract location-related data
    final locationData = _userSnapshot!.data.entries
        .where((entry) {
          final key = entry.key.toLowerCase();
          // Include location data but exclude home address
          return (key.contains('location') || 
                  key.contains('coordinates') ||
                  key.contains('latitude') ||
                  key.contains('longitude') ||
                  key.contains('visited') ||
                  key.contains('geographic')) &&
                 !key.contains('home_address') &&
                 !key.contains('homeaddress') &&
                 !key.contains('residential');
        })
        .toList();
    
    if (locationData.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.electricGreen.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.electricGreen),
                const SizedBox(width: 8),
                Text(
                  'Location Data (Vibe Indicators)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Core vibe indicator for AI personality matching',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 12),
            ...locationData.map((entry) => _buildInfoRow(entry.key, _formatDataValue(entry.value))),
          ],
        ),
      ),
    );
  }

  String _formatDataValue(dynamic value) {
    if (value is Map) {
      // Format location data nicely
      if (value.containsKey('lat') && value.containsKey('lng')) {
        return 'Lat: ${value['lat']}, Lng: ${value['lng']}';
      }
      return value.toString();
    } else if (value is List) {
      if (value.isEmpty) return 'Empty';
      return '${value.length} items';
    }
    return value.toString();
  }
}

