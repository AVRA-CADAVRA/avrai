import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/geo_hierarchy_service.dart';
import 'package:avrai/core/services/geographic_scope_service.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/expertise_level.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:get_it/get_it.dart';

/// Event Creation Controller
/// 
/// Orchestrates the complete event creation workflow. Coordinates validation,
/// expertise checks, geographic scope validation, and event creation.
/// 
/// **Responsibilities:**
/// - Validate form data (required fields, format)
/// - Verify user expertise (Local level+ required)
/// - Validate geographic scope (based on expertise level)
/// - Validate dates/times (future dates, logical ordering)
/// - Create event via ExpertiseEventService
/// - Handle payment validation (if paid event)
/// - Return unified result with validation errors
/// 
/// **Dependencies:**
/// - `ExpertiseEventService` - Create events
/// - `GeographicScopeService` - Validate geographic scope
/// 
/// **Usage:**
/// ```dart
/// final controller = EventCreationController();
/// final result = await controller.createEvent(
///   formData: EventFormData(
///     title: 'Coffee Tasting Tour',
///     description: 'Explore local coffee shops',
///     category: 'Coffee',
///     eventType: ExpertiseEventType.tour,
///     startTime: DateTime.now().add(Duration(days: 1)),
///     endTime: DateTime.now().add(Duration(days: 1, hours: 2)),
///     location: 'Greenpoint, Brooklyn',
///     locality: 'Greenpoint',
///     maxAttendees: 20,
///     price: 50.0,
///     isPublic: true,
///   ),
///   host: user,
/// );
/// 
/// if (result.isSuccess) {
///   final event = result.event!;
/// } else {
///   // Handle errors
///   final error = result.error;
///   final validationErrors = result.validationErrors;
/// }
/// ```
class EventCreationController implements WorkflowController<EventFormData, EventCreationResult> {
  static const String _logName = 'EventCreationController';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final ExpertiseEventService _eventService;
  final GeographicScopeService _geographicScopeService;
  final GeoHierarchyService _geoHierarchyService;
  // ignore: unused_field
  final AtomicClockService _atomicClock; // Reserved for future timestamp-based event tracking
  
  // AVRAI Core System Integration (optional, graceful degradation)
  final PersonalityKnotService? _personalityKnotService;
  final KnotStorageService? _knotStorageService;
  final KnotFabricService? _knotFabricService;
  final KnotWorldsheetService? _knotWorldsheetService;
  final KnotEvolutionStringService? _knotStringService;
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService? _quantumEntanglementService;
  final QuantumMatchingAILearningService? _aiLearningService;
  
  EventCreationController({
    ExpertiseEventService? eventService,
    GeographicScopeService? geographicScopeService,
    GeoHierarchyService? geoHierarchyService,
    AtomicClockService? atomicClock,
    PersonalityKnotService? personalityKnotService,
    KnotStorageService? knotStorageService,
    KnotFabricService? knotFabricService,
    KnotWorldsheetService? knotWorldsheetService,
    KnotEvolutionStringService? knotStringService,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    QuantumMatchingAILearningService? aiLearningService,
  })  : _eventService = eventService ?? GetIt.instance<ExpertiseEventService>(),
        _geographicScopeService =
            geographicScopeService ?? GetIt.instance<GeographicScopeService>(),
        _geoHierarchyService =
            geoHierarchyService ?? GetIt.instance<GeoHierarchyService>(),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _personalityKnotService = personalityKnotService ??
            (GetIt.instance.isRegistered<PersonalityKnotService>()
                ? GetIt.instance<PersonalityKnotService>()
                : null),
        _knotStorageService = knotStorageService ??
            (GetIt.instance.isRegistered<KnotStorageService>()
                ? GetIt.instance<KnotStorageService>()
                : null),
        _knotFabricService = knotFabricService ??
            (GetIt.instance.isRegistered<KnotFabricService>()
                ? GetIt.instance<KnotFabricService>()
                : null),
        _knotWorldsheetService = knotWorldsheetService ??
            (GetIt.instance.isRegistered<KnotWorldsheetService>()
                ? GetIt.instance<KnotWorldsheetService>()
                : null),
        _knotStringService = knotStringService ??
            (GetIt.instance.isRegistered<KnotEvolutionStringService>()
                ? GetIt.instance<KnotEvolutionStringService>()
                : null),
        _locationTimingService = locationTimingService ??
            (GetIt.instance.isRegistered<LocationTimingQuantumStateService>()
                ? GetIt.instance<LocationTimingQuantumStateService>()
                : null),
        _quantumEntanglementService = quantumEntanglementService ??
            (GetIt.instance.isRegistered<QuantumEntanglementService>()
                ? GetIt.instance<QuantumEntanglementService>()
                : null),
        _aiLearningService = aiLearningService ??
            (GetIt.instance.isRegistered<QuantumMatchingAILearningService>()
                ? GetIt.instance<QuantumMatchingAILearningService>()
                : null);
  
  @override
  Future<EventCreationResult> execute(EventFormData input) async {
    // This method is a convenience wrapper - actual implementation in createEvent
    // We need host which isn't in EventFormData, so we use createEvent directly
    throw UnimplementedError(
      'Use createEvent() method instead - requires host parameter',
    );
  }
  
  /// Create event workflow
  /// 
  /// Validates form data, checks expertise, validates geographic scope,
  /// validates dates, creates event, and validates payment setup if needed.
  /// 
  /// **Parameters:**
  /// - `formData`: Event form data (title, description, category, etc.)
  /// - `host`: UnifiedUser hosting the event
  /// 
  /// **Returns:**
  /// `EventCreationResult` with success status, created event, and any errors
  Future<EventCreationResult> createEvent({
    required EventFormData formData,
    required UnifiedUser host,
  }) async {
    try {
      _logger.info('🎯 Starting event creation workflow: ${formData.title}', tag: _logName);
      
      // STEP 1: Validate form data
      final formValidation = validateForm(formData);
      if (!formValidation.isValid) {
        _logger.warning(
          '❌ Form validation failed: ${formValidation.allErrors.join(", ")}',
          tag: _logName,
        );
        return EventCreationResult.failure(
          error: 'Form validation failed',
          errorCode: 'VALIDATION_ERROR',
          validationErrors: formValidation,
        );
      }
      
      // STEP 2: Validate expertise
      final expertiseValidation = validateExpertise(host, formData.category);
      if (!expertiseValidation.isValid) {
        _logger.warning(
          '❌ Expertise validation failed: ${expertiseValidation.error}',
          tag: _logName,
        );
        return EventCreationResult.failure(
          error: expertiseValidation.error ?? 'Expertise validation failed',
          errorCode: 'EXPERTISE_ERROR',
          validationErrors: ValidationResult.invalid(
            generalErrors: [expertiseValidation.error ?? 'Expertise validation failed'],
          ),
        );
      }
      
      // STEP 3: Validate geographic scope
      if (formData.locality != null && formData.locality!.isNotEmpty) {
        try {
          _geographicScopeService.validateEventLocation(
            userId: host.id,
            user: host,
            category: formData.category,
            eventLocality: formData.locality!,
          );
          _logger.debug('✅ Geographic scope validated', tag: _logName);
        } catch (e) {
          _logger.warning('❌ Geographic scope validation failed: $e', tag: _logName);
          return EventCreationResult.failure(
            error: e.toString().replaceFirst('Exception: ', ''),
            errorCode: 'GEOGRAPHIC_SCOPE_ERROR',
            validationErrors: ValidationResult.invalid(
              generalErrors: [e.toString().replaceFirst('Exception: ', '')],
            ),
          );
        }
      }
      
      // STEP 4: Validate dates
      final dateValidation = validateDates(formData.startTime, formData.endTime);
      if (!dateValidation.isValid) {
        _logger.warning(
          '❌ Date validation failed: ${dateValidation.allErrors.join(", ")}',
          tag: _logName,
        );
        return EventCreationResult.failure(
          error: 'Date validation failed',
          errorCode: 'DATE_ERROR',
          validationErrors: dateValidation,
        );
      }
      
      // STEP 5: Validate payment (if paid event)
      // Note: Price validation (including negative check) is already handled in validateForm()
      if (formData.price != null && formData.price! > 0) {
        _logger.debug('✅ Payment validation passed (paid event: \$${formData.price})', tag: _logName);
      }
      
      // STEP 6: Create event via service
      ExpertiseEvent createdEvent;
      try {
        // Strong geo: resolve canonical codes (best-effort, non-blocking).
        String? cityCode;
        String? localityCode;
        final locationHint = (formData.location ?? '').trim();
        final localityName = (formData.locality ?? '').trim();

        if (locationHint.isNotEmpty) {
          cityCode = await _geoHierarchyService.lookupCityCode(locationHint);
        }
        if ((cityCode == null || cityCode.isEmpty) &&
            localityName.isNotEmpty) {
          cityCode = await _geoHierarchyService.lookupCityCode(localityName);
        }
        if (cityCode != null &&
            cityCode.isNotEmpty &&
            localityName.isNotEmpty) {
          localityCode = await _geoHierarchyService.lookupLocalityCode(
            cityCode: cityCode,
            localityName: localityName,
          );
        }

        createdEvent = await _eventService.createEvent(
          host: host,
          title: formData.title,
          description: formData.description,
          category: formData.category,
          eventType: formData.eventType,
          startTime: formData.startTime,
          endTime: formData.endTime,
          spots: formData.spots,
          location: formData.location,
          latitude: formData.latitude,
          longitude: formData.longitude,
          cityCode: cityCode,
          localityCode: localityCode,
          maxAttendees: formData.maxAttendees,
          price: formData.price,
          isPublic: formData.isPublic,
        );
        _logger.info('✅ Event created successfully: ${createdEvent.id}', tag: _logName);
      } catch (e) {
        _logger.error('❌ Event creation failed: $e', error: e, tag: _logName);
        return EventCreationResult.failure(
          error: e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'CREATION_ERROR',
        );
      }
      
      // STEP 7: AVRAI Core System Integration (optional, graceful degradation)
      
      // 7.1: Generate/retrieve host personality knot
      if (_personalityKnotService != null && _knotStorageService != null) {
        try {
          // Get host's agentId (if available)
          // Note: Knot generation typically happens during onboarding
          // This ensures knot exists for event creation
          _logger.debug('ℹ️ Knot services available (knot should exist from onboarding)', tag: _logName);
        } catch (e) {
          _logger.warn('⚠️ Knot service check failed (non-blocking): $e', tag: _logName);
          // Continue - knot is optional enhancement
        }
      }
      
      // 7.2: Create 4D quantum location state for event
      if (_locationTimingService != null && formData.latitude != null && formData.longitude != null) {
        try {
          _logger.info(
            '🌐 Creating 4D quantum location state for event: ${formData.latitude}, ${formData.longitude}',
            tag: _logName,
          );
          
          // Re-resolve cityCode for quantum state creation (if needed)
          String? resolvedCityCode;
          final locationHint = (formData.location ?? '').trim();
          final localityName = (formData.locality ?? '').trim();
          
          if (locationHint.isNotEmpty) {
            resolvedCityCode = await _geoHierarchyService.lookupCityCode(locationHint);
          }
          if ((resolvedCityCode == null || resolvedCityCode.isEmpty) && localityName.isNotEmpty) {
            resolvedCityCode = await _geoHierarchyService.lookupCityCode(localityName);
          }
          
          // Create UnifiedLocationData from form data
          final locationData = UnifiedLocationData(
            latitude: formData.latitude!,
            longitude: formData.longitude!,
            city: resolvedCityCode,
            address: formData.location,
          );
          
          // Create location quantum state for event
          final locationQuantumState = await _locationTimingService!.createLocationQuantumState(
            location: locationData,
            locationType: 0.7, // Default to suburban/urban mix
            accessibilityScore: null, // Not available from form
            vibeLocationMatch: null, // Not available from form
          );
          
          // Create timing quantum state from event DateTime
          final timingQuantumState = await _locationTimingService!.createTimingQuantumStateFromDateTime(
            preferredTime: formData.startTime,
            frequencyPreference: 0.5, // Default frequency
            durationPreference: 0.5, // Default duration
            timingVibeMatch: null, // Not available from form
          );
          
          _logger.info(
            '✅ 4D quantum states created for event (location + timing)',
            tag: _logName,
          );
          
          // Note: Quantum states are created but not yet stored with event
          // Future integration: Store quantum states with event via event service
          // For now, quantum states are available for compatibility calculations
          // ignore: unused_local_variable
          final _ = [locationQuantumState, timingQuantumState];
        } catch (e) {
          _logger.warn(
            '⚠️ 4D quantum state creation failed (non-blocking): $e',
            tag: _logName,
          );
          // Continue - quantum state creation is optional
        }
      }
      
      // 7.3: Create quantum entanglement state for event
      if (_quantumEntanglementService != null) {
        try {
          // Create quantum state for event entity
          // This enables quantum compatibility calculations
          _logger.debug('ℹ️ Quantum entanglement service available (quantum state creation deferred to matching)', tag: _logName);
        } catch (e) {
          _logger.warn('⚠️ Quantum entanglement service check failed (non-blocking): $e', tag: _logName);
          // Continue - quantum entanglement is optional
        }
      }
      
      // 7.4: Create fabric for group events (if maxAttendees > 1)
      if (_knotFabricService != null && formData.maxAttendees > 1) {
        try {
          _logger.info(
            '🧵 Creating fabric for group event (maxAttendees: ${formData.maxAttendees})',
            tag: _logName,
          );
          
          // Get host's knot (if available)
          // For now, fabric creation is deferred until attendees join
          // This is a placeholder for future fabric creation on event creation
          _logger.debug('ℹ️ Fabric creation deferred until attendees join', tag: _logName);
        } catch (e) {
          _logger.warn('⚠️ Fabric creation failed (non-blocking): $e', tag: _logName);
          // Continue - fabric creation is optional
        }
      }
      
      // 7.5: Create worldsheet for group tracking (if group event)
      if (_knotWorldsheetService != null && formData.maxAttendees > 1) {
        try {
          _logger.debug('ℹ️ Worldsheet creation deferred until fabric exists', tag: _logName);
          // Worldsheet creation happens after fabric creation
        } catch (e) {
          _logger.warn('⚠️ Worldsheet creation check failed (non-blocking): $e', tag: _logName);
          // Continue - worldsheet creation is optional
        }
      }
      
      // 7.6: Predict string evolution for recurring events (if applicable)
      if (_knotStringService != null) {
        try {
          // Check if event is recurring (would be in formData if supported)
          // For now, string evolution is deferred to future recurring event support
          _logger.debug('ℹ️ String evolution prediction deferred (recurring events not yet supported)', tag: _logName);
        } catch (e) {
          _logger.warn('⚠️ String evolution prediction failed (non-blocking): $e', tag: _logName);
          // Continue - string evolution is optional
        }
      }
      
      // 7.7: Learn from event creation via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null) {
        try {
          // Learn from successful event creation
          // This helps the AI2AI network understand event creation patterns
          _logger.debug('ℹ️ AI2AI learning service available (learning deferred to matching)', tag: _logName);
          // Note: Actual learning happens when matches occur, not during event creation
        } catch (e) {
          _logger.warn('⚠️ AI2AI learning failed (non-blocking): $e', tag: _logName);
          // Continue - AI2AI learning is optional and non-blocking
        }
      }
      
      // STEP 8: Return success result
      return EventCreationResult.success(event: createdEvent);
    } catch (e, stackTrace) {
      _logger.error(
        '❌ Unexpected error in event creation workflow: $e',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return EventCreationResult.failure(
        error: 'Unexpected error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }
  
  @override
  ValidationResult validate(EventFormData input) {
    return validateForm(input);
  }
  
  @override
  Future<void> rollback(EventCreationResult result) async {
    // Event creation rollback is not needed because:
    // 1. ExpertiseEventService.createEvent() creates the event atomically
    // 2. If creation fails, no event is created (no partial state)
    // 3. Events cannot be easily "undone" once created - they require proper cancellation flow
    // If rollback is needed in the future (e.g., delete event on failure), implement here
    _logger.debug('Rollback called (no-op for event creation)', tag: _logName);
  }
  
  /// Validate form data
  /// 
  /// Checks all required fields are present and valid.
  /// 
  /// **Returns:**
  /// `ValidationResult` with field-level errors
  ValidationResult validateForm(EventFormData data) {
    final fieldErrors = <String, String>{};
    final generalErrors = <String>[];
    
    // Title validation
    if (data.title.trim().isEmpty) {
      fieldErrors['title'] = 'Title is required';
    } else if (data.title.trim().length < 3) {
      fieldErrors['title'] = 'Title must be at least 3 characters';
    }
    
    // Description validation
    if (data.description.trim().isEmpty) {
      fieldErrors['description'] = 'Description is required';
    } else if (data.description.trim().length < 10) {
      fieldErrors['description'] = 'Description must be at least 10 characters';
    }
    
    // Category validation
    if (data.category.trim().isEmpty) {
      fieldErrors['category'] = 'Category is required';
    }
    
    // Event type validation (checked via enum, but ensure it's set)
    // EventType is non-nullable enum, so it's always set
    
    // Location validation (optional, but if provided must be valid)
    if (data.location != null && data.location!.trim().isEmpty) {
      fieldErrors['location'] = 'Location cannot be empty if provided';
    }
    
    // Max attendees validation
    if (data.maxAttendees < 1) {
      fieldErrors['maxAttendees'] = 'Max attendees must be at least 1';
    } else if (data.maxAttendees > 1000) {
      fieldErrors['maxAttendees'] = 'Max attendees cannot exceed 1000';
    }
    
    // Price validation (optional, but if provided must be valid)
    if (data.price != null && data.price! < 0) {
      fieldErrors['price'] = 'Price cannot be negative';
    }
    
    if (fieldErrors.isNotEmpty || generalErrors.isNotEmpty) {
      return ValidationResult.invalid(
        fieldErrors: fieldErrors,
        generalErrors: generalErrors,
      );
    }
    
    return ValidationResult.valid();
  }
  
  /// Validate expertise requirements
  /// 
  /// Checks that user has Local level or higher expertise in the category.
  /// 
  /// **Returns:**
  /// `ExpertiseValidationResult` with validation status and error message
  ExpertiseValidationResult validateExpertise(UnifiedUser user, String category) {
    // Check if user has expertise in category
    if (!user.hasExpertiseIn(category)) {
      return ExpertiseValidationResult.invalid(
        error: 'You must have expertise in $category to host events',
      );
    }
    
    // Check expertise level (must be Local or higher)
    final expertiseLevel = user.getExpertiseLevel(category);
    if (expertiseLevel == null || expertiseLevel.index < ExpertiseLevel.local.index) {
      return ExpertiseValidationResult.invalid(
        error: 'You need Local level or higher expertise in $category to host events',
      );
    }
    
    return ExpertiseValidationResult.valid();
  }
  
  /// Validate dates
  /// 
  /// Checks that dates are in the future and end time is after start time.
  /// 
  /// **Returns:**
  /// `ValidationResult` with date validation errors
  ValidationResult validateDates(DateTime startTime, DateTime endTime) {
    final generalErrors = <String>[];
    
    final now = DateTime.now();
    
    // Check start time is in the future
    if (startTime.isBefore(now)) {
      generalErrors.add('Start time must be in the future');
    }
    
    // Check end time is after start time
    if (endTime.isBefore(startTime)) {
      generalErrors.add('End time must be after start time');
    }
    
    // Check duration is reasonable (at least 1 minute, max 7 days)
    final duration = endTime.difference(startTime);
    if (duration.inMinutes < 1) {
      generalErrors.add('Event duration must be at least 1 minute');
    } else if (duration.inDays > 7) {
      generalErrors.add('Event duration cannot exceed 7 days');
    }
    
    if (generalErrors.isNotEmpty) {
      return ValidationResult.invalid(generalErrors: generalErrors);
    }
    
    return ValidationResult.valid();
  }
}

/// Event Form Data
/// 
/// Data class containing all form fields for event creation.
class EventFormData {
  final String title;
  final String description;
  final String category;
  final ExpertiseEventType eventType;
  final DateTime startTime;
  final DateTime endTime;
  final List<Spot>? spots;
  final String? location;
  final String? locality; // Locality for geographic scope validation
  final double? latitude;
  final double? longitude;
  final int maxAttendees;
  final double? price;
  final bool isPublic;
  
  const EventFormData({
    required this.title,
    required this.description,
    required this.category,
    required this.eventType,
    required this.startTime,
    required this.endTime,
    this.spots,
    this.location,
    this.locality,
    this.latitude,
    this.longitude,
    this.maxAttendees = 20,
    this.price,
    this.isPublic = true,
  });
}

/// Event Creation Result
/// 
/// Result returned by EventCreationController after attempting to create an event.
class EventCreationResult extends ControllerResult {
  final ExpertiseEvent? event;
  final ValidationResult? validationErrors;
  
  const EventCreationResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.event,
    this.validationErrors,
  });
  
  /// Create a successful result
  factory EventCreationResult.success({
    required ExpertiseEvent event,
    Map<String, dynamic>? metadata,
  }) {
    return EventCreationResult(
      success: true,
      event: event,
      metadata: metadata,
    );
  }
  
  /// Create a failed result
  factory EventCreationResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
    ValidationResult? validationErrors,
  }) {
    return EventCreationResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
      validationErrors: validationErrors,
    );
  }
  
  @override
  List<Object?> get props => [
    ...super.props,
    event,
    validationErrors,
  ];
}

/// Expertise Validation Result
/// 
/// Result of expertise validation checks.
class ExpertiseValidationResult {
  final bool isValid;
  final String? error;
  
  const ExpertiseValidationResult({
    required this.isValid,
    this.error,
  });
  
  /// Create a valid result
  factory ExpertiseValidationResult.valid() {
    return const ExpertiseValidationResult(isValid: true);
  }
  
  /// Create an invalid result
  factory ExpertiseValidationResult.invalid({required String error}) {
    return ExpertiseValidationResult(isValid: false, error: error);
  }
}

