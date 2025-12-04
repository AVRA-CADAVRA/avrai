import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Partner Rating Page
/// 
/// Agent 2: Phase 5, Week 17 - Feedback UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Rate each partner individually
/// - Professionalism, communication, reliability ratings
/// - Would partner again?
/// - Positive feedback
/// - Improvement suggestions
class PartnerRatingPage extends StatefulWidget {
  final ExpertiseEvent event;
  final String partnerId;
  final String partnershipRole; // 'host', 'venue', 'sponsor', etc.

  const PartnerRatingPage({
    super.key,
    required this.event,
    required this.partnerId,
    required this.partnershipRole,
  });

  @override
  State<PartnerRatingPage> createState() => _PartnerRatingPageState();
}

class _PartnerRatingPageState extends State<PartnerRatingPage> {
  final PostEventFeedbackService _feedbackService = PostEventFeedbackService(
    eventService: GetIt.instance<ExpertiseEventService>(),
    partnershipService: GetIt.instance<PartnershipService>(),
  );

  final _formKey = GlobalKey<FormState>();
  final _positivesController = TextEditingController();
  final _improvementsController = TextEditingController();

  double _overallRating = 0.0;
  double _professionalism = 0.0;
  double _communication = 0.0;
  double _reliability = 0.0;
  double _wouldPartnerAgain = 0.0;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _positivesController.dispose();
    _improvementsController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (!_formKey.currentState!.validate()) return;
    if (_overallRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('Please sign in to submit a rating');
      }

      // Get partnership ID (simplified - in production, get from partnership service)
      String partnershipId = 'partnership_${widget.event.id}_${widget.partnerId}';
      try {
        final partnerships = await GetIt.instance<PartnershipService>()
            .getPartnershipsForEvent(widget.event.id);
        final partnership = partnerships.firstWhere(
          (p) => p.userId == widget.partnerId || p.businessId == widget.partnerId,
        );
        partnershipId = partnership.id;
      } catch (e) {
        // Use default partnership ID if not found
      }

      await _feedbackService.submitPartnerRating(
        eventId: widget.event.id,
        raterId: authState.user.id,
        ratedId: widget.partnerId,
        partnershipRole: widget.partnershipRole,
        overallRating: _overallRating,
        professionalism: _professionalism,
        communication: _communication,
        reliability: _reliability,
        wouldPartnerAgain: _wouldPartnerAgain,
        positives: _positivesController.text.trim().isEmpty
            ? null
            : _positivesController.text.trim(),
        improvements: _improvementsController.text.trim().isEmpty
            ? null
            : _improvementsController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thank you for your rating!'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Rate Partner',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner Info
                _buildPartnerInfo(),
                const SizedBox(height: 24),

                // Overall Rating
                _buildOverallRating(),
                const SizedBox(height: 24),

                // Detailed Ratings
                _buildDetailedRatings(),
                const SizedBox(height: 24),

                // Would Partner Again
                _buildWouldPartnerAgain(),
                const SizedBox(height: 24),

                // Positive Feedback
                _buildPositives(),
                const SizedBox(height: 24),

                // Improvement Suggestions
                _buildImprovements(),
                const SizedBox(height: 24),

                // Error Display
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text('Submit Rating'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate Your Partner',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Event: ${widget.event.title}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Role: ${_getRoleDisplayName(widget.partnershipRole)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Rating *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = (index + 1).toDouble();
            return GestureDetector(
              onTap: () {
                setState(() {
                  _overallRating = starValue;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  _overallRating >= starValue
                      ? Icons.star
                      : Icons.star_border,
                  size: 48,
                  color: _overallRating >= starValue
                      ? AppTheme.warningColor
                      : AppColors.grey400,
                ),
              ),
            );
          }),
        ),
        if (_overallRating > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${_overallRating.toStringAsFixed(1)} out of 5',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Ratings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildRatingSlider('Professionalism', _professionalism, (value) {
          setState(() {
            _professionalism = value;
          });
        }),
        const SizedBox(height: 16),
        _buildRatingSlider('Communication', _communication, (value) {
          setState(() {
            _communication = value;
          });
        }),
        const SizedBox(height: 16),
        _buildRatingSlider('Reliability', _reliability, (value) {
          setState(() {
            _reliability = value;
          });
        }),
      ],
    );
  }

  Widget _buildRatingSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              value > 0 ? '${value.toStringAsFixed(1)} / 5.0' : 'Not rated',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          label: value > 0 ? value.toStringAsFixed(1) : null,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildWouldPartnerAgain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Would you partner again? *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = (index + 1).toDouble();
            return GestureDetector(
              onTap: () {
                setState(() {
                  _wouldPartnerAgain = starValue;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  _wouldPartnerAgain >= starValue
                      ? Icons.star
                      : Icons.star_border,
                  size: 40,
                  color: _wouldPartnerAgain >= starValue
                      ? AppColors.electricGreen
                      : AppColors.grey400,
                ),
              ),
            );
          }),
        ),
        if (_wouldPartnerAgain > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getWouldPartnerAgainText(_wouldPartnerAgain),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPositives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Positive Feedback (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _positivesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What did they do well?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildImprovements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Improvement Suggestions (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _improvementsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What could be improved?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'host':
        return 'Host';
      case 'venue':
        return 'Venue';
      case 'sponsor':
        return 'Sponsor';
      case 'business':
        return 'Business Partner';
      default:
        return role;
    }
  }

  String _getWouldPartnerAgainText(double rating) {
    if (rating >= 4.5) return 'Definitely yes';
    if (rating >= 3.5) return 'Probably yes';
    if (rating >= 2.5) return 'Maybe';
    if (rating >= 1.5) return 'Probably not';
    return 'Definitely not';
  }
}

