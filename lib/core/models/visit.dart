import 'package:equatable/equatable.dart';

/// Visit Model
/// 
/// Represents a user's visit to a location/spot.
/// Supports automatic check-ins via geofencing and Bluetooth ai2ai detection.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise through exploration
/// - Automatic check-ins (zero friction)
/// - Quality scoring based on dwell time and engagement
/// 
/// **Automatic Check-In Technology:**
/// - Background location detection (geofencing, 50m radius)
/// - Bluetooth ai2ai proximity verification (works offline)
/// - Dwell time calculation (5+ minutes = valid visit)
/// - Quality scoring (longer stay = higher quality)
class Visit extends Equatable {
  /// Visit ID
  final String id;
  
  /// User reference
  final String userId;
  
  /// Location reference (Spot ID)
  final String locationId;
  
  /// Check-in time
  final DateTime checkInTime;
  
  /// Check-out time (null if still checked in)
  final DateTime? checkOutTime;
  
  /// Dwell time (calculated from check-in/out)
  final Duration? dwellTime;
  
  /// Quality score (0.0 to 1.5)
  /// Based on dwell time, review given, repeat visit
  final double qualityScore;
  
  /// Automatic check-in flag
  final bool isAutomatic;
  
  /// Geofencing data
  final GeofencingData? geofencingData;
  
  /// Bluetooth data (ai2ai detection)
  final BluetoothData? bluetoothData;
  
  /// Review/rating given (if any)
  final String? reviewId;
  final double? rating;
  
  /// Repeat visit flag (visited this location before)
  final bool isRepeatVisit;
  
  /// Visit number (1st, 2nd, 3rd, etc.)
  final int visitNumber;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const Visit({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.checkInTime,
    this.checkOutTime,
    this.dwellTime,
    this.qualityScore = 0.0,
    this.isAutomatic = false,
    this.geofencingData,
    this.bluetoothData,
    this.reviewId,
    this.rating,
    this.isRepeatVisit = false,
    this.visitNumber = 1,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Check if visit is still active (checked in but not checked out)
  bool get isActive => checkOutTime == null;

  /// Calculate dwell time from check-in/out times
  Duration calculateDwellTime() {
    if (checkOutTime == null) {
      return DateTime.now().difference(checkInTime);
    }
    return checkOutTime!.difference(checkInTime);
  }

  /// Calculate quality score based on visit characteristics
  /// 
  /// **Quality Formula:**
  /// - Quick stop (5 min, no review): 0.5 points
  /// - Normal visit (15 min, no review): 0.8 points
  /// - Long stay (30+ min, no review): 1.0 points
  /// - Normal + review (15 min + rating): 1.3 points
  /// - Long + detailed review: 1.5 points
  double calculateQualityScore() {
    final dwell = calculateDwellTime();
    final minutes = dwell.inMinutes;

    double score = 0.0;

    // Base score from dwell time
    if (minutes >= 30) {
      score = 1.0;
    } else if (minutes >= 15) {
      score = 0.8;
    } else if (minutes >= 5) {
      score = 0.5;
    } else {
      return 0.0; // Too short, invalid visit
    }

    // Bonus for review
    if (rating != null) {
      score += 0.3;
    }

    // Bonus for detailed review (if reviewId exists)
    if (reviewId != null) {
      score += 0.2;
    }

    // Bonus for repeat visit (shows loyalty)
    if (isRepeatVisit) {
      score += 0.1;
    }

    // Cap at 1.5
    return score > 1.5 ? 1.5 : score;
  }

  /// Check out from visit
  Visit checkOut({DateTime? checkOutTime}) {
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
      'userId': userId,
      'locationId': locationId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'dwellTime': dwellTime?.inMinutes,
      'qualityScore': qualityScore,
      'isAutomatic': isAutomatic,
      'geofencingData': geofencingData?.toJson(),
      'bluetoothData': bluetoothData?.toJson(),
      'reviewId': reviewId,
      'rating': rating,
      'isRepeatVisit': isRepeatVisit,
      'visitNumber': visitNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      locationId: json['locationId'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      dwellTime: json['dwellTime'] != null
          ? Duration(minutes: json['dwellTime'] as int)
          : null,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
      isAutomatic: json['isAutomatic'] as bool? ?? false,
      geofencingData: json['geofencingData'] != null
          ? GeofencingData.fromJson(
              json['geofencingData'] as Map<String, dynamic>,
            )
          : null,
      bluetoothData: json['bluetoothData'] != null
          ? BluetoothData.fromJson(
              json['bluetoothData'] as Map<String, dynamic>,
            )
          : null,
      reviewId: json['reviewId'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isRepeatVisit: json['isRepeatVisit'] as bool? ?? false,
      visitNumber: json['visitNumber'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Copy with method
  Visit copyWith({
    String? id,
    String? userId,
    String? locationId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    Duration? dwellTime,
    double? qualityScore,
    bool? isAutomatic,
    GeofencingData? geofencingData,
    BluetoothData? bluetoothData,
    String? reviewId,
    double? rating,
    bool? isRepeatVisit,
    int? visitNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Visit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      locationId: locationId ?? this.locationId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      dwellTime: dwellTime ?? this.dwellTime,
      qualityScore: qualityScore ?? this.qualityScore,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      geofencingData: geofencingData ?? this.geofencingData,
      bluetoothData: bluetoothData ?? this.bluetoothData,
      reviewId: reviewId ?? this.reviewId,
      rating: rating ?? this.rating,
      isRepeatVisit: isRepeatVisit ?? this.isRepeatVisit,
      visitNumber: visitNumber ?? this.visitNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        locationId,
        checkInTime,
        checkOutTime,
        dwellTime,
        qualityScore,
        isAutomatic,
        geofencingData,
        bluetoothData,
        reviewId,
        rating,
        isRepeatVisit,
        visitNumber,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Geofencing Data
/// Data from geofencing-based automatic check-in
class GeofencingData extends Equatable {
  /// Geofence radius (meters)
  final double radius;
  
  /// Latitude
  final double latitude;
  
  /// Longitude
  final double longitude;
  
  /// Accuracy (meters)
  final double? accuracy;
  
  /// Trigger time
  final DateTime triggeredAt;

  const GeofencingData({
    this.radius = 50.0, // Default 50m radius
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.triggeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'radius': radius,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'triggeredAt': triggeredAt.toIso8601String(),
    };
  }

  factory GeofencingData.fromJson(Map<String, dynamic> json) {
    return GeofencingData(
      radius: (json['radius'] as num?)?.toDouble() ?? 50.0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      triggeredAt: DateTime.parse(json['triggeredAt'] as String),
    );
  }

  @override
  List<Object?> get props => [radius, latitude, longitude, accuracy, triggeredAt];
}

/// Bluetooth Data
/// Data from Bluetooth ai2ai proximity detection
class BluetoothData extends Equatable {
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

  const BluetoothData({
    this.deviceId,
    this.rssi,
    required this.detectedAt,
    this.ai2aiConnected = false,
    this.personalityExchanged = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'rssi': rssi,
      'detectedAt': detectedAt.toIso8601String(),
      'ai2aiConnected': ai2aiConnected,
      'personalityExchanged': personalityExchanged,
    };
  }

  factory BluetoothData.fromJson(Map<String, dynamic> json) {
    return BluetoothData(
      deviceId: json['deviceId'] as String?,
      rssi: json['rssi'] as int?,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      ai2aiConnected: json['ai2aiConnected'] as bool? ?? false,
      personalityExchanged: json['personalityExchanged'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        rssi,
        detectedAt,
        ai2aiConnected,
        personalityExchanged,
      ];
}

