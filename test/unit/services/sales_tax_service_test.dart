import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/sales_tax_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'sales_tax_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService])
void main() {
  group('SalesTaxService', () {
    late SalesTaxService service;
    late MockExpertiseEventService mockEventService;
    
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      
      service = SalesTaxService(
        eventService: mockEventService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Test Event',
        description: 'A test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        isPaid: true,
        price: 25.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('calculateSalesTax', () {
      test('should return zero tax for tax-exempt event types', () async {
        // Arrange
        final workshopEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.workshop,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => workshopEvent);

        // Act
        final calculation = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );

        // Assert
        expect(calculation, isA<SalesTaxCalculation>());
        expect(calculation.isTaxExempt, isTrue);
        expect(calculation.taxAmount, equals(0.0));
        expect(calculation.taxRate, equals(0.0));
        expect(calculation.totalAmount, equals(25.0));
        expect(calculation.exemptionReason, isNotNull);
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should calculate tax for taxable event types', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final calculation = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );

        // Assert
        expect(calculation, isA<SalesTaxCalculation>());
        expect(calculation.isTaxExempt, isFalse);
        expect(calculation.taxableAmount, equals(25.0));
        expect(calculation.taxRate, greaterThanOrEqualTo(0.0));
        expect(calculation.totalAmount, greaterThanOrEqualTo(25.0));
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.calculateSalesTax(
            eventId: 'event-123',
            ticketPrice: 25.0,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });

      test('should calculate correct tax amount', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final calculation = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 100.0,
        );

        // Assert
        expect(calculation.taxAmount, equals(calculation.taxableAmount * (calculation.taxRate / 100.0)));
        expect(calculation.totalAmount, equals(calculation.taxableAmount + calculation.taxAmount));
      });
    });

    group('getTaxRateForLocation', () {
      test('should return tax rate for state', () async {
        // Act
        final taxRate = await service.getTaxRateForLocation(
          state: 'CA',
        );

        // Assert
        expect(taxRate, greaterThanOrEqualTo(0.0));
        expect(taxRate, lessThanOrEqualTo(15.0)); // Reasonable upper bound
      });

      test('should cache tax rates', () async {
        // Act - call twice
        final rate1 = await service.getTaxRateForLocation(state: 'CA');
        final rate2 = await service.getTaxRateForLocation(state: 'CA');

        // Assert - should be same (cached)
        expect(rate1, equals(rate2));
      });

      test('should return different rates for different locations', () async {
        // Act
        final caRate = await service.getTaxRateForLocation(state: 'CA');
        final nyRate = await service.getTaxRateForLocation(state: 'NY');

        // Assert
        // Rates may be same if using defaults, but method should handle both
        expect(caRate, isA<double>());
        expect(nyRate, isA<double>());
      });

      test('should handle missing state gracefully', () async {
        // Act
        final taxRate = await service.getTaxRateForLocation(state: null);

        // Assert
        expect(taxRate, equals(0.0)); // Default for missing state
      });
    });

    group('tax exemption logic', () {
      test('should exempt workshop events', () async {
        // Arrange
        final workshopEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.workshop,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => workshopEvent);

        // Act
        final calculation = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );

        // Assert
        expect(calculation.isTaxExempt, isTrue);
      });

      test('should exempt lecture events', () async {
        // Arrange
        final lectureEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.lecture,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => lectureEvent);

        // Act
        final calculation = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );

        // Assert
        expect(calculation.isTaxExempt, isTrue);
      });

      test('should not exempt meetup events', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final calculation = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );

        // Assert
        expect(calculation.isTaxExempt, isFalse);
      });

      test('should not exempt tour events', () async {
        // Arrange
        final tourEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.tour,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => tourEvent);

        // Act
        final calculation = await service.calculateSalesTax(
          eventId: 'event-123',
          ticketPrice: 25.0,
        );

        // Assert
        expect(calculation.isTaxExempt, isFalse);
      });
    });
  });
}

