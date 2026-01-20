import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/controllers/event_creation_controller.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';

/// Community Event Creation Form Page
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 28)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Simplified event creation form (no expertise required)
/// - Community events are free (no payment on app)
/// - Public events only
/// - Integration with CommunityEventService (to be created by Agent 1)
class CreateCommunityEventPage extends StatefulWidget {
  const CreateCommunityEventPage({super.key});

  @override
  State<CreateCommunityEventPage> createState() => _CreateCommunityEventPageState();
}

class _CreateCommunityEventPageState extends State<CreateCommunityEventPage> {
  final _formKey = GlobalKey<FormState>();
  
  // TODO: Replace with CommunityEventService when Agent 1 creates it
  // Using EventCreationController for now
  late final EventCreationController _eventCreationController;
  
  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  ExpertiseEventType? _selectedEventType;
  DateTime? _startTime;
  DateTime? _endTime;
  final _locationController = TextEditingController();
  int _maxAttendees = 20;
  // ignore: unused_field
  final bool _isPublic = true; // Always true for community events
  
  // State
  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;
  
  // Available categories (all categories, not just user's expertise)
  final List<String> _availableCategories = [
    'Coffee',
    'Bookstores',
    'Restaurants',
    'Bars',
    'Parks',
    'Museums',
    'Music',
    'Art',
    'Sports',
    'Other',
  ];
  
  // Event types
  final List<ExpertiseEventType> _eventTypes = ExpertiseEventType.values;

  @override
  void initState() {
    super.initState();
    _eventCreationController = GetIt.instance<EventCreationController>();
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
        _error = 'Please sign in to create community events';
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
        initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now().add(const Duration(hours: 1))),
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
        initialTime: TimeOfDay.fromDateTime(_endTime ?? _startTime!.add(const Duration(hours: 2))),
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

  Future<void> _createEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Validate form
      if (!_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validate required fields
      if (_selectedCategory == null || _selectedEventType == null) {
        setState(() {
          _error = 'Please select a category and event type';
          _isLoading = false;
        });
        return;
      }

      // Validate dates
      if (_startTime == null || _endTime == null) {
        setState(() {
          _error = 'Please select start and end times';
          _isLoading = false;
        });
        return;
      }

      if (_endTime!.isBefore(_startTime!)) {
        setState(() {
          _error = 'End time must be after start time';
          _isLoading = false;
        });
        return;
      }

      if (_startTime!.isBefore(DateTime.now())) {
        setState(() {
          _error = 'Start time must be in the future';
          _isLoading = false;
        });
        return;
      }

      // Use EventCreationController for event creation
      // Community events: price must be null or 0.0, isPaid must be false, isPublic must be true
      final formData = EventFormData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        eventType: _selectedEventType!,
        startTime: _startTime!,
        endTime: _endTime!,
        location: _locationController.text.trim(),
        maxAttendees: _maxAttendees,
        price: null, // Community events are free
        isPublic: true, // Community events must be public
      );

      final result = await _eventCreationController.createEvent(
        formData: formData,
        host: _currentUser!,
      );

      setState(() {
        _isLoading = false;
      });

      if (!result.isSuccess) {
        setState(() {
          _error = result.error ?? 'Failed to create community event';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (mounted && result.event != null) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Community event "${result.event!.title}" created successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate back
        Navigator.pop(context, result.event);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create community event: $e';
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

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null && _error == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Create Community Event',
            style: TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create Community Event',
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
              // Community Event Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.electricGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.electricGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Community events are free and open to everyone. No expertise required!',
                        style: TextStyle(
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
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
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
                      color: _startTime != null ? AppColors.textPrimary : AppColors.textHint,
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
                      color: _endTime != null ? AppColors.textPrimary : AppColors.textHint,
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

              // Public Event Indicator (always public for community events)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.electricGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.public, color: AppColors.electricGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Community events are always public',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  onPressed: _isLoading ? null : _createEvent,
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
                          'Create Community Event',
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
        return 'Tour';
      case ExpertiseEventType.workshop:
        return 'Workshop';
      case ExpertiseEventType.tasting:
        return 'Tasting';
      case ExpertiseEventType.meetup:
        return 'Meetup';
      case ExpertiseEventType.walk:
        return 'Walk';
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

