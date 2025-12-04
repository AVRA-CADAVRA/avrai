import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';

/// Event Feedback Page
/// 
/// Agent 2: Phase 5, Week 17 - Feedback UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Overall star rating
/// - Category ratings (sliders)
/// - Highlight selection (chips)
/// - Improvement suggestions
/// - Would attend again? (toggle)
/// - Would recommend? (toggle)
/// - Optional comments
/// - Submit button
class EventFeedbackPage extends StatefulWidget {
  final ExpertiseEvent event;

  const EventFeedbackPage({
    super.key,
    required this.event,
  });

  @override
  State<EventFeedbackPage> createState() => _EventFeedbackPageState();
}

class _EventFeedbackPageState extends State<EventFeedbackPage> {
  final PostEventFeedbackService _feedbackService = PostEventFeedbackService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );

  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  double _overallRating = 0.0;
  final Map<String, double> _categoryRatings = {
    'organization': 0.0,
    'content_quality': 0.0,
    'venue': 0.0,
    'value_for_money': 0.0,
  };
  final List<String> _selectedHighlights = [];
  final List<String> _selectedImprovements = [];
  bool _wouldAttendAgain = false;
  bool _wouldRecommend = false;
  bool _isSubmitting = false;
  String? _error;

  // Available highlight options
  final List<String> _highlightOptions = [
    'Great organization',
    'Engaging content',
    'Excellent venue',
    'Good value',
    'Friendly host',
    'Well-paced',
    'Interactive',
    'Educational',
    'Fun atmosphere',
    'Networking opportunities',
  ];

  // Available improvement options
  final List<String> _improvementOptions = [
    'Better communication',
    'More preparation',
    'Better venue',
    'More content',
    'Better timing',
    'More interactive',
    'Better organization',
    'More value',
    'Better facilities',
    'More engagement',
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
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
        throw Exception('Please sign in to submit feedback');
      }

      await _feedbackService.submitFeedback(
        eventId: widget.event.id,
        userId: authState.user.id,
        overallRating: _overallRating,
        categoryRatings: _categoryRatings,
        comments: _commentsController.text.trim().isEmpty
            ? null
            : _commentsController.text.trim(),
        highlights: _selectedHighlights.isEmpty ? null : _selectedHighlights,
        improvements:
            _selectedImprovements.isEmpty ? null : _selectedImprovements,
        wouldAttendAgain: _wouldAttendAgain,
        wouldRecommend: _wouldRecommend,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thank you for your feedback!'),
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
          'Event Feedback',
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
                // Event Info
                _buildEventInfo(),
                const SizedBox(height: 24),

                // Overall Rating
                _buildOverallRating(),
                const SizedBox(height: 24),

                // Category Ratings
                _buildCategoryRatings(),
                const SizedBox(height: 24),

                // Highlights
                _buildHighlights(),
                const SizedBox(height: 24),

                // Improvements
                _buildImprovements(),
                const SizedBox(height: 24),

                // Would Attend Again / Recommend
                _buildRecommendationToggles(),
                const SizedBox(height: 24),

                // Comments
                _buildComments(),
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
                  onPressed: _isSubmitting ? null : _submitFeedback,
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
                      : const Text('Submit Feedback'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
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
            'How was your experience?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDateTime(widget.event.startTime)} • ${widget.event.location ?? 'Location TBD'}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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

  Widget _buildCategoryRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Ratings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._categoryRatings.keys.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getCategoryDisplayName(category),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _categoryRatings[category]! > 0
                          ? '${_categoryRatings[category]!.toStringAsFixed(1)} / 5.0'
                          : 'Not rated',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _categoryRatings[category]!,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  label: _categoryRatings[category]! > 0
                      ? _categoryRatings[category]!.toStringAsFixed(1)
                      : null,
                  onChanged: (value) {
                    setState(() {
                      _categoryRatings[category] = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What was great? (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _highlightOptions.map((highlight) {
            final isSelected = _selectedHighlights.contains(highlight);
            return FilterChip(
              label: Text(highlight),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedHighlights.add(highlight);
                  } else {
                    _selectedHighlights.remove(highlight);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImprovements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What could be better? (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _improvementOptions.map((improvement) {
            final isSelected = _selectedImprovements.contains(improvement);
            return FilterChip(
              label: Text(improvement),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedImprovements.add(improvement);
                  } else {
                    _selectedImprovements.remove(improvement);
                  }
                });
              },
              selectedColor: AppTheme.warningColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.warningColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.warningColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendationToggles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Would you attend again?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            value: _wouldAttendAgain,
            onChanged: (value) {
              setState(() {
                _wouldAttendAgain = value;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
          SwitchListTile(
            title: Text(
              'Would you recommend to others?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            value: _wouldRecommend,
            onChanged: (value) {
              setState(() {
                _wouldRecommend = value;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Comments (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share any additional thoughts...',
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

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'organization':
        return 'Organization';
      case 'content_quality':
        return 'Content Quality';
      case 'venue':
        return 'Venue';
      case 'value_for_money':
        return 'Value for Money';
      default:
        return category;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

