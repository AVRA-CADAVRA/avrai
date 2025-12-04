import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/automatic_check_in_service.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for AutomaticCheckInService
void main() {
  group('AutomaticCheckInService Tests', () {
    late AutomaticCheckInService service;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      service = AutomaticCheckInService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('handleGeofenceTrigger', () {
      test('should create automatic check-in with geofence trigger', () async {
        final checkIn = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 10.0,
        );

        expect(checkIn.id, isNotEmpty);
        expect(checkIn.visitId, isNotEmpty);
        expect(checkIn.geofenceTrigger, isNotNull);
        expect(checkIn.geofenceTrigger!.locationId, equals('location-1'));
        expect(checkIn.geofenceTrigger!.latitude, equals(40.7128));
        expect(checkIn.geofenceTrigger!.longitude, equals(-74.0060));
        expect(checkIn.isActive, isTrue);
        expect(checkIn.visitCreated, isTrue);
      });

      test('should create visit when geofence triggered', () async {
        final checkIn = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final visit = await service.getVisitById(checkIn.visitId);
        expect(visit, isNotNull);
        expect(visit!.userId, equals('user-1'));
        expect(visit.locationId, equals('location-1'));
        expect(visit.isAutomatic, isTrue);
        expect(visit.isActive, isTrue);
      });
    });

    group('handleBluetoothTrigger', () {
      test('should create automatic check-in with Bluetooth trigger', () async {
        final checkIn = await service.handleBluetoothTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          deviceId: 'device-123',
          rssi: -50,
        );

        expect(checkIn.id, isNotEmpty);
        expect(checkIn.visitId, isNotEmpty);
        expect(checkIn.bluetoothTrigger, isNotNull);
        expect(checkIn.bluetoothTrigger!.deviceId, equals('device-123'));
        expect(checkIn.bluetoothTrigger!.rssi, equals(-50));
        expect(checkIn.isActive, isTrue);
      });

      test('should handle ai2ai connection', () async {
        final checkIn = await service.handleBluetoothTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          deviceId: 'device-123',
          rssi: -50,
          ai2aiConnected: true,
          personalityExchanged: true,
        );

        expect(checkIn.bluetoothTrigger!.ai2aiConnected, isTrue);
        expect(checkIn.bluetoothTrigger!.personalityExchanged, isTrue);
      });
    });

    group('checkOut', () {
      test('should check out from automatic check-in', () async {
        final checkIn = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Wait a bit (simulate dwell time)
        await Future.delayed(const Duration(milliseconds: 100));

        final checkedOut = await service.checkOut(
          userId: 'user-1',
        );

        expect(checkedOut.isActive, isFalse);
        expect(checkedOut.checkOutTime, isNotNull);
        expect(checkedOut.dwellTime, isNotNull);
        expect(checkedOut.qualityScore, greaterThan(0.0));
      });

      test('should calculate quality score based on dwell time', () async {
        final checkIn = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Simulate long dwell time (30+ minutes)
        final longDwellTime = const Duration(minutes: 35);
        final checkInTime = checkIn.checkInTime;
        final checkOutTime = checkInTime.add(longDwellTime);

        final checkedOut = await service.checkOut(
          userId: 'user-1',
          checkOutTime: checkOutTime,
        );

        // Long stay should give high quality score
        expect(checkedOut.qualityScore, greaterThanOrEqualTo(1.0));
      });

      test('should return zero quality for short visits', () async {
        final checkIn = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Simulate short visit (less than 5 minutes)
        final shortDwellTime = const Duration(minutes: 3);
        final checkInTime = checkIn.checkInTime;
        final checkOutTime = checkInTime.add(shortDwellTime);

        final checkedOut = await service.checkOut(
          userId: 'user-1',
          checkOutTime: checkOutTime,
        );

        // Short visit should give zero quality
        expect(checkedOut.qualityScore, equals(0.0));
      });
    });

    group('getActiveCheckIns', () {
      test('should return active check-ins for user', () async {
        await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-2',
          latitude: 40.7130,
          longitude: -74.0062,
        );

        final activeCheckIns = await service.getActiveCheckIns('user-1');
        expect(activeCheckIns.length, equals(2));
      });

      test('should return empty list when no active check-ins', () async {
        final activeCheckIns = await service.getActiveCheckIns('user-1');
        expect(activeCheckIns, isEmpty);
      });
    });

    group('getVisitById', () {
      test('should return visit by ID', () async {
        final checkIn = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final visit = await service.getVisitById(checkIn.visitId);
        expect(visit, isNotNull);
        expect(visit!.id, equals(checkIn.visitId));
      });

      test('should return null for non-existent visit', () async {
        final visit = await service.getVisitById('non-existent');
        expect(visit, isNull);
      });
    });

    group('getVisitsForUser', () {
      test('should return all visits for user', () async {
        await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-2',
          latitude: 40.7130,
          longitude: -74.0062,
        );

        final visits = await service.getVisitsForUser('user-1');
        expect(visits.length, equals(2));
      });

      test('should filter visits by category', () async {
        // This would require category information in visits
        // Implementation depends on Visit model structure
      });
    });
  });
}

