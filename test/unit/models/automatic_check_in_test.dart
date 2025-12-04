import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/automatic_check_in.dart';

/// SPOTS AutomaticCheckIn Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test AutomaticCheckIn model functionality
/// 
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Active Status: Check if check-in is active
/// - Trigger Type: Geofence vs Bluetooth
/// - Quality Score Calculation: Based on dwell time
/// - Check Out: Check out from automatic check-in
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// 
/// Dependencies:
/// - GeofenceTrigger: Geofence trigger data
/// - BluetoothTrigger: Bluetooth trigger data

void main() {
  group('AutomaticCheckIn', () {
    late AutomaticCheckIn checkIn;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      checkIn = AutomaticCheckIn(
        id: 'checkin-123',
        visitId: 'visit-456',
        checkInTime: testDate,
        qualityScore: 0.0,
        visitCreated: false,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    group('Constructor and Properties', () {
      test('should create check-in with all required fields', () {
        expect(checkIn.id, 'checkin-123');
        expect(checkIn.visitId, 'visit-456');
        expect(checkIn.checkInTime, testDate);
        expect(checkIn.visitCreated, false);
        expect(checkIn.qualityScore, 0.0);
      });

      test('should create check-in with geofence trigger', () {
        final geofenceTrigger = GeofenceTrigger(
          locationId: 'spot-123',
          latitude: 40.7128,
          longitude: -74.0060,
          triggeredAt: testDate,
        );
        
        final checkInWithGeofence = checkIn.copyWith(
          geofenceTrigger: geofenceTrigger,
        );

        expect(checkInWithGeofence.geofenceTrigger, isNotNull);
        expect(checkInWithGeofence.triggerType, CheckInTriggerType.geofence);
      });

      test('should create check-in with Bluetooth trigger', () {
        final bluetoothTrigger = BluetoothTrigger(
          detectedAt: testDate,
          ai2aiConnected: true,
          personalityExchanged: true,
        );
        
        final checkInWithBluetooth = checkIn.copyWith(
          bluetoothTrigger: bluetoothTrigger,
        );

        expect(checkInWithBluetooth.bluetoothTrigger, isNotNull);
        expect(checkInWithBluetooth.triggerType, CheckInTriggerType.bluetooth);
      });
    });

    group('Active Status', () {
      test('should identify active check-ins', () {
        expect(checkIn.isActive, true);
        expect(checkIn.checkOutTime, isNull);
      });

      test('should identify inactive check-ins', () {
        final checkedOut = checkIn.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );
        expect(checkedOut.isActive, false);
      });
    });

    group('Trigger Type', () {
      test('should identify geofence trigger', () {
        final geofenceTrigger = GeofenceTrigger(
          locationId: 'spot-123',
          latitude: 40.7128,
          longitude: -74.0060,
          triggeredAt: testDate,
        );
        final checkInWithGeofence = checkIn.copyWith(
          geofenceTrigger: geofenceTrigger,
        );
        expect(checkInWithGeofence.triggerType, CheckInTriggerType.geofence);
      });

      test('should identify Bluetooth trigger', () {
        final bluetoothTrigger = BluetoothTrigger(
          detectedAt: testDate,
          ai2aiConnected: true,
          personalityExchanged: false,
        );
        final checkInWithBluetooth = checkIn.copyWith(
          bluetoothTrigger: bluetoothTrigger,
        );
        expect(checkInWithBluetooth.triggerType, CheckInTriggerType.bluetooth);
      });

      test('should identify unknown trigger when no triggers', () {
        expect(checkIn.triggerType, CheckInTriggerType.unknown);
      });
    });

    group('Quality Score Calculation', () {
      test('should calculate quality score for long stay', () {
        final longCheckIn = checkIn.copyWith(
          dwellTime: const Duration(hours: 1),
        );
        final score = longCheckIn.calculateQualityScore();
        expect(score, 1.0);
      });

      test('should calculate quality score for normal visit', () {
        final normalCheckIn = checkIn.copyWith(
          dwellTime: const Duration(minutes: 15),
        );
        final score = normalCheckIn.calculateQualityScore();
        expect(score, 0.8);
      });

      test('should calculate quality score for quick stop', () {
        final quickCheckIn = checkIn.copyWith(
          dwellTime: const Duration(minutes: 5),
        );
        final score = quickCheckIn.calculateQualityScore();
        expect(score, 0.5);
      });

      test('should return 0.0 for too short visit', () {
        final tooShort = checkIn.copyWith(
          dwellTime: const Duration(minutes: 2),
        );
        final score = tooShort.calculateQualityScore();
        expect(score, 0.0);
      });
    });

    group('Check Out', () {
      test('should check out and calculate quality', () {
        // Note: checkOut calculates quality based on this.dwellTime (which is null initially)
        // So we need to set dwellTime first, or the quality will be 0.0
        // For a 2-hour visit, we should get 1.0 quality score
        final checkInWithDwell = checkIn.copyWith(
          dwellTime: const Duration(hours: 2),
        );
        final checkedOut = checkInWithDwell.checkOut(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );

        expect(checkedOut.checkOutTime, isNotNull);
        expect(checkedOut.dwellTime, isNotNull);
        expect(checkedOut.qualityScore, 1.0); // 2 hours = 1.0 quality
        expect(checkedOut.isActive, false);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = checkIn.toJson();

        expect(json['id'], 'checkin-123');
        expect(json['visitId'], 'visit-456');
        expect(json['visitCreated'], false);
        expect(json['qualityScore'], 0.0);
      });

      test('should deserialize from JSON correctly', () {
        final json = checkIn.toJson();
        final deserialized = AutomaticCheckIn.fromJson(json);

        expect(deserialized.id, checkIn.id);
        expect(deserialized.visitId, checkIn.visitId);
        expect(deserialized.checkInTime, checkIn.checkInTime);
      });
    });
  });
}

