import 'package:flutter/material.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/geographic_scope_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/widgets/common/standard_error_widget.dart';
import 'package:spots/presentation/widgets/common/standard_loading_widget.dart';

/// Locality Selection Widget
/// Agent 2: Phase 6, Week 24 - Geographic Scope UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Show available localities based on user's expertise level
/// - Filter localities based on geographic scope
/// - Show large city neighborhoods as separate localities
/// - Display helpful messaging for local vs city experts
class LocalitySelectionWidget extends StatefulWidget {
  final UnifiedUser user;
  final String? selectedLocality;
  final String category;
  final Function(String?) onLocalitySelected;
  final String? errorMessage;

  const LocalitySelectionWidget({
    super.key,
    required this.user,
    required this.category,
    required this.onLocalitySelected,
    this.selectedLocality,
    this.errorMessage,
  });

  @override
  State<LocalitySelectionWidget> createState() => _LocalitySelectionWidgetState();
}

class _LocalitySelectionWidgetState extends State<LocalitySelectionWidget> {
  final GeographicScopeService _scopeService = GeographicScopeService();
  List<String> _availableLocalities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableLocalities();
  }

  Future<void> _loadAvailableLocalities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scope = _scopeService.getHostingScope(
        user: widget.user,
        category: widget.category,
      );

      setState(() {
        _availableLocalities = scope['localities'] ?? [];
        _isLoading = false;
      });

      // Auto-select for local experts (only one option)
      if (_availableLocalities.length == 1 && widget.selectedLocality == null) {
        widget.onLocalitySelected(_availableLocalities.first);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _availableLocalities = [];
      });
    }
  }

  /// Get helpful message based on expertise level
  String _getHelpfulMessage() {
    final level = _getUserExpertiseLevel();
    if (level == null) return '';

    if (level == ExpertiseLevel.local) {
      return 'As a Local expert, you can host events in your locality only.';
    } else if (level == ExpertiseLevel.city) {
      return 'As a City expert, you can host events in all localities within your city.';
    } else if (level == ExpertiseLevel.regional) {
      return 'As a State expert, you can host events in all localities within your state.';
    } else if (level == ExpertiseLevel.national) {
      return 'As a National expert, you can host events in all localities within your nation.';
    } else if (level == ExpertiseLevel.global || level == ExpertiseLevel.universal) {
      return 'As a ${level.displayName} expert, you can host events anywhere.';
    }

    return '';
  }

  ExpertiseLevel? _getUserExpertiseLevel() {
    return widget.user.getExpertiseLevel(widget.category);
  }

  bool _isCityExpert() {
    final level = _getUserExpertiseLevel();
    if (level == null) return false;
    return level.index >= ExpertiseLevel.city.index;
  }

  @override
  Widget build(BuildContext context) {
    final helpfulMessage = _getHelpfulMessage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with tooltip
        Row(
          children: [
            Text(
              'Locality *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Select the locality where you want to host this event. '
                  'Local experts can only host in their locality. '
                  'City experts can host in all localities within their city.',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Helpful message
        if (helpfulMessage.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.electricGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.electricGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    helpfulMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Locality dropdown
        if (_isLoading)
          // Loading state
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: StandardLoadingWidget.inline(
              message: _isCityExpert()
                  ? 'Loading available localities in your city...'
                  : 'Loading your locality...',
              size: 16,
            ),
          )
        else if (_availableLocalities.isNotEmpty)
          DropdownButtonFormField<String>(
            value: widget.selectedLocality,
            decoration: InputDecoration(
              labelText: 'Select Locality',
              hintText: 'Choose a locality',
              hintStyle: TextStyle(color: AppColors.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.grey100,
              errorText: widget.errorMessage,
            ),
            style: TextStyle(color: AppColors.textPrimary),
            items: _availableLocalities.map((locality) {
              return DropdownMenuItem(
                value: locality,
                child: Text(locality),
              );
            }).toList(),
            onChanged: widget.onLocalitySelected,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Locality is required';
              }
              return null;
            },
          )
        else
          // No localities available
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No localities available. Please check your location settings.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Error message
        if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          StandardErrorWidget.inline(
            message: widget.errorMessage!,
          ),
        ],
      ],
    );
  }
}

