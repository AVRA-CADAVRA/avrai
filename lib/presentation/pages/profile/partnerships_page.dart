import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/widgets/profile/partnership_display_widget.dart';
import 'package:spots/presentation/widgets/profile/partnership_visibility_toggle.dart';

/// Partnerships Detail Page
/// 
/// Full page displaying all partnerships with filters and visibility controls.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipsPage extends StatefulWidget {
  const PartnershipsPage({super.key});

  @override
  State<PartnershipsPage> createState() => _PartnershipsPageState();
}

class _PartnershipsPageState extends State<PartnershipsPage> {
  List<UserPartnership> _allPartnerships = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnerships();
  }

  Future<void> _loadPartnerships() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        // TODO: Replace with actual PartnershipProfileService once Agent 1 completes it
        // Example:
        // final service = sl<PartnershipProfileService>();
        // final partnerships = await service.getUserPartnerships(authState.user.id);
        // setState(() {
        //   _allPartnerships = partnerships;
        //   _isLoading = false;
        // });
        
        // For now, empty list
        setState(() {
          _allPartnerships = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateVisibility(String partnershipId, bool isPublic) async {
    // TODO: Replace with actual service call once PartnershipProfileService is available
    // Example:
    // final service = sl<PartnershipProfileService>();
    // await service.updatePartnershipVisibility(partnershipId, isPublic);
    
    // Update local state
    setState(() {
      _allPartnerships = _allPartnerships.map((p) {
        if (p.id == partnershipId) {
          return p.copyWith(isPublic: isPublic);
        }
        return p;
      }).toList();
    });
  }

  Future<void> _updateBulkVisibility(Map<String, bool> visibilityMap) async {
    // TODO: Replace with actual service call once PartnershipProfileService is available
    // Example:
    // final service = sl<PartnershipProfileService>();
    // await service.updateBulkPartnershipVisibility(visibilityMap);
    
    // Update local state
    setState(() {
      _allPartnerships = _allPartnerships.map((p) {
        final isPublic = visibilityMap[p.id] ?? p.isPublic;
        return p.copyWith(isPublic: isPublic);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partnerships'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPartnerships,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Your Partnerships',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your partnerships and visibility settings',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bulk Visibility Controls
                    if (_allPartnerships.isNotEmpty)
                      BulkPartnershipVisibilityControls(
                        partnerships: _allPartnerships,
                        onBulkVisibilityChanged: _updateBulkVisibility,
                      ),
                    if (_allPartnerships.isNotEmpty) const SizedBox(height: 24),

                    // Partnerships Display
                    PartnershipDisplayWidget(
                      partnerships: _allPartnerships,
                      maxDisplayCount: 0, // Show all
                      showFilters: true,
                      showVisibilityControls: true,
                      onPartnershipTap: (partnership) {
                        // Navigate to partnership details if needed
                        // For now, just show a snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Partnership: ${partnership.partnerName}'),
                          ),
                        );
                      },
                      onVisibilityChanged: (isPublic) {
                        // This will be handled per-card in the widget
                        // But we can also handle it here if needed
                      },
                    ),

                    // Expertise Boost Section (if partnerships exist)
                    if (_allPartnerships.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildExpertiseBoostSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExpertiseBoostSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Expertise Boost',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your partnerships contribute to your expertise calculation. '
              'Active and completed partnerships boost your expertise in related categories.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Navigate to expertise dashboard
                // context.go('/profile/expertise-dashboard');
              },
              icon: const Icon(Icons.school),
              label: const Text('View Expertise Dashboard'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

