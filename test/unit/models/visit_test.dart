import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/visit.dart';

/// SPOTS Visit Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test Visit model functionality
/// 
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Active Status: Check if visit is active
/// - Dwell Time Calculation: Calculate from check-in/out
/// - Quality Score Calculation: Based on dwell time and engagement
/// - Check Out: Check out from visit
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// 
/// Dependencies:
/// - GeofencingData: Geofencing trigger data
/// - BluetoothData: Bluetooth trigger data

void main() {
  group('Visit', () {
    late Visit visit;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      visit = Visit(
        id: 'visit-123',
        userId: 'user-789',
        locationId: 'spot-456',
        checkInTime: testDate,
        qualityScore: 0.0,
        isAutomatic: true,
        isRepeatVisit: false,
        visitNumber: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    group('Constructor and Properties', () {
      test('should create visit with all required fields', () {
        expect(visit.id, 'visit-123');
        expect(visit.userId, 'user-789');
        expect(visit.locationId, 'spot-456');
        expect(visit.checkInTime, testDate);
        expect(visit.isAutomatic, true);
        expect(visit.isRepeatVisit, false);
        expect(visit.visitNumber, 1);
      });

      test('should create visit with default values', () {
        final minimalVisit = Visit(
          id: 'visit-1',
          userId: 'user-1',
          locationId: 'spot-1',
          checkInTime: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(minimalVisit.checkOutTime, isNull);
        expect(minimalVisit.dwellTime, isNull);
        expect(minimalVisit.qualityScore, 0.0);
        expect(minimalVisit.isAutomatic, false);
        expect(minimalVisit.isRepeatVisit, false);
        expect(minimalVisit.visitNumber, 1);
      });
    });

    group('Active Status', () {
      test('should identify active visits', () {
        expect(visit.isActive, true);
        expect(visit.checkOutTime, isNull);
      });

      test('should identify inactive visits', () {
        final checkedOut = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );
        expect(checkedOut.isActive, false);
        expect(checkedOut.checkOutTime, isNotNull);
      });
    });

    group('Dwell Time Calculation', () {
      test('should calculate dwell time for checked out visit', () {
        final checkedOut = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );
        final dwellTime = checkedOut.calculateDwellTime();
        expect(dwellTime, const Duration(hours: 2));
      });

      test('should calculate current dwell time for active visit', () {
        final now = DateTime.now();
        final activeVisit = visit.copyWith(checkInTime: now.subtract(const Duration(minutes: 30)));
        final dwellTime = activeVisit.calculateDwellTime();
        expect(dwellTime.inMinutes, greaterThanOrEqualTo(29));
        expect(dwellTime.inMinutes, lessThanOrEqualTo(31));
      });
    });

    group('Quality Score Calculation', () {
      test('should calculate quality score for long stay', () {
        final longVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 1)),
          dwellTime: const Duration(hours: 1),
        );
        final score = longVisit.calculateQualityScore();
        expect(score, greaterThanOrEqualTo(1.0));
      });

      test('should calculate quality score for normal visit', () {
        final normalVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 15)),
          dwellTime: const Duration(minutes: 15),
        );
        final score = normalVisit.calculateQualityScore();
        expect(score, greaterThanOrEqualTo(0.8));
        expect(score, lessThan(1.0));
      });

      test('should calculate quality score for quick stop', () {
        final quickVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 5)),
          dwellTime: const Duration(minutes: 5),
        );
        final score = quickVisit.calculateQualityScore();
        expect(score, greaterThanOrEqualTo(0.5));
        expect(score, lessThan(0.8));
      });

      test('should add bonus for review', () {
        final visitWithReview = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 15)),
          dwellTime: const Duration(minutes: 15),
          rating: 4.5,
        );
        final score = visitWithReview.calculateQualityScore();
        expect(score, greaterThan(0.8)); // Should have bonus
      });

      test('should add bonus for detailed review', () {
        final visitWithDetailedReview = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 15)),
          dwellTime: const Duration(minutes: 15),
          reviewId: 'review-123',
          rating: 4.5,
        );
        final score = visitWithDetailedReview.calculateQualityScore();
        expect(score, greaterThan(1.0)); // Should have both bonuses
      });

      test('should add bonus for repeat visit', () {
        final repeatVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 15)),
          dwellTime: const Duration(minutes: 15),
          isRepeatVisit: true,
        );
        final score = repeatVisit.calculateQualityScore();
        expect(score, greaterThan(0.8)); // Should have repeat bonus
      });

      test('should cap quality score at 1.5', () {
        final maxVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 1)),
          dwellTime: const Duration(hours: 1),
          reviewId: 'review-123',
          rating: 5.0,
          isRepeatVisit: true,
        );
        final score = maxVisit.calculateQualityScore();
        expect(score, lessThanOrEqualTo(1.5));
      });
    });

    group('Check Out', () {
      test('should check out visit and calculate quality', () {
        final checkedOut = visit.checkOut(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );

        expect(checkedOut.checkOutTime, isNotNull);
        expect(checkedOut.dwellTime, isNotNull);
        expect(checkedOut.qualityScore, greaterThan(0.0));
        expect(checkedOut.isActive, false);
      });

      test('should use current time if check out time not provided', () {
        final checkedOut = visit.checkOut();
        expect(checkedOut.checkOutTime, isNotNull);
        expect(checkedOut.isActive, false);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = visit.toJson();

        expect(json['id'], 'visit-123');
        expect(json['userId'], 'user-789');
        expect(json['locationId'], 'spot-456');
        expect(json['isAutomatic'], true);
        expect(json['isRepeatVisit'], false);
        expect(json['visitNumber'], 1);
      });

      test('should deserialize from JSON correctly', () {
        final json = visit.toJson();
        final deserialized = Visit.fromJson(json);

        expect(deserialized.id, visit.id);
        expect(deserialized.userId, visit.userId);
        expect(deserialized.locationId, visit.locationId);
        expect(deserialized.checkInTime, visit.checkInTime);
        expect(deserialized.isAutomatic, visit.isAutomatic);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final visit2 = visit.copyWith();
        expect(visit, equals(visit2));
      });

      test('should not be equal when properties differ', () {
        final visit2 = visit.copyWith(qualityScore: 1.0);
        expect(visit, isNot(equals(visit2)));
      });
    });
  });
}

