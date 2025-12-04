import 'package:equatable/equatable.dart';
import 'package:spots/core/models/expertise_event.dart';

/// Safety Requirement Enum
/// 
/// Represents different safety requirements for events.
enum SafetyRequirement {
  capacityLimit,
  emergencyExits,
  firstAidKit,
  emergencyContacts,
  weatherPlan,
  alcoholPolicy,
  minorPolicy,
  foodSafety,
  accessibilityPlan,
  covidProtocol,
  securityPersonnel,
  fireSafety,
  crowdControl,
}

/// Event Safety Guidelines Model
/// 
/// Represents safety guidelines and requirements for an event.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to safe event experiences
/// - Enables trust through safety measures
/// - Supports user protection and well-being
/// 
/// **Usage:**
/// ```dart
/// final guidelines = EventSafetyGuidelines(
///   eventId: 'event-123',
///   type: EventType.workshop,
///   requirements: [SafetyRequirement.capacityLimit, SafetyRequirement.emergencyExits],
///   acknowledged: false,
/// );
/// ```
class EventSafetyGuidelines extends Equatable {
  /// Event ID these guidelines are for
  final String eventId;
  
  /// Event type
  final ExpertiseEventType type;
  
  /// Required safety measures
  final List<SafetyRequirement> requirements;
  
  /// Whether host has acknowledged guidelines
  final bool acknowledged;
  
  /// When guidelines were acknowledged
  final DateTime? acknowledgedAt;
  
  /// Emergency information
  final EmergencyInformation? emergencyInfo;
  
  /// Insurance recommendation
  final InsuranceRecommendation? insurance;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const EventSafetyGuidelines({
    required this.eventId,
    required this.type,
    required this.requirements,
    this.acknowledged = false,
    this.acknowledgedAt,
    this.emergencyInfo,
    this.insurance,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  EventSafetyGuidelines copyWith({
    String? eventId,
    ExpertiseEventType? type,
    List<SafetyRequirement>? requirements,
    bool? acknowledged,
    DateTime? acknowledgedAt,
    EmergencyInformation? emergencyInfo,
    InsuranceRecommendation? insurance,
    Map<String, dynamic>? metadata,
  }) {
    return EventSafetyGuidelines(
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      requirements: requirements ?? this.requirements,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      emergencyInfo: emergencyInfo ?? this.emergencyInfo,
      insurance: insurance ?? this.insurance,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'type': type.toString(),
      'requirements': requirements.map((r) => r.name).toList(),
      'acknowledged': acknowledged,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'emergencyInfo': emergencyInfo?.toJson(),
      'insurance': insurance?.toJson(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory EventSafetyGuidelines.fromJson(Map<String, dynamic> json) {
    return EventSafetyGuidelines(
      eventId: json['eventId'] as String,
      type: ExpertiseEventType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ExpertiseEventType.workshop,
      ),
      requirements: (json['requirements'] as List<dynamic>?)
          ?.map((r) => SafetyRequirement.values.firstWhere(
                (s) => s.name == r,
                orElse: () => SafetyRequirement.capacityLimit,
              ))
          .toList() ?? [],
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      emergencyInfo: json['emergencyInfo'] != null
          ? EmergencyInformation.fromJson(json['emergencyInfo'] as Map<String, dynamic>)
          : null,
      insurance: json['insurance'] != null
          ? InsuranceRecommendation.fromJson(json['insurance'] as Map<String, dynamic>)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        type,
        requirements,
        acknowledged,
        acknowledgedAt,
        emergencyInfo,
        insurance,
        metadata,
      ];
}

/// Emergency Information Model
/// 
/// Represents emergency contact and safety information for an event.
class EmergencyInformation extends Equatable {
  /// Event ID
  final String eventId;
  
  /// Emergency contacts
  final List<EmergencyContact> contacts;
  
  /// Nearest hospital name
  final String? nearestHospital;
  
  /// Nearest hospital address
  final String? nearestHospitalAddress;
  
  /// Nearest hospital phone
  final String? nearestHospitalPhone;
  
  /// Evacuation plan description
  final String? evacuationPlan;
  
  /// Meeting point in case of emergency
  final String? meetingPoint;

  const EmergencyInformation({
    required this.eventId,
    this.contacts = const [],
    this.nearestHospital,
    this.nearestHospitalAddress,
    this.nearestHospitalPhone,
    this.evacuationPlan,
    this.meetingPoint,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'nearestHospital': nearestHospital,
      'nearestHospitalAddress': nearestHospitalAddress,
      'nearestHospitalPhone': nearestHospitalPhone,
      'evacuationPlan': evacuationPlan,
      'meetingPoint': meetingPoint,
    };
  }

  /// Create from JSON
  factory EmergencyInformation.fromJson(Map<String, dynamic> json) {
    return EmergencyInformation(
      eventId: json['eventId'] as String,
      contacts: (json['contacts'] as List<dynamic>?)
          ?.map((c) => EmergencyContact.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      nearestHospital: json['nearestHospital'] as String?,
      nearestHospitalAddress: json['nearestHospitalAddress'] as String?,
      nearestHospitalPhone: json['nearestHospitalPhone'] as String?,
      evacuationPlan: json['evacuationPlan'] as String?,
      meetingPoint: json['meetingPoint'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        contacts,
        nearestHospital,
        nearestHospitalAddress,
        nearestHospitalPhone,
        evacuationPlan,
        meetingPoint,
      ];
}

/// Emergency Contact Model
class EmergencyContact extends Equatable {
  final String name;
  final String phone;
  final String role; // "Host", "Venue Manager", "Security", etc.

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
    );
  }

  @override
  List<Object?> get props => [name, phone, role];
}

/// Insurance Recommendation Model
class InsuranceRecommendation extends Equatable {
  final ExpertiseEventType eventType;
  final int attendeeCount;
  final bool recommended;
  final bool required;
  final String explanation;
  final double suggestedCoverageAmount;
  final List<String> insuranceProviders;

  const InsuranceRecommendation({
    required this.eventType,
    required this.attendeeCount,
    required this.recommended,
    required this.required,
    required this.explanation,
    required this.suggestedCoverageAmount,
    this.insuranceProviders = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType.toString(),
      'attendeeCount': attendeeCount,
      'recommended': recommended,
      'required': required,
      'explanation': explanation,
      'suggestedCoverageAmount': suggestedCoverageAmount,
      'insuranceProviders': insuranceProviders,
    };
  }

  factory InsuranceRecommendation.fromJson(Map<String, dynamic> json) {
    return InsuranceRecommendation(
      eventType: ExpertiseEventType.values.firstWhere(
        (e) => e.toString() == json['eventType'],
        orElse: () => ExpertiseEventType.workshop,
      ),
      attendeeCount: json['attendeeCount'] as int? ?? 0,
      recommended: json['recommended'] as bool? ?? false,
      required: json['required'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      suggestedCoverageAmount: (json['suggestedCoverageAmount'] as num?)?.toDouble() ?? 0.0,
      insuranceProviders: List<String>.from(json['insuranceProviders'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        eventType,
        attendeeCount,
        recommended,
        required,
        explanation,
        suggestedCoverageAmount,
        insuranceProviders,
      ];
}
