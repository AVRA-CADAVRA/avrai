import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/reservations/reservation_detail_page.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_card_widget.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:go_router/go_router.dart';

/// My Reservations Page
/// Phase 15: Reservation System Implementation
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Display user's reservations
/// - Filter by status
/// - Sort by date
/// - Quick actions (cancel, modify)
class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ReservationService _reservationService;

  List<Reservation> _pendingReservations = [];
  List<Reservation> _confirmedReservations = [];
  List<Reservation> _cancelledReservations = [];
  List<Reservation> _pastReservations = [];

  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _reservationService = di.sl<ReservationService>();
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to view your reservations';
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
      // Load all reservations
      final reservations = await _reservationService.getUserReservations(
        userId: _currentUser!.id,
      );

      // Separate by status
      final now = DateTime.now();
      final pending = <Reservation>[];
      final confirmed = <Reservation>[];
      final cancelled = <Reservation>[];
      final past = <Reservation>[];

      for (final reservation in reservations) {
        if (reservation.status == ReservationStatus.cancelled) {
          cancelled.add(reservation);
        } else if (reservation.reservationTime.isBefore(now)) {
          past.add(reservation);
        } else if (reservation.status == ReservationStatus.pending) {
          pending.add(reservation);
        } else if (reservation.status == ReservationStatus.confirmed) {
          confirmed.add(reservation);
        }
      }

      // Sort by date (upcoming first)
      pending.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
      confirmed.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
      cancelled.sort((a, b) => b.reservationTime.compareTo(a.reservationTime));
      past.sort((a, b) => b.reservationTime.compareTo(a.reservationTime));

      setState(() {
        _pendingReservations = pending;
        _confirmedReservations = confirmed;
        _cancelledReservations = cancelled;
        _pastReservations = past;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error loading reservations: $e',
        name: 'MyReservationsPage',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  List<Reservation> _getReservationsForTab(int index) {
    switch (index) {
      case 0:
        return _pendingReservations;
      case 1:
        return _confirmedReservations;
      case 2:
        return _cancelledReservations;
      case 3:
        return _pastReservations;
      default:
        return [];
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Pending (${_pendingReservations.length})';
      case 1:
        return 'Confirmed (${_confirmedReservations.length})';
      case 2:
        return 'Cancelled (${_cancelledReservations.length})';
      case 3:
        return 'Past (${_pastReservations.length})';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          Semantics(
            label: 'View reservation analytics',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () {
                context.push('/reservations/analytics');
              },
              tooltip: 'View Analytics',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          indicatorColor: AppColors.white,
          tabs: [
            Tab(text: _getTabTitle(0)),
            Tab(text: _getTabTitle(1)),
            Tab(text: _getTabTitle(2)),
            Tab(text: _getTabTitle(3)),
          ],
        ),
      ),
      body: _isLoading
          ? Semantics(
              label: 'Loading reservations',
              child: const Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? Semantics(
                  label: 'Error loading reservations: $_error',
                  liveRegion: true,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.errorColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: 'Retry loading reservations',
                          button: true,
                          child: ElevatedButton(
                            onPressed: _loadReservations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(4, (index) {
                    final reservations = _getReservationsForTab(index);
                    return reservations.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No reservations',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReservations,
                            child: ListView.builder(
                              itemCount: reservations.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, i) {
                                final reservation = reservations[i];
                                return ReservationCardWidget(
                                  reservation: reservation,
                                  onTap: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ReservationDetailPage(
                                          reservationId: reservation.id,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadReservations();
                                    }
                                  },
                                );
                              },
                            ),
                          );
                  }),
                ),
      floatingActionButton: Semantics(
        label: 'Create new reservation',
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).pushNamed('/reservations/create');
            if (result != null) {
              _loadReservations();
            }
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Get user-friendly error message from exception
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error. Your reservations are available offline.';
    }
    
    // Not found errors
    if (errorString.contains('not found') || errorString.contains('does not exist')) {
      return 'Unable to load reservations. Please try again.';
    }
    
    // Generic error
    return 'Failed to load reservations. Please try again.';
  }
}
