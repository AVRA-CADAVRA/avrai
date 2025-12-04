import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_colors.dart';

/// Success Animation Widget
/// Agent 2: Event Discovery & Hosting UI (Week 4, Task 2.12)
/// 
/// Provides a smooth success animation for actions
class SuccessAnimation extends StatefulWidget {
  final IconData icon;
  final String message;
  final Duration duration;

  const SuccessAnimation({
    super.key,
    this.icon = Icons.check_circle,
    required this.message,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    // Auto-hide after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show success animation as overlay
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    showDialog(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0),
      barrierDismissible: false,
      builder: (context) => Center(
        child: SuccessAnimation(
          message: message,
          icon: icon,
          duration: duration,
        ),
      ),
    );
  }
}

