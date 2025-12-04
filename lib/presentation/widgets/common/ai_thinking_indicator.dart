/// AI Thinking Indicator Widget
/// 
/// Part of Feature Matrix Phase 1.3: LLM Full Integration
/// Provides visual feedback while LLM is processing requests.
/// 
/// Features:
/// - Animated thinking indicator
/// - Context loading states (personality, vibe, AI2AI insights)
/// - Optional "what AI is considering" visibility
/// - Timeout handling with helpful messages
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:spots/core/theme/colors.dart';

/// Enum representing different AI processing stages
enum AIThinkingStage {
  loadingContext,
  analyzingPersonality,
  consultingNetwork,
  generatingResponse,
  finalizing,
}

/// Widget that shows AI thinking/processing state
class AIThinkingIndicator extends StatefulWidget {
  final AIThinkingStage stage;
  final bool showDetails;
  final Duration timeout;
  final VoidCallback? onTimeout;
  final bool compact;
  
  const AIThinkingIndicator({
    super.key,
    this.stage = AIThinkingStage.generatingResponse,
    this.showDetails = true,
    this.timeout = const Duration(seconds: 30),
    this.onTimeout,
    this.compact = false,
  });
  
  @override
  State<AIThinkingIndicator> createState() => _AIThinkingIndicatorState();
}

class _AIThinkingIndicatorState extends State<AIThinkingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _timeoutTimer;
  bool _timedOut = false;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimeoutTimer();
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startTimeoutTimer() {
    _timeoutTimer = Timer(widget.timeout, () {
      if (mounted) {
        setState(() {
          _timedOut = true;
        });
        widget.onTimeout?.call();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_timedOut) {
      return _buildTimeoutMessage();
    }
    
    if (widget.compact) {
      return _buildCompactIndicator();
    }
    
    return _buildFullIndicator();
  }
  
  Widget _buildFullIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildAnimatedIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStageTitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.showDetails) ...[
                      const SizedBox(height: 6),
                      Text(
                        _getStageDescription(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.showDetails) ...[
            const SizedBox(height: 16),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCompactIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedIcon(size: 16),
          const SizedBox(width: 8),
          Text(
            _getStageTitle(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.electricGreen,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedIcon({double size = 24}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(size * 0.25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.electricGreen,
                  AppColors.electricGreen,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStageIcon(),
              size: size,
              color: AppColors.white,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProgressBar() {
    final progress = _getStageProgress();
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricGreen),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getProgressLabel(),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.electricGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTimeoutMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taking longer than usual',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The AI is still thinking. This might take a moment...',
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
    );
  }
  
  String _getStageTitle() {
    switch (widget.stage) {
      case AIThinkingStage.loadingContext:
        return 'Loading context...';
      case AIThinkingStage.analyzingPersonality:
        return 'Analyzing personality...';
      case AIThinkingStage.consultingNetwork:
        return 'Consulting AI network...';
      case AIThinkingStage.generatingResponse:
        return 'AI is thinking...';
      case AIThinkingStage.finalizing:
        return 'Finalizing response...';
    }
  }
  
  String _getStageDescription() {
    switch (widget.stage) {
      case AIThinkingStage.loadingContext:
        return 'Gathering your preferences and history';
      case AIThinkingStage.analyzingPersonality:
        return 'Understanding your personality and vibe';
      case AIThinkingStage.consultingNetwork:
        return 'Learning from AI2AI insights';
      case AIThinkingStage.generatingResponse:
        return 'Crafting a personalized response';
      case AIThinkingStage.finalizing:
        return 'Almost ready...';
    }
  }
  
  IconData _getStageIcon() {
    switch (widget.stage) {
      case AIThinkingStage.loadingContext:
        return Icons.inventory_2_outlined;
      case AIThinkingStage.analyzingPersonality:
        return Icons.psychology;
      case AIThinkingStage.consultingNetwork:
        return Icons.share;
      case AIThinkingStage.generatingResponse:
        return Icons.auto_awesome;
      case AIThinkingStage.finalizing:
        return Icons.check_circle_outline;
    }
  }
  
  double _getStageProgress() {
    switch (widget.stage) {
      case AIThinkingStage.loadingContext:
        return 0.2;
      case AIThinkingStage.analyzingPersonality:
        return 0.4;
      case AIThinkingStage.consultingNetwork:
        return 0.6;
      case AIThinkingStage.generatingResponse:
        return 0.8;
      case AIThinkingStage.finalizing:
        return 0.95;
    }
  }
  
  String _getProgressLabel() {
    switch (widget.stage) {
      case AIThinkingStage.loadingContext:
        return 'Step 1 of 5';
      case AIThinkingStage.analyzingPersonality:
        return 'Step 2 of 5';
      case AIThinkingStage.consultingNetwork:
        return 'Step 3 of 5';
      case AIThinkingStage.generatingResponse:
        return 'Step 4 of 5';
      case AIThinkingStage.finalizing:
        return 'Step 5 of 5';
    }
  }
}

/// Simpler dot-based thinking indicator
class AIThinkingDots extends StatefulWidget {
  final Color color;
  final double size;
  
  const AIThinkingDots({
    super.key,
    this.color = AppColors.electricGreen,
    this.size = 8.0,
  });
  
  @override
  State<AIThinkingDots> createState() => _AIThinkingDotsState();
}

class _AIThinkingDotsState extends State<AIThinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final opacity = (value < 0.5) 
                ? (value * 2).clamp(0.3, 1.0)
                : (2 - value * 2).clamp(0.3, 1.0);
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

