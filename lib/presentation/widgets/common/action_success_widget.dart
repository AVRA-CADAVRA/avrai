/// Action Success Widget
/// 
/// Part of Feature Matrix Phase 1.3: LLM Full Integration
/// Provides rich visual feedback after successful action execution.
/// 
/// Features:
/// - Success animations (confetti, checkmarks)
/// - Action result preview
/// - Undo button with timeout
/// - Quick actions (view result, share, etc.)
/// - Auto-dismiss option
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/ai/action_models.dart';

/// Widget that displays success feedback after action execution
class ActionSuccessWidget extends StatefulWidget {
  final ActionResult result;
  final VoidCallback? onUndo;
  final VoidCallback? onViewResult;
  final Duration undoTimeout;
  final bool autoDismiss;
  final Duration autoDismissDelay;
  
  const ActionSuccessWidget({
    super.key,
    required this.result,
    this.onUndo,
    this.onViewResult,
    this.undoTimeout = const Duration(seconds: 5),
    this.autoDismiss = false,
    this.autoDismissDelay = const Duration(seconds: 3),
  });
  
  @override
  State<ActionSuccessWidget> createState() => _ActionSuccessWidgetState();
}

class _ActionSuccessWidgetState extends State<ActionSuccessWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  Timer? _undoTimer;
  Timer? _dismissTimer;
  bool _undoAvailable = true;
  int _undoSecondsRemaining = 5;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startUndoTimer();
    if (widget.autoDismiss) {
      _startDismissTimer();
    }
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
  }
  
  void _startUndoTimer() {
    if (widget.onUndo == null) return;
    
    _undoSecondsRemaining = widget.undoTimeout.inSeconds;
    _undoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _undoSecondsRemaining--;
          if (_undoSecondsRemaining <= 0) {
            _undoAvailable = false;
            timer.cancel();
          }
        });
      }
    });
  }
  
  void _startDismissTimer() {
    _dismissTimer = Timer(widget.autoDismissDelay, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _undoTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.black.withValues(alpha: 0),
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSuccessIcon(),
                const SizedBox(height: 20),
                _buildSuccessTitle(),
                const SizedBox(height: 12),
                _buildResultPreview(),
                const SizedBox(height: 20),
                _buildActionButtons(),
                if (_undoAvailable && widget.onUndo != null) ...[
                  const SizedBox(height: 16),
                  _buildUndoCountdown(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricGreen,
            AppColors.success,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.electricGreen.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle,
        size: 48,
        color: AppColors.white,
      ),
    );
  }
  
  Widget _buildSuccessTitle() {
    final title = _getSuccessTitle();
    
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
  
  Widget _buildResultPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildPreviewContent(),
          if ((widget.result.successMessage ?? widget.result.errorMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.result.successMessage ?? widget.result.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPreviewContent() {
    final intent = widget.result.intent;
    
    if (intent is CreateListIntent) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.list_alt,
              color: AppColors.electricGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intent.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (intent.description.isNotEmpty)
                  Text(
                    intent.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      );
    } else if (intent is CreateSpotIntent) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.place,
              color: AppColors.electricGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intent.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  intent.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (intent is AddSpotToListIntent) {
      final spotName = intent.metadata['spotName'] as String? ?? 'Spot';
      final listName = intent.metadata['listName'] as String? ?? 'List';
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMiniIcon(Icons.place, AppColors.electricGreen),
          const SizedBox(width: 8),
          Text(
            spotName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_forward,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          _buildMiniIcon(Icons.list_alt, AppColors.electricGreen),
          const SizedBox(width: 8),
          Text(
            listName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );
    }
    
    return Text(
      'Action completed successfully',
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
  
  Widget _buildMiniIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onViewResult != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                widget.onViewResult!();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.electricGreen,
                side: BorderSide(color: AppColors.electricGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        if (widget.onViewResult != null) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUndoCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.undo,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Can undo in ${_undoSecondsRemaining}s',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _undoAvailable
                ? () {
                    widget.onUndo?.call();
                    Navigator.of(context).pop();
                  }
                : null,
            child: Text(
              'Undo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _undoAvailable ? AppColors.warning : AppColors.grey300,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getSuccessTitle() {
    final intent = widget.result.intent;
    
    if (intent is CreateListIntent) {
      return '🎉 List Created!';
    } else if (intent is CreateSpotIntent) {
      return '📍 Spot Created!';
    } else if (intent is AddSpotToListIntent) {
      return '✨ Added to List!';
    }
    
    return '✅ Success!';
  }
}

/// Simple success toast for quick feedback
class ActionSuccessToast extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  
  const ActionSuccessToast({
    super.key,
    required this.message,
    this.icon = Icons.check_circle,
    this.color = AppColors.electricGreen,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show toast at the top of the screen
  static void show(BuildContext context, String message, {
    IconData icon = Icons.check_circle,
    Color color = AppColors.electricGreen,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: ActionSuccessToast(
          message: message,
          icon: icon,
          color: color,
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

