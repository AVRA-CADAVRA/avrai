// Recurring Reservations Page
//
// Phase 10.3: Recurring Reservations
// Page for managing recurring reservation series
//
// Displays all recurring series and allows management actions

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/reservation_recurrence_service.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/injection_container.dart' as di;

/// Recurring Reservations Page
///
/// **Purpose:** Manage all recurring reservation series
///
/// **Features:**
/// - Display all recurring series
/// - Show series details (pattern, instances, status)
/// - Pause/resume series
/// - Cancel series
/// - Skip individual instances
/// - View series instances
///
/// **Phase 10.3:** Recurring reservations management with full AVRAI integration
class RecurringReservationsPage extends StatefulWidget {
  const RecurringReservationsPage({super.key});

  @override
  State<RecurringReservationsPage> createState() =>
      _RecurringReservationsPageState();
}

class _RecurringReservationsPageState extends State<RecurringReservationsPage> {
  static const String _logName = 'RecurringReservationsPage';

  late final ReservationRecurrenceService _recurrenceService;

  List<RecurringReservationSeries> _series = [];
  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _recurrenceService = di.sl<ReservationRecurrenceService>();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to view your recurring reservations';
      });
      return;
    }

    final user = authState.user;

    // Convert User to UnifiedUser
    _currentUser = UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO(Phase 10.3): Implement getUserSeries in service
      // For now, return empty list
      final series = await _recurrenceService.getUserSeries(_currentUser!.id);

      if (mounted) {
        setState(() {
          _series = series;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error loading recurring series: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = 'Failed to load recurring reservations: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pauseSeries(String seriesId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _recurrenceService.pauseSeries(seriesId);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recurring series paused'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadSeries();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to pause series'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  Future<void> _cancelSeries(String seriesId) async {
    // Confirm cancellation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recurring Series'),
        content: const Text(
          'Are you sure you want to cancel this recurring reservation series? This will not cancel existing reservations, but will stop creating new ones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _recurrenceService.cancelSeries(seriesId);

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recurring series cancelled'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadSeries();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to cancel series'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  String _getPatternLabel(RecurrencePatternType type, int interval) {
    switch (type) {
      case RecurrencePatternType.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrencePatternType.weekly:
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrencePatternType.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrencePatternType.custom:
        return 'Every $interval days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Reservations'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSeries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSeries,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _series.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.repeat,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No recurring reservations',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a recurring reservation to see it here',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _series.length,
                      itemBuilder: (context, index) {
                        final series = _series[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: Icon(
                              series.isPaused
                                  ? Icons.pause_circle
                                  : series.isCancelled
                                      ? Icons.cancel
                                      : Icons.repeat,
                              color: series.isPaused
                                  ? AppTheme.warningColor
                                  : series.isCancelled
                                      ? AppTheme.errorColor
                                      : AppTheme.primaryColor,
                            ),
                            title: Text(
                              _getPatternLabel(
                                series.pattern.type,
                                series.pattern.interval,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${series.instanceIds.length} reservation${series.instanceIds.length == 1 ? '' : 's'}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Pattern Details
                                    _DetailRow(
                                      label: 'Pattern',
                                      value: _getPatternLabel(
                                        series.pattern.type,
                                        series.pattern.interval,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Instances',
                                      value: '${series.instanceIds.length}',
                                    ),
                                    if (series.pattern.endDate != null) ...[
                                      const SizedBox(height: 8),
                                      _DetailRow(
                                        label: 'End Date',
                                        value: series.pattern.endDate!
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0],
                                      ),
                                    ],
                                    if (series.pattern.maxOccurrences !=
                                        null) ...[
                                      const SizedBox(height: 8),
                                      _DetailRow(
                                        label: 'Max Occurrences',
                                        value:
                                            '${series.pattern.maxOccurrences}',
                                      ),
                                    ],
                                    const SizedBox(height: 16),

                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: series.isPaused
                                            ? AppTheme.warningColor
                                                .withValues(alpha: 0.1)
                                            : series.isCancelled
                                                ? AppTheme.errorColor
                                                    .withValues(alpha: 0.1)
                                                : AppTheme.successColor
                                                    .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: series.isPaused
                                              ? AppTheme.warningColor
                                              : series.isCancelled
                                                  ? AppTheme.errorColor
                                                  : AppTheme.successColor,
                                        ),
                                      ),
                                      child: Text(
                                        series.isPaused
                                            ? 'Paused'
                                            : series.isCancelled
                                                ? 'Cancelled'
                                                : 'Active',
                                        style: TextStyle(
                                          color: series.isPaused
                                              ? AppTheme.warningColor
                                              : series.isCancelled
                                                  ? AppTheme.errorColor
                                                  : AppTheme.successColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        if (!series.isCancelled) ...[
                                          if (series.isPaused)
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _isLoading
                                                    ? null
                                                    : () {
                                                        // TODO(Phase 10.3): Implement resume
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Resume feature coming soon',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                icon: const Icon(
                                                  Icons.play_arrow,
                                                ),
                                                label: const Text('Resume'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppTheme.successColor,
                                                  side: const BorderSide(
                                                    color:
                                                        AppTheme.successColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _isLoading
                                                    ? null
                                                    : () => _pauseSeries(
                                                          series.id,
                                                        ),
                                                icon: const Icon(Icons.pause),
                                                label: const Text('Pause'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppTheme.warningColor,
                                                  side: const BorderSide(
                                                    color:
                                                        AppTheme.warningColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _isLoading
                                                ? null
                                                : () =>
                                                    _cancelSeries(series.id),
                                            icon: const Icon(Icons.cancel),
                                            label: const Text('Cancel'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppTheme.errorColor,
                                              side: const BorderSide(
                                                color: AppTheme.errorColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

/// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
