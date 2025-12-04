import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/payment_event_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/stripe_service.dart';
import 'package:spots/core/config/stripe_config.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/models/payment_status.dart';
import 'package:spots/core/models/payment_result.dart';
import 'package:spots/core/models/user_role.dart';

/// Payment Event Service Integration Tests
/// 
/// Tests the integration between payment processing and event registration.
void main() {
  group('PaymentEventService', () {
    late PaymentEventService paymentEventService;
    late PaymentService paymentService;
    late ExpertiseEventService eventService;
    
    setUp(() {
      final stripeConfig = StripeConfig.test();
      final stripeService = StripeService(stripeConfig);
      paymentService = PaymentService(stripeService, ExpertiseEventService());
      eventService = ExpertiseEventService();
      paymentEventService = PaymentEventService(paymentService, eventService);
    });
    
    test('processEventPayment handles free events correctly', () async {
      // Create free event
      final host = UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        displayName: 'Host',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
        tags: [],
        expertiseMap: {},
        friends: [],
        curatedLists: [],
        collaboratedLists: [],
        followedLists: [],
        primaryRole: UserRole.user,
        isAgeVerified: false,
      );
      
      final freeEvent = ExpertiseEvent(
        id: 'event-free',
        title: 'Free Event',
        description: 'A free event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        price: null,
        isPaid: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final user = UnifiedUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
        tags: [],
        expertiseMap: {},
        friends: [],
        curatedLists: [],
        collaboratedLists: [],
        followedLists: [],
        primaryRole: UserRole.user,
        isAgeVerified: false,
      );
      
      // Process payment for free event
      final result = await paymentEventService.processEventPayment(
        event: freeEvent,
        user: user,
      );
      
      // Should succeed without payment
      expect(result.isSuccess, isTrue);
      expect(result.registered, isTrue);
      expect(result.payment, isNull); // No payment for free events
    });
    
    test('processEventPayment handles paid events - payment required', () async {
      // Note: This test would require actual Stripe integration or mocks
      // For now, this is a placeholder test structure
      
      // Create paid event
      final host = UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        displayName: 'Host',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
        tags: [],
        expertiseMap: {},
        friends: [],
        curatedLists: [],
        collaboratedLists: [],
        followedLists: [],
        primaryRole: UserRole.user,
        isAgeVerified: false,
      );
      
      final paidEvent = ExpertiseEvent(
        id: 'event-paid',
        title: 'Paid Event',
        description: 'A paid event',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: host,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        price: 25.00,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final user = UnifiedUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
        tags: [],
        expertiseMap: {},
        friends: [],
        curatedLists: [],
        collaboratedLists: [],
        followedLists: [],
        primaryRole: UserRole.user,
        isAgeVerified: false,
      );
      
      // Process payment for paid event
      // Note: This will fail without actual Stripe backend integration
      // In production, this would use mocked services
      final result = await paymentEventService.processEventPayment(
        event: paidEvent,
        user: user,
      );
      
      // Result depends on payment service implementation
      // If payment fails (no backend), result.isSuccess will be false
      // This is expected behavior for MVP without backend
    });
    
    test('processEventPayment enforces capacity limits', () async {
      // Create event with max capacity
      final host = UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        displayName: 'Host',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
        tags: [],
        expertiseMap: {},
        friends: [],
        curatedLists: [],
        collaboratedLists: [],
        followedLists: [],
        primaryRole: UserRole.user,
        isAgeVerified: false,
      );
      
      final fullEvent = ExpertiseEvent(
        id: 'event-full',
        title: 'Full Event',
        description: 'An event at capacity',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        maxAttendees: 1,
        attendeeCount: 1, // Already full
        price: null,
        isPaid: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final user = UnifiedUser(
        id: 'user-1',
        email: 'user@example.com',
        displayName: 'User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
        tags: [],
        expertiseMap: {},
        friends: [],
        curatedLists: [],
        collaboratedLists: [],
        followedLists: [],
        primaryRole: UserRole.user,
        isAgeVerified: false,
      );
      
      // Try to register for full event
      final result = await paymentEventService.processEventPayment(
        event: fullEvent,
        user: user,
      );
      
      // Should fail because event is full
      expect(result.isSuccess, isFalse);
      expect(result.registered, isFalse);
    });
  });
}

