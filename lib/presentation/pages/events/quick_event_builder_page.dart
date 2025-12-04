import 'package:flutter/material.dart';
import 'package:spots/core/models/event_template.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/services/event_template_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/pages/events/event_published_page.dart';

/// OUR_GUTS.md: "The key opens doors to events"
/// Easy Event Hosting - Phase 2: Quick Event Builder
/// Philosophy: 5-7 minutes → 30 seconds (Instagram Stories-like creation)
class QuickEventBuilderPage extends StatefulWidget {
  final UnifiedUser currentUser;
  final EventTemplate? preselectedTemplate;
  final ExpertiseEvent? copyFrom; // For "Host Again" feature
  final bool isBusinessAccount; // For business-only templates
  
  const QuickEventBuilderPage({
    Key? key,
    required this.currentUser,
    this.preselectedTemplate,
    this.copyFrom,
    this.isBusinessAccount = false,
  }) : super(key: key);
  
  @override
  State<QuickEventBuilderPage> createState() => _QuickEventBuilderPageState();
}

class _QuickEventBuilderPageState extends State<QuickEventBuilderPage> {
  final _templateService = EventTemplateService();
  final _eventService = ExpertiseEventService();
  
  int _currentStep = 0;
  EventTemplate? _selectedTemplate;
  DateTime? _selectedDateTime;
  List<Spot> _selectedSpots = [];
  int _maxAttendees = 20;
  double? _price;
  String? _customTitle;
  String? _customDescription;
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    
    // Pre-select template if provided
    if (widget.preselectedTemplate != null) {
      _selectedTemplate = widget.preselectedTemplate;
      _currentStep = 1; // Skip to date/time selection
    }
    
    // Pre-fill from existing event (Copy/Host Again)
    if (widget.copyFrom != null) {
      _prefillFromEvent(widget.copyFrom!);
    }
  }
  
  void _prefillFromEvent(ExpertiseEvent event) {
    // Find matching template
    final templates = _templateService.getAllTemplates();
    _selectedTemplate = templates.firstWhere(
      (t) => t.category == event.category && t.eventType == event.eventType,
      orElse: () => templates.first,
    );
    
    // Copy spots and settings
    _selectedSpots = event.spots;
    _maxAttendees = event.maxAttendees;
    _price = event.price;
    _customTitle = event.title;
    _customDescription = event.description;
    
    // Auto-suggest next available time (next weekend)
    _selectedDateTime = _suggestNextWeekend();
  }
  
  DateTime _suggestNextWeekend() {
    final now = DateTime.now();
    var saturday = now.add(Duration(days: (DateTime.saturday - now.weekday) % 7));
    if (saturday.isBefore(now)) {
      saturday = saturday.add(const Duration(days: 7));
    }
    return DateTime(saturday.year, saturday.month, saturday.day, 10, 0); // 10 AM Saturday
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Event',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _canGoBack && !_isLoading ? _previousStep : null,
              child: Text('Back', style: TextStyle(color: AppTheme.primaryColor)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? AppTheme.primaryColor
                      : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTemplateSelection();
      case 1:
        return _buildDateTimeSelection();
      case 2:
        return _buildSpotSelection();
      case 3:
        return _buildReviewPublish();
      default:
        return const SizedBox();
    }
  }
  
  // ========================================================================
  // STEP 1: TEMPLATE SELECTION
  // ========================================================================
  
  Widget _buildTemplateSelection() {
    // Filter templates based on account type
    final templates = widget.isBusinessAccount
        ? _templateService.getBusinessTemplates()
        : _templateService.getExpertTemplates();
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Choose Event Type',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a template to get started quickly',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...templates.map((template) => _buildTemplateCard(template)).toList(),
      ],
    );
  }
  
  Widget _buildTemplateCard(EventTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = template;
          _maxAttendees = template.defaultMaxAttendees;
          _price = template.suggestedPrice;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  template.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${template.defaultDuration.inHours}h • ${template.recommendedSpotCount} spots • ${template.getPriceDisplay()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (template.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: template.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 28),
          ],
        ),
      ),
    );
  }
  
  // ========================================================================
  // STEP 2: DATE & TIME SELECTION
  // ========================================================================
  
  Widget _buildDateTimeSelection() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'When?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose date and time for your event',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        
        // Quick date options
        Text(
          'Quick Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickDateOption('This Weekend', _suggestNextWeekend()),
        _buildQuickDateOption('Next Weekend', _suggestNextWeekend().add(const Duration(days: 7))),
        
        const SizedBox(height: 32),
        
        // Custom date picker
        ElevatedButton.icon(
          onPressed: _pickCustomDateTime,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _selectedDateTime == null
                ? 'Choose Custom Date'
                : 'Selected: ${_formatDateTime(_selectedDateTime!)}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.grey300),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickDateOption(String label, DateTime dateTime) {
    final isSelected = _selectedDateTime != null &&
        _selectedDateTime!.year == dateTime.year &&
        _selectedDateTime!.month == dateTime.month &&
        _selectedDateTime!.day == dateTime.day;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedDateTime = dateTime),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatDateTime(dateTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  String _formatDateTime(DateTime dt) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month ${dt.day} at $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
  
  // ========================================================================
  // STEP 3: SPOT SELECTION (Simplified for now)
  // ========================================================================
  
  Widget _buildSpotSelection() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Choose Spots',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select ${_selectedTemplate?.recommendedSpotCount ?? 3} spots for your event',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        
        // Placeholder for spot selection
        // In full implementation, this would show user's spots in category
        Center(
          child: Column(
            children: [
              Icon(Icons.location_on, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Spot selection UI coming soon',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'For now, spots will be selected automatically',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ========================================================================
  // STEP 4: REVIEW & PUBLISH
  // ========================================================================
  
  Widget _buildReviewPublish() {
    if (_selectedTemplate == null || _selectedDateTime == null) {
      return const Center(child: Text('Missing information'));
    }
    
    final event = _templateService.createEventFromTemplate(
      template: _selectedTemplate!,
      host: widget.currentUser,
      startTime: _selectedDateTime!,
      selectedSpots: _selectedSpots,
      customTitle: _customTitle,
      customDescription: _customDescription,
      customMaxAttendees: _maxAttendees,
      customPrice: _price,
    );
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Review & Publish',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Everything look good?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        
        // Event preview card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _selectedTemplate!.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.calendar_today, _formatDateTime(event.startTime)),
              _buildInfoRow(Icons.schedule, '${_selectedTemplate!.defaultDuration.inHours} hours'),
              _buildInfoRow(Icons.people, 'Max ${event.maxAttendees} attendees'),
              if (event.price != null)
                _buildInfoRow(Icons.attach_money, '\$${event.price!.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  // ========================================================================
  // NAVIGATION
  // ========================================================================
  
  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed && !_isLoading ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 3 ? 'Publish Event' : 'Continue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedTemplate != null;
      case 1:
        return _selectedDateTime != null;
      case 2:
        return true; // Spots optional for now
      case 3:
        return true;
      default:
        return false;
    }
  }
  
  bool get _canGoBack => _currentStep > 0;
  
  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _publishEvent();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  Future<void> _publishEvent() async {
    if (_selectedTemplate == null || _selectedDateTime == null) {
      setState(() {
        _error = 'Please complete all required steps';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create event from template
      final templateEvent = _templateService.createEventFromTemplate(
        template: _selectedTemplate!,
        host: widget.currentUser,
        startTime: _selectedDateTime!,
        selectedSpots: _selectedSpots,
        customTitle: _customTitle,
        customDescription: _customDescription,
        customMaxAttendees: _maxAttendees,
        customPrice: _price,
      );

      // Create event via service
      final event = await _eventService.createEvent(
        host: widget.currentUser,
        title: templateEvent.title,
        description: templateEvent.description,
        category: templateEvent.category,
        eventType: templateEvent.eventType,
        startTime: templateEvent.startTime,
        endTime: templateEvent.endTime,
        spots: templateEvent.spots,
        location: templateEvent.location,
        latitude: templateEvent.latitude,
        longitude: templateEvent.longitude,
        maxAttendees: templateEvent.maxAttendees,
        price: templateEvent.price,
        isPublic: templateEvent.isPublic,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Navigate to success page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EventPublishedPage(event: event),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to publish event: $e';
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
}

