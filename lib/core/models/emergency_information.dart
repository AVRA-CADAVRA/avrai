import 'package:equatable/equatable.dart';

/// Emergency Information Model
/// 
/// Represents emergency contact and information for an event.
/// 
/// **Philosophy Alignment:**
/// - Ensures user safety and preparedness
/// - Provides clear emergency protocols
/// - Supports responsible event hosting
/// 
/// **Usage:**
/// ```dart
/// final emergencyInfo = EmergencyInformation(
///   eventId: 'event-123',
///   primaryContactName: 'John Doe',
///   primaryContactPhone: '+1234567890',
///   nearestHospital: 'City Hospital',
///   hospitalAddress: '123 Main St',
///   hospitalPhone: '+1987654321',
///   emergencyInstructions: 'Call 911 for emergencies',
/// );
/// ```
class EmergencyInformation extends Equatable {
  /// Unique emergency information identifier
  final String id;
  
  /// Event ID this emergency info is for
  final String eventId;
  
  /// Primary contact name (event host/coordinator)
  final String primaryContactName;
  
  /// Primary contact phone number
  final String primaryContactPhone;
  
  /// Secondary contact name (backup)
  final String? secondaryContactName;
  
  /// Secondary contact phone number
  final String? secondaryContactPhone;
  
  /// Nearest hospital name
  final String? nearestHospital;
  
  /// Hospital address
  final String? hospitalAddress;
  
  /// Hospital phone number
  final String? hospitalPhone;
  
  /// Nearest emergency services address
  final String? nearestEmergencyServicesAddress;
  
  /// Emergency services phone number
  final String? emergencyServicesPhone;
  
  /// Emergency instructions/notes
  final String? emergencyInstructions;
  
  /// Event location for emergency services
  final String? eventLocation;
  
  /// Event coordinates (latitude)
  final double? latitude;
  
  /// Event coordinates (longitude)
  final double? longitude;
  
  /// When information was created
  final DateTime createdAt;
  
  /// When information was last updated
  final DateTime updatedAt;

  const EmergencyInformation({
    required this.id,
    required this.eventId,
    required this.primaryContactName,
    required this.primaryContactPhone,
    this.secondaryContactName,
    this.secondaryContactPhone,
    this.nearestHospital,
    this.hospitalAddress,
    this.hospitalPhone,
    this.nearestEmergencyServicesAddress,
    this.emergencyServicesPhone,
    this.emergencyInstructions,
    this.eventLocation,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  EmergencyInformation copyWith({
    String? id,
    String? eventId,
    String? primaryContactName,
    String? primaryContactPhone,
    String? secondaryContactName,
    String? secondaryContactPhone,
    String? nearestHospital,
    String? hospitalAddress,
    String? hospitalPhone,
    String? nearestEmergencyServicesAddress,
    String? emergencyServicesPhone,
    String? emergencyInstructions,
    String? eventLocation,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyInformation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      primaryContactName: primaryContactName ?? this.primaryContactName,
      primaryContactPhone: primaryContactPhone ?? this.primaryContactPhone,
      secondaryContactName: secondaryContactName ?? this.secondaryContactName,
      secondaryContactPhone: secondaryContactPhone ?? this.secondaryContactPhone,
      nearestHospital: nearestHospital ?? this.nearestHospital,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      hospitalPhone: hospitalPhone ?? this.hospitalPhone,
      nearestEmergencyServicesAddress:
          nearestEmergencyServicesAddress ?? this.nearestEmergencyServicesAddress,
      emergencyServicesPhone:
          emergencyServicesPhone ?? this.emergencyServicesPhone,
      emergencyInstructions:
          emergencyInstructions ?? this.emergencyInstructions,
      eventLocation: eventLocation ?? this.eventLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'primaryContactName': primaryContactName,
      'primaryContactPhone': primaryContactPhone,
      'secondaryContactName': secondaryContactName,
      'secondaryContactPhone': secondaryContactPhone,
      'nearestHospital': nearestHospital,
      'hospitalAddress': hospitalAddress,
      'hospitalPhone': hospitalPhone,
      'nearestEmergencyServicesAddress': nearestEmergencyServicesAddress,
      'emergencyServicesPhone': emergencyServicesPhone,
      'emergencyInstructions': emergencyInstructions,
      'eventLocation': eventLocation,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EmergencyInformation.fromJson(Map<String, dynamic> json) {
    return EmergencyInformation(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      primaryContactName: json['primaryContactName'] as String,
      primaryContactPhone: json['primaryContactPhone'] as String,
      secondaryContactName: json['secondaryContactName'] as String?,
      secondaryContactPhone: json['secondaryContactPhone'] as String?,
      nearestHospital: json['nearestHospital'] as String?,
      hospitalAddress: json['hospitalAddress'] as String?,
      hospitalPhone: json['hospitalPhone'] as String?,
      nearestEmergencyServicesAddress:
          json['nearestEmergencyServicesAddress'] as String?,
      emergencyServicesPhone: json['emergencyServicesPhone'] as String?,
      emergencyInstructions: json['emergencyInstructions'] as String?,
      eventLocation: json['eventLocation'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Check if has location information
  bool get hasLocation => latitude != null && longitude != null;

  /// Check if has hospital information
  bool get hasHospitalInfo =>
      nearestHospital != null && hospitalAddress != null;

  @override
  List<Object?> get props => [
        id,
        eventId,
        primaryContactName,
        primaryContactPhone,
        secondaryContactName,
        secondaryContactPhone,
        nearestHospital,
        hospitalAddress,
        hospitalPhone,
        nearestEmergencyServicesAddress,
        emergencyServicesPhone,
        emergencyInstructions,
        eventLocation,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      ];
}

