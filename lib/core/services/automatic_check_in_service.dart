import 'package:spots/core/models/visit.dart';
import 'package:spots/core/models/automatic_check_in.dart';
import 'package:spots/core/services/logger.dart';

/// Automatic Check-In Service
/// 
/// Handles automatic check-ins via geofencing and Bluetooth ai2ai detection.
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
class AutomaticCheckInService {
  static const String _logName = 'AutomaticCheckInService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  // In-memory storage for check-ins (in production, use database)
  final Map<String, AutomaticCheckIn> _checkIns = {};
  final Map<String, Visit> _visits = {};

  // Active check-ins (user ID -> check-in)
  final Map<String, AutomaticCheckIn> _activeCheckIns = {};

  /// Handle geofence trigger (user entered geofence)
  /// 
  /// **Flow:**
  /// 1. Create automatic check-in with geofence trigger
  /// 2. Create visit record
  /// 3. Start tracking dwell time
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `locationId`: Location/Spot ID
  /// - `latitude`: Latitude
  /// - `longitude`: Longitude
  /// - `accuracy`: Location accuracy (meters)
  /// 
  /// **Returns:**
  /// AutomaticCheckIn with geofence trigger
  Future<AutomaticCheckIn> handleGeofenceTrigger({
    required String userId,
    required String locationId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      _logger.info(
        'Geofence trigger: user=$userId, location=$locationId',
        tag: _logName,
      );

      // Check if user already has active check-in
      if (_activeCheckIns.containsKey(userId)) {
        _logger.warning(
          'User already has active check-in, ignoring new trigger',
          tag: _logName,
        );
        return _activeCheckIns[userId]!;
      }

      // Create geofence trigger
      final geofenceTrigger = GeofenceTrigger(
        locationId: locationId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        triggeredAt: DateTime.now(),
      );

      // Create visit
      final visit = Visit(
        id: _generateVisitId(),
        userId: userId,
        locationId: locationId,
        checkInTime: DateTime.now(),
        isAutomatic: true,
        geofencingData: GeofencingData(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          triggeredAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create automatic check-in
      final checkIn = AutomaticCheckIn(
        id: _generateCheckInId(),
        visitId: visit.id,
        geofenceTrigger: geofenceTrigger,
        checkInTime: DateTime.now(),
        visitCreated: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save check-in and visit
      await _saveCheckIn(checkIn);
      await _saveVisit(visit);
      _activeCheckIns[userId] = checkIn;

      _logger.info('Created automatic check-in: ${checkIn.id}', tag: _logName);

      return checkIn;
    } catch (e) {
      _logger.error('Error handling geofence trigger', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Handle Bluetooth ai2ai trigger (Bluetooth device detected)
  /// 
  /// **Flow:**
  /// 1. Create automatic check-in with Bluetooth trigger
  /// 2. Create visit record
  /// 3. Start tracking dwell time
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `locationId`: Location/Spot ID (if known from ai2ai exchange)
  /// - `deviceId`: Detected device ID
  /// - `rssi`: Signal strength
  /// - `ai2aiConnected`: Whether ai2ai connection established
  /// - `personalityExchanged`: Whether personality exchange completed
  /// 
  /// **Returns:**
  /// AutomaticCheckIn with Bluetooth trigger
  Future<AutomaticCheckIn> handleBluetoothTrigger({
    required String userId,
    String? locationId,
    String? deviceId,
    int? rssi,
    bool ai2aiConnected = false,
    bool personalityExchanged = false,
  }) async {
    try {
      _logger.info(
        'Bluetooth trigger: user=$userId, device=$deviceId',
        tag: _logName,
      );

      // Check if user already has active check-in
      if (_activeCheckIns.containsKey(userId)) {
        _logger.warning(
          'User already has active check-in, ignoring new trigger',
          tag: _logName,
        );
        return _activeCheckIns[userId]!;
      }

      // Create Bluetooth trigger
      final bluetoothTrigger = BluetoothTrigger(
        deviceId: deviceId,
        rssi: rssi,
        detectedAt: DateTime.now(),
        ai2aiConnected: ai2aiConnected,
        personalityExchanged: personalityExchanged,
        locationId: locationId,
      );

      // Create visit (if location known)
      Visit? visit;
      if (locationId != null) {
        visit = Visit(
          id: _generateVisitId(),
          userId: userId,
          locationId: locationId,
          checkInTime: DateTime.now(),
          isAutomatic: true,
          bluetoothData: BluetoothData(
            deviceId: deviceId,
            rssi: rssi,
            detectedAt: DateTime.now(),
            ai2aiConnected: ai2aiConnected,
            personalityExchanged: personalityExchanged,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveVisit(visit);
      }

      // Create automatic check-in
      final checkIn = AutomaticCheckIn(
        id: _generateCheckInId(),
        visitId: visit?.id ?? 'pending',
        bluetoothTrigger: bluetoothTrigger,
        checkInTime: DateTime.now(),
        visitCreated: visit != null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save check-in
      await _saveCheckIn(checkIn);
      if (visit != null) {
        _activeCheckIns[userId] = checkIn;
      }

      _logger.info('Created automatic check-in: ${checkIn.id}', tag: _logName);

      return checkIn;
    } catch (e) {
      _logger.error('Error handling Bluetooth trigger', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Check out from automatic check-in
  /// 
  /// **Flow:**
  /// 1. Calculate dwell time
  /// 2. Calculate quality score
  /// 3. Update check-in and visit
  /// 4. Remove from active check-ins
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `checkOutTime`: Check-out time (optional, defaults to now)
  /// 
  /// **Returns:**
  /// Updated AutomaticCheckIn with dwell time and quality score
  Future<AutomaticCheckIn> checkOut({
    required String userId,
    DateTime? checkOutTime,
  }) async {
    try {
      _logger.info('Checking out: user=$userId', tag: _logName);

      final activeCheckIn = _activeCheckIns[userId];
      if (activeCheckIn == null) {
        throw Exception('No active check-in found for user: $userId');
      }

      final checkout = checkOutTime ?? DateTime.now();

      // Calculate dwell time
      final dwellTime = checkout.difference(activeCheckIn.checkInTime);

      // Check if visit exists
      final visit = _visits[activeCheckIn.visitId];
      if (visit != null) {
        // Update visit
        final updatedVisit = visit.checkOut(checkOutTime: checkout);
        await _saveVisit(updatedVisit);

        // Calculate quality score
        final qualityScore = activeCheckIn.calculateQualityScore();

        // Update check-in
        final updatedCheckIn = activeCheckIn.checkOut(checkOutTime: checkout);

        // Save updated check-in
        await _saveCheckIn(updatedCheckIn);

        // Remove from active check-ins
        _activeCheckIns.remove(userId);

        _logger.info(
          'Checked out: dwell=${dwellTime.inMinutes}min, quality=$qualityScore',
          tag: _logName,
        );

        return updatedCheckIn;
      } else {
        // Visit not found, just update check-in
        final updatedCheckIn = activeCheckIn.checkOut(checkOutTime: checkout);
        await _saveCheckIn(updatedCheckIn);
        _activeCheckIns.remove(userId);

        return updatedCheckIn;
      }
    } catch (e) {
      _logger.error('Error checking out', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get active check-in for user
  AutomaticCheckIn? getActiveCheckIn(String userId) {
    return _activeCheckIns[userId];
  }

  /// Get visit by ID
  Visit? getVisit(String visitId) {
    return _visits[visitId];
  }

  /// Get all visits for user
  List<Visit> getUserVisits(String userId) {
    return _visits.values.where((v) => v.userId == userId).toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
  }

  /// Get all visits for location
  List<Visit> getLocationVisits(String locationId) {
    return _visits.values.where((v) => v.locationId == locationId).toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
  }

  // Private helper methods

  Future<void> _saveCheckIn(AutomaticCheckIn checkIn) async {
    _checkIns[checkIn.id] = checkIn;
    // In production, save to database
  }

  Future<void> _saveVisit(Visit visit) async {
    _visits[visit.id] = visit;
    // In production, save to database
  }

  String _generateCheckInId() {
    return 'checkin-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateVisitId() {
    return 'visit-${DateTime.now().millisecondsSinceEpoch}';
  }
}

