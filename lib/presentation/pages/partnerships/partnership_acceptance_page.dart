import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/partnerships/revenue_split_display.dart';
import 'package:spots/presentation/widgets/partnerships/compatibility_badge.dart';
import 'package:get_it/get_it.dart';

/// Partnership Acceptance Page
/// 
/// Allows businesses to view, accept, or decline partnership proposals.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipAcceptancePage extends StatefulWidget {
  final EventPartnership partnership;

  const PartnershipAcceptancePage({
    super.key,
    required this.partnership,
  });

  @override
  State<PartnershipAcceptancePage> createState() => _PartnershipAcceptancePageState();
}

class _PartnershipAcceptancePageState extends State<PartnershipAcceptancePage> {
  final _partnershipService = GetIt.instance<PartnershipService>();
  final _eventService = GetIt.instance<ExpertiseEventService>();
  final _paymentService = GetIt.instance<PaymentService>();
  
  bool _isLoading = false;
  ExpertiseEvent? _event;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final event = await _eventService.getEventById(widget.partnership.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptPartnership() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User must be signed in');
      }

      // Approve partnership (business side)
      await _partnershipService.approvePartnership(
        partnershipId: widget.partnership.id,
        approvedBy: authState.user.id,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partnership accepted!'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting partnership: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declinePartnership() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Partnership?'),
        content: const Text('Are you sure you want to decline this partnership proposal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Update partnership status to cancelled
      await _partnershipService.updatePartnershipStatus(
        partnershipId: widget.partnership.id,
        status: PartnershipStatus.cancelled,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partnership declined'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining partnership: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Partnership Proposal'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final event = _event!;
    final agreement = widget.partnership.agreement;
    final revenueSplit = widget.partnership.revenueSplit;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Partnership Proposal',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Proposal Header
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partnership Proposal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.partnership.user != null)
                    Text(
                      'from ${widget.partnership.user!.displayName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (widget.partnership.vibeCompatibilityScore != null) ...[
                    const SizedBox(height: 12),
                    CompatibilityBadge(
                      compatibility: widget.partnership.vibeCompatibilityScore!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Event Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.event, event.title),
                      _buildInfoRow(Icons.calendar_today, _formatDateTime(event.startTime)),
                      if (event.location != null)
                        _buildInfoRow(Icons.location_on, event.location!),
                      _buildInfoRow(Icons.people, '${event.maxAttendees} max attendees'),
                      if (event.price != null)
                        _buildInfoRow(Icons.attach_money, '\$${event.price!.toStringAsFixed(2)}/ticket'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Partnership Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partnership Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.handshake, 'Type: ${widget.partnership.type.displayName}'),
                      if (agreement != null && agreement.terms['revenueSplit'] != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.account_balance_wallet,
                          'Revenue Split: ${agreement.terms['revenueSplit']['userPercentage'].toStringAsFixed(0)}% / ${agreement.terms['revenueSplit']['businessPercentage'].toStringAsFixed(0)}%',
                        ),
                      ],
                      if (widget.partnership.sharedResponsibilities.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Responsibilities:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.partnership.sharedResponsibilities.map((resp) => Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.check, size: 16, color: AppColors.electricGreen),
                                  const SizedBox(width: 8),
                                  Text(
                                    resp,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      if (agreement?.customArrangementDetails != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Custom Terms:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          agreement!.customArrangementDetails!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Revenue Breakdown (if paid event)
            if (event.price != null && event.price! > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Revenue Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (revenueSplit != null)
                      RevenueSplitDisplay(
                        split: revenueSplit,
                        showDetails: true,
                        showLockStatus: false,
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Revenue split will be calculated after event details are finalized',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _acceptPartnership,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text(
                              'Accept Partnership',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _declinePartnership,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.grey300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dateTime.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dateTime.day} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $ampm';
  }
}

