import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';

/// OUR_GUTS.md: "The key works offline"
/// Shows when AI2AI connections happen offline
class OfflineConnectionBadge extends StatelessWidget {
  final bool isOffline;
  final int? queuedConnectionsCount;
  
  const OfflineConnectionBadge({
    Key? key,
    required this.isOffline,
    this.queuedConnectionsCount,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!isOffline && (queuedConnectionsCount ?? 0) == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOffline 
            ? AppColors.warning.withValues(alpha: 0.1) 
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOffline ? AppColors.warning : AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.cloud_done,
            size: 16,
            color: isOffline ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            isOffline 
                ? 'Offline Mode' 
                : '${queuedConnectionsCount ?? 0} ready to sync',
            style: TextStyle(
              fontSize: 12,
              color: isOffline ? AppColors.warning : AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for app bar
class OfflineConnectionIcon extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onTap;
  
  const OfflineConnectionIcon({
    Key? key,
    required this.isOffline,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!isOffline) {
      return const SizedBox.shrink();
    }
    
    return IconButton(
      icon: Icon(
        Icons.cloud_off,
        color: AppColors.warning,
      ),
      tooltip: 'Working Offline - The key still works!',
      onPressed: onTap ?? () => _showOfflineDialog(context),
    );
  }
  
  void _showOfflineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: AppColors.warning),
            const SizedBox(width: 12),
            Text('Working Offline', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Your key still works!\n\n'
          '✅ AI learns with you\n'
          '✅ AI2AI connections work\n'
          '✅ Personality evolves\n'
          '✅ Discoveries saved\n\n'
          'When you\'re back online, your connections will sync '
          'and you\'ll get network insights.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

