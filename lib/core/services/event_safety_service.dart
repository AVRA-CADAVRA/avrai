import 'package:spots/core/models/event_safety_guidelines.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/logger.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

/// Event Safety Service
/// 
/// Generates and manages safety guidelines for events based on event type,
/// location, and other factors.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to safe event experiences
/// - Enables trust through safety measures
/// - Supports user protection and well-being
/// 
/// **Responsibilities:**
/// - Generate safety guidelines per event type
/// - Provide emergency information retrieval
/// - Generate insurance recommendations
/// - Determine safety requirements
/// 
/// **Usage:**
/// ```dart
/// final safetyService = EventSafetyService(eventService);
/// 
/// // Generate guidelines for event
/// final guidelines = await safetyService.generateGuidelines('event-123');
/// 
/// // Get emergency information
/// final emergencyInfo = await safetyService.getEmergencyInfo('event-123');
/// ```
class EventSafetyService {
  static const String _logName = 'EventSafetyService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService _eventService;
  
  // In-memory storage for safety guidelines (in production, use database)
  final Map<String, EventSafetyGuidelines> _safetyGuidelines = {};

  // #region agent log
  static const String _agentDebugLogPath = '/Users/reisgordon/SPOTS/.cursor/debug.log';
  late final String _agentRunId = 'event_safety_${_uuid.v4()}';
  void _agentLog(String hypothesisId, String location, String message, Map<String, Object?> data) {
    try {
      final payload = <String, Object?>{
        'sessionId': 'debug-session',
        'runId': _agentRunId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File(_agentDebugLogPath).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // ignore: avoid_catches_without_on_clauses
    }
  }
  // #endregion
  
  EventSafetyService({
    required ExpertiseEventService eventService,
  }) : _eventService = eventService;
  
  /// Generate safety guidelines for an event
  /// 
  /// **Flow:**
  /// 1. Get event by ID
  /// 2. Determine requirements based on event type
  /// 3. Get emergency information for location
  /// 4. Get insurance recommendation
  /// 5. Create and save guidelines
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// EventSafetyGuidelines for the event
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  Future<EventSafetyGuidelines> generateGuidelines(String eventId) async {
    try {
      _logger.info('Generating safety guidelines: event=$eventId', tag: _logName);
      
      // Step 1: Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Step 2: Determine requirements based on event type
      final requirements = _getRequirementsForType(event.eventType, event);
      
      // Step 3: Get emergency information
      final emergencyInfo = await _getEmergencyInfo(eventId, event);
      
      // Step 4: Get insurance recommendation
      final insurance = _getInsuranceRecommendation(event);
      
      // Step 5: Create guidelines
      final guidelines = EventSafetyGuidelines(
        eventId: eventId,
        type: event.eventType,
        requirements: requirements,
        acknowledged: false,
        emergencyInfo: emergencyInfo,
        insurance: insurance,
      );
      
      // Step 6: Save guidelines
      await _saveGuidelines(guidelines);
      
      _logger.info('Safety guidelines generated: event=$eventId, requirements=${requirements.length}', tag: _logName);
      return guidelines;
    } catch (e) {
      _logger.error('Error generating safety guidelines', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get emergency information for an event
  /// 
  /// **Flow:**
  /// 1. Get event location
  /// 2. Find nearest hospital
  /// 3. Create emergency contacts list
  /// 4. Generate evacuation plan
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `event`: Event object (optional, will fetch if not provided)
  /// 
  /// **Returns:**
  /// EmergencyInformation for the event
  Future<EmergencyInformation> getEmergencyInfo(
    String eventId, [
    ExpertiseEvent? event,
  ]) async {
    try {
      _logger.info('Getting emergency info: event=$eventId', tag: _logName);
      
      // Get event if not provided
      event ??= await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Create emergency contacts (host is always first contact)
      final contacts = [
        EmergencyContact(
          name: event.host.displayName ?? 'Host',
          phone: '', // UnifiedUser doesn't have phoneNumber - would need to get from profile
          role: 'Host',
        ),
      ];
      
      // Find nearest hospital (simplified - in production, use location services)
      final nearestHospital = await _findNearestHospital(event);
      
      // Generate evacuation plan
      final evacuationPlan = _generateEvacuationPlan(event);
      
      // Create emergency information
      final emergencyInfo = EmergencyInformation(
        eventId: eventId,
        contacts: contacts,
        nearestHospital: nearestHospital['name'],
        nearestHospitalAddress: nearestHospital['address'],
        nearestHospitalPhone: nearestHospital['phone'],
        evacuationPlan: evacuationPlan,
        meetingPoint: event.location,
      );
      
      return emergencyInfo;
    } catch (e) {
      _logger.error('Error getting emergency info', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get insurance recommendation for an event
  /// 
  /// **Parameters:**
  /// - `event`: Event object
  /// 
  /// **Returns:**
  /// InsuranceRecommendation for the event
  InsuranceRecommendation getInsuranceRecommendation(ExpertiseEvent event) {
    // Determine if insurance is recommended or required
    final isRecommended = event.maxAttendees > 20 || event.isPaid;
    final isRequired = event.maxAttendees > 50;
    
    // Calculate suggested coverage amount (based on ticket price and attendee count)
    final suggestedCoverage = event.isPaid && event.price != null
        ? event.price! * event.maxAttendees * 1.5
        : 10000.0; // Default $10k coverage
    
    // Generate explanation
    final explanation = _generateInsuranceExplanation(event, isRecommended, isRequired);
    
    return InsuranceRecommendation(
      eventType: event.eventType,
      attendeeCount: event.maxAttendees,
      recommended: isRecommended,
      required: isRequired,
      explanation: explanation,
      suggestedCoverageAmount: suggestedCoverage,
      insuranceProviders: const [
        'Eventbrite Event Insurance',
        'The Event Helper',
        'Thimble',
      ],
    );
  }
  
  /// Get safety requirements for event type
  /// 
  /// Determines safety requirements based on event type and characteristics.
  List<SafetyRequirement> _getRequirementsForType(
    ExpertiseEventType type,
    ExpertiseEvent event,
  ) {
    final requirements = <SafetyRequirement>[
      SafetyRequirement.capacityLimit,      // Always required
      SafetyRequirement.emergencyExits,     // Always required
      SafetyRequirement.emergencyContacts,  // Always required
    ];
    
    // Event type specific requirements
    switch (type) {
      case ExpertiseEventType.tour:
        // Tours are often outdoor and may involve movement
        requirements.add(SafetyRequirement.weatherPlan);
        if (event.maxAttendees > 15) {
          requirements.add(SafetyRequirement.crowdControl);
        }
        break;
      case ExpertiseEventType.workshop:
        // Workshops may involve equipment
        requirements.add(SafetyRequirement.firstAidKit);
        if (event.maxAttendees > 30) {
          requirements.add(SafetyRequirement.fireSafety);
        }
        break;
      case ExpertiseEventType.tasting:
        // Tastings may involve food/alcohol
        requirements.add(SafetyRequirement.foodSafety);
        requirements.add(SafetyRequirement.firstAidKit);
        // Check if alcohol is involved (would be in metadata in production)
        requirements.add(SafetyRequirement.alcoholPolicy);
        break;
      case ExpertiseEventType.meetup:
        // Meetups are typically low-risk
        break;
      case ExpertiseEventType.walk:
        // Walks are outdoor activities
        requirements.add(SafetyRequirement.weatherPlan);
        break;
      case ExpertiseEventType.lecture:
        // Lectures may have larger audiences
        if (event.maxAttendees > 50) {
          requirements.add(SafetyRequirement.accessibilityPlan);
          requirements.add(SafetyRequirement.crowdControl);
        }
        break;
    }
    
    // General requirements based on event size
    if (event.maxAttendees > 50) {
      requirements.add(SafetyRequirement.accessibilityPlan);
      requirements.add(SafetyRequirement.crowdControl);
    }
    
    if (event.maxAttendees > 100) {
      requirements.add(SafetyRequirement.securityPersonnel);
    }
    
    // Always include COVID protocol (current health guidance)
    requirements.add(SafetyRequirement.covidProtocol);
    
    return requirements;
  }
  
  /// Find nearest hospital to event location
  Future<Map<String, String?>> _findNearestHospital(ExpertiseEvent event) async {
    // In production, use geocoding service to find nearest hospital
    // For now, return placeholder data
    return {
      'name': 'Nearest Hospital',
      'address': event.location ?? 'Address not available',
      'phone': '911', // Emergency number
    };
  }
  
  /// Generate evacuation plan for event
  String _generateEvacuationPlan(ExpertiseEvent event) {
    final buffer = StringBuffer();
    buffer.writeln('Evacuation Plan for ${event.title}');
    buffer.writeln('');
    buffer.writeln('1. Primary Exit: ${event.location ?? "Main entrance"}');
    buffer.writeln('2. Secondary Exit: Use alternative exits if available');
    buffer.writeln('3. Meeting Point: ${event.location ?? "Designated safe area"}');
    buffer.writeln('4. Emergency Contact: Host (see contact list)');
    return buffer.toString();
  }
  
  /// Generate insurance explanation
  String _generateInsuranceExplanation(
    ExpertiseEvent event,
    bool isRecommended,
    bool isRequired,
  ) {
    if (isRequired) {
      return 'Insurance is required for events with 50+ attendees. This protects you and your attendees.';
    } else if (isRecommended) {
      return 'Insurance is recommended for events with 20+ attendees or paid events. This provides liability protection.';
    } else {
      return 'While not required, event insurance can provide peace of mind and protect against unforeseen circumstances.';
    }
  }
  
  /// Get guidelines for an event
  Future<EventSafetyGuidelines?> getGuidelines(String eventId) async {
    // Check if guidelines exist in storage
    if (_safetyGuidelines.containsKey(eventId)) {
      return _safetyGuidelines[eventId];
    }
    
    // Generate guidelines if they don't exist
    return await generateGuidelines(eventId);
  }
  
  /// Acknowledge safety guidelines
  Future<void> acknowledgeGuidelines(String eventId) async {
    // #region agent log
    _agentLog(
      'A',
      'event_safety_service.dart:acknowledgeGuidelines:entry',
      'acknowledgeGuidelines entry',
      {'eventId': eventId, 'hasExistingGuidelines': _safetyGuidelines.containsKey(eventId)},
    );
    // #endregion

    // Acknowledgement should only apply to already-generated guidelines.
    // It should NOT auto-generate guidelines (that can mask missing-guidelines scenarios).
    final guidelines = _safetyGuidelines[eventId];
    if (guidelines == null) {
      // #region agent log
      _agentLog(
        'A',
        'event_safety_service.dart:acknowledgeGuidelines:missing',
        'No guidelines found; throwing',
        {'eventId': eventId},
      );
      // #endregion
      throw Exception('Guidelines not found for event: $eventId');
    }
    
    final updated = guidelines.copyWith(
      acknowledged: true,
      acknowledgedAt: DateTime.now(),
    );
    
    await _saveGuidelines(updated);
    _logger.info('Guidelines acknowledged: event=$eventId', tag: _logName);

    // #region agent log
    _agentLog(
      'A',
      'event_safety_service.dart:acknowledgeGuidelines:done',
      'Guidelines acknowledged',
      {'eventId': eventId, 'acknowledged': true},
    );
    // #endregion
  }
  
  /// Determine safety requirements (public method)
  List<SafetyRequirement> determineSafetyRequirements(ExpertiseEvent event) {
    return _getRequirementsForType(event.eventType, event);
  }
  
  // Private helper methods
  
  Future<void> _saveGuidelines(EventSafetyGuidelines guidelines) async {
    // In production, save to database
    _safetyGuidelines[guidelines.eventId] = guidelines;
  }
  
  Future<EmergencyInformation> _getEmergencyInfo(
    String eventId,
    ExpertiseEvent event,
  ) async {
    return await getEmergencyInfo(eventId, event);
  }
  
  InsuranceRecommendation _getInsuranceRecommendation(ExpertiseEvent event) {
    return getInsuranceRecommendation(event);
  }
}
