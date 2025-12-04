import 'package:flutter/material.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/widgets/profile/partnership_card.dart';
import 'package:spots/presentation/widgets/profile/partnership_visibility_toggle.dart';

/// Partnership Display Widget
/// 
/// Displays a list of partnerships on user profiles with filtering and visibility controls.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipDisplayWidget extends StatefulWidget {
  final List<UserPartnership> partnerships;
  final ValueChanged<UserPartnership>? onPartnershipTap;
  final ValueChanged<String>? onViewAllTap;
  final ValueChanged<bool>? onVisibilityChanged;
  final int maxDisplayCount;
  final bool showFilters;
  final bool showVisibilityControls;

  const PartnershipDisplayWidget({
    super.key,
    required this.partnerships,
    this.onPartnershipTap,
    this.onViewAllTap,
    this.onVisibilityChanged,
    this.maxDisplayCount = 3,
    this.showFilters = false,
    this.showVisibilityControls = false,
  });

  @override
  State<PartnershipDisplayWidget> createState() =>
      _PartnershipDisplayWidgetState();
}

class _PartnershipDisplayWidgetState extends State<PartnershipDisplayWidget> {
  ProfilePartnershipType? _selectedType;
  PartnershipStatus? _selectedStatus;

  List<UserPartnership> get _filteredPartnerships {
    var filtered = widget.partnerships;

    // Filter by type
    if (_selectedType != null) {
      filtered = filtered
          .where((p) => p.type == _selectedType)
          .toList();
    }

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered
          .where((p) => p.status == _selectedStatus)
          .toList();
    }

    return filtered;
  }

  List<UserPartnership> get _displayedPartnerships {
    final filtered = _filteredPartnerships;
    if (widget.maxDisplayCount > 0) {
      return filtered.take(widget.maxDisplayCount).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.partnerships.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Partnerships',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.partnerships.length > widget.maxDisplayCount &&
                widget.onViewAllTap != null)
              TextButton(
                onPressed: () {
                  widget.onViewAllTap!('');
                },
                child: Text(
                  'View All (${widget.partnerships.length})',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Filters (if enabled)
        if (widget.showFilters) ...[
          _buildFilters(),
          const SizedBox(height: 16),
        ],

        // Partnership List
        if (_displayedPartnerships.isEmpty)
          _buildEmptyFilterState()
        else
          ..._displayedPartnerships.map((partnership) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProfilePartnershipCard(
                partnership: partnership,
                onTap: widget.onPartnershipTap != null
                    ? () => widget.onPartnershipTap!(partnership)
                    : null,
                showVisibilityToggle: widget.showVisibilityControls,
                onVisibilityChanged: widget.onVisibilityChanged != null
                    ? (isPublic) {
                        widget.onVisibilityChanged!(isPublic);
                        // Note: In a real implementation, you'd update the partnership
                        // through a service call here
                      }
                    : null,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        // Type Filter
        Expanded(
          child: DropdownButtonFormField<ProfilePartnershipType?>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Type',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey300),
              ),
              filled: true,
              fillColor: AppColors.grey100,
            ),
            items: [
              const DropdownMenuItem<ProfilePartnershipType?>(
                value: null,
                child: Text('All Types'),
              ),
              ...ProfilePartnershipType.values.map((type) {
                return DropdownMenuItem<ProfilePartnershipType?>(
                  value: type,
                  child: Text(type.displayName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        // Status Filter
        Expanded(
          child: DropdownButtonFormField<PartnershipStatus?>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey300),
              ),
              filled: true,
              fillColor: AppColors.grey100,
            ),
            items: [
              const DropdownMenuItem<PartnershipStatus?>(
                value: null,
                child: Text('All Status'),
              ),
              ...PartnershipStatus.values.map((status) {
                return DropdownMenuItem<PartnershipStatus?>(
                  value: status,
                  child: Text(status.displayName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No partnerships yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create partnerships to showcase your collaborations',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No partnerships match your filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedStatus = null;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

