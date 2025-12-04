import 'package:flutter/material.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';

class CommunityValidationWidget extends StatefulWidget {
  final Spot spot;
  final VoidCallback? onValidationComplete;

  const CommunityValidationWidget({
    super.key,
    required this.spot,
    this.onValidationComplete,
  });

  @override
  State<CommunityValidationWidget> createState() => _CommunityValidationWidgetState();
}

class _CommunityValidationWidgetState extends State<CommunityValidationWidget> {
  bool _isValidating = false;
  int? _selectedAccuracy;
  String? _selectedIssue;
  final TextEditingController _commentController = TextEditingController();

  final List<String> _accuracyLabels = [
    'Very Poor',
    'Poor', 
    'Fair',
    'Good',
    'Excellent',
  ];

  final List<String> _commonIssues = [
    'Incorrect location',
    'Wrong business hours',
    'Outdated information',
    'Place doesn\'t exist',
    'Wrong category',
    'Missing details',
    'Duplicate listing',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isExternalData {
    return widget.spot.metadata.containsKey('is_external') && 
           widget.spot.metadata['is_external'] == true;
  }

  String get _dataSource {
    return widget.spot.metadata['source']?.toString() ?? 'community';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExternalData) {
      return const SizedBox.shrink(); // Only show for external data
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.verified_user,
                  color: AppColors.electricGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Community Validation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Help verify this ${_dataSource} data',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSourceBadge(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // OUR_GUTS.md Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Per OUR_GUTS.md: Your community validation helps maintain authentic, trustworthy place data.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Accuracy Rating
            const Text(
              'How accurate is this information?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(5, (index) {
                final isSelected = _selectedAccuracy == index;
                return ChoiceChip(
                  label: Text(
                    '${index + 1}★',
                    style: TextStyle(
                      color: isSelected ? AppColors.black : AppColors.grey700,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedAccuracy = selected ? index : null;
                    });
                  },
                  selectedColor: _getAccuracyColor(index),
                  backgroundColor: AppColors.grey200,
                );
              }),
            ),
            if (_selectedAccuracy != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _accuracyLabels[_selectedAccuracy!],
                  style: TextStyle(
                    fontSize: 12,
                    color: _getAccuracyColor(_selectedAccuracy!),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Issues (if accuracy is low)
            if (_selectedAccuracy != null && _selectedAccuracy! < 3) ...[
              const Text(
                'What seems to be the issue?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _commonIssues.map((issue) {
                  final isSelected = _selectedIssue == issue;
                  return FilterChip(
                    label: Text(
                      issue,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppColors.black : AppColors.grey700,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedIssue = selected ? issue : null;
                      });
                    },
                    selectedColor: AppColors.error,
                    backgroundColor: AppColors.grey200,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Additional Comments
            const Text(
              'Additional comments (optional)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share any additional details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            
            const SizedBox(height: 16),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
                child: ElevatedButton(
                onPressed: _selectedAccuracy != null && !_isValidating
                    ? _submitValidation
                    : null,
                  // Use global ElevatedButtonTheme
                 child: _isValidating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                           valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                        ),
                      )
                    : const Text('Submit Validation'),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Privacy Note
            Text(
              'Your validation is anonymous and helps improve data quality for the community.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge() {
    final source = _dataSource;
    Color color;
    String displayName;
    
    switch (source.toLowerCase()) {
      case 'google_places':
        color = AppColors.grey600;
        displayName = 'Google';
        break;
      case 'openstreetmap':
      case 'osm':
        color = AppColors.grey600;
        displayName = 'OSM';
        break;
      default:
        color = AppColors.grey600;
        displayName = source.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getAccuracyColor(int rating) {
    switch (rating) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.grey600;
      case 4:
        return AppColors.success;
      default:
        return AppColors.grey600;
    }
  }

  void _submitValidation() async {
    setState(() {
      _isValidating = true;
    });

    try {
      // Simulate API call to submit validation
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, this would:
      // 1. Send validation data to backend
      // 2. Update spot's validation score
      // 3. Flag for review if accuracy is low
      // 4. Track user's validation history
      
      final validationData = {
        'spot_id': widget.spot.id,
        'source': _dataSource,
        'accuracy_rating': _selectedAccuracy! + 1, // 1-5 scale
        'accuracy_label': _accuracyLabels[_selectedAccuracy!],
        'issue': _selectedIssue,
        'comment': _commentController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': 'anonymous', // In real app, use actual user ID
      };
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thank you! Your validation helps improve community data quality.',
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
        
        widget.onValidationComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting validation: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }
}