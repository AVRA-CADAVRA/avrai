import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_recommendation_service.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/core/services/reservation_rate_limit_service.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/controllers/reservation_creation_controller.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/reservations/reservation_confirmation_page.dart';
import 'package:avrai/presentation/widgets/reservations/time_slot_picker_widget.dart';
import 'package:avrai/presentation/widgets/reservations/party_size_picker_widget.dart';
import 'package:avrai/presentation/widgets/reservations/ticket_count_picker_widget.dart';
import 'package:avrai/presentation/widgets/reservations/pricing_display_widget.dart';
import 'package:avrai/presentation/widgets/reservations/rate_limit_warning_widget.dart';
import 'package:avrai/presentation/widgets/reservations/waitlist_join_widget.dart';
import 'package:avrai/presentation/widgets/reservations/special_requests_widget.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_suggestions_widget.dart';
import 'package:avrai/injection_container.dart' as di;

/// Reservation Creation Page
/// Phase 15: Reservation System Implementation
/// Section 15.2.1: Reservation Creation UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Form for reservation details
/// - Integration with spots/events/businesses
/// - Quantum compatibility display
/// - Rate limit checking
/// - Availability checking
/// - Waitlist support
/// - Confirmation flow
class CreateReservationPage extends StatefulWidget {
  final ReservationType? type;
  final String? targetId;
  final String? targetTitle;

  const CreateReservationPage({
    super.key,
    this.type,
    this.targetId,
    this.targetTitle,
  });

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  final _formKey = GlobalKey<FormState>();
  late final ReservationCreationController _controller;
  late final ReservationService _reservationService;
  late final ReservationRecommendationService _recommendationService;
  late final ReservationAvailabilityService? _availabilityService;
  late final ReservationRateLimitService? _rateLimitService;
  late final ReservationWaitlistService? _waitlistService;
  late final ExpertiseEventService _eventService;

  // Form fields
  ReservationType? _selectedType;
  String? _selectedTargetId;
  String? _selectedTargetTitle;
  DateTime? _reservationTime;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  int _partySize = 1;
  int _ticketCount = 1;
  String? _specialRequests;
  double? _ticketPrice;
  double? _depositAmount;
  double? _compatibilityScore;

  // State
  bool _isLoading = false;
  bool _isLoadingCompatibility = false;
  bool _isCheckingAvailability = false;
  String? _error;
  UnifiedUser? _currentUser;
  List<Map<String, dynamic>> _availableTargets = [];
  
  // Rate limit and availability state
  RateLimitCheckResult? _rateLimitResult;
  AvailabilityResult? _availabilityResult;
  bool _showWaitlist = false;
  
  // Performance optimization: Debounce timers
  Timer? _availabilityDebounceTimer;
  Timer? _compatibilityDebounceTimer;
  
  // Performance optimization: Cache compatibility scores
  final Map<String, double> _compatibilityCache = {};

  @override
  void initState() {
    super.initState();
    _controller = di.sl<ReservationCreationController>();
    _reservationService = di.sl<ReservationService>();
    _recommendationService = di.sl<ReservationRecommendationService>();
    _availabilityService = di.sl.isRegistered<ReservationAvailabilityService>()
        ? di.sl<ReservationAvailabilityService>()
        : null;
    _rateLimitService = di.sl.isRegistered<ReservationRateLimitService>()
        ? di.sl<ReservationRateLimitService>()
        : null;
    _waitlistService = di.sl.isRegistered<ReservationWaitlistService>()
        ? di.sl<ReservationWaitlistService>()
        : null;
    _eventService = ExpertiseEventService();

    // Pre-fill from widget parameters
    _selectedType = widget.type;
    _selectedTargetId = widget.targetId;
    _selectedTargetTitle = widget.targetTitle;
    if (_selectedTargetId != null && _selectedType != null) {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    }

    _loadUserData();
    _loadAvailableTargets();
    if (_selectedTargetId != null) {
      _checkRateLimit();
    }
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to create reservations';
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
  }

  Future<void> _loadAvailableTargets() async {
    if (_selectedType == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_selectedType == ReservationType.event) {
        // Load events
        final events = await _eventService.searchEvents(maxResults: 50);
        setState(() {
          _availableTargets = events.map((e) => {
            'id': e.id,
            'title': e.title,
            'type': 'event',
            'startTime': e.startTime,
            'endTime': e.endTime,
          }).toList();
        });
      } else {
        // For spots and businesses, we'd load from their respective services
        // For now, if targetId is provided, use it
        if (_selectedTargetId != null && _selectedTargetTitle != null) {
          setState(() {
            _availableTargets = [{
              'id': _selectedTargetId,
              'title': _selectedTargetTitle,
              'type': _selectedType.toString(),
            }];
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load available options: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkRateLimit() async {
    if (_currentUser == null ||
        _selectedType == null ||
        _selectedTargetId == null ||
        _rateLimitService == null) {
      return;
    }

    try {
      final result = await _rateLimitService!.checkRateLimit(
        userId: _currentUser!.id,
        type: _selectedType!,
        targetId: _selectedTargetId!,
        reservationTime: _reservationTime,
      );

      setState(() {
        _rateLimitResult = result;
      });
    } catch (e) {
      developer.log(
        'Rate limit check failed: $e',
        name: 'CreateReservationPage',
      );
      setState(() {
        _rateLimitResult = null;
      });
    }
  }

  Future<void> _checkAvailability() async {
    if (_currentUser == null ||
        _selectedType == null ||
        _selectedTargetId == null ||
        _reservationTime == null ||
        _availabilityService == null) {
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
      _showWaitlist = false;
    });

    try {
      final result = await _availabilityService!.checkAvailability(
        type: _selectedType!,
        targetId: _selectedTargetId!,
        reservationTime: _reservationTime!,
        partySize: _partySize,
        ticketCount: _ticketCount,
      );

      setState(() {
        _availabilityResult = result;
        _showWaitlist = !result.isAvailable && result.waitlistAvailable;
        _isCheckingAvailability = false;
      });
    } catch (e) {
      developer.log(
        'Error checking availability: $e',
        name: 'CreateReservationPage',
      );
      setState(() {
        _availabilityResult = null;
        _showWaitlist = false;
        _isCheckingAvailability = false;
      });
    }
  }

  void _onTimeSelected(DateTime time) {
    setState(() {
      _reservationTime = time;
      _selectedTime = time;
      _selectedDate = DateTime(time.year, time.month, time.day);
    });
    // Debounce compatibility and availability checks (performance optimization)
    _debounceCompatibilityCheck();
    _debounceAvailabilityCheck();
  }
  
  /// Debounced compatibility check (performance optimization)
  void _debounceCompatibilityCheck() {
    _compatibilityDebounceTimer?.cancel();
    _compatibilityDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _calculateCompatibility();
      }
    });
  }
  
  /// Debounced availability check (performance optimization)
  void _debounceAvailabilityCheck() {
    _availabilityDebounceTimer?.cancel();
    _availabilityDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkAvailability();
      }
    });
  }

  void _onPartySizeChanged(int size) {
    setState(() {
      _partySize = size;
      // Auto-update ticket count to match party size if not manually set
      if (_ticketCount < size) {
        _ticketCount = size;
      }
    });
    if (_reservationTime != null) {
      _debounceAvailabilityCheck();
    }
  }

  void _onTicketCountChanged(int count) {
    setState(() {
      _ticketCount = count;
    });
    if (_reservationTime != null) {
      _debounceAvailabilityCheck();
    }
  }

  Future<void> _calculateCompatibility() async {
    if (_currentUser == null || _selectedTargetId == null || _reservationTime == null) {
      return;
    }

    // Performance optimization: Check cache first
    final cacheKey = '${_currentUser!.id}_${_selectedTargetId}_${_reservationTime!.millisecondsSinceEpoch ~/ 3600000}'; // Cache by hour
    if (_compatibilityCache.containsKey(cacheKey)) {
      setState(() {
        _compatibilityScore = _compatibilityCache[cacheKey];
      });
      return;
    }

    setState(() {
      _isLoadingCompatibility = true;
    });

    try {
      // Get recommendations to find compatibility score
      final recommendations = await _recommendationService.getQuantumMatchedReservations(
        userId: _currentUser!.id,
        limit: 50,
      );

      final matchingRecommendation = recommendations.firstWhere(
        (r) => r.targetId == _selectedTargetId,
        orElse: () => recommendations.first,
      );

      // Cache compatibility score (performance optimization)
      _compatibilityCache[cacheKey] = matchingRecommendation.compatibility;
      
      // Limit cache size (performance optimization)
      if (_compatibilityCache.length > 50) {
        final oldestKey = _compatibilityCache.keys.first;
        _compatibilityCache.remove(oldestKey);
      }

      setState(() {
        _compatibilityScore = matchingRecommendation.compatibility;
      });
    } catch (e) {
      developer.log(
        'Compatibility calculation failed: $e',
        name: 'CreateReservationPage',
      );
      // Compatibility calculation failed, continue without it
      setState(() {
        _compatibilityScore = null;
      });
    } finally {
      setState(() {
        _isLoadingCompatibility = false;
      });
    }
  }

  Future<void> _createReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser == null) {
      setState(() {
        _error = 'Please sign in to create reservations';
      });
      return;
    }

    if (_selectedType == null || _selectedTargetId == null || _reservationTime == null) {
      setState(() {
        _error = 'Please fill in all required fields';
      });
      return;
    }

    // Check rate limit
    if (_rateLimitResult != null && !_rateLimitResult!.allowed) {
      setState(() {
        _error = _rateLimitResult!.reason ?? 'Rate limit exceeded';
      });
      return;
    }

    // Check availability
    if (_availabilityResult != null && !_availabilityResult!.isAvailable && !_showWaitlist) {
      setState(() {
        _error = _availabilityResult!.reason ?? 'Reservation not available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check for existing reservation
      final hasExisting = await _reservationService.hasExistingReservation(
        userId: _currentUser!.id,
        type: _selectedType!,
        targetId: _selectedTargetId!,
        reservationTime: _reservationTime!,
      );

      if (hasExisting) {
        setState(() {
          _error = 'You already have a reservation for this at this time';
          _isLoading = false;
        });
        return;
      }

      // Create reservation using controller (orchestrates all services)
      final input = ReservationCreationInput(
        userId: _currentUser!.id,
        type: _selectedType!,
        targetId: _selectedTargetId!,
        reservationTime: _reservationTime!,
        partySize: _partySize,
        ticketCount: _ticketCount,
        specialRequests: _specialRequests?.isEmpty ?? true ? null : _specialRequests,
        ticketPrice: _ticketPrice,
        depositAmount: _depositAmount,
      );

      // Validate input
      final validation = _controller.validate(input);
      if (!validation.isValid) {
        setState(() {
          _error = validation.firstError ?? 'Validation failed';
          _isLoading = false;
        });
        return;
      }

      // Execute workflow
      final result = await _controller.execute(input);

      if (!result.success) {
        setState(() {
          _error = result.error ?? 'Failed to create reservation';
          _isLoading = false;
        });
        return;
      }

      final reservation = result.reservation!;

      // Navigate to confirmation page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ReservationConfirmationPage(
              reservation: reservation,
              compatibilityScore: result.compatibilityScore,
              queuePosition: result.queuePosition,
              waitlistPosition: result.waitlistPosition,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error creating reservation: $e',
        name: 'CreateReservationPage',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reservation'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
      ),
      body: _currentUser == null
          ? Semantics(
              label: 'Loading user information',
              child: const Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Semantics(
                        label: 'Error: $_error',
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.errorColor),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ),

                    // AI-Powered Reservation Suggestions (Phase 6.2)
                    // Show suggestions when no target is selected
                    if (_selectedTargetId == null && _currentUser != null)
                      ReservationSuggestionsWidget(
                        userId: _currentUser!.id,
                        recommendationService: _recommendationService,
                        maxSuggestions: 5,
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            _selectedType = suggestion.type;
                            _selectedTargetId = suggestion.targetId;
                            _selectedTargetTitle = suggestion.title;
                            if (suggestion.recommendedTime != null) {
                              _reservationTime = suggestion.recommendedTime;
                              _selectedDate = DateTime(
                                suggestion.recommendedTime!.year,
                                suggestion.recommendedTime!.month,
                                suggestion.recommendedTime!.day,
                              );
                              _selectedTime = suggestion.recommendedTime;
                            }
                          });
                          _loadAvailableTargets();
                          _checkRateLimit();
                          _calculateCompatibility();
                        },
                      ),

                    if (_selectedTargetId == null && _currentUser != null)
                      const SizedBox(height: 16),

                    // Reservation Type
                    Semantics(
                      label: 'Reservation type',
                      hint: 'Select whether this is a spot, business, or event reservation',
                      child: DropdownButtonFormField<ReservationType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Reservation Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event, color: AppTheme.primaryColor),
                        ),
                        items: ReservationType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                            _selectedTargetId = null;
                            _selectedTargetTitle = null;
                            _rateLimitResult = null;
                            _availabilityResult = null;
                            _showWaitlist = false;
                          });
                          _loadAvailableTargets();
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a reservation type';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Target Selection (Event/Spot/Business)
                    if (_selectedType != null && _availableTargets.isNotEmpty)
                      Semantics(
                        label: _selectedType == ReservationType.event
                            ? 'Select event'
                            : _selectedType == ReservationType.spot
                                ? 'Select spot'
                                : 'Select business',
                        hint: 'Choose the ${_selectedType == ReservationType.event ? 'event' : _selectedType == ReservationType.spot ? 'spot' : 'business'} for your reservation',
                        child: DropdownButtonFormField<String>(
                          value: _selectedTargetId,
                          decoration: InputDecoration(
                            labelText: _selectedType == ReservationType.event
                                ? 'Select Event'
                                : _selectedType == ReservationType.spot
                                    ? 'Select Spot'
                                    : 'Select Business',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                          ),
                          items: _availableTargets.map((target) {
                            return DropdownMenuItem(
                              value: target['id'] as String,
                              child: Text(target['title'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTargetId = value;
                              _selectedTargetTitle = _availableTargets
                                  .firstWhere((t) => t['id'] == value)['title'] as String;
                              _rateLimitResult = null;
                              _availabilityResult = null;
                              _showWaitlist = false;
                            });
                            _checkRateLimit();
                            _calculateCompatibility();
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a target';
                            }
                            return null;
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Rate Limit Warning
                    if (_selectedTargetId != null && _rateLimitService != null)
                      RateLimitWarningWidget(
                        rateLimitResult: _rateLimitResult,
                        userId: _currentUser?.id,
                        type: _selectedType,
                        targetId: _selectedTargetId,
                      ),

                    const SizedBox(height: 16),

                    // Time Slot Picker
                    if (_selectedType != null && _selectedTargetId != null)
                      TimeSlotPickerWidget(
                        type: _selectedType!,
                        targetId: _selectedTargetId!,
                        initialDate: _selectedDate,
                        initialTime: _selectedTime,
                        availabilityService: _availabilityService,
                        onTimeSelected: _onTimeSelected,
                        onError: (error) {
                          setState(() {
                            _error = error;
                          });
                        },
                      ),

                    const SizedBox(height: 16),

                    // Party Size Picker
                    PartySizePickerWidget(
                      initialPartySize: _partySize,
                      onPartySizeChanged: _onPartySizeChanged,
                      maxPartySize: 100,
                    ),

                    const SizedBox(height: 16),

                    // Ticket Count Picker
                    TicketCountPickerWidget(
                      initialTicketCount: _ticketCount,
                      partySize: _partySize,
                      onTicketCountChanged: _onTicketCountChanged,
                    ),

                    const SizedBox(height: 16),

                    // Pricing Display
                    if (_ticketPrice != null || _depositAmount != null)
                      PricingDisplayWidget(
                        ticketPrice: _ticketPrice,
                        ticketCount: _ticketCount,
                        depositAmount: _depositAmount,
                        isFree: _ticketPrice == null && _depositAmount == null,
                      ),

                    const SizedBox(height: 16),

                    // Special Requests
                    SpecialRequestsWidget(
                      initialValue: _specialRequests,
                      maxLength: 500,
                      onChanged: (value) {
                        setState(() {
                          _specialRequests = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Availability Result
                    if (_isCheckingAvailability)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Checking availability...',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else if (_availabilityResult != null && !_availabilityResult!.isAvailable && !_showWaitlist)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.errorColor),
                        ),
                        child: Text(
                          _availabilityResult!.reason ?? 'Reservation not available',
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),

                    // Waitlist Join Widget
                    if (_showWaitlist && _waitlistService != null && _currentUser != null && _selectedType != null && _selectedTargetId != null && _reservationTime != null)
                      WaitlistJoinWidget(
                        waitlistService: _waitlistService,
                        type: _selectedType!,
                        targetId: _selectedTargetId!,
                        reservationTime: _reservationTime!,
                        userId: _currentUser!.id,
                        partySize: _partySize,
                        onJoined: (entry) {
                          // Navigate to confirmation page with waitlist position
                          if (mounted && entry != null) {
                            // Create a temporary reservation for confirmation page
                            // In real implementation, this would be handled by the controller
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to waitlist!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        onError: (error) {
                          setState(() {
                            _error = error;
                          });
                        },
                      ),

                    const SizedBox(height: 24),

                    // Quantum Compatibility Score
                    if (_isLoadingCompatibility)
                      Semantics(
                        label: 'Calculating compatibility score',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Calculating compatibility...',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_compatibilityScore != null)
                      Semantics(
                        label: 'Quantum compatibility score: ${(_compatibilityScore! * 100).toStringAsFixed(0)} percent',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryColor),
                          ),
                          child: Row(
                            children: [
                              Semantics(
                                label: 'Compatibility star icon',
                                child: const Icon(Icons.star, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quantum Compatibility: ${(_compatibilityScore! * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Create Button
                    Semantics(
                      label: _isLoading
                          ? 'Creating reservation, please wait'
                          : (_rateLimitResult != null && !_rateLimitResult!.allowed)
                              ? 'Rate limit exceeded. ${_rateLimitResult!.reason ?? 'Please wait before creating another reservation.'}'
                              : (_availabilityResult != null && !_availabilityResult!.isAvailable && !_showWaitlist)
                                  ? 'Reservation not available. ${_availabilityResult!.reason ?? 'Please select a different time.'}'
                                  : 'Create reservation',
                      button: true,
                      enabled: !_isLoading &&
                          (_rateLimitResult == null || _rateLimitResult!.allowed) &&
                          (_availabilityResult == null || _availabilityResult!.isAvailable || _showWaitlist),
                      child: ElevatedButton(
                        onPressed: (_isLoading || 
                                    (_rateLimitResult != null && !_rateLimitResult!.allowed) ||
                                    (_availabilityResult != null && !_availabilityResult!.isAvailable && !_showWaitlist))
                            ? null
                            : _createReservation,
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
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              )
                            : const Text(
                                'Create Reservation',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _availabilityDebounceTimer?.cancel();
    _compatibilityDebounceTimer?.cancel();
    super.dispose();
  }

  /// Get user-friendly error message from exception
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Payment errors
    if (errorString.contains('payment') || errorString.contains('stripe')) {
      return 'Payment failed. Please check your payment method and try again.';
    }
    
    // Capacity errors
    if (errorString.contains('capacity') || errorString.contains('available')) {
      return 'No capacity available at this time. Please try another time.';
    }
    
    // Rate limit errors
    if (errorString.contains('rate limit') || errorString.contains('too many')) {
      return 'Too many reservations created. Please wait before creating another.';
    }
    
    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error. Your reservation has been saved locally and will sync when online.';
    }
    
    // Validation errors
    if (errorString.contains('invalid') || errorString.contains('validation')) {
      return 'Invalid reservation details. Please check your input and try again.';
    }
    
    // Generic error
    return 'Failed to create reservation. Please try again.';
  }
}
