/// Offline Indicator Widget
/// 
/// Part of Feature Matrix Phase 1.3: LLM Full Integration
/// Provides clear feedback when app is offline and what functionality is limited.
/// 
/// Features:
/// - Offline mode banner
/// - Explanation of limited functionality
/// - What works offline vs. online
/// - Retry connection option
/// - Auto-dismisses when back online
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:spots/core/theme/colors.dart';

/// Widget that displays offline status and functionality information
class OfflineIndicatorWidget extends StatefulWidget {
  final bool isOffline;
  final VoidCallback? onRetry;
  final bool showDismiss;
  final List<String>? limitedFeatures;
  final List<String>? availableFeatures;
  
  const OfflineIndicatorWidget({
    super.key,
    required this.isOffline,
    this.onRetry,
    this.showDismiss = true,
    this.limitedFeatures,
    this.availableFeatures,
  });
  
  @override
  State<OfflineIndicatorWidget> createState() => _OfflineIndicatorWidgetState();
}

class _OfflineIndicatorWidgetState extends State<OfflineIndicatorWidget> {
  bool _expanded = false;
  bool _dismissed = false;
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isOffline || _dismissed) {
      return const SizedBox.shrink();
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_expanded) _buildExpandedContent(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return InkWell(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limited Functionality',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'re offline. Some features are unavailable.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onRetry != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.onRetry,
                tooltip: 'Retry connection',
                color: AppColors.warning,
              ),
            if (widget.showDismiss)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _dismissed = true;
                  });
                },
                tooltip: 'Dismiss',
                color: AppColors.textSecondary,
                iconSize: 20,
              ),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpandedContent() {
    final limited = widget.limitedFeatures ?? _getDefaultLimitedFeatures();
    final available = widget.availableFeatures ?? _getDefaultAvailableFeatures();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          _buildFeatureSection(
            'Not Available Offline',
            limited,
            Icons.block,
            AppColors.error,
          ),
          const SizedBox(height: 16),
          _buildFeatureSection(
            'Still Works Offline',
            available,
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(height: 16),
          _buildReconnectTip(),
        ],
      ),
    );
  }
  
  Widget _buildFeatureSection(
    String title,
    List<String> features,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(left: 26, bottom: 6),
          child: Text(
            '• $feature',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        )),
      ],
    );
  }
  
  Widget _buildReconnectTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connect to WiFi or mobile data to access all features',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<String> _getDefaultLimitedFeatures() {
    return [
      'Cloud AI responses (LLM-powered chat)',
      'AI personality insights',
      'AI2AI network learning',
      'Real-time recommendations',
      'Cloud data sync',
    ];
  }
  
  List<String> _getDefaultAvailableFeatures() {
    return [
      'View saved spots and lists',
      'Basic rule-based commands',
      'Browse local data',
      'Offline map access (if cached)',
      'Create lists and spots (sync later)',
    ];
  }
}

/// Compact offline banner for minimal UI disruption
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onTap;
  
  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!isOffline) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.warning.withValues(alpha: 0.2),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Offline mode • Limited functionality',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Auto-detecting offline indicator that monitors connectivity
class AutoOfflineIndicator extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  
  const AutoOfflineIndicator({
    super.key,
    required this.builder,
  });
  
  @override
  State<AutoOfflineIndicator> createState() => _AutoOfflineIndicatorState();
}

class _AutoOfflineIndicatorState extends State<AutoOfflineIndicator> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;
  
  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }
  
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (mounted) {
        setState(() {
          _isOffline = result is List 
              ? result.contains(ConnectivityResult.none)
              : result == ConnectivityResult.none;
        });
      }
    } catch (e) {
      // Assume offline if check fails
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }
  
  void _listenToConnectivityChanges() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() {
          _isOffline = result is List 
              ? result.contains(ConnectivityResult.none)
              : result == ConnectivityResult.none;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isOffline);
  }
}

