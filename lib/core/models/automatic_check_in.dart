import 'package:equatable/equatable.dart';

/// Automatic Check-In Model
/// 
/// Represents an automatic check-in triggered by geofencing or Bluetooth ai2ai detection.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise through automatic exploration
/// - Zero friction (no phone interaction needed)
/// - Works offline (Bluetooth-based)
/// 
/// **Technology:**
/// - Background location detection (geofencing, 50m radius)
/// - Bluetooth ai2ai proximity verification (works offline)
/// - Dwell time calculation (5+ minutes = valid visit)
/// - Quality scoring (longer stay = higher quality)
class AutomaticCheckIn extends Equatable {
  /// Check-in ID
  final String id;
  
  /// Visit reference (the visit this check-in created)
  final String visitId;
  
  /// Geofence trigger (if triggered by geofencing)
  final GeofenceTrigger? geofenceTrigger;
  
  /// Bluetooth trigger (if triggered by Bluetooth ai2ai)
  final BluetoothTrigger? bluetoothTrigger;
  
  /// Dwell time (calculated after check-out)
  final Duration? dwellTime;
  
  /// Quality score (calculated based on dwell time and engagement)
  final double qualityScore;
  
  /// Check-in time
  final DateTime checkInTime;
  
  /// Check-out time (null if still checked in)
  final DateTime? checkOutTime;
  
  /// Visit created flag
  final bool visitCreated;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const AutomaticCheckIn({
    required this.id,
    required this.visitId,
    this.geofenceTrigger,
    this.bluetoothTrigger,
    this.dwellTime,
    this.qualityScore = 0.0,
    required this.checkInTime,
    this.checkOutTime,
    this.visitCreated = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Check if check-in is still active
  bool get isActive => checkOutTime == null;

  /// Get trigger type
  CheckInTriggerType get triggerType {
    if (geofenceTrigger != null) {
      return CheckInTriggerType.geofence;
    } else if (bluetoothTrigger != null) {
      return CheckInTriggerType.bluetooth;
    } else {
      return CheckInTriggerType.unknown;
    }
  }

  /// Calculate quality score based on dwell time
  /// 
  /// **Quality Formula:**
  /// - Quick stop (5 min): 0.5 points
  /// - Normal visit (15 min): 0.8 points
  /// - Long stay (30+ min): 1.0 points
  double calculateQualityScore() {
    if (dwellTime == null) return 0.0;

    final minutes = dwellTime!.inMinutes;

    if (minutes >= 30) {
      return 1.0;
    } else if (minutes >= 15) {
      return 0.8;
    } else if (minutes >= 5) {
      return 0.5;
    } else {
      return 0.0; // Too short, invalid
    }
  }

  /// Check out from automatic check-in
  AutomaticCheckIn checkOut({DateTime? checkOutTime}) {
    final checkout = checkOutTime ?? DateTime.now();
    final dwell = checkout.difference(this.checkInTime);
    final quality = calculateQualityScore();

    return copyWith(
      checkOutTime: checkout,
      dwellTime: dwell,
      qualityScore: quality,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitId': visitId,
      'geofenceTrigger': geofenceTrigger?.toJson(),
      'bluetoothTrigger': bluetoothTrigger?.toJson(),
      'dwellTime': dwellTime?.inMinutes,
      'qualityScore': qualityScore,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'visitCreated': visitCreated,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory AutomaticCheckIn.fromJson(Map<String, dynamic> json) {
    return AutomaticCheckIn(
      id: json['id'] as String,
      visitId: json['visitId'] as String,
      geofenceTrigger: json['geofenceTrigger'] != null
          ? GeofenceTrigger.fromJson(
              json['geofenceTrigger'] as Map<String, dynamic>,
            )
          : null,
      bluetoothTrigger: json['bluetoothTrigger'] != null
          ? BluetoothTrigger.fromJson(
              json['bluetoothTrigger'] as Map<String, dynamic>,
            )
          : null,
      dwellTime: json['dwellTime'] != null
          ? Duration(minutes: json['dwellTime'] as int)
          : null,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      visitCreated: json['visitCreated'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Copy with method
  AutomaticCheckIn copyWith({
    String? id,
    String? visitId,
    GeofenceTrigger? geofenceTrigger,
    BluetoothTrigger? bluetoothTrigger,
    Duration? dwellTime,
    double? qualityScore,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? visitCreated,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AutomaticCheckIn(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      geofenceTrigger: geofenceTrigger ?? this.geofenceTrigger,
      bluetoothTrigger: bluetoothTrigger ?? this.bluetoothTrigger,
      dwellTime: dwellTime ?? this.dwellTime,
      qualityScore: qualityScore ?? this.qualityScore,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      visitCreated: visitCreated ?? this.visitCreated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        visitId,
        geofenceTrigger,
        bluetoothTrigger,
        dwellTime,
        qualityScore,
        checkInTime,
        checkOutTime,
        visitCreated,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Check-In Trigger Type
enum CheckInTriggerType {
  geofence,   // Triggered by geofencing
  bluetooth,  // Triggered by Bluetooth ai2ai
  unknown,    // Unknown trigger
}

/// Geofence Trigger
/// Triggered when user enters geofence (50m radius)
class GeofenceTrigger extends Equatable {
  /// Location ID (Spot ID)
  final String locationId;
  
  /// Latitude
  final double latitude;
  
  /// Longitude
  final double longitude;
  
  /// Geofence radius (meters)
  final double radius;
  
  /// Accuracy (meters)
  final double? accuracy;
  
  /// Trigger time
  final DateTime triggeredAt;

  const GeofenceTrigger({
    required this.locationId,
    required this.latitude,
    required this.longitude,
    this.radius = 50.0,
    this.accuracy,
    required this.triggeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'accuracy': accuracy,
      'triggeredAt': triggeredAt.toIso8601String(),
    };
  }

  factory GeofenceTrigger.fromJson(Map<String, dynamic> json) {
    return GeofenceTrigger(
      locationId: json['locationId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 50.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      triggeredAt: DateTime.parse(json['triggeredAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        locationId,
        latitude,
        longitude,
        radius,
        accuracy,
        triggeredAt,
      ];
}

/// Bluetooth Trigger
/// Triggered when Bluetooth ai2ai device detected nearby
class BluetoothTrigger extends Equatable {
  /// Device ID detected
  final String? deviceId;
  
  /// Signal strength (RSSI)
  final int? rssi;
  
  /// Detection time
  final DateTime detectedAt;
  
  /// ai2ai connection established
  final bool ai2aiConnected;
  
  /// Personality exchange completed
  final bool personalityExchanged;
  
  /// Location ID (if known from ai2ai exchange)
  final String? locationId;

  const BluetoothTrigger({
    this.deviceId,
    this.rssi,
    required this.detectedAt,
    this.ai2aiConnected = false,
    this.personalityExchanged = false,
    this.locationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'rssi': rssi,
      'detectedAt': detectedAt.toIso8601String(),
      'ai2aiConnected': ai2aiConnected,
      'personalityExchanged': personalityExchanged,
      'locationId': locationId,
    };
  }

  factory BluetoothTrigger.fromJson(Map<String, dynamic> json) {
    return BluetoothTrigger(
      deviceId: json['deviceId'] as String?,
      rssi: json['rssi'] as int?,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      ai2aiConnected: json['ai2aiConnected'] as bool? ?? false,
      personalityExchanged: json['personalityExchanged'] as bool? ?? false,
      locationId: json['locationId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        rssi,
        detectedAt,
        ai2aiConnected,
        personalityExchanged,
        locationId,
      ];
}

