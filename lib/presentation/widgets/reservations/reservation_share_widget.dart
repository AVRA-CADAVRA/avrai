// Reservation Share Widget
//
// Phase 10.4: Reservation Sharing & Transfer
// Widget for sharing reservations with other users
//
// Allows users to share reservations with read-only or full access

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_sharing_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;

/// Reservation Share Widget
///
/// **Purpose:** Allow users to share reservations with other users
///
/// **Features:**
/// - User search/selection
/// - Permission level selection (read-only or full access)
/// - Share action
/// - Loading states
/// - Error handling
/// - Success feedback
///
/// **Phase 10.4:** Reservation sharing with full AVRAI system integration
class ReservationShareWidget extends StatefulWidget {
  final Reservation reservation;
  final VoidCallback? onShareComplete;
  final VoidCallback? onCancel;

  const ReservationShareWidget({
    super.key,
    required this.reservation,
    this.onShareComplete,
    this.onCancel,
  });

  @override
  State<ReservationShareWidget> createState() => _ReservationShareWidgetState();
}

class _ReservationShareWidgetState extends State<ReservationShareWidget> {
  static const String _logName = 'ReservationShareWidget';

  late final ReservationSharingService _sharingService;

  final TextEditingController _userSearchController = TextEditingController();
  String? _selectedUserId;
  String? _selectedUserName;
  SharingPermission _permission = SharingPermission.readOnly;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sharingService = di.sl<ReservationSharingService>();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  /// Share reservation with selected user
  Future<void> _shareReservation() async {
    if (_selectedUserId == null) {
      setState(() {
        _error = 'Please select a user to share with';
      });
      return;
    }

    // TODO(Phase 10.4): Get current user ID from auth context
    final ownerUserId = 'user_placeholder'; // Replace with actual userId

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _sharingService.shareReservation(
        reservationId: widget.reservation.id,
        ownerUserId: ownerUserId,
        sharedWithUserId: _selectedUserId!,
        permission: _permission,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reservation shared with $_selectedUserName successfully',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Notify parent
          widget.onShareComplete?.call();
        } else {
          setState(() {
            _error = result.error ?? 'Failed to share reservation';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to share reservation'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error sharing reservation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = 'Failed to share: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show user search dialog
  Future<void> _showUserSearch() async {
    // TODO(Phase 10.4): Implement user search functionality
    // For now, show a simple dialog with text input
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(),
              decoration: const InputDecoration(
                labelText: 'User ID or Email',
                hintText: 'Enter user ID or email',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, {
                    'userId': value,
                    'userName': value,
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Full user search coming soon',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Will be handled by onSubmitted
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedUserId = result['userId'];
        _selectedUserName = result['userName'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.share,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Share Reservation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reservation Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservation Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${widget.reservation.type.name}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Time: ${widget.reservation.reservationTime.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Party Size: ${widget.reservation.partySize}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // User Selection
          const Text(
            'Share With',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showUserSearch,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Select User',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                suffixIcon: Icon(Icons.search),
              ),
              child: Text(
                _selectedUserName ?? 'Tap to search for user',
                style: TextStyle(
                  color: _selectedUserName != null
                      ? AppColors.black
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Permission Level Selection
          const Text(
            'Permission Level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SharingPermission>(
            segments: [
              ButtonSegment(
                value: SharingPermission.readOnly,
                label: const Text('Read Only'),
                icon: const Icon(Icons.visibility),
              ),
              ButtonSegment(
                value: SharingPermission.fullAccess,
                label: const Text('Full Access'),
                icon: const Icon(Icons.edit),
              ),
            ],
            selected: {_permission},
            onSelectionChanged: (Set<SharingPermission> newSelection) {
              setState(() {
                _permission = newSelection.first;
              });
            },
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _permission == SharingPermission.readOnly
                      ? Icons.info_outline
                      : Icons.warning_amber_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _permission == SharingPermission.readOnly
                        ? 'User can view reservation details but cannot modify or cancel'
                        : 'User can view, modify, and cancel this reservation',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _shareReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : const Text('Share Reservation'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
