import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/models/expertise_level.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/pages/events/event_review_page.dart';
import 'package:avrai/presentation/widgets/events/locality_selection_widget.dart';
import 'package:avrai/presentation/widgets/events/geographic_scope_indicator_widget.dart';
import 'package:avrai/core/services/geographic_scope_service.dart';

/// Event Creation Form Page
/// Agent 2: Event Discovery & Hosting UI (Week 3, Task 2.8)
///
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
///
/// Features:
/// - Simple event creation form
/// - Form validation
/// - Expertise verification (Local level+ required)
/// - Integration with ExpertiseEventService
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = ExpertiseEventService();
  final _geographicScopeService = GeographicScopeService();

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  ExpertiseEventType? _selectedEventType;
  DateTime? _startTime;
  DateTime? _endTime;
  final _locationController = TextEditingController();
  String? _selectedLocality; // Geographic scope: locality selection
  int _maxAttendees = 20;
  double? _price;
  bool _isPublic = true;

  // State
  bool _isLoading = false;
  String? _error;
  String? _expertiseError;
  String? _geographicScopeError; // Geographic scope validation error
  UnifiedUser? _currentUser;
  Map<String, ExpertiseLevel>? _userExpertise;

  // Available categories (from user's expertise)
  List<String> _availableCategories = [];

  // Event types
  final List<ExpertiseEventType> _eventTypes = ExpertiseEventType.values;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to create events';
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

    // Check if user can host events
    if (!_currentUser!.canHostEvents()) {
      setState(() {
        _expertiseError =
            'You need Local level or higher expertise to host events.\nBuild your expertise first!';
      });
      return;
    }

    // Get user's expertise categories
    setState(() {
      _availableCategories = _currentUser!.getExpertiseCategories();

      // Build expertise map
      _userExpertise = {};
      for (final category in _availableCategories) {
        final level = _currentUser!.getExpertiseLevel(category);
        if (level != null && level.index >= ExpertiseLevel.local.index) {
          _userExpertise![category] = level;
        }
      }

      // Filter categories to only those with Local level+
      _availableCategories = _userExpertise!.keys.toList();

      // Pre-select first category if available
      if (_availableCategories.isNotEmpty) {
        _selectedCategory = _availableCategories.first;
      }
    });
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _startTime ?? DateTime.now().add(const Duration(hours: 1))),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryColor,
                onPrimary: AppColors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (!mounted) return;

      if (time != null) {
        setState(() {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );

          // Auto-set end time to 2 hours after start if not set
          if (_endTime == null || _endTime!.isBefore(_startTime!)) {
            _endTime = _startTime!.add(const Duration(hours: 2));
          }
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    if (_startTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start time first'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime!.add(const Duration(hours: 2)),
      firstDate: _startTime!,
      lastDate: _startTime!.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
        },
      );
    if (!mounted) return;

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _endTime ?? _startTime!.add(const Duration(hours: 2))),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryColor,
                onPrimary: AppColors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (!mounted) return;

      if (time != null) {
        final selectedEnd = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        if (selectedEnd.isBefore(_startTime!)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        setState(() {
          _endTime = selectedEnd;
        });
      }
    }
  }

  /// Create event directly (bypassing review page)
  ///
  /// Note: Currently unused - event creation happens in EventReviewPage.
  /// Kept for potential future use (e.g., quick create without review).
  // ignore: unused_element
  Future<void> _createEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = await _eventService.createEvent(
        host: _currentUser!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        eventType: _selectedEventType!,
        startTime: _startTime!,
        endTime: _endTime!,
        location: _locationController.text.trim(),
        maxAttendees: _maxAttendees,
        price: _price,
        isPublic: _isPublic,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" created successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back
        Navigator.pop(context, event);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create event: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Validate geographic scope using GeographicScopeService
  bool _validateGeographicScope() {
    if (_currentUser == null || _selectedCategory == null) {
      return false;
    }

    // If no locality selected, check if it's required
    if (_selectedLocality == null || _selectedLocality!.isEmpty) {
      setState(() {
        _geographicScopeError = 'Please select a locality for your event.';
      });
      return false;
    }

    try {
      // Use GeographicScopeService to validate
      _geographicScopeService.validateEventLocation(
        userId: _currentUser!.id,
        user: _currentUser!,
        category: _selectedCategory!,
        eventLocality: _selectedLocality!,
      );

      setState(() {
        _geographicScopeError = null;
      });
      return true;
    } catch (e) {
      setState(() {
        _geographicScopeError = e.toString().replaceFirst('Exception: ', '');
      });
      return false;
    }
  }

  void _validateAndProceed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check expertise
    if (_selectedCategory == null ||
        !_currentUser!.hasExpertiseIn(_selectedCategory!)) {
      setState(() {
        _expertiseError =
            'You must have expertise in the selected category to host events.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category you have expertise in'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check expertise level
    final expertiseLevel = _currentUser!.getExpertiseLevel(_selectedCategory!);
    if (expertiseLevel == null ||
        expertiseLevel.index < ExpertiseLevel.local.index) {
      setState(() {
        _expertiseError =
            'You need Local level or higher expertise in $_selectedCategory to host events.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'You need Local level+ expertise in $_selectedCategory to host events'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate geographic scope
    if (!_validateGeographicScope()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _geographicScopeError ?? 'Geographic scope validation failed'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate dates
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end times'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to review page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventReviewPage(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          eventType: _selectedEventType!,
          startTime: _startTime!,
          endTime: _endTime!,
          location: _locationController.text.trim(),
          maxAttendees: _maxAttendees,
          price: _price,
          isPublic: _isPublic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_expertiseError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Create Event'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Event Hosting Unlocked',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _expertiseError!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create Event',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expertise Check Display
              if (_selectedCategory != null && _userExpertise != null) ...[
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
                      const Icon(Icons.check_circle,
                          color: AppColors.electricGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Expertise: ${_userExpertise![_selectedCategory!]?.displayName ?? "Unknown"} level in $_selectedCategory',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Event Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'Enter event title',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Event title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your event',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                items: _availableCategories.map((category) {
                  final level = _userExpertise![category];
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category),
                        if (level != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.electricGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              level.displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.electricGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _expertiseError = null;
                    _geographicScopeError = null;
                    _selectedLocality = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Geographic Scope Indicator
              if (_selectedCategory != null && _currentUser != null) ...[
                GeographicScopeIndicatorWidget(
                  user: _currentUser!,
                  category: _selectedCategory!,
                ),
                const SizedBox(height: 16),
              ],

              // Locality Selection
              if (_selectedCategory != null && _currentUser != null) ...[
                LocalitySelectionWidget(
                  user: _currentUser!,
                  category: _selectedCategory!,
                  selectedLocality: _selectedLocality,
                  errorMessage: _geographicScopeError,
                  onLocalitySelected: (locality) {
                    setState(() {
                      _selectedLocality = locality;
                      _geographicScopeError = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Event Type Dropdown
              DropdownButtonFormField<ExpertiseEventType>(
                initialValue: _selectedEventType,
                decoration: InputDecoration(
                  labelText: 'Event Type *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getEventTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Event type is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date/Time
              InkWell(
                onTap: _selectStartTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start Date & Time *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startTime != null
                        ? '${_formatDate(_startTime!)} at ${_formatTime(_startTime!)}'
                        : 'Select start time',
                    style: TextStyle(
                      color: _startTime != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End Date/Time
              InkWell(
                onTap: _selectEndTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date & Time *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endTime != null
                        ? '${_formatDate(_endTime!)} at ${_formatTime(_endTime!)}'
                        : 'Select end time',
                    style: TextStyle(
                      color: _endTime != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  hintText: 'Enter event location',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  suffixIcon: const Icon(Icons.location_on),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Max Attendees
              TextFormField(
                initialValue: _maxAttendees.toString(),
                decoration: InputDecoration(
                  labelText: 'Max Attendees',
                  hintText: 'Enter max attendees',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    _maxAttendees = parsed;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Price (Optional - if set, event is paid)
              TextFormField(
                initialValue: _price?.toStringAsFixed(2),
                decoration: InputDecoration(
                  labelText: 'Price (Optional)',
                  hintText: 'Leave empty for free event',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  prefixText: '\$ ',
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null && parsed >= 0) {
                    setState(() {
                      _price = parsed > 0 ? parsed : null;
                    });
                  } else {
                    setState(() {
                      _price = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Public/Private Toggle
              SwitchListTile(
                title: const Text('Public Event'),
                subtitle: const Text('Anyone can discover this event'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                activeThumbColor: AppTheme.primaryColor,
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text(
                          'Review & Publish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEventTypeDisplayName(ExpertiseEventType type) {
    switch (type) {
      case ExpertiseEventType.tour:
        return 'Expert Tour';
      case ExpertiseEventType.workshop:
        return 'Workshop';
      case ExpertiseEventType.tasting:
        return 'Tasting';
      case ExpertiseEventType.meetup:
        return 'Meetup';
      case ExpertiseEventType.walk:
        return 'Curated Walk';
      case ExpertiseEventType.lecture:
        return 'Lecture';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
